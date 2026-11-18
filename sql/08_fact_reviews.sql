
-- ============================================================
-- COMMERCEIQ: FACT REVIEWS
-- Grain: One row per review_record_id
-- ============================================================

DROP TABLE IF EXISTS analytics.fact_reviews;

CREATE TABLE analytics.fact_reviews AS
SELECT
    review_record_id,
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM staging.order_reviews;

-- Primary key
ALTER TABLE analytics.fact_reviews
ADD CONSTRAINT pk_fact_reviews
PRIMARY KEY (review_record_id);

-- Foreign key
ALTER TABLE analytics.fact_reviews
ADD CONSTRAINT fk_reviews_orders
FOREIGN KEY (order_id)
REFERENCES analytics.fact_orders(order_id);

-- Index
CREATE INDEX idx_fact_reviews_order
ON analytics.fact_reviews(order_id);

-- ============================================================
-- VALIDATION 1: Total review records
-- ============================================================

SELECT
    COUNT(*) AS total_reviews,
    COUNT(DISTINCT review_record_id) AS unique_review_records,
    COUNT(DISTINCT order_id) AS reviewed_orders,
    ROUND(AVG(review_score), 2) AS average_review_score
FROM analytics.fact_reviews;

-- ============================================================
-- VALIDATION 2: Review score distribution
-- ============================================================

SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM analytics.fact_reviews
GROUP BY review_score
ORDER BY review_score;

-- ============================================================
-- VALIDATION 3: Duplicate review record keys
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_record_id) AS unique_review_keys
FROM analytics.fact_reviews;

-- ============================================================
-- VALIDATION 4: Missing order relationships
-- ============================================================

SELECT
    COUNT(*) FILTER (
        WHERE o.order_id IS NULL
    ) AS missing_orders
FROM analytics.fact_reviews r
LEFT JOIN analytics.fact_orders o
    ON r.order_id = o.order_id;
