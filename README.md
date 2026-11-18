# CommerceIQ – E-Commerce Business Intelligence & Predictive Analytics

An end-to-end e-commerce analytics project built using **Python, PostgreSQL, SQL, and Power BI**. The project transforms raw marketplace data into a structured analytical warehouse and interactive business intelligence dashboards.

## Project Overview

CommerceIQ analyzes the Brazilian Olist e-commerce marketplace dataset to help understand sales performance, customer purchasing behavior, product categories, seller performance, delivery reliability, payment preferences, and customer satisfaction.

The project covers data profiling, cleaning, relational database design, analytical SQL development, KPI validation, and Power BI reporting.

## Technology Stack

- **Python:** Data inspection, cleaning, validation, and PostgreSQL loading
- **PostgreSQL:** Staging tables, analytical warehouse, dimensions, facts, and KPI views
- **SQL:** Data modeling, aggregations, business metrics, and validation
- **Power BI:** Interactive dashboards and business reporting
- **Pandas:** Data processing and analysis

## Data Source

[Olist Brazilian E-Commerce Public Dataset – Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains anonymized Brazilian e-commerce transactions from 2016–2018.

The project processes nine source tables containing approximately **1.55 million records**.

Dataset files are not included in this repository. Download them from Kaggle and place the original CSV files in `data/raw/`.

## Project Workflow

1. **Data Profiling:** Inspect source tables, record counts, data types, missing values, and key fields.
2. **Data Cleaning:** Parse dates, validate numeric values, preserve legitimate repeated reviews, and document data-quality findings.
3. **PostgreSQL Loading:** Load cleaned datasets into staging tables.
4. **Data Warehouse Design:** Build analytical dimensions and fact tables.
5. **KPI Development:** Create SQL views for sales, categories, sellers, customers, delivery, satisfaction, payments, and executive KPIs.
6. **Validation:** Reconcile warehouse row counts, relationships, and business metrics.
7. **Power BI Reporting:** Build interactive dashboards for business analysis.

## Data Warehouse

The analytical schema includes:

### Dimensions
- `dim_customers`
- `dim_products`
- `dim_sellers`
- `dim_date`

### Fact Tables
- `fact_orders`
- `fact_order_items`
- `fact_payments`
- `fact_reviews`

The fact tables preserve their respective business grains to avoid double-counting when analyzing multiple transaction-level datasets.

## Business Intelligence Dashboards

The Power BI report contains five analytical pages:

1. **Executive Overview:** GMV, orders, unique customers, repeat customer rate, on-time delivery, and average review score.
2. **Sales & Category:** Monthly sales trends, category GMV, order distribution, and average item prices.
3. **Customer Analytics:** One-time versus repeat customers, customer purchase frequency, and customer GMV.
4. **Seller & Delivery:** Seller performance, seller-state GMV, and delivery performance.
5. **Payments & Satisfaction:** Payment method distribution, payment value, and monthly customer satisfaction.

## Key Findings

| Metric | Result |
|---|---:|
| Total Orders | 99,441 |
| Unique Customers | 96,096 |
| Items Sold | 112,650 |
| GMV | R$13,591,643.70 |
| Freight Value | R$2,251,909.54 |
| Repeat Customer Rate | 3.12% |
| Eligible Delivery Orders | 96,470 |
| On-Time Delivery Rate | 91.89% |
| Average Review Score | 4.09 / 5 |

### Additional Insights

- Health & Beauty was the highest-GMV product category.
- São Paulo accounted for approximately 64.4% of seller GMV.
- Credit cards represented the largest share of payment value.
- March 2018 had the lowest monthly on-time delivery rate among the analyzed months.

## Repository Structure

```text
CommerceIQ/
├── docs/
│   ├── business_requirements.md
│   └── data_model.md
├── reports/
│   ├── cleaning_report.json
│   └── data_profile.json
├── sql/
│   ├── 01_staging_validation.sql
│   ├── 03_analytics_schema.sql
│   ├── 04_dimension_validation.sql
│   ├── 05_fact_orders.sql
│   ├── 06_fact_order_items.sql
│   ├── 07_fact_payments.sql
│   ├── 08_fact_reviews.sql
│   ├── 09_dim_date.sql
│   └── 10–18 KPI and validation scripts
├── src/
│   ├── check_review_consistency.py
│   ├── clean_data.py
│   ├── database.py
│   ├── inspect_data.py
│   ├── investigate_reviews.py
│   ├── load_to_postgres.py
│   ├── validate_data.py
│   └── validate_processed.py
├── requirements.txt
└── .gitignore
```

## Running the Project

### 1. Clone the repository

```bash
git clone https://github.com/1616piyu/CommerceIQ-Ecommerce-Analytics.git
cd CommerceIQ-Ecommerce-Analytics
```

### 2. Create a Python environment

```bash
python -m venv .venv
```

Activate it on Windows:

```powershell
.venv\Scripts\Activate.ps1
```

Install dependencies:

```bash
pip install -r requirements.txt
```

### 3. Prepare the dataset

Download the Olist dataset from Kaggle and place the original CSV files in:

```text
data/raw/
```

### 4. Configure PostgreSQL

Create a PostgreSQL database named `commerceiq`.

Configure your database connection using local environment variables. Do not commit credentials or `.env` files.

### 5. Run the Python pipeline

Run the scripts in the appropriate order:

```bash
python src/inspect_data.py
python src/validate_data.py
python src/investigate_reviews.py
python src/check_review_consistency.py
python src/clean_data.py
python src/validate_processed.py
python src/load_to_postgres.py
```

### 6. Build the analytical warehouse

Execute the SQL scripts in `sql/` in numerical order, beginning with staging validation and schema creation, followed by dimensions, facts, KPI views, and final warehouse validation.

The database setup and scripts should be reviewed against the project documentation before execution.

### 7. Open the Power BI report

Connect Power BI Desktop to the local PostgreSQL database and load the analytical views from the `analytics` schema.

The local `.pbix` report is not included in this repository.

## Important Metric Definitions

- **GMV:** Sum of product item prices. Freight is reported separately. GMV is not net revenue or profit.
- **Repeat Customer:** A customer identified by `customer_unique_id` with more than one order in the historical dataset.
- **On-Time Delivery Rate:** On-time delivered orders divided by delivered orders with both actual and estimated delivery timestamps.
- **Customer Satisfaction:** Average review score from the available review records.

## Limitations

- The dataset is historical and anonymized.
- Monetary values are in Brazilian Real (BRL).
- The dataset does not provide marketing spend, operating costs, or profit; profitability and ROI are not calculated.
- Historical repeat-purchase behavior should not be interpreted as a predictive churn model.
- Delivery metrics exclude delivered orders without the required actual delivery timestamp.

## Future Enhancements

- Customer lifetime value estimation
- Customer inactivity and churn propensity analysis
- Delivery delay prediction
- Seller risk and performance scoring
- Automated KPI monitoring

## Author

**Piyush Pratap Singh**

- GitHub: https://github.com/1616piyu
- LinkedIn: https://www.linkedin.com/in/piyush-pratap-singh-22995029a/

## Dataset Attribution and License

Dataset: Olist Brazilian E-Commerce Public Dataset.

The dataset is distributed under the **CC BY-NC-SA 4.0** license. Please refer to the original Kaggle dataset page for its terms. This repository does not redistribute the source dataset.