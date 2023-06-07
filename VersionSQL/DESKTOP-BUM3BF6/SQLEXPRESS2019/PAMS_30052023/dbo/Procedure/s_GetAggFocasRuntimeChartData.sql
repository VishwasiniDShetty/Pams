/****** Object:  Procedure [dbo].[s_GetAggFocasRuntimeChartData]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
-- Author:		Anjana  C V
-- Create date: 05 June 2020
-- Modified date: 05 June 2020
-- Description: To Runtime Chart For MultipleMac data from aggregate data
exec s_GetAggFocasRuntimeChartData '','',''
exec s_GetAggFocasRuntimeChartData @Date=N'2020-04-06',@Shiftname=N'夜班',@Machineid=N'M18-MCV-450',@PlantID=N'天津晟宇',@Sorttype=N'MaxDowntime',@param=N'Down'
**************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetAggFocasRuntimeChartData]                
 @Date datetime ='',              
 @Shiftname nvarchar(50)='',                
 @PlantID nvarchar(50)='',                
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
        
CREATE TABLE #MachinewiseStoppages              
(              
 id bigint identity(1,1),              
 Machineid nvarchar(50),              
 --Fromtime datetime,              
 --Totime datetime,              
 BatchTS datetime,              
 BatchStart datetime,              
 BatchEnd datetime,              
 Stoppagetime int,              
 MachineStatus nvarchar(50),              
 Reason nvarchar(50),              
 AlarmStatus nvarchar(50),
 TotalStoppage float                           
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
Declare @strShift  as nvarchar(250)               
Declare @CurStrtTime as datetime                
DECLARE @joined NVARCHAR(500)
                
Select @strsql = ''                
Select @strmachine = ''                
select @strPlantID = ''                
select @strShift = ''

select @joined = coalesce(@joined + ',''', '''')+item+'''' from [SplitStrings](@machineid, ',')     
if @joined = ''''''  
set @joined = ''  
                              
if isnull(@PlantID,'') <> ''                
Begin                
 Select @strPlantID = ' and ( PlantID = N''' + @PlantID + ''')'                
End              

if isnull(@Machineid,'') <> ''                
Begin                
 Select @strmachine = ' and ( machineid in (' + @joined + '))'                
End 

if isnull(@Shiftname,'') <> ''                
Begin                
 Select @strShift = ' and ( Shift = N''' + @Shiftname + ''')'              
End 
                  
Select @CurStrtTime=@Date              
                            
declare @threshold as int              
Select @threshold = isnull(ValueInText,10) from Focas_Defaults where parameter='DowntimeThreshold'              
                           
If @threshold = '' or @threshold is NULL              
Begin              
 select @threshold='10'              
End  
                       
Select @strsql=''
	select @strsql=@strsql+' insert into #MachinewiseStoppages(Machineid,BatchTS,Batchstart,BatchEnd,MachineStatus,Stoppagetime)              
     select F.Machineid,F.BatchTS,F.Batchstart,F.BatchEnd,F.MachineStatus,Stoppagetime 
	from FocasWeb_RuntimeData F                           
	where  convert(nvarchar(10),F.Date,120)   = '''+ convert(nvarchar(10),@Date,120)+'''  '
	select @strsql =  @strsql + @StrPlantid + @strmachine + @strShift
	print(@strsql)
	EXEC(@Strsql)             
 
 
update #MachinewiseStoppages set TotalStoppage = T1.TotalStoppage from
(Select Machineid,SUM(ISNULL(Stoppagetime,0)) as TotalStoppage from  #MachinewiseStoppages 
where Stoppagetime>(@threshold) and MachineStatus='Down' Group by Machineid)T1 
inner join #MachinewiseStoppages on #MachinewiseStoppages.Machineid=T1.Machineid     

insert into #Summary(Machineid,TotalRuntime)
Select Machineid,sum(ISNULL(Stoppagetime,0)) as Runtime from #MachinewiseStoppages
where MachineStatus='Prod' group by Machineid

update #Summary set TotalDowntime=T.Downtime from
(Select Machineid,sum(ISNULL(Stoppagetime,0)) as Downtime from #MachinewiseStoppages
where MachineStatus='Down' group by Machineid)T inner join #Summary on #Summary.Machineid=T.Machineid

update #Summary set MaxDowntime=T.MaxDowntime from
(Select Machineid,Max(ISNULL(Stoppagetime,0)) as MaxDowntime from #MachinewiseStoppages
where MachineStatus='Down' group by Machineid)T inner join #Summary on #Summary.Machineid=T.Machineid

update #Summary set NoOfDownOccurences=T.NoOfDownOccurences from
(Select Machineid,count(ISNULL(Stoppagetime,0)) as NoOfDownOccurences from #MachinewiseStoppages
where MachineStatus='Down' group by Machineid)T inner join #Summary on #Summary.Machineid=T.Machineid

if @Sorttype='TotalRuntime' or ISNULL(@Sorttype,'')=''
Begin
	Insert into #MachinewiseSort(Machineid,SortOrder)
	Select Machineid,ROW_number() over(order by Runtime desc) from
	(Select Machineid,sum(ISNULL(Stoppagetime,0)) as Runtime from #MachinewiseStoppages
	where MachineStatus='Prod' group by Machineid)T
End

if @Sorttype='TotalDowntime'
Begin
	Insert into #MachinewiseSort(Machineid,SortOrder)
	Select Machineid,ROW_number() over(order by Downtime desc) from
	(Select Machineid,sum(ISNULL(Stoppagetime,0)) as Downtime from #MachinewiseStoppages
	where MachineStatus='Down' group by Machineid)T
End

if @Sorttype='MaxDowntime'
Begin

	Insert into #MachinewiseSort(Machineid,SortOrder)
	Select Machineid,ROW_number() over(order by Downtime desc) from
	(Select Machineid,Max(ISNULL(Stoppagetime,0)) as Downtime from #MachinewiseStoppages
	where MachineStatus='Down' group by Machineid)T
End

if @Sorttype='NoOfDownOccurences'
Begin
	Insert into #MachinewiseSort(Machineid,SortOrder)
	Select Machineid,ROW_number() over(order by Downtime desc) from
	(Select Machineid,Count(Stoppagetime) as Downtime 
	from #MachinewiseStoppages
	where MachineStatus='Down' group by Machineid)T
End

IF @param=''
Begin        
	select F.Machineid,F.Batchstart,F.BatchEnd,dbo.f_FormatTime(F.Stoppagetime,'hh:mm:ss') as Stoppagetime,F.MachineStatus as Reason 
	from #MachinewiseStoppages F
	inner join #MachinewiseSort M on F.Machineid=M.Machineid
	--order by Machineid,Batchstart,batchend 
	Order by M.SortOrder             
END 

IF @param='Prod'
Begin        
	select F.Machineid,F.Batchstart,F.BatchEnd,dbo.f_FormatTime(F.Stoppagetime,'hh:mm:ss') as Stoppagetime,F.MachineStatus as Reason 
	from #MachinewiseStoppages F
	inner join #MachinewiseSort M on F.Machineid=M.Machineid
	where F.MachineStatus='Prod'
	--order by Machineid,Batchstart    
	Order by M.SortOrder            
END

IF @param='Down'
Begin        
	select F.Machineid,F.Batchstart,F.BatchEnd,dbo.f_FormatTime(F.Stoppagetime,'hh:mm:ss') as Stoppagetime,F.MachineStatus as Reason  
	from #MachinewiseStoppages F
	inner join #MachinewiseSort M on F.Machineid=M.Machineid
	where F.MachineStatus='Down'
	--order by Machineid,Batchstart   
	Order by M.SortOrder            
END

IF @param='NO_DATA'
Begin        
	select F.Machineid,F.Batchstart,F.BatchEnd,dbo.f_FormatTime(F.Stoppagetime,'hh:mm:ss') as Stoppagetime,F.MachineStatus as Reason  
	from #MachinewiseStoppages F
	inner join #MachinewiseSort M on F.Machineid=M.Machineid
	where F.MachineStatus='NO_DATA'
	--order by Machineid,Batchstart  
	Order by M.SortOrder             
END

SELECT #Summary.Machineid,dbo.f_FormatTime(TotalRuntime,'hh:mm:ss') as TotalRuntime,dbo.f_FormatTime(TotalDowntime,'hh:mm:ss') as TotalDowntime,
dbo.f_FormatTime(MaxDowntime,'hh:mm:ss') as MaxDowntime,NoOfDownOccurences FROM #Summary inner join #MachinewiseSort M on #Summary.Machineid=M.Machineid
Order by M.SortOrder    

END              
              
