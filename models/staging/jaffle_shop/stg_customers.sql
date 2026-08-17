-- models/staging/jaffle_shop/stg_customers.sql
with source as (
    select * from {{ source('jaffle_shop', 'raw_customers') }}
),
renamed as (
    select
        id as customer_id,
        name as customer_name
    from source
)
select * from renamed