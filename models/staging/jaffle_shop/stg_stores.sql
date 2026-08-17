-- models/staging/jaffle_shop/stg_stores.sql
with source as (
    select * from {{ source('jaffle_shop', 'raw_stores') }}
),
renamed as (
    select
        id as store_id,
        name as store_name,
        opened_at,
        tax_rate
    from source
)
select * from renamed