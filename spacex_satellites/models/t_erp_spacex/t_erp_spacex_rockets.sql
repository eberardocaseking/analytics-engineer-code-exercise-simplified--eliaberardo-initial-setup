
{{ config(materialized='table') }}

{{ config(
    materialized='table'
) }}

with rockets_raw as (
    select
        id as rocket_id,
        name as rocket_name,
        first_flight,
        height,
        diameter,
        stages,
        engines,
        payload_weights
    FROM {{ source('public', 'rockets') }} 
),

-- Flatten payloads per orbit
payload_flat as (
    select
        rocket_id,
        rocket_name,
        first_flight,
        height,
        diameter,
        stages,
        -- Engines: extract from JSON object
        (engines->>'number')::int as engines_number,
        engines->>'type' as engines_type,
        engines->>'version' as engines_version,
        engines->>'layout' as engines_layout,
        (engines->'isp'->>'sea_level')::int as isp_sea_level,
        (engines->'isp'->>'vacuum')::int as isp_vacuum,
        (engines->>'engine_loss_max')::int as engine_loss_max,
        -- Payloads: flatten JSON array
        max(case when pw->>'id' = 'leo' then (pw->>'kg')::int end) as payload_leo_kg,
        max(case when pw->>'id' = 'leo' then (pw->>'lb')::int end) as payload_leo_lb,
        max(case when pw->>'id' = 'gto' then (pw->>'kg')::int end) as payload_gto_kg,
        max(case when pw->>'id' = 'gto' then (pw->>'lb')::int end) as payload_gto_lb
    from rockets_raw,
         lateral unnest(payload_weights) as pw
    group by rocket_id, rocket_name, first_flight, height, diameter, stages, engines
)

select *
from payload_flat
order by rocket_id
