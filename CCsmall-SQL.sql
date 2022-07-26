/*
Credit Cards Records and applications Data Exploration 
Skills Used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/



Select			*
From			CreditCard..application_record$
Where			CODE_GENDER='F'
Order By		6 Desc,7




-- Calculate the life percentage work which shows what percentage of life, they have been employed.
-- AS an example if a person is 40 years old and have been working for 20 years, this results in 50%  lifepercentageworked

Select			NAME_EDUCATION_TYPE , NAME_FAMILY_STATUS , OCCUPATION_TYPE ,	DAYS_EMPLOYED , DAYS_BIRTH ,  
				Round( (DAYS_EMPLOYED / DAYS_BIRTH) * 100,1) AS 'Life_%_Worked'
From			CreditCard..application_record$
Where			OCCUPATION_TYPE is not null
Order By		6 Desc



-- Here we want to Group rows that have the same values into Summary rows, like NAME_EDUCATION_TYPE ,  NAME_FAMILY_STATUS , NAME_housing_TYPE
-- and then aggregate data using Sume function to calculate Life_%_Worked_Per_Group

Select			NAME_EDUCATION_TYPE 
AS 
				Education_Level , NAME_FAMILY_STATUS AS Relationship_Status , 
				NAME_housing_TYPE AS Residence,
				Round(	-avg(DAYS_EMPLOYED) / 365 ,1) AS Avg_Years_Employed , Round( -avg( DAYS_BIRTH) / 365 , 1) AS Avg_Age,
				Round( Sum(DAYS_EMPLOYED) / Sum(DAYS_BIRTH) * 100,1) AS 'Life_%_Worked_Per_Group'
From			CreditCard..application_record$
Where			OCCUPATION_TYPE is not null
Group By		NAME_EDUCATION_TYPE ,  NAME_FAMILY_STATUS , NAME_housing_TYPE
Order By		6 Desc



-- Find which Groups have the highest percentage of their life worked
-- there is no BOTTOM operator in SQL ; if needed you can simply sort (Order By) it in reverse

Select	
				Top 10
				NAME_EDUCATION_TYPE AS Education_Level , NAME_FAMILY_STATUS AS Relationship_Status , 
				NAME_housing_TYPE AS Residence,
				Round(	-avg(DAYS_EMPLOYED) / 365 ,1) AS Avg_Years_Employed , Round( -avg( DAYS_BIRTH) / 365 , 1) AS Avg_Age,
				Round( Sum(DAYS_EMPLOYED) / Sum(DAYS_BIRTH) * 100,1) AS 'Life_%_Worked_Per_Group'

From			CreditCard..application_record$
Where			OCCUPATION_TYPE is not null
Group By		NAME_EDUCATION_TYPE ,  NAME_FAMILY_STATUS , NAME_housing_TYPE
Order By		6 Desc




--Finding the Average_Years_employed For each occupation type

Select			OCCUPATION_TYPE , Round(-avg(days_employed/365),1) AS  Average_Years_employed
From			CreditCard..application_record$
Where			OCCUPATION_TYPE is not null
Group By		OCCUPATION_TYPE
Order By		2 Desc






-- BREAKING THINGS DOWN By  NAME_FAMILY_STATUS , NAME_INCOME_TYPE
-- Showing Family status and income type with the highest Average HoUse income
-- Exclude subsets that are too small to avoid inaccuate insights


Select			NAME_FAMILY_STATUS , NAME_INCOME_TYPE , Count(*) AS G_members_Count ,Round( avg(AMT_INCOME_TOTAL) / 1000  ,0 ) AS Avg_HoUse_Income_X_$1000 
From			CreditCard..application_record$
Group By		NAME_FAMILY_STATUS , NAME_INCOME_TYPE
Having			Count(*) >=10   
Order By		4 Desc



-- GLOBAL NUMBERS
-- In original datASet 365243 days equals to 1000 years which cant be true for DAYS_EMPLOYED
-- Such data are excluded


Select			
			Sum(AMT_INCOME_TOTAL) AS Sum_Total_Income , Sum(CNT_FAM_MEMBERS) AS Sum_Total_Family_Memebrs,
			Round(Sum(-DAYS_EMPLOYED / 365),0) AS Sum_Total_Years_Employed
From			CreditCard..application_record$
Where			DAYS_EMPLOYED != 365243





-- Joining the 2 sources tables with all columns included

Select			*
From			CreditCard..application_record$ AS App
Join			CreditCard..credit_record$      AS Crd
on				app.id=crd.id




-- We Use SQL Partition By to divide the result set into Partitions and perform computation On each subset of Partitioned data.
-- For each subset bASed On  NAME_income_TYPE ,NAME_EDUCATION_TYPE , NAME_FAMILY_STATUS , NAME_HOUSING_TYPE  we want to claculate rolling_months_balance
-- That represerensts te Sum total of MONTHS_BALANCE for that Group


Select  
			app.id, NAME_INCOME_TYPE,NAME_EDUCATION_TYPE, NAME_FAMILY_STATUS , NAME_HOUSING_TYPE ,   -MONTHS_BALANCE AS Month_Count,	
			-Sum(months_balance) Over (Partition By NAME_income_TYPE ,NAME_EDUCATION_TYPE , NAME_FAMILY_STATUS , 
			NAME_HOUSING_TYPE    ) AS rolling_months_balance
From			CreditCard..application_record$ AS App
Join			CreditCard..credit_record$      AS Crd
on				app.id=crd.id
Where			DAYS_EMPLOYED != 365243 and NAME_INCOME_TYPE is not null
Order By		7,1,2








-- We create subquery named SubQ to get the NAME_INCOME_TYPE,NAME_EDUCATION_TYPE, NAME_FAMILY_STATUS , NAME_HOUSING_TYPE ,    Month_Count after Joining 2 tables
-- Using CTE and With ClaUse to perform Calculation On Partition By in previous query
-- the common table expression (CTE) is a temporary named result set that you can reference within a Select, INSERT, UPDATE, or DELETE statement.



with SubQ AS

				(Select  app.id, NAME_INCOME_TYPE,NAME_EDUCATION_TYPE, NAME_FAMILY_STATUS , NAME_HOUSING_TYPE ,   -MONTHS_BALANCE AS Month_Count,	
				-Sum(months_balance) Over (Partition By NAME_income_TYPE ,NAME_EDUCATION_TYPE , NAME_FAMILY_STATUS , NAME_HOUSING_TYPE    ) AS rolling_months_balance
				From CreditCard..application_record$ AS App
				Join CreditCard..credit_record$      AS Crd
				on app.id=crd.id
				Where DAYS_EMPLOYED != 365243 and NAME_INCOME_TYPE is not null)
				
Select			id, NAME_INCOME_TYPE,NAME_EDUCATION_TYPE, NAME_FAMILY_STATUS , NAME_HOUSING_TYPE ,    Month_Count
From			subq
Where			rolling_months_balance < 1000
Order By		id








-- Create Temporary Table #Creditinfo to perform Calculation On Partition By in previous query
		
DROP Table if exists	#Creditinfo
Create Table			#Creditinfo
							(
							id numeric,
							NAME_INCOME_TYPE nvarchar(255),
							NAME_EDUCATION_TYPE nvarchar(255),
							NAME_FAMILY_STATUS nvarchar(255),
							NAME_HOUSING_TYPE nvarchar(255),
							month_Count float,
							rolling_months_balance float
							)
Insert into				#Creditinfo

						Select  app.id, NAME_INCOME_TYPE,NAME_EDUCATION_TYPE, NAME_FAMILY_STATUS , NAME_HOUSING_TYPE ,   -MONTHS_BALANCE AS Month_Count,	
						-Sum(months_balance) Over (Partition By NAME_income_TYPE ,NAME_EDUCATION_TYPE , NAME_FAMILY_STATUS , NAME_HOUSING_TYPE    ) AS rolling_months_balance
						From CreditCard..application_record$ AS App
						Join CreditCard..credit_record$      AS Crd
						on app.id=crd.id
						Where DAYS_EMPLOYED != 365243 and NAME_INCOME_TYPE is not null


Select					* , Round((rolling_months_balance / month_Count) , 0) AS RMPM_ratio
From					#Creditinfo
Where					month_Count!=0




-- Creating View to store data 
-- This can be Used for later visualizations in tableau 
-- Refresh the source databASe  in the object ecplorer to view the results

Use				CreditCard
Go

Create View			CCView_V5 AS

Select				app.id, NAME_INCOME_TYPE,NAME_EDUCATION_TYPE, NAME_FAMILY_STATUS , NAME_HOUSING_TYPE ,   -MONTHS_BALANCE AS Month_Count,	
					-Sum(months_balance) Over (Partition By NAME_income_TYPE ,NAME_EDUCATION_TYPE , NAME_FAMILY_STATUS , NAME_HOUSING_TYPE    ) AS rolling_months_balance
From				CreditCard..application_record$ AS App
					Join CreditCard..credit_record$      AS Crd
					on app.id=crd.id
Where				DAYS_EMPLOYED != 365243 and NAME_INCOME_TYPE is not null




---------------------------------------------------------
Select				*
From				CCView_V5


