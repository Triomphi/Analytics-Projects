-- 1.1
-- Create a detailed overview of all individual customers. 
-- Individual customers are defined by CustomerType = 'I' and/or are stored in the individual customer table.

WITH -- Subquery TO find customers CURRENT address
latest_address AS(
    SELECT
        customer_addr.CustomerID,
        MAX(customer_addr.AddressID) AS ID
    FROM
        `adwentureworks_db.customeraddress` AS customer_addr
    GROUP BY
        customer_addr.CustomerID
),
-- Subquery TO find customer ORDER details
order_info AS (
    SELECT
        sales_order.CustomerID,
        COUNT(*) AS num_orders,
        ROUND(SUM(TotalDue), 3) AS total_amount,
        MAX(OrderDate) AS last_order_date
    FROM
        `adwentureworks_db.salesorderheader` AS sales_order
    GROUP BY
        CustomerID
) -- Main query TO find top 200 Individual customers
SELECT
    individual.CustomerID,
    contact.Firstname,
    contact.LastName,
    CONCAT(contact.Firstname, ' ', contact.LastName) AS FullName,
    CONCAT(
        COALESCE(contact.Title, 'Dear'),
        ' ',
        contact.LastName
    ) AS addressing_title,
    contact.Emailaddress,
    contact.Phone,
    customer.AccountNumber,
    customer.CustomerType,
    address.AddressLine1,
    COALESCE(address.AddressLine2, ' ') AS AddressLine2,
    address.City,
    state.Name AS State,
    country.Name AS Country,
    order_info.num_orders,
    order_info.total_amount,
    order_info.last_order_date
FROM
    `adwentureworks_db.individual` AS individual
    INNER JOIN `adwentureworks_db.contact` AS contact ON individual.ContactID = contact.ContactId
    INNER JOIN `tc-da-1.adwentureworks_db.customer` AS customer ON customer.CustomerID = individual.CustomerID
    INNER JOIN `adwentureworks_db.customeraddress` AS customer_address ON customer.CustomerID = customer_address.CustomerID
    INNER JOIN `adwentureworks_db.address` AS address ON address.AddressID = customer_address.AddressID
    INNER JOIN latest_address ON address.AddressID = latest_address.ID
    INNER JOIN `adwentureworks_db.stateprovince` AS state ON address.StateProvinceID = state.StateProvinceID
    INNER JOIN `adwentureworks_db.countryregion` AS country ON state.CountryRegionCode = country.CountryRegionCode
    INNER JOIN order_info ON order_info.CustomerID = individual.CustomerID
ORDER BY
    order_info.total_amount DESC
LIMIT
    200

-- 1.2
-- The business found the original query valuable and now wants to extend it. 
-- Specifically, they need the data for the top 200 customers with the highest total amount (including tax) who have not placed an order in the last 365 days.

WITH -- subquery to find customers current address
latest_address AS(
    SELECT
        customer_addr.CustomerID,
        MAX(customer_addr.AddressID) AS ID
    FROM
        `adwentureworks_db.customeraddress` AS customer_addr
    GROUP BY
        customer_addr.CustomerID
),
-- subquery to find customer order details
order_info AS (
    SELECT
        sales_order.CustomerID,
        COUNT(*) AS num_orders,
        ROUND(SUM(TotalDue), 3) AS total_amount,
        MAX(OrderDate) AS last_order_date
    FROM
        `adwentureworks_db.salesorderheader` AS sales_order
    GROUP BY
        CustomerID
),
-- subquery to find top 200 customers
top_200_customers AS (
    SELECT
        individual.CustomerID,
        contact.Firstname,
        contact.LastName,
        CONCAT(contact.Firstname, ' ', contact.LastName) AS FullName,
        CONCAT(
            COALESCE(contact.Title, 'Dear'),
            ' ',
            contact.LastName
        ) AS addressing_title,
        contact.Emailaddress,
        contact.Phone,
        customer.AccountNumber,
        customer.CustomerType,
        address.AddressLine1,
        COALESCE(address.AddressLine2, ' ') AS AddressLine2,
        address.City,
        state.Name AS State,
        country.Name AS Country,
        order_info.num_orders,
        order_info.total_amount,
        order_info.last_order_date,
    FROM
        `adwentureworks_db.individual` AS individual
        INNER JOIN `adwentureworks_db.contact` AS contact ON individual.ContactID = contact.ContactId
        INNER JOIN `tc-da-1.adwentureworks_db.customer` AS customer ON customer.CustomerID = individual.CustomerID
        INNER JOIN `adwentureworks_db.customeraddress` AS cust_addr ON customer.CustomerID = cust_addr.CustomerID
        INNER JOIN `adwentureworks_db.address` AS address ON address.AddressID = cust_addr.AddressID
        INNER JOIN latest_address ON address.AddressID = latest_address.ID
        INNER JOIN `adwentureworks_db.stateprovince` AS state ON address.StateProvinceID = state.StateProvinceID
        INNER JOIN `adwentureworks_db.countryregion` AS country ON state.CountryRegionCode = country.CountryRegionCode
        INNER JOIN order_info ON order_info.CustomerID = individual.CustomerID
    ORDER BY
        order_info.total_amount DESC
    LIMIT
        200
) -- main query to find top 200 customers who have not ordered in the last 365 days
SELECT
    *
