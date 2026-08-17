-- models/marts/dim_customers.sql
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
        min(ordered_at) as first_order_date,
        max(ordered_at) as most_recent_order_date,
        count(order_id) as number_of_orders,
        sum(order_total) as lifetime_value
    from orders
    group by customer_id
),
final as (
    select
        c.customer_id,
        c.customer_name,
        co.first_order_date,
        co.most_recent_order_date,
        coalesce(co.number_of_orders, 0) as number_of_orders,
        coalesce(co.lifetime_value, 0) as lifetime_value,
        case when co.number_of_orders > 1 then 'recurrent' else 'nouveau' end as customer_status
    from customers c
    left join customer_orders co on c.customer_id = co.customer_id
)
select * from final