{{ config(materialized='table') }}
{{ config(alias='time') }}

WITH date_rows AS (
    SELECT generate_series(
        '2000-01-01'::date,
        (current_date + interval '3 years')::date,
        '1 day'::interval
    )::date AS date_day
),

enriched AS (
    SELECT
        date_day,
        EXTRACT(DAY FROM date_day)::int AS day,
        EXTRACT(MONTH FROM date_day)::int AS month,
        EXTRACT(QUARTER FROM date_day)::int AS quarter,
        EXTRACT(YEAR FROM date_day)::int AS year,
        EXTRACT(WEEK FROM date_day)::int AS calendar_week_name,
        EXTRACT(DOW FROM date_day)::int AS day_n
    FROM date_rows
)

SELECT
    date_day AS _date,
    CAST(TO_CHAR(date_day, 'YYYYMMDD') AS integer) AS sk_time_id,
    date_day AS date_description,
    day,
    month,
    quarter,
    year,
    calendar_week_name,
    CASE month
        WHEN 1  THEN 'January'
        WHEN 2  THEN 'February'
        WHEN 3  THEN 'March'
        WHEN 4  THEN 'April'
        WHEN 5  THEN 'May'
        WHEN 6  THEN 'June'
        WHEN 7  THEN 'July'
        WHEN 8  THEN 'August'
        WHEN 9  THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END::varchar AS month_description,
    CASE
        WHEN month IN (1,2,3)    THEN '1. Quarter'
        WHEN month IN (4,5,6)    THEN '2. Quarter'
        WHEN month IN (7,8,9)    THEN '3. Quarter'
        WHEN month IN (10,11,12) THEN '4. Quarter'
    END::varchar AS quarter_description,
    CASE
        WHEN month IN (1,2,3,4,5,6) THEN '1. Halfyear'
        ELSE '2. Halfyear'
    END::varchar AS half_year_descr,
    CASE
        WHEN month IN (1,2,3,4,5,6) THEN 1
        ELSE 2
    END AS half_year,
    day_n,
    CASE day_n
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END::varchar AS weekday_description,
    CASE WHEN day_n BETWEEN 1 AND 5 THEN 1 ELSE 0 END AS is_weekday,
    CASE WHEN day_n BETWEEN 1 AND 5 THEN 1 ELSE 0 END AS is_working_day,
    CASE day_n
        WHEN 1 THEN 1
        WHEN 2 THEN 2
        WHEN 3 THEN 3
        WHEN 4 THEN 4
        WHEN 5 THEN 5
        WHEN 6 THEN 6
        WHEN 0 THEN 7
    END AS weekday
FROM enriched