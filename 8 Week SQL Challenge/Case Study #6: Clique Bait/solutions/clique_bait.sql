
/*
8 WEEK SQL CHALLENGE: Case Study #5 - Clique Bait
*/

-- 2. Digital Analysis
-- Q1
SELECT COUNT(DISTINCT(user_id)) FROM users;

-- Q2
WITH count_cte AS(
    SELECT
        user_id,
        COUNT(cookie_id) AS cookie_count
    FROM users
    GROUP BY user_id
)
SELECT
    ROUND(AVG(cookie_count)) AS avg_cookie
FROM count_cte;

-- Q3
SELECT
    TO_CHAR(u.start_date, 'MM - Month') AS month,
    COUNT(DISTINCT e.visit_id) AS visit_count
FROM users u
INNER JOIN events e
    ON u.cookie_id = e.cookie_id
GROUP BY month
ORDER BY month;

-- Q4
With name_cte AS(
    SELECT
        i.event_name,
        e.event_type,
        COUNT(*) as event_count
    FROM events e
    INNER JOIN event_identifier i
        ON e.event_type = i.event_type
    GROUP BY e.event_type, i.event_name
)
SELECT 
    event_name,
    event_count
FROM name_cte
ORDER BY event_type;

-- Q5
SELECT
    ROUND(SUM(CASE WHEN event_type = 3 THEN 1 END ) * 100.0 / COUNT(DISTINCT (visit_id)),2) AS purchase_pct
FROM events

-- Q6
WITH pct_cte AS(
    SELECT
        visit_id,
        MAX(CASE WHEN page_id = 12 AND event_type = 1 THEN 1 END) AS checkout_count,
        MAX(CASE WHEN event_type = 3 THEN 1 END) AS purchase_count
    FROM events
    GROUP BY visit_id
)
SELECT
    ROUND(100.0 * (1 - (SUM(purchase_count) * 1.0/ SUM(checkout_count))), 2) AS pct
FROM pct_cte;

-- Q7
SELECT
    p.page_name,
    COUNT(e.page_id) AS page_count
FROM page_hierarchy p
INNER JOIN events e
    ON p.page_id = e.page_id
GROUP BY p.page_name
ORDER BY page_count DESC
LIMIT 3;

-- Q8
SELECT
    p.product_category,
    SUM(CASE WHEN e.event_type = 1 THEN 1 END) AS view_count,
    SUM(CASE WHEN e.event_type = 2 THEN 1 END) AS add_count
FROM events e
INNER JOIN page_hierarchy p
    ON e.page_id = p.page_id
WHERE p.product_category IS NOT NULL
GROUP BY p.product_category;

-- Q9
SELECT
    (CASE WHEN p.product_id IS NOT NULL THEN p.page_name END) AS product_name,
    COUNT(*) AS purchase_count
FROM events e
INNER JOIN page_hierarchy p 
    ON e.page_id = p.page_id
WHERE e.event_type = 2
  AND e.visit_id IN (
    SELECT visit_id
    FROM events 
    WHERE event_type = 3
)
GROUP BY p.product_id, p.page_name
ORDER BY purchase_count DESC
LIMIT 3;

-- 3. Product Funnel Analysis
-- product_info table
DROP TABLE IF EXISTS product_info;

