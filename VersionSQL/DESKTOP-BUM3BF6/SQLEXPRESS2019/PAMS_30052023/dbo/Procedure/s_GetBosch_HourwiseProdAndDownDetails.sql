/****** Object:  Procedure [dbo].[s_GetBosch_HourwiseProdAndDownDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--s_GetBosch_HourwiseProdAndDownDetails '2016-06-15','','ACE VTL-01','PartIDInfo'
--select * from machineinformation
--[dbo].[s_GetBosch_HourwiseProdAndDownDetails] '2016-0-20','','Gehring Valve Spool','PartIDInfo'
--[dbo].[s_GetBosch_HourwiseProdAndDownDetails] '2016-09-15','','Gehring Valve Spool','HourwiseCount'
--[dbo].[s_GetBosch_HourwiseProdAndDownDetails] '2016-09-15','','Gehring Valve Spool','HourwiseDown'

CREATE     PROCEDURE [dbo].[s_GetBosch_HourwiseProdAndDownDetails]
	@Startdate datetime,
	@SHIFTNAME nvarchar(50)='',
	@Machineid nvarchar(50),
	@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN
SET ARITHABORT ON
Create Table #HourlyData  
 ( 
	SLNO int,
	Machineid nvarchar(50),   
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	Shiftstart datetime,
	ShiftEnd datetime,
	HourName nvarchar(50),
	HourID int,
	FromTime datetime,
	ToTime Datetime,
	TypeID nvarchar(50),
	Actual float,  
	Target float Default 0,
	kwh float,
	Maxenergy float,
	Minenergy float,
	Employeeid nvarchar(500),
	Employeename nvarchar(500),
	ScrapLoss float,
	RepairLoss float,
	PDTStatus int
 ) 

CREATE TABLE #Target  
(
	MachineID nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	OpnInterface nvarchar(50),
	msttime datetime,
    ndtime datetime,
	FromTm datetime,
	ToTm datetime,   
    runtime int,   
    batchid int,
	Target float Default 0,
	autodataid bigint
)

CREATE TABLE #FinalTarget  
(

	MachineID nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	OpnInterface nvarchar(50),
	msttime datetime,
    ndtime datetime,
	FromTm datetime,
	ToTm datetime,   
    runtime int,   
    batchid int,
	Target float Default 0,
	autodataid bigint

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
	[PartsCount] [int] NULL ,
	id  bigint not null
)

ALTER TABLE #T_autodataforDown

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime ASC
)ON [PRIMARY]

Create table #Downcategory
(
	IDD int,
	Slno int identity(1,1) NOT NULL,
	Machineid nvarchar(50),   
	HourID int,
	ShiftID int,
	FromTime datetime,
	ToTime Datetime,
	Downtime float, 
	Downcategory nvarchar(50)
)

Create table #PredefinedDowncategory
(
	Slno int identity(1,1) NOT NULL,
	Machineid nvarchar(50),   
	HourID int,
	ShiftID int,
	FromTime datetime,
	ToTime Datetime,
	Downtime float, 
	OrgLoss float,
	PlannedLoss float,
	NotPlanned float
)


Create table #GetShiftTime
(
dDate DateTime,
ShiftName NVarChar(50),
StartTime DateTime,
EndTime DateTime
)

Create table #ShiftTime
(
dDate DateTime ,
ShiftName NVarChar(50),
Shiftid int,
StartTime DateTime,
EndTime DateTime
)


declare @stdate as nvarchar(50) 	
Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime
Declare @strsql nvarchar(4000)
Declare @strMachine as nvarchar(255)

if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
end

Select @Startdate = dbo.f_GetLogicalDayend(@Startdate)

Declare @shiftid as smallint
Declare @preday as datetime
Declare @gettime as datetime
Declare @gettime1 as datetime
Declare @sttime_1 as datetime
Declare @ndtime_1 as datetime
Declare @ShiftStartTime as datetime
declare @ShiftEndTime as datetime

select @gettime1=(Select @Startdate)
Select @gettime=(select dbo.f_GetLogicalDaystart(@Startdate))
Select @preday=(select dateadd(day,-1,@gettime))
Select @shiftid=(Select top 1 shiftid from shiftdetails where running=1 order by shiftid desc)
Select @shiftname=(Select ShiftName from shiftdetails where running=1 and shiftid=@shiftid)
insert into #GetShiftTime Exec s_GetShiftTime  @preday,@shiftname

insert into #GetShiftTime Exec s_GetShiftTime @gettime,''

Declare Finder  cursor for 
Select StartTime,Endtime from #GetShiftTime order by StartTime
Open Finder
FETCH NEXT FROM Finder INTO @sttime_1,@ndtime_1
while (@@fetch_status= 0)
Begin

If (@gettime1>=@sttime_1 and @gettime1>=@ndtime_1)
begin

select @ShiftStartTime=@sttime_1
Select @ShiftEndTime=@ndtime_1
Print @ShiftStartTime
print @ShiftEndTime
End

FETCH NEXT FROM Finder INTO @sttime_1,@ndtime_1

End
Close Finder
Deallocate Finder


Insert into #ShiftTime(ddate,Shiftname,Starttime,Endtime)
Select top 1 * from #GetShiftTime Where StartTime<=@ShiftStartTime and Endtime<=@ShiftEndTime order by starttime desc


Update #ShiftTime set Shiftid = T.Shiftid from
(Select shiftdetails.Shiftid,shiftdetails.Shiftname from shiftdetails inner join #ShiftTime on #ShiftTime.Shiftname=shiftdetails.Shiftname
where running=1)T inner join #ShiftTime on #ShiftTime.Shiftname=T.Shiftname

select @stdate = CAST(datePart(yyyy,ddate) AS nvarchar(4)) + '-' + CAST(datePart(mm,ddate) AS nvarchar(2)) + '-' + CAST(datePart(dd,ddate) AS nvarchar(2)) from #ShiftTime

insert into #HourlyData(Machineid,PDate,ShiftName,ShiftID,Shiftstart,ShiftEnd,HourName,HourID,FromTime,ToTime,Actual,Target,ScrapLoss,Repairloss,PDTStatus)
select @Machineid,@stdate,S.ShiftName,S.Shiftid,S.StartTime,S.Endtime,SH.Hourname,SH.HourID,
dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),
dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2))))),0,0,0,0,0
 from (Select * from #ShiftTime) S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid
order by S.Shiftid,SH.Hourid
 


select @stdate = CAST(datePart(yyyy,@Startdate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@Startdate) AS nvarchar(2)) + '-' + CAST(datePart(dd,@Startdate) AS nvarchar(2))
   
insert into #HourlyData(Machineid,PDate,ShiftName,ShiftID,Shiftstart,ShiftEnd,HourName,HourID,FromTime,ToTime,Actual,Target,ScrapLoss,Repairloss,PDTStatus)
select @Machineid,@stdate,S.ShiftName,S.ShiftID,
Dateadd(DAY,S.FromDay,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,S.FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,S.FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,S.FromTime) as nvarchar(2))))) as StartTime,
DateAdd(Day,S.ToDay,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,S.ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,S.ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,S.ToTime) as nvarchar(2))))) as EndTime,
SH.Hourname,SH.HourID,
dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),
dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2))))),0,0,0,0,0
 from (Select top 2 * from shiftdetails where running=1 order by shiftid) S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid
where S.running=1 order by S.Shiftid,SH.Hourid


			
Select @T_ST=min(FromTime) from #HourlyData 
Select @T_ED=max(Totime) from #HourlyData 


---Getting Production Records
Select @strsql=''
select @strsql ='insert into #T_autodataforDown '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc 
where (datatype=1) and (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
				 and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
select @strsql = @strsql + @strmachine
--print @strsql
exec (@strsql)

--Getting BCD Records Excluding ICD Records
Select @strsql=''
select @strsql ='insert into #T_autodataforDown '
select @strsql = @strsql + 'SELECT A1.mc, A1.comp, A1.opn, A1.opr, A1.dcode,A1.sttime,'
 select @strsql = @strsql + 'A1.ndtime, A1.datatype, A1.cycletime, A1.loadunload, A1.msttime, A1.PartsCount,A1.id'
select @strsql = @strsql + ' from autodata A1 inner join Machineinformation on Machineinformation.interfaceid=A1.mc where A1.datatype=2 and
(( A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
 ( A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
 (A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) or
 (A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and A1.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
and NOT EXISTS ( select * from Autodata A2 inner join Machineinformation on Machineinformation.interfaceid=A2.mc where  A2.datatype=1 and  ((  A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) 
OR (A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and  A2.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
and A2.sttime<=A1.sttime and A2.ndtime>A1.ndtime and A1.mc=A2.mc'
select @strsql = @strsql + @strmachine
select @strsql = @strsql + ' )'
select @strsql = @strsql + @strmachine
--print @strsql
exec (@strsql)

Declare @LastRecordInAutodata as datetime
Select @LastRecordInAutodata = case when MAX(ndtime)>@T_ED then @T_ED else MAX(ndtime) END from Autodata where sttime>=@T_ST and ndtime<=@T_ED

If @Param = 'PartIDInfo'
BEGIN

	Create table #Part
	(
		MFC nvarchar(500),
		CycleTime float,
		ItemNo nvarchar(50),
		POT float
	)

	Insert into #Part(MFC,CycleTime,ItemNo,POT)
	Select Top 1 C.description as MFC,ISNULL(COP.Cycletime,0) as CycleTime,M.Interfaceid as ItemNo ,0 from componentinformation C Inner join
	(Select M.Machineid,A.comp,A.opn,MAX(A.Sttime) as Sttime from #T_autodataforDown A
	Inner join Machineinformation M on A.mc=M.Interfaceid
	where sttime>=@T_ST and ndtime<=@T_ED and M.Machineid=@Machineid group by M.Machineid,A.comp,A.opn)T on C.Interfaceid=T.Comp
	Inner join Machineinformation M on T.Machineid=M.Machineid
	Inner Join ComponentOperationPricing COP on COP.Machineid=T.Machineid and COP.interfaceid=T.opn and C.ComponentId=COP.ComponentID
	order by T.Sttime desc

	Update #Part SET POT = ISNULL(#Part.POT,0) + ISNULL(T1.POT,0) FROM(
	Select Datediff(minute,@T_ST,@T_ED)-ISNULL(SUM(T.PDT),0) as POT from
	(Select H.Fromtime as HourStart,H.Totime as HourEnd,datediff(minute,P.Starttime,P.Endtime) as PDT,P.Machine from PlannedDowntimes P
	Inner join #HourlyData H on P.Machine=H.Machineid
	where P.starttime>=H.Fromtime and P.Endtime<=H.Totime)T)T1

	Select * from #Part
END



If @param='HourwiseCount' or @param='HourwiseDown'
BEGIN

		---------------------------------------- Getting EmployeeID and EmployeeName For Each Shift --------------------------------------
		select employeeinformation.Name as oprname, employeeinformation.Employeeid as oprid,#HourlyData.Shiftstart,#HourlyData.machineID
		into #opr from #T_autodataforDown autodata 
		inner join Machineinformation M on autodata.mc=M.interfaceid
		inner join #HourlyData on #HourlyData.Machineid=#HourlyData.Machineid 
		INNER JOIN employeeinformation ON employeeinformation.interfaceid=autodata.opr 
		where 
		((autodata.msttime>=#HourlyData.Shiftstart) and (autodata.ndtime<=#HourlyData.ShiftEnd)
		OR (autodata.msttime<#HourlyData.Shiftstart and autodata.ndtime>#HourlyData.Shiftstart and autodata.ndtime<=#HourlyData.ShiftEnd)
		OR (autodata.msttime>=#HourlyData.Shiftstart and autodata.msttime<#HourlyData.ShiftEnd and autodata.ndtime>#HourlyData.ShiftEnd)
		OR (autodata.msttime<#HourlyData.Shiftstart and autodata.ndtime>#HourlyData.ShiftEnd)) 
		group by #HourlyData.machineID,employeeinformation.Employeeid,employeeinformation.Name,#HourlyData.Shiftstart

		UPDATE #HourlyData SET Employeeid = t2.opr 
		from(
		SELECT t.Shiftstart,t.machineID ,
			   STUFF(ISNULL((SELECT ', ' + x.oprid
						FROM #opr x
					   WHERE x.Shiftstart = t.Shiftstart and x.machineID = t.machineID
					GROUP BY x.oprid
					 FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), ''), 1, 2, '') [opr]      
		  FROM #opr t)
		as t2 inner join #HourlyData on t2.Shiftstart = #HourlyData.Shiftstart and t2.machineID =#HourlyData .MachineID 

		UPDATE #HourlyData SET Employeename = t2.opr 
		from(
		SELECT t.Shiftstart,t.machineID ,
			   STUFF(ISNULL((SELECT ', ' + x.oprname
						FROM #opr x
					   WHERE x.Shiftstart = t.Shiftstart and x.machineID = t.machineID
					GROUP BY x.oprname
					 FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), ''), 1, 2, '') [opr]      
		  FROM #opr t)
		as t2 inner join #HourlyData on t2.Shiftstart = #HourlyData.Shiftstart and t2.machineID =#HourlyData .MachineID 

	


		-------------------------------- Getting Hourwise Actual For the Given Machine and PDT applied-------------------------
		Update #HourlyData set Actual = Isnull(Actual,0) + Isnull(T1.Comp,0) from  
		(Select M.machineid,T.FromTime,T.ToTime,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
		from #T_autodataforDown A
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		cross join #HourlyData T 
		WHERE T.machineid=M.machineid and A.DataType=1 and M.machineid=@Machineid
		AND(A.ndtime > T.FromTime  AND A.ndtime <=T.ToTime)
		Group by M.machineid,T.FromTime,T.ToTime)T1 inner join #HourlyData on #HourlyData.FromTime=T1.FromTime
		and #HourlyData.ToTime=T1.ToTime and #HourlyData.machineid=T1.machineid

 
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN

			Update #HourlyData set Actual = Isnull(Actual,0) - Isnull(T1.Comp,0) from  
			(Select M.machineid,T1.FromTime,T1.ToTime,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
			from #T_autodataforDown A
			Inner join machineinformation M on M.interfaceid=A.mc
			Inner join #HourlyData T1 on T1.machineid=M.machineid
			Inner join componentinformation C ON A.Comp=C.interfaceid
			Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
			CROSS jOIN PlannedDownTimes T
			WHERE A.DataType=1 and T.machine=T1.Machineid and M.machineid=@Machineid
			AND(A.ndtime > T1.FromTime  AND A.ndtime <=T1.ToTime)
			AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
			Group by M.machineid,T1.FromTime,T1.ToTime)T1 inner join #HourlyData on #HourlyData.FromTime=T1.FromTime
			and #HourlyData.ToTime=T1.ToTime and #HourlyData.machineid=T1.machineid	
		END


		--------Getting Hourwise Rejections For the Given Machine and Rejection Codes (PDT Applied)--------------
		Update #HourlyData set ScrapLoss = isnull(ScrapLoss,0) + isnull(T1.RejQty,0)
		From
		( Select SUM(A.Rejection_Qty) as RejQty,M.Machineid,#HourlyData.fromtime from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #HourlyData on #HourlyData.machineid=M.machineid 
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
		where A.CreatedTS>=#HourlyData.fromtime and A.CreatedTS<#HourlyData.ToTime and A.flag = 'Rejection' and A.Rejection_code IN('1')
		and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
		group by M.Machineid,#HourlyData.fromtime
		)T1 inner join #HourlyData B on B.Machineid=T1.Machineid and B.fromtime=T1.fromtime

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
			Update #HourlyData set ScrapLoss = isnull(ScrapLoss,0) - isnull(T1.RejQty,0) from
			(Select #HourlyData.fromtime,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
			inner join Machineinformation M on A.mc=M.interfaceid
			inner join #HourlyData on #HourlyData.machineid=M.machineid 
			inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
			Cross join Planneddowntimes P
			where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and A.Rejection_code IN('1')
			and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
			A.CreatedTS>=#HourlyData.fromtime and A.CreatedTS<#HourlyData.ToTime And
			A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
			group by #HourlyData.fromtime,M.Machineid)T1 inner join #HourlyData B on B.Machineid=T1.Machineid and B.fromtime=T1.fromtime
		END

		--------Getting Hourwise Rework For the Given Machine and Rework Codes (PDT Applied)--------------
		Update #HourlyData set RepairLoss = isnull(RepairLoss,0) + isnull(T1.RwkQty,0)
		From
		( Select SUM(A.Rejection_Qty) as RwkQty,M.Machineid,#HourlyData.fromtime from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #HourlyData on #HourlyData.machineid=M.machineid 
		inner join Reworkinformation R on A.Rejection_code=R.Reworkinterfaceid
		where A.CreatedTS>=#HourlyData.fromtime and A.CreatedTS<#HourlyData.ToTime and A.flag = 'MarkedforRework' and A.Rejection_code IN('1')
		and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
		group by M.Machineid,#HourlyData.fromtime
		)T1 inner join #HourlyData B on B.Machineid=T1.Machineid and B.fromtime=T1.fromtime

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
			Update #HourlyData set RepairLoss = isnull(RepairLoss,0) - isnull(T1.RwkQty,0) from
			(Select #HourlyData.fromtime,SUM(A.Rejection_Qty) as RwkQty,M.Machineid from AutodataRejections A
			inner join Machineinformation M on A.mc=M.interfaceid
			inner join #HourlyData on #HourlyData.machineid=M.machineid 
			inner join Reworkinformation R on A.Rejection_code=R.Reworkinterfaceid
			Cross join Planneddowntimes P
			where P.PDTStatus =1 and A.flag = 'MarkedforRework' and P.machine=M.Machineid and A.Rejection_code IN('1')
			and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
			A.CreatedTS>=#HourlyData.fromtime and A.CreatedTS<#HourlyData.ToTime And
			A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
			group by #HourlyData.fromtime,M.Machineid)T1 inner join #HourlyData B on B.Machineid=T1.Machineid and B.fromtime=T1.fromtime
		END

		-------Getting Hourwise Target For the Given Machine and Target is based on Runtime Logic (PDT Applied)-------------------------
		insert into #Target(MachineID,machineinterface,Compinterface,Opninterface,msttime,ndtime,FromTm,ToTm,batchid,runtime,autodataid)
		SELECT M.machineid, M.interfaceid,Autodata.Comp,Autodata.opn,
		Case when autodata.msttime< T.fromtime then T.fromtime else autodata.msttime end, 
		Case when autodata.ndtime> T.totime then T.totime else autodata.ndtime end,
		T.fromtime,T.totime,0,0,autodata.id FROM #T_autodataforDown autodata
		INNER JOIN  machineinformation M ON autodata.mc = M.InterfaceID 
		Left Outer Join PlantMachine ON PlantMachine.MachineID=M.machineid 
		cross join #HourlyData T  
		WHERE M.Machineid=T.Machineid and M.machineid = @machineid and 
		((autodata.ndtime > T.fromtime  AND autodata.ndtime <= T.totime)
		OR (autodata.msttime>=T.Fromtime  and autodata.msttime<T.Totime  and autodata.ndtime>T.Totime)
		OR (autodata.msttime<T.Fromtime and autodata.ndtime>T.Totime ))
		order by autodata.msttime

		declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50),@From_Prev datetime
		declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@Fromtime datetime,@id nvarchar(50)
		declare @batchid int
		Declare @autodataid bigint,@autodataid_prev bigint
		declare @setupcursor  cursor
		set @setupcursor=cursor for
		select autodataid,FromTm,machineinterface ,Compinterface ,Opninterface  from #Target order by machineinterface,msttime
		open @setupcursor
		fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn
		set @autodataid_prev=@autodataid
		set @mc_prev = @mc
		set @comp_prev = @comp
		set @opn_prev = @opn
		SET @From_Prev = @Fromtime
		set @batchid =1

		while @@fetch_status = 0
		begin
		If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn	and @From_Prev = @Fromtime
			begin		
				update #Target set batchid = @batchid where autodataid=@autodataid and machineinterface=@mc and Compinterface=@comp and Opninterface=@opn and FromTm=@Fromtime
				print @batchid
			end
			else
			begin	
				  set @batchid = @batchid+1        
				  update #Target set batchid = @batchid where autodataid=@autodataid and machineinterface=@mc and Compinterface=@comp and Opninterface=@opn and FromTm=@Fromtime
				  set @autodataid_prev=@autodataid 
				  set @mc_prev=@mc 	
				  set @comp_prev=@comp
				  set @opn_prev=@opn	
				  SET @From_Prev = @Fromtime
			end	
			fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn
			
		end
		close @setupcursor
		deallocate @setupcursor
		


		insert into #FinalTarget (MachineID,machineinterface,Compinterface,Opninterface,Runtime,batchid,msttime,ndtime,FromTm,ToTm) 
		Select MachineID,machineinterface,Compinterface,Opninterface,datediff(s,min(msttime),max(ndtime)),batchid,min(msttime),max(ndtime),FromTm,ToTm from #Target 
		group by MachineID,batchid,FromTm,ToTm,machineinterface,Compinterface,Opninterface order by batchid 



		
		
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N'
		BEGIN

			Update #FinalTarget set Runtime=Isnull(Runtime,0) - Isnull(T3.pdt,0) 
			from (
			Select t2.machineinterface,T2.Machine,T2.msttime,T2.ndtime,T2.Fromtm,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt
			from
				(
				Select T1.machineinterface,T1.Compinterface,T1.Opninterface,T1.msttime,T1.ndtime,T1.FromTm,Pdt.machine,
				Case when  T1.msttime <= pdt.StartTime then pdt.StartTime else T1.msttime End as StartTimepdt,
				Case when  T1.ndtime >= pdt.EndTime then pdt.EndTime else T1.ndtime End as EndTimepdt
				from #FinalTarget T1
				inner join Planneddowntimes pdt on t1.machineid=Pdt.machine
				where PDTstatus = 1  and
				((pdt.StartTime >= t1.msttime and pdt.EndTime <= t1.ndTime)or
				(pdt.StartTime < t1.msttime and pdt.EndTime > t1.msttime and pdt.EndTime <=t1.ndTime)or
				(pdt.StartTime >= t1.msttime and pdt.StartTime <t1.ndTime and pdt.EndTime >t1.ndTime) or
				(pdt.StartTime <  t1.msttime and pdt.EndTime >t1.ndTime))
				)T2 group by  t2.machineinterface,T2.Machine,T2.msttime,T2.ndtime,T2.Fromtm
			) T3 inner join #FinalTarget T on T.machineinterface=T3.machineinterface and T.msttime=T3.msttime and  T.ndtime=T3.ndtime and T.Fromtm=T3.Fromtm

		ENd
 

		
		Update #HourlyData set Target = Isnull(Target,0) + isnull(T1.targetcount,0) from 
		(
			Select T.Machineid,T.FromTm,T.ToTm,sum(((T.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100) as targetcount
			from #FinalTarget T 
			inner join machineinformation M on M.Interfaceid=T.machineinterface
			inner join componentinformation C on C.interfaceid=T.Compinterface
			inner join componentoperationpricing CO on M.machineid=co.machineid and c.componentid=Co.componentid
			and Co.interfaceid=T.Opninterface
			group by T.FromTm,T.ToTm,T.Machineid
		)T1 inner join #HourlyData on #HourlyData.machineid=T1.machineid and #HourlyData.Fromtime=T1.FromTm and  #HourlyData.Totime=T1.ToTm



		-------------------------------- Getting Hourwise KWH For the Given Machine-------------------------
		Update #HourlyData
		set #HourlyData.MinEnergy = ISNULL(#HourlyData.MinEnergy,0)+ISNULL(t1.kwh,0) from 
		(
		select T.MachineiD,T.FromTime,T.ToTime,round(kwh,2) as kwh from 
			(
			select  tcs_energyconsumption.MachineiD,FromTime,ToTime,
			min(gtime) as mingtime
			from tcs_energyconsumption WITH(NOLOCK) inner join #HourlyData on 
			tcs_energyconsumption.machineID = #HourlyData.MachineID and tcs_energyconsumption.gtime >= #HourlyData.FromTime and tcs_energyconsumption.gtime <= #HourlyData.ToTime
			where tcs_energyconsumption.kwh>0 
			group by  tcs_energyconsumption.MachineiD,FromTime,ToTime)T
			inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime 
			AND tcs_energyconsumption.MachineID = T.MachineID --DR0359
		) as t1  inner join #HourlyData on t1.machineiD = #HourlyData.machineID and t1.FromTime = #HourlyData.FromTime and t1.ToTime = #HourlyData.ToTime

		Update #HourlyData
		set #HourlyData.MaxEnergy = ISNULL(#HourlyData.MaxEnergy,0)+ISNULL(t1.kwh,0) from 
		(
		select T.MachineiD,T.FromTime,T.ToTime,round(kwh,2)as kwh from 
			(
			select  tcs_energyconsumption.MachineiD,FromTime,ToTime,
			max(gtime) as maxgtime
			from tcs_energyconsumption WITH(NOLOCK) inner join #HourlyData on 
			tcs_energyconsumption.machineID = #HourlyData.MachineID and tcs_energyconsumption.gtime >= #HourlyData.FromTime	and tcs_energyconsumption.gtime <= #HourlyData.ToTime
			where tcs_energyconsumption.kwh>0 
			group by  tcs_energyconsumption.MachineiD,FromTime,ToTime
			)T
			inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime  
			AND tcs_energyconsumption.MachineID = T.MachineID 
		) as t1  inner join #HourlyData on t1.machineiD = #HourlyData.machineID and t1.FromTime = #HourlyData.FromTime and t1.ToTime = #HourlyData.ToTime

		Update #HourlyData set #HourlyData.KWH = ISNULL(#HourlyData.KWH,0)+ISNULL(t1.kwh,0)from 
		(
		 select MachineiD,FromTime,ToTime,round((MaxEnergy - MinEnergy),2) as kwh from #HourlyData 
		) as t1 inner join #HourlyData on t1.machineiD = #HourlyData.machineID and t1.FromTime = #HourlyData.FromTime and t1.ToTime = #HourlyData.ToTime

		-------------------------------- Getting Hourwise TypeID For the Given Machine-------------------------
		UPDATE #HourlyData SET TypeID = t2.comp 
		from(
		SELECT t.MachineID,t.FromTime ,t.Totime,
			   STUFF(ISNULL((SELECT '\ ' + x.compinterface
						FROM #FinalTarget x inner join ComponentInformation C on x.compinterface=C.interfaceid
					   WHERE x.MachineID = t.MachineID and x.FromTm = t.FromTime and x.ToTm=t.Totime
					GROUP BY x.compinterface
					 FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), ''), 1, 2, '') [comp]      
		  FROM #HourlyData t)
		as t2 inner join #HourlyData on t2.MachineID = #HourlyData.MachineID and t2.FromTime =#HourlyData .FromTime and t2.Totime = #HourlyData.Totime	
		
	   -------------------------------To Update PDTstatus at Hour Level----------------------------------
		Update #HourlyData Set PDTStatus = T1.PDT from
		(Select H.Fromtime,H.Totime,P.Starttime,P.Endtime,'1' as PDT,P.Machine from PlannedDowntimes P
		Inner join #HourlyData H on P.Machine=H.Machineid
		where P.starttime>=H.Fromtime and P.Endtime<=H.Totime)T1 inner join #HourlyData on t1.machine = #HourlyData.machineID
		and t1.FromTime = #HourlyData.FromTime and t1.ToTime = #HourlyData.ToTime


		--------------------------Getting Categorywise Downtimes for each hour and Machine----------------

		Create table #tempDowncategory
		(
			DownCategory nvarchar(50)
		 )

		insert into #tempDowncategory(DownCategory)Values('BreakDown')
		insert into #tempDowncategory(DownCategory)Values('Not Planned')
		insert into #tempDowncategory(DownCategory)Values('SpeedLoss')
		insert into #tempDowncategory(DownCategory)Values('ScrapLoss')
		insert into #tempDowncategory(DownCategory)Values('RepairLoss')

		Insert into #PredefinedDowncategory(Machineid,ShiftID,Hourid,Fromtime,Totime,plannedLoss,OrgLoss,NotPlanned)
		Select H.Machineid,H.Shiftid,H.HourID,H.FromTime,H.ToTime,0,0,0 from #HourlyData H


		Insert into #Downcategory(Machineid,ShiftID,Hourid,Fromtime,Totime,Downcategory,Downtime)
		Select H.Machineid,H.Shiftid,H.HourID,H.FromTime,H.ToTime,T.DownCategory,0 from
		(Select distinct DownCategory from DownCategoryInformation 
		)T cross join #HourlyData H Order by T.DownCategory

		Insert into #Downcategory(Machineid,ShiftID,Hourid,Fromtime,Totime,Downcategory,Downtime)
		Select H.Machineid,H.Shiftid,H.HourID,H.FromTime,H.ToTime,T.DownCategory,0 from
		(Select DownCategory from #tempDowncategory
		)T cross join #HourlyData H Order by T.DownCategory




		--Here We are considering ALL Downcodes EXCEPT 'P01' i.e 'Speed loss/CT High' and Considering ALL Downcodes Which are not of Type ML.
		update #Downcategory set Downtime=Isnull(Downtime,0) + ISNULL(T.Down,0) From
		(
			select DC.Fromtime,DC.Downcategory,sum(
			CASE
			WHEN  autodata.msttime>=DC.Fromtime  and  autodata.ndtime<=DC.Totime  THEN  loadunload
			WHEN (autodata.sttime<DC.Fromtime and  autodata.ndtime>DC.Fromtime and autodata.ndtime<=DC.Totime)  THEN DateDiff(second, DC.Fromtime, ndtime)
			WHEN (autodata.msttime>=DC.Fromtime  and autodata.sttime<DC.Totime  and autodata.ndtime>DC.Totime)  THEN DateDiff(second, stTime, DC.Totime)
			WHEN autodata.msttime<DC.Fromtime and autodata.ndtime>DC.Totime   THEN DateDiff(second, DC.Fromtime, DC.Totime)
			END
			)AS down
			from #T_autodataforDown autodata 
			inner join machineinformation M ON autodata.mc = M.InterfaceID 
			left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
			inner join downcodeinformation D on autodata.dcode=D.interfaceid
			inner join #Downcategory DC on DC.Machineid=M.Machineid and D.Catagory=DC.DownCategory
			inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory and DCI.DownCategory=DC.DownCategory
			where autodata.datatype=2 AND M.Machineid=@Machineid and D.availeffy = 0 and --D.interfaceid<>'P01' and 
			(
			(autodata.msttime>=DC.Fromtime  and  autodata.ndtime<=DC.Totime)
			OR (autodata.sttime<DC.Fromtime and  autodata.ndtime>DC.Fromtime and autodata.ndtime<=DC.Totime)
			OR (autodata.msttime>=DC.Fromtime  and autodata.sttime<DC.Totime  and autodata.ndtime>DC.Totime)
			OR (autodata.msttime<DC.Fromtime and autodata.ndtime>DC.Totime )
		) group by DC.Fromtime,DC.Downcategory)T INNER JOIN #Downcategory ON T.Downcategory = #Downcategory.downCategory and T.Fromtime=#Downcategory.Fromtime

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN

			UPDATE #Downcategory set Downtime =isnull(Downtime,0) - isNull(TT.DPDT ,0)
			FROM(
				SELECT DC.Fromtime,DC.Downcategory, SUM
				   (CASE
					WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (autodata.loadunload)
					WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as DPDT
				FROM #T_autodataforDown AutoData CROSS JOIN PlannedDownTimes T 
				inner join machineinformation M ON autodata.mc = M.InterfaceID 
				left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
				inner join downcodeinformation D on autodata.dcode=D.interfaceid
				inner join #Downcategory DC on DC.Machineid=M.Machineid and D.Catagory=DC.DownCategory
				inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory and DCI.DownCategory=DC.DownCategory
				WHERE autodata.DataType=2 AND M.Machineid=@Machineid AND T.Machine=M.Machineid and D.availeffy = 0 and --D.interfaceid<>'P01' and 
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					) AND
					(
					(T.StartTime>=DC.Fromtime  and  T.EndTime<=DC.Totime)
					OR (T.StartTime<DC.Fromtime and  T.EndTime>DC.Fromtime and T.EndTime<=DC.Totime)
					OR (T.StartTime>=DC.Fromtime  and T.StartTime<DC.Totime  and T.EndTime>DC.Totime)
					OR (T.StartTime<DC.Fromtime and T.EndTime>DC.Totime )
					) 
			group by DC.Fromtime,DC.Downcategory
			) as TT INNER JOIN #Downcategory ON TT.Downcategory = #Downcategory.downCategory and TT.Fromtime=#Downcategory.Fromtime

		END

		
		/********************************************************************************************************************
		Here We are considering Downcodes Which Are Of Type ML and EXCEPT 'L10' i.e 'M\C Not Planned' as we need to show this code as a separate Column.
		IN Bosch Jaipur we are assuming that All Downcodes under PlannedLoss Category will be defined as ML with Predefined Threshold.
		We will Assume Downtime less than Threshold will be a PlannedLoss if it is crossing Threshold then Threshold will be PlannedLoss
		And (Downtime-Threshold) will be Organizational Loss(i.e. They have to set one Downcode Under Absentism Category For Org.Loss)
		***************************************************************************************************************************/
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
		BEGIN

		UPDATE #PredefinedDowncategory SET PlannedLoss = isnull(PlannedLoss,0) + isNull(TT.WithinThreshold,0),OrgLoss=ISNULL(OrgLoss,0) + ISNULL(AfterThreshold,0)
		from
		(select DC.Fromtime,DC.Downcategory,sum(
		CASE
		WHEN (loadunload) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0 THEN isnull(D.Threshold,0)
		ELSE loadunload END) AS WithinThreshold,
		SUM(CASE
		WHEN (loadunload) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0 THEN isnull(loadunload,0)-isnull(D.Threshold,0)
		ELSE 0 END) AS AfterThreshold
		from #T_autodataforDown autodata
		INNER join machineinformation M ON autodata.mc = M.InterfaceID 
		LEFT Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		INNER JOIN downcodeinformation D ON autodata.dcode = D.interfaceid
		INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=D.Catagory
		INNER join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory and DCI.DownCategory=DC.DownCategory
		where (autodata.msttime>=DC.Fromtime and autodata.ndtime<=DC.Totime) AND M.Machineid=@Machineid and (autodata.datatype=2) and (D.availeffy = 1) and (D.ThresholdfromCO <>1)
		and D.interfaceid<>'8' 
		group by DC.Fromtime,DC.Downcategory) as TT INNER JOIN #PredefinedDowncategory ON TT.Fromtime=#PredefinedDowncategory.Fromtime



		UPDATE #PredefinedDowncategory SET PlannedLoss = isnull(PlannedLoss,0) + isNull(TT.WithinThreshold,0),OrgLoss=ISNULL(OrgLoss,0) + ISNULL(AfterThreshold,0)
		from
		(select DC.Fromtime,DC.Downcategory,sum(
		CASE WHEN DateDiff(second, DC.Fromtime, ndtime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then isnull(D.Threshold,0)
		ELSE DateDiff(second, DC.Fromtime, ndtime)
		END)AS WithinThreshold,
		SUM(CASE WHEN DateDiff(second, DC.Fromtime, ndtime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then DateDiff(second, DC.Fromtime, ndtime) - isnull(D.Threshold,0)
		ELSE 0
		END) AS AfterThreshold
		from #T_autodataforDown autodata
		INNER join machineinformation M ON autodata.mc = M.InterfaceID 
		LEFT Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		INNER JOIN downcodeinformation D ON autodata.dcode = D.interfaceid
		INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=D.Catagory
		INNER join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory and DCI.DownCategory=DC.DownCategory
		where (autodata.sttime<DC.Fromtime and autodata.ndtime>DC.Fromtime and autodata.ndtime<=DC.Totime) 
		AND M.Machineid=@Machineid and (autodata.datatype=2) and (D.availeffy = 1) and (D.ThresholdfromCO <>1) and D.interfaceid<>'8' 
		group by DC.Fromtime,DC.Downcategory) as TT INNER JOIN #PredefinedDowncategory ON TT.Fromtime=#PredefinedDowncategory.Fromtime



		UPDATE #PredefinedDowncategory SET PlannedLoss = isnull(PlannedLoss,0) + isNull(TT.WithinThreshold,0),OrgLoss=ISNULL(OrgLoss,0) + ISNULL(AfterThreshold,0)
		from
		(select DC.Fromtime,DC.Downcategory,SUM(
		CASE WHEN DateDiff(second,stTime, DC.Totime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then isnull(D.Threshold,0)
		ELSE DateDiff(second, stTime, DC.Totime)
		END) WithinThreshold,
		SUM(CASE WHEN DateDiff(second,stTime, DC.Totime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then DateDiff(second,stTime, DC.Totime) - isnull(D.Threshold,0)
		ELSE 0
		END) AS AfterThreshold
		from #T_autodataforDown autodata
		INNER join machineinformation M ON autodata.mc = M.InterfaceID 
		LEFT Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		INNER JOIN downcodeinformation D ON autodata.dcode = D.interfaceid
		INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=D.Catagory
		INNER join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory and DCI.DownCategory=DC.DownCategory
		where (autodata.msttime>=DC.Fromtime and autodata.sttime<DC.Totime and autodata.ndtime>DC.Totime)
		AND M.Machineid=@Machineid and (autodata.datatype=2) and (D.availeffy = 1) and (D.ThresholdfromCO <>1) and D.interfaceid<>'8' 
		group by DC.Fromtime,DC.Downcategory) as TT INNER JOIN #PredefinedDowncategory ON TT.Fromtime=#PredefinedDowncategory.Fromtime



		UPDATE #PredefinedDowncategory SET PlannedLoss = isnull(PlannedLoss,0) + isNull(TT.WithinThreshold,0),OrgLoss=ISNULL(OrgLoss,0) + ISNULL(AfterThreshold,0)
		from
		(select DC.Fromtime,DC.Downcategory,sum(
		CASE WHEN DateDiff(second, DC.Fromtime, DC.Totime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then isnull(D.Threshold,0)
		ELSE DateDiff(second, DC.Fromtime, DC.Totime)
		END) WithinThreshold,
		SUM(CASE WHEN DateDiff(second, DC.Fromtime, DC.Totime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then DateDiff(second, DC.Fromtime, DC.Totime) - isnull(D.Threshold,0)
		ELSE 0
		END) AS AfterThreshold
		from #T_autodataforDown autodata
		INNER join machineinformation M ON autodata.mc = M.InterfaceID 
		LEFT Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		INNER JOIN downcodeinformation D ON autodata.dcode = D.interfaceid
		INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=D.Catagory
		INNER join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory and DCI.DownCategory=DC.DownCategory
		where (autodata.msttime<DC.Fromtime and autodata.ndtime>DC.Totime)
		AND M.Machineid=@Machineid and (autodata.datatype=2) and (D.availeffy = 1) and (D.ThresholdfromCO <>1) and D.interfaceid<>'8' 
		group by DC.Fromtime,DC.Downcategory) as TT INNER JOIN #PredefinedDowncategory ON TT.Fromtime=#PredefinedDowncategory.Fromtime

		END
		
			---Management loss calculation FOR DownCategory=Planned Loss Except Downcode<>(L10)
		---IN T1 Select get all the downtimes which is of type management loss
		---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
		---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
		---In T4 consolidate everything at machine level and update the same to #PredefinedDowncategory for ManagementLoss and MLDown
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN

		UPDATE #PredefinedDowncategory SET  PlannedLoss = isnull(PlannedLoss,0) + isNull(t4.Mloss,0),OrgLoss=isNull(OrgLoss,0)-isNull(t4.Dloss,0)
		from
		(select T3.Fromtime,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
		select   t1.id,T1.mc,T1.Threshold,T1.Fromtime,
		case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
		then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
		else 0 End  as Dloss,
		case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
		then isnull(T1.Threshold,0)
		else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
		 from
		
		(   select id,mc,comp,opn,opr,D.threshold,DC.Fromtime,
			case when autodata.sttime<DC.Fromtime then DC.Fromtime else sttime END as sttime,
	       		case when ndtime>DC.Totime then DC.Totime else ndtime END as ndtime
			from autodata 
			INNER join machineinformation M ON autodata.mc = M.InterfaceID 
			inner join downcodeinformation D on autodata.dcode=D.interfaceid 
			INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=D.Catagory
			where (autodata.datatype=2) AND  (D.availeffy = 1) and (D.ThresholdfromCO <>1) and (D.interfaceid<>'8') and (M.Machineid=@Machineid) AND
			(
			(autodata.sttime>=DC.Fromtime  and  autodata.ndtime<=DC.Totime)
			OR (autodata.sttime<DC.Fromtime and  autodata.ndtime>DC.Fromtime and autodata.ndtime<=DC.Totime)
			OR (autodata.sttime>=DC.Fromtime  and autodata.sttime<DC.Totime  and autodata.ndtime>DC.Totime)
			OR (autodata.sttime<DC.Fromtime and autodata.ndtime>DC.Totime )
			) 
		) as T1 	 
		left outer join
		(SELECT autodata.id,DC.Fromtime,
				   sum(CASE
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PPDT
			FROM AutoData CROSS jOIN PlannedDownTimes T 
			INNER join machineinformation M ON autodata.mc = M.InterfaceID 
			inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
			INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=downcodeinformation.Catagory
			WHERE autodata.DataType=2 AND T.Machine=M.Machineid AND (downcodeinformation.interfaceid<>'8') and (M.Machineid=@Machineid) AND
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				)
				AND
				(
				(T.StartTime>=DC.Fromtime  and  T.EndTime<=DC.Totime)
				OR (T.StartTime<DC.Fromtime and  T.EndTime>DC.Fromtime and T.EndTime<=DC.Totime)
				OR (T.StartTime>=DC.Fromtime  and T.StartTime<DC.Totime  and T.EndTime>DC.Totime)
				OR (T.StartTime<DC.Fromtime and T.EndTime>DC.Totime )
				) 
				AND (downcodeinformation.availeffy = 1) 
				AND (downcodeinformation.ThresholdfromCO <>1) --NR0097 
				group  by autodata.id,DC.Fromtime ) as T2 on T1.id=T2.id and T1.Fromtime=T2.Fromtime) as T3  group by T3.Fromtime
		) as t4 INNER JOIN #PredefinedDowncategory ON T4.Fromtime=#PredefinedDowncategory.Fromtime
		END


		/********************************************************************************************************************
		Here We are considering Downcode and Of TYPE ML 'L10' i.e 'M\C Not Planned' as we need to show this code as a separate Column.
		We will Assume Downtime less than Threshold then "Downtime" will be a NotPlanned if it is crossing Threshold then "Threshold" will be NotPlanned
		And "(Downtime-Threshold)" will be Organizational Loss(i.e. They have to set one Downcode Under Absentism Category For Org.Loss)
		***************************************************************************************************************************/
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
		BEGIN

		UPDATE #PredefinedDowncategory SET NotPlanned = isnull(NotPlanned,0) + isNull(TT.WithinThreshold,0),OrgLoss=ISNULL(OrgLoss,0) + ISNULL(AfterThreshold,0)
		from
		(select DC.Fromtime,DC.Downcategory,sum(
		CASE
		WHEN (loadunload) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0 THEN isnull(D.Threshold,0)
		ELSE loadunload END) AS WithinThreshold,
		SUM(CASE
		WHEN (loadunload) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0 THEN isnull(loadunload,0)-isnull(D.Threshold,0)
		ELSE 0 END) AS AfterThreshold
		from #T_autodataforDown autodata
		INNER join machineinformation M ON autodata.mc = M.InterfaceID 
		LEFT Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		INNER JOIN downcodeinformation D ON autodata.dcode = D.interfaceid
		INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=D.Catagory
		INNER join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory and DCI.DownCategory=DC.DownCategory
		where (autodata.msttime>=DC.Fromtime and autodata.ndtime<=DC.Totime) AND M.Machineid=@Machineid and (autodata.datatype=2) and (D.availeffy = 1) and (D.ThresholdfromCO <>1)
		and D.interfaceid='8' 
		group by DC.Fromtime,DC.Downcategory) as TT INNER JOIN #PredefinedDowncategory ON  TT.Fromtime=#PredefinedDowncategory.Fromtime

		UPDATE #PredefinedDowncategory SET NotPlanned = isnull(NotPlanned,0) + isNull(TT.WithinThreshold,0),OrgLoss=ISNULL(OrgLoss,0) + ISNULL(AfterThreshold,0)
		from
		(select DC.Fromtime,DC.Downcategory,sum(
		CASE WHEN DateDiff(second, DC.Fromtime, ndtime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then isnull(D.Threshold,0)
		ELSE DateDiff(second, DC.Fromtime, ndtime)
		END)AS WithinThreshold,
		SUM(CASE WHEN DateDiff(second, DC.Fromtime, ndtime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then DateDiff(second, DC.Fromtime, ndtime) - isnull(D.Threshold,0)
		ELSE 0
		END) AS AfterThreshold
		from #T_autodataforDown autodata
		INNER join machineinformation M ON autodata.mc = M.InterfaceID 
		LEFT Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		INNER JOIN downcodeinformation D ON autodata.dcode = D.interfaceid
		INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=D.Catagory
		INNER join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory and DCI.DownCategory=DC.DownCategory
		where (autodata.sttime<DC.Fromtime and autodata.ndtime>DC.Fromtime and autodata.ndtime<=DC.Totime) 
		AND M.Machineid=@Machineid and (autodata.datatype=2) and (D.availeffy = 1) and (D.ThresholdfromCO <>1) and D.interfaceid='8' 
		group by DC.Fromtime,DC.Downcategory) as TT INNER JOIN #PredefinedDowncategory ON  TT.Fromtime=#PredefinedDowncategory.Fromtime

		UPDATE #PredefinedDowncategory SET NotPlanned = isnull(NotPlanned,0) + isNull(TT.WithinThreshold,0),OrgLoss=ISNULL(OrgLoss,0) + ISNULL(AfterThreshold,0)
		from
		(select DC.Fromtime,DC.Downcategory,SUM(
		CASE WHEN DateDiff(second,stTime, DC.Totime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then isnull(D.Threshold,0)
		ELSE DateDiff(second, stTime, DC.Totime)
		END) WithinThreshold,
		SUM(CASE WHEN DateDiff(second,stTime, DC.Totime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then DateDiff(second,stTime, DC.Totime) - isnull(D.Threshold,0)
		ELSE 0
		END) AS AfterThreshold
		from #T_autodataforDown autodata
		INNER join machineinformation M ON autodata.mc = M.InterfaceID 
		LEFT Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		INNER JOIN downcodeinformation D ON autodata.dcode = D.interfaceid
		INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=D.Catagory
		INNER join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory and DCI.DownCategory=DC.DownCategory
		where (autodata.msttime>=DC.Fromtime and autodata.sttime<DC.Totime and autodata.ndtime>DC.Totime)
		AND M.Machineid=@Machineid and (autodata.datatype=2) and (D.availeffy = 1) and (D.ThresholdfromCO <>1) and D.interfaceid='8' 
		group by DC.Fromtime,DC.Downcategory) as TT INNER JOIN #PredefinedDowncategory ON TT.Fromtime=#PredefinedDowncategory.Fromtime

		UPDATE #PredefinedDowncategory SET NotPlanned = isnull(NotPlanned,0) + isNull(TT.WithinThreshold,0),OrgLoss=ISNULL(OrgLoss,0) + ISNULL(AfterThreshold,0)
		from
		(select DC.Fromtime,DC.Downcategory,sum(
		CASE WHEN DateDiff(second, DC.Fromtime, DC.Totime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then isnull(D.Threshold,0)
		ELSE DateDiff(second, DC.Fromtime, DC.Totime)
		END) WithinThreshold,
		SUM(CASE WHEN DateDiff(second, DC.Fromtime, DC.Totime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0
		then DateDiff(second, DC.Fromtime, DC.Totime) - isnull(D.Threshold,0)
		ELSE 0
		END) AS AfterThreshold
		from #T_autodataforDown autodata
		INNER join machineinformation M ON autodata.mc = M.InterfaceID 
		LEFT Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		INNER JOIN downcodeinformation D ON autodata.dcode = D.interfaceid
		INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=D.Catagory
		INNER join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory and DCI.DownCategory=DC.DownCategory
		where (autodata.msttime<DC.Fromtime and autodata.ndtime>DC.Totime)
		AND M.Machineid=@Machineid and (autodata.datatype=2) and (D.availeffy = 1) and (D.ThresholdfromCO <>1) and D.interfaceid='8' 
		group by DC.Fromtime,DC.Downcategory) as TT INNER JOIN #PredefinedDowncategory ON TT.Fromtime=#PredefinedDowncategory.Fromtime
		END

		---Management loss calculation FOR NOT PLANNED(L10)
	---IN T1 Select get all the downtimes which is of type management loss
	---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
	---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
	---In T4 consolidate everything at machine level and update the same to #PredefinedDowncategory for ManagementLoss and MLDown

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN

		UPDATE #PredefinedDowncategory SET  NotPlanned = isnull(NotPlanned,0) + isNull(t4.Mloss,0),OrgLoss=isNull(OrgLoss,0)+isNull(t4.Dloss,0)
		from
		(select T3.Fromtime,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
		select   t1.id,T1.mc,T1.Threshold,T1.Fromtime,
		case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
		then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
		else 0 End  as Dloss,
		case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
		then isnull(T1.Threshold,0)
		else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
		 from
		
		(   select id,mc,comp,opn,opr,D.threshold,DC.Fromtime,
			case when autodata.sttime<DC.Fromtime then DC.Fromtime else sttime END as sttime,
	       		case when ndtime>DC.Totime then DC.Totime else ndtime END as ndtime
			from autodata 
			INNER join machineinformation M ON autodata.mc = M.InterfaceID 
			inner join downcodeinformation D on autodata.dcode=D.interfaceid 
			INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=D.Catagory
			where (autodata.datatype=2) AND  (D.availeffy = 1) and (D.ThresholdfromCO <>1) and (D.interfaceid='8') and (M.Machineid=@Machineid) AND
			(
			(autodata.sttime>=DC.Fromtime  and  autodata.ndtime<=DC.Totime)
			OR (autodata.sttime<DC.Fromtime and  autodata.ndtime>DC.Fromtime and autodata.ndtime<=DC.Totime)
			OR (autodata.sttime>=DC.Fromtime  and autodata.sttime<DC.Totime  and autodata.ndtime>DC.Totime)
			OR (autodata.sttime<DC.Fromtime and autodata.ndtime>DC.Totime )
			) 
		) as T1 	 
		left outer join
		(SELECT autodata.id,DC.Fromtime,
				   sum(CASE
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PPDT
			FROM AutoData CROSS jOIN PlannedDownTimes T 
			INNER join machineinformation M ON autodata.mc = M.InterfaceID 
			inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
			INNER join #Downcategory DC on DC.Machineid=M.Machineid and DC.DownCategory=downcodeinformation.Catagory
			WHERE autodata.DataType=2 AND T.Machine=M.Machineid AND (downcodeinformation.interfaceid='8') and (M.Machineid=@Machineid) AND
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				)
				AND
				(
				(T.StartTime>=DC.Fromtime  and  T.EndTime<=DC.Totime)
				OR (T.StartTime<DC.Fromtime and  T.EndTime>DC.Fromtime and T.EndTime<=DC.Totime)
				OR (T.StartTime>=DC.Fromtime  and T.StartTime<DC.Totime  and T.EndTime>DC.Totime)
				OR (T.StartTime<DC.Fromtime and T.EndTime>DC.Totime )
				) 
				AND (downcodeinformation.availeffy = 1) 
				AND (downcodeinformation.ThresholdfromCO <>1) --NR0097 
				group  by autodata.id,DC.Fromtime ) as T2 on T1.id=T2.id and T1.Fromtime=T2.Fromtime) as T3  group by T3.Fromtime
		) as t4 INNER JOIN #PredefinedDowncategory ON T4.Fromtime=#PredefinedDowncategory.Fromtime
		END


		--To Update PlannedLoss
		UPDATE #Downcategory SET Downtime = ISNULL(Downtime,0) + ISNULL(T1.PL,0) from
		(Select Fromtime,SUM(PlannedLoss) as PL from #PredefinedDowncategory
		Group by Fromtime)T1 inner join #Downcategory on T1.Fromtime=#Downcategory.Fromtime and #Downcategory.Downcategory like 'Planned%'


		--To Update NotPlanned
		UPDATE #Downcategory SET Downtime = ISNULL(Downtime,0) + ISNULL(T1.NP,0) from
		(Select Fromtime,SUM(NotPlanned) as NP from #PredefinedDowncategory
		Group by Fromtime)T1 inner join #Downcategory on T1.Fromtime=#Downcategory.Fromtime and #Downcategory.Downcategory like 'Not Planned'

		--To Update OrgLoss
		UPDATE #Downcategory SET Downtime = ISNULL(Downtime,0) + ISNULL(T1.OL,0) from
		(Select Fromtime,SUM(OrgLoss) as OL from #PredefinedDowncategory
		Group by Fromtime)T1 inner join #Downcategory on T1.Fromtime=#Downcategory.Fromtime and #Downcategory.Downcategory like 'Absentism%'


			 
		--To Update SpeedLoss
		UPDATE #Downcategory SET Downtime = ISNULL(Downtime,0) + ISNULL(TT.Consumedtime,0) from
		(Select T2.Fromtime,T2.Totime,((datediff(second,T2.Fromtime,T2.Totime)-T1.PDT)-T2.Downtime) as Consumedtime From 
			 (select HourStart,HourEnd,sum(PDT) AS PDT from
				(
				Select H.FromTm as HourStart,H.ToTm as HourEnd,datediff(second,P.Starttime,case when P.Endtime>@LastRecordInAutodata then @LastRecordInAutodata else P.Endtime END) as PDT,P.Machine from PlannedDowntimes P
				inner join #FinalTarget H on P.Machine=H.Machineid
				where P.starttime>=H.FromTm and P.Endtime<=H.ToTm
				)T group by HourStart,HourEnd
			)T1 right outer JOIN
			(
				Select D.Fromtime,case when D.Totime>@LastRecordInAutodata then @LastRecordInAutodata else D.Totime END as Totime,SUM(D.Downtime) as Downtime from
				#Downcategory D  where  D.Totime<=@LastRecordInAutodata group by  D.Fromtime,D.Totime
			 )T2 on T1.HourStart=T2.FromTime and T1.HourEnd=T2.ToTime
		 )TT INNER JOIN #Downcategory on TT.Fromtime=#Downcategory.Fromtime and #Downcategory.Downcategory like 'SpeedLoss%'



		--To Update SpeedLoss
		UPDATE #Downcategory SET Downtime = ISNULL(Downtime,0) - ISNULL(TT.StdCT,0) from
		(Select T.fromtime,T.totime,sum(T.cycletime)*SUM(H.Actual) as StdCT from
			(
			SELECT x.FromTm as Fromtime,x.ToTm as Totime,x.compinterface,COP.Cycletime FROM #FinalTarget x 
					inner join ComponentInformation C on x.compinterface=C.interfaceid
					inner join Componentoperationpricing COP on x.Machineid=COP.Machineid and x.opninterface=COP.interfaceid and COP.Componentid=C.ComponentID
			)T inner join #HourlyData H on T.Fromtime=H.Fromtime group by T.fromtime,T.totime
		 )TT INNER JOIN #Downcategory on TT.Fromtime=#Downcategory.Fromtime and Downtime>0 and #Downcategory.Downcategory like 'SpeedLoss%'


		--To ADD SpeedLoss To Performance Loss
		UPDATE #Downcategory SET Downtime = ISNULL(Downtime,0) + ISNULL(T1.SL,0) from
		(Select Fromtime,SUM(Downtime) as SL from #Downcategory
		where DownCategory like 'SpeedLoss%' Group by Fromtime
		)T1 inner join #Downcategory on T1.Fromtime=#Downcategory.Fromtime and #Downcategory.Downcategory like 'Performance Loss%'


		--To Combine Electrical+Mechanical Breakdown as Single Breakdown category
		UPDATE #Downcategory SET Downtime = T1.Brkdwn from
		(Select Fromtime,SUM(Downtime) as Brkdwn from #Downcategory
		--INNER JOIN downcodeinformation D ON #Downcategory.DownCategory=D.Catagory
		where DownCategory like 'Mechanical Breakdown%' and DownCategory like 'Electrical Breakdown%'
		Group by Fromtime)T1 inner join #Downcategory on T1.Fromtime=#Downcategory.Fromtime and #Downcategory.Downcategory='BreakDown'

		--To Get ScrapLoss
		UPDATE #Downcategory SET Downtime = ISNULL(Downtime,0) + ISNULL(T1.SL,0) from
		(Select Fromtime,SUM(ScrapLoss) as SL from #HourlyData
		Group by Fromtime)T1 inner join #Downcategory on T1.Fromtime=#Downcategory.Fromtime and #Downcategory.Downcategory='Scrap%'

		--To Get RepairLoss
		UPDATE #Downcategory SET Downtime = ISNULL(Downtime,0) + ISNULL(T1.RL,0) from
		(Select Fromtime,SUM(RepairLoss) as RL from #HourlyData
		Group by Fromtime)T1 inner join #Downcategory on T1.Fromtime=#Downcategory.Fromtime and #Downcategory.Downcategory='Repair%'

		

		 
		---Formatting Downtime To Mins.
		Update #Downcategory set Downtime= dbo.f_FormatTime(Downtime,'mm')

		

		If @param='HourwiseCount'
		Begin

		Update #HourlyData set Slno=T.Slno from
		(Select H.ShiftId,Case when H.ShiftId='3' then '1'
		when H.ShiftId='1' then '2'
		when H.ShiftId='2' then '3' end as Slno from #HourlyData H)T inner join #HourlyData on #HourlyData.Shiftid=T.Shiftid

		Select H.Slno as Shiftid,H.ShiftId as ActualShiftid,H.Employeeid,H.EmployeeName,H.HourID,H.PDTStatus,CONVERT(varchar(5),H.Fromtime,108) + '-' + CONVERT(varchar(5),H.Totime,108) as [Time],Round(H.Target,0) as Target,H.Actual,Round(H.KWH,2) as KWH,H.TypeID 
		from #HourlyData H order by Slno --Order by H.ShiftID,H.HourID
		
		ENd



		If @param='HourwiseDown'
		Begin

		Update #Downcategory set IDD=T.Slno from
		(Select H.ShiftId,Case when H.ShiftId='3' then '1'
		when H.ShiftId='1' then '2'
		when H.ShiftId='2' then '3' end as Slno from #Downcategory H)T inner join #Downcategory on #Downcategory.Shiftid=T.Shiftid

		Select IDD as Shiftid,Shiftid as ActualShiftid,Hourid,CONVERT(varchar(5),Fromtime,108) + '-' + CONVERT(varchar(5),Totime,108) as [Time],downCategory,downtime from #Downcategory 
		WHERE downCategory NOT in ('Electrical Breakdown','Mechanical Breakdown','SpeedLoss') order by IDD,hourID,downCategory--Order by shiftid,hourID,downCategory
		
		ENd



--		--Pivoting Hourstart,Downcategory and Downtime
--		DECLARE @DynamicPivotQuery AS NVARCHAR(2000)
--		DECLARE @SelectColumnName1 AS NVARCHAR(2000)
--
--		SELECT @SelectColumnName1= ISNULL(@SelectColumnName1 + ',','') 
--		 + QUOTENAME(downCategory)
--		  FROM (select distinct downCategory from #Downcategory
--		  )AS BatchValues  
--
--		SET @DynamicPivotQuery = 
--		N'
--		Select Shiftid,Hourid,fromtime,totime,OrgLoss,NotPlanned,Breakdown,' + @SelectColumnName1 + ' into ##Down from(
--		select Shiftid,Hourid,fromtime,totime,OrgLoss,NotPlanned,Breakdown,downCategory,downtime
--		FROM #Downcategory)t 
--		PIVOT(sum(downtime) FOR downCategory IN(' + @SelectColumnName1 + '))PVT1
--		order by Shiftid,Hourid'
--		EXEC sp_executesql @DynamicPivotQuery
--
--
--		--Select @strsql=''
--		--Select @strsql= @strsql + 'Select H.ShiftId,H.Employeeid,H.EmployeeName,H.HourID,RIGHT(''0''+LTRIM(RIGHT(CONVERT(varchar,H.Fromtime,100),8)),7)as Fromtime,RIGHT(''0''+LTRIM(RIGHT(CONVERT(varchar,H.Totime,100),8)),7) as Totime,Round(H.Target,0) as Target,H.Actual,Round(H.KWH,2) as KWH,H.TypeID,##Down.OrgLoss,##Down.NotPlanned,##Down.' + @SelectColumnName1 + ',H.ScrapLoss,H.RepairLoss from
--		--##Down inner join #HourlyData H on H.Fromtime=##Down.Fromtime
--		--Order by H.ShiftID,H.HourID'
--		--exec(@strsql)
--
--		Select @strsql=''
--		Select @strsql= @strsql + 'Select H.ShiftId,H.Employeeid,H.EmployeeName,H.HourID,CONVERT(varchar(5),H.Fromtime,108) + ''-'' + CONVERT(varchar(5),H.Totime,108) as [Time],Round(H.Target,0) as Target,H.Actual,Round(H.KWH,2) as KWH,H.TypeID,##Down.OrgLoss,##Down.NotPlanned,##Down.Breakdown,##Down.' + @SelectColumnName1 + ',H.ScrapLoss,H.RepairLoss from
--		##Down inner join #HourlyData H on H.Fromtime=##Down.Fromtime
--		Order by H.ShiftID,H.HourID'
--		exec(@strsql)


--		Drop table ##Down

END




END
