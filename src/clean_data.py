
from pathlib import Path
from collections import Counter
import json
import pandas as pd

# --------------------------------------------------
# 1. PROJECT PATHS
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "data" / "raw"
PROCESSED_DIR = BASE_DIR / "data" / "processed"
REPORT_DIR = BASE_DIR / "reports"

PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
REPORT_DIR.mkdir(parents=True, exist_ok=True)

CHUNK_SIZE = 100_000

# --------------------------------------------------
# 2. DATASET CONFIGURATION
# --------------------------------------------------

DATASETS = {
    "olist_orders_dataset.csv": {
        "dates": [
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date"
        ],
        "numeric": [],
        "string": ["order_id", "customer_id"]
    },

    "olist_customers_dataset.csv": {
        "dates": [],
        "numeric": [],
        "string": [
            "customer_id",
            "customer_unique_id",
            "customer_zip_code_prefix"
        ]
    },

    "olist_order_items_dataset.csv": {
        "dates": ["shipping_limit_date"],
        "numeric": [
            "order_item_id",
            "price",
            "freight_value"
        ],
        "string": [
            "order_id",
            "product_id",
            "seller_id"
        ]
    },

    "olist_order_payments_dataset.csv": {
        "dates": [],
        "numeric": [
            "payment_sequential",
            "payment_installments",
            "payment_value"
        ],
        "string": ["order_id"]
    },

    "olist_order_reviews_dataset.csv": {
        "dates": [
            "review_creation_date",
            "review_answer_timestamp"
        ],
        "numeric": ["review_score"],
        "string": ["review_id", "order_id"]
    },

    "olist_products_dataset.csv": {
        "dates": [],
        "numeric": [
            "product_name_lenght",
            "product_description_lenght",
            "product_photos_qty",
            "product_weight_g",
            "product_length_cm",
            "product_height_cm",
            "product_width_cm"
        ],
        "string": ["product_id"]
    },

    "olist_sellers_dataset.csv": {
        "dates": [],
        "numeric": [],
        "string": [
            "seller_id",
            "seller_zip_code_prefix"
        ]
    },

    "olist_geolocation_dataset.csv": {
        "dates": [],
        "numeric": [
            "geolocation_lat",
            "geolocation_lng"
        ],
        "string": ["geolocation_zip_code_prefix"]
    },

    "product_category_name_translation.csv": {
        "dates": [],
        "numeric": [],
        "string": []
    }
}


# --------------------------------------------------
# 3. CLEAN ONE DATASET IN CHUNKS
# --------------------------------------------------

def clean_dataset(filename, config):

    source_path = RAW_DIR / filename
    output_path = PROCESSED_DIR / filename.replace(
        ".csv", "_cleaned.csv"
    )

    if not source_path.exists():
        raise FileNotFoundError(
            f"Dataset not found: {source_path}"
        )

    # Remove previous output so reruns don't append duplicates.
    if output_path.exists():
        output_path.unlink()

    print(f"\nProcessing: {filename}")

    total_rows = 0
    review_counter = 0

    null_counts = Counter()
    invalid_dates = Counter()
    invalid_numeric = Counter()

    first_chunk = True

    # Preserve identifiers and postal codes as strings.
    dtype_config = {
        column: "string"
        for column in config["string"]
    }

    for chunk in pd.read_csv(
        source_path,
        chunksize=CHUNK_SIZE,
        low_memory=False,
        dtype=dtype_config
    ):

        original_rows = len(chunk)
        total_rows += original_rows

        # ------------------------------------------
        # A. Normalize order status
        # ------------------------------------------

        if "order_status" in chunk.columns:
            chunk["order_status"] = (
                chunk["order_status"]
                .str.strip()
                .str.lower()
            )

        # ------------------------------------------
        # B. Convert date columns
        # ------------------------------------------

        for column in config["dates"]:

            original_non_null = chunk[column].notna().sum()

            converted = pd.to_datetime(
                chunk[column],
                errors="coerce"
            )

            invalid_count = (
                original_non_null - converted.notna().sum()
            )

            invalid_dates[column] += int(invalid_count)
            chunk[column] = converted

        # ------------------------------------------
        # C. Convert numeric columns
        # ------------------------------------------

        for column in config["numeric"]:

            original_non_null = chunk[column].notna().sum()

            converted = pd.to_numeric(
                chunk[column],
                errors="coerce"
            )

            invalid_count = (
                original_non_null - converted.notna().sum()
            )

            invalid_numeric[column] += int(invalid_count)
            chunk[column] = converted

        # ------------------------------------------
        # D. Generate unique review row IDs
        # ------------------------------------------

        if filename == "olist_order_reviews_dataset.csv":

            review_ids = range(
                review_counter + 1,
                review_counter + len(chunk) + 1
            )

            chunk.insert(
                0,
                "review_record_id",
                [
                    f"REV{number:09d}"
                    for number in review_ids
                ]
            )

            review_counter += len(chunk)

        # ------------------------------------------
        # E. Flag missing delivery timestamps
        # ------------------------------------------

        if filename == "olist_orders_dataset.csv":

            chunk["missing_actual_delivery_flag"] = (
                (chunk["order_status"] == "delivered")
                & chunk[
                    "order_delivered_customer_date"
                ].isna()
            )

        # ------------------------------------------
        # F. Track missing values
        # ------------------------------------------

        for column, count in chunk.isna().sum().items():
            null_counts[column] += int(count)

        # ------------------------------------------
        # G. Save cleaned chunk
        # ------------------------------------------

        chunk.to_csv(
            output_path,
            index=False,
            mode="w" if first_chunk else "a",
            header=first_chunk
        )

        first_chunk = False

        print(
            f"  Processed {total_rows:,} rows",
            end="\r"
        )

    print(f"\n  Completed: {total_rows:,} rows")
    print(f"  Saved: {output_path.name}")

    return {
        "source_file": filename,
        "output_file": output_path.name,
        "rows_processed": total_rows,
        "missing_values": dict(null_counts),
        "invalid_dates": dict(invalid_dates),
        "invalid_numeric_values": dict(invalid_numeric)
    }


# --------------------------------------------------
# 4. RUN THE FULL CLEANING PIPELINE
# --------------------------------------------------

def main():

    print("\nCOMMERCEIQ - DATA CLEANING PIPELINE")
    print("=" * 70)

    results = []

    for filename, config in DATASETS.items():

        result = clean_dataset(filename, config)
        results.append(result)

    report_path = REPORT_DIR / "cleaning_report.json"

    with open(report_path, "w", encoding="utf-8") as file:
        json.dump(results, file, indent=4)

    # ----------------------------------------------
    # Final summary
    # ----------------------------------------------

    print("\n" + "=" * 70)
    print("CLEANING PIPELINE SUMMARY")
    print("=" * 70)

    summary = pd.DataFrame([
        {
            "dataset": result["source_file"],
            "rows_processed": result["rows_processed"],
            "output_file": result["output_file"]
        }
        for result in results
    ])

    print(summary.to_string(index=False))

    print("\nTotal datasets processed:", len(results))
    print("Cleaning report:", report_path)
    print("All source files remain unchanged.")
    print("\nCleaning pipeline completed successfully.")


if __name__ == "__main__":
    main()
