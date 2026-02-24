
{{ config(
    materialized='table',
    unique_key='satellite_id'
) }}

SELECT
    -- Satellite 
    id AS satellite_id,
    version AS satellite_version,
    launch AS satellite_launch_id,

    -- Orbital position (real-time)
    longitude AS satellite_longitude,
    latitude AS satellite_latitude,
    height_km AS satellite_height_km,
    velocity_kms AS satellite_velocity_kms,

    -- spaceTrack fields (flattened from JSON)
    "spaceTrack"->>'OBJECT_NAME'AS st_object_name,
    ("spaceTrack"->>'NORAD_CAT_ID')::INT AS st_norad_cat_id,
    "spaceTrack"->>'OBJECT_ID' AS st_object_id,
    "spaceTrack"->>'OBJECT_TYPE' AS st_object_type,
    "spaceTrack"->>'CLASSIFICATION_TYPE'AS st_classification_type,
    "spaceTrack"->>'COUNTRY_CODE'AS st_country_code,
    ("spaceTrack"->>'LAUNCH_DATE')::DATE AS st_launch_date,
    ("spaceTrack"->>'DECAY_DATE')::DATE  AS st_decay_date,
    "spaceTrack"->>'SITE'AS st_launch_site,
    ("spaceTrack"->>'EPOCH')::TIMESTAMP AS st_epoch,
    ("spaceTrack"->>'PERIOD')::FLOAT AS st_period_min,
    ("spaceTrack"->>'INCLINATION')::FLOAT AS st_inclination_deg,
    ("spaceTrack"->>'APOAPSIS')::FLOAT AS st_apoapsis_km,
    ("spaceTrack"->>'PERIAPSIS')::FLOAT  AS st_periapsis_km,
    "spaceTrack"->>'RCS_SIZE'AS st_rcs_size,

    -- is in orbit?
    ("spaceTrack"->>'DECAY_DATE') IS NULL AS is_in_orbit,

    _sdc_extracted_at AS satellite_sdc_extracted_at,
     _sdc_received_at  AS satellite_sdc_received_at,
    _sdc_batched_at  AS satellite_sdc_batched_at,
    _sdc_deleted_at AS satellite_sdc_deleted_at,
    _sdc_sequence  AS satellite_sdc_sequence,
    _sdc_table_version  AS satellite_sdc_table_version,
    _sdc_sync_started_at AS satellite_sdc_sync_started_at

FROM {{ source('public', 'starlink') }}
