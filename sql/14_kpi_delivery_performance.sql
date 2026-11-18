
-- ============================================================
-- COMMERCEIQ: DELIVERY PERFORMANCE
-- Grain: One row per month of purchase
-- Only delivered orders with both actual and estimated
-- delivery timestamps are eligible for on-time calculations.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delivery_performance AS

SELECT
    d.year,
    d.month,
    d.year_month,

    COUNT(*) AS eligible_delivery_orders,

    COUNT(*) FILTER (
        WHERE o.is_late = FALSE
    ) AS on_time_deliveries,

    COUNT(*) FILTER (
        WHERE o.is_late = TRUE
    ) AS late_deliveries,

    ROUND(
        COUNT(*) FILTER (
            WHERE o.is_late = FALSE
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_rate,

    ROUND(
        AVG(o.delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(
            CASE
                WHEN o.is_late = TRUE
                THEN EXTRACT(
                    EPOCH FROM (
                        o.order_delivered_customer_date
                        - o.order_estimated_delivery_date
                    )
                ) / 86400.0
            END
        ),
        2
    ) AS average_late_days

FROM analytics.fact_orders o

JOIN analytics.dim_date d
    ON o.order_purchase_timestamp::date = d.date_key

WHERE o.is_delivery_performance_eligible = TRUE

GROUP BY
    d.year,
    d.month,
    d.year_month;


-- ============================================================
-- VALIDATION 1: Monthly delivery performance
-- ============================================================

SELECT *
FROM analytics.vw_delivery_performance
ORDER BY year, month;


-- ============================================================
-- VALIDATION 2: Overall delivery performance
-- ============================================================

SELECT
    SUM(eligible_delivery_orders) AS eligible_orders,

    SUM(on_time_deliveries) AS on_time_deliveries,

    SUM(late_deliveries) AS late_deliveries,

    ROUND(
        SUM(on_time_deliveries) * 100.0
        / NULLIF(SUM(eligible_delivery_orders), 0),
        2
    ) AS overall_on_time_rate

FROM analytics.vw_delivery_performance;


-- ============================================================
-- VALIDATION 3: Reconcile with fact_orders
-- ============================================================

SELECT
    COUNT(*) AS eligible_orders,

    COUNT(*) FILTER (
        WHERE is_late = FALSE
    ) AS on_time_deliveries,

    COUNT(*) FILTER (
        WHERE is_late = TRUE
    ) AS late_deliveries

FROM analytics.fact_orders

WHERE is_delivery_performance_eligible = TRUE;
