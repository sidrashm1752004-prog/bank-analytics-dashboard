
-- create Database & Data Import --

create database BankData;

create table DC(
CustomerID	varchar(50),
CustomerName varchar(50),
AccountNumber varchar(20) ,
TransactionDate VARCHAR(20)	,
TransactionType varchar(10),
Amount decimal(12,2),
Balance	decimal(15,2),
Description varchar(50),	
Branch varchar(20),	
TransactionMethod varchar(20)	,
Currency varchar(10),	
BankName varchar(50)
);


set GLOBAL LOCAL_INFILE=ON;
LOAD DATA LOCAL INFILE 'C:/Users/eknath/OneDrive/Desktop/bank/DataforSQL1.csv' INTO TABLE DC
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

UPDATE dc
SET TransactionDate = STR_TO_DATE(TransactionDate, '%d-%m-%Y');



-- All KPI ------------------------------------------------------------------------------------------------------------------------

-- KPI.1 Total Credit
select concat("Rs.",round(sum(Amount)/1000000,2)," M") as Total_Credit from dc where TransactionType="Credit" ;

-- KPI.2 Total Debit
select concat("Rs.",round(sum(Amount)/1000000,2)," M") as Total_Debit from dc where TransactionType="Debit";

-- KPI.3 Total Transaction Value
select concat("Rs.", Round(sum(amount)/1000000,2)," M") as Total_Amount from dc;

-- KPI.4 Total_Balance

select 
    concat("Rs.", round(sum(latest_balance)/1000000,2), " M") as Total_Balance
from (
    select AccountNumber, max(Balance) as latest_balance
    from dc
    group by AccountNumber
) as t;


-- KPI.5 Credit to Debit Ratio:

select 
	Round(sum(case when TransactionType="Credit" then Amount else 0 end)/
    sum(case when TransactionType="Debit" then Amount else 0 end),3) as Credit_DebitRatio
from dc;

-- KPI.6 Net Cash Flow (Bank-wise)

select 
	BankName,
    Concat(Round((sum(case when TransactionType="Credit" then Amount else 0 end)-
    sum(case when TransactionType="Debit" then Amount else 0 end))/1000,2),' K') as Net_transaction_Amt
from dc
group by bankName
order by Net_transaction_Amt;    
    


-- KPI.7 No. of transaction per month


select
    monthname(TransactionDate) as Month,
    count(amount) as Total_No_Transactions
from dc
group by month(TransactionDate), monthname(TransactionDate)
order by month(TransactionDate);




-- Q.1  TOP 3 high-value transactions (VIEW) --------------------------------------------------------------

Create view high_value_transactions as
select	
	BankName, 
	CONCAT("INR ",Round(sum(Amount)/1000000,2)," M") as Transaction_amt
from dc
group by 
	BankName
order by 
	sum(Amount) desc
LIMIT 3;

select * from high_value_transactions;
Drop view high_value_transactions;



-- Q.2 top transaction by amount per branch (SUBQUERY,WINDOW FUNCTION) -------------------------------------------------------
select 
branch,
amount from (
select 
branch,
amount,
dense_rank() over (partition by branch order by amount desc) as rnk
from dc)t
where rnk =1;


-- Q.3 Total Credit and Debit per Branch -----------------------------------------------------------------------------------

select
branch ,
TransactionType,
concat("Rs.", round(sum(Amount)/1000000,2)," M") as Branchwise_Total_CreditDebit
from dc
group by Branch,TransactionType


-- Q.4 total debit, total credit, and balance for accounts

Delimiter $$
create procedure Account_details (
	in a_AccountNumber varchar(100)
)
	Begin
		select
        AccountNumber,
        sum(case when TransactionType="Credit" then Amount else 0 end) total_credit,
        sum(case when TransactionType="Debit" then Amount else 0 end) total_debit,
        max(Balance) as latest_Balance
        from dc
        where find_in_set(AccountNumber,a_AccountNumber)
        group by AccountNumber;

	end $$
delimiter ;

Call Account_details ('1217789486,1665145627,3048583565');
drop procedure Account_details;



-- Q.6 branches where more than 50% of transactions are debit (Branch dependency)

select 
branch ,
round((COUNT(Case when TransactionType='Debit' THEN 1 END)/ COUNT(*))*100,2)
as debit_per
from dc
group by Branch
having debit_per>50
order by debit_per desc ;

-- Q.7 Branch-wise Month-over-Month Growth based on SUM(Amount)

with Monthly_growth as (
	select Branch,
			month(TransactionDate) As month_no,
            sum(Amount) Total_amt
	from dc
    group by Branch,
			month(TransactionDate)
)
select branch,
	month_no,
    Total_amt,
	round((Total_amt-lag(Total_amt) over(partition by  branch order by month_no))/
		lag(Total_amt) over(partition by  branch order by month_no)*100,2) as Growth_per
from Monthly_growth;

-- Q.8 Transaction Method Distribution:

select 
TransactionMethod,
Round((sum(Amount)/(select sum(amount) from dc))*100,2) method_contribution
from dc
group by TransactionMethod
order by method_contribution desc;




