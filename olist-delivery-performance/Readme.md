# Delivery Performance & Review Impact Analysis

An end-to-end analytics project on a Brazilian e-commerce marketplace: a hand-built Kimball star schema in SQL Server feeding a three-page Power BI dashboard that diagnoses where late delivery hurts customer satisfaction, where it concentrates, and whose fault it actually is.

## Objective

Late deliveries affect roughly 8% of orders on this marketplace, and those orders average **2.6 review stars against 4.3 for on-time orders** — a near-full collapse in customer satisfaction, not a mild dip. This project identifies where that damage concentrates by seller, category, and region, weights it by revenue so effort goes where money is actually at risk, and separates seller-caused delay from carrier-caused delay so the right party is held accountable.

Framed for a Head of Marketplace Operations who needs to know *where* to focus and *whose* fault the lateness is — not just that delivery is a problem.

## Key Findings

- **Late orders average 2.6 stars vs 4.3 for on-time** — late delivery is associated with a ~1.7-point satisfaction drop for the majority of affected customers.
- **8.11% of delivered orders arrive late** (89K early / on-time vs 8K late out of ~96K delivered orders).
- **Only ~27% of late deliveries are seller-caused** (seller missed their shipping-limit deadline). The other **~73% stem from carrier transit time** — which redirects the operational focus from seller coaching toward logistics. Seller SLA miss rate is 9.04%, close to but distinct from the final late rate, confirming seller and carrier delay are related but separate problems.
- **Northeastern states are dramatically worse** (Alagoas ~24%, Maranhão ~19% late) than the rest of Brazil, consistent with distance from the São Paulo seller base — and the two-leg split shows this is transit-driven, i.e. a distance problem rather than a seller-behavior one.
- **Late rate deteriorates through late 2017 into 2018** after being stable earlier, and the trend split shows the deterioration is carrier-transit-driven (peaking ~13 days in early 2018).

## Data Source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle). ~99,000 orders placed September 2016 – October 2018, across 9 raw tables (orders, order items, customers, sellers, products, payments, reviews, geolocation, category translation).

Raw CSVs are not committed to this repo (see `.gitignore`) — download from the link above.

## Architecture

Three-layer build in a single SQL Server database:

- **`stg` schema** — raw tables imported as-is via the SSMS Import Flat File wizard; untouched source of truth. (Script `01` is intentionally skipped: the raw load was done through the GUI wizard, not a script.)
- **`dw` schema** — Kimball star schema built by hand with T-SQL, one script per table.
- **Reporting layer** — Power BI (Import mode) over the `dw` schema, DAX measures, three report pages.

### Star Schema

**Fact table:** `Fact_OrderItem` — grain = one row per order item; population = delivered orders only with valid delivery and carrier dates (~110,188 item rows from ~96,470 delivered orders).

**Dimensions:**
- `Dim_Date` — generated date spine, smart key (`YYYYMMDD`), marked as the model's official date table.
- `Dim_Customer` — deduplicated to one row per real person (`customer_unique_id`), identity only. Considered treating as a degenerate dimension; kept as its own table for cheaper customer counts.
- `Dim_Product` — English category names joined from the translation table.
- `Dim_Seller` — one row per seller; links to geography.
- `Dim_Geography` — conformed dimension shared by customers and sellers, sourced from the geolocation table, one row per zip prefix.

**Keys:** surrogate keys (`_SK`) via `IDENTITY` throughout, natural keys (`_NK`) kept alongside. `Dim_Date` is the standard exception, using a smart `YYYYMMDD` key. Degenerate dimensions (`Order_NK`, `OrderItem_NK`) kept directly on the fact.

**Computed fact columns:** delivery delay (actual vs estimated), is-late flag, seller handoff days (purchase → carrier), carrier transit days (carrier → customer), seller-missed-SLA flag (handoff vs shipping-limit date), and pre-aggregated average review score per order.

## Key Design Decisions

