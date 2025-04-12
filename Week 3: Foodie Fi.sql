--A. CUSTOMER JOURNEY

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
