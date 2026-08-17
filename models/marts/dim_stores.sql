-- models/marts/dim_stores.sql
{{ config(materialized='table') }}

with stores as (
    select * from {{ ref('stg_stores') }}
),
orders as (
    select * from {{ ref('stg_orders') }}
),
store_orders as (
    select
        store_id,
        count(order_id) as number_of_orders,
        sum(order_total) as total_revenue
    from orders
    group by store_id
),
final as (
    select
        s.store_id,
        s.store_name,
        s.opened_at,
        s.tax_rate,
        coalesce(so.number_of_orders, 0) as number_of_orders,
        coalesce(so.total_revenue, 0) as total_revenue
    from stores s
    left join store_orders so on s.store_id = so.store_id
)
select * from final