FROM
    top_200_customers
WHERE
    top_200_customers.last_order_date < (
        (
            SELECT
                MAX(OrderDate) -- 2004-07-31 00:00:00 UTC
            FROM
                `adwentureworks_db.salesorderheader`
        ) - INTERVAL 365 day
    )

-- 1.3
-- Enhance your original 1.1 SELECT by adding a new column that flags customers as Active or Inactive, based on whether they have placed an order within the last 365 days.
--Return only the top 500 rows, ordered by CustomerId in descending order.

WITH -- Subquery to find customers current address
latest_address AS(
    SELECT
        customer_addr.CustomerID,
        MAX(customer_addr.AddressID) AS ID
    FROM
        `adwentureworks_db.customeraddress` AS customer_addr
    GROUP BY
        customer_addr.CustomerID
),
-- subquery to find customers order details
order_info AS (
    SELECT
        sales_order.CustomerID,
        COUNT(*) AS num_orders,
        ROUND(SUM(TotalDue), 3) AS total_amount,
        MAX(OrderDate) AS last_order_date
    FROM
        `adwentureworks_db.salesorderheader` AS sales_order
    GROUP BY
        CustomerID
) -- Main query to identify active and inactive customers
SELECT
    individual.CustomerID,
    contact.Firstname,
    contact.LastName,
    CONCAT(contact.Firstname, ' ', contact.LastName) AS FullName,
    CONCAT(
        COALESCE(contact.Title, 'Dear'),
        ' ',
        contact.LastName
    ) AS addressing_title,
    contact.Emailaddress,
    contact.Phone,
    customer.AccountNumber,
    customer.CustomerType,
    address.AddressLine1,
    COALESCE(address.AddressLine2, ' ') AS AddressLine2,
    address.City,
    state.Name AS State,
    country.Name AS Country,
    order_info.num_orders,
    order_info.total_amount,
    order_info.last_order_date,
    CASE
        WHEN order_info.last_order_date < (
            select
                DATE_SUB(MAX(OrderDate), INTERVAL 365 DAY)
            from
                `adwentureworks_db.salesorderheader`
        ) THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status,
FROM
    `adwentureworks_db.individual` AS individual
    INNER JOIN `adwentureworks_db.contact` AS contact ON individual.ContactID = contact.ContactId
    INNER JOIN `tc-da-1.adwentureworks_db.customer` AS customer ON customer.CustomerID = individual.CustomerID
    INNER JOIN `adwentureworks_db.customeraddress` AS cust_addr ON customer.CustomerID = cust_addr.CustomerID
    INNER JOIN `adwentureworks_db.address` AS address ON address.AddressID = cust_addr.AddressID
    INNER JOIN latest_address ON address.AddressID = latest_address.ID
    INNER JOIN `adwentureworks_db.stateprovince` AS state ON address.StateProvinceID = state.StateProvinceID
    INNER JOIN `adwentureworks_db.countryregion` AS country ON state.CountryRegionCode = country.CountryRegionCode
    INNER JOIN order_info ON order_info.CustomerID = individual.CustomerID
