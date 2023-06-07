/****** Object:  Procedure [dbo].[S_Get_Hourly_Production_Repotrs_Leonine]    Committed by VersionSQL https://www.versionsql.com ******/

/*
CreatedBy : Raksha R
CreatedDate : 26 Aug 2022

Note : @StartTime and @EndTime is LogicalDaystart and LogicalDaysEnd of selected dates

Exec [dbo].[S_Get_Hourly_Production_Repotrs_Leonine] '2022-08-02 08:15:00','2022-08-03 08:15:00','First Shift ','CNC-10',''
exec S_Get_Hourly_Production_Repotrs_Leonine @StartTime='2022-11-02 08:15:00',@EndTime='2022-11-03 08:15:00',@Shift=N'',@MachineID=N'CNC-12',@GroupID=N'CNC_CELL,VMC_CELL'
exec S_Get_Hourly_Production_Repotrs_Leonine @StartTime='2022-11-01 08:15:00',@EndTime='2022-11-10 08:15:00',@Shift=N'',@MachineID=N'CNC-12',@GroupID=N'CNC_CELL,VMC_CELL'

*/
CREATE procedure [dbo].[S_Get_Hourly_Production_Repotrs_Leonine]
@StartTime datetime='',
@EndTime datetime='',
@Shift nvarchar(50)='',
@MachineID nvarchar(MAX)='',
@GroupID nvarchar(max)=''

AS
BEGIN

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
	StdCycleTime float default 0,
	SubOperations int,
	HourlyPartCount float default 0,
	HourlyTarget float default 0,
	RunTime float default 0,
	ShiftTarget float default 0,
	TotalOutput float default 0,
	DownTime float default 0,
	SetupTime float default 0,
	ProductionHours float default 0
)

CREATE TABLE #ShiftDetails   
(  
 SlNo bigint identity(1,1) NOT NULL,
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime  ,
 ShiftID int
) 

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

CREATE TABLE #PlannedDownTimesShift  
(  
 SlNo int not null identity(1,1),  
 Starttime datetime,  
 EndTime datetime,  
 Machine nvarchar(50),  
 MachineInterface nvarchar(50),  
 DownReason nvarchar(50),  
 ShiftSt datetime  
)  

Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50)
)

Insert into #Downcode(Downid)
Select distinct downid from downcodeinformation 
where downid = 'SETUP CHANGE' 
--where downid = 'Set Up Approval'

Declare @strMachine as nvarchar(max)
Declare @StrGroupID AS NVarchar(max)
Declare @StrTPMMachines AS nvarchar(500)

SELECT @strMachine = ''
Select @StrGroupID=''
SELECT @StrTPMMachines=''

declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = '  AND MachineInformation.TPMTrakEnabled = 1  '  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END  

if isnull(@machineid,'') <> ''
begin
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	SET @strMachine = ' and machineinformation.MachineID in (' + @MachineID +')'
end

If isnull(@GroupID ,'') <> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	Select @StrGroupID = ' And ( PlantMachineGroups.GroupID IN (' + @GroupID + ')) '
End


Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 

Declare @strSql as nvarchar(4000)

--Select @T_ST=dbo.f_GetLogicalDaystart(@StartTime)
--Select @T_ED=dbo.f_GetLogicalDayend(@EndTime)

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

