-- models/staging/jaffle_shop/stg_supplies.sql
with source as (
    select * from {{ source('jaffle_shop', 'raw_supplies') }}
),
renamed as (
    select
        id as supply_id,
        name as supply_name,
        cost as supply_cost,
        perishable as is_perishable_supply,
        sku as product_sku
    from source
)
select * from renamed