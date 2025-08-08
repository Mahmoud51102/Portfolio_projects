ALTER TABLE "TitanicSchema".titanic 
ALTER COLUMN "Name" TYPE varchar(255);

CREATE TABLE titanic_copy AS
SELECT * FROM titanic t ;

INSERT INTO titanic_copy 
SELECT * FROM "TitanicSchema".titanic ;


/*1. Data Exploration & Cleaning*/

/*calculate the number of rows*/
SELECT count(*) AS num_of_passengers
FROM titanic t 

/*calculate the number of columns*/
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'TitanicSchema'   
  AND table_name   = 'titanic';
 
/*What are the names and data types of the columns?*/
 SELECT column_name , data_type
 FROM information_schema.COLUMNS
 WHERE table_schema = 'TitanicSchema'   
  		AND table_name   = 'titanic';

/*Are there any missing values? In which columns?*/
SELECT count(*) 
FROM titanic_copy tc 
WHERE age IS NULL  -- 177 ROWS WHERE AGE IS MISSING

SELECT count(*) 
FROM titanic_copy tc 
WHERE CABIN IS NULL OR CABIN = '' -- 687 ROWS WHERE CABIN IS MISSING

SELECT COUNT(*)
FROM titanic_copy tc 
WHERE embarked IS NULL OR embarked = '' -- 2 ROWS WHERE EMBARKED IS MISSING

/*Replace missing values in the "Age" column with the median age*/
WITH median_cte AS (
	SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY age) AS median_age
	FROM titanic_copy tc 
)
UPDATE titanic_copy 
SET AGE = (SELECT median_age FROM median_cte)
WHERE age IS NULL 

SELECT count(*) 
FROM titanic_copy tc 
WHERE age IS NULL -- NOW WE CAN SEE THAT WE DON'T HAVE ANY MISSING VALUE IN THE AGE COLUMN

/*Drop rows where "Embarked" is missing*/
SELECT *
FROM titanic_copy tc 
WHERE embarked = '' -- FIRST WE MAKE A CHECK TO NOT FALL INTO A MISTAKE AND DELETE SOME IMPORTANT ROWS

DELETE 
FROM titanic_copy tc 
WHERE embarked = '' -- AND NOW WE ARE SURE THAT THE 2 ROWS THAT HAS MISSING EMBARKED ARE GONE :)

--------------------------------------------------------------------------------------------------------------------
/*2. Filtering & Indexing*/

/*Select all passengers who are female*/
SELECT DISTINCT SEX
FROM titanic_copy tc -- TO EXPLORE IF THEY ARE WRITTEN IN UPPER OR LOWER CASE AND SO ON

SELECT *
FROM titanic_copy tc 
WHERE SEX = 'female'

/*Show all passengers under the age of 18*/
SELECT *
FROM titanic_copy tc 
WHERE AGE < 18

/*Retrieve the names of passengers who paid a fare greater than 50*/
SELECT t."Name"
FROM titanic t
WHERE FARE > 50

---------------------------------------------------------------------------------------------------------------------
/*3. Aggregation & Grouping*/

/*What is the average age of passengers?*/
SELECT ROUND(AVG(AGE)) AS avg_age_of_passengers
FROM titanic_copy tc -- THE AVERAGE AGE IS 29.3

/*What is the survival rate by gender?*/
SELECT * FROM titanic_copy tc 

WITH gender_counts AS (
    SELECT 
        sex,
        COUNT(*) AS total_passengers,
        COUNT(*) FILTER (WHERE survived = 1) AS survived_count
    FROM titanic_copy
    GROUP BY sex
)
SELECT 
    sex,
    (survived_count::numeric / total_passengers::numeric) * 100.0 AS survival_rate
FROM gender_counts;

/*What is the average fare per class (Pclass)?*/
SELECT pclass, AVG(fare) AS avg_fare
FROM titanic_copy tc 
GROUP BY pclass 
ORDER BY pclass

------------------------------------------------------------------------------------------------------------------------------
/*4. Data Transformation*/

/*Create a new column "FamilySize" as the sum of SibSp and Parch*/
SELECT * FROM titanic_copy tc 


-- Sibsp: number of siblings or spouses aboard
-- Parch = number of parents or children aboard
ALTER TABLE titanic_copy 
ADD COLUMN FamilySize INTEGER

UPDATE titanic_copy 
SET FamilySize = sibsp + parch 

/*Create a new binary column "IsAlone" where 1 indicates the passenger is alone*/
ALTER TABLE titanic_copy 
ADD COLUMN IsAlone INTEGER

UPDATE titanic_copy 
SET IsAlone = 
			CASE WHEN sibsp = 0 AND parch = 0 THEN 1
			ELSE 0
			END

