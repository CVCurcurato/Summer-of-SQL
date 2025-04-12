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
SELECT DATE_TRUNC('month',start_date), COUNT(DISTINCT customer_id)
FROM subscriptions
WHERE plan_id = 0
GROUP BY 1
ORDER BY 1
