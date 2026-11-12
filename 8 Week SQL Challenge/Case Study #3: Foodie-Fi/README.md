
# 🥑 Case Study #3: Foodie-Fi

<p align="center">
<img src= "png/foodie_fi.png" alt="Foodie-Fi Poster" width="500"><br>
  <strong>Source:</strong> <a href="https://8weeksqlchallenge.com/case-study-3/">8 Week SQL Challenge: Case Study #3 - Foodie-Fi </a>
</p>

## Table of Contents
- [Objective](#objective)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question & Solution](#question-and-solution)
- [Challenges](#challenges)
- [Key Takeaways](#key-takeaways)
  
## Objective
Danny created a new streaming service that only had food related content called Foodie-Fi. This case study aims to help Danny answer important business question using customer data.

## Entity Relationship Diagram
There are 2 key datasets for this case study:
- `plans` : shows the name and price for each `plan_id`
- `subscriptions` : shows all customer orders

<p align="center">
<img src="png/entity_relationship_diagram.png" alt="Entity Relationship Diagram" width="800">
</p>
  
## Question & Solution
### A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

<details>
  <summary>View full sample table</summary>
  <img width="247" height="623" alt="1" src="https://github.com/user-attachments/assets/c34779eb-af35-4571-8d98-5f7ee8ca190c" /><br>
</details>


Before describing each customer's journey, I used a JOIN to combine the `subscription` and `plan` table to retrieve the name for each plan ID and filter for only the following customers in the sample.

```SQL
SELECT s.customer_id, s.plan_id, p.plan_name, s.start_date FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19);
```

**Result**:

In this section, I will focus on three customers and share their onboarding journey.

**Customer #2**

<img width="556" height="91" alt="customer2" src="https://github.com/user-attachments/assets/d00a9086-98be-4e7a-849e-9b07d7a4083e" /><br>
- Customer 2 joined the free trial on September 20, 2020. After the end of the 7 day trial, Customer 2 subscribed to the pro annual plan on September 27, 2020.

**Customer #15**

<img width="554" height="113" alt="customer15" src="https://github.com/user-attachments/assets/23c47fd0-a6ec-40d2-8081-2d40212e66c9" /><br>
- Customer 15 initially started their subscription with a free trial on March 17, 2020. After the end of their 7 day trial, Customer 15 was automatically subscribed to the pro monthly plan on March 24, 2020. They then cancelled their Foodie-Fi service on April 29, 2020. 

**Customer #16**

<img width="558" height="117" alt="customer16" src="https://github.com/user-attachments/assets/d456e0f9-7bc5-400b-a1af-9e07c4b829ef" /><br>
- Customer 16 initially started their subscription with a free trial on May 31, 2020. After the end of their 7 day trial, Customer 16 subscribed to the basic monthly plan on June 7, 2020. They then upgraded their plan to the pro annual on October 10, 2020.

### B. Data Analysis Questions

**1. How many customers has Foodie-Fi ever had?**
- Use COUNT() with DISTINCT to find the number of unique customer
  
```SQL
SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions;
```

**Result**:

<img width="139" height="72" alt="1" src="https://github.com/user-attachments/assets/b6f29fb3-4aa3-4888-8edf-c83199e9b0c1" /><br>
- Foodie-Fi has 1000 unique customers

**2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value**
- Use TO_CHAR() to retrieve the month from `start_date` and format 'MM-MONTH' for readability
- Then used COUNT() on `plan_id` and filter with WHERE so only the trial plans are being counted
- GROUP BY the month
  
```SQL
SELECT 
    TO_CHAR(s.start_date, 'MM - MONTH') AS month,
    COUNT(s.plan_id)
FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.plan_id = 0
GROUP BY TO_CHAR(s.start_date, 'MM - MONTH')
ORDER BY month;
```

**Result**:

<img width="248" height="336" alt="2" src="https://github.com/user-attachments/assets/89388264-c75f-4a13-8c4a-f3e951123d83" /><br>
- March has the highest count with 94 trial subscriptions in comparison to February with 68 trial subscriptions. 

**3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name**
- EXTRACT() the year from `start_date` and filter for years after 2020 using WHERE
- COUNT() on `plan_id` and GROUP BY `plan_id` and `plan_name` to retrieve the count for every plan after 2020
  
```SQL
SELECT 
    p.plan_name,
    COUNT(s.plan_id)
FROM subscriptions s
INNER JOIN plans p
    ON s.plan_id = p.plan_id
WHERE EXTRACT(YEAR FROM s.start_date) > '2020'
GROUP BY s.plan_id, p.plan_name
ORDER BY s.plan_id;
```

**Result**:

<img width="269" height="141" alt="3" src="https://github.com/user-attachments/assets/94575afa-4c80-492b-9f08-db6770099e23" /><br>
- There seems to be no record of any customers on a trial subscription after 2020. A majority of customers are continuing with current plans or churning their subscription which holds the highest count. It's possible that there are no records of any new customers after 2020 and that current customers are continuing their subscription.

**4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?**
- Create a CTE called `customer_count_cte` that counts and filters for customers who have churned
- Calculate the percentage of customers who have churned
  - Multiply `customer_count` in the percentage formula by 1.0 to convert int to float and prevent int division which rounds down
  - Use a scalar subquery to retrieve the total count of unique customers and apply a NULLIF to prevent any fatal runtime error if the denominator equals to zero
  - ROUND() to 1 decimal place
     
```SQL
WITH customer_count_cte AS(
    SELECT 
        p.plan_name,
        COUNT(s.customer_id) AS customer_count
    FROM subscriptions s
    INNER JOIN plans p
        ON s.plan_id = p.plan_id
    WHERE s.plan_id = 4
    GROUP BY p.plan_name
)
SELECT
    customer_count AS customer_count,
    ROUND((customer_count * 1.0 / NULLIF((SELECT COUNT(DISTINCT (customer_id)) FROM subscriptions), 0)) * 100, 1) AS percentage
FROM customer_count_cte;
```

**Result**:

<img width="338" height="71" alt="4" src="https://github.com/user-attachments/assets/a03832e7-2ea8-46f1-a745-ecbf137e7a9f" /><br>
- 307 customers have churned their subscription, which is 30.7% of the subscription plan.

**5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?**
- Use LAG() to retrieve the previous row on `plan_id` with PARTITION BY `customer_id` and ORDER BY `start_date` as the previous plan
- Filter with WHERE the previous plan was the trial period and their current plan is churned
  
```SQL
WITH plan_status_cte AS(
    SELECT
        customer_id,
        LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS previous_plan,
        plan_id AS current_plan
    FROM subscriptions
)
SELECT 
    COUNT(customer_id) AS customer_count,
    ROUND((COUNT(customer_id) * 1.0 / NULLIF((SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions), 0)) * 100, 0) AS churn_percentage
FROM plan_status_cte
WHERE previous_plan = 0 AND current_plan = 4;
```

**Result**:

<img width="378" height="64" alt="5" src="https://github.com/user-attachments/assets/aad18674-0184-4377-b84b-c045a0376e35" /><br>
- 92 of customers have churned after their trial period, which is 9% of the subscription plan.


**6. What is the number and percentage of customer plans after their initial free trial?**
- Create a CTE called `next_plan_cte` that uses LEAD() to look into the new row on `plan_id`, which looks at the next plan for every customer
- COUNT() for every customer and calculate the percentage with the count of customers on a specific plan by the total count of customers, rounded to 1 decimal place
- JOIN with plans to retrieve the name of each `plan_id` for readability
- Filter so that the next plan is not null AND the customer's current plan is trial

```SQL
WITH next_plan_cte AS(
    SELECT
        plan_id,
        customer_id,
        LEAD(plan_id)OVER(PARTITION BY customer_id ORDER BY plan_id) AS next_plan
    FROM subscriptions s
)
SELECT
    p.plan_name,
    COUNT(np.customer_id) AS customer_count,
    ROUND((COUNT(np.customer_id) * 1.0/ (SELECT COUNT(DISTINCT (customer_id)) FROM subscriptions)) * 100, 1) AS percentage
FROM next_plan_cte np
INNER JOIN plans p
    ON np.next_plan = p.plan_id
WHERE np.next_plan IS NOT NULL AND np.plan_id = 0
GROUP BY p.plan_name, np.next_plan
ORDER BY np.next_plan;
```

**Result**:

<img width="463" height="136" alt="6" src="https://github.com/user-attachments/assets/b3bbc219-913a-4c19-8a47-1ffa0084282d" /><br>
- Right after the trial period, a majority of customers subscribed to the basic monthly plan (54.6%). Followed by those who subscribed or was automatically enrolled into the pro monthly plan (32.5%). A low majority of customers would subscribed to the pro annual plan (3.7%) or churn their subscription (9.2%).

**7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?**
- Create a CTE called `next_plan_cte` that counts the number of unique customers
- Use a subquery to count the number of customers using LEAD() that looks at the next row in `plan_id`
- Filter for plans before the year 2020 ends
  
```SQL
WITH next_plan_cte AS(
    SELECT
        p.plan_name,
        COUNT(DISTINCT s.customer_id) AS customer_count
    FROM (
        SELECT customer_id, plan_id,
            LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY plan_id) AS next_plan
        FROM subscriptions
        WHERE start_date <= '2020-12-31'
    ) s
    INNER JOIN plans p
        ON s.plan_id = p.plan_id
    WHERE next_plan IS NULL
    GROUP BY p.plan_id, p.plan_name
    ORDER BY p.plan_id
)
SELECT
    plan_name,
    customer_count,
    ROUND((customer_count * 1.0 / (SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions)) * 100, 1) AS percentage
FROM next_plan_cte;
```

**Result**:

<img width="465" height="168" alt="7" src="https://github.com/user-attachments/assets/5ce2df36-bb60-4409-8e0a-7fda1de9ac79" /><br>
- The pro monthly plan seems to be the subscribed plan popular at the end of the year (32.6%).

**8. How many customers have upgraded to an annual plan in 2020?**
- COUNT with DISTINCT to count the number of every unique customer
- Filter so that the results only return customers in the year 2020 with the pro annual plan 
```SQL
SELECT
    COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions
WHERE start_date BETWEEN '2020-01-01' AND '2020-12-31' AND plan_id = 3;
```

**Result**:

<img width="202" height="70" alt="8" src="https://github.com/user-attachments/assets/59dfb8e7-2446-4891-9582-49addf7b24e2" /><br>
- 195 customers upgraded their previous plan to the annual plan in 2020.


**9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?**
- Create two CTEs that filter for the proper `plan_id`: `trial_cte` that returns the date that customers had a trial subscription and `annual_cte` that returns the date customers have an annual plan
- Subtract the annual date from trial date to get the number of days in between and use ROUND() + AVG() to round the average of days it takes for customer to join the pro annual plan
  
```SQL
WITH trial_cte AS(
    SELECT
        customer_id,
        start_date AS trial_date
    FROM subscriptions
    WHERE plan_id = 0
), 
annual_cte AS(
    SELECT
        customer_id,
        start_date AS annual_date
    FROM subscriptions
    WHERE plan_id = 3
)
SELECT
    ROUND(AVG(ac.annual_date - tc.trial_date),0) AS avg_days
FROM trial_cte tc
INNER JOIN annual_cte ac
    ON tc.customer_id = ac.customer_id;
```

**Result**:

<img width="159" height="74" alt="9" src="https://github.com/user-attachments/assets/5a69dd36-2978-4c2a-8b8d-87a257fee2f7" /><br>
- It takes on average 105 days for customers to join the pro annual plan from the day they joined Foodie-Fi.

**10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)**
- Using the same CTEs from Q9, add another CTE called `day_difference_cte` that counts the days between the annual date and trail date using a WIDTH_BUCKET that organizes the count of day in 30 day interval
- Use a string concatenation, || that joins the average days to string text

```SQL
WITH trial_cte AS(
    SELECT
        customer_id,
        start_date AS trial_date
    FROM subscriptions
    WHERE plan_id = 0
), 
annual_cte AS(
    SELECT
        customer_id,
        start_date AS annual_date
    FROM subscriptions
    WHERE plan_id = 3
),
day_difference_cte AS(
    SELECT 
        WIDTH_BUCKET(ac.annual_date - tc.trial_date, 0, 365, 12) AS avg_days
    FROM trial_cte tc
    INNER JOIN annual_cte ac
        ON tc.customer_id = ac.customer_id
)
SELECT
    ((avg_days - 1) * 30 || '-' || avg_days * 30 || ' days') AS bucket_days,
    COUNT(*)
FROM day_difference_cte
GROUP BY avg_days
ORDER BY avg_days
```

**Result**:

<img width="279" height="328" alt="10" src="https://github.com/user-attachments/assets/699f73c9-57a0-429d-a212-fcd57849c8e1" /><br>
- From the beginning to the mid year, customers seem to upgrade their subscription to the pro annual plan with the first to 30 days and 120-150 days the highest. From 210 to 360 days, there was a drop of customers who didn't upgrade their subscripiton.

**11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?**
- Use LAG to count a row back to find the customers previous_plan
- Filter so that the previous plan was a pro monthly and that the current plan is a basic monthly. EXTRACT() for the year so that it also filters for customers in 2020.
  
```SQL
WITH plan_status_cte AS(
    SELECT
        customer_id,
        LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS previous_plan,
        plan_id AS current_plan,
        start_date
    FROM subscriptions
)
SELECT COUNT(*)
FROM plan_status_cte
WHERE previous_plan = 2 AND current_plan = 1 AND EXTRACT(YEAR FROM start_date) = '2020';
```

**Result**:

<img width="143" height="69" alt="11" src="https://github.com/user-attachments/assets/5d8b4d3f-d859-41bc-958e-8a3bb83368db" /><br>
- 0 customers were reported to downgrade their plan from a pro monthly to a basic monthyl.

### C. Challenge Payment Question
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments


### D. Outside The Box Questions

## Challenge
## Key Takeaway
