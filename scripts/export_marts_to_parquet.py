"""
Exporte les 5 data marts en fichiers Parquet pour connexion Power BI.
Usage : python scripts/export_marts_to_parquet.py
Prerequis : avoir execute `dbt build --profiles-dir .` au prealable.
"""
import duckdb
import os

os.makedirs("docs/exports", exist_ok=True)

con = duckdb.connect("warehouse/jaffle_shop.duckdb")

marts = ["dim_customers", "dim_products", "dim_stores", "fct_orders", "fct_order_items"]

for mart in marts:
    path = f"docs/exports/{mart}.parquet"
    con.execute(f"COPY {mart} TO '{path}' (FORMAT PARQUET)")
    print(f"Exporte : {path}")

print("Export termine.")
