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
- [Challenge](#challenges)
- [Key Takeaway](#key-takeaways)
  
## Objective
This case study analyzes Pizza Runner’s order, runner, and delivery data to uncover insights on customer ordering behavior, runner performance, ingredient usage, and revenue, so Danny can make data-driven decisions to grow his pizza delivery business.

## Entity Relationship Diagram
There are 6 key datasets for this case study:
- `runners` : shows the `registration_date` for each new runner
- `customer_orders` : displays all customer pizza orders, with one row for each individual pizza that is part of the order
- `runner_orders` : after each order is received through the system, they are assigned to a runner, however not all orders are fully complete and can be cancelled by the restaurant or the customer
- `pizza_names` : Pizza Runner only has 2 pizzas available, the Meat Lovers or Vegeterian
- `pizza_recipes` : Each `pizza_id` has a standard set of `toppings` which are used as part of the pizza recipe
- `pizza_toppings` : Contains all of the `topping_name` values with their corresponding `topping_id` value

<p align="center">
<img src="png/entity_relationship_diagram.png" alt="Entity Relationship Diagram" width="800">
</p>

## Data Cleaning
Before investigating the data, I had to clean the dataset by handling the `null` values and data types in the `customer_orders` and `runner_orders` tables.
```SQL
-- CLEANS customer_orders TABLE
-- replaces all empty rows and capitalize null into NULL
UPDATE customer_orders
SET exclusions = NULL
WHERE TRIM(exclusions) = '' OR TRIM(exclusions) = 'null';

UPDATE customer_orders
SET extras = NULL
WHERE TRIM(extras) = '' OR TRIM(extras) = 'null';

-- CLEANS runner_orders TABLE
-- change columns to show metrics
ALTER TABLE runner_orders
RENAME COLUMN distance TO distance_km;

ALTER TABLE runner_orders
RENAME COLUMN duration TO duration_mins;
 
-- adds NULL 
UPDATE runner_orders
SET pickup_time = NULL
WHERE TRIM(pickup_time) = '' OR TRIM(pickup_time) = 'null';

UPDATE runner_orders
SET distance_km = NULL
WHERE TRIM(distance_km) = '' OR TRIM(distance_km) = 'null';

UPDATE runner_orders
SET duration_mins = NULL
WHERE TRIM(duration_mins) = '' OR TRIM(duration_mins) = 'null';

UPDATE runner_orders
SET cancellation = NULL
WHERE TRIM(cancellation) = '' OR TRIM(cancellation) = 'null';

-- removes km inside columns
UPDATE runner_orders
SET distance_km = REPLACE(distance_km, 'km', '')
WHERE distance_km LIKE '%km%';

-- removes minutes inside columns
UPDATE runner_orders
SET duration_mins = REPLACE(duration_mins, 'minute', '')
WHERE duration_mins LIKE '%min%';

UPDATE runner_orders
SET duration_mins = REPLACE(duration_mins, 'minutes', '')
WHERE duration_mins LIKE '%min%';

UPDATE runner_orders
SET duration_mins = REPLACE(duration_mins, 'mins', '')
WHERE duration_mins LIKE '%min%';

-- changes all the type to the appropriate type
ALTER TABLE runner_orders
ALTER COLUMN duration_mins TYPE INT USING duration_mins::INT;

ALTER TABLE runner_orders
ALTER COLUMN distance_km TYPE FLOAT USING distance_km::FLOAT;

ALTER TABLE runner_orders
ALTER COLUMN pickup_time TYPE TIMESTAMP USING pickup_time::TIMESTAMP;
```


## Question and Solution
### A. Pizza Metrics
**1. How many pizzas were ordered?**
```SQL
SELECT COUNT(*) FROM customer_orders;
```
**Approach:**

**Result:**

**2. How many unique customer orders were made?**
```SQL
SELECT COUNT(DISTINCT order_id) FROM customer_orders;
```
**Approach:**

**Result:**

**3. How many successful orders were delivered by each runner?**
```SQL
SELECT runner_id, COUNT(*) FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;
```
**Approach:**

**Result:**

**4. How many of each type of pizza was delivered?**
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
**Approach:**

**Result:**

**5. How many Vegetarian and Meatlovers were ordered by each customer?**
```SQL
SELECT 
    c.customer_id,
    COUNT(CASE WHEN c.pizza_id = 1 THEN 1 END) AS meat_lover_count,
    COUNT(CASE WHEN c.pizza_id = 2 THEN 1 END) AS vegeterian_count
FROM customer_orders c 
INNER JOIN pizza_names pn 
    ON c.pizza_id = pn.pizza_id
GROUP BY c.customer_id
ORDER BY c.customer_id;
```
**Approach:**

**Result:**

**6. What was the maximum number of pizzas delivered in a single order?**
```SQL
SELECT count(c.pizza_id) AS pizza_count FROM customer_orders c
INNER JOIN runner_orders r 
    ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.order_id, c.order_time
ORDER BY pizza_count DESC
LIMIT 1;
```
**Approach:**

**Result:**

**7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?**
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
**Approach:**

**Result:**

**8. How many pizzas were delivered that had both exclusions and extras?**
```SQL
SELECT COUNT(*) FROM customer_orders c 
INNER JOIN runner_orders r 
    ON c.order_id = r.order_id
WHERE c.exclusions IS NOT NULL 
    AND c.extras IS NOT NULL 
    AND r.cancellation is NULL;
```
**Approach:**

**Result:**

**9. What was the total volume of pizzas ordered for each hour of the day?**
```SQL
SELECT
    EXTRACT (HOUR FROM order_time) AS hour_of_day,
    COUNT(*) AS total_vol_of_pizza
FROM customer_orders
GROUP BY 
    EXTRACT (HOUR FROM order_time) 
ORDER BY hour_of_day;
```
**Approach:**

**Result:**

**10. What was the volume of orders for each day of the week?**
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
**Approach:**

**Result:**

### B. Runner and Customer Experience
### C. Ingredient Optimisation
### D. Pricing and Ratings
### E. Bonus Question

## Challenges

## Key Takeaways
