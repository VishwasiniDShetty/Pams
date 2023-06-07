/****** Object:  Procedure [dbo].[FocasWeb_ViewShift&HourwiseSummary]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************************************
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '','Allplants'
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '','AllShifts'
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '','AllMachines'

--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '2016-08-10','SHIFTWISESUMMARY'
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '2016-08-10','Hourwisecycles'
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '2016-08-10','HOURWISETIMEINFO'
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '2016-08-10','SHIFTWISESTOPPAGES'


--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '2017-08-09',''

**********************************************************************************/


CREATE PROCEDURE [dbo].[FocasWeb_ViewShift&HourwiseSummary]  
	@Date datetime ='', 
	@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN



create table #finaldata
(
Date datetime,
PlantCode nvarchar(50),
PlantID nvarchar(50),
MCInterface nvarchar(50),
MachineId nvarchar(50),
DisplayOrder int,
ShiftID int,
ShiftName nvarchar(50),
ColumnName nvarchar(50),
DisplayName nvarchar(50),
ColumnValue float,
DayValue float,
Navid nvarchar(50)
)

Create table #Machine
(
PlantCode nvarchar(50),
PlantID nvarchar(50),
MCInterface nvarchar(50),
MachineId nvarchar(50),
RunningPart nvarchar(50),
Partscount int,
Stoppages float,
McStatus nvarchar(50),
Color nvarchar(50),
MachineMTB nvarchar(50)
)

--If @param='AllShifts'
--Begin
	Select Distinct S.ShiftID,S.ShiftName from Shiftdetails S
	Where S.Running=1
	Order by S.ShiftID
--End


--If @param='AllPlants'
--Begin
	Select Distinct P.PlantCode,P.Plantid from PlantInformation P 
	Order by P.PlantID
--End

--If @param='AllMachines'
--Begin
	Insert into #Machine(PlantCode,PlantID,MCInterface,MachineId,RunningPart,Partscount,Stoppages,McStatus,MachineMTB)
	Select PIN.PlantCode,P.PlantID,M.Interfaceid,M.Machineid,0,0,0,0,M.MachineMTB from PlantInformation PIN
	Inner join PlantMachine P on P.PlantID=PIN.Plantid
	Inner Join Machineinformation M on P.Machineid=M.Machineid
	where M.DNCTransferEnabled=1 --Replaced DNCEnabled instead of TPMEnabled for Kennametal 
	Order by PIN.PlantID,M.MachineID

	Update #Machine Set Partscount = T1.Parts From 
	(Select Date,PlantID,MachineID,SUM(Partcount) as Parts from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120)
	Group By Date,PlantID,MachineID)T1 
	inner join #Machine on #Machine.PlantID=T1.PlantID AND #Machine.MachineID=T1.MachineID 

	Update #Machine Set Stoppages = T1.Stoppages From 
	(Select Date,PlantID,MachineID,SUM(Stoppages) as Stoppages from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120)
	Group By Date,PlantID,MachineID)T1 
	inner join #Machine on #Machine.PlantID=T1.PlantID AND #Machine.MachineID=T1.MachineID 

	Update #Machine Set RunningPart=T.Programno From 
	(Select T1.Plantid,T1.Machineid,L.Programno from
	(Select P.PlantID,P.MachineID,Max(Cnctimestamp) as CTS
	 from Focas_livedata L Inner Join PlantMachine P on P.machineid=L.Machineid
	inner join Machineinformation M on L.Machineid=M.Machineid and P.Machineid=M.Machineid
	where Convert(Nvarchar(10),L.cnctimestamp,120)=Convert(Nvarchar(10),@date,120)
	Group By P.PlantID,P.MachineID)T1 inner join Focas_livedata L on T1.machineid=L.Machineid and T1.CTS=L.cnctimestamp
	)T inner join #Machine on #Machine.PlantID=T.PlantID AND #Machine.MachineID=T.MachineID 

	Update #Machine Set McStatus = T1.McStatus,Color=T1.Color From 
	(Select T.PlantID,T.MachineID,
	 Case 
	 when MachineStatus='In Cycle' then 'Running'
	 when MachineStatus='Alarm' then 'Alarm'
	 when MachineStatus='Emergency' then 'Alarm'
	 when MachineStatus='Idle' then 'Stopped'
	 when MachineStatus='Feed Hold' then 'Stopped'
	 when MachineStatus='STOP' then 'Stopped'
	 when MachineStatus='Unavailable' then 'Stopped'
	 when MachineStatus=NULL then 'Stopped'
	End as McStatus,
	 Case 
	 when MachineStatus='In Cycle' then 'Green'
	 when MachineStatus='Alarm' then 'Red'
	 when MachineStatus='Emergency' then 'Red'
	 when MachineStatus='Idle' then 'Yellow'
	 when MachineStatus='Feed Hold' then 'Yellow'
	 when MachineStatus='STOP' then 'Yellow'
	 when MachineStatus='Unavailable' then 'Yellow'
	 when MachineStatus=NULL then 'Yellow'

	End as Color from 
	(Select P.plantid,M.Machineid,Max(cnctimestamp) as cts from	Focas_livedata L 
	Inner Join PlantMachine P on P.machineid=L.Machineid
	inner join Machineinformation M on L.Machineid=M.Machineid and P.Machineid=M.Machineid
	where Convert(Nvarchar(10),L.cnctimestamp,120)=Convert(Nvarchar(10),@Date,120)
	Group By P.PlantID,M.MachineID)T inner join Focas_livedata L on L.machineid=T.Machineid and L.cnctimestamp=T.cts)T1 inner join #Machine on #Machine.PlantID=T1.PlantID AND #Machine.MachineID=T1.MachineID 

	Update #Machine Set McStatus = 'Stopped',Color='Yellow' where  McStatus='0'


	Select PlantCode,PlantID,MCInterface,MachineId,RunningPart,Partscount,dbo.f_FormatTime(Stoppages,'hh:mm') as Stoppages,McStatus,color,MachineMTB from #Machine
