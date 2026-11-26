# 🌲 Case Study #7: Balanced Tree Clothing Co.

<p align="center">
  <img src="png/balance_tree_poster.png" alt="Balanced Tree Clothing Co. Poster" width="500"><br>
  <strong>Source:</strong> <a href="https://8weeksqlchallenge.com/case-study-7/">8 Week SQL Challenge: Case Study #7 - Balanced Tree Clothing Co.</a>
</p>

## Table of Contents
- [Objective](#objective)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question & Solution](#question-and-solution)
- [Key Takeaways](#key-takeaways)
- [Challenges](#challenges)

## Objective
CEO Danny needs help to expand his trendy fashion company, Balanced Tree Clothing Co. designed for modern adventurers, analyze their sales performance and generate a basic monthly financial report. 

## Entity Relationship Diagram
There is a total of 4 datasets for this case study, however, we will be utilizing two for the majority of the analysis:
- `product_details` : includes all information about the entire products that Balanced Clothing sells in their store
- `product_sales` : contains product information for all the transactions made for Balanced Tree
  
The following two tables will be used for the bonus question:
- `product_hierarcy` 
- `product_price`

<p align="center">
<img src="png/entity_relationship_diagram.png" alt="Entity Relationship Diagram" width="800">
</p>

## Question and Solution

### A. High Level Sales Analysis

<details>
  <summary>View Solutions</summary>

  **Q1. What was the total quantity sold for all products?**
  - Use SUM() to get the total count quantity of products across all rows rather than using COUNT() which will only count one product per row

  ```SQL
  SELECT SUM(qty) AS total_qty FROM sales;
  ```

  **Result**:
  
  <img width="165" height="65" alt="1" src="https://github.com/user-attachments/assets/671e89f5-2a8e-4a4a-a29c-8069bbe75dec" /><br>
  - The total quantity sold for all products is 45,216.
  
  
  **Q2. What is the total generated revenue for all products before discounts?**
  - Total Revenue = Quantity Sold x Price Per Product
  - Multiply `qty` to `price` and use SUM() to get the total revenue for all products
  
  ```SQL
  SELECT
      ROUND(SUM(qty * price), 2) AS gross_revenue
  FROM sales;
  ```
  
  **Result**:
  
  <img width="191" height="63" alt="2" src="https://github.com/user-attachments/assets/6fab7d46-b6e3-480b-9a83-49606751ab70" /><br>
  - The total revenue for all products before discounts are applied is $1,289,453.
  
  
  **Q3. What was the total discount amount for all products?**
  - Total Discount Amount = Σ(Original Price x Discount % / 100 x Quantity)
  - Use the equation above and wrap it in a SUM() to apply for all products
  
  ```SQL
  SELECT 
      ROUND(SUM(price * (discount / 100.0) * qty), 2) AS total_discount_amt
  FROM sales;
  ```
  
  **Result**:
  
  <img width="230" height="64" alt="3" src="https://github.com/user-attachments/assets/fc079ce4-4fcc-4140-b7cd-56a1bfdfad2f" /><br>
  - The total discount amount for all products is $156,229.14.


</details>

### B. Transaction Analysis

<details>
  <summary>View Solutions</summary>
  
  **Q1. How many unique transactions were there?**
  - Use COUNT() + DISTINCT to get the total count of unique transactions

  ```SQL
  SELECT COUNT(DISTINCT txn_id) AS total_txn FROM sales;
  ```

  **Result**:
  
  <img width="165" height="64" alt="1" src="https://github.com/user-attachments/assets/ed0fc08b-cf0a-48dc-a71d-744920f72539" /><br>
  - There is a total of 2,500 unique transactions.

  
  **Q2. What is the average unique products purchased in each transaction?**
  - Count the number of unique `prod_id` with COUNT() and GROUP BY `txn_id`
  - Wrap the number of unique products in AVG() to get the average count
  
  ```SQL
  WITH count_cte AS(
    SELECT 
        txn_id,
        COUNT(DISTINCT prod_id) AS product_count
    FROM sales
    GROUP BY txn_id
  )
  SELECT
      ROUND(AVG(product_count)) AS avg_product_count
  FROM count_cte;
  ```

  **Result**:
  
  <img width="223" height="64" alt="2" src="https://github.com/user-attachments/assets/e7165f99-9c34-48f6-b5f8-ee9b9a372872" /><br>
  - On average, 6 unique products were purchased in each transaction.
  
  
  **Q3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?**
  - Calculate the total revenue before discounts and GROUP BY transactions
  - Use PERCENTILE_CONT() to calculate the 25th, 50th, and 75th percentile values 
  
  ```SQL
  WITH revenue_cte AS(
      SELECT
          txn_id,
          SUM(qty * price) AS revenue
      FROM sales
      GROUP BY txn_id
  )
  SELECT
      ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue)::NUMERIC, 2) AS percentile_25,
      ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue)::NUMERIC, 2) AS percentile_50,
      ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue)::NUMERIC, 2) AS percentile_75
  FROM revenue_cte;
  ```

  **Result**:
  
  <img width="506" height="65" alt="3" src="https://github.com/user-attachments/assets/99c0c492-1e83-4fe7-9152-2e6a1206294e" /><br>
  - At the 25th percentile, the total revenue per transaction is $375.75. In the 50th percentile (median), the value is $509.50. In the 75th percentile, the value is $647.00. This demonstrates a gradual growth throughout the percentiles.

  
  **Q4. What is the average discount value per transaction?**
  - Calculate for the total discount amount and GROUP BY transactions
  - Use AVG() to get the average discount value per transaction
  
  ```SQL
  WITH discount_cte AS(
      SELECT
          txn_id,
          SUM(price * (discount / 100.0) * qty) AS total_discount_amt
      FROM sales
      GROUP BY txn_id
  )
  SELECT
      ROUND(AVG(total_discount_amt), 2) AS avg_discount_val
  FROM discount_cte;
  ```

  **Result**:
  
  <img width="215" height="68" alt="4" src="https://github.com/user-attachments/assets/01d3328a-2ef1-4fa4-b917-333268afbb33" /><br>
  - The average discount value is $62.49 per transactions.
  
  
  **Q5. What is the percentage split of all transactions for members vs non-members?**
  - Use CASE to group members and non-members
  - COUNT() the number of members for each group and CAST to NUMERIC since the `member` column is a a boolean data type
  - For the denominator, use a subquery to divide by the total count of members in the `sales` table
  
  ```SQL
  SELECT 
      CASE
          WHEN member = TRUE THEN 'member'
          WHEN member = FALSE THEN 'non-member'
          ELSE NULL 
      END AS member_type,
      ROUND(COUNT(member)::NUMERIC * 100.0 / (SELECT COUNT(member) FROM sales), 2) AS pct
  FROM sales
  GROUP BY     
      CASE
          WHEN member = TRUE THEN 'member'
          WHEN member = FALSE THEN 'non-member'
          ELSE NULL 
      END;
  ```

  **Result**:
  
  <img width="262" height="87" alt="5" src="https://github.com/user-attachments/assets/8fca66ab-829b-4d76-93e6-bd293cbe09c6" /><br>
  - Members contribute 60.03% of all transactions while non-members contribute 39.97%.

  
  **Q6. What is the average revenue for member transactions and non-member transactions?**
  - Use a CASE to sort out members and non-members
  - Calculate for the total revenue before discounts for each transaction by using a GROUP BY on member types and transactions
  - Use AVG() to find the average revenue 
  
  ```SQL
  WITH revenue_cte AS(
  SELECT 
      CASE
          WHEN member = TRUE THEN 'member'
          WHEN member = FALSE THEN 'non-member'
          ELSE NULL 
      END AS member_type,
      txn_id,
      SUM(qty * price) AS revenue
  FROM sales
  GROUP BY txn_id,     
      CASE
          WHEN member = TRUE THEN 'member'
          WHEN member = FALSE THEN 'non-member'
          ELSE NULL 
      END
  )
  SELECT 
      member_type,
      ROUND(AVG(revenue), 2) AS avg_revenue
  FROM revenue_cte
  GROUP BY member_type;
  ```

  **Result**:
  
  <img width="322" height="88" alt="6" src="https://github.com/user-attachments/assets/b0164059-3fb8-470e-a0f0-af7f99aa802b" /><br>
  - The average gross revenue for members is $516.27 compared to non-members with $515.04.

  
</details>

### C. Product Analysis
<details>
  <summary>View Solutions</summary>

  **Q1. What are the top 3 products by total revenue before discount?**
- Calculate the gross revenue and GROUP BY the product id and name
- ORDER BY the gross revenue in descending order so that the highest value is at the top and LIMIT to the top 3

```SQL
SELECT
    s.prod_id AS product_id,
    d.product_name,
    ROUND(SUM(s.qty * s.price), 2) AS gross_revenue
FROM sales s
INNER JOIN product_details d
    ON s.prod_id = d.product_id
GROUP BY d.product_name, s.prod_id
ORDER BY gross_revenue DESC
LIMIT 3;
```

**Result**:

<img width="537" height="111" alt="1" src="https://github.com/user-attachments/assets/6fa8c59b-7de4-42f3-bf04-002ded608342" /><br>
- Men's Blue Polo Shirt has the highest grossing revenue of $217,683. Followed by Women's Grey Fashion Jacket with $209,304 and Men's White Tee Shirt with $152,000.


**Q2. What is the total quantity, revenue and discount for each segment?**
- Use SUM() on `qty` to get the total quantity for each segment
- Calculate the gross revenue and total discount amount
- JOIN with `product_details` to GROUP BY `segment_id` and `segment_name`

```SQL
SELECT
    d.segment_id,
    d.segment_name,
    SUM(s.qty) AS total_qty,
    ROUND(SUM(s.qty * s.price), 2) AS gross_revenue,
    ROUND(SUM(s.price * (s.discount / 100.0) * s.qty), 2) AS discount_amt
FROM sales s
INNER JOIN product_details d
    ON s.prod_id = d.product_id
GROUP BY d.segment_id, d.segment_name
ORDER BY d.segment_id;
```

**Result**:

<img width="751" height="133" alt="2" src="https://github.com/user-attachments/assets/2919118b-cce5-4311-893a-f59728e2d63d" /><br>
- Jackets had the highest quantity (11,385) while shirts have the highest grossing revenue ($406,143.00) and total discount amount ($4,9594.27).
- Socks had the lowest total quantity (11,217), along with jeans with the lowest grossing revenue ($208,350.00) and total discount amount ($25,343.97).


**Q3. What is the top selling product for each segment?**
- Use SUM() to get the total quantity for each segment
- Use DENSE_RANK() to rank the products in each segment by the total quantity in descending order and LIMIT to 1 so only the highest product shows

```SQL
WITH rank_cte AS(
    SELECT
        d.segment_id,
        d.segment_name,
        d.product_id,
        d.product_name,
        SUM(s.qty) AS total_qty,
        DENSE_RANK()OVER(PARTITION BY d.segment_id ORDER BY SUM(s.qty) DESC) AS rn
    FROM sales s
    INNER JOIN product_details d
        ON s.prod_id = d.product_id
    GROUP BY d.segment_id, d.segment_name, d.product_id, d.product_name

)
SELECT 
    segment_id, 
    segment_name, 
    product_id, 
    product_name, 
    total_qty
FROM rank_cte
WHERE rn = 1
ORDER BY segment_id;
```

**Result**:

<img width="799" height="137" alt="3" src="https://github.com/user-attachments/assets/f1bd1e5f-db13-43ad-a10b-1ef1bd08db5b" /><br>
- Jackets has the highest quantity sold with their most popular item being Women's Grey Fashion Jacket, selling 3,876 quantities.


**Q4. What is the total quantity, revenue and discount for each category?**
- Calculate the total quantity, gross revenue and discount using SUM() and GROUP BY the category

```SQL
SELECT
    d.category_id,
    d.category_name,
    SUM(s.qty) AS total_qty,
    ROUND(SUM(s.qty * s.price), 2) AS gross_revenue,
    ROUND(SUM(s.price * (s.discount / 100.0) * s.qty), 2) AS discount_amt
FROM sales s
INNER JOIN product_details d
    ON s.prod_id = d.product_id
GROUP BY d.category_id, d.category_name
ORDER BY d.category_id;
```

**Result**:

<img width="769" height="92" alt="4" src="https://github.com/user-attachments/assets/4c39e963-cc93-4f30-a7e7-9d374dca35a1" /><br>
- Womens sold the highest total quantity of 22,734. But mens have the highest grossing revenue of $714,120 with a total discount amount of $86,607.71.


**Q5. What is the top selling product for each category?**
- Calculate the total quantity using SUM()
- Use a DENSE_RANK() to rank the products in `category_id` by the total quantity in descending order and LIMIT to 1 to get the highest value

```SQL
WITH rank_cte AS(
    SELECT
        d.category_id,
        d.category_name,
        d.product_id,
        d.product_name,
        SUM(s.qty) AS total_qty,
        DENSE_RANK()OVER(PARTITION BY d.category_id ORDER BY SUM(s.qty) DESC) AS rn
    FROM sales s
    INNER JOIN product_details d
        ON s.prod_id = d.product_id
    GROUP BY d.category_id, d.category_name, d.product_id, d.product_name

)
SELECT 
    category_id, 
    category_name, 
    product_id, 
    product_name, 
    total_qty
FROM rank_cte
WHERE rn = 1
ORDER BY category_id;
```

**Result**:

<img width="804" height="93" alt="5" src="https://github.com/user-attachments/assets/ac20e9d6-5ed8-45b6-98ca-f483db14a24a" /><br>
- Women's Grey Fashion Jacket sold a total of 3,876 quantities versus Men's Blue Polo Shirt that sold 3,819 qunaitites.


**Q6. What is the percentage split of revenue by product for each segment?**
- Calculate the gross revenue and GROUP BY segments and products
- Calculate the percentage split by multiplying the gross revenue by 100.0, to prevent floor division, and divide by SUM()OVER() which sums the revenue for each segment
- ORDER BY segment_id and pct split in descending order so that the highest value is at top for each segement

```SQL
WITH revenue_cte AS (
    SELECT 
        d.segment_id,
        d.segment_name, 
        d.product_id,
        d.product_name,
        SUM(s.qty * s.price) AS revenue
    FROM sales s
    INNER JOIN product_details d
        ON s.prod_id = d.product_id
    GROUP BY d.segment_id, d.segment_name, d.product_id, d.product_name
)
SELECT
    segment_id,
    segment_name,
    product_id,
    product_name,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (PARTITION BY segment_name), 2) AS pct
FROM revenue_cte
ORDER BY segment_id, pct DESC;
```

**Result**:

<img width="778" height="328" alt="6" src="https://github.com/user-attachments/assets/3b5faf83-755e-4bdd-84e4-2af1336e0cea" /><br>


**Q7. What is the percentage split of revenue by segment for each category?**
- Use the same logic as Q6, but change every `product_id` and `product_name` to `category_id` and `category_name`

```SQL
WITH revenue_cte AS (
    SELECT 
        d.segment_id,
        d.segment_name, 
        d.category_id,
        d.category_name,
        SUM(s.qty * s.price) AS revenue
    FROM sales s
    INNER JOIN product_details d
        ON s.prod_id = d.product_id
    GROUP BY d.segment_id, d.segment_name, d.category_id, d.category_name
)
SELECT
    category_id,
    category_name,
    segment_id,
    segment_name,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (PARTITION BY category_name), 2) AS pct
FROM revenue_cte
ORDER BY category_id, pct DESC;
```

**Result**:

<img width="706" height="138" alt="7" src="https://github.com/user-attachments/assets/562041dc-c6a8-4404-a18e-da5e6f60be38" /><br>


**Q8. What is the percentage split of total revenue by category?**
- Use CASE to group category name by their IDs
- Calculate the total revenue by using the sum of the gross revenue for each category by the total gross revenue across the `sales` table

```SQL
SELECT 
		category_id, 
    CASE
        WHEN d.category_id = 1 THEN d.category_name
        WHEN d.category_id = 2 THEN d.category_name
        ELSE NULL 
    END AS category_type,
    ROUND(SUM(s.qty * s.price) * 100.0 / (SELECT SUM (qty * price) FROM sales), 2) AS pct
FROM sales s
INNER JOIN product_details d
    ON s.prod_id = d.product_id
GROUP BY category_id,     
    CASE
        WHEN d.category_id = 1 THEN d.category_name
        WHEN d.category_id = 2 THEN d.category_name
        ELSE NULL 
    END
ORDER BY category_id;
```

**Result**:

<img width="276" height="93" alt="8" src="https://github.com/user-attachments/assets/dae63892-5e27-4a1c-9a4a-c983456fb699" /><br>
- Mens category takes up 55.38% of total gross revenue compared to womens with 44.62%.


**Q9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)**
- Calculate the transaction "penetration" by the count of transaction over the unique count of transaction across `sales`
- Filter results so transactions has at least 1 product that was purchased

```SQL
SELECT
    d.product_id,
    d.product_name,
    ROUND(COUNT(s.txn_id) * 100.0/ (SELECT COUNT(DISTINCT txn_id) FROM sales), 2) AS txn_penetration
FROM sales s
INNER JOIN product_details d
    ON s.prod_id = d.product_id
WHERE qty >= 1
GROUP BY d.product_id, d.product_name;
```

**Result**:

<img width="582" height="158" alt="9" src="https://github.com/user-attachments/assets/5bd72291-b471-4db5-a938-727e2b75f530" /><br>
- Women's Navy Oversized Jeans has the highest transaction penetration of 50.96% while Women's Cream Relaxed Jeans and Men's White Striped Socks are tied with 49.72%.


**Q10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?**
- Use the combination formula to answer this question
  
  <img width="272" height="84" alt="image" src="https://github.com/user-attachments/assets/8642b879-61dc-4b09-bb35-81e027a728fd" />

```SQL
WITH product_cte AS(
    SELECT
        s.txn_id,
        s.prod_id,
        d.product_name
    FROM sales s
    INNER JOIN product_details d
        ON s.prod_id = d.product_id
)
SELECT
    a.product_name,
    b.product_name,
    c.product_name,
    COUNT(*) AS combination_count
FROM product_cte a
INNER JOIN product_cte b
    ON a.txn_id = b.txn_id
INNER JOIN product_cte c
    ON a.txn_id = c.txn_id
WHERE a.prod_id < b.prod_id AND b.prod_id < c.prod_id
GROUP BY a.product_name, b.product_name, c.product_name
ORDER BY combination_count DESC
LIMIT 1;
```

**Result**:

<img width="799" height="64" alt="10" src="https://github.com/user-attachments/assets/dacf3146-6dc0-4068-ba1d-e98a809c5cbc" /><br>
- The most common combination is a Men's White Tee Shirt, Women's Grey Fashion Jacket, and a Men's Teal Button Up Shirt with a count of 352.
  
</details>

### D. Reporting Challenge

### E. Bonus Challenge




## Key Takeaways

## Challenges
