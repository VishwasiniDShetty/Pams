/****** Object:  Procedure [dbo].[s_GetFocasHourShiftwiseLiveDetails]    Committed by VersionSQL https://www.versionsql.com ******/

  
        
        
/**************************************************************************************************************        
--NR0098 - SwathiKS - 26/Dec/2013 :: Created New Procedure to Get Shiftwise Powerontime and Cuttingtime for the selected Machines and Time Period.          
--ER0376 - SwathiKS - 18/feb/2014 :: To include New Parameter 'Hour' to get hourwise Powerontime,Cuttingtime,Operatingtime for the selected Days-Shifts-Machines.        
-- Vasavi - 15/04/2015 :: To include New Parameter 'Day' to get daywise Powerontime,Cuttingtime,Operatingtime for the selected Days-Machines.        
--To get summary for the selected day based on the shift,day,hour.        
SwathiKS - 29/Jul/2015 :: To calculate Programwise Partscount for the given Machine and Time Period at Hour-Shift-Day Level.        
--[dbo].[s_GetFocasHourShiftwiseLiveDetails] '2018-03-05','2018-03-05','''A''','','','hour',''
--[dbo].[s_GetFocasHourShiftwiseLiveDetails] '2019-04-12','2019-04-12','','','Ó¢ÐÛ','hour','Shift'
-- [dbo].[s_GetFocasHourShiftwiseLiveDetails] '2019-04-12','2019-04-12',N'µÚ¶þ','','','hour','hour'
-- [dbo].[s_GetFocasHourShiftwiseLiveDetails] '2020-04-07','2020-04-07',N'''夜班''','','','hour',''
          
*************************************************************************************************************/         
        
CREATE procedure [dbo].[s_GetFocasHourShiftwiseLiveDetails]          
 @Starttime datetime,          
 @Endtime datetime,          
 @Shiftname nvarchar(50)='',          
 @PlantID nvarchar(50),          
 @Machineid nvarchar(1000),          
 @Param nvarchar(20)='',        
 @param1 nvarchar(50)=''        
        
WITH RECOMPILE        
AS          
BEGIN          
         
        
 SET NOCOUNT ON;        
         
Create Table #LiveDetails          
(          
 [Sl No] Bigint Identity(1,1) Not Null,          
 [Machineid] nvarchar(50),          
 [ShiftDate] datetime,          
 [ShiftName] nvarchar(50),          
 [From time] datetime,          
 [To Time] datetime,          
 [Powerontime] float,          
 [Cutting time] float,          
 [Operating time] float,        
 [PartsCount] int, --SV        
 [ProgramNo] nvarchar(50), --SV        
 FinalTarget float
)          
        
         
CREATE TABLE #MachinewiseStoppages        
(        
 id bigint identity(1,1),        
 Machineid nvarchar(50),        
 Fromtime datetime,        
 Totime datetime,        
 BatchTS datetime,        
 BatchStart datetime,        
 BatchEnd datetime,        
 Stoppagetime int,        
 MachineStatus nvarchar(50),        
 Reason nvarchar(50),        
 AlarmStatus nvarchar(50),        
 Shiftname nvarchar(50),        
 ShiftDate datetime,
 TotalStoppage int       
)        
         
CREATE TABLE #ShiftDetails           
(          
 SlNo bigint identity(1,1) NOT NULL, --ER0376        
 PDate datetime,          
 Shift nvarchar(20),          
 ShiftStart datetime,          
 ShiftEnd datetime          
)          
          
--ER0376 From here        
CREATE TABLE #SDetails           
(          
 PDate datetime,          
 Shift nvarchar(20),          
 ShiftStart datetime,          
 ShiftEnd datetime          
)          
        
CREATE TABLE #HourDetails           
(          
 PDate datetime,          
 Shift nvarchar(20),          
 HourStart datetime,          
 HourEnd datetime          
)          
Create table #Day        
(        
 [From Time] datetime,        
 [To time] datetime        
)          
--ER0376 Till here        
          
Declare @strsql nvarchar(4000)          
Declare @strmachine nvarchar(2000)          
Declare @StrPlantid as nvarchar(1000)          
Declare @CurStrtTime as datetime          
Declare @CurEndTime as datetime          
declare @shift as nvarchar(1000)          
          
