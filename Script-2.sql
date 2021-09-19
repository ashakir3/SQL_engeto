#t_Azizbek_Shakirov_projekt_SQL_final
# Updatovani nazvu countries, pridavani sloupce weekend,ctvrtleti a spojovani pomocnych tabulek

CREATE TABLE t_Azizbek_Shakirov_projekt_SQL_final (
SELECT
	CASE WHEN cbd.country = 'Burma' THEN 'Myanmar'
		WHEN cbd.country = 'Cabo Verde' THEN 'Cape Verde'
		WHEN cbd.country = 'Congo (Brazzaville)' THEN 'Congo'
		WHEN cbd.country = 'Congo (Kinshasa)' THEN 'The Democratic Republic of Congo'
		WHEN cbd.country = 'Cote d"Ivoire' THEN 'Ivory Coast'
		WHEN cbd.country = 'Czechia' THEN 'Czech Republic' 
		WHEN cbd.country = 'Eswatini' THEN 'Swaziland'
		WHEN cbd.country = 'Fiji' THEN 'Fiji Islands'
		WHEN cbd.country = 'Holy See' THEN 'Holy See (Vatican City State)'
		WHEN cbd.country = 'Korea, South' THEN 'South Korea'
		WHEN cbd.country = 'Libya' THEN 'Libyan Arab Jamahiriya'
		WHEN cbd.country = 'Micronesia' THEN 'Micronesia, Federated States of'
		WHEN cbd.country = 'Russia' THEN 'Russian Federation'
		WHEN cbd.country = 'US' THEN 'United States'
		ELSE cbd.country 
		END AS country,
	cbd.date,
	cbd.confirmed,
	ct.tests_performed,
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
	lev.diff_2015_1956,
	dtv.average_temp,
	hv.hours,
	wsp.max_wind_speed
FROM covid19_basic_differences cbd
JOIN covid19_tests ct 
ON cbd.country = ct.country  and cbd.date = ct.`date` 
JOIN economies_view ev
ON cbd.country  = ev.country
JOIN religions_view rv 
ON cbd.country = rv.country 
JOIN countries_view cv
ON cbd.country =cv.country
JOIN life_expectancy_view lev
ON cbd.country = lev.country 
JOIN day_temp_view dtv
ON cbd.country = dtv.country and cbd.`date` = dtv.`date` 
JOIN hours_view hv
ON cbd.country = hv.country and cbd.`date` = hv.date
JOIN wind_speed_view wsp
ON cbd.country = wsp.country and cbd.date = wsp.date
GROUP by cbd.country,cbd.`date`,rv.percentage );


# Beru z Countries jen to co potreba pro zadani
CREATE TABLE countries_view (
	SELECT 
	country,
	population_density,
	median_age_2018
	from countries);

# Beru z Economies jen to co potreba pro zadani a omezuji pocet countries, pouzil jsem tady AVG, jelikoz nekterym countries chybi informace pro nektere roky.
CREATE TABLE economies_view (
	SELECT country,
	round(avg(gini),2) as average_gini,
	round(avg(mortaliy_under5),2) as average_mor_under5
	FROM economies 
	WHERE
	country in (SELECT country from covid19_basic_differences)
	GROUP BY country );

# Beru informace z Religions za posledni rok.
CREATE TABLE religions_view (
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
	GROUP by country,religion );

# Pocitam rozdil z tabulky life_expectancy (2015-1965)
CREATE TABLE life_expectancy_view ( 
	SELECT
		le1.country,
		(le1.life_expectancy - le2.life_expectancy) as diff_2015_1956
	FROM life_expectancy le1 
	CROSS JOIN life_expectancy le2
	WHERE le1.`year` = '2015' AND le2.`year` = '1965'
	GROUP by country) ;

# Prumerna denni teplota
CREATE TABLE day_temp_view (
SELECT
c.country,
cast(w.`date` as date) as date,
avg(LEFT(temp,2)) as average_temp
from weather w 
JOIN countries c 
ON w.city = c.capital_city
WHERE time between '06:00' and '18:00'
group by w.`date`,c.country) ;


# Pocitani hodin v danem dni, kdy byly srazky nenulove
CREATE TABLE hours_view (
SELECT
c.country,
cast(w.`date` as date) as date,
count(w.rain) * 3 as hours
from weather w 
JOIN countries c 
ON w.city = c.capital_city
WHERE w.rain > '0.0 mm'
group by c.country,w.`date`) ;

# Maximalni sila vetru v narazech
CREATE TABLE wind_speed_view (
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
group by country,`date`);



