#t_Azizbek_Shakirov_projekt_SQL_final
# Updatovani nazvu countries, pridavani sloupce weekend,ctvrtleti a spojovani pomocnych tabulek

CREATE TABLE t_Azizbek_Shakirov_projekt_SQL_final (
SELECT
	cbd.country as country,
	cbd.date as date,
	cbd.confirmed as confirmed,
	ct.tests_performed as tests_performed,
	cbd.weekend as weekned,
	cbd.period as period,
	cv.population_density as population_density,
	evg.gdp_per_person as gdp_per_person,
	ev.average_gini as average_gini,
	ev.average_mor_under5 as average_mor_under5,
	cv.median_age_2018 as median_age_2018,
	rv.religion as religion,
	rv.percentage as percentage,
	round(lev.diff_2015_1956,2) as diff_2015_1956,
	dtv.average_temp as average_temperature,
	hv.hours as hours_rain,
	wsp.max_wind_speed as max_wind_speed
FROM covid19_b_d_view cbd
JOIN covid19_tests ct 
ON cbd.country = ct.country  and cbd.date = ct.`date` 
JOIN economies_view_gdp evg
ON cbd.country = evg.country
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

# Standartizovani nazvu statu
CREATE TABLE covid19_b_d_view(
	SELECT 
		CASE WHEN country = 'Burma' THEN 'Myanmar'
		WHEN country = 'Cabo Verde' THEN 'Cape Verde'
		WHEN country = 'Congo (Brazzaville)' THEN 'Congo'
		WHEN country = 'Congo (Kinshasa)' THEN 'The Democratic Republic of Congo'
		WHEN country = 'Cote d"Ivoire' THEN 'Ivory Coast'
		WHEN country = 'Czechia' THEN 'Czech Republic' 
		WHEN country = 'Eswatini' THEN 'Swaziland'
		WHEN country = 'Fiji' THEN 'Fiji Islands'
		WHEN country = 'Holy See' THEN 'Holy See (Vatican City State)'
		WHEN country = 'Korea, South' THEN 'South Korea'
		WHEN country = 'Libya' THEN 'Libyan Arab Jamahiriya'
		WHEN country = 'Micronesia' THEN 'Micronesia, Federated States of'
		WHEN country = 'Russia' THEN 'Russian Federation'
		WHEN country = 'US' THEN 'United States'
		ELSE country 
		END AS country,
		confirmed,
		date,
	CASE 
		WHEN weekday(date) in (5,6) Then 1
		ELSE 0
	END as weekend,
	CASE
		WHEN month(date) in (1,2,3) then  0
		WHEN month(date) in (4,5,6) then  1
		WHEN month(date) in (7,8,9) then  2
		ELSE 3
	end as period
	FROM covid19_basic_differences);



# Beru z Countries jen to co potreba pro zadani
CREATE TABLE countries_view (
	SELECT 
	country,
	round(population_density,2) as population_density,
	round(median_age_2018,2) as median_age_2018
	from countries);

# Beru z Economies jen to co potreba(krome HDP) pro zadani a omezuji pocet countries, pouzil jsem tady AVG, jelikoz nekterym countries chybi informace pro nektere roky.
CREATE TABLE economies_view (
	SELECT country,
	round(avg(gini),2) as average_gini,
	round(avg(mortaliy_under5),2) as average_mor_under5
	FROM economies # deleted where country 
	GROUP BY country );



# Pocitani HDP
CREATE TABLE economies_view_gdp (
	SELECT country,
	round(GDP/population,2) as gdp_per_person
	FROM economies 
	WHERE
	year = 2020 # deleted where country 
);


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
	WHERE le1.`year` = 2015 AND le2.`year` = 1965
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
group by c.country, w.`date`) ;


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

# Zmenen format date a mene sloupcu
CREATE table covid19_tests_view(
	SELECT 
	country,
	cast(`date` as date) as date,
	tests_performed 
	FROM covid19_tests 
	GROUP by country,date);
	

