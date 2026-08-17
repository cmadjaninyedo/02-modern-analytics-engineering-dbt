-- models/staging/jaffle_shop/stg_order_items.sql
with source as (
    select * from {{ source('jaffle_shop', 'raw_items') }}
),
renamed as (
    select
        id as order_item_id,
        order_id,
        sku as product_sku
    from source
)
select * from renamed