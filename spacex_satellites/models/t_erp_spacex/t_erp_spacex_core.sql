{{ config(
    materialized='table',
    unique_key='core_id'
) }}

-- Stage 1: load raw cores
WITH cores_raw AS (
    SELECT
        id as core_id,
        serial,
        status,
        rtls_attempts,
        rtls_landings,
        asds_attempts,
        asds_landings,
        last_update,
        launches,        -- JSON array of launch IDs
        _sdc_extracted_at,
        _sdc_received_at,
        _sdc_batched_at,
        _sdc_deleted_at,
        _sdc_sequence,
        _sdc_table_version,
        _sdc_sync_started_at
    FROM {{ source('public', 'cores') }}
),

-- Stage 2: Flatten launches JSON array
launches_flat AS (
    SELECT
        c.core_id,
        lj #>> '{}' AS launch_id
    FROM cores_raw c,
         LATERAL unnest(c.launches) AS lj
    WHERE c.launches IS NOT NULL
)

-- Stage 3: Combine
SELECT
    c.core_id,
    c.serial,
    c.status,
    c.rtls_attempts,
    c.rtls_landings,
    c.asds_attempts,
    c.asds_landings,
    c.last_update,
    lf.launch_id,
    c._sdc_extracted_at,
    c._sdc_received_at,
    c._sdc_batched_at,
    c._sdc_deleted_at,
    c._sdc_sequence,
    c._sdc_table_version,
    c._sdc_sync_started_at
FROM cores_raw c
LEFT JOIN launches_flat lf
ON c.core_id = lf.core_id
