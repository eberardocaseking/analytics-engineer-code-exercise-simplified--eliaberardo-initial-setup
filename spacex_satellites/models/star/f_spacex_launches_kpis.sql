
{{ config(materialized='table') }}

SELECT
    -- Launch
    l.launch_id,
    l.launch_name,
    l.launch_date_utc,
    l.launch_success,
    l.launch_net,
    l.launch_window,
    l.launch_upcoming,
    l.launch_failures,
    l.launch_links,

    -- Payload
    p.payloads_id,
    p.payloads_name,
    p.payloads_type,
    p.payloads_mass_kg,
    p.payloads_mass_lbs,
    p.payloads_orbit,
    p.payloads_regime,
    p.payloads_reused,
    p.customer AS payload_customer,

    -- Core / booster
    l.core_id,
    l.core_flight,
    l.landing_success,
    c.serial AS core_serial,
    c.status AS core_status,
    c.rtls_landings,
    c.asds_landings,

    -- Capsule
    l.capsule_id,
    cap.status AS capsule_status,
    cap.type AS capsule_type,
    cap.reuse_count AS capsule_reuse_count,

    -- Starlink satellite
    sl.satellite_id,
    sl.satellite_version,
    sl.st_object_name,
    sl.st_norad_cat_id,
    sl.st_object_type,
    sl.st_launch_date AS satellite_launch_date,
    sl.st_decay_date AS satellite_decay_date,
    sl.is_in_orbit,
    sl.satellite_height_km,
    sl.satellite_velocity_kms,
    sl.st_inclination_deg,
    sl.st_apoapsis_km,
    sl.st_periapsis_km,
    sl.st_period_min

FROM {{ ref('t_erp_spacex_launches') }} l
LEFT JOIN {{ ref('t_erp_spacex_payloads') }} p
    ON l.payload_id = p.payloads_id
LEFT JOIN {{ ref('t_erp_spacex_core') }} c
    ON l.core_id = c.core_id
LEFT JOIN {{ ref('t_erp_spacex_capsule') }} cap
    ON l.capsule_id = cap.capsule_id
LEFT JOIN {{ ref('t_erp_spacex_starlink') }} sl
    ON p.norad_id = sl.st_norad_cat_id

WHERE payloads_name ILIKE 'Starlink%'
