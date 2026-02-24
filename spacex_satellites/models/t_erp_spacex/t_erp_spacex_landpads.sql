

{{ config(
    materialized='table',
    unique_key='landpad_id'
) }}


SELECT 
    id AS landpads_id,
    name AS landpads_name,
    full_name AS landpads_full_name,
    status AS landpads_status,
    type AS landpads_type,
    locality AS landpads_locality,
    region AS landpads_region,
    latitude AS landpads_latitude,
    longitude AS landpads_longitude,
    landing_attempts AS landpads_landing_attempts,
    landing_successes AS landpads_landing_successes,
    ROUND(100.0 * landing_successes / NULLIF(landing_attempts, 0), 1) AS landpads_landing_success_pct,
    details AS landpads_details,
    launches AS landpads_launches,
    _sdc_extracted_at AS landpads_sdc_extracted_at,
    _sdc_received_at AS landpads_sdc_received_at,
    _sdc_batched_at AS landpads_sdc_batched_at,
    _sdc_deleted_at AS landpads_sdc_deleted_at,
    _sdc_sequence AS landpads_sdc_sequence,
    _sdc_table_version AS landpads_sdc_table_version,
    _sdc_sync_started_at AS landpads_sdc_sync_started_at

FROM {{ source('public', 'landpads') }} l