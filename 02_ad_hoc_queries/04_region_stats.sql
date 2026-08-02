-- ============================================================================
-- 04_region_stats.sql
-- Задача: статистика по регионам 
-- Витрина: product_user_features
-- ============================================================================

SELECT
	region,
-- общее число клиентов:
	COUNT(user_id) AS count_users,
-- общее число заказов:
	SUM(total_orders) AS sum_orders,
-- средняя стоимость одного заказа:
	ROUND(AVG(avg_order_cost),0) AS avg_order_cost,
-- доля заказов, которые были куплены в рассрочку:
	ROUND((SUM(num_installment_orders)/SUM(total_orders))*100,2)||'%' AS ratio_installment_orders,
-- доля заказов, которые были куплены с использованием промокодов:
	ROUND((SUM(num_orders_with_promo)/SUM(total_orders))*100,2)||'%' AS ratio_promo_orders,
-- доля пользователей, совершивших отмену заказа хотя бы один раз:
	ROUND(AVG(used_cancel)*100,2)|| '%' AS ratio_canceled_users
FROM ds_ecom.product_user_features
GROUP BY region
ORDER BY COUNT(user_id);