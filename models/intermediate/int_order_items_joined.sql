-- models/intermediate/int_order_items_joined.sql
with order_items as (
    select * from {{ ref('stg_order_items') }}
),
products as (
    select * from {{ ref('stg_products') }}
),
supply_costs as (
    select * from {{ ref('int_product_supply_costs') }}
),
orders as (
    select * from {{ ref('stg_orders') }}
),
joined as (
    select
        oi.order_item_id,
        oi.order_id,
        o.customer_id,
        o.store_id,
        o.ordered_at,
        p.product_sku,
        p.product_name,
        p.product_type,
        p.product_price,
        coalesce(sc.total_supply_cost, 0) as product_cost,
        p.product_price - coalesce(sc.total_supply_cost, 0) as item_margin
    from order_items oi
    left join products p on oi.product_sku = p.product_sku
    left join supply_costs sc on oi.product_sku = sc.product_sku
    left join orders o on oi.order_id = o.order_id
)
select * from joined