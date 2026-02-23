{{ config(
    materialized='table',
    unique_key='rocket_id'
) }}


WITH rockets_raw AS (
    SELECT
        id AS rocket_id,
        name AS rocket_name,
        active,
        cost_per_launch,
        success_rate_pct,
        first_flight,
        stages,
        description,
        engines,
        payload_weights
    FROM {{ source('public', 'rockets') }}
),

-- Flatten payloads per orbit
payload_flat AS (
    SELECT
        rocket_id,
        rocket_name,
        active,
        cost_per_launch,
        success_rate_pct,
        first_flight,
        stages,
        description,
        -- Engines: extract from JSON object
        (engines->>'number')::INT AS engines_number,
        engines->>'type' AS engines_type,
        engines->>'version' AS engines_version,
        engines->>'layout' AS engines_layout,
        (engines->'isp'->>'sea_level')::INT AS isp_sea_level,
        (engines->'isp'->>'vacuum')::INT AS isp_vacuum,
        (engines->>'engine_loss_max')::INT AS engine_loss_max,
        -- Payloads: flatten JSON array
        MAX(CASE WHEN pw->>'id' = 'leo' THEN (pw->>'kg')::INT END) AS payload_leo_kg,
        MAX(CASE WHEN pw->>'id' = 'leo' THEN (pw->>'lb')::INT END) AS payload_leo_lb,
        MAX(CASE WHEN pw->>'id' = 'gto' THEN (pw->>'kg')::INT END) AS payload_gto_kg,
        MAX(CASE WHEN pw->>'id' = 'gto' THEN (pw->>'lb')::INT END) AS payload_gto_lb
    FROM rockets_raw,
         LATERAL UNNEST(payload_weights) AS pw
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
)

SELECT
    rocket_id,
    rocket_name,
    active,
    cost_per_launch,
    success_rate_pct,
    first_flight,
    stages,
    description,
    engines_number,
    engines_type,
    engines_version,
    engines_layout,
    isp_sea_level,
    isp_vacuum,
    engine_loss_max,
    payload_leo_kg,
    payload_leo_lb,
    payload_gto_kg,
    payload_gto_lb
FROM payload_flat
ORDER BY rocket_id
