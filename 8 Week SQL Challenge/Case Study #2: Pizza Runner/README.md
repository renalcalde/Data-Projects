# 🍕 Case Study #2: Pizza Runner

<p align="center">
<img src= "png/pizza_runner.png" alt="Pizza Runner Poster" width="500"><br>
  <strong>Source:</strong> <a href="https://8weeksqlchallenge.com/case-study-2/">8 Week SQL Challenge: Case Study #2 - Pizza Runner</a>
</p>

## Table of Contents
- [Objective](#objective)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Data Cleaning](#data-cleaning)
- [Question & Solution](#question-and-solution)
  - [A. Pizza Metrics](#a-pizza-metrics)
  - [B. Runner and Customer Experience](#b-runner-and-customer-experience)
  - [C. Ingredient Optimisation](#c-ingredient-optimisation)
  - [D. Pricing and Ratings](#d-pricing-and-ratings)
  - [E. Bonus Questions](#e-bonus-questions)
- [Challenge](#challenges)
- [Key Takeaway](#key-takeaways)
  
## Objective
This case study analyzes Pizza Runner’s order, runner, and delivery data to uncover insights on customer ordering behavior, runner performance, ingredient usage, and revenue, so Danny can make data-driven decisions to grow his pizza delivery business.

## Entity Relationship Diagram
There are 6 key datasets for this case study:
- `runners` : Runner registration dates
- `customer_orders` : One row per pizza ordered
- `runner_orders` : One row per order, with pickup/delivery details and `cancellation` status
- `pizza_names` : The two pizzas: Meat Lovers and Vegetarian
- `pizza_recipes` : Standard toppings for each `pizza_id`
- `pizza_toppings` : Topping names and their `topping_id`

<p align="center">
<img src="png/entity_relationship_diagram.png" alt="Entity Relationship Diagram" width="800">
</p>

## Data Cleaning
Before investigating the data, I had to clean the dataset by handling the `null` values and data types in the `customer_orders` and `runner_orders` tables.
- `customer_orders`: converted blank and `'null'` values in `exclusions` and `extras` to NULL
- `runner_orders`: similar fix for `cancellation`, and I turned `pickup_time`, `distance`, and `duration` into usable data types

Full script: [data_cleaning.sql](./data_cleaning.sql)

## Question and Solution
### A. Pizza Metrics
**1. How many pizzas were ordered?**

```SQL
SELECT COUNT(*) FROM customer_orders;
```
**Result:**

<img width="164" height="109" alt="Screenshot 2026-11-02 at 7 56 38 PM" src="https://github.com/user-attachments/assets/084a66cf-a67e-4d88-975f-8506611b8408" /><br>

**2. How many unique customer orders were made?**
- Use COUNT(DISTINCT `order_id`)) so orders with multiple pizzas are counted once

```SQL
SELECT COUNT(DISTINCT order_id) FROM customer_orders;
```
**Result:**

<img width="164" height="105" alt="Screenshot 2026-11-03 at 8 12 47 PM" src="https://github.com/user-attachments/assets/3b2230f3-f30d-4d41-9435-7f4569bd174a" /><br>

**3. How many successful orders were delivered by each runner?**
- Use COUNT since `runner_orders` has one row per order
- Use a WHERE statement to filter for successful deliveries if `cancellation` is NULL from the `runner_orders` table

```SQL
SELECT runner_id, COUNT(*) FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;
```

**Result:**

<img width="266" height="148" alt="Screenshot 2026-11-04 at 6 43 04 AM" src="https://github.com/user-attachments/assets/448878c7-a9ea-413b-93f0-58e1cc1e7cff" /><br>

**4. How many of each type of pizza was delivered?**
- JOIN `customer_orders` with `runner_orders` and filtered on `cancellation` IS NULL so only delivered pizzas are counted
- JOIN `pizza_names` to GROUP BY the readable name instead of the numeric `pizza_id`

```SQL
SELECT pn.pizza_name, COUNT(c.pizza_id) FROM customer_orders c
INNER JOIN runner_orders r
    ON c.order_id = r.order_id
INNER JOIN pizza_names pn
    ON c.pizza_id = pn.pizza_id
WHERE r.cancellation IS NULL
GROUP BY pn.pizza_name, c.pizza_id
ORDER BY c.pizza_id;
```

**Result:**

<img width="273" height="126" alt="4" src="https://github.com/user-attachments/assets/747b3c49-874e-4f39-b54a-1c8f62ea21e3" /><br>

**5. How many Vegetarian and Meatlovers were ordered by each customer?**
- Use conditional aggregation (COUNT + CASE) to act as a tracker for each pizza type in single pass, instead of one query per type
  
```SQL
SELECT 
    c.customer_id,
    COUNT(CASE WHEN c.pizza_id = 1 THEN 1 END) AS meat_lover_count,
    COUNT(CASE WHEN c.pizza_id = 2 THEN 1 END) AS vegeterian_count
FROM customer_orders c 
GROUP BY c.customer_id
ORDER BY c.customer_id;
```

**Result:**

<img width="541" height="199" alt="5" src="https://github.com/user-attachments/assets/98cd3ebc-115e-423b-8e92-89fa0f02a001" /><br>


**6. What was the maximum number of pizzas delivered in a single order?**
- GROUP BY `order_id` to count pizzas per order, then sorted descending with LIMIT 1 so it only returns a single line with the highest pizza count

```SQL
SELECT COUNT(c.pizza_id) AS pizza_count FROM customer_orders c
INNER JOIN runner_orders r 
    ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.order_id, c.order_time
ORDER BY pizza_count DESC
LIMIT 1;
```

**Result:**

<img width="181" height="94" alt="6" src="https://github.com/user-attachments/assets/3df85055-ce4f-461c-b951-d8c76c8be529" /><br>

**7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?**
- Use conditional aggregation (COUNT + CASE) to act as a tracker for the number of times an order has a change or no changes in a single pass rather than running two separate queries
- JOIN to `runner_orders` and filter on `cancellation` IS NULL so only delivered pizzas are counted

```SQL
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
```

**Result:**

<img width="524" height="202" alt="7" src="https://github.com/user-attachments/assets/102484ef-7fef-44f9-9a6d-a758553f628a" /><br>

**8. How many pizzas were delivered that had both exclusions and extras?**
- JOIN to `runner_orders` and filtered on `cancellation` IS NULL so only delivered pizzas are counted
- Required both `exclusions` and `extras` to be NOT NULL (using AND, not OR), so only pizzas with both modifications are counted

```SQL
SELECT COUNT(*) FROM customer_orders c 
INNER JOIN runner_orders r 
    ON c.order_id = r.order_id
WHERE c.exclusions IS NOT NULL 
    AND c.extras IS NOT NULL 
    AND r.cancellation is NULL;
```

**Result:**

<img width="158" height="104" alt="8" src="https://github.com/user-attachments/assets/4557c855-8e7b-4e21-b372-73a3e6149b7d" /><br>

**9. What was the total volume of pizzas ordered for each hour of the day?**
- Use EXTRACT(HOUR FROM order_time) to bucket orders by hour regardless of date

```SQL
SELECT
    EXTRACT (HOUR FROM order_time) AS hour_of_day,
    COUNT(*) AS total_vol_of_pizza
FROM customer_orders
GROUP BY 
    EXTRACT (HOUR FROM order_time) 
ORDER BY hour_of_day;
```

**Result:**

<img width="378" height="219" alt="9" src="https://github.com/user-attachments/assets/0e08f472-4c3e-44cd-8308-7461776e8220" /><br>

**10. What was the volume of orders for each day of the week?**
- Use COUNT(DISTINCT `order_id`) to count for every unique orders, keeping duplicates to one row
- EXTRACT(DOW ...) to day names with CASE since DOW returns numbers
- ORDER BY the numeric DOW rather than the day name keeps Monday-Sunday in calendar order instead of alphabetical
  
```SQL
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
```

**Result:**

<img width="331" height="174" alt="10" src="https://github.com/user-attachments/assets/c2ad966b-0bec-4011-bd8c-ecb21cbc945d" /><br>

### B. Runner and Customer Experience
**1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)**
- Use `'2021-01-01'` as a fixed anchor instead of DATE_TRUNC('week', ...), since the question defines weeks starting on that date, not on Monday

```SQL
SELECT
    '2021-01-01'::DATE + (FLOOR((registration_date::DATE - '2021-01-01'::DATE) / 7) * 7)::INT AS week_start,
    '2021-01-01'::DATE + ((FLOOR((registration_date::DATE - '2021-01-01'::DATE) / 7) * 7) + 6)::INT AS week_end,
    COUNT(runner_id) AS total_runners
FROM runners
GROUP BY 1, 2
ORDER BY 1;
```
**Result:**

<img width="450" height="152" alt="1" src="https://github.com/user-attachments/assets/a231acbd-6345-4785-82b2-37061018e875" /><br>

**2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?**
- JOIN `customer_orders` to get each order’s `order_time`, then converted the time gap referred as `prep_time` from an interval to minutes with EXTRACT(EPOCH ...) / 60 so it could be averaged

```SQL
SELECT 
    r.runner_id, 
    ROUND(AVG(EXTRACT(EPOCH FROM (r.pickup_time - c.order_time)) / 60::INT),2) AS prep_time
FROM runner_orders r
INNER JOIN customer_orders c
    ON r.order_id = c.order_id
WHERE r.cancellation IS NULL
GROUP BY r.runner_id;
```
**Result:**

<img width="296" height="150" alt="2" src="https://github.com/user-attachments/assets/4a41da36-cc72-4bcf-8fdd-b352cf4951ec" /><br>


**3. Is there any relationship between the number of pizzas and how long the order takes to prepare?**
- Create a CTE called `pizza_prep_time` that groups orders by `pizza_count` and averages the prep time
- Subtract `order_time` from `pickup_time`, convert it to minutes with EXTRACT(EPOCH ...) / 60 (turns seconds into minutes) and rounds to 2 decimals
  
```SQL
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
```
**Result:**

<img width="341" height="158" alt="3 2" src="https://github.com/user-attachments/assets/84d33cd8-7e5c-4c34-ba7d-79d4c3e133cf" /><br>

- A single pizza roughly takes 12 minutes to prepare, 2 pizzas take about 18 minutes and 3 pizzas take about 29 minutes.
- We can roughly concluded that it takes about 10 minutes to prepare each pizza.

**4. What was the average distance travelled for each customer?**
- JOIN `customer_orders` to get each order’s customer, since `runner_orders` has the distance but not `customer_id`
- Relied on AVG ignoring NULL distances, so cancelled orders are excluded without a separate filter
- Cast to NUMERIC so ROUND(..., 2) works

```SQL
SELECT DISTINCT(c.customer_id), ROUND(AVG(r.distance_km)::NUMERIC,2) AS avg_distance FROM runner_orders r   
INNER JOIN customer_orders c 
    ON r.order_id = c.order_id
GROUP BY c.customer_id
ORDER BY c.customer_id;
```
**Result:**

<img width="335" height="204" alt="4" src="https://github.com/user-attachments/assets/4229a8f2-4fb4-4832-a15c-cd7cbdfda00a" /><br>

**5. What was the difference between the longest and shortest delivery times for all orders?**
```SQL
SELECT 
    MIN(duration_mins) AS shortest_time, 
    MAX(duration_mins) AS longest_time, 
    (MAX(duration_mins) - MIN(duration_mins)) AS time_difference 
FROM runner_orders;
```
**Result:**

<img width="516" height="104" alt="5" src="https://github.com/user-attachments/assets/150b3c02-88df-4fbd-adbe-640dd9d8398f" /><br>

**6. What was the average speed for each runner for each delivery and do you notice any trend for these values?**
- JOIN `customer_orders` to `runner_orders` and keeps only delivered orders.
- `r.distance_km * 60 / r.duration_mins` converts speed to km/h. Duration is in minutes, so multiplying distance by 60 first is the same as dividing distance by hours.
- GROUP BY includes `order_id`, so you get one row per delivery, and COUNT(*) gives the number of pizzas in that delivery.

```SQL
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
```
**Result:**

<img width="856" height="272" alt="6" src="https://github.com/user-attachments/assets/7aa9e6bc-ac97-4820-a9fc-a7f7dcf12954" /><br>

- Runner 1's average speed is from 38km/h to 60km/h.
- Runner 2's average speed is from 35km/h to 94km/h.
- Runner 3's average speed is 40km/h.
- Runner 2 has the highest average speed, however for the same distance, runner 2 speed fluctuates.

**7. What is the successful delivery percentage for each runner?**
- Use a CTE called `success_rate` to act as a tracker for the total of successful delivery attempts using a SUM(CASE...) combination
- `successful_attempts * 100.0/total_attempts` calculates for the percentage rate and ROUND keeps it to 2 decimal places
  
```SQL
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
```
**Result:**

<img width="758" height="150" alt="7" src="https://github.com/user-attachments/assets/54c678d0-a3fd-4c7b-aeab-5525dad1d642" /><br>

### C. Ingredient Optimisation
**1. What are the standard ingredients for each pizza?**

```SQL
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
```
**Result:**

<img width="314" height="436" alt="1" src="https://github.com/user-attachments/assets/5f6e3938-2c74-4be0-8abd-acc9f3460b56" /><br>

**2. What was the most commonly added extra?**

```SQL
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
```
**Result:**

<img width="579" height="170" alt="2" src="https://github.com/user-attachments/assets/2d06fd51-21e5-4960-9ca1-3130c2b8f431" /><br>

**3. What was the most common exclusion?**

```SQL
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
```
**Result:**

<img width="631" height="173" alt="3" src="https://github.com/user-attachments/assets/96c74bd3-53f1-48c5-b93e-d83c65600c42" /><br>

**4. Generate an order item for each record in the `customers_orders` table in the format of one of the following:**<br>
   **- `Meat Lovers`**<br>
   **- `Meat Lovers - Exclude Beef`**<br>
   **- `Meat Lovers - Extra Bacon`**<br>
   **- `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`**<br>

```SQL
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
```
**Result:**

<img width="1015" height="371" alt="4" src="https://github.com/user-attachments/assets/556a80db-47ce-41d0-a9b0-2aad75507cc0" /><br>

**6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?**

```SQL
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
```
**Result:**

<img width="324" height="380" alt="6" src="https://github.com/user-attachments/assets/313871a8-2f0f-401a-bf78-53bbdaa6381b" /><br>

### D. Pricing and Ratings
**1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?**
```SQL
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
```
**Result:**

<img width="179" height="122" alt="1" src="https://github.com/user-attachments/assets/b474293f-4b72-4c66-99f8-b0a0bdcbd78e" /><br>

**2. What if there was an additional $1 charge for any pizza extras?**
   **- Add cheese is $1 extra**
```SQL
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
```
**Result:**

<img width="174" height="119" alt="2" src="https://github.com/user-attachments/assets/b4108ee2-a586-4016-a8a0-f3b11ff7e445" /><br>

**3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.**
```SQL
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
```
**Result:**

<img width="266" height="331" alt="3" src="https://github.com/user-attachments/assets/af9b13cf-13f2-445d-95f8-dd35fb933e05" /><br>

**4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?** <br>
   **- `customer_id`**<br>
   **- `order_id`**<br>
   **- `runner_id`**<br>
   **- `rating`**<br>
   **- `order_time`**<br>
   **- `pickup_time`**<br>
   **- Time between order and pickup**<br>
   **- Delivery duration**<br>
   **- Average speed**<br>
   **- Total number of pizzas**<br>
```SQL
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
```
**Result:**

<img width="1379" height="278" alt="4" src="https://github.com/user-attachments/assets/539a9ce9-6476-4654-86ac-32f4252690ca" /><br>

**5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?**
```SQL
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
```
**Result:**

<img width="199" height="117" alt="5" src="https://github.com/user-attachments/assets/f444fdc5-6c3d-467d-a2e3-8b5068bc0eb4" /><br>

### E. Bonus Questions
**If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?**
```SQL
INSERT INTO pizza_recipes (pizza_id, toppings) 
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

SELECT pn.pizza_id, pn.pizza_name, pr.toppings FROM pizza_names pn 
INNER JOIN pizza_recipes pr 
    ON pn.pizza_id = pr.pizza_id;
```
**Result:**

<img width="437" height="152" alt="1" src="https://github.com/user-attachments/assets/3b0828f2-a4a7-4b49-8f25-26432e45df1a" /><br>
<img width="295" height="156" alt="2" src="https://github.com/user-attachments/assets/fe0c6fdc-bfaa-41ca-94e8-ccd1c2320aae" /><br>
<img width="573" height="152" alt="3" src="https://github.com/user-attachments/assets/a3a815bd-8948-4139-bf8e-2569c34241f6" /><br>

## Challenges

## Key Takeaways
