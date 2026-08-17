-- models/marts/fct_orders.sql
{{ config(materialized='table') }}

with orders as (
    select * from {{ ref('stg_orders') }}
),
items as (
    select
        order_id,
        count(*) as number_of_items
    from {{ ref('stg_order_items') }}
    group by order_id
),
final as (
    select
        o.order_id,
        o.customer_id,
        o.store_id,
        o.ordered_at,
        o.subtotal,
        o.tax_paid,
        o.order_total,
        coalesce(i.number_of_items, 0) as number_of_items
    from orders o
    left join items i on o.order_id = i.order_id
)
select * from final