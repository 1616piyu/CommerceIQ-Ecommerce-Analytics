
-- ============================================================
-- COMMERCEIQ
-- FACT TABLE 1: FACT_ORDERS
-- Grain: One row per order
-- ============================================================

-- STEP 1: Recreate fact_orders

DROP TABLE IF EXISTS analytics.fact_orders CASCADE;

CREATE TABLE analytics.fact_orders AS

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- Delivery duration in days
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        o.order_delivered_customer_date
                        - o.order_purchase_timestamp
                    )
                ) / 86400.0
            )::numeric,
            2
        )
        ELSE NULL
    END AS delivery_days,

    -- Delivered order flag
    (o.order_status = 'delivered') AS is_delivered,

    -- Actual delivery timestamp availability
    (o.order_delivered_customer_date IS NOT NULL)
        AS has_actual_delivery_date,

    -- Valid delivery performance record
    (
        o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
    ) AS is_delivery_performance_eligible,

    -- Late delivery flag
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN (
            o.order_delivered_customer_date
            > o.order_estimated_delivery_date
        )
        ELSE NULL
    END AS is_late

FROM staging.orders o;


-- STEP 2: Add primary key
ALTER TABLE analytics.fact_orders
ADD CONSTRAINT pk_fact_orders
PRIMARY KEY (order_id);


-- STEP 3: Add customer relationship
ALTER TABLE analytics.fact_orders
ADD CONSTRAINT fk_fact_orders_customers
FOREIGN KEY (customer_id)
REFERENCES analytics.dim_customers(customer_id);


-- STEP 4: Create useful indexes
CREATE INDEX idx_fact_orders_customer_id
ON analytics.fact_orders(customer_id);

CREATE INDEX idx_fact_orders_purchase_timestamp
ON analytics.fact_orders(order_purchase_timestamp);

CREATE INDEX idx_fact_orders_status
ON analytics.fact_orders(order_status);


-- STEP 5: Verify total records
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders
FROM analytics.fact_orders;


-- STEP 6: Verify order status distribution
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM analytics.fact_orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- STEP 7: Verify delivery eligibility
SELECT
    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE is_delivery_performance_eligible = TRUE
    ) AS eligible_delivery_records,

    COUNT(*) FILTER (
        WHERE is_late = TRUE
    ) AS late_deliveries,

    COUNT(*) FILTER (
        WHERE is_late = FALSE
    ) AS on_time_deliveries

FROM analytics.fact_orders
WHERE order_status = 'delivered';


-- STEP 8: Inspect sample records
SELECT *
FROM analytics.fact_orders
ORDER BY order_purchase_timestamp
LIMIT 10;
