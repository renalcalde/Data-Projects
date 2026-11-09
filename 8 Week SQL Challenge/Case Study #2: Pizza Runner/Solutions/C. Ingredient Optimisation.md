
<div align="center">
  
# C. Ingredient Optimisation
*Note: Not all questions from this section was answered, specifically, Question 5 was omitted.*

</div>
<br>



**1. What are the standard ingredients for each pizza?**
- Use UNNEST(STRING_TO_ARRAY(`toppings`, ',')) to split each comma-separated string of `topping_ids` into an array, then expand the array into one row per topping. Without this, multiple toppings stay packed in a single cell and can’t be counted or joined.
- Wrapped the result in TRIM to remove the leading spaces left over from the comma separation

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
- Create a CTE called `extra_topping_cte` that applies the same TRIM(UNNEST(STRING_TO_ARRAY(...))) logic to the extras column and uses COUNT(*) to count how often each topping was added across all customer orders
- Joined to `pizza_toppings` on `topping_id` so the output shows topping names instead of IDs, and sorted by count in descending order so the most popular extra appears first

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
- Bacon is the most commonly added ingredient (added 4 times)

**3. What was the most common exclusion?**
- Reused the same approach as Question 2, swapping `extras` for `exclusions`

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
- Cheese is the most commonly excluded ingredient (excluded 4 times)

**4. Generate an order item for each record in the `customers_orders` table in the format of one of the following:**<br>
   **- `Meat Lovers`**<br>
   **- `Meat Lovers - Exclude Beef`**<br>
   **- `Meat Lovers - Extra Bacon`**<br>
   **- `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`**<br>

- Convert comma-separated topping IDs into names with STRING_TO_ARRAY, a cast to int[], and STRING_AGG, so each order shows readable toppings instead of IDs.
- Built the order description with || and COALESCE, so orders without exclusions or extras skip that segment instead of returning NULL.

```SQL
SELECT
    c.order_id,
    c.pizza_id,
    c.exclusions,
    c.extras,
    pn.pizza_name
        || COALESCE(' - Exclude ' || (
            SELECT STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name)
            FROM pizza_toppings pt 
            WHERE pt.topping_id = ANY (
                STRING_TO_ARRAY(REPLACE(c.exclusions, ' ', ''), ',')::int[]
            )
        ), '')
        || COALESCE(' - Extra ' || (
            SELECT STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name)
            FROM pizza_toppings pt 
            WHERE pt.topping_id = ANY (
                STRING_TO_ARRAY(REPLACE(c.extras, ' ', ''), ',')::int[]
            )
        ), '') AS order_item
FROM customer_orders c
INNER JOIN pizza_names pn
    ON pn.pizza_id = c.pizza_id
INNER JOIN runner_orders r 
    ON r.order_id = c.order_id
WHERE r.cancellation IS NULL OR r.cancellation IN ('', 'null')
ORDER BY c.order_id;
```
**Result:**

<img width="1015" height="371" alt="4" src="https://github.com/user-attachments/assets/556a80db-47ce-41d0-a9b0-2aad75507cc0" /><br>

**6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?**
- Create a CTE called `pizza_toppings_cte` that uses TRIM(UNNEST(STRING_TO_ARRAY(...))) to turn each pizza’s topping list into one row per topping
- Filter for successful deliveries only and sorted by COUNT in descending order so the most frequent ingredient is at the top

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
