USE Marketplace360;
GO

-- Fact tablolarının kayıt seviyeleri ve anahtar kontrolü
SELECT
    (SELECT COUNT(*)
     FROM analytics.fact_orders) AS order_rows,

    (SELECT COUNT(DISTINCT order_id)
     FROM analytics.fact_orders) AS distinct_orders,

    (SELECT COUNT(*)
     FROM analytics.fact_order_items) AS order_item_rows,

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT
                order_id,
                order_item_id
            FROM analytics.fact_order_items
            GROUP BY
                order_id,
                order_item_id
        ) AS item_keys
    ) AS distinct_order_item_keys;
GO


-- Temel kalite ve iş kuralları
SELECT
    SUM(
        CASE
            WHEN gross_order_value <> item_value + freight_value
                THEN 1
            ELSE 0
        END
    ) AS order_value_mismatches,

    SUM(
        CASE
            WHEN is_delivery_sequence_valid = 0
                THEN 1
            ELSE 0
        END
    ) AS invalid_delivery_sequences,

    SUM(
        CASE
            WHEN has_conflicting_reviews = 1
                THEN 1
            ELSE 0
        END
    ) AS conflicting_review_orders,

    SUM(
        CASE
            WHEN has_non_positive_payment = 1
                THEN 1
            ELSE 0
        END
    ) AS non_positive_payment_orders,

    SUM(
        CASE
            WHEN item_count = 0
                THEN 1
            ELSE 0
        END
    ) AS orders_without_items,

    SUM(
        CASE
            WHEN payment_count = 0
                THEN 1
            ELSE 0
        END
    ) AS orders_without_payments
FROM analytics.fact_orders;
GO


-- Sipariş toplamı ile ödeme toplamı arasındaki fark
SELECT
    COUNT(*) AS orders_with_payment_difference,

    CAST(
        AVG(ABS(payment_value - gross_order_value))
        AS DECIMAL(18, 2)
    ) AS average_absolute_difference,

    CAST(
        MAX(ABS(payment_value - gross_order_value))
        AS DECIMAL(18, 2)
    ) AS maximum_absolute_difference
FROM analytics.fact_orders
WHERE ABS(payment_value - gross_order_value) > 0.01;
GO


-- Genel finansal toplamlar
SELECT
    CAST(SUM(item_value) AS DECIMAL(18, 2))
        AS total_item_value,

    CAST(SUM(freight_value) AS DECIMAL(18, 2))
        AS total_freight_value,

    CAST(SUM(gross_order_value) AS DECIMAL(18, 2))
        AS total_gross_order_value,

    CAST(SUM(payment_value) AS DECIMAL(18, 2))
        AS total_payment_value
FROM analytics.fact_orders;
GO


-- Ürün kategorisi kontrolleri
SELECT
    SUM(
        CASE
            WHEN category_name_english = 'unknown'
                THEN 1
            ELSE 0
        END
    ) AS unknown_category_products,

    SUM(
        CASE
            WHEN category_name_english IN
            (
                'pc_gamer',
                'kitchen_portables_and_food_preparers'
            )
                THEN 1
            ELSE 0
        END
    ) AS manually_translated_products
FROM analytics.dim_products;
GO


-- Analiz dönemi
SELECT
    MIN(full_date) AS start_date,
    MAX(full_date) AS end_date,
    COUNT(*) AS date_count
FROM analytics.dim_date;
GO