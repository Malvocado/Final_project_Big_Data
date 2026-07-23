# UrbanCart E-Commerce Analytics Pipeline

A complete analytics pipeline for UrbanCart, a fictional online retailer. The project moves from raw, imperfect data (SQLite database + two messy CSV exports) through four phases — SQL extraction, pandas-based cleaning, NumPy numerical analysis, and business visualization — to produce a decision-ready report. Built with Python 3.14, pandas, NumPy, matplotlib, seaborn, and SQLite.

## Project Structure

| Path | Description |
|---|---|
| `ecommerce.db` | Source database — 6 tables (customers, products, orders, order_items, reviews, web_sessions) |
| `queries.sql` | Phase 1 — 10 SQL analytics queries |
| `legacy_customers_export.csv` | Phase 2 input — messy CRM export with 4 date formats, duplicates, missing values |
| `product_catalog_2024.csv` | Phase 2 input — supplier catalog with different column naming than the DB |
| `pipeline.ipynb` | Main notebook — Phases 1 through 4 (SQL extraction, cleaning, NumPy routines, 8 business charts) |
| `data/processed/` | Phase 2 output — 14 cleaned CSV files ready for analysis |
| `data/result_for_phase3/` | Phase 3 output — RFM segments and Monte Carlo results |

## Individual Contributions

**Phase 1 — SQL Data Extraction.** Authored all 10 SQL queries against `ecommerce.db`, covering category revenue, top-20 customer lifetime value, month-over-month revenue trends with LAG window functions, return rates via CTEs, cross-quarter customer retention using HAVING, top-rated products, session analytics with EXISTS subqueries, DENSE_RANK within categories, payment-method mix, and a custom profitability query. Queries are self-contained and runnable directly against the provided database.

**Phase 2 — Data Cleaning & Integration with pandas.** Reconciled three data sources (SQL extracts, legacy CRM export, supplier catalog) into clean, analysis-ready DataFrames. Standardized four inconsistent date formats into a single datetime dtype. Detected and resolved ~5% duplicate/near-duplicate customer records using exact and fuzzy matching. Applied a documented missing-value policy (median imputation for age, flag for review_text). Identified and capped price outliers using z-score thresholds. Merged `product_catalog_2024.csv` with the products table on SKU/product_id, reconciling column-name differences, and reported SKUs present in only one source. Deduplicated ~0.8% exact-duplicate `order_items` rows and split negative quantities into a separate returns table. Produced a category-by-month pivot table and a weekly active customers time series. Saved 14 cleaned CSV files to `data/processed/`.

**Phase 3 — Numerical Analysis with NumPy.** Implemented all four routines on raw NumPy arrays without pandas convenience methods or scikit-learn shortcuts: (1) RFM customer segmentation using `np.percentile` + `np.digitize` for manual quintile bucketing, yielding 5 segments (Champions through Lost); (2) product-similarity matrix via `np.dot` and `np.linalg.norm` for cosine similarity, recommending 3 products for 5 sample customers; (3) linear regression via the normal equation with `np.linalg.inv`, fitting monthly revenue to month index (R-squared = 0.71), forecasting 2 months ahead with confidence intervals; (4) Monte Carlo stockout simulation (5,000+ trials) using `np.random.normal`, reporting stockout probabilities and recommended reorder points. Each routine includes the mathematical formula, a short explanation, and a sanity-check validation against a library function or trivial case.

**Phase 4 — Business Insights & Visualization.** Produced 8 business charts with interpretations: (1) identified the Loyal segment as the largest total-revenue driver with demographic comparison; (2) detected seasonal revenue patterns using rolling averages; (3) computed effective category margins net of discounts and returns; (4) quantified the correlation between review ratings and repeat purchases; (5) analyzed device-country engagement-to-purchase conversion rates; (6) presented the regression-based revenue forecast with 95% CI; (7) ranked top-5 stockout-risk products via expanded Monte Carlo simulation; (8) demonstrated material revenue inflation from raw vs. cleaned data as a data-quality finding.

## How to Run

```powershell
# Activate virtual environment
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.venv\Scripts\activate

# Install dependencies (if needed)
pip install pandas numpy scipy matplotlib seaborn jupyter

# Launch notebook
jupyter notebook pipeline.ipynb
```

Run all cells in order. The notebook reads from `ecommerce.db`, `legacy_customers_export.csv`, and `product_catalog_2024.csv`, and writes cleaned outputs to `data/processed/` and `data/result_for_phase3/`.
