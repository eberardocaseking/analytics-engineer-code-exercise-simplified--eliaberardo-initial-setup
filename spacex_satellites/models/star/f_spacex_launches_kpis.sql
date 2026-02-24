
{{ config(materialized='table') }}

SELECT
    -- Foreign keys
    l.launch_id,
    l.rocket_id,
    l.core_id,
    l.landpad_id,
    p.payloads_id,
    sl.satellite_id,
    sl.st_norad_cat_id,

    -- Launch (degenerate dimension + measures)
    l.launch_name,
    l.launch_date_utc,
    l.launch_success,
    l.launch_net,
    l.launch_window,
    l.launch_upcoming,
    l.launch_failures,

    -- Booster / core measures
    l.core_flight,
    l.landing_success,

    -- Payload measures
    p.payloads_mass_kg,
    p.payloads_mass_lbs,
    p.payloads_reused,

    -- Satellite measures
    sl.st_launch_date AS satellite_launch_date,
    sl.st_decay_date AS satellite_decay_date,
    sl.is_in_orbit,
    sl.satellite_height_km,
    sl.satellite_velocity_kms,
    sl.st_inclination_deg,
    sl.st_apoapsis_km,
    sl.st_periapsis_km,
    sl.st_period_min

FROM {{ ref('t_erp_spacex_launches') }} AS l
LEFT JOIN {{ ref('d_spacex_payloads') }} AS p
    ON l.payload_id = p.payloads_id
LEFT JOIN {{ ref('d_spacex_starlink') }} AS sl
    ON p.norad_id = sl.st_norad_cat_id

WHERE p.payloads_name ILIKE 'Starlink%'