--End

--IF @Param = 'SHIFTWISESUMMARY'
--BEGIN

insert into #finaldata(Date,PlantCode,PlantID,MCInterface,MachineID,DisplayOrder,ShiftID,ShiftName,ColumnName,DisplayName,Navid)
select F.Date,PIN.PlantCode,F.plantID,M.Interfaceid,F.MachineID,C.Sortorder,F.ShiftID,F.Shift,C.Rowheader,C.DisplayName,C.Navid from FocasWeb_ShiftwiseSummary F
inner join PlantInformation PIN on F.PlantID=PIN.PlantID
Inner join PlantMachine P on P.PlantID=PIN.Plantid
Inner Join Machineinformation M on P.Machineid=M.Machineid and F.Machineid=M.Machineid
Cross Join FocasWeb_RowHeader C  where M.DNCTransferEnabled=1 and Convert(Nvarchar(10),F.Date,120)=Convert(Nvarchar(10),@Date,120) order By C.Sortorder,F.ShiftID


Update #finaldata Set ColumnValue = T1.TotalTime From 
(Select Date,PlantID,MachineID,Shift,TotalTime from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='Totaltime'

Update #finaldata Set ColumnValue = T1.Powerontime From 
(Select Date,PlantID,MachineID,Shift,Powerontime from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='Powerontime'

Update #finaldata Set ColumnValue = T1.OperatingTime From 
(Select Date,PlantID,MachineID,Shift,OperatingTime from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='Operatingtime'

Update #finaldata Set ColumnValue = T1.Cuttingtime From 
(Select Date,PlantID,MachineID,Shift,Cuttingtime from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='Cuttingtime'

Update #finaldata Set ColumnValue = T1.Stoppages From 
(Select Date,PlantID,MachineID,Shift,Stoppages from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='Stoppagetime'

Update #finaldata Set ColumnValue = T1.Partcount From 
(Select Date,PlantID,MachineID,Shift,Partcount from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='cycles'

Update #finaldata Set Dayvalue = T1.Stoppages From 
(Select Date,PlantID,MachineID,SUM(ColumnValue) as  Stoppages from #finaldata where #finaldata.ColumnName='Stoppagetime'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID and #finaldata.ColumnName='Stoppagetime'

Update #finaldata Set Dayvalue = T1.Parts From 
(Select Date,PlantID,MachineID,SUM(ColumnValue) as  Parts from #finaldata where #finaldata.ColumnName='cycles'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID  and #finaldata.ColumnName='cycles'

Update #finaldata Set Dayvalue = T1.Cuttingtime From 
(Select Date,PlantID,MachineID,SUM(ColumnValue) as  Cuttingtime from #finaldata where #finaldata.ColumnName='Cuttingtime'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID  and #finaldata.ColumnName='Cuttingtime'

Update #finaldata Set Dayvalue = T1.Operatingtime From 
(Select Date,PlantID,MachineID,SUM(ColumnValue) as  Operatingtime from #finaldata where #finaldata.ColumnName='Operatingtime'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID and #finaldata.ColumnName='Operatingtime'

Update #finaldata Set Dayvalue = T1.Powerontime From 
(Select Date,PlantID,MachineID,SUM(ColumnValue) as  Powerontime from #finaldata where #finaldata.ColumnName='Powerontime'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID and  #finaldata.ColumnName='Powerontime'

Update #finaldata Set Dayvalue = T1.Totaltime From 
(Select Date,PlantID,MachineID,SUM(ColumnValue) as  Totaltime from #finaldata where #finaldata.ColumnName='Totaltime'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.ColumnName='Totaltime'


CREATE TABLE #t
(
PlantCode nvarchar(50),
PlantID nvarchar(50),
MCInterface nvarchar(50),
MachineId nvarchar(50),
DisplayName nvarchar(50),
DisplayOrder int,
Navid nvarchar(50),
ColumnName1 nvarchar(50),
ColumnName2 nvarchar(50),
ColumnName3 nvarchar(50),
DayValue nvarchar(50)
)


declare @countofshift as int
select @countofshift=count(*) from Shiftdetails where running=1

INSERT INTO #t(PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,dayvalue,Columnname1)
SELECT PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,case when Columnname<>'cycles' then dbo.f_FormatTime(DayValue,'hh:mm') else cast(DayValue as nvarchar(50)) end
,case when Columnname<>'cycles' then dbo.f_FormatTime(SUM(ColumnValue),'hh:mm') else cast(SUM(ColumnValue) as nvarchar(50)) end  from #finaldata 
where shiftname=(select distinct shiftname from #finaldata where shiftid=1)
group by PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,Columnname,DayValue
order by PlantID,Machineid,DisplayOrder

UPDATE #t SET Columnname2=t.Columnname2 FROM
(SELECT PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,case when Columnname<>'cycles' then dbo.f_FormatTime(SUM(ColumnValue),'hh:mm') else cast(SUM(ColumnValue) as nvarchar(50)) end as Columnname2 from #finaldata  
where shiftname=(select distinct shiftname from #finaldata where shiftid=2)
group by PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,Columnname)T
INNER JOIN #T ON #T.MCInterface=T.MCInterface AND #T.DisplayName=t.DisplayName

declare @NameofShift as nvarchar(20)
select @NameofShift=''
SELECT @NameofShift = Shiftname from shiftdetails where Shiftid=1 and running=1
EXEC tempdb.sys.sp_rename N'[tempdb].[dbo].[#T].Columnname1', 
@NameofShift, N'COLUMN';

select @NameofShift=''
SELECT @NameofShift = Shiftname from shiftdetails where Shiftid=2 and running=1
EXEC tempdb.sys.sp_rename N'[tempdb].[dbo].[#T].Columnname2', 
@NameofShift, N'COLUMN';

If @countofshift=3
Begin
	UPDATE #t SET Columnname3=t.Columnname3 FROM
	(SELECT PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,case when Columnname<>'cycles' then dbo.f_FormatTime(SUM(ColumnValue),'hh:mm') else cast(SUM(ColumnValue) as nvarchar(50)) end AS Columnname3 from #finaldata  
	where shiftname=(select distinct shiftname from #finaldata where shiftid=3)
	group by PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,Columnname)T
	INNER JOIN #T ON #T.MCInterface=T.MCInterface AND #T.DisplayName=t.DisplayName

	select @NameofShift=''
	SELECT @NameofShift = Shiftname from shiftdetails where Shiftid=3 and running=1
	EXEC tempdb.sys.sp_rename N'[tempdb].[dbo].[#T].Columnname3', 
	@NameofShift, N'COLUMN';

End


SELECT * FROM #T order by PlantID,Machineid,DisplayOrder


--DECLARE @cols AS NVARCHAR(MAX),@query  AS NVARCHAR(MAX),@MachineList as NVARCHAR(MAX)
--
--
--select @cols = STUFF((SELECT distinct ',' + QUOTENAME(Shiftname) 
--					from #finaldata
--                   
--			FOR XML PATH(''), TYPE
--			).value('.', 'NVARCHAR(MAX)') 
--		,1,1,'')
--

--set @query = 'SELECT PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,case when Columnname<>''cycles'' then dbo.f_FormatTime(SUM([A]),''hh:mm'') else cast(SUM([A]) as nvarchar(50)) end as A,
--			 case when Columnname<>''cycles'' then dbo.f_FormatTime(SUM([B]),''hh:mm'') else cast(SUM([B]) as nvarchar(50)) end as B, 
--			 case when Columnname<>''cycles'' then dbo.f_FormatTime(SUM([C]),''hh:mm'') else cast(SUM([C]) as nvarchar(50)) end as C,
--			 case when Columnname<>''cycles'' then dbo.f_FormatTime(DayValue,''hh:mm'') else cast(DayValue as nvarchar(50)) end as DayValue  from 
--			 (
--				select PlantCode,PlantID,MCInterface,Machineid,DisplayOrder,DisplayName,Columnname,ColumnValue,Shiftname,ShiftId,
--				DayValue,NavID
--				from #finaldata 
--			) x
--			pivot 
--			(
--				SUM(ColumnValue)
--				for Shiftname in ([A],[B],[C])
--			) p1 group by PlantCode,PlantID,MCInterface,Machineid,displayname,Columnname,DisplayOrder,DayValue,NavID order by PlantID,Machineid,DisplayOrder
--			'
--
--execute(@query);



--END


--IF @PARAM = 'HOURWISECYCLES'
--BEGIN
	Select PIN.PlantCode,F.PlantID, M.Interfaceid AS MCInterface,F.MachineID, F.Shiftid , F.Shift, F.HourID,F.HourStart, F.HourEnd, F.ProgramID, F.PartCount FROM FocasWeb_HourwiseCycles F
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner join PlantMachine P on P.PlantID=PIN.Plantid
	Inner Join Machineinformation M on P.Machineid=M.Machineid and F.Machineid=M.Machineid
	where M.DNCTransferEnabled=1 and Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By PIN.PlantID,F.MachineID,ShiftID,HourID
--END

--IF @PARAM = 'HOURWISETIMEINFO'
--BEGIN

	Select Convert(Nvarchar(10),F.Date,120) as Tdate,F.PlantID,F.MachineID, F.ShiftID, F.Shift,SUM(F.PowerOntime) as TotalPOT,
	SUM(F.OperatingTime) as TotalOT,SUM(F.CuttingTime) as TotalCT Into #Times_Summary from FocasWeb_HourwiseTimeInfo F
	Group by F.Date,F.PlantID,F.MachineID, F.ShiftID, F.Shift


	SELECT PIN.PlantCode,F.PlantID,M.Interfaceid AS MCInterface,F.MachineID, F.ShiftID, F.Shift, F.HourID, F.HourStart, F.HourEnd, 
	dbo.f_FormatTime(F.PowerOntime,'hh:mm') as PowerOntime, dbo.f_FormatTime(F.OperatingTime,'hh:mm') as OperatingTime,
	dbo.f_FormatTime(F.CuttingTime,'hh:mm') as CuttingTime,round(F.PowerOntime/60,0) as PowerOntimeint,Round(F.OperatingTime/60,0) as Operatingtimeint,
	Round(F.CuttingTime/60,0) AS Cuttingtimeint,dbo.f_FormatTime(T.TotalPOT,'hh:mm') as TotalPOT, dbo.f_FormatTime(T.TotalOT,'hh:mm') as TotalOT,
	dbo.f_FormatTime(T.TotalCT,'hh:mm') as TotalCT
	FROM FocasWeb_HourwiseTimeInfo F 
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner join PlantMachine P on P.PlantID=PIN.Plantid
	Inner Join Machineinformation M on P.Machineid=M.Machineid and F.Machineid=M.Machineid
	left outer join #Times_Summary T on Convert(Nvarchar(10),F.Date,120)=Convert(Nvarchar(10),T.TDate,120) and T.Plantid=F.Plantid and T.Machineid=F.Machineid and T.Shift=F.Shift
	where M.DNCTransferEnabled=1 and Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By PIN.PlantID, F.MachineID, F.ShiftID , HourID

--END

--IF @PARAM = 'SHIFTWISESTOPPAGES'
--BEGIN

	SELECT PIN.PlantCode,F.PlantID, M.Interfaceid AS MCInterface,F.MachineID,F.ShiftID, F.Shift, F.Batchstart, F.BatchEnd,
    dbo.f_FormatTime(F.StoppageTime,'hh:mm')as StoppageTime, F.Reason
	FROM  FocasWeb_ShiftwiseStoppages F
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner join PlantMachine P on P.PlantID=PIN.Plantid
	Inner Join Machineinformation M on P.Machineid=M.Machineid and F.Machineid=M.Machineid
	where M.DNCTransferEnabled=1 and Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By PIN.PlantCode, F.MachineID,ShiftID,Batchstart

--END

	Create table #Alarm
	(
	PDate datetime,  
	Shift nvarchar(20),  
	ShiftStart datetime,  
	ShiftEnd datetime, 
	ShiftID int,
	PlantCode nvarchar(20),  
	PlantId nvarchar(20),  
	Mcinterface nvarchar(20),  
	Machineid nvarchar(20),  
	AlarmNo bigint,
	Fromtime datetime,
	Totime Datetime,
	Duration float,
	Shiftcount int,
	Totalduration float,
	AlarmMSG nvarchar(max)
	)


	CREATE TABLE #ShiftDetails   
	(  
	 SlNo bigint identity(1,1) NOT NULL,
	 PDate datetime,  
	 Shift nvarchar(20),  
	 ShiftStart datetime,  
	 ShiftEnd datetime,
	 ShiftID int 
	)  
	
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)   
	EXEC s_GetShiftTime @Date,''  

	Update #ShiftDetails Set Shiftid = T1.Shiftid From
	(Select Shiftid,Shiftname from Shiftdetails where running=1)T1 inner join #ShiftDetails on #ShiftDetails.Shift=T1.shiftname


	Insert into #Alarm(PlantCode,Plantid,Mcinterface,Machineid,Pdate, Shift, ShiftStart, ShiftEnd,Shiftid,AlarmNo,AlarmMSG,Fromtime,Totime,Duration)
	Select PIN.PlantCode,P.PlantID, M.Interfaceid AS MCInterface,M.MachineID,S.Pdate, S.Shift, S.ShiftStart, S.ShiftEnd,S.Shiftid,
	F.AlarmNo,F.AlarmMSG,F.AlarmTime,F.Endtime,Datediff(second,F.AlarmTime,F.Endtime) from 
	Focas_Alarmhistory F Cross join #ShiftDetails S
	left outer join Focas_AlarmCategory c on  F.AlarmGroupNo = C.AlarmNo    
	left outer join Focas_AlarmMaster A on A.Alarmno=F.AlarmNo
	Inner Join Machineinformation M on F.Machineid=M.Machineid 
	Inner join PlantMachine P on P.Machineid=M.Machineid 
	inner join PlantInformation PIN on P.PlantID=PIN.PlantID
	where M.DNCTransferEnabled=1 and F.Alarmtime between S.Shiftstart and S.Shiftend
	Order by P.PlantID,M.MachineID,S.Shiftid,F.AlarmTime,F.AlarmMSG

	update #Alarm Set Shiftcount = T1.Shiftcount,Totalduration=T1.TotalTime From 
	(Select PlantID,Machineid,Shift,Count(AlarmNo) as Shiftcount,SUM(Duration) as TotalTime From #Alarm
	 Group by PlantID,Machineid,Shift)T1 inner Join #Alarm on #Alarm.PlantID=T1.PlantID and #Alarm.Machineid=T1.Machineid and #Alarm.Shift=T1.Shift 


	Select PlantCode,Plantid,Mcinterface,Machineid,Shiftid,Shift,AlarmNo,AlarmMSG,Fromtime,Totime,dbo.f_FormatTime(Duration,'hh:mm')as Duration, 
    Shiftcount,dbo.f_FormatTime(Totalduration,'hh:mm')as Totalduration  from #Alarm
	where ( AlarmNo < 1150  OR AlarmNo > 1172 ) Order by PlantID,MachineID,Shiftid,Fromtime


	Select PlantCode,Plantid,Mcinterface,Machineid,Shiftid,Shift,AlarmNo,AlarmMSG,Max(Fromtime) as Lastseen,Count(AlarmNo) as NoOfOccurences 
    from #Alarm where (AlarmNo < 1150  OR AlarmNo > 1172 ) Group by PlantCode,Plantid,Mcinterface,Machineid,Shiftid,Shift,AlarmNo,AlarmMSG
	Order by PlantID,MachineID,Shiftid

	SELECT  Slno, AlarmNo, Flag, FilePath, Description, Cause, Solution, MTB FROM  Focas_AlarmMaster where ( AlarmNo < 1150  OR AlarmNo > 1172 ) Order by MTB,Alarmno

END
