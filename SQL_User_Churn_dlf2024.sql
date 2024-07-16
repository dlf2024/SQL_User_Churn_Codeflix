/* Get familiar with the data */
/* Task 1 - Inspect subscriptions table */
SELECT * FROM subscriptions LIMIT 100;
/* There are 2 segments: 87 and 30 */

/* Task 2 - Determine the range of months */
SELECT MIN(subscription_start) AS date_min, 
MAX(subscription_start) AS date_max
FROM subscriptions;
/* dates range from 2016-12-01 to 2017-03-30 */

/* Calculate churn rate for each segment */
/* Task 3 - create a temporary table of months */
WITH months as
(SELECT
  '2016-12-01' as first_day,
  '2016-12-31' as last_day
UNION
SELECT
  '2017-01-01' as first_day,
  '2017-01-31' as last_day
UNION
SELECT
  '2017-02-01' as first_day,
  '2017-02-23' as last_day
UNION
SELECT
  '2017-03-01' as first_day,
  '2017-03-30' as last_day
)
SELECT *
FROM months;

/* Task 4 - create a temporary cross_join, from subscriptions and months */
WITH months as
(SELECT
  '2016-12-01' as first_day,
  '2016-12-31' as last_day
UNION
SELECT
  '2017-01-01' as first_day,
  '2017-01-31' as last_day
UNION
SELECT
  '2017-02-01' as first_day,
  '2017-02-23' as last_day
UNION
SELECT
  '2017-03-01' as first_day,
  '2017-03-30' as last_day
),
cross_join AS
(SELECT *
FROM subscriptions
CROSS JOIN months)
SELECT *
FROM cross_join
LIMIT 10;

/* Task 5-6 - create a temporary table, status, from the cross_join table */
WITH months AS (
  SELECT '2016-12-01' AS first_day, '2016-12-31' AS last_day
  UNION
  SELECT '2017-01-01', '2017-01-31'
  UNION
  SELECT '2017-02-01', '2017-02-28'
  UNION
  SELECT '2017-03-01', '2017-03-31'
),
cross_join AS (
  SELECT subscriptions.*, months.first_day, months.last_day
  FROM subscriptions
  CROSS JOIN months
),
status AS (
  SELECT 
    id, 
    first_day AS month,
    CASE
      WHEN (segment = 87 AND subscription_start < first_day AND (subscription_end > first_day OR subscription_end IS NULL)) THEN 1
      ELSE 0
    END AS is_active_87,
    CASE
      WHEN (segment = 30 AND subscription_start < first_day AND (subscription_end > first_day OR subscription_end IS NULL)) THEN 1
      ELSE 0
    END AS is_active_30,
     CASE
      WHEN (segment = 87) AND (subscription_end BETWEEN first_day AND last_day) THEN 1
      ELSE 0
    END AS is_canceled_87,
    CASE
      WHEN (segment = 30) AND (subscription_end BETWEEN first_day AND last_day) THEN 1
      ELSE 0
    END AS is_canceled_30
  FROM cross_join
)
SELECT * FROM status
LIMIT 10;

/* Task 7 -  Create a status_aggregate temporary table that is a SUM of the active and canceled subscriptions for each segment, for each month */
WITH months AS (
  SELECT '2016-12-01' AS first_day, '2016-12-31' AS last_day
  UNION
  SELECT '2017-01-01', '2017-01-31'
  UNION
  SELECT '2017-02-01', '2017-02-28'
  UNION
  SELECT '2017-03-01', '2017-03-31'
),
cross_join AS (
  SELECT subscriptions.*, months.first_day, months.last_day
  FROM subscriptions
  CROSS JOIN months
),
status AS (
  SELECT 
    id, 
    first_day AS month,
    CASE
      WHEN (segment = 87 AND subscription_start < first_day AND (subscription_end > first_day OR subscription_end IS NULL)) THEN 1
      ELSE 0
    END AS is_active_87,
    CASE
      WHEN (segment = 30 AND subscription_start < first_day AND (subscription_end > first_day OR subscription_end IS NULL)) THEN 1
      ELSE 0
    END AS is_active_30,
     CASE
      WHEN (segment = 87) AND (subscription_end BETWEEN first_day AND last_day) THEN 1
      ELSE 0
    END AS is_canceled_87,
    CASE
      WHEN (segment = 30) AND (subscription_end BETWEEN first_day AND last_day) THEN 1
      ELSE 0
    END AS is_canceled_30
  FROM cross_join
),
status_aggregate AS (
  SELECT
  SUM(is_active_87) AS sum_active_87,
  SUM(is_active_30) AS sum_active_30,
  SUM(is_canceled_87) AS sum_canceled_87,
  SUM(is_canceled_30) AS sum_canceled_30
  FROM status
  GROUP BY month
)
SELECT * FROM status_aggregate;

