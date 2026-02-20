{{ config(materialized='table') }}


SELECT  
id AS core_id,
serial,
status,
rtls_attempts,
rtls_landings,
asds_attempts,
asds_landings,
last_update,
launches,
_sdc_extracted_at AS sdc_extracted_at,
_sdc_received_at AS sdc_received_at,
_sdc_batched_at AS sdc_batched_at,
_sdc_deleted_at AS sdc_deleted_at,
_sdc_sequence AS sdc_sequence,
_sdc_table_version AS sdc_table_version,
_sdc_sync_started_at AS sdc_sync_started_at
FROM 


{{ source('public', 'cores') }} 