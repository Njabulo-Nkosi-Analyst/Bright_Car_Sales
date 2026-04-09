 --Data profilling
 
select top(10) [YEAR],[make],[model],[trim],[body],[transmission],[vin],[state],[condition],[odometer],
               [color],[interior],[seller],[mmr],[sellingprice],[saledate]
  FROM [CARS].[dbo].[car_sales_trends]

 --checking schema
USE [CARS];
GO

EXEC sp_help 'car_sales_trends';
GO

--Structural Integrity (Deduplication & Nulls)

---CTE checking duplicated and removing them
WITH DuplicateCTE AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY vin
               ORDER BY saledate DESC 
           ) as row_num
    FROM [CARS].[dbo].[car_sales_trends]
)
DELETE FROM DuplicateCTE 
WHERE row_num > 1;

----checking for null values
 select
    COUNT(*) AS Total_Records,
  
    -- Categorical Null Counts
    SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS Null_Year,
    SUM(CASE WHEN make IS NULL OR make = '' THEN 1 ELSE 0 END) AS Null_Make,
    SUM(CASE WHEN model IS NULL OR model = '' THEN 1 ELSE 0 END) AS Null_Model,
    SUM(CASE WHEN trim IS NULL OR trim = '' THEN 1 ELSE 0 END) AS Null_Trim,
    SUM(CASE WHEN body IS NULL OR body = '' THEN 1 ELSE 0 END) AS Null_Body,
    SUM(CASE WHEN transmission IS NULL OR transmission = '' THEN 1 ELSE 0 END) AS Null_Transmission,
    
    -- Technical/Location Null Counts
    SUM(CASE WHEN state IS NULL OR state = '' THEN 1 ELSE 0 END) AS Null_State,
    SUM(CASE WHEN condition IS NULL THEN 1 ELSE 0 END) AS Null_Condition,
    SUM(CASE WHEN odometer IS NULL THEN 1 ELSE 0 END) AS Null_Odometer,
    
    -- Color/Interior Null Counts
    SUM(CASE WHEN color IS NULL OR color = '' THEN 1 ELSE 0 END) AS Null_Color,
    SUM(CASE WHEN interior IS NULL OR interior = '' THEN 1 ELSE 0 END) AS Null_Interior,
    
    -- Financial Null Counts
    SUM(CASE WHEN mmr IS NULL THEN 1 ELSE 0 END) AS Null_MMR,
    SUM(CASE WHEN sellingprice IS NULL THEN 1 ELSE 0 END) AS Null_SellingPrice,
    SUM(CASE WHEN saledate IS NULL THEN 1 ELSE 0 END) AS Null_SaleDate
FROM [CARS].[dbo].[car_sales_trends];

--cleaning nulls
WITH DataCleaningCTE AS (
    SELECT 
        make, model, trim, body, transmission, 
        condition, odometer,color,sellingprice,interior,mmr,saledate

    FROM [CARS].[dbo].[car_sales_trends]

    --Rows that have a NULL or empty string
    WHERE make IS NULL OR make = ''
       OR model IS NULL OR model = ''
       OR transmission IS NULL OR transmission = ''
       OR condition IS NULL OR condition = ''
       OR odometer IS NULL OR odometer = ''
       OR color IS NULL OR color = ''
       OR interior IS NULL OR interior = ''
       OR sellingprice IS NULL OR sellingprice = ''
)
UPDATE DataCleaningCTE
SET 
    -- Fix Text Columns
    make = ISNULL(NULLIF(make, ''), 'Unknown'),
    model = ISNULL(NULLIF(model, ''), 'Unknown'),
    trim= ISNULL(NULLIF(trim, ''), 'Unknown'),
    body= ISNULL(NULLIF(body, ''), 'Unknown'),
    transmission = ISNULL(NULLIF(transmission, ''), 'Unknown'),
    color = ISNULL(NULLIF(color, ''), 'Unknown'),
    interior =ISNULL(NULLIF(interior, ''), 'Unknown'),

    -- Fix Numeric Columns (using 0 as a placeholder)
    condition = ISNULL(condition, 0),
    odometer = ISNULL(odometer, 0),
    mmr = ISNULL(mmr, 0),
    sellingprice = ISNULL(sellingprice, 0),
    
    -- 2. Fixing Date with Placeholder
    saledate = ISNULL(NULLIF(saledate, ''), '1900-01-01')
    ;
