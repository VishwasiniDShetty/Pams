/****** Object:  Procedure [dbo].[s_GetFocasShiftwiseLiveDetails]    Committed by VersionSQL https://www.versionsql.com ******/

                
          
/**************************************************************************************************************                
--NR0098 - SwathiKS - 26/Dec/2013 :: Created New Procedure to Get Shiftwise Powerontime and Cuttingtime for the selected Machines and Time Period.                  
--ER0376 - SwathiKS - 18/feb/2014 :: To include New Parameter 'Hour' to get hourwise Powerontime,Cuttingtime,Operatingtime for the selected Days-Shifts-Machines.                
-- Vasavi - 15/04/2015 :: To include New Parameter 'Day' to get daywise Powerontime,Cuttingtime,Operatingtime for the selected Days-Machines.                
--To get summary for the selected day based on the shift,day,hour.                
SwathiKS - 29/Jul/2015 :: To calculate Programwise Partscount for the given Machine and Time Period at Hour-Shift-Day Level.                
exec [dbo].[s_GetFocasShiftwiseLiveDetails] '2022-10-10','2022-10-11','','','''CNC-01''','Stoppages','Day'                  
*************************************************************************************************************/                 
                
CREATE procedure [dbo].[s_GetFocasShiftwiseLiveDetails]                  
 @Starttime datetime,                  
 @Endtime datetime,                  
 @Shiftname nvarchar(50)='',                  
 @PlantID nvarchar(50),                  
 @Machineid nvarchar(1000),                  
 @Param nvarchar(20)='',                
 @param1 nvarchar(50)='' --Vasavi added      
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
 TotalTime float
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
 ShiftDate datetime      
)          
                  
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
 Select @strMachine = ' AND Machineinformation.MachineID  in ( ' +  @machineid + ') '                  
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
 Select @strsql = @strsql +  'Delete from #SDetails where shift not in ( ' +  @Shiftname + ') '   --ER0376                
 exec(@strsql)                  
End                  
                
--ER0376 From here                
INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)                  
select Pdate, Shift, ShiftStart, ShiftEnd from #SDetails                
--ER0376 Till here                
                
                
                
--ER0376 From here                 
If @param = 'Shift' or @param1 ='Shift'  --Vasavi added            
Begin                  
 select @strsql =''                  
 select @strsql = @strsql + 'Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName,TotalTime,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])   --SV                
 SELECT distinct Machineinformation.machineid,S.PDate,S.shiftstart,S.shiftend,S.Shift,DATEDIFF(SECOND,S.shiftstart,S.shiftend),0,0,0,0,0 FROM Machineinformation  --SV                
 --inner join Plantmachine on Machineinformation.machineid=Plantmachine.machineid                  
 Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid                  
 Cross join #ShiftDetails S where 1=1'                  
 Select @strsql = @strsql + @strmachine + @StrPlantid                  
 print @strsql                  
 Exec (@strsql)                    
End               
          
           
if @param = 'day' or @param1 ='DAY'  --Vasavi added               
BEGIN            
              
 while @StartTime<=@EndTime                      
 BEGIN                
  Insert into #day([From Time],[To time])                
  Select dbo.f_GetLogicalDay(@StartTime,'start'),dbo.f_GetLogicalDay(@startTime,'End')                
  SELECT @StartTime=DATEADD(DAY,1,@StartTime)                
 END           
               
 select @strsql =''                  
 select @strsql = @strsql + 'Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],TotalTime,ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])  --SV                
 SELECT distinct Machineinformation.machineid,s.[From Time],s.[From Time],s.[To time],DATEDIFF(SECOND,s.[From time],s.[To Time]),0,0,0,0,0,0 FROM Machineinformation  --SV                
 --inner join Plantmachine on Machineinformation.machineid=Plantmachine.machineid                 
 Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid                   
 Cross join #day S where 1=1'                  
 Select @strsql = @strsql + @strmachine + @StrPlantid                  
 print @strsql                  
 Exec (@strsql)           
         
end                
                