Select @strsql = ''          
Select @strmachine = ''          
select @strPlantID = ''          
Select @shift =''          
  
	      
if isnull(@machineid,'') <> ''          
Begin          
 --Select @strMachine = ' AND Machineinformation.MachineID in (N' + @machineid + ') '   
  Select @strMachine = N' AND Machineinformation.MachineID = N''' + @machineid + ''''          
End          
      
if isnull(@PlantID,'') <> ''          
Begin          
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'          
End          
          
Select @CurStrtTime=@Starttime          
Select @CurEndTime=@Endtime          
          
          
While @CurStrtTime<=@CurEndTime          
BEGIN          
 INSERT #SDetails(Pdate, Shift, ShiftStart, ShiftEnd)   --ER0376        
 EXEC s_GetShiftTime @CurStrtTime,''          
 SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)          
END          
         
if isnull(@Shiftname,'') <> ''          
Begin          
 select @strsql =''          
 Select @strsql = @strsql +  'Delete from #SDetails where shift not in ( N' +  @Shiftname + ') '   --ER0376        
 exec(@strsql)          
End          
 print '----delete from shiftdetailstemp-----' 
 print  'Delete from #SDetails where shift not in ( ' +  @Shiftname + ') '     
--ER0376 From here        
INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)          
select Pdate, Shift, ShiftStart, ShiftEnd from #SDetails        
--ER0376 Till here        
        
        
        
--ER0376 From here         
If @param = 'Shift' or @param1 ='Shift' --Vasavi added        
Begin          
 select @strsql =''          
 select @strsql = @strsql + 'Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])   --SV        
 SELECT distinct Machineinformation.machineid,S.PDate,S.shiftstart,S.shiftend,S.Shift,0,0,0,0,0 FROM Machineinformation  --SV        
 --inner join Plantmachine on Machineinformation.machineid=Plantmachine.machineid          
 Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid          
 Cross join #ShiftDetails S where 1=1'          
 Select @strsql = @strsql + @strmachine + @StrPlantid          
 print @strsql          
 Exec (@strsql)           
End        
if @param = 'day'or @param1 ='DAY'  --Vasavi added        
        
BEGIN        
 while @StartTime<=@EndTime        
        
 BEGIN        
  Insert into #day([From Time],[To time])        
  Select dbo.f_GetLogicalDay(@StartTime,'start'),dbo.f_GetLogicalDay(@startTime,'End')        
  SELECT @StartTime=DATEADD(DAY,1,@StartTime)        
 END        
 select @strsql =''          
 select @strsql = @strsql + 'Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])  --SV        
 SELECT distinct Machineinformation.machineid,0,s.[From Time],s.[To time],0,0,0,0,0,0 FROM Machineinformation  --SV        
 --inner join Plantmachine on Machineinformation.machineid=Plantmachine.machineid         
 Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid           
 Cross join #day S where 1=1'          
 Select @strsql = @strsql + @strmachine + @StrPlantid          
 print @strsql          
 Exec (@strsql)         
 end        
        
If @param = 'Hour' or @param1 ='Hour' --Vasavi Added        
BEGIN        
 Declare  @CountOfRows as int        
 Declare @i as int        
 Declare @Shiftstart as datetime        
 Declare @shiftend as datetime        
 Declare @Pdate as datetime        
 Declare @sname as nvarchar(20)        
 Select @i = 1        
        
 Select @CountOfRows = Count(*) from #ShiftDetails        
 Select @Pdate=Pdate,@sname=Shift,@shiftstart = ShiftStart,@shiftend = shiftend from #ShiftDetails where slno=@i        
        
 While @i <= @CountOfRows        
 Begin        
   While @shiftstart<@shiftend        
   Begin        
   INSERT #HourDetails(Pdate, Shift, HourStart, HourEnd)          
   Select @Pdate, @sname, @shiftstart,case when DATEADD(HOUR,1,@shiftstart)>@shiftend then @shiftend else DATEADD(HOUR,1,@shiftstart) end         
   SELECT @shiftstart=DATEADD(HOUR,1,@shiftstart)          
   End        
   Select @i = @i + 1        
   Select @Pdate=Pdate,@sname=Shift,@shiftstart = ShiftStart,@shiftend = shiftend from #ShiftDetails where slno=@i        
   END        
        
 select @strsql =''          
 select @strsql = @strsql + 'Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])   --SV        
 SELECT distinct Machineinformation.machineid,S.PDate,S.Hourstart,S.Hourend,S.Shift,0,0,0,0,0 FROM Machineinformation   --SV        
 --inner join Plantmachine on Machineinformation.machineid=Plantmachine.machineid         
 Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid          
 Cross join #HourDetails S where 1=1'          
 Select @strsql = @strsql + @strmachine + @StrPlantid          
 print @strsql          
 Exec (@strsql)           
END        

If @param = 'OEMHour'        
BEGIN        
        
        
  --Select @shiftstart = Dateadd(hour,-23,@Endtime)        
  --Select @Shiftend = dateadd(hour,1,@Endtime)        
  Select @shiftstart = @Endtime        
  Select @Shiftend = dateadd(day,1,@Endtime)        
        
   While @shiftstart<@shiftend        
   Begin        
   INSERT #HourDetails(HourStart, HourEnd)          
   Select  @shiftstart,case when DATEADD(HOUR,1,@shiftstart)>@shiftend then @shiftend else DATEADD(HOUR,1,@shiftstart) end         
   SELECT @shiftstart=DATEADD(HOUR,1,@shiftstart)          
   End        
        
        
 select @strsql =''          
 select @strsql = @strsql + 'Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])   --SV        
 SELECT distinct Machineinformation.machineid,S.PDate,S.Hourstart,S.Hourend,S.Shift,0,0,0,0,0 FROM Machineinformation   --SV        
 --inner join Plantmachine on Machineinformation.machineid=Plantmachine.machineid          
 Left Outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid          
 Cross join #HourDetails S where 1=1'          
 Select @strsql = @strsql + @strmachine + @StrPlantid          
 print @strsql          
 Exec (@strsql)           
END        
--ER0376 Till here        
         
declare @DataStart as datetime        
declare @DataEnd as datetime        
        
select @DataStart= (select top 1 [From Time] from #LiveDetails order by [From Time])        
select @DataEnd = (select top 1 [To Time] from #LiveDetails order by [From Time] desc)        
        
select MachineID, MachineStatus, MachineMode, ProgramNo, PowerOnTime, OperatingTime, CutTime, CNCTimeStamp, PartsCount, BatchTS, MachineUpDownStatus, MachineUpDownBatchTS,ProgramBlock        
into #FocasLivedata from dbo.focas_livedata with(NOLOCK) where cnctimestamp>=@DataStart and cnctimestamp<=@DataEnd        
    

          
Update #LiveDetails set [Powerontime]  = isnull(#LiveDetails.[Powerontime] ,0) + isnull(T2.Powerontime,0),        
--[PartsCount]=isnull(T2.[PartsCount],0),   --SV        
[Cutting time]  = isnull([Cutting time] ,0) + isnull(T2.Cuttingtime,0),          
[Operating time]  = isnull([Operating time] ,0) + isnull(T2.Operatingtime,0)  From          
(select L.[From Time]  as TS,F.machineid,Max(F.Powerontime)-Min(F.Powerontime) as Powerontime,        
--Max(F.PartsCount)-Min(F.PartsCount) as PartsCount,          
Max(Cuttime)-Min(Cuttime) as Cuttingtime,Max(Operatingtime)-Min(Operatingtime) as Operatingtime from #FocasLivedata F          
inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time]  and F.cnctimestamp<=L.[To Time]           
where F.Powerontime>0 and F.CutTime>0 and F.OperatingTime>0 group by F.machineid,L.[From Time]           
)T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS and #LiveDetails.Machineid=T2.MachineID          
         
Update #LiveDetails Set [Cutting time] = [Cutting time]/60 where [Cutting time]>0           
Update #LiveDetails Set [Operating time] = [Operating time] /60 where [Operating time]>0          
        
--SV From Here        
         
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
 Batchts datetime        
)        
        
Create Table #LiveDetails1          
(            
 [Sl No] Bigint Identity(1,1) Not Null,            
 [Machineid] nvarchar(50),            
 [From Time] datetime,            
 [To time] datetime,            
 [Powerontime] float,            
 [Cutting time] float,            
 [Operating time] float,        
 [ProgramNo] nvarchar(100),         
 [PartsCount] int,
 FinalTarget float         
)         
        
Create table #Totalgetparts        
(        
 id bigint,        
 Machineid nvarchar(50),        
 Fromtime datetime,        
 Totime datetime,        
 ProgramNo nvarchar(50),        
 Partscount int,        
 Total int,        
 Partnumber nvarchar(4000),      
 Target float,                       
 OEE float,
 TotalPartsCount float,
 AvgOEE float         
)        
        
truncate table #GetParts        
truncate table #TempGetParts        
        
select @strsql=''        
select @strsql = @strsql + 'Insert into #tempGetParts(Machineid,ProgramNo,Batchts,Partscount)        
select F.machineid,min(F.Programno) as ProgramNo,F.Batchts,0 from #FocasLivedata F        
        
    inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time] and F.partscount is not null            
   where exists        
   (        
    select liv.ProgramNo From #FocasLivedata liv with(NOLOCK)         
    inner join #LiveDetails L1 on L1.machineid=liv.machineid 
	--and liv.cnctimestamp>=L1.[From Time] and liv.cnctimestamp<=L1.[To Time]            
	and liv.cnctimestamp>=L1.[From Time] and liv.cnctimestamp<=L1.[To Time]   --Commented and added logic for China for count mismatch         
    where liv.MachineMode = ''MEM'' --and liv.MachineStatus = ''In Cycle'' 
	and liv.batchts is not null         
    and F.Programno=liv.programno and F.machineid=liv.machineid and F.Batchts=liv.Batchts '        
    Select @strsql = @strsql + 'group by liv.ProgramNo        
    )        
   group by F.Machineid,F.BatchTs order by F.batchts '        
print @strsql        
exec(@strsql)        
        
        
Insert into #GetParts(Machineid,Fromtime,Totime,ProgramNo,Batchts,Partscount,cnctimestamp)        
select T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts,Max(F.Partscount)-Min(F.Partscount),min(F.cnctimestamp) from #FocasLivedata F        
inner join #tempGetParts T on T.Programno=F.programno and T.machineid=F.machineid and T.Batchts=F.Batchts        
inner join #LiveDetails L1 on L1.machineid=T.machineid 
--and F.cnctimestamp>=L1.[From Time] and F.CNCTimeStamp<L1.[To Time]         
and F.cnctimestamp>L1.[From Time] and F.CNCTimeStamp<L1.[To Time]      --Commented and added logic for China for count mismatch    
where F.MachineMode = 'MEM' --and F.MachineStatus = 'In Cycle' 
and F.batchts is not null         
group by T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts        
order by T.Machineid,L1.[From Time],T.Batchts        
         
 select * into #Focas_Getparts from focas_livedata f with(NOLOCK)  where cnctimestamp>=Dateadd(day,-2,@DataStart) and cnctimestamp<=@DataEnd  
        
--To get last recorded partscount for the previous batchtime        
update #getparts set Prevcount=T1.Partscount from        
(Select T.machineid,f.Partscount,T.fromtime,T.cnctimestamp from #Focas_Getparts f inner join        
    (Select g.fromtime,g.machineid,g.cnctimestamp,Max(f.id) as idd from #Focas_Getparts f with(NOLOCK)         
    inner join #getparts g on f.machineid=g.machineid         
    where f.cnctimestamp<g.cnctimestamp and f.MachineMode = 'MEM' --and f.MachineStatus = 'In Cycle' 
	group by g.machineid,g.fromtime,g.cnctimestamp         
    )T on F.id=T.idd         
)T1 inner join #getparts on #getparts.machineid=T1.machineid and #GetParts.Fromtime=T1.fromtime and #GetParts.cnctimestamp=T1.cnctimestamp        
        
        
--To get first recorded partscount for the current batchtime        
update #getparts set currentcount=T1.Partscount from        
(Select g.fromtime,g.machineid,g.cnctimestamp,f.partscount as Partscount from #FocasLivedata f with(NOLOCK)         
inner join #getparts g on f.machineid=g.machineid and g.cnctimestamp=f.cnctimestamp        
where f.MachineMode = 'MEM' --and f.MachineStatus = 'In Cycle'         
)T1 inner join #getparts on #getparts.machineid=T1.machineid and #GetParts.Fromtime=T1.fromtime and #GetParts.cnctimestamp=T1.cnctimestamp        
        
        
        
 IF @Param='hour' or @Param='OEMhour'        
 BEGIN        
          
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
        
END        
        
        
        
 IF @Param='shift' or @param='day'        
 BEGIN        

------Commented and added below logic for china
    --Logic to consider Partcount : if Prevcount<Curcount then 1 elseif Prevcount>Curcount or Prevcount=CurCount then 0 and add it to the existing Partscount and Prevcount SHOULD NOT BE NULL.        
    --update #getparts set Partscount=isnull(Partscount,0)  + isnull(T1.Pcount,0) from        
    --(Select machineid,fromtime,cnctimestamp,case        
    --when Prevcount>=Currentcount then 0          
    --when PrevCount<CurrentCount THEN 1          
    --when Prevcount is null then 1 end as Pcount from #getparts        
    --)T1        
    --inner join #getparts on #getparts.machineid=T1.Machineid and #GetParts.Fromtime=T1.Fromtime and #GetParts.cnctimestamp=T1.cnctimestamp  
	
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
	------Commented and added below logic for china      
END        
        
        
 Declare @Curtime as datetime                    
 select @curtime= getdate()      
      
--To Sum up all the Parts at ProgramNo Level for the given Machine and time Period.        
Insert into #Totalgetparts(id,Machineid,Fromtime,Totime,ProgramNo,Partscount,total)        
        
--Select row_number() over(order by Machineid) as id, Machineid,Fromtime,Totime,ProgramNo,isnull(Sum(Partscount),0)as Partscount,0 as total into #Totalgetparts from #getparts        
--where Partscount>0        
--group by Machineid,Fromtime,Totime,ProgramNo order by Machineid,Fromtime        
        
Select row_number() over(order by Machineid) as id, Machineid,Fromtime,Totime,ProgramNo,isnull(Sum(Partscount),0)as Partscount,0 as total from #getparts        
where Partscount>0        
group by Machineid,Fromtime,Totime,ProgramNo order by Machineid,Fromtime        
        
update #Totalgetparts set Partnumber = T1.Programblock from        
(select F.Programblock,FD.ProgramNo from #Totalgetparts  FD        
inner join #FocasLivedata F on FD.ProgramNo=F.ProgramNo)T1 inner join #Totalgetparts F on T1.ProgramNo=F.ProgramNo        
        
update #Totalgetparts set Total= T.Total from         
(select Machineid,Fromtime,Totime,isnull(Sum(Partscount),0)as total from #Totalgetparts group by Machineid,Fromtime,Totime)T inner join        
#totalgetparts on #totalgetparts.machineID=T.MachineID        
     
 declare @CurrentTime as datetime    
Select @CurrentTime = getdate()    
       
-- update #Totalgetparts set Target= T.Target from                 
--(select T.Machineid,T.Fromtime,T.ProgramNo,ROUND((ISNULL(cast(T.Partscount as float),0)*(60/Isnull(cast(F.Target as float),0))),2) as Target from #Totalgetparts T            
--inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join                
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.Fromtime=T.Fromtime            
  
--update #Totalgetparts set Target= T.Target from               
--(select T.Machineid,T.Fromtime,T.ProgramNo,Isnull(F.Target,0) as Target from #Totalgetparts T          
--inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.Fromtime=T.Fromtime 


--update #Totalgetparts set FinalTarget= T.Ftarget from                 
--(select T.Machineid,T.Fromtime,T.Totime,ROUND(ISNULL(cast(SUM(T.Target) as float),0),2) as Ftarget from #Totalgetparts T            
--Group by T.Machineid,T.Fromtime,T.Totime)T inner join                
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.Fromtime=T.Fromtime  


     
--update #Totalgetparts set OEE= T.OEE from                 
--(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(SUM(T.Target) as float),0)/cast(Datediff(minute,T.Fromtime,case when T.Totime>@CurrentTime then @CurrentTime else T.Totime END) as float))*100,2) as OEE from #Totalgetparts T            
--Group by T.Machineid,T.Fromtime,T.Totime)T inner join                
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.Fromtime=T.Fromtime            
 
--update #Totalgetparts set Target= T.Target from               
--(select Machineid,OEETarget as Target from machineinformation)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID 

--update #Totalgetparts set OEE= T.OEE*100 from               
--(
--select T.Machineid,T.Fromtime,T.Totime,ROUND(ISNULL(cast(SUM(T.Partscount) as float),0)/ISNULL(cast(SUM(T.Target) as float),0),2) as OEE from #Totalgetparts T where T.Target>0         
--Group by T.Machineid,T.Fromtime,T.Totime,T.Target
--)T inner join #totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.Fromtime=T.Fromtime 
 
 --------------------------COMMENTED FOR CHINA--------------------------    

 update #Totalgetparts set Target= T.Target from               
(select T.Machineid,T.Fromtime,T.ProgramNo,ROUND((ISNULL(cast(T.Partscount as float),0)*(Isnull(cast(F.Cycletime as float),0))),2) as Target 
from #Totalgetparts T          
inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join              
#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.Fromtime=T.Fromtime          

--update #Totalgetparts set OEE= T1.OEE 
--from  
--(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(T.Target as float),0)/cast(Datediff(second,T.Fromtime,T.Totime) as float))*100,2) as OEE from                  
--	(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as Target from #Totalgetparts T          
--	Group by T.Machineid,T.Fromtime,T.Totime
--	)T 
--)T1 inner join #totalgetparts on #totalgetparts.machineID=T1.MachineID and #totalgetparts.Fromtime=T1.Fromtime          


update #Totalgetparts set OEE= T1.OEE from  
(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(T.Target as float),0)/Isnull([Operating time]*60,0))*100,2) as OEE from                  
	(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as Target from #Totalgetparts T          
	Group by T.Machineid,T.Fromtime,T.Totime
	)T inner join #LiveDetails L on L.Machineid=T.Machineid and L.[From Time]=T.Fromtime and L.[To Time]=T.Totime     
where Isnull([Operating time],0)<>0	           
)T1 inner join #totalgetparts on #totalgetparts.machineID=T1.MachineID and #totalgetparts.Fromtime=T1.Fromtime
    
 update #Totalgetparts set AvgOEE= T.AvgOEE from                 
(select ROUND(AVG(OEE),0) as AvgOEE from #Totalgetparts)T 
        
    
Insert into #LiveDetails1([Machineid],[From Time],[To time],[Powerontime],[Cutting time],[Operating time],[ProgramNo],[Partscount])          
Select Machineid,min([From time]),Max([To time]),0,0,0,0,0  from #Livedetails group by Machineid-- order by machineid,[From time]         
        
        
Update #LiveDetails1 set [Powerontime]  = Isnull([Powerontime],0) + ISNULL(T1.PTime,0),            
[Cutting time]  = Isnull([Cutting time],0) + ISNULL(T1.CTime,0),            
[Operating time] = Isnull([Operating time],0) + ISNULL(T1.OTime,0) from             
(Select F.machineid,L.[From Time] as Fromtime,L.[To time] as Totime,Max(F.Powerontime) - Min(F.Powerontime) as Ptime,            
Max(F.CutTime)- Min(F.CutTime) as CTime,Max(F.OperatingTime)- Min(F.OperatingTime) as OTime 
from dbo.Focas_LiveData F            
inner join #LiveDetails1 L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time]                 
group by F.machineid,L.[From Time],L.[To time])T1            
inner join #LiveDetails1 on #LiveDetails1.[From Time] = T1.Fromtime and #LiveDetails1.Machineid = T1.MachineID            
            
Update #LiveDetails1 Set [Cutting time] = [Cutting time]/60 where [Cutting time]>0             
Update #LiveDetails1 Set [Operating time] = [Operating time] /60 where [Operating time]>0            
        
        
update #LiveDetails1 set [PartsCount] = T1.Parts from        
(select Machineid,isnull(sum(Partscount),0) as Parts 
from  #Totalgetparts where PartsCount>0 group by machineid)T1 inner join #livedetails1 on T1.machineid=#livedetails1.machineid        

update #LiveDetails1 set FinalTarget= T.Ftarget from                 
(select M.Machineid,ROUND(ISNULL(cast(M.OEETarget as float),0),2) as Ftarget from machineinformation M)T inner join                
#LiveDetails1 on #LiveDetails1.machineID=T.MachineID 

update #LiveDetails set FinalTarget= T.Ftarget from                 
(select M.Machineid,ROUND(ISNULL(cast(M.OEETarget as float),0),2) as Ftarget from machineinformation M)T inner join                
#LiveDetails on #LiveDetails.machineID=T.MachineID 

------------------Commented for china----------------------
--update #LiveDetails1 set FinalTarget= T.Ftarget from                 
--(select M.Machineid,ROUND(ISNULL(cast(SUM(M.Target) as float),0),2) as Ftarget 
--from #Totalgetparts M
--GROUP BY Machineid)T inner join                
--#LiveDetails1 on #LiveDetails1.machineID=T.MachineID 

--update #LiveDetails set FinalTarget= T.Ftarget from                 
--(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as FTarget from #Totalgetparts T          
-- Group by T.Machineid,T.Fromtime,T.Totime
--)T inner join               
--#LiveDetails on #LiveDetails.machineID=T.MachineID AND T.Fromtime = #LiveDetails.[From time]

update #Totalgetparts set TotalPartsCount = T1.Parts from        
(select Machineid,isnull(sum(Partscount),0) as Parts from  #Totalgetparts where PartsCount>0 group by machineid)T1 
inner join #Totalgetparts on T1.machineid=#Totalgetparts.machineid        

--SV Till Here        
         
--ER0376 From here         
        
If @param = 'shift'        
Begin         
        
------SV from Here         
 --select Machineid,ShiftDate,ShiftName,Round(Powerontime,2) as Powerontime,Round([Cutting time],2) as [Cutting time],        
 --Round([Operating time],2) as [Operating time],[PartsCount] from #LiveDetails Order by Machineid,ShiftDate,shiftname         
        
 select L.Machineid,L.ShiftDate,L.ShiftName,Round(L.Powerontime,2) as Powerontime,Round(L.[Cutting time],2) as [Cutting time],        
 Round(L.[Operating time],2) as [Operating time],isnull(P.ProgramNo,0) as ProgramNo,isnull(P.PartsCount,0) as PartsCount,Partnumber,Round(P.OEE,2) as OEE,L.FinalTarget,
 P.TotalPartsCount,P.AvgOEE  from #LiveDetails L left outer join #Totalgetparts P        
 on L.Machineid=P.Machineid and L.[From Time]=P.Fromtime and L.[To Time]=P.Totime         
    Order by L.Machineid,L.ShiftDate,L.shiftname         
        
        
--    Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],          
--    sum(DATEDIFF( MINUTE,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,          
--    sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,        
--    sum(Round([Operating time],2)) as  [Operating time], sum([PartsCount])as [PartsCount]        
--    From #LiveDetails         
        
  Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],          
    sum(DATEDIFF( MINUTE,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,          
    sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,        
    sum(Round([Operating time],2)) as  [Operating time], sum([PartsCount])as [PartsCount]        
    From #LiveDetails1        
----SV Till here         
end        
        
 If @param = 'Day'        
Begin          
        
----SV        
-- select Machineid,[From Time],[To Time],Round(Powerontime,2) as Powerontime,Round([Cutting time],2) as [Cutting time],[PartsCount],        
-- Round([Operating time],2) as [Operating time] from #LiveDetails         
-- Order by Machineid,[From Time]        
        
 select L.Machineid,L.[From Time],L.[To Time],Round(L.Powerontime,2) as Powerontime,Round(L.[Cutting time],2) as [Cutting time],        
 Round(L.[Operating time],2) as [Operating time],isnull(P.ProgramNo,0) as ProgramNo,isnull(P.PartsCount,0) as PartsCount,Partnumber,Round(P.OEE,2) as OEE,L.FinalTarget,
 p.TotalPartsCount,P.AvgOEE  from #LiveDetails L left outer join #Totalgetparts P        
 on L.Machineid=P.Machineid and L.[From Time]=P.Fromtime and L.[To Time]=P.Totime         
 Order by L.Machineid,L.[From Time]        
        
        
--    Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],          
--    sum(DATEDIFF( MINUTE,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,          
--    sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,        
--    sum(Round([Operating time],2)) as  [Operating time],        
--   sum([PartsCount])as [PartsCount]        
--    From #LiveDetails         
        
  Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],          
    sum(DATEDIFF( MINUTE,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,          
    sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,        
    sum(Round([Operating time],2)) as  [Operating time],        
   sum([PartsCount])as [PartsCount]        
    From #LiveDetails1        
-----SV        
end        
        
If @param = 'hour' or @Param='OEMhour'        
Begin          
        
------SV        
-- select Machineid,ShiftDate,ShiftName,[From Time],[To Time],Round(Powerontime,2) as Powerontime,[PartsCount],        
-- Round([Cutting time],2) as [Cutting time],Round([Operating time],2) as [Operating time] from #LiveDetails         
-- Order by Machineid,ShiftDate,shiftname         
        
 select DENSE_RANK() OVER(Order By L.[From Time]) as ID,L.Machineid,L.ShiftDate,L.ShiftName,L.[From Time],L.[To Time],Round(L.Powerontime,2) as Powerontime,        
 Round(L.[Cutting time],2) as [Cutting time],Round(L.[Operating time],2) as [Operating time],        
 isnull(P.ProgramNo,0) as ProgramNo,isnull(P.PartsCount,0) as PartsCount,Partnumber,Round(P.OEE,2) as OEE,L.FinalTarget,P.TotalPartsCount,P.AvgOEE from #LiveDetails L left outer join #Totalgetparts P        
 on L.Machineid=P.Machineid and L.[From Time]=P.Fromtime and L.[To time]=P.Totime-- where P.PartsCount>0        
 Order by L.Machineid,L.ShiftDate,L.shiftname         
        
--    Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],          
--    sum(DATEDIFF( MINUTE,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,          
--    sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,        
--    sum(Round([Operating time],2)) as  [Operating time],        
-- sum([PartsCount]) as [PartsCount]        
--    From #LiveDetails         
        
      Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],          
    sum(DATEDIFF( MINUTE,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,          
    sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,        
    sum(Round([Operating time],2)) as  [Operating time],        
 sum([PartsCount]) as [PartsCount]        
    From #LiveDetails1        
-----SV        
end        
        
        
declare @threshold as int        
Select @threshold = isnull(ValueInText,10) from Focas_Defaults where parameter='DowntimeThreshold'        
        
--Vasavi Added From Here.        
If @threshold = '' or @threshold is NULL        
Begin        
 select @threshold='10'        
End        
        
        
if @param='Stoppages'         
Begin        
        
  insert into #MachinewiseStoppages(Machineid,ShiftDate,fromtime,totime,ShiftName,BatchTS,Batchstart,BatchEnd,MachineStatus,TotalStoppage)        
  select L1.Machineid,L1.ShiftDate,L1.[From Time],L1.[To Time],L1.Shiftname,F.machineupdownbatchts,min(F.cnctimestamp),max(F.cnctimestamp)        
  ,case when F.machineupdownstatus=0 then 'Down'        
  when F.machineupdownstatus=1 then 'Prod' end,0 from #FocasLivedata F with(NOLOCK)        
  inner join #LiveDetails L1 on L1.machineid=F.machineid         
  and F.cnctimestamp>=L1.[From Time] and F.cnctimestamp<=L1.[To Time]        
  where F.machineupdownbatchts is not null        
  group by L1.Machineid,L1.ShiftDate,L1.[From Time],L1.[To Time],L1.ShiftName,F.machineupdownbatchts,F.machineupdownstatus        
  order by L1.Machineid,L1.ShiftDate,L1.[From Time],L1.ShiftName        
        
        
  update #MachinewiseStoppages set Stoppagetime = datediff(s,Batchstart,BatchEnd)   

  update #MachinewiseStoppages set TotalStoppage = T1.TotalStoppage from
  (Select Machineid,SUM(Stoppagetime) as TotalStoppage from  #MachinewiseStoppages 
   where Stoppagetime>(@threshold) and MachineStatus='Down' Group by Machineid)T1 
  inner join #MachinewiseStoppages on #MachinewiseStoppages.Machineid=T1.Machineid
     
  if(@param1 ='Day')        
  BEGIN        
  select Machineid, convert(varchar, fromtime, 105) as [From Time],ToTime as [To Time],ShiftName,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,        
  Stoppagetime as StoppagetimeInSec,Reason,dbo.f_FormatTime(TotalStoppage,'hh:mm:ss') as TotalStoppage from #MachinewiseStoppages         
  where Stoppagetime>(@threshold) and MachineStatus='Down' order by Machineid, FromTime        
  END        
        
  if(@param1 ='Shift')        
  BEGIN        
  select Machineid, convert(varchar, fromtime, 105) as [From Time],ToTime as [To Time],ShiftName,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,        
  Stoppagetime as StoppagetimeInSec,Reason,dbo.f_FormatTime(TotalStoppage,'hh:mm:ss') as TotalStoppage from #MachinewiseStoppages         
  where Stoppagetime>(@threshold) and MachineStatus='Down' order by Machineid, FromTime,ShiftName        
  END        
        
  if(@param1 ='hour')        
  BEGIN          
   select Machineid, convert(varchar, ShiftDate, 105) as [Date] ,FromTime as [From Time],ToTime as [To Time],ShiftName,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,        
   Stoppagetime as StoppagetimeInSec,Reason,dbo.f_FormatTime(TotalStoppage,'hh:mm:ss') as TotalStoppage from #MachinewiseStoppages              
  where Stoppagetime>(@threshold) and MachineStatus='Down' order by  Machineid,ShiftDate,ShiftName, FromTime        
        
  END        
        
  return        
END        
--Vasavi Added Till Here.        
        
        
End          
           
