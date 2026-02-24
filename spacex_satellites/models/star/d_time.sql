{{ config(materialized='table') }}

SELECT
    sk_time_id,
    _date,
    day,
    month,
    month_description,
    quarter,
    quarter_description,
    half_year,
    half_year_descr,
    year,
    calendar_week_name,
    day_n,
    weekday,
    weekday_description,
    is_weekday,
    is_working_day

FROM {{ ref('t_erp_dim_time') }}