If @param = 'Hour'  or @param1 ='Hour' --Vasavi Added              
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
 select @strsql = @strsql + 'Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],TotalTime,ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])   --SV                
 SELECT distinct Machineinformation.machineid,S.PDate,S.Hourstart,S.Hourend,DATEDIFF(SECOND,S.Hourstart,S.Hourend),S.Shift,0,0,0,0,0 FROM Machineinformation   --SV                
 --inner join Plantmachine on Machineinformation.machineid=Plantmachine.machineid                  
 Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid                  
 Cross join #HourDetails S where 1=1'                  
 Select @strsql = @strsql + @strmachine + @StrPlantid                  
 print @strsql                  
 Exec (@strsql)                   
END                
                
                
If @param = 'OEMHour'                
BEGIN                
                
               
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
           
          
If @param = 'Shift'              
BEGIN            
          
Update #LiveDetails set [Powerontime]  = isnull(#LiveDetails.[Powerontime] ,0) + isnull(T2.Powerontime,0),                
[Cutting time]  = isnull([Cutting time] ,0) + isnull(T2.Cuttingtime,0),                  
[Operating time]  = isnull([Operating time] ,0) + isnull(T2.Operatingtime,0)  From                  
(select L.ShiftDate,L.ShiftName,L.machineid,Sum(F.Powerontime) as Powerontime,Sum(F.Cuttingtime) as Cuttingtime,Sum(F.Operatingtime) as Operatingtime          
from FocasWeb_ShiftwiseSummary F inner join #LiveDetails L on L.machineid=F.machineid and Convert(nvarchar(10),F.Date,120)=Convert(nvarchar(10),L.ShiftDate,120) and F.Shift=L.ShiftName               
group by L.ShiftDate,L.ShiftName,L.machineid               
)T2 inner join #LiveDetails on #LiveDetails.ShiftDate = T2.ShiftDate and #LiveDetails.ShiftName = T2.ShiftName and #LiveDetails.Machineid=T2.MachineID            
                
 End            
          
If @param = 'Day'              
BEGIN            
          
Update #LiveDetails set [Powerontime]  = isnull(#LiveDetails.[Powerontime] ,0) + isnull(T2.Powerontime,0),                
[Cutting time]  = isnull([Cutting time] ,0) + isnull(T2.Cuttingtime,0),                  
[Operating time]  = isnull([Operating time] ,0) + isnull(T2.Operatingtime,0)  From                  
(select L.ShiftDate,L.machineid,Sum(F.Powerontime) as Powerontime,Sum(F.Cuttingtime) as Cuttingtime,Sum(F.Operatingtime) as Operatingtime          
from FocasWeb_ShiftwiseSummary F inner join #LiveDetails L on L.machineid=F.machineid and Convert(nvarchar(10),F.Date,120)=Convert(nvarchar(10),L.ShiftDate,120)           
group by L.ShiftDate,L.machineid                  
)T2 inner join #LiveDetails on #LiveDetails.ShiftDate = T2.ShiftDate and #LiveDetails.Machineid=T2.MachineID            
                
 End            
          
          
          
If @param = 'Hour' or @param = 'OEMHour'                
BEGIN            
          
Update #LiveDetails set [Powerontime]  = isnull(#LiveDetails.[Powerontime] ,0) + isnull(T2.Powerontime,0),                
[Cutting time]  = isnull([Cutting time] ,0) + isnull(T2.Cuttingtime,0),                  
[Operating time]  = isnull([Operating time] ,0) + isnull(T2.Operatingtime,0)  From                  
(select L.ShiftDate,L.ShiftName,L.[From Time],L.[To Time],L.machineid,Sum(F.Powerontime) as Powerontime,Sum(F.Cuttingtime) as Cuttingtime,Sum(F.Operatingtime) as Operatingtime          
from FocasWeb_HourwiseTimeInfo F              
inner join #LiveDetails L on L.machineid=F.machineid and Convert(nvarchar(10),F.Date,120)=Convert(nvarchar(10),L.ShiftDate,120) and F.Shift=L.ShiftName                   
and F.HourStart=L.[From Time]  and F.HourEnd=L.[To Time]                   
group by L.ShiftDate,L.ShiftName,L.[From Time],L.[To Time],L.machineid                   
)T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.[From Time] and #LiveDetails.Machineid=T2.MachineID            
                
 End           
            
          
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
 [PartsCount] int                   
)                 
                
