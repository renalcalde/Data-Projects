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

### 2. Data Exploration
**1. What day of the week is used for each `week_date` value?**
- Use DISTINCT to get each unique week from `week_date`
- Use TO_CHAR to turn the `week_date` into the week name

```SQL
SELECT
    DISTINCT (week_date) as dates,
    TO_CHAR(week_date, 'fmDay') AS week_name
FROM clean_weekly_sales
GROUP BY dates;
```

**Result**:

<img width="264" height="156" alt="1" src="https://github.com/user-attachments/assets/dcc648b5-1432-474f-986e-a05c9de55fe4" />

*Only showing the first 5 rows*

- Each `week_date` starts on a Monday.


**2. What range of week numbers are missing from the dataset?**
- Use MIN() to find the earliest date in `week_date` and use MAX() to find the maximum number of weeks
- Create a week bucket using INTERVAL '7 days' to get the beginning date and ending date of that missing week
- Filter results so it only returns missing weeks from `clean_weekly_sales`

```SQL
WITH date_bounds AS(
    SELECT
        MIN(week_date)::DATE AS min_date,
        MAX(week_number) AS max_week
    FROM clean_weekly_sales
),
bucketed AS(
    SELECT
        gs.week_number,
        (d.min_date + (gs.week_number - 1) * INTERVAL '7 days')::DATE AS week_start,
        (d.min_date + (gs.week_number * INTERVAL '7 days') - INTERVAL '1 day')::DATE AS week_end
    FROM date_bounds d
    CROSS JOIN LATERAL GENERATE_SERIES(1, max_week) AS gs(week_number)
)
SELECT
    b.week_number AS missing_week_number,
    b.week_start,
    b.week_end
FROM bucketed b
LEFT JOIN clean_weekly_sales c 
    ON b.week_number = c.week_number
WHERE c.week_number IS NULL
ORDER BY b.week_number;
```

**Result**:

<img width="490" height="155" alt="2" src="https://github.com/user-attachments/assets/12dfe14e-6e49-45d9-8e35-62e2ca6a0a33" />

*Only showing the first 5 out of 56 rows of missing week number*<br>

**3. How many total transactions were there for each year in the dataset?**
- Use COUNT() to count the number of transactions in `clean_weekly_sales` and GROUP BY year

```SQL
SELECT 
    calendar_number AS year,
    COUNT(transactions) AS transaction_count
FROM clean_weekly_sales
GROUP BY calendar_number
ORDER BY calendar_number;
```

**Result**:

<img width="315" height="116" alt="3" src="https://github.com/user-attachments/assets/28ffe45d-53cc-43f7-b55a-48eae2489906" /><br>
- 2020 has the highest transaction count of 5,711 compared to 2018 with the lowest count of 5,698.

**4. What is the total sales for each region for each month?**

```SQL
SELECT 
    TO_CHAR(week_date, 'MM - MONTH') AS month_name,
    region,
    SUM(sales) AS sales_count
FROM clean_weekly_sales
GROUP BY month_name, region
ORDER BY month_name, region;
```

**Result**:

<img width="416" height="203" alt="4" src="https://github.com/user-attachments/assets/c8a5518b-ad52-41de-b74c-70c6e4723426" /><br>

*Only showing the month of March*<br>


**5. What is the total count of transactions for each platform?**
- Use COUNT() to count the number of transactions in `clean_weekly_sales` and GROUP BY platform

```SQL
SELECT 
    platform,
    COUNT(transactions) AS transaction_count
FROM clean_weekly_sales
GROUP BY platform;
```

**Result**:

<img width="345" height="91" alt="5" src="https://github.com/user-attachments/assets/655113b1-83c6-42e1-963c-8fa9fd081c86" /><br>
- Retail has the highest transaction count of 8,568 compared to Shopify with 8,549.


**6. What is the percentage of sales for Retail vs Shopify for each month?**
- Turn `month_number` into the month names using TO_CHAR()
- SUM() the sales to get the total sales and use SUM() + CASE to add up the sales for both retail and shopify platforms 
- Individually divide both platforms from the total to get the percentage and use a NULLIF() to avoid zero division
- GROUP BY month

```SQL
WITH total_cte AS(
    SELECT
        month_number,
        TO_CHAR(TO_DATE(month_number::TEXT, 'MM'), 'FMMonth') AS month,
        SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) AS retail_total,
        SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) AS shopify_total,
        SUM(sales) AS total
    FROM clean_weekly_sales
    GROUP BY month_number
)
SELECT
    month,
    ROUND((retail_total * 100.0/ NULLIF(total, 0)), 2) AS retail_pct,
    ROUND((shopify_total * 100.0/ NULLIF(total, 0)), 2) AS shopify_pct
FROM total_cte
ORDER BY month_number;
```

