{{ config(materialized='table') }}

SELECT
    landpads_id,
    landpads_name,
    landpads_full_name,
    landpads_status,
    landpads_type,
    landpads_locality,
    landpads_region,
    landpads_latitude,
    landpads_longitude,
    landpads_landing_attempts,
    landpads_landing_successes,
    landpads_landing_success_pct

FROM {{ ref('t_erp_spacex_landpads') }}
