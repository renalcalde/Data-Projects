
/*
8 WEEK SQL CHALLENGE: Case Study #5 - Data Mart
*/

-- 1. Data Cleansing Steps
DROP TABLE IF EXISTS clean_weekly_sales;

CREATE TABLE clean_weekly_sales AS 
WITH date_bounds AS(
    SELECT MIN(TO_DATE(week_date, 'DD/MM/YY')) AS min_date
    FROM weekly_sales
),
bucketed AS(
    SELECT
        TO_DATE(w.week_date, 'DD/MM/YY') AS clean_week,
        FLOOR((TO_DATE(w.week_date, 'DD/MM/YY') - b.min_date) / 7)::INT AS week_bucket,
        b.min_date,
        w.region,
        w.platform,
        COALESCE(NULLIF(NULLIF(TRIM(w.segment),''), 'null'), 'unknown') AS segment,
        CASE LEFT(w.segment, 1)
            WHEN 'C' THEN 'Couples'
            WHEN 'F' THEN 'Families'
            ELSE 'unknown'
        END AS demographic,
        CASE SUBSTRING(w.segment FROM 2)
            WHEN '1' THEN 'Young Adults'
            WHEN '2' THEN 'Middle Aged'
            WHEN '3' THEN 'Retirees'
            WHEN '4' THEN 'Retirees'
            ELSE 'unknown'
        END AS age_band,
        w.customer_type,
        w.transactions,
        w.sales,
        ROUND(AVG(w.sales/ NULLIF(w.transactions, 0)),2) AS avg_transaction
    FROM weekly_sales w
    CROSS JOIN date_bounds b
    GROUP BY clean_week, b.min_date, w.region, w.platform, w.segment, w.customer_type, w.transactions, w.sales
)
SELECT
	clean_week AS week_date,
    week_bucket + 1 AS week_number,
    EXTRACT(MONTH FROM clean_week)::INT AS month_number,
    EXTRACT(YEAR FROM clean_week)::INT AS calendar_number,
    region,
    platform,
    segment,
    age_band,
    demographic,
    customer_type,
    transactions,
    sales,
    avg_transaction
FROM bucketed
ORDER BY clean_week;

-- 2. Data Exploration
-- Q1
SELECT
    DISTINCT (week_date) as dates,
    TO_CHAR(week_date, 'fmDay') AS week_name
FROM clean_weekly_sales
GROUP BY dates;

-- Q2
WITH date_bounds AS(
    SELECT
        MIN(week_date)::DATE AS min_date,
        MAX(week_number) AS max_week
    FROM clean_weekly_sales
),
bucketed AS(
    SELECT
        gs.week_number,
        (d.min_date + (gs.week_number - 1) * INTERVAL '7 days')::DATE AS week_start,
        (d.min_date + (gs.week_number * INTERVAL '7 days') - INTERVAL '1 day')::DATE AS week_end
    FROM date_bounds d
    CROSS JOIN LATERAL GENERATE_SERIES(1, max_week) AS gs(week_number)
)
SELECT
    b.week_number AS missing_week_number,
    b.week_start,
    b.week_end
FROM bucketed b
LEFT JOIN clean_weekly_sales c 
    ON b.week_number = c.week_number
WHERE c.week_number IS NULL
ORDER BY b.week_number;

-- Q3
SELECT 
    calendar_number AS year,
    COUNT(transactions) AS transaction_count
FROM clean_weekly_sales
GROUP BY calendar_number
ORDER BY calendar_number;

-- Q4
SELECT 
    TO_CHAR(week_date, 'MM - MONTH') AS month_name,
    region,
    SUM(sales) AS sales_count
FROM clean_weekly_sales
GROUP BY month_name, region
ORDER BY month_name, region;

-- Q5
SELECT 
    platform,
    COUNT(transactions) AS transaction_count
FROM clean_weekly_sales
GROUP BY platform;

-- Q6
WITH total_cte AS(
    SELECT
        month_number,
        TO_CHAR(TO_DATE(month_number::TEXT, 'MM'), 'FMMonth') AS month,
        SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) AS retail_total,
        SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) AS shopify_total,
        SUM(sales) AS total
    FROM clean_weekly_sales
    GROUP BY month_number
)
SELECT
    month,
    ROUND((retail_total * 100.0/ NULLIF(total, 0)), 2) AS retail_pct,
    ROUND((shopify_total * 100.0/ NULLIF(total, 0)), 2) AS shopify_pct
