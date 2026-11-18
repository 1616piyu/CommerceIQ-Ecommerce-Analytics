
-- ============================================================
-- COMMERCEIQ: MONTHLY SALES PERFORMANCE
-- Grain: One row per purchase month
-- GMV = Sum of item prices, excluding freight
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_sales_performance AS

SELECT
    d.year,
    d.quarter,
    d.month,
    d.year_month,

    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNT(DISTINCT o.customer_id) AS unique_customer_accounts,

    COUNT(DISTINCT o.customer_id) FILTER (
        WHERE o.order_status = 'delivered'
    ) AS delivered_customer_accounts,

    ROUND(SUM(i.item_price), 2) AS gmv_brl,

    ROUND(SUM(i.freight_value), 2) AS freight_revenue_brl,

    ROUND(SUM(i.item_total_with_freight), 2)
        AS total_item_value_with_freight_brl

FROM analytics.fact_orders o

JOIN analytics.dim_date d
    ON o.order_purchase_timestamp::date = d.date_key

LEFT JOIN (
    SELECT
        order_id,
        SUM(item_price) AS item_price,
        SUM(freight_value) AS freight_value,
        SUM(item_total_with_freight) AS item_total_with_freight
    FROM analytics.fact_order_items
    GROUP BY order_id
) i
    ON o.order_id = i.order_id

GROUP BY
    d.year,
    d.quarter,
    d.month,
    d.year_month;
    
-- ============================================================
-- VALIDATION: Monthly sales
-- ============================================================

SELECT *
FROM analytics.vw_sales_performance
ORDER BY year, month
LIMIT 15;

-- ============================================================
-- VALIDATION: Overall GMV from monthly view
-- ============================================================

SELECT
    ROUND(SUM(gmv_brl), 2) AS total_gmv_brl,
    SUM(total_orders) AS total_orders_across_months
FROM analytics.vw_sales_performance;