Create table #Totalgetparts                
(                
 id bigint,                
 Machineid nvarchar(50),           
 ShiftDate datetime,          
 Shift nvarchar(50),               
 Fromtime datetime,                
 Totime datetime,                
 ProgramNo nvarchar(50),                
 Partscount int,                
 Total int,                
 Partnumber nvarchar(4000),  
 Target float,  
 OEE float,
 Cycletime float               
)                
                
truncate table #Totalgetparts                
          
declare @DataStart as datetime            
declare @DataEnd as datetime            
            
select @DataStart= (select top 1 [From Time] from #LiveDetails order by [From Time])            
select @DataEnd = (select top 1 [To Time] from #LiveDetails order by [From Time] desc)            

declare @Curtime as datetime
Select @Curtime=Getdate()          
 
     
If @Param='Shift'          
Begin          
 --To Sum up all the Parts at ProgramNo Level for the given Machine and time Period.                
 Insert into #Totalgetparts(id,Machineid,ShiftDate,Shift,ProgramNo,Partscount,total,Partnumber,Target,OEE,Cycletime)                
 Select row_number() over(order by Machineid) as id, Machineid,date,Shift,ProgramID,isnull(Sum(Partcount),0)as Partscount,0 as total,ProgramBlock,0,0,MAX(Cycletime) from FocasWeb_HourwiseCycles                
 where (partcount>0 and Convert(nvarchar(10),Date,120)>=Convert(nvarchar(10),@DataStart,120) and Convert(nvarchar(10),Date,120)<=Convert(nvarchar(10),@DataEnd,120))          
 group by Machineid,date,Shift,ProgramID,ProgramBlock order by Machineid,date     
  
--update #Totalgetparts set Target= T.Target from       
--(select T.Machineid,T.ShiftDate,T.Shift,T.ProgramNo,ROUND((ISNULL(cast(T.Partscount as float),0)*(60/Isnull(cast(F.Target as float),0))),2) as Target from #Totalgetparts T  
--inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join      
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.ShiftDate=T.ShiftDate and #totalgetparts.Shift=T.Shift  
--  
-- 
--update #Totalgetparts set OEE= T.OEE from       
--(select T.Machineid,T.ShiftDate,T.Shift,ROUND((ISNULL(cast(SUM(T.Target) as float),0)/cast(Datediff(minute,L.[From Time],case when L.[To Time]>@Curtime then @Curtime else L.[To Time] END) as float))*100,2) as OEE from #Totalgetparts T  
--inner join #LiveDetails L on L.Machineid=T.Machineid and convert(nvarchar(10),L.ShiftDate,120)=convert(nvarchar(10),T.ShiftDate,120) and L.ShiftName=T.Shift
--Group by T.Machineid,T.ShiftDate,T.Shift,L.[From Time],L.[To Time])T inner join      
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ShiftDate=T.ShiftDate and #totalgetparts.Shift=T.Shift  

--update #Totalgetparts set Target= T.Target from               
--(select Machineid,OEETarget as Target from machineinformation)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID 


--update #Totalgetparts set OEE= T.OEE from       
--(select T.Machineid,T.ShiftDate,T.Shift,ROUND(ISNULL(cast(SUM(T.Partscount) as float),0)/ISNULL(cast(SUM(T.Target) as float),0),2) as OEE from #Totalgetparts T         
--inner join #LiveDetails L on L.Machineid=T.Machineid and convert(nvarchar(10),L.ShiftDate,120)=convert(nvarchar(10),T.ShiftDate,120) and L.ShiftName=T.Shift
--where T.Target>0   Group by T.Machineid,T.ShiftDate,T.Shift,L.[From Time],L.[To Time])T inner join      
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ShiftDate=T.ShiftDate and #totalgetparts.Shift=T.Shift  
 --------------------------COMMENTED FOR CHINA--------------------------    
UPDATE #Totalgetparts
SET Fromtime = T.FromTime,
	Totime = T.Totime 
FROM 
    (
	SELECT DISTINCT Shiftdate ,ShiftName, [From time] as FromTime ,[To Time] as Totime
	from #LiveDetails
	) t
INNER JOIN  #Totalgetparts Tp On  CONVERT(nvarchar(10),Tp.ShiftDate,120) = CONVERT(nvarchar(10),T.ShiftDate,120)  AND Tp.Shift = T.ShiftName

-- update #Totalgetparts set Target= T.Target from               
--(select T.Machineid,T.Fromtime,T.ProgramNo,ROUND((ISNULL(cast(T.Partscount as float),0)*(Isnull(cast(F.Cycletime as float),0))),2) as Target from #Totalgetparts T          
--inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.Fromtime=T.Fromtime          

update #Totalgetparts set Target= ROUND((ISNULL(cast(Partscount as float),0)*(Isnull(cast(Cycletime as float),0))),2)
         
--update #Totalgetparts set OEE= T1.OEE from  
--(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(T.Target as float),0)/cast(Datediff(second,T.Fromtime,T.Totime) as float))*100,2) as OEE from                  
--	(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as Target from #Totalgetparts T          
--	Group by T.Machineid,T.Fromtime,T.Totime
--	)T 
--)T1 inner join #totalgetparts on #totalgetparts.machineID=T1.MachineID and #totalgetparts.Fromtime=T1.Fromtime          

update #Totalgetparts set OEE= T1.OEE from  
(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(T.Target as float),0)/Isnull([Operating time],0))*100,2) as OEE from                  
	(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as Target from #Totalgetparts T          
	Group by T.Machineid,T.Fromtime,T.Totime
	)T inner join #LiveDetails L on L.Machineid=T.Machineid and L.[From Time]=T.Fromtime and L.[To Time]=T.Totime 
