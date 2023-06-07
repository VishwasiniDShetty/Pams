/****** Object:  Procedure [dbo].[s_GetFocasCycleDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetFocasCycleDetails]  '2017-09-09 06:00:00','1','','ACE-01',''
CREATE procedure [dbo].[s_GetFocasCycleDetails]          
 @Date datetime,     
 @Shiftname nvarchar(50)='',                     
 @PlantID nvarchar(50)='',          
 @Machineid nvarchar(1000)='',          
 @Param nvarchar(20)=''        
        
WITH RECOMPILE        
AS          
BEGIN          
         
        
 SET NOCOUNT ON;        
         
Create Table #CycleDetails          
(          
 [Machineid] nvarchar(50),          
 [ProgramNo] nvarchar(50),       
 [CNCTimestamp] datetime,          
 [ActualCycleTime] float,          
 [IdealCycleTime] float
)          
        
CREATE TABLE #ShiftDetails                 
(                
 SlNo bigint identity(1,1) NOT NULL,              
 PDate datetime,                
 Shift nvarchar(20),                
 ShiftStart datetime,                
 ShiftEnd datetime                
)   
          
Declare @strsql nvarchar(4000)          
Declare @strmachine nvarchar(2000)          
Declare @StrPlantid as nvarchar(1000)          

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

Declare @Starttime as datetime
declare @Endtime as Datetime

INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)                 
EXEC s_GetShiftTime @Date,@Shiftname 

Select @Starttime=Min(ShiftStart) From #ShiftDetails
select @Endtime = Max(ShiftEnd) From #ShiftDetails  

Select @Strsql=''
Select @Strsql = @Strsql + 'Insert into #CycleDetails([Machineid],[ProgramNo],[CNCTimestamp],[ActualCycleTime],[IdealCycleTime])
Select FC.[Machineid],FC.[ProgramNo],FC.[CNCTimestamp],FC.CycleTime,Case when FT.Target>0 then (3600/FT.Target) Else ISNULL(FT.Target,0) END from Focas_CycleDetails FC
inner join Machineinformation on Machineinformation.Machineid=FC.Machineid
inner join PlantMachine on PlantMachine.Machineid=FC.Machineid 
Left Outer join Focas_ProgramwiseTarget FT on  FC.[Machineid]=FT.[Machineid] and FC.[ProgramNo]=FT.[ProgramNo]'
Select @Strsql = @Strsql + ' where FC.[CNCTimestamp]>= ''' + Convert(nvarchar(20),@Starttime,120) +''' and FC.[CNCTimestamp]<=''' + Convert(nvarchar(20),@Endtime,120) +''' '
Select @Strsql = @Strsql + @strMachine +  @strPlantID
Print @Strsql
Exec(@Strsql)

Select ROW_NUMBER() OVER(Order By [CNCTimestamp]) as IDD,[Machineid],[ProgramNo],[CNCTimestamp],[ActualCycleTime],[IdealCycleTime] From #CycleDetails Order by [CNCTimestamp]
     
End          
           
