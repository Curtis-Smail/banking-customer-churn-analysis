# Data Dictionary — Banking Churn Analysis

## Customers Table

| Column | Data Type | Description |
|---|---|---|
| `customer_id` | Integer | Unique identifier for each customer. Primary key. |
| `segment_id` | Integer | Identifier linking the customer to a customer segment. Foreign key to `customer_segments.segment_id`. |
| `surname` | Text | Customer's last name. Used for identification only and not included in analytical calculations. |
| `age` | Integer | Customer's age in years. |
| `gender` | Text | Customer's gender after standardization during data cleaning. |
| `geography` | Text | Country or geographic region where the customer resides. |
| `estimated_salary` | Decimal | Estimated annual salary of the customer. |
| `marital_status` | Text | Customer's marital status. |
| `occupation` | Text | Customer's occupation after standardization of inconsistent values. |
| `join_date` | Date | Date the customer became a client of the bank. |
| `segment` | Text | Customer segment assigned by the business (Retail, Family, Student, Premium, or Senior). |
| `num_dependents` | Integer | Number of financial dependents associated with the customer. |
| `preferred_contact_method` | Text | Customer's preferred communication channel (Email, Phone, SMS, etc.). |

## Customer Accounts Table

| Column | Data Type | Description |
|---|---|---|
| `account_id` | Integer | Unique identifier for each customer account. Primary key. |
| `customer_id` | Integer | Customer associated with the account. Foreign key to `customers.customer_id`. |
| `credit_score` | Integer | Customer's credit score at the time of analysis. |
| `tenure` | Integer | Number of years the customer has been with the bank. |
| `balance` | Decimal | Current account balance. |
| `num_products` | Integer | Number of banking products held by the customer. |
| `has_credit_card` | Boolean | Indicates whether the customer owns a credit card. |
| `is_active_member` | Boolean | Indicates whether the customer is considered an active member. |
| `exited` | Boolean | Churn indicator. `True` indicates the customer left the bank; `False` indicates the customer remained. |
| `complaints_last_year` | Integer | Number of complaints submitted by the customer during the previous year. |
| `monthly_transactions` | Integer | Average number of transactions completed per month. |
| `average_transaction_value` | Decimal | Average monetary value of the customer's transactions. |
| `last_login_days` | Integer | Number of days since the customer's last login to online banking services. Lower values indicate more recent activity. |

## Customer Segments Table

| Column | Data Type | Description |
|---|---|---|
| `segment_id` | Integer | Unique identifier for each customer segment. Primary key. |
| `segment_name` | Text | Name of the customer segment. |
| `description` | Text | Business description of the customer segment. |

## Known Data Quality Issues

| Table | Column | Issue | Rows Affected | Resolution |
|---|---|---|---|---|
| `customers` | `segment_id` | References a `segment_id` not present in `customer_segments` | 9 | Retained, flagged "Unknown" in `segment` |
| `customer_accounts` | `customer_id` | References a `customer_id` not present in `customers` | 10 | Retained in raw data; excluded from customer-level analysis |

## Derived Fields

The following fields are not part of the source data — they were engineered during
the Python analysis (`notebooks/churn_eda.ipynb`) to support segmentation and the
combined risk score. They do not exist in the raw or cleaned CSVs.

| Field | Type | Description |
|---|---|---|
| `age_group` | Text | Age bucketed into bands: Under 30, 30-39, 40-49, 50-59, 60+ |
| `tenure_band` | Text | Tenure bucketed into bands: 0-1 yrs, 1-3 yrs, 3-5 yrs, 5+ yrs |
| `balance_tier` | Text | Balance bucketed into: $0, Low ($1-25K), Mid ($25K-75K), High ($75K+) |
| `credit_score_band` | Text | Credit score bucketed into: Poor (<580), Fair (580-669), Good (670-739), Very Good (740-799), Exceptional (800+) |
| `salary_band` | Text | Estimated salary bucketed into: Low (<$40K), Lower-Mid ($40K-$75K), Upper-Mid ($75K-$100K), High ($100K+) |
| `product_group` | Text | `num_products` collapsed to binary: Single Product (1) vs. Multiple Products (2-4) |
| `login_engagement` | Text | `last_login_days` bucketed into: Highly Active (≤7 days), Active (8-30), Low Activity (31-90), Inactive (90+) |
| `engagement_risk_flag` | Integer (0/1) | 1 if `login_engagement` is "Low Activity" or "Inactive" |
| `one_product_flag` | Integer (0/1) | 1 if `num_products` = 1 |
| `complaint_flag` | Integer (0/1) | 1 if `complaints_last_year` > 0 |
| `zero_balance_flag` | Integer (0/1) | 1 if `balance` = 0 |
| `short_tenure_flag` | Integer (0/1) | 1 if `tenure` ≤ 1 |
| `risk_factor_count` | Integer (0-5) | Sum of the five risk flags above |
| `risk_group` | Text | "High Risk (3+ factors)" if `risk_factor_count` ≥ 3, otherwise "Lower Risk" |

## Relationships

| Parent Table | Child Table | Relationship |
|---|---|---|
| `customer_segments` | `customers` | One segment can contain many customers (1:M). |
| `customers` | `customer_accounts` | One customer can be associated with one account in this dataset (1:1). |

## Primary Keys

| Table | Primary Key |
|---|---|
| `customers` | `customer_id` |
| `customer_accounts` | `account_id` |
| `customer_segments` | `segment_id` |

## Foreign Keys

| Table | Foreign Key | References |
|---|---|---|
| `customers` | `segment_id` | `customer_segments.segment_id` |
| `customer_accounts` | `customer_id` | `customers.customer_id` |

**Note:** These foreign key relationships are documented but not enforced at the
database level. This dataset intentionally contains 9 customer records with an
unresolved `segment_id` and 10 account records with an unresolved `customer_id`
(see [Known Data Quality Issues](#known-data-quality-issues)) — enforcing FK
constraints in SQL would reject these rows on table creation. See
`sql/schema_and_load.sql` for the schema as implemented.
