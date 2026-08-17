-- models/intermediate/int_product_supply_costs.sql
with supplies as (
    select * from {{ ref('stg_supplies') }}
),
aggregated as (
    select
        product_sku,
        sum(supply_cost) as total_supply_cost,
        sum(case when is_perishable_supply then supply_cost else 0 end) as perishable_cost,
        sum(case when not is_perishable_supply then supply_cost else 0 end) as non_perishable_cost,
        count(*) as number_of_supplies
    from supplies
    group by product_sku
)
select * from aggregated