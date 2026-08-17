-- tests/assert_no_negative_product_margin.sql
select product_sku, margin_per_unit
from {{ ref('dim_products') }}
where margin_per_unit < 0