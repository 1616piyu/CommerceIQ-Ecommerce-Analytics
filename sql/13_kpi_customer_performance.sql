
-- ============================================================
-- COMMERCEIQ: CUSTOMER PERFORMANCE
-- Grain: One row per actual unique customer
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_customer_performance AS

WITH customer_orders AS (

    SELECT
        dc.customer_unique_id,
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,

        COALESCE(oi.order_gmv_brl, 0) AS order_gmv_brl

    FROM analytics.fact_orders o

    JOIN analytics.dim_customers dc
        ON o.customer_id = dc.customer_id

    LEFT JOIN (
        SELECT
            order_id,
            SUM(item_price) AS order_gmv_brl
        FROM analytics.fact_order_items
        GROUP BY order_id
    ) oi
        ON o.order_id = oi.order_id
),

customer_summary AS (

    SELECT
        customer_unique_id,

        COUNT(DISTINCT order_id) AS total_orders,

        COUNT(DISTINCT order_id) FILTER (
            WHERE order_status = 'delivered'
        ) AS delivered_orders,

        ROUND(SUM(order_gmv_brl), 2) AS lifetime_gmv_brl,

        MIN(order_purchase_timestamp) AS first_order_date,

        MAX(order_purchase_timestamp) AS latest_order_date

    FROM customer_orders

    GROUP BY customer_unique_id
)

SELECT
    customer_unique_id,

    total_orders,

    delivered_orders,

    lifetime_gmv_brl,

    first_order_date,

    latest_order_date,

    CASE
        WHEN total_orders > 1 THEN 'Repeat Customer'
        ELSE 'One-time Customer'
    END AS customer_type,

    ROUND(
        lifetime_gmv_brl / NULLIF(total_orders, 0),
        2
    ) AS average_gmv_per_order_brl

FROM customer_summary;


-- ============================================================
-- VALIDATION 1: Overall customer KPIs
-- ============================================================

SELECT
    COUNT(*) AS total_unique_customers,

    COUNT(*) FILTER (
        WHERE customer_type = 'Repeat Customer'
    ) AS repeat_customers,

    COUNT(*) FILTER (
        WHERE customer_type = 'One-time Customer'
    ) AS one_time_customers,

    ROUND(
        COUNT(*) FILTER (
            WHERE customer_type = 'Repeat Customer'
        ) * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_percentage,

    ROUND(SUM(lifetime_gmv_brl), 2) AS total_customer_gmv_brl

FROM analytics.vw_customer_performance;


-- ============================================================
-- VALIDATION 2: Customer type breakdown
-- ============================================================

SELECT
    customer_type,

    COUNT(*) AS customer_count,

    ROUND(SUM(lifetime_gmv_brl), 2) AS gmv_brl,

    ROUND(AVG(total_orders), 2) AS average_orders_per_customer

FROM analytics.vw_customer_performance

GROUP BY customer_type

ORDER BY customer_count DESC;


-- ============================================================
-- VALIDATION 3: Top 15 customers by lifetime GMV
-- ============================================================

SELECT *
FROM analytics.vw_customer_performance
ORDER BY lifetime_gmv_brl DESC
LIMIT 15;


-- ============================================================
-- VALIDATION 4: Customer GMV reconciliation
-- ============================================================

SELECT
    ROUND(SUM(lifetime_gmv_brl), 2) AS customer_gmv_brl
FROM analytics.vw_customer_performance;
