
from pathlib import Path
import pandas as pd

from sqlalchemy import text

from database import engine


# --------------------------------------------------
# PROJECT CONFIGURATION
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent
PROCESSED_DIR = BASE_DIR / "data" / "processed"

SCHEMA = "staging"

READ_CHUNK_SIZE = 25_000
WRITE_CHUNK_SIZE = 5_000


# --------------------------------------------------
# DATASET MAPPING
# --------------------------------------------------

DATASETS = {
    "olist_orders_dataset_cleaned.csv": {
        "table": "orders",
        "strings": [
            "order_id", "customer_id", "order_status"
        ],
        "dates": [
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date"
        ]
    },

    "olist_customers_dataset_cleaned.csv": {
        "table": "customers",
        "strings": [
            "customer_id",
            "customer_unique_id",
            "customer_zip_code_prefix",
            "customer_city",
            "customer_state"
        ]
    },

    "olist_order_items_dataset_cleaned.csv": {
        "table": "order_items",
        "strings": [
            "order_id", "product_id", "seller_id"
        ],
        "dates": ["shipping_limit_date"]
    },

    "olist_order_payments_dataset_cleaned.csv": {
        "table": "order_payments",
        "strings": ["order_id", "payment_type"]
    },

    "olist_order_reviews_dataset_cleaned.csv": {
        "table": "order_reviews",
        "strings": [
            "review_record_id",
            "review_id",
            "order_id",
            "review_comment_title",
            "review_comment_message"
        ],
        "dates": [
            "review_creation_date",
            "review_answer_timestamp"
        ]
    },

    "olist_products_dataset_cleaned.csv": {
        "table": "products",
        "strings": ["product_id", "product_category_name"]
    },

    "olist_sellers_dataset_cleaned.csv": {
        "table": "sellers",
        "strings": [
            "seller_id",
            "seller_zip_code_prefix",
            "seller_city",
            "seller_state"
        ]
    },

    "olist_geolocation_dataset_cleaned.csv": {
        "table": "geolocation",
        "strings": [
            "geolocation_zip_code_prefix",
            "geolocation_city",
            "geolocation_state"
        ]
    },

    "product_category_name_translation_cleaned.csv": {
        "table": "category_translation",
        "strings": [
            "product_category_name",
            "product_category_name_english"
        ]
    }
}


# --------------------------------------------------
# LOAD ONE DATASET
# --------------------------------------------------

def load_dataset(filename, config):

    file_path = PROCESSED_DIR / filename

    if not file_path.exists():
        raise FileNotFoundError(
            f"Processed file not found: {file_path}"
        )

    table_name = config["table"]

    print("\n" + "=" * 65)
    print(f"LOADING: {filename}")
    print(f"TARGET: {SCHEMA}.{table_name}")
    print("=" * 65)

    dtype_config = {
        column: "string"
        for column in config.get("strings", [])
    }

    total_loaded = 0
    first_chunk = True

    for chunk in pd.read_csv(
        file_path,
        chunksize=READ_CHUNK_SIZE,
        low_memory=False,
        dtype=dtype_config
    ):

        # Convert date columns
        for column in config.get("dates", []):
            chunk[column] = pd.to_datetime(
                chunk[column],
                errors="coerce"
            )

        # Convert pandas nullable booleans if present
        if "missing_actual_delivery_flag" in chunk.columns:
            chunk["missing_actual_delivery_flag"] = (
                chunk["missing_actual_delivery_flag"].astype("boolean")
            )

        # Load chunk into PostgreSQL
        chunk.to_sql(
            name=table_name,
            con=engine,
            schema=SCHEMA,
            if_exists="replace" if first_chunk else "append",
            index=False,
            chunksize=WRITE_CHUNK_SIZE,
            method=None
        )

        total_loaded += len(chunk)
        first_chunk = False

        print(f"Rows loaded: {total_loaded:,}", end="\r")

    print(f"\nCompleted: {total_loaded:,} rows")

    return total_loaded


# --------------------------------------------------
# VERIFY DATABASE ROW COUNTS
# --------------------------------------------------

def verify_database_counts(expected_counts):

    print("\n" + "=" * 75)
    print("POSTGRESQL ROW COUNT VALIDATION")
    print("=" * 75)

    results = []

    with engine.connect() as connection:

        for table_name, expected in expected_counts.items():

            query = text(
                f'SELECT COUNT(*) FROM "{SCHEMA}"."{table_name}"'
            )

            actual = connection.execute(query).scalar_one()

            status = "PASS" if actual == expected else "FAIL"

            results.append({
                "table": table_name,
                "expected": expected,
                "actual": actual,
                "status": status
            })

            print(
                f"{table_name:<25} "
                f"Expected: {expected:>10,} | "
                f"Actual: {actual:>10,} | "
                f"{status}"
            )

    return results


# --------------------------------------------------
# MAIN PIPELINE
# --------------------------------------------------

def main():

    print("\nCOMMERCEIQ - POSTGRESQL DATA LOADER")
    print("=" * 75)

    # Ensure staging schema exists
    with engine.begin() as connection:
        connection.execute(
            text("CREATE SCHEMA IF NOT EXISTS staging")
        )

    expected_counts = {}

    for filename, config in DATASETS.items():

        loaded = load_dataset(filename, config)

        expected_counts[config["table"]] = loaded

    results = verify_database_counts(expected_counts)

    failures = [
        result for result in results
        if result["status"] != "PASS"
    ]

    print("\n" + "=" * 75)

    if failures:
        print("DATA LOADING COMPLETED WITH VALIDATION FAILURES")
        raise RuntimeError(
            f"{len(failures)} PostgreSQL table(s) failed validation."
        )

    print("ALL DATASETS LOADED AND VALIDATED SUCCESSFULLY")

    print("\nTotal tables:", len(results))
    print(
        "Total rows:",
        f"{sum(item['actual'] for item in results):,}"
    )

    print(f"\nPostgreSQL schema: {SCHEMA}")


if __name__ == "__main__":
    main()