/* Planned Down times for the given time period */  
Select @strsql=''  
select @strsql = 'insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason)'  
select @strsql = @strsql + 'select  
CASE When StartTime<'''+ convert(nvarchar(25),@T_ST,120)+''' Then '''+ convert(nvarchar(25),@T_ST,120)+''' Else StartTime End,  
case When EndTime>'''+ convert(nvarchar(25),@T_ED,120)+''' Then '''+ convert(nvarchar(25),@T_ED,120)+''' Else EndTime End,  
Machine,MachineInformation.InterfaceID,  
DownReason  
FROM PlannedDownTimes 
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
WHERE PDTstatus =1 and (  
(StartTime >= '''+ convert(nvarchar(25),@T_ST,120)+'''  AND EndTime <='''+ convert(nvarchar(25),@T_ED,120)+''')  
OR ( StartTime < '''+ convert(nvarchar(25),@T_ST,120)+'''  AND EndTime <= '''+ convert(nvarchar(25),@T_ED,120)+''' AND EndTime > '''+ convert(nvarchar(25),@T_ST,120)+''' )  
OR ( StartTime >= '''+ convert(nvarchar(25),@T_ST,120)+'''  AND StartTime <'''+ convert(nvarchar(25),@T_ED,120)+''' AND EndTime > '''+ convert(nvarchar(25),@T_ED,120)+''' )  
OR ( StartTime < '''+ convert(nvarchar(25),@T_ST,120)+'''  AND EndTime > '''+ convert(nvarchar(25),@T_ED,120)+''') )'  
select @strsql = @strsql + @strmachine  + @StrTPMMachines 
select @strsql = @strsql + 'ORDER BY StartTime'  
print @strsql  
exec (@strsql)  


Declare @T_ST1 AS Datetime 
Declare @T_ED1 AS Datetime 

--Select @T_ST1=dbo.f_GetLogicalDaystart(@StartTime)
--Select @T_ED1=dbo.f_GetLogicalDayend(@EndTime)

select @T_ST1=@StartTime
select @T_ED1=@EndTime

while @T_ST1<=@T_ED1
begin
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)   
	--EXEC s_GetShiftTime @T_ST1,''  
	EXEC s_GetShiftTime @T_ST1,@Shift
	SELECT @T_ST1=DATEADD(DAY,1,@T_ST1)
end

update #ShiftDetails set Shiftid=T.Shiftid from
(select * from shiftdetails where Running=1)T 
inner join #ShiftDetails on #ShiftDetails.Shift=T.Shiftname

delete from #ShiftDetails where ShiftStart>=@EndTime


Insert into #HourData(Mdate,ShiftStart,ShiftEnd,ShiftName,ShiftID,HourStart,HourEnd,HourID,HourName)
Select distinct convert(nvarchar(10),T1.Pdate,120),T1.ShiftStart,T1.ShiftEnd,T1.Shift,T1.ShiftID,
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
insert into #Temp(ShiftDate,ShiftName,ShiftID,ShiftStart,ShiftEnd,HourID,HourName,HourStart,HourEnd,MachineID,MachineInt,MachineDescription,ComponentID,ComponentInt,OperationNo,OperationInt,
OperatorID,OperatorInt,StdCycleTime,SubOperations)
select distinct H.Mdate,H.ShiftName,H.ShiftID,H.ShiftStart,H.ShiftEnd,H.HourID,H.HourName,H.HourStart,H.HourEnd,machineinformation.machineid,machineinformation.InterfaceID,machineinformation.Description,
componentinformation.componentid,componentinformation.InterfaceID,
componentoperationpricing.operationno,componentoperationpricing.InterfaceID,Ei.employeeid,EI.interfaceid,componentoperationpricing.cycletime,componentoperationpricing.SubOperations from #T_autodata autodata
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr 
LEFT JOIN PlantMachineGroups on machineinformation.machineid = PlantMachineGroups.machineid
Cross Join #HourData H 
where 1=1 '
Set @strSql = @strSql + @strMachine + @StrGroupID + @StrTPMMachines
print @strsql
exec (@strsql)

UPDATE #Temp SET HourlyPartCount = ISNULL(HourlyPartCount,0) + ISNULL(t2.val,0)
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
	UPDATE #Temp SET HourlyPartCount = ISNULL(HourlyPartCount,0) - ISNULL(T2.val,0) from(
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



Update #Temp set TotalOutput = isnull(T1.Total,0)
From (
	select ShiftDate,ShiftID,MachineInt,ComponentInt,OperationInt,OperatorInt,sum(isnull(HourlyPartCount,0)) as Total from #Temp
	 group by ShiftDate,ShiftID,MachineInt,ComponentInt,OperationInt,OperatorInt
)T1 inner join #Temp T2 on T1.ShiftDate=T2.ShiftDate and T1.ShiftID=T2.ShiftID and t1.MachineInt=t2.MachineInt and T1.ComponentInt=t2.ComponentInt and t1.OperationInt=T2.OperationInt and t1.OperatorInt=t2.OperatorInt

