-- ============================================================================
-- 03_user_rang.sql
-- Задача: ранжирование пользователей
-- Витрина: product_user_features
-- ============================================================================

WITH rank_table AS (
SELECT
	CASE
        WHEN avg_order_cost IS NOT NULL
        THEN ROW_NUMBER() OVER (ORDER BY avg_order_cost DESC)
        ELSE NULL
    END AS avg_order_cost_rank,
    *
FROM ds_ecom.product_user_features
)
SELECT *
FROM rank_table
WHERE total_orders>=3
ORDER BY avg_order_cost DESC
LIMIT 15;