--cleaning uncleaned records
WITH body_trim as (
    SELECT body, trim
    FROM [CARS].[dbo].[car_sales_trends]
    WHERE (body IS NULL OR LEN(TRIM(body)) < 1)
       OR (trim IS NULL OR LEN(TRIM(trim)) < 1)
)
UPDATE body_trim
SET 
    body = ISNULL(NULLIF(TRIM(body), ''), 'Unknown'),
    trim = ISNULL(NULLIF(TRIM(trim), ''), 'Unknown');

---changing saledate dtype
WITH DateCleaningCTE AS (
    SELECT saledate
    FROM [CARS].[dbo].[car_sales_trends]
)
UPDATE DateCleaningCTE
SET saledate = ISNULL(
    TRY_CONVERT(VARCHAR, TRY_CONVERT(DATETIME, SUBSTRING(saledate, 5, 20)), 120),
    '1990-01-02 00:00:00'
);
--Checking there are zero NULLs and every row looks like a date,
ALTER TABLE [CARS].[dbo].[car_sales_trends]
ALTER COLUMN saledate DATETIME NOT NULL;

--Categorical Consistency
-- 1. Check Brand & Model Consistency
SELECT make, COUNT(*) as Count FROM [CARS].[dbo].[car_sales_trends] GROUP BY make ORDER BY make;
SELECT model, COUNT(*) as Count FROM [CARS].[dbo].[car_sales_trends] GROUP BY model ORDER BY model;
SELECT make, model, [year] FROM [CARS].[dbo].[car_sales_trends] WHERE model = '1';

-- 2. Check Trim & Body Style
SELECT trim, COUNT(*) as Count FROM [CARS].[dbo].[car_sales_trends] GROUP BY trim ORDER BY trim;
SELECT body, COUNT(*) as Count FROM [CARS].[dbo].[car_sales_trends] GROUP BY body ORDER BY body;

-- 3. Check Technical Specs
SELECT transmission, COUNT(*) as Count FROM [CARS].[dbo].[car_sales_trends] GROUP BY transmission ORDER BY transmission;
SELECT state, COUNT(*) as Count FROM [CARS].[dbo].[car_sales_trends] GROUP BY state ORDER BY state;

-- 4. Check Aesthetics (Colors)
SELECT color, COUNT(*) as Count FROM [CARS].[dbo].[car_sales_trends] GROUP BY color ORDER BY color;
SELECT interior, COUNT(*) as Count FROM [CARS].[dbo].[car_sales_trends] GROUP BY interior ORDER BY interior;

