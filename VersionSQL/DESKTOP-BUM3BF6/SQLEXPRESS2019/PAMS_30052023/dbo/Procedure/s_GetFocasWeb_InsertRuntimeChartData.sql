/****** Object:  Procedure [dbo].[s_GetFocasWeb_InsertRuntimeChartData]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
-- Author:		Anjana  C V
-- Create date: 05 June 2020
-- Modified date: 05 June 2020
-- Description: To aggregate runtime chart data 
exec s_GetFocasWeb_InsertRuntimeChartData '','','2020-07-10 07:00:00'
**************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetFocasWeb_InsertRuntimeChartData]                               
 @PlantID nvarchar(50) = '',                
 @Machineid nvarchar(max)='',                
 @DateTime DateTime = ''

WITH RECOMPILE              
AS              
BEGIN 

SET NOCOUNT ON;              
              
if (@Datetime>getdate() or  ISNULL(@Datetime,'')= ''  )        
Begin              
	set @Datetime=getdate()              
End       
       
Create Table #LiveDetails                
(                
 SlNo Bigint Identity(1,1) Not Null,                
 Machineid nvarchar(50),        
 PlantID nvarchar(50),               
 MachineStatus nvarchar(100),              
 RunningProgram nvarchar(100),              
 ShiftDate datetime,                
 ShiftName nvarchar(50),                
 FromTime datetime,                
 ToTime datetime          
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
FromTime datetime,              
ToTime datetime              
)                
        
CREATE TABLE #MachinewiseStoppages              
(              
 id bigint identity(1,1),  
 PlantID nvarchar(50),            
 Machineid nvarchar(50),              
 Fromtime datetime,              
 Totime datetime,  
 ShiftDate Datetime,
 ShiftName nvarchar(50),            
 BatchTS datetime,              
 BatchStart datetime,              
 BatchEnd datetime,              
 Stoppagetime int,              
 MachineStatus nvarchar(50),              
 Reason nvarchar(50),              
 AlarmStatus nvarchar(50),
 TotalStoppage float              
)              

CREATE TABLE #TempNodata              
(              
 Machineid nvarchar(50),              
 Fromtime datetime,              
 Totime datetime,                          
 BatchStart datetime
)

CREATE TABLE #Nodata              
(              
 Machineid nvarchar(50),              
 Fromtime datetime,              
 Totime datetime,                          
 starttime datetime,
 Endtime datetime
)

Declare @strsql nvarchar(max)                
Declare @strmachine nvarchar(max)                
Declare @StrPlantid as nvarchar(1000)                
Declare @CurStrtTime as datetime                
DECLARE @joined NVARCHAR(500)--ER0210  
                
Select @strsql = ''                
Select @strmachine = ''                
select @strPlantID = ''                

select @joined = coalesce(@joined + ',''', '''')+item+'''' from [SplitStrings](@machineid, ',')     
if @joined = ''''''  
set @joined = ''  
                              
if isnull(@PlantID,'') <> ''                
Begin                
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'                
End              

if isnull(@Machineid,'') <> ''                
Begin                
 Select @strmachine = ' and ( machineinformation.machineid in (' + @joined + '))'                
End 
                  
Select @CurStrtTime=@DateTime              

INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)                 
	EXEC s_GetShiftTime @CurStrtTime,''   

	Select @strsql=''
	select @strsql=@strsql+'  
	Insert into #LiveDetails (PlantID,Machineid,ShiftDate,FromTime,ToTime,ShiftName)  
	SELECT distinct PlantMachine.PlantID,Machineinformation.machineid,S.Pdate,S.ShiftStart,S.ShiftEnd,S.Shift 
	FROM dbo.Machineinformation              
	left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid                
	Cross join #ShiftDetails S '
	select @strsql =  @strsql + ' where machineinformation.interfaceid>0 '
	select @strsql =  @strsql + @StrPlantid + @strmachine
	print(@strsql)
	EXEC(@Strsql) 

declare @DataStart as datetime              
declare @DataEnd as datetime              
              
select @DataStart= (select top 1 FromTime from #LiveDetails order by FromTime)              
select @DataEnd = (select top 1 ToTime from #LiveDetails order by FromTime desc)              
              
select MachineID, MachineStatus, MachineMode, ProgramNo, PowerOnTime, OperatingTime, CutTime, CNCTimeStamp, PartsCount, BatchTS, MachineUpDownStatus, MachineUpDownBatchTS              
into #FocasLivedata 
from dbo.focas_livedata with(NOLOCK) where cnctimestamp>=@DataStart and cnctimestamp<=@DataEnd              
                            
declare @threshold as int              
Select @threshold = isnull(ValueInText,10) from Focas_Defaults where parameter='DowntimeThreshold'              
                           
If @threshold = '' or @threshold is NULL              
Begin              
 select @threshold='10'              
End              
                         
insert into #MachinewiseStoppages(PlantID,Machineid,fromtime,totime,ShiftName,ShiftDate,BatchTS,Batchstart,BatchEnd,MachineStatus)              
select L1.PlantID,L1.Machineid,L1.FromTime,L1.ToTime,L1.ShiftName,L1.ShiftDate,F.machineupdownbatchts,
min(F.cnctimestamp),max(F.cnctimestamp)              
,case when F.machineupdownstatus=0 then 'Down'              
when F.machineupdownstatus=1 then 'Prod' end 
from #FocasLivedata F with(NOLOCK)              
inner join #LiveDetails L1 on L1.machineid=F.machineid and F.cnctimestamp>=L1.FromTime and F.cnctimestamp<=L1.ToTime              
where F.machineupdownbatchts is not null              
group by L1.PlantID,L1.Machineid,L1.FromTime,L1.ToTime,L1.ShiftName,L1.ShiftDate,F.machineupdownbatchts,F.machineupdownstatus              
order by L1.PlantID,L1.Machineid,L1.FromTime,F.machineupdownbatchts              

update #MachinewiseStoppages set Stoppagetime = datediff(s,Batchstart,BatchEnd)              
    
update #MachinewiseStoppages set TotalStoppage = T1.TotalStoppage from
(Select Machineid,SUM(Stoppagetime) as TotalStoppage from  #MachinewiseStoppages 
where Stoppagetime>(@threshold) and MachineStatus='Down' Group by Machineid)T1 
inner join #MachinewiseStoppages on #MachinewiseStoppages.Machineid=T1.Machineid

select M1.PlantID,M1.fromtime,M1.ShiftDate,M1.ShiftName ,M1.totime,M1.machineid,M1.batchend as starttime,min(m2.batchstart) as endtime 
into #NOdata1 
from #MachinewiseStoppages M1               
inner join #MachinewiseStoppages M2 on M1.machineid=M2.machineid              
where M1.id<M2.id 
group by M1.PlantID,M1.fromtime,M1.totime,M1.machineid,M1.batchend,M1.ShiftDate ,M1.ShiftName  

--Prediction Logic            
select M1.PlantID,M1.machineid,M1.ShiftDate,M1.ShiftName,min(fromtime) as fromtime,min(totime) as totime,
     case when min(batchstart)>min(fromtime) then min(fromtime) end as starttime,
min(batchstart) as endtime 
into #NOData2 
from #MachinewiseStoppages M1            
group by M1.PlantID,M1.machineid,M1.ShiftDate ,M1.ShiftName  


Insert into #MachinewiseStoppages(PlantID,Machineid,ShiftDate,ShiftName,fromtime,totime,Batchstart,BatchEnd,Stoppagetime,MachineStatus)              
select PlantID,Machineid,ShiftDate,ShiftName,fromtime,totime,starttime,endtime,datediff(s,starttime,endtime),'NO_DATA' from #NOdata2 where datediff(second,starttime,endtime)>60             
order by Machineid,fromtime,starttime     

Insert into #MachinewiseStoppages(PlantID,Machineid,ShiftDate,ShiftName,fromtime,totime,Batchstart,BatchEnd,Stoppagetime,MachineStatus)              
select PlantID,Machineid,ShiftDate,ShiftName,fromtime,totime,starttime,endtime,datediff(s,starttime,endtime),'NO_DATA' from #NOdata1 where datediff(second,starttime,endtime)>60             
order by Machineid,fromtime,starttime     

Create table #Focas_RunDownTimeAggTrail
(
MachineID nvarchar(50),
startTime datetime,
endtime datetime
)

insert into #Focas_RunDownTimeAggTrail(MachineID,startTime,endtime)
select #MachinewiseStoppages.MachineID,min(#MachinewiseStoppages.BatchStart),min(#MachinewiseStoppages.BatchStart) 
from #MachinewiseStoppages
where NOT EXISTS(select distinct #MachinewiseStoppages.MachineID from #MachinewiseStoppages 
	inner Join Focas_RunDownTimeAggTrail A on #MachinewiseStoppages.MachineID=A.MachineID)
group by #MachinewiseStoppages.MachineID

insert into #Focas_RunDownTimeAggTrail(MachineID,starttime,endtime)
select A.MachineID,MAX(A.Starttime),max(A.RecordEndtime) from Focas_RunDownTimeAggTrail A
where EXISTS(select distinct #MachinewiseStoppages.MachineID from #MachinewiseStoppages 
           inner Join Focas_RunDownTimeAggTrail A on #MachinewiseStoppages.MachineID=A.MachineID)
group by A.MachineID

delete from FocasWeb_RuntimeData 
WHERE BatchStart = (select starttime from #Focas_RunDownTimeAggTrail where machineid = FocasWeb_RuntimeData.machineid)
AND EXISTS (SELECT * from #MachinewiseStoppages M WHERE M.BatchStart = FocasWeb_RuntimeData.BatchStart AND  M.machineid = FocasWeb_RuntimeData.machineid )

INSERT INTO FocasWeb_RuntimeData (PlantID,MachineId,[date],Shift,ShiftStart,ShiftEnd,Batchstart,BatchEnd,Stoppagetime,MachineStatus )
select DISTINCT F.PlantID,F.Machineid,cast(convert(nvarchar(10),ShiftDate,120) as datetime),ShiftName,F.Fromtime,Totime,F.Batchstart,F.BatchEnd,F.Stoppagetime as Stoppagetime,F.MachineStatus as Reason 
	 from #MachinewiseStoppages F
	 inner join #Focas_RunDownTimeAggTrail T on F.MachineID=T.MachineID
     --where  F.BatchStart>=T.endtime
	 where  F.BatchStart>=T.startTime
	Order by F.Machineid,F.Batchstart  

/********************************************************************************************************/ 

