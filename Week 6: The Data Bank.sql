-- 1. How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes

-- 2. What is the number of nodes per region?

SELECT region_name,
    R.region_id, 
    COUNT(node_id) AS nodes_per_region
FROM customer_nodes AS C
INNER JOIN regions AS R
    ON C.region_id = R.region_id
GROUP BY 1,2

-- 3. How many customers are allocated to each region?
SELECT region_name,
COUNT(DISTINCT customer_id) AS customers_per_region
FROM customer_nodes AS C
INNER JOIN regions AS R
    ON C.region_id = R.region_id
GROUP BY 1

-- 4. How many days on average are customers reallocated to a different node?
WITH datedifference AS (
SELECT customer_id,
node_id,
SUM(DATEDIFF(day, start_date, end_date)) AS date_diff
FROM customer_nodes
WHERE end_date != '9999-12-31'
GROUP BY 1,2
)

SELECT ROUND(AVG(date_diff),1)
FROM datedifference

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH datedifference AS (
SELECT region_name,
customer_id,
node_id,
SUM(DATEDIFF(day, start_date, end_date)) AS date_diff
FROM customer_nodes AS C
INNER JOIN regions AS R
    ON R.region_id = C.region_id
WHERE end_date != '9999-12-31'
GROUP BY 1,2,3
),

ordered AS(
SELECT region_name, 
date_diff,
ROW_NUMBER() OVER(PARTITION BY region_name ORDER BY date_diff) AS rn
FROM datedifference
),

max_rows AS (
SELECT
region_name,
MAX(rn) AS max_rn
FROM ordered
GROUP BY region_name
)

SELECT O.region_name,
date_diff AS days_in_node,
CASE WHEN rn = ROUND(M.max_rn * 0.50) THEN 'Median'
     WHEN rn = ROUND(M.max_rn * 0.80) THEN '80th Percentile'
     WHEN rn = ROUND(M.max_rn * 0.95) THEN '95th Percentile'
     END AS metric
FROM ordered AS O
INNER JOIN max_rows AS M
ON M.region_name = O.region_name
WHERE rn IN (
    ROUND(M.max_rn * 0.50),
    ROUND(M.max_rn * 0.80),
    ROUND(M.max_rn * 0.95)
)
