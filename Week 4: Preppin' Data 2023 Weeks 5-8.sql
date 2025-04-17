-- Preppin' Data 2023 Week 05

-- Create the bank code by splitting out off the letters from the Transaction code, call this field 'Bank'
-- Change transaction date to the just be the month of the transaction
-- Total up the transaction values so you have one row for each bank and month combination
-- Rank each bank for their value of transactions each month against the other banks. 1st is the highest value of transactions, 3rd the lowest. 
-- Without losing all of the other data fields, find:
--     - The average rank a bank has across all of the months, call this field 'Avg Rank per Bank'
--     - The average transaction value per rank, call this field 'Avg Transaction Value per Rank'
WITH ranked AS(
SELECT 
    CASE WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 1 THEN 'January'
    WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 2 THEN 'February'
    WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 3 THEN 'March'
    WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 4 THEN 'April'
    WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 5 THEN 'May'
    WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 6 THEN 'June'
    WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 7 THEN 'July'
    WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 8 THEN 'August'
    WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 9 THEN 'September'
    WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 10 THEN 'October'
    WHEN DATE_PART('month', TO_DATE(transaction_date,'DD/MM/YYYY hh24:mi:ss')) = 11 THEN 'November'
        ELSE 'December' END AS transaction_month,
    SPLIT_PART(transaction_code,'-',1) AS bank,
    SUM(value) AS total_value,
    RANK() OVER(PARTITION BY transaction_month ORDER BY SUM(value) DESC) monthly_rank
FROM pd2023_wk01
GROUP BY bank,transaction_month
)

SELECT *, 
AVG(total_value) OVER(PARTITION BY monthly_rank ORDER BY monthly_rank),
AVG(monthly_rank) OVER(PARTITION BY bank ORDER BY bank)
FROM ranked
GROUP BY 1,2,3,4

-- Preppin' Data 2023 Week 06

-- Reshape the data so we have 5 rows for each customer, with responses for the Mobile App and Online Interface being in separate fields on the same row
-- Clean the question categories so they don't have the platform in from of them
--     - e.g. Mobile App - Ease of Use should be simply Ease of Use
-- Exclude the Overall Ratings, these were incorrectly calculated by the system
-- Calculate the Average Ratings for each platform for each customer 
-- Calculate the difference in Average Rating between Mobile App and Online Interface for each customer
-- Catergorise customers as being:
--     - Mobile App Superfans if the difference is greater than or equal to 2 in the Mobile App's favour
--     - Mobile App Fans if difference >= 1
--     - Online Interface Fan
--     - Online Interface Superfan
--     - Neutral if difference is between 0 and 1
-- Calculate the Percent of Total customers in each category, rounded to 1 decimal place

WITH pre_pivot AS (
SELECT customer_id, 
    SPLIT_PART(pivot_columns,'___',1) AS mobile,
    SPLIT_PART(pivot_columns,'___',2) AS online,
    value
FROM
(
SELECT *
FROM pd2023_wk06_dsb_customer_survey
) AS src
UNPIVOT (
value FOR pivot_columns IN (
MOBILE_APP___EASE_OF_USE, MOBILE_APP___EASE_OF_ACCESS, MOBILE_APP___NAVIGATION, MOBILE_APP___LIKELIHOOD_TO_RECOMMEND, MOBILE_APP___OVERALL_RATING, ONLINE_INTERFACE___EASE_OF_USE, ONLINE_INTERFACE___EASE_OF_ACCESS, ONLINE_INTERFACE___NAVIGATION, ONLINE_INTERFACE___LIKELIHOOD_TO_RECOMMEND,
ONLINE_INTERFACE___OVERALL_RATING
)) AS pvt

),

formatted_data AS (
SELECT *
FROM pre_pivot
PIVOT (SUM(value) FOR mobile IN ('MOBILE_APP', 'ONLINE_INTERFACE')) AS p
WHERE online != 'OVERALL_RATING'
),

categorized AS (
SELECT customer_id,
    AVG("'MOBILE_APP'"),
    AVG("'ONLINE_INTERFACE'"),
    AVG("'MOBILE_APP'") - AVG("'ONLINE_INTERFACE'") AS difference_in_ratings,
    CASE 
    WHEN AVG("'MOBILE_APP'") - AVG("'ONLINE_INTERFACE'") >= 2 THEN 'Mobile App Superfans'
    WHEN AVG("'MOBILE_APP'") - AVG("'ONLINE_INTERFACE'") >= 1 THEN 'Mobile App Fans'
    WHEN AVG("'MOBILE_APP'") - AVG("'ONLINE_INTERFACE'") <= -2 THEN 'Online Interface Superfans'
    WHEN AVG("'MOBILE_APP'") - AVG("'ONLINE_INTERFACE'") <= -1 THEN 'Online Interface Fans'
    ELSE 'Neutral'
END as fan_category
FROM formatted_data
GROUP BY 1
)

SELECT 
fan_category as preference,
ROUND((COUNT(customer_id) / (SELECT COUNT(customer_id) FROM categorized))*100,1) as percent_of_customers
FROM categorized
GROUP BY fan_category
