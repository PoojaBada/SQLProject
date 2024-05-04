select * from athlete_events
select * from athletes

alter table athlete_events 
alter column year nvarchar(50)



/*1. Which team has won the maximum gold medals over the years */
select top 1 team, count(distinct event) as med_cnt
from athlete_events ae
inner join athletes a
on ae.athlete_id=a.id
where medal='Gold'
group by team 
order by med_cnt desc

/*2. For each team print total silver medals and year in which they won maximum silver medal..output 3 columns:
team,total_silver_medals, year_of_max_silver */
with cte as (
select team, year, count(distinct event) as total_silver_medals,
rank() over (partition by team order by count(distinct event) desc) as rn
from athlete_events ae
inner join athletes a
on ae.athlete_id=a.id
where medal='Silver'
group by team,year
--order by team,rn
)
select team,sum(total_silver_medals) as tot_medals, max(case when rn=1 then year end) as year
from cte
group by team

/*3. which player has won maximum gold medals amongst the players 
--which have won only gold medal (never won silver or bronze) over the years */
with cte as (
select name,medal
from athlete_events ae
inner join athletes a
on ae.athlete_id=a.id
)
select name,count(1) as med_cnt 
from cte
where name not in (select distinct name from cte where medal in ('Silver','Bronze'))
and medal='Gold' 
group by name
order by med_cnt desc

/*4. In each year which player has won maximum gold medal. Write a query to print year,player name 
and no of golds won in that year. In case of a tie print comma separated player names. */
with cte as (
select year,name,count(medal) as med_cnt,
rank() over (partition by year order by count(medal) desc) as rn
from athlete_events ae
inner join athletes a
on ae.athlete_id=a.id
where medal='Gold'
group by year,name
)
select year,med_cnt,STRING_AGG(name,',') as players
from cte
where rn=1
group by year,med_cnt
order by year

/*5. In which event and year India has won its first gold medal,first silver medal and first bronze medal
print 3 columns medal,year,sport */
with cte as (
select medal,year,event,
row_number() over (partition by medal order by year) as rn
from athlete_events ae
inner join athletes a
on ae.athlete_id=a.id
where team='India'
)
select medal,year,event
from cte
where rn=1 and medal in ('Gold','Silver','Bronze')

/*6. Find players who won gold medal in summer and winter olympics both */
select name 
from athlete_events ae
inner join athletes a
on ae.athlete_id=a.id
where medal='Gold'
group by name
having count(distinct season)=2

/*7. Find players who won gold, silver and bronze medal in a single olympics. print player name along with year */
select name,year
from athlete_events ae
inner join athletes a
on ae.athlete_id=a.id
where medal not in ('NA')
group by name,year
having count(distinct medal)=3

--crosscheck
select name,year,medal,games
from athlete_events ae
inner join athletes a
on ae.athlete_id=a.id
where name='Alexander Viggo Jensen' and medal not in ('NA')

/*8. Find players who have won gold medals in consecutive 3 summer olympics in the same event. Consider only olympics 2000 onwards. 
Assume summer olympics happens every 4 year starting 2000. Print player name and event name */
with cte as (
select name,year,event
from athlete_events ae
inner join athletes a
on ae.athlete_id=a.id
where medal='Gold' and season='Summer' and year>='2000'
),
cte1 as (
select *, lag(year,1) over(partition by name,event order by year ) as prev_year,
lead(year,1) over(partition by name,event order by year ) as next_year
from cte
)
select *
from cte1
where year=prev_year+4 and year=next_year-4