{{ config(materialized='table') }}

SELECT
    core_id,
    serial,
    status,
    rtls_attempts,
    rtls_landings,
    asds_attempts,
    asds_landings,
    last_update

FROM {{ ref('t_erp_spacex_core') }}
