    
    with cleaned as (
    SELECT 
    
      *,
      FORMAT(saledate, 'yyyy-MM-dd') AS sale_date_formatted,
      FORMAT(saledate, 'yyyy-MM') AS MONTH_ID,
      FORMAT(saledate, 'yyyy') AS YEARS,
      FORMAT(saledate, 'MMM') AS MONTH,
      FORMAT(saledate, 'ddd') AS WEEKDAYS,
      ----time
      FORMAT(saledate, 'HH:mm') AS Time_24hr,

      ---case statement
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
    [year]
      ,[make]
      ,[model]
      ,[trim]
      ,[body]
      ,[transmission]
      ,[vin]
      ,[state]
      ,[condition]
      ,[odometer]
      ,[color]
      ,[interior]
      ,[seller]
      ,[mmr]
      ,[sellingprice]
      ,[saledate]
ORDER BY 
    Total_Revenue DESC;
