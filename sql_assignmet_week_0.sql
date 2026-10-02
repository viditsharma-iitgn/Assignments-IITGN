
---

## Q1. Basic Filtering — High-Value Products


USE retail_events_db;

SELECT
    event_id,
    store_id,
    product_code,
    base_price,
    promo_type
FROM fact_events
WHERE base_price > 1000;

---

## Q2. Sorting Promotional Events



SELECT
    event_id,
    product_code,
    promo_type,
    `quantity_sold(before_promo)`,
    `quantity_sold(after_promo)`
FROM fact_events
WHERE `quantity_sold(after_promo)` > 100
ORDER BY `quantity_sold(after_promo)` DESC;


---

## Q3. Distinct Promotion Types


SELECT DISTINCT
    promo_type
FROM fact_events;


---

## Q4. Basic Aggregation




SELECT
    COUNT(*) AS event_count,
    SUM(`quantity_sold(before_promo)`) AS total_before,
    SUM(`quantity_sold(after_promo)`) AS total_after,
    AVG(base_price) AS average_base_price,
    MAX(base_price) AS maximum_base_price,
    MIN(base_price) AS minimum_base_price
FROM fact_events;


---

## Q5. Sales Volume by Promotion Type


SELECT
    promo_type,
    COUNT(*) AS event_count,
    SUM(`quantity_sold(before_promo)`) AS total_before,
    SUM(`quantity_sold(after_promo)`) AS total_after
FROM fact_events
GROUP BY promo_type
ORDER BY total_after DESC;


---

## Q6. Promotion Uplift


SELECT
    promo_type,
    SUM(`quantity_sold(before_promo)`) AS total_before,
    SUM(`quantity_sold(after_promo)`) AS total_after,
    SUM(`quantity_sold(after_promo)`)
        - SUM(`quantity_sold(before_promo)`) AS quantity_change
FROM fact_events
GROUP BY promo_type
ORDER BY quantity_change DESC;


---

## Q7. Product Performance




SELECT
    p.product_code,
    p.product_name,
    p.category,
    SUM(f.`quantity_sold(after_promo)`) AS total_quantity_after
FROM fact_events AS f
INNER JOIN dim_products AS p
    ON f.product_code = p.product_code
GROUP BY
    p.product_code,
    p.product_name,
    p.category
ORDER BY total_quantity_after DESC;


---

## Q8. Category-Level Performance


SELECT
    p.category,
    COUNT(*) AS event_count,
    SUM(f.`quantity_sold(before_promo)`) AS total_before,
    SUM(f.`quantity_sold(after_promo)`) AS total_after,
    SUM(f.`quantity_sold(after_promo)`)
        - SUM(f.`quantity_sold(before_promo)`) AS quantity_change
FROM fact_events AS f
INNER JOIN dim_products AS p
    ON f.product_code = p.product_code
GROUP BY p.category
ORDER BY total_after DESC;


---

## Q9. Store Performance


SELECT
    s.city,
    COUNT(*) AS event_count,
    SUM(f.`quantity_sold(before_promo)`) AS total_before,
    SUM(f.`quantity_sold(after_promo)`) AS total_after
FROM fact_events AS f
INNER JOIN dim_stores AS s
    ON f.store_id = s.store_id
GROUP BY s.city
ORDER BY total_after DESC;


---

## Q10. Campaign Performance

SELECT
    c.campaign_name,
    c.start_date,
    c.end_date,
    COUNT(*) AS event_count,
    SUM(f.`quantity_sold(before_promo)`) AS total_before,
    SUM(f.`quantity_sold(after_promo)`) AS total_after
FROM fact_events AS f
INNER JOIN dim_campaigns AS c
    ON f.campaign_id = c.campaign_id
GROUP BY
    c.campaign_id,
    c.campaign_name,
    c.start_date,
    c.end_date
ORDER BY total_after DESC;


---

## Q11. Product Category with HAVING


SELECT
    p.category,
    SUM(f.`quantity_sold(after_promo)`) AS total_after,
    AVG(f.base_price) AS average_base_price
FROM fact_events AS f
INNER JOIN dim_products AS p
    ON f.product_code = p.product_code
GROUP BY p.category
HAVING total_after > 1000
ORDER BY total_after DESC;


---

## Q12. Store and Category Analysis


SELECT
    s.city,
    p.category,
    SUM(f.`quantity_sold(after_promo)`) AS total_after
