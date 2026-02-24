{{ config(materialized='table') }}

SELECT
    capsule_id,
    status,
    type,
    reuse_count,
    water_landings,
    land_landings

FROM {{ ref('t_erp_spacex_capsule') }}
