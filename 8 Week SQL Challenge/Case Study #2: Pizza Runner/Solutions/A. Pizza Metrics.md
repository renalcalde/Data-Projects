<div align="center">
  
# A. Pizza Metrics

</div>

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
- JOIN `customer_orders` with `runner_orders` and filtered on `cancellation` is NULL so only delivered pizzas are counted
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
- Meatlovers tend to be the most frequently ordered pizza

**5. How many Vegetarian and Meatlovers were ordered by each customer?**
- Use COUNT + CASE to act as a tracker for each pizza type in a single pass, instead of one query per type
  
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
- GROUP BY `order_id` to count pizzas per order, then sort in descending order with LIMIT 1 so it only returns a single line with the highest pizza count

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
- Use COUNT + CASE to act as a tracker for the number of times an order has a change or no changes in a single pass, than running two separate queries
- JOIN to `runner_orders` and filter on `cancellation` is NULL so only delivered pizzas are counted

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
- JOIN to `runner_orders` and filtered on `cancellation` is NULL so only delivered pizzas are counted
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
- High volume orders seem to take place in the afternoon (1 and 6 PM) and late evening (9 and 11 PM)

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
- Wednesday has the highest volume of orders (5), compared to the weekend like Friday (1) and Saturday (2)


