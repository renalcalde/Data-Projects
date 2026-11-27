
/* 8 WEEK SQL CHALLENGE: Case Study #7 - Balanced Tree Clothing Co. */

-- D. Reporting Challenge

-- resets views and tables whenever month changes
DROP VIEW IF EXISTS monthly_report_sales CASCADE;
DROP TABLE IF EXISTS report_month CASCADE;
DROP VIEW IF EXISTS full_sales CASCADE;

-- combines sales and product_details
CREATE OR REPLACE VIEW full_sales AS
SELECT
    s.prod_id,
    s.qty,
    s.price,
    s.discount,
    s.member,
    s.txn_id,
    s.start_txn_time,
    DATE_TRUNC('month', s.start_txn_time)::DATE AS txn_month,
    d.product_id,
    d.product_name,
    d.category_id,
    d.segment_id,
    d.style_id,
    d.category_name,
    d.segment_name,
    d.style_name
FROM sales s 
INNER JOIN product_details d
    ON s.prod_id = d.product_id;

-- creates the monthly filter on the sales
CREATE TEMP TABLE report_month AS
SELECT DATE '2021-01-01' AS month; -->> CHANGE THE MONTH HERE <<--

-- filters result to the according month
CREATE TEMP VIEW monthly_report_sales AS 
SELECT * 
FROM full_sales fs
INNER JOIN report_month rm
    ON fs.txn_month = rm.month;

-- =====================================================================

-- A. High Level Sales Analysis
-- Q1
SELECT SUM(qty) AS total_qty FROM monthly_report_sales;

-- Q2
SELECT
    ROUND(SUM(qty * price), 2) AS gross_revenue
FROM monthly_report_sales;

-- Q3
SELECT 
    ROUND(SUM(price * (discount / 100.0) * qty), 2) AS total_discount_amt
FROM monthly_report_sales;

-- B. Transaction Analysis
-- Q1
SELECT COUNT(DISTINCT txn_id) AS total_txn FROM sales;

-- Q2
WITH count_cte AS(
    SELECT 
        txn_id,
        COUNT(DISTINCT prod_id) AS product_count
    FROM monthly_report_sales
    GROUP BY txn_id
)
SELECT
    ROUND(AVG(product_count)) AS avg_product_count
FROM count_cte;

-- Q3
WITH revenue_cte AS(
    SELECT
        txn_id,
        SUM(qty * price) AS revenue
    FROM monthly_report_sales
    GROUP BY txn_id
)
SELECT
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue)::NUMERIC, 2) AS percentile_25,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue)::NUMERIC, 2) AS percentile_50,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue)::NUMERIC, 2) AS percentile_75
FROM revenue_cte;

-- Q4
WITH discount_cte AS(
    SELECT
        txn_id,
        SUM(price * (discount / 100.0) * qty) AS total_discount_amt
    FROM monthly_report_sales
    GROUP BY txn_id
)
SELECT
    ROUND(AVG(total_discount_amt), 2) AS avg_discount_val
FROM discount_cte;

-- Q5
SELECT 
    CASE
        WHEN member = TRUE THEN 'member'
        WHEN member = FALSE THEN 'non-member'
        ELSE NULL 
    END AS member_type,
    ROUND(COUNT(member)::NUMERIC * 100.0 / (SELECT COUNT(member) FROM sales), 2) AS pct
FROM monthly_report_sales
GROUP BY     
    CASE
        WHEN member = TRUE THEN 'member'
        WHEN member = FALSE THEN 'non-member'
        ELSE NULL 
    END;

-- Q6
WITH revenue_cte AS(
SELECT 
    CASE
        WHEN member = TRUE THEN 'member'
        WHEN member = FALSE THEN 'non-member'
        ELSE NULL 
    END AS member_type,
    txn_id,
    SUM(qty * price) AS revenue
FROM monthly_report_sales
GROUP BY txn_id,     
    CASE
        WHEN member = TRUE THEN 'member'
        WHEN member = FALSE THEN 'non-member'
        ELSE NULL 
    END
)
SELECT 
    member_type,
    ROUND(AVG(revenue), 2) AS avg_revenue
FROM revenue_cte
GROUP BY member_type;

-- C. Product Analysis
-- Q1
SELECT
    prod_id AS product_id,
    product_name,
    ROUND(SUM(qty * price), 2) AS gross_revenue
