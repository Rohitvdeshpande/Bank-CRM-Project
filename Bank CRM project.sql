CREATE DATABASE bank_crm;

use bank_crm;
select * from activecustomer;
select * from bank_churn;
select * from creditcard;
select * from customerinfo;
select * from exitcustomer;
select * from gender;
select * from geography;

Alter table customerinfo
add column bankDOJ1 date;
                   /* Modification in customerinfo table in bankDOJ column */
update customerinfo
set bankDOJ1= str_to_date(bankDOJ, '%d-%m-%Y');

alter table customerinfo
drop column bankDOJ;

alter table customerinfo
rename column bankDOJ1 to bankDOJ;

                         /* Question and Answers To Objective Questions */
/* 1.	What is the distribution of account balances across different regions? */
		select ci.GeographyID, g.GeographyLocation, round(sum(bc.Balance),2) as Balance
		from customerinfo ci
		join bank_churn bc ON ci.CustomerId = bc.CustomerId
        join geography g ON ci.GeographyID= g.GeographyID 
		group by 1,2
		ORDER BY ci.GeographyID;

/* 2.	Identify the top 5 customers with the highest number of transactions in the last quarter of the year. */

		select CustomerId, Surname, EstimatedSalary from customerinfo
		where year(bankDOJ)= 2019 and quarter(bankDOJ)= 4
        order by EstimatedSalary desc limit 5;
        
/* 3.	Calculate the average number of products used by customers who have a credit card. */

		select avg(NumOfProducts) as avg_product_cc from bank_churn
		where HasCrCard= 1;
        
/* 4.	Determine the churn rate by gender for the most recent year in the dataset. */
		select g.GenderCategory, 
        cast(count(case when exited= 1 then b.CustomerId end)*100/ count(b.CustomerId) as decimal(10,2)) 
        as churn_rate
        from bank_churn b join customerinfo c on b.CustomerId= c.CustomerId
        join gender g ON g.GenderID= c.GenderID
        where year(bankDOJ)= 2019
        group by 1;
        
        select count(*) from bank_churn b 
        join customerinfo c ON c.CustomerId= b.CustomerId
        where genderID= 2 and exited= 1 and year(bankDOJ) = 2019;
	
/* 5.	Compare the average credit score of customers who have exited and those who remain. */

		select
		Avg(Case when exited= 1 then creditscore end) as avg_credit_exited,
		Avg(case when exited= 0 then CreditScore end) as avg_credit_remain
		from bank_churn;    
        
/* 6.	Which gender has a higher average estimated salary, 
        and how does it relate to the number of active accounts? */
  	
	   select g.GenderCategory,round(avg(c.EstimatedSalary),2) as avg_salary,
	   round(avg( case when a.ActiveID=1 then c.EstimatedSalary end),2) as avg_salary_active,
	   round(avg( case when a.ActiveID=0 then c.EstimatedSalary end),2) as avg_salary_inactive
	   from customerinfo c 
	   inner join gender g 
	   ON c.genderid= g.genderid
	   inner join bank_churn b ON b.CustomerId= c.CustomerId
	   inner join activecustomer a ON b.IsActiveMember= a.ActiveID
	   group by g.GenderCategory
       Order by avg_salary desc limit 1;
       
/* 7.	Segment the customers based on their credit score and identify the segment with the highest exit rate. */
  
		select CreditScore, count(CustomerId) as customer_count from bank_churn
		where exited= 1
		group by CreditScore
		order by customer_count ;
        
/* 8.	Find out which geographic region has the highest number of 
        active customers with a tenure greater than 5 years. */
  
		select g.GeographyLocation,count(case when a.ActiveCategory= 'Active Member' then 1 end ) 
        as count_active_member from customerinfo c 
		inner join bank_churn b ON c.CustomerId= b.CustomerId
		inner join geography g ON c.GeographyID= g.GeographyID
		inner join activecustomer a ON b.IsActiveMember= a.ActiveID 
		where b.Tenure>5
		group by g.GeographyLocation
		order by count_active_member desc limit 1;
        
/* 10.	For customers who have exited, what is the most common number of products they have used? */

		select NumOfProducts, count(NumOfProducts) as total_count 
        from bank_churn
		where exited= 1
		group by NumOfProducts
		order by total_count desc limit 1;

/* 11.	Examine the trend of customer exits over time and identify 
		any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it. */

		select year(bankDOJ) as year, count(c.CustomerId) as count_customer_churn
        from bank_churn b 
		inner join customerinfo c ON b.CustomerId= c.CustomerId
		where Exited= 1
		group by year(bankdoj);

                      
/* 13.	Identify any potential outliers in terms of spend among customers who have remained with the bank.

		 select * from bank_churn;
		 select * from customerinfo;
		 SELECT 
		     PERCENTILE_CONT(0.25) OVER (ORDER BY (c.estimatedsalary - b.balance)) AS q1,
		     PERCENTILE_CONT(0.75) OVER (ORDER BY (c.estimatedsalary - b.balance)) AS q3
		 FROM customerinfo c
		 INNER JOIN bank_churn b ON c.cutomerId = b.customerId;
*/
/* 15.	Using SQL, write a query to find out the gender-wise average income of males
		and females in each geography id. Also, rank the gender according to the average value. */
  
		  with temp as
		  (
		  select c.GeographyID,g.GenderCategory , 
          round(AVG(c.EstimatedSalary),2) as avg_salary
			from customerinfo c 
		  inner join gender g ON c.GenderID= g.GenderID
		  group by c.GeographyID,g.GenderCategory
		  )
		  select *, rank() over(order by avg_salary desc) 
          as ranking from temp
		  ;
  
