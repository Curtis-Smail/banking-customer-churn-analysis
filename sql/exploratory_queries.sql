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

-- Q1. What is the overall customer churn rate?
SELECT COUNT(*) total_accounts,
	   SUM(exited) total_churned,
	   ROUND(AVG(exited) * 100, 2) overall_churn_rate
FROM customer_accounts;

-- Of the 10,000 accounts, 2,725 have churned, creating an overall churn rate of 27.25%.

-- Q2. Compare the customer segments, which has the highest and lowest churn rate?
SELECT COALESCE(s.segment_name, 'Unknown') segment,
	   COUNT(*) total_customers,
       SUM(a.exited) churned_customers,
       ROUND(AVG(a.exited) * 100, 2) churn_rate_pct
FROM customer_accounts a
JOIN customers c
ON a.customer_id = c.customer_id
LEFT JOIN customer_segments s
ON c.segment_id = s.segment_id
GROUP BY s.segment_id, s.segment_name
ORDER BY churn_rate_pct DESC;

-- After comparing the segments, the segment with the highest churn rate is Student at 33.52%,
-- and the lowest is Premium at 22.28%.

-- Q3. How does customer engagement influence churn?
SELECT
    CASE 
        WHEN is_active_member = 1 THEN 'Active'
        ELSE 'Inactive'
    END activity_status,
    COUNT(*) total_customers,
    SUM(exited) churned_customers,
    ROUND(AVG(exited) * 100, 2) churn_rate_pct,
    ROUND(AVG(monthly_transactions), 1) avg_monthly_transactions,
    ROUND(AVG(last_login_days), 1) avg_days_since_last_login
FROM customer_accounts
GROUP BY is_active_member;

-- Customer engagement shows inactive customers have a churn rate 3x higher than active customers,
-- compared to customer segments, which fall within a 12 percentage point spread.

-- Q4. Does the number of products held affect churn?
SELECT 
    num_products,
    COUNT(*) total_customers,
    SUM(exited) churned_customers,
    ROUND(AVG(exited) * 100, 2) churn_rate_pct,
    ROUND(AVG(balance), 2) avg_balance
FROM customer_accounts
GROUP BY num_products
ORDER BY num_products;

-- Customers with 1 product churn nearly 15 percentage points more than those with 2-4 products,
-- and they are also less valuable customers

-- Q5. Is there a relationship between complaints and churn?
SELECT complaints_last_year,
       COUNT(*) total_accounts,
       ROUND(AVG(exited) * 100, 2) churn_rate_pct
FROM customer_accounts
GROUP BY complaints_last_year
ORDER BY complaints_last_year;

-- As the number of complaints increases, the churn rate gradually increases, except at 4 complaints
-- (less than a 2 percentage point gap between 3 and 4 complaints) and 6 complaints (only 9 accounts,
-- difficult to judge reliably). The 7- and 8-complaint categories each have only 1 account, so those
-- are also too small to conclude from.

SELECT
    complaints_last_year,
    COUNT(*) total_customers,
    ROUND(AVG(exited) * 100, 2) churn_rate_pct,
    CASE
        WHEN COUNT(*) < 30 THEN 'Small Sample'
        ELSE 'Sufficient Sample'
    END sample_quality
FROM customer_accounts
GROUP BY complaints_last_year
ORDER BY complaints_last_year;

-- Adding in a sample quality column creates a more accurate comparison between complaints and churn rate.

-- Q6. Which financial characteristics are most associated with churn?
SELECT
    CASE
        WHEN balance = 0 THEN '$0'
        WHEN balance < 25000 THEN 'Low ($1-25K)'
        WHEN balance < 75000 THEN 'Mid ($25K-75K)'
        ELSE 'High ($75K+)'
    END balance_tier,
    COUNT(*) total_accounts,
    ROUND(AVG(exited) * 100, 2) churn_rate_pct
FROM customer_accounts
GROUP BY balance_tier
ORDER BY MIN(balance);

-- Churn is substantially higher at a $0 balance (34.26%) than the Low and Mid tiers (26.22% and 25.35%).
-- There is another notable drop in churn for the High balance tier (21.61%).

