/****** Object:  Procedure [dbo].[Focas_ViewMachinewiseTimeChart]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Focas_ViewMachinewiseTimeChart]  '2016-apr-05','B','','','','shift'
CREATE procedure [dbo].[Focas_ViewMachinewiseTimeChart]  
 @Date datetime,   
 @Shiftname nvarchar(50)='',  
 @PlantID nvarchar(50)='',  
 @Machineid nvarchar(50)='',  
 @operator nvarchar(50)='',
 @Param nvarchar(20)='' ---Shift,Day

WITH RECOMPILE
AS  
BEGIN  
 

SET NOCOUNT ON;
 
Create Table #LiveDetails  
(  
 [Sl No] Bigint Identity(1,1) Not Null, 
 [Machineid] nvarchar(50), 
 [From Time] datetime,
 [To time] datetime,
 [ShiftDate] datetime,
 [ShiftName] nvarchar(50)
)  

Create Table #FinalData
(  
 [Sl No] Bigint Identity(1,1) Not Null, 
 PDate datetime,  
 Shift nvarchar(20), 
 [Machineid] nvarchar(50), 
 [From Time] datetime,
 [To time] datetime,
 [ProgramNo] nvarchar(100),
 [Partnumber] nvarchar(4000),
 [PartDesc] nvarchar(4000),
 [SettingTimeFrom] datetime,
 [SettingTimeTo] datetime,
 [Cycletime] float default 0,
 [ClampTime] float default 0,
 [Totaltime] float,
 [IdealCountFor1Hour] int,
 [IdealCountFor8Hrs] int,
 [TotalHours] int,
 [TotalProdQty] int default 0,
 [AccQty] int default 0,
 [RejQty] int default 0,
 [Remarks] nvarchar(4000)

) 
 
CREATE TABLE #ShiftDetails   
(  
 SlNo bigint identity(1,1) NOT NULL, 
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime  
)  
  
 
Create table #Day
(
	[From Time] datetime,
	[To time] datetime
)  

  
Declare @strsql nvarchar(4000)  
Declare @strmachine nvarchar(2000)  
Declare @StrPlantid as nvarchar(1000)   
declare @shift as nvarchar(1000)  
declare @timeformat as nvarchar(2000)

Select @timeformat = isnull((select valueintext from Focas_Defaults where parameter='FocasTimeSettings'),'ss')
 
Select @strsql = ''  
Select @strmachine = ''  
select @strPlantID = ''  
Select @shift =''  
  
if isnull(@machineid,'') <> ''  
Begin  
 Select @strMachine = ' AND ( Machineinformation.MachineID =N''' +  @machineid + ''')'  
End  
  
if isnull(@PlantID,'') <> ''  
Begin  
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'  
End  

If @param= 'Shift'
Begin
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)    
	EXEC s_GetShiftTime @date,@shiftname 
End

If @param = 'day'
Begin
	Insert into #day([From Time],[To time])
	Select dbo.f_GetLogicalDay(@date,'start'),dbo.f_GetLogicalDay(@date,'End')
End
 

If @param = 'Shift' 
Begin  
	select @strsql =''  
	select @strsql = @strsql + 'Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName)   --SV
	SELECT distinct Machineinformation.machineid,S.PDate,S.shiftstart,S.shiftend,S.Shift FROM Machineinformation  --SV
	Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid  
	Cross join #ShiftDetails S where 1=1'  
	Select @strsql = @strsql + @strmachine + @StrPlantid  
	print @strsql  
	Exec (@strsql)   
End


if @param = 'day'
BEGIN

	select @strsql =''  
	select @strsql = @strsql + 'Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time])  --SV
	SELECT distinct Machineinformation.machineid,convert(nvarchar(10),s.[From Time],120),s.[From Time],s.[To time] FROM Machineinformation  --SV
	Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid   
	Cross join #day S where 1=1'  
	Select @strsql = @strsql + @strmachine + @StrPlantid  
	print @strsql  
	Exec (@strsql) 
end



--SV From Here
 
Create table #GetParts
(
	id bigint identity(1,1),
	PDate datetime,  
	Shift nvarchar(20),
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
	Batchts datetime
)

Create Table #LiveDetails1  
(    
 [Sl No] Bigint Identity(1,1) Not Null,    
 [Machineid] nvarchar(50),    
 [From Time] datetime,    
 [To time] datetime,    
 [ProgramNo] nvarchar(100), 
 [PartsCount] int   
) 

truncate table #GetParts
truncate table #TempGetParts

declare @DataStart as datetime
declare @DataEnd as datetime

select @DataStart= (select top 1 [From Time] from #LiveDetails order by [From Time])
select @DataEnd = (select top 1 [To Time] from #LiveDetails order by [From Time] desc)

select MachineID, MachineStatus, MachineMode, ProgramNo, PowerOnTime, OperatingTime, CutTime, CNCTimeStamp, PartsCount, BatchTS, MachineUpDownStatus, MachineUpDownBatchTS,ProgramBlock
into #FocasLivedata from dbo.focas_livedata with(NOLOCK) where cnctimestamp>=@DataStart and cnctimestamp<=@DataEnd

select @strsql=''
select @strsql = @strsql + 'Insert into #tempGetParts(Machineid,ProgramNo,Batchts,Partscount)
select F.machineid,min(F.Programno) as ProgramNo,F.Batchts,0 from #FocasLivedata F
			 inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time] and F.partscount is not null    
			where exists
			(
				select liv.ProgramNo From #FocasLivedata liv with(NOLOCK) 
				inner join #LiveDetails L1 on L1.machineid=liv.machineid and liv.cnctimestamp>=L1.[From Time] and liv.cnctimestamp<=L1.[To Time]    
				where liv.MachineMode = ''MEM'' and liv.MachineStatus = ''In Cycle'' and liv.batchts is not null 
				and F.Programno=liv.programno and F.machineid=liv.machineid and F.Batchts=liv.Batchts '
				Select @strsql = @strsql + 'group by liv.ProgramNo
			 )
			group by F.Machineid,F.BatchTs order by F.batchts '
print @strsql
exec(@strsql)


Insert into #GetParts(Machineid,Fromtime,Totime,ProgramNo,Batchts,Partscount,cnctimestamp,pdate ,shift)
select T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts,Max(F.Partscount)-Min(F.Partscount),min(F.cnctimestamp),L1.shiftdate,L1.shiftname from #FocasLivedata F
inner join #tempGetParts T on T.Programno=F.programno and T.machineid=F.machineid and T.Batchts=F.Batchts
inner join #LiveDetails L1 on L1.machineid=T.machineid and F.cnctimestamp>=L1.[From Time] and F.CNCTimeStamp<=L1.[To Time] 
where F.MachineMode = 'MEM' and F.MachineStatus = 'In Cycle' and F.batchts is not null 
group by T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts,L1.shiftdate,L1.shiftname
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
Insert into #FinalData (pdate,shift,Machineid,[From time],[To Time],ProgramNo,TotalProdQty)
Select pdate,shift,Machineid,Fromtime,Totime,ProgramNo,isnull(Sum(Partscount),0) from #getparts
where Partscount>0
group by Machineid,Fromtime,Totime,ProgramNo,pdate,shift order by Machineid,Fromtime

update #FinalData set Partnumber = T1.Programblock from
(select F.Programblock,FD.ProgramNo from #FinalData FD
inner join #FocasLivedata F on FD.ProgramNo=F.ProgramNo)T1 inner join #finaldata F on T1.ProgramNo=F.ProgramNo

update #FinalData set Partdesc = T1.Partdesc from
(select F.ComponentDescription as Partdesc,FD.Partnumber from #FinalData FD
inner join FocasComponentInformation F on FD.Partnumber=F.ComponentId)T1 inner join #finaldata F on T1.PartNumber=F.PartNumber

update #FinalData set [Cycletime] = isnull(T1.MachiningTime,0),[ClampTime]=isnull(T1.LoadUnload,0) from
(select F.CycleTime as MachiningTime,F.LoadUnloadTime as LoadUnload,FD.PartNumber from #FinalData FD
inner join FocasComponentInformation F on FD.PartNumber=F.ComponentId)T1 inner join #finaldata F on T1.PartNumber=F.PartNumber


--update #FinalData set [TotalTime] = [Cycletime] + [ClampTime]

update #FinalData set [TotalTime] = T1.Powerontime from
(select Max(F.Powerontime)-Min(F.Powerontime) as Powerontime,FD.ProgramNo,FD.Machineid,FD.[From Time] from #FinalData FD
inner join #FocasLivedata F on FD.ProgramNo=F.ProgramNo
where F.cnctimestamp>=FD.[From Time]  and F.cnctimestamp<=FD.[To Time] and F.Powerontime>0
group by FD.ProgramNo,FD.Machineid,FD.[From Time])T1 inner join #finaldata F on T1.ProgramNo=F.ProgramNo
and F.Machineid=T1.Machineid and F.[From Time]=T1.[From Time]

update #finaldata set [IdealCountFor1Hour] = 3600/[TotalTime] where [TotalTime]>0

If @param='Shift'
Begin

	update #finaldata set [TotalHours] = T1.Totalhours ,[Remarks]=T1.Remarks from
	(select F.Totalhours,FD.PartNumber ,F.Remarks,FD.Machineid,FD.pDate,F.shift from #FinalData FD
	left outer join Focas_PartwiseRejectionInfo F on FD.PartNumber=F.PartNumber and F.Machine=FD.Machineid
	and convert(nvarchar(10),F.Date,120)=convert(nvarchar(10),FD.PDate,120) and F.Shift=FD.shift)
	T1 inner join #finaldata F on T1.PartNumber=F.PartNumber and F.Machineid=T1.Machineid and F.pdate=T1.pdate and F.Shift=T1.shift

	update #finaldata set [RejQty] = T1.RejQty from
	(select SUM(F.[RejQty]) as Rejqty,FD.PartNumber,FD.Machineid,FD.pDate,F.shift from #FinalData FD
	inner join Focas_PartwiseRejectionInfo F on FD.PartNumber=F.PartNumber and F.Machine=FD.Machineid
	and convert(nvarchar(10),F.Date,120)=convert(nvarchar(10),FD.PDate,120)  and F.Shift=FD.shift group by FD.PartNumber,FD.Machineid,FD.pDate,F.shift)
	T1 inner join #finaldata F on T1.PartNumber=F.PartNumber and F.Machineid=T1.Machineid and F.pdate=T1.pdate and F.Shift=T1.shift
End

If @param='day'
Begin


	update #finaldata set [TotalHours] =  T1.Totalhours  from
	(select sum(F.Totalhours) as Totalhours,FD.PartNumber,FD.pdate,FD.Machineid from #FinalData FD
	left outer join Focas_PartwiseRejectionInfo F on FD.PartNumber=F.PartNumber and F.Machine=FD.Machineid
	and convert(nvarchar(10),F.Date,120)=convert(nvarchar(10),FD.PDate,120) group by FD.PartNumber,FD.pdate,FD.Machineid)T1 inner join #finaldata F on T1.PartNumber=F.PartNumber and F.Machineid=T1.Machineid and F.pdate=T1.pdate


	update #finaldata set [RejQty] = T1.RejQty from
	(select SUM(F.[RejQty]) as Rejqty,FD.PartNumber,FD.Machineid,FD.PDate from #FinalData FD
	inner join Focas_PartwiseRejectionInfo F on FD.PartNumber=F.PartNumber and F.Machine=FD.Machineid
	and convert(nvarchar(10),F.Date,120)=convert(nvarchar(10),FD.PDate,120) group by FD.PartNumber,FD.Machineid,FD.pDate)
	T1 inner join #finaldata F on T1.PartNumber=F.PartNumber and F.Machineid=T1.Machineid and F.pdate=T1.pdate 
End

update #finaldata set [TotalHours] = datediff(hour,[from Time],[To time]) where [TotalHours] IS NULL  

update #finaldata set [IdealCountFor8Hrs] = [IdealCountFor1Hour]*[TotalHours]

update #finaldata set [accQty] = [TotalProdQty] - [RejQty]

 select [Sl No], pdate,shift,Machineid,[From time],[To Time],ProgramNo,PartNumber,[PartDesc],[SettingTimeFrom],[SettingTimeTo],
 dbo.f_FormatTime([Cycletime],@timeformat) as [Cycletime], dbo.f_FormatTime([ClampTime],@timeformat) as [ClampTime], dbo.f_FormatTime([Totaltime],@timeformat) as [Totaltime],
 [IdealCountFor1Hour],[IdealCountFor8Hrs],[TotalHours],[TotalProdQty],[AccQty],[RejQty],[Remarks] from #FinalData

 end

  
