create database braintree_coding_challenge;
use braintree_coding_challenge;
show tables;
select * from continent_map;
select * from continents;
select * from countries;
select * from per_capita;

/*
1. Data Integrity Checking & Cleanup

-   Alphabetically list all of the country codes in the continent_map
    table that appear more than once. Display any values where
    country_code is null as country_code = "FOO" and make this row
    appear first in the list, even though it should alphabetically sort
    to the middle. Provide the results of this query as your answer.

-   For all countries that have multiple rows in the continent_map
    table, delete all multiple records leaving only the 1 record per
    country. The record that you keep should be the first one when
    sorted by the continent_code alphabetically ascending. Provide the
    query/ies and explanation of step(s) that you follow to delete these
    records.
*/

-- Part 1:
select coalesce(country_code, 'FOO') as country_code from
	(
		select country_code, count(*) ct from continent_map group by country_code
	) t1
where ct>1 order by ct desc,1;

-- Part 2:
create temporary table continent_map_temp (
select *, row_number() over(partition by country_code order by continent_code) as rn from continent_map);

select * from continent_map_temp;
delete from continent_map_temp where rn>1;

select country_code, continent_code from continent_map_temp;

/*
2. List the countries ranked 10-12 in each continent by the percent of
year-over-year growth descending from 2011 to 2012.
The percent of growth should be calculated as: ((2012 gdp - 2011 gdp) /
2011 gdp)
The list should include the columns:
-   rank
-   continent_name
-   country_code
-   country_name
-   growth_percent*/
with cte as(
		select co.continent_name, pc.country_code, c.country_name, row_number() over(partition by country_code, co.continent_code order by year) as rn, year, gdp_per_capita
		from per_capita pc 
		join countries c on pc.country_code = c.country_code
		join continent_map cm on pc.country_code = cm.country_code
		join continents co on cm.continent_code = co.continent_code
		where year in(2011, 2012)
	),
cte2 as(
		select t1.continent_name, t1.country_code, t1.country_name, round(((t2.gdp_per_capita - t1.gdp_per_capita)/(t1.gdp_per_capita))*100,2) as growth_percent
		from cte t1 
		join cte t2 on t1.continent_name = t2.continent_name and t1.country_code = t2.country_code and t1.rn<t2.rn
	),
cte3 as(
		select *, rank() over(partition by continent_name order by growth_percent desc) rnk from cte2
        )
select rnk, continent_name, country_code, country_name, growth_percent from cte3 where rnk between 10 and 12;

/*
3. For the year 2012, create a 3 column, 1 row report showing the
percent share of gdp_per_capita for the following regions:

(i) Asia, (ii) Europe, (iii) the Rest of the World. Your result should
    look something like

  Asia    Europe   Rest of World
  ------- -------- ---------------
  25.0%   25.0%    50.0%
*/
with cte as(
select co.continent_name, sum(gdp_per_capita) as total_gdp from per_capita pc 
join countries c on pc.country_code = c.country_code
join continent_map cm on pc.country_code = cm.country_code
join continents co on cm.continent_code = co.continent_code
where year = 2012
group by continent_name)
select 
round((sum(case when continent_name = 'Asia' then total_gdp else 0 end)/sum(total_gdp)) * 100, 2) as Asia,
round((sum(case when continent_name = 'Europe' then total_gdp else 0 end)/sum(total_gdp)) * 100, 2) as Europe,
round((sum(case when continent_name not in ('Europe', 'Asia') then total_gdp else 0 end)/sum(total_gdp)) * 100, 2) as Rest_of_world
from cte;

/*
4a. What is the count of countries and sum of their related
gdp_per_capita values for the year 2007 where the string 'an' (case
insensitive) appears anywhere in the country name?

4b. Repeat question 4a, but this time make the query case sensitive.
*/
select count(*), sum(gdp_per_capita) from per_capita pc 
join countries c on pc.country_code = c.country_code 
where year = 2007 and country_name like '%an%';

-- 4b. (For Case sensitive searches)
select count(*), sum(gdp_per_capita) from per_capita pc 
join countries c on pc.country_code = c.country_code 
where year = 2007 and country_name like binary '%an%';


/*
5. Find the sum of gpd_per_capita by year and the count of countries
for each year that have non-null gdp_per_capita where (i) the year is
before 2012 and (ii) the country has a null gdp_per_capita in 2012.
Your result should have the columns:

-   year
-   country_count
-   total*/
select year, count(distinct (country_code)) country_count, sum(gdp_per_capita) as total 
from per_capita where year < 2012 and gdp_per_capita is not null
group by year;

select year, count(*) count_countries, sum(gdp_per_capita) as total 
from per_capita where year = 2012 and gdp_per_capita is null
group by year;

/*
6. All in a single query, execute all of the steps below and provide
the results as your final answer:
a.  create a single list of all per_capita records for year 2009 that
    includes columns:
-   continent_name
-   country_code
-   country_name
-   gdp_per_capita

b.  order this list by:
-   continent_name ascending
-   characters 2 through 4 (inclusive) of the country_name descending

c.  create a running total of gdp_per_capita by continent_name

d.  return only the first record from the ordered list for which each
    continent's running total of gdp_per_capita meets or exceeds
    $70,000.00 with the following columns:
-   continent_name
-   country_code
-   country_name
-   gdp_per_capita
-   running_total*/
with cte as(
select co.continent_name, pc.country_code, c.country_name, pc.gdp_per_capita, 
sum(gdp_per_capita) over(partition by continent_name order by co.continent_name, substr(country_name,2, 3) desc) running_total
from per_capita pc 
join countries c on pc.country_code = c.country_code 
join continent_map cm on pc.country_code = cm.country_code 
join continents co on cm.continent_code = co.continent_code
where year = 2009)
select * from cte where running_total >= 70000;


/*
7. Find the country with the highest average gdp_per_capita for each
continent for all years. Now compare your list to the following data
set. Please describe any and all mistakes that you can find with the
data set below. Include any code that you use to help detect these
mistakes.

  rank   continent_name     country_code    country_name     avg_gdp_per_capita
  ------ ----------------- --------------- --------------- -----------------------
  1      Africa            SYC             Seychelles       $11,348.66
  1      Asia              KWT             Kuwait           $43,192.49
  1      Europe            MCO             Monaco           $152,936.10
  1      North America     BMU             Bermuda          $83,788.48
  1      Oceania           AUS             Australia        $47,070.39
  1      South America     CHL             Chile            $10,781.71
*/

with cte as
	(
		select co.continent_name, c.country_code, c.country_name, concat('$ ', round(avg(gdp_per_capita),2)) as avg_gdp_per_capita, 
		rank () over(partition by co.continent_name order by co.continent_name,  avg(gdp_per_capita) desc) rnk
		from per_capita pc 
        join countries c on pc.country_code = c.country_code 
		join continent_map cm on pc.country_code = cm.country_code
		join continents co on cm.continent_code = co.continent_code
		group by co.continent_name, c.country_name
	)
select * from cte where rnk =1;
