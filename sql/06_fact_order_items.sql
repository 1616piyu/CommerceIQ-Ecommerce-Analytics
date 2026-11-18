
-- ============================================================
-- COMMERCEIQ
-- FACT TABLE 2: FACT_ORDER_ITEMS
-- Grain: One row per order item
-- ============================================================

-- STEP 1: Create fact table

DROP TABLE IF EXISTS analytics.fact_order_items CASCADE;

CREATE TABLE analytics.fact_order_items AS
SELECT
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,

    i.shipping_limit_date,

    -- Product price (BRL)
    i.price AS item_price,

    -- Freight charged (BRL)
    i.freight_value,

    -- Total item amount including freight
    (i.price + i.freight_value) AS item_total_with_freight

FROM staging.order_items i;


-- STEP 2: Add composite primary key

ALTER TABLE analytics.fact_order_items
ADD CONSTRAINT pk_fact_order_items
PRIMARY KEY (order_id, order_item_id);


-- STEP 3: Add foreign keys

ALTER TABLE analytics.fact_order_items
ADD CONSTRAINT fk_items_orders
FOREIGN KEY (order_id)
REFERENCES analytics.fact_orders(order_id);

ALTER TABLE analytics.fact_order_items
ADD CONSTRAINT fk_items_products
FOREIGN KEY (product_id)
REFERENCES analytics.dim_products(product_id);

ALTER TABLE analytics.fact_order_items
ADD CONSTRAINT fk_items_sellers
FOREIGN KEY (seller_id)
REFERENCES analytics.dim_sellers(seller_id);


-- STEP 4: Create indexes

CREATE INDEX idx_fact_items_product
ON analytics.fact_order_items(product_id);

CREATE INDEX idx_fact_items_seller
ON analytics.fact_order_items(seller_id);


-- STEP 5: Validate row count and GMV

SELECT
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT order_id) AS unique_orders,
    SUM(item_price) AS total_gmv_brl,
    SUM(freight_value) AS total_freight_brl,
    SUM(item_total_with_freight) AS total_with_freight_brl
FROM analytics.fact_order_items;


-- STEP 6: Validate price values

SELECT
    COUNT(*) FILTER (WHERE item_price < 0) AS negative_prices,
    COUNT(*) FILTER (WHERE freight_value < 0) AS negative_freight,
    COUNT(*) FILTER (WHERE item_total_with_freight < 0) AS negative_totals
FROM analytics.fact_order_items;


-- STEP 7: Inspect top-selling product categories

SELECT
    p.product_category_english,
    COUNT(*) AS items_sold,
    ROUND(SUM(i.item_price), 2) AS category_gmv_brl
FROM analytics.fact_order_items i
LEFT JOIN analytics.dim_products p
    ON i.product_id = p.product_id
GROUP BY p.product_category_english
ORDER BY category_gmv_brl DESC
LIMIT 10;


-- STEP 8: Inspect sample records

SELECT *
FROM analytics.fact_order_items
LIMIT 10;
