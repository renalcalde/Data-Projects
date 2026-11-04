/*
8 WEEK SQL CHALLENGE
CASE STUDY #1: DANNY'S DINER
*/

-- Q1
SELECT sales.customer_id, SUM(menu.price) as total_spending FROM sales
INNER JOIN menu
    ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;

-- Q2
SELECT customer_id, COUNT(DISTINCT order_date) FROM sales
GROUP BY customer_id
ORDER BY customer_id ASC;

-- Q3
WITH first_purchase AS (
    SELECT 
        s.customer_id, 
        s.order_date, 
        m.product_name,
        DENSE_RANK() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.order_date ASC, s.customer_id ASC
        ) as purchase_rank
    FROM sales s
    INNER JOIN menu m
        ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name, s.order_date
    ORDER BY s.customer_id
)

SELECT customer_id, order_date, product_name FROM first_purchase 
WHERE purchase_rank = 1;

-- Q4
SELECT menu.product_name, COUNT(sales.product_id) FROM sales
INNER JOIN menu
    ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY COUNT(sales.product_id) DESC
LIMIT 1;

-- Q5
WITH first_pruchase AS (
    SELECT 
        s.customer_id, 
        COUNT(s.product_id) AS order_count, 
        m.product_name,
        DENSE_RANK() OVER (
            PARTITION BY s.customer_id
            ORDER BY COUNT(s.product_id) DESC
        ) as purchase_rank
    FROM sales s
    INNER JOIN menu m
        ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
    ORDER BY s.customer_id
)
SELECT customer_id, order_count, product_name FROM first_pruchase 
WHERE purchase_rank = 1;

-- Q6
WITH first_purchase AS(
    SELECT
        mb.customer_id,
        mb.join_date,
        s.order_date,
        m.product_name,
        DENSE_RANK() OVER(
            PARTITION BY mb.customer_id
            ORDER BY s.order_date, mb.customer_id
        ) as purchase_rank
    FROM members mb 
    INNER JOIN sales s
        ON mb.customer_id = s.customer_id
    INNER JOIN menu m 
        ON m.product_id = s.product_id
    WHERE s.order_date > mb.join_date
    ORDER BY mb.customer_id, s.order_date
)

SELECT customer_id, join_date, order_date, product_name FROM first_purchase
WHERE purchase_rank = 1;

-- Q7
WITH latest_purchase AS(
    SELECT
        mb.customer_id,
        mb.join_date,
        s.order_date,
        m.product_name,
        DENSE_RANK() OVER(
            PARTITION BY mb.customer_id
            ORDER BY s.order_date DESC, mb.customer_id
        ) as purchase_rank
    FROM members mb 
    INNER JOIN sales s
        ON mb.customer_id = s.customer_id
    INNER JOIN menu m 
        ON m.product_id = s.product_id
    WHERE s.order_date < mb.join_date
    ORDER BY mb.customer_id, s.order_date
)

SELECT customer_id, join_date, order_date, product_name FROM latest_purchase
WHERE purchase_rank = 1;

-- Q8
SELECT mb.customer_id, COUNT(s.product_id) AS order_count, SUM(m.price) AS total_spend FROM members mb
INNER JOIN sales s
    ON mb.customer_id = s.customer_id
INNER JOIN menu m 
    ON m.product_id = s.product_id
WHERE mb.join_date > s.order_date
GROUP BY mb.customer_id, s.customer_id
ORDER BY s.customer_id;

-- Q9
SELECT
    s.customer_id,
    SUM(
        CASE
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS total_points_earned
FROM sales s 
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY customer_id;

-- Q10
SELECT
    mb.customer_id,
    SUM(
        CASE
            WHEN s.order_date BETWEEN mb.join_date AND mb.join_date + INTERVAL '6 days' THEN m.price * 20 -- strictly looks at a time window
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END
    ) AS total_points_earned
FROM members mb 
INNER JOIN sales s ON mb.customer_id = s.customer_id
INNER JOIN menu m ON s.product_id = m.product_id
WHERE EXTRACT(MONTH FROM s.order_date) = 1
GROUP BY mb.customer_id
ORDER BY customer_id;

-- BONUS QUESTIONS

-- Q1 JOIN ALL THE THINGS
SELECT 
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN mb.join_date <= s.order_date THEN 'Y'
        ELSE 'N'
    END AS member
FROM members mb
FULL JOIN sales s ON mb.customer_id = s.customer_id 
FULL JOIN menu m ON s.product_id = m.product_id
ORDER BY s.customer_id, s.order_date;

-- Q2 RANK ALL THE THINGS
WITH member_status AS (
    SELECT 
        s.customer_id,
        s.order_date,
        m.product_name,
        m.price,
        CASE
            WHEN mb.join_date <= s.order_date THEN 'Y'
            ELSE 'N'
        END AS member
    FROM members mb
    FULL JOIN sales s ON mb.customer_id = s.customer_id 
    FULL JOIN menu m ON s.product_id = m.product_id
    ORDER BY s.customer_id, s.order_date
),
ranking_status AS (
    SELECT
        customer_id,
        order_date,
        product_name,
        price,
        member,
        CASE
            WHEN member = 'Y' THEN 
            RANK() OVER(
                PARTITION BY customer_id, member
                ORDER BY order_date
            )
            ELSE NULL
        END AS ranking
    FROM member_status
)

SELECT customer_id, order_date, product_name, price, member, ranking FROM ranking_status;