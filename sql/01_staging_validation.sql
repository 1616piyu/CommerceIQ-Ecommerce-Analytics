
-- ============================================================
-- COMMERCEIQ: STAGING DATABASE VALIDATION
-- ============================================================

-- 1. Confirm all staging tables exist
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'staging'
ORDER BY table_name;


-- 2. Validate row counts
SELECT 'orders' AS table_name, COUNT(*) AS total_rows FROM staging.orders
UNION ALL
SELECT 'customers', COUNT(*) FROM staging.customers
UNION ALL
SELECT 'order_items', COUNT(*) FROM staging.order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM staging.order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM staging.order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM staging.products
UNION ALL
SELECT 'sellers', COUNT(*) FROM staging.sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM staging.geolocation
UNION ALL
SELECT 'category_translation', COUNT(*) FROM staging.category_translation
ORDER BY table_name;


-- 3. Check duplicate primary/business keys
SELECT 'orders.order_id' AS key_name, COUNT(*) AS duplicate_count
FROM (
    SELECT order_id
    FROM staging.orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'customers.customer_id', COUNT(*)
FROM (
    SELECT customer_id
    FROM staging.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'products.product_id', COUNT(*)
FROM (
    SELECT product_id
    FROM staging.products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'sellers.seller_id', COUNT(*)
FROM (
    SELECT seller_id
    FROM staging.sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'order_items.order_id + order_item_id', COUNT(*)
FROM (
    SELECT order_id, order_item_id
    FROM staging.order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'order_payments.order_id + payment_sequential', COUNT(*)
FROM (
    SELECT order_id, payment_sequential
    FROM staging.order_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'order_reviews.review_record_id', COUNT(*)
FROM (
    SELECT review_record_id
    FROM staging.order_reviews
    GROUP BY review_record_id
    HAVING COUNT(*) > 1
) d;


-- 4. Check orphan relationships
-- Orders without matching customers
SELECT COUNT(*) AS orders_without_customer
FROM staging.orders o
LEFT JOIN staging.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Order items without matching orders
SELECT COUNT(*) AS items_without_order
FROM staging.order_items i
LEFT JOIN staging.orders o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order items without matching products
SELECT COUNT(*) AS items_without_product
FROM staging.order_items i
LEFT JOIN staging.products p
    ON i.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Order items without matching sellers
SELECT COUNT(*) AS items_without_seller
FROM staging.order_items i
LEFT JOIN staging.sellers s
    ON i.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- Payments without matching orders
SELECT COUNT(*) AS payments_without_order
FROM staging.order_payments p
LEFT JOIN staging.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Reviews without matching orders
SELECT COUNT(*) AS reviews_without_order
FROM staging.order_reviews r
LEFT JOIN staging.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 5. Check critical NULL values
SELECT
    'orders.order_id' AS column_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_count
FROM staging.orders

UNION ALL

SELECT
    'customers.customer_id',
    COUNT(*) FILTER (WHERE customer_id IS NULL)
FROM staging.customers

UNION ALL

SELECT
    'order_items.order_id',
    COUNT(*) FILTER (WHERE order_id IS NULL)
FROM staging.order_items

UNION ALL

SELECT
    'order_items.product_id',
    COUNT(*) FILTER (WHERE product_id IS NULL)
FROM staging.order_items

UNION ALL

SELECT
    'order_reviews.review_record_id',
    COUNT(*) FILTER (WHERE review_record_id IS NULL)
FROM staging.order_reviews;


-- 6. Check invalid numeric values
SELECT
    COUNT(*) FILTER (WHERE price < 0) AS negative_item_prices,
    COUNT(*) FILTER (WHERE freight_value < 0) AS negative_freight_values
FROM staging.order_items;

SELECT
    COUNT(*) FILTER (WHERE payment_value < 0) AS negative_payment_values,
    COUNT(*) FILTER (WHERE payment_installments < 0) AS negative_installments
FROM staging.order_payments;

SELECT
    COUNT(*) FILTER (
        WHERE review_score NOT BETWEEN 1 AND 5
    ) AS invalid_review_scores
FROM staging.order_reviews;


-- 7. Review delivery data quality
SELECT
    order_status,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_actual_delivery
FROM staging.orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- 8. Check repeat customer identifiers
SELECT
    COUNT(*) AS customer_rows,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM staging.customers;
