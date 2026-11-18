
# CommerceIQ – Database Design

## Architecture
Raw CSV -> Staging -> Analytics -> Power BI

## Fact tables

### fact_orders
Grain: One row per order.
Primary key: order_id

Measures / attributes:
- order_status
- order_purchase_timestamp
- order_approved_at
- order_delivered_carrier_date
- order_delivered_customer_date
- order_estimated_delivery_date
- customer_id
- missing_actual_delivery_flag

### fact_order_items
Grain: One row per order item.
Composite primary key: order_id, order_item_id

Measures:
- price
- freight_value

Foreign keys:
- order_id
- product_id
- seller_id

### fact_payments
Grain: One row per payment sequence.
Composite primary key: order_id, payment_sequential

Measures:
- payment_value
- payment_installments

Attributes:
- payment_type

### fact_reviews
Grain: One row per source review record.
Primary key: review_record_id

Attributes:
- review_id
- order_id
- review_score
- review_comment_title
- review_comment_message
- review_creation_date
- review_answer_timestamp

## Dimension tables

### dim_customers
Primary key: customer_id
Business customer identifier: customer_unique_id

Attributes:
- customer_zip_code_prefix
- customer_city
- customer_state

### dim_products
Primary key: product_id

Attributes:
- product_category_name
- product_category_name_english
- product dimensions and weight

### dim_sellers
Primary key: seller_id

Attributes:
- seller_zip_code_prefix
- seller_city
- seller_state

### dim_date
Primary key: date_key

Attributes:
- calendar_date
- year
- quarter
- month
- month_name
- day
- weekday

## Important analytical rules

1. GMV = SUM(fact_order_items.price).
2. Freight = SUM(fact_order_items.freight_value).
3. Payment total = SUM(fact_payments.payment_value).
4. Never directly join raw order items and payments before aggregation.
5. Repeat customers are identified using customer_unique_id.
6. Delivery performance excludes orders without an actual delivery timestamp.
7. Reviews retain all source records using review_record_id.
8. GMV must not be described as profit or net revenue.
