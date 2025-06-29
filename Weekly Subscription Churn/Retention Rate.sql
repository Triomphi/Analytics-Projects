WITH
  cohort_data AS (
  SELECT
    DISTINCT user_pseudo_id AS user,
    category,
    country,
    DATE_TRUNC(subscription_start, WEEK) AS start_week,
    DATE_TRUNC(subscription_end, WEEK) AS end_week
  FROM
    `turing_data_analytics.subscriptions` ),

retained as (
SELECT
  start_week,
  -- Count users who started in each cohort week (week 0)
  COUNT(user) AS week_0,
   -- Retained customers calculations for weeks 1 to 6
  COUNTIF(DATE_DIFF(end_week, start_week, WEEK) > 0 OR end_week IS NULL) AS week_1,
  COUNTIF((DATE_DIFF(end_week, start_week, WEEK) > 1 OR end_week IS NULL) AND start_week < (SELECT MAX(start_week) FROM cohort_data)) AS week_2,
  COUNTIF((DATE_DIFF(end_week, start_week, WEEK) > 2 OR end_week IS NULL) AND start_week < (SELECT DATETIME_SUB(MAX(start_week), INTERVAL 1 WEEK) FROM cohort_data)) AS week_3,
  COUNTIF((DATE_DIFF(end_week, start_week, WEEK) > 3 OR end_week IS NULL) AND start_week < (SELECT DATETIME_SUB(MAX(start_week), INTERVAL 2 WEEK) FROM cohort_data)) AS week_4,
  COUNTIF((DATE_DIFF(end_week, start_week, WEEK) > 4 OR end_week IS NULL) AND start_week < (SELECT DATETIME_SUB(MAX(start_week), INTERVAL 3 WEEK) FROM cohort_data)) AS week_5,
  COUNTIF((DATE_DIFF(end_week, start_week, WEEK) > 5 OR end_week IS NULL) AND start_week < (SELECT DATETIME_SUB(MAX(start_week), INTERVAL 4 WEEK) FROM cohort_data)) AS week_6
FROM
  cohort_data
GROUP BY
  start_week)

SELECT
start_week,
-- Retention rate calculations
week_0/week_0 AS week_0,
ROUND(week_1/week_0, 2) AS week_1,
ROUND(week_2/week_0, 2) AS week_2,
ROUND(week_3/week_0, 2) AS week_3,
ROUND(week_4/week_0, 2) AS week_4,
ROUND(week_5/week_0, 2) AS week_5,
ROUND(week_6/week_0, 2) AS week_6
FROM retained