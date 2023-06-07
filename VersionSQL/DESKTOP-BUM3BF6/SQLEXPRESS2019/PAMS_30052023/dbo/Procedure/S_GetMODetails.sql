/****** Object:  Procedure [dbo].[S_GetMODetails]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0374 - SwathiKS - 03/Feb/2014 :: To include New Column "Actual Count" at Machine-Component-WorkorderNumber Level.
--DR0344 - SwathiKS - 24/Apr/2014 :: To Change MORunningtime Calculation.
--ER0403 - SwathiKS - 31/Dec/2014 :: To include First MO arrival time in Report.i.e take minimum Starttime from autodata for that MO.
--[dbo].[S_GetMODetails] '2014-04-14 06:00:00 AM','2014-04-20 06:00:00 AM','','SP-15_A',''


CREATE Procedure [dbo].[S_GetMODetails]
@Starttime datetime,
@Endtime datetime,
@PlantID nvarchar(50),
@Machineid nvarchar(50),
@Param nvarchar(50)
WITH RECOMPILE
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

create table #MCOInfo
(
	CellNo nvarchar(50),
	MCNo nvarchar(50),
	McInterface nvarchar(50),
	CompInterface nvarchar(50),
	MONo nvarchar(50),
	ItemCode nvarchar(50),
	EmployeeName nvarchar(50)
)

create table #MOInfo
(
	Sdate datetime,--ER0403
	PDate Datetime,
	CellNo nvarchar(50),
	MCNo nvarchar(50),
	McInterface nvarchar(50),
	CompInterface nvarchar(50),
	MONo nvarchar(50),
	ItemCode nvarchar(50),
	EmployeeName nvarchar(50),
	MOQuantity int,
	MOSettingTime float,
	MORunningTime float,
	TotalCycletime float,
	AllowenceTime float,
	ActualTime float,
	Diff float,
	Eff float,
	Reason1 nvarchar(50),
	Reason2 nvarchar(50),
	Remarks nvarchar(50),
	Remarks1 nvarchar(100),
	Category nvarchar(50),
	ActualCount float --ER0374
)

CREATE TABLE #T_autodataforDown
(
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
	[WorkOrderNumber] [nvarchar](50) NULL,
	id  bigint not null
)

ALTER TABLE #T_autodataforDown

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime ASC
)ON [PRIMARY]

CREATE TABLE #Runtime
(
	MachineID nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	Component nvarchar(50) NOT NULL,
	msttime datetime,
    ndtime datetime, 
    runtime int,   
    batchid int,
    autodataid bigint,
	autodataWO nvarchar(50)
)

CREATE TABLE #FinalRuntime
(

	MachineID nvarchar(50) NOT NULL,
	Component nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	msttime datetime,
    ndtime datetime,
    runtime int,   
    batchid int,
	autodataWO nvarchar(50),
	components float --ER0374
)

Create table #MachineLevelDown
(
	MachineInterface nvarchar(50),
	Machineid nvarchar(50),
	DownID nvarchar(50),
	DownTime nvarchar(50) ,
	PDT int 
)

Create table #PlannedDownTimes
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	StartTime DateTime,
	EndTime DateTime
)


CREATE TABLE #T_autodata
(
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
	[msttime] [datetime] NULL,
	[PartsCount] [int] NULL ,
	id  bigint not null,
	[WorkOrderNumber] [nvarchar](50) NULL
)

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime,ndtime ASC
)ON [PRIMARY]


declare @Downcategory as nvarchar(50)
Declare @strsql as nvarchar(4000)
Declare @strMachine as nvarchar(255)
Declare @strPlantID as nvarchar(255)
SELECT @strPlantID = ''
SELECT @strMachine = ''
Select @strsql = ''

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime
Select @T_ST=convert(nvarchar(25),@StartTime,120)
Select @T_ED=convert(nvarchar(25),@EndTime,120)

Declare @T_START AS Datetime 
Declare @T_END AS Datetime 

Select @T_START=dbo.f_GetLogicalDay(@StartTime,'start')
Select @T_END=dbo.f_GetLogicalDay(@EndTime,'End')


Select @Downcategory = Valueintext from shopdefaults where Parameter='Ignore_DownCategory_FromRuntime'


if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
end

if isnull(@PlantID,'')<> ''
Begin

	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id,WorkOrderNumber'
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_START,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_END,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_START,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_END,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_START,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_START,120)+'''
				 and ndtime<='''+convert(nvarchar(25),@T_END,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_START,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_END,120)+''' and sttime<'''+convert(nvarchar(25),@T_END,120)+''' ) )'
print @strsql
exec (@strsql)


Select @strsql = 'Insert into #MCOInfo(CellNo,MCNo,MONo,ItemCode,EmployeeName,McInterface,CompInterface)'
Select @strsql = @strsql + ' select Distinct P.PlantCode,Machineinformation.Machineid,MD.MONumber,CI.Componentid,E.employeeid,Machineinformation.Interfaceid,CI.Interfaceid
 from #T_autodata A
inner join Machineinformation on A.mc=Machineinformation.interfaceid 
inner join Componentinformation CI on A.comp=CI.interfaceid  
inner join Componentoperationpricing COP on A.opn=COP.interfaceid  
and Machineinformation.Machineid=COP.Machineid and CI.Componentid=COP.Componentid  
inner join Employeeinformation E on A.opr=E.interfaceid
inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid
inner join PlantInformation P on P.plantid=Plantmachine.plantid
inner join MoDetails MD on A.mc=MD.Machineinterface and A.workorderNumber=MD.MONumber' 
Select @strsql = @strsql + ' where ((A.sttime>='''+ convert(nvarchar(25),@StartTime,120)+''' and A.ndtime<='''+ convert(nvarchar(25),@EndTime,120)+''') OR (
A.sttime<'''+ convert(nvarchar(25),@StartTime,120)+''' and A.ndtime>'''+ convert(nvarchar(25),@StartTime,120)+''' and A.ndtime<='''+ convert(nvarchar(25),@EndTime,120)+''' )) '
Select @strsql = @strsql + @strMachine + @strPlantID
PRINT @strSql
EXEC(@strSql)

If NOT Exists(Select Count(*) from #MCOInfo)
Begin
	Return;
End

SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT Machine,InterfaceID,
		CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
		CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
	FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
	WHERE PDTstatus =1 and(
	(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
	OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
SET @strSql =  @strSql +  ' ORDER BY Machine,StartTime'
EXEC(@strSql)

Select @strsql=''
select @strsql ='insert into #T_autodataforDown '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, WorkOrderNumber,id'
select @strsql = @strsql + ' from #T_autodata autodata where (datatype=1) and (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
				 and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)

Select @strsql=''
select @strsql ='insert into #T_autodataforDown '
select @strsql = @strsql + 'SELECT A1.mc, A1.comp, A1.opn, A1.opr, A1.dcode,A1.sttime,'
 select @strsql = @strsql + 'A1.ndtime, A1.datatype, A1.cycletime, A1.loadunload, A1.msttime, A1.WorkOrderNumber,A1.id'
select @strsql = @strsql + ' from #T_autodata A1 where A1.datatype=2 and
(( A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
 ( A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
 (A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) or
 (A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and A1.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
and NOT EXISTS ( select * from #T_autodata A2 where  A2.datatype=1 and  ((  A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) 
OR (A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and  A2.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
and A2.sttime<=A1.sttime and A2.ndtime>A1.ndtime and A1.mc=A2.mc)'
print @strsql
exec (@strsql)

declare @CurMachineID as Nvarchar(50)
declare @CurComponentID as Nvarchar(50)
Declare @CMONO as Nvarchar(50)
declare @CurOperatorID as Nvarchar(50)

declare @CurMachineID_prev as Nvarchar(50)
declare @CurComponentID_prev as Nvarchar(50)
Declare @CMONO_prev as Nvarchar(50)
declare @CurOperatorID_prev as Nvarchar(50)

DECLARE @AllOprAtMachineLevel AS NVARCHAR(1000)
Declare TmpCursorsec Cursor For SELECT MONo,MCNo,ItemCode,EmployeeName from #MCOInfo order by MCNo,ItemCode,MONo

OPEN  TmpCursorsec
FETCH NEXT FROM TmpCursorsec INTO @CMONO,@CurMachineID,@CurComponentID,@CurOperatorID

set @CurMachineID_prev=@CurMachineID
set @CMONO_prev=@CMONO
set @CurComponentID_prev = @CurComponentID
set @CurOperatorID_prev=@CurOperatorID

set @AllOprAtMachineLevel=''
WHILE @@FETCH_STATUS=0
BEGIN

if @CurMachineID_prev=@CurMachineID and @CMONO_prev=@CMONO and @CurComponentID_prev = @CurComponentID and @CurOperatorID_prev<>@CurOperatorID
begin
	SELECT @AllOprAtMachineLevel=@CurOperatorID_prev + ' ; ' + @CurOperatorID
	update #MCOInfo set Employeename=@AllOprAtMachineLevel where MCNo=@CurMachineID and MONo =@CMONO and Itemcode=@CurComponentID
End

set @AllOprAtMachineLevel=''
set @CurMachineID_prev=@CurMachineID	
set @CMONO_prev=@CMONO
set @CurComponentID_prev = @CurComponentID
set @CurOperatorID_prev=@CurOperatorID

FETCH NEXT FROM TmpCursorsec INTO @CMONO,@CurMachineID,@CurComponentID,@CurOperatorID
END
close TmpCursorsec
deallocate TmpCursorsec


Insert into #MOInfo(CellNo,MCNo,MONo,ItemCode,EmployeeName,McInterface,CompInterface)
select Distinct CellNo,MCNo,MONo,ItemCode,EmployeeName,McInterface,CompInterface from #MCOInfo

--Update #MOInfo set Pdate = T1.LastArrival from  --ER0403
Update #MOInfo set Pdate = T1.LastArrival,SDate=T1.FirstArrival from  --ER0403
(Select Mc,Comp,WorkOrderNumber,Min(sttime) as FirstArrival,Max(ndtime) as LastArrival from #T_autodata A
inner join #MOInfo M on A.mc=M.McInterface and A.comp=M.CompInterface and A.WorkOrderNumber=M.MONo
where A.ndtime>@starttime and A.ndtime<=@Endtime
Group by Mc,Comp,WorkOrderNumber)T1
inner join #MOInfo M on T1.mc=M.McInterface and T1.comp=M.CompInterface and T1.WorkOrderNumber=M.MONo


Update #MOInfo Set MOQuantity = Isnull(MOQuantity,0) + Isnull(T1.Qty,0) from
(Select MODetails.Machineinterface,MODetails.MONumber,MODetails.MOQty as Qty from MODetails
inner join #MOInfo on MODetails.Machineinterface=#MOInfo.McInterface and MODetails.MONumber=#MOInfo.MONo
)T1 inner join #MOInfo on T1.Machineinterface=#MOInfo.McInterface and T1.MONumber=#MOInfo.MONo


Update #MOInfo Set MOSettingTime = Isnull(MOSettingTime,0) + Isnull(T1.Settime,0) from
(Select MCNo,ItemCode,isnull(StdSetupTime,0) as Settime from Componentoperationpricing CO
inner join #MOInfo M on M.MCNo=CO.Machineid and M.ItemCode=CO.Componentid
)T1 inner join #MOInfo on T1.MCNo=#MOInfo.MCNo and T1.ItemCode=#MOInfo.ItemCode


/**  DR0344 From Here
Update #MOInfo set MORunningTime = Isnull(MORunningTime,0) + isnull(T1.Runtime,0) from
(Select MCNo,ItemCode,isnull(Cycletime,0)* MOQuantity  as Runtime from Componentoperationpricing CO
inner join #MOInfo M on M.MCNo=CO.Machineid and M.ItemCode=CO.Componentid
)T1 inner join #MOInfo on T1.MCNo=#MOInfo.MCNo and T1.ItemCode=#MOInfo.ItemCode
DR0344 Till Here **/

