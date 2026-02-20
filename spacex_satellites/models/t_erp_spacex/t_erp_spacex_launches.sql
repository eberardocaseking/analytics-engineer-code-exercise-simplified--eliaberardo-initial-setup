{{ config(
    materialized='table',
    unique_key='launch_id'
) }}

-- Stage 1: load raw launches
with launches_raw as (
    select
        id as launch_id,
        name as launch_name,
        date_utc as launch_date_utc,
        success as launch_success,
        net as launch_net,
        "window" as launch_window,   -- reserved keyword
        upcoming as launch_upcoming,
        payloads as launch_payloads, -- jsonb[] array
        cores as launch_cores,       -- jsonb[] array of objects
        capsules as launch_capsules, -- jsonb[] array
        crew as launch_crew,         -- jsonb[] array
        failures as launch_failures,
        links as launch_links
    from public.launches
),

-- Stage 2: Flatten payloads (jsonb[] of strings)
payloads_flat as (
    select
        l.launch_id,
        pw #>> '{}' as payload_id
    from launches_raw l,
         lateral unnest(l.launch_payloads) as pw
),

-- Stage 3: Flatten cores (jsonb[] of objects)
cores_flat as (
    select
        l.launch_id,
        core_json->>'core' as core_id,
        (core_json->>'flight')::int as core_flight,
        (core_json->>'landing_success')::boolean as landing_success
    from launches_raw l,
         lateral unnest(l.launch_cores) as core_json
    where l.launch_cores is not null
),

-- Stage 4: Flatten capsules (jsonb[] of strings)
capsules_flat as (
    select
        l.launch_id,
        caps #>> '{}' as capsule_id
    from launches_raw l,
         lateral unnest(l.launch_capsules) as caps
    where l.launch_capsules is not null
),

-- Stage 5: Flatten crew (jsonb[] of strings)
crew_flat as (
    select
        l.launch_id,
        cr #>> '{}' as crew_id
    from launches_raw l,
         lateral unnest(l.launch_crew) as cr
    where l.launch_crew is not null
)

-- Stage 6: Combine all into staging table
select
    l.launch_id,
    l.launch_name,
    l.launch_date_utc,
    l.launch_success,
    l.launch_net,
    l.launch_window,
    l.launch_upcoming,
    l.launch_failures,
    l.launch_links,
    p.payload_id,
    c.core_id,
    c.core_flight,
    c.landing_success,
    cap.capsule_id,
    cr.crew_id
from launches_raw l
left join payloads_flat p on l.launch_id = p.launch_id
left join cores_flat c on l.launch_id = c.launch_id
left join capsules_flat cap on l.launch_id = cap.launch_id
left join crew_flat cr on l.launch_id = cr.launch_id