--Standardize updates
UPDATE [CARS].[dbo].[car_sales_trends]
SET 
    -- 1. Standardize Makes
    make = CASE 
        WHEN make IN ('chev truck') THEN 'Chevrolet'
        WHEN make IN ('dodge tk') THEN 'Dodge'
        WHEN make IN ('ford tk', 'ford truck') THEN 'Ford'
        WHEN make IN ('gmc truck') THEN 'GMC'
        WHEN make IN ('hyundai tk') THEN 'Hyundai'
        WHEN make IN ('mazda tk') THEN 'Mazda'
        WHEN make IN ('mercedes', 'mercedes-b') THEN 'Mercedes-Benz'
        WHEN make IN ('vw') THEN 'Volkswagen'
        WHEN make IN ('landrover') THEN 'Land Rover'
        WHEN make = 'airstream' THEN 'Airstream'
        WHEN make = 'plymouth' THEN 'Plymouth'
        ELSE UPPER(LEFT(make, 1)) + LOWER(SUBSTRING(make, 2, LEN(make))) 
    END,

    -- 2. Standardize Models
    model = CASE 
        WHEN make = 'BMW' AND model = '1' THEN '1 Series'
        WHEN model = '3-Sep' THEN '9-3'
        WHEN model = '5-Sep' THEN '9-5'
        WHEN model IN ('expedit', 'expeditn', 'expedition') THEN 'Expedition'
        WHEN model = 'excurs' THEN 'Excursion'
        WHEN model IN ('twn&country', 'twn/cntry') THEN 'Town and Country'
        WHEN model = 'subrbn' THEN 'Suburban'
        WHEN model = 'mountnr' THEN 'Mountaineer'
        WHEN model = 'ridgelin' THEN 'Ridgeline'
        WHEN model = 'pathfind' THEN 'Pathfinder'
        WHEN model = 'uplandr' THEN 'Uplander'
        WHEN model = 'f150' THEN 'F-150'
        WHEN model = 'f250' THEN 'F-250'
        WHEN model = 'f350' THEN 'F-350'
        WHEN model = 'beetle' THEN 'Beetle'
        WHEN model = 'camry' THEN 'Camry'
        WHEN model = 'corvette' THEN 'Corvette'
        WHEN model = 'cx-7' THEN 'CX-7'
        WHEN model = 'rangerover' THEN 'Range Rover'
        WHEN model = 'dot' THEN 'Unknown'
        ELSE model 
    END,

    -- 3. Standardize Body Types
    body = CASE 
        WHEN body = 'Koup' THEN 'Coupe'
        WHEN body = 'regular-cab' THEN 'Regular Cab'
        ELSE body 
    END,
    -- 4. Standardize Transmission
    transmission = CASE 
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        WHEN transmission = 'Sedan' THEN 'Unknown'
        ELSE transmission 
    END,

    -- 5. Standardize State
    state = CASE 
        WHEN state LIKE '3vw%' THEN 'Unknown'
        ELSE UPPER(TRIM(state))
    END,

    -- 6. Standardize Color (The Dash and Casing Fix)
    color = CASE 
        WHEN TRIM(color) = '—' OR color LIKE '[0-9]%' THEN 'Unknown'
        ELSE UPPER(LEFT(color, 1)) + LOWER(SUBSTRING(color, 2, LEN(color)))
    END,

    -- 7. Standardize Interior (The Dash and Casing Fix)
    interior = CASE 
        WHEN TRIM(interior) = '—' THEN 'Unknown'
        ELSE UPPER(LEFT(interior, 1)) + LOWER(SUBSTRING(interior, 2, LEN(interior)))
    END;

--Data Quality
SELECT 
    -- 1. Check for Zeroes or Nulls or Negatives
    COUNT(CASE WHEN sellingprice <= 0 OR sellingprice IS NULL THEN 1 END) AS Zero_or_Null_Sales,
    COUNT(CASE WHEN mmr <= 0 OR mmr IS NULL THEN 1 END) AS Zero_or_Null_MMR,

    -- 2. Selling Price Stats (CAST to prevent overflow)
    MIN(sellingprice) AS Min_SellingPrice,
    MAX(sellingprice) AS Max_SellingPrice,
    AVG(CAST(sellingprice AS BIGINT)) AS Avg_SellingPrice,

    -- 3. MMR Stats (CAST to prevent overflow)
    MIN(mmr) AS Min_MMR,
    MAX(mmr) AS Max_MMR,
    AVG(CAST(mmr AS BIGINT)) AS Avg_MMR,

    -- 4. The Profit/Loss Margin
    AVG(CAST(sellingprice AS BIGINT) - CAST(mmr AS BIGINT)) AS Avg_Price_Difference
