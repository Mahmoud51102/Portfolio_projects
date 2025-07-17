-- REMOVING DUPLICATES
SELECT *
FROM layoffs;

-- to not mess around with the original table
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT INTO layoffs_staging
SELECT * FROM layoffs;


WITH duplicate_cte AS (
	SELECT *, ROW_NUMBER() OVER(
			PARTITION BY company, location, industry,
            total_laid_off, percentage_laid_off, 'date',
            country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)

SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

/* because we can't delete from the CTE, we will make a new staging table and
add a column called row_num, so we can delete the duplicates easily*/
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER() OVER(
			PARTITION BY company, location, industry,
            total_laid_off, percentage_laid_off, `date`, stage,
            country, funds_raised_millions) AS row_num
FROM layoffs_staging;
-- because i can't delete until i disable the update safe mode
SET SQL_SAFE_UPDATES = 0;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SET SQL_SAFE_UPDATES = 1;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- STANDARDIZING DATA
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

/* after we found out there is some industries called crypto and others are crypto currency
we will now change the all the industries starting with the word crypto to Crypto*/
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

/* next we go into every other column and go through the data inside every column
to see if there is some data need to be stadardized */
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

/*after we found an issue in the united states field, there was United states and 
United states. so we are going to remove that '.' in the end*/
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

/*now after we found the date column type is text and it should be date not text
we will convert it to date and this is the right format, the Y should be capital and the
m and d small,,, also the format should be written typically like the exact form 
like in the table, for example: 12/16/2022. if we wrote the format like this:
%Y/%d/%m this would be wrong*/
SELECT `date`, str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

SELECT `date` FROM layoffs_staging2;

/*this way does not change the column type, so now we will change the column type 
using the Alter Table and modify*/
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *  FROM layoffs_staging2;

/*now we are going to modify the null fields*/
SELECT DISTINCT industry
FROM layoffs_staging2;
/*we found out that there is some blank and NULL industries*/

SELECT * FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

SELECT * FROM layoffs_staging2
WHERE company = 'Airbnb';

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT t1.company, t1.industry, t2.industry
FROM layoffs_staging2 t1
LEFT JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL)
	AND t2.industry IS NOT NULL;

/*we joined the table with itself to observe the value we are going to update to*/

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL )
	AND t2.industry IS NOT NULL;

SELECT * FROM layoffs_staging2
WHERE company = 'Airbnb';
/*after we queried the Airbnb company, i discovered that there is repeated rows, so the next step is to get rid of the redundant data
we created a temp table that has the same rows as layoffs_staging2 nut without the row number because we don't need it anymore*/

CREATE TABLE layoffs_staging2_clean AS
SELECT DISTINCT company, location, industry, total_laid_off, percentage_laid_off, 
                date, stage, country, funds_raised_millions
FROM layoffs_staging2;

DROP TABLE layoffs_staging2;
ALTER TABLE layoffs_staging2_clean RENAME TO layoffs_staging2;

DROP TABLE layoffs_staging2_clean;

SELECT * FROM layoffs_staging2;

/*the resutls of the next query does not make any sense, so we are going to get rid of them*/
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND 
percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND 
percentage_laid_off IS NULL;

SELECT DISTINCT company
FROM layoffs_staging2











