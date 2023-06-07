/****** Object:  Procedure [dbo].[s_GetShiftwiseHourlyProdandDownAndon]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0421 - Swathi KS - 28/Jan/2016 :: To Include PE i.e CumulativeActual/Target
--[dbo].[s_GetShiftwiseHourlyProdandDownAndon] '2015-12-21 12:15:22.993','ABDS LINE','report'
--[dbo].[s_GetShiftwiseHourlyProdandDownAndon] '2015-12-21 12:10:17.917','ABDS LINE','dashboard'

CREATE PROCEDURE [dbo].[s_GetShiftwiseHourlyProdandDownAndon]
@StartTime nvarchar(50),
@Machineid nvarchar(50),
@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;



create Table #HourwiseDetails
(
	id bigint identity(1,1) NOT NULL,
	Rowindicator Nvarchar(50),
	ShiftName Nvarchar(50),
	StartDate Nvarchar(50),
	HourID Nvarchar(50),
	HourStart Nvarchar(50),
	HourEnd Nvarchar(50),
	HourTimeDisplay nvarchar(50),
	Machineinterface nvarchar(50),
	ProjectCode nvarchar(50),
	ProjectCodeinterface nvarchar(50) ,
--	Target Nvarchar(50) default 0,
--	Actual Nvarchar(50) default 0,
	Target float default 0,
	Actual float default 0,
	Loss1 nvarchar(MAX),
	Loss2 nvarchar(50),
	Loss3 nvarchar(50),
	Loss4 nvarchar(50),
	Loss5 nvarchar(50),
	Loss6 nvarchar(50),
	Loss7 nvarchar(50),
	RejTarget Nvarchar(50),
	RejActual Nvarchar(50),
	RejReason nvarchar(MAX),
	Operator nvarchar(50),
	ShiftID nvarchar(50),
	PE Float	
)

create Table #HourwiseDetailstemp
(
	Rowindicator Nvarchar(50),
	ShiftName Nvarchar(50),
	StartDate Nvarchar(50),
	HourID Nvarchar(50),
	HourStart Nvarchar(50),
	HourEnd Nvarchar(50),
	HourTimeDisplay nvarchar(50),
	Machineinterface nvarchar(50),
	ProjectCode nvarchar(50),
	ProjectCodeinterface nvarchar(50) ,
--	Target Nvarchar(50) default 0,
--	Actual Nvarchar(50) default 0,
	Target float default 0,
	Actual float default 0,
	Loss1 nvarchar(MAX),
	Loss2 nvarchar(50),
	Loss3 nvarchar(50),
	Loss4 nvarchar(50),
	Loss5 nvarchar(50),
	Loss6 nvarchar(50),
	Loss7 nvarchar(50),
	RejTarget Nvarchar(50),
	RejActual Nvarchar(50),
	RejReason nvarchar(MAX),
	Operator nvarchar(50),
	ShiftID nvarchar(50),
	PE Float	
)


create table #ShiftTemp
(
	Slno int identity(1,1) NOT NULL,
	StartDate  Nvarchar(50),
	ShiftName nvarchar(50),
	Starttime datetime,
	EndTime datetime,
	ShiftID int
)

Create Table #HourTemp1
(
	ShiftName nvarchar(50),
	StartDate  Nvarchar(50),
	HourID Nvarchar(50),
	HourStart Nvarchar(50),
	HourEnd Nvarchar(50),
	HourTimeDisplay nvarchar(50),
	ShiftID int
)

Create Table #HourTemp
(
	ShiftName nvarchar(50),
	StartDate  Nvarchar(50),
	HourID Nvarchar(50),
	HourStart Nvarchar(50),
	HourEnd Nvarchar(50),
	HourTimeDisplay nvarchar(50),
	ShiftID int
)

Create Table #CatagoryHead
(
	CatagoryID bigint identity(1,1) NOT NULL,
	CatagoryHead nvarchar(50)
)

CREATE TABLE #T_autodata(
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] NULL,
	[datatype] [tinyint] NULL ,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] NULL,
	[PartsCount] decimal(18,5) NULL , 
	id  bigint not null
)


Declare @Curtime as datetime
Select @Curtime = getdate()

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 


--insert into #HourwiseDetailstemp(Rowindicator,ShiftName,StartDate,Machineinterface,HourTimeDisplay,HourStart,HourEnd,HourID,ProjectCode,ProjectCodeinterface,Target,Actual,RejTarget,RejActual,RejReason,Operator,ShiftID)
--select 'H','ShiftName','StartDate','Machineinterface','HourTimeDisplay','HourStart','HourEnd','HourID','ProjectCode','ProjectCodeinterface','Target','Actual','RejTarget','RejActual','RejReason','Operator','ShiftID'


Declare @i as Nvarchar(50),@j as nvarchar(50)
Declare @countofrows as Nvarchar(50)
Declare @ColName as Nvarchar(50)
Declare @strsql as nvarchar(MAX)
Declare @Counter as nvarchar(50)
declare @curstarttime as datetime  
Declare @curendtime as datetime  
declare @Endtime as datetime  
Declare @StrDiv int  

Update #HourwiseDetailstemp Set Loss1 = 'Issues for Not Meeting Target'

/*
Insert into #CatagoryHead(CatagoryHead)
select Distinct Catagory from downcodeinformation where Catagory IS NOT NULL order by Catagory
*/