**Result**:

<img width="412" height="209" alt="6" src="https://github.com/user-attachments/assets/7d5f1c84-d7a8-4d3f-a02e-ca2a1a84d9b6" /><br>
- Retails holds a high percentage of sales that is about 97% across all months (March to September). This is significantly higher than Shopify sales which is only about 2% of sales across all months. 


**7. What is the percentage of sales by demographic for each year in the dataset?**
- Use SUM() + CASE to get the total sales for each demographic: families, couples and unknown
- Calculate the percentage for each demographic and GROUP BY year

```SQL
WITH total_cte AS(
	SELECT
		calendar_number,
		SUM(CASE WHEN demographic = 'Families' THEN sales ELSE 0 END) AS families_sales,
		SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END) AS couples_sales,
		SUM(CASE WHEN demographic = 'unknown' THEN sales ELSE 0 END) AS unknown_sales,
		SUM(sales) AS total
	FROM clean_weekly_sales
	GROUP BY calendar_number
)
SELECT
	calendar_number AS year,
	ROUND((families_sales * 100.0/ NULLIF(total, 0)), 2) AS families_pct,
	ROUND((couples_sales * 100.0/ NULLIF(total, 0)), 2) AS couples_pct,
	ROUND((unknown_sales * 100.0/ NULLIF(total, 0)), 2) AS unknown_pct
FROM total_cte
ORDER BY calendar_number;
```

**Result**:

<img width="564" height="112" alt="7" src="https://github.com/user-attachments/assets/9063c7a2-e9af-440d-8506-bef9cf91d9b5" /><br>
- Families and couples seem to have a steady growth over the years compared to unknown who experiences a slight decline. For instance, families in 2018 were 31.99% of sales which then jumped to 32.73% in 2020. Similarly to couples who in 2018 were 26.38% of sales which then jumped to 28.72% in 2020. However, unknown declined from 2018 (41.63%) to 2020 (38.55%). It's possible overtime, unknown has become identified and have shifted to either demographics accordingly.

**8. Which `age_band` and `demographic` values contribute the most to Retail sales?**
- Filter results so it only returns for retail sales across `age_band`, `demographic` and `segment`
- Use a SUM(SUM(sales))OVER to get the total sales across the table
- ORDER BY total percentage in descending order to get the highest percentage at the top and the lowest at the bottom

```SQL
WITH retail_cte AS(
    SELECT 
        segment,
        age_band,
        demographic,
        SUM(sales) AS total_sales,
        ROUND(SUM(sales) * 100 / SUM(SUM(sales))OVER(), 2) AS pct_of_total
    FROM clean_weekly_sales
    WHERE platform = 'Retail'
    GROUP BY age_band, demographic, segment
)
SELECT
    segment,
    age_band,
    demographic,
    pct_of_total
FROM retail_cte
ORDER BY pct_of_total DESC;
```

**Result**:

<img width="611" height="234" alt="8" src="https://github.com/user-attachments/assets/f3ad9529-b65a-4c2c-a5fc-30c409b8b2ed" /><br>
- Unknown leads with the highest percentage of 40.52% and the second highest being Retirees with families (F3) of 16.73%. Young adults with families (F1) returned with the lowest percentage total of 4.47%.

**9. Can we use the `avg_transaction` column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?**
- No, we can't because `avg_transaction` divides sales value from the transactions value. To find the transaction size, you will need to divide the sum of transaction from the transaction count. Hence, we will do the following to calculate for the transaction size.
- Use SUM() to get the total value of transactions and divide from COUNT() to find the number of transactions, then use AVG() to average the transaction size
- Use a subquery to filter results for retail
- FULL JOIN and use another subquery to filter results for shopify

```SQL
WITH transaction_cte AS(
    SELECT
        SUM(transactions) AS transaction_total,
        COUNT(transactions) AS transaction_count
    FROM clean_weekly_sales
)
SELECT
    ROUND(AVG(transaction_total/transaction_count),2) AS avg_transaction_size
FROM transaction_cte;
```

**Result**:

<img width="652" height="114" alt="9" src="https://github.com/user-attachments/assets/5107cb4b-8b63-42e7-b2b6-44069c8e0bc9" /><br>
- The average retail and shopify transaction size steadily increases over the years. Where the average transaction size for retail was 120,770 in 2018 then 130,698 in 2020. Similarly to the average transaction size for shopify with 523 in 2018 and 889 in 2020. However, as it's seen, retail has a overwhelming demand than shopify.

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