/* 16.	Using SQL, write a query to find out the average tenure of the 
		people who have exited in each age bracket (18-30, 30-50, 50+). */
  
		  with AgeBucket as
		  (
		  select c.CustomerId,c.surname,c.age,c.GenderID,
          c.EstimatedSalary,c.GeographyID,c.bankDOJ,
		  b.CreditScore,b.tenure,b.balance,b.NumOfProducts,
          b.HasCrCard,b.IsActiveMember,b.Exited,
		  case when c.age between 18 and 30 then '18-30'
			   when c.age between 31 and 50 then '30-50'
			   else '50+'
			   end as age_bracket
		  from bank_churn b 
		  inner join customerinfo c ON b.CustomerId= c.CustomerId
		  where exited=1
		  )
		  select age_bracket, round(avg(tenure),2) avg_tenure from AgeBucket
		  group by age_bracket
		  ;
		  
  /* 19. Rank each bucket of credit score as per the number of customers who have churned the bank. */
  
		  with creditbucket as
		  (
		  select *,
		  case when creditscore between 0 and 579 then 'Poor'
			   when creditscore between 580 and 669 then 'Fair'
			   when creditscore between 670 and 739 then 'Good'
			   when creditscore between 740 and 800 then 'Very Good'
			   else 'Excellent'
			   end as creditBucket
		  from bank_churn
		  where exited = 1
		  )
		  select creditbucket, count(customerid) as total_count,
		  dense_rank() over(order by count(customerid) desc) as ranking  
		  from creditbucket
		  group by creditbucket
		  ;

/* 20.	According to the age buckets find the number of customers who have a credit card. 
        Also, retrieve those buckets that have a lesser than average number of credit cards per bucket. */

		create view ageBucket1 as
		(
		select c.CustomerId,c.surname,c.age,c.GenderID,
			   c.EstimatedSalary,c.GeographyID,c.bankDOJ,
			   b.CreditScore,b.tenure,b.balance,b.NumOfProducts,
               b.HasCrCard,b.IsActiveMember,b.Exited,
		  case when c.age between 18 and 30 then '18-30'
			   when c.age between 31 and 50 then '30-50'
			   else '50+'
			   end as age_bracket
		  from bank_churn b 
		  inner join customerinfo c ON b.CustomerId= c.CustomerId
		  );
  
		  with cte1 as
		  (select age_bracket, count(customerid) total_customer,
		  count(case when hascrcard=1 then customerid end) as count_customer_with_credit
		  from agebucket1
		  group by 1)
		  select *, round((select avg(count_customer_with_credit) from cte1),2) as avg_customer_with_credit from cte1
		  having count_customer_with_credit < (select avg(count_customer_with_credit) from cte1)
		  ;
  
/* 21.	Rank the Locations as per the number of people who have churned
        the bank and the average balance of the learners.  */

		with cte as(
		select g.GeographyLocation, count(distinct b.CustomerId) as count_churn
		from bank_churn b 
		join customerinfo c on b.CustomerId= c.CustomerId
		join geography g ON c.GeographyID= g.GeographyID
		where b.exited= 1
		group by 1)
		select *, rank() over(order by count_churn desc) as rnk from cte
		;
		-- ---------- Average balance
		select round(avg(balance),2) as avg_balance from bank_churn;
        
        
	/* Subjective question no 9 ans */
        with AgeBucket as
		  (
		  select c.CustomerId,c.surname,c.age,c.GenderID,
          c.EstimatedSalary,c.GeographyID,c.bankDOJ,
		  b.CreditScore,b.tenure,b.balance,b.NumOfProducts,
          b.HasCrCard,b.IsActiveMember,b.Exited,
		  case when c.age between 18 and 30 then '18-30'
			   when c.age between 31 and 50 then '30-50'
			   else '50+'
			   end as age_bracket
		  from bank_churn b 
		  inner join customerinfo c ON b.CustomerId= c.CustomerId
		
		  )
		  select age_bracket, count(customerId) total_customers from AgeBucket
		  group by age_bracket
		  ;
          
          
/*  22.	As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.
Ans ->*/ 	
select 
 ci.CustomerId,
    		 ci.Surname,
  		 concat(ci.CustomerId,'_',ci.Surname) as CustomerId_Surname
  		 from
    		 customerinfo ci
     		  join
    		bank_churn ot on ci.CustomerId = ot.CustomerId;

          
   /* 23.	Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.
Ans ->*/  
 SELECT
   	 bc.*,
    	(SELECT ExitCategory FROM exitcustomer ec WHERE ec.ExitID = bc.Exited) AS ExitCategory
FROM
    	bank_churn bc;




UPDATE customerinfo c
INNER JOIN bank_churn bc ON c.CustomerId = bc.CustomerId
SET bc.IsActiveMember = c.IsActive;



/*  25.	Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”. */
SELECT
    bc.CustomerId,
    ci.Surname,
    CASE WHEN bc.IsActiveMember = 1 THEN 'Active' ELSE 'Inactive' END AS ActiveStatus
FROM
    bank_churn bc
JOIN
    customerinfo ci ON bc.CustomerId = ci.CustomerId
WHERE
    ci.Surname LIKE '%on';
