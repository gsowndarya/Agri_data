create schema agri_data;

use agri_data;

select * from df;
select * from df_info;
select * from df_crop;

-- 1.Year-wise Trend of Rice Production Across States (Top 3)

WITH rice_sum AS (
    SELECT
        info.year,
        info.state_name,
        ROUND(SUM(crop.rice_production_tons), 2) AS total_rice_production
    FROM df_crop crop
    JOIN df_info info 
        ON crop.dist_name = info.dist_name
    GROUP BY info.year, info.state_name
),

ranked_rice AS (
    SELECT 
        year,
        state_name,
        total_rice_production,
        ROW_NUMBER() OVER (
            PARTITION BY year 
            ORDER BY total_rice_production DESC
        ) AS rank_rice
    FROM rice_sum
)
SELECT 
    year,
    state_name,
    total_rice_production
FROM ranked_rice
WHERE rank_rice <= 3
ORDER BY year ASC, total_rice_production DESC;

-- 2.Top 5 Districts by Wheat Yield Increase Over the Last 5 Years

WITH yield_data AS (
    SELECT 
        dist_name,
        year,
        wheat_yield_ha
    FROM df
    WHERE year IN (2012, 2017)
),

yield_year AS (
    SELECT 
        dist_name,
        MAX(CASE WHEN year = 2012 THEN wheat_yield_ha END) AS yield_2012,
        MAX(CASE WHEN year = 2017 THEN wheat_yield_ha END) AS yield_2017
    FROM yield_data
    GROUP BY dist_name
),

yield_diff AS (
    SELECT 
        dist_name,
        yield_2012,
        yield_2017,
        ROUND(yield_2017 - yield_2012, 2) AS yield_increase
    FROM yield_year
    WHERE yield_2012 IS NOT NULL AND yield_2017 IS NOT NULL
)

SELECT 
    dist_name,
    yield_2012,
    yield_2017,
    yield_increase
FROM yield_diff
ORDER BY yield_increase DESC
LIMIT 7;

-- 3.States with the Highest Growth in Oilseed Production (5-Year Growth Rate)

WITH oilseed_years AS (
    SELECT 
        state_name,
        year,
        ROUND(SUM(oilseeds_production_tons),2) AS total_production
    FROM df
    WHERE year IN (2012, 2017)
    GROUP BY state_name, year
),
pivot_production AS (
    SELECT 
        state_name,
        MAX(CASE WHEN year = 2012 THEN total_production END) AS prod_2012,
        MAX(CASE WHEN year = 2017 THEN total_production END) AS prod_2017
    FROM oilseed_years
    GROUP BY state_name
),
growth_calc AS (
    SELECT 
        state_name,
        prod_2012,
        prod_2017,
        ROUND(((prod_2017 - prod_2012) / NULLIF(prod_2012, 0)) * 100, 2) AS growth_rate_percent
    FROM pivot_production
    WHERE prod_2012 IS NOT NULL AND prod_2017 IS NOT NULL
)
SELECT 
    state_name,
    prod_2012,
    prod_2017,
    growth_rate_percent
FROM growth_calc
ORDER BY growth_rate_percent DESC
LIMIT 8;

-- 4.District-wise Correlation Between Area and Production for Major Crops (Rice, Wheat, and Maize)

WITH rice_corr AS (
    SELECT 
        dist_name,
        ROUND( 
            (SUM(rice_area_ha * rice_production_tons) - SUM(rice_area_ha) * SUM(rice_production_tons) / COUNT(*))
            /
            (SQRT(SUM(rice_area_ha * rice_area_ha) - POWER(SUM(rice_area_ha), 2) / COUNT(*)) *
             SQRT(SUM(rice_production_tons * rice_production_tons) - POWER(SUM(rice_production_tons), 2) / COUNT(*))),
            2
        ) AS rice_corr
    FROM df
    GROUP BY dist_name
),
wheat_corr AS (
    SELECT 
        dist_name,
        ROUND( 
            (SUM(wheat_area_ha * wheat_production_tons) - SUM(wheat_area_ha) * SUM(wheat_production_tons) / COUNT(*))
            /
            (SQRT(SUM(wheat_area_ha * wheat_area_ha) - POWER(SUM(wheat_area_ha), 2) / COUNT(*)) *
             SQRT(SUM(wheat_production_tons * wheat_production_tons) - POWER(SUM(wheat_production_tons), 2) / COUNT(*))),
            2
        ) AS wheat_corr
    FROM df
    GROUP BY dist_name
),
maize_corr AS (
    SELECT 
        dist_name,
        ROUND( 
            (SUM(maize_area_ha * maize_production_tons) - SUM(maize_area_ha) * SUM(maize_production_tons) / COUNT(*))
            /
            (SQRT(SUM(maize_area_ha * maize_area_ha) - POWER(SUM(maize_area_ha), 2) / COUNT(*)) *
             SQRT(SUM(maize_production_tons * maize_production_tons) - POWER(SUM(maize_production_tons), 2) / COUNT(*))),
            2
        ) AS maize_corr
    FROM df
    GROUP BY dist_name
)

