-- Calculate rfm_values
WITH
  fre_and_mon AS(
  SELECT
    CustomerID,
    MAX(CAST(InvoiceDate AS date)) AS last_purchase_date,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    SUM(Quantity*UnitPrice) AS monetary
  FROM
    `tc-da-1.turing_data_analytics.rfm`
  WHERE
    CAST(InvoiceDate AS date) BETWEEN '2010-12-01'
    AND '2011-12-01'
  GROUP BY
    1
  )
SELECT
  CustomerID,
  DATE_DIFF('2011-12-01', fre_and_mon.last_purchase_date, day) AS recency,
  fre_and_mon.frequency, 
  fre_and_mon.monetary
FROM
  fre_and_mon



-- Calculate rfm_quantiles
WITH
  fre_and_mon AS(
  SELECT
    CustomerID,
    MAX(CAST(InvoiceDate AS date)) AS last_purchase_date,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    SUM(Quantity*UnitPrice) AS monetary
  FROM
    `tc-da-1.turing_data_analytics.rfm`
  WHERE
    CAST(InvoiceDate AS date) BETWEEN '2010-12-01'
    AND '2011-12-01'
  GROUP BY
    1 ),
  
  rfm_values AS (
  SELECT
    *,
    DATE_DIFF('2011-12-01', fre_and_mon.last_purchase_date, day) AS recency,
  FROM
    fre_and_mon)

SELECT
  m.percentiles[OFFSET(25)] AS m25,
  m.percentiles[OFFSET(50)] AS m50,
  m.percentiles[OFFSET(75)] AS m75,
  f.percentiles[OFFSET(25)] AS f25,
  f.percentiles[OFFSET(50)] AS f50,
  f.percentiles[OFFSET(75)] AS f75,
  r.percentiles[OFFSET(25)] AS r25,
  r.percentiles[OFFSET(50)] AS r50,
  r.percentiles[OFFSET(75)] AS r75
FROM (
  SELECT
    APPROX_QUANTILES(monetary, 100) AS percentiles
  FROM
    rfm_values) AS m,
  (
  SELECT
    APPROX_QUANTILES(frequency, 100) AS percentiles
  FROM
    rfm_values) AS f,
  (
  SELECT
    APPROX_QUANTILES(recency, 100) AS percentiles
  FROM
    rfm_values) AS r


-- Calculate rfm_scores
WITH
  fre_and_mon AS(
  SELECT
    CustomerID,
    MAX(CAST(InvoiceDate AS date)) AS last_purchase_date,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    SUM(Quantity*UnitPrice) AS monetary
  FROM
    `tc-da-1.turing_data_analytics.rfm`
  WHERE
    CAST(InvoiceDate AS date) BETWEEN '2010-12-01'
    AND '2011-12-01'
  GROUP BY
    1 ),
  
  rfm_values AS (
  SELECT
    *,
    DATE_DIFF('2011-12-01', fre_and_mon.last_purchase_date, day) AS recency,
  FROM
    fre_and_mon),
  rfm_quantiles AS (
  SELECT 
    rfm_values.*,
    m.percentiles[OFFSET(25)] AS m25,
    m.percentiles[OFFSET(50)] AS m50,
    m.percentiles[OFFSET(75)] AS m75,
    f.percentiles[OFFSET(25)] AS f25,
    f.percentiles[OFFSET(50)] AS f50,
    f.percentiles[OFFSET(75)] AS f75,
    r.percentiles[OFFSET(25)] AS r25,
    r.percentiles[OFFSET(50)] AS r50,
    r.percentiles[OFFSET(75)] AS r75
  FROM rfm_values,
  (
    SELECT
      APPROX_QUANTILES(monetary, 100) AS percentiles
    FROM
      rfm_values) AS m,
    (
    SELECT
      APPROX_QUANTILES(frequency, 100) AS percentiles
    FROM
      rfm_values) AS f,
    (
    SELECT
      APPROX_QUANTILES(recency, 100) AS percentiles
    FROM
      rfm_values) AS r)

SELECT 
  CONCAT(r_score,f_score,m_score) as rfm_score,
  COUNT(*) as n
FROM (
  SELECT 
  CASE 
    WHEN monetary <= m25 THEN 1
    WHEN monetary > m25 AND monetary <=m50 THEN 2
    WHEN monetary > m50 AND monetary <=m75 THEN 3
    WHEN monetary > m75 THEN 4
    END AS m_score,
  CASE 
    WHEN frequency <= f25 THEN 1
    WHEN frequency > f25 AND frequency <=f50 THEN 2
    WHEN frequency > f50 AND frequency <=f75 THEN 3
    WHEN frequency > f75 THEN 4
    END AS f_score,
  CASE 
    WHEN recency <= r25 THEN 4
    WHEN recency > r25 AND recency <=r50 THEN 3
    WHEN recency > r50 AND recency <=r75 THEN 2
    WHEN recency > r75 THEN 1
    END AS r_score
  FROM rfm_quantiles
)   
GROUP BY 1
ORDER BY n 


