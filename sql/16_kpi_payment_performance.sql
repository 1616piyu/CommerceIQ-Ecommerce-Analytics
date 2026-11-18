
-- =========================================================
-- 16. PAYMENT PERFORMANCE KPI
-- View: analytics.vw_payment_performance
-- Grain: payment type
-- =========================================================

CREATE OR REPLACE VIEW analytics.vw_payment_performance AS

SELECT
    payment_type,

    COUNT(*) AS total_payment_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    ROUND(SUM(payment_value), 2) AS total_payment_value_brl,

    ROUND(AVG(payment_value), 2) AS average_payment_value_brl,

    ROUND(
        COUNT(*) * 100.0
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS payment_record_percentage,

    ROUND(
        SUM(payment_value) * 100.0
        / NULLIF(SUM(SUM(payment_value)) OVER (), 0),
        2
    ) AS payment_value_percentage

FROM analytics.fact_payments
GROUP BY payment_type;
