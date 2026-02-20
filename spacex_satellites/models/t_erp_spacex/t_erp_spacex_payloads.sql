{{ config(
    materialized='table',
    unique_key='payloads_id'
) }}


-- Stage 1: load raw payloads
WITH payloads_raw AS (
    SELECT
        id AS payloads_id,
        name AS payloads_name,
        type AS payloads_type,
        reused AS payloads_reused,
        launch AS payloads_launch_id,
        customers AS payloads_customers,       -- jsonb[] of strings
        norad_ids AS payloads_norad_ids,       -- jsonb[] of integers
        nationalities AS payloads_nationalities,   -- jsonb[] of strings
        manufacturers AS payloads_manufacturers,   -- jsonb[] of strings
        mass_kg  AS payloads_mass_kg,
        mass_lbs AS payloads_mass_lbs,
        orbit AS payloads_orbit,
        reference_system AS payloads_reference_system,
        regime AS payloads_regime,
        longitude AS payloads_longitude,
        semi_major_axis_km AS payloads_semi_major_axis_km,
        eccentricity  AS payloads_eccentricity,
        periapsis_km AS payloads_periapsis_km,
        apoapsis_km AS payloads_apoapsis_km,
        inclination_deg AS payloads_inclination_deg,
        period_min AS payloads_period_min,
        lifespan_years AS payloads_lifespan_years,
        epoch AS payloads_epoch,
        mean_motion  AS payloads_mean_motion,
        raan AS payloads_raan,
        arg_of_pericenter AS payloads_arg_of_pericenter,
        mean_anomaly AS payloads_mean_anomaly,
        dragon AS payloads_dragon,          -- jsonb object
        _sdc_extracted_at AS payloads_sdc_extracted_at,
        _sdc_received_at AS payloads_sdc_received_at,
        _sdc_batched_at AS payloads_sdc_batched_at,
        _sdc_deleted_at AS payloads_sdc_deleted_at,
        _sdc_sequence AS payloads_sdc_sequence,
        _sdc_table_version AS payloads_sdc_table_version,
        _sdc_sync_started_at AS payloads_sdc_sync_started_at
    FROM {{ source('public', 'payloads') }}
),

-- Flatten customers (jsonb[] of strings)
customers_flat AS (
    SELECT
        p.payloads_id,
        cust #>> '{}' AS customer
    FROM payloads_raw p,
         LATERAL unnest(p.payloads_customers) AS cust
    WHERE p.payloads_customers IS NOT NULL
),

-- Flatten norad_ids (jsonb[] of integers)
norad_ids_flat AS (
    SELECT
        p.payloads_id,
        (nid #>> '{}')::int AS norad_id
    FROM payloads_raw p,
         LATERAL unnest(p.payloads_norad_ids) AS nid
    WHERE p.payloads_norad_ids IS NOT NULL
),

--  Flatten nationalities (jsonb[] of strings)
nationalities_flat AS (
    SELECT
        p.payloads_id,
        nat #>> '{}' AS nationality
    FROM payloads_raw p,
         LATERAL unnest(p.payloads_nationalities) AS nat
    WHERE p.payloads_nationalities IS NOT NULL
),

--  Flatten manufacturers (jsonb[] of strings)
manufacturers_flat AS (
    SELECT
        p.payloads_id,
        mfr #>> '{}' AS manufacturer
    FROM payloads_raw p,
         LATERAL unnest(p.payloads_manufacturers) AS mfr
    WHERE p.payloads_manufacturers IS NOT NULL
),

-- Extract dragon JSON object fields as flat columns
dragon_flat AS (
    SELECT
        p.payloads_id,
        p.payloads_dragon->>'capsule'AS dragon_capsule_id,
        (p.payloads_dragon->>'mass_returned_kg')::float AS dragon_mass_returned_kg,
        (p.payloads_dragon->>'mass_returned_lbs')::float AS dragon_mass_returned_lbs,
        (p.payloads_dragon->>'flight_time_sec')::int AS dragon_flight_time_sec,
        p.payloads_dragon->>'manifest'AS dragon_manifest,
        (p.payloads_dragon->>'water_landing')::boolean AS dragon_water_landing,
        (p.payloads_dragon->>'land_landing')::boolean  AS dragon_land_landing
    FROM payloads_raw p
    WHERE p.payloads_dragon IS NOT NULL
)

-- Combine all into final table
SELECT
    p.payloads_id,
    p.payloads_name,
    p.payloads_type,
    p.payloads_reused,
    p.payloads_launch_id,
    p.payloads_mass_kg,
    p.payloads_mass_lbs,
    p.payloads_orbit,
    p.payloads_reference_system,
    p.payloads_regime,
    p.payloads_longitude,
    p.payloads_semi_major_axis_km,
    p.payloads_eccentricity,
    p.payloads_periapsis_km,
    p.payloads_apoapsis_km,
    p.payloads_inclination_deg,
    p.payloads_period_min,
    p.payloads_lifespan_years,
    p.payloads_epoch,
    p.payloads_mean_motion,
    p.payloads_raan,
    p.payloads_arg_of_pericenter,
    p.payloads_mean_anomaly,
    p.payloads_sdc_extracted_at,
    p.payloads_sdc_received_at,
    p.payloads_sdc_batched_at,
    p.payloads_sdc_deleted_at,
    p.payloads_sdc_sequence,
    p.payloads_sdc_table_version,
    p.payloads_sdc_sync_started_at,
    -- Unnested arrays
    cust.customer,
    nid.norad_id,
    nat.nationality,
    mfr.manufacturer,
    -- Dragon object fields
    d.dragon_capsule_id,
    d.dragon_mass_returned_kg,
    d.dragon_mass_returned_lbs,
    d.dragon_flight_time_sec,
    d.dragon_manifest,
    d.dragon_water_landing,
    d.dragon_land_landing
FROM payloads_raw p
LEFT JOIN customers_flat AS cust
    ON p.payloads_id = cust.payloads_id
LEFT JOIN norad_ids_flat AS nid  
    ON p.payloads_id = nid.payloads_id
LEFT JOIN nationalities_flat AS nat  
    ON p.payloads_id = nat.payloads_id
LEFT JOIN manufacturers_flat AS mfr  
    ON p.payloads_id = mfr.payloads_id
LEFT JOIN dragon_flat AS d   
    ON p.payloads_id = d.payloads_id


