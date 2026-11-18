
-- ============================================================
-- COMMERCEIQ: CATEGORY PERFORMANCE
-- Grain: One row per product category
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_category_performance AS

SELECT
    COALESCE(
        p.product_category_english,
        'Unknown'
    ) AS product_category,

    COUNT(*) AS total_items_sold,

    COUNT(DISTINCT i.order_id) AS total_orders,

    COUNT(DISTINCT i.product_id) AS unique_products,

    COUNT(DISTINCT i.seller_id) AS unique_sellers,

    ROUND(SUM(i.item_price), 2) AS gmv_brl,

    ROUND(SUM(i.freight_value), 2) AS freight_value_brl,

    ROUND(
        AVG(i.item_price),
        2
    ) AS average_item_price_brl

FROM analytics.fact_order_items i

LEFT JOIN analytics.dim_products p
    ON i.product_id = p.product_id

GROUP BY
    COALESCE(p.product_category_english, 'Unknown');


-- ============================================================
-- VALIDATION 1: Top 15 categories by GMV
-- ============================================================

SELECT *
FROM analytics.vw_category_performance
ORDER BY gmv_brl DESC
LIMIT 15;


-- ============================================================
-- VALIDATION 2: Category totals must reconcile
-- ============================================================

SELECT
    SUM(total_items_sold) AS total_items,
    SUM(gmv_brl) AS total_gmv_brl,
    SUM(freight_value_brl) AS total_freight_brl
FROM analytics.vw_category_performance;


-- ============================================================
-- VALIDATION 3: Category count
-- ============================================================

SELECT
    COUNT(*) AS total_categories
FROM analytics.vw_category_performance;
