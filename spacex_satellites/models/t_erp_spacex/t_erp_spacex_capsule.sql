
{{ config(
    materialized='table',
    unique_key='capsule_id'
) }}



SELECT  
id AS capsule_id,
status,
type,
reuse_count,
water_landings,
land_landings
FROM 

{{ source('public', 'capsules') }} c