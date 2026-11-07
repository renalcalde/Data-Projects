/*
8 WEEK SQL CHALLENGE
CASE STUDY #2: PIZZA RUNNER
*/

-- A. PIZZA METRICS
-- Q1
SELECT COUNT(*) FROM customer_orders;

-- Q2
SELECT COUNT(DISTINCT order_id) FROM customer_orders;

-- Q3
SELECT runner_id, COUNT(*) FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- Q4
SELECT pn.pizza_name, COUNT(c.pizza_id) FROM customer_orders c
INNER JOIN runner_orders r
    ON c.order_id = r.order_id
INNER JOIN pizza_names pn
    ON c.pizza_id = pn.pizza_id
WHERE r.cancellation IS NULL
GROUP BY pn.pizza_name, c.pizza_id
ORDER BY c.pizza_id;

-- Q5
SELECT 
    c.customer_id,
    COUNT(CASE WHEN c.pizza_id = 1 THEN 1 END) AS meat_lover_count,
    COUNT(CASE WHEN c.pizza_id = 2 THEN 1 END) AS vegeterian_count
FROM customer_orders c 
INNER JOIN pizza_names pn 
    ON c.pizza_id = pn.pizza_id
GROUP BY c.customer_id
ORDER BY c.customer_id;

-- Q6
SELECT count(c.pizza_id) AS pizza_count FROM customer_orders c
INNER JOIN runner_orders r 
    ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.order_id, c.order_time
ORDER BY pizza_count DESC
LIMIT 1;

-- Q7
SELECT 
    c.customer_id,
    COUNT(CASE WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN 1 END) AS changes_count,
    COUNT(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN 1 END) AS no_changes_count
FROM customer_orders c 
INNER JOIN runner_orders r
    ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;

-- Q8
SELECT COUNT(*) FROM customer_orders c 
INNER JOIN runner_orders r 
    ON c.order_id = r.order_id
WHERE c.exclusions IS NOT NULL 
    AND c.extras IS NOT NULL 
    AND r.cancellation is NULL;

-- Q9
SELECT
    EXTRACT (HOUR FROM order_time) AS hour_of_day,
    COUNT(*) AS total_vol_of_pizza
FROM customer_orders
GROUP BY 
    EXTRACT (HOUR FROM order_time) 
ORDER BY hour_of_day;

-- Q10
SELECT
    CASE EXTRACT (DOW FROM order_time)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_of_week,
    COUNT(DISTINCT(order_id)) AS total_orders
FROM customer_orders
GROUP BY
    EXTRACT (DOW FROM order_time) 
ORDER BY day_of_week;

-- B. RUNNER AND CUSTOMER EXPERIENCE
-- Q1
SELECT
    '2021-01-01'::DATE + (FLOOR((registration_date::DATE - '2021-01-01'::DATE) / 7) * 7)::INT AS week_start,
    '2021-01-01'::DATE + ((FLOOR((registration_date::DATE - '2021-01-01'::DATE) / 7) * 7) + 6)::INT AS week_end,
    COUNT(runner_id) AS total_runners
FROM runners
GROUP BY 1, 2
ORDER BY 1;

-- Q2
SELECT 
    r.runner_id, 
    ROUND(AVG(EXTRACT(EPOCH FROM (r.pickup_time - c.order_time)) / 60::INT),2) AS prep_time
FROM runner_orders r
INNER JOIN customer_orders c
    ON r.order_id = c.order_id
WHERE r.cancellation IS NULL
GROUP BY r.runner_id;

-- Q3
-- prep time for every order
SELECT 
    c.order_time::DATE AS order_date,
    c.order_id,
    COUNT(*) AS pizza_count,
    ROUND(EXTRACT(EPOCH FROM (r.pickup_time - c.order_time)) / 60::INT,2) AS prep_time
FROM customer_orders c 
INNER JOIN runner_orders r  
    ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.order_id, c.order_time, r.pickup_time, c.customer_id  

-- avg per pizza count
WITH pizza_prep_time AS(
    SELECT 
        c.order_id,
        COUNT(*) AS pizza_count,
        (EXTRACT(EPOCH FROM (r.pickup_time - c.order_time)) / 60)::INT AS prep_time
    FROM customer_orders c 
    INNER JOIN runner_orders r  
        ON c.order_id = r.order_id
    WHERE r.cancellation IS NULL
    GROUP BY c.order_id, c.order_time, r.pickup_time, c.customer_id       
)
SELECT
    pizza_count,
    ROUND(AVG(prep_time),2) as avg_prep_time
