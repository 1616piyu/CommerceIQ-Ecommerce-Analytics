
from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "data" / "raw"

reviews = pd.read_csv(
    RAW_DIR / "olist_order_reviews_dataset.csv",
    low_memory=False
)

print("\nCOMMERCEIQ - REVIEW DUPLICATE INVESTIGATION")
print("=" * 70)

# 1. Exact duplicate rows across all columns
exact_duplicates = reviews.duplicated().sum()

print("\n1. EXACT DUPLICATE ROWS")
print(f"Exact duplicate rows: {exact_duplicates:,}")

# 2. Review IDs appearing more than once
duplicate_ids = reviews[
    reviews.duplicated(subset=["review_id"], keep=False)
].sort_values("review_id")

print("\n2. DUPLICATE REVIEW ID DETAILS")
print(f"Rows with a repeated review_id: {len(duplicate_ids):,}")
print(
    "Number of review IDs repeated:",
    duplicate_ids["review_id"].nunique()
)

print("\nFirst 15 duplicate review records:")
print(
    duplicate_ids[
        [
            "review_id",
            "order_id",
            "review_score",
            "review_comment_title",
            "review_comment_message"
        ]
    ].head(15).to_string(index=False)
)

# 3. Do duplicate review IDs belong to different orders?
orders_per_review = (
    duplicate_ids.groupby("review_id")["order_id"].nunique()
)

print("\n3. REVIEW IDs ASSOCIATED WITH MULTIPLE ORDERS")
print(
    "Repeated review IDs linked to multiple orders:",
    (orders_per_review > 1).sum()
)

# 4. Orders with multiple review records
reviews_per_order = reviews.groupby("order_id").agg(
    review_rows=("review_id", "size"),
    distinct_review_ids=("review_id", "nunique")
)

multiple_reviews = reviews_per_order[
    reviews_per_order["review_rows"] > 1
].sort_values("review_rows", ascending=False)

print("\n4. ORDERS WITH MULTIPLE REVIEW RECORDS")
print(f"Orders with multiple review rows: {len(multiple_reviews):,}")

print("\nFirst 15 examples:")
print(multiple_reviews.head(15).to_string())

# 5. Inspect one example with repeated review ID
if not duplicate_ids.empty:
    example_id = duplicate_ids["review_id"].iloc[0]

    print("\n5. FULL DETAILS FOR ONE REPEATED REVIEW ID")
    print(f"Review ID: {example_id}")

    print(
        reviews[reviews["review_id"] == example_id]
        .to_string(index=False)
    )

orders = pd.read_csv(
    RAW_DIR / "olist_orders_dataset.csv",
    low_memory=False
)

missing_delivery = orders[
    (orders["order_status"] == "delivered")
    & (orders["order_delivered_customer_date"].isna())
]

print("\nDELIVERED ORDERS WITH MISSING DELIVERY TIMESTAMPS")
print(f"Count: {len(missing_delivery)}")

print(
    missing_delivery[
        [
            "order_id",
            "order_status",
            "order_purchase_timestamp",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date"
        ]
    ].to_string(index=False)
)


print("\nInvestigation completed.")
