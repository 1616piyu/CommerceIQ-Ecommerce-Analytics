
-- ============================================================
-- COMMERCEIQ: SELLER PERFORMANCE
-- Grain: One row per seller
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_seller_performance AS

SELECT
    i.seller_id,

    s.seller_state,

    COUNT(*) AS total_items_sold,

    COUNT(DISTINCT i.order_id) AS total_orders,

    COUNT(DISTINCT i.product_id) AS unique_products,

    ROUND(SUM(i.item_price), 2) AS gmv_brl,

    ROUND(SUM(i.freight_value), 2) AS freight_value_brl,

    ROUND(AVG(i.item_price), 2) AS average_item_price_brl

FROM analytics.fact_order_items i

LEFT JOIN analytics.dim_sellers s
    ON i.seller_id = s.seller_id

GROUP BY
    i.seller_id,
    s.seller_state;


-- ============================================================
-- VALIDATION 1: Top 15 sellers by GMV
-- ============================================================

SELECT *
FROM analytics.vw_seller_performance
ORDER BY gmv_brl DESC
LIMIT 15;


-- ============================================================
-- VALIDATION 2: Seller totals reconciliation
-- ============================================================

SELECT
    COUNT(*) AS sellers_with_sales,
    SUM(total_items_sold) AS total_items,
    SUM(gmv_brl) AS total_gmv_brl,
    SUM(freight_value_brl) AS total_freight_brl
FROM analytics.vw_seller_performance;


-- ============================================================
-- VALIDATION 3: Seller state performance
-- ============================================================

SELECT
    seller_state,
    COUNT(*) AS sellers,
    ROUND(SUM(gmv_brl), 2) AS gmv_brl
FROM analytics.vw_seller_performance
GROUP BY seller_state
ORDER BY gmv_brl DESC
LIMIT 10;
