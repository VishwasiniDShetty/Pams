/****** Object:  Procedure [dbo].[s_GetFocasRuntimeChartForMultipleMac]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetFocasRuntimeChartForMultipleMac] '2019-07-11','','',N'','Prod'              
--[dbo].[s_GetFocasRuntimeChartForMultipleMac] '2019-07-01','','',N'VMC-05','Down' 
--[dbo].[s_GetFocasRuntimeChartForMultipleMac] '2019-07-01','','',N'VMC-05','NO_DATA'                
--[dbo].[s_GetFocasRuntimeChartForMultipleMac] '2019-10-17','','',N'','','Totalruntime'              
--[dbo].[s_GetFocasRuntimeChartForMultipleMac] '2019-10-14','','',N'','','TotalDowntime'   
--[dbo].[s_GetFocasRuntimeChartForMultipleMac] '2019-10-14','','',N'','','MaxDowntime'   
--[dbo].[s_GetFocasRuntimeChartForMultipleMac] '2019-10-14','','',N'','','NoOfDownOccurences'   


CREATE PROCEDURE [dbo].[s_GetFocasRuntimeChartForMultipleMac]                
 @Date datetime ='',              
 @Shiftname nvarchar(50)='',                
 @PlantID nvarchar(50),                
 @Machineid nvarchar(max)='',                
 @Param nvarchar(50)='', --Prod/Down/NO_DATA
 @Sorttype nvarchar(50)=''      -- Totalruntime/TotalDowntime/MaxDowntime
              
WITH RECOMPILE              
AS              
BEGIN              
               
 SET NOCOUNT ON;              
              
if (@Date>getdate())              
Begin              
	set @Date=getdate()              
End       
       
Create Table #LiveDetails                
(                
 [Sl No] Bigint Identity(1,1) Not Null,                
 [Machineid] nvarchar(50),                
 [MachineStatus] nvarchar(100),              
 [RunningProgram] nvarchar(100),              
 [ShiftDate] datetime,                
 [ShiftName] nvarchar(50),                
 [From time] datetime,                
 [To Time] datetime          
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


Create table #MachinewiseSort
(
	Machineid nvarchar(50),
	SortOrder int
)

create table #Summary
(
	Machineid nvarchar(50),
	MaxDowntime float,
	TotalRuntime float,
	TotalDowntime float,
	NoOfDownOccurences int
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
                  
Select @CurStrtTime=@Date              

                        
if (@Shiftname='DAY')          
BEGIN              
              
	Insert into #day([From Time],[To time])              
	Select dbo.f_GetLogicalDay(@Date,'start'),dbo.f_GetLogicalDay(@Date,'End')              
 
	Select @strsql=''
	select @strsql=@strsql+'             
	Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName)  
	SELECT distinct Machineinformation.machineid,0,S.[From Time],S.[To time],0 FROM dbo.Machineinformation              
	left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid                
	Cross join #day S '
	select @strsql =  @strsql + ' where machineinformation.interfaceid>0 '
	select @strsql =  @strsql + @StrPlantid + @strmachine
	print(@strsql)
	EXEC(@Strsql)           
end              
Else
Begin
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)                 
	EXEC s_GetShiftTime @CurStrtTime,@Shiftname   

	Select @strsql=''
	select @strsql=@strsql+'  
	Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName)  
	SELECT distinct Machineinformation.machineid,S.Pdate,S.ShiftStart,S.ShiftEnd,S.Shift FROM dbo.Machineinformation              
	left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid                
	Cross join #ShiftDetails S '
	select @strsql =  @strsql + ' where machineinformation.interfaceid>0 '
	select @strsql =  @strsql + @StrPlantid + @strmachine
	print(@strsql)
	EXEC(@Strsql)   
End
                       
declare @DataStart as datetime              
declare @DataEnd as datetime              
              
select @DataStart= (select top 1 [From Time] from #LiveDetails order by [From Time])              
select @DataEnd = (select top 1 [To Time] from #LiveDetails order by [From Time] desc)              
              
select MachineID, MachineStatus, MachineMode, ProgramNo, PowerOnTime, OperatingTime, CutTime, CNCTimeStamp, PartsCount, BatchTS, MachineUpDownStatus, MachineUpDownBatchTS              
into #FocasLivedata from dbo.focas_livedata with(NOLOCK) where cnctimestamp>=@DataStart and cnctimestamp<=@DataEnd              
                            
declare @threshold as int              
Select @threshold = isnull(ValueInText,10) from Focas_Defaults where parameter='DowntimeThreshold'              
                           
If @threshold = '' or @threshold is NULL              
Begin              
 select @threshold='10'              
End              
                         
insert into #MachinewiseStoppages(Machineid,fromtime,totime,BatchTS,Batchstart,BatchEnd,MachineStatus)              
select L1.Machineid,L1.[From Time],L1.[To Time],F.machineupdownbatchts,
min(F.cnctimestamp),max(F.cnctimestamp)              
,case when F.machineupdownstatus=0 then 'Down'              
when F.machineupdownstatus=1 then 'Prod' end from #FocasLivedata F with(NOLOCK)              
inner join #LiveDetails L1 on L1.machineid=F.machineid and F.cnctimestamp>=L1.[From Time] and F.cnctimestamp<=L1.[To Time]              
where F.machineupdownbatchts is not null              
group by L1.Machineid,L1.[From Time],L1.[To Time],F.machineupdownbatchts,F.machineupdownstatus              
order by L1.Machineid,L1.[From Time],F.machineupdownbatchts              

update #MachinewiseStoppages set Stoppagetime = datediff(s,Batchstart,BatchEnd)              
    
update #MachinewiseStoppages set TotalStoppage = T1.TotalStoppage from
(Select Machineid,SUM(Stoppagetime) as TotalStoppage from  #MachinewiseStoppages 
where Stoppagetime>(@threshold) and MachineStatus='Down' Group by Machineid)T1 
inner join #MachinewiseStoppages on #MachinewiseStoppages.Machineid=T1.Machineid

select M1.fromtime,M1.totime,M1.machineid,M1.batchend as starttime,min(m2.batchstart) as endtime into #NOdata1 from #MachinewiseStoppages M1               
inner join #MachinewiseStoppages M2 on M1.machineid=M2.machineid              
where M1.id<M2.id group by M1.fromtime,M1.totime,M1.machineid,M1.batchend   

--Prediction Logic            
select M1.machineid,min(fromtime) as fromtime,min(totime) as totime,case when min(batchstart)>min(fromtime) then min(fromtime) end as starttime,
min(batchstart) as endtime into #NOData2 from #MachinewiseStoppages M1            
group by M1.machineid  


Insert into #MachinewiseStoppages(Machineid,fromtime,totime,Batchstart,BatchEnd,Stoppagetime,MachineStatus)              
select Machineid,fromtime,totime,starttime,endtime,datediff(s,starttime,endtime),'NO_DATA' from #NOdata2 where datediff(second,starttime,endtime)>60             
order by Machineid,fromtime,starttime     

Insert into #MachinewiseStoppages(Machineid,fromtime,totime,Batchstart,BatchEnd,Stoppagetime,MachineStatus)              
select Machineid,fromtime,totime,starttime,endtime,datediff(s,starttime,endtime),'NO_DATA' from #NOdata1 where datediff(second,starttime,endtime)>60             
order by Machineid,fromtime,starttime     

insert into #Summary(Machineid,TotalRuntime)
Select Machineid,sum(Stoppagetime) as Runtime from #MachinewiseStoppages
where MachineStatus='Prod' group by Machineid

update #Summary set TotalDowntime=T.Downtime from
(Select Machineid,sum(Stoppagetime) as Downtime from #MachinewiseStoppages
where MachineStatus='Down' group by Machineid)T inner join #Summary on #Summary.Machineid=T.Machineid

update #Summary set MaxDowntime=T.MaxDowntime from
(Select Machineid,Max(Stoppagetime) as MaxDowntime from #MachinewiseStoppages
where MachineStatus='Down' group by Machineid)T inner join #Summary on #Summary.Machineid=T.Machineid

update #Summary set NoOfDownOccurences=T.NoOfDownOccurences from
(Select Machineid,count(Stoppagetime) as NoOfDownOccurences from #MachinewiseStoppages
where MachineStatus='Down' group by Machineid)T inner join #Summary on #Summary.Machineid=T.Machineid

if @Sorttype='TotalRuntime' or ISNULL(@Sorttype,'')=''
Begin
	Insert into #MachinewiseSort(Machineid,SortOrder)
	Select Machineid,ROW_number() over(order by Runtime desc) from
	(Select Machineid,sum(Stoppagetime) as Runtime from #MachinewiseStoppages
	where MachineStatus='Prod' group by Machineid)T
End

if @Sorttype='TotalDowntime'
Begin
	Insert into #MachinewiseSort(Machineid,SortOrder)
	Select Machineid,ROW_number() over(order by Downtime desc) from
	(Select Machineid,sum(Stoppagetime) as Downtime from #MachinewiseStoppages
	where MachineStatus='Down' group by Machineid)T
End

if @Sorttype='MaxDowntime'
Begin
	Insert into #MachinewiseSort(Machineid,SortOrder)
	Select Machineid,ROW_number() over(order by Downtime desc) from
	(Select Machineid,Max(Stoppagetime) as Downtime from #MachinewiseStoppages
	where MachineStatus='Down' group by Machineid)T

	--Select Machineid,ROW_number() over(order by MaxDowntime desc) from
	--(Select Machineid,Max(Downtime) as MaxDowntime from 
	--	(Select Machineid,sum(Stoppagetime) as Downtime,MachineStatus from #MachinewiseStoppages
	--	where MachineStatus='Down' group by Machineid,MachineStatus
	--	)T1 group by Machineid
	--)T
End

if @Sorttype='NoOfDownOccurences'
Begin
	Insert into #MachinewiseSort(Machineid,SortOrder)
	Select Machineid,ROW_number() over(order by Downtime desc) from
	(Select Machineid,Count(Stoppagetime) as Downtime from #MachinewiseStoppages
	where MachineStatus='Down' group by Machineid)T
End


IF @param=''
Begin        
	select F.Machineid,F.Batchstart,F.BatchEnd,dbo.f_FormatTime(F.Stoppagetime,'hh:mm:ss') as Stoppagetime,F.MachineStatus as Reason from #MachinewiseStoppages F
	inner join #MachinewiseSort M on F.Machineid=M.Machineid
	--order by Machineid,Batchstart,batchend 
	Order by M.SortOrder             
END 

IF @param='Prod'
Begin        
	select F.Machineid,F.Batchstart,F.BatchEnd,dbo.f_FormatTime(F.Stoppagetime,'hh:mm:ss') as Stoppagetime,F.MachineStatus as Reason from #MachinewiseStoppages F
	inner join #MachinewiseSort M on F.Machineid=M.Machineid
	where F.MachineStatus='Prod'
	--order by Machineid,Batchstart    
	Order by M.SortOrder            
END

IF @param='Down'
Begin        
	select F.Machineid,F.Batchstart,F.BatchEnd,dbo.f_FormatTime(F.Stoppagetime,'hh:mm:ss') as Stoppagetime,F.MachineStatus as Reason  from #MachinewiseStoppages F
	inner join #MachinewiseSort M on F.Machineid=M.Machineid
	where F.MachineStatus='Down'
	--order by Machineid,Batchstart   
	Order by M.SortOrder            
END

IF @param='NO_DATA'
Begin        
	select F.Machineid,F.Batchstart,F.BatchEnd,dbo.f_FormatTime(F.Stoppagetime,'hh:mm:ss') as Stoppagetime,F.MachineStatus as Reason  from #MachinewiseStoppages F
	inner join #MachinewiseSort M on F.Machineid=M.Machineid
	where F.MachineStatus='NO_DATA'
	--order by Machineid,Batchstart  
	Order by M.SortOrder             
END

SELECT #Summary.Machineid,dbo.f_FormatTime(TotalRuntime,'hh:mm:ss') as TotalRuntime,dbo.f_FormatTime(TotalDowntime,'hh:mm:ss') as TotalDowntime,
dbo.f_FormatTime(MaxDowntime,'hh:mm:ss') as MaxDowntime,NoOfDownOccurences FROM #Summary inner join #MachinewiseSort M on #Summary.Machineid=M.Machineid
Order by M.SortOrder    

END              
              
