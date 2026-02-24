{{ config(materialized='table') }}

SELECT
    satellite_id,
    satellite_version,
    satellite_launch_id,
    satellite_longitude,
    satellite_latitude,
    satellite_height_km,
    satellite_velocity_kms,
    st_object_name,
    st_norad_cat_id,
    st_object_id,
    st_object_type,
    st_launch_date,
    st_decay_date,
    st_launch_site,
    st_epoch,
    st_period_min,
    st_inclination_deg,
    st_apoapsis_km,
    st_periapsis_km,
    st_rcs_size,
    is_in_orbit

FROM {{ ref('t_erp_spacex_starlink') }}