where Isnull([Operating time],0)<>0	           	              
)T1 inner join #totalgetparts on #totalgetparts.machineID=T1.MachineID and #totalgetparts.Fromtime=T1.Fromtime
          
end          
          
If @Param='Day'          
Begin      
    
 --To Sum up all the Parts at ProgramNo Level for the given Machine and time Period.                
 Insert into #Totalgetparts(id,Machineid,ShiftDate,ProgramNo,Partscount,total,Partnumber,Target,OEE,Cycletime)                
 Select row_number() over(order by Machineid) as id, Machineid,date,ProgramID,isnull(Sum(Partcount),0)as Partscount,0 as tota,ProgramBlock,0,0,MAX(Cycletime) from FocasWeb_HourwiseCycles          
  where (partcount>0 and Convert(nvarchar(10),Date,120)>=Convert(nvarchar(10),@DataStart,120) and Convert(nvarchar(10),Date,120)<=Convert(nvarchar(10),@DataEnd,120))          
  group by Machineid,date,ProgramID,ProgramBlock order by Machineid,date    
  
--update #Totalgetparts set Target= T.Target from       
--(select T.Machineid,T.ShiftDate,T.ProgramNo,ROUND((ISNULL(cast(T.Partscount as float),0)*(60/Isnull(cast(F.Target as float),0))),2) as Target from #Totalgetparts T  
--inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join      
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.ShiftDate=T.ShiftDate  
--  
--
--update #Totalgetparts set OEE= T.OEE from       
--(select T.Machineid,T.ShiftDate,ROUND((ISNULL(cast(SUM(T.Target) as float),0)/cast(Datediff(minute,L.[From Time],case when L.[To Time]>@Curtime then @Curtime else L.[To Time] END) as float))*100,2) as OEE from #Totalgetparts T 
--inner join #LiveDetails L on L.Machineid=T.Machineid and convert(nvarchar(10),L.ShiftDate,120)=convert(nvarchar(10),T.ShiftDate,120)
--Group by T.Machineid,T.ShiftDate,L.[From Time],L.[To Time])T inner join      
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ShiftDate=T.ShiftDate  

--update #Totalgetparts set Target= T.Target from               
--(select Machineid,OEETarget as Target from machineinformation)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID 

         
--update #Totalgetparts set OEE= T.OEE from       
--(select T.Machineid,T.ShiftDate,ROUND(ISNULL(cast(SUM(T.Partscount) as float),0)/ISNULL(cast(SUM(T.Target) as float),0),2) as OEE from #Totalgetparts T         
--inner join #LiveDetails L on L.Machineid=T.Machineid and convert(nvarchar(10),L.ShiftDate,120)=convert(nvarchar(10),T.ShiftDate,120)
--where T.Target>0   Group by T.Machineid,T.ShiftDate,L.[From Time],L.[To Time])T inner join      
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ShiftDate=T.ShiftDate       

 --------------------------COMMENTED FOR CHINA--------------------------    
 UPDATE #Totalgetparts
SET Fromtime = T.FromTime,
	Totime = T.Totime 
FROM 
    (
	SELECT DISTINCT Shiftdate , [From time] as FromTime ,[To Time] as Totime
	from #LiveDetails
	) t
INNER JOIN  #Totalgetparts Tp On  CONVERT(nvarchar(10),Tp.ShiftDate,120) = CONVERT(nvarchar(10),T.ShiftDate,120)

-- update #Totalgetparts set Target= T.Target from               
--(select T.Machineid,T.Fromtime,T.ProgramNo,ROUND((ISNULL(cast(T.Partscount as float),0)*(Isnull(cast(F.Cycletime as float),0))),2) as Target from #Totalgetparts T          
--inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.Fromtime=T.Fromtime          

--update #Totalgetparts set OEE= T1.OEE from  
--(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(T.Target as float),0)/cast(Datediff(second,T.Fromtime,T.Totime) as float))*100,2) as OEE from                  
--	(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as Target from #Totalgetparts T          
--	Group by T.Machineid,T.Fromtime,T.Totime
--	)T 
--)T1 inner join #totalgetparts on #totalgetparts.machineID=T1.MachineID and #totalgetparts.Fromtime=T1.Fromtime          

