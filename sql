CREATE DATABASE IF NOT EXISTS market_analysis;
USE market_analysis;

DROP TABLE IF EXISTS amazon_sales;

CREATE TABLE amazon_sales (
    order_id VARCHAR(50),
    date DATE,
    status VARCHAR(50),
    fulfilment VARCHAR(50),
    sales_channel VARCHAR(50),
    ship_city VARCHAR(100),
    ship_state VARCHAR(100),
    ship_country VARCHAR(50),
    category VARCHAR(100),
    qty INT,
    amount DECIMAL(10,2),
    b2b VARCHAR(10)
);
select database();
DROP TABLE amazon_sales;
RENAME TABLE `amazon sale report` TO amazon_sales;
SELECT COUNT(*) 
FROM amazon_sales;
SHOW tables;
SELECT COUNT(*) AS total_rows
FROM amazon_sales;

SELECT 
    MIN(date) AS start_date,
    MAX(date) AS end_date
FROM amazon_sales;
SELECT
    SUM(amount) AS total_revenue,
    AVG(amount) AS avg_order_value
FROM amazon_sales;


SELECT status, COUNT(*) AS count
FROM amazon_sales
GROUP BY status
ORDER BY count DESC;

SELECT fulfilment, COUNT(*) 
FROM amazon_sales
GROUP BY fulfilment;

SELECT
    ship_state,
    SUM(amount) AS total_revenue,
    COUNT(*) AS total_orders
FROM amazon_sales
GROUP BY ship_state
ORDER BY total_revenue DESC;
-- this is from each state how much revenue and total orders

-- top reveue contributing states now 

SELECT
   ship_state,
    SUM(amount) AS total_revenue
FROM amazon_sales
GROUP BY ship_state
ORDER BY total_revenue DESC
LIMIT 10;

-- limit 10 focuses on the top 10..

SELECT
    ship_state,
    COUNT(*) AS total_orders,
    AVG(amount) AS avg_order_value
FROM amazon_sales
GROUP BY ship_state
ORDER BY total_orders DESC;

-- Some high-volume markets generate relatively low average order values, indicating operational load without proportional revenue.

SELECT
   ship_state,
    COUNT(*) AS total_orders,
    SUM(
        CASE 
            WHEN status = 'Shipped' THEN 1 
            ELSE 0 
        END
    ) AS shipped_orders,
    ROUND(
        SUM(
            CASE 
                WHEN status = 'Shipped' THEN 1 
                ELSE 0 
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS fulfillment_rate
FROM amazon_sales
GROUP BY ship_state
ORDER BY fulfillment_rate DESC;

-- We filter out weak markets and identify states that combine strong demand with reliable order fulfillment, making them suitable for expansion.

SELECT
  ship_state ,
    SUM(amount) AS total_revenue,
    COUNT(*) AS total_orders,
    AVG(amount) AS avg_order_value,
    ROUND(
        SUM(
            CASE 
                WHEN status = 'Shipped' THEN 1 
                ELSE 0 
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS fulfillment_rate
FROM amazon_sales
GROUP BY ship_state
HAVING total_revenue > (
    SELECT AVG(state_revenue)
    FROM (
        SELECT ship_state, SUM(amount) AS state_revenue
        FROM amazon_sales
        GROUP BY ship_state
    ) AS t
)
ORDER BY fulfillment_rate DESC, total_revenue DESC;

-- Inner query → calculates total revenue per state
-- filters states above average revenue
-- Final sort prioritizes:
-- High fulfillment rate
-- High revenue

-- This is decision-grade SQL.
DESCRIBE amazon_sales;
SELECT
    `ship-state`,
    SUM(amount) AS total_revenue,
    ROUND(
        SUM(amount) / (SELECT SUM(amount) FROM amazon_sales) * 100,
        2
    ) AS revenue_share_pct
FROM amazon_sales
GROUP BY `ship-state`
ORDER BY total_revenue DESC;

SELECT
    `ship-state`,
    `ship-city`,
    SUM(amount) AS city_revenue,
    COUNT(*) AS total_orders
FROM amazon_sales
GROUP BY `ship-state`, `ship-city`
ORDER BY `ship-state`, city_revenue DESC;

SELECT
    `ship-state` AS state,
    `Category` AS category,
    SUM(amount) AS category_revenue,
    COUNT(*) AS total_orders
FROM amazon_sales
GROUP BY `ship-state`, `Category`
ORDER BY state, category_revenue DESC;

SELECT
    `ship-state` AS state,
    b2b,
    SUM(amount) AS total_revenue,
    COUNT(*) AS total_orders
FROM amazon_sales
GROUP BY `ship-state`, b2b
ORDER BY state, total_revenue DESC;

SELECT
    `ship-state` AS state,
    SUM(amount) AS total_revenue,

    ROUND(
        SUM(amount) / (SELECT SUM(amount) FROM amazon_sales) * 100,
        2
    ) AS revenue_share_pct,

    ROUND(
        SUM(CASE WHEN `Status` = 'Shipped' THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS fulfillment_rate,

    RANK() OVER (ORDER BY SUM(amount) DESC) AS revenue_rank,

    RANK() OVER (
        ORDER BY 
        ROUND(
            SUM(CASE WHEN `Status` = 'Shipped' THEN 1 ELSE 0 END)
            / COUNT(*) * 100,
            2
        ) DESC
    ) AS fulfillment_rank,

    (
        RANK() OVER (ORDER BY SUM(amount) DESC)
        +
        RANK() OVER (
            ORDER BY 
            ROUND(
                SUM(CASE WHEN `Status` = 'Shipped' THEN 1 ELSE 0 END)
                / COUNT(*) * 100,
                2
            ) DESC
        )
    ) AS composite_score

FROM amazon_sales
GROUP BY `ship-state`
ORDER BY composite_score ASC;