FROM total_cte
ORDER BY month_number;

-- Q7
WITH total_cte AS(
	SELECT
		calendar_number,
		SUM(CASE WHEN demographic = 'Families' THEN sales ELSE 0 END) AS families_sales,
		SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END) AS couples_sales,
		SUM(CASE WHEN demographic = 'unknown' THEN sales ELSE 0 END) AS unknown_sales,
		SUM(sales) AS total
	FROM clean_weekly_sales
	GROUP BY calendar_number
)
SELECT
	calendar_number AS year,
	ROUND((families_sales * 100.0/ NULLIF(total, 0)), 2) AS families_pct,
	ROUND((couples_sales * 100.0/ NULLIF(total, 0)), 2) AS couples_pct,
	ROUND((unknown_sales * 100.0/ NULLIF(total, 0)), 2) AS unknown_pct
FROM total_cte
ORDER BY calendar_number;

-- Q8
WITH retail_cte AS(
    SELECT 
        segment,
        age_band,
        demographic,
        SUM(sales) AS total_sales,
        ROUND(SUM(sales) * 100 / SUM(SUM(sales))OVER(), 2) AS pct_of_total
    FROM clean_weekly_sales
    WHERE platform = 'Retail'
    GROUP BY age_band, demographic, segment
)
SELECT
    segment,
    age_band,
    demographic,
    pct_of_total
FROM retail_cte
ORDER BY pct_of_total DESC;

-- Q9
WITH transaction_cte AS(
    SELECT
        platform,
        calendar_number AS year,
        SUM(transactions) AS transaction_total,
        COUNT(transactions) AS transaction_count
    FROM clean_weekly_sales
    GROUP BY platform, year
)
SELECT
    r.year,
    r.retail_avg_transaction_size,
    s.shopify_avg_transaction_size
FROM (
    SELECT
        year,
        ROUND(AVG(transaction_total/transaction_count),2) AS retail_avg_transaction_size
    FROM transaction_cte 
    WHERE platform = 'Retail'
    GROUP BY year
) AS r
FULL JOIN (
    SELECT
        year,
        ROUND(AVG(transaction_total/transaction_count),2) AS shopify_avg_transaction_size
    FROM transaction_cte 
    WHERE platform = 'Shopify'
    GROUP BY year
) AS s
    ON r.year = s.year;

-- 3. Before & After Analysis
-- Q1
WITH sales_cte AS(
    SELECT
        SUM(sales) AS total_sales,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15'::DATE - INTERVAL '4 weeks' AND '2020-06-15'::DATE - INTERVAL '1 day' 
            THEN sales ELSE 0
        END) AS sales_weeks_before,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15'::DATE AND '2020-06-15'::DATE + INTERVAL '4 weeks' 
            THEN sales ELSE 0
        END) AS sales_weeks_after
    FROM clean_weekly_sales
)
SELECT
    sales_weeks_before AS sales_before,
    ROUND(sales_weeks_before * 100.0 / total_sales, 2) AS before_pct,
    sales_weeks_after AS sales_after,
    ROUND(sales_weeks_after * 100.0 / total_sales , 2) AS after_pct,
    ROUND((sales_weeks_after - sales_weeks_before) * 100.0 / sales_weeks_before, 2) AS growth_rate
FROM sales_cte;

-- Q2
WITH sales_cte AS(
    SELECT
        SUM(sales) AS total_sales,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15'::DATE - INTERVAL '12 weeks' AND '2020-06-15'::DATE - INTERVAL '1 day' 
            THEN sales ELSE 0
        END) AS sales_weeks_before,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15'::DATE AND '2020-06-15'::DATE + INTERVAL '12 weeks' 
            THEN sales ELSE 0
        END) AS sales_weeks_after
    FROM clean_weekly_sales
)
SELECT
    sales_weeks_before AS sales_before,
    ROUND(sales_weeks_before * 100.0 / total_sales, 2) AS before_pct,
    sales_weeks_after AS sales_after,
    ROUND(sales_weeks_after * 100.0 / total_sales , 2) AS after_pct,
    ROUND((sales_weeks_after - sales_weeks_before) * 100.0 / sales_weeks_before, 2) AS growth_rate
