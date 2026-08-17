-- models/marts/fct_order_items.sql
{{ config(materialized='table') }}

select
    order_item_id,
    order_id,
    customer_id,
    store_id,
    ordered_at,
    product_sku,
    product_name,
    product_type,
    product_price,
    product_cost,
    item_margin
from {{ ref('int_order_items_joined') }}