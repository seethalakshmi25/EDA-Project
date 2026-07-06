/* ============================================================
   LAYOFFS DATASET - SQL EDA PROJECT
   Tool: SQL Server / SSMS
   ============================================================ */


/* ------------------------------------------------------------
   STEP 0: Raw data was imported into dbo.layoffs via
   SSMS's "Import Flat File" wizard (all columns as NVARCHAR
   to avoid type-conversion errors on messy text like 'NULL').
   ------------------------------------------------------------ */


/* ------------------------------------------------------------
   STEP 1: Convert text columns to proper numeric types.
   Handles the literal text "NULL" appearing in the raw CSV.
   ------------------------------------------------------------ */
SELECT
  company,
  location,
  industry,
  CASE WHEN total_laid_off = 'NULL' THEN NULL ELSE CAST(total_laid_off AS FLOAT) END AS total_laid_off,
  CASE WHEN percentage_laid_off = 'NULL' THEN NULL ELSE CAST(percentage_laid_off AS FLOAT) END AS percentage_laid_off,
  date,
  stage,
  country,
  CASE WHEN funds_raised_millions = 'NULL' THEN NULL ELSE CAST(funds_raised_millions AS FLOAT) END AS funds_raised_millions
INTO layoffs_clean
FROM dbo.layoffs;


/* ------------------------------------------------------------
   STEP 2: Check for missing values (NULLs)
   ------------------------------------------------------------ */
SELECT
  SUM(CASE WHEN total_laid_off IS NULL THEN 1 ELSE 0 END) AS missing_total_laid_off,
  SUM(CASE WHEN percentage_laid_off IS NULL THEN 1 ELSE 0 END) AS missing_percentage,
  SUM(CASE WHEN industry IS NULL THEN 1 ELSE 0 END) AS missing_industry,
  SUM(CASE WHEN funds_raised_millions IS NULL THEN 1 ELSE 0 END) AS missing_funds
FROM layoffs_clean;


/* ------------------------------------------------------------
   STEP 3: Find and remove true duplicate rows
   (all 9 columns identical = same event recorded twice)
   ------------------------------------------------------------ */
-- Check
SELECT company, location, industry, total_laid_off, date, COUNT(*) as cnt
FROM layoffs_clean
GROUP BY company, location, industry, total_laid_off, date
HAVING COUNT(*) > 1;

-- Remove
WITH cte AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
      ORDER BY (SELECT NULL)
    ) AS rn
  FROM layoffs_clean
)
DELETE FROM cte WHERE rn > 1;

-- Note: A few rows (e.g. Oda, Terminus) looked similar but had different
-- country/stage/funding values, so they were kept as distinct records
-- rather than deleted as duplicates.


/* ------------------------------------------------------------
   STEP 4: Standardize inconsistent text values
   ------------------------------------------------------------ */
-- Industry: "Crypto", "Crypto Currency", "CryptoCurrency" -> "Crypto"
SELECT DISTINCT industry FROM layoffs_clean ORDER BY industry;

UPDATE layoffs_clean
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Country: "United States." (trailing period) -> "United States"
UPDATE layoffs_clean
SET country = 'United States'
WHERE country = 'United States.';


/* ------------------------------------------------------------
   STEP 5: Fix the date column (convert text -> real DATE type)
   ------------------------------------------------------------ */
ALTER TABLE layoffs_clean
ADD date_new DATE;

UPDATE layoffs_clean
SET date_new = TRY_CONVERT(DATE, date, 101);

-- Verify no rows failed to convert (that weren't already bad data)
SELECT date, date_new
FROM layoffs_clean
WHERE date IS NOT NULL AND date_new IS NULL;

-- Drop old text column, rename new one
ALTER TABLE layoffs_clean DROP COLUMN date;
EXEC sp_rename 'layoffs_clean.date_new', 'date', 'COLUMN';


/* ------------------------------------------------------------
   STEP 6: Check for impossible values
   ------------------------------------------------------------ */
SELECT * FROM layoffs_clean
WHERE total_laid_off < 0
   OR percentage_laid_off < 0
   OR percentage_laid_off > 1;
-- Result: empty -> no impossible values found


/* ============================================================
   EXPLORATORY DATA ANALYSIS (EDA)
   ============================================================ */

-- Q1: Total layoffs by industry
SELECT industry, SUM(total_laid_off) AS total_layoffs
FROM layoffs_clean
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY total_layoffs DESC;
-- Finding: Crypto and Marketing were hit hardest by total headcount laid off.

-- Q2: Top 10 single largest layoff events
SELECT TOP 10 company, total_laid_off, date, industry
FROM layoffs_clean
WHERE total_laid_off IS NOT NULL
ORDER BY total_laid_off DESC;
-- Finding: Largest single events came from big established tech companies
-- (Google, Meta, Microsoft, Amazon), not struggling startups.

-- Q3: Monthly layoffs trend
SELECT FORMAT(date, 'yyyy-MM') AS month, SUM(total_laid_off) AS total_layoffs
FROM layoffs_clean
WHERE total_laid_off IS NOT NULL AND date IS NOT NULL
GROUP BY FORMAT(date, 'yyyy-MM')
ORDER BY month;
-- Finding: Two distinct waves - a sharp COVID shock (Mar-May 2020) and a
-- larger, slower-building wave peaking in January 2023 (84,714 layoffs).

-- Q4: Total layoffs by country
SELECT country, SUM(total_laid_off) AS total_layoffs
FROM layoffs_clean
WHERE total_laid_off IS NOT NULL
GROUP BY country
ORDER BY total_layoffs DESC;
-- Finding: United States accounts for ~66% of all recorded layoffs (256,559),
-- more than 7x the next closest country (India).

-- Q5: Total layoffs by company stage
SELECT stage, SUM(total_laid_off) AS total_layoffs, COUNT(*) AS num_events
FROM layoffs_clean
WHERE total_laid_off IS NOT NULL
GROUP BY stage
ORDER BY total_layoffs DESC;
-- Finding: Post-IPO (publicly traded) companies accounted for ~53% of all
-- layoffs, reinforcing that this was a large-company correction, not
-- startups running out of funding.


/* ------------------------------------------------------------
   DATA QUALITY NOTE
   ------------------------------------------------------------ */
-- 1 row (Blackbaud, 500 layoffs) had an unparseable original date value.
-- It was kept for industry/company totals but excluded from date-based
-- (monthly trend) analysis via "WHERE date IS NOT NULL".
