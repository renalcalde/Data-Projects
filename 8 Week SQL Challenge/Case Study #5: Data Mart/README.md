# 🛒 Case Study #5: Data Mart

<p align="center">
  <img src="png/data_mart.png" alt="Data Mart Poster" width="500"><br>
  <strong>Source:</strong> <a href="https://8weeksqlchallenge.com/case-study-5/">8 Week SQL Challenge: Case Study #5 - Data Mart</a>
</p>

## Table of Contents
- [Objective](#objective)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question & Solution](#question-and-solution)
- [Challenges](#challenges)
- [Key Takeaways](#key-takeaways)

## Objective
Data Mart is Danny's latest venture, an international online supermarket specialized in fresh produce. In June 2020, large scale supply changes were implemented at Data Mart as products now used a sustainable packaging method. Danny wants to know how these changes impacted sales performance and answer key business questions, such as:
- What was the quantifiable impact of the changes introduced in June 2020?
- Which platform, region, segment and customer types were the most impacted by this change?
- What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?

## Entity Relationship Diagram
There is only a single key dataset for this case study:
- `data_mart.weekly_sales` : the tables list valuable customer insight, such as the week order's where made and form what region, what platform was used to order, customer information, along with transaction and sales.

<p align="center">
<img src="png/entity_relationship_diagram.png" alt="Entity Relationship Diagram" width="250">
</p>

## Question and Solution

View the [full code](./data_mart.sql)

- [1. Data Cleansing Steps](https://github.com/renalcalde/Data-Projects/blob/main/8%20Week%20SQL%20Challenge/Case%20Study%20%235%3A%20Data%20Mart/Solutions/1.%20Data%20Cleansing%20Steps.md)
- [2. Data Exploration](https://github.com/renalcalde/Data-Projects/blob/main/8%20Week%20SQL%20Challenge/Case%20Study%20%235%3A%20Data%20Mart/Solutions/2.%20Data%20Exploration.md)

### 4. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
- region
- platform
- age_band
- demographic
- customer_type

```SQL
WITH sales_cte AS (
  SELECT 
    CASE 
      WHEN GROUPING(region) = 0 THEN 'region'
      WHEN GROUPING(platform) = 0 THEN 'platform'
      WHEN GROUPING(age_band) = 0 THEN 'age_band'
      WHEN GROUPING(demographic) = 0 THEN 'demographic'
      WHEN GROUPING(customer_type) = 0 THEN 'customer_type'
    END AS category,
    COALESCE(region, platform, age_band, demographic, customer_type) AS subcategory,
    SUM(CASE 
        WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
             TO_CHAR(DATE '2020-06-15' - INTERVAL '12 weeks', 'MM-DD') 
         AND TO_CHAR(DATE '2020-06-15' - INTERVAL '1 day', 'MM-DD') 
         THEN sales ELSE 0 
    END) AS sales_before,
    SUM(CASE 
      WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
           TO_CHAR(DATE '2020-06-15', 'MM-DD') 
       AND TO_CHAR(DATE '2020-06-15' + INTERVAL '12 weeks', 'MM-DD') 
       THEN sales ELSE 0 
    END) AS sales_after
  FROM clean_weekly_sales
  GROUP BY GROUPING SETS (
    (region),
    (platform),
    (age_band),
    (demographic),
    (customer_type)
  )
)
SELECT 
  category,
  subcategory,
  sales_before,
  sales_after,
  ROUND((sales_after - sales_before) * 100.0 / NULLIF(sales_before, 0), 2) AS growth_rate
FROM sales_cte
ORDER BY growth_rate;
```

**Result**:

<img width="727" height="159" alt="1 5" src="https://github.com/user-attachments/assets/141417d9-b58c-4df1-914b-5fcee68d9bc7" />

*Only showing the first 5 rows* 

Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?

## Challenges

## Key Takeaways
