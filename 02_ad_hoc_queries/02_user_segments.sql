-- ============================================================================
-- 02_user_segments.sql
-- Задача: разделение пользователей на сегменты
-- Витрина: product_user_features
-- ============================================================================

WITH user_total AS (
	SELECT 
		user_id,
-- суммарное количество заказов клиента по всем регионам:
		SUM(total_orders) AS total_orders_user,
-- суммарная стоимость всех его заказов:
		SUM(total_order_costs) AS total_order_costs_user
	FROM ds_ecom.product_user_features
	GROUP BY user_id
),
user_group AS (
SELECT 
	user_id,
	total_orders_user,
	total_order_costs_user,
	CASE
		WHEN total_orders_user='1' 
		THEN 'сегмент 1 заказ'
		WHEN total_orders_user BETWEEN 2 AND 5
		THEN 'сегмент 2-5 заказов'
		WHEN total_orders_user BETWEEN 6 AND 10
		THEN 'сегмент 6-10 заказов'
		ELSE 'сегмент 11 и более заказов'
	END AS segments	
FROM user_total
)
SELECT
	segments,
-- общее количество уникальных клиентов в сегменте:
	COUNT(*) AS count_users_segment,
-- среднее количество заказов на клиента в сегменте:
	ROUND(AVG(total_orders_user),0) AS avg_total_orders,
-- средняя стоимость заказа по клиентам в сегменте:
	ROUND((SUM(total_order_costs_user)/SUM(total_orders_user)),0) AS avg_total_order_costs
FROM user_group
GROUP BY segments
ORDER BY COUNT(*);