--DR0344 Added From Here
Update #MOInfo set MORunningTime = Isnull(MORunningTime,0) + isnull(T1.Runtime,0) from
(Select MCNo,ItemCode,isnull(Cycletime,0) as Runtime from Componentoperationpricing CO
inner join #MOInfo M on M.MCNo=CO.Machineid and M.ItemCode=CO.Componentid
)T1 inner join #MOInfo on T1.MCNo=#MOInfo.MCNo and T1.ItemCode=#MOInfo.ItemCode

Update #MOInfo set MORunningTime = Isnull(MORunningTime,0)*MOQuantity
--DR0344 Added Till Here

Update #MOInfo set TotalCycletime = [MOSettingTime] + [MORunningTime]

insert into #Runtime(MachineID,machineinterface,Component,Compinterface,msttime,ndtime,batchid,runtime,autodataid,autodataWO)
SELECT #MOInfo.MCNo, #MOInfo.McInterface,#MOInfo.ItemCode, #MOInfo.CompInterface,
Case when autodata.msttime< @Starttime then @Starttime else autodata.msttime end, 
Case when autodata.ndtime> @Endtime then @Endtime else autodata.ndtime end,
0,0,autodata.id,autodata.workordernumber FROM #T_autodataforDown  autodata
INNER JOIN #MOInfo ON autodata.mc = #MOInfo.McInterface 
and autodata.comp=#MOInfo.CompInterface and autodata.WorkOrderNumber=#MOInfo.MONo
WHERE ((autodata.msttime >= @Starttime  AND autodata.ndtime <= @Endtime)
OR ( autodata.msttime < @Starttime  AND autodata.ndtime <= @Endtime AND autodata.ndtime >@Starttime )
OR ( autodata.msttime >= @Starttime   AND autodata.msttime <@Endtime AND autodata.ndtime > @Endtime )
OR ( autodata.msttime < @Starttime  AND autodata.ndtime > @Endtime ))
order by autodata.msttime


declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@WO_prev nvarchar(50)
declare @mc nvarchar(50),@comp nvarchar(50),@WO nvarchar(50),@id nvarchar(50)
declare @batchid int
Declare @autodataid bigint,@autodataid_prev bigint
declare @setupcursor  cursor

set @setupcursor=cursor for
select autodataid,MachineID,Component,autodataWO  from #Runtime order by machineid,msttime
open @setupcursor

fetch next from @setupcursor into @autodataid,@mc,@comp,@WO

set @autodataid_prev=@autodataid
set @mc_prev = @mc
set @comp_prev = @comp
set @WO_prev = @WO
set @batchid =1

while @@fetch_status = 0
begin
If @mc_prev=@mc and @comp_prev=@comp and @WO_prev = @WO
	begin		
		update #Runtime set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and autodataWO=@WO
		print @batchid
	end
	else
	begin	
		  set @batchid = @batchid+1        
		  update #Runtime set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and autodataWO=@WO
		  set @autodataid_prev=@autodataid 
		  set @mc_prev=@mc 	
		  set @comp_prev=@comp
		  set @WO_prev = @WO
	end	
	fetch next from @setupcursor into @autodataid,@mc,@comp,@WO
	
end
close @setupcursor
deallocate @setupcursor



insert into #FinalRuntime (MachineID,Component,machineinterface,Compinterface,Runtime,batchid,msttime,ndtime,autodatawo) 
Select MachineID,Component,machineinterface,Compinterface,datediff(s,min(msttime),max(ndtime)),batchid,min(msttime),max(ndtime),autodatawo from #Runtime
group by MachineID,Component,batchid,machineinterface,Compinterface,autodatawo order by batchid 


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN

