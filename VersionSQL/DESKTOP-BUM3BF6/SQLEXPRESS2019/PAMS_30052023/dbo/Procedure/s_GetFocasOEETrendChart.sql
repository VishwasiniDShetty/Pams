/****** Object:  Procedure [dbo].[s_GetFocasOEETrendChart]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetFocasOEETrendChart]  '2019-09-01','','','','Year'
--[dbo].[s_GetFocasOEETrendChart]  '2019-08-01','','','','Month'
--[dbo].[s_GetFocasOEETrendChart]  '2020-07-22','','','AMIT','Shift&day'
--[dbo].[s_GetFocasOEETrendChart]  '2019-08-10','','','','CurrentShift&day'

CREATE procedure [dbo].[s_GetFocasOEETrendChart]          
@StartDate As DateTime,  
@ShiftName As NVarChar(50)='',  
@PlantID As NVarChar(50)='',  
@MachineID As nvarchar(50) = '',    
@ComparisonType As nvarchar(50)=''        
WITH RECOMPILE        
AS          
BEGIN          
         
SET NOCOUNT ON;        
         
Create Table #FinalOutput         
(      
 [Plantid] nvarchar(50),    
 [Machineid] nvarchar(50),             
 [Startdate] datetime,
 [Enddate] datetime,  
 [PDate] datetime,     
 [Shift] nvarchar(50),         
 [CN] float,          
 [OEE] float,
 [OperatingTime] float,
 Shiftid int,
 DStart datetime
)          
        
CREATE TABLE #ShiftDetails                 
(                
 SlNo bigint identity(1,1) NOT NULL,              
 PDate datetime,                
 Shift nvarchar(20),                
 ShiftStart datetime,                
 ShiftEnd datetime            
)   

CREATE TABLE #TimePeriodDetails        
 (        
PDate datetime,        
Shift nvarchar(20),        
DStart datetime,        
DEnd datetime,
Shiftid int       
)   
          
Declare @strsql nvarchar(4000)          
Declare @strmachine nvarchar(2000)          
Declare @StrPlantid as nvarchar(1000)          

Declare @StratOfMonth As DateTime        
Declare @EndOfMonth As DateTime        
Declare @AddMonth As DateTime        
Declare @EndDate As DateTime        

Select @strsql = ''          
Select @strmachine = ''          
select @strPlantID = ''          
          
if isnull(@machineid,'') <> ''          
Begin          
 Select @strMachine = ' AND ( Machineinformation.MachineID = N''' +  @machineid + ''') '          
End          
          
if isnull(@PlantID,'') <> ''          
Begin          
 Select @strPlantID = ' AND ( PlantMachine.PlantID = N''' + @PlantID + ''')'          
End          

IF @ComparisonType='Year'        
BEGIN        
   Select @StartDate = cast(datepart(yyyy,@StartDate) as nvarchar(4))+ '-01' + '-01'        
   select @EndDate = dateadd(Month,11,@StartDate)        
      
  SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')        
  SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@EndDate,'End')     
     
  While @StratOfMonth<=@EndOfMonth        
  BEGIN        
	INSERT INTO #TimePeriodDetails ( DStart, DEnd )        
	SELECT @StratOfMonth,dbo.f_GetPhysicalMonth(@StratOfMonth,'End')        
        
	SELECT @StratOfMonth=DateAdd(MM,1,@StratOfMonth)          
  END        
END    


IF @ComparisonType='Month'        
BEGIN        
	--Select @StartDate = cast(datepart(yyyy,@StartDate) as nvarchar(4))+ '-01' + '-01'            
      
	SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')           
     
	INSERT INTO #TimePeriodDetails ( DStart, DEnd )        
	SELECT @StratOfMonth,dbo.f_GetPhysicalMonth(@StratOfMonth,'End')     
END  


If @ComparisonType='Shift&Day'     
BEGIN        

	SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')        
	SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@StratOfMonth,'End')        
    
	WHILE @StratOfMonth<=@EndOfMonth    
	BEGIN    
		INSERT #TimePeriodDetails(Pdate, Shift, DStart, DEnd)        
		EXEC s_GetShiftTime @StratOfMonth,@ShiftName        
		SELECT  @StratOfMonth = DATEADD(DD,1,@StratOfMonth)    
	END   
	
	SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')        
	SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@StratOfMonth,'End')           
       
	While @StratOfMonth<=@EndOfMonth        
	BEGIN        
		INSERT INTO #TimePeriodDetails (Pdate, Shift,Shiftid)        
		SELECT @StratOfMonth ,'Day' ,4              
		SELECT @StratOfMonth=DateAdd(day,1,@StratOfMonth)        
	END        
	
	Update #TimePeriodDetails Set Shiftid = isnull(#TimePeriodDetails.Shiftid,0) + isnull(T1.shiftid,0) from    
	(Select SD.shiftid ,SD.shiftname from shiftdetails SD    
	inner join #TimePeriodDetails S on SD.shiftname=S.shift where    
	running=1 )T1 inner join #TimePeriodDetails on  T1.shiftname=#TimePeriodDetails.shift 
	 
END  

If @ComparisonType='CurrentShift&Day'     
BEGIN        

	INSERT #TimePeriodDetails(Pdate, Shift, DStart, DEnd)        
	EXEC s_GetShiftTime @startdate,@ShiftName        

	INSERT INTO #TimePeriodDetails (Pdate, Shift,Shiftid)        
	SELECT top 1 Pdate ,'Day' ,4  from   #TimePeriodDetails         

	Update #TimePeriodDetails Set Shiftid = isnull(#TimePeriodDetails.Shiftid,0) + isnull(T1.shiftid,0) from    
	(Select SD.shiftid ,SD.shiftname from shiftdetails SD    
	inner join #TimePeriodDetails S on SD.shiftname=S.shift where    
	running=1 )T1 inner join #TimePeriodDetails on  T1.shiftname=#TimePeriodDetails.shift 
	 
END  

IF @ComparisonType='Year' or @ComparisonType='Month'         
BEGIN  

	insert into #FinalOutput(Plantid,Machineid,Startdate,Enddate,CN,OperatingTime,OEE)
	select P.PlantID,M.Machineid,T.DStart,T.DEnd,0,0,0 from machineinformation M
	inner join PlantMachine P on M.machineid=P.MachineID
	cross join #TimePeriodDetails T
	where (M.machineid=@MachineID or ISNULL(@MachineID,'')='') and (P.PlantID=@PlantID or ISNULL(@PlantID,'')='')

	update #FinalOutput set CN=T.PCount from
	(Select F.Machineid,F.Startdate,F.Enddate,SUM(H.Partcount*H.Cycletime)as Pcount from FocasWeb_HourwiseCycles H
	inner join #FinalOutput F on F.Machineid=H.Machineid and datepart(YEAR,F.Startdate)=datepart(YEAR,H.date) and datepart(mm,F.Startdate)=datepart(mm,H.date)
	group by F.Machineid,F.Startdate,F.Enddate
	)T inner join #FinalOutput on #FinalOutput.Machineid=T.Machineid and #FinalOutput.Startdate=T.Startdate

	 
	--update #FinalOutput set OperatingTime=T.OperatingTime from
	--(Select F.Machineid,F.Startdate,F.Enddate,SUM(H.OperatingTime)as OperatingTime from FocasWeb_HourwiseTimeInfo H
	--inner join #FinalOutput F on F.Machineid=H.Machineid and datepart(YEAR,F.Startdate)=datepart(YEAR,H.date) and datepart(mm,F.Startdate)=datepart(mm,H.date)
	--group by F.Machineid,F.Startdate,F.Enddate
	--)T inner join #FinalOutput on #FinalOutput.Machineid=T.Machineid and #FinalOutput.Startdate=T.Startdate

	update #FinalOutput set OperatingTime=T.OperatingTime from
	(Select F.Machineid,F.Startdate,F.Enddate,SUM(H.OperatingTime)as OperatingTime from FocasWeb_ShiftwiseSummary H
	inner join #FinalOutput F on F.Machineid=H.Machineid and datepart(YEAR,F.Startdate)=datepart(YEAR,H.date) and datepart(mm,F.Startdate)=datepart(mm,H.date)
	group by F.Machineid,F.Startdate,F.Enddate
	)T inner join #FinalOutput on #FinalOutput.Machineid=T.Machineid and #FinalOutput.Startdate=T.Startdate

	Update #FinalOutput set OEE=ROUND((CN/OperatingTime)*100,2) where OperatingTime>0

	    
	select Plantid,Machineid,datename(Month,Startdate) as NameofMonth,OEE from #FinalOutput 
	order by Machineid,Startdate

END


IF @ComparisonType='Shift&Day' OR @ComparisonType='CurrentShift&Day'
BEGIN  

	update #TimePeriodDetails set DStart= T.Dstart from
	(select Pdate,min(Dstart) as Dstart,Shift from #TimePeriodDetails where Shift<>'Day' group by Pdate,Shift)T
	inner join #TimePeriodDetails on #TimePeriodDetails.PDate=T.PDate and #TimePeriodDetails.Shift=T.Shift

	insert into #FinalOutput(Plantid,Machineid,PDate,Shift,CN,OperatingTime,OEE,Shiftid,DStart)
	select P.PlantID,M.Machineid,T.Pdate,T.shift,0,0,0,T.Shiftid,T.DStart from machineinformation M
	inner join PlantMachine P on M.machineid=P.MachineID
	cross join #TimePeriodDetails T
	where (M.machineid=@MachineID or ISNULL(@MachineID,'')='') and (P.PlantID=@PlantID or ISNULL(@PlantID,'')='')

	update #FinalOutput set CN=T.PCount from
	(Select F.Machineid,F.PDate,F.shift,SUM(H.Partcount*H.Cycletime)as Pcount from FocasWeb_HourwiseCycles H
	inner join #FinalOutput F on F.Machineid=H.Machineid and convert(nvarchar(10),F.PDate,120)=convert(nvarchar(10),H.date,120) and H.Shift=F.Shift
	where F.Shift<>'Day'
	group by F.Machineid,F.PDate,F.shift
	)T inner join #FinalOutput on #FinalOutput.Machineid=T.Machineid and convert(nvarchar(10),#FinalOutput.PDate,120)=convert(nvarchar(10),T.PDate,120)
	and #FinalOutput.Shift=T.Shift

	--update #FinalOutput set OperatingTime=T.OperatingTime from
	--(Select F.Machineid,F.PDate,F.shift,SUM(H.OperatingTime)as OperatingTime from FocasWeb_HourwiseTimeInfo H
	--inner join #FinalOutput F on F.Machineid=H.Machineid and convert(nvarchar(10),F.PDate,120)=convert(nvarchar(10),H.date,120) and H.Shift=F.Shift
	--where F.Shift<>'Day'
	--group by F.Machineid,F.PDate,F.shift
	--)T inner join #FinalOutput on #FinalOutput.Machineid=T.Machineid and convert(nvarchar(10),#FinalOutput.PDate,120)=convert(nvarchar(10),T.PDate,120)
	--and #FinalOutput.Shift=T.Shift
	
	update #FinalOutput set OperatingTime=T.OperatingTime from
	(Select F.Machineid,F.PDate,F.shift,SUM(H.OperatingTime)as OperatingTime from FocasWeb_ShiftwiseSummary H
	inner join #FinalOutput F on F.Machineid=H.Machineid and convert(nvarchar(10),F.PDate,120)=convert(nvarchar(10),H.date,120) and H.Shift=F.Shift
	where F.Shift<>'Day'
	group by F.Machineid,F.PDate,F.shift
	)T inner join #FinalOutput on #FinalOutput.Machineid=T.Machineid and convert(nvarchar(10),#FinalOutput.PDate,120)=convert(nvarchar(10),T.PDate,120)
	and #FinalOutput.Shift=T.Shift

	update #FinalOutput set CN=T.PCount from
	(Select F.Machineid,F.PDate,SUM(H.Partcount*H.Cycletime)as Pcount from FocasWeb_HourwiseCycles H
	inner join #FinalOutput F on F.Machineid=H.Machineid and convert(nvarchar(10),F.PDate,120)=convert(nvarchar(10),H.date,120) 
	where F.Shift='Day'
	group by F.Machineid,F.PDate
	)T inner join #FinalOutput on #FinalOutput.Machineid=T.Machineid and convert(nvarchar(10),#FinalOutput.PDate,120)=convert(nvarchar(10),T.PDate,120)
	where #FinalOutput.Shift='Day'

	--update #FinalOutput set OperatingTime=T.OperatingTime from
	--(Select F.Machineid,F.PDate,SUM(H.OperatingTime)as OperatingTime from FocasWeb_HourwiseTimeInfo H
	--inner join #FinalOutput F on F.Machineid=H.Machineid and convert(nvarchar(10),F.PDate,120)=convert(nvarchar(10),H.date,120) 
	--where F.Shift='Day'
	--group by F.Machineid,F.PDate
	--)T inner join #FinalOutput on #FinalOutput.Machineid=T.Machineid and convert(nvarchar(10),#FinalOutput.PDate,120)=convert(nvarchar(10),T.PDate,120)
	--where #FinalOutput.Shift='Day'

	update #FinalOutput set OperatingTime=T.OperatingTime from
	(Select F.Machineid,F.PDate,SUM(H.OperatingTime)as OperatingTime from FocasWeb_ShiftwiseSummary H
	inner join #FinalOutput F on F.Machineid=H.Machineid and convert(nvarchar(10),F.PDate,120)=convert(nvarchar(10),H.date,120) 
	where F.Shift='Day'
	group by F.Machineid,F.PDate
	)T inner join #FinalOutput on #FinalOutput.Machineid=T.Machineid and convert(nvarchar(10),#FinalOutput.PDate,120)=convert(nvarchar(10),T.PDate,120)
	where #FinalOutput.Shift='Day'

	Update #FinalOutput set OEE=ROUND((CN/OperatingTime)*100,2) where OperatingTime>0
	    
	select Plantid,Machineid,case when shift<>'Day' then Dstart else convert(nvarchar(10),Pdate,120) end as StartDate,Shift,OEE from #FinalOutput 
	--where (Shift=@ShiftName or isnull(@ShiftName,'')='')
	order by Machineid,PDate,shiftid

END


End          
           
