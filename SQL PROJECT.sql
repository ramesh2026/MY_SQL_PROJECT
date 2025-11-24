select market
 from dim_customer
where customer = 'Atliq Exclusive' AND region = 'APAC'
order by market;

## QUESTION_2

WITH cte AS (
    SELECT 
        fiscal_year,
        COUNT(DISTINCT product_code) AS unique_products
    FROM gdb023.fact_sales_monthly
    GROUP BY fiscal_year
)
SELECT
    SUM(CASE WHEN fiscal_year = 2020 THEN unique_products END) AS unique_products_2020,
    SUM(CASE WHEN fiscal_year = 2021 THEN unique_products END) AS unique_products_2021,
    ROUND(
        (
            (SUM(CASE WHEN fiscal_year = 2021 THEN unique_products END) -
             SUM(CASE WHEN fiscal_year = 2020 THEN unique_products END)
            )
            /
            SUM(CASE WHEN fiscal_year = 2020 THEN unique_products END)
        ) * 100
    ,2) AS percentage_chg
FROM cte;




##question_3





SELECT
  segment,
  COUNT(DISTINCT product_code) AS product_count
FROM gdb023.dim_product
GROUP BY segment
ORDER BY product_count DESC;




##QUESTION_4



    
    
    
    WITH product_counts AS (
    SELECT
        p.segment,
        s.fiscal_year,
        COUNT(DISTINCT s.product_code) AS unique_products
    FROM gdb023.dim_product p
    JOIN gdb023.fact_sales_monthly s
        ON p.product_code = s.product_code
    WHERE s.fiscal_year IN (2020, 2021)
    GROUP BY p.segment, s.fiscal_year
),

pivoted AS (
    SELECT
        segment,
        SUM(CASE WHEN fiscal_year = 2020 THEN unique_products END) AS product_count_2020,
        SUM(CASE WHEN fiscal_year = 2021 THEN unique_products END) AS product_count_2021
    FROM product_counts
    GROUP BY segment
)

SELECT
    segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM pivoted
ORDER BY difference DESC;



##QUESTION_5




##PART-1 
select 
 p.product_code, p.product,mc.manufacturing_cost
 from dim_product as p
 inner join fact_manufacturing_cost as mc
 on p.product_code=mc.product_code
 where mc.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost);
 ##PART-2
 select 
 p.product_code, p.product,mc.manufacturing_cost
 from dim_product as p
 inner join fact_manufacturing_cost as mc
 on p.product_code=mc.product_code
 where mc.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);
 
 
 
 
 ##QUESTION_6
 
 
 
 
 
 
SELECT
  c.customer_code,
  c.customer,
  ROUND(AVG(f.pre_invoice_discount_pct) * 100, 2) AS average_discount_percentage
FROM gdb023.fact_pre_invoice_deductions f
JOIN gdb023.dim_customer c
  ON f.customer_code = c.customer_code
WHERE f.fiscal_year = 2021
  AND c.market = 'india'
GROUP BY c.customer_code, c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;




####QESTION_7





SELECT
    MONTHNAME(s.date) AS month,
    YEAR(s.date) AS year,
    ROUND(SUM(s.sold_quantity * g.gross_price), 2) AS gross_sales_amount
FROM gdb023.fact_sales_monthly s
JOIN gdb023.fact_gross_price g
    ON s.product_code = g.product_code
   AND s.fiscal_year = g.fiscal_year
JOIN gdb023.dim_customer c
    ON s.customer_code = c.customer_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY year, month
ORDER BY year, MONTH(s.date);




####QUESTION_8






WITH month_data AS (
  SELECT
    
    MONTH(s.date) AS month_number,
    s.sold_quantity
  FROM gdb023.fact_sales_monthly s
  WHERE s.fiscal_year = 2020
)

SELECT
  CASE
    WHEN month_number IN (9,10,11) THEN 'Q1'    -- Sep-Nov => FY Q1
    WHEN month_number IN (12,1,2)  THEN 'Q2'    -- Dec-Feb => FY Q2
    WHEN month_number IN (3,4,5)   THEN 'Q3'    -- Mar-May => FY Q3
    WHEN month_number IN (6,7,8)   THEN 'Q4'    -- Jun-Aug => FY Q4
    ELSE 'Unknown'
  END AS fiscal_quarter,
  SUM(sold_quantity) AS total_sold_quantity
FROM month_data
GROUP BY fiscal_quarter
ORDER BY total_sold_quantity DESC;




###QUESTION__9





SELECT
  channel,
  ROUND(gross_mln, 2) AS gross_sales_mln,
  ROUND((gross_mln / SUM(gross_mln) OVER ()) * 100, 2) AS percentage
FROM (
  SELECT
    c.channel,
    SUM(s.sold_quantity * g.gross_price) / 1000000 AS gross_mln
  FROM gdb023.fact_sales_monthly s
  JOIN gdb023.fact_gross_price g
    ON s.product_code = g.product_code
   AND s.fiscal_year = g.fiscal_year
  JOIN gdb023.dim_customer c
    ON s.customer_code = c.customer_code
  WHERE s.fiscal_year = 2021
  GROUP BY c.channel
) t
ORDER BY gross_sales_mln DESC;




#####QUESTION_10



WITH prod_sales AS (
    SELECT
        p.division,
        s.product_code,
        p.product,
        SUM(s.sold_quantity) AS total_sold_quantity
    FROM gdb023.fact_sales_monthly s
    JOIN gdb023.dim_product p
        ON s.product_code = p.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY p.division, s.product_code, p.product
),
ranked AS (
    SELECT
        division,
        product_code,
        product,
        total_sold_quantity,
        RANK() OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
    FROM prod_sales
)

SELECT *
FROM ranked
WHERE rank_order <= 3
ORDER BY division, rank_order;
