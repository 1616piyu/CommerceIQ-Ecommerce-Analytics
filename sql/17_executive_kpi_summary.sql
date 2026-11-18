
-- =========================================================
-- 17. EXECUTIVE KPI SUMMARY
-- View: analytics.vw_executive_kpi_summary
-- Grain: one row for the entire marketplace
-- =========================================================

CREATE OR REPLACE VIEW analytics.vw_executive_kpi_summary AS

WITH sales AS (
    SELECT
        SUM(total_orders) AS total_orders,
        ROUND(SUM(gmv_brl), 2) AS total_gmv_brl,
        ROUND(SUM(freight_revenue_brl), 2) AS total_freight_brl
    FROM analytics.vw_sales_performance
),

items AS (
    SELECT
        SUM(total_items_sold) AS total_items_sold
    FROM analytics.vw_category_performance
),

customers AS (
    SELECT
        COUNT(*) AS total_unique_customers,
        COUNT(*) FILTER (
            WHERE customer_type = 'Repeat Customer'
        ) AS repeat_customers
    FROM analytics.vw_customer_performance
),

delivery AS (
    SELECT
        SUM(eligible_delivery_orders) AS eligible_delivery_orders,
        SUM(on_time_deliveries) AS on_time_deliveries,
        SUM(late_deliveries) AS late_deliveries
    FROM analytics.vw_delivery_performance
),

satisfaction AS (
    SELECT
        SUM(total_review_records) AS total_reviews,
        ROUND(
            SUM(average_review_score * total_review_records)
            / NULLIF(SUM(total_review_records), 0),
            2
        ) AS average_review_score
    FROM analytics.vw_customer_satisfaction
),

payments AS (
    SELECT
        SUM(total_payment_records) AS total_payment_records,
        ROUND(SUM(total_payment_value_brl), 2)
            AS total_payment_value_brl
    FROM analytics.vw_payment_performance
)

SELECT
    s.total_orders,
    c.total_unique_customers,
    i.total_items_sold,
    s.total_gmv_brl,
    s.total_freight_brl,

    p.total_payment_records,
    p.total_payment_value_brl,

    c.repeat_customers,

    ROUND(
        c.repeat_customers * 100.0
        / NULLIF(c.total_unique_customers, 0),
        2
    ) AS repeat_customer_percentage,

    d.eligible_delivery_orders,
    d.on_time_deliveries,
    d.late_deliveries,

    ROUND(
        d.on_time_deliveries * 100.0
        / NULLIF(d.eligible_delivery_orders, 0),
        2
    ) AS on_time_delivery_percentage,

    sf.total_reviews,
    sf.average_review_score

FROM sales s
CROSS JOIN items i
CROSS JOIN customers c
CROSS JOIN delivery d
CROSS JOIN satisfaction sf
CROSS JOIN payments p;