----------------------- RunTime calculaion start-----------------------------------------------------------------------------------------------------------------------------------------------------------------

		Select @strsql=''   
		Select @strsql= 'insert into #RunTime(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface, OperatorID,  OperatorInt,
		msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,SubOperations)'  
		select @strsql = @strsql + ' SELECT A3.machineid, autodata.mc,A3.componentid, autodata.comp,  
		A3.operationno, autodata.opn,A3.OperatorID,autodata.opr,
		Case when autodata.msttime<  T.Shiftstart then T.Shiftstart else autodata.msttime end,   
		Case when autodata.ndtime> T.Shiftend  then T.Shiftend else autodata.ndtime end,     
		T.Shiftstart,T.Shiftend,0,autodata.id,A3.StdCycleTime,A3.SubOperations FROM #T_autodata autodata  with(nolock)
		inner join (select distinct MachineID,MachineInt,ComponentID,ComponentInt,OperationNo,OperationInt,OperatorID,OperatorInt,StdCycleTime,SubOperations from #Temp) A3 
		on autodata.mc=A3.MachineInt and autodata.comp=A3.ComponentInt and autodata.opn=A3.OperationInt and autodata.opr=A3.OperatorInt
		cross join(select distinct Shiftstart,Shiftend from #ShiftDetails) as T
		WHERE ((autodata.msttime>=T.Shiftstart  and  autodata.ndtime<=T.Shiftend ) 
			OR ( autodata.sttime<T.Shiftstart  and  autodata.ndtime>T.Shiftstart  and autodata.ndtime<=T.Shiftend ) --SV Added 
			or (autodata.msttime>=T.Shiftstart  and autodata.sttime<T.Shiftend  and autodata.ndtime>T.Shiftend)
			OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime > T.Shiftend) )' --SV Added 
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

		----Update #FinalRunTime Set BatchEnd=T1.BE
		----From(
		----	Select A1.machineinterface,A1.FromTm,A2.BatchStart,(Case when A2.BatchEnd<A1.ToTm Then A1.ToTm else A2.BatchEnd end) as BE from #FinalRunTime A1
		----	inner join (select machineinterface,Convert(nvarchar(10),FromTm,120) as Date1,FromTm,Max(BatchStart) as BatchStart,Max(BatchEnd) as BatchEnd from #FinalRunTime
		----	group by machineinterface,Convert(nvarchar(10),FromTm,120),FromTm) A2
		----	on A1.machineinterface=A2.machineinterface and Convert(nvarchar(10),A1.FromTm,120)=Convert(nvarchar(10),A2.Date1,120) and A1.FromTm=A2.FromTm and A1.BatchStart=A2.BatchStart
		----)T1 inner join #FinalRunTime T2 on T1.machineinterface=T2.machineinterface and T1.FromTm=T2.FromTm and T1.BatchStart=T2.BatchStart

		----Update #FinalRunTime Set BatchStart=T1.BS
		----From(
		----	Select A1.machineinterface,A1.FromTm,A2.BatchStart,(Case when A1.FromTm<A2.BatchStart Then A1.FromTm else A2.BatchStart end) as BS from #FinalRunTime A1
		----	inner join (select machineinterface,Convert(nvarchar(10),FromTm,120) as Date1,FromTm,min(BatchStart) as BatchStart,Min(BatchEnd) as BatchEnd from #FinalRunTime
		----	group by machineinterface,Convert(nvarchar(10),FromTm,120),FromTm) A2
		----	on A1.machineinterface=A2.machineinterface and Convert(nvarchar(10),A1.FromTm,120)=Convert(nvarchar(10),A2.Date1,120) and A1.FromTm=A2.FromTm and A1.BatchStart=A2.BatchStart
		----)T1 inner join #FinalRunTime T2 on T1.machineinterface=T2.machineinterface and T1.FromTm=T2.FromTm and T1.BatchStart=T2.BatchStart

		update #FinalRunTime set Runtime=datediff(SECOND,BatchStart,BatchEnd)


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
)T1 inner join #Temp T2 on T1.machineinterface=T2.MachineInt and T1.Compinterface=T2.ComponentInt and T1.OpnInterface=T2.OperationInt and T1.OperatorInt=T2.OperatorInt 
and T1.FromTm=T2.ShiftStart and T1.ToTm=T2.ShiftEnd