FROM fact_events AS f
INNER JOIN dim_products AS p
    ON f.product_code = p.product_code
INNER JOIN dim_stores AS s
    ON f.store_id = s.store_id
GROUP BY
    s.city,
    p.category
ORDER BY
    s.city ASC,
    total_after DESC;


---

## Q13. Promotion Effectiveness by Product


SELECT
    p.product_name,
    p.category,
    SUM(f.`quantity_sold(before_promo)`) AS total_before,
    SUM(f.`quantity_sold(after_promo)`) AS total_after,
    SUM(f.`quantity_sold(after_promo)`)
        - SUM(f.`quantity_sold(before_promo)`) AS quantity_change,
    ROUND(
        (
            SUM(f.`quantity_sold(after_promo)`)
            - SUM(f.`quantity_sold(before_promo)`)
        ) * 100.0
        / NULLIF(SUM(f.`quantity_sold(before_promo)`), 0),
        2
    ) AS percentage_change
FROM fact_events AS f
INNER JOIN dim_products AS p
    ON f.product_code = p.product_code
GROUP BY
    p.product_code,
    p.product_name,
    p.category
ORDER BY percentage_change DESC;


---

## Q14. Campaign and Promotion Type Analysis

SELECT
    c.campaign_name,
    f.promo_type,
    COUNT(*) AS event_count,
    SUM(f.`quantity_sold(before_promo)`) AS total_before,
    SUM(f.`quantity_sold(after_promo)`) AS total_after,
    SUM(f.`quantity_sold(after_promo)`)
        - SUM(f.`quantity_sold(before_promo)`) AS quantity_change
FROM fact_events AS f
INNER JOIN dim_campaigns AS c
    ON f.campaign_id = c.campaign_id
GROUP BY
    c.campaign_id,
    c.campaign_name,
    f.promo_type
ORDER BY
    c.campaign_name ASC,
    quantity_change DESC;


---

## Q15. Product Revenue Before and After Promotion


WITH product_revenue AS (
    SELECT
        p.product_code,
        p.product_name,
        p.category,
        SUM(
            f.base_price * f.`quantity_sold(before_promo)`
        ) AS revenue_before,
        SUM(
            f.base_price * f.`quantity_sold(after_promo)`
        ) AS revenue_after
    FROM fact_events AS f
    INNER JOIN dim_products AS p
        ON f.product_code = p.product_code
    GROUP BY
        p.product_code,
        p.product_name,
        p.category
)
SELECT
    product_name,
    category,
    revenue_before,
    revenue_after,
    revenue_after - revenue_before AS revenue_difference
FROM product_revenue
ORDER BY revenue_difference DESC;


---

## Q16. Classify Promotion Performance


WITH promotion_summary AS (
    SELECT
        promo_type,
        SUM(`quantity_sold(before_promo)`) AS total_before,
        SUM(`quantity_sold(after_promo)`) AS total_after,
        ROUND(
            (
                SUM(`quantity_sold(after_promo)`)
                - SUM(`quantity_sold(before_promo)`)
            ) * 100.0
            / NULLIF(SUM(`quantity_sold(before_promo)`), 0),
            2
        ) AS percentage_change
    FROM fact_events
    GROUP BY promo_type
)
SELECT
    promo_type,
    total_before,
    total_after,
    percentage_change,
    CASE
        WHEN percentage_change >= 50 THEN 'High Impact'
        WHEN percentage_change >= 20 THEN 'Medium Impact'
        ELSE 'Low Impact'
    END AS performance_category
FROM promotion_summary
ORDER BY percentage_change DESC;


---

## Q17. Top Products Within Each Category


WITH product_totals AS (
    SELECT
        p.product_code,
        p.category,
        p.product_name,
        SUM(f.`quantity_sold(after_promo)`) AS total_quantity_after
    FROM fact_events AS f
    INNER JOIN dim_products AS p
        ON f.product_code = p.product_code
    GROUP BY
        p.product_code,
        p.category,
        p.product_name
),
ranked_products AS (
    SELECT
        category,
        product_name,
        total_quantity_after,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY total_quantity_after DESC
        ) AS category_rank
    FROM product_totals
)
SELECT
    category,
    product_name,
    total_quantity_after,
    category_rank
FROM ranked_products
WHERE category_rank <= 2
ORDER BY
    category,
    category_rank;


---

## Q18. Best-Performing Stores Within Each City

