-- ============================================================================
-- 05_monthly_activity.sql
-- Задача: Активность пользователей в 2023 г.  
-- Витрина: product_user_features
-- ============================================================================

set lc_time = 'ru_RU';
WITH prog1 AS (
SELECT 
	TO_CHAR(first_order_ts, 'TMmonth') AS months,
	user_id,
	total_orders,
	avg_order_cost,
	avg_order_rating,
	used_money_transfer,
	lifetime,
	first_order_ts
FROM ds_ecom.product_user_features
WHERE EXTRACT(YEAR FROM first_order_ts)=2023
),
-- агрегация по клиенту:
group_user AS (
SELECT 
	months,
-- общее количество клиентов:
	user_id,
-- число заказов:
	SUM(total_orders) AS total_orders_user_month,
-- средняя стоимость одного заказа:
	ROUND(AVG(avg_order_cost),0) AS avg_order_cost_user_month,
-- средний рейтинг:
	ROUND(AVG(avg_order_rating),2) AS avg_order_rating_user_month,
-- доля пользователей, использующих денежные переводы при оплате:
	ROUND(SUM(used_money_transfer)::NUMERIC/COUNT(user_id),4) AS used_money_transfer_user_month,
-- средняя продолжительность активности пользователя:
	AVG(lifetime) AS lifetime_user_month,
	first_order_ts
FROM prog1
GROUP BY months, user_id, 	first_order_ts
)
SELECT
    months,
    -- общее количество уникальных клиентов в месяце:
    COUNT(user_id) AS count_users,
    -- суммарное число заказов клиентов в этом месяце:
    SUM(total_orders_user_month) AS sum_orders,
    -- средняя стоимость одного заказа по клиентам:
    ROUND(AVG(avg_order_cost_user_month), 0) AS avg_cost,
    -- средний рейтинг по клиентам:
    ROUND(AVG(avg_order_rating_user_month), 2) AS avg_rating,
    -- доля клиентов, использовавших денежный перевод хотя бы один раз:
    ROUND((SUM(used_money_transfer_user_month)::NUMERIC / COUNT(user_id))*100, 2)||'%' AS ratio_transfer,
    -- средняя продолжительность активности клиента:
    AVG(lifetime_user_month) AS avg_lifetime
FROM group_user
GROUP BY months
ORDER BY EXTRACT(MONTH FROM MIN(first_order_ts));