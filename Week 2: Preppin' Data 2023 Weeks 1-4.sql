-- Preppin' Data 2023 Week 01

-- Split the Transaction Code to extract the letters at the start of the transaction code. These identify the bank who processes the transaction 
    -- Rename the new field with the Bank code 'Bank'. 
-- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values. 
-- Change the date to be the day of the week
-- Different levels of detail are required in the outputs. You will need to sum up the values of the transactions in three ways:
    -- 1. Total Values of Transactions by each bank
    -- 2. Total Values by Bank, Day of the Week and Type of Transaction (Online or In-Person)
    -- 3. Total Values by Bank and Customer Code

-- 1. Total Values of Transactions by each bank
SELECT REGEXP_SUBSTR(transaction_code, '^[A-Z]{2,3}') AS bank,
SUM(value) AS value
FROM PD2023_WK01
GROUP BY bank

-- 2. Total Values by Bank, Day of the Week and Type of Transaction (Online or In-Person)
SELECT REGEXP_SUBSTR(transaction_code, '^[A-Z]{2,3}') AS bank,
CASE WHEN online_or_in_person = 1 THEN 'Online' ELSE 'In-Person' END AS online_or_in_person,
    CASE WHEN DAYNAME(TO_DATE(LEFT(transaction_date,10), 'DD/MM/YYYY')) = 'Mon' THEN 'Monday'
         WHEN DAYNAME(TO_DATE(LEFT(transaction_date,10), 'DD/MM/YYYY')) = 'Tue' THEN 'Tuesday'
         WHEN DAYNAME(TO_DATE(LEFT(transaction_date,10), 'DD/MM/YYYY')) = 'Wed' THEN 'Wednesday'
         WHEN DAYNAME(TO_DATE(LEFT(transaction_date,10), 'DD/MM/YYYY')) = 'Thu' THEN 'Thursday'
         WHEN DAYNAME(TO_DATE(LEFT(transaction_date,10), 'DD/MM/YYYY')) = 'Fri' THEN 'Friday'
         WHEN DAYNAME(TO_DATE(LEFT(transaction_date,10), 'DD/MM/YYYY')) = 'Sat' THEN 'Saturday'
         ELSE 'Sunday' END AS transaction_date,
SUM(value) AS value
FROM PD2023_WK01
GROUP BY 1,2,3

-- 3. Total Values by Bank and Customer Code
SELECT REGEXP_SUBSTR(transaction_code, '^[A-Z]{2,3}') AS bank,
customer_code,

-- Preppin' Data 2023 Week 02

-- In the Transactions table, there is a Sort Code field which contains dashes. We need to remove these so just have a 6 digit string
-- Use the SWIFT Bank Code lookup table to bring in additional information about the SWIFT code and Check Digits of the receiving bank account
-- Add a field for the Country Code
      -- Hint: all these transactions take place in the UK so the Country Code should be GB
-- Create the IBAN as above
      -- Hint: watch out for trying to combine string fields with numeric fields - check data types
-- Remove unnecessary fields

SELECT transaction_id, 'GB' || check_digits || swift_code || REPLACE(sort_code,'-','') || account_number AS IBAN
FROM PD2023_WK02_TRANSACTIONS AS T
JOIN PD2023_WK02_SWIFT_CODES AS C
ON T.bank = C.bank
SUM(value) AS value
FROM PD2023_WK01
GROUP BY 1,2

-- Preppin' Data 2023 Week 03

-- For the transactions file:
    -- Filter the transactions to just look at DSB (help)
        -- These will be transactions that contain DSB in the Transaction Code field
    -- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values
    -- Change the date to be the quarter (help)
    -- Sum the transaction values for each quarter and for each Type of Transaction (Online or In-Person) (help)
-- For the targets file:
    -- Pivot the quarterly targets so we have a row for each Type of Transaction and each Quarter (help)
    -- Rename the fields
    -- Remove the 'Q' from the quarter field and make the data type numeric (help)
-- Join the two datasets together (help)
    -- You may need more than one join clause!
