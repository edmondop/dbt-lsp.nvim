-- Customer dimension table

{{ config(materialized='table') }}

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customer_orders as (
    select
        customer_id,
        count(*) as total_orders,
        sum(total_amount) as lifetime_value
    from orders
    group by customer_id
)

select
    c.customer_id,
    c.customer_name,
    c.customer_email,
    c.created_at,
    coalesce(co.total_orders, 0) as total_orders,
    coalesce(co.lifetime_value, 0) as lifetime_value
from customers c
left join customer_orders co on c.customer_id = co.customer_id
