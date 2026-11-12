
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
Foodie-Fi is a subscription streaming service created by Danny that offers only food-related content. Launched in 2020, it lets customers start with a free trial and then choose one of three plans (basic monthly, pro monthly, or pro annual). Customers can also cancel at any time. This case study uses Danny's subscription data to answer key business questions and help him make data-driven investment and product decisions.

## Entity Relationship Diagram
There are 2 key datasets for this case study:
- `plans` : shows the name and price for each `plan_id`
- `subscriptions` : shows all customer orders

<p align="center">
<img src="png/entity_relationship_diagram.png" alt="Entity Relationship Diagram" width="800">
</p>
  
## Question & Solution
View the [full code](foodie_fi.sql)

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
- Use COUNT() with DISTINCT to find the number of unique customers
  
```SQL
SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions;
```

**Result**:

<img width="139" height="72" alt="1" src="https://github.com/user-attachments/assets/b6f29fb3-4aa3-4888-8edf-c83199e9b0c1" /><br>
- Foodie-Fi had 1,000 unique customers.

**2. What is the monthly distribution of `trial` plan `start_date` values for our dataset - use the start of the month as the group by value**
- Use TO_CHAR() to format the month from `start_date` into 'MM-MONTH' for readability
- Then use COUNT() on `plan_id` and filter results for trial period
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

**3. What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of events for each `plan_name`**
- Filter results to show subscriptions after the year 2020 using an EXTRACT()
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
- There seems to be no record of any customers on a trial period after 2020. A majority of customers are continuing with current plans or cancelling their subscription which holds the highest count.
  
**4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?**
- Use a CTE to filter and count for customers who have churned
- Divide the number of customers who have churned by the total number of customers, then multiply by 100 to get the percentage and round to 1 decimal place
  - Multiply `customer_count` in the percentage formula by 1.0 to convert int to float and prevent int division which rounds down
  - Use a scalar subquery to retrieve the total count of unique customers and apply a NULLIF to prevent any fatal runtime error if the denominator equals to zero
     
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
- 307 customers have churned their subscription, which is 30.7% of total customers.

**5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?**
- Create a CTE that looks into a customers previous plan using a LAG() function and the `plan_id` as their current plan
- Filter the results so that previous plan is the trial period and their current plan is churned
  
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
- 92 of customers didn't continue with their subscription after their trial period, which is about 9% of customers.


**6. What is the number and percentage of customer plans after their initial free trial?**
- Create a CTE that looks into a customer's next plan after their trial period ends using a LEAD() function and uses `plan_id` as their current plan
- COUNT() for every customer GROUP BY the plan they joined right after
- Filter the results so that the next plan is not null and the customer's current plan is a trial period

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
- Right after the trial period ends, a majority of customers subscribed to the basic monthly plan (54.6%). Followed by those who subscribed or was automatically enrolled into the pro monthly plan (32.5%). A low majority of customers would subscribed to the pro annual plan (3.7%) or not continue their subscription (9.2%).

**7. What is the customer count and percentage breakdown of all 5 `plan_name` values at `2020-12-31`?**
- Create a CTE that counts the number of unique customers from a subquery that uses LEAD() to look into the customer's next plan
- Filter results for plans on or before the date '2020-12-31'
  
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
- The pro monthly plan has the highest subscription by the end of the year (32.6%). However, churn rates have also increased near the end of the year (23.6%).

**8. How many customers have upgraded to an annual plan in 2020?**
- COUNT with DISTINCT to find the total count of every unique customer
- Filter the results so it only returns customers in the year 2020 with a pro annual plan
  
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
- Create two CTEs that filter for two types of `plan_id` on the `start_date`: the trial period date and the pro annual date
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
- It takes on average 105 days for customers to join the pro annual plan from the first day they joined Foodie-Fi.