Insert into [dbo].Focas_RunDownTimeAggTrail(MachineID,Starttime,Endtime,RecordEndtime,AggregateTS )
Select S.Machineid,Max(S.BatchStart) as Start,MAX(S.BatchEnd) as Endtime,
case when max(T.BatchEnd)>MAX(S.BatchEnd) then MAX(S.BatchEnd) else max(T.BatchEnd) end, getdate() 
from #MachinewiseStoppages S
inner join FocasWeb_RuntimeData T on T.MachineID=S.Machineid
where S.Machineid NOT IN(Select Distinct MachineID From Focas_RunDownTimeAggTrail)
group by S.Machineid

Update Focas_RunDownTimeAggTrail 
	SET Starttime=T1.StartTime,
	Endtime=T1.Endtime,
	RecordEndtime=T1.RecordEndtime,
	AggregateTS=getdate() 
FROM
(
Select S.Machineid,Max(S.BatchStart) as StartTime,MAX(S.BatchEnd) as Endtime,
case when max(T.BatchEnd)>MAX(S.BatchEnd) then MAX(S.BatchEnd) else max(T.BatchEnd) end as RecordEndtime 
from #MachinewiseStoppages S
inner join FocasWeb_RuntimeData T on T.MachineID=S.Machineid
where S.Machineid IN(Select Distinct MachineID From Focas_RunDownTimeAggTrail)
group by S.Machineid
)T1 inner join Focas_RunDownTimeAggTrail on Focas_RunDownTimeAggTrail.MachineID=T1.MachineID 
/********************************************************************************************************/
END

   
