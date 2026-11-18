
-- =========================================================
-- 18. FINAL WAREHOUSE VALIDATION
-- Read-only checks for CommerceIQ analytical warehouse
-- =========================================================

-- 1. Analytical tables and row counts
SELECT 'dim_customers' AS table_name, COUNT(*) AS total_rows
FROM analytics.dim_customers
UNION ALL
SELECT 'dim_products', COUNT(*)
FROM analytics.dim_products
UNION ALL
SELECT 'dim_sellers', COUNT(*)
FROM analytics.dim_sellers
UNION ALL
SELECT 'dim_date', COUNT(*)
FROM analytics.dim_date
UNION ALL
SELECT 'fact_orders', COUNT(*)
FROM analytics.fact_orders
UNION ALL
SELECT 'fact_order_items', COUNT(*)
FROM analytics.fact_order_items
UNION ALL
SELECT 'fact_payments', COUNT(*)
FROM analytics.fact_payments
UNION ALL
SELECT 'fact_reviews', COUNT(*)
FROM analytics.fact_reviews
ORDER BY table_name;


-- 2. Verify primary keys and foreign keys
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.constraint_schema = 'analytics'
  AND tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
ORDER BY tc.table_name, tc.constraint_type;


-- 3. Verify analytical views exist
SELECT
    table_name AS view_name
FROM information_schema.views
WHERE table_schema = 'analytics'
ORDER BY table_name;


-- 4. Reconcile order, item and GMV totals
SELECT
    (SELECT COUNT(*)
     FROM analytics.fact_orders) AS fact_orders,

    (SELECT COUNT(DISTINCT order_id)
     FROM analytics.fact_orders) AS unique_orders,

    (SELECT COUNT(*)
     FROM analytics.fact_order_items) AS fact_items,

    (SELECT ROUND(SUM(item_price), 2)
     FROM analytics.fact_order_items) AS item_gmv_brl;


-- 5. Verify executive KPI view
SELECT *
FROM analytics.vw_executive_kpi_summary;
