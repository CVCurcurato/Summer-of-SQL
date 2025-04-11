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
