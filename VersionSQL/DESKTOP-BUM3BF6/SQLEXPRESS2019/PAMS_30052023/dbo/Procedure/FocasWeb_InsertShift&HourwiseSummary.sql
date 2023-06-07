/****** Object:  Procedure [dbo].[FocasWeb_InsertShift&HourwiseSummary]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[FocasWeb_InsertShift&HourwiseSummary] '2020-12-14'
CREATE PROCEDURE [dbo].[FocasWeb_InsertShift&HourwiseSummary]  
@StartDate datetime=''
WITH RECOMPILE
AS
BEGIN
	
SET NOCOUNT ON
DECLARE @update_count int
DECLARE @ErrorCode  int  
DECLARE @ErrorStep  varchar(200)
DECLARE @Return_Message VARCHAR(1024) 
SET @ErrorCode = 0
SET @Return_Message = ''


Declare @Date as Datetime
If @StartDate= ''
Begin
	SET @Date=getdate()
End
Else
Begin
	SET @Date=@StartDate
End

Create Table #ShiftwiseSummary  
(  
	[Sl No] Bigint Identity(1,1) Not Null, 
	[PlantID] nvarchar(50), 
	[Machineid] nvarchar(50),  
	[MachineStatus] nvarchar(100),
	[RunningProgram] nvarchar(100),
	[ShiftDate] datetime,  
	[ShiftName] nvarchar(50),  
	[From time] datetime,  
	[To Time] datetime,  
	[TotalTime] float,
	[Powerontime] float,  
	[Cutting time] float,  
	[Operating time] float,
	[PartsCount] int, 
	[ProgramNo] nvarchar(50),
	[Stoppagetime] float,
	[ShiftID] int
)  





CREATE TABLE #ShiftDetails   
(  
 SlNo bigint identity(1,1) NOT NULL,
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime  
)  


Create Table #HourwiseSummary  
(  
	[Sl No] Bigint Identity(1,1) Not Null, 
	[PlantID] nvarchar(50), 
	[Machineid] nvarchar(50),  
	[MachineStatus] nvarchar(100),
	[RunningProgram] nvarchar(100),
	[ShiftDate] datetime,  
	[ShiftName] nvarchar(50),  
	[From time] datetime,  
	[To Time] datetime,  
	[TotalTime] float,
	[Powerontime] float,  
	[Cutting time] float,  
	[Operating time] float,
	[PartsCount] int, 
	[ProgramNo] nvarchar(50),
	[Stoppagetime] float,
	[HourID] int,
	[Shiftid] int
)


CREATE TABLE #HourDetails   
(  
 PDate datetime,  
 Shift nvarchar(20), 
 Shiftid int,
 HourID int, 
 HourStart datetime,  
 HourEnd datetime  
) 

CREATE TABLE #Shift_MachinewiseStoppages
(
	id bigint identity(1,1),
	[PlantID] nvarchar(50),
	[ShiftDate] datetime,  
	[ShiftName] nvarchar(50),  
 	[ShiftID] int,
	Machineid nvarchar(50),
	Fromtime datetime,
	Totime datetime,
	BatchTS	datetime,
	BatchStart datetime,
	BatchEnd datetime,
	Stoppagetime int,
	MachineStatus nvarchar(50),
	Reason nvarchar(50)
)

CREATE TABLE #Hour_MachinewiseStoppages
(
	id bigint identity(1,1),
	Machineid nvarchar(50),
	Fromtime datetime,
	Totime datetime,
	BatchTS	datetime,
	BatchStart datetime,
	BatchEnd datetime,
	Stoppagetime int,
	MachineStatus nvarchar(50),
	Reason nvarchar(50)
)

Declare @strsql nvarchar(4000)  
Select @strsql = ''  


INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)   
EXEC s_GetShiftTime @Date,''  


Insert into #ShiftwiseSummary (PlantID,Machineid,ShiftDate,[From time],[To Time],ShiftID,ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],Stoppagetime)   --SV
SELECT distinct Plantmachine.PlantID,Machineinformation.machineid,S.PDate,S.shiftstart,S.shiftend,S.ShiftID,S.Shift,0,0,0,0,0 FROM dbo.Machineinformation  
left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid  
Cross join (Select T.Pdate, T.Shift, S.ShiftID , T.ShiftStart, T.ShiftEnd from #ShiftDetails T inner join Shiftdetails S on S.Shiftname=T.Shift where S.Running=1) S
--where Plantmachine.PlantID IS NOT NULL AND Machineinformation.TPMTrakenabled=1  --Commented for Kennametal instead of TPMEnabled looking for DNCEnabled
where Plantmachine.PlantID IS NOT NULL AND Machineinformation.DNCTransferEnabled=1 


declare @Counter as datetime
declare @stdate as nvarchar(20)
select @counter=convert(datetime, cast(DATEPART(yyyy,@Date)as nvarchar(4))+'-'+cast(datepart(mm,@Date)as nvarchar(2))+'-'+cast(datepart(dd,@Date)as nvarchar(2)) +' 00:00:00.000')         
select @stdate = CAST(datePart(yyyy,@Date) AS nvarchar(4)) + '-' + CAST(datePart(mm,@Date) AS nvarchar(2)) + '-' + CAST(datePart(dd,@Date) AS nvarchar(2))         


insert  #HourDetails (PDate,Shift,Shiftid,Hourstart,Hourend,HourID)         
select @counter,S.ShiftName, S.Shiftid,       
dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),         
dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2))))),SH.HourID       
from (Select distinct ShiftName,Shiftid from #ShiftwiseSummary) S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid                

Insert into #HourwiseSummary (PlantID,Machineid,ShiftDate,Shiftid,HourID,[From time],[To Time],ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],Stoppagetime)   --SV
SELECT distinct PlantMachine.PlantID,Machineinformation.machineid,S.PDate,S.Shiftid,S.Hourid,S.Hourstart,S.Hourend,S.Shift,0,0,0,0,0 FROM dbo.Machineinformation  
left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid  
--Cross join #HourDetails S where Plantmachine.PlantID IS NOT NULL AND Machineinformation.TPMTrakenabled=1 --Commented for Kennametal instead of TPMEnabled looking for DNCEnabled
Cross join #HourDetails S where Plantmachine.PlantID IS NOT NULL AND Machineinformation.DNCTransferEnabled=1 

declare @DataStart as datetime
declare @DataEnd as datetime

select @DataStart= (select top 1 [From Time] from #ShiftwiseSummary order by [From Time])
select @DataEnd = (select top 1 [To Time] from #ShiftwiseSummary order by [From Time] desc)

select MachineID, MachineStatus, MachineMode, ProgramNo, PowerOnTime, OperatingTime, CutTime, CNCTimeStamp, PartsCount, BatchTS, MachineUpDownStatus, MachineUpDownBatchTS,Programblock
into #FocasLivedata from dbo.focas_livedata with(NOLOCK) where cnctimestamp>=@DataStart and cnctimestamp<=@DataEnd



declare @threshold as int
Select @threshold = isnull(ValueInText,5) from Focas_Defaults where parameter='DowntimeThreshold'


If @threshold = '' or @threshold is NULL
Begin
	select @threshold='5'
End

---------------------------- Shiftwise Stoppages ----------------------------------------------------
insert into #Shift_MachinewiseStoppages(PlantID,Machineid,Shiftdate,Shiftid,Shiftname,fromtime,totime,BatchTS,Batchstart,BatchEnd,MachineStatus)
select L1.PlantID,L1.Machineid,L1.Shiftdate,L1.Shiftid,L1.Shiftname,L1.[From Time],L1.[To Time],F.machineupdownbatchts,min(F.cnctimestamp),max(F.cnctimestamp)
,case when F.machineupdownstatus=0 then 'Down'
when F.machineupdownstatus=1 then 'Prod' end from #FocasLivedata F with(NOLOCK)
inner join #ShiftwiseSummary L1 on L1.machineid=F.machineid and F.cnctimestamp>=L1.[From Time] and F.cnctimestamp<=L1.[To Time]
where F.machineupdownbatchts is not null
group by L1.PlantID,L1.Machineid,L1.Shiftdate,L1.Shiftid,L1.Shiftname,L1.[From Time],L1.[To Time],F.machineupdownbatchts,F.machineupdownstatus
order by L1.Machineid,L1.[From Time],F.machineupdownbatchts

update #Shift_MachinewiseStoppages set Stoppagetime = datediff(s,Batchstart,BatchEnd)


Update #ShiftwiseSummary set Stoppagetime = T1.Stoppagetime From
(
select Machineid,fromtime,dbo.f_FormatTime(SUM(Stoppagetime),'ss') as Stoppagetime from  		
	(select Machineid,fromtime,Batchstart,BatchEnd,Stoppagetime,Reason from #Shift_MachinewiseStoppages 
	where Stoppagetime>(@threshold*10) and MachineStatus='Down'
	)T
 group by Machineid,fromtime
 )T1
inner join #ShiftwiseSummary on #ShiftwiseSummary.[From Time] = T1.fromtime and #ShiftwiseSummary.Machineid=T1.MachineID 
---------------------------- Shiftwise Stoppages ----------------------------------------------------


---------------------------- Hourwise Stoppages ----------------------------------------------------
insert into #Hour_MachinewiseStoppages(Machineid,fromtime,totime,BatchTS,Batchstart,BatchEnd,MachineStatus)
select L1.Machineid,L1.[From Time],L1.[To Time],F.machineupdownbatchts,min(F.cnctimestamp),max(F.cnctimestamp)
,case when F.machineupdownstatus=0 then 'Down'
when F.machineupdownstatus=1 then 'Prod' end from #FocasLivedata F with(NOLOCK)
inner join #HourwiseSummary L1 on L1.machineid=F.machineid and F.cnctimestamp>=L1.[From Time] and F.cnctimestamp<=L1.[To Time]
where F.machineupdownbatchts is not null
group by L1.Machineid,L1.[From Time],L1.[To Time],F.machineupdownbatchts,F.machineupdownstatus
order by L1.Machineid,L1.[From Time],F.machineupdownbatchts

update #Hour_MachinewiseStoppages set Stoppagetime = datediff(s,Batchstart,BatchEnd)


Update #HourwiseSummary set Stoppagetime = T1.Stoppagetime From
(
select Machineid,fromtime,dbo.f_FormatTime(SUM(Stoppagetime),'ss') as Stoppagetime from  		
	(select Machineid,fromtime,Batchstart,BatchEnd,Stoppagetime,Reason from #Hour_MachinewiseStoppages 
	where Stoppagetime>(@threshold*10) and MachineStatus='Down'
	)T
 group by Machineid,fromtime
 )T1
inner join #HourwiseSummary on #HourwiseSummary.[From Time] = T1.fromtime and #HourwiseSummary.Machineid=T1.MachineID 
---------------------------- Hourwise Stoppages ----------------------------------------------------


---------------------------- Shiftwise POT,CT,OT,TT ----------------------------------------------------
Update #ShiftwiseSummary set [Powerontime]  = isnull(#ShiftwiseSummary.[Powerontime] ,0) + isnull(T2.Powerontime,0),
[Cutting time]  = isnull([Cutting time] ,0) + isnull(T2.Cuttingtime,0),  
[Operating time]  = isnull([Operating time] ,0) + isnull(T2.Operatingtime,0)  From  
(select L.[From Time]  as TS,F.machineid,Max(F.Powerontime)-Min(F.Powerontime) as Powerontime,
Max(Cuttime)-Min(Cuttime) as Cuttingtime,Max(Operatingtime)-Min(Operatingtime) as Operatingtime from #FocasLivedata F  with(NOLOCK)
inner join #ShiftwiseSummary L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time]  and F.cnctimestamp<=L.[To Time]   
where (F.Powerontime>0 or F.CutTime>0 or F.OperatingTime>0) group by F.machineid,L.[From Time]   
)T2 inner join #ShiftwiseSummary on #ShiftwiseSummary.[From Time] = T2.TS and #ShiftwiseSummary.Machineid=T2.MachineID  
 
--Update #ShiftwiseSummary Set [Cutting time] = round([Cutting time]/60,0) where [Cutting time]>0   
--Update #ShiftwiseSummary Set [Operating time] = round([Operating time] /60,0) where [Operating time]>0 

Update #ShiftwiseSummary Set [Powerontime] = [Powerontime]*60 where [Powerontime]>0   


update #ShiftwiseSummary set [TotalTime]=DATEDIFF( second,[From Time],[To time]) from #ShiftwiseSummary
---------------------------- Shiftwise POT,CT,OT,TT ----------------------------------------------------


---------------------------- Hourwise POT,CT,OT,TT ----------------------------------------------------
Update #HourwiseSummary set [Powerontime]  = isnull(#HourwiseSummary.[Powerontime] ,0) + isnull(T2.Powerontime,0),
[Cutting time]  = isnull([Cutting time] ,0) + isnull(T2.Cuttingtime,0),  
[Operating time]  = isnull([Operating time] ,0) + isnull(T2.Operatingtime,0)  From  
(select L.[From Time]  as TS,F.machineid,Max(F.Powerontime)-Min(F.Powerontime) as Powerontime,
Max(Cuttime)-Min(Cuttime) as Cuttingtime,Max(Operatingtime)-Min(Operatingtime) as Operatingtime from #FocasLivedata F  with(NOLOCK)
inner join #HourwiseSummary L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time]  and F.cnctimestamp<=L.[To Time]   
where (F.Powerontime>0 or F.CutTime>0 or F.OperatingTime>0) group by F.machineid,L.[From Time]   
)T2 inner join #HourwiseSummary on #HourwiseSummary.[From Time] = T2.TS and #HourwiseSummary.Machineid=T2.MachineID  
 
Update #HourwiseSummary Set [Powerontime] = [Powerontime]*60 where [Powerontime]>0   

--Update #HourwiseSummary Set [Cutting time] = round([Cutting time]/60,0) where [Cutting time]>0   
--Update #HourwiseSummary Set [Operating time] = round([Operating time] /60,0) where [Operating time]>0 

update #HourwiseSummary set [TotalTime]=DATEDIFF( SECOND,[From Time],[To time]) from #HourwiseSummary
---------------------------- Hourwise POT,CT,OT,TT ----------------------------------------------------


Create table #GetParts
(
	id bigint identity(1,1),
	Machineid nvarchar(50),
	Fromtime datetime,
	Totime datetime,
	ProgramNo nvarchar(50),
	Partscount int,
	Batchts datetime,
	PrevBatchts datetime,
	PrevCount int,
	CurrentCount int,
	cnctimestamp datetime
)



Create table #TempGetParts
(
	id bigint identity(1,1),
	Machineid nvarchar(50),
	ProgramNo nvarchar(50),
	Partscount int,
	Batchts datetime,
	cnctimestamp datetime
)

truncate table #GetParts
truncate table #TempGetParts



---------------------------- Shiftwise Partscount ----------------------------------------------------

select @strsql=''
select @strsql = @strsql + 'Insert into #tempGetParts(Machineid,ProgramNo,Batchts,Partscount)
select F.machineid,min(F.Programno) as ProgramNo,F.Batchts,0 from #FocasLivedata F with(NOLOCK)
			 inner join #ShiftwiseSummary L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time] and F.partscount is not null    
			where exists
			(
				select liv.ProgramNo From #FocasLivedata liv with(NOLOCK)
				inner join #ShiftwiseSummary L1 on L1.machineid=liv.machineid and liv.cnctimestamp>=L1.[From Time] and liv.cnctimestamp<=L1.[To Time]    
				where liv.MachineMode = ''MEM'' and liv.MachineStatus = ''In Cycle'' and liv.batchts is not null 
				and F.Programno=liv.programno and F.machineid=liv.machineid and F.Batchts=liv.Batchts '
				Select @strsql = @strsql + 'group by liv.ProgramNo
			 )
			group by F.Machineid,F.BatchTs order by F.batchts '
print @strsql
exec(@strsql)


Insert into #GetParts(Machineid,Fromtime,Totime,ProgramNo,Batchts,Partscount,cnctimestamp)
select T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts,Max(F.Partscount)-Min(F.Partscount),min(F.cnctimestamp) from #FocasLivedata F with(NOLOCK)
inner join #tempGetParts T on T.Programno=F.programno and T.machineid=F.machineid and T.Batchts=F.Batchts
inner join #ShiftwiseSummary L1 on L1.machineid=T.machineid and F.cnctimestamp>=L1.[From Time] and F.CNCTimeStamp<=L1.[To Time] 
where F.MachineMode = 'MEM' and F.MachineStatus = 'In Cycle' and F.batchts is not null 
group by T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts
order by T.Machineid,L1.[From Time],T.Batchts


--To get last recorded partscount for the previous batchtime
update #getparts set Prevcount=T1.Partscount from
(Select T.machineid,f.Partscount,T.fromtime,T.cnctimestamp from focas_livedata f inner join
	   (Select g.fromtime,g.machineid,g.cnctimestamp,Max(f.id) as idd from focas_livedata f with(NOLOCK) 
	   inner join #getparts g on f.machineid=g.machineid 
	   where f.cnctimestamp<g.cnctimestamp and f.MachineMode = 'MEM' and f.MachineStatus = 'In Cycle' group by g.machineid,g.fromtime,g.cnctimestamp
	   )T on F.id=T.idd 
)T1 inner join #getparts on #getparts.machineid=T1.machineid and #GetParts.Fromtime=T1.fromtime and #GetParts.cnctimestamp=T1.cnctimestamp



--To get first recorded partscount for the current batchtime
update #getparts set currentcount=T1.Partscount from
(Select g.fromtime,g.machineid,g.cnctimestamp,f.partscount as Partscount from #FocasLivedata f with(NOLOCK) 
inner join #getparts g on f.machineid=g.machineid and g.cnctimestamp=f.cnctimestamp
where f.MachineMode = 'MEM' and f.MachineStatus = 'In Cycle' 
)T1 inner join #getparts on #getparts.machineid=T1.machineid and #GetParts.Fromtime=T1.fromtime and #GetParts.cnctimestamp=T1.cnctimestamp


--Logic to consider Partcount : if Prevcount<Curcount then 1 elseif Prevcount>Curcount or Prevcount=CurCount then 0 and add it to the existing Partscount and Prevcount SHOULD NOT BE NULL.
update #getparts set Partscount=isnull(Partscount,0)  + isnull(T1.Pcount,0) from
(Select machineid,fromtime,cnctimestamp,case
when Prevcount>=Currentcount then 0  
when PrevCount<CurrentCount THEN 1  
when Prevcount is null then 1 end as Pcount from #getparts
)T1
inner join #getparts on #getparts.machineid=T1.Machineid and #GetParts.Fromtime=T1.Fromtime and #GetParts.cnctimestamp=T1.cnctimestamp


--To Sum up all the Parts at ProgramNo Level for the given Machine and time Period.
Select row_number() over(order by Machineid) as id, Machineid,Fromtime,Totime,ProgramNo,isnull(Sum(Partscount),0)as Partscount,0 as total into #Totalgetparts from #getparts
group by Machineid,Fromtime,Totime,ProgramNo order by Machineid,Fromtime

update #ShiftwiseSummary set Partscount= T2.total from 
(select Machineid,Fromtime,Totime,isnull(Sum(Partscount),0)as total from #Totalgetparts group by Machineid,Fromtime,Totime)T2
inner join #ShiftwiseSummary on #ShiftwiseSummary.[From Time] = T2.Fromtime and #ShiftwiseSummary.Machineid=T2.MachineID
---------------------------- Shiftwise Partscount ----------------------------------------------------



---------------------------- Hourwise Partscount ----------------------------------------------------

truncate table #GetParts
truncate table #TempGetParts


select @strsql=''
select @strsql = @strsql + 'Insert into #tempGetParts(Machineid,ProgramNo,Batchts,Partscount)
select F.machineid,min(F.Programno) as ProgramNo,F.Batchts,0 from #FocasLivedata F with(NOLOCK)
			 inner join #HourwiseSummary L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time] and F.partscount is not null    
			where exists
			(
				select liv.ProgramNo From #FocasLivedata liv with(NOLOCK)
				inner join #HourwiseSummary L1 on L1.machineid=liv.machineid and liv.cnctimestamp>=L1.[From Time] and liv.cnctimestamp<=L1.[To Time]    
				where liv.MachineMode = ''MEM'' and liv.MachineStatus = ''In Cycle'' and liv.batchts is not null 
				and F.Programno=liv.programno and F.machineid=liv.machineid and F.Batchts=liv.Batchts '
				Select @strsql = @strsql + 'group by liv.ProgramNo
			 )
			group by F.Machineid,F.BatchTs order by F.batchts '
print @strsql
exec(@strsql)


Insert into #GetParts(Machineid,Fromtime,Totime,ProgramNo,Batchts,Partscount,cnctimestamp)
select T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts,Max(F.Partscount)-Min(F.Partscount),min(F.cnctimestamp) from #FocasLivedata F with(NOLOCK)
inner join #tempGetParts T on T.Programno=F.programno and T.machineid=F.machineid and T.Batchts=F.Batchts
inner join #HourwiseSummary L1 on L1.machineid=T.machineid and F.cnctimestamp>=L1.[From Time] and F.CNCTimeStamp<=L1.[To Time] 
where F.MachineMode = 'MEM' and F.MachineStatus = 'In Cycle' and F.batchts is not null 
group by T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts
order by T.Machineid,L1.[From Time],T.Batchts


--To get last recorded partscount for the previous batchtime
update #getparts set Prevcount=T1.Partscount from
(Select T.machineid,f.Partscount,T.fromtime,T.cnctimestamp from focas_livedata f inner join
	   (Select g.fromtime,g.machineid,g.cnctimestamp,Max(f.id) as idd from focas_livedata f with(NOLOCK) 
	   inner join #getparts g on f.machineid=g.machineid 
	   where f.cnctimestamp<g.cnctimestamp and f.MachineMode = 'MEM' and f.MachineStatus = 'In Cycle' group by g.machineid,g.fromtime,g.cnctimestamp
	   )T on F.id=T.idd 
)T1 inner join #getparts on #getparts.machineid=T1.machineid and #GetParts.Fromtime=T1.fromtime and #GetParts.cnctimestamp=T1.cnctimestamp



--To get first recorded partscount for the current batchtime
update #getparts set currentcount=T1.Partscount from
(Select g.fromtime,g.machineid,g.cnctimestamp,f.partscount as Partscount from #FocasLivedata f with(NOLOCK) 
inner join #getparts g on f.machineid=g.machineid and g.cnctimestamp=f.cnctimestamp
where f.MachineMode = 'MEM' and f.MachineStatus = 'In Cycle' 
)T1 inner join #getparts on #getparts.machineid=T1.machineid and #GetParts.Fromtime=T1.fromtime and #GetParts.cnctimestamp=T1.cnctimestamp



--Logic to consider Partcount : if Prevcount<Curcount then 1 elseif Prevcount>Curcount or Prevcount=CurCount then 0 and add it to the existing Partscount and Prevcount SHOULD NOT BE NULL.
update #getparts set Partscount=isnull(Partscount,0)  + isnull(T1.Pcount,0) from
(SELECT machineid,fromtime,cnctimestamp,case
when Prevcount>=Currentcount then 0 
when PrevCount<CurrentCount THEN 1 
when Prevcount is null then 1 end as Pcount
FROM
(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY machineid ORDER BY cnctimestamp) rn 
	FROM #getparts r
) r
WHERE r.rn =1
)T1 inner join #getparts on #getparts.machineid=T1.Machineid and #GetParts.Fromtime=T1.Fromtime and #GetParts.cnctimestamp=T1.cnctimestamp


--Logic to consider Partcount : if Prevcount<Curcount then 1 elseif Prevcount>Curcount or Prevcount=CurCount then 0 and add it to the existing Partscount and Prevcount SHOULD NOT BE NULL.
update #getparts set Partscount=isnull(Partscount,0)  + isnull(T1.Pcount,0) from
(SELECT machineid,fromtime,cnctimestamp,case
when Prevcount>=Currentcount then 0 
when PrevCount<CurrentCount THEN currentcount-prevcount
when Prevcount is null then 1 end as Pcount
FROM
(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY machineid ORDER BY cnctimestamp) rn 
	FROM #getparts r
) r
WHERE r.rn >1
)T1 inner join #getparts on #getparts.machineid=T1.Machineid and #GetParts.Fromtime=T1.Fromtime and #GetParts.cnctimestamp=T1.cnctimestamp


Create table #Hour_Totalgetparts
(
	id bigint,
	Machineid nvarchar(50),
	Fromtime datetime,
	Totime datetime,
	ProgramNo nvarchar(50),
	Partscount int,
	total int,
	ProgramBlock nvarchar(4000)
)

--To Sum up all the Parts at ProgramNo Level for the given Machine and time Period.
Insert into #Hour_Totalgetparts
Select row_number() over(order by Machineid) as id, Machineid,Fromtime,Totime,ProgramNo,isnull(Sum(Partscount),0)as Partscount,0 as total,'0' as ProgramBlock  from #getparts
group by Machineid,Fromtime,Totime,ProgramNo order by Machineid,Fromtime

update #Hour_Totalgetparts set ProgramBlock = T1.Programblock from      
(select F.Programblock,FD.ProgramNo from #Hour_Totalgetparts  FD      
inner join #FocasLivedata F on FD.ProgramNo=F.ProgramNo)T1 inner join #Hour_Totalgetparts F on T1.ProgramNo=F.ProgramNo     

update #HourwiseSummary set Partscount= T2.total from 
(select Machineid,Fromtime,Totime,isnull(Sum(Partscount),0)as total from #Hour_Totalgetparts group by Machineid,Fromtime,Totime)T2
inner join #HourwiseSummary on #HourwiseSummary.[From Time] = T2.Fromtime and #HourwiseSummary.Machineid=T2.MachineID
---------------------------- Hourwise Partscount ----------------------------------------------------



BEGIN TRY
	BEGIN TRAN

	------------------------------ HOURWISE CYCLES ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting HOURWISE CYCLES Into Table FocasWeb_HourwiseCycles';

	IF NOT EXISTS(Select * from FocasWeb_HourwiseCycles F where  Convert(Nvarchar(10),F.Date,120) In (Select Distinct Convert(Nvarchar(10),L.ShiftDate,120) From #HourwiseSummary L))
	BEGIN

		Insert into FocasWeb_HourwiseCycles( PlantID, MachineID, Date,Shiftid, Shift, HourID, HourStart, HourEnd, ProgramID, PartCount,UpdatedTS,ProgramBlock)
		select #HourwiseSummary.PlantID,#HourwiseSummary.Machineid,Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.ShiftID,#HourwiseSummary.Shiftname,#HourwiseSummary.hourid,#HourwiseSummary.[From Time],#HourwiseSummary.[To Time],T2.ProgramNo,isnull(Sum(T2.Partscount),0)as CycleCount,getdate(),T2.ProgramBlock from #Hour_Totalgetparts T2
		Right Outer join #HourwiseSummary on #HourwiseSummary.[From Time] = T2.Fromtime and #HourwiseSummary.Machineid=T2.MachineID
		group by #HourwiseSummary.ShiftID,#HourwiseSummary.PlantID,#HourwiseSummary.Machineid,Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.Shiftname,#HourwiseSummary.hourid,#HourwiseSummary.[From Time],#HourwiseSummary.[To Time],T2.ProgramNo,T2.ProgramBlock
		Order by Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.PlantID,#HourwiseSummary.Machineid,#HourwiseSummary.ShiftID,#HourwiseSummary.hourid
		
	END
	ELSE
	BEGIN

		Delete from FocasWeb_HourwiseCycles where Convert(Nvarchar(10),Date,120) In (Select Distinct Convert(Nvarchar(10),L.ShiftDate,120) From #HourwiseSummary L)


		Insert into FocasWeb_HourwiseCycles( PlantID, MachineID, Date, ShiftID,Shift, HourID, HourStart, HourEnd, ProgramID, PartCount,UpdatedTS,ProgramBlock)
		select #HourwiseSummary.PlantID,#HourwiseSummary.Machineid,Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.ShiftID,#HourwiseSummary.Shiftname,#HourwiseSummary.hourid,#HourwiseSummary.[From Time],#HourwiseSummary.[To Time],T2.ProgramNo,isnull(Sum(T2.Partscount),0)as CycleCount,getdate(),T2.ProgramBlock from #Hour_Totalgetparts T2
		Right Outer join #HourwiseSummary on #HourwiseSummary.[From Time] = T2.Fromtime and #HourwiseSummary.Machineid=T2.MachineID
		group by #HourwiseSummary.ShiftID,#HourwiseSummary.PlantID,#HourwiseSummary.Machineid,Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.Shiftname,#HourwiseSummary.hourid,#HourwiseSummary.[From Time],#HourwiseSummary.[To Time],T2.ProgramNo,T2.ProgramBlock
		Order by Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.PlantID,#HourwiseSummary.Machineid,#HourwiseSummary.ShiftID,#HourwiseSummary.hourid
	END

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_HourwiseCycles'
	------------------------------ HOURWISE CYCLES ---------------------------------------------------------------------


	------------------------------ SHIFTWISE SUMMARY ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting SHIFTWISE SUMMARY Into Table FocasWeb_ShiftwiseSummary';

	IF NOT EXISTS(Select * from FocasWeb_ShiftwiseSummary F where  Convert(Nvarchar(10),F.Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L))
	BEGIN


		Insert into FocasWeb_ShiftwiseSummary( PlantID, MachineID, Date, ShiftID,Shift, PartCount, TotalTime, PowerOnTime, OperatingTime, CuttingTime, Stoppages, UpdatedTS)
		Select PlantID,Machineid,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,SUM(Partscount),SUM(TotalTime),SUM([Powerontime]),SUM([Operating time]),
		SUM([Cutting time]),SUM(Stoppagetime),getdate() from #ShiftwiseSummary Group by PlantID,Machineid,Shiftdate,Shiftname,ShiftID
		Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID
	END
	ELSE
	BEGIN


		DELETE from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L)
	 
		Insert into FocasWeb_ShiftwiseSummary( PlantID, MachineID, Date,ShiftID, Shift, PartCount, TotalTime, PowerOnTime, OperatingTime, CuttingTime, Stoppages, UpdatedTS)
		Select PlantID,Machineid,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,SUM(Partscount),SUM(TotalTime),SUM([Powerontime]),SUM([Operating time]),
		SUM([Cutting time]),SUM(Stoppagetime),getdate() from #ShiftwiseSummary Group by PlantID,Machineid,Shiftdate,Shiftname,ShiftID
		Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID
	END

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseSummary'
	------------------------------ SHIFTWISE SUMMARY ---------------------------------------------------------------------



	------------------------------ SHIFTWISE STOPPAGES ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting SHIFTWISE STOPPAGES Into Table FocasWeb_ShiftwiseStoppages';

	IF NOT EXISTS(Select * from [FocasWeb_ShiftwiseStoppages] F where Convert(Nvarchar(10),F.Date,120) in ( Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #ShiftwiseSummary L))
	BEGIN

		Insert into [FocasWeb_ShiftwiseStoppages](PlantID, MachineID, Date, ShiftID, Shift, Batchstart, BatchEnd, StoppageTime, Reason, UpdatedTS)
		select PlantID,Machineid,Convert(Nvarchar(10),ShiftDate,120),Shiftid,Shiftname,Batchstart,BatchEnd,Stoppagetime,Reason,getdate() from #Shift_MachinewiseStoppages 
		where Stoppagetime>(@threshold*10) and MachineStatus='Down' Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID

	END
	ELSE
	BEGIN

		DELETE from [FocasWeb_ShiftwiseStoppages]  where  Convert(Nvarchar(10),Date,120) in ( Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #ShiftwiseSummary L)

		Insert into [FocasWeb_ShiftwiseStoppages](PlantID, MachineID, Date, ShiftID, Shift, Batchstart, BatchEnd, StoppageTime, Reason, UpdatedTS)
		select PlantID,Machineid,Convert(Nvarchar(10),ShiftDate,120),Shiftid,Shiftname,Batchstart,BatchEnd,Stoppagetime,Reason,getdate() from #Shift_MachinewiseStoppages 
		where Stoppagetime>(@threshold*10) and MachineStatus='Down' Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID
	END

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseStoppages'
	------------------------------ SHIFTWISE STOPPAGES ---------------------------------------------------------------------

	------------------------------ HOURWISE TIMEINFO ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting HOURWISE TIMEINF Into Table [FocasWeb_HourwiseTimeInfo]';

	IF NOT EXISTS(Select * from [FocasWeb_HourwiseTimeInfo] F where  Convert(Nvarchar(10),F.Date,120) in(Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #HourwiseSummary L))
	BEGIN

		Insert into [FocasWeb_HourwiseTimeInfo](PlantID, MachineID, Date, ShiftID, Shift, HourID, HourStart, HourEnd, PowerOntime, OperatingTime, CuttingTime, UpdatedTS)
		select PlantID,Machineid,Shiftdate,Shiftid,Shiftname,HourID,[From Time],[To Time],[Powerontime],[Operating time],[Cutting time],getdate()
		from #HourwiseSummary 

	END
	ELSE
	BEGIN

		DELETE from [FocasWeb_HourwiseTimeInfo] where  Convert(Nvarchar(10),Date,120) in(Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #HourwiseSummary L)

		Insert into [FocasWeb_HourwiseTimeInfo](PlantID, MachineID, Date, ShiftID, Shift, HourID, HourStart, HourEnd, PowerOntime, OperatingTime, CuttingTime, UpdatedTS)
		select PlantID,Machineid,Shiftdate,Shiftid,Shiftname,HourID,[From Time],[To Time],[Powerontime],[Operating time],[Cutting time],getdate()
		from #HourwiseSummary 
	END

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table [FocasWeb_HourwiseTimeInfo]'
	------------------------------ HOURWISE TIMEINFO ---------------------------------------------------------------------


	COMMIT TRAN
    SET  @ErrorCode  = 0
	Print 'MachineConnect data Inserted Successfully For the day ='  + @Date
    RETURN @ErrorCode  

END TRY
BEGIN CATCH    
	PRINT 'Exception happened. Rolling back the transaction'  
    SET @ErrorCode = ERROR_NUMBER() 
	SET @Return_Message = @ErrorStep + ' '
							+ cast(isnull(ERROR_NUMBER(),-1) as varchar(20)) + ' line: '
							+ cast(isnull(ERROR_LINE(),-1) as varchar(20)) + ' ' 
							+ isnull(ERROR_MESSAGE(),'') + ' > ' 
							+ isnull(ERROR_PROCEDURE(),'')
	PRINT @Return_Message
	IF @@TRANCOUNT > 0 ROLLBACK
    RETURN @ErrorCode 
END CATCH

END
