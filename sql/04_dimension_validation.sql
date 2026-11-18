
-- ============================================================
-- COMMERCEIQ: DIMENSION TABLE VALIDATION
-- ============================================================

-- 1. Check dimension row counts
SELECT 'dim_customers' AS table_name, COUNT(*) AS total_rows
FROM analytics.dim_customers

UNION ALL

SELECT 'dim_products', COUNT(*)
FROM analytics.dim_products

UNION ALL

SELECT 'dim_sellers', COUNT(*)
FROM analytics.dim_sellers;


-- 2. Check duplicate customer IDs
SELECT
    COUNT(*) AS duplicate_customer_ids
FROM (
    SELECT customer_id
    FROM analytics.dim_customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) d;


-- 3. Check duplicate product IDs
SELECT
    COUNT(*) AS duplicate_product_ids
FROM (
    SELECT product_id
    FROM analytics.dim_products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) d;


-- 4. Check duplicate seller IDs
SELECT
    COUNT(*) AS duplicate_seller_ids
FROM (
    SELECT seller_id
    FROM analytics.dim_sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) d;


-- 5. Inspect product categories
SELECT
    product_category_english,
    COUNT(*) AS product_count
FROM analytics.dim_products
GROUP BY product_category_english
ORDER BY product_count DESC
LIMIT 15;


-- 6. Inspect customer locations
SELECT
    customer_state,
    COUNT(*) AS customer_count
FROM analytics.dim_customers
GROUP BY customer_state
ORDER BY customer_count DESC
LIMIT 10;
