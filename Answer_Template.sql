

CREATE DATABASE Cellphones_Information
Use Cellphones_Information

Select top 1 * from DIM_CUSTOMER
Select top 1 * from DIM_DATE
Select top 1 * from DIM_LOCATION
Select top 1 * from DIM_MANUFACTURER
Select top 1 * from DIM_MODEL
Select top 1 * from FACT_TRANSACTIONS








--SQL Advance Case Study


--Q1-- List all the states in which we have customers who have bought cellphones from 2005 till today.



-- Customer ID, states, date, mobile

select distinct state from (
select t1.State, sum(quantity) as cnt, YEAR(t2.Date) as year from DIM_LOCATION AS T1
join FACT_TRANSACTIONS as t2
on t1.IDLocation = t2.IDLocation
WHERE YEAR(t2.Date) >=2005
group by t1.state , YEAR(t2.Date)
) as A


--Q2--What state in the US is buying the most 'Samsung' cell phones?
	
	select top 1 state,count(*) as cnt from DIM_LOCATION as t1
	join FACT_TRANSACTIONS as t2
	on t1.IDLocation = t2.IDLocation
	join DIM_Model as t3
	on t2.IDModel = t3.IDModel
	join DIM_MANUFACTURER as t4
	on t3.IDManufacturer = t4.IDManufacturer
	where country = 'US' and Manufacturer_name = 'Samsung'
	Group by state
	order by cnt desc
	   	  

--Q3-- Show the number of transactions for each model per zip code per state      
	
	select idmodel,state,zipcode,COUNT(*) as tot_trans
	from FACT_TRANSACTIONS as t1
	join DIM_LOCATION as t2
	on t1.IDLocation = t2.IDLocation
	group by IDModel, State,ZipCode
	
--Q4--Show the cheapest cellphone (Output should contain the price also)

Select top 1 model_name, min(unit_price) as min_price from DIM_MODEL
group by Model_Name
order by min_price asc

--Q5--Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.


--avg price for each model

select t1.IDModel,avg(totalprice) as avg_price, sum(quantity) as tot_qty from FACT_TRANSACTIONS as t1
 join DIM_MODEL as t2
 on t1.IDModel = t2.IDModel
 join DIM_MANUFACTURER as t3
 on t2.IDManufacturer = t3.IDManufacturer
where manufacturer_name in (select top 5 manufacturer_name from FACT_TRANSACTIONS as t1
                            join DIM_MODEL as t2
                            on t1.IDModel = t2.IDModel
                            join DIM_MANUFACTURER as t3
                            on t2.IDManufacturer = t3.IDManufacturer
                            group by Manufacturer_name
                            order by sum(totalprice) desc)

group by t1.IDModel
order by avg_price desc



-- Top 5 manufactures

select top 5 manufacturer_name , sum(totalprice) as Sales from FACT_TRANSACTIONS as t1
join DIM_MODEL as t2
on t1.IDModel = t2.IDModel
join DIM_MANUFACTURER as t3
on t2.IDManufacturer = t3.IDManufacturer
group by Manufacturer_name
order by Sales desc


--Q6--List the names of the customers and the average amount spent in 2009,where the average is higher than 500

select 
    c.Customer_Name, 
    avg(t.TotalPrice) as avg_spent
from FACT_TRANSACTIONS as t
join DIM_CUSTOMER as c
    on t.IDCustomer = c.IDCustomer
where YEAR(t.Date) = 2009
group by c.Customer_Name
having avg(t.TotalPrice) > 500
order by avg_spent desc


--Q6--END
	
--Q7--ist if there is any model that was in the top 5 in terms of quantity,simultaneously in 2008, 2009 and 2010

  with Yearly_Rank as (
    select 
        t.IDModel,
        YEAR(t.Date) as yr,
        sum(t.Quantity) as tot_qty,
        RANK() over (partition by YEAR(t.Date) order by sum(t.Quantity) desc) as rnk
    from FACT_TRANSACTIONS as t
    where YEAR(t.Date) in (2008, 2009, 2010)
    group by t.IDModel, YEAR(t.Date)
)

select distinct m.Model_Name
from Yearly_Rank as y
join DIM_MODEL as m
    on y.IDModel = m.IDModel
where y.rnk <= 5
group by m.Model_Name, y.IDModel
having count(distinct y.yr) = 3
	

--Q8--Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.

with Yearly_Manufacturer_Sales as (
    select 
        man.Manufacturer_Name,
        YEAR(t.Date) as yr,
        sum(t.TotalPrice) as tot_sales,
        RANK() over (partition by YEAR(t.Date) order by sum(t.TotalPrice) desc) as rnk
    from FACT_TRANSACTIONS as t
    join DIM_MODEL as mo
        on t.IDModel = mo.IDModel
    join DIM_MANUFACTURER as man
        on mo.IDManufacturer = man.IDManufacturer
    where YEAR(t.Date) in (2009, 2010)
    group by man.Manufacturer_Name, YEAR(t.Date)
)

select yr, Manufacturer_Name, tot_sales
from Yearly_Manufacturer_Sales
where rnk = 2
order by yr



--Q9-- Show the manufacturers that sold cellphones in 2010 but did not in 2009.

select distinct man.Manufacturer_Name
from FACT_TRANSACTIONS as t
join DIM_MODEL as mo
    on t.IDModel = mo.IDModel
join DIM_MANUFACTURER as man
    on mo.IDManufacturer = man.IDManufacturer
where YEAR(t.Date) = 2010
and man.Manufacturer_Name not in (
    select distinct man2.Manufacturer_Name
    from FACT_TRANSACTIONS as t2
    join DIM_MODEL as mo2
        on t2.IDModel = mo2.IDModel
    join DIM_MANUFACTURER as man2
        on mo2.IDManufacturer = man2.IDManufacturer
    where YEAR(t2.Date) = 2009
)

--Q10--Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.

	with Customer_Yearly as (
    select 
        IDCustomer,
        YEAR(Date) as yr,
        avg(TotalPrice) as avg_spend,
        avg(Quantity) as avg_qty
    from FACT_TRANSACTIONS
    group by IDCustomer, YEAR(Date)
),

Ranked as (
    select 
        cy.*,
        LAG(avg_spend) over (partition by IDCustomer order by yr) as prev_spend,
        sum(avg_spend) over (partition by IDCustomer) as overall_spend
    from Customer_Yearly as cy
)

select top 100
    c.Customer_Name, r.yr, r.avg_spend, r.avg_qty,
    round((r.avg_spend - r.prev_spend) / r.prev_spend * 100, 2) as pct_change_spend
from Ranked as r
join DIM_CUSTOMER as c on r.IDCustomer = c.IDCustomer
order by r.overall_spend desc, r.yr

--Q10--END
	