-- Remove unnecessary fields
-- Calculate the Variance to Target for each row WITH CTE AS(
SELECT CASE WHEN online_or_in_person = 1 THEN 'Online' ELSE 'In-Person' END AS online_or_in_person,
QUARTER(TO_DATE(transaction_date, 'DD/MM/YYYY hh24:mi:ss')) AS quarter,
SUM(value) AS value
FROM PD2023_WK01
WHERE SPLIT_PART(transaction_code,'-',1) = 'DSB'
GROUP BY 1,2
)

SELECT T.online_or_in_person, REPLACE(T.quarter,'Q','') AS quarter, target, (value - target) AS variance_to_target
FROM PD2023_WK03_TARGETS AS T
UNPIVOT(target FOR quarter IN(Q1,Q2,Q3,Q4))
INNER JOIN CTE AS P 
ON T.online_or_in_person = P.online_or_in_person
AND REPLACE(T.quarter,'Q','') = P.quarter

-- Preppin' Data 2023 Week 04

-- We want to stack the tables on top of one another, since they have the same fields in each sheet. We can do this one of 2 ways:
    -- Drag each table into the canvas and use a union step to stack them on top of one another
    -- Use a wildcard union in the input step of one of the tables
-- Some of the fields aren't matching up as we'd expect, due to differences in spelling. Merge these fields together
-- Make a Joining Date field based on the Joining Day, Table Names and the year 2023
-- Now we want to reshape our data so we have a field for each demographic, for each new customer (help)
-- Make sure all the data types are correct for each field
-- Remove duplicates (help)
    -- If a customer appears multiple times take their earliest joining date
WITH CTE AS (
SELECT *, 'PD2023_WK04_JANUARY' AS tablename FROM PD2023_WK04_JANUARY

UNION ALL
SELECT *, 'PD2023_WK04_FEBRUARY' AS tablename FROM PD2023_WK04_FEBRUARY

UNION ALL
SELECT *, 'PD2023_WK04_MARCH' AS tablename FROM PD2023_WK04_MARCH

UNION ALL
SELECT *, 'PD2023_WK04_APRIL' AS tablename FROM PD2023_WK04_APRIL

UNION ALL
SELECT *, 'PD2023_WK04_MAY' AS tablename FROM PD2023_WK04_MAY

UNION ALL
SELECT *, 'PD2023_WK04_JUNE' AS tablename FROM PD2023_WK04_JUNE

UNION ALL
SELECT *, 'PD2023_WK04_JULY' AS tablename FROM PD2023_WK04_JULY

UNION ALL
SELECT *, 'PD2023_WK04_AUGUST' AS tablename FROM PD2023_WK04_AUGUST

UNION ALL
SELECT *, 'PD2023_WK04_SEPTEMBER' AS tablename FROM PD2023_WK04_SEPTEMBER

UNION ALL
SELECT *, 'PD2023_WK04_OCTOBER' AS tablename FROM PD2023_WK04_OCTOBER

UNION ALL
SELECT *, 'PD2023_WK04_NOVEMBER' AS tablename FROM PD2023_WK04_NOVEMBER

UNION ALL
SELECT *, 'PD2023_WK04_DECEMBER' AS tablename FROM PD2023_WK04_DECEMBER
)
,

PRE_PIVOT AS (
SELECT id, TO_VARCHAR(TO_DATE(joining_day || '/' || SPLIT_PART(tablename,'_',3) || '/2023', 'DD/MON/YYYY'), 'DD/MM/YYYY') AS joining_date,
demographic, value
FROM CTE
)
, 

POST_PIVOT AS (
SELECT id, joining_date, ethnicity, account_type, CAST(date_of_birth AS date) AS date_of_birth,
ROW_NUMBER() OVER(PARTITION BY id ORDER BY joining_date ASC) AS rn
FROM PRE_PIVOT
PIVOT(MAX(value) FOR demographic IN ('Ethnicity','Account Type','Date of Birth')) AS P
(id, joining_date, ethnicity, account_type, date_of_birth)
)

SELECT id, joining_date, account_type, date_of_birth, ethnicity
FROM POST_PIVOT
WHERE rn = 1
