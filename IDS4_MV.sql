---------------------------------------------------------------------------------
--=================== TO BE RUN FROM XHAJEK00s ACCOUNT ========================== 
---------------------------------------------------------------------------------

CREATE MATERIALIZED VIEW product_sales
BUILD IMMEDIATE
REFRESH ON DEMAND
AS
SELECT 
    tp.product_id,
    tp.name,
    tp.price,
    SUM(oi.quantity) AS total_sold,
    COUNT(DISTINCT oi.tOrder_id) AS total_orders
FROM xmervaj00.tProduct tp
LEFT JOIN xmervaj00.order_item oi ON tp.product_id = oi.product_id
GROUP BY tp.product_id, tp.name, tp.price;


SELECT * FROM product_sales
WHERE total_sold > 50
ORDER BY total_sold DESC;
