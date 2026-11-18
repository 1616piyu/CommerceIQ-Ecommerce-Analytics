
-- ============================================================
-- COMMERCEIQ: FACT PAYMENTS
-- Grain: One row per order_id + payment_sequential
-- ============================================================

DROP TABLE IF EXISTS analytics.fact_payments;

CREATE TABLE analytics.fact_payments AS
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    ROUND(payment_value::numeric, 2) AS payment_value
FROM staging.order_payments;

-- Primary key
ALTER TABLE analytics.fact_payments
ADD CONSTRAINT pk_fact_payments
PRIMARY KEY (order_id, payment_sequential);

-- Foreign key
ALTER TABLE analytics.fact_payments
ADD CONSTRAINT fk_payments_orders
FOREIGN KEY (order_id)
REFERENCES analytics.fact_orders(order_id);

-- Index
CREATE INDEX idx_fact_payments_order
ON analytics.fact_payments(order_id);

-- ============================================================
-- VALIDATION 1: Row count and payment value
-- ============================================================

SELECT
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    SUM(payment_value) AS total_payment_value_brl
FROM analytics.fact_payments;

-- ============================================================
-- VALIDATION 2: Payment types
-- ============================================================

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value), 2) AS payment_value_brl
FROM analytics.fact_payments
GROUP BY payment_type
ORDER BY payment_value_brl DESC;

-- ============================================================
-- VALIDATION 3: Duplicate payment keys
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, payment_sequential))
        AS unique_payment_keys
FROM analytics.fact_payments;

-- ============================================================
-- VALIDATION 4: Orphan orders
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE o.order_id IS NULL
    ) AS missing_orders
FROM analytics.fact_payments p
LEFT JOIN analytics.fact_orders o
    ON p.order_id = o.order_id;
