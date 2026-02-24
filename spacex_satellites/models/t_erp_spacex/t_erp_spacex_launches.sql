{{ config(
    materialized='table',
    unique_key='launch_id'
) }}

--load raw launches
WITH launches_raw AS (
    SELECT
        id AS launch_id,
        rocket AS rocket_id,
        name AS launch_name,
        date_utc AS launch_date_utc,
        success AS launch_success,
        net AS launch_net,
        "window"AS launch_window,   
        upcoming AS launch_upcoming,
        payloads AS launch_payloads, 
        cores AS launch_cores,    
        capsules AS launch_capsules,
        crew AS launch_crew,  
        failures AS launch_failures

    FROM {{ source('public', 'launches') }}
),

--  Flatten payloads 
payloads_flat AS (
    SELECT
        l.launch_id,
        pw #>> '{}' AS payload_id
    FROM launches_raw l,
         LATERAL UNNEST(l.launch_payloads) AS pw
),

-- Flatten cores 
cores_flat AS (
    SELECT
        l.launch_id,
        core_json->>'core' AS core_id,
        (core_json->>'flight')::INT AS core_flight,
        (core_json->>'landing_success')::BOOLEAN AS landing_success,
        core_json->>'landpad' AS landpad_id
    FROM launches_raw l,
         LATERAL UNNEST(l.launch_cores) AS core_json
    WHERE l.launch_cores IS NOT NULL
),

--  Flatten capsules 
capsules_flat AS (
    SELECT
        l.launch_id,
        caps #>> '{}' AS capsule_id
    FROM launches_raw l,
         LATERAL UNNEST(l.launch_capsules) AS caps
    WHERE l.launch_capsules IS NOT NULL
)

SELECT
    l.launch_id,
    l.rocket_id,
    l.launch_name,
    l.launch_date_utc,
    l.launch_success,
    l.launch_net,
    l.launch_window,
    l.launch_upcoming,
    l.launch_failures,
    p.payload_id,
    c.core_id,
    c.core_flight,
    c.landing_success,
    c.landpad_id,
    cap.capsule_id
FROM launches_raw l
LEFT JOIN payloads_flat  p
    ON l.launch_id = p.launch_id
LEFT JOIN cores_flat     c
    ON l.launch_id = c.launch_id
LEFT JOIN capsules_flat  cap
    ON l.launch_id = cap.launch_id
