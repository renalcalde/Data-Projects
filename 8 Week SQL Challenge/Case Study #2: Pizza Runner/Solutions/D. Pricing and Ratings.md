<div align="center">
  
# D. Pricing and Ratings

</div>

**1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?**
- Use a CASE statement to assign each `pizza_id` its price, then SUM to total the revenue across orders
  
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
- Created a CTE called `count_modification_cte` that counts the extras on each order
- Reuse the SUM + CASE pricing logic and added the extras count, since each extra adds a $1 charge

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
- Create a TABLE called `ratings` with order_id and rating as INT, since ratings are whole numbers and decimal precision is not required
- Use INSERT to add the values, then SELECT to confirm the data loaded correctly

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
- Create two subqueries, one that SUMs the total revenue of all pizza deliveries and one that SUMs each runner earnings by the total distance they traveled multiplied by $0.30
- Subtract the runner earnings from revenue to get the remaining profit 
  
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
            ROUND((SUM(distance_km) * 0.30)::NUMERIC,2) AS runner_earnings
        FROM runner_orders
    ) AS net_revenue;
```
**Result:**

<img width="199" height="117" alt="5" src="https://github.com/user-attachments/assets/f444fdc5-6c3d-467d-a2e3-8b5068bc0eb4" /><br>

