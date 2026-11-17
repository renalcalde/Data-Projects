# 💰 Case Study #4: Data Bank

<p align="center">
  <img src="png/data_bank.png" alt="Data Bank Poster" width="500"><br>
  <strong>Source:</strong> <a href="https://8weeksqlchallenge.com/case-study-4/">8 Week SQL Challenge: Case Study #4 - Data Bank</a>
</p>

## Table of Contents
- [Objective](#objective)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question & Solution](#question-and-solution)
- [Challenges](#challenges)
- [Key Takeaways](#key-takeaways)

## Objective
Created by Danny, Data Bank is a digital banking system that also offers cloud storage that scales with a customer's balance.​ The management team at Data Bank wants to increase their total customer base and use customer data to understand demand needs.

## Entity Relationship Diagram
There are 3 key datasets in this case study:
- `regions` : both a customer's money and data is stored across the region in a network of nodes, which can be seen as bank branches/ stores
- `customer_nodes` : customers are randomly distributed across the nodes according to their region which reduces the risk of hackers stealing valuable information
- `customer_transaction` : stores all customers deposits, withdrawals and purchases made using their Data Bank debit card

<p align="center">
<img src="png/entity_relationship_diagram.png" alt="Entity Relationship Diagram" width="800">
</p>

## Question and Solution
View the [full code](data_bank.sql)
### A. Customer Nodes Exploration
**1. How many unique nodes are there on the Data Bank system?**
- Use COUNT() with DISTINCT to find the number of unique nodes
  
```SQL
SELECT COUNT(DISTINCT node_id) FROM customer_nodes;
```

**Result**:

<img width="141" height="68" alt="1" src="https://github.com/user-attachments/assets/c45fe687-f51f-4382-94d6-d0fc5cf7420b" /><br>
- Data Bank has 5 unique nodes.

**2. What is the number of nodes per region?**
- Use JOIN to get the name for each region

```SQL
SELECT 
    r.region_name,
    COUNT(DISTINCT n.node_id)
FROM customer_nodes n
INNER JOIN regions r
    ON n.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;
```

**Result**:

<img width="281" height="165" alt="2" src="https://github.com/user-attachments/assets/63362348-1d80-4380-af93-e200fa1009c2" /><br>
- Each region has 5 unique nodes.

**3. How many customers are allocated to each region?**
- Use JOIN to get the name for each region and a COUNT() with DISTINCT to find the number of customers per region

```SQL
SELECT 
    r.region_name,
    COUNT(DISTINCT n.customer_id)
FROM customer_nodes n
INNER JOIN regions r
    ON n.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;
```

**Result**:

<img width="281" height="167" alt="3" src="https://github.com/user-attachments/assets/e9c23865-eb92-4de9-a66d-004ee80da13f" /><br>
- Australia has the highest count with 110 customers in comparison to Europe who only has total of 88 customers.

**4. How many days on average are customers reallocated to a different node?**
- Find the earliest and latest dates using MIN and MAX. After identifying that the maximum `end_date` is '9999-12-31', I checked the rest of the `end_date` in descending order to see if there is any odd dates as well
- After confirming there isn't, I use AVG() to find the difference of days between `end_date` and `start_date` and ROUND() to 2 decimal places
- Filter the results so that the `end_date` doesn't contain '9999-12-31' 
  
```SQL
-- Step 1
SELECT 
    MIN(start_date),
    MAX(end_date)
FROM customer_nodes;

-- Step 2
SELECT 
    DISTINCT(end_date)
FROM customer_nodes
ORDER BY end_date DESC;

-- Step 3
SELECT 
    ROUND(AVG(end_date - start_date),2) AS avg_days
FROM customer_nodes
WHERE end_date != '9999-12-31';
```

**Result**:

<img width="156" height="64" alt="4" src="https://github.com/user-attachments/assets/4267f40a-4268-4bfe-a924-4e86248acd4d" /><br>
- On average, customer's remain in a node for about 14.63 days or 15 days.
- After checking that all customers have '9999-12-31' in their latest `end_date`, this suggests that '9999-12-31' is a placeholder that represents the current node that the customer is in. 

**5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?**
- Find the days between `end_date` and `start_date`
- Filter results so that the `end_date` doesn't contain '9999-12-31'
- Use PERCENTILE_COUNT() to find the specific percentile values across the sorted set of numbers

```SQL
WITH days_cte AS(
    SELECT 
        region_id,
        customer_id,
        (end_date - start_date) AS days
    FROM customer_nodes
    WHERE end_date != '9999-12-31'
    GROUP BY region_id, customer_id, end_date, start_date
)
SELECT
    r.region_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY d.days) AS median,
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY d.days) AS percentile_80,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY d.days) AS percentile_95
FROM days_cte d
INNER JOIN regions r
    ON d.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;
```

**Result**:

<img width="598" height="160" alt="5" src="https://github.com/user-attachments/assets/6a848fa2-f61b-450b-85ce-24261de158cf" /><br>
- All of the regions share the same median of 15 days and a 95th percentile of 28 days. For the 80th percentile, Africa and Europe share 24 days while the remaining regions share 23.
- While all the regions are similarly consistent, Africa and Europe appear to be only a day behind when it comes to reallocating their customers.

### B. Customer Transactions
**1. What is the unique count and total amount for each transaction type?**
- Use COUNT() to find the number per transaction type and SUM() to find the total amount for each transaction type

```SQL
SELECT 
    txn_type,
    COUNT(txn_type),
    SUM(txn_amount)
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type;
```

**Result**:

<img width="340" height="113" alt="1" src="https://github.com/user-attachments/assets/b7697fe9-ad9b-4945-a10c-90b4d716b7f2" /><br>
- Deposit has the highest count (2671) and total amount ($1,259,168). In comparison to withdrawal, who has the lowest count (1580) and total amount ($793,003). This suggests depositing money into the Data Bank system, is a popular feature for customers.

**2. What is the average total historical deposit counts and amounts for all customers?**
- Similar logic to Q1, but filter results so it returns the count, total amount and the average amount per deposit
- AVG() the total count, total amount, and average deposit

```SQL
WITH deposit_cte AS(
    SELECT 
        customer_id,
        COUNT(txn_type) AS depo_count,
        SUM(txn_amount) AS depo_sum,
        AVG(txn_amount) AS depo_avg
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT
    ROUND(AVG(depo_count),2) AS deposit_count,
    ROUND(AVG(depo_avg),2) AS deposit_average,
    ROUND(AVG(depo_sum),2) AS deposit_amount
FROM deposit_cte;
```

**Result**:

<img width="529" height="70" alt="2" src="https://github.com/user-attachments/assets/f7e9fab1-7025-4da3-a247-f2dfa8c0538d" /><br>
- Customers have deposited money into their account about 5 times totaling roughly $2,718.24 with an average of $508.61 per deposit.

**3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?**
- Create a CTE to act as a tracker and count the times a customer either deposit, purchase or withdrawals money
- Filter the results so that deposit count is greater than one AND purchase or withdrawal count is exactly one time
- Use EXTRACT() to get the month number and TO_CHAR() to add the name of the month from `txn_date`, then GROUP BY the month

```SQL
WITH count_cte AS(
    SELECT
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        TO_CHAR(txn_date, 'MON') AS month_name, 
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM customer_transactions
    GROUP BY customer_id, month_name, month
)
SELECT
    month_name,
    COUNT(*)
FROM count_cte
WHERE deposit_count > 1 AND (purchase_count = 1 OR withdrawal_count = 1)
GROUP BY month_name, month
ORDER BY month;
```

**Result**:

<img width="270" height="143" alt="3" src="https://github.com/user-attachments/assets/6048bacc-6f7b-4534-bea8-4da4ca463cfb" /><br>
- January has the highest count for customers who deposited more than 1 time and has only once purchased or withdrawal money from their account.
- This shows that customers where highly conservative using their money in the beginning of the year or the first time they open a Data Bank account. April has a concerningly low amount of customers who meet this requirement, it's possible that the data is incomplete for this month and should be investigated further.

**4. What is the closing balance for each customer at the end of the month?**
- Use DATE_TRUNC() to find the earliest and latest transaction dates across the table
- Use a RECURSIVE CTE to implement all four months per customer even if there is no net change for that month
- Calculate the monthly net change
- LEFT JOIN the monthly net changes into the calendar and use COALESCE() to turn months with no transaction into 0. Use (SUM()OVER) to get each month's closing balance

```SQL

WITH RECURSIVE cte AS(
    SELECT
        customer_id,
        (DATE_TRUNC('month', d.min_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE AS start_month_end,
        (DATE_TRUNC('month', d.max_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE AS end_month_end
    FROM (SELECT DISTINCT customer_id FROM customer_transactions) c
    CROSS JOIN (
        SELECT MIN(txn_date) AS min_date, MAX(txn_date) AS max_date
        FROM customer_transactions
    ) d
),
cte2 AS(
    SELECT
        customer_id,
        start_month_end AS month_end,
        end_month_end
    FROM cte

    UNION ALL

    SELECT
        customer_id,
        (DATE_TRUNC('month', month_end + INTERVAL '1 day') + INTERVAL '1 month' - INTERVAL '1 day')::DATE,
        end_month_end
    FROM cte2
    WHERE month_end < end_month_end
),
cte3 AS(
    SELECT
        customer_id,
        (DATE_TRUNC('month', txn_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE AS month_end,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, DATE_TRUNC('month', txn_date)
),
cte4 AS (
    SELECT
        c2.customer_id,
        c2.month_end,
        COALESCE(c3.net_change, 0) AS net_change,
        SUM(COALESCE(c3.net_change, 0)) OVER(PARTITION BY c2.customer_id ORDER BY c2.month_end) AS closing_balance
    FROM cte2 c2
    LEFT JOIN cte3 c3
        ON c3.customer_id = c2.customer_id
        AND c3.month_end = c2.month_end
)
SELECT * 
FROM cte4
ORDER BY customer_id, month_end;
```

**Result**:

*Not all output is shown, only the first 3 customers are displayed*
<img width="611" height="328" alt="4" src="https://github.com/user-attachments/assets/6d8f97a1-f226-4945-907b-e2539b0d4991" /><br>

**5. What is the percentage of customers who increase their closing balance by more than 5%?**
- Calculate for the net_change and use (SUM()OVER) to find the closing balance
- Compare each closing balance to the previous row using LAG() and use NULLIF() to avoid dividing by zero
- Filter results so customers whose balance grew by more than 5% are kept

```SQL

WITH cte AS(
    SELECT
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        TO_CHAR(txn_date, 'MON') AS month_end,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, month, month_end
),
cte2 AS(
    SELECT
        customer_id,
        month_end,
        month,
        SUM(net_change) OVER(PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM cte
    GROUP BY customer_id, month_end, month, net_change
),
cte3 AS(
    SELECT
        customer_id,
        month_end,
        closing_balance,
        100 *(closing_balance - LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY	month))
            / NULLIF( LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY	month), 0) AS percentage_increase
    FROM cte2
    GROUP BY customer_id, month_end, month, closing_balance
)
SELECT
    100 * COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions)::FLOAT AS percentage
FROM cte3
WHERE percentage_increase > 5;
```

**Result**:

<img width="173" height="67" alt="5" src="https://github.com/user-attachments/assets/14d958a4-4040-4f9e-8d31-3b7243a3e01d" /><br>
- About 75.8% of customers had an increase in their closing balance by more than 5%.

### C. Data Allocation Challenge
To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

- Option 1: data is allocated based off the amount of money at the end of the previous month
- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
- Option 3: data is updated real-time
  
For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

- running customer balance column that includes the impact each transaction
- customer balance at the end of each month
- minimum, average and maximum values of the running balance for each customer

**Using all of the data available - how much data would have been required for each option on a monthly basis?**

**Option 1**
- Calculate each customer's monthly net change by adding deposits and subtracting purchases and withdrawals
- Use SUM() OVER() to take a running total per customer to find each month's closing balance
- Use LAG() to retrieve the previous month's closing balance since data allocation is based off the previous month
- Use COALESCE() to treat missing values as 0 and SUM() + CASE WHEN to turn any negative values into 0 since data can't be negative
- SUM() the results across all customers and GROUP BY month to get the total data allocated each month
  
```SQL
WITH cte AS(
    SELECT 
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        TO_CHAR(txn_date, 'MON') AS month_end,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, month, month_end
),
cte2 AS(
    SELECT
        *,
        SUM(net_change) OVER(PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM cte
),
cte3 AS(
    SELECT
        *,
        LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY customer_id, month) AS running_balance
    FROM cte2
)
SELECT
    month_end,
    SUM(COALESCE(CASE WHEN running_balance < 0 THEN 0 ELSE running_balance END, 0)) AS data_allocated
FROM cte3
GROUP BY month_end, month
ORDER BY month;
```

**Result**:

<img width="328" height="138" alt="1" src="https://github.com/user-attachments/assets/47290898-bed3-4c54-8e70-3f4409a242a3" /><br>
- January contains 0 data because there is no previous month to base off data allocated.
- March has the highest data allocated with 240,602 while April has the lowest data allocated with 153,147.
- Data allocation for this option seems to fluctuate since it relies on a single snapshot rather than an average.

**Option 2**
- Apply the same logic as Option 1 with some minor changes
- Calculate a customer's daily net change
- Use AVG() with RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW to average a customer's balance from the last 30 days as this is what data allocation is being based off
- Use ROW_NUMBER() to assign each customer's row within a month and rn = 1 to get their last transaction

```SQL
WITH cte AS(
    SELECT 
        customer_id,
        txn_date,
        EXTRACT(MONTH FROM txn_date) AS month,
        TO_CHAR(txn_date, 'MON') AS month_end,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, txn_date, month, month_end
),
cte2 AS(
    SELECT
        *,
        SUM(net_change) OVER(PARTITION BY customer_id ORDER BY txn_date) AS closing_balance
    FROM cte
),
cte3 AS(
    SELECT
        *,
        AVG(closing_balance) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
            RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
        ) AS running_balance
    FROM cte2
),
cte4 AS(
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY customer_id, month ORDER BY txn_date DESC) AS rn
    FROM cte3
)
SELECT
    month_end,
    ROUND(SUM(CASE WHEN running_balance < 0 THEN 0 ELSE running_balance END), 0) AS data_allocated
FROM cte4
WHERE rn = 1
GROUP BY month_end, month
ORDER BY month;
```

**Result**:

<img width="328" height="136" alt="2" src="https://github.com/user-attachments/assets/216960e7-4943-4c5c-8f77-237dfb475f0a" /><br>
- March has the highest data allocated of 232,335 while April has the lowest of 152,190.
- Data allocation for this option is moderately stable as it seems to react to month-to-month balance change, which makes this easier to predict.


**Option 3**
- Apply the same logic as Option 1 & 2 with some minor changes
- Calculate a customer's monthly net change
- Use SUM()OVER to find the running total per customers ordered by month
- GROUP BY month to get the total data allocated with no LAG() or AVG() since data is allocated based on current balance

```SQL
WITH cte AS(
    SELECT 
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        TO_CHAR(txn_date, 'MON') AS month_end,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM customer_transactions
    GROUP BY customer_id, month, month_end
),
cte2 AS(
    SELECT
        *,
        SUM(net_change) OVER(PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM cte
)
SELECT
    month_end,
    SUM(CASE WHEN closing_balance < 0 THEN 0 ELSE closing_balance END) AS data_allocated
FROM cte2
GROUP BY month_end, month
ORDER BY month;
```

**Result**:

<img width="328" height="142" alt="3" src="https://github.com/user-attachments/assets/18b759d2-e0f0-4e8e-b1dd-06e3c886063d" /><br>
- March has the highest data allocated of 240,065 while April has the lowest of 157,033.
- Data allocation for this option is the most stable and has the highest values. However, because this is updated in real time it can make it difficult to predict for future data storage.

### E. Extension Request
The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.

1. Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.

2. With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.

View the [PowerPoint presentation](https://1drv.ms/p/c/5173473c9b608ebd/IQAXX-jgqmG2QYO4XGUhNeQGAZc26y_HIOM6KUsbJu1Xzcg?e=eNEhfs)
  
## Challenges
- Q4 and Q5 from Customer Transaction, required manipulating DATE_TRUNC() to retrieve specific dates. Such as converting dates into month-ends, building a month-end calendar and joined it to the monthly net changes. 
- All three options from the Data Allocation Challenge proved to be difficult. Option 1: LAG() for last month’s balance, with NULLs handled for January. Option 2: The hardest. I approximated the 30-day average with a rolling window and used ROW_NUMBER() to count each customer once per month. Option 3: Simple, but negatives had to be set to 0 before summing.

## Key Takeaways
**Business Insights**
- Each region has 5 distinct nodes that customers are frequently and randomly allocated to. Customers are allocated to a new node on an average of 15 days. While all 5 regions share the same median (15 days) and 95th percentile (28 days), Africa and Europe share the same 80th percentile of 24 days while the remaining regions share 23 days. This suggests that Africa and Europe are only a day behind when it comes to allocating customers to a new node, however it still shows that nodes are frequently yet consistently allocated.
- March has the highest data allocation (~232k to 240k) in all three options while April is the lowest in all three (~152K to 157K). This suggests A baseline of 240k data per month is required for our customers and that April's data may be incomplete and will need further investigation.
- Option 3 shows the highest and smoothest monthly totals, but because it updates in real time, data allocation changes constantly which may pose difficulties to forecast and can get expensive. Option 2 allocates less and lags in real changes, but it's more predictable and affordable since it relies on the previous 30 days. Overall, Option 2 is the best choice for data allocation because it's more predictable and keeps costs lower. To attract new customers, I recommend a small welcome allocation for their first 30 days. This encourages sign-ups and avoids missing values for new customers who have no previous 30 days of balance history, which would skew the results.

**Key Insights**
- Learn PERCENTILE_CONT() to calculate specific percentile value from a sorted set of numbers
- Improve DATE_TRUNC() manipulation to round a date to a set interval such as the start of a month for grouping and month-end dates
- LEFT JOIN with COALESCE() to keep rows with no match and turns NULL into 0 
- Learn RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW to define a window by date rather than row count