/*Categorize "Age" into bins: Child (0–12), Teen (13–19), Adult (20–59),
Senior (60+)*/
SELECT passengerid ,
	CASE WHEN AGE BETWEEN 0 AND 12 THEN 'Child'
	WHEN age BETWEEN 13 AND 19 THEN 'Teen'
	WHEN AGE BETWEEN 20 AND 59 THEN 'Adult'
	WHEN AGE >= 60 THEN 'Senior'
	ELSE 'Unknown'
	END AS age_bin
FROM titanic_copy tc;
-------------------------------------------------------------------------------------------------------------------------

/*5. Sorting & Ranking*/
/* List the top 10 passengers who paid the highest fares*/
SELECT passengerid,
	   SUBSTRING("Name" FROM ' (?:Mr|Mrs|Miss|Ms|Master|Dr|Rev|Col|Capt)\..*') AS name,
	   fare,
	   RANK() OVER (ORDER BY fare DESC)
FROM titanic_copy tc
LIMIT 10;

/*Sort the dataset by "Age" and "Fare" in descending order*/
SELECT *
FROM titanic_copy tc 
ORDER BY AGE DESC, fare DESC; 
--------------------------------------------------------------------------------------------------------------------------
/*6. Value Counts & Crosstabs*/
/*How many passengers embarked from each port?*/
SELECT embarked, count(*) AS num_of_passengers
FROM titanic_copy tc2
GROUP BY embarked;

/*How many survived vs. not survived by passenger class?*/
SELECT pclass, survived, count(*)
FROM titanic_copy tc 
GROUP BY survived, pclass
ORDER BY pclass 

/*Use a cross-tabulation to explore survival by both Sex and Pclass*/
SELECT
    sex,
    -- Class 1
    COUNT(*) FILTER (WHERE pclass = 1 AND survived = 0) AS class1_not_survived,
    COUNT(*) FILTER (WHERE pclass = 1 AND survived = 1) AS class1_survived,
    -- Class 2
    COUNT(*) FILTER (WHERE pclass = 2 AND survived = 0) AS class2_not_survived,
    COUNT(*) FILTER (WHERE pclass = 2 AND survived = 1) AS class2_survived,
    -- Class 3
    COUNT(*) FILTER (WHERE pclass = 3 AND survived = 0) AS class3_not_survived,
    COUNT(*) FILTER (WHERE pclass = 3 AND survived = 1) AS class3_survived
FROM titanic_copy
GROUP BY sex;

--------------------------------------------------------------------------------------------------------------
/*7. Boolean Logic & Queries*/
/*Who are the passengers in 1st class who survived and were older than 60?*/
SELECT passengerid, "Name", pclass, age, survived 
FROM titanic_copy tc
WHERE survived = 1 AND pclass = 1 AND age > 60 

/*Which female passengers under 30 paid a fare less than 10 and survived?*/
SELECT passengerid, "Name", age, fare, survived 
FROM titanic_copy tc
WHERE sex = 'female' AND age < 30 AND fare < 10 AND survived = 1;
--------------------------------------------------------------------------------------------------------------
/*What is the mean and standard deviation of the "Fare" column?*/
SELECT AVG(fare), stddev(fare)
FROM titanic_copy tc2 

/*Compare the median age of survivors vs. non-survivors*/
SELECT survived, 
		percentile_cont(0.5) WITHIN GROUP (ORDER BY age) AS median_age
FROM titanic_copy tc 
GROUP BY survived 
---------------------------------------------------------------------------------------------------------------

/*Exploratory & Filtering Questions*/
/*How many passengers are male? Female?*/
SELECT sex, count(*) AS num_passengers
FROM titanic_copy tc 
GROUP BY sex

/*How many male passengers survived?*/
SELECT sex, count(*) AS num_male_survived
FROM titanic_copy tc 
WHERE sex = 'male' AND survived = 1
GROUP BY sex

/*How many females under the age of 30 did not survive?*/
SELECT sex, count(*) AS num_female_not_survived_under_30 
FROM titanic_copy tc 
WHERE sex = 'female' AND age < 30 AND survived = 0
GROUP BY sex

/*How many children (age < 12) were in 3rd class?*/
SELECT count(*) AS num_children
FROM titanic_copy tc 
WHERE age < 13 AND pclass = 3

/*Who are the oldest and youngest passengers who survived?*/
(
  SELECT 'Youngest' AS type, *
  FROM titanic_copy
  WHERE survived = 1
  ORDER BY age ASC
  LIMIT 1
)
UNION ALL
(
  SELECT 'Oldest' AS type, *
  FROM titanic_copy
  WHERE survived = 1
  ORDER BY age DESC
  LIMIT 1
);

/*What class did most non-survivors belong to?*/
SELECT pclass, count(*) AS num_non_survivors
FROM titanic_copy tc 
WHERE survived = 0
GROUP BY pclass 
ORDER BY num_non_survivors DESC 
LIMIT 1

/*What is the survival rate per class (Pclass)?*/
SELECT 
	pclass, 
	(count(*) FILTER (WHERE survived = 1)::NUMERIC / count(*)::NUMERIC) * 100.0 AS survival_rate
