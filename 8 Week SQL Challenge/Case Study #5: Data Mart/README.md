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


### 3. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the `week_date` value of `2020-06-15` as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all `week_date` values for `2020-06-15` as the start of the period after the change and the previous `week_date` values would be before

Using this analysis approach - answer the following questions:
1. What is the total sales for the 4 weeks before and after `2020-06-15`? What is the growth or reduction rate in actual values and percentage of sales?
- Calculate the total sales using SUM()
- Use SUM() + CASE to get the total sales 4 weeks before the baseline date, use BETWEEN the earliest 4 weeks from '2020-06-15' AND a day before '2020-06-15'
- Use another SUM() + CASE to get the total sales 4 weeks after the baseline date, use BETWEEN '2020-06-15' and the latest 4 weeks from '2020-06-15'
- Calculate the percentage before and after 4 weeks, along with the growth rate
  
```SQL
WITH sales_cte AS(
    SELECT
        SUM(sales) AS total_sales,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15'::DATE - INTERVAL '4 weeks' AND '2020-06-15'::DATE - INTERVAL '1 day' 
            THEN sales ELSE 0
        END) AS sales_weeks_before,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15'::DATE AND '2020-06-15'::DATE + INTERVAL '4 weeks' 
            THEN sales ELSE 0
        END) AS sales_weeks_after
    FROM clean_weekly_sales
)
SELECT
    sales_weeks_before AS sales_before,
    ROUND(sales_weeks_before * 100.0 / total_sales, 2) AS before_pct,
    sales_weeks_after AS sales_after,
    ROUND(sales_weeks_after * 100.0 / total_sales , 2) AS after_pct,
    ROUND((sales_weeks_after - sales_weeks_before) * 100.0 / sales_weeks_before, 2) AS growth_rate
FROM sales_cte;
```

**Result**:

<img width="731" height="63" alt="1" src="https://github.com/user-attachments/assets/4ca388d1-ad91-445e-83f6-58dbf6c9f4ed" /><br>
- 4 weeks before the baseline date, sales were at 5.75%. 4 weeks after the baseline date, sales jumped to 7.13%. The overall growth rate is 23.83%, demonstrating that the sustainable packing was successful in the early launch week.

2. What about the entire 12 weeks before and after?
- Use the same method as Q1, but only change INTERVAL '4 weeks' to '12 weeks'

```SQL
WITH sales_cte AS(
    SELECT
        SUM(sales) AS total_sales,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15'::DATE - INTERVAL '12 weeks' AND '2020-06-15'::DATE - INTERVAL '1 day' 
            THEN sales ELSE 0
        END) AS sales_weeks_before,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15'::DATE AND '2020-06-15'::DATE + INTERVAL '12 weeks' 
            THEN sales ELSE 0
        END) AS sales_weeks_after
    FROM clean_weekly_sales
)
SELECT
    sales_weeks_before AS sales_before,
    ROUND(sales_weeks_before * 100.0 / total_sales, 2) AS before_pct,
    sales_weeks_after AS sales_after,
    ROUND(sales_weeks_after * 100.0 / total_sales , 2) AS after_pct,
    ROUND((sales_weeks_after - sales_weeks_before) * 100.0 / sales_weeks_before, 2) AS growth_rate
FROM sales_cte;
```

**Result**:

<img width="728" height="64" alt="2" src="https://github.com/user-attachments/assets/f28884e0-6682-4c1c-a97e-b0f7a329e55a" /><br>
- 12 weeks before the baseline date, sales were at 17.49%. 12 weeks after the baseline date, sales dropped to 17.12%. The growth rate is -2.14%, while this is a slight decline, it goes to show that overtime sales dropped. It's possible the attraction of a new sustainable packing lost it's excitement or possible defects were found which turned customers away, an investigation is needed to understand why the slow decline.


3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
- Combine the same logic from Q1 and Q2 into the same CTE
- UNION ALL to calculate the percentages for each sales period
- Filter results so it returns the values for each year

```SQL
WITH sales_cte AS(
    SELECT
        calendar_number AS year,
        SUM(sales) AS total_sales,
        -- 4 weeks
        SUM(CASE 
            WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
                 TO_CHAR(DATE '2020-06-15' - INTERVAL '4 weeks', 'MM-DD')
             AND TO_CHAR(DATE '2020-06-15' - INTERVAL '1 day', 'MM-DD')
            THEN sales ELSE 0 
        END) AS sales4w_before,
        SUM(CASE 
            WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
                 TO_CHAR(DATE '2020-06-15', 'MM-DD')
             AND TO_CHAR(DATE '2020-06-15' + INTERVAL '4 weeks', 'MM-DD')
            THEN sales ELSE 0 
        END) AS sales4w_after,

        -- 12 weeks
        SUM(CASE 
            WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
                 TO_CHAR(DATE '2020-06-15' - INTERVAL '12 weeks', 'MM-DD')
             AND TO_CHAR(DATE '2020-06-15' - INTERVAL '1 day', 'MM-DD')
            THEN sales ELSE 0 
        END) AS sales12w_before,
        SUM(CASE 
            WHEN TO_CHAR(week_date, 'MM-DD') BETWEEN 
                 TO_CHAR(DATE '2020-06-15', 'MM-DD')
             AND TO_CHAR(DATE '2020-06-15' + INTERVAL '12 weeks', 'MM-DD')
            THEN sales ELSE 0 
        END) AS sales12w_after
    FROM clean_weekly_sales
    GROUP BY year
)
SELECT
    year,
    '4 weeks' AS sales_period,
    sales4w_before AS sales_before,
    ROUND(sales4w_before * 100.0 / total_sales, 2) AS before_pct,
    sales4w_after AS sales_after,
    ROUND(sales4w_after * 100.0 / total_sales , 2) AS after_pct,
    ROUND((sales4w_after - sales4w_before) * 100.0 / sales4w_before, 2) AS growth_rate
FROM sales_cte
WHERE year IN (2020, 2019, 2018)

UNION ALL

SELECT
    year,
    '12 weeks' AS sales_period,
    sales12w_before AS sales_before,
    ROUND(sales12w_before * 100.0 / total_sales, 2) AS before_pct,
    sales12w_after AS sales_after,
    ROUND(sales12w_after * 100.0 / total_sales , 2) AS after_pct,
    ROUND((sales12w_after - sales12w_before) * 100.0 / sales12w_before, 2) AS growth_rate
FROM sales_cte
WHERE year IN (2020, 2019, 2018)
ORDER BY sales_period DESC, year;
```

**Result**:

<img width="972" height="184" alt="3" src="https://github.com/user-attachments/assets/f48d22fb-795b-4c87-9424-acab0bedc0cf" /><br>
- Looking at the 4 weeks around the baseline date '06-15', we can see there was a sudden increase over the years. In 2018, the growth rate was 0.19% with a slight decline to 0.19% in 2019 but suddenly jumped to 23.83% in 2020.
- In comparison to the 12 weeks around the baseline date '06-15', there was a steady decline over the years. In 2018, the growth rate was 1.63% then gradually declined from -0.30% in 2019 to -2.14% in 2020.
- Since there was a significant dropped from 2019 to 2020 around the 12 weeks, it's possible the cause behind it is the new sustainable package as this is around the time it was released. However, if we look at the overall image of the years, we can see in 2018 a high growth rate that gradually declined over the years. Is it possible that the decline over the years is because there was a massive increase in customers?

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