CREATE TABLE product_info AS
WITH base_cte AS(
    SELECT
        e.visit_id,
        e.page_id,
        e.event_type,
        h.page_name,
        h.product_id,
        SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS viewed,
        SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart
    FROM events e
    INNER JOIN page_hierarchy h 
        ON e.page_id = h.page_id
    GROUP BY e.visit_id, e.page_id, h.page_name, h.product_id, e.event_type
),
purchased_cte AS(
    SELECT 
        DISTINCT visit_id
    FROM events
    WHERE event_type = 3
),
combine_cte AS(
    SELECT
        b.visit_id,
        b.page_id,
        b.event_type,
        b.page_name,
        b.product_id,
        b.viewed,
        b.add_to_cart,
        CASE WHEN p.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
    FROM base_cte b
    LEFT JOIN purchased_cte p
        ON b.visit_id = p.visit_id
),
info_cte AS(
    SELECT
        product_id,
        page_name AS product_name,
        SUM(viewed) AS viewed,
        SUM(add_to_cart) AS cart_added,
        SUM(CASE WHEN add_to_cart >= 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
        SUM(CASE WHEN add_to_cart >= 1 AND purchase >= 1 THEN 1 ELSE 0 END) AS purchased
    FROM combine_cte
    GROUP BY product_id, product_name
)
SELECT
    product_name,
    viewed,
    cart_added,
    abandoned,
    purchased
FROM info_cte
WHERE product_id IS NOT NULL
ORDER BY product_id;

-- product_category_info table

DROP TABLE IF EXISTS product_category_info;

CREATE TABLE product_category_info AS 
WITH base_cte AS(
    SELECT
        e.visit_id,
        e.page_id,
        e.event_type,
        h.product_category,
        h.product_id,
        SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS viewed,
        SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart
    FROM events e
    INNER JOIN page_hierarchy h 
        ON e.page_id = h.page_id
    GROUP BY e.visit_id, e.page_id, h.product_category, h.product_id, e.event_type
),
purchased_cte AS(
    SELECT 
        DISTINCT visit_id
    FROM events
    WHERE event_type = 3
),
combine_cte AS(
    SELECT
        b.visit_id,
        b.page_id,
        b.event_type,
        b.product_category,
        b.product_id,
        b.viewed,
        b.add_to_cart,
        CASE WHEN p.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
    FROM base_cte b
    LEFT JOIN purchased_cte p
        ON b.visit_id = p.visit_id
),
info_cte AS(
    SELECT
        product_category,
        SUM(viewed) AS viewed,
        SUM(add_to_cart) AS cart_added,
        SUM(CASE WHEN add_to_cart >= 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
        SUM(CASE WHEN add_to_cart >= 1 AND purchase >= 1 THEN 1 ELSE 0 END) AS purchased
    FROM combine_cte
    GROUP BY product_category
)
SELECT
    product_category,
    viewed,
    cart_added,
    abandoned,
    purchased
FROM info_cte
WHERE product_category IS NOT NULL;

-- Q1
SELECT 
    product_name,
    viewed, 
    cart_added, 
    purchased 
FROM product_info;

-- Q2
SELECT 
    product_name,
    abandoned
FROM product_info
ORDER BY abandoned DESC;

-- Q3
SELECT 
    product_name,
    ROUND(MAX(purchased * 100.0 / viewed), 2) AS view_to_purchase_pct
FROM product_info
GROUP BY product_name
ORDER BY view_to_purchase_pct DESC;

-- Q4
SELECT
    ROUND(AVG(cart_added * 100 / viewed), 2) AS avg_conversion_rate
FROM product_info;

-- Q5
SELECT
    ROUND(AVG(purchased * 100 / cart_added), 2) AS avg_conversion_rate
FROM product_info;

-- 3. Campaigns Analysis

DROP TABLE IF EXISTS campaign_info;

CREATE TABLE campaign_info AS 
SELECT 
    MAX(u.user_id) AS user_id,
    e.visit_id,
    MIN(e.event_time) AS visit_start_time,
    SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_views,
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds,
    MAX(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchase,
    COALESCE(MAX(c.campaign_name), 'No Campaign') AS campaign
    SUM(CASE WHEN e.event_type = 4 THEN 1 ELSE 0 END) AS impression,
    SUM(CASE WHEN e.event_type = 5 THEN 1 ELSE 0 END) AS click,
    STRING_AGG(p.product_id::TEXT, ', ' ORDER BY e.sequence_number) AS cart_products
FROM events e
INNER JOIN users u 
    ON e.cookie_id = u.cookie_id
INNER JOIN campaign_identifier c
    ON e.event_time BETWEEN c.start_date AND c.end_date
INNER JOIN page_hierarchy p 
    ON e.page_id = p.page_id 
GROUP BY e.visit_id
ORDER BY user_id, visit_start_time;

-- Q1
SELECT
    impression,
    COUNT(DISTINCT user_id) AS user_count
FROM campaign_info
WHERE impression IN (1, 0)
GROUP BY impression;

-- Q2
WITH count_cte AS(
    SELECT 
        SUM(CASE WHEN impression = 1 THEN 1 ELSE 0 END) AS impression_count,
        SUM(CASE WHEN click = 1 THEN 1 ELSE 0 END) AS click_count
    FROM campaign_info
)
SELECT
    ROUND(SUM(click_count * 100.0/ impression_count), 2) AS click_thru_rate
FROM count_cte;

-- Q3
WITH count_cte AS (
    SELECT
        COUNT(*) FILTER (WHERE impression = 1 AND click = 0) AS imp_no_click_visits,
        COUNT(*) FILTER (WHERE impression = 1 AND click = 0 AND purchase >= 1) AS imp_no_click_purchases,
        COUNT(*) FILTER (WHERE click = 1) AS click_visits,
        COUNT(*) FILTER (WHERE click = 1 AND purchase >= 1) AS click_purchases
    FROM campaign_info
),
rates_cte AS (
    SELECT
        (imp_no_click_purchases * 100.0 / imp_no_click_visits) AS imp_no_click_rate,
        (click_purchases * 100.0 / click_visits) AS click_rate
    FROM count_cte
)
SELECT
    ROUND(imp_no_click_rate, 2) AS no_click_rate,
    ROUND(click_rate, 2) AS click_rate,
    ROUND(click_rate - imp_no_click_rate, 2) AS uplift_pp
FROM rates_cte;

-- Q4
WITH count_cte AS (
    SELECT
        -- no impression
        COUNT(*) FILTER (WHERE impression = 0) AS no_imp_visits,
        COUNT(*) FILTER (WHERE impression = 0 AND purchase >= 1) AS no_imp_purchases,

        -- impression w/ no click
        COUNT(*) FILTER (WHERE impression = 1 AND click = 0) AS imp_no_click_visits,
        COUNT(*) FILTER (WHERE impression = 1 AND click = 0 AND purchase >= 1) AS imp_no_click_purchases,

        -- impression w/ click
        COUNT(*) FILTER (WHERE click = 1) AS click_visits,
        COUNT(*) FILTER (WHERE click = 1 AND purchase >= 1) AS click_purchases
    FROM campaign_info
),
rates_cte AS (
    SELECT
        (no_imp_purchases * 100.0 / no_imp_visits) AS no_imp_rate,
        (imp_no_click_purchases * 100.0 / imp_no_click_visits) AS imp_no_click_rate,
        (click_purchases * 100.0 / click_visits) AS click_rate
    FROM count_cte
)
SELECT
    ROUND(no_imp_rate, 2) AS no_impression_rate,
    ROUND(imp_no_click_rate, 2) AS impression_no_click_rate,
    ROUND(click_rate, 2) AS click_rate,
    ROUND(imp_no_click_rate - no_imp_rate, 2) AS uplift_no_click_pp,
    ROUND(click_rate - no_imp_rate, 2) AS uplift_click_pp
FROM rates_cte;

-- Q5
WITH visit_summary_cte AS (
  SELECT
    visit_id,
    CASE WHEN impression = 1 THEN 1 ELSE 0 END AS impression,
    CASE WHEN click = 1 THEN 1 ELSE 0 END AS click,
    CASE WHEN purchase >= 1 THEN 1 ELSE 0 END AS purchase
  FROM campaign_info
),
funnel_cte AS (
  SELECT
    COUNT(*) AS all_visits,
    SUM(impression) AS saw_ad,
    SUM(CASE WHEN impression = 1 AND click = 1 THEN 1 ELSE 0 END) AS clicked,
    SUM(CASE WHEN impression = 1 AND click = 1 AND purchase >= 1 THEN 1 ELSE 0 END) AS clicked_and_purchased
  FROM visit_summary_cte
)
SELECT
  all_visits,
  saw_ad,
  clicked,
  clicked_and_purchased,
  ROUND(100.0 * saw_ad / all_visits, 2) AS all_to_saw_ad_pct,
  ROUND(100.0 * clicked / saw_ad, 2) AS saw_ad_to_clicked_pct,
  ROUND(100.0 * clicked_and_purchased / clicked, 2) AS clicked_to_purchased_pct

-- Q6
WITH count_cte AS(
SELECT
    SUM(CASE WHEN c.impression = 1 AND i.campaign_id = 1 THEN 1 ELSE 0 END) AS fish_impression_count,
    SUM(CASE WHEN c.impression = 1 AND i.campaign_id = 2 THEN 1 ELSE 0 END) AS luxury_impression_count,
    SUM(CASE WHEN c.impression = 1 AND i.campaign_id = 3 THEN 1 ELSE 0 END) AS shellfish_impression_count,
    COUNT(DISTINCT c.user_id) AS user_count
FROM campaign_info c
INNER JOIN campaign_identifier i
    ON c.campaign = i.campaign_name
)
SELECT 
    ROUND(SUM(fish_impression_count * 100.0/ user_count), 2) AS avg_fish_campaign,
    ROUND(SUM(luxury_impression_count * 100.0/ user_count), 2) AS avg_luxury_campaign,
    ROUND(SUM(shellfish_impression_count * 100.0/ user_count), 2) AS avg_shellfish_campaign
FROM count_cte;

-- Q7
WITH count_cte AS(
    SELECT 
        -- fish campaign
        SUM(CASE WHEN c.impression = 1 AND i.campaign_id = 1 THEN 1 ELSE 0 END) AS f_impression_count,
        SUM(CASE WHEN c.click = 1 AND i.campaign_id = 1 THEN 1 ELSE 0 END) AS f_click_count,

        -- luxury campaign
        SUM(CASE WHEN c.impression = 1 AND i.campaign_id = 2 THEN 1 ELSE 0 END) AS l_impression_count,
        SUM(CASE WHEN c.click = 1 AND i.campaign_id = 2 THEN 1 ELSE 0 END) AS l_click_count,

        -- shellfish campaign
        SUM(CASE WHEN c.impression = 1 AND i.campaign_id = 3 THEN 1 ELSE 0 END) AS s_impression_count,
        SUM(CASE WHEN c.click = 1 AND i.campaign_id = 3 THEN 1 ELSE 0 END) AS s_click_count
    FROM campaign_info c
    INNER JOIN campaign_identifier i
        ON c.campaign = i.campaign_name
)
SELECT
    ROUND(SUM(f_click_count * 100.0/ f_impression_count), 2) AS fish_click_thru_rate,
    ROUND(SUM(l_click_count * 100.0/ l_impression_count), 2) AS luxury_click_thru_rate,
    ROUND(SUM(s_click_count * 100.0/ s_impression_count), 2) AS shellfish_click_thru_rate
FROM count_cte;

-- Q8
WITH campaign_cte AS(
SELECT
    -- fish campaign
    SUM(CASE WHEN c.impression = 1 AND c.click = 1 AND c.purchase >= 1 AND i.campaign_id = 1 THEN 1 ELSE 0 END) AS purchase_fish_campaign,
    SUM(CASE WHEN c.impression = 1 AND c.click = 1 AND i.campaign_id = 1 THEN 1 ELSE 0 END) AS fish_campaign,

    -- luxury campaign
    SUM(CASE WHEN c.impression = 1 AND c.click = 1 AND c.purchase >= 1 AND i.campaign_id = 2 THEN 1 ELSE 0 END) AS purchase_luxury_campaign,
    SUM(CASE WHEN c.impression = 1 AND c.click = 1 AND i.campaign_id = 2 THEN 1 ELSE 0 END) AS luxury_campaign,

    -- shellfish campaign
    SUM(CASE WHEN c.impression = 1 AND c.click = 1 AND c.purchase >= 1 AND i.campaign_id = 3 THEN 1 ELSE 0 END) AS purchase_shellfish_campaign,
    SUM(CASE WHEN c.impression = 1 AND c.click = 1 AND i.campaign_id = 3 THEN 1 ELSE 0 END) AS shellfish_campaign
FROM campaign_info c
INNER JOIN campaign_identifier i
    ON c.campaign = i.campaign_name
)
SELECT
    ROUND(SUM(purchase_fish_campaign * 100.0/ fish_campaign), 2) AS fish_campaign_conversion_rate,
    ROUND(SUM(purchase_luxury_campaign * 100.0/ luxury_campaign), 2) AS luxury_campaign_conversion_rate,
    ROUND(SUM(purchase_shellfish_campaign * 100.0/ shellfish_campaign), 2) AS shellfish_campaign_conversion_rate
FROM campaign_cte;