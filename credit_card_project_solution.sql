select * from credit_card_transactions
order by transaction_id

/*1. write a query to print top 5 cities with highest spends and their percentage contribution of total/ credit card spends*/
with cte as(
select city, sum(amount) as spend
from credit_card_transactions
group by city
),
tot_spend as
(select *,sum(spend) over() as total_spend
from cte)
select top 5 city, spend, round(spend*100.0/total_spend,2) as per 
from tot_spend
order by per desc

/*2. write a query to print highest spend month and amount spent in that month for each card type*/
with cte as (
select top 1 datepart(year,transaction_date) as trans_year,
datepart(month,transaction_date) as trans_month, sum(amount) as spend
from credit_card_transactions
group by datepart(year,transaction_date),
datepart(month,transaction_date)
)
select c.trans_year,c.trans_month,cc.card_type,
sum(cc.amount) as spend_by_type
from cte c
inner join credit_card_transactions cc on
c.trans_year=datepart(year,cc.transaction_date) and c.trans_month=datepart(month,cc.transaction_date)
group by c.trans_year,c.trans_month,cc.card_type

/*3. write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)*/
with cte as (
select  *, sum(amount) over(partition by card_type order by transaction_date,transaction_id) as amt
from credit_card_transactions
),
cte1 as(
select *,rank () over (partition by card_type order by amt) as rn
from  cte
where amt>=1000000
)
select * from cte1
where rn=1

/*4. write a query to find city which had lowest percentage spend for gold card type*/
with cte as (
select city, sum(amount) as tot_spend,
sum (case when card_type='Gold' then amount else 0 end) as gold_spend
from credit_card_transactions
group by city
)
select top 1 city, round(gold_spend/tot_spend*100.0,2) as per_spend
from cte
where gold_spend>0
order by per_spend asc

/* 5. write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)*/
with cte as (
select city,exp_type, sum(amount) as exp
from credit_card_transactions
group by city,exp_type
),
cte1 as(
select *,row_number
() over(partition by city order by exp) as rn,
row_number() over(partition by city order by exp desc) as rn1
from cte
)
select city,
max(case when rn=1 then exp_type end) as lowest_expense_type,
max(case when rn1=1 then exp_type end) as highest_expense_type
from cte1
group by city


/*6. write a query to find percentage contribution of spends by females for each expense type*/
with cte as(
select exp_type, sum(amount) as tot_spend,
sum(case when gender='F' then amount else 0 end) as fem_spend
from credit_card_transactions
group by exp_type
)
select *,round(fem_spend*100.0/tot_spend,2) as fem_cont
from cte
order by fem_cont

/*7. which card and expense type combination saw highest month over month growth in Jan-2014*/
with cte as(
select card_type, exp_type,datepart(year,transaction_date) as trans_year,
datepart(month,transaction_date) as trans_month,sum(amount) as cur_mon_exp
from credit_card_transactions
--where datepart(year,transaction_date)=2014 and datepart(month,transaction_date)=1
group by card_type, exp_type,datepart(year,transaction_date),
datepart(month,transaction_date)
),
cte1 as(
select *, lag(cur_mon_exp,1) over (partition by card_type,exp_type order by trans_year,trans_month) as prev_mon_exp
from cte
)
select top 1 *, cur_mon_exp-prev_mon_exp as mom_growth
from cte1
where  trans_year=2014 and trans_month=1 and prev_mon_exp is not null
order by mom_growth desc

/*8. during weekends which city has highest total spend to total no of transcations ratio*/
select top 1 city,sum(amount)/count(transaction_id) as ratio
from credit_card_transactions
where datepart(weekday,transaction_date) in (1,7)
group by city
order by ratio desc
/*select transaction_date,DATENAME(weekday,transaction_date),
datepart(weekday,transaction_date)
from credit_card_transactions*/

/*9.  which city took least number of days to reach its 500th transaction after the first transaction in that city*/
with cte as(
select city,transaction_date,transaction_id,
row_number() over(partition by city order by transaction_date,transaction_id) as trans_num
from credit_card_transactions
--where city='Delhi'
),
cte1 as (
select city, max(case when trans_num=1 then transaction_date end) as first_trans_date,
max(case when trans_num=500 then transaction_date end ) as five_hundredth_trans_date
from cte
where trans_num in (1,500)
group by city
)
select city,datediff(day,first_trans_date,five_hundredth_trans_date) as date_diff
from cte1
where datediff(day,first_trans_date,five_hundredth_trans_date) is not null
order by date_diff