WITH store_totals AS (
    SELECT
        s.city,
        s.store_id,
        SUM(f.`quantity_sold(after_promo)`) AS total_quantity_after
    FROM dim_stores AS s
    INNER JOIN fact_events AS f
        ON s.store_id = f.store_id
    GROUP BY
        s.city,
        s.store_id
),
ranked_stores AS (
    SELECT
        city,
        store_id,
        total_quantity_after,
        DENSE_RANK() OVER (
            PARTITION BY city
            ORDER BY total_quantity_after DESC
        ) AS city_rank
    FROM store_totals
)
SELECT
    city,
    store_id,
    total_quantity_after,
    city_rank
FROM ranked_stores
WHERE city_rank <= 2
ORDER BY
    city,
    city_rank;


---

## Q19. Campaign-Level Product Performance

WITH campaign_product_totals AS (
    SELECT
        c.campaign_id,
        c.campaign_name,
        p.product_code,
        p.product_name,
        SUM(f.`quantity_sold(before_promo)`) AS total_before,
        SUM(f.`quantity_sold(after_promo)`) AS total_after,
        SUM(f.`quantity_sold(after_promo)`)
            - SUM(f.`quantity_sold(before_promo)`) AS quantity_change,
        ROUND(
            (
                SUM(f.`quantity_sold(after_promo)`)
                - SUM(f.`quantity_sold(before_promo)`)
            ) * 100.0
            / NULLIF(SUM(f.`quantity_sold(before_promo)`), 0),
            2
        ) AS percentage_change
    FROM fact_events AS f
    INNER JOIN dim_campaigns AS c
        ON f.campaign_id = c.campaign_id
    INNER JOIN dim_products AS p
        ON f.product_code = p.product_code
    GROUP BY
        c.campaign_id,
        c.campaign_name,
        p.product_code,
        p.product_name
),
ranked_products AS (
    SELECT
        campaign_id,
        campaign_name,
        product_name,
        total_before,
        total_after,
        quantity_change,
        percentage_change,
        ROW_NUMBER() OVER (
            PARTITION BY campaign_id
            ORDER BY percentage_change DESC
        ) AS campaign_rank
    FROM campaign_product_totals
)
SELECT
    campaign_name,
    product_name,
    total_before,
    total_after,
    quantity_change,
    percentage_change,
    campaign_rank
FROM ranked_products
WHERE campaign_rank <= 3
ORDER BY
    campaign_name,
    campaign_rank;


---

## Q20. Complete Promotional Performance Analysis


WITH product_metrics AS (
    SELECT
        p.product_code,
        p.product_name,
        p.category,
        COUNT(*) AS event_count,
        SUM(f.`quantity_sold(before_promo)`) AS total_before,
        SUM(f.`quantity_sold(after_promo)`) AS total_after,
        SUM(f.`quantity_sold(after_promo)`)
            - SUM(f.`quantity_sold(before_promo)`) AS quantity_change,
        ROUND(
            (
                SUM(f.`quantity_sold(after_promo)`)
                - SUM(f.`quantity_sold(before_promo)`)
            ) * 100.0
            / NULLIF(SUM(f.`quantity_sold(before_promo)`), 0),
            2
        ) AS percentage_change,
        SUM(
            f.base_price * f.`quantity_sold(before_promo)`
        ) AS revenue_before,
        SUM(
            f.base_price * f.`quantity_sold(after_promo)`
        ) AS revenue_after,
        SUM(
            f.base_price * f.`quantity_sold(after_promo)`
        )
        - SUM(
            f.base_price * f.`quantity_sold(before_promo)`
        ) AS revenue_change,
        AVG(f.base_price) AS average_base_price
    FROM fact_events AS f
    INNER JOIN dim_products AS p
        ON f.product_code = p.product_code
    GROUP BY
        p.product_code,
        p.product_name,
        p.category
),
ranked_products AS (
    SELECT
        product_name,
        category,
        event_count,
        total_before,
        total_after,
        quantity_change,
        percentage_change,
        revenue_before,
        revenue_after,
        revenue_change,
        average_base_price,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY revenue_change DESC
        ) AS product_rank
    FROM product_metrics
)
SELECT
    product_name,
    category,
    event_count,
    total_before,
    total_after,
    quantity_change,
    percentage_change,
    revenue_before,
    revenue_after,
    revenue_change,
    average_base_price,
    product_rank
FROM ranked_products
WHERE product_rank <= 2
ORDER BY
    category,
    product_rank;
