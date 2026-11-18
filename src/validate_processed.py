
from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
PROCESSED_DIR = BASE_DIR / "data" / "processed"

print("\nCOMMERCEIQ - PROCESSED DATA VALIDATION")
print("=" * 70)

# 1. Check all cleaned files and their row counts
files = sorted(PROCESSED_DIR.glob("*_cleaned.csv"))

print(f"\nCleaned files found: {len(files)}")

for file_path in files:
    df = pd.read_csv(file_path, low_memory=False)

    print(
        f"{file_path.name:<55} "
        f"{len(df):>10,} rows"
    )

# 2. Validate review identifiers
print("\n1. REVIEW RECORD ID VALIDATION")
print("-" * 70)

reviews = pd.read_csv(
    PROCESSED_DIR / "olist_order_reviews_dataset_cleaned.csv",
    low_memory=False
)

print("Total review rows:", len(reviews))
print("Unique review record IDs:", reviews["review_record_id"].nunique())
print("Duplicate review record IDs:", reviews["review_record_id"].duplicated().sum())
print("Missing review record IDs:", reviews["review_record_id"].isna().sum())

# 3. Validate delivery flags
print("\n2. DELIVERY FLAG VALIDATION")
print("-" * 70)

orders = pd.read_csv(
    PROCESSED_DIR / "olist_orders_dataset_cleaned.csv",
    low_memory=False
)

flag_count = orders["missing_actual_delivery_flag"].sum()

print("Total orders:", len(orders))
print("Delivered orders missing actual delivery timestamp:", flag_count)


# 4. Check source and processed record counts correctly
print("\n3. SOURCE VS PROCESSED RECORD COUNTS")
print("-" * 70)

raw_dir = BASE_DIR / "data" / "raw"

def count_csv_records(file_path):
    total = 0

    for chunk in pd.read_csv(
        file_path,
        chunksize=100_000,
        low_memory=False
    ):
        total += len(chunk)

    return total


for processed_file in files:

    source_name = processed_file.name.replace(
        "_cleaned.csv", ".csv"
    )

    source_file = raw_dir / source_name

    source_rows = count_csv_records(source_file)
    processed_rows = count_csv_records(processed_file)

    status = "PASS" if source_rows == processed_rows else "FAIL"

    print(
        f"{source_name:<45} "
        f"Source: {source_rows:>9,} | "
        f"Processed: {processed_rows:>9,} | "
        f"{status}"
    )