FROM [CARS].[dbo].[car_sales_trends];-- done cleaning dataset

    with cleaned as (
    SELECT *,
      FORMAT(saledate, 'yyyy-MM-dd') AS sale_date_formatted,
      FORMAT(saledate, 'yyyy-MM') AS MONTH_ID,
      FORMAT(saledate, 'yyyy') AS YEARS,
      FORMAT(saledate, 'MMM') AS MONTH,
      FORMAT(saledate, 'ddd') AS WEEKDAYS,
        
      ----time
      FORMAT(saledate, 'HH:mm') AS Time_24hr,

      ---case statement time
      CASE
         WHEN FORMAT(saledate, 'HH:mm') BETWEEN '00:00' AND '05:59' THEN '1.Night (00:00-05:59)'   
         WHEN FORMAT(saledate, 'HH:mm') BETWEEN '06:00' AND '11:59' THEN '2.Morning (06:00-11:59)'
         WHEN FORMAT(saledate, 'HH:mm') BETWEEN '12:00' AND '16:59' THEN '3.Afternoon (12:00-16:59)'
         WHEN FORMAT(saledate, 'HH:mm') BETWEEN '17:00' AND '20:00' THEN '4.Evening (17:00-20:00)'
END as Time_Group ,

---case statement odometer
   CASE
        WHEN odometer BETWEEN 0 AND 25000 THEN '1.Low (0-25K mi)'
        WHEN odometer BETWEEN 25001 AND 75000 THEN '2.Standard (25K-75K mi)'
        WHEN odometer BETWEEN 75001 AND 150000 THEN '3.High (75K-150K mi)'
        ELSE '4.Elevated (150K+ mi)'
    END AS Mileage_Segment,

----CASE STATEMENT CONDITION
    
    CASE
        WHEN condition BETWEEN 37 AND 49 THEN '1.Excellent (>37)'
        WHEN condition BETWEEN 25 AND 36 THEN '2.Good(25-36)'
        WHEN condition BETWEEN 12 AND 24 THEN '3.Fair(12-24)'
        ELSE '4.Poor(<11)'
    END AS Condition_Segment


FROM
    [TEST CARS].[dbo].[car_sales_data]
    )
SELECT 
       -- Financial metrics

    SUM(CAST(sellingprice AS DECIMAL(18, 2))) AS Total_Revenue
    ,
    SUM(CAST(mmr AS DECIMAL(18, 2))) AS Total_Cost
    ,
    SUM(CAST(sellingprice AS DECIMAL(18, 2)) - CAST(mmr AS DECIMAL(18, 2))) AS Total_Gross_Profit
    ,
    --Gross Profit Margin Percentage
    (
    (SUM(CAST(sellingprice AS DECIMAL(18, 2)) - CAST(mmr AS DECIMAL(18, 2))) /  
    NULLIF(SUM(CAST(sellingprice AS DECIMAL(18, 2))), 0)) * 100
    ) AS Gross_Profit_Margin
    ,
    COUNT(model) AS Quantity_Sold
    ,
    AVG(sellingprice) as 'Average revenue'
    
--Question 1
   ,
   Make
  ,Model
  
--Q2The relationship between price, mileage, and year of manufacture

   Mileage_Segment,
   [year]  ,

 --Q3  Which regions or locations have the highest sales volumes 

   [state]

 --Q4 Emerging trends in customer purchasing preferences 

  ,Condition_Segment
  ,body,
   transmission,

   color,
   interior,
   trim
   -----------
   ,MONTH_ID,YEARS,MONTH,WEEKDAYS,Time_24hr,Time_Group 
       ,[year],[condition],[odometer]
      ,[saledate]

FROM 
   cleaned
GROUP BY sale_date_formatted,MONTH_ID,YEARS,MONTH,WEEKDAYS,Time_24hr,Time_Group ,Mileage_Segment,Condition_Segment,
    [year],[make],[model],[trim],[body],[transmission],[vin  ,[state],[condition],[odometer],[color],[interior]
      ,[seller],[mmr],[sellingprice],[saledate]
ORDER BY 
    Total_Revenue DESC;
