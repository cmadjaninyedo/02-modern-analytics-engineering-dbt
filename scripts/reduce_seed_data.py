import csv
from datetime import datetime, timedelta

INPUT_ORDERS = "seeds/raw_orders.csv"
OUTPUT_ORDERS = "seeds/raw_orders_reduced.csv"
INPUT_ITEMS = "seeds/raw_items.csv"
OUTPUT_ITEMS = "seeds/raw_items_reduced.csv"

DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

# --- Passe 1 : trouver la date la plus recente, sans tout charger en memoire ---
max_date = None
with open(INPUT_ORDERS, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        d = datetime.strptime(row["ordered_at"], DATE_FORMAT)
        if max_date is None or d > max_date:
            max_date = d

cutoff = max_date - timedelta(days=365)
print(f"Date la plus recente : {max_date}")
print(f"Date de coupure (1 an avant) : {cutoff}")

# --- Passe 2 : filtrer les commandes et ecrire au fur et a mesure ---
valid_order_ids = set()
kept_orders = 0
total_orders = 0

with open(INPUT_ORDERS, newline="", encoding="utf-8") as fin, \
     open(OUTPUT_ORDERS, "w", newline="", encoding="utf-8") as fout:
    reader = csv.DictReader(fin)
    writer = csv.DictWriter(fout, fieldnames=reader.fieldnames)
    writer.writeheader()
    for row in reader:
        total_orders += 1
        d = datetime.strptime(row["ordered_at"], DATE_FORMAT)
        if d >= cutoff:
            writer.writerow(row)
            valid_order_ids.add(row["id"])
            kept_orders += 1

print(f"Commandes : {kept_orders} conservees sur {total_orders}")

# --- Passe 3 : filtrer les items pour rester coherent avec les commandes gardees ---
kept_items = 0
total_items = 0

with open(INPUT_ITEMS, newline="", encoding="utf-8") as fin, \
     open(OUTPUT_ITEMS, "w", newline="", encoding="utf-8") as fout:
    reader = csv.DictReader(fin)
    writer = csv.DictWriter(fout, fieldnames=reader.fieldnames)
    writer.writeheader()
    for row in reader:
        total_items += 1
        if row["order_id"] in valid_order_ids:
            writer.writerow(row)
            kept_items += 1

print(f"Items : {kept_items} conserves sur {total_items}")
print("Termine.")