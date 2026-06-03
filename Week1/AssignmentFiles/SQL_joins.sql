USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.

select p.name, c.name from products p
join categories c on p.category_id=c.category_id;

-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.

select o.order_id, o.order_datetime, s.name as store_name, p.name as product_name, oi.quantity, oi.quantity * p.price as line_total  from 
orders o 
join order_items oi on o.order_id=oi.order_id
join products p on p.product_id=oi.product_id
join stores s on s.store_id=o.store_id
order by o.order_datetime,o.order_id;

-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
select concat(c.last_name,', ', c.first_name),s.name, o.order_datetime, SUM(quantity * p.price) as order_total
from orders o
join order_items oi on oi.order_id=o.order_id
join products p on p.product_id=oi.product_id
join customers c on c.customer_id=o.customer_id
join stores s on s.store_id=o.store_id
group by concat(c.last_name,', ', c.first_name),s.name, o.order_datetime;

-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
select c.last_name, c.first_name, c.city, c.state, order_id from customers c
left join orders o on c.customer_id=o.customer_id
where order_id is null;

-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.

with product_sales AS (
    SELECT 
	s.name as store_name,
	p.name as product_name,
	sum(quantity) AS total_units
    from orders o
    join order_items oi on oi.order_id=o.order_id
    join stores s ON o.store_id = s.store_id
    join products p ON oi.product_id = p.product_id
    where o.status = 'paid'
    group by s.name,
        p.name
),
ranked  AS (
    select 
        store_name,
        product_name,
        total_units,
        row_number() over (partition by store_name order by total_units desc) as ranking
    from product_sales
)
select
    store_name,product_name,total_units
from ranked
WHERE ranking = 1;


-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
select s.name as store_name, p.name as product_name, on_hand 
from inventory i
join stores s on i.store_id=s.store_id
join products p on p.product_id=i.product_id
where on_hand < 12;

-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').

select e.first_name,e.last_name, hire_date,title from stores s
join employees e on s.store_id=e.store_id where title='Manager';

-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.

with p_revenue as (
    select
        p.name as product_name,
        sum(oi.quantity * p.price) AS total_revenue
    from products p
    join order_items oi on p.product_id = oi.product_id 
	join orders o on o.order_id = oi.order_id
    where o.status = 'paid'
    group by p.name
)
select 
    product_name,
    total_revenue
from p_revenue
where total_revenue > (select avg(total_revenue) from p_revenue);

-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
select c.customer_id,concat(c.first_name,', ', last_name) as customer_name, max(o.order_datetime) AS last_paid_order_date
from customers c
left join orders o 
    on c.customer_id = o.customer_id 
    and o.status = 'paid' 
group by c.customer_id, concat(c.first_name,', ', last_name);

-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price))
select s.name as store_name,c.name as category_name,p.name as product_name, SUM(quantity * p.price) as total_revenue from 
stores s
join orders o on o.store_id=s.store_id
join order_items oi on oi.order_id=o.order_id
join products p on oi.product_id=p.product_id
join categories c on p.category_id=c.category_id
where status ='paid'
group by s.name ,c.name ,p.name