update #Totalgetparts set Target=ROUND((ISNULL(cast(Partscount as float),0)*(Isnull(cast(Cycletime as float),0))),2)

update #Totalgetparts set OEE= T1.OEE from  
(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(T.Target as float),0)/Isnull([Operating time],0))*100,2) as OEE from                  
	(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as Target from #Totalgetparts T          
	Group by T.Machineid,T.Fromtime,T.Totime
	)T inner join #LiveDetails L on L.Machineid=T.Machineid and L.[From Time]=T.Fromtime and L.[To Time]=T.Totime 
where Isnull([Operating time],0)<>0	                         
)T1 inner join #totalgetparts on #totalgetparts.machineID=T1.MachineID and #totalgetparts.Fromtime=T1.Fromtime

end          
          
If @Param='Hour' or @Param='OEMHour'          
Begin          
 --To Sum up all the Parts at ProgramNo Level for the given Machine and time Period.                
 Insert into #Totalgetparts(id,Machineid,ShiftDate,Shift,Fromtime,Totime,ProgramNo,Partscount,total,Partnumber,Target,OEE,Cycletime)                
 Select row_number() over(order by Machineid) as id, Machineid,date,Shift,Hourstart,HourEnd,ProgramID,isnull(Sum(Partcount),0)as Partscount,0 as total,ProgramBlock,0,0,MAX(Cycletime) from FocasWeb_HourwiseCycles                
 where (partcount>0 and Convert(nvarchar(10),Date,120)>=Convert(nvarchar(10),@DataStart,120) and Convert(nvarchar(10),Date,120)<=Convert(nvarchar(10),@DataEnd,120))          
 group by Machineid,date,Shift,Hourstart,HourEnd,ProgramID,ProgramBlock order by Machineid,Hourstart               
    