**10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)**
- Using the same CTEs from Q9, add another CTE that counts the days between the annual date and trial date using a WIDTH_BUCKET that groups the days into 12 equal 30 day intervals
- Use a string concatenation, to present the buckets into readable text 

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
*Approach adapted from [Katie Huang's solution](https://github.com/katiehuangx/8-Week-SQL-Challenge/tree/main/Case%20Study%20%233%20-%20Foodie-Fi).*

**Result**:

<img width="279" height="328" alt="10" src="https://github.com/user-attachments/assets/699f73c9-57a0-429d-a212-fcd57849c8e1" /><br>
- From the beginning to the mid year, customers seem to upgrade their subscription to the pro annual plan with 0-30 days and 120-150 days being the highest. From 210 to 360 days, there was a significant drop of customers who didn't upgrade their subscription.

**11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?**
- Create a CTE that uses LAG() to look back at a customer's previous plan and `plan_id` as their current plan
- Filter the results so that the previous plan was a pro monthly and that the current plan is a basic monthly, with this change taking place in 2020
  
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
- 0 customers were reported to downgrade their plan from a pro monthly to a basic monthly.

### C. Challenge Payment Question
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments

To solve this challenge, we would need to do the following steps:
1. Retrieve subscriptions in 2020.
2. Filter results so trial and churned plans are excluded.
3. JOIN the `subscription` and `plans` table to get the plan name and price.
4. Use a LEAD() function to look at a customer's next plan. Combine this with a COALESCE so that if the next plan is NULL, it will change the NULL into '2020-12-31' which is the last day of the year.
5. Use a RECURSIVE CTE for the monthly payment dates. This will continue a customer's plan until it reaches the cutoff date or if they upgraded their plan to a pro annual plan.
6. Create another CTE that uses a LAG() function to look at a customer's previous plan and its price. Use this to then create the reduce price for when a customer upgrades their basic monthly plan to either a pro monthly or pro annual plan.
7. Add the payment_order using a ROW_NUMBER() function that ranks a customer's purchase order and resets for every customer.
8. Tie everything together and add it to a new table called `payments`.

```SQL
DROP TABLE IF EXISTS payments;

CREATE TABLE payments AS
WITH RECURSIVE plan_cutoffs AS(
    SELECT 
        s.customer_id,
        s.plan_id,
        p.plan_name,
        s.start_date,
        COALESCE(LEAD(s.start_date) OVER(PARTITION BY s.customer_id ORDER BY s.start_date), '2020-12-31') AS cutoff_date,
        p.price
    FROM subscriptions s
    INNER JOIN plans p
        ON s.plan_id = p.plan_id
    WHERE s.plan_id NOT IN (0,4) AND s.start_date <= '2020-12-31'
),
monthly_payments AS(
    SELECT
        customer_id,
        plan_id,
        plan_name,
        start_date,
        cutoff_date,
        price
    FROM plan_cutoffs

    UNION ALL
    
    SELECT
        customer_id,
        plan_id,
        plan_name,
        (start_date + INTERVAL '1 month')::DATE,
        cutoff_date,
        price
    FROM monthly_payments
    WHERE cutoff_date > (start_date + INTERVAL '1 month')::DATE AND plan_id != 3
),
prior_plan AS(
    SELECT *,
        LAG(plan_id) OVER(PARTITION BY customer_id ORDER BY start_date) AS previous_plan,
        LAG(price) OVER(PARTITION BY customer_id ORDER BY start_date) AS previous_price
    FROM monthly_payments
    ORDER BY customer_id, start_date
)
SELECT
    customer_id,
    plan_id,
    plan_name,
    start_date AS payment_date,
    CASE
        WHEN previous_plan = 1 AND plan_id IN (2,3) THEN price - previous_price 
        ELSE price 
    END AS amount,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS payment_order
FROM prior_plan;

SELECT * FROM payments;
```
*Approach adapted from [Eke's solution](https://blog.devgenius.io/8-week-sql-challenge-case-study-3-foodie-fi-solution-d9dddf30755f).*

**Result**:

*Not the full output: showing a selected amount of rows*
<img width="833" height="423" alt="Screenshot 2026-11-11 at 7 59 17 PM" src="https://github.com/user-attachments/assets/868c998e-061a-46ea-9a43-d989bcab89ac" /><br>


### D. Outside The Box Questions

**1. How would you calculate the rate of growth for Foodie-Fi?**
I would compare the yearly revenue between the earliest and latest year (2020 and 2021) using the growth rate formula:
  Growth rate = (current year revenue - previous year revenue) / previous year revenue * 100

Using PostgreSQL, I gather the following data:
- In 2020, Foodie-Fi made $54,663.20 (2,448 customers)
- In 2021, Foodie-Fi made $13,810.20 (202 customers)
This gives the growth rate -74.74%, however I would read this figure with caution. 2021 appears to cover part of the year, so the drop reflects an incomplete year and not a real decline in revenue.

**2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?**
- Audience engagement: how often are customer interacting with the service and how long are they watching content
- Quality of Experience: streaming performance & customer satisfaction
- Subscriber growth and retention: new sign-ups, trial to paid conversion, and churn rates

**3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?**
- Churn rates: Why has the churned rate continue to grow over the course of the year compared to when customers churned right after the trial period?
- Upgrade paths: Why did customers upgrade to pro or annual plans compared to those who didn't? What encouraged them to upgrade?

**4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?**
- Did you find another service that offers a better price?
- Did you face any difficulties navigating or using the service?
- Did you find the content useful or relevant to you?

**5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?**
- Automated payments: make renewels automatic so customers don't lapse by accident
- Grace period: give customers extra time to fix a failed payment before the plan ends
To validate the effectiveness of the change I would run a A/B test. One group of customers have the change and a control group that doesn't and compare the churn rates between the two over the same period.  

## Challenges
- Q9 from the Data Analysis Section, my previous attempt grouped by the annual plan date instead of customers, which collapsed several customers into a single row. I fixed this by adding two queries that filter for one plan (the trial date and annual plan date), and using them on the same line which gives exactly one row per customer.
- Q10 from the Data Analysis Section, I faced difficulties creating a 30-day bucket. After researching, I used `WIDTH_BUCKET()` to assign each customer to a bucket and `||` to concatenate the bounds into a readable label such as "0-30 days".
- The Challenge Payment Question proved to be difficult because not only did I have to figure out how to approach the problem but I also had to combine several techniques: filtering the data, generate recurring payment dates, handling reduced prices and numbering payment orders. After researching, I found a source that helped guide me during this challenge.

## Key Takeaways
**Business Insights**
- After the trial period, 54.6% of customers subscribed to the basic monthly plan, while 32.5% were automatically enrolled or subscribed to the pro monthly and 3.7% to the pro annual plan (3.7%). Together, this suggests that 90% of trials convert to a paid plan which represents the trials effectiveness.
- However, there is a concerning churning rate. Right after the trial period, 9% of customers immediately cancelled their subscription and by the end of the year, 23.6% had churned. This suggests that over time, customers decided to cancel their plan, which should be investigated further to find out why.
- 195 customers have upgraded their plan to the annual plan in 2020, which is about 19.5% of customers. It takes on average 105 days for customers to upgrade their plan from the first day they joined Foodie-Fi, with the earliest making the switch in the first to 30 days or 120 to 150 days. This suggests two groups of customers: those who commit early and those who upgrade after a few months of use.

**Key Insights**
- Learned LEAD() and LAG() that either look at the next row or previous row depending on which function is being used
- Learned how to use a WIDTH_BUCKET() to create bucket bins
- Used a RECURSIVE CTE that references itself to process data until it reaches a stopping condition
- Practiced my data analytics ability by thinking about how and why a data is acting a certain way and how to present the idea to others

