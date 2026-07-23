-- Query 1: Total revenue, order count, and average order value by product category (net of discounts)
SELECT 
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.category;

-- Query 2: Top 20 customers by lifetime spend, including their city and signup date (net of discounts)
SELECT 
    c.customer_id,
    c.name,
    c.city,
    c.signup_date,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS lifetime_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.name, c.city, c.signup_date
ORDER BY lifetime_spend DESC
LIMIT 20;

-- Query 3: Month-over-month revenue trend for the last 24 months using LAG window function
WITH monthly_revenue AS (
    SELECT 
        strftime('%Y-%m', o.order_date) AS month,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY strftime('%Y-%m', o.order_date)
)
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2) AS mom_change
FROM monthly_revenue
ORDER BY month DESC
LIMIT 24;

-- Query 4: Return rate (share of order_items with negative quantity) for each product category using a CTE
WITH category_items AS (
    SELECT 
        p.category,
        COUNT(*) AS total_items,
        SUM(CASE WHEN oi.quantity < 0 THEN 1 ELSE 0 END) AS returned_items
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category
)
SELECT 
    category,
    returned_items,
    total_items,
    ROUND(CAST(returned_items AS REAL) / total_items, 4) AS return_rate
FROM category_items;

-- Query 5: Customers who placed orders in every one of the last 3 calendar quarters
WITH max_date AS (
    SELECT MAX(order_date) AS max_o_date FROM orders
),
customer_quarters AS (
    SELECT DISTINCT
        o.customer_id,
        strftime('%Y', o.order_date) || '-Q' || ((CAST(strftime('%m', o.order_date) AS INTEGER) + 2) / 3) AS year_quarter
    FROM orders o, max_date
    WHERE o.order_date >= date(max_date.max_o_date, '-9 months', 'start of month')
)
SELECT 
    c.customer_id,
    c.name
FROM customers c
JOIN customer_quarters cq ON c.customer_id = cq.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(DISTINCT cq.year_quarter) = 3;

-- Query 6: Top 10 products by average review rating with at least 15 reviews
SELECT 
    p.product_id,
    p.name,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(r.review_id) AS review_count
FROM products p
JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.name
HAVING COUNT(r.review_id) >= 15
ORDER BY avg_rating DESC, review_count DESC
LIMIT 10;

-- Query 7: Average session duration and pages viewed by device type for purchasing customers
SELECT 
    w.device,
    ROUND(AVG(w.duration_minutes), 2) AS avg_duration_minutes,
    ROUND(AVG(w.pages_viewed), 2) AS avg_pages_viewed
FROM web_sessions w
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = w.customer_id
)
GROUP BY w.device;

-- Query 8: Product revenue ranking within each category using DENSE_RANK()
WITH product_revenue AS (
    SELECT 
        p.category,
        p.product_id,
        p.name,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS total_revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_id, p.name
)
SELECT 
    category,
    product_id,
    name,
    total_revenue,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) AS category_rank
FROM product_revenue;

-- Query 9: Payment-method mix (share of orders) split by country
WITH country_payment_counts AS (
    SELECT 
        c.country,
        o.payment_method,
        COUNT(o.order_id) AS method_orders,
        SUM(COUNT(o.order_id)) OVER (PARTITION BY c.country) AS country_total_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.country, o.payment_method
)
SELECT 
    country,
    payment_method,
    method_orders,
    country_total_orders,
    ROUND(CAST(method_orders AS REAL) / country_total_orders, 4) AS order_share
FROM country_payment_counts
ORDER BY country, order_share DESC;

-- Query 10: Profitability margin by category to identify margin
-- leakage (Leadership metric: Revenue alone hides high-cost categories)
SELECT 
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS net_revenue,
    ROUND(SUM(oi.quantity * p.cost), 2) AS total_cost,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) - SUM(oi.quantity * p.cost), 2) AS net_profit,
    ROUND((SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) - SUM(oi.quantity * p.cost)) / SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) * 100, 2) AS profit_margin_pct
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY profit_margin_pct ASC;