ORDER BY
    order_info.CustomerID DESC
LIMIT
    500

-- 1.4
-- The business requires data on all active customers from North America. Only include customers who meet either of the following criteria:
-- Total amount (with tax) is no less than 2500, or They have placed 5 or more orders.
-- Additionally, split the customers' address into two separate columns (Address No and Address Str) in the output.

WITH -- subquery to find customers current address
latest_address AS(
    SELECT
        customer_addr.CustomerID,
        MAX(customer_addr.AddressID) AS ID
    FROM
        `adwentureworks_db.customeraddress` AS customer_addr
    GROUP BY
        customer_addr.CustomerID
),
-- Subquery to get customer order details
order_info AS (
    SELECT
        sales_order.CustomerID,
        COUNT(*) AS num_orders,
        ROUND(SUM(TotalDue), 3) AS total_amount,
        MAX(OrderDate) AS last_order
    FROM
        `adwentureworks_db.salesorderheader` AS sales_order
    GROUP BY
        CustomerID
),
-- subquery to find customers in North America
north_america_customers AS (
    SELECT
        customer.CustomerID,
        territory.TerritoryID
    FROM
        `adwentureworks_db.customer` AS customer
        INNER JOIN `adwentureworks_db.salesterritory` AS territory ON customer.TerritoryID = territory.TerritoryID
    WHERE
        territory.Group = 'North America'
) -- Main query to find active customers in North America
SELECT
    individual.CustomerID,
    contact.Firstname,
    contact.LastName,
    CONCAT(contact.Firstname, ' ', contact.LastName) AS FullName,
    CONCAT(
        COALESCE(contact.Title, 'Dear'),
        ' ',
        contact.LastName
    ) AS addressing_title,
    contact.Emailaddress,
    contact.Phone,
    customer.AccountNumber,
    customer.CustomerType,
    LEFT(
        address.AddressLine1,
        STRPOS(address.AddressLine1, ' ')
    ) AS address_no,
    RIGHT(
        address.AddressLine1,
        LENGTH(address.AddressLine1) - STRPOS(address.AddressLine1, ' ')
    ) AS Address_st,
    COALESCE(address.AddressLine2, ' ') AS AddressLine2,
    address.City,
    state.Name AS State,
    country.Name AS Country,
    order_info.num_orders,
    order_info.total_amount,
    order_info.last_order,
    CASE
        WHEN order_info.last_order < (
            select
                DATE_SUB(MAX(OrderDate), INTERVAL 365 DAY)
            from
                `adwentureworks_db.salesorderheader`
        ) THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status,
FROM
    `adwentureworks_db.individual` AS individual
    INNER JOIN `adwentureworks_db.contact` AS contact ON individual.ContactID = contact.ContactId
    INNER JOIN `tc-da-1.adwentureworks_db.customer` AS customer ON customer.CustomerID = individual.CustomerID
    INNER JOIN `adwentureworks_db.customeraddress` AS cust_addr ON customer.CustomerID = cust_addr.CustomerID
    INNER JOIN `adwentureworks_db.address` AS address ON address.AddressID = cust_addr.AddressID
    INNER JOIN latest_address ON address.AddressID = latest_address.ID
    INNER JOIN `adwentureworks_db.stateprovince` AS state ON address.StateProvinceID = state.StateProvinceID
    INNER JOIN `adwentureworks_db.countryregion` AS country ON state.CountryRegionCode = country.CountryRegionCode
    INNER JOIN order_info ON order_info.CustomerID = individual.CustomerID
    INNER JOIN north_america_customers AS na ON na.CustomerID = individual.CustomerID
WHERE
    order_info.last_order > (
        select
            DATE_SUB(MAX(OrderDate), INTERVAL 365 DAY)
        from
            `adwentureworks_db.salesorderheader`
    )
    AND (
        order_info.total_amount >= 2500
        OR order_info.num_orders > 5
    )
ORDER BY
    Country,
    State,
    order_info.last_order
LIMIT
    500