Update #FinalRuntime set Runtime = Isnull(Runtime,0) - Isnull(T1.MLDown,0) from
(
	select T.machineinterface,T.Compinterface,T.autodatawo,SUM
	    (CASE
		WHEN (autodata.sttime >= T.msttime  AND autodata.ndtime <=T.ndtime)  THEN autodata.loadunload
		WHEN ( autodata.sttime < T.msttime  AND autodata.ndtime <= T.ndtime  AND autodata.ndtime > T.msttime ) THEN DateDiff(second,T.msttime,autodata.ndtime)
		WHEN ( autodata.sttime >= T.msttime   AND autodata.sttime <T.ndtime  AND autodata.ndtime > T.ndtime  ) THEN DateDiff(second,autodata.sttime,T.ndtime )
		WHEN ( autodata.sttime < T.msttime  AND autodata.ndtime > T.ndtime ) THEN DateDiff(second,T.msttime,T.ndtime )
		END ) as MLDown
	from #T_autodata autodata  
	INNER JOIN #FinalRuntime T on T.machineinterface=Autodata.mc and T.Compinterface=Autodata.comp
	and T.autodatawo = Autodata.Workordernumber
	INNER JOIN DownCodeInformation D ON AutoData.DCode = D.InterfaceID
	INNER JOIN DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
	WHERE autodata.DataType=2 AND DCI.DownCategory = @Downcategory and
	((autodata.sttime >= T.msttime  AND autodata.ndtime <=T.ndtime)
	OR ( autodata.sttime < T.msttime  AND autodata.ndtime <= T.ndtime AND autodata.ndtime > T.msttime )
	OR ( autodata.sttime >= T.msttime   AND autodata.sttime <T.ndtime AND autodata.ndtime > T.ndtime )
	OR ( autodata.sttime < T.msttime  AND autodata.ndtime > T.ndtime))
	group by T.machineinterface,T.Compinterface,T.autodatawo
)T1 inner join  #FinalRuntime on  T1.machineinterface=#FinalRuntime.machineinterface and T1.Compinterface=#FinalRuntime.Compinterface
and T1.autodatawo=#FinalRuntime.autodatawo 

