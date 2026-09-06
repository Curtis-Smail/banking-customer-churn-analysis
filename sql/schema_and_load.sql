-- Checking to make sure that all the data was imported properly

USE banking_churn;

SELECT *
FROM customer_accounts;

DESCRIBE customer_accounts;

SELECT * 
FROM customer_segments;

DESCRIBE customer_segments;

SELECT *
FROM customers;

DESCRIBE customers;

-- Initial analysis shows that certain types were imported incorrectly, and no keys were set

ALTER TABLE customer_accounts ADD PRIMARY KEY (account_id);
SELECT COUNT(*) total, COUNT(DISTINCT account_id) unique_ids
FROM customer_accounts;

ALTER TABLE customer_accounts MODIFY COLUMN balance DECIMAL(12,2);

UPDATE customer_accounts
SET has_credit_card = 
CASE 
	WHEN has_credit_card = 'TRUE' THEN 1
    WHEN has_credit_card = 'FALSE' THEN 0
END;
ALTER TABLE customer_accounts MODIFY COLUMN has_credit_card TINYINT;

UPDATE customer_accounts
SET is_active_member = 
CASE 
	WHEN is_active_member = 'TRUE' THEN 1
    WHEN is_active_member = 'FALSE' THEN 0
END;
ALTER TABLE customer_accounts MODIFY COLUMN is_active_member TINYINT;

UPDATE customer_accounts
SET exited = 
CASE 
	WHEN exited = 'TRUE' THEN 1
    WHEN exited = 'FALSE' THEN 0
END;
ALTER TABLE customer_accounts MODIFY COLUMN exited TINYINT;

SELECT COUNT(*) null_after_conversion
FROM customer_accounts
WHERE has_credit_card IS NULL OR is_active_member IS NULL OR exited IS NULL;

-- Ran into a couple issues with the boolean values, I converted them to true / false in the csv which I should have kept as 0s and 1s
-- Converted them back into 0s and 1s so the formula could work as intended

ALTER TABLE customer_accounts MODIFY COLUMN average_transaction_value DECIMAL(10,2);

DESCRIBE customer_accounts;

ALTER TABLE customer_segments ADD PRIMARY KEY (segment_id);
ALTER TABLE customer_segments MODIFY COLUMN segment_name VARCHAR(50) NOT NULL;
ALTER TABLE customer_segments MODIFY COLUMN description VARCHAR(255);

DESCRIBE customer_segments;

ALTER TABLE customers ADD PRIMARY KEY (customer_id);
ALTER TABLE customers MODIFY COLUMN surname VARCHAR(100);
ALTER TABLE customers MODIFY COLUMN gender VARCHAR(10);
ALTER TABLE customers MODIFY COLUMN geography VARCHAR(50);
ALTER TABLE customers MODIFY COLUMN estimated_salary DECIMAL(12,2);
ALTER TABLE customers MODIFY COLUMN marital_status VARCHAR(50);
ALTER TABLE customers MODIFY COLUMN occupation VARCHAR(50);

UPDATE customers
SET join_date = STR_TO_DATE(join_date, '%m/%d/%Y');

ALTER TABLE customers MODIFY COLUMN join_date DATE;

SELECT COUNT(*) null_dates
FROM customers
WHERE join_date IS NULL;

-- Ran into an issue with the date as it was formatted differently in excel
-- Converted the date to match MySQLs format and ran the formula as intended

ALTER TABLE customers MODIFY COLUMN segment VARCHAR(20);
ALTER TABLE customers MODIFY COLUMN preferred_contact_method VARCHAR(30);

DESCRIBE customers;

-- Everything is now formated as intended, ready to further explore

-- Orphaned accounts
SELECT COUNT(*) AS orphaned_accounts
FROM customer_accounts a
LEFT JOIN customers c
    ON a.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Customers with unresolved segments
SELECT COUNT(*) AS unresolved_segments
FROM customers c
LEFT JOIN customer_segments s
    ON c.segment_id = s.segment_id
WHERE s.segment_id IS NULL;

-- No FOREIGN KEY constraints added: this dataset intentionally contains
-- 9 customers with an unresolved segment_id and 10 accounts with an
-- unresolved customer_id (planted data quality issues used for the EDA).
-- Enforcing FKs here would reject those rows on constraint creation.

SHOW CREATE TABLE customers; 
SHOW CREATE TABLE customer_accounts;
SHOW CREATE TABLE customer_segments;