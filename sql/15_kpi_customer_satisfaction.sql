
-- =========================================================
-- 15. CUSTOMER SATISFACTION KPI
-- View: analytics.vw_customer_satisfaction
-- Grain: monthly review performance
-- =========================================================

CREATE OR REPLACE VIEW analytics.vw_customer_satisfaction AS

WITH order_review_summary AS (
    SELECT
        order_id,
        COUNT(*) AS review_records,
        AVG(review_score) AS average_order_review_score,
        MIN(review_score) AS minimum_review_score,
        MAX(review_score) AS maximum_review_score
    FROM analytics.fact_reviews
    GROUP BY order_id
),

monthly_reviews AS (
    SELECT
        d.year,
        d.month,
        d.year_month,
        r.review_score,
        o.order_status,
        o.is_late,
        ors.average_order_review_score,
        ors.review_records
    FROM analytics.fact_reviews r
    JOIN analytics.fact_orders o
        ON r.order_id = o.order_id
    JOIN analytics.dim_date d
        ON o.order_purchase_timestamp::date = d.date_key
    JOIN order_review_summary ors
        ON r.order_id = ors.order_id
)

SELECT
    year,
    month,
    year_month,

    COUNT(*) AS total_review_records,

    COUNT(DISTINCT review_score) AS distinct_scores,

    ROUND(AVG(review_score), 2) AS average_review_score,

    COUNT(*) FILTER (
        WHERE review_score >= 4
    ) AS positive_reviews,

    COUNT(*) FILTER (
        WHERE review_score <= 2
    ) AS negative_reviews,

    ROUND(
        COUNT(*) FILTER (WHERE review_score >= 4) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS positive_review_percentage,

    ROUND(
        COUNT(*) FILTER (WHERE review_score <= 2) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS negative_review_percentage

FROM monthly_reviews
GROUP BY year, month, year_month;
