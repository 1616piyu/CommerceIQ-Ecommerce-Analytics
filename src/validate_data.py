
from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "data" / "raw"


def load_csv(filename):
    path = RAW_DIR / filename
    if not path.exists():
        raise FileNotFoundError(f"Missing dataset: {path}")
    return pd.read_csv(path, low_memory=False)


def check_unique(df, columns, table_name):
    duplicates = df.duplicated(subset=columns).sum()
    print(
        f"{table_name:<20} | "
        f"Key: {columns} | "
        f"Duplicate rows: {duplicates:,}"
    )


def check_foreign_key(child, child_col, parent, parent_col, label):
    child_values = set(child[child_col].dropna().unique())
    parent_values = set(parent[parent_col].dropna().unique())

    missing = child_values - parent_values

    print(
        f"{label:<35} | "
        f"Unmatched values: {len(missing):,}"
    )


def main():
    print("\nCOMMERCEIQ - DATA QUALITY VALIDATION")
    print("=" * 75)

    orders = load_csv("olist_orders_dataset.csv")
    customers = load_csv("olist_customers_dataset.csv")
    items = load_csv("olist_order_items_dataset.csv")
    payments = load_csv("olist_order_payments_dataset.csv")
    reviews = load_csv("olist_order_reviews_dataset.csv")
    products = load_csv("olist_products_dataset.csv")
    sellers = load_csv("olist_sellers_dataset.csv")
    translations = load_csv("product_category_name_translation.csv")

    # --------------------------------------------------
    # 1. Primary and composite key checks
    # --------------------------------------------------
    print("\n1. DUPLICATE KEY CHECKS")
    print("-" * 75)

    check_unique(orders, ["order_id"], "Orders")
    check_unique(customers, ["customer_id"], "Customers")
    check_unique(items, ["order_id", "order_item_id"], "Order items")
    check_unique(payments, ["order_id", "payment_sequential"], "Payments")
    check_unique(reviews, ["review_id"], "Reviews")
    check_unique(products, ["product_id"], "Products")
    check_unique(sellers, ["seller_id"], "Sellers")
    check_unique(
        translations,
        ["product_category_name"],
        "Category translations"
    )

    print("\n2. FOREIGN KEY / RELATIONSHIP CHECKS")
    print("-" * 75)

    check_foreign_key(
        orders, "customer_id",
        customers, "customer_id",
        "Orders -> Customers"
    )

    check_foreign_key(
        items, "order_id",
        orders, "order_id",
        "Order items -> Orders"
    )

    check_foreign_key(
        items, "product_id",
        products, "product_id",
        "Order items -> Products"
    )

    check_foreign_key(
        items, "seller_id",
        sellers, "seller_id",
        "Order items -> Sellers"
    )

    check_foreign_key(
        payments, "order_id",
        orders, "order_id",
        "Payments -> Orders"
    )

    check_foreign_key(
        reviews, "order_id",
        orders, "order_id",
        "Reviews -> Orders"
    )

    # --------------------------------------------------
    # 3. Order status distribution
    # --------------------------------------------------
    print("\n3. ORDER STATUS DISTRIBUTION")
    print("-" * 75)

    print(orders["order_status"].value_counts(dropna=False).to_string())

    # --------------------------------------------------
    # 4. Date validation
    # --------------------------------------------------
    print("\n4. ORDER DATE VALIDATION")
    print("-" * 75)

    date_columns = [
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date"
    ]

    for column in date_columns:
        orders[column] = pd.to_datetime(
            orders[column],
            errors="coerce"
        )

    print(
        "Invalid purchase timestamps:",
        orders["order_purchase_timestamp"].isna().sum()
    )

    print(
        "Delivery before purchase:",
        (
            orders["order_delivered_customer_date"]
            < orders["order_purchase_timestamp"]
        ).sum()
    )

    print(
        "Approval before purchase:",
        (
            orders["order_approved_at"]
            < orders["order_purchase_timestamp"]
        ).sum()
    )

    print(
        "Delivered orders with missing delivery timestamp:",
        (
            (orders["order_status"] == "delivered")
            & orders["order_delivered_customer_date"].isna()
        ).sum()
    )

    # --------------------------------------------------
    # 5. Numeric value validation
    # --------------------------------------------------
    print("\n5. NUMERIC VALUE VALIDATION")
    print("-" * 75)

    numeric_checks = {
        "Order item price": items["price"],
        "Freight value": items["freight_value"],
        "Payment value": payments["payment_value"],
        "Review score": reviews["review_score"],
        "Payment installments": payments["payment_installments"]
    }

    for label, series in numeric_checks.items():
        print(
            f"{label:<25} | "
            f"Negative: {(series < 0).sum():,} | "
            f"Missing: {series.isna().sum():,}"
        )

    print(
        "Review scores outside 1-5:",
        (~reviews["review_score"].between(1, 5)).sum()
    )

    # --------------------------------------------------
    # 6. Order-level multiplicity
    # --------------------------------------------------
    print("\n6. MULTIPLE ROWS PER ORDER")
    print("-" * 75)

    item_counts = items.groupby("order_id").size()
    payment_counts = payments.groupby("order_id").size()
    review_counts = reviews.groupby("order_id").size()

    print(
        "Orders with multiple item rows:",
        (item_counts > 1).sum()
    )

    print(
        "Orders with multiple payment rows:",
        (payment_counts > 1).sum()
    )

    print(
        "Orders with multiple review rows:",
        (review_counts > 1).sum()
    )

    print("\n7. SUMMARY")
    print("-" * 75)
    print(f"Orders:       {len(orders):,}")
    print(f"Customers:    {len(customers):,}")
    print(f"Order items:  {len(items):,}")
    print(f"Payments:     {len(payments):,}")
    print(f"Reviews:      {len(reviews):,}")
    print(f"Products:     {len(products):,}")
    print(f"Sellers:      {len(sellers):,}")

    print("\nValidation checks completed.")
    print("Review the results before making any cleaning decisions.")


if __name__ == "__main__":
    main()