--update #Totalgetparts set Target= T.Target from       
--(select T.Machineid,T.Fromtime,T.ProgramNo,ROUND((ISNULL(cast(T.Partscount as float),0)*(60/Isnull(cast(F.Target as float),0))),2) as Target from #Totalgetparts T  
--inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join      
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.Fromtime=T.Fromtime  
--  
--  
--update #Totalgetparts set OEE= T.OEE from       
--(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(SUM(T.Target) as float),0)/cast(Datediff(minute,T.Fromtime,case when T.Totime>@Curtime then @Curtime else T.Totime END) as float))*100,2) as OEE from #Totalgetparts T  
--Group by T.Machineid,T.Fromtime,T.Totime)T inner join      
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.Fromtime=T.Fromtime  
 
--update #Totalgetparts set Target= T.Target from               
--(select Machineid,OEETarget as Target from machineinformation)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID 
  

--update #Totalgetparts set OEE= T.OEE from       
--(select T.Machineid,T.Fromtime,T.Totime,ROUND(ISNULL(cast(SUM(T.Partscount) as float),0)/ISNULL(cast(SUM(T.Target) as float),0),2) as OEE from #Totalgetparts T  where T.Target>0         
--Group by T.Machineid,T.Fromtime,T.Totime)T inner join      
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.Fromtime=T.Fromtime     

 --------------------------COMMENTED FOR CHINA--------------------------    

-- update #Totalgetparts set Target= T.Target from               
--(select T.Machineid,T.Fromtime,T.ProgramNo,ROUND((ISNULL(cast(T.Partscount as float),0)*(Isnull(cast(F.Cycletime as float),0))),2) as Target from #Totalgetparts T          
--inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.Fromtime=T.Fromtime          

--update #Totalgetparts set OEE= T1.OEE from  
--(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(T.Target as float),0)/cast(Datediff(second,T.Fromtime,T.Totime) as float))*100,2) as OEE from                  
--	(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as Target from #Totalgetparts T          
--	Group by T.Machineid,T.Fromtime,T.Totime
--	)T 
--)T1 inner join #totalgetparts on #totalgetparts.machineID=T1.MachineID and #totalgetparts.Fromtime=T1.Fromtime          

update #Totalgetparts set Target= ROUND((ISNULL(cast(Partscount as float),0)*(Isnull(cast(Cycletime as float),0))),2)

update #Totalgetparts set OEE= T1.OEE from  
(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(T.Target as float),0)/Isnull([Operating time],0))*100,2) as OEE from                  
	(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as Target from #Totalgetparts T          
	Group by T.Machineid,T.Fromtime,T.Totime
	)T inner join #LiveDetails L on L.Machineid=T.Machineid and L.[From Time]=T.Fromtime and L.[To Time]=T.Totime  
where Isnull([Operating time],0)<>0	           	             
)T1 inner join #totalgetparts on #totalgetparts.machineID=T1.MachineID and #totalgetparts.Fromtime=T1.Fromtime

end          
           
Update #LiveDetails Set [Cutting time] = round([Cutting time]/60,0) where [Cutting time]>0               
Update #LiveDetails Set [Operating time] = round([Operating time] /60,0) where [Operating time]>0             
Update #LiveDetails Set [Powerontime] = [Powerontime]/60 where [Powerontime]>0            
          
          
Insert into #LiveDetails1([Machineid],[From Time],[To time],[Powerontime],[Cutting time],[Operating time],[Partscount])            
Select Machineid,min([From time]),Max([To time]),0,0,0,0  from #Livedetails group by Machineid-- order by machineid,[From time]           
          
          
Update #LiveDetails1 set [Powerontime]  = Isnull([Powerontime],0) + ISNULL(T1.PTime,0),              
[Cutting time]  = Isnull([Cutting time],0) + ISNULL(T1.CTime,0),              
[Operating time] = Isnull([Operating time],0) + ISNULL(T1.OTime,0) from               
(Select L.machineid,sum(L.Powerontime) as Ptime,              
sum(L.[Cutting time]) as CTime,sum(L.[Operating time]) as OTime from #LiveDetails L            
group by L.machineid)T1              
inner join #LiveDetails1 on #LiveDetails1.Machineid = T1.MachineID              
          
