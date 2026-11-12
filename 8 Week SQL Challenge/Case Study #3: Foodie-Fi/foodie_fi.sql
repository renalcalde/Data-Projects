
/*
8 WEEK SQL CHALLENGE
Case Study #3: Foodie-Fi
*/

-- A. Customer Journey
SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19);

SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE customer_id = 1;

SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE customer_id = 2;

SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE customer_id = 11;

SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE customer_id = 13;

SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE customer_id = 15;

SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE customer_id = 16;

SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE customer_id = 18;

SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE customer_id = 19;

-- B. Data Analysis Questions
-- Q1
SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions;

-- Q2
SELECT 
    TO_CHAR(s.start_date, 'MM - MONTH') AS month,
    COUNT(s.plan_id)
FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.plan_id = 0
GROUP BY TO_CHAR(s.start_date, 'MM - MONTH')
ORDER BY month;

-- Q3
SELECT 
    p.plan_name,
    COUNT(s.plan_id)
FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE EXTRACT(YEAR FROM s.start_date) > '2020'
GROUP BY s.plan_id, p.plan_name
ORDER BY s.plan_id;

-- Q4
WITH customer_count_cte AS(
    SELECT 
        p.plan_name,
        COUNT(s.customer_id) AS customer_count
    FROM subscriptions s
    INNER JOIN plans p
        ON s.plan_id = p.plan_id
    WHERE s.plan_id = 4
    GROUP BY p.plan_name
)
SELECT
    customer_count AS customer_count,
    ROUND((customer_count * 1.0 / NULLIF((SELECT COUNT(DISTINCT (customer_id)) FROM subscriptions), 0)) * 100, 1) AS percentage
FROM customer_count_cte;

-- Q5
WITH plan_status_cte AS(
    SELECT
        customer_id,
        LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS previous_plan,
        plan_id AS current_plan
    FROM subscriptions
)
SELECT 
    COUNT(customer_id) AS customer_count,
    ROUND((COUNT(customer_id) * 1.0 / NULLIF((SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions), 0)) * 100, 0) AS churn_percentage
FROM plan_status_cte

-- Q6
WITH next_plan_cte AS(
    SELECT
        plan_id,
        customer_id,
        LEAD(plan_id)OVER(PARTITION BY customer_id ORDER BY plan_id) AS next_plan
    FROM subscriptions s
)
SELECT
    p.plan_name,
    COUNT(np.customer_id) AS customer_count,
    ROUND((COUNT(np.customer_id) * 1.0/ (SELECT COUNT(DISTINCT (customer_id)) FROM subscriptions)) * 100, 1) AS percentage
FROM next_plan_cte np
INNER JOIN plans p
    ON np.next_plan = p.plan_id
WHERE np.next_plan IS NOT NULL AND np.plan_id = 0
GROUP BY p.plan_name, np.next_plan
ORDER BY np.next_plan;

-- Q7
WITH next_plan_cte AS(
    SELECT
        p.plan_name,
        COUNT(DISTINCT s.customer_id) AS customer_count
    FROM (
        SELECT customer_id, plan_id,
            LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY plan_id) AS next_plan
        FROM subscriptions
        WHERE start_date <= '2020-12-31'
    ) s
    INNER JOIN plans p
        ON s.plan_id = p.plan_id
    WHERE next_plan IS NULL
    GROUP BY p.plan_id, p.plan_name
    ORDER BY p.plan_id
)
SELECT
    plan_name,
    customer_count,
    ROUND((customer_count * 1.0 / (SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions)) * 100, 1) AS percentage
FROM next_plan_cte;

-- Q8
SELECT
    COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions
WHERE start_date BETWEEN '2020-01-01' AND '2020-12-31' AND plan_id = 3;

-- Q9
WITH trial_cte AS(
    SELECT
        customer_id,
        start_date AS trial_date
    FROM subscriptions
    WHERE plan_id = 0
), 
annual_cte AS(
    SELECT
        customer_id,
        start_date AS annual_date
    FROM subscriptions
    WHERE plan_id = 3
)
SELECT
    ROUND(AVG(ac.annual_date - tc.trial_date),0) AS avg_days
FROM trial_cte tc
INNER JOIN annual_cte ac
    ON tc.customer_id = ac.customer_id;

-- Q10
WITH trial_cte AS(
    SELECT
        customer_id,
        start_date AS trial_date
    FROM subscriptions
    WHERE plan_id = 0
), 
annual_cte AS(
    SELECT
        customer_id,
        start_date AS annual_date
    FROM subscriptions
    WHERE plan_id = 3
),
day_difference_cte AS(
    SELECT 
        WIDTH_BUCKET(ac.annual_date - tc.trial_date, 0, 365, 12) AS avg_days
    FROM trial_cte tc
    INNER JOIN annual_cte ac
        ON tc.customer_id = ac.customer_id
)
SELECT
    ((avg_days - 1) * 30 || '-' || avg_days * 30 || ' days') AS bucket_days,
    COUNT(*)
FROM day_difference_cte
GROUP BY avg_days
ORDER BY avg_days

-- Q11
WITH plan_status_cte AS(
    SELECT
        customer_id,
        LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS previous_plan,
        plan_id AS current_plan,
        start_date
    FROM subscriptions
)
SELECT COUNT(*)
FROM plan_status_cte
WHERE previous_plan = 2 AND current_plan = 1 AND EXTRACT(YEAR FROM start_date) = '2020';

-- C. Challenge Payment Question
DROP TABLE IF EXISTS payments;

CREATE TABLE payments AS
WITH RECURSIVE plan_cutoffs AS(
    SELECT 
        s.customer_id,
        s.plan_id,
        p.plan_name,
        s.start_date,
        COALESCE(LEAD(s.start_date) OVER(PARTITION BY s.customer_id ORDER BY s.start_date), '2020-12-31') AS cutoff_date,
        p.price
    FROM subscriptions s
    INNER JOIN plans p
        ON s.plan_id = p.plan_id
    WHERE s.plan_id NOT IN (0,4) AND s.start_date <= '2020-12-31'
),
monthly_payments AS(
    SELECT
        customer_id,
        plan_id,
        plan_name,
        start_date,
        cutoff_date,
        price
    FROM plan_cutoffs

    UNION ALL
    
    SELECT
        customer_id,
        plan_id,
        plan_name,
        (start_date + INTERVAL '1 month')::DATE,
        cutoff_date,
        price
    FROM monthly_payments
    WHERE cutoff_date > (start_date + INTERVAL '1 month')::DATE AND plan_id != 3
),
prior_plan AS(
    SELECT *,
        LAG(plan_id) OVER(PARTITION BY customer_id ORDER BY start_date) AS previous_plan,
        LAG(price) OVER(PARTITION BY customer_id ORDER BY start_date) AS previous_price
    FROM monthly_payments
    ORDER BY customer_id, start_date
)
SELECT
    customer_id,
    plan_id,
    plan_name,
    start_date AS payment_date,
    CASE
        WHEN previous_plan = 1 AND plan_id IN (2,3) THEN price - previous_price 
        ELSE price 
    END AS amount,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS payment_order
FROM prior_plan;

SELECT * FROM payments;