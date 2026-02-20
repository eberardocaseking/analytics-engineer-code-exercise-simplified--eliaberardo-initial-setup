{{ config(materialized='table') }}
SELECT 

    id AS member_id,
    name,
    status,
    agency,
    image,
    wikipedia,
    launches,
    _sdc_extracted_at AS extracted_at,
    _sdc_received_at AS received_at,
    _sdc_batched_at AS batched_at,
    _sdc_deleted_at AS deleted_at,
    _sdc_sequence AS sequence,
    _sdc_table_version AS table_version,
    _sdc_sync_started_at

FROM {{ source('public', 'crew') }} 