--Update #LiveDetails1 Set [Cutting time] = [Cutting time]/60 where [Cutting time]>0                   
--Update #LiveDetails1 Set [Powerontime] = [Powerontime]/60 where [Powerontime]>0               
--Update #LiveDetails1 Set [Operating time] = [Operating time] /60 where [Operating time]>0              

Update #LiveDetails1 Set [Cutting time] = [Cutting time] where [Cutting time]>0                   
Update #LiveDetails1 Set [Powerontime] = [Powerontime] where [Powerontime]>0               
Update #LiveDetails1 Set [Operating time] = [Operating time] where [Operating time]>0              
            
Update #LiveDetails1 set [PartsCount] = T1.Parts 
 from          
(select Machineid,isnull(sum(Partscount),0) as Parts from  #Totalgetparts where PartsCount>0 group by machineid)T1           
inner join #livedetails1 on T1.machineid=#livedetails1.machineid          
                
          
If @param = 'shift'                
Begin                 
               
 Select L.Machineid,L.ShiftDate,L.ShiftName,Round(L.Powerontime,2) as Powerontime,Round(L.[Cutting time],2) as [Cutting time],                
 Round(L.[Operating time],2) as [Operating time],isnull(P.ProgramNo,0) as ProgramNo,isnull(P.PartsCount,0) as PartsCount,Partnumber,P.OEE as OEE,dbo.f_FormatTime(L.TotalTime,'mm') as TotalTime
 from #LiveDetails L left outer join #Totalgetparts P                
 on L.Machineid=P.Machineid and convert(nvarchar(10),L.Shiftdate,120)=convert(nvarchar(10),P.Shiftdate,120) and L.Shiftname=P.Shift                 
    Order by L.Machineid,L.ShiftDate,L.shiftname                 
               
  Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],                  
    sum(DATEDIFF( MINUTE,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,                  
    sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,                
    sum(Round([Operating time],2)) as  [Operating time], sum([PartsCount])as [PartsCount]                
    From #LiveDetails1               
end                
                
 If @param = 'Day'                
Begin                  
          
 select L.Machineid,L.[From Time],L.[To Time],Round(L.Powerontime,2) as Powerontime,Round(L.[Cutting time],2) as [Cutting time],                
	 Round(L.[Operating time],2) as [Operating time],isnull(P.ProgramNo,0) as ProgramNo,isnull(P.PartsCount,0) as PartsCount,Partnumber,P.OEE as OEE,dbo.f_FormatTime(L.TotalTime,'mm') as TotalTime 
	 from #LiveDetails L 
	 left outer join #Totalgetparts P                
	 on L.Machineid=P.Machineid and convert(nvarchar(10),L.Shiftdate,120)=convert(nvarchar(10),P.Shiftdate,120)                
	 Order by L.Machineid,L.[From Time]                
               
  Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],                  
    sum(DATEDIFF( MINUTE,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,                  
    sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,                
    sum(Round([Operating time],2)) as  [Operating time],                
   sum([PartsCount])as [PartsCount]                
    From #LiveDetails1          
             
end                
                
If @param = 'hour' or @Param='OEMhour'                
Begin                  
               
 select L.Machineid,L.ShiftDate,L.ShiftName,L.[From Time],L.[To Time],Round(L.Powerontime,2) as Powerontime,                
 Round(L.[Cutting time],2) as [Cutting time],Round(L.[Operating time],2) as [Operating time],                
 isnull(P.ProgramNo,0) as ProgramNo,isnull(P.PartsCount,0) as PartsCount,Partnumber,P.OEE as OEE,dbo.f_FormatTime(L.TotalTime,'mm') as TotalTime
 from #LiveDetails L left outer join #Totalgetparts P                
 on L.Machineid=P.Machineid and L.[From Time]=P.Fromtime and L.[To time]=P.Totime-- where P.PartsCount>0                
 Order by L.Machineid,L.ShiftDate,L.[From Time]                 
                
  Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],                  
    sum(DATEDIFF( MINUTE,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,                  
    sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,                
    sum(Round([Operating time],2)) as  [Operating time],                
 sum([PartsCount]) as [PartsCount]                
    From #LiveDetails1              
end                
       
      
      
declare @threshold as int      
Select @threshold = isnull(ValueInText,5) from Focas_Defaults where parameter='DowntimeThreshold'      
      
--Vasavi Added From Here.      
If @threshold = '' or @threshold is NULL      
Begin      
 select @threshold='5'      
End      
      
      
if @param='Stoppages'       
Begin      

  select MachineID, MachineStatus, MachineMode, ProgramNo, PowerOnTime, OperatingTime, CutTime, CNCTimeStamp, PartsCount, BatchTS, MachineUpDownStatus, MachineUpDownBatchTS,ProgramBlock      
  into #FocasLivedata from dbo.focas_livedata with(NOLOCK) where cnctimestamp>=@DataStart and cnctimestamp<=@DataEnd      
      
      
  insert into #MachinewiseStoppages(Machineid,ShiftDate,fromtime,totime,ShiftName,BatchTS,Batchstart,BatchEnd,MachineStatus)      
  select L1.Machineid,L1.ShiftDate,L1.[From Time],L1.[To Time],L1.Shiftname,F.machineupdownbatchts,min(F.cnctimestamp),max(F.cnctimestamp)      
  ,case when F.machineupdownstatus=0 then 'Down'      
  when F.machineupdownstatus=1 then 'Prod' end from #FocasLivedata F with(NOLOCK)      
  inner join #LiveDetails L1 on L1.machineid=F.machineid       
  and F.cnctimestamp>=L1.[From Time] and F.cnctimestamp<=L1.[To Time]      
  where F.machineupdownbatchts is not null      
  group by L1.Machineid,L1.ShiftDate,L1.[From Time],L1.[To Time],L1.ShiftName,F.machineupdownbatchts,F.machineupdownstatus      
  order by L1.Machineid,L1.ShiftDate,L1.[From Time],L1.ShiftName      
   
      
  update #MachinewiseStoppages set Stoppagetime = datediff(s,Batchstart,BatchEnd)      
  if(@param1 ='Day')      
  BEGIN      
  select Machineid, 
  --convert(varchar, fromtime, 105) as [From Time],
  fromtime as [From Time],
  ToTime as [To Time],ShiftName,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,      
  Stoppagetime as StoppagetimeInSec,Reason from #MachinewiseStoppages       
  --where Stoppagetime>(@threshold*60) and MachineStatus='Down' order by Machineid, FromTime      
  where Stoppagetime>(@threshold) and MachineStatus='Down' order by Machineid, FromTime      
  END      
      
  if(@param1 ='Shift')      
  BEGIN      
  select Machineid, 
  --convert(varchar, fromtime, 105) as [From Time],
  fromtime as [From Time],
  ToTime as [To Time],ShiftName,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,      
  Stoppagetime as StoppagetimeInSec,Reason from #MachinewiseStoppages       
  --where Stoppagetime>(@threshold*60) and MachineStatus='Down' order by Machineid, FromTime,ShiftName      
  WHERE Stoppagetime>(@threshold) and MachineStatus='Down' order by Machineid, FromTime,ShiftName      
  END      
      
  if(@param1 ='hour')      
  BEGIN        
   select Machineid, convert(varchar, ShiftDate, 105) as [Date] ,FromTime as [From Time],ToTime as [To Time],ShiftName,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,      
   Stoppagetime as StoppagetimeInSec,Reason from #MachinewiseStoppages            
  --where Stoppagetime>(@threshold*60) and MachineStatus='Down' order by  Machineid,ShiftDate,ShiftName, FromTime      
   where Stoppagetime>(@threshold) and MachineStatus='Down' order by  Machineid,ShiftDate,ShiftName, FromTime      
      
  END      
      
  return      
END      
--Vasavi Added Till Here.      
      
               
End 
