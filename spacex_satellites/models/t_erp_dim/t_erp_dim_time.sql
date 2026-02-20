{{ config(materialized='table') }}
{{ config(alias='time') }}

WITH date_rows AS (
{{ dbt_utils.date_spine(
    datepart="day",
    start_date="to_date('01/01/2000', 'mm/dd/yyyy')",
    end_date="dateadd(year, 3, current_date)")
}}
)

SELECT 
    date_day AS _date,
    CAST(TO_CHAR(date_day, 'yyyymmdd') as integer) AS sk_time_id,
    date_day AS date_description,
    EXTRACT(DAY FROM date_day) AS day,
    EXTRACT(MONTH FROM date_day ) AS month,
    EXTRACT(QUARTER FROM date_day) AS quarter,
    EXTRACT(YEAR FROM date_day) AS year,
    EXTRACT (WEEK FROM date_day) as calendar_week_name,
    CASE month
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April' 
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END ::varchar as  month_description,
    CASE 
        WHEN month IN ( '1','2','3') THEN '1. Quarter'
        WHEN month IN ('4','5','6') THEN '2. Quarter'
        WHEN month IN ('7','8','9') THEN '3. Quarter'
        WHEN month IN ('10','11','12') THEN '4. Quarter'
    END ::varchar as quarter_description,
    CASE
        WHEN month IN ('1','2','3','4','5','6') THEN '1. Halfyear'
        ELSE '2. Halfyear'
    END ::varchar AS half_year_descr,
    CASE
        WHEN month IN ('1','2','3','4','5','6') THEN 1
        ELSE 2
    END AS half_year,
    EXTRACT (DOW FROM date_day) AS day_n,
    CASE day_n 
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END ::varchar AS weekday_description,
    CASE
        WHEN weekday_description IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') THEN 1
        ELSE 0
    END AS is_weekday,
    CASE
        WHEN weekday_description IN ('Saturday', 'Sunday') THEN 0
        ELSE 1
    END AS is_working_day,
    CASE weekday_description
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END AS weekday
FROM date_rows