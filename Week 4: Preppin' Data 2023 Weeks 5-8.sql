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

-- Preppin' Data 2023 Week 07

-- For the Transaction Path table:
--     - Make sure field naming convention matches the other tables
--         - i.e. instead of Account_From it should be Account From
-- For the Account Information table:
--     - Make sure there are no null values in the Account Holder ID
--     - Ensure there is one row per Account Holder ID
--         - Joint accounts will have 2 Account Holders, we want a row for each of them
-- For the Account Holders table:
--     - Make sure the phone numbers start with 07
-- Bring the tables together
-- Filter out cancelled transactions 
-- Filter to transactions greater than £1,000 in value 
-- Filter out Platinum accounts

WITH ACC as (
SELECT account_number, account_type,
value as account_holder_id, 
balance_date, balance,
FROM pd2023_wk07_account_information, LATERAL SPLIT_TO_TABLE(account_holder_id,', ')
WHERE account_holder_id IS NOT NULL
)
SELECT D.transaction_id, account_to, transaction_date, value, 
account_number, account_type, balance_date, balance,
name, date_of_birth,
'0' || contact_number::varchar(20) as contact_number,
first_line_of_address
FROM pd2023_wk07_transaction_detail as D
INNER JOIN pd2023_wk07_transaction_path as P ON D.transaction_id = P.transaction_id
INNER JOIN ACC on ACC.account_number = P.account_from
INNER JOIN pd2023_wk07_account_holders as H ON H.account_holder_id = ACC.account_holder_id
WHERE cancelled_ = 'N'
AND value > 1000
AND account_type <> 'Platinum'

-- Preppin' Data 2023 Week 08

-- Create a 'file date' using the month found in the file name
--     - The Null value should be replaced as 1
-- Clean the Market Cap value to ensure it is the true value as 'Market Capitalisation'
--     - Remove any rows with 'n/a'
-- Categorise the Purchase Price into groupings
    -- 0 to 24,999.99 as 'Low'
    -- 25,000 to 49,999.99 as 'Medium'
    -- 50,000 to 74,999.99 as 'High'
    -- 75,000 to 100,000 as 'Very High'
-- Categorise the Market Cap into groupings
    -- Below $100M as 'Small'
    -- Between $100M and below $1B as 'Medium'
    -- Between $1B and below $100B as 'Large' 
    -- $100B and above as 'Huge'
-- Rank the highest 5 purchases per combination of: file date, Purchase Price Categorisation and Market Capitalisation Categorisation.
-- Output only records with a rank of 1 to 5

WITH stocks AS (
SELECT *, TO_DATE('2023-01-01') AS file_date FROM pd2023_wk08_01
UNION ALL
SELECT *, TO_DATE('2023-02-01') AS file_date FROM pd2023_wk08_02
UNION ALL
SELECT *, TO_DATE('2023-03-01') AS file_date FROM pd2023_wk08_03
UNION ALL
SELECT *, TO_DATE('2023-04-01') AS file_date FROM pd2023_wk08_04
UNION ALL
SELECT *, TO_DATE('2023-05-01') AS file_date FROM pd2023_wk08_05
UNION ALL
SELECT *, TO_DATE('2023-06-01') AS file_date FROM pd2023_wk08_06
UNION ALL
SELECT *, TO_DATE('2023-07-01') AS file_date FROM pd2023_wk08_07
UNION ALL
SELECT *, TO_DATE('2023-08-01') AS file_date FROM pd2023_wk08_08
UNION ALL
SELECT *, TO_DATE('2023-09-01') AS file_date FROM pd2023_wk08_09
UNION ALL
SELECT *, TO_DATE('2023-10-01') AS file_date FROM pd2023_wk08_10
UNION ALL
SELECT *, TO_DATE('2023-11-01') AS file_date FROM pd2023_wk08_11
UNION ALL
SELECT *, TO_DATE('2023-12-01') AS file_date FROM pd2023_wk08_12

),
step1 AS (
SELECT *, 
REPLACE(purchase_price, '$', '') AS price,
REPLACE(REPLACE(REPLACE(market_cap, '$', ''),'M',''),'B','') AS value,

CASE WHEN RIGHT(market_cap, 1) = 'M' THEN value * 1000000 
     WHEN RIGHT(market_cap, 1) = 'B' THEN value * 1000000000 
     ELSE 0 END AS market_capitalization,
     
CASE WHEN price >= 0 AND price <= 24999.99 THEN 'Low'
     WHEN price >= 25000 AND price <= 44999.99 THEN 'Medium'
     WHEN price >= 50000 AND price <= 74999.99 THEN 'High' 
     ELSE 'Very High' END AS purchase_price_group,


CASE WHEN market_capitalization < 100000000  THEN 'Small'
     WHEN market_capitalization >= 100000000 AND market_capitalization < 1000000000 THEN 'Medium'
     WHEN market_capitalization >= 1000000000 AND market_capitalization < 100000000000 THEN 'Large'
     ELSE 'Huge' END AS market_capitalization_group


FROM stocks
WHERE market_cap != 'n/a'
),

step2 AS (
SELECT market_capitalization_group,
purchase_price_group,
file_date,
ticker,
sector,
market,
stock_name,
market_capitalization,
price AS purchase_price,
RANK() OVER(PARTITION BY file_date, market_capitalization_group, purchase_price_group ORDER BY purchase_price DESC) AS rank
FROM step1
)

SELECT *
FROM step2
WHERE rank <= 5
AND file_date = '2023-10-01'
