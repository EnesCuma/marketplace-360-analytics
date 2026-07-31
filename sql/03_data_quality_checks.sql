USE Marketplace360;
GO

/* =========================================================
   MARKETPLACE 360 ANALYTICS
   Data quality checks for staging tables
   ========================================================= */

-- 1. Row counts
SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM stg.customers

UNION ALL
SELECT 'geolocation', COUNT(*)
FROM stg.geolocation

UNION ALL
SELECT 'order_items', COUNT(*)
FROM stg.order_items

UNION ALL
SELECT 'order_payments', COUNT(*)
FROM stg.order_payments

UNION ALL
SELECT 'order_reviews', COUNT(*)
FROM stg.order_reviews

UNION ALL
SELECT 'orders', COUNT(*)
FROM stg.orders

UNION ALL
SELECT 'products', COUNT(*)
FROM stg.products

UNION ALL
SELECT 'sellers', COUNT(*)
FROM stg.sellers

UNION ALL
SELECT 'product_category_translation', COUNT(*)
FROM stg.product_category_translation;
GO


-- 2. Missing values in important columns
SELECT
    'customers' AS table_name,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_primary_id,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS missing_secondary_id,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS missing_state
FROM stg.customers

UNION ALL

SELECT
    'orders',
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END)
FROM stg.orders

UNION ALL

SELECT
    'order_items',
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END)
FROM stg.order_items

UNION ALL

SELECT
    'products',
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END)
FROM stg.products

UNION ALL

SELECT
    'sellers',
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END)
FROM stg.sellers;
GO


-- 3. Duplicate primary identifiers
SELECT
    'customers.customer_id' AS checked_column,
    COUNT(*) AS duplicate_groups,
    SUM(record_count - 1) AS extra_records
FROM
(
    SELECT customer_id, COUNT(*) AS record_count
    FROM stg.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) AS duplicates

UNION ALL

SELECT
    'orders.order_id',
    COUNT(*),
    SUM(record_count - 1)
FROM
(
    SELECT order_id, COUNT(*) AS record_count
    FROM stg.orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS duplicates

UNION ALL

SELECT
    'products.product_id',
    COUNT(*),
    SUM(record_count - 1)
FROM
(
    SELECT product_id, COUNT(*) AS record_count
    FROM stg.products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) AS duplicates

UNION ALL

SELECT
    'sellers.seller_id',
    COUNT(*),
    SUM(record_count - 1)
FROM
(
    SELECT seller_id, COUNT(*) AS record_count
    FROM stg.sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) AS duplicates

UNION ALL

SELECT
    'order_reviews.review_id',
    COUNT(*),
    SUM(record_count - 1)
FROM
(
    SELECT review_id, COUNT(*) AS record_count
    FROM stg.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
) AS duplicates;
GO


-- 4. Composite key duplicates in order items
SELECT
    COUNT(*) AS duplicate_groups,
    SUM(record_count - 1) AS extra_records
FROM
(
    SELECT
        order_id,
        order_item_id,
        COUNT(*) AS record_count
    FROM stg.order_items
    GROUP BY
        order_id,
        order_item_id
    HAVING COUNT(*) > 1
) AS duplicates;
GO


-- 5. Orphan records between related tables
SELECT
    'orders_without_customer' AS quality_check,
    COUNT(*) AS issue_count
FROM stg.orders AS o
LEFT JOIN stg.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'order_items_without_order',
    COUNT(*)
FROM stg.order_items AS oi
LEFT JOIN stg.orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'order_items_without_product',
    COUNT(*)
FROM stg.order_items AS oi
LEFT JOIN stg.products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'order_items_without_seller',
    COUNT(*)
FROM stg.order_items AS oi
LEFT JOIN stg.sellers AS s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL

SELECT
    'payments_without_order',
    COUNT(*)
FROM stg.order_payments AS op
LEFT JOIN stg.orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'reviews_without_order',
    COUNT(*)
FROM stg.order_reviews AS r
LEFT JOIN stg.orders AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;
GO


-- 6. Failed numeric conversions
SELECT
    'order_items.price' AS checked_column,
    COUNT(*) AS invalid_value_count
FROM stg.order_items
WHERE price IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18, 2), price) IS NULL

UNION ALL

SELECT
    'order_items.freight_value',
    COUNT(*)
FROM stg.order_items
WHERE freight_value IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18, 2), freight_value) IS NULL

UNION ALL

SELECT
    'order_payments.payment_value',
    COUNT(*)
FROM stg.order_payments
WHERE payment_value IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18, 2), payment_value) IS NULL

UNION ALL

SELECT
    'order_payments.payment_installments',
    COUNT(*)
FROM stg.order_payments
WHERE payment_installments IS NOT NULL
  AND TRY_CONVERT(INT, payment_installments) IS NULL

UNION ALL

SELECT
    'order_reviews.review_score',
    COUNT(*)
FROM stg.order_reviews
WHERE review_score IS NOT NULL
  AND TRY_CONVERT(INT, review_score) IS NULL

UNION ALL

SELECT
    'products.product_weight_g',
    COUNT(*)
FROM stg.products
WHERE product_weight_g IS NOT NULL
  AND TRY_CONVERT(DECIMAL(18, 2), product_weight_g) IS NULL;
GO


-- 7. Failed date conversions
SELECT
    'orders.order_purchase_timestamp' AS checked_column,
    COUNT(*) AS invalid_value_count
FROM stg.orders
WHERE order_purchase_timestamp IS NOT NULL
  AND TRY_CONVERT(DATETIME2, order_purchase_timestamp) IS NULL