SELECT 
    r.dist_name,
    r.rice_corr,
    w.wheat_corr,
    m.maize_corr
FROM rice_corr r
JOIN wheat_corr w ON r.dist_name = w.dist_name
JOIN maize_corr m ON r.dist_name = m.dist_name
ORDER BY r.dist_name;

-- 5.Yearly Production Growth of Cotton in Top 5 Cotton Producing States

WITH State_Cotton_Production AS (
    SELECT 
        i.state_name,
        i.year,
        SUM(c.cotton_production_tons) AS cotton_prod
    FROM df_crop AS c
    JOIN df_info AS i ON c.dist_name = i.dist_name
    GROUP BY i.state_name, i.year
),
Top_States AS (
    SELECT 
        state_name,
        ROUND(SUM(cotton_prod),2) AS total_cotton_prod
    FROM State_Cotton_Production
    GROUP BY state_name
    ORDER BY total_cotton_prod DESC
    LIMIT 5
)
SELECT 
    scp.state_name,
    scp.year,
    scp.cotton_prod
FROM State_Cotton_Production scp
JOIN Top_States ts ON scp.state_name = ts.state_name
ORDER BY scp.state_name, scp.year;
      
-- 6.Districts with the Highest Groundnut Production in 2017

SELECT 
    dist_name,
    groundnut_production_tons
FROM df
WHERE year = 2017
ORDER BY groundnut_production_tons DESC
LIMIT 10;

-- 7.Annual Average Maize Yield Across All States

SELECT 
    year,
    ROUND(AVG(maize_yield_ha), 2) AS avg_maize_yield
FROM df
GROUP BY year
ORDER BY year;


-- 8.Total Area Cultivated for Oilseeds in Each State

SELECT 
    state_name,
    ROUND(SUM(oilseeds_area_ha), 2) AS total_oilseeds_area_ha
FROM df
GROUP BY state_name
ORDER BY total_oilseeds_area_ha DESC;


-- 9.Districts with the Highest Rice Yield

SELECT 
    dist_name,
    ROUND(SUM(rice_yield_ha), 2) AS sum_rice_yield_ha
FROM df_crop
GROUP BY dist_name
ORDER BY sum_rice_yield_ha DESC
LIMIT 10;


-- 10.Compare the Production of Wheat and Rice for the Top 5 States Over 10 Years

WITH State_Production AS (
    SELECT 
        i.state_name,
        i.year,
        ROUND(SUM(c.wheat_production_tons),2) AS wheat_prod,
        ROUND(SUM(c.rice_production_tons),2) AS rice_prod
    FROM df_crop AS c
    JOIN df_info AS i ON c.dist_name = i.dist_name
    WHERE i.year BETWEEN 2008 AND 2017
    GROUP BY i.state_name, i.year
),
Top_States AS (
    SELECT 
        state_name,
        ROUND(SUM(wheat_prod + rice_prod),2) AS total_prod
    FROM State_Production
    GROUP BY state_name
    ORDER BY total_prod DESC
    LIMIT 5
)
SELECT 
    sp.state_name,
    sp.year,
    sp.wheat_prod,
    sp.rice_prod
FROM State_Production sp
JOIN Top_States ts ON sp.state_name = ts.state_name
ORDER BY sp.state_name, sp.year;
 