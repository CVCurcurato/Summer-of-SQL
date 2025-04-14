--A. Customer Journey
--Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
--Briefly describe the first 8 customers’ onboarding journey.
SELECT plan_name, price, customer_id, start_date,
    CASE WHEN customer_id = 1 THEN 'Customer switched to basic sub after trial'
    WHEN customer_id = 2 THEN 'Customer switched to pro sub after trial'
    WHEN customer_id = 3 THEN 'Customer switched to basic sub after trial'
    WHEN customer_id = 4 THEN 'Customer switched to basic sub after trial, then attritioned after ~3 months'
    WHEN customer_id = 5 THEN 'Customer switched to basic sub after trial'
    WHEN customer_id = 6 THEN 'Customer switched to basic sub after trial, then attritioned after ~2 months'
    WHEN customer_id = 7 THEN 'Customer switched to basic sub after trial, then pro sub after ~3 months'
    WHEN customer_id = 8 THEN 'Customer switched to basic sub after trial, then pro sub after ~2 months'
    ELSE '' END AS onboarding_description
FROM plans AS P
INNER JOIN subscriptions AS S
ON P.plan_id = S.plan_id
WHERE customer_id <= 8

--B. Data Analysis Questions

-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id)
FROM subscriptions
-- Result, 1000 customers

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
-- Since the wording is odd, I have interpreted this to mean what is the count of customers starting a trial each month
SELECT DATE_TRUNC('month',start_date), COUNT(customer_id) AS count_of_customers
FROM subscriptions
WHERE plan_id = 0
GROUP BY 1
ORDER BY 1

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT P.plan_name, COUNT(*) AS count_of_events
FROM subscriptions AS S
INNER JOIN plans AS P
    ON S.plan_id = P.plan_id
WHERE start_date > DATE('2020-12-31')
GROUP BY 1

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(DISTINCT customer_id) AS total_customers_count,
    SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) AS customers_churned_count,
    ROUND(SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END)  * 100 / COUNT(DISTINCT customer_id),1) AS percentage_of_churn
FROM subscriptions

-- 4. Alternative Solution using subqueries
SELECT COUNT(DISTINCT customer_id) AS total_customers_count,
(SELECT COUNT(DISTINCT customer_id) FROM subscriptions WHERE plan_id = 4) AS customers_churned_count,
ROUND((SELECT COUNT(DISTINCT customer_id) FROM subscriptions WHERE plan_id = 4) * 100 / total_customers_count,1) AS percentage_of_churn
FROM subscriptions

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH numbered AS (
SELECT *, COUNT(DISTINCT customer_id) AS total_customers, LEAD(plan_id, 1, 999) OVER(PARTITION BY customer_id ORDER BY start_date ASC) AS next_rownumber
FROM subscriptions
GROUP BY 1,2,3
ORDER BY customer_id, start_date ASC
)

SELECT COUNT(customer_id) AS churned_after_trial, ROUND(COUNT(customer_id) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) AS percentage
FROM numbered
WHERE next_rownumber = 4
AND plan_id = 0
ORDER BY customer_id, start_date ASC
    
-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH numbered AS (
SELECT P.plan_name, S.plan_id, customer_id, start_date, COUNT(DISTINCT customer_id) AS total_customers, 
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date ASC) AS rownumber
FROM subscriptions AS S
INNER JOIN plans AS P
    ON S.plan_id = P.plan_id
GROUP BY 1,2,3,4
ORDER BY customer_id, start_date ASC
)

SELECT plan_name, plan_id, COUNT(DISTINCT customer_id) AS customers_retained, ROUND(COUNT(DISTINCT customer_id) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),1) AS percentage
FROM numbered
WHERE rownumber = 2
GROUP BY 1,2
ORDER BY plan_id ASC
