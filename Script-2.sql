SELECT cbd.country, 
	cbd.date, 
	CASE 
		WHEN weekday(cbd.date) in (5,6) Then 1
		ELSE 0
	END as weekend,
	CASE
		WHEN month(cbd.date) in (1,2,3) then  0
		WHEN month(cbd.date) in (4,5,6) then  1
		WHEN month(cbd.date) in (7,8,9) then  2
		ELSE 3
	end as period,
	ev.average_gini,
	ev.average_mor_under5,
	round(cv.population_density,2) as population_density,
	cv.median_age_2018,
	rv.religion,
	round(rv.percentage,2) as percentage,
	lev.diff_2015_1956
FROM covid19_basic_differences cbd
JOIN economies_view ev
ON cbd.country  = ev.country
JOIN religions_view rv 
ON cbd.country = rv.country 
JOIN countries_view cv
ON cbd.country =cv.country
JOIN life_expectancy_view lev
ON cbd.country = lev.country 
GROUP by `date`,country,rv.percentage ;

"""CREATE VIEW countries_view AS
	SELECT 
	country,
	population_density,
	median_age_2018
	from countries;"""
"""
CREATE VIEW economies_view AS
	SELECT country,
	round(avg(gini),2) as average_gini,
	round(avg(mortaliy_under5),2) as average_mor_under5
	FROM economies 
	WHERE
	country in (SELECT country from covid19_basic_differences)
	GROUP BY country ;"""
"""
CREATE view religions_view AS
	WITH base AS( 
	SELECT 
		country,
		religion,
		population,
		sum(population) over(partition by country) total_population
	FROM religions
	WHERE `year` = '2020'
	)
	SELECT
		country,
		religion,
		population,
		round(population/total_population*100,2) as percentage,
		total_population
	from base
	GROUP by country,religion ;"""
"
CREATE view life_expectancy_view AS 
	SELECT
		le1.country,
		(le1.life_expectancy - le2.life_expectancy) as diff_2015_1956
	FROM life_expectancy le1 
	CROSS JOIN life_expectancy le2
	WHERE le1.`year` = '2015' AND le2.`year` = '1965'
	GROUP by country ;"



SELECT
c.country,
cast(w.`date` as date) as date,
avg(temp)
from weather w 
JOIN countries c 
ON w.city = c.capital_city
WHERE time between '06:00' and '18:00'
group by w.`date`,c.country ;

SELECT
c.country,
cast(w.`date` as date) as date,
count(w.rain) * 3 as hours
from weather w 
JOIN countries c 
ON w.city = c.capital_city
WHERE w.rain > '0.0 mm'
group by c.country,w.`date` ;

WITH base as(
SELECT 
c.country,
cast(w.`date` as date) as date,
left(w.gust,2) as gust_speed
from weather w 
JOIN countries c 
ON w.city = c.capital_city
)
SELECT 
country,
date,
max(cast(gust_speed as INT)) as max_wind_speed
FROM base
group by country,`date`;

SELECT * 
FROM weather
WHERE city ='Tirana';