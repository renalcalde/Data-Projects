

In a single query, perform the following operations and generate a new table in the `data_mart` schema named `clean_weekly_sales`:
- Convert the `week_date` to a `DATE` format
- Add a `week_number` as the second column for each `week_date` value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a `month_number` with the calendar month for each `week_date` value as the 3rd column
 -Add a `calendar_year` column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called `age_band` after the original `segment` column using the following mapping on the number inside the `segment` value

<div align="center">
  
| segment | age_band |
| ------- | -------- |
| 1 | Young Adults |
| 2 | Middle Aged |
| 3 or 4 | Retirees |

</div>

- Add a new `demographic` column using the following mapping for the first letter in the `segment` values:

<div align="center">

| segment | demographic |
| ------- | -------- |
| C | Couples |
| F | Families |

</div>

- Ensure all `null` string values with an `"unknown"`string value in the original `segment` column as well as the new `age_band` and `demographic` columns
- Generate a new `avg_transaction` column as the sales value divided by `transactions` rounded to 2 decimal places for each record

### 1. Data Cleansing Steps

```SQL
DROP TABLE IF EXISTS clean_weekly_sales;

CREATE TABLE clean_weekly_sales AS 
WITH date_bounds AS(
    SELECT MIN(TO_DATE(week_date, 'DD/MM/YY')) AS min_date
    FROM weekly_sales
),
bucketed AS(
    SELECT
        TO_DATE(w.week_date, 'DD/MM/YY') AS clean_week,
        FLOOR((TO_DATE(w.week_date, 'DD/MM/YY') - b.min_date) / 7)::INT AS week_bucket,
        b.min_date,
        w.region,
        w.platform,
        COALESCE(NULLIF(NULLIF(TRIM(w.segment),''), 'null'), 'unknown') AS segment,
        CASE LEFT(w.segment, 1)
            WHEN 'C' THEN 'Couples'
            WHEN 'F' THEN 'Families'
            ELSE 'unknown'
        END AS demographic,
        CASE SUBSTRING(w.segment FROM 2)
            WHEN '1' THEN 'Young Adults'
            WHEN '2' THEN 'Middle Aged'
            WHEN '3' THEN 'Retirees'
            WHEN '4' THEN 'Retirees'
            ELSE 'unknown'
        END AS age_band,
        w.customer_type,
        w.transactions,
        w.sales,
        ROUND(AVG(w.sales/ NULLIF(w.transactions, 0)),2) AS avg_transaction
    FROM weekly_sales w
    CROSS JOIN date_bounds b
    GROUP BY clean_week, b.min_date, w.region, w.platform, w.segment, w.customer_type, w.transactions, w.sales
)
SELECT
		clean_week AS week_date,
    week_bucket + 1 AS week_number,
    EXTRACT(MONTH FROM clean_week)::INT AS month_number,
    EXTRACT(YEAR FROM clean_week)::INT AS calendar_number,
    region,
    platform,
    segment,
    age_band,
    demographic,
    customer_type,
    transactions,
    sales,
    avg_transaction
FROM bucketed
ORDER BY clean_week;
```
<p align="center">
  <img width="1793" height="360" alt="clean_weekly_sales" src="https://github.com/user-attachments/assets/ae8b4a3b-f455-4ed7-a49d-9c996cd1a4fc" />
  <em>Not all outputs are shown</em> 
</p>
