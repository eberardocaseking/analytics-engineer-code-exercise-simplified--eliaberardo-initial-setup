
{{ config(
    materialized='table',
    unique_key='crew_id'
) }}

WITH crew_raw AS (
    SELECT
        id AS crew_id,
        name,
        status,
        agency,
        image,
        wikipedia,
        launches
     FROM {{ source('public', 'crew') }}
),

launches_flat AS (
    SELECT
        c.crew_id,
        lj #>> '{}' AS launch_id
    FROM crew_raw c,
         LATERAL unnest(c.launches) AS lj
    WHERE c.launches IS NOT NULL
)

SELECT
    c.crew_id,
    c.name,
    c.status,
    c.agency,
    c.image,
    c.wikipedia,
    lf.launch_id
FROM crew_raw c
LEFT JOIN launches_flat lf ON c.crew_id = lf.crew_id
