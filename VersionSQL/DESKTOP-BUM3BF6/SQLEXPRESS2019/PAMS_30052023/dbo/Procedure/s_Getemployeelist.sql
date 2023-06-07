/****** Object:  Procedure [dbo].[s_Getemployeelist]    Committed by VersionSQL https://www.versionsql.com ******/

/*******************************************************************************************************
Procedure created by shilpa h.m for Employeelisting report
--mod 1 :- ER0182 By Kusuma M.H on 19-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:Component and operation not qualified.So,ER0181 not done.
--mod 2 :- DR0212 By Kusuma M.H on 23-Sep-2009. s_GetEmployeeList ->  Increase the variable size '@strPlantID' from 50 to 100
DR0248 - KarthikR - 11/Aug/2010 - To handle Error Invalid Cursor state If @sortorder='Interfaceid'.
DR0300 - SwathiKS - 09/Nov/2011 :: To Handle 'Invalid Cursor State Error' in Report.
********************************************************************************************************/
--s_Getemployeelist 'Interfaceid',''
CREATE        procedure [dbo].[s_Getemployeelist]
@sortorder nvarchar(50),
@Plantid nvarchar(50)
as
begin
--mod 2
--Declare @StrPlant as nvarchar(50)
Declare @StrPlant as nvarchar(100)
--mod 2
Declare @Str as nvarchar(1000)

/*DR0300 Commented fro here
Create table #Temp
	(
	 	Employeeid  nvarchar(50),
		InterfaceId  nvarchar(50),
		EmployeeName  nvarchar(50),
	 	Designation  nvarchar(50),
		Qualification  nvarchar(50),
		Address1  nvarchar(50),
		Address2 nvarchar(50)
	)
DR0300 Commented Till here. */

--DR0300 From Here.
Create table #Temp
	(
	 	Employeeid  nvarchar(50),
		InterfaceId  nvarchar(50),
		EmployeeName  nvarchar(150),
	 	Designation  nvarchar(100),
		Qualification  nvarchar(100),
		Address1  nvarchar(100),
		Address2 nvarchar(100)
	)
--DR0300 Till Here.

if isnull(@PlantID, '') <> ''
begin
	---mod 1
--	SELECT @StrPlant=' And PlantEmployee.PlantID='''+ @PlantID +''''
	SELECT @StrPlant=' And PlantEmployee.PlantID=N'''+ @PlantID +''''
	---mod 1
end
If @sortorder='EmployeeId'
begin
	select @Str='Insert into #Temp
		select distinct employeeinformation.Employeeid,Interfaceid,Name,Designation,Qualification,Address1,Address2 from employeeinformation  left outer join
		plantemployee on PlantEmployee.employeeid = employeeinformation.employeeid'
	select @Str=	@Str+' where operate=0'
	select @Str=	@Str + isnull(@StrPlant,'')
	select @Str=	@Str +' order by employeeinformation.employeeid'
	exec(@Str)
	set @str=''
	select @Str='Insert into #Temp
		select distinct employeeinformation.Employeeid,Interfaceid,Name,Designation,Qualification,Address1,Address2 from employeeinformation  left outer join
		plantemployee on PlantEmployee.employeeid = employeeinformation.employeeid where operate=1'
	select @Str=@Str + isnull(@StrPlant,'') + ' order by employeeinformation.employeeid'
	
	exec(@Str)
end
If @sortorder='Interfaceid'
begin

/* ----DR0248 - KarthikR - 11/Aug/2010 
	select @Str='Insert into #Temp
		select distinct employeeinformation.Employeeid,cast(employeeinformation.Interfaceid as int),Name,Designation,Qualification,Address1,Address2 from employeeinformation  left outer join
		plantemployee on PlantEmployee.employeeid = employeeinformation.employeeid where operate=0'
	select @Str=@Str + isnull(@StrPlant,'') + ' order by cast(employeeinformation.Interfaceid as int)'
	exec(@Str)
*/
	select @Str='Insert into #Temp
		select distinct employeeinformation.Employeeid,cast(employeeinformation.Interfaceid as bigint),Name,Designation,Qualification,Address1,Address2 from employeeinformation  left outer join
		plantemployee on PlantEmployee.employeeid = employeeinformation.employeeid where operate=0'
	select @Str=@Str + isnull(@StrPlant,'') + ' order by cast(employeeinformation.Interfaceid as bigint)'
	exec(@Str)
---DR0248 - KarthikR - 11/Aug/2010 

	set @str=''
	select @Str='Insert into #Temp
		select distinct employeeinformation.Employeeid,employeeinformation.Interfaceid,Name,Designation,Qualification,Address1,Address2 from employeeinformation  left outer join
		plantemployee on PlantEmployee.employeeid = employeeinformation.employeeid where operate=1'
	select @Str=@Str + isnull(@StrPlant,'') + ' order by employeeinformation.Interfaceid'
	exec(@Str)
end
select * from #Temp
end
