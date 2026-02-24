{{ config(materialized='table') }}

SELECT
    rocket_id,
    rocket_name,
    active,
    first_flight,
    stages,
    description,
    cost_per_launch,
    success_rate_pct,
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

FROM {{ ref('t_erp_spacex_rockets') }}
