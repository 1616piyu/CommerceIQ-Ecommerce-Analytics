
-- ============================================================
-- COMMERCEIQ
-- ANALYTICAL DATABASE - INITIAL STRUCTURE
-- ============================================================

CREATE SCHEMA IF NOT EXISTS analytics;

-- Confirm schemas
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('staging', 'analytics')
ORDER BY schema_name;


-- ============================================================
-- STEP 1: CUSTOMER DIMENSION
-- Grain: One row per customer_id
-- ============================================================

DROP TABLE IF EXISTS analytics.dim_customers CASCADE;

CREATE TABLE analytics.dim_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.customers;


-- ============================================================
-- STEP 2: PRODUCT DIMENSION
-- Grain: One row per product_id
-- ============================================================

DROP TABLE IF EXISTS analytics.dim_products CASCADE;

CREATE TABLE analytics.dim_products AS
SELECT
    p.product_id,
    p.product_category_name,

    COALESCE(
        t.product_category_name_english,
        'Unknown'
    ) AS product_category_english,

    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm

FROM staging.products p
LEFT JOIN staging.category_translation t
    ON p.product_category_name = t.product_category_name;


-- ============================================================
-- STEP 3: SELLER DIMENSION
-- Grain: One row per seller_id
-- ============================================================

DROP TABLE IF EXISTS analytics.dim_sellers CASCADE;

CREATE TABLE analytics.dim_sellers AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.sellers;


-- ============================================================
-- STEP 4: VERIFY DIMENSION ROW COUNTS
-- ============================================================

SELECT
    'dim_customers' AS table_name,
    COUNT(*) AS total_rows
FROM analytics.dim_customers

UNION ALL

SELECT
    'dim_products',
    COUNT(*)
FROM analytics.dim_products

UNION ALL

SELECT
    'dim_sellers',
    COUNT(*)
FROM analytics.dim_sellers

ORDER BY table_name;
