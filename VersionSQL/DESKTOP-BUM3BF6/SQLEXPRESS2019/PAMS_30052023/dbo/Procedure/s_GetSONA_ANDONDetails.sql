/****** Object:  Procedure [dbo].[s_GetSONA_ANDONDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetSONA_ANDONDetails] '2016-05-19 17:40:00','','FINAL INSPECTION','',''

CREATE PROCEDURE [dbo].[s_GetSONA_ANDONDetails]
	@Startdate datetime,
	@SHIFT nvarchar(50)='',
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)='',
	@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON; --ER0377

Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(255)
declare @timeformat as nvarchar(2000)
Declare @StrTPMMachines AS nvarchar(500)
	
SELECT @StrTPMMachines=''				
SELECT @strMachine = ''
SELECT @strPlantID = ''
SELECT @timeformat ='ss'

Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	select @timeformat = 'ss'
end

Create Table #Shift
(	
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	HourName nvarchar(50),
	HourID int,
	FromTime datetime,
	ToTime Datetime
)

Create Table #ShiftTemp
(	
	Plantid nvarchar(50),
	Machineid nvarchar(50),
	machineinterface nvarchar(50),
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	HourName nvarchar(50),
	HourID int,
	FromTime datetime,
	ToTime Datetime,
	Actual float
)

Create Table #ShiftSummary
(	
	Plantid nvarchar(50),
	Machineid nvarchar(50),
	machineinterface nvarchar(50),
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	FromTime datetime,
	ToTime Datetime,
	Actual float,
	Target int,
	RejCount float,
	LineLevelRejQty float,
	LineLevelRwkQty float
)


Create Table #BekidoChokko
(	
	Machineid nvarchar(50),
	OKProdqty float,
	RejCount float,
	LineLevelRejQty float,
	LineLevelRwkQty float,
	TotalAvailableHours float,
	BNMCT float,
	Bekido float,
	Chokko float
)

Create Table #PDT
(	
	Machineid nvarchar(50),
	machineinterface nvarchar(50),
	FromTime datetime,
	ToTime Datetime,
	StartTime_PDT Datetime,
	EndTime_PDT Datetime,
	DownReason nvarchar(50),
	Actual float
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
declare @counter as datetime
declare @stdate as nvarchar(20)

if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
end

if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'
END
ELSE
BEGIN
	SET  @StrTPMMachines = ' '
END


Select @T_ST=dbo.f_GetLogicalDaystart(@StartDate)
Select @T_ED=dbo.f_GetLogicalDayend(@StartDate)


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


select @stdate = CAST(datePart(yyyy,@StartDate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@StartDate) AS nvarchar(2)) + '-' + CAST(datePart(dd,@StartDate) AS nvarchar(2))
select @counter=convert(datetime, cast(DATEPART(yyyy,@StartDate)as nvarchar(4))+'-'+cast(datepart(mm,@StartDate)as nvarchar(2))+'-'+cast(datepart(dd,@StartDate)as nvarchar(2)) +' 00:00:00.000')

If @Shift<>'' 
Begin         
	insert  #Shift	(PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime)
	select @counter,S.ShiftName,S.ShiftID,SH.Hourname,SH.HourID,
	dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),
	dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))
	from shiftdetails S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid
	where S.running=1
	and S.ShiftName = @Shift 
end       

If @Shift = '' 
Begin         
	insert  #Shift	(PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime)
	select @counter,S.ShiftName,S.ShiftID,SH.Hourname,SH.HourID,
	dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),
	dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))
	from shiftdetails S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid
	where S.running=1
end 


select @strsql=''
Select @strsql = @Strsql + '
insert  #ShiftTemp	(Plantid,Machineid,MachineInterface,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Actual)
Select Plantmachine.Plantid,MachineInformation.MachineID,MachineInformation.interfaceid,S.PDate,S.ShiftName,S.ShiftID,S.HourName,S.HourID,S.FromTime,S.ToTime,0
FROM MachineInformation cross join #shift S
LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
where 1=1 '
SET @strSql =  @strSql + @strMachine + @strPlantID + @StrTPMMachines

print @strsql
EXEC(@strSql)



	update #ShiftTemp set Actual=T1.Actual1 from
	(
	select M.machineid as machine,S.FromTime as hrstart,S.ToTime as hrend,sum(A.partscount/O.suboperations) as Actual1
	from #T_autodata A
	inner join machineinformation M on M.interfaceid=A.mc
	inner join componentinformation C on C.interfaceid=A.comp
	inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
	inner join #ShiftTemp S on M.Machineid= S.machineid
	where A.datatype=1 and A.ndtime>S.FromTime and A.ndtime<=S.ToTime
	group by M.machineid,S.FromTime ,S.ToTime
	) as T1 inner join #ShiftTemp on #ShiftTemp.machineid=T1.machine and #ShiftTemp.Fromtime=T1.hrstart and #ShiftTemp.totime=T1.hrend


	insert into #PDT
	select st.machineID,st.machineinterface,st.FromTime,st.ToTime,
	case when  st.FromTime > pdt.StartTime then st.FromTime else pdt.StartTime end,
	case when  st.ToTime < pdt.EndTime then st.ToTime else pdt.EndTime end,pdt.DownReason,0
	from #ShiftTemp st inner join PlannedDownTimes pdt
	on st.machineID = pdt.Machine and PDTstatus = 1 and
	((pdt.StartTime >= st.FromTime  AND pdt.EndTime <=st.ToTime)
	OR ( pdt.StartTime < st.FromTime  AND pdt.EndTime <= st.ToTime AND pdt.EndTime > st.FromTime )
	OR ( pdt.StartTime >= st.FromTime   AND pdt.StartTime <st.ToTime AND pdt.EndTime > st.ToTime )
	OR ( pdt.StartTime < st.FromTime  AND pdt.EndTime > st.ToTime))

	--ER0210-KarthikG-17/Dec/2009::From Here
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
	update #PDT set Actual=isnull(#PDT.Actual,0) + isNull(t1.Actual ,0) from
	(
		select M.machineid as machine,StartTime_PDT,EndTime_PDT,sum(A.partscount/O.suboperations) as Actual
		from #T_autodata A
		inner join machineinformation M on M.interfaceid=A.mc
		inner join componentinformation C on C.interfaceid=A.comp
		inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
		inner join #PDT  on M.Machineid= #PDT.machineid
		where A.datatype=1 and A.ndtime>#PDT.StartTime_PDT and A.ndtime<=#PDT.EndTime_PDT
		group by M.machineid,StartTime_PDT,EndTime_PDT
	) as t1 inner join #PDT on #PDT.machineid=t1.machine and #PDT.StartTime_PDT=t1.StartTime_PDT and #PDT.EndTime_PDT=t1.EndTime_PDT

		Update #ShiftTemp set Actual = isnull(#ShiftTemp.Actual,0) - isNull(t1.Actual ,0) from(
			Select MachineID,FromTime,ToTime,sum(Actual) as Actual from #PDT Group by MachineID,FromTime,ToTime
		) as t1 inner join #ShiftTemp on t1.machineID = #ShiftTemp.machineID and
		t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime

	End

	------------------------- OUTPUT1 : To Get Hourwise Actual -----------------------------------
	declare @Dynamicpivotquery as nvarchar(MAX)
	declare @Columnname as nvarchar(MAX)

	Select @Columnname = ISNULL(@Columnname + ',','') + Quotename(Hourid)
	from(Select distinct hourid from #shifttemp) as Hours

	SET @Dynamicpivotquery = 
	N'Select shiftname,'+ @Columnname + ' from 
	(Select Shiftname,Hourid,Actual from #Shifttemp) as S
	pivot(SUM(Actual) for hourid in('+ @Columnname + ')) as PVTTable'
	EXEC sp_executesql @DynamicPivotQuery
  	------------------------- OUTPUT1 : To Get Hourwise Actual --------------------------------------------


	------------------------- OUTPUT2 : To Get Shiftwise Actual and Target -----------------------------------

	insert #Shiftsummary(Plantid,Machineid,MachineInterface,PDate,ShiftName,ShiftID,FromTime,ToTime,Actual,Target,Rejcount,LineLevelRejQty,LineLevelRwkQty)
	Select Plantid,Machineid,Machineinterface,Pdate,Shiftname,Shiftid,Min(Fromtime),Max(Totime),Sum(Actual),0,0,0,0 from #ShiftTemp
	group by  Plantid,Machineid,Machineinterface,Pdate,Shiftname,Shiftid


	select A.machineid,A.Componentid,A.Operationno,S.FromTime,S.ToTime,S.Pdate,S.Shiftname into #Temp from 
	(select top 1 M.Machineid,C.Componentid,CO.Operationno from #T_autodata A  
	inner join Machineinformation M on A.mc=M.interfaceid  
	inner join Componentinformation C on A.comp=C.interfaceid  
	inner join Componentoperationpricing CO on A.opn=CO.interfaceid and M.Machineid=CO.Machineid and C.Componentid=CO.Componentid 
	where M.machineid=@Machineid 
	order by sttime desc) A cross join #Shiftsummary S 


	declare @LastSetDateInLoadschedule as Datetime
	SET @LastSetDateInLoadschedule = (Select TOP 1 DATE FROM LOADSCHEDULE L inner join #Temp on L.Machine=#Temp.Machineid and L.component=#Temp.componentid and L.operation=#Temp.operationno
	where L.date<=#Temp.Pdate ORDER BY DATE DESC)


	update #Shiftsummary set Target = isnull(Target,0) + isnull(T.targetcount,0) from
	(
	Select T1.Pdate,T1.Fromtime,T1.Machineid,sum(L.idealcount) as targetcount from loadschedule L inner join
	#Temp T1 on L.Machine=T1.Machineid and L.component=T1.componentid and L.operation=T1.operationno and L.date<=T1.Pdate and T1.Shiftname=L.Shift
	where L.date=@LastSetDateInLoadschedule and 
	L.Shift in(SELECT distinct L.Shift FROM LOADSCHEDULE L inner join #Temp T1 on L.Machine=T1.Machineid and L.component=T1.componentid and L.operation=T1.operationno and L.date=@LastSetDateInLoadschedule)
	group by T1.Pdate,T1.Fromtime,T1.Machineid
	)T inner join #Shiftsummary on #Shiftsummary.Fromtime=T.Fromtime and #Shiftsummary.Machineid=T.Machineid

	Select ShiftName,Actual,Target from #Shiftsummary
	------------------------- OUTPUT2 : To Get Hourwise Actual and Target -----------------------------------


	------------------------- OUTPUT : To Get BEKIDO and CHOKKO -----------------------------------
	Declare @Shiftstart as datetime
	Declare @Curtime as datetime


	Select @Shiftstart = (Select Top 1 fromtime from #shiftsummary order by fromtime)
	Select @Curtime = getdate()

	Update #Shiftsummary set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
	From
	( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	inner join #Shiftsummary S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=S.Pdate and A.RejShift=S.shiftid
	where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.Pdate) and  
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	group by A.mc,M.Machineid
	)T1 inner join #Shiftsummary B on B.Machineid=T1.Machineid 

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN

		Update #Shiftsummary set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
		(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
		inner join #Shiftsummary S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=S.Pdate and A.RejShift=S.shiftid
		Cross join Planneddowntimes P
		where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
		A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and 
		Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
		and P.starttime>=S.fromtime and P.Endtime<=S.totime
		group by A.mc,M.Machineid)T1 inner join #Shiftsummary B on B.Machineid=T1.Machineid 

	END

	Update #Shiftsummary set LineLevelRejQty = isnull(LineLevelRejQty,0) + isnull(T1.RejQty,0)
	From
	( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Shiftsummary S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=S.Pdate and A.RejShift=S.shiftid
	where A.flag = 'Rejection' and A.Rejection_code='99' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.Pdate) and  
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	group by A.mc,M.Machineid
	)T1 inner join #Shiftsummary B on B.Machineid=T1.Machineid 

	Update #Shiftsummary set LineLevelRwkQty = isnull(LineLevelRwkQty,0) + isnull(T1.RejQty,0)
	From
	( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Shiftsummary S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=S.Pdate and A.RejShift=S.shiftid
	where A.flag = 'Rejection' and A.Rejection_code='98' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.Pdate) and  
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	group by A.mc,M.Machineid
	)T1 inner join #Shiftsummary B on B.Machineid=T1.Machineid 


	Insert into #BekidoChokko(Machineid,OKProdqty,RejCount,LineLevelRejQty,LineLevelRwkQty,TotalAvailableHours,BNMCT,Bekido,Chokko)
	Select Machineid,SUM(Actual)-SUM(RejCount),SUM(RejCount),SUM(LineLevelRejQty),SUM(LineLevelRwkQty),datediff(SECOND,@shiftstart,@curtime),0,0,0 from #shiftsummary
	group by Machineid

	update #BekidoChokko set TotalAvailableHours=isnull(#BekidoChokko.TotalAvailableHours,0) - isNull(t1.PDTHours ,0) from
	(
		select ISNULL(SUM(datediff(hour,StartTime_PDT,EndTime_PDT)),0) as PDTHours from #BekidoChokko
		inner join #PDT  on #BekidoChokko.Machineid= #PDT.machineid
		where #PDT.StartTime_PDT>=@shiftstart and #PDT.EndTime_PDT<=@curtime and #PDT.Machineid=@Machineid
	) as t1 



	update #BekidoChokko set BNMCT = Isnull(BNMCT,0) + ISnull(T.Cycle,0) from
	(Select T1.Machineid,Sum(T1.Cycletime) as Cycle from 
		(select co.machineid,co.Componentid,co.Operationno,sum(CO.Cycletime) as cycletime from 
			(select distinct A.mc,A.comp,A.opn from #T_autodata A   
			where A.ndtime>@shiftstart and A.ndtime<=@curtime 
			)A
		inner join Componentinformation C on A.comp=C.interfaceid  
		inner join Componentoperationpricing CO on A.opn=CO.interfaceid and C.Componentid=CO.Componentid 
		WHERE co.machineid='BNM' group by co.machineid,co.Componentid,co.Operationno 
		)T1 
	group by T1.Machineid)T


	update #BekidoChokko  set chokko = (OKProdqty + LineLevelRwkQty + (LineLevelRejQty + RejCount))/(OKProdqty) * 100 where OKProdqty>0

	update #BekidoChokko  set Bekido = (OKProdqty * BNMCT)/(TotalAvailableHours) * 100 where OKProdqty>0 

	------------------------- OUTPUT : To Get BEKIDO and CHOKKO -----------------------------------



	------------------------- OUTPUT3 : To Get Running Model -----------------------------------
	select top 1 C.description as [Current Model] from #T_autodata A  
	inner join Machineinformation M on A.mc=M.interfaceid  
	inner join Componentinformation C on A.comp=C.interfaceid  
	inner join Componentoperationpricing CO on A.opn=CO.interfaceid and M.Machineid=CO.Machineid and C.Componentid=CO.Componentid 
	where M.machineid=@Machineid 
	order by sttime desc  
	------------------------- OUTPUT3 : To Get Running Model -----------------------------------


	------------------------- OUTPUT4 : To Get Top5 DownLosses -----------------------------------

	Create table #Loss
	(
		Plantid nvarchar(50),
		Machineid nvarchar(50),
		DownCategory nvarchar(50),
		Downid nvarchar(50),
		Downtime float
	)

	Create table #CycleLoss
	(
		Plantid nvarchar(50),
		Machineid nvarchar(50),
		Componentid nvarchar(50),
		Operationno nvarchar(50),
		StdCycletime float,
		DownCategory nvarchar(50),
		Downid nvarchar(50),
		Downtime float
	)


	create table #CurrentShift
	(
		Startdate datetime,
		shiftname nvarchar(10),
		Starttime datetime,
		Endtime datetime,
		shiftid int
	)

		create table #Slno
	(
		IDD int
	)

	Insert into #Slno(IDD)
	Select '1'
	
	Insert into #Slno(IDD)
	Select '2'

	Insert into #Slno(IDD)
	Select '3'


	declare @starttime as datetime
	declare @endtime as datetime

	select @StartTime = dbo.f_GetLogicalDaystart(@Startdate)
	Select @Endtime = dbo.f_GetLogicalDayend(@Startdate)


	Insert into #Loss(Plantid,Machineid,downCategory,Downid,Downtime)
	select S.Plantid,S.Machineid,D.Catagory,D.downid,sum(
	CASE
	WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
	WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
	WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
	WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
	END
	)AS down
	from #T_autodata autodata 
	inner join machineinformation M ON autodata.mc = M.InterfaceID 
	inner join (Select distinct Plantid,machineid from #Shifttemp) S on S.machineid=M.machineid
	left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
	inner join downcodeinformation D on autodata.dcode=D.interfaceid
	inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
	where autodata.datatype=2 AND 
	(
	(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
	OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
	OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
	OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
	) 
	group by S.Plantid,S.Machineid,D.Catagory,D.downid

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
	BEGIN

		UPDATE #Loss set Downtime =isnull(Downtime,0) - isNull(TT.DPDT ,0)
		FROM(
			SELECT S.Plantid,S.Machineid,D.Catagory,D.downid, SUM
			   (CASE
				WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (autodata.loadunload)
				WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as DPDT
			FROM #T_autodata AutoData CROSS JOIN PlannedDownTimes T 
			inner join machineinformation M ON autodata.mc = M.InterfaceID 
			left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
			inner join downcodeinformation D on autodata.dcode=D.interfaceid
			inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
			inner join (Select distinct Plantid,machineid from #Shifttemp) S on S.machineid=M.machineid
			WHERE autodata.DataType=2  AND T.Machine=M.Machineid and
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				) AND
				(
				(T.StartTime>=@StartTime  and  T.EndTime<=@EndTime)
				OR (T.StartTime<@StartTime and  T.EndTime>@StartTime and T.EndTime<=@EndTime)
				OR (T.StartTime>=@StartTime  and T.StartTime<@EndTime  and T.EndTime>@EndTime)
				OR (T.StartTime<@StartTime and T.EndTime>@EndTime )) 
		group by S.Plantid,S.Machineid,D.Catagory,D.downid
		) as TT INNER JOIN #Loss ON TT.Catagory = #Loss.downCategory and TT.downid=#Loss.Downid and TT.Machineid=#Loss.Machineid

	END


	select 
	T.Downid,Round([dbo].[f_FormatTime](T.Downtime,'mm'),0) as Downtime,T.rn into #down
	from (
		 select T.Machineid,T.DownCategory,
				T.Downid,
				T.Downtime,
				row_number() over(partition by T.Machineid order by T.downtime desc) as rn
		 from #Loss as T where downtime>0
		 ) as T 
	where T.rn <= 3
	order by T.Machineid,T.Downtime desc

	select S.IDD,D.Downid,D.Downtime from #down D right outer join #slno S on D.rn=S.IDD
	------------------------- OUTPUT4 : To Get Top5 DownLosses -----------------------------------

	------------------------- OUTPUT5 : To Get Time Loss and CycleLoss ForDay -----------------------------------
	select Round([dbo].[f_FormatTime](sum(#Loss.Downtime),'mm'),0) as downtime into #TimeLossForDay from #Loss where downtime>0

	Insert into #cycleLoss(Plantid,Machineid,Componentid,Operationno,StdCycletime,downCategory,Downid,Downtime)
	select S.Plantid,S.Machineid,CO.Componentid,CO.Operationno,CO.Cycletime,D.Catagory,D.downid,sum(
	CASE
	WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  autodata.loadunload
	WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
	WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
	WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
	END
	)AS down
	from #T_autodata autodata 
	inner join machineinformation M ON autodata.mc = M.InterfaceID 
	inner join (Select distinct Plantid,machineid from #Shifttemp) S on S.machineid=M.machineid
	left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
    Inner join componentinformation CI on autodata.comp=CI.interfaceid   
    inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and CI.componentid=CO.componentid  and CO.machineid=M.machineid  
	inner join downcodeinformation D on autodata.dcode=D.interfaceid
	inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
	where autodata.datatype=2 AND 
	(
	(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
	OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
	OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
	OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
	) 
	group by S.Plantid,S.Machineid,D.Catagory,D.downid,CO.Componentid,CO.Operationno,CO.Cycletime

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
	BEGIN

		UPDATE #cycleLoss set Downtime =isnull(Downtime,0) - isNull(TT.DPDT ,0)
		FROM(
			SELECT S.Plantid,S.Machineid,D.Catagory,D.downid,CO.Componentid,CO.Operationno, SUM
			   (CASE
				WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (autodata.loadunload)
				WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as DPDT
			FROM #T_autodata AutoData CROSS JOIN PlannedDownTimes T 
			inner join machineinformation M ON autodata.mc = M.InterfaceID 
			Inner join componentinformation CI on autodata.comp=CI.interfaceid   
			inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and CI.componentid=CO.componentid  and CO.machineid=M.machineid  
			left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
			inner join downcodeinformation D on autodata.dcode=D.interfaceid
			inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
			inner join (Select distinct Plantid,machineid from #Shifttemp) S on S.machineid=M.machineid
			WHERE autodata.DataType=2  AND T.Machine=M.Machineid and
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				) AND
				(
				(T.StartTime>=@StartTime  and  T.EndTime<=@EndTime)
				OR (T.StartTime<@StartTime and  T.EndTime>@StartTime and T.EndTime<=@EndTime)
				OR (T.StartTime>=@StartTime  and T.StartTime<@EndTime  and T.EndTime>@EndTime)
				OR (T.StartTime<@StartTime and T.EndTime>@EndTime )) 
		group by S.Plantid,S.Machineid,D.Catagory,D.downid,CO.Componentid,CO.Operationno
		) as TT INNER JOIN #cycleLoss ON TT.Catagory = #cycleLoss.downCategory and TT.downid=#cycleLoss.Downid and TT.Machineid=#cycleLoss.Machineid and TT.componentid=#cycleLoss.componentid and TT.operationno=#cycleLoss.operationno

	END


	select Plantid,Machineid,Componentid,Operationno,StdCycletime,sum(Downtime)as downtime into #dayLossSummary from #CycleLoss
	group by Plantid,Machineid,Componentid,Operationno,StdCycletime



	Select Isnull(Round(sum(T.dayloss),0),0) as CyclelossFortheday into #dayLossSummary1 from (
	select Plantid,Machineid,Componentid,Operationno,sum(Downtime)/sum(StdCycletime) as dayloss from #dayLossSummary where downtime>0
	group by Plantid,Machineid,Componentid,Operationno)T

	select #TimeLossForDay.Downtime as TimeLossFortheday,#dayLossSummary1.CyclelossFortheday from #TimeLossForDay,#dayLossSummary1 
	------------------------- OUTPUT5 : To Get Time Loss and CycleLoss ForDay -----------------------------------


	------------------------- OUTPUT6 : To Get Time Loss and CycleLoss ForShift -----------------------------------
	delete from #CurrentShift
	delete from #Loss
	delete from #CycleLoss

	Insert into #CurrentShift
	exec [dbo].[s_GetCurrentShiftTime] @Startdate,''

	select @StartTime = Starttime from #CurrentShift
	Select @Endtime = Endtime from #CurrentShift


	Insert into #Loss(Plantid,Machineid,downCategory,Downid,Downtime)
	select S.Plantid,S.Machineid,D.Catagory,D.downid,sum(
	CASE
	WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
	WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
	WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
	WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
	END
	)AS down
	from #T_autodata autodata 
	inner join machineinformation M ON autodata.mc = M.InterfaceID 
	inner join (Select distinct Plantid,machineid from #Shifttemp) S on S.machineid=M.machineid
	left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
	inner join downcodeinformation D on autodata.dcode=D.interfaceid
	inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
	where autodata.datatype=2 AND 
	(
	(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
	OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
	OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
	OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
	) 
	group by S.Plantid,S.Machineid,D.Catagory,D.downid

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
	BEGIN

		UPDATE #Loss set Downtime =isnull(Downtime,0) - isNull(TT.DPDT ,0)
		FROM(
			SELECT S.Plantid,S.Machineid,D.Catagory,D.downid, SUM
			   (CASE
				WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (autodata.loadunload)
				WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as DPDT
			FROM #T_autodata AutoData CROSS JOIN PlannedDownTimes T 
			inner join machineinformation M ON autodata.mc = M.InterfaceID 
			left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
			inner join downcodeinformation D on autodata.dcode=D.interfaceid
			inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
			inner join (Select distinct Plantid,machineid from #Shifttemp) S on S.machineid=M.machineid
			WHERE autodata.DataType=2  AND T.Machine=M.Machineid and
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				) AND
				(
				(T.StartTime>=@StartTime  and  T.EndTime<=@EndTime)
				OR (T.StartTime<@StartTime and  T.EndTime>@StartTime and T.EndTime<=@EndTime)
				OR (T.StartTime>=@StartTime  and T.StartTime<@EndTime  and T.EndTime>@EndTime)
				OR (T.StartTime<@StartTime and T.EndTime>@EndTime )) 
		group by S.Plantid,S.Machineid,D.Catagory,D.downid
		) as TT INNER JOIN #Loss ON TT.Catagory = #Loss.downCategory and TT.downid=#Loss.Downid and TT.Machineid=#Loss.Machineid

	END

	select Round([dbo].[f_FormatTime](sum(#Loss.Downtime),'mm'),0) as downtime into #TimeLossForShift from #Loss where downtime>0


	Insert into #cycleLoss(Plantid,Machineid,Componentid,Operationno,StdCycletime,downCategory,Downid,Downtime)
	select S.Plantid,S.Machineid,CO.Componentid,CO.Operationno,CO.Cycletime,D.Catagory,D.downid,sum(
	CASE
	WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  autodata.loadunload
	WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
	WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
	WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
	END
	)AS down
	from #T_autodata autodata 
	inner join machineinformation M ON autodata.mc = M.InterfaceID 
	inner join (Select distinct Plantid,machineid from #Shifttemp) S on S.machineid=M.machineid
	left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
    Inner join componentinformation CI on autodata.comp=CI.interfaceid   
    inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and CI.componentid=CO.componentid  and CO.machineid=M.machineid  
	inner join downcodeinformation D on autodata.dcode=D.interfaceid
	inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
	where autodata.datatype=2 AND 
	(
	(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
	OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
	OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
	OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
	) 
	group by S.Plantid,S.Machineid,D.Catagory,D.downid,CO.Componentid,CO.Operationno,CO.Cycletime

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
	BEGIN

		UPDATE #cycleLoss set Downtime =isnull(Downtime,0) - isNull(TT.DPDT ,0)
		FROM(
			SELECT S.Plantid,S.Machineid,D.Catagory,D.downid,CO.Componentid,CO.Operationno, SUM
			   (CASE
				WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (autodata.loadunload)
				WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as DPDT
			FROM #T_autodata AutoData CROSS JOIN PlannedDownTimes T 
			inner join machineinformation M ON autodata.mc = M.InterfaceID 
			Inner join componentinformation CI on autodata.comp=CI.interfaceid   
			inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and CI.componentid=CO.componentid  and CO.machineid=M.machineid  
			left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
			inner join downcodeinformation D on autodata.dcode=D.interfaceid
			inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
			inner join (Select distinct Plantid,machineid from #Shifttemp) S on S.machineid=M.machineid
			WHERE autodata.DataType=2  AND T.Machine=M.Machineid and
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				) AND
				(
				(T.StartTime>=@StartTime  and  T.EndTime<=@EndTime)
				OR (T.StartTime<@StartTime and  T.EndTime>@StartTime and T.EndTime<=@EndTime)
				OR (T.StartTime>=@StartTime  and T.StartTime<@EndTime  and T.EndTime>@EndTime)
				OR (T.StartTime<@StartTime and T.EndTime>@EndTime )) 
		group by S.Plantid,S.Machineid,D.Catagory,D.downid,CO.Componentid,CO.Operationno
		) as TT INNER JOIN #cycleLoss ON TT.Catagory = #cycleLoss.downCategory and TT.downid=#cycleLoss.Downid and TT.Machineid=#cycleLoss.Machineid and TT.componentid=#cycleLoss.componentid and TT.operationno=#cycleLoss.operationno

	END


	select Plantid,Machineid,Componentid,Operationno,StdCycletime,sum(Downtime)as downtime into #ShiftLossSummary from #CycleLoss
	group by Plantid,Machineid,Componentid,Operationno,StdCycletime


	Select Isnull(Round(sum(T.shiftloss),0),0) as CyclelossFortheshift into #ShiftLossSummary1 from (
	select Plantid,Machineid,Componentid,Operationno,sum(Downtime)/sum(StdCycletime) as shiftloss from #ShiftLossSummary where downtime>0
	group by Plantid,Machineid,Componentid,Operationno)T

	select #TimeLossForShift.Downtime as TimeLossFortheShift,#ShiftLossSummary1.CyclelossFortheshift from #TimeLossForShift,#ShiftLossSummary1
	------------------------- OUTPUT6 : To Get Time Loss and CycleLoss ForShift -----------------------------------

	Select Round(Bekido,2) as Bekido,Round(chokko,2) as chokko from #BekidoChokko

end
