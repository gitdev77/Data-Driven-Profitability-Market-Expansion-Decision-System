-- Check total rows
SELECT COUNT(*) AS total_rows
FROM amazon_sales;

-- Check date range
SELECT 
    MIN(order_date) AS start_date,
    MAX(order_date) AS end_date
FROM amazon_sales;

-- Validate nulls
SELECT 
    COUNT(*) AS null_amount_rows
FROM amazon_sales
WHERE amount IS NULL;

-- Distinct status values
SELECT DISTINCT status
FROM amazon_sales;