FROM monthly_report_sales
GROUP BY product_name, prod_id
ORDER BY gross_revenue DESC
LIMIT 3;

-- Q2
SELECT
    segment_id,
    segment_name,
    SUM(qty) AS total_qty,
    ROUND(SUM(qty * price), 2) AS gross_revenue,
    ROUND(SUM(price * (discount / 100.0) * qty), 2) AS discount_amt
FROM monthly_report_sales 
GROUP BY segment_id, segment_name
ORDER BY segment_id;

-- Q3
WITH rank_cte AS(
    SELECT
        segment_id,
        segment_name,
        product_id,
        product_name,
        SUM(qty) AS total_qty,
        DENSE_RANK()OVER(PARTITION BY segment_id ORDER BY SUM(qty) DESC) AS rn
    FROM monthly_report_sales
    GROUP BY segment_id, segment_name, product_id, product_name

)
SELECT 
    segment_id, 
    segment_name, 
    product_id, 
    product_name, 
    total_qty
FROM rank_cte
WHERE rn = 1
ORDER BY segment_id;

-- Q4
SELECT
    category_id,
    category_name,
    SUM(qty) AS total_qty,
    ROUND(SUM(qty * price), 2) AS gross_revenue,
    ROUND(SUM(price * (discount / 100.0) * qty), 2) AS discount_amt
FROM monthly_report_sales
GROUP BY category_id, category_name
ORDER BY category_id;

-- Q5
WITH rank_cte AS(
    SELECT
        category_id,
        category_name,
        product_id,
        product_name,
        SUM(qty) AS total_qty,
        DENSE_RANK()OVER(PARTITION BY category_id ORDER BY SUM(qty) DESC) AS rn
    FROM monthly_report_sales
    GROUP BY category_id, category_name, product_id, product_name

)
SELECT 
    category_id, 
    category_name, 
    product_id, 
    product_name, 
    total_qty
FROM rank_cte
WHERE rn = 1
ORDER BY category_id;

-- Q6
WITH revenue_cte AS (
    SELECT 
        segment_id,
        segment_name,  
        product_id,
        product_name,
        SUM(qty * price) AS revenue
    FROM monthly_report_sales
    GROUP BY segment_id, segment_name, product_id, product_name
)
SELECT
    segment_id,
    segment_name,
    product_id,
    product_name,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (PARTITION BY segment_name), 2) AS pct
FROM revenue_cte
ORDER BY segment_id, pct DESC;

-- Q7
WITH revenue_cte AS (
    SELECT 
        segment_id,
        segment_name, 
        category_id,
        category_name,
        SUM(qty * price) AS revenue
    FROM monthly_report_sales
    GROUP BY segment_id, segment_name, category_id, category_name
)
SELECT
    category_id,
    category_name,
    segment_id,
    segment_name,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (PARTITION BY category_name), 2) AS pct
FROM revenue_cte
ORDER BY category_id, pct DESC;

-- Q8
SELECT 
	category_id, 
    CASE
        WHEN category_id = 1 THEN category_name
        WHEN category_id = 2 THEN category_name
        ELSE NULL 
    END AS category_type,
    ROUND(SUM(qty * price) * 100.0 / (SELECT SUM (qty * price) FROM sales), 2) AS pct
FROM monthly_report_sales
GROUP BY category_id,     
    CASE
        WHEN category_id = 1 THEN category_name
        WHEN category_id = 2 THEN category_name
        ELSE NULL 
    END
ORDER BY category_id;

-- Q9
SELECT
    product_id,
    product_name,
    ROUND(COUNT(txn_id) * 100.0/ (SELECT COUNT(DISTINCT txn_id) FROM sales), 2) AS txn_penetration
FROM monthly_report_sales
WHERE qty >= 1
GROUP BY product_id, product_name;

-- Q10
WITH product_cte AS(
    SELECT
        txn_id,
        prod_id,
        product_name
    FROM monthly_report_sales
)
SELECT
    a.product_name,
    b.product_name,
    c.product_name,
    COUNT(*) AS combination_count
FROM product_cte a
INNER JOIN product_cte b
    ON a.txn_id = b.txn_id
INNER JOIN product_cte c
    ON a.txn_id = c.txn_id
WHERE a.prod_id < b.prod_id AND b.prod_id < c.prod_id
GROUP BY a.product_name, b.product_name, c.product_name
ORDER BY combination_count DESC
LIMIT 1;