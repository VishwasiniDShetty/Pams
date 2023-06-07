/****** Object:  Procedure [dbo].[s_GetDownCodelist]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************************************************************
Procedure created by Mrudula Rao on 05-dec-2007 for DR0070
Procedure used in SM_DowncodeList Report.
Procedure altered by Kusuma M.H on 25-Feb-2009 for DR0164.
mod 1 :- ER0182 By Kusuma M.H on 19-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:Component and operation not qualified.So,ER0181 not done.
mod 2 :- By Mrudula M. Rao on 08-oct-2009 for DR0216.Error Detected By Database DLL when user selects sort by Interfaceid.
		 Add "CyCti" as non changable down id.
--ER0414 - SwathiKS - 18/Aug/2015 :: To include Predefined Downs 'Early Closure' and 'Absent'.
**********************************************************************************************************/
--[dbo].[s_GetDownCodelist] 'interfaceid',''
------This procedure is used in the report SM_DownCodeListing.rpt
CREATE	Procedure [dbo].[s_GetDownCodelist]
	@sortorder as nvarchar(50)='',
	@category as nvarchar(50)='' --DR0164::Kusuma M.H
as
Begin
create table #DownList
	(
		DownID  nvarchar(50),
		downno int,
		downInt nvarchar(50),
		downdesc nvarchar(100),
		Category nvarchar(100),
		Threshold Float
	)
---mod 1
---Increased the size of the string to support unicode characters.
--Declare @strsql as nvarchar(1000)
--declare @strsql2 as  nvarchar(1000)
Declare @strsql as nvarchar(4000)
declare @strsql2 as  nvarchar(4000)
---mod 1
Declare @downcategory as nvarchar(250)--DR0164::Kusuma M.H
-- If @sortorder='Downid'
--	begin
--		select @strsql= 'insert into #DownList(DownID,downno ,downInt,downdesc,Category,Threshold ) '
--		
--		select @strsql= @strsql + 'select downcodeinformation.Downid,downcodeinformation.Downno,downcodeinformation.Interfaceid
--					   ,downcodeinformation.DownDescription,Catagory,Threshold from Downcodeinformation '
--		select @strsql=@strsql + ' order by downcodeinformation.Downid asc'
--		print @strsql
--		exec(@strsql)
--	end
--	
--	If @sortorder='Interfaceid'
--	begin
--
--		insert into #DownList(DownID,downno ,downInt,downdesc,Category,Threshold )
--		select downcodeinformation.Downid,downcodeinformation.Downno,convert(nvarchar(50),cast(downcodeinformation.Interfaceid as int))
--					   ,downcodeinformation.DownDescription,Catagory,Threshold from Downcodeinformation where
--		and downcodeinformation.Interfaceid not in ('NO_DATA','unknown','McTI' )	
--		order by cast(downcodeinformation.Interfaceid as int) asc
--
--		insert into #DownList(DownID,downno ,downInt,downdesc,Category,Threshold )
--		select downcodeinformation.Downid,downcodeinformation.Downno,downcodeinformation.Interfaceid
--					   ,downcodeinformation.DownDescription,Catagory,Threshold from Downcodeinformation where
--		and downcodeinformation.Interfaceid  in ('NO_DATA','unknown','McTI' )	
--		order by downcodeinformation.Interfaceid  asc
if isnull(@category,'')<>''
	begin
	---mod 1
