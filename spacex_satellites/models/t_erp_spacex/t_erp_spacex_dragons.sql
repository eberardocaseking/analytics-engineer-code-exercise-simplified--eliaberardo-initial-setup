
{{ config(
    materialized='table',
    unique_key='dragon_id'
) }}


SELECT 
    id AS dragon_id,
    name,
    type,
    active,
    crew_capacity,
    sidewall_angle_deg,
    orbit_duration_yr,
    dry_mass_kg,
    dry_mass_lb,
    first_flight,
    heat_shield,
    thrusters,
    launch_payload_mass,
    launch_payload_vol,
    return_payload_mass,
    return_payload_vol,
    pressurized_capsule,
    trunk,
    height_w_trunk,
    diameter,
    flickr_images,
    wikipedia,
    description,
    _sdc_extracted_at AS extracted_at,
    _sdc_received_at AS received_at,
    _sdc_batched_at AS batched_at,
    _sdc_deleted_at AS deleted_at,
    _sdc_sequence AS sequence,
    _sdc_table_version AS table_version,
    _sdc_sync_started_at AS sync_started_at

FROM {{ source('public', 'dragons') }} 