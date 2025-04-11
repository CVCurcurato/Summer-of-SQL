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
