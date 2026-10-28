
/*
California Outreach Spending

The original SQL script for this project were not retained. I recreated the analysis from available dataset and project outputs; these queries documents the portfolio version of the work.
*/ 

-- Compared each years' csv to find inconsistencies
-- Standarized the 2021 raw contract data: clean text, convert dates and dollar amounts, and assign report year
SELECT 
    2021 AS report_year, 
	to_date(NULLIF(btrim(report_period), ''), 'MM/DD/YYYY') AS report_period, 
    btrim(business_unit) AS business_unit, 
    btrim(department_name) AS department_name, 
    btrim(procurement_transaction_id) AS procurement_txn_id, 
    btrim(campaign_name) AS campaign_name, 
    to_date(NULLIF(btrim(report_period), ''), 'MM/DD/YYYY') AS report_period, 
    to_date(NULLIF(btrim(contract_start), ''), 'MM/DD/YYYY') AS contract_start, 
    to_date(NULLIF(btrim(contract_end), ''), 'MM/DD/YYYY') AS contract_end, 
    upper(btrim(sub_or_prime_contractor)) AS contractor_role, 
    btrim(fi_cal_supplier_id) AS supplier_id, 
    btrim(fi_cal_supplier_name) AS supplier_name, 
    NULLIF(regexp_replace(supplier_paid, '[^0-9.]', '', 'g'), '')::numeric AS supplier_paid, 
    NULLIF(regexp_replace(contract_amount_reported, '[^0-9.]', '', 'g'), '')::numeric AS contract_amount 
FROM raw_2021; 

-- Standarized 2022 raw contract data to match the same column output
SELECT 
    2022 AS report_year, 
	safe_to_date(NULLIF(btrim("Report Period"), ''), 'MM/DD/YYYY') AS report_period, 
    btrim("Business Unit") AS business_unit, 
    btrim("Department Name") AS department_name, 
    btrim("Procurement Transaction ID") AS procurement_txn_id, 
    btrim("Campaign Name") AS campaign_name, 
    safe_to_date(NULLIF(btrim("Contract Start"), ''), 'MM/DD/YYYY') AS contract_start, 
    safe_to_date(NULLIF(btrim("Contract End"), ''), 'MM/DD/YYYY') AS contract_end, 
    upper(btrim("Sub or Prime Contractor")) AS contractor_role, 
    btrim("FI$Cal Supplier ID") AS supplier_id, 
    btrim("FI$Cal Supplier Name") AS supplier_name, 
    NULLIF(regexp_replace("Supplier Paid", '[^0-9.]', '', 'g'), '')::numeric AS supplier_paid, 
    NULLIF(regexp_replace("Contract Amount Reported", '[^0-9.]', '', 'g'), '')::numeric AS contract_amount 
FROM raw_2022; 

-- Standarized 2023 raw contract data to match the same column output
SELECT 
    2023 AS report_year, 
	safe_to_date(NULLIF(btrim("Report Period"), ''), 'DD-Mon-YY') AS report_period, 
    btrim("Business Unit") AS business_unit, 
    btrim("Department Name") AS department_name, 
    btrim("Procurement Transaction ID") AS procurement_txn_id, 
    btrim("Campaign Name") AS campaign_name, 
    safe_to_date(NULLIF(btrim("Contract Start"), ''), 'MM/DD/YYYY') AS contract_start, 
    safe_to_date(NULLIF(btrim("Contract End"), ''), 'MM/DD/YYYY') AS contract_end, 
    upper(btrim("Sub or Prime Contractor")) AS contractor_role, 
    btrim("FI$Cal Supplier ID") AS supplier_id, 
    btrim("FI$Cal Supplier Name") AS supplier_name, 
    NULLIF(regexp_replace("Supplier Paid", '[^0-9.]', '', 'g'), '')::numeric AS supplier_paid, 
    NULLIF(regexp_replace("Contract Amount Reported", '[^0-9.]', '', 'g'), '')::numeric AS contract_amount 
FROM raw_2023; 

/*
Undocumented:
Created two tables: contracts and outreach spend, before handling any duplicates or missing values, then combining it into full_dataset
*/

-- Compared annual outreach spending totals across the cleaned outreach table
SELECT 'outreach_spend' AS source, report_year, sum(amount) AS total
FROM outreach_spend_cleaned
GROUP BY report_year

UNION ALL

SELECT 'full_dataset', report_year, sum(outreach_amount)
FROM full_dataset
GROUP BY report_year

UNION ALL

SELECT 'live join', c.report_year, sum(o.amount)
FROM contracts_cleaned c
JOIN outreach_spend_cleaned o
  ON c.report_year = o.report_year AND c.row_id = o.row_id
GROUP BY c.report_year

ORDER BY report_year, source;

-- Compare yearly spending totals before and after cleaning the outreach data
SELECT 'uncleaned' AS version, report_year, sum(amount) AS total
FROM outreach_spend
GROUP BY report_year

UNION ALL

SELECT 'cleaned', report_year, sum(amount)
FROM outreach_spend_cleaned
GROUP BY report_year

ORDER BY report_year, version;

-- Count cleaned contracts by year and inspect the range of contract start dates
SELECT report_year, count(*) AS contracts, min(contract_start), max(contract_start)
FROM contracts_cleaned
GROUP BY report_year
ORDER BY report_year;

-- View the 10 largest outreach spending records and their linked contract details.
SELECT o.report_year, o.row_id, o.community, o.media_type, o.amount,
       c.contract_amount, c.department_name, c.supplier_name, c.campaign_name
FROM outreach_spend_cleaned o
JOIN contracts_cleaned c ON c.report_year = o.report_year AND c.row_id = o.row_id
ORDER BY o.amount DESC
LIMIT 10;

-- Rank campaigns by total outreach spending
SELECT c.report_year, c.campaign_name, sum(o.amount) AS outreach_total
FROM outreach_spend_cleaned o
JOIN contracts_cleaned c ON c.report_year = o.report_year AND c.row_id = o.row_id
GROUP BY c.report_year, c.campaign_name
ORDER BY outreach_total DESC
LIMIT 40;

-- Compare outreach spending for campaigns labeled COVID-related or other
SELECT c.report_year,
       CASE WHEN c.campaign_name ILIKE '%covid%'
              OR c.campaign_name ILIKE '%vaccin%'
              OR c.campaign_name ILIKE '%vax%'
			  OR c.campaign_name ILIKE '%pandemic%'
            THEN 'COVID-related' ELSE 'Other' END AS category,
       sum(o.amount) AS outreach_total
FROM outreach_spend_cleaned o
JOIN contracts_cleaned c ON c.report_year = o.report_year AND c.row_id = o.row_id
GROUP BY 1, 2
ORDER BY 1, 2;

-- Compare spending by media type in 2021 and 2023, and calculate the percentage change between those years.
SELECT media_type, 
       sum(amount) FILTER (WHERE report_year = 2021) AS y2021,
       sum(amount) FILTER (WHERE report_year = 2023) AS y2023,
       ROUND(100.0 * (COALESCE(sum(amount) FILTER (WHERE report_year = 2023), 0)
         - COALESCE(sum(amount) FILTER (WHERE report_year = 2021), 0))
         / NULLIF(sum(amount) FILTER (WHERE report_year = 2021), 0), 1) AS pct_change
FROM outreach_spend_cleaned
GROUP BY media_type
ORDER BY pct_change DESC NULLS LAST;
