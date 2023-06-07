/****** Object:  Procedure [dbo].[S_Get_HourWiseOperatorIncentiveReport]    Committed by VersionSQL https://www.versionsql.com ******/

/*
Created by Raksha R on 13-jan-2022

exec [dbo].[S_Get_HourWiseOperatorIncentiveReport] '2022-01-01 07:30:00.000','2022-01-02 07:30:00.000','Satish 2'
exec [dbo].[S_Get_HourWiseOperatorIncentiveReport] '2022-01-01 07:30:00.000','2022-01-02 07:30:00.000',''
exec [dbo].[S_Get_HourWiseOperatorIncentiveReport] @StartTime=N'2022-02-01 07:30:00',@EndTime=N'2022-02-26 19:30:00',@OperatorID=N'AMIT YADAV'
*/
CREATE procedure [dbo].[S_Get_HourWiseOperatorIncentiveReport]
@StartTime datetime='',
@EndTime datetime='',
@OperatorID nvarchar(150)=''

AS
BEGIN

Declare @StrOperatorID nvarchar(200)
select @StrOperatorID=''

if isnull(@OperatorID,'') <> ''  
Begin  
 Select @StrOperatorID = ' and ( EI.employeeid = N''' + @OperatorID + ''')'  
End  

--Declare @MinHourlyIncentive float
--Declare @MaxHourlyIncentive float

Declare @ShiftIncentiveInRs float
Declare @ShiftTarget float
Declare @HourlyIncentive float

--select @MinHourlyIncentive = ValueInInt from ShopDefaults where Parameter='OperatorIncentiveReport' and ValueInText='MinHourlyIncentive'
--select @MaxHourlyIncentive = ValueInInt from ShopDefaults where Parameter='OperatorIncentiveReport' and ValueInText='MaxHourlyIncentive'
select @ShiftIncentiveInRs = ValueInInt from ShopDefaults where Parameter='OperatorIncentiveReport' and ValueInText='ShiftIncentiveInRs'
select @ShiftTarget  = ValueInInt from ShopDefaults where Parameter='OperatorIncentiveReport' and ValueInText='ShiftTarget'
Select @HourlyIncentive = isnull(ValueInInt,0) from ShopDefaults where Parameter='OperatorIncentiveReport' and ValueInText='HourlyIncentive'

Create table #Temp
(
	ShiftDate datetime,
	ShiftName nvarchar(50),
	ShiftID int,
	ShiftStart datetime,
	ShiftEnd datetime,
	HourStart datetime,
	HourEnd datetime,
	HourID int,
	HourName nvarchar(50),
	MachineID nvarchar(50),
	MachineInt nvarchar(50),
	MachineDescription nvarchar(250),
	ComponentID nvarchar(50),
	ComponentInt nvarchar(50),
	OperationNo nvarchar(50),
	OperationInt int,
	OperatorID nvarchar(50),
	OperatorInt nvarchar(50),
	AvgCycleTime float default 0,
	AvgLoadUnload float default 0,
	RunTime float default 0,
	HourlyTarget float default 0,
	HourValue float default 0,
	HourlyIncentive float default 0,
	IncentiveRupess float,
	HourlyTotalIncentive float,
	ShiftTarget float,
	ShiftProducedQty float,
	ShiftIncentiveTotal float
)

Create table #MasterTemp
(
	MachineID nvarchar(50),
	MachineInt nvarchar(50),
	MachineDescription nvarchar(250),
	ComponentID nvarchar(50),
	ComponentInt nvarchar(50),
	OperationNo nvarchar(50),
	OperationInt int,
	OperatorID nvarchar(50),
	OperatorInt nvarchar(50),
	stdTime float,
	SubOperations int
)

--SV Added from here
Create table #finalTemp
(
	ShiftDate datetime,
	ShiftName nvarchar(50),
	ShiftID int,
	ShiftStart datetime,
	ShiftEnd datetime,
	HourStart datetime,
	HourEnd datetime,
	HourID int,
	HourName nvarchar(50),
	MachineID nvarchar(50),
	MachineInt nvarchar(50),
	MachineDescription nvarchar(250),
	OperatorID nvarchar(50),
	OperatorInt nvarchar(50),
	AvgCycleTime float default 0,
	AvgLoadUnload float default 0,
	RunTime float default 0,
	HourlyTarget float default 0,
	HourValue float default 0,
	HourlyIncentive float default 0,
	IncentiveRupess float,
	HourlyTotalIncentive float,
	ShiftTarget float,
	ShiftProducedQty float,
	ShiftIncentiveTotal float
)
--SV Added till here


CREATE TABLE #ShiftDetails   
(  
 SlNo bigint identity(1,1) NOT NULL,
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime  ,
 ShiftID int
) 

CREATE TABLE #RunTime    
(  
  
MachineID nvarchar(50) NOT NULL,  
machineinterface nvarchar(50),  
Compinterface nvarchar(50),  
OpnInterface nvarchar(50), 
Component nvarchar(50) NOT NULL,  
Operation nvarchar(50) NOT NULL,  
OperatorID nvarchar(50) ,
OperatorInt nvarchar(50) ,
FromTm datetime,  
ToTm datetime,     
msttime datetime,  
ndtime datetime,  
batchid int,  
autodataid bigint ,
stdTime float,
SubOperations int
)  

CREATE TABLE #FinalRunTime  
(  
	
	MachineID nvarchar(50) NOT NULL,  
	machineinterface nvarchar(50),  
	Component nvarchar(50) NOT NULL,  
	Compinterface nvarchar(50),  
	Operation nvarchar(50) NOT NULL,  
	OpnInterface nvarchar(50),  
	OperatorID nvarchar(50) ,
	OperatorInt nvarchar(50) ,
	FromTm datetime,  
	ToTm datetime,     
	BatchStart datetime,  
	BatchEnd datetime,  
	batchid int,  
	stdTime float,
	Target int default 0,
	Actual int default 0,
	Runtime float default 0,
	SubOperations int,
)  


CREATE TABLE #T_autodata(
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] not NULL,
	[datatype] [tinyint] NULL ,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] not NULL,
	[PartsCount] decimal(18,5) NULL ,
	id  bigint not null
)

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime,ndtime,msttime ASC
)ON [PRIMARY]

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 

Declare @strSql as nvarchar(4000)

--Select @T_ST=dbo.f_GetLogicalDaystart(dateadd(SECOND,1,@StartTime))
--Select @T_ED=dbo.f_GetLogicalDayend(dateadd(second,1,@EndTime))

Select @T_ST=@StartTime
Select @T_ED=@EndTime


Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)

Declare @T_ST1 AS Datetime 
Declare @T_ED1 AS Datetime 

select @T_ST1=@StartTime
select @T_ED1=@EndTime

while @T_ST1<=@T_ED1
begin
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)   
	EXEC s_GetShiftTime @T_ST1,''  
	SELECT @T_ST1=DATEADD(DAY,1,@T_ST1)
end

update #ShiftDetails set Shiftid=T.Shiftid from
(select * from shiftdetails where Running=1)T 
inner join #ShiftDetails on #ShiftDetails.Shift=T.Shiftname

Create table #HourData
(
	Mdate datetime,
	ShiftStart datetime,
	ShiftEnd datetime,
	ShiftName nvarchar(50),
	ShiftID int,
	HourStart datetime,
	HourEnd datetime,
	HourID int,
	HourName nvarchar(50)
)

Insert into #HourData(Mdate,ShiftStart,ShiftEnd,ShiftName,ShiftID,HourStart,HourEnd,HourID,HourName)
Select distinct T1.Pdate,T1.ShiftStart,T1.ShiftEnd,T1.Shift,T1.ShiftID,
 case when fromday = 0 then cast((cast(datepart(yyyy,Pdate) as nvarchar(20))+'-'+cast(datepart(m,Pdate) as nvarchar(20))+'-'+cast(datepart(dd,Pdate) as nvarchar(20))+' '+cast(datepart(hh,hourStart) as nvarchar(20))+':'+cast(datepart(n,hourStart) as nvarchar(20))+':'+cast(datepart(s,hourStart) as nvarchar(20))) as DateTime)      
    when fromday = 1 then cast((cast(datepart(yyyy,Pdate) as nvarchar(20))+'-'+cast(datepart(m,Pdate) as nvarchar(20))+'-'+cast(datepart(dd,Pdate) as nvarchar(20))+' '+cast(datepart(hh,hourStart) as nvarchar(20))+':'+cast(datepart(n,hourStart) as nvarchar(20))+':'+cast(datepart(s,hourStart) as nvarchar(20))) as DateTime)+1      
  end as FromTime,      
  case when today = 0 then cast((cast(datepart(yyyy,Pdate) as nvarchar(20))+'-'+cast(datepart(m,Pdate) as nvarchar(20))+'-'+cast(datepart(dd,Pdate) as nvarchar(20))+' '+cast(datepart(hh,hourEnd) as nvarchar(20))+':'+cast(datepart(n,hourEnd) as nvarchar(20))+':'+cast(datepart(s,hourEnd) as nvarchar(20))) as DateTime)      
    when today = 1 then cast((cast(datepart(yyyy,Pdate) as nvarchar(20))+'-'+cast(datepart(m,Pdate) as nvarchar(20))+'-'+cast(datepart(dd,Pdate) as nvarchar(20))+' '+cast(datepart(hh,hourEnd) as nvarchar(20))+':'+cast(datepart(n,hourEnd) as nvarchar(20))+':'+cast(datepart(s,hourEnd) as nvarchar(20))) as DateTime)+1      
  end as ToTime,HourID,HourName
from #ShiftDetails T1
inner join ShiftHourDefinition T2 on  T1.ShiftID=T2.ShiftID

Set @strSql=''
Set @strSql = '
insert into #Temp(ShiftDate,ShiftName,ShiftID,ShiftStart,ShiftEnd,HourID,HourName,HourStart,HourEnd,MachineID,MachineInt,MachineDescription,ComponentID,ComponentInt,OperationNo,OperationInt,OperatorID,OperatorInt)
select distinct H.Mdate,H.ShiftName,H.ShiftID,H.ShiftStart,H.ShiftEnd,H.HourID,H.HourName,H.HourStart,H.HourEnd,machineinformation.machineid,machineinformation.InterfaceID,machineinformation.Description,componentinformation.componentid,componentinformation.InterfaceID,
componentoperationpricing.operationno,componentoperationpricing.InterfaceID,Ei.employeeid,EI.interfaceid from #T_autodata autodata
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr 
Cross Join #HourData H 
where 1=1 '
Set @strSql = @strSql + @StrOperatorID
print @strsql
exec (@strsql)


Set @strSql=''
Set @strSql = '
insert into #MasterTemp(MachineID,MachineInt,MachineDescription,ComponentID,ComponentInt,OperationNo,OperationInt,OperatorID,OperatorInt,stdTime,SubOperations)
select distinct machineinformation.machineid,machineinformation.InterfaceID,machineinformation.Description,componentinformation.componentid,componentinformation.InterfaceID,
componentoperationpricing.operationno,componentoperationpricing.InterfaceID,Ei.employeeid,EI.interfaceid,componentoperationpricing.Cycletime,componentoperationpricing.SubOperations from (select distinct mc,comp,opn,opr from #T_autodata) autodata
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr 
where 1=1 '
--Set @strSql = @strSql + @StrOperatorID
print @strsql
exec (@strsql)

--UPDATE #Temp SET HourValue = ISNULL(T2.HourValue,0) + ISNULL(t1.val,0)
--From
--(
--	Select A.mc,A.comp,A.opn,A.opr,T.HourStart,T.HourEnd,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As val
--	from #T_autodata A
--	Inner join machineinformation M on M.interfaceid=A.mc
--	Inner join componentinformation C ON A.Comp=C.interfaceid
--	Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
--	cross join #HourData T 
--	WHERE  A.DataType=1 
--	AND(A.ndtime > T.HourStart  AND A.ndtime <=T.HourEnd)
--	Group by  A.mc,A.comp,A.opn,A.opr,T.HourStart,T.HourEnd
--) As T1 Inner join #Temp T2 on T1.mc=T2.MachineInt and T1.comp=T2.ComponentInt and T1.opn=T2.OperationInt and T1.opr=T2.OperatorInt and T1.HourStart=T2.HourStart and T1.HourEnd=T2.HourEnd

UPDATE #Temp SET HourValue = ISNULL(HourValue,0) + ISNULL(t2.val,0)
From
(
	  Select mc,comp,opn,opr,HourStart,HourEnd ,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As val 
		   From (select mc,comp,opn,opr,HourStart,HourEnd ,SUM(autodata.partscount)AS OrginalCount
			from #T_autodata autodata --ER0374
			inner join #Temp T1 on autodata.mc = T1.MachineInt and autodata.comp=T1.ComponentInt and autodata.opn=T1.OperationInt and autodata.opr=T1.OperatorInt
		   where (autodata.ndtime>HourStart) and (autodata.ndtime<=HourEnd) and (autodata.datatype=1)
		   Group By mc,comp,opn,opr,HourStart,HourEnd ) as T1
	Inner join componentinformation C on T1.Comp = C.interfaceid
	Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
	inner join machineinformation on machineinformation.machineid =O.machineid
	and T1.mc=machineinformation.interfaceid
	GROUP BY mc,comp,opn,opr,HourStart,HourEnd 
) as T2 inner join #Temp on T2.mc = #Temp.MachineInt and T2.comp=#Temp.ComponentInt and T2.opn=#Temp.OperationInt and T2.opr=#Temp.OperatorInt
	and T2.HourStart=#Temp.HourStart and T2.HourEnd=#Temp.HourEnd


--Mod 4 Apply PDT for calculation of Count
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #Temp SET HourValue = ISNULL(HourValue,0) - ISNULL(T2.val,0) from(
		select mc,comp,opn,opr,HourStart,HourEnd ,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as val From ( 
			select mc,comp,opn,opr,HourStart,HourEnd ,Sum(ISNULL(PartsCount,1))AS OrginalCount
			from #T_autodata autodata 
			inner join #Temp T1 on autodata.mc = T1.MachineInt and autodata.comp=T1.ComponentInt and autodata.opn=T1.OperationInt and autodata.opr=T1.OperatorInt
			inner JOIN PlannedDownTimes T on T.Machine=T1.MachineID
			WHERE autodata.DataType=1 And T.Machine = T1.MachineID
			AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
			AND (autodata.ndtime > HourStart  AND autodata.ndtime <=HourEnd)
		    Group by mc,comp,opn,opr,HourStart,HourEnd
		) as T1
	Inner join Machineinformation M on M.interfaceID = T1.mc
	Inner join componentinformation C on T1.Comp=C.interfaceid
	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
	GROUP BY MC,comp,opn,opr,HourStart,HourEnd 
	) as T2 inner join #Temp on T2.mc = #Temp.MachineInt and T2.comp=#Temp.ComponentInt and T2.opn=#Temp.OperationInt and T2.opr=#Temp.OperatorInt
	and T2.HourStart=#Temp.HourStart and T2.HourEnd=#Temp.HourEnd
END

UPDATE #Temp SET ShiftProducedQty=T1.ShiftProducedQty
From(
select MachineInt,ComponentInt,OperationInt,OperatorInt,ShiftStart,ShiftEnd,Sum(isnull(HourValue,0)) as ShiftProducedQty from #Temp
group by MachineInt,ComponentInt,OperationInt,OperatorInt,ShiftStart,ShiftEnd
)As T1 Inner join #Temp T2 on T1.MachineInt=T2.MachineInt and T1.ComponentInt=T2.ComponentInt and T1.OperationInt=T2.OperationInt and T1.OperatorInt=T2.OperatorInt and T1.ShiftStart=T2.ShiftStart and T1.ShiftEnd=T2.ShiftEnd


----------------------- Avg cycle time calculaion -----------------------------------------------------------------------------------------------------------------------------------------------------------------



--Update #Temp Set AvgCycleTime=T1.AvgCycleTime, AvgLoadUnload=T1.AvgLoadUnload
--From(
--	select A1.mc,A1.comp,A1.opn,A1.opr,A2.ShiftStart,A2.ShiftEnd,sum(isnull(A1.cycletime,0)) as AvgCycleTime, Sum(isnull(A1.loadunload,0)) as AvgLoadUnload from #T_autodata A1
--	inner join #Temp A2 on A1.mc=A2.MachineInt and A1.comp=A2.ComponentInt and A1.opn=A2.OperationInt and A1.opr=A2.OperatorInt
--	and (( sttime >= A2.ShiftStart and ndtime <= A2.ShiftEnd ) OR 
--	( sttime < A2.ShiftStart and ndtime > A2.ShiftStart and ndtime<=A2.ShiftEnd ))
--	where A1.datatype=1
--	group by A1.mc,A1.comp,A1.opn,A1.opr,A2.ShiftStart,A2.ShiftEnd,A1.loadunload
--)T1 inner join #Temp T2 on T1.mc=T2.MachineInt and T1.comp=T2.ComponentInt and T1.opn=T2.OperationInt and T1.opr=T2.OperatorInt AND T1.ShiftStart=T2.ShiftStart AND T1.ShiftEnd=T2.ShiftEnd

--Update #Temp Set AvgCycleTime=T1.AvgCycleTime, AvgLoadUnload=T1.AvgLoadUnload
--From(
--select  autodata.mc,machineinformation.machineid,componentinformation.componentid,autodata.comp,autodata.opn,autodata.opr,A2.ShiftStart,A2.ShiftEnd,sum(isnull(autodata.cycletime,0)) as AvgCycleTime, Sum(isnull(autodata.loadunload,0)) as AvgLoadUnload from #T_autodata autodata
--inner join #Temp A3 on autodata.mc=A3.MachineInt and autodata.comp=A3.ComponentInt and autodata.opn=A3.OperationInt and autodata.opr=A3.OperatorInt
--INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN 
--componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN 
--componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)
--and componentoperationpricing.machineid=machineinformation.machineid 
--AND (componentinformation.componentid = componentoperationpricing.componentid) 
--Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
--LEFT JOIN PlantMachineGroups on machineinformation.machineid = PlantMachineGroups.machineid
--cross join  #ShiftDetails A2
--where machineinformation.interfaceid > '0'
--and (( sttime >= A2.shiftstart and ndtime <= A2.shiftend ) OR 
--( sttime < A2.shiftstart and ndtime > A2.shiftstart and ndtime<=A2.shiftend ))
--and autodata.datatype=1 
--AND (autodata.partscount > 0 ) 
--group by autodata.mc,machineinformation.machineid,componentinformation.componentid,autodata.comp,autodata.opn,autodata.opr,A2.ShiftStart,A2.ShiftEnd
--)T1 inner join #Temp T2 on T1.mc=T2.MachineInt and T1.comp=T2.ComponentInt and T1.opn=T2.OperationInt and T1.opr=T2.OperatorInt AND T1.ShiftStart=T2.ShiftStart AND T1.ShiftEnd=T2.ShiftEnd


Update #Temp Set AvgCycleTime=T1.AvgCycleTime, AvgLoadUnload=T1.AvgLoadUnload
From(
select  autodata.mc,A3.machineid,A3.componentid,autodata.comp,autodata.opn,autodata.opr,A2.ShiftStart,A2.ShiftEnd,sum(isnull(autodata.cycletime,0)) as AvgCycleTime, Sum(isnull(autodata.loadunload,0)) as AvgLoadUnload from #T_autodata autodata
inner join #MasterTemp A3 on autodata.mc=A3.MachineInt and autodata.comp=A3.ComponentInt and autodata.opn=A3.OperationInt and autodata.opr=A3.OperatorInt
cross join  #ShiftDetails A2
where (( sttime >= A2.shiftstart and ndtime <= A2.shiftend ) OR 
( sttime < A2.shiftstart and ndtime > A2.shiftstart and ndtime<=A2.shiftend ))
and autodata.datatype=1 
AND (autodata.partscount > 0 ) 
group by autodata.mc,A3.machineid,A3.componentid,autodata.comp,autodata.opn,autodata.opr,A2.ShiftStart,A2.ShiftEnd
)T1 inner join #Temp T2 on T1.mc=T2.MachineInt and T1.comp=T2.ComponentInt and T1.opn=T2.OperationInt and T1.opr=T2.OperatorInt AND T1.ShiftStart=T2.ShiftStart AND T1.ShiftEnd=T2.ShiftEnd


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' 
and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' 
BEGIN
	UPDATE #Temp set AvgCycleTime =isnull(AvgCycleTime,0) - isNull(TT.PPDT ,0),
	AVGLoadUnload = isnull(AVGLoadUnload,0) - isnull(LD,0)
	FROM(
		--Production Time in PDT
	Select A.mc,A.comp,A.Opn,A.opr,A.ShiftStart,A.ShiftEnd,Sum
			(CASE
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.sttime,A.ndtime) --DR0325 Added
			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT,
			sum(case
			WHEN A.msttime >= T.StartTime  AND A.sttime <=T.EndTime  THEN DateDiff(second,A.msttime,A.sttime)
			WHEN ( A.msttime < T.StartTime  AND A.sttime <= T.EndTime  AND A.sttime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.sttime)
			WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.sttime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
			WHEN ( A.msttime < T.StartTime  AND A.sttime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as LD
			From
			
			(
				SELECT distinct M.MachineID,
				autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime,autodata.msttime
				,autodata.Cycletime,M.ShiftStart,M.ShiftEnd,autodata.opr
				from #T_autodata autodata --ER0324 Added
				inner join #Temp M on M.machineint=Autodata.mc
				and autodata.comp=M.ComponentInt and autodata.Opn=M.OperationInt and autodata.opr=M.OperatorInt
				where autodata.DataType=1 And autodata.ndtime >M.ShiftStart  AND autodata.ndtime <=M.ShiftEnd
			)A
			CROSS jOIN PlannedDownTimes T 
			WHERE T.Machine=A.MachineID AND
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )	
		group by A.mc,A.comp,A.Opn,A.opr,A.ShiftStart,A.ShiftEnd
	)
	as TT INNER JOIN #Temp ON TT.mc = #Temp.MachineInt
		and TT.comp = #Temp.ComponentInt
			and TT.opn = #Temp.OperationInt and TT.opr=#Temp.OperatorInt and TT.ShiftStart=#Temp.ShiftStart
						and TT.ShiftEnd= #Temp.ShiftEnd

	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #Temp set AvgCycleTime =isnull(AvgCycleTime,0) + isNull(T2.IPDT ,0) 	FROM	
		(
		Select AutoData.mc,autodata.comp,autodata.Opn,autodata.opr,T1.ShiftStart,T1.ShiftEnd,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join --ER0324 Added
			(Select distinct machineID,mc,Sttime,NdTime,M.ShiftStart,M.ShiftEnd from #T_autodata autodata
				inner join #Temp M on M.machineint=Autodata.mc
				and autodata.comp=M.ComponentInt and autodata.Opn=M.OperationInt and autodata.opr=M.OperatorInt
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(ndtime > M.ShiftStart) AND (ndtime <= M.ShiftEnd)) as T1
		ON AutoData.mc=T1.mc 
		CROSS jOIN PlannedDownTimes T 
		Where AutoData.DataType=2 And T.Machine=T1.MachineID
		And (( autodata.Sttime >= T1.Sttime ) --DR0339
		And ( autodata.ndtime <= T1.ndtime ) --DR0339
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )))
		GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn,autodata.opr,T1.ShiftStart,T1.ShiftEnd
		)AS T2  INNER JOIN #Temp ON T2.mc = #Temp.MachineInt
				and T2.comp = #Temp.ComponentInt
			and T2.opn = #Temp.OperationInt and T2.opr=#Temp.OperatorInt and T2.ShiftStart=#Temp.ShiftStart
						and T2.ShiftEnd= #Temp.ShiftEnd
	
End


Update #Temp set avgCycletime=(isnull(avgCycletime,0)/isnull(ShiftProducedQty,1))* isnull(suboperations,1) 
,avgloadunload=(isnull(avgloadunload,0)/isnull(ShiftProducedQty,1))* isnull(suboperations,1)
from #Temp
inner join componentoperationpricing C on #Temp.MachineID=C.MachineID and #Temp.ComponentID=C.Componentid and
#Temp.OperationNo = c.Operationno 
where ShiftProducedQty>0



----------------------- Avg cycle time calculaion -----------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------- RunTime calculaion -----------------------------------------------------------------------------------------------------------------------------------------------------------------

		--Select @strsql=''   
		--Select @strsql= 'insert into #RunTime(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface, OperatorID,  OperatorInt,
		--msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,SubOperations)'  
		--select @strsql = @strsql + ' SELECT  machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
		--componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.EmployeeID,autodata.opr,
		--Case when autodata.msttime<  T.Shiftstart then T.Shiftstart else autodata.msttime end,   
		--Case when autodata.ndtime> T.Shiftend  then T.Shiftend else autodata.ndtime end,     
		--T.Shiftstart,T.Shiftend,0,autodata.id,componentoperationpricing.Cycletime,componentoperationpricing.SubOperations FROM #T_autodata autodata  with(nolock)
		--INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
		--INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
		--INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
		--AND componentinformation.componentid = componentoperationpricing.componentid  
		--and componentoperationpricing.machineid=machineinformation.machineid   
		--inner Join Employeeinformation EI on EI.interfaceid=autodata.opr 
		--cross join(select distinct Shiftstart,Shiftend from #ShiftDetails) as T
		--WHERE ((autodata.ndtime > T.Shiftstart and autodata.ndtime <=T.Shiftend) 
		--	OR ( autodata.msttime >= T.Shiftstart  AND autodata.msttime <T.Shiftend AND autodata.ndtime > T.Shiftend ) --SV Added 
		--	OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime > T.Shiftend) )'  --SV Added 

		----WHERE ((autodata.msttime>=T.Shiftstart  and  autodata.ndtime<=T.Shiftend ) 
		----	OR ( autodata.sttime<T.Shiftstart  and  autodata.ndtime>T.Shiftstart  and autodata.ndtime<=T.Shiftend ) --SV Added 
		----	or (autodata.msttime>=T.Shiftstart  and autodata.sttime<T.Shiftend  and autodata.ndtime>T.Shiftend)
		----	OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime > T.Shiftend) )'  --SV Added 

		----select @strsql = @strsql + @StrOperatorID
		--select @strsql = @strsql + ' order by autodata.msttime'  
		--print @strsql  
		--exec (@strsql)
		
		
		Select @strsql=''   
		Select @strsql= 'insert into #RunTime(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface, OperatorID,  OperatorInt,
		msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,SubOperations)'  
		select @strsql = @strsql + ' SELECT  A3.machineid, autodata.mc,A3.componentid, autodata.comp,  
		A3.operationno, autodata.opn,A3.OperatorID,autodata.opr,
		Case when autodata.msttime<  T.Shiftstart then T.Shiftstart else autodata.msttime end,   
		Case when autodata.ndtime> T.Shiftend  then T.Shiftend else autodata.ndtime end,     
		T.Shiftstart,T.Shiftend,0,autodata.id,A3.stdTime,A3.SubOperations FROM #T_autodata autodata  with(nolock)
		inner join #MasterTemp A3 on autodata.mc=A3.MachineInt and autodata.comp=A3.ComponentInt and autodata.opn=A3.OperationInt and autodata.opr=A3.OperatorInt
		cross join(select distinct Shiftstart,Shiftend from #ShiftDetails) as T
		WHERE ((autodata.ndtime > T.Shiftstart and autodata.ndtime <=T.Shiftend) 
			OR ( autodata.msttime >= T.Shiftstart  AND autodata.msttime <T.Shiftend AND autodata.ndtime > T.Shiftend ) --SV Added 
			OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime > T.Shiftend) )'  --SV Added 

		--WHERE ((autodata.msttime>=T.Shiftstart  and  autodata.ndtime<=T.Shiftend ) 
		--	OR ( autodata.sttime<T.Shiftstart  and  autodata.ndtime>T.Shiftstart  and autodata.ndtime<=T.Shiftend ) --SV Added 
		--	or (autodata.msttime>=T.Shiftstart  and autodata.sttime<T.Shiftend  and autodata.ndtime>T.Shiftend)
		--	OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime > T.Shiftend) )'  --SV Added 

		--select @strsql = @strsql + @StrOperatorID
		select @strsql = @strsql + ' order by autodata.msttime'  
		print @strsql  
		exec (@strsql)

		insert into #FinalRunTime(MachineID,Component,operation,machineinterface,Compinterface,Opninterface,OperatorID,OperatorInt,batchid,BatchStart,BatchEnd,FromTm,ToTm,stdtime,Actual,Target,Runtime,SubOperations) 
		select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,OperatorID,OperatorInt,batchid,min(msttime),max(ndtime),FromTm,ToTm,stdtime,0,0,0,SubOperations
		from
		(
		select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,msttime,ndtime,FromTm,ToTm,stdtime,SubOperations,OperatorID,OperatorInt,
		RANK() OVER (
		PARTITION BY t.machineid
		order by t.machineid, t.msttime
		) -
		RANK() OVER (
		PARTITION BY  t.machineid, t.component, t.operation,t.OperatorID,t.fromtm 
		order by t.machineid, t.fromtm, t.msttime
		) AS batchid
		from #RunTime t 
		) tt
		group by MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,FromTm,ToTm,stdtime,SubOperations,OperatorID,OperatorInt
		order by tt.batchid

		Update #FinalRunTime Set BatchEnd=T1.BE
		From(
			Select A1.machineinterface,A1.FromTm,A2.BatchStart,(Case when A2.BatchEnd<A1.ToTm Then A1.ToTm else A2.BatchEnd end) as BE from #FinalRunTime A1
			inner join (select machineinterface,Convert(nvarchar(10),FromTm,120) as Date1,FromTm,Max(BatchStart) as BatchStart,Max(BatchEnd) as BatchEnd from #FinalRunTime
			group by machineinterface,Convert(nvarchar(10),FromTm,120),FromTm) A2
			on A1.machineinterface=A2.machineinterface and Convert(nvarchar(10),A1.FromTm,120)=Convert(nvarchar(10),A2.Date1,120) and A1.FromTm=A2.FromTm and A1.BatchStart=A2.BatchStart
		)T1 inner join #FinalRunTime T2 on T1.machineinterface=T2.machineinterface and T1.FromTm=T2.FromTm and T1.BatchStart=T2.BatchStart

		Update #FinalRunTime Set BatchStart=T1.BS
		From(
			Select A1.machineinterface,A1.FromTm,A2.BatchStart,(Case when A1.FromTm<A2.BatchStart Then A1.FromTm else A2.BatchStart end) as BS from #FinalRunTime A1
			inner join (select machineinterface,Convert(nvarchar(10),FromTm,120) as Date1,FromTm,min(BatchStart) as BatchStart,Min(BatchEnd) as BatchEnd from #FinalRunTime
			group by machineinterface,Convert(nvarchar(10),FromTm,120),FromTm) A2
			on A1.machineinterface=A2.machineinterface and Convert(nvarchar(10),A1.FromTm,120)=Convert(nvarchar(10),A2.Date1,120) and A1.FromTm=A2.FromTm and A1.BatchStart=A2.BatchStart
		)T1 inner join #FinalRunTime T2 on T1.machineinterface=T2.machineinterface and T1.FromTm=T2.FromTm and T1.BatchStart=T2.BatchStart

		update #FinalRunTime set Runtime=datediff(s,BatchStart,BatchEnd)


		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N'
		BEGIN

			Update #FinalRunTime set Runtime=Isnull(Runtime,0) - Isnull(T3.pdt,0) 
			from (
			Select t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm,T2.ToTm,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt
			from
				(
				Select T1.machineinterface,T1.Compinterface,T1.Opninterface,T1.BatchStart,T1.BatchEnd,T1.FromTm,ToTm,Pdt.machine,
				Case when  T1.BatchStart <= pdt.StartTime then pdt.StartTime else T1.BatchStart End as StartTimepdt,
				Case when  T1.BatchEnd >= pdt.EndTime then pdt.EndTime else T1.BatchEnd End as EndTimepdt
				from #FinalRunTime T1
				inner join Planneddowntimes pdt on t1.machineid=Pdt.machine
				where PDTstatus = 1  and
				((pdt.StartTime >= t1.BatchStart and pdt.EndTime <= t1.BatchEnd)or
				(pdt.StartTime < t1.BatchStart and pdt.EndTime > t1.BatchStart and pdt.EndTime <=t1.BatchEnd)or
				(pdt.StartTime >= t1.BatchStart and pdt.StartTime <t1.BatchEnd and pdt.EndTime >t1.BatchEnd) or
				(pdt.StartTime <  t1.BatchStart and pdt.EndTime >t1.BatchEnd))
				)T2 group by  t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm,T2.ToTm
			) T3 inner join #FinalRunTime T on T.machineinterface=T3.machineinterface and T.BatchStart=T3.BatchStart and  T.BatchEnd=T3.BatchEnd and T.Fromtm=T3.Fromtm and T.ToTm=T3.ToTm

		ENd


Update #Temp set RunTime=T1.totalRuntime
From(
	select machineinterface,Compinterface,OpnInterface,OperatorInt,FromTm,ToTm,sum(isnull(Runtime,0)) as totalRuntime from #FinalRunTime
	group by machineinterface,Compinterface,OpnInterface,OperatorInt,FromTm,ToTm
)T1 inner join #Temp T2 on T1.machineinterface=T2.MachineInt and T1.Compinterface=T2.ComponentInt and T1.OpnInterface=T2.OperationInt and T1.OperatorInt=T2.OperatorInt and T1.FromTm=T2.ShiftStart and T1.ToTm=T2.ShiftEnd


----------------------- RunTime calculaion -----------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------/* HourlyTarget = RunTime/AvgCycleTime */-----------

--Update #Temp Set HourlyTarget= isnull(RunTime,0)/isnull(AvgCycleTime,0) where isnull(AvgCycleTime,0)<>0 --SV commented

-----------/* ShiftTarget =	(HourlyTarget*ShiftTarget) where ShiftTarget is defined in ShopDefaults	*/-----------

--Update #Temp Set ShiftTarget = isnull(HourlyTarget,0) * isnull(@ShiftTarget,0) --SV commented

-----------/* HourlyIncentive =	HourlyTarget * (HourlyIncentive/100) where HourlyIncentive is defined in ShopDefaults	*/-----------

--update #Temp set HourlyIncentive = HourlyTarget * (@HourlyIncentive/100) --SV commented

--UPDATE #Temp SET IncentiveRupess = T1.IncentiveRupess
--From(
--select MachineInt,ComponentInt,OperationInt,OperatorInt,HourStart,HourEnd,HourValue,
--(Case when ((isnull(HourValue,0) between @MinHourlyIncentive and @MaxHourlyIncentive) or (isnull(HourValue,0) >@MaxHourlyIncentive)) Then 10 else 0 end) as IncentiveRupess from #Temp
--)As T1 Inner join #Temp T2 on T1.MachineInt=T2.MachineInt and T1.ComponentInt=T2.ComponentInt and T1.OperationInt=T2.OperationInt and T1.OperatorInt=T2.OperatorInt and T1.HourStart=T2.HourStart and T1.HourEnd=T2.HourEnd


-----------/* If production count for each hour is >= calculated HourlyIncentive then IncentiveRupess= 10 rs Else 0Rs 	*/-----------

--SV Commented from here
--UPDATE #Temp SET IncentiveRupess = T1.IncentiveRupess
--From(
--select MachineInt,ComponentInt,OperationInt,OperatorInt,HourStart,HourEnd,HourValue,
--(Case when (isnull(HourValue,0) >= HourlyIncentive) Then 10 
--	when HourValue=0 and HourlyTarget=0 then 0
--when (isnull(HourValue,0) < HourlyIncentive) Then 0 
--else 0 end) as IncentiveRupess from #Temp
--)As T1 Inner join #Temp T2 on T1.MachineInt=T2.MachineInt and T1.ComponentInt=T2.ComponentInt and T1.OperationInt=T2.OperationInt and T1.OperatorInt=T2.OperatorInt and T1.HourStart=T2.HourStart and T1.HourEnd=T2.HourEnd

--UPDATE #Temp SET HourlyTotalIncentive = T1.HourlyTotalIncentive
--From(
--select MachineInt,ComponentInt,OperationInt,OperatorInt,ShiftStart,ShiftEnd,sum(isnull(IncentiveRupess,0)) as HourlyTotalIncentive from #Temp
--group by MachineInt,ComponentInt,OperationInt,OperatorInt,ShiftStart,ShiftEnd
--)As T1 Inner join #Temp T2 on T1.MachineInt=T2.MachineInt and T1.ComponentInt=T2.ComponentInt and T1.OperationInt=T2.OperationInt and T1.OperatorInt=T2.OperatorInt and T1.ShiftStart=T2.ShiftStart and T1.ShiftEnd=T2.ShiftEnd


--Update #Temp Set ShiftIncentiveTotal=@ShiftIncentiveInRs

--Update #Temp set HourlyTotalIncentive=0 where ShiftProducedQty>=ShiftTarget

--Update #Temp set ShiftIncentiveTotal=0 where ShiftProducedQty<ShiftTarget
--SV Commented till here

--SV Commented & Added  below to keep Shiftwise one row
--select distinct HourStart,HourEnd,ShiftDate,ShiftID,ShiftName,HourID,HourName,MachineID,MachineDescription,MachineInt,ComponentID,ComponentInt,OperationNo,OperationInt,OperatorID,OperatorInt,
--HourValue,Round(AvgCycleTime,2) as AvgCycleTimeInSec,round(RunTime,2) as RunTimeInSec,Round(HourlyTarget,2) as HourlyTarget,
--IncentiveRupess,HourlyTotalIncentive,Round(ShiftTarget,2) as ShiftTarget,ShiftProducedQty,ShiftIncentiveTotal from #Temp
--where HourlyTarget>0
--Order by MachineID,ComponentID,OperationNo,OperatorID,ShiftDate,ShiftID,HourID
--SV Commented till here



--SV Added From here
Insert into #finalTemp(HourStart,HourEnd,ShiftDate,ShiftStart,ShiftEnd,ShiftID,ShiftName,HourID,HourName,MachineID,MachineDescription,MachineInt,OperatorID,OperatorInt,HourValue,ShiftProducedQty)
select distinct HourStart,HourEnd,ShiftDate,ShiftStart,ShiftEnd,ShiftID,ShiftName,HourID,HourName,MachineID,MachineDescription,MachineInt,OperatorID,OperatorInt,
SUM(HourValue) as HourValue,0 from #Temp
--where HourlyTarget>0
group by HourStart,HourEnd,ShiftDate,ShiftStart,ShiftEnd,ShiftID,ShiftName,HourID,HourName,MachineID,MachineDescription,MachineInt,OperatorID,OperatorInt
Order by MachineID,OperatorID,ShiftDate,ShiftID,HourID

UPDATE #finalTemp SET ShiftProducedQty=T1.ShiftProducedQty
From(
select MachineInt,OperatorInt,ShiftDate,ShiftName,Sum(isnull(HourValue,0)) as ShiftProducedQty from #finalTemp
group by MachineInt,OperatorInt,ShiftDate,ShiftName
)As T1 Inner join #finalTemp T2 on T1.MachineInt=T2.MachineInt and T1.OperatorInt=T2.OperatorInt and T1.ShiftDate=T2.ShiftDate and T1.ShiftName=T2.ShiftName


update #finalTemp set AvgCycleTime=T.AvgCycleTimeInSec, avgloadunload=T.avgloadunloadInSec,RunTime=T.RunTimeInSec from
(Select ShiftDate,ShiftID,MachineID,OperatorID,
Round(sum(AvgCycleTime),2) as AvgCycleTimeInSec,Round(Sum(avgloadunload),2) as avgloadunloadInSec,round(sum(RunTime),2) as RunTimeInSec from
(Select distinct ShiftDate,ShiftID,MachineID,OperatorID,AvgCycleTime,avgloadunload,RunTime from #temp)T1
Group by ShiftDate,ShiftID,MachineID,OperatorID)T
inner join #finalTemp on #finalTemp.ShiftDate=T.ShiftDate and #finalTemp.ShiftID=T.ShiftID and
#finalTemp.MachineID=T.MachineID and #finalTemp.OperatorID=T.OperatorID

-----------/* HourlyTarget = RunTime/AvgCycleTime */-----------

Update #finalTemp Set HourlyTarget= isnull(RunTime,0)/((isnull(AvgCycleTime,0)) + (isnull(avgloadunload,0))) where ((isnull(AvgCycleTime,0)) + (isnull(avgloadunload,0)))<>0 --SV

-----------/* ShiftTarget =	(HourlyTarget*ShiftTarget) where ShiftTarget is defined in ShopDefaults	*/-----------

Update #finalTemp Set ShiftTarget = isnull(HourlyTarget,0) * isnull(@ShiftTarget,0) --SV

-----------/* HourlyIncentive =	HourlyTarget * (HourlyIncentive/100) where HourlyIncentive is defined in ShopDefaults	*/-----------

update #finalTemp set HourlyIncentive = HourlyTarget * (@HourlyIncentive/100) --SV

UPDATE #finalTemp SET IncentiveRupess = T1.IncentiveRupess
From(
select MachineInt,OperatorInt,HourStart,HourEnd,HourValue,
(Case when (isnull(HourValue,0) >= HourlyIncentive) Then 10 
	when HourValue=0 and HourlyTarget=0 then 0
when (isnull(HourValue,0) < HourlyIncentive) Then 0 
else 0 end) as IncentiveRupess from #finalTemp
)As T1 Inner join #finalTemp T2 on T1.MachineInt=T2.MachineInt  and T1.OperatorInt=T2.OperatorInt and T1.HourStart=T2.HourStart and T1.HourEnd=T2.HourEnd

UPDATE #finalTemp SET HourlyTotalIncentive = T1.HourlyTotalIncentive
From(
select MachineInt,OperatorInt,ShiftStart,ShiftEnd,sum(isnull(IncentiveRupess,0)) as HourlyTotalIncentive from #finalTemp
group by MachineInt,OperatorInt,ShiftStart,ShiftEnd
)As T1 Inner join #finalTemp T2 on T1.MachineInt=T2.MachineInt and T1.OperatorInt=T2.OperatorInt and T1.ShiftStart=T2.ShiftStart and T1.ShiftEnd=T2.ShiftEnd


Update #finalTemp Set ShiftIncentiveTotal=@ShiftIncentiveInRs

Update #finalTemp set HourlyTotalIncentive=0 where ShiftProducedQty>=ShiftTarget

Update #finalTemp set ShiftIncentiveTotal=0 where ShiftProducedQty<ShiftTarget

select distinct HourStart,HourEnd,ShiftDate,ShiftID,ShiftName,HourID,HourName,MachineID,MachineDescription,MachineInt,OperatorID,OperatorInt,
HourValue,
--Round(AvgCycleTime,2) as AvgCycleTimeInSec,
Round(((isnull(AvgCycleTime,0)) + (isnull(avgloadunload,0))),2) as AvgCycleTimeInSec,
round(RunTime,2) as RunTimeInSec,Round(HourlyTarget,2) as HourlyTarget,
IncentiveRupess,HourlyTotalIncentive,Round(ShiftTarget,2) as ShiftTarget,ShiftProducedQty,ShiftIncentiveTotal from #finalTemp
where HourlyTarget>0
Order by MachineID,OperatorID,ShiftDate,ShiftID,HourID
--SV Added Till here

END
