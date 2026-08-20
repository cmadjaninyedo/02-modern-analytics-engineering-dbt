# Modern Analytics Engineering Platform (dbt + DuckDB)

Pipeline d'Analytics Engineering complet de la donnée brute au dashboard décisionnel, construit sur le dataset officiel **Jaffle Shop** (dbt Labs), un café fictif à 6 magasins.

## Problème métier

Un café en expansion (6 magasins, plusieurs années d'activité) dispose de données transactionnelles dispersées dans des exports CSV bruts, sans modèle de données gouverné, testé ni documenté. La direction ne peut répondre rapidement à des questions simples : quels produits sont les plus rentables ? Quels magasins sous-performent ? Quand l'activité ralentit-elle dans l'année ? Ce projet met en place une couche d'Analytics Engineering avec **dbt + DuckDB**, qui transforme les données brutes en indicateurs fiables, testés et exploitables dans un dashboard Power BI.

## Données

- **Source** : [Jaffle Shop](https://github.com/dbt-labs/jaffle-shop) (dbt Labs) — version moderne officielle à 6 tables, dataset de référence utilisé dans les cours dbt Learn.
- **Tables sources** : `raw_customers`, `raw_orders`, `raw_items`, `raw_products`, `raw_supplies`, `raw_stores`.
- **Volume** : le dataset source couvre plusieurs années (~2 millions de commandes). Pour garder le dépôt raisonnablement léger tout en conservant un volume représentatif, seules les commandes référencées dans `raw_items` ont été conservées (**530 395 commandes**, **770 017 lignes d'articles**), avec cohérence référentielle stricte vérifiée entre les deux tables. Cette décision est documentée dans le code (`scripts/reduce_seed_data.py`) et assumée comme un compromis reproductibilité/volumétrie plutôt que cachée.
- **Licence** : dataset synthétique, libre d'utilisation, fourni par dbt Labs à des fins pédagogiques.

## Choix technique : DuckDB plutôt que Snowflake

dbt + **DuckDB** est utilisé à la place de dbt + Snowflake, car le compte d'essai Snowflake expire après 30 jours, ce qui rendrait ce dépôt inutilisable pour un recruteur qui le clone après cette période. DuckDB est gratuit, local, pérenne, et de plus en plus employé en production comme en portfolio pour ce type de démonstration analytique. Snowflake reste la stack cible mentionnée pour un environnement d'entreprise à plus grande échelle.

## Architecture

```
Sources (seeds CSV : raw_customers, raw_orders, raw_items,
                      raw_products, raw_supplies, raw_stores)
        |
        v
      DuckDB (warehouse/jaffle_shop.duckdb — regenere via dbt build)
        |
        v
       dbt
   +----+--------+------------+
   |             |            |
staging     intermediate     marts
(6 modeles) (resolution sku,  (dim_customers, dim_products, dim_stores,
             calcul de marge)  fct_orders, fct_order_items)
        |
        v
     Power BI (connecte uniquement aux marts)
```

Voir `docs/lineage_graph.png` pour le graphe de lignage complet généré par `dbt docs generate`.

**Modèle en étoile** : 3 dimensions (`dim_customers`, `dim_products`, `dim_stores`) et 2 tables de faits (`fct_orders` au grain commande, `fct_order_items` au grain ligne d'article), reliées par 4 relations simples sans chemin de filtrage ambigu.

## Technologies

`dbt-core` · `dbt-duckdb` · `DuckDB` · `dbt-utils` · `Python` (réduction/export de données) · `Git/GitHub` · `Power BI`

## Tests et qualité de données

- **26 tests** exécutés à chaque `dbt build` : `not_null` et `unique` sur toutes les clés primaires (staging et marts), `relationships` entre toutes les tables de faits et leurs dimensions, `dbt_utils.accepted_range` pour garantir qu'aucune commande n'a de montant négatif, et un test singulier SQL personnalisé (`assert_no_negative_product_margin`).
- **Résultat** : `dbt build` → **35 modèles/seeds/tests exécutés, 0 échec**.
- **Une hypothèse de test corrigée en cours de route** : un premier test d'unicité `(order_id, product_sku)` supposait qu'une commande ne contient qu'un seul exemplaire de chaque produit. Le lancer sur les données réelles a révélé jusqu'à 5 exemplaires du même produit dans une seule commande (achat groupé), le test a été retiré au profit d'un contrôle plus fidèle à la réalité métier (`order_total >= 0`). Cet ajustement illustre le rôle des tests comme outil de découverte autant que de validation.

## Documentation

- Documentation générée via `dbt docs generate` / consultable en local via `dbt docs serve --profiles-dir .`
- Graphe de lignage complet (6 sources → 6 staging → 2 intermediate → 5 marts) : `docs/lineage_graph.png`

## Résultats clés

| Indicateur | Valeur |
|---|---|
| Clients | 3 102 |
| Commandes (1 an) | 530 395 |
| Articles vendus | 770 017 |
| Chiffre d'affaires total | 5 724 969,06 \$ |
| Panier moyen | 10,79 \$ |
| Marge brute totale générée | 4 291 820,38 \$ |
| Marge moyenne par article vendu | 5,57 \$ |
| Taux de marge brute | ~79 % |
| Magasins | 6 (Brooklyn, Chicago, Los Angeles, New Orleans, Philadelphia, San Francisco) |

**Insights tirés du dashboard :**

1. **Saisonnalité marquée** : le CA mensuel chute fortement en juillet (377 530 \$, point bas de l'année) et remonte en fin d'année (541 563 \$ en décembre), un signal exploitable pour anticiper les besoins en stock et en personnel.
2. **Effet jour de semaine inattendu** : le volume de commandes est stable et élevé du lundi au vendredi (~915-926K \$ chacun) mais chute d'environ 38 % le week-end (~565-574K \$), cohérent avec une clientèle de bureau plutôt que de loisir, un point à vérifier avec le métier avant d'en tirer une action commerciale.
3. **Le volume prime sur la marge unitaire pour le CA produit** : le produit générant le plus de chiffre d'affaires (`for richer or pourover`, une boisson à 7 \$, 835 660 \$ de CA) n'est pas celui à la marge unitaire la plus élevée (`flame impala`, un jaffle à 14 \$, 10,57 \$ de marge/unité), un rappel que prioriser la marge par produit sans regarder le volume peut être trompeur.
4. **Disparité de performance entre magasins** : Brooklyn génère 1,29M \$ de CA (75 % de plus que Los Angeles, le magasin le plus faible à 737K \$), sans corrélation évidente avec le taux de taxe local (Brooklyn a le 2e taux le plus bas à 4 %, Los Angeles le taux le plus haut à 8 %), suggère que la performance dépend davantage de facteurs locaux (emplacement, ancienneté, affluence) que de la fiscalité.
5. **Segmentation client peu discriminante en l'état** : avec ~171 commandes par client en moyenne sur l'année, 99,94 % des clients sont classés "récurrent" par la définition actuelle (>1 commande), une segmentation par quartile de fréquence ou de valeur serait plus informative en conditions réelles.

## Structure du dépôt

```
02-modern-analytics-engineering-dbt/
|-- README.md
|-- profiles.yml
|-- dbt_project.yml
|-- packages.yml
|-- requirements.txt
|-- notebooks/
|   `-- 01_exploration.ipynb
|-- scripts/
|   |-- reduce_seed_data.py
|   `-- export_marts_to_parquet.py
|-- seeds/
|   |-- raw_customers.csv
|   |-- raw_orders.csv          (reduit a ~1 an, voir ci-dessus)
|   |-- raw_items.csv           (reduit en coherence avec raw_orders)
|   |-- raw_products.csv
|   |-- raw_supplies.csv
|   `-- raw_stores.csv
|-- models/
|   |-- staging/jaffle_shop/    (6 modeles + sources + tests)
|   |-- intermediate/           (2 modeles : couts et marge)
|   `-- marts/                  (3 dimensions + 2 tables de faits)
|-- macros/
|   `-- cents_to_dollars.sql
|-- tests/
|   `-- assert_no_negative_product_margin.sql
|-- docs/
|   |-- lineage_graph.png
|   |-- dashboard.pbix
|   `-- exports/                (Parquet des dimensions ; fct_* regeneres via script)
`-- screenshots/
```

## Comment reproduire

```bash
python -m venv venv && source venv/bin/activate   # Windows : venv\Scripts\activate
pip install -r requirements.txt
dbt deps --profiles-dir .
dbt build --profiles-dir .
dbt docs generate --profiles-dir . && dbt docs serve --profiles-dir .
python scripts/export_marts_to_parquet.py
```

Ouvre ensuite `docs/dashboard.pbix` dans Power BI Desktop, ou reconstruis le dashboard en connectant Power BI aux fichiers Parquet générés dans `docs/exports/` (voir README section "Connexion Power BI" du guide de réalisation pour le détail).

## Certification

dbt Fundamentals (dbt Labs) — obtenue en parallèle de ce projet.

## Auteur

Crespino Marius ADJANINYEDO — [ linkedin.com/in/cm-adjaninyedo] — [Email: cmadjaninyedo1@gmail.com]