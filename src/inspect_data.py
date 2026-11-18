
from pathlib import Path
import json
import pandas as pd

# Project paths
BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "data" / "raw"
REPORT_DIR = BASE_DIR / "reports"

REPORT_DIR.mkdir(parents=True, exist_ok=True)

# Expected dataset files
FILES = [
    "olist_orders_dataset.csv",
    "olist_customers_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv",
    "olist_geolocation_dataset.csv",
    "product_category_name_translation.csv"
]


def inspect_csv(filename):
    """Profile a CSV in chunks to limit memory usage."""

    path = RAW_DIR / filename

    if not path.exists():
        print(f"\n[ERROR] Missing file: {filename}")
        return None

    print(f"\n{'=' * 65}")
    print(f"FILE: {filename}")
    print("=" * 65)

    total_rows = 0
    null_counts = None
    columns = None
    sample = None

    try:
        for chunk in pd.read_csv(
            path,
            chunksize=100_000,
            low_memory=False
        ):
            if columns is None:
                columns = chunk.columns.tolist()
                null_counts = pd.Series(0, index=columns)
                sample = chunk.head(3).copy()

            total_rows += len(chunk)
            null_counts += chunk.isnull().sum()

        null_percentages = (
            (null_counts / total_rows) * 100
        ).round(2)

        print(f"Rows: {total_rows:,}")
        print(f"Columns: {len(columns)}")

        print("\nColumn names:")
        print(columns)

        print("\nMissing values:")
        print(null_percentages[null_percentages > 0])

        print("\nSample records:")
        print(sample.to_string(index=False))

        return {
            "file": filename,
            "rows": total_rows,
            "columns_count": len(columns),
            "columns": columns,
            "missing_values": null_counts.to_dict(),
            "missing_percentages": null_percentages.to_dict()
        }

    except Exception as error:
        print(f"[ERROR] Could not inspect {filename}: {error}")
        return None


def main():

    print("\nCOMMERCEIQ - DATA PROFILING")
    print("Starting dataset inspection...\n")

    if not RAW_DIR.exists():
        print(f"Raw data folder not found: {RAW_DIR}")
        return

    results = []

    for filename in FILES:
        result = inspect_csv(filename)

        if result is not None:
            results.append(result)

    # Save profiling report
    output_file = REPORT_DIR / "data_profile.json"

    with open(output_file, "w", encoding="utf-8") as file:
        json.dump(results, file, indent=4, default=str)

    # Summary
    print("\n" + "=" * 65)
    print("DATASET SUMMARY")
    print("=" * 65)

    summary = pd.DataFrame([
        {
            "file": item["file"],
            "rows": item["rows"],
            "columns": item["columns_count"]
        }
        for item in results
    ])

    print(summary.to_string(index=False))

    print(f"\nSuccessfully inspected: {len(results)}/{len(FILES)} files")
    print(f"Report saved to: {output_file}")


if __name__ == "__main__":
    main()
