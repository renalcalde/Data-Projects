<div align="center">
  
# B. Runner and Customer Experience

</div>

**1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)**
- Use `'2021-01-01'` as a fixed anchor instead of DATE_TRUNC('week', ...), since the question defines weeks starting on that date, whereas DATE_TRUNC('week', ...) starts weeks on Monday

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
- JOIN `customer_orders` to get each order’s `order_time`, since `runner_orders` only has the pickup time
- Subtract `order_time` from `pickup_time` to get prep time, convert prep time from an interval to minutes with EXTRACT(EPOCH ...) / 60, since an interval can’t be averaged directly and round to 2 decimals for readability

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
- Create a CTE called `pizza_prep_time` that groups orders by `pizza_count` and AVG the prep time using EXTRACT(EPOCH ...) / 60 and ROUND to 2 decimal places
  
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
- A single pizza roughly takes 12 minutes to prepare, 2 pizzas take about 18 minutes and 3 pizzas take about 29 minutes. While we can't concluded a concrete prep time with pizza count, the data demonstrates an upward trend.

**4. What was the average distance travelled for each customer?**
- JOIN `customer_orders` to get each order’s customer, since `runner_orders` has the distance but not `customer_id`
- Relied on AVG ignoring NULL distances, so cancelled orders are excluded without a separate filter
- Cast to NUMERIC, to retrieve an exact decimal, not a whole number and ROUND to 2 decimal places for readability

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
- JOIN `customer_orders` to `runner_orders` and keep only delivered orders
- `r.distance_km * 60 / r.duration_mins` converts speed to km/h, `duration` is in minutes, so multiplying distance by 60 first is the same as dividing distance by hours
- GROUP BY `order_id` to get one row per delivery, so COUNT(*) gives the number of pizzas in each delivery

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
- Runner 1's average speed is from 38km/h to 60km/h. Runner 2's average speed is from 35km/h to 94km/h. Runner 3's average speed is 40km/h.
- Runner 2 has the highest average speed, however for the same distance, Runner 2's speed fluctuates.

**7. What is the successful delivery percentage for each runner?**
- Use a CTE called `success_rate` to act as a tracker for the total and successful deliveries using SUM(CASE WHEN...)
- Calculate the percentage as `successful_attempts * 100.0/total_attempts` 
  
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