--	set @downcategory =' where downcodeinformation.catagory =''' + @category + ''''
	set @downcategory =' where downcodeinformation.catagory =N''' + @category + ''''
	print @category
	print @downcategory
	---mod 1
	If @sortorder='Downid'
		begin
		select @strsql= 'insert into #DownList(DownID,downno ,downInt,downdesc,Category,Threshold ) '
		
		select @strsql= @strsql + 'select downcodeinformation.Downid,downcodeinformation.Downno,downcodeinformation.Interfaceid
					   ,downcodeinformation.DownDescription,Catagory,Threshold from Downcodeinformation ' + @downcategory
		select @strsql=@strsql + ' order by downcodeinformation.Downid asc'
		print @strsql
		exec(@strsql)
	end
	
	If @sortorder='Interfaceid'
	begin
		insert into #DownList(DownID,downno ,downInt,downdesc,Category,Threshold )
		select downcodeinformation.Downid,downcodeinformation.Downno,convert(nvarchar(50),cast(downcodeinformation.Interfaceid as int))
					   ,downcodeinformation.DownDescription,Catagory,Threshold from Downcodeinformation where Downcodeinformation.catagory=@category
		and downcodeinformation.Interfaceid 
		---mod 2
		---not in ('NO_DATA','unknown','McTI' )	
		--not in ('NO_DATA','unknown','McTI','CycTI')
		not in ('NO_DATA','unknown','McTI','CycTI','Early Closure','Absent','Dummy Cycle','Dry Cycle','DCL','DCLU','SCI','SCILU') --ER0414 --SV

		---mod 2
		order by cast(downcodeinformation.Interfaceid as int) asc

		
		insert into #DownList(DownID,downno ,downInt,downdesc,Category,Threshold )
		select downcodeinformation.Downid,downcodeinformation.Downno,downcodeinformation.Interfaceid
					   ,downcodeinformation.DownDescription,Catagory,Threshold from Downcodeinformation where Downcodeinformation.catagory=@category
		and downcodeinformation.Interfaceid  
		---mod 2
		---in ('NO_DATA','unknown','McTI' )	
		--in ('NO_DATA','unknown','McTI','CycTI')
		in ('NO_DATA','unknown','McTI','CycTI','Early Closure','Absent','Dummy Cycle','Dry Cycle','DCL','DCLU','SCI','SCILU') --ER0414 --SV

		---mod 2
		order by downcodeinformation.Interfaceid  asc
	end
	end
else
	begin
	If @sortorder='Downid'
		begin
		select @strsql= 'insert into #DownList(DownID,downno ,downInt,downdesc,Category,Threshold ) '
		
		select @strsql= @strsql + 'select downcodeinformation.Downid,downcodeinformation.Downno,downcodeinformation.Interfaceid
					   ,downcodeinformation.DownDescription,Catagory,Threshold from Downcodeinformation '
		select @strsql=@strsql + ' order by downcodeinformation.Downid asc'
--		print @strsql
		exec(@strsql)
		
	end
	If @sortorder='Interfaceid'
	begin
		insert into #DownList(DownID,downno ,downInt,downdesc,Category,Threshold )
		select downcodeinformation.Downid,downcodeinformation.Downno,convert(nvarchar(50),cast(downcodeinformation.Interfaceid as int))
					   ,downcodeinformation.DownDescription,Catagory,Threshold from Downcodeinformation where
		downcodeinformation.Interfaceid 
		---mod 2
		---not in ('NO_DATA','unknown','McTI' )	
		--not in ('NO_DATA','unknown','McTI','CycTI') --ER0414
		--not in ('NO_DATA','unknown','McTI','CycTI','Early Closure','Absent') --ER0414
		not in ('NO_DATA','unknown','McTI','CycTI','Early Closure','Absent','Dummy Cycle','Dry Cycle','DCL','DCLU','SCI','SCILU') --ER0414 --SV
		---mod 2
		order by cast(downcodeinformation.Interfaceid as int) asc
	
		insert into #DownList(DownID,downno ,downInt,downdesc,Category,Threshold )
		select downcodeinformation.Downid,downcodeinformation.Downno,downcodeinformation.Interfaceid
					   ,downcodeinformation.DownDescription,Catagory,Threshold from Downcodeinformation
		where downcodeinformation.Interfaceid 
		 ---mod 2
		---in ('NO_DATA','unknown','McTI' )	
		--in ('NO_DATA','unknown','McTI','CycTI') --ER0414
		--in ('NO_DATA','unknown','McTI','CycTI','Early Closure','Absent')--ER0414
		in ('NO_DATA','unknown','McTI','CycTI','Early Closure','Absent','Dummy Cycle','Dry Cycle','DCL','DCLU','SCI','SCILU') --ER0414 --SV

		---mod 2
		order by downcodeinformation.Interfaceid  asc
	end --DR0164::Kusuma M.H
end
	select * from #DownList
end
