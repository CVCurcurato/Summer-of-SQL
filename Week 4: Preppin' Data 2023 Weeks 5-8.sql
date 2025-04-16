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