/* Task 8 - Calculate the churn rates for the two segments over the three month period */
-- Create a Month table
WITH months AS (
  SELECT '2016-12-01' AS first_day, '2016-12-31' AS last_day
  UNION
  SELECT '2017-01-01', '2017-01-31'
  UNION
  SELECT '2017-02-01', '2017-02-28'
  UNION
  SELECT '2017-03-01', '2017-03-31'
),
-- Create a Cross Join table of months and subscriptions
cross_join AS (
  SELECT subscriptions.*, months.first_day, months.last_day
  FROM subscriptions
  CROSS JOIN months
),
-- Create a Status table
status AS (
  SELECT 
    id, 
    first_day AS month,
 -- Determine Active Status 
    CASE
      WHEN (segment = 87 AND subscription_start < first_day AND (subscription_end > first_day OR subscription_end IS NULL)) THEN 1
      ELSE 0
    END AS is_active_87,
    CASE
      WHEN (segment = 30 AND subscription_start < first_day AND (subscription_end > first_day OR subscription_end IS NULL)) THEN 1
      ELSE 0
    END AS is_active_30,
-- Determine Canceled Status 
    CASE
      WHEN (segment = 87) AND (subscription_end BETWEEN first_day AND last_day) THEN 1
      ELSE 0
    END AS is_canceled_87,
    CASE
      WHEN (segment = 30) AND (subscription_end BETWEEN first_day AND last_day) THEN 1
      ELSE 0
    END AS is_canceled_30
  FROM cross_join
),
-- Aggregate (SUM) Active and Canceled Users
status_aggregate AS (
  SELECT
    month,
    SUM(is_active_87) AS sum_active_87,
    SUM(is_active_30) AS sum_active_30,
    SUM(is_canceled_87) AS sum_canceled_87,
    SUM(is_canceled_30) AS sum_canceled_30
  FROM status
  GROUP BY month
)
-- Compute churn rates and ratio
SELECT
  month,
  churn_rate_87,
  churn_rate_30,
  ROUND(churn_rate_87 / churn_rate_30, 1) AS churn_rate_ratio
FROM (
  SELECT
    month,
    ROUND(1.0 * sum_canceled_87 / sum_active_87, 2) AS churn_rate_87,
    ROUND(1.0 * sum_canceled_30 / sum_active_30, 2) AS churn_rate_30
  FROM status_aggregate
) AS calculated_rates;
/* segment 30 has a 3 to 4.6 lower churn rate then 87. */

/* Task 9 - modify this code to support a large number of segments */
/* Solution: aggregate data in a way that can handle any number of segments dynamically by using groupings and conditional aggregations. */
WITH months AS (
  SELECT '2016-12-01' AS first_day, '2016-12-31' AS last_day
  UNION
  SELECT '2017-01-01', '2017-01-31'
  UNION
  SELECT '2017-02-01', '2017-02-28'
  UNION
  SELECT '2017-03-01', '2017-03-31'
),
cross_join AS (
  SELECT subscriptions.*, months.first_day, months.last_day
  FROM subscriptions
  CROSS JOIN months
),
status AS (
  SELECT 
    id, 
    first_day AS month,
    segment,
    CASE
      WHEN subscription_start < first_day AND (subscription_end > first_day OR subscription_end IS NULL) THEN 1
      ELSE 0
    END AS is_active,
    CASE
      WHEN subscription_end BETWEEN first_day AND last_day THEN 1
      ELSE 0
    END AS is_canceled
  FROM cross_join
),
status_aggregate AS (
  SELECT
    month,
    segment,
    SUM(is_active) AS sum_active,
    SUM(is_canceled) AS sum_canceled
  FROM status
  GROUP BY month, segment
)
SELECT
  month,
  segment,
  ROUND(1.0 * sum_canceled / sum_active, 2) AS churn_rate
FROM status_aggregate
ORDER BY month, segment;