Insert into #CatagoryHead(CatagoryHead)Values('Equipment failure')
Insert into #CatagoryHead(CatagoryHead)Values('Setup and Adjustment')
Insert into #CatagoryHead(CatagoryHead)Values('Idling and Minor stoppages')
Insert into #CatagoryHead(CatagoryHead)Values('Reduced Speed')
Insert into #CatagoryHead(CatagoryHead)Values('Defects in Process')
Insert into #CatagoryHead(CatagoryHead)Values('Start up losses')

Select @countofrows = Count(CatagoryHead) from #CatagoryHead 

Select @i = 1
Select @j = 2
Select @ColName= 'Loss' + @j



while @i <=@countofrows
Begin
	Select @strSql=''
	Select @strSql = @strSql + 'Update #HourwiseDetailstemp Set ' + @ColName + '= T.CatagoryHead from
	(select Distinct CatagoryHead from #CatagoryHead where CatagoryID= ''' + @i + ''')T '
	print @strsql
	Exec(@strSql) 

	Select @i= @i + 1
	Select @j= @j + 1
	Select @ColName= 'Loss' + @j
end

If @param = 'Dashboard'
Begin
	Insert into #ShiftTemp(StartDate,ShiftName, Starttime,EndTime,ShiftID)  
	Exec [s_GetCurrentShiftTime] @StartTime,''  
END

If @param = 'Report'
Begin
	Insert into #ShiftTemp(StartDate,ShiftName, Starttime,EndTime)  
	Exec s_GetShiftTime @StartTime,''  
END

Declare @mc as nvarchar(50)
Select @mc=interfaceid from machineinformation where machineid=@Machineid

Select @T_ST=min(Starttime) from #ShiftTemp 
Select @T_ED=max(EndTime) from #ShiftTemp 

Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where mc= ''' + @mc +''' and (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
				 and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)

declare @k as int
Declare @count as int
Declare @shift as nvarchar(50)
declare @shiftid as int
declare @LogicalDaystart as datetime
Select @k = 1
Select @Count = count(*) from #ShiftTemp

While @k <= @Count
Begin

	SELECT TOP 1 @counter=Starttime FROM #ShiftTemp where slno=@k ORDER BY Starttime ASC  
	SELECT TOP 1 @EndTime=EndTime FROM #ShiftTemp where slno=@k ORDER BY Starttime DESC  
	Select @Shift = Shiftname from #ShiftTemp where slno=@k 
	Select @shiftid = Shiftid from #ShiftTemp where slno=@k 
	Select @LogicalDaystart=StartDate from #ShiftTemp where slno=@k 
	select @StrDiv=cast (ceiling (cast(datediff(second,@counter,@EndTime)as float ) /3600) as int)   
	Select @i=1

	While(@counter < @EndTime)  
	BEGIN  
		SELECT @curstarttime=@counter  
		SELECT @curendtime=DATEADD(Second,3600,@counter)  
		if @curendtime >= @EndTime  
		Begin  
		 set @curendtime = @EndTime  
		End  

		 Insert into #HourTemp1(ShiftName,StartDate,HourID,HourStart,HourEnd,HourTimeDisplay,ShiftID)
		 Select @Shift,Convert(nvarchar(10),@LogicalDaystart,120) + ' 00:00:00.000',@i,convert(nvarchar(20),@curstarttime,120),
		 convert(nvarchar(20),@curendtime,120),
		Case Len(convert(Nvarchar(2),Datepart(hh,@curstarttime))) When 1 then '0'+convert(Nvarchar(2),Datepart(hh,@curstarttime))Else convert(Nvarchar(2),Datepart(hh,@curstarttime)) End +':'+
		Case Len(convert(Nvarchar(2),Datepart(n,@curstarttime))) When 1 then '0'+convert(Nvarchar(2),Datepart(n,@curstarttime))Else convert(Nvarchar(2),Datepart(n,@curstarttime)) End+' - '+
		Case Len(convert(Nvarchar(2),Datepart(hh,@curendtime))) When 1 then '0'+convert(Nvarchar(2),Datepart(hh,@curendtime))Else convert(Nvarchar(2),Datepart(hh,@curendtime)) End +':'+
		Case Len(convert(Nvarchar(2),Datepart(n,@curendtime))) When 1 then '0'+convert(Nvarchar(2),Datepart(n,@curendtime))Else convert(Nvarchar(2),Datepart(n,@curendtime)) End,
		case when @Count>1 then @k else @shiftid end
				
		 SELECT @counter = DATEADD(Second,3600,@counter)  
		Select @i = @i + 1
	END  

Select @k = @k +1
END


If @param = 'Dashboard'
Begin
	Insert into #HourTemp(ShiftName,StartDate,HourID,HourStart,HourEnd,HourTimeDisplay,ShiftID)
	Select ShiftName,StartDate,HourID,HourStart,HourEnd,HourTimeDisplay,ShiftID from #HourTemp1 where Hourstart<=@Curtime
End

If @param = 'Report'
Begin
	Insert into #HourTemp(ShiftName,StartDate,HourID,HourStart,HourEnd,HourTimeDisplay,ShiftID)
	Select ShiftName,StartDate,HourID,HourStart,HourEnd,HourTimeDisplay,ShiftID from #HourTemp1 
End

Select @strsql=''
select @strsql ='INSERT INTO #HourwiseDetailstemp(Rowindicator,Shiftname,StartDate,HourID,HourStart,HourEnd,HourTimeDisplay,Machineinterface,ProjectCode,ProjectCodeinterface,Target,Actual,ShiftID,PE)'
select @strsql = @strsql + 'SELECT distinct ''D'',Shiftname,StartDate,HourID,HourStart,HourEnd,HourTimeDisplay,machineinformation.interfaceid,
				componentinformation.componentid,componentinformation.interfaceid,0,0,ShiftID,0'
select @strsql = @strsql + ' from #T_autodata autodata  INNER JOIN  machineinformation on machineinformation.interfaceid=autodata.mc'
select @strsql = @strsql + ' INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID '
select @strsql = @strsql + ' INNER JOIN componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
select @strsql = @strsql + ' INNER JOIN employeeinformation on autodata.opr=employeeinformation.interfaceid 
							left outer Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID'
select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '
select @strsql = @strsql + ' cross join #HourTemp where '
select @strsql = @strsql + '(( sttime >= HourStart and ndtime <= HourEnd ) OR '
select @strsql = @strsql + '( sttime < HourStart and ndtime > HourEnd )OR '
select @strsql = @strsql + '( sttime < HourStart and ndtime > HourStart and ndtime<=HourEnd )'
select @strsql = @strsql + ' OR ( sttime >= HourStart and ndtime > HourEnd and sttime<HourEnd )) and machineinformation.interfaceid>0 '
select @strsql = @strsql + ' and machineinformation.machineid= ''' + @machineid + ''''
select @strsql = @strsql + ' order by HourStart'
print @strsql
exec (@strsql)



INSERT INTO #HourwiseDetails(Rowindicator,Shiftname,StartDate,HourID,HourStart,HourEnd,HourTimeDisplay,Machineinterface,ProjectCode,ProjectCodeinterface,Target,Actual,ShiftID,PE)
Select 'D',H.Shiftname,H.StartDate,H.HourID,H.HourStart,H.HourEnd,H.HourTimeDisplay,Machineinterface,ProjectCode,ProjectCodeinterface,Target,Actual,H.ShiftID,0
from #HourwiseDetailstemp HD right outer join #HourTemp H on H.Hourstart=HD.Hourstart



--Update #HourwiseDetails set Target = T1.66 from
--(
--Select H.HourStart,H.HourEnd,H.ProjectCode,S.target from shifthourtargets S inner join #HourwiseDetails H on S.Componentid=H.ProjectCode
--where S.sdate=(select top 1 S.Sdate from shifthourtargets S
--inner join #HourwiseDetails H on S.Componentid=H.ProjectCode and S.shiftid=H.shiftid
--where S.Sdate<=H.StartDate And S.machineid=@Machineid order by S.sdate desc) And S.Hourid=H.Hourid and S.shiftid=H.shiftid
--And S.machineid=@Machineid)T1 inner join #HourwiseDetails H on T1.Hourstart=H.Hourstart and T1.Hourend=H.HourEnd and T1.ProjectCode=H.ProjectCode and H.Rowindicator='D'


Update #HourwiseDetails set Target = T1.Target from
(
select H.HourStart,H.HourEnd,H.ProjectCode,T.Target
from (
     select S.Sdate,
            S.Componentid,
            S.Shiftid,
	    S.hourid,
	    S.Target,
            row_number() over(partition by S.Componentid,S.shiftid,S.hourid order by S.Sdate desc) as rn
     from Shifthourtargets S where S.Machineid=@Machineid
     ) as T inner join #HourwiseDetails H on T.Componentid=H.ProjectCode and T.Shiftid=H.Shiftid and T.Hourid=H.Hourid
where T.rn <= 1)T1 inner join #HourwiseDetails H on T1.Hourstart=H.Hourstart and T1.Hourend=H.HourEnd and T1.ProjectCode=H.ProjectCode and H.Rowindicator='D'

Update #HourwiseDetails set Actual = Isnull(Actual,0) + Isnull(T1.Comp,0) from  
(Select T.ProjectCode,T.HourStart,T.HourEnd,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
from autodata A
Inner join machineinformation M on M.interfaceid=A.mc
Inner join #HourwiseDetails T on T.Machineinterface=A.mc and T.ProjectCodeinterface=A.comp
Inner join componentinformation C ON A.Comp=C.interfaceid
Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
WHERE A.DataType=1 and M.machineid=@Machineid
AND(A.ndtime > T.HourStart  AND A.ndtime <=T.HourEnd) and T.Rowindicator='D'
Group by T.ProjectCode,T.HourStart,T.HourEnd)T1 inner join #HourwiseDetails on #HourwiseDetails.HourStart=T1.HourStart
and #HourwiseDetails.HourEnd=T1.HourEnd and #HourwiseDetails.ProjectCode=T1.ProjectCode and #HourwiseDetails.Rowindicator='D'

Select @countofrows = Count(CatagoryHead) from #CatagoryHead 

Select @i = 1
Select @j = 2
Select @ColName= 'Loss' + @j

while @i <=@countofrows
Begin
	Select @strSql=''
	Select @strSql = @strSql + 'Update #HourwiseDetails Set ' + @ColName + '= T.Down from
	(SELECT T1.ProjectCode,T1.HourStart,T1.HourEnd,D.Catagory,sum(
			CASE
	        WHEN  autodata.msttime>=T1.HourStart  and  autodata.ndtime<=T1.HourEnd  THEN  loadunload
			WHEN (autodata.msttime<T1.HourStart and  autodata.ndtime>T1.HourStart and autodata.ndtime<=T1.HourEnd)  THEN DateDiff(second, T1.HourStart, ndtime)
			WHEN (autodata.msttime>=T1.HourStart  and autodata.sttime<T1.HourEnd  and autodata.ndtime>T1.HourEnd)  THEN DateDiff(second, stTime, T1.HourEnd)
			WHEN autodata.msttime<T1.HourStart and autodata.ndtime>T1.HourEnd THEN DateDiff(second, T1.HourStart, T1.HourEnd)
			END
		)AS down
	from #T_autodata autodata 
	Inner join machineinformation M on M.interfaceid=autodata.mc
	Inner join #HourwiseDetails T1 on T1.Machineinterface=autodata.mc and T1.ProjectCodeinterface=autodata.comp
	Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
	Inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
	inner join #CatagoryHead C on D.Catagory=C.CatagoryHead
	where autodata.datatype=2 AND M.machineid= ''' + @Machineid + ''' and 
	(
	(autodata.msttime>=T1.HourStart  and  autodata.ndtime<=T1.HourEnd)
	OR (autodata.sttime<T1.HourStart and  autodata.ndtime>T1.HourStart and autodata.ndtime<=T1.HourEnd)
	OR (autodata.msttime>=T1.HourStart  and autodata.sttime<T1.HourEnd  and autodata.ndtime>T1.HourEnd)
	OR (autodata.msttime<T1.HourStart and autodata.ndtime>T1.HourEnd)
	) AND C.CatagoryID= ''' + @i + ''' and T1.Rowindicator=''D''
	group by T1.ProjectCode,T1.HourStart,T1.HourEnd,D.Catagory)T inner join #HourwiseDetails on #HourwiseDetails.HourStart=T.HourStart
	and #HourwiseDetails.HourEnd=T.HourEnd and #HourwiseDetails.ProjectCode=T.ProjectCode and #HourwiseDetails.Rowindicator=''D'''
	print @strsql
	Exec(@strSql) 

	Select @i= @i + 1
	Select @j= @j +1
	Select @ColName= 'Loss' + @j
end


SELECT T1.ProjectCode,T1.HourStart,T1.HourEnd,D.Downid,sum(
		CASE
        WHEN  autodata.msttime>=T1.HourStart  and  autodata.ndtime<=T1.HourEnd  THEN  loadunload
		WHEN (autodata.msttime<T1.HourStart and  autodata.ndtime>T1.HourStart and autodata.ndtime<=T1.HourEnd)  THEN DateDiff(second, T1.HourStart, ndtime)
		WHEN (autodata.msttime>=T1.HourStart  and autodata.sttime<T1.HourEnd  and autodata.ndtime>T1.HourEnd)  THEN DateDiff(second, stTime, T1.HourEnd)
		WHEN autodata.msttime<T1.HourStart and autodata.ndtime>T1.HourEnd   THEN DateDiff(second, T1.HourStart, T1.HourEnd)
		END
	)AS down,0 as batchid
into #TempDown  from #T_autodata autodata
Inner join machineinformation M on M.interfaceid=autodata.mc
Inner join #HourwiseDetails T1 on T1.Machineinterface=autodata.mc and T1.ProjectCodeinterface=autodata.comp
Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
Inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
inner join #CatagoryHead C on D.Catagory=C.CatagoryHead
where autodata.datatype=2 AND M.machineid= @Machineid and 
(
(autodata.msttime>=T1.HourStart  and  autodata.ndtime<=T1.HourEnd)
OR (autodata.sttime<T1.HourStart and  autodata.ndtime>T1.HourStart and autodata.ndtime<=T1.HourEnd)
OR (autodata.msttime>=T1.HourStart  and autodata.sttime<T1.HourEnd  and autodata.ndtime>T1.HourEnd)
OR (autodata.msttime<T1.HourStart and autodata.ndtime>T1.HourEnd)
) and T1.Rowindicator='D'
group by T1.ProjectCode,T1.HourStart,T1.HourEnd,D.Downid
order by T1.HourStart asc,down desc

--SV From Here
--SELECT
-- B.HourStart,B.ProjectCode
--,SUBSTRING((SELECT ','+ CAST(Downid AS VARCHAR) + ' (' + cast(Round([dbo].[f_FormatTime](down,'mm'),2) as Varchar) + ')'
--            FROM #TempDown A
--            WHERE A.HourStart = B.HourStart and A.ProjectCode = B.ProjectCode
--            FOR XML PATH('')
--             ),2,100)As Downid_CSV
--INTO #Down FROM #TempDown B
--GROUP BY  B.HourStart,B.ProjectCode

SELECT
 B.HourStart,B.ProjectCode
,SUBSTRING((SELECT ','+ CAST(Downid AS VARCHAR) + ' (' + cast([dbo].[f_FormatTime](down,'hh:mm') as Varchar) + ')'
            FROM #TempDown A
            WHERE A.HourStart = B.HourStart and A.ProjectCode = B.ProjectCode
            FOR XML PATH('')
             ),2,100)As Downid_CSV
INTO #Down FROM #TempDown B
GROUP BY  B.HourStart,B.ProjectCode
--SV till Here


Update #HourwiseDetails set Loss1=T1.Loss from
(Select HourStart,ProjectCode,Downid_CSV as Loss from #Down)T1  inner join #HourwiseDetails on #HourwiseDetails.HourStart=T1.HourStart
and #HourwiseDetails.ProjectCode=T1.ProjectCode and #HourwiseDetails.Rowindicator='D'


Update #HourwiseDetails set RejTarget = T1.RejTarget from
(Select (100-Isnull(QE,95)) as RejTarget from EfficiencyTarget where machineid=@Machineid and
convert(nvarchar(10),@starttime,120) between convert(nvarchar(10),startdate,120) and convert(nvarchar(10),enddate,120) and Targetlevel='MONTH')T1


Update #HourwiseDetails set RejActual = T1.RejActual from
(Select T1.ProjectCode,T1.HourStart,T1.HourEnd,SUM(A.Rejection_Qty) as RejActual
from AutodataRejections A 
Inner join machineinformation M on M.interfaceid=A.mc
Inner join rejectioncodeinformation R on R.interfaceid=A.Rejection_Code
Inner join #HourwiseDetails T1 on T1.Machineinterface=A.mc and T1.ProjectCodeinterface=A.comp
where A.Flag='Rejection' and M.machineid=@Machineid 
and (A.CreatedTS>=T1.HourStart  and A.CreatedTS<=T1.HourEnd)and T1.Rowindicator='D'
group by T1.ProjectCode,T1.HourStart,T1.HourEnd
)T1 inner join #HourwiseDetails on #HourwiseDetails.HourStart=T1.HourStart
and #HourwiseDetails.HourEnd=T1.HourEnd and #HourwiseDetails.ProjectCode=T1.ProjectCode and #HourwiseDetails.Rowindicator='D'


Update #HourwiseDetails set RejActual = round((cast(RejActual as float)/cast(Actual as float))*100,2) where RejActual is not null and Rowindicator='D'

Select T1.ProjectCode,T1.HourStart,T1.HourEnd,SUM(A.Rejection_Qty) as RejActual,R.rejectionid as Rejection_Code into #RejTemp
from AutodataRejections A 
Inner join rejectioncodeinformation R on R.interfaceid=A.Rejection_Code
Inner join machineinformation M on M.interfaceid=A.mc
Inner join #HourwiseDetails T1 on T1.Machineinterface=A.mc and T1.ProjectCodeinterface=A.comp
where A.Flag='Rejection' and M.machineid=@Machineid 
and (A.CreatedTS>=T1.HourStart  and A.CreatedTS<=T1.HourEnd)and T1.Rowindicator='D'
group by T1.ProjectCode,T1.HourStart,T1.HourEnd,R.rejectionid

SELECT
 B.HourStart,B.ProjectCode
,SUBSTRING((SELECT ','+ CAST(Rejection_Code AS VARCHAR) + ' (' + cast(RejActual as Varchar) + ')'
            FROM #RejTemp A
            WHERE A.HourStart = B.HourStart and A.ProjectCode = B.ProjectCode
            FOR XML PATH('')
             ),2,100)As Rej_CSV
INTO #Rej FROM #RejTemp B
GROUP BY  B.HourStart,B.ProjectCode


Update #HourwiseDetails set RejReason=T1.Loss from
(Select HourStart,ProjectCode,Rej_CSV as Loss from #Rej)T1  inner join #HourwiseDetails on #HourwiseDetails.HourStart=T1.HourStart
and #HourwiseDetails.ProjectCode=T1.ProjectCode and #HourwiseDetails.Rowindicator='D'


Update #HourwiseDetails set Operator = T2.Operator from
(Select T1.Shiftname,T1.opr as Operator from
(Select T.Shiftname,T.opr,row_number() over(partition by T.shiftname order by T.Reccount desc) as rn from
(Select Shiftname,employeeinformation.employeeid as opr,Count(*) as Reccount from #T_autodata autodata
INNER JOIN  machineinformation on machineinformation.interfaceid=autodata.mc 
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID  
INNER JOIN componentoperationpricing COP ON autodata.opn = COP.InterfaceID AND componentinformation.componentid = COP.componentid and COP.machineid=machineinformation.machineid  
INNER JOIN employeeinformation on autodata.opr=employeeinformation.interfaceid 
Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID  
cross join #ShiftTemp where (sttime >= starttime and ndtime <= Endtime )  
and machineinformation.interfaceid>0 and machineinformation.machineid= @machineid 
group by Shiftname,employeeinformation.employeeid)T where Reccount>0
)T1 where T1.rn=1)T2 inner join #HourwiseDetails on #HourwiseDetails.shiftname=T2.shiftname and #HourwiseDetails.Rowindicator='D'



INSERT INTO #HourwiseDetails(Rowindicator,Shiftname,HourTimeDisplay,Target,Actual,Loss2,Loss3,Loss4,Loss5,Loss6,Loss7,RejTarget,RejActual,PE)
Select 'Summary',case when @param = 'Report' then 'ALL' else max(Shiftname) end ,
Case Len(convert(Nvarchar(2),Datepart(hh,@T_ST))) When 1 then '0'+convert(Nvarchar(2),Datepart(hh,@T_ST))Else convert(Nvarchar(2),Datepart(hh,@T_ST)) End +':'+
Case Len(convert(Nvarchar(2),Datepart(n,@T_ST))) When 1 then '0'+convert(Nvarchar(2),Datepart(n,@T_ST))Else convert(Nvarchar(2),Datepart(n,@T_ST)) End+' - '+
Case Len(convert(Nvarchar(2),Datepart(hh,@T_ED))) When 1 then '0'+convert(Nvarchar(2),Datepart(hh,@T_ED))Else convert(Nvarchar(2),Datepart(hh,@T_ED)) End +':'+
Case Len(convert(Nvarchar(2),Datepart(n,@T_ED))) When 1 then '0'+convert(Nvarchar(2),Datepart(n,@T_ED))Else convert(Nvarchar(2),Datepart(n,@T_ED)) End,
sum(Cast(Target as float)),sum(Cast(Actual as float)),Sum(cast(Loss2 as float)),Sum(cast(Loss3 as float)),Sum(cast(Loss4 as float)),Sum(cast(Loss5 as float)),Sum(cast(Loss6 as float)),Sum(cast(Loss7 as float)),
max(cast(RejTarget as float)),Sum(cast(RejActual as float)),Round(sum(Cast(Actual as float))/sum(Cast(Target as float))*100,2) from #HourwiseDetails Where Rowindicator='D' 

update #HourwiseDetails set Loss2 = [dbo].[f_FormatTime](Loss2,'hh:mm') where Loss2 IS NOT NULL and Rowindicator='D' 
update #HourwiseDetails set Loss3 = [dbo].[f_FormatTime](Loss3,'hh:mm') where Loss3 IS NOT NULL and Rowindicator='D' 
update #HourwiseDetails set Loss4 = [dbo].[f_FormatTime](Loss4,'hh:mm') where Loss4 IS NOT NULL and Rowindicator='D' 
update #HourwiseDetails set Loss5 = [dbo].[f_FormatTime](Loss5,'hh:mm') where Loss5 IS NOT NULL and Rowindicator='D' 
update #HourwiseDetails set Loss6 = [dbo].[f_FormatTime](Loss6,'hh:mm') where Loss6 IS NOT NULL and Rowindicator='D' 
update #HourwiseDetails set Loss7 = [dbo].[f_FormatTime](Loss7,'hh:mm') where Loss7 IS NOT NULL and Rowindicator='D' 

--update #HourwiseDetails set PE = Round((Actual/Target)*100,2) where Target>0 and Rowindicator='D' 

--update #HourwiseDetails set PE = Round((T1.cumulative/T1.Target)*100,2) from
--(
--select startdate,shiftname,hourstart,projectcode,target,
--       (select sum(actual) 
--        from #HourwiseDetails H2
--        where H2.startdate = H1.startdate and H2.shiftname = H1.shiftname and 
--           H2.projectcode = H1.projectcode and H2.hourstart <= H1.hourstart and Target>0 and Rowindicator='D' 
--       ) as cumulative
--from #HourwiseDetails H1 where Target>0 and Rowindicator='D' 
--)T1 inner join #HourwiseDetails on #HourwiseDetails.HourStart=T1.HourStart
--and #HourwiseDetails.ProjectCode=T1.ProjectCode and #HourwiseDetails.Rowindicator='D'


update #HourwiseDetails set PE = Round((T1.CumActual/T1.CumTarget)*100,2) from
(
select H2.id,H2.startdate,H2.shiftname,H2.hourstart,H2.projectcode,
       (select sum(H1.actual) from #HourwiseDetails H1
        where H1.id<=H2.id and Rowindicator='D' 
       ) as CumActual,
       (select sum(H1.Target) from #HourwiseDetails H1
        where H1.id<=H2.id and Rowindicator='D' 
       ) as CumTarget
from #HourwiseDetails H2 where Target>0 and Rowindicator='D' 
group by H2.id,H2.startdate,H2.shiftname,H2.hourstart,H2.projectcode
)T1 inner join #HourwiseDetails on #HourwiseDetails.HourStart=T1.HourStart
and #HourwiseDetails.ProjectCode=T1.ProjectCode and #HourwiseDetails.Rowindicator='D'



update #HourwiseDetails set Loss2 = [dbo].[f_FormatTime](Loss2,'mm') where Loss2 IS NOT NULL and Rowindicator='Summary' 
update #HourwiseDetails set Loss3 = [dbo].[f_FormatTime](Loss3,'mm') where Loss3 IS NOT NULL and Rowindicator='Summary' 
update #HourwiseDetails set Loss4 = [dbo].[f_FormatTime](Loss4,'mm') where Loss4 IS NOT NULL and Rowindicator='Summary' 
update #HourwiseDetails set Loss5 = [dbo].[f_FormatTime](Loss5,'mm') where Loss5 IS NOT NULL and Rowindicator='Summary' 
update #HourwiseDetails set Loss6 = [dbo].[f_FormatTime](Loss6,'mm') where Loss6 IS NOT NULL and Rowindicator='Summary' 
update #HourwiseDetails set Loss7 = [dbo].[f_FormatTime](Loss7,'mm') where Loss7 IS NOT NULL and Rowindicator='Summary' 



--SV From here
--select Shiftname,HourTimeDisplay,ProjectCode,Target,Actual,Loss1,Round([dbo].[f_FormatTime](Loss2,'mm'),2) as Loss2,Round([dbo].[f_FormatTime](Loss3,'mm'),2) as Loss3,
--Round([dbo].[f_FormatTime](Loss4,'mm'),2) as Loss4,Round([dbo].[f_FormatTime](Loss5,'mm'),2) as Loss5,Round([dbo].[f_FormatTime](Loss6,'mm'),2) as Loss6,
--Round([dbo].[f_FormatTime](Loss7,'mm'),2) as Loss7,RejTarget,RejActual,RejReason,Operator from #HourwiseDetails
--Where Rowindicator='D' or Rowindicator='Summary'



select Shiftname,HourTimeDisplay,ProjectCode,Target,Actual,Loss1,Loss2,Loss3,
Loss4,Loss5,Loss6,Loss7,RejTarget,RejActual,RejReason,Operator,PE from #HourwiseDetails
Where Rowindicator='D' or Rowindicator='Summary'
--SV Till Here

return

END