FROM sales_cte;

-- Q3
WITH sales_cte AS(
    SELECT
        calendar_number AS year,
        SUM(sales) AS total_sales,
        -- 4 weeks
        SUM(CASE 
            WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
                 TO_CHAR(DATE '2020-06-15' - INTERVAL '4 weeks', 'MM-DD')
             AND TO_CHAR(DATE '2020-06-15' - INTERVAL '1 day', 'MM-DD')
            THEN sales ELSE 0 
        END) AS sales4w_before,
        SUM(CASE 
            WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
                 TO_CHAR(DATE '2020-06-15', 'MM-DD')
             AND TO_CHAR(DATE '2020-06-15' + INTERVAL '4 weeks', 'MM-DD')
            THEN sales ELSE 0 
        END) AS sales4w_after,

        -- 12 weeks
        SUM(CASE 
            WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
                 TO_CHAR(DATE '2020-06-15' - INTERVAL '12 weeks', 'MM-DD')
             AND TO_CHAR(DATE '2020-06-15' - INTERVAL '1 day', 'MM-DD')
            THEN sales ELSE 0 
        END) AS sales12w_before,
        SUM(CASE 
            WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
                 TO_CHAR(DATE '2020-06-15', 'MM-DD')
             AND TO_CHAR(DATE '2020-06-15' + INTERVAL '12 weeks', 'MM-DD')
            THEN sales ELSE 0 
        END) AS sales12w_after
    FROM clean_weekly_sales
    GROUP BY year
)
SELECT
    year,
    '4 weeks' AS sales_period,
    sales4w_before AS sales_before,
    ROUND(sales4w_before * 100.0 / total_sales, 2) AS before_pct,
    sales4w_after AS sales_after,
    ROUND(sales4w_after * 100.0 / total_sales , 2) AS after_pct,
    ROUND((sales4w_after - sales4w_before) * 100.0 / sales4w_before, 2) AS growth_rate
FROM sales_cte
WHERE year IN (2020, 2019, 2018)

UNION ALL

SELECT
    year,
    '12 weeks' AS sales_period,
    sales12w_before AS sales_before,
    ROUND(sales12w_before * 100.0 / total_sales, 2) AS before_pct,
    sales12w_after AS sales_after,
    ROUND(sales12w_after * 100.0 / total_sales , 2) AS after_pct,
    ROUND((sales12w_after - sales12w_before) * 100.0 / sales12w_before, 2) AS growth_rate
FROM sales_cte
WHERE year IN (2020, 2019, 2018)
ORDER BY sales_period DESC, year;

-- 4. Bonus Question
WITH sales_cte AS (
  SELECT 
    CASE 
      WHEN GROUPING(region) = 0 THEN 'region'
      WHEN GROUPING(platform) = 0 THEN 'platform'
      WHEN GROUPING(age_band) = 0 THEN 'age_band'
      WHEN GROUPING(demographic) = 0 THEN 'demographic'
      WHEN GROUPING(customer_type) = 0 THEN 'customer_type'
    END AS category,
    COALESCE(region, platform, age_band, demographic, customer_type) AS subcategory,
    SUM(CASE 
        WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
             TO_CHAR(DATE '2020-06-15' - INTERVAL '12 weeks', 'MM-DD') 
         AND TO_CHAR(DATE '2020-06-15' - INTERVAL '1 day', 'MM-DD') 
         THEN sales ELSE 0 
    END) AS sales_before,
    SUM(CASE 
      WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
           TO_CHAR(DATE '2020-06-15', 'MM-DD') 
       AND TO_CHAR(DATE '2020-06-15' + INTERVAL '12 weeks', 'MM-DD') 
       THEN sales ELSE 0 
    END) AS sales_after
  FROM clean_weekly_sales
  GROUP BY GROUPING SETS (
    (region),
    (platform),
    (age_band),
    (demographic),
    (customer_type)
  )
)
SELECT 
  category,
  subcategory,
  sales_before,
  sales_after,
  ROUND((sales_after - sales_before) * 100.0 / NULLIF(sales_before, 0), 2) AS growth_rate
FROM sales_cte
ORDER BY growth_rate;

