-- models/marts/dim_products.sql
{{ config(materialized='table') }}

with products as (
    select * from {{ ref('stg_products') }}
),
supply_costs as (
    select * from {{ ref('int_product_supply_costs') }}
),
final as (
    select
        p.product_sku,
        p.product_name,
        p.product_type,
        p.product_price,
        coalesce(sc.total_supply_cost, 0) as total_supply_cost,
        p.product_price - coalesce(sc.total_supply_cost, 0) as margin_per_unit,
        coalesce(sc.number_of_supplies, 0) as number_of_supplies
    from products p
    left join supply_costs sc on p.product_sku = sc.product_sku
)
select * from final