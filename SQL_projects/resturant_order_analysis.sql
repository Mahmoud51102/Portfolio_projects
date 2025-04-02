/*EXPLORING THE MENU_ITEMS TABLE*/
SELECT *
FROM menu_items;

/*the number of items in the menu*/
SELECT COUNT(*) 
FROM menu_items;

/*the cheapest item*/
SELECT *
FROM menu_items
ORDER BY price
LIMIT 1;

/*the most expensive item*/
SELECT *
FROM menu_items
ORDER BY price DESC
LIMIT 1;

/*the number of the italian food on the menu*/
SELECT COUNT(*) AS italian_count
FROM menu_items
WHERE category LIKE '%Italian%';

/*the cheapest italian dish on the menu*/
SELECT *
FROM menu_items
WHERE category = 'Italian'
ORDER BY price;

/*the most expensive italian dish on the menu*/
SELECT *
FROM menu_items
WHERE category = 'Italian'
ORDER BY price DESC;

/*how many dishes in each category*/
SELECT category, COUNT(*) AS num_dishes
FROM menu_items
GROUP BY category;

/*what is the average dish price for each category*/
SELECT category, ROUND(AVG(price),2) AS avg_price
FROM menu_items
GROUP BY category;
/*-------------------------------------------------------------------------------------------------*/

/*EXPLORING THE ORDER_DETAILS TABLE*/
SELECT *
FROM order_details;

/*what is the date range of the table*/
SELECT MIN(order_date), MAX(order_date)
FROM order_details;

/*how many orders were made within this date range*/
SELECT COUNT(DISTINCT order_id)
FROM order_details;

/*how many items were ordered within this date range*/
SELECT COUNT(*)
FROM order_details;

/*which orders have the most number of items*/
SELECT order_id, COUNT(item_id) AS num_items
FROM order_details
GROUP BY order_id
ORDER BY num_items DESC;

/*how many orders have more than 12 items*/
WITH items_cte AS (
	SELECT order_id, COUNT(item_id) AS num_items
	FROM order_details
	GROUP BY order_id
	HAVING COUNT(item_id) > 12
)
SELECT COUNT(*) AS num_orders_over_12_items
FROM items_cte;
/*-----------------------------------------------------------------------------------*/

/*ANALYZE CUSTOMER BEHAVIOR*/

/*combine the 2 tables*/
SELECT *
FROM order_details AS od
LEFT JOIN menu_items AS mi
	ON od.item_id = mi.menu_item_id;
 
/*what is the most ordered item name and in which category*/
SELECT item_name, category, COUNT(*) AS num_orders
FROM order_details AS od
LEFT JOIN menu_items AS mi
	ON od.item_id = mi.menu_item_id
GROUP BY item_name, category
ORDER BY num_orders DESC;

/*what are the top 5 orders that spent the most money*/
SELECT order_id, SUM(price) total_price
FROM order_details AS od
LEFT JOIN menu_items AS mi
	ON od.item_id = mi.menu_item_id
GROUP BY order_id
ORDER BY total_price DESC
LIMIT 5;

/*the details of the highest spend order*/
With total_price_cte AS (
	SELECT order_id, SUM(price) total_price
	FROM order_details AS od
	LEFT JOIN menu_items AS mi
		ON od.item_id = mi.menu_item_id
	GROUP BY order_id
	
), ranking_cte AS (
SELECT order_details_id, od.order_id, order_date, order_time,
	   item_id,
	   DENSE_RANK() OVER (ORDER BY total_price DESC) ranking
FROM order_details AS od
LEFT JOIN total_price_cte AS tcp
	ON od.order_id = tcp.order_id
)
SELECT *
FROM ranking_cte AS rc
LEFT JOIN menu_items AS mi
	ON rc.item_id = mi.menu_item_id
WHERE ranking = 1;

/*now I copied the previous CTEs because I am going to view the details of the top 5 highest spend orders this time*/
With total_price_cte AS (
	SELECT order_id, SUM(price) total_price
	FROM order_details AS od
	LEFT JOIN menu_items AS mi
		ON od.item_id = mi.menu_item_id
	GROUP BY order_id
	
), ranking_cte AS (
SELECT order_details_id, od.order_id, order_date, order_time,
	   item_id,
	   DENSE_RANK() OVER (ORDER BY total_price DESC) ranking
FROM order_details AS od
LEFT JOIN total_price_cte AS tcp
	ON od.order_id = tcp.order_id
)
SELECT *
FROM ranking_cte AS rc
LEFT JOIN menu_items AS mi
	ON rc.item_id = mi.menu_item_id
WHERE ranking <= 5; -- this assure that we will query the top 5 highest spend orders