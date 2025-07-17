-- Layoffs Exploratory data analysis

SELECT * 
FROM layoffs_staging2;

SELECT MIN(total_laid_off), MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1 -- 100% of the employees got laid off "company went under"
ORDER BY total_laid_off DESC;

/*what companies have the most layoffs?*/
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

/*now we will select the range where companies started laying off until they stopped laying off employees*/
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

/*what industries have the most layoffs?*/
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

/*this query returns every year and the SUM of employees laid off in that year*/
SELECT EXTRACT(YEAR FROM `date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY EXTRACT(YEAR FROM `date`)
ORDER BY 2 DESC;

/*This query returns the month and the year and SUM of the employees laid off in every month from 2020 - 2023*/
SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC;

WITH rolling_total AS (
		SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off) AS total_off
		FROM layoffs_staging2
		WHERE SUBSTRING(`date`,1,7) IS NOT NULL
		GROUP BY `Month`
		ORDER BY 1 ASC
)
/*the next query sums the total_laid_offs every month and for every year*/
SELECT `Month`, total_off, SUM(total_off) OVER(
												PARTITION BY SUBSTRING(`Month`,1,4)
                                                ORDER BY `Month`) AS roll_total
FROM rolling_total;

/*the next query calculates the sum of the total_laid_off employees in each company in each year*/
SELECT company, EXTRACT(YEAR from `date`) AS year, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
GROUP BY company, year
ORDER BY total_off DESC;

/*this CTE gives the sum of total laid_offs per year for each company*/
WITH Company_Year(company, years, total_off) AS (
	SELECT company, EXTRACT(YEAR from `date`), SUM(total_laid_off)
	FROM layoffs_staging2
	GROUP BY company, EXTRACT(YEAR from `date`)
),
/*this CTE gives the rank "which company has the most laid_offs in each year*/
Company_Year_Rank AS (
	SELECT *, DENSE_RANK() OVER(PARTITION BY years
								ORDER BY total_off DESC) AS Ranking
	FROM Company_Year
	WHERE years IS NOT NULL 
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;

/*the next queries calculates the avg per year for each country and rank them descendingly*/
WITH Country_Avg_laid_off AS (
	SELECT country, EXTRACT(YEAR FROM `date`) AS `year`, ROUND(AVG(percentage_laid_off),2) AS avg_laid_off
	FROM layoffs_staging2
	GROUP BY country,`year`
), Country_Rank AS (
	SELECT *, DENSE_RANK() OVER(partition by `year`
							 order by avg_laid_off DESC) Ranking
	FROM Country_Avg_laid_off 
    WHERE `year` IS NOT NULL
)
SELECT *
FROM Country_Rank
WHERE Ranking <= 5;

/*this query gives the total funds raised for each company and in which industry*/
SELECT company, industry, SUM(funds_raised_millions) AS total_funds
FROM layoffs_staging2
WHERE funds_raised_millions IS NOT NULL
GROUP BY company, industry
ORDER BY total_funds DESC;

/*we are now going to discover the most funds raised per year for each company and in which industry*/
WITH Company_Funds AS (
	SELECT company, industry, EXTRACT(YEAR FROM `date`) as `year`, SUM(funds_raised_millions) AS total_funds
	FROM layoffs_staging2
	WHERE funds_raised_millions IS NOT NULL AND EXTRACT(YEAR FROM `date`) IS NOT NULL
	GROUP BY company, industry, `year`
), Company_Funds_Rank AS (
	SELECT *, DENSE_RANK() OVER(PARTITION BY `year`
								ORDER BY total_funds DESC) AS Ranking
	FROM Company_Funds
)
SELECT *
FROM Company_Funds_Rank
WHERE Ranking <= 5;