END




--ER0374 Added From Here
UPDATE #FinalRuntime SET components = ISNULL(components,0) + ISNULL(t1.comp1,0)
From
(
	  Select mc,comp,Workordernumber,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1
		   From 
			(
			select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn,Workordernumber from #T_autodata autodata
			where (autodata.ndtime>@starttime) and (autodata.ndtime<=@Endtime) and (autodata.datatype=1)
			Group By mc,comp,opn,Workordernumber
			) as T1	Inner join componentinformation C on T1.Comp = C.interfaceid
	Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
	inner join machineinformation on machineinformation.machineid =O.machineid
	and T1.mc=machineinformation.interfaceid
	GROUP BY mc,comp,Workordernumber
) As T1 inner join  #FinalRuntime on  T1.mc=#FinalRuntime.machineinterface and T1.comp=#FinalRuntime.Compinterface
and T1.Workordernumber=#FinalRuntime.autodatawo 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #FinalRuntime SET components = ISNULL(components,0) - ISNULL(T1.comp1,0) from 
	 (
		select mc,comp,workordernumber,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp1 From 
			( 
			select mc,workordernumber,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn from #T_autodata autodata
			CROSS JOIN #PlannedDownTimes P
			WHERE autodata.DataType=1 And P.MachineInterface = autodata.mc
			AND (autodata.ndtime > P.StartTime  AND autodata.ndtime <=P.EndTime)
			AND (autodata.ndtime > @starttime  AND autodata.ndtime <=@Endtime)
		    Group by mc,comp,opn,workordernumber
		) as T1
	Inner join Machineinformation M on M.interfaceID = T1.mc
	Inner join componentinformation C on T1.Comp=C.interfaceid
	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
	GROUP BY MC,comp,workordernumber
	) as T1 inner join  #FinalRuntime on  T1.mc=#FinalRuntime.machineinterface and T1.comp=#FinalRuntime.Compinterface
and T1.Workordernumber=#FinalRuntime.autodatawo 
END

Update #MOInfo Set ActualCount = Isnull(ActualCount,0) + isnull(T1.components,0) from
(Select machineinterface,Compinterface,autodatawo,components from #FinalRuntime)T1
inner join #MOInfo M on T1.machineinterface=M.McInterface and T1.Compinterface=M.CompInterface and T1.autodatawo=M.MONo

--ER0374 Added Till here



Update #MOInfo Set ActualTime = Isnull(ActualTime,0) + isnull(T1.Runtime,0) from
(Select machineinterface,Compinterface,autodatawo,sum(Runtime) as Runtime from #FinalRuntime
group by machineinterface,Compinterface,autodatawo)T1
inner join #MOInfo M on T1.machineinterface=M.McInterface and T1.Compinterface=M.CompInterface and T1.autodatawo=M.MONo



Insert into #MachineLevelDown(MachineInterface,Machineid,DownTime,DownID)
select D1.McInterface,D1.MCNo,sum
(
CASE
	WHEN  autodata.msttime>=@Starttime  and  autodata.ndtime<=@Endtime  THEN  autodata.loadunload
	WHEN (autodata.msttime<@Starttime and  autodata.ndtime>@Starttime and autodata.ndtime<=@Endtime)  THEN DateDiff(second, @Starttime, ndtime)
	WHEN (autodata.msttime>=@Starttime  and autodata.msttime<@Endtime  and autodata.ndtime>@Endtime)  THEN DateDiff(second, mstTime, @Endtime)
	WHEN autodata.msttime<@Starttime and autodata.ndtime>@Endtime   THEN DateDiff(second, @Starttime, @Endtime)
END
)AS down,downcodeinformation.DownID
from #T_autodata autodata 
inner join (Select distinct McInterface,MCNo from #MOInfo) D1 on autodata.mc = D1.McInterface 
inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
where autodata.datatype=2  and
(
(autodata.msttime>=@Starttime  and  autodata.ndtime<=@Endtime)
OR (autodata.msttime<@Starttime and  autodata.ndtime>@Starttime and autodata.ndtime<=@Endtime)
OR (autodata.msttime>=@Starttime  and autodata.msttime<@Endtime  and autodata.ndtime>@Endtime)
OR (autodata.msttime<@Starttime and autodata.ndtime>@Endtime )
) 
group by D1.McInterface,downcodeinformation.DownID,D1.MCNo



If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	UPDATE #MachineLevelDown set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,autodata.sttime,T.EndTime)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,T.StartTime,T.EndTime)
			END ) as PPDT,downcodeinformation.downid as dcode
		FROM #T_autodata AutoData inner join (Select distinct McInterface,MCNo from #MOInfo) D1 on autodata.mc = D1.McInterface 
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		CROSS jOIN #PlannedDownTimes T
		WHERE autodata.DataType=2 AND T.Machineid=D1.MCNo AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
		group by autodata.MC,downcodeinformation.downid
	) as TT INNER JOIN #MachineLevelDown ON TT.mc = #MachineLevelDown.MachineInterface And TT.dcode = #MachineLevelDown.DownID
