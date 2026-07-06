# Layoffs Dataset — SQL EDA Project

An end-to-end exploratory data analysis (EDA) of global tech layoffs (2020–2023), built entirely in SQL Server, with visualizations in Python.

## What this project is

This project takes a raw, messy real-world dataset of company layoffs and takes it through the full analyst workflow: cleaning, structuring, querying, and visualizing — to uncover patterns in when, where, and which companies were affected most.

## Tools used

- **SQL Server / SSMS** — data cleaning and analysis
- **Python (pandas, matplotlib, seaborn)** — visualizations, run in Google Colab

## Dataset

Layoffs dataset (`layoffs_cleaned.csv`) containing company name, location, industry, number laid off, percentage of workforce laid off, date, company funding stage, country, and total funds raised.

## Data cleaning steps

1. **Type conversion** — raw columns were imported as text; converted `total_laid_off`, `percentage_laid_off`, and `funds_raised_millions` to numeric types, correctly handling literal `"NULL"` text values in the source file.
2. **Missing values** — checked and quantified NULLs across key columns.
3. **Duplicate removal** — identified and removed exact duplicate records using `ROW_NUMBER()`.
4. **Text standardization** — merged inconsistent category names (e.g. `"Crypto"`, `"Crypto Currency"`, `"CryptoCurrency"` → `"Crypto"`; `"United States."` → `"United States"`).
5. **Date correction** — converted the `date` column from text to a proper `DATE` type.
6. **Validity checks** — confirmed no negative layoff counts or invalid percentages.

Full queries: [`layoffs_analysis.sql`](./layoffs_analysis.sql)

## Key findings

1. **Crypto and Marketing were hit hardest** by total layoff volume — together accounting for ~21,000 layoffs, nearly double the next closest industry.

2. **The largest single layoff events came from big, established tech companies** (Google, Meta, Microsoft, Amazon) — not struggling startups — suggesting a broad industry-wide correction rather than companies running out of money.

3. **Layoffs came in two distinct waves**: a sharp shock in March–May 2020 (COVID-19), and a larger, slower-building wave that peaked at 84,714 layoffs in January 2023 alone — over 3x the worst month of the pandemic shock.

4. **The United States accounted for ~66% of all recorded layoffs** (256,559), more than 7x the next closest country (India, 35,993).

5. **Post-IPO (publicly traded) companies made up ~53% of all layoffs**, reinforcing that this wave was driven primarily by large, mature companies correcting pandemic-era over-hiring — not early-stage startups failing.

## Visualizations

See [`layoffs_eda.ipynb`](./layoffs_eda.ipynb) for charts covering:
- Top 10 industries by total layoffs
- Monthly layoffs trend (2020–2023)
- Top 10 countries by total layoffs
- Total layoffs by company funding stage

## Data quality note

One row (Blackbaud, 500 layoffs) had an unparseable original date value. It was retained for industry/company-level totals but excluded specifically from date-based trend analysis.

## Files in this repo

| File | Description |
|---|---|
| `layoffs_analysis.csv` | Cleaned dataset used for analysis |
| `layoffs_analysis.sql` | All SQL queries: cleaning + EDA, with comments |
| `datavisualization.ipynb` | Python notebook with charts |
| `README.md` | This file |