FROM titanic_copy tc 
GROUP BY pclass
ORDER BY pclass;
--Another solution
SELECT 
	pclass,
	(sum(CASE WHEN (survived = 1) THEN 1 ELSE 0 END)::NUMERIC / count(*)::NUMERIC) * 100.0 AS survival_rate
FROM titanic_copy tc 
GROUP BY pclass
ORDER BY pclass

/*What is the survival rate for males vs. females?*/
SELECT 
	sex,
	(count(*) FILTER (WHERE survived = 1)::NUMERIC / count(*)::NUMERIC) * 100.0 AS survival_rate
FROM titanic_copy tc 
GROUP BY sex

---------------------------------------------------------------------------------------------------------------------------
/*Insightful Logical Questions*/

/*What percentage of passengers were traveling alone (SibSp + Parch == 0)?*/
SELECT 
	(count(*) FILTER (WHERE isalone = 1)::NUMERIC / count(*)::NUMERIC) * 100.0 AS alone_percentage
FROM titanic_copy tc 

/*Among those who traveled alone, how many survived?*/
SELECT count(*) AS num_alone_survived
FROM titanic_copy tc 
WHERE isalone = 1 AND survived = 1

/*Which embarkation point (Embarked) had the highest survival rate?*/
SELECT 
	embarked,
	(count(*) FILTER (WHERE survived = 1)::NUMERIC / count(*)) * 100.0 AS survival_rate
FROM titanic_copy tc
GROUP BY embarked
ORDER BY survival_rate DESC 
LIMIT 1

/*What is the median fare paid by survivors vs. non-survivors?*/
SELECT 
	CASE WHEN survived = 0 THEN 'survivors' ELSE 'non-survivors' END AS survivor_status,
	percentile_cont(0.5) WITHIN GROUP (ORDER BY fare) 
FROM titanic_copy tc 
GROUP BY survived 

/*Did people who paid higher fares have a higher chance of survival?*/
SELECT 
	CASE WHEN fare <= 20 THEN 'Low (<=20)'
    	 WHEN fare <= 100 THEN 'Medium (21-100)'
         ELSE 'High (>100)'
  	END AS fare_band,
	(count(*) FILTER (WHERE survived = 1)::NUMERIC / count(*)) * 100.0 AS survival_rate
FROM titanic_copy tc 
GROUP BY fare_band 
ORDER BY survival_rate DESC 

/*Among passengers older than 60, how many survived, and in which class were they?*/
SELECT 
	COALESCE(pclass::text, 'total_old_passengers') AS pclass, --because ROLLUP SETS NULL FOR the total
	count(*) AS num_survived
FROM titanic_copy tc 
WHERE survived = 1 AND age > 60
GROUP BY ROLLUP(pclass)

/*How many 1st-class passengers died despite paying high fares?*/
SELECT 
	pclass,
	CASE WHEN fare <= 20 THEN 'low fare' 
		 WHEN fare BETWEEN 21 AND 99 THEN 'medium fare'
		 WHEN fare >= 100 THEN 'high fare'
	END AS fare_band,
	count(*) AS non_survivors
FROM titanic_copy tc 
WHERE survived = 0 AND pclass = 1 AND fare >= 100
GROUP BY pclass, fare_band

--------------------------------------------------------------------------------------------------------------------
/*Comparison & Reasoning Questions*/
/*Compare the average age of survivors and non-survivors*/
SELECT 
	avg(age) FILTER (WHERE survived = 0) AS avg_non_survivors,
	avg(age) FILTER (WHERE survived = 1) AS avg_survivors
FROM titanic_copy tc 

/*Did families (defined as FamilySize > 1) have a higher survival rate than individuals?*/
SELECT * FROM titanic_copy tc 

SELECT
	CASE WHEN familysize + 1 <= 1 THEN 'individual' -- I added 1 here because FAMILYsize does NOT INCLUDE the passesnger himself
		 ELSE 'family'
	END AS family_category,
	(count(*) FILTER (WHERE survived = 1)::NUMERIC / count(*)::NUMERIC) * 100.0 AS survival_rate
FROM titanic_copy tc 
GROUP BY family_category

/*Was survival more likely for passengers in a higher class regardless of age or gender?*/


/*Is there any class where more passengers survived than died?*/
SELECT 
	pclass,
	count(*) FILTER (WHERE survived = 1) AS num_survived,
	count(*) FILTER (WHERE survived = 0) AS num_not_survived
FROM titanic_copy tc 
GROUP BY pclass -- ONLY the FIRST CLASS

/*How many passengers named “John” were aboard, and how many of them survived?*/
SELECT "Name"
FROM titanic_copy tc 
WHERE "Name" LIKE '%John%'
GROUP BY "Name"

SELECT count(*) 
FROM titanic_copy tc 
WHERE "Name" LIKE '%John%' AND survived = 1




 

