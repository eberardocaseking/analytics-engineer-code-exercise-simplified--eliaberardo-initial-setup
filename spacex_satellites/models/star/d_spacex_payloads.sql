{{ config(materialized='table') }}

SELECT
    payloads_id,
    payloads_name,
    payloads_type,
    payloads_reused,
    payloads_launch_id,
    payloads_mass_kg,
    payloads_mass_lbs,
    payloads_orbit,
    payloads_reference_system,
    payloads_regime,
    payloads_inclination_deg,
    payloads_period_min,
    payloads_lifespan_years,
    customer,
    norad_id,
    nationality,
    manufacturer

FROM {{ ref('t_erp_spacex_payloads') }}
