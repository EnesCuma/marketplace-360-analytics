USE Marketplace360;
GO

-- 1. Ürün satırı bulunmayan siparişlerin durumları
SELECT
    order_status,
    COUNT(*) AS orders_without_items
FROM analytics.fact_orders
WHERE item_count = 0
GROUP BY order_status
ORDER BY orders_without_items DESC;
GO


-- 2. Ödeme kaydı bulunmayan sipariş
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    item_count,
    gross_order_value,
    payment_count,
    payment_value
FROM analytics.fact_orders
WHERE payment_count = 0;
GO


-- 3. Sipariş tutarı ile ödeme tutarı farklı olan kayıtların durumları
SELECT
    order_status,
    COUNT(*) AS orders_with_payment_difference,

    SUM(
        CASE
            WHEN item_count = 0 THEN 1
            ELSE 0
        END
    ) AS orders_without_items,

    CAST(
        AVG(ABS(payment_value - gross_order_value))
        AS DECIMAL(18, 2)
    ) AS average_absolute_difference,

    CAST(
        MAX(ABS(payment_value - gross_order_value))
        AS DECIMAL(18, 2)
    ) AS maximum_absolute_difference
FROM analytics.fact_orders
WHERE ABS(payment_value - gross_order_value) > 0.01
GROUP BY order_status
ORDER BY orders_with_payment_difference DESC;
GO


-- 4. Ödeme farklarının büyüklük dağılımı
WITH payment_differences AS
(
    SELECT
        ABS(payment_value - gross_order_value) AS absolute_difference
    FROM analytics.fact_orders
    WHERE ABS(payment_value - gross_order_value) > 0.01
)
SELECT
    CASE
        WHEN absolute_difference <= 1
            THEN '0.01 - 1.00'
        WHEN absolute_difference <= 10
            THEN '1.01 - 10.00'
        WHEN absolute_difference <= 100
            THEN '10.01 - 100.00'
        WHEN absolute_difference <= 500
            THEN '100.01 - 500.00'
        ELSE 'More than 500'
    END AS difference_range,

    COUNT(*) AS order_count,

    CAST(
        AVG(absolute_difference)
        AS DECIMAL(18, 2)
    ) AS average_difference
FROM payment_differences
GROUP BY
    CASE
        WHEN absolute_difference <= 1
            THEN '0.01 - 1.00'
        WHEN absolute_difference <= 10
            THEN '1.01 - 10.00'
        WHEN absolute_difference <= 100
            THEN '10.01 - 100.00'
        WHEN absolute_difference <= 500
            THEN '100.01 - 500.00'
        ELSE 'More than 500'
    END
ORDER BY
    MIN(absolute_difference);
GO


-- 5. Teslim edilmiş siparişlerde ödeme farkı
SELECT
    COUNT(*) AS delivered_orders_with_difference,

    CAST(
        AVG(ABS(payment_value - gross_order_value))
        AS DECIMAL(18, 2)
    ) AS average_absolute_difference,

    CAST(
        MAX(ABS(payment_value - gross_order_value))
        AS DECIMAL(18, 2)
    ) AS maximum_absolute_difference,

    CAST(
        SUM(payment_value - gross_order_value)
        AS DECIMAL(18, 2)
    ) AS net_payment_difference
FROM analytics.fact_orders
WHERE order_status = 'delivered'
  AND ABS(payment_value - gross_order_value) > 0.01;
GO


-- 6. En büyük ödeme farkına sahip siparişler
SELECT TOP 25
    order_id,
    order_status,
    item_count,
    gross_order_value,
    payment_value,

    CAST(
        payment_value - gross_order_value
        AS DECIMAL(18, 2)
    ) AS payment_difference,

    primary_payment_type,
    payment_count,
    has_non_positive_payment
FROM analytics.fact_orders
WHERE ABS(payment_value - gross_order_value) > 0.01
ORDER BY
    ABS(payment_value - gross_order_value) DESC;
GO