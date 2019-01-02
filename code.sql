--All the questions will start with a comment section given a short description about the question
--All comment blocks will start with an indicator which question it is.
--E.g. question one will have the indicator [1/10] meaning, question 1 from the total 10 questions.

--[1/10] Here I have taken a look at the first 100 rows of data and determine which segments 
--are present in the table. The segment has either the value 87 or 30. Thus, there are two
--different segments.

SELECT *
FROM subscriptions
LIMIT 100;

--[2/10] Here I have taken the minimum of subscription_start the find the first month, and the maximum --value of subscription_end to find the latest month. The first date is the 1st of December 2016 and
--the latest date is 31st of March 2017. Thus, the date range in months is 4 months. I will be able
--to calculate the churn rate over the months January 2017, February 2017, and March 2017. I can't
--calculate the churn rate for Decemner 2016, because the December months have a NULL value for
--subscription_end

SELECT MIN(subscription_start), MAX(subscription_end)
FROM subscriptions;

--[3/10] To calculate the churn rate for both segments over the first three months of 2017. I created
-- a temporary months table to get started with this. The table contains the temporary 
--first_day column and last_day column for the first three months of 2017.

WITH months AS
(SELECT
  '2017-01-01' AS first_day,
  '2017-01-31' AS last_day
UNION
SELECT
  '2017-02-01' AS first_day,
  '2017-02-28' AS last_day
UNION
SELECT
  '2017-03-01' AS first_day,
  '2017-03-31' AS last_day
),

--[4/10]The following query will cross join the subscriptions table with the months table.

cross_join AS
(SELECT subscriptions.*, months.*
FROM subscriptions
CROSS JOIN months),

--[5/10]The following query will create a temporay status table with the cross_join table. It will
-- have case statements who check which IDs have an active status (1 = yes, 0 = no).
--[6/10]Added two case statements that check if the subscription is canceled (1 = yes, 0 = no).
--[7/10]Added a temporay table (status_aggregate) that sums the active and canceled status per
--segment per month.
--[8/10] Added the churn rate calculations to calculate the churn rate per month and per segment. I 
--used the temporay table (status_aggregate), because this table had summed it per month and per
--segment. The 1.0 multiplier is so that the result will be shown as a number.
--[9/10]I didn't hardcode the segments, per added a group by to solve this.
--[10/10] Done did it!

status AS
(SELECT id, first_day as month, segment,
	CASE
  	WHEN (subscription_start < first_day)
      AND (
     	 subscription_end > first_day
      	OR subscription_end IS NULL
   	 			) 
      THEN 1
    	ELSE 0
  END as is_active,
  CASE
 		WHEN (subscription_end BETWEEN first_day AND last_day)
 			THEN 1
 			ELSE 0
 	END AS is_canceled
	FROM cross_join),
  status_aggregate AS (
    SELECT month, segment,
    SUM(is_active) AS sum_active,
    SUM(is_canceled) AS sum_canceled
    FROM status
    GROUP BY month, segment
  )
  SELECT month, segment,
  1.0 * sum_canceled / sum_active AS churn_rate
  FROM status_aggregate;