UNION ALL

SELECT
    'orders.order_approved_at',
    COUNT(*)
FROM stg.orders
WHERE order_approved_at IS NOT NULL
  AND TRY_CONVERT(DATETIME2, order_approved_at) IS NULL

UNION ALL

SELECT
    'orders.order_delivered_carrier_date',
    COUNT(*)
FROM stg.orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND TRY_CONVERT(DATETIME2, order_delivered_carrier_date) IS NULL

UNION ALL

SELECT
    'orders.order_delivered_customer_date',
    COUNT(*)
FROM stg.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND TRY_CONVERT(DATETIME2, order_delivered_customer_date) IS NULL

UNION ALL

SELECT
    'orders.order_estimated_delivery_date',
    COUNT(*)
FROM stg.orders
WHERE order_estimated_delivery_date IS NOT NULL
  AND TRY_CONVERT(DATETIME2, order_estimated_delivery_date) IS NULL

UNION ALL

SELECT
    'order_items.shipping_limit_date',
    COUNT(*)
FROM stg.order_items
WHERE shipping_limit_date IS NOT NULL
  AND TRY_CONVERT(DATETIME2, shipping_limit_date) IS NULL

UNION ALL

SELECT
    'order_reviews.review_creation_date',
    COUNT(*)
FROM stg.order_reviews
WHERE review_creation_date IS NOT NULL
  AND TRY_CONVERT(DATETIME2, review_creation_date) IS NULL;
GO


-- 8. Order status distribution
SELECT
    order_status,
    COUNT(*) AS order_count,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(6, 2)
    ) AS percentage
FROM stg.orders
GROUP BY order_status
ORDER BY order_count DESC;
GO


-- 9. Invalid or suspicious values
SELECT
    'non_positive_item_price' AS quality_check,
    COUNT(*) AS issue_count
FROM stg.order_items
WHERE TRY_CONVERT(DECIMAL(18, 2), price) <= 0

UNION ALL

SELECT
    'negative_freight_value',
    COUNT(*)
FROM stg.order_items
WHERE TRY_CONVERT(DECIMAL(18, 2), freight_value) < 0

UNION ALL

SELECT
    'non_positive_payment_value',
    COUNT(*)
FROM stg.order_payments
WHERE TRY_CONVERT(DECIMAL(18, 2), payment_value) <= 0

UNION ALL

SELECT
    'review_score_outside_1_to_5',
    COUNT(*)
FROM stg.order_reviews
WHERE TRY_CONVERT(INT, review_score) NOT BETWEEN 1 AND 5

UNION ALL

SELECT
    'negative_product_weight',
    COUNT(*)
FROM stg.products
WHERE TRY_CONVERT(DECIMAL(18, 2), product_weight_g) < 0;
GO


-- 10. Date sequence checks
SELECT
    'approval_before_purchase' AS quality_check,
    COUNT(*) AS issue_count
FROM stg.orders
WHERE TRY_CONVERT(DATETIME2, order_approved_at)
    < TRY_CONVERT(DATETIME2, order_purchase_timestamp)

UNION ALL

SELECT
    'delivery_before_purchase',
    COUNT(*)
FROM stg.orders
WHERE TRY_CONVERT(DATETIME2, order_delivered_customer_date)
    < TRY_CONVERT(DATETIME2, order_purchase_timestamp)

UNION ALL

SELECT
    'customer_delivery_before_carrier_delivery',
    COUNT(*)
FROM stg.orders
WHERE TRY_CONVERT(DATETIME2, order_delivered_customer_date)
    < TRY_CONVERT(DATETIME2, order_delivered_carrier_date);
GO


-- 11. Customers and repeat purchasing
SELECT
    COUNT(*) AS customer_records,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS distinct_people
FROM stg.customers;
GO


-- 12. Products without English category translation
SELECT
    COUNT(*) AS products_without_translation
FROM stg.products AS p
LEFT JOIN stg.product_category_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL;
GO
-- Duplicate review IDs: identical and conflicting records
WITH duplicate_review_ids AS
(
    SELECT review_id
    FROM stg.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
SELECT TOP 100
    r.*
FROM stg.order_reviews AS r
INNER JOIN duplicate_review_ids AS d
    ON r.review_id = d.review_id
ORDER BY
    r.review_id,
    r.review_answer_timestamp;
GO


-- Number of exact duplicate review rows
SELECT
    SUM(record_count - 1) AS exact_duplicate_rows
FROM
(
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        COUNT(*) AS record_count
    FROM stg.order_reviews
    GROUP BY
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    HAVING COUNT(*) > 1
) AS exact_duplicates;
GO


-- Review IDs connected to more than one order
SELECT
    COUNT(*) AS review_ids_with_multiple_orders
FROM
(
    SELECT review_id
    FROM stg.order_reviews
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
) AS conflicting_reviews;
GO


-- Non-positive payments
SELECT *
FROM stg.order_payments
WHERE TRY_CONVERT(DECIMAL(18, 2), payment_value) <= 0
ORDER BY order_id, payment_sequential;
GO


-- Delivery sequence anomalies
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM stg.orders
WHERE TRY_CONVERT(DATETIME2, order_delivered_customer_date)
    < TRY_CONVERT(DATETIME2, order_delivered_carrier_date)
ORDER BY order_id;
GO


-- Products without an English category match
SELECT DISTINCT
    p.product_category_name
FROM stg.products AS p
LEFT JOIN stg.product_category_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
ORDER BY p.product_category_name;
GO