- **Geography keyed on zip prefix, not city name.** City is free text and inconsistent in the source data (embedded state codes like `sao paulo - sp`, hyphen/space variants, accents, and at least one row containing an email address in the seller data). Zip prefix is the reliable key; State is used for regional analysis; City is retained for reference only. One prefix can legitimately span multiple towns (Brazilian zip prefixes are broad), so dedup is on the full key.
- **Customer address treated as an order attribute, not a customer attribute.** 252 customers show different addresses across orders, so address lives at the order/geography level rather than being forced onto a single "representative" customer row.
- **Category near-duplicates cleaned in Power Query** (e.g. `home_confort` merged into `home_comfort`).
- **Validation before constraints.** A validation script confirms zero orphaned keys, row-count reconciliation, null rates within documented bounds, and measure sanity — run *before* adding FK constraints (which would fail on orphans) and indexes.
- **FK constraints and indexes added after load** rather than before — standard warehouse practice to keep bulk load fast. Non-clustered indexes on the fact's FK columns plus a covering index on the late-order flag.

## Known Data Quality Notes

- ~1,339 of ~1M geolocation rows have null lat/long from an import precision mismatch.
- ~623 of ~32,951 products (1.9%) have no English category translation.
- Product category names contain near-duplicate variants in the source (merged where found).
- Seller `city` field contains non-city values in some rows (e.g. an email address) — one reason zip prefix, not city, is the geography key.
- The dataset starts thin in late 2016 (very low order volume), producing a misleading 100% late rate in the first month; trend views are read from 2017 onward.

## Dashboard

### Page 1 — Olist Marketplace: Delivery Performance
Headline finding (2.6 vs 4.3 review stars), core KPIs (total revenue, total orders, late rate, average delay, seller SLA miss rate), a delivery-outcome donut, and the late-rate trend over time with review score overlaid.

![Overview](screenshots/Olist%20Marketplace%20Delivery%20Performance.png)

### Page 2 — Which Sellers and Regions to Fix First
Late rate by category and by state (top 10 each), a seller revenue-vs-late-rate scatter (priority sellers in the top-right), and a seller scorecard table sorted by revenue at risk, showing total revenue alongside revenue at risk.

![Which Sellers and Regions to Fix First](screenshots/Which%20Sellers%20and%20Regions%20to%20Fix%20First.png)

### Page 3 — Whose Fault Is It: Seller or Carrier?
Splits late delivery into seller-handoff delay vs carrier-transit delay (~27% seller-caused, ~73% carrier-caused), a two-leg trend over time, SLA miss rate by seller, and the delay split by state — so the fix is aimed at the right party.

![Whose Fault Is It](screenshots/Whose%20Fault%20Is%20It%20Seller%20or%20Carrier.png)

> **A note on the different totals:** the headline KPI cards ($15M revenue, ~96K orders) cover the full delivered-order population. The page 2 seller scorecard totals to a smaller base (~73K orders, ~$10.6M revenue) because that table is filtered to sellers with 50+ orders, so tiny-volume sellers don't distort the priority ranking. The two figures measure different populations by design, not a discrepancy.

## Tech Stack

SQL Server 2025 (Developer Edition) · SSMS · Power BI Desktop · T-SQL · DAX · Kimball dimensional modeling · Git

## Repo Structure

```
olist-delivery-performance/
├── sql/            # staging move, dimension + fact builds, validation, FK constraints, indexes
├── dax/            # all Power BI measures with comments
├── screenshots/    # dashboard page images
├── pbix/           # Power BI report file
└── README.md
```

## What I'd Do Differently / Next Steps

- Rebuild the same model with **dbt on a cloud warehouse** to add automated testing, documentation, and lineage.
- Add **SCD2** handling to track seller/geography changes over time (this dataset is a static snapshot, so change-tracking was out of scope here).
- Investigate the 2018 carrier-transit regression with additional time-series analysis.