SELECT
    CASE
        WHEN estimated_salary < 40000 THEN 'Low (<$40K)'
        WHEN estimated_salary < 75000 THEN 'Lower-Mid ($40K-$75K)'
        WHEN estimated_salary < 100000 THEN 'Upper-Mid($75K-$100K)'
        ELSE 'High ($100K+)'
    END salary_band,
    COUNT(*) total_customers,
    ROUND(AVG(a.exited) * 100, 2) churn_rate_pct
FROM customers c
JOIN customer_accounts a
ON c.customer_id = a.customer_id
GROUP BY salary_band
ORDER BY MIN(estimated_salary);

-- Churn rate is noticeably higher for Low and Lower-Mid (27.56% - 28.24%) compared to Upper-Mid and High (21.95%-23.25%). 

SELECT
    CASE
        WHEN credit_score < 580 THEN 'Poor (<580)'
        WHEN credit_score < 670 THEN 'Fair (580-669)'
        WHEN credit_score < 740 THEN 'Good (670-739)'
        WHEN credit_score < 800 THEN 'Very Good (740-799)'
        ELSE 'Exceptional (800+)'
    END credit_score_band,
    COUNT(*) total_accounts,
    ROUND(AVG(exited) * 100, 2) churn_rate_pct
FROM customer_accounts
GROUP BY credit_score_band
ORDER BY MIN(credit_score);

-- Churn rate across credit score bands is fairly flat, staying within 2 percentage points of each other.

-- Q7. How does customer tenure relate to churn?
SELECT
    CASE
        WHEN tenure <= 1 THEN '0-1 yrs'
        WHEN tenure <= 3 THEN '1-3 yrs'
        WHEN tenure <= 5 THEN '3-5 yrs'
        ELSE '5+ yrs'
    END tenure_band,
    COUNT(*) total_accounts,
    ROUND(AVG(exited) * 100, 2) churn_rate_pct
FROM customer_accounts
GROUP BY tenure_band
ORDER BY MIN(tenure);

-- Churn is highest among customers with 0–1 years of tenure, with an 8 percentage-point difference
-- compared with the 1-3 year group.

-- Q8. Which premium customers are most at risk of leaving?
SELECT
    CASE
        WHEN (
            (a.is_active_member = 0) +
            (a.num_products = 1) +
            (a.complaints_last_year >= 1) +
            (a.balance = 0) +
            (a.tenure <= 1)
        ) >= 2 THEN 'High Risk (2+ factors)'
        ELSE 'Lower Risk'
    END risk_group,
    COUNT(*) premium_customers,
    ROUND(AVG(a.exited) * 100, 2) churn_rate_pct,
    ROUND(AVG(a.balance), 2) avg_balance
FROM customer_accounts a
JOIN customers c         
ON a.customer_id = c.customer_id
JOIN customer_segments s 
ON c.segment_id = s.segment_id
WHERE s.segment_name = 'Premium'
GROUP BY risk_group;

-- More than half of Premium customers (517 of 965) are classified as high risk, churning at 32.11%
-- compared to just 10.94% for lower-risk Premium customers. Given that Premium's overall average
-- churn rate is 22.28% (as shown in Q2), this segment is masking a large at-risk subgroup that
-- behaves similarly to high-risk customers elsewhere in the bank.

-- Q9. Which combination of factors best characterizes the highest-risk churn group?
SELECT
    CASE
        WHEN (
            (is_active_member = 0) +
            (num_products = 1) +
            (complaints_last_year >= 1) +
            (balance = 0) +
            (tenure <= 1)
        ) >= 2 THEN 'High Risk (2+ factors)'
        ELSE 'Lower Risk'
    END risk_group,
    COUNT(*) total_accounts,
    ROUND(AVG(exited) * 100, 2) churn_rate_pct
FROM customer_accounts
GROUP BY risk_group;

-- Customers with 2 or more risk factors have a churn rate over 26 percentage points higher than
-- those with fewer than 2.
