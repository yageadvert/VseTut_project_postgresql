-- ============================================================================
-- 01_data_mart.sql
-- Задача: создание витрины данных
-- Витрина: product_user_features
-- ============================================================================

CREATE TABLE product_user_features AS
-- Шаг 1. Сбор информации о заказах каждого клиента:
-- Первый тип оплаты, наличие промокода и рассрочки по уникальным заказам из order_payments:
WITH step1_payments AS (
SELECT
	order_id,
-- тип оплаты первого заказа:
	MIN(
		CASE 
			WHEN payment_sequential =1 
			THEN payment_type
		END
		) AS first_payment_type,
-- поле-признак, указывающее использовался ли при оплате заказа промокод (1 - использовался, 0 - нет)
	    CASE
	    	WHEN COUNT(*) FILTER (WHERE payment_type = 'промокод') > 0 
	    	THEN 1
	        ELSE 0
	    END AS used_promo,
-- поле-признак, указывающее использовалась ли при оплате заказа рассрочка (1 - использовалась, 0 - нет)	    
	    CASE
	        WHEN COUNT(*) FILTER (WHERE payment_installments > 1) > 0
	        THEN 1
	        ELSE 0
	    END AS used_installments
	FROM ds_ecom.order_payments
	GROUP BY order_id
),
-- Шаг 2.
-- Для каждого доставленного заказа считается стоимость по данным из order_items:
step2_orders AS (
	SELECT 
		order_id, 
		SUM(price+delivery_cost) AS total_cost 
	FROM ds_ecom.order_items
	JOIN ds_ecom.orders USING(order_id)
	WHERE order_status IN ('Доставлено')
	GROUP BY order_id
),
-- Шаг 3. 
-- Средний рейтинг для каждого заказа из order_reviews:
step3_ratings AS (
    SELECT
        order_id,
        AVG(
            CASE
                WHEN review_score BETWEEN 10 AND 50 THEN review_score / 10.0
                ELSE review_score::numeric
            END
        ) AS avg_order_rating
    FROM ds_ecom.order_reviews
    GROUP BY order_id
),
-- Шаг 4.
-- Топ3 регионов по количеству заказов и статусам:
step4_top_regions AS (
    SELECT
        u.region
    FROM ds_ecom.users u
    JOIN ds_ecom.orders o USING(buyer_id)
    WHERE o.order_status IN ('Доставлено', 'Отменено')
    GROUP BY u.region
    ORDER BY COUNT(o.order_id) DESC
    LIMIT 3
 ),
-- Объединенные три CTE и добавленные из orders необходимые для дальнейших расчетов поля:
step4_main_orders AS (
SELECT
	o.order_id,			--ds_ecom.orders
	o.buyer_id,			--ds_ecom.orders
	o.order_status,		--ds_ecom.orders
	o.order_purchase_ts,--ds_ecom.orders
	first_payment_type, --step1
	used_promo,			--step1
	used_installments,	--step1
	total_cost,			--step2
	avg_order_rating	--step3
FROM ds_ecom.orders o
LEFT JOIN step1_payments s1 ON o.order_id = s1.order_id
LEFT JOIN step2_orders o2 ON o.order_id = o2.order_id
LEFT JOIN step3_ratings s3 ON o.order_id = s3.order_id
WHERE o.order_status IN ('Доставлено', 'Отменено')
)
-- Финальная витрина:
SELECT
    u.user_id,
    tr.region,
-- Дата первого заказ клиента:
    MIN(mo.order_purchase_ts) AS first_order_ts,
-- Дата последнего заказа клиента:
    MAX(mo.order_purchase_ts) AS last_order_ts,
-- Разница между датой первого и последнего заказов:
    (MAX(mo.order_purchase_ts) - MIN(mo.order_purchase_ts)) AS lifetime_days,
-- Количество заказов:
    COUNT(mo.order_id) AS total_orders,
-- Средняя оценка, которую пользователь выставляет своим заказам (если отзывов не было - значение 0):
    AVG(mo.avg_order_rating) FILTER (WHERE mo.avg_order_rating IS NOT NULL) AS avg_order_score,
-- Количество заказов, для которых получена оценка с рейтингом:
    COUNT(mo.order_id) FILTER (WHERE mo.avg_order_rating IS NOT NULL) AS num_orders_with_rating,
-- Количество отмененных заказов:    
    COUNT(mo.order_id) FILTER (WHERE mo.order_status = 'Отменено') AS num_canceled_orders,
-- Доля отмененных заказов:
    COUNT(mo.order_id) FILTER (WHERE mo.order_status = 'Отменено')::numeric /
        NULLIF(COUNT(mo.order_id), 0) AS canceled_orders_ratio,
-- Суммарная стоимость всех доставленных пользователю заказов:
    SUM(mo.total_cost) AS total_order_costs,
-- Средняя стоимость заказа:
    AVG(mo.total_cost) AS avg_order_cost,
-- Количество заказов, оплаченных в рассрочку:
    COUNT(mo.order_id) FILTER (WHERE mo.used_installments = 1) AS num_installment_orders,
-- Количество заказов, купленных с использованием промокодов для оплаты:
    COUNT(mo.order_id) FILTER (WHERE mo.used_promo = 1) AS num_orders_with_promo,
-- Использовал ли клиент денежный перевод хотя бы один раз в качестве первого типа оплаты ( 1 — использовал, 0 — не использовал):
    MAX(CASE WHEN mo.first_payment_type = 'денежный перевод' THEN 1 ELSE 0 END) AS used_money_transfer,
-- Использовал ли клиент рассрочку хотя бы один раз ( 1 — использовал, 0 — не использовал):
    MAX(mo.used_installments) AS used_installments,
-- Отменял ли клиент хотя бы один заказ ( 1 — отменял, 0 — не отменял):
    MAX(CASE WHEN mo.order_status = 'Отменено' THEN 1 ELSE 0 END) AS used_cancel
FROM ds_ecom.users u
JOIN step4_top_regions tr USING(region)
JOIN step4_main_orders mo USING(buyer_id)
GROUP BY u.user_id, tr.region;