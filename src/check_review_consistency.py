
from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
REVIEWS_FILE = BASE_DIR / "data" / "raw" / "olist_order_reviews_dataset.csv"

reviews = pd.read_csv(REVIEWS_FILE, low_memory=False)

# Fields that should describe the review itself.
# order_id is deliberately excluded because one review ID
# can be associated with multiple orders in this dataset.
review_fields = [
    "review_score",
    "review_comment_title",
    "review_comment_message",
    "review_creation_date",
    "review_answer_timestamp"
]

repeated = reviews[
    reviews.duplicated("review_id", keep=False)
].copy()

consistency = (
    repeated.groupby("review_id")[review_fields]
    .nunique(dropna=False)
)

# A repeated review ID is consistent if every review field
# has only one distinct value within that ID.
consistency["is_consistent"] = (
    consistency[review_fields].le(1).all(axis=1)
)

print("\nCOMMERCEIQ - REVIEW CONSISTENCY CHECK")
print("=" * 65)

print("Repeated review IDs:", len(consistency))
print(
    "Consistent review IDs:",
    consistency["is_consistent"].sum()
)
print(
    "Inconsistent review IDs:",
    (~consistency["is_consistent"]).sum()
)

print("\nConsistency summary:")
print(consistency["is_consistent"].value_counts().to_string())

inconsistent_ids = consistency[
    ~consistency["is_consistent"]
].index

if len(inconsistent_ids) > 0:
    print("\nExamples of inconsistent review IDs:")

    print(
        repeated[repeated["review_id"].isin(inconsistent_ids)]
        .sort_values("review_id")
        .head(20)
        .to_string(index=False)
    )
else:
    print("\nAll repeated review IDs have consistent review content.")

print("\nCheck completed.")