FROM pizza_prep_time
GROUP BY pizza_count;

-- Q4
SELECT DISTINCT(c.customer_id), ROUND(AVG(r.distance_km)::numeric,2) AS avg_distance FROM runner_orders r   
INNER JOIN customer_orders c 
    ON r.order_id = c.order_id
GROUP BY c.customer_id
ORDER BY c.customer_id;

-- Q5
SELECT 
    MIN(duration_mins) AS shortest_time, 
    MAX(duration_mins) AS longest_time, 
    (MAX(duration_mins) - MIN(duration_mins)) AS time_difference 
FROM runner_orders;

-- Q6
SELECT
    r.runner_id,
    r.order_id,
    COUNT(*) AS pizza_count,
    r.distance_km,
    r.duration_mins,
    AVG(ROUND(r.distance_km * 60/ r.duration_mins)) AS avg_speed
FROM runner_orders r
INNER JOIN customer_orders c
    ON r.order_id = c.order_id
WHERE r.cancellation IS NULL
GROUP BY r.runner_id, r.order_id, r.distance_km, r.duration_mins;

-- Q7
WITH success_rate AS(
    SELECT 
        runner_id,
        SUM(CASE WHEN cancellation is NULL THEN 1 ELSE 0 END) AS successful_attempts,
        COUNT(*) AS total_attempts
    FROM runner_orders
    GROUP BY runner_id
)
SELECT
    runner_id,
    successful_attempts,
    total_attempts,
    ROUND((successful_attempts * 100.0/total_attempts), 2) AS success_rate_percentage
FROM success_rate
ORDER BY runner_id;

-- C. INGREDIENT OPTIMISATION
-- Q1
WITH pizza_toppings_cte AS(
    SELECT
        pr.pizza_id,
        TRIM(unnest(string_to_array(pr.toppings, ',')))::INT AS topping_ids
    FROM pizza_recipes pr
)
SELECT 
    ptc.pizza_id,
    pt.topping_name
FROM pizza_toppings_cte ptc
INNER JOIN pizza_toppings pt
    ON ptc.topping_ids = pt.topping_id
GROUP BY ptc.pizza_id, ptc.topping_ids, pt.topping_name
ORDER BY ptc.pizza_id;

-- Q2
WITH extra_topping_cte AS(
    SELECT
        TRIM(unnest(string_to_array(c.extras,',')))::INT AS extra_topping_id,
        COUNT(*) AS extra_toppings_count
    FROM customer_orders c
    GROUP BY extra_topping_id
)
SELECT
    etc.extra_topping_id,
    pt.topping_name,
    etc.extra_toppings_count
FROM extra_topping_cte etc
INNER JOIN pizza_toppings pt 
    ON etc.extra_topping_id = pt.topping_id
GROUP BY etc.extra_topping_id, pt.topping_name, etc.extra_toppings_count
ORDER BY etc.extra_toppings_count DESC;

-- Q3
WITH exclusion_topping_cte AS(
    SELECT
        TRIM(unnest(string_to_array(c.exclusions,',')))::INT AS exclusion_topping_id,
        COUNT(*) AS exclusion_toppings_count
    FROM customer_orders c
    GROUP BY exclusion_topping_id
)
SELECT
    etc.exclusion_topping_id,
    pt.topping_name,
    etc.exclusion_toppings_count
FROM exclusion_topping_cte etc
INNER JOIN pizza_toppings pt 
    ON etc.exclusion_topping_id = pt.topping_id
GROUP BY etc.exclusion_topping_id, pt.topping_name, etc.exclusion_toppings_count
ORDER BY etc.exclusion_toppings_count DESC;

-- Q4
WITH cleaned_data AS(
    SELECT
        order_id,
        pizza_id,
        NULLIF(NULLIF(TRIM(exclusions), ''), 'null') AS exclusions,
        NULLIF(NULLIF(TRIM(extras), ''), 'null') AS extras
    FROM customer_orders
)
SELECT
    cd.order_id,
    cd.pizza_id,
    cd.exclusions,
    cd.extras,
    pn.pizza_name
        || COALESCE(' - Exclude ' || (
            SELECT STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name)
            FROM pizza_toppings pt 
            WHERE pt.topping_id = ANY (
                STRING_TO_ARRAY(REPLACE(cd.exclusions, ' ', ''), ',')::int[]
            )
        ), '')
        || COALESCE(' - Extra ' || (
            SELECT STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name)
            FROM pizza_toppings pt 
            WHERE pt.topping_id = ANY (
                STRING_TO_ARRAY(REPLACE(cd.extras, ' ', ''), ',')::int[]
            )
        ), '') AS order_item
