{{ config(materialized='table') }}


WITH

-- deduplicate to one row per (launch, satellite) 
satellite_facts AS (
    SELECT DISTINCT
        launch_id,
        launch_name,
        launch_date_utc::DATE AS launch_date,
        satellite_id,
        is_in_orbit
    FROM {{ ref('f_spacex_launches_kpis') }}
    WHERE launch_success = true
      AND satellite_id IS NOT NULL
),

--– aggregate to one row per launch
launch_stats AS (
    SELECT
        launch_id,
        MIN(launch_name) AS launch_name,
        MIN(launch_date) AS launch_date,
        COUNT(*) AS satellites_deployed,
        SUM(CASE WHEN is_in_orbit THEN 1 ELSE 0 END) AS satellites_in_orbit
    FROM satellite_facts
    {{ dbt_utils.group_by(1) }}
),

-- cumulative running totals across historical launches
historical AS (
    SELECT
        launch_id,
        launch_name,
        launch_date,
        satellites_deployed,
        satellites_in_orbit,
        ROW_NUMBER() OVER (ORDER BY launch_date) AS launch_number,
        SUM(satellites_deployed)
            OVER (ORDER BY launch_date
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS cumulative_deployed,
        SUM(satellites_in_orbit)
            OVER (ORDER BY launch_date
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS cumulative_in_orbit
    FROM launch_stats
),

-- projection parameters: overall averages across all historical launches
projection_params AS (
    SELECT
        MAX(launch_date) AS last_launch_date,
        MAX(launch_number) AS last_launch_number,
        MAX(cumulative_deployed) AS last_cumulative_deployed,
        MAX(cumulative_in_orbit) AS last_cumulative_in_orbit,
        AVG(satellites_deployed)::FLOAT AS avg_deployed_per_launch,
        AVG(satellites_in_orbit)::FLOAT AS avg_in_orbit_per_launch,
        -- Average days between consecutive launches
        (MAX(launch_date) - MIN(launch_date))::FLOAT
            / NULLIF(MAX(launch_number) - 1, 0) AS avg_days_between_launches
    FROM historical
),

-- generate projected future launches (up to 1500 to cover the gap to 42k)
projected AS (
    SELECT
        gs.n AS n,
        pp.last_launch_date
            + (gs.n * pp.avg_days_between_launches)::INT AS launch_date,
        pp.last_launch_number + gs.n AS launch_number,
        pp.avg_deployed_per_launch::INT AS satellites_deployed,
        pp.avg_in_orbit_per_launch::INT AS satellites_in_orbit,
        (pp.last_cumulative_deployed
            + gs.n * pp.avg_deployed_per_launch)::INT AS cumulative_deployed,
        (pp.last_cumulative_in_orbit
            + gs.n * pp.avg_in_orbit_per_launch)::INT AS cumulative_in_orbit
    FROM projection_params pp
    CROSS JOIN GENERATE_SERIES(1, 1500) AS gs(n)
),

-- keep only up to (and including) the first launch that reaches 42,000
projected_trimmed AS (
    SELECT *
    FROM projected
    WHERE n <= (SELECT MIN(n) FROM projected WHERE cumulative_in_orbit >= 42000)
)

--historical rows followed by projected rows
SELECT
    launch_id,
    launch_name,
    launch_date,
    CAST(TO_CHAR(launch_date, 'YYYYMMDD') AS integer) AS launch_date_id,
    launch_number,
    satellites_deployed,
    satellites_in_orbit,
    cumulative_deployed,
    cumulative_in_orbit,
    false AS is_projected
FROM historical

UNION ALL

SELECT
    NULL AS launch_id,
    'Projected Launch #' || launch_number AS launch_name,
    launch_date,
    CAST(TO_CHAR(launch_date, 'YYYYMMDD') AS integer) AS launch_date_id,
    launch_number,
    satellites_deployed,
    satellites_in_orbit,
    cumulative_deployed,
    cumulative_in_orbit,
    true AS is_projected
FROM projected_trimmed

ORDER BY launch_date
