

/* 8 WEEK SQL CHALLENGE: Case Study #7 - Balanced Tree Clothing Co. */

-- A. High Level Sales Analysis 
-- Q1
SELECT SUM(qty) AS total_qty FROM sales;

-- Q2
SELECT
    ROUND(SUM(qty * price), 2) AS gross_revenue
FROM sales;

-- Q3
SELECT 
    ROUND(SUM(price * (discount / 100.0) * qty), 2) AS total_discount_amt
FROM sales;

-- B. Transaction Analysis 
-- Q1
SELECT COUNT(DISTINCT txn_id) AS total_txn FROM sales;

-- Q2
WITH count_cte AS(
    SELECT 
        txn_id,
        COUNT(DISTINCT prod_id) AS product_count
    FROM sales
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
    FROM sales
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
    FROM sales
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
FROM sales
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
FROM sales
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
    s.prod_id AS product_id,
    d.product_name,
    ROUND(SUM(s.qty * s.price), 2) AS gross_revenue
FROM sales s
INNER JOIN product_details d
    ON s.prod_id = d.product_id
GROUP BY d.product_name, s.prod_id
ORDER BY gross_revenue DESC
LIMIT 3;

-- Q2
SELECT
    d.segment_id,
    d.segment_name,
    SUM(s.qty) AS total_qty,
    ROUND(SUM(s.qty * s.price), 2) AS gross_revenue,
    ROUND(SUM(s.price * (s.discount / 100.0) * s.qty), 2) AS discount_amt
FROM sales s
INNER JOIN product_details d
    ON s.prod_id = d.product_id
GROUP BY d.segment_id, d.segment_name
ORDER BY d.segment_id;

-- Q3
WITH rank_cte AS(
    SELECT
        d.segment_id,
        d.segment_name,
        d.product_id,
        d.product_name,
        SUM(s.qty) AS total_qty,
        DENSE_RANK()OVER(PARTITION BY d.segment_id ORDER BY SUM(s.qty) DESC) AS rn
    FROM sales s
    INNER JOIN product_details d
        ON s.prod_id = d.product_id
    GROUP BY d.segment_id, d.segment_name, d.product_id, d.product_name

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
    d.category_id,
    d.category_name,
    SUM(s.qty) AS total_qty,
    ROUND(SUM(s.qty * s.price), 2) AS gross_revenue,
    ROUND(SUM(s.price * (s.discount / 100.0) * s.qty), 2) AS discount_amt
FROM sales s
INNER JOIN product_details d
    ON s.prod_id = d.product_id
GROUP BY d.category_id, d.category_name
ORDER BY d.category_id;

-- Q5
WITH rank_cte AS(
    SELECT
        d.category_id,
        d.category_name,
        d.product_id,
        d.product_name,
        SUM(s.qty) AS total_qty,
        DENSE_RANK()OVER(PARTITION BY d.category_id ORDER BY SUM(s.qty) DESC) AS rn
    FROM sales s
    INNER JOIN product_details d
        ON s.prod_id = d.product_id
    GROUP BY d.category_id, d.category_name, d.product_id, d.product_name

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
        d.segment_id,
        d.segment_name, 
        d.product_id,
        d.product_name,
        SUM(s.qty * s.price) AS revenue
    FROM sales s
    INNER JOIN product_details d
        ON s.prod_id = d.product_id
    GROUP BY d.segment_id, d.segment_name, d.product_id, d.product_name
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
        d.segment_id,
        d.segment_name, 
        d.category_id,
        d.category_name,
        SUM(s.qty * s.price) AS revenue
    FROM sales s
    INNER JOIN product_details d
        ON s.prod_id = d.product_id
    GROUP BY d.segment_id, d.segment_name, d.category_id, d.category_name
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
        WHEN d.category_id = 1 THEN d.category_name
        WHEN d.category_id = 2 THEN d.category_name
        ELSE NULL 
    END AS category_type,
    ROUND(SUM(s.qty * s.price) * 100.0 / (SELECT SUM (qty * price) FROM sales), 2) AS pct
FROM sales s
INNER JOIN product_details d
    ON s.prod_id = d.product_id
GROUP BY category_id,     
    CASE
        WHEN d.category_id = 1 THEN d.category_name
        WHEN d.category_id = 2 THEN d.category_name
        ELSE NULL 
    END
ORDER BY category_id;

-- Q9
SELECT
    d.product_id,
    d.product_name,
    ROUND(COUNT(s.txn_id) * 100.0/ (SELECT COUNT(DISTINCT txn_id) FROM sales), 2) AS txn_penetration
FROM sales s
INNER JOIN product_details d
    ON s.prod_id = d.product_id
WHERE qty >= 1
GROUP BY d.product_id, d.product_name;

-- Q10
WITH product_cte AS(
    SELECT
        s.txn_id,
        s.prod_id,
        d.product_name
    FROM sales s
    INNER JOIN product_details d
        ON s.prod_id = d.product_id
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

-- D. Reporting Challenge 
-- This section is in a separate file: 'reporting_challenge.sql'

-- E. Bonus Challenge 
WITH category_cte AS(
    SELECT
        id AS category_id,
        level_text AS category_name
    FROM product_hierarchy
    WHERE level_name = 'Category'
),
segment_cte AS(
    SELECT
        parent_id AS category_id,
        id AS segment_id,
        level_text AS segment_name
    FROM product_hierarchy
    WHERE level_name = 'Segment'
),
style_cte AS(
    SELECT
        parent_id AS segment_id,
        id AS style_id,
        level_text AS style_name
    FROM product_hierarchy
    WHERE level_name = 'Style'
),
combine_cte AS(
    SELECT
        cat.category_id,
        cat.category_name,
        seg.segment_id,
        seg.segment_name,
        sty.style_id,
        sty.style_name
    FROM category_cte cat
    INNER JOIN segment_cte seg
        ON cat.category_id = seg.category_id
    INNER JOIN style_cte sty
        ON seg.segment_id = sty.segment_id
)
SELECT
    pp.product_id,
    pp.price,
    cc.style_name || ' ' || cc.segment_name || ' - ' || cc.category_name AS product_name,
    cc.category_id,
    cc.segment_id,
    cc.style_id,
    cc.category_name,
    cc.segment_name,
    cc.style_name
FROM product_prices pp
INNER JOIN combine_cte cc
    ON cc.style_id = pp.id;