-- Segment customers
WITH
  fre_and_mon AS(
  SELECT
    CustomerID,
    Country,
    MAX(CAST(InvoiceDate AS date)) AS last_purchase_date,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    SUM(Quantity*UnitPrice) AS monetary
  FROM
    `tc-da-1.turing_data_analytics.rfm`
  WHERE
    CAST(InvoiceDate AS date) BETWEEN '2010-12-01'
    AND '2011-12-01'
  GROUP BY
    1,
    2 ),
  
  rfm_values AS (
  SELECT
    *,
    DATE_DIFF('2011-12-01', fre_and_mon.last_purchase_date, day) AS recency
  FROM
    fre_and_mon),

  rfm_quantiles AS (
  SELECT 
    rfm_values.*,
    m.percentiles[OFFSET(25)] AS m25,
    m.percentiles[OFFSET(50)] AS m50,
    m.percentiles[OFFSET(75)] AS m75,
    f.percentiles[OFFSET(25)] AS f25,
    f.percentiles[OFFSET(50)] AS f50,
    f.percentiles[OFFSET(75)] AS f75,
    r.percentiles[OFFSET(25)] AS r25,
    r.percentiles[OFFSET(50)] AS r50,
    r.percentiles[OFFSET(75)] AS r75
  FROM rfm_values,
  (
    SELECT
      APPROX_QUANTILES(monetary, 100) AS percentiles
    FROM
      rfm_values) AS m,
    (
    SELECT
      APPROX_QUANTILES(frequency, 100) AS percentiles
    FROM
      rfm_values) AS f,
    (
    SELECT
      APPROX_QUANTILES(recency, 100) AS percentiles
    FROM
      rfm_values) AS r),

  rfm_score AS (
  SELECT 
    *,
    CAST(ROUND((f_score + m_score)/2,0) AS INT64) AS fm_score
  FROM (
    SELECT 
    *,
    CASE 
      WHEN monetary <= m25 THEN 1
      WHEN monetary > m25 AND monetary <=m50 THEN 2
      WHEN monetary > m50 AND monetary <=m75 THEN 3
      WHEN monetary > m75 THEN 4
      END AS m_score,
    CASE 
      WHEN frequency <= f25 THEN 1
      WHEN frequency > f25 AND frequency <=f50 THEN 2
      WHEN frequency > f50 AND frequency <=f75 THEN 3
      WHEN frequency > f75 THEN 4
      END AS f_score,
    CASE 
      WHEN recency <= r25 THEN 4
      WHEN recency > r25 AND recency <=r50 THEN 3
      WHEN recency > r50 AND recency <=r75 THEN 2
      WHEN recency > r75 THEN 1
      END AS r_score
    FROM rfm_quantiles
  )   
)
SELECT 
  CustomerID, 
  Country,
  recency,
  frequency, 
  monetary,
  r_score,
  f_score,
  m_score,
  fm_score,
  CASE 
    WHEN (r_score = 4 AND fm_score = 4) THEN 'Champions'
    WHEN (r_score IN (3, 4) AND fm_score IN (3, 4)) THEN 'Loyal Customers'
    WHEN (r_score = 4 AND fm_score IN (2, 3)) THEN 'Potential Loyalists'
    WHEN (r_score = 4 AND fm_score = 1) THEN 'Recent Customers'
    WHEN (r_score = 3 AND fm_score IN (2, 3)) THEN 'Promising'
    WHEN (r_score = 2 AND fm_score IN (2, 3)) OR (r_score = 3 AND fm_score = 1) THEN 'Customers Needing Attention'
    WHEN (r_score = 2 AND fm_score = 1) THEN 'About to Sleep'
    WHEN (r_score = 2 AND fm_score = 4) OR (r_score = 1 AND fm_score IN (3, 4)) THEN 'At Risk'
    WHEN (r_score = 1 AND fm_score = 4) THEN 'Cant Lose Them'
    WHEN (r_score = 1 AND fm_score IN (1, 2)) THEN 'Hibernating'
    WHEN (r_score = 1 AND fm_score = 1) THEN 'Lost'
END AS rfm_segment 
FROM rfm_score