FROM cleaned_data cd
INNER JOIN pizza_names pn
    ON pn.pizza_id = cd.pizza_id
INNER JOIN runner_orders r 
    ON r.order_id = cd.order_id
WHERE r.cancellation IS NULL OR r.cancellation IN ('', 'null')
ORDER BY cd.order_id;

-- Q6
WITH pizza_toppings_cte AS(
    SELECT
        pr.pizza_id,
        TRIM(unnest(string_to_array(pr.toppings, ',')))::INT AS topping_ids
    FROM pizza_recipes pr
)
SELECT 
    pt.topping_name,
    COUNT(*) AS qty_count
FROM pizza_toppings_cte ptc
INNER JOIN customer_orders c
    ON ptc.pizza_id = c.pizza_id
INNER JOIN runner_orders r
    ON c.order_id = r.order_id
INNER JOIN pizza_toppings pt
    ON topping_ids = pt.topping_id
WHERE r.cancellation IS NULL
GROUP BY pt.topping_name, pt.topping_id
ORDER BY qty_count DESC;

-- D. PRICING AND RATINGS
-- Q1
SELECT 
    SUM(
        CASE 
            WHEN c.pizza_id = 1 THEN 12
            WHEN c.pizza_id = 2 THEN 10
            ELSE 0
        END 
    ) AS total_cost
FROM customer_orders c 
INNER JOIN runner_orders r
    ON c.order_id = r.order_id
WHERE r.cancellation IS NULL;

-- Q2
WITH count_modification_cte AS(
    SELECT
        c.pizza_id,
        c.order_id,
        c.extras,
        CASE 
            WHEN c.extras IS NULL OR c.extras = '' THEN 0
            ELSE LENGTH(c.extras) - LENGTH(REPLACE(c.extras, ',', '')) + 1
        END AS extras_count
    FROM customer_orders c
)
SELECT
    SUM(
        CASE 
            WHEN cmc.pizza_id = 1 THEN 12
            WHEN cmc.pizza_id = 2 THEN 10
            ELSE 0
        END 
        + cmc.extras_count
    ) AS total_cost
FROM count_modification_cte cmc 
INNER JOIN runner_orders r
    ON cmc.order_id = r.order_id
WHERE r.cancellation IS NULL;

-- Q3
CREATE TABLE ratings (
    order_id INT,
    rating INT
);

INSERT INTO ratings (order_id, rating)
VALUES 
    (1, 2),
    (2, 4),
    (3, 2),
    (4, 5),
    (5, 1),
    (6, 5),
    (7, 4),
    (8, 3),
    (9, 3),
    (10, 5);
    
SELECT * FROM ratings;

-- Q4
SELECT
    c.customer_id,
    c.order_id,
    ro.runner_id,
    r.rating,
    c.order_time,
    ro.pickup_time,
    ROUND(AVG(EXTRACT(EPOCH FROM (ro.pickup_time - c.order_time)) / 60::INT),2) AS prep_time,
    duration_mins,
    AVG(ROUND(ro.distance_km * 60/ ro.duration_mins)) AS avg_speed,
    COUNT(*) AS total_pizzas
FROM customer_orders c 
INNER JOIN runner_orders ro
    ON c.order_id = ro.order_id
INNER JOIN ratings r
    ON c.order_id = r.order_id
WHERE ro.cancellation IS NULL
GROUP BY c.customer_id, c.order_id, ro.runner_id, r.rating, c.order_time, ro.pickup_time, ro.duration_mins;

-- Q5
SELECT
    (
        SELECT 
            SUM(
                CASE 
                    WHEN c.pizza_id = 1 THEN 12
                    WHEN c.pizza_id = 2 THEN 10
                    ELSE 0
                END 
            ) AS pizza_revenue
        FROM customer_orders c 
        INNER JOIN runner_orders r
            ON c.order_id = r.order_id
        WHERE r.cancellation IS NULL
    )
    -
    (
        SELECT
            ROUND((SUM(distance_km) * 0.30)::NUMERIC,2) AS earnings
        FROM runner_orders
    ) AS cost_of_goods;

-- E. BONUS QUESTION
INSERT INTO pizza_recipes (pizza_id, toppings) 
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

SELECT pn.pizza_id, pn.pizza_name, pr.toppings FROM pizza_names pn 
INNER JOIN pizza_recipes pr 
    ON pn.pizza_id = pr.pizza_id;
