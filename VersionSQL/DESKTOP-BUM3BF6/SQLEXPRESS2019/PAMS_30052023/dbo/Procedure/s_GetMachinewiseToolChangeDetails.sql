/****** Object:  Procedure [dbo].[s_GetMachinewiseToolChangeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0391 - SwathiKS - 2014/Aug/26 :: Created New Procedure To show Tool Change Details.
--Launch will be under SM -> Std -> Tool Change Frequency Report -> Format III
--s_GetMachinewiseToolChangeDetails '2014-09-06 06:00:00 AM','2014-09-09 06:00:00 AM','','ECONO-3',''

CREATE PROCEDURE [dbo].[s_GetMachinewiseToolChangeDetails]
	@StartTime datetime,
	@EndTime datetime,
	@plantid nvarchar(50) = '',
	@MachineID nvarchar(50) = '',
	@Param nvarchar(20)= ''
	
AS
BEGIN

Declare @strSql as nvarchar(4000)
SELECT @strSql = ''

Create table #ToolDetails
(
Machineid nvarchar(50),
Mcinterface nvarchar(50),
Compinterface nvarchar(50),
Opninterface nvarchar(50),
ToolNo decimal(18,2),
ToolDescription nvarchar(50),
NoOfAlarms int,
Alarmtime nvarchar(500),
NoOfTimesChanged int,
ChangeTime datetime,
TotalParts int,
Component nvarchar(50),
Operation nvarchar(50),
PartsByCO int,
Starttime datetime,
endtime datetime,
Suboperation int
)

Create table #PartChange
(
Machineid nvarchar(50),
Mcinterface nvarchar(50),
ToolNo nvarchar(50),
ToolDescription nvarchar(50),
NoOfAlarms int default 0,
Alarmtime nvarchar(500),
Starttime Datetime,
Endtime datetime,
NoOfTimesChanged int,
ChangeTime datetime,
TotalParts int
)

Create table #Part
(
Machineid nvarchar(50),
Mcinterface nvarchar(50),
ToolNo nvarchar(50),
ToolDescription nvarchar(50),
Starttime Datetime,
Alarmid bigint
)

Create table #Alarmdetails
(
Machineid nvarchar(50),
Mcinterface nvarchar(50),
ToolNo nvarchar(50),
NoOfAlarms int default 0,
Alarmtime Datetime,
Starttime Datetime

)

Create table #PlannedDownTimes
(
	MachineID nvarchar(50) NOT NULL, --ER0374
	MachineInterface nvarchar(50) NOT NULL, --ER0374
	StartTime DateTime NOT NULL, --ER0374
	EndTime DateTime NOT NULL --ER0374
)

ALTER TABLE #PlannedDownTimes
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface],
			[StartTime],
			[EndTime]
						
		) ON [PRIMARY]


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
SET @strSql =  @strSql +   ' ORDER BY Machine,StartTime'
EXEC(@strSql)



--Getting Machine-Toolwise Starttime for Recordtype=18 from AutodataAlarms
insert into #Part(Machineid,Mcinterface,ToolNo,ToolDescription,Starttime,Alarmid)
Select M.machineid,M.interfaceid,T.ToolNo,T.ToolDescription,A.Alarmtime,A.ID from AutodataAlarms A
inner join Machineinformation M on A.machineid=M.interfaceid
inner join (Select distinct ToolNo,ToolDescription from ToolSequence) T on A.Alarmnumber=T.ToolNo
where A.recordtype=18 and (A.Alarmtime>=@starttime and A.Alarmtime<=@Endtime) and M.machineid=@machineid



--Getting Machine-Toolwise Starttime and Endtime using self join of #Part
insert into #PartChange(Machineid,Mcinterface,ToolNo,ToolDescription,Starttime,Endtime)
Select A1.Machineid,A1.Mcinterface,A1.ToolNo,A1.ToolDescription,A1.starttime,min(A2.starttime) from #Part A1,#Part A2
where A1.Alarmid<A2.Alarmid and A1.ToolNo=A2.Toolno
group by A1.Machineid,A1.Mcinterface,A1.ToolNo,A1.ToolDescription,A1.starttime

--Prediction
insert into #PartChange(Machineid,Mcinterface,ToolNo,ToolDescription,Starttime,Endtime)
Select A1.Machineid,A1.Mcinterface,A1.ToolNo,A1.ToolDescription,case when min(A1.starttime)>@starttime then @starttime end,min(A1.starttime) from #Part A1
group by A1.Machineid,A1.Mcinterface,A1.ToolNo,A1.ToolDescription

--Getting Noofalarms i.e count of recordtype=6 from Autodataalarms
update #PartChange set NoOfAlarms=isnull(NoOfAlarms,0) + isnull(T1.Alarmcount,0) from
(
select P.Mcinterface,A.Alarmnumber,count(*) as Alarmcount,P.endtime from AutodataAlarms A
inner join #PartChange P on A.machineid=P.Mcinterface and A.Alarmnumber=P.ToolNo
where A.Alarmtime>=P.starttime and A.Alarmtime<=P.Endtime and A.Recordtype=6
group by P.Mcinterface,A.Alarmnumber,P.endtime
)as T1 inner join #PartChange on #PartChange.endtime=T1.endtime and #PartChange.Mcinterface=T1.Mcinterface and #PartChange.ToolNo=T1.Alarmnumber


--To Get Alarmtimes by comma separated
insert into #Alarmdetails(Machineid,Mcinterface,ToolNo,NoOfAlarms,Alarmtime,Starttime)
select P.machineid,P.Mcinterface,A.Alarmnumber,count(*) as Alarmcount, A.Alarmtime,P.endtime from AutodataAlarms A,#PartChange P
where A.Alarmtime>=P.starttime and A.Alarmtime<=P.Endtime and A.Recordtype=6
and P.Mcinterface=A.machineid and P.ToolNo=A.Alarmnumber
group by P.machineid,P.Mcinterface,A.Alarmnumber,A.Alarmtime,P.endtime


declare @Machine as nvarchar(50),@M_Prev as nvarchar(50)
declare @Tool as decimal(18,2),@Tool_Prev as decimal(18,2)
declare @Toolstart as datetime,@Toolstart_Prev as datetime,@Atime as datetime

declare @Alarmtime cursor  
set @Alarmtime = cursor for 
Select Machineid,ToolNo,Starttime,Alarmtime from #Alarmdetails order by ToolNo,Starttime
open @Alarmtime

Fetch next from @Alarmtime into @Machine,@Tool,@Toolstart,@Atime


while @@Fetch_Status=0
Begin
	if @Machine=@M_Prev and @Tool = @Tool_Prev and @Toolstart=@Toolstart_Prev
	begin
		update #PartChange set Alarmtime=COALESCE(Alarmtime,'') + convert(nvarchar(20),@Atime,120) + ',' where endtime=@Toolstart
	end
	else
	Begin
		update #PartChange set Alarmtime=COALESCE(Alarmtime,'') + convert(nvarchar(20),@Atime,120) + ',' where endtime=@Toolstart
		set @Machine=@M_Prev
		set @Tool = @Tool_Prev 
		set @Toolstart=@Toolstart_Prev
	end
	Fetch next from @Alarmtime into @Machine,@Tool,@Toolstart,@Atime
end
close @Alarmtime
Deallocate @Alarmtime



update #PartChange set NoOfTimesChanged=isnull(NoOfTimesChanged,0) + isnull(T1.Toolcount,0) from
(
select P.Mcinterface,P.ToolNo,Count(P.ToolNo) as Toolcount from #PartChange P
group by P.Mcinterface,P.ToolNo
)as T1 inner join #PartChange on #PartChange.Mcinterface=T1.Mcinterface and #PartChange.ToolNo=T1.Toolno


update #PartChange set changetime=isnull(changetime,0) + isnull(T1.Ctime,0) from(
select P.Mcinterface,P.ToolNo,P.endtime as Ctime from #PartChange P
)as T1 inner join #PartChange on #PartChange.endtime=T1.Ctime and #PartChange.Mcinterface=T1.Mcinterface and #PartChange.ToolNo=T1.ToolNo


Select @strsql=''
select @strsql ='insert into #ToolDetails(Machineid,Mcinterface,Component,Compinterface,Operation,Opninterface,ToolNo,ToolDescription,NoOfAlarms,Alarmtime,
				NoOfTimesChanged,ChangeTime,TotalParts,PartsByCO,Starttime,Endtime,Suboperation) '
select @strsql = @strsql + 'SELECT distinct  Machineinformation.Machineid,Machineinformation.interfaceid,
				componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,
				componentoperationpricing.interfaceid,P.ToolNo, P.ToolDescription, P.NoOfAlarms, P.Alarmtime, P.NoOfTimesChanged, '
select @strsql = @strsql + ' P.ChangeTime,0,0,P.Starttime,P.Endtime,componentoperationpricing.SubOperations from autodata 
							 inner join machineinformation on machineinformation.interfaceid=autodata.mc '  
select @strsql = @strsql + ' inner join componentinformation ON autodata.comp = componentinformation.InterfaceID '
select @strsql = @strsql + ' INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID'
select @strsql = @strsql + ' AND componentinformation.componentid = componentoperationpricing.componentid '
select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '
select @strsql = @strsql + ' cross join #PartChange P '
select @strsql = @strsql + ' inner join Toolsequence T on P.ToolNo=T.ToolNo and T.Componentid=componentoperationpricing.componentid and T.operationno=componentoperationpricing.InterfaceID'
select @strsql = @strsql + ' where machineinformation.machineid= ''' + @machineid + ''' and (autodata.datatype=1) and'
select @strsql = @strsql + '( ndtime > Convert(nvarchar(20),P.Starttime,120) and ndtime <= convert(nvarchar(20),P.endtime,120) ) '
select @strsql = @strsql + ' order by P.endtime'
print @strsql
exec (@strsql)


--Calculation of PartsCount Begins..
UPDATE #ToolDetails SET TotalParts = ISNULL(TotalParts,0) + ISNULL(t2.comp,0)
From
(
	  Select T1.mc,T1.ToolNo,T1.starttime,T1.endtime,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(T1.SubOperation,1))) As Comp 
		   From (select A.mc,SUM(A.partscount)AS OrginalCount,A.comp,A.opn,T.Toolno,T.suboperation,T.starttime,T.endtime from autodata A
			inner join #ToolDetails T on A.mc=T.Mcinterface and A.Comp=T.Compinterface and A.Opn=T.Opninterface
		   where (A.ndtime>T.starttime) and (A.ndtime<=T.endtime) and (A.datatype=1)
		   Group By A.mc,A.comp,A.opn,T.Toolno,T.suboperation,T.starttime,T.endtime) as T1	
	GROUP BY T1.mc,T1.ToolNo,T1.starttime,T1.endtime
) As T2 Inner join #ToolDetails on T2.mc = #ToolDetails.Mcinterface and #ToolDetails.ToolNo=T2.ToolNo and #ToolDetails.starttime=T2.starttime and #ToolDetails.endtime=T2.endtime

--Mod 4 Apply PDT for calculation of Count
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN

	UPDATE #ToolDetails SET TotalParts = ISNULL(TotalParts,0) - ISNULL(T2.comp,0) from
	(
	 Select T1.mc,T1.ToolNo,T1.starttime,T1.endtime,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(T1.SubOperation,1))) As Comp from
		( 
			select A.mc,SUM(A.partscount)AS OrginalCount,A.comp,A.opn,T.Toolno,T.suboperation,T.starttime,T.endtime from autodata A
			inner join #ToolDetails T on A.mc=T.Mcinterface and A.Comp=T.Compinterface and A.Opn=T.Opninterface
			CROSS JOIN #PlannedDownTimes T1
			where (A.ndtime>T.starttime and A.ndtime<=T.endtime) 
			AND (A.ndtime>T1.StartTime AND A.ndtime<=T1.EndTime) and (A.datatype=1)
			Group By A.mc,A.comp,A.opn,T.Toolno,T.suboperation,T.starttime,T.endtime
		) as T1
	GROUP BY T1.mc,T1.ToolNo,T1.starttime,T1.endtime
	) as T2 Inner join #ToolDetails on T2.mc = #ToolDetails.Mcinterface and #ToolDetails.ToolNo=T2.ToolNo and #ToolDetails.starttime=T2.starttime and #ToolDetails.endtime=T2.endtime
END


--Calculation of PartsCount Begins at MCO Level..
UPDATE #ToolDetails SET PartsByCO = ISNULL(PartsByCO,0) + ISNULL(t2.Compcount,0)
From
(
	  Select T1.mc,T1.comp,T1.opn,T1.ToolNo,T1.starttime,T1.endtime,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(T1.SubOperation,1))) As Compcount 
		   From (select A.mc,SUM(A.partscount)AS OrginalCount,A.comp,A.opn,T.Toolno,T.suboperation,T.starttime,T.endtime from autodata A
			inner join #ToolDetails T on A.mc=T.Mcinterface and A.Comp=T.Compinterface and A.Opn=T.Opninterface
		   where (A.ndtime>T.starttime) and (A.ndtime<=T.endtime) and (A.datatype=1)
		   Group By A.mc,A.comp,A.opn,T.Toolno,T.suboperation,T.starttime,T.endtime) as T1	
	GROUP BY T1.mc,T1.comp,T1.opn,T1.ToolNo,T1.starttime,T1.endtime
) As T2 Inner join #ToolDetails on T2.mc = #ToolDetails.Mcinterface and #ToolDetails.ToolNo=T2.ToolNo and #ToolDetails.starttime=T2.starttime and #ToolDetails.endtime=T2.endtime
and T2.Comp=#ToolDetails.Compinterface and T2.Opn=#ToolDetails.Opninterface

--Mod 4 Apply PDT for calculation of Count at MCO Level
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN

	UPDATE #ToolDetails SET PartsByCO = ISNULL(PartsByCO,0) - ISNULL(T2.Compcount,0) from
	(
	 Select T1.mc,T1.comp,T1.opn,T1.ToolNo,T1.starttime,T1.endtime,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(T1.SubOperation,1))) As Compcount from
		( 
			select A.mc,SUM(A.partscount)AS OrginalCount,A.comp,A.opn,T.Toolno,T.suboperation,T.starttime,T.endtime from autodata A
			inner join #ToolDetails T on A.mc=T.Mcinterface and A.Comp=T.Compinterface and A.Opn=T.Opninterface
			CROSS JOIN #PlannedDownTimes T1
			where (A.ndtime>T.starttime and A.ndtime<=T.endtime) 
			AND (A.ndtime>T1.StartTime AND A.ndtime<=T1.EndTime) and (A.datatype=1)
			Group By A.mc,A.comp,A.opn,T.Toolno,T.suboperation,T.starttime,T.endtime
		) as T1
	GROUP BY T1.mc,T1.comp,T1.opn,T1.ToolNo,T1.starttime,T1.endtime
	) as T2 Inner join #ToolDetails on T2.mc = #ToolDetails.Mcinterface and #ToolDetails.ToolNo=T2.ToolNo and #ToolDetails.starttime=T2.starttime and #ToolDetails.endtime=T2.endtime
   and T2.Comp=#ToolDetails.Compinterface and T2.Opn=#ToolDetails.Opninterface

END


select ToolNo,ToolDescription,NoOfAlarms,Alarmtime,NoOfTimesChanged,ChangeTime,TotalParts,Component + ' [' + Operation + ']' as Partandopn,PartsByCO from #ToolDetails order by ToolNo,endtime
End
 