----------------------- RunTime calculaion end-----------------------------------------------------------------------------------------------------------------------------------------------------------------


----------------------- Setup time calculaion start-----------------------------------------------------------------------------------------------------------------------------------------------------------------

 Select @strsql = ''
	 Select @strsql = @strsql + ' UPDATE #Temp SET  SetupTime =  isNull(t2.down,0)  
	 from  
	 (select  F.ShiftStart,F.ShiftEnd,F.MachineInt,F.ComponentInt,F.OperationInt,F.OperatorInt,  
	  sum (CASE  
		WHEN (autodata.msttime >= F.ShiftStart  AND autodata.ndtime <=F.ShiftEnd)  THEN autodata.loadunload  
		WHEN ( autodata.msttime < F.ShiftStart  AND autodata.ndtime <= F.ShiftEnd  AND autodata.ndtime > F.ShiftStart ) THEN DateDiff(second,F.ShiftStart,autodata.ndtime)  
		WHEN ( autodata.msttime >= F.ShiftStart   AND autodata.msttime <F.ShiftEnd  AND autodata.ndtime > F.ShiftEnd  ) THEN DateDiff(second,autodata.msttime,F.ShiftEnd )  
		WHEN ( autodata.msttime < F.ShiftStart  AND autodata.ndtime > F.ShiftEnd ) THEN DateDiff(second,F.ShiftStart,F.ShiftEnd )  
		END ) as down  
		from #T_autodata autodata   
		inner join (select distinct ShiftStart,ShiftEnd,MachineInt,ComponentInt,OperationInt,OperatorInt from #Temp) F on autodata.mc = F.MachineInt and autodata.comp=F.ComponentInt and autodata.opn=F.OperationInt and autodata.opr = F.OperatorInt  
		inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
		inner join #Downcode on #Downcode.downid= downcodeinformation.downid
		where (autodata.datatype=''2'') AND  
		(( (autodata.msttime>=F.ShiftStart) and (autodata.ndtime<=F.ShiftEnd))  
		   OR ((autodata.msttime<F.ShiftStart)and (autodata.ndtime>F.ShiftStart)and (autodata.ndtime<=F.ShiftEnd))  
		   OR ((autodata.msttime>=F.ShiftStart)and (autodata.msttime<F.ShiftEnd)and (autodata.ndtime>F.ShiftEnd))  
		   OR((autodata.msttime<F.ShiftStart)and (autodata.ndtime>F.ShiftEnd)))   
		   AND (downcodeinformation.availeffy = ''0'')  
		   group by F.ShiftStart,F.ShiftEnd,F.MachineInt,F.ComponentInt,F.OperationInt,F.OperatorInt  
	 ) as t2 Inner Join #Temp on t2.MachineInt = #Temp.MachineInt and  
	 t2.ComponentInt = #Temp.ComponentInt and t2.OperationInt = #Temp.OperationInt and  t2.OperatorInt = #Temp.OperatorInt   
	 and t2.ShiftStart=#Temp.ShiftStart and t2.ShiftEnd=#Temp.ShiftEnd '
     print @strsql
	 exec(@strsql) 
	 
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
	BEGIN   
			Select @strsql = '' 
			Select @strsql = @strsql + 'UPDATE  #Temp SET SetupTime = isnull(#Temp.SetupTime,0) - isNull(T2.PPDT ,0)  
			FROM(  
			SELECT F.ShiftStart,F.ShiftEnd,F.MachineInt,F.ComponentInt,F.OperationInt,F.OperatorInt,  
			SUM  
			(CASE  
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
			END ) as PPDT  
			FROM #T_autodata AutoData  
			CROSS jOIN #PlannedDownTimesShift T  
			INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
			INNER JOIN (select distinct ShiftStart,ShiftEnd,MachineInt,ComponentInt,OperationInt,OperatorInt from #Temp) F on F.MachineInt=Autodata.mc and F.ComponentInt=Autodata.comp and F.OperationInt = Autodata.opn and F.OperatorInt=Autodata.opr  
			inner join #Downcode on #Downcode.downid= downcodeinformation.downid
			
			WHERE autodata.DataType=''2'' AND T.machineinterface=autodata.mc  AND (downcodeinformation.availeffy = ''0'') 
				AND  
				((autodata.sttime >= F.ShiftStart  AND autodata.ndtime <=F.ShiftEnd)  
				OR ( autodata.sttime < F.ShiftStart  AND autodata.ndtime <= F.ShiftEnd AND autodata.ndtime > F.ShiftStart )  
				OR ( autodata.sttime >= F.ShiftStart   AND autodata.sttime <F.ShiftEnd AND autodata.ndtime > F.ShiftEnd )  
				OR ( autodata.sttime < F.ShiftStart  AND autodata.ndtime > F.ShiftEnd))  
				AND  
				((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
				OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
				AND  
				((F.ShiftStart >= T.StartTime  AND F.ShiftEnd <=T.EndTime)  
				OR ( F.ShiftStart < T.StartTime  AND F.ShiftEnd <= T.EndTime AND F.ShiftEnd > T.StartTime )  
				OR ( F.ShiftStart >= T.StartTime   AND F.ShiftStart <T.EndTime AND F.ShiftEnd > T.EndTime )  
				OR ( F.ShiftStart < T.StartTime  AND F.ShiftEnd > T.EndTime) )   
				group  by F.ShiftStart,F.ShiftEnd,F.MachineInt,F.ComponentInt,F.OperationInt,F.OperatorInt  
			)AS T2  Inner Join #Temp on t2.MachineInt = #Temp.MachineInt and  
			t2.ComponentInt = #Temp.ComponentInt and t2.OperationInt = #Temp.OperationInt and  t2.OperatorInt = #Temp.OperatorInt   
			and t2.ShiftStart=#Temp.ShiftStart and t2.ShiftEnd=#Temp.ShiftEnd  '
		print @strsql
		exec(@Strsql)
	END
----------------------- Setup time calculaion end-----------------------------------------------------------------------------------------------------------------------------------------------------------------

--Update #Temp set ShiftTarget = ((DATEDIFF(SECOND,ShiftStart,ShiftEnd)) - isnull(SetupTime,0) ) / isnull(StdCycleTime,0)

Update #Temp set ShiftTarget = (isnull(RunTime,0)-isnull(SetupTime,0)) / isnull(StdCycleTime,0) where isnull(StdCycleTime,0)>0

--Update #Temp set HourlyTarget= (DATEDIFF(SECOND,HourStart,HourEnd)) / isnull(StdCycleTime,0)

Update #Temp set HourlyTarget= isnull(ShiftTarget,0) / dbo.f_FormatTime(isnull(RunTime,0),'hh') where isnull(RunTime,0)>0

Update #Temp set ProductionHours= isnull(TotalOutput,0) / isnull(HourlyTarget,0) where isnull(HourlyTarget,0)>0

select ShiftDate,ShiftName,HourStart,HourEnd,MachineID,MachineInt,ComponentID,ComponentInt,OperationNo,OperationInt,OperatorID,OperatorInt,HourID,Round(HourlyPartCount,2) as HourlyPartCount,
StdCycleTime,Round(HourlyTarget,2) as HourlyTarget,Round(TotalOutput,2) as TotalOutput,RunTime,Round(ShiftTarget,2) as ShiftTarget,
dbo.f_FormatTime(SetupTime,'mm') as SetupTimeInMin,SetupTime as SetupTimeInSec,Round(ProductionHours,2) as ProductionHours from #Temp
where TotalOutput<>0 and ShiftTarget<>0 and HourlyTarget<>0 and ProductionHours<>0
Order By ShiftDate,ShiftID,MachineID,ComponentID,OperationNo,OperatorID,HourID

END
