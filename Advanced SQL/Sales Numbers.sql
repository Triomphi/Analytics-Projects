-- 2.1 
-- Create a query to report monthly sales figures by Country and Region. For each month, include:
-- Number of orders, Number of unique customers, Number of salespersons, and Total amount (with tax) earned

SELECT
    LAST_DAY(DATE(sales.OrderDate), MONTH) AS month,
    territory.CountryRegionCode,
    territory.Name AS region,
    COUNT(sales.SalesOrderID) AS num_order,
    COUNT(DISTINCT sales.CustomerID) AS num_customer,
    COUNT(DISTINCT sales.SalesPersonID) AS num_sales_person,
    ROUND(SUM(sales.TotalDue), 0) AS total_w_tax
FROM
    `adwentureworks_db.salesorderheader` AS sales
    INNER JOIN `adwentureworks_db.salesterritory` AS territory ON territory.TerritoryID = sales.TerritoryID
GROUP BY
    month,
    territory.CountryRegionCode,
    territory.Name

-- 2.2 
-- Enhance the 2.1 query by adding a cumulative sum of the total amount (with tax) earned, calculated per Country and Region.

WITH -- Subquery to get monthly sales data
monthly_sales AS (
    SELECT
        LAST_DAY(DATE(sales.OrderDate), MONTH) AS month,
        territory.CountryRegionCode,
        territory.Name AS region,
        COUNT(sales.SalesOrderID) AS num_order,
        COUNT(DISTINCT sales.CustomerID) AS num_customer,
        COUNT(DISTINCT sales.SalesPersonID) AS num_sales_person,
        ROUND(SUM(sales.TotalDue), 0) AS total_w_tax
    FROM
        `adwentureworks_db.salesorderheader` AS sales
        INNER JOIN `adwentureworks_db.salesterritory` AS territory ON territory.TerritoryID = sales.TerritoryID
    GROUP BY
        month,
        territory.CountryRegionCode,
        territory.Name
) -- Main Query
SELECT
    month,
    CountryRegionCode,
    region,
    num_order,
    num_customer,
    num_sales_person,
    total_w_tax,
    SUM(total_w_tax) OVER (
        PARTITION BY CountryRegionCode
        ORDER BY
            month
    ) AS cumulative_sum
FROM
    monthly_sales

-- 2.3 
-- Enhance the 2.2 query by adding a sales_rank column that ranks rows from highest to lowest total amount (with tax) earned per country and month.
-- For each country, assign rank 1 to the region with the highest total amount in a given month, and so on.

WITH -- Subquery to find monthly sales data
monthly_sales AS (
    SELECT
        LAST_DAY(DATE(sales.OrderDate), MONTH) AS month,
        territory.CountryRegionCode,
        territory.Name AS region,
        COUNT(sales.SalesOrderID) AS num_order,
        COUNT(DISTINCT sales.CustomerID) AS num_customer,
        COUNT(DISTINCT sales.SalesPersonID) AS num_sales_person,
        ROUND(SUM(sales.TotalDue)) AS total_w_tax
    FROM
        `adwentureworks_db.salesorderheader` AS sales
        INNER JOIN `adwentureworks_db.salesterritory` AS territory ON territory.TerritoryID = sales.TerritoryID
    GROUP BY
        month,
        territory.CountryRegionCode,
        territory.Name
) -- Main Query
SELECT
    month,
    CountryRegionCode,
    region,
    num_order,
    num_customer,
    num_sales_person,
    total_w_tax,
    RANK() OVER (
        PARTITION BY CountryRegionCode
        ORDER BY
            total_w_tax DESC
    ) AS sales_rank,
    SUM(total_w_tax) OVER (
        PARTITION BY CountryRegionCode
        ORDER BY
            month
    ) AS cumulative_sum
FROM
    monthly_sales -- WHERE region = 'France'
ORDER BY
    sales_rank

-- 2.4 
-- Enhance the 2.3 query by adding country-level tax details. Since tax rates can vary by province, include the mean_tax_rate column to reflect the average tax rate per country. 
-- Additionally, for transparency, add the perc_provinces_w_tax column to show the percentage of provinces with available tax data for each country.

WITH -- Subquery to find the maximum tax rate in each province
max_tax AS (
    SELECT
        StateProvinceID,
        MAX(taxrate) AS highest_taxrate
    FROM
        `adwentureworks_db.salestaxrate`
    GROUP BY
        StateProvinceID
),
-- Subquery to find the number of provinces and provinces with tax in each country
Province_tax_info AS (
    SELECT
        sp.CountryRegionCode,
        COUNT(sp.StateProvinceID) AS total_provinces,
        COUNT(DISTINCT max_tax.StateProvinceID) AS provinces_with_tax
    FROM
        `adwentureworks_db.stateprovince` AS sp
        LEFT JOIN max_tax ON max_tax.StateProvinceID = sp.StateProvinceID
    GROUP BY
        sp.CountryRegionCode
),
-- Subquery to find the mean tax rate and percentage of provinces with tax rates for each country
country_tax_rate AS (
    SELECT
        Province_tax_info.CountryRegionCode,
        ROUND(AVG(max_tax.highest_taxrate), 1) AS avg_tax_rate,
        ROUND(
            Province_tax_info.provinces_with_tax / Province_tax_info.total_provinces,
            2
        ) AS perc_prov_w_tax
    FROM
        max_tax
        INNER JOIN `adwentureworks_db.stateprovince` AS state ON state.StateProvinceID = max_tax.stateprovinceid
        INNER JOIN Province_tax_info ON state.CountryRegionCode = Province_tax_info.CountryRegionCode
    GROUP BY
        Province_tax_info.CountryRegionCode,
        Province_tax_info.total_provinces,
        Province_tax_info.provinces_with_tax
),
-- Subquery to get monthly sales data
monthly_sales AS (
    SELECT
        LAST_DAY(DATE(sales.OrderDate), MONTH) AS month,
        territory.CountryRegionCode,
        territory.Name AS region,
        COUNT(sales.SalesOrderID) AS num_order,
        COUNT(DISTINCT sales.CustomerID) AS num_customer,
        COUNT(DISTINCT sales.SalesPersonID) AS num_sales_person,
        ROUND(SUM(sales.TotalDue)) AS total_w_tax
    FROM
        `adwentureworks_db.salesorderheader` AS sales
        INNER JOIN `adwentureworks_db.salesterritory` AS territory ON territory.TerritoryID = sales.TerritoryID
    GROUP BY
        month,
        territory.CountryRegionCode,
        territory.Name
) -- Main query
SELECT
    ms.month,
    ms.CountryRegionCode,
    ms.region,
    ms.num_order,
    ms.num_customer,
    ms.num_sales_person,
    ms.total_w_tax,
    RANK() OVER (
        PARTITION BY ms.CountryRegionCode
        ORDER BY
            ms.total_w_tax DESC
    ) AS sales_rank,
    SUM(ms.total_w_tax) OVER (
        PARTITION BY ms.CountryRegionCode
        ORDER BY
            ms.month
    ) AS cumulative_sum,
    ctr.avg_tax_rate,
    ctr.perc_prov_w_tax
FROM
    monthly_sales AS ms
    LEFT JOIN country_tax_rate AS ctr ON ms.CountryRegionCode = ctr.CountryRegionCode --WHERE
    --ms.CountryRegionCode = 'US'
ORDER BY
    sales_rank;