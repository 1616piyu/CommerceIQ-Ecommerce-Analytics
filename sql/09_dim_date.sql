
-- ============================================================
-- COMMERCEIQ: DATE DIMENSION
-- Calendar range: 2016-01-01 to 2018-12-31
-- ============================================================

DROP TABLE IF EXISTS analytics.dim_date;

CREATE TABLE analytics.dim_date AS
SELECT
    d::date AS date_key,
    EXTRACT(YEAR FROM d)::int AS year,
    EXTRACT(QUARTER FROM d)::int AS quarter,
    EXTRACT(MONTH FROM d)::int AS month,
    TO_CHAR(d, 'Month') AS month_name,
    TO_CHAR(d, 'YYYY-MM') AS year_month,
    EXTRACT(WEEK FROM d)::int AS week_of_year,
    EXTRACT(DAY FROM d)::int AS day_of_month,
    EXTRACT(DOW FROM d)::int AS day_of_week,
    TO_CHAR(d, 'Day') AS day_name,
    CASE
        WHEN EXTRACT(ISODOW FROM d) IN (6, 7)
        THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM GENERATE_SERIES(
    DATE '2016-01-01',
    DATE '2018-12-31',
    INTERVAL '1 day'
) AS series(d);

-- Primary key
ALTER TABLE analytics.dim_date
ADD CONSTRAINT pk_dim_date
PRIMARY KEY (date_key);

-- ============================================================
-- VALIDATION 1: Date coverage
-- ============================================================

SELECT
    COUNT(*) AS total_dates,
    MIN(date_key) AS first_date,
    MAX(date_key) AS last_date
FROM analytics.dim_date;

-- ============================================================
-- VALIDATION 2: Calendar breakdown
-- ============================================================

SELECT
    year,
    COUNT(*) AS calendar_days,
    SUM(CASE WHEN is_weekend THEN 1 ELSE 0 END) AS weekend_days
FROM analytics.dim_date
GROUP BY year
ORDER BY year;

-- ============================================================
-- VALIDATION 3: Check duplicate dates
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT date_key) AS unique_dates
FROM analytics.dim_date;
