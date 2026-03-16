--Deliver Time v Weight
CREATE OR REPLACE VIEW analysis.delivery_time_by_weight AS 
SELECT 
	CASE
		WHEN p.product_weight_g < 456 THEN '0-1 lbs'
		WHEN p.product_weight_g < 2267 THEN '1-5 lbs'
		WHEN p.product_weight_g < 4535 THEN '5-10 lbs'
		WHEN p.product_weight_g < 9072 THEN '10-20 lbs'
		WHEN p.product_weight_g < 22678 THEN '20-50 lbs'
		ELSE '50+ lbs'
	END AS weight_bucket,
	ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400))
	AS avg_delivery_days,
	COUNT(*) AS total_orders
FROM public.orders o 
JOIN public.order_items oi 
ON o.order_id = oi.order_id
JOIN public.products p 
ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
AND p.product_weight_g IS NOT NULL
GROUP BY weight_bucket
ORDER BY avg_delivery_days;

--Delivery Time vs Customer Review Rating 
CREATE OR REPLACE VIEW analysis.delivery_time_vs_rating AS
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400))
	AS avg_delivery_days AS delivery_days,
    AVG(r.review_score) AS avg_rating,
    COUNT(*) AS total_orders
FROM public.orders o
JOIN public.order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_days
ORDER BY delivery_days;

--Delivery Time vs Size
CREATE OR REPLACE VIEW analysis.delivery_time_by_volume_bucket AS
SELECT
	CASE 
		WHEN (p.product_length_cm * p.product_height_cm * p.product_width_cm) < 1000 THEN 'Very Small'
		WHEN (p.product_length_cm * p.product_height_cm * p.product_width_cm) < 5000 THEN 'Small'
		WHEN (p.product_length_cm * p.product_height_cm * p.product_width_cm) < 20000 THEN 'Medium'
		WHEN (p.product_length_cm * p.product_height_cm * p.product_width_cm) < 50000 THEN 'Large'
		ELSE 'Very Large'
	END AS volume_bucket,
	ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400))
	AS avg_delivery_days,
	COUNT(*) AS total_orders
FROM public.orders o 
JOIN public.order_items oi
ON o.order_id = oi.order_id
JOIN public.products p 
ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
AND p.product_length_cm IS NOT NULL
AND p.product_height_cm IS NOT NULL
AND p.product_width_cm IS NOT NULL
GROUP BY volume_bucket
ORDER BY avg_delivery_days DESC;

--Number of Orders per State
CREATE OR REPLACE VIEW analysis.orders_by_state AS
SELECT
    c.customer_state,
    COUNT(o.order_id) AS total_orders
FROM public.customers c
JOIN public.orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;

--Number of Orders Each Month 
CREATE OR REPLACE VIEW analysis.orders_per_month AS
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(o.order_id) AS total_orders
FROM public.orders o
GROUP BY month
ORDER BY month;

--Delivery Time per State
CREATE OR REPLACE VIEW analysis.delivery_time_by_state AS
SELECT
    c.customer_state,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400))
	AS avg_delivery_days,
    COUNT(o.order_id) AS total_orders
FROM public.orders o
JOIN public.customers c
ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

--Revenue Per Category 
CREATE OR REPLACE VIEW analysis.revenue_by_category AS
SELECT
    t.product_category_name_english AS category,
    SUM(oi.price) AS total_revenue,
	COUNT(oi.order_item_id) AS items_sold
FROM public.order_items oi
JOIN public.products p
ON oi.product_id = p.product_id
JOIN public.product_category_name_translation t
ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY total_revenue DESC;