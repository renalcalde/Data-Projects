
/*
8 WEEK SQL CHALLENGE:
Case Study #4 - Data Bank
*/

-- A. Customer Nodes Exploration
-- Q1
SELECT COUNT(DISTINCT node_id) FROM customer_nodes;

-- Q2
SELECT 
    r.region_name,
    COUNT(DISTINCT n.node_id)
FROM customer_nodes n
INNER JOIN regions r
    ON n.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;

-- Q3
SELECT 
    r.region_name,
    COUNT(DISTINCT n.customer_id)
FROM customer_nodes n
INNER JOIN regions r
    ON n.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;

-- Q4
-- Step 1
SELECT 
    MIN(start_date),
    MAX(end_date)
FROM customer_nodes;

-- Step 2
SELECT 
    DISTINCT(end_date)
FROM customer_nodes
ORDER BY end_date DESC;

-- Step 3
SELECT 
    ROUND(AVG(end_date - start_date),2) AS avg_days
FROM customer_nodes
WHERE end_date != '9999-12-31';


-- Q5
WITH days_cte AS(
    SELECT 
        region_id,
        customer_id,
        (end_date - start_date) AS days
    FROM customer_nodes
    WHERE end_date != '9999-12-31'
    GROUP BY region_id, customer_id, end_date, start_date
)
SELECT
    r.region_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY d.days) AS median,
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY d.days) AS percentile_80,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d.days) AS percentile_95
FROM days_cte d
INNER JOIN regions r
    ON d.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;

-- B. Customer Transactions
-- Q1
SELECT 
    txn_type,
    COUNT(txn_type),
    SUM(txn_amount)
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type;

-- Q2
WITH deposit_cte AS(
    SELECT 
        customer_id,
        COUNT(txn_type) AS depo_count,
        SUM(txn_amount) AS depo_sum,
        AVG(txn_amount) AS depo_avg
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT
    ROUND(AVG(depo_count),2) AS deposit_count,
    ROUND(AVG(depo_avg),2) AS deposit_average,
    ROUND(AVG(depo_sum),2) AS deposit_amount
FROM deposit_cte;

-- Q3
WITH count_cte AS(
    SELECT
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        TO_CHAR(txn_date, 'MON') AS month_name, 
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM customer_transactions
    GROUP BY customer_id, month_name, month
)
SELECT
    month_name,
    COUNT(*)
FROM count_cte
WHERE deposit_count > 1 AND (purchase_count = 1 OR withdrawal_count = 1)
GROUP BY month_name, month
ORDER BY month;

-- Q4
WITH RECURSIVE cte AS(
    SELECT
        customer_id,
        (DATE_TRUNC('month', d.min_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE AS start_month_end,
        (DATE_TRUNC('month', d.max_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE AS end_month_end
    FROM (SELECT DISTINCT customer_id FROM customer_transactions) c
    CROSS JOIN (
        SELECT MIN(txn_date) AS min_date, MAX(txn_date) AS max_date
        FROM customer_transactions
    ) d
),
cte2 AS(
    SELECT
        customer_id,
        start_month_end AS month_end,
        end_month_end
    FROM cte

    UNION ALL

    SELECT
        customer_id,
        (DATE_TRUNC('month', month_end + INTERVAL '1 day') + INTERVAL '1 month' - INTERVAL '1 day')::DATE,
        end_month_end
    FROM cte2
    WHERE month_end < end_month_end
),
cte3 AS(
    SELECT
        customer_id,
        (DATE_TRUNC('month', txn_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE AS month_end,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, DATE_TRUNC('month', txn_date)
),
cte4 AS (
    SELECT
        c2.customer_id,
        c2.month_end,
        COALESCE(c3.net_change, 0) AS net_change,
        SUM(COALESCE(c3.net_change, 0)) OVER(PARTITION BY c2.customer_id ORDER BY c2.month_end) AS closing_balance
    FROM cte2 c2
    LEFT JOIN cte3 c3
        ON c3.customer_id = c2.customer_id
        AND c3.month_end = c2.month_end
)
SELECT * 
FROM cte4
ORDER BY customer_id, month_end;

-- Q5
WITH cte AS(
    SELECT
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        TO_CHAR(txn_date, 'MON') AS month_end,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, month, month_end
),
cte2 AS(
    SELECT
        customer_id,
        month_end,
        month,
        SUM(net_change) OVER(PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM cte
    GROUP BY customer_id, month_end, month, net_change
),
cte3 AS(
    SELECT
        customer_id,
        month_end,
        closing_balance,
        100 *(closing_balance - LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY	month))
            / NULLIF( LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY	month), 0) AS percentage_increase
    FROM cte2
    GROUP BY customer_id, month_end, month, closing_balance
)
SELECT
    100 * COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions)::FLOAT AS percentage
FROM cte3
WHERE percentage_increase > 5;

-- C. Data Allocation Challenge
-- Option 1
WITH cte AS(
    SELECT 
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        TO_CHAR(txn_date, 'MON') AS month_end,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, month, month_end
),
cte2 AS(
    SELECT
        *,
        SUM(net_change) OVER(PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM cte
),
cte3 AS(
    SELECT
        *,
        LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY customer_id, month) AS running_balance
    FROM cte2
)
SELECT
    month_end,
    SUM(COALESCE(CASE WHEN running_balance < 0 THEN 0 ELSE running_balance END, 0)) AS data_allocated
FROM cte3
GROUP BY month_end, month
ORDER BY month;

-- Option 2
WITH cte AS(
    SELECT 
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        TO_CHAR(txn_date, 'MON') AS month_end,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, month, month_end
),
cte2 AS(
    SELECT
        *,
        SUM(net_change) OVER(PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM cte
),
cte3 AS(
    SELECT
        *,
        AVG(closing_balance) OVER (PARTITION BY customer_id ORDER BY customer_id, month) AS running_balance
    FROM cte2
)
SELECT
    month_end,
    ROUND(SUM(CASE WHEN running_balance < 0 THEN 0 ELSE running_balance END), 0) AS data_allocated
FROM cte3
GROUP BY month_end, month
ORDER BY month;

-- Option 3
WITH cte AS(
    SELECT 
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        TO_CHAR(txn_date, 'MON') AS month_end,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, month, month_end
),
cte2 AS(
    SELECT
        *,
        SUM(net_change) OVER(PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM cte
)
SELECT
    month_end,
    SUM(CASE WHEN closing_balance < 0 THEN 0 ELSE closing_balance END) AS data_allocated
FROM cte2
GROUP BY month_end, month
ORDER BY month;
