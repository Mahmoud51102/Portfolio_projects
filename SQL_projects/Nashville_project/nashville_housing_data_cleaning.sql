SELECT * FROM nashville_housing nh
ORDER BY "UniqueID " ;

-- create the staging table we are going to operate on
CREATE TABLE nashville_housing2 AS 
SELECT * FROM nashville_housing nh ;

/*POPULATE PropertyAddress data*/

SELECT *
FROM nashville_housing2 nh 
--WHERE nh."PropertyAddress" IS NULL 
ORDER BY "ParcelID";

/*we discovered that there is some rows have the same parcell_ID and the same property_address
  so we are going to do a self join to know how we are going to update the null values with later
*/

SELECT nh."ParcelID", nh."PropertyAddress", nh2."ParcelID" , nh2."PropertyAddress"
FROM nashville_housing2 nh 
JOIN nashville_housing2 nh2 
	ON nh2."ParcelID" = nh."ParcelID"
	AND nh2."UniqueID " <> nh."UniqueID " /*to not get the same row twice*/
	AND nh."PropertyAddress" IS NULL 
	AND nh2."PropertyAddress" IS NOT NULL;
	
UPDATE nashville_housing2 nh1
SET "PropertyAddress" = nh2."PropertyAddress"
FROM nashville_housing2 nh2
WHERE nh1."ParcelID" = nh2."ParcelID"
  AND nh1."UniqueID " <> nh2."UniqueID "
  AND nh1."PropertyAddress" IS NULL
  AND nh2."PropertyAddress" IS NOT NULL;


/*--------------------------------------------------------------------------------*/
/*BREAKING OUT property address INTO INDIVIDUAL COLUMNS (street, city)*/

SELECT "PropertyAddress" 
FROM nashville_housing2 nh ;

SELECT "PropertyAddress", 
		split_part("PropertyAddress", ',', 1) AS street,
		split_part("PropertyAddress", ',', 2) AS city
FROM nashville_housing2 nh;

ALTER TABLE nashville_housing2 
ADD COLUMN "property_split_street" varchar(255);

UPDATE nashville_housing2 
SET "property_split_street" = split_part("PropertyAddress", ',', 1) 

ALTER TABLE nashville_housing2 
ADD COLUMN "property_split_city" varchar(255);

UPDATE nashville_housing2 
SET "property_split_city" = split_part("PropertyAddress", ',', 2) 

SELECT * FROM nashville_housing2 nh 
ORDER BY "UniqueID " 

/*NOW WE ARE GOING TO THE OWNER ADDRESS COLUMN (street, city, state)*/

SELECT "OwnerAddress" 
FROM nashville_housing2 nh 

SELECT 
	"OwnerAddress",
	split_part("OwnerAddress", ',', 1) AS street,
	split_part("OwnerAddress", ',', 2) AS city,
	split_part("OwnerAddress", ',', 3) AS state 
FROM nashville_housing2 nh

ALTER TABLE nashville_housing2 
ADD COLUMN "owner_split_street" varchar(255);

UPDATE nashville_housing2 
SET "owner_split_street" = split_part("OwnerAddress", ',', 1)

ALTER TABLE nashville_housing2 
ADD COLUMN "owner_split_city" varchar(255);

UPDATE nashville_housing2 
SET "owner_split_city" = split_part("OwnerAddress", ',', 2)

ALTER TABLE nashville_housing2 
ADD COLUMN "owner_split_state" varchar(255);

UPDATE nashville_housing2 
SET "owner_split_state" = split_part("OwnerAddress", ',', 3)

SELECT * 
FROM nashville_housing2 nh 

/*-----------------------------------------------------------------------------*/
/*CHANGE Y and N to YES and NO in 'SoldAsVacant' column*/

SELECT DISTINCT "SoldAsVacant" 
FROM nashville_housing2 nh 


SELECT "SoldAsVacant",
	CASE WHEN "SoldAsVacant" LIKE '%Y%' THEN 'Yes'
	WHEN "SoldAsVacant" LIKE '%N%' THEN 'No'
	ELSE "SoldAsVacant" END
FROM nashville_housing2 nh 

UPDATE nashville_housing2 
SET "SoldAsVacant" = 
		CASE WHEN "SoldAsVacant" LIKE '%Y%' THEN 'Yes'
		WHEN "SoldAsVacant" LIKE '%N%' THEN 'No'
		ELSE "SoldAsVacant" END

/*---------------------------------------------------------------------------------------*/
/*REMOVE DUPLICATES*/

WITH duplicate_cte AS (
	SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY "ParcelID",
					 "PropertyAddress",
					 "SalePrice",
					 "LegalReference",
					 "SaleDate"
					  -- Columns that define uniqueness
		ORDER BY "UniqueID "
	) AS row_num
	FROM nashville_housing2 nh 
)
/*SELECT *
FROM duplicate_cte 
WHERE row_num > 1;*/
DELETE 
FROM nashville_housing2 nh  
WHERE "UniqueID " IN 
					(SELECT "UniqueID " FROM duplicate_cte WHERE row_num > 1) 

/*checked on some duplicated row in the next query*/
SELECT *
FROM nashville_housing2 nh 
WHERE "ParcelID" = '081 02 0 144.00' AND 
	  "LandUse" = 'SINGLE FAMILY' AND 
	  "PropertyAddress" = '1728  PECAN ST, NASHVILLE'









 