END

declare @machine nvarchar(50)
declare @GetDowntime cursor
set @getdowntime = Cursor for
Select machineinterface from
(select distinct machineinterface,machineid from #MachineLevelDown)T order by T.machineid
open @getdowntime

Fetch next from @getdowntime into @machine

While @@Fetch_status = 0
Begin

		Update #MOInfo set Reason1 = isnull(Reason1,'') + isnull(TT.Dreason1,'') from 
		(
		select top 1 Machineinterface as mc,DownID + '-' + dbo.f_formattime(Downtime,'hh:mm') as Dreason1  from #MachineLevelDown
		where Downtime>0 and machineinterface=@machine Order by dbo.f_formattime(Downtime,'hh:mm') desc
		) as TT INNER JOIN #MOInfo ON TT.mc = #MOInfo.McInterface 

		Update #MOInfo set Reason2 = isnull(Reason2,'') + isnull(TT.Dreason2,'') from 
		(
		select top 1 M.Machineinterface as mc,M.DownID + '-' + dbo.f_formattime(M.Downtime,'hh:mm') as Dreason2  from #MachineLevelDown M
		INNER JOIN #MOInfo ON M.Machineinterface = #MOInfo.McInterface 
		where M.Downtime>0 and M.DownID + '-' + dbo.f_formattime(M.Downtime,'hh:mm')<>#MOInfo.Reason1 and M.machineinterface=@machine 
		Order by dbo.f_formattime(M.Downtime,'hh:mm') desc
		) as TT INNER JOIN #MOInfo ON TT.mc = #MOInfo.McInterface 

		Fetch next from @getdowntime into @machine

end

CLOSE @getdowntime;
DEALLOCATE @getdowntime;



Update #MOInfo set Remarks1 = Isnull(Remarks1,'') + isnull(T.Reason,'')
from(Select McInterface,
Case when isnull(Reason2,'a')<> 'a' then Reason1 + ',' + Reason2 else Reason1 end as Reason from #MOInfo)T
inner join #MOInfo on  T.McInterface = #MOInfo.McInterface 


--ER0374
--Select Pdate,CellNo,MCNo,MONo,ItemCode,EmployeeName,MOQuantity,dbo.f_FormatTime(MOSettingTime,'hh') as MOSettingTime,dbo.f_FormatTime(MORunningTime,'hh') as MORunningTime,dbo.f_FormatTime(TotalCycletime,'hh') as TotalCycletime,
--dbo.f_FormatTime(Isnull(ActualTime,0),'hh') as ActualTime,Remarks1 from #MOInfo Order by CellNo,MCNo,Pdate
--ER0403 
--Select Pdate,CellNo,MCNo,MONo,ItemCode,EmployeeName,ActualCount,MOQuantity,dbo.f_FormatTime(MOSettingTime,'hh') as MOSettingTime,dbo.f_FormatTime(MORunningTime,'hh') as MORunningTime,dbo.f_FormatTime(TotalCycletime,'hh') as TotalCycletime,
--dbo.f_FormatTime(Isnull(ActualTime,0),'hh') as ActualTime,Remarks1 from #MOInfo Order by CellNo,MCNo,Pdate
Select Sdate,Pdate,CellNo,MCNo,MONo,ItemCode,EmployeeName,ActualCount,MOQuantity,dbo.f_FormatTime(MOSettingTime,'hh') as MOSettingTime,dbo.f_FormatTime(MORunningTime,'hh') as MORunningTime,dbo.f_FormatTime(TotalCycletime,'hh') as TotalCycletime,
dbo.f_FormatTime(Isnull(ActualTime,0),'hh') as ActualTime,Remarks1 from #MOInfo Order by CellNo,MCNo,Pdate
--ER0403
--ER0374

end
