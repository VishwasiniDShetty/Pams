/****** Object:  Procedure [dbo].[s_GetAggDrilldownTPMTrakData_Graph]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
-- Author: Anjana C V
-- Create date: 10 Dec 2018
-- Modified date: 10 Dec 2018
-- Description:  Get Agg Drill down TPMTrak Data Graph Wheels at Machine,Plant, Component , Operator level

--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2020-08-10','','','KI/HMC-05','','','Day','AvgMcHrRate','','','','Machine'        
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-01','','','','','','YEAR','OEE','','ComponentID','','Component'        
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-01','','','','','','YEAR','OEE','','OperatorID','','Operator' 
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-01','','','','','','YEAR','downtime','','PlantID','','cell' 
        
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2020-09-01','','','','','','currentMONTH','AvgMcHrRate','AvgMcHrRate','asc','','Machine'       
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2020-09-01','','','','','','MONTH','AvgMcHrRate','','acs','','Machine'          
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-01','','','','','','MONTH','QE','','NameOftheMonth','','Operator'   
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-01','','','','','','MONTH','AcceptedParts','','NameOftheMonth','','Plant'   
    
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2020-05-05','','','ACE-01','','','DAY','AvgMcHrRate','','Day','','Machine'       
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-25','','','','','','DAY','ReworkPerformed','','Day','','Component'          
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-25','','','','','','DAY','OEE','','Day','','Operator'   
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-25','','','','','','DAY','DownTime','','Day','','Plant'         
     
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2020-05-05','','','ACE-01','','','Shift','AvgMcHrRate','','Parameter','','Machine'       
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-25','','','','','','Shift','OEE','','Parameter','','Component'  
-- [dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-25','','','','','','Shift','OEE','','Parameter','','Component'        
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-25','','','','','','Shift','OEE','','Parameter','','Operator'   
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-25','','','','','','Shift','OEE','','Parameter','','Operator'
--[dbo].[s_GetAggDrilldownTPMTrakData_Graph] '2019-01-25','','','','','','Shift','OEE','','Parameter','','Plant' 

exec [s_GetAggDrilldownTPMTrakData_Graph] @StartDate=N'2020-01-01',@ShiftName=N'',@PlantID=N'',@MachineID=N'',@Component=N'',
@Employee=N'',@ComparisonType=N'YEAR',@Parameter=N'DownTime',@SortColumn=N'DownTime',@SortOrder=N'asc',@view=N'Machine',@Groupid=N''

****************************************************************************************************/        
CREATE  PROCEDURE [dbo].[s_GetAggDrilldownTPMTrakData_Graph]        
 @StartDate As DateTime,        
 @ShiftName As NVarChar(50)='',        
 @PlantID As NVarChar(50)='',        
 @MachineID As nvarchar(50) = '',      
 @Component As nvarchar(50)='',     
 @Employee As nvarchar(50)='',       
 @ComparisonType As nvarchar(20), /*SHIFT,DAY,MONTH,YEAR*/        
 @Parameter As nvarchar(50)='', /* All KPIs,Parts Count,Down Time, AE, PE, OE ,QE,Rej Count */       
 @SortColumn nvarchar(50)='',    
 @SortOrder nvarchar(50)='',
 @Groupid as nvarchar(50)='',
 @View as nvarchar(50) = '' /* Machine,Component,operator, plant */
AS        
BEGIN        
----------------------------------------------------------------------------------------------------------        
--------* Declaration of Variables *--------        
----------------------------------------------------------------------------------------------------------        
Declare @Strsql nvarchar(4000)        
Declare @timeformat AS nvarchar(12) 
Declare @hrformat AS nvarchar(12)     
        
Declare @Strmachine nvarchar(255)        
Declare @StrPlantID AS NVarchar(255)        
Declare @StrShift AS NVarchar(255)        
 Declare @StrComponent as nvarchar(255)    
Declare @StrEmployee as nvarchar(255)    
Declare @StrGroupid as nvarchar(255)  
       
Declare @CurDate As DateTime        
Declare @StratOfMonth As DateTime        
Declare @EndOfMonth As DateTime        
Declare @AddMonth As DateTime        
Declare @EndDate As DateTime        
        
DECLARE @StrColumn as nvarchar(100)
DECLARE @StrProdColumn as nvarchar(100)
DECLARE @StrTemp as nvarchar(500) 
DECLARE @StrShiftProd as nvarchar(500)  
DECLARE @StrShiftDown as nvarchar(500)  

Select @StrColumn = ''   
select @StrProdColumn=''     
Select @StrTemp = ''        
Select @StrShiftProd = ''        
Select @StrShiftDown = ''        
        
Select @Strsql = ''        
Select @Strmachine = ''        
Select @StrPlantID=''        
Select @StrShift=''     
Select @StrComponent=''    
Select @StrEmployee=''  
Select @StrGroupid=''      


-------------------------------------------------------------------------------------------------------------        
   -- * Building Strings * --        
-------------------------------------------------------------------------------------------------------------     

IF @View = 'Plant'
BEGIN
	Select @StrColumn = 'PlantID'        
	Select @StrTemp = ' #ProdData.PlantID = T2.PlantID '        
	Select @StrShiftProd = ' T1.PlantID =  ShiftProductionDetails.PlantID '        
	Select @StrShiftDown = ' T1.PlantID = ShiftDowntimeDetails.PlantID '

END

ELSE IF @View = 'Cell'
BEGIN
	Select @StrColumn = 'Groupid'        
	Select @StrTemp = ' #ProdData.Groupid = T2.Groupid '        
	Select @StrShiftProd = ' T1.Groupid =  ShiftProductionDetails.GroupID '        
	Select @StrShiftDown = ' T1.Groupid = ShiftDowntimeDetails.GroupID '
END
   
ELSE IF @View = 'Machine'
BEGIN
	Select @StrColumn = ' MachineID,machineDescription '        
	Select @StrTemp = ' #ProdData.MachineID=T2.MachineID '        
	Select @StrShiftProd = ' T1.MachineID =  ShiftProductionDetails.Machineid '         
	Select @StrShiftDown = ' T1.machineid = ShiftDowntimeDetails.machineid '
END
   
ELSE IF @View = 'Component'
BEGIN
	Select @StrColumn = 'ComponentID'        
	Select @StrTemp = ' #ProdData.ComponentID=T2.ComponentID '        
	Select @StrShiftProd = ' T1.ComponentID =  ShiftProductionDetails.ComponentID '         
	Select @StrShiftDown = ' T1.ComponentID = ShiftDowntimeDetails.ComponentID '
END
   
ELSE IF @View = 'Operator'
BEGIN
	Select @StrColumn = 'OperatorID'        
	Select @StrTemp = ' #ProdData.OperatorID=T2.OperatorID '        
	Select @StrShiftProd = ' T1.OperatorID =  ShiftProductionDetails.OperatorID '        
	Select @StrShiftDown = ' T1.OperatorID = ShiftDowntimeDetails.OperatorID '
END

           
If isnull(@PlantID,'') <> ''        
Begin        
Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )'        
End        
        
If isnull(@Machineid,'') <> ''        
Begin        
 Select @Strmachine = ' And ( MachineInformation.MachineID = N''' + @MachineID + ''')'        
End        

 If isnull(@Groupid,'') <> ''  
Begin  
-- Select @StrGroupid = ' And ( PlantMachineGroups.GroupID = N''' + @GroupID + ''')'  
 Select @StrGroupid = ' And ( GroupID = N''' + @GroupID + ''')'  
End         
 
  If isnull(@Component,'') <> ''  
Begin  
 Select @StrComponent = ' And ( ComponentID = N''' + @Component + ''')'  
End         
    
 If isnull(@Employee,'') <> ''  
Begin  
 Select @StrEmployee = ' And ( OperatorID = N''' + @Employee + ''')'  
End         
           
SELECT @timeformat ='mm' 
SELECT @hrformat = 'hh'
    
Select @timeformat = isnull((select valueintext2 from CockpitDefaults where parameter='TPMTrakAppSettings' and ValueinText='Downtime'),'mm')    
if (@timeformat <>'hh' and @timeformat <>'mm')    
begin    
 select @timeformat = 'mm'    
end      
        
        
Create Table #ProdData        
(        
 Pdate DateTime,        
 StartDate  DateTime,        
 EndDate DateTime,        
 Shift  NVarChar(20),
 PlantID  NVarChar(50),      
 Groupid nvarchar(50),
 MachineID  NVarChar(50),
 machineDescription NVarChar(150), 
 ComponentID NVarChar(50),
 OperatorID NVarChar(50),        
 ProdCount float DEFAULT 0,        
 AcceptedParts Int DEFAULT 0,        
 RejCount  float DEFAULT 0,        
 ReworkPerformed Int DEFAULT 0,        
 MarkedForRework Int DEFAULT 0,        
 AEffy  Float DEFAULT 0,        
 PEffy  Float DEFAULT 0,        
 QEffy  Float DEFAULT 0,        
 OEffy  Float DEFAULT 0,        
 UtilisedTime  Float DEFAULT 0,        
 DownTime  Float DEFAULT 0,        
 CN  Float DEFAULT 0,        
 ManagementLoss float default 0,        
 DowntimeAE float default 0,
 PPM float default 0  ,
 McHrRate float default 0,
 AvgMcHrRate float default 0
)        
        
        
CREATE TABLE #PlantMcCompOpr         
(        
PlantID  NVarChar(50),      
Groupid  NVarChar(50),      
MachineID  NVarChar(50),
machineDescription NVarChar(50), 
ComponentID NVarChar(50),
OperatorID NVarChar(50)         
)        
        
        
CREATE TABLE #TimePeriodDetails        
 (        
PDate datetime,        
Shift nvarchar(20),        
DStart datetime,        
DEnd datetime        
--CONSTRAINT ShiftAgg_ComparisonReports2_key PRIMARY KEY (PDate,DStart,DEnd)        
)        
        
IF @ComparisonType='Month'        
BEGIN        
   Select @StartDate = cast(datepart(yyyy,@StartDate) as nvarchar(4))+ '-01' + '-01'        
   select @EndDate = dateadd(Month,11,@StartDate)        
      
  SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')        
  SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@EndDate,'End')        
  While @StratOfMonth<=@EndOfMonth        
  BEGIN        
   INSERT INTO #TimePeriodDetails ( DStart, DEnd )        
   SELECT @StratOfMonth,dbo.f_GetPhysicalMonth(@StratOfMonth,'End')        
        
   SELECT @StratOfMonth=DateAdd(mm,1,@StratOfMonth)          
           
  END        
END        
     
IF @ComparisonType='CurrentMonth'        
BEGIN          
    
  SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')        
  SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@EndDate,'End')        
       
   INSERT INTO #TimePeriodDetails ( DStart, DEnd )        
   SELECT @StratOfMonth,dbo.f_GetPhysicalMonth(@StratOfMonth,'End')        
     
END    
       
If @ComparisonType='SHIFT' --or @ComparisonType='OEE_Month'        
BEGIN        
    
  Select @StartDate = cast(datepart(yyyy,@StartDate) as nvarchar(4))+ '-01' + '-01'        
  select @EndDate = dateadd(Month,11,@StartDate)        
      
  SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')        
  SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@EndDate,'End')        
    
 WHILE @StratOfMonth<=@EndOfMonth    
 BEGIN    
  INSERT #TimePeriodDetails(Pdate, Shift, DStart, DEnd)        
  EXEC s_GetShiftTime @StratOfMonth,@ShiftName        
  SELECT  @StratOfMonth = DATEADD(DAY,1,@StratOfMonth)    
END    
     
END        
    
If @ComparisonType='CurrentSHIFT' --or @ComparisonType='OEE_Month'        
BEGIN        
    
  INSERT #TimePeriodDetails(Pdate, Shift, DStart, DEnd)        
  EXEC s_GetShiftTime @StartDate,@ShiftName        
     
END     
    
    
        
IF @ComparisonType='DAY'        
BEGIN        
        
   Select @StartDate = cast(datepart(yyyy,@StartDate) as nvarchar(4))+ '-01' + '-01'        
   select @EndDate = dateadd(Month,11,@StartDate)       
      
  SELECT @CurDate=dbo.f_GetPhysicalMonth(@StartDate,'Start')            
  SELECT @EndDate = dbo.f_GetPhysicalMonth(@EndDate,'END')        
       
 While @CurDate<=@EndDate        
 BEGIN        
  INSERT INTO #TimePeriodDetails ( pDate )        
  SELECT @CurDate        
          
  SELECT @CurDate=DateAdd(dd,1,@CurDate)        
 END        
END        
    
 IF @ComparisonType='CurrentDAY'        
BEGIN        
           SELECT @CurDate=@StartDate        
  INSERT INTO #TimePeriodDetails ( pDate )        
  SELECT @CurDate        
            
END      
 
       
Select @Strsql =''        
Select @Strsql ='Insert Into #PlantMcCompOpr('+ @StrColumn +')' 
       
IF @View = 'Plant'
BEGIN
	Select @Strsql =@Strsql+' Select  Distinct PlantMachine.PlantID From MachineInformation'        
	Select @Strsql =@Strsql+' Left Outer Join PlantMachine ON MachineInformation.MachineID=PlantMachine.MachineID' 
	Select @Strsql =@Strsql+' Left Outer Join PlantMachineGroups ON MachineInformation.MachineID=PlantMachineGroups.MachineID'          
	Select @Strsql =@Strsql+' Where MachineInformation.MachineID Is Not NULL'        
	Select @Strsql =@Strsql+@StrPlantID+@Strmachine+@StrGroupid      
	print @Strsql        
	Exec (@Strsql)   
END
ELSE IF @View = 'Cell'
BEGIN
	Select @Strsql =@Strsql+' Select  Distinct PlantMachineGroups.Groupid From PlantMachineGroups 
	inner join MachineInformation on MachineInformation.machineid=PlantMachineGroups.machineid'        
	Select @Strsql =@Strsql+' inner Join PlantMachine ON PlantMachineGroups.MachineID=PlantMachine.MachineID and PlantMachineGroups.Plantid=PlantMachine.Plantid '      
	Select @Strsql =@Strsql+' Where MachineInformation.MachineID Is Not NULL'        
	Select @Strsql =@Strsql+@StrPlantID+@Strmachine+@StrGroupid      
	print @Strsql        
	Exec (@Strsql)   
END
ELSE IF  @View =  'Machine'
BEGIN
	Select @Strsql =@Strsql+' Select  Distinct MachineInformation.MachineID,MachineInformation.Description From MachineInformation'        
	Select @Strsql =@Strsql+' Left Outer Join PlantMachine ON MachineInformation.MachineID=PlantMachine.MachineID' 
	Select @Strsql =@Strsql+' Left Outer Join PlantMachineGroups ON MachineInformation.MachineID=PlantMachineGroups.MachineID'          
	Select @Strsql =@Strsql+' Where MachineInformation.MachineID Is Not NULL'        
	Select @Strsql =@Strsql+@StrPlantID+@Strmachine+@StrGroupid 
	Select @Strsql =@Strsql+' Order By MachineInformation.MachineID'        
	print @Strsql        
	Exec (@Strsql)        
END
ELSE IF  @View =  'Component'
BEGIN
 Select @Strsql =@Strsql+' (Select ComponentID From ShiftProductionDetails
  where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')' 
 Select @Strsql = @Strsql+@StrComponent+@StrGroupid  +' )' 
 Select @Strsql = @Strsql+ 'UNION 
 (Select ComponentID from ShiftDownTimeDetails
  where datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'
   Select @Strsql = @Strsql+@StrComponent+@StrGroupid  +' )'  
 print @Strsql        
 Exec (@Strsql)        
END

ELSE IF  @View =  'Operator'
BEGIN  
 Select @Strsql =@Strsql+ ' (Select OperatorID From ShiftProductionDetails
 where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')' 
 Select @Strsql = @Strsql+@StrEmployee+@StrGroupid  +' )' 
 Select @Strsql =@Strsql+' UNION 
 (Select OperatorID from ShiftDownTimeDetails
 where datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')' 
 Select @Strsql = @Strsql+@StrEmployee+@StrGroupid  +')' 
 print @Strsql        
 Exec (@Strsql) 
END       

     
declare @ColumnToShow as nvarchar(50),@order as nvarchar(50)    
select @order = ''+@SortColumn+'' + ' ' + ''+@Sortorder+''     
        
If @ComparisonType='Year'        
BEGIN  
      
 Select @Strsql =  ''
 Select @Strsql = 'Insert Into #ProdData( '+@StrColumn+')        
 Select ' + @StrColumn +' From #PlantMcCompOpr '       
 
 print @Strsql        
 Exec (@Strsql)  

 If isnull(@PlantID,'') <> ''        
 Begin        
  Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'        
 End        
         
 If isnull(@Machineid,'') <> ''        
 Begin        
  Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = N''' + @MachineID + ''')'        
 End        
         
 If isnull(@Component,'') <> ''    
 Begin    
 Select @StrComponent = ' And (ShiftProductionDetails.Componentid = N''' + @Component + ''')'    
 End    
    
 If isnull(@Employee,'') <> ''    
 Begin    
 Select @StrEmployee = ' And (ShiftProductionDetails.Operatorid = N''' + @Employee + ''')'    
 End      
     
  If isnull(@ShiftName,'') <> ''        
 Begin        
 Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @ShiftName + ''')'        
 End      
 
If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID = N''' + @GroupID + ''')'  
End 

IF @View = 'Machine'
BEGIN
	Select @StrColumn = ' MachineID '  
END  

          
 Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'        
 Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'        
 Select @Strsql = @Strsql+ ' From('        
 Select @Strsql = @Strsql+ ' Select T1.'+@StrColumn+',Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,         
        Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) AS MarkedForRework,
		Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime        
                             From ShiftProductionDetails inner Join #ProdData T1 on  '+@StrShiftProd       
 Select @Strsql = @Strsql+ ' where Datepart(YEAR,ShiftProductionDetails.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee  + @StrGroupid       
 Select @Strsql = @Strsql+ ' GROUP By T1.'+@StrColumn        
 Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON '+@StrTemp         
 Print @Strsql        
 Exec(@Strsql)         
        
 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'        
 Select @Strsql = @Strsql+' FROM('        
 Select @Strsql = @Strsql+' Select T1.'+@StrColumn+',Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'        
 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on '+@StrShiftProd+'        
          Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'        
 Select @Strsql = @Strsql+' Where datepart(YEAR,ShiftProductionDetails.Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
 Select @Strsql = @Strsql+' Group By T1.'+@StrColumn      
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON '+@StrTemp    
 Print @Strsql        
 Exec(@Strsql)        
        
        
 Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'        
 Select @Strsql = @Strsql + ' From ('        
 Select @Strsql = @Strsql + ' Select T1.'+@StrColumn+',sum(ShiftProductionDetails.Prod_Qty *(ShiftProductionDetails.CO_StdMachiningTime+ShiftProductionDetails.CO_StdLoadUnload)) AS CN '        
 Select @Strsql = @Strsql + ' From ShiftProductionDetails inner Join #ProdData T1 '        
 Select @Strsql = @Strsql + ' on '+@StrShiftProd+' where         
 datepart(YEAR,ShiftProductionDetails.Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
 Select @Strsql = @Strsql + ' Group By T1.'+@StrColumn       
 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON '+@StrTemp       
 Print @Strsql        
 Exec(@Strsql)        
     
 Select @Strsql = 'Update #ProdData Set McHrRate=ISNULL(T2.McHrRate,0)'        
 Select @Strsql = @Strsql + ' From ('        
 Select @Strsql = @Strsql + ' Select T1.'+@StrColumn+',Sum((isnull(ShiftProductionDetails.AcceptedParts,0)) * (isnull(ShiftProductionDetails.Price,0)))as McHrRate '        
 Select @Strsql = @Strsql + ' From ShiftProductionDetails inner Join #ProdData T1 '        
 Select @Strsql = @Strsql + ' on '+@StrShiftProd+' where datepart(YEAR,ShiftProductionDetails.Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
 Select @Strsql = @Strsql + ' Group By T1.'+@StrColumn       
 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON '+@StrTemp       
 Print @Strsql        
 Exec(@Strsql)

 
 If isnull(@PlantID,'') <> ''        
 Begin        
  Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'        
 End        
         
 If isnull(@Machineid,'') <> ''        
 Begin        
  Select @Strmachine = ' And ( ShiftDownTimeDetails.MachineID = N''' + @MachineID + ''')'        
 End        
         
 If isnull(@Component,'') <> ''    
 Begin    
 Select @StrComponent = ' And (ShiftDownTimeDetails.Componentid = N''' + @Component + ''')'    
 End    
    
 If isnull(@Employee,'') <> ''    
 Begin    
 Select @StrEmployee = ' And (ShiftDownTimeDetails.Operatorid = N''' + @Employee + ''')'    
 End      
      
  If isnull(@ShiftName,'') <> ''        
 Begin        
 Select @StrShift = ' And ( ShiftDownTimeDetails.Shift = N''' + @ShiftName + ''')'        
 End      
   
If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID = N''' + @GroupID + ''')'  
End 

     
 Select @Strsql =''        
 SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '        
 Select @Strsql = @Strsql+ 'From (SELECT '+@StrColumn+',sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '        
 Select @Strsql = @Strsql+ 'WHERE datepart(YEAR,ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')
                            and downid in (select downid from downcodeinformation where prodeffy = 1) '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee  + @StrGroupid       
 Select @Strsql = @Strsql+ ' Group By '+@StrColumn        
 Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON '+@StrTemp           
 print @StrSql        
 EXEC(@StrSql)       

        
 Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'        
 Select @Strsql = @Strsql + ' From (select T1.'+@StrColumn+',(Sum(ShiftDowntimeDetails.DownTime))As DownTime'        
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join #ProdData T1 on '+ @StrShiftDown +'      
 where datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee  + @StrGroupid       
 Select @Strsql = @Strsql + ' Group By T1.'+@StrColumn       
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON '+@StrTemp         
 Print @Strsql        
 Exec(@Strsql)         
        
         
 Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'        
 Select @Strsql = @Strsql + 'from (select T1.'+@StrColumn+', sum(        
   CASE         
  WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0          
  THEN isnull(ShiftDownTimeDetails.Threshold,0)        
  ELSE ShiftDownTimeDetails.DownTime        
   END) AS LOSS '        
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner JOIN #ProdData T1 on '+ @StrShiftDown +' where ML_flag = 1        
 and datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'          
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
 Select @Strsql = @Strsql + ' Group By T1.'+@StrColumn+''        
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON  '+@StrTemp              
 Print @Strsql        
 Exec(@Strsql)         
         
---mod 1 introduced with mod2 to neglect threshold ML from dtime        
 UPDATE #ProdData SET DownTime=DownTime-ManagementLoss            
        
        
 UPDATE #ProdData SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)        
 Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0        
        
 UPDATE #ProdData        
 SET        
  PEffy = (CN/UtilisedTime) ,        
  AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))        
 WHERE UtilisedTime <> 0        
 UPDATE #ProdData        
 SET        
  --Round(OEffy,2)        
  OEffy = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE'
						THEN (AEffy*100)
					WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE*PE'
						THEN (AEffy * ISNULL(PEffy,1))*100
					ELSE  (PEffy * AEffy * ISNULL(QEffy,1))*100
				END,        
  PEffy = PEffy * 100 ,        
  AEffy = AEffy * 100,        
  QEffy = QEffy * 100        

update #ProdData set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0
      
update #ProdData set AvgMcHrRate=McHrRate/Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float)
where Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float) <> 0


IF @View = 'Machine'
BEGIN
	Select @StrColumn = ' MachineID,machineDescription '  
END    
 
 Update #ProdData set DownTime= CAST(dbo.f_FormatTime((ISNULL(DownTime,0)+ISNULL(ManagementLoss,0)),''+@timeformat+'') as float)


 select @Strsql=''    
 select @strsql=@strsql + ' select '+@StrColumn+',Case When '''+@Parameter+'''=''OEE'' then round(OEffy,2)     
 When '''+@Parameter+'''=''AE'' then round(AEffy,2)         
 When '''+@Parameter+'''=''PE'' then round(PEffy,2)          
 When '''+@Parameter+'''=''QE'' then round(QEffy,2)         
 When '''+@Parameter+'''=''AcceptedParts'' then AcceptedParts        
 When '''+@Parameter+'''=''RejCount'' then RejCount        
 When '''+@Parameter+'''=''ReworkPerformed'' then ReworkPerformed        
 --When '''+@Parameter+'''=''DownTime'' then Round(dbo.f_FormatTime((ISNULL(DownTime,0)+ISNULL(ManagementLoss,0)),'''+@timeformat+'''),2)   
 When '''+@Parameter+'''=''DownTime'' then Round(DownTime,2)   
 When '''+@Parameter+'''=''PPM'' then round(PPM,2)     
 When '''+@Parameter+'''=''AvgMcHrRate'' then round(AvgMcHrRate,2)
 END as Parameter From #ProdData     
 order by '+@order+' '    
 print(@strsql)    
 exec(@strsql)    
       
END        
         
        
If @ComparisonType='Month' or @ComparisonType='CurrentMonth'       
BEGIN        
        
 select @Strsql=''    
 select @strsql=@strsql + 'Insert Into #ProdData('+@StrColumn+',Pdate,StartDate,EndDate,Shift)        
 Select '+@StrColumn+',Pdate,DStart,DEnd ,Shift From #TimePeriodDetails CROSS Join #PlantMcCompOpr'       
 
 print @Strsql        
 Exec (@Strsql)   
    
 If isnull(@PlantID,'') <> ''        
 Begin        
  Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'        
 End        
         
 If isnull(@Machineid,'') <> ''        
 Begin        
  Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = N''' + @MachineID + ''')'        
 End        
         
 If isnull(@Component,'') <> ''    
 Begin    
 Select @StrComponent = ' And (ShiftProductionDetails.Componentid = N''' + @Component + ''')'    
 End    
    
 If isnull(@Employee,'') <> ''    
 Begin    
 Select @StrEmployee = ' And (ShiftProductionDetails.Operatorid = N''' + @Employee + ''')'    
 End    
     
  If isnull(@ShiftName,'') <> ''        
 Begin        
 Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @ShiftName + ''')'        
 End         
  
If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID = N''' + @GroupID + ''')'  
End 

IF @View = 'Machine'
BEGIN
	Select @StrColumn = ' MachineID '  
END 

         
  Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'        
  Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'        
  Select @Strsql = @Strsql+ ' From('        
  Select @Strsql = @Strsql+ ' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,ShiftProductionDetails.'+@StrColumn+',Sum(ISNULL(Prod_Qty,0))ProdCount,Sum(ISNULL(AcceptedParts,0))AcceptedParts,        
         Sum(ISNULL(Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(Marked_For_Rework,0)) AS MarkedForRework,Sum(Sum_of_ActCycleTime)As UtilisedTime        
                              From ShiftProductionDetails CROSS Join (Select StartDate ,EndDate,'+@StrColumn+'  From #ProdData ) as T1 '        
  Select @Strsql = @Strsql+ ' Where '+@StrShiftProd+' And pDate>=T1.StartDate And pDate<= T1.EndDate'        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
  Select @Strsql = @Strsql+ ' GROUP By T1.StartDate,T1.EndDate,ShiftProductionDetails.'+@StrColumn      
  Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And '+@StrTemp        
  Print @Strsql        
  Exec(@Strsql)        
        
/*================================================================================================================*/     
        
  Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'        
  Select @Strsql = @Strsql+' FROM('        
  Select @Strsql = @Strsql+' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,ShiftProductionDetails.'+@StrColumn+',Sum(isnull(Rejection_Qty,0))Rej'        
  Select @Strsql = @Strsql+' From ShiftProductionDetails CROSS Join (Select StartDate ,EndDate,'+@StrColumn+'  From #ProdData )T1        
        Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'        
  Select @Strsql = @Strsql+' Where '+@StrShiftProd+' and pDate>=T1.StartDate And pDate<= T1.EndDate'        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
  Select @Strsql = @Strsql+' Group By T1.StartDate,T1.EndDate,ShiftProductionDetails.'+@StrColumn  
  Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And '+@StrTemp        
  Print @Strsql        
  Exec(@Strsql)        
          
        
      
  Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'        
  Select @Strsql = @Strsql + ' From ('        
  Select @Strsql = @Strsql + ' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,ShiftProductionDetails.'+@StrColumn+',sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '        
  Select @Strsql = @Strsql + ' From ShiftProductionDetails CROSS Join (Select StartDate ,EndDate,'+@StrColumn+' From #ProdData )T1 '        
  Select @Strsql = @Strsql + ' Where '+@StrShiftProd+' and pDate>=T1.StartDate And pDate<= T1.EndDate '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
  Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate,ShiftProductionDetails.'+@StrColumn         
  Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And '+@StrTemp    
  Print @Strsql        
  Exec(@Strsql)        
       
	
	  Select @Strsql = 'Update #ProdData Set McHrRate=ISNULL(T2.McHrRate,0)'        
  Select @Strsql = @Strsql + ' From ('        
  Select @Strsql = @Strsql + ' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,ShiftProductionDetails.'+@StrColumn+',Sum(isnull(ShiftProductionDetails.AcceptedParts,0) * isnull(ShiftProductionDetails.Price,0))as McHrRate'        
  Select @Strsql = @Strsql + ' From ShiftProductionDetails CROSS Join (Select StartDate ,EndDate,'+@StrColumn+' From #ProdData )T1 '        
  Select @Strsql = @Strsql + ' Where '+@StrShiftProd+' and pDate>=T1.StartDate And pDate<= T1.EndDate '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
  Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate,ShiftProductionDetails.'+@StrColumn         
  Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And '+@StrTemp    
  Print @Strsql        
  Exec(@Strsql) 


 If isnull(@PlantID,'') <> ''        
 Begin        
  Select @StrPlantID = ' And ( ShiftDowntimeDetails.PlantID = N''' + @PlantID + ''' )'        
 End        
         
 If isnull(@Machineid,'') <> ''        
 Begin        
  Select @Strmachine = ' And ( ShiftDowntimeDetails.MachineID = N''' + @MachineID + ''')'        
 End        
         
 If isnull(@Component,'') <> ''    
 Begin    
 Select @StrComponent = ' And (ShiftDowntimeDetails.Componentid = N''' + @Component + ''')'    
 End    
    
 If isnull(@Employee,'') <> ''    
 Begin    
 Select @StrEmployee = ' And (ShiftDowntimeDetails.Operatorid = N''' + @Employee + ''')'    
 End      
          
    If isnull(@ShiftName,'') <> ''        
 Begin        
 Select @StrShift = ' And ( ShiftDownTimeDetails.Shift = N''' + @ShiftName + ''')'        
 End      
     
If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID = N''' + @GroupID + ''')'  
End 

     
  Select @Strsql =''        
  SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '        
  Select @Strsql = @Strsql+ 'From (SELECT '+@StrColumn+',datepart(mm,ddate)as dmonth,datepart(yyyy,ddate)as dyear,sum(datediff(s,starttime,endtime)) as MinorDownTime 
  FROM ShiftDownTimeDetails '        
  Select @Strsql = @Strsql+ 'WHERE downid in (select downid from downcodeinformation where prodeffy = 1) 
  Group By '+@StrColumn+',datepart(mm,ddate),datepart(yyyy,ddate)'        
  Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON '+@StrTemp+' and T2.dmonth=datepart(mm,#ProdData.Startdate) 
  and T2.dyear=datepart(yyyy,#ProdData.EndDate)'        
  print @StrSql        
  EXEC(@StrSql)       

  Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'        
  Select @Strsql = @Strsql + ' From (select T1.StartDate As StartDate ,T1.EndDate As EndDate,ShiftDownTimeDetails.'+@StrColumn+',(Sum(DownTime))As DownTime'        
  Select @Strsql = @Strsql + ' From ShiftDownTimeDetails CROSS Join (Select StartDate ,EndDate,'+@StrColumn+'  From #ProdData )T1        
          where '+@StrShiftDown+' and dDate>=T1.StartDate And dDate<= T1.EndDate'        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid       
  Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate, ShiftDownTimeDetails.'+@StrColumn        
  Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And '+@StrTemp       
  Print @Strsql        
  Exec(@Strsql)         
        
  Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'        
  Select @Strsql = @Strsql + 'from (select T1.startdate as startdate, T1.Enddate as Enddate, ShiftDownTimeDetails.'+@StrColumn+', sum(        
    CASE         
   WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0          
   THEN isnull(ShiftDownTimeDetails.Threshold,0)        
   ELSE ShiftDownTimeDetails.DownTime        
    END) AS LOSS '        
   Select @Strsql = @Strsql + ' From ShiftDownTimeDetails CROSS JOIN (Select StartDate ,EndDate,'+@StrColumn+'  From #ProdData )T1        
                                         where '+@StrShiftDown+' and dDate>=T1.StartDate And dDate<= T1.EndDate And ML_flag = 1'        
          
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
  Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate,ShiftDownTimeDetails.'+@StrColumn       
  Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And '+@StrTemp        
  Print @Strsql        
  Exec(@Strsql)         
         
        
 ---mod 1 introduced with mod2 to neglect threshold ML from dtime        
  UPDATE #ProdData SET DownTime=DownTime-ManagementLoss    ---ER0335 Added        
        
        
  UPDATE #ProdData SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)        
  Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0        
  UPDATE #ProdData        
  SET        
   PEffy = (CN/UtilisedTime) ,        
   AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))        
  WHERE UtilisedTime <> 0        
  UPDATE #ProdData        
  SET        
   OEffy = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE'
						THEN (AEffy*100)
					WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE*PE'
						THEN (AEffy * ISNULL(PEffy,1))*100
					ELSE  (PEffy * AEffy * ISNULL(QEffy,1))*100
				END,        
   PEffy = PEffy * 100 ,        
   AEffy = AEffy * 100,        
   QEffy = QEffy * 100        

 update #ProdData set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0


update #ProdData set AvgMcHrRate=McHrRate/Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float)
where Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float) <> 0


  /*      
 select MachineID,Startdate,Enddate,Substring(Datename(Month,Startdate),1,3) as NameOftheMonth,Case When @Parameter='OEE' then round(OEffy,2)        
 When @Parameter='AE' then round(AEffy,2)         
 When @Parameter='PE' then round(PEffy,2)          
 When @Parameter='QE' then round(QEffy,2)         
 When @Parameter='AcceptedParts' then AcceptedParts        
 When @Parameter='RejCount' then RejCount        
 When @Parameter='ReworkPerformed' then ReworkPerformed        
 When @Parameter='DownTime' then Round(dbo.f_FormatTime(DownTime,@timeformat),2) END as Parameter From #ProdData order by MachineID,startdate        
 */     

IF @View = 'Machine'
BEGIN
	Select @StrColumn = ' MachineID,machineDescription '  
END 

Update #ProdData set DownTime= CAST(dbo.f_FormatTime((ISNULL(DownTime,0)+ISNULL(ManagementLoss,0)),''+@timeformat+'') as float)

	IF @ComparisonType='CurrentMonth'      
	BEGIN

	
	 select @Strsql=''    
	 select @strsql=@strsql + ' select '+@StrColumn+',Startdate,Enddate,Substring(Datename(Month,Startdate),1,3) as NameOftheMonth,Case When '''+@Parameter+'''=''OEE'' then round(OEffy,2)     
	 When '''+@Parameter+'''=''AE'' then round(AEffy,2)         
	 When '''+@Parameter+'''=''PE'' then round(PEffy,2)          
	 When '''+@Parameter+'''=''QE'' then round(QEffy,2)         
	 When '''+@Parameter+'''=''AcceptedParts'' then AcceptedParts        
	 When '''+@Parameter+'''=''RejCount'' then RejCount        
	 When '''+@Parameter+'''=''ReworkPerformed'' then ReworkPerformed        
	 --When '''+@Parameter+'''=''DownTime'' then Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),'''+@timeformat+'''),2) 
	 When '''+@Parameter+'''=''DownTime'' then Round(DownTime,2)
	 When '''+@Parameter+'''=''PPM'' then round(PPM,2) 
	  When '''+@Parameter+'''=''AvgMcHrRate'' then round(AvgMcHrRate,2)
	 END as Parameter From #ProdData     
	 order by '+@order+' '    
	 print(@strsql)    
	 exec(@strsql)    
	 
	END
	IF @ComparisonType='Month'      
	BEGIN

	 select @Strsql=''    
	 select @strsql=@strsql + ' select '+@StrColumn+',Startdate,Enddate,Substring(Datename(Month,Startdate),1,3) as NameOftheMonth,Case When '''+@Parameter+'''=''OEE'' then round(OEffy,2)     
	 When '''+@Parameter+'''=''AE'' then round(AEffy,2)         
	 When '''+@Parameter+'''=''PE'' then round(PEffy,2)          
	 When '''+@Parameter+'''=''QE'' then round(QEffy,2)         
	 When '''+@Parameter+'''=''AcceptedParts'' then AcceptedParts        
	 When '''+@Parameter+'''=''RejCount'' then RejCount        
	 When '''+@Parameter+'''=''ReworkPerformed'' then ReworkPerformed        
	 --When '''+@Parameter+'''=''DownTime'' then Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),'''+@timeformat+'''),2) 
	 When '''+@Parameter+'''=''DownTime'' then Round(DownTime,2)
	 When '''+@Parameter+'''=''PPM'' then round(PPM,2)  
	  When '''+@Parameter+'''=''AvgMcHrRate'' then round(AvgMcHrRate,2)
	 END as Parameter From #ProdData     
	 order by '+@StrColumn+',startdate,'+@order+' '    
	 print(@strsql)    
	 exec(@strsql)    
	 
	END
        
         
END        
        
        
If @ComparisonType='Day'  or @ComparisonType='CurrentDAY'      
BEGIN        
        
  select @Strsql=''    
 select @strsql=@strsql + 'Insert Into #ProdData('+@StrColumn+',Pdate,StartDate,EndDate,Shift)        
 Select '+@StrColumn+',Pdate,DStart,DEnd ,Shift From #TimePeriodDetails CROSS Join #PlantMcCompOpr'        
 Print @Strsql        
 Exec (@Strsql)   
    
 If isnull(@PlantID,'') <> ''        
 Begin        
  Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'        
 End        
         
 If isnull(@Machineid,'') <> ''        
 Begin        
  Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = N''' + @MachineID + ''')'        
 End        
         
 If isnull(@Component,'') <> ''    
 Begin    
 Select @StrComponent = ' And (ShiftProductionDetails.Componentid = N''' + @Component + ''')'    
 End    
    
 If isnull(@Employee,'') <> ''    
 Begin    
 Select @StrEmployee = ' And (ShiftProductionDetails.Operatorid = N''' + @Employee + ''')'    
 End     
     
  If isnull(@ShiftName,'') <> ''        
 Begin        
 Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @ShiftName + ''')'        
 End          
   
If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID = N''' + @GroupID + ''')'  
End 

IF @View = 'Machine'
BEGIN
	Select @StrColumn = ' MachineID '  
END 

  Select @Strsql =''        
  Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'        
  Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=isnull(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'        
  Select @Strsql = @Strsql+ ' From('        
  Select @Strsql = @Strsql+ ' Select pDate,ShiftProductionDetails.'+@StrColumn+',Sum(ISNULL(Prod_Qty,0))ProdCount,Sum(ISNULL(AcceptedParts,0))AcceptedParts,        
         Sum(ISNULL(Rework_Performed,0))AS Rework_Performed,Sum(Isnull(Marked_For_Rework,0))AS MarkedForRework,Sum(Sum_of_ActCycleTime)As UtilisedTime        
                              From ShiftProductionDetails Inner Join (Select pDate As tDate ,'+@StrColumn+'  From #ProdData )T1 
							  ON ShiftProductionDetails.pDate=T1.tDate And '+@StrShiftProd        
  --Select @Strsql = @Strsql+ ' Where ShiftProductionDetails.'+@StrColumn+' IS NOT NULL And pDate=T1.tDate '     
  Select @Strsql = @Strsql+ ' Where  pDate=T1.tDate '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
  Select @Strsql = @Strsql+ ' GROUP By pDate,ShiftProductionDetails.'+@StrColumn       
  Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And '+@StrTemp       
  Print @Strsql        
  Exec(@Strsql)        
        
       
  Select @Strsql =''        
  Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'        
  Select @Strsql = @Strsql+' FROM('        
  Select @Strsql = @Strsql+' Select pDate,ShiftProductionDetails.'+@StrColumn+',Sum(isnull(Rejection_Qty,0))Rej'        
  Select @Strsql = @Strsql+' From ShiftProductionDetails Inner Join (Select pDate As tDate ,'+@StrColumn+' From #ProdData )T1 
  ON ShiftProductionDetails.pDate=T1.tDate And '+@StrShiftProd+'       
        Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'        
  Select @Strsql = @Strsql+' Where pDate=T1.tDate'        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
  Select @Strsql = @Strsql+' Group By pDate,ShiftProductionDetails.'+@StrColumn       
  Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.pDate And '+@StrTemp         
  Print @Strsql        
  Exec(@Strsql)        
        
  Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'        
  Select @Strsql = @Strsql + ' From ('        
  Select @Strsql = @Strsql + ' Select pDate,ShiftProductionDetails.'+@StrColumn+',sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '        
  Select @Strsql = @Strsql + ' From ShiftProductionDetails Inner Join (Select pDate As tDate ,'+@StrColumn+'  From #ProdData )T1 
  ON ShiftProductionDetails.pDate=T1.tDate And '+@StrShiftProd        
  Select @Strsql = @Strsql + ' Where pDate=T1.tDate '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
  Select @Strsql = @Strsql + ' Group By pDate,ShiftProductionDetails.'+@StrColumn       
  Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.pDate And '+@StrTemp       
  Print @Strsql        
  Exec(@Strsql)        
          
  Select @Strsql = 'Update #ProdData Set McHrRate=ISNULL(T2.McHrRate,0)'        
  Select @Strsql = @Strsql + ' From ('        
  Select @Strsql = @Strsql + ' Select pDate,ShiftProductionDetails.'+@StrColumn+',Sum(isnull(ShiftProductionDetails.AcceptedParts,0) * isnull(ShiftProductionDetails.Price,0))as McHrRate '        
  Select @Strsql = @Strsql + ' From ShiftProductionDetails Inner Join (Select pDate As tDate ,'+@StrColumn+'  From #ProdData )T1 
  ON ShiftProductionDetails.pDate=T1.tDate And '+@StrShiftProd        
  Select @Strsql = @Strsql + ' Where pDate=T1.tDate '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
  Select @Strsql = @Strsql + ' Group By pDate,ShiftProductionDetails.'+@StrColumn       
  Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.pDate And '+@StrTemp       
  Print @Strsql        
  Exec(@Strsql) 


 If isnull(@PlantID,'') <> ''        
 Begin        
  Select @StrPlantID = ' And ( ShiftDowntimeDetails.PlantID = N''' + @PlantID + ''' )'        
 End        
         
 If isnull(@Machineid,'') <> ''        
 Begin        
  Select @Strmachine = ' And ( ShiftDowntimeDetails.MachineID = N''' + @MachineID + ''')'        
 End        
         
 If isnull(@Component,'') <> ''    
 Begin    
 Select @StrComponent = ' And (ShiftDowntimeDetails.Componentid = N''' + @Component + ''')'    
 End    
    
 If isnull(@Employee,'') <> ''    
 Begin    
 Select @StrEmployee = ' And (ShiftDowntimeDetails.Operatorid = N''' + @Employee + ''')'    
 End      
            
 If isnull(@ShiftName,'') <> ''        
 Begin        
 Select @StrShift = ' And ( ShiftDowntimeDetails.Shift = N''' + @ShiftName + ''')'        
 End         
   
If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID = N''' + @GroupID + ''')'  
End 

      
  Select @Strsql =''        
  SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)        
  From (select ddate,'+@StrColumn+',sum(datediff(s,starttime,endtime)) as MinorDownTime from shiftdowntimedetails         
  where downid in (select downid from downcodeinformation where prodeffy = 1)'         
  SELECT @StrSql=@StrSql+' group by '+@StrColumn+',ddate) as T2 Inner Join #ProdData ON '+@StrTemp+' and T2.ddate=#ProdData.pdate'        
  print @StrSql        
  EXEC(@StrSql)        
    
        
  Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'        
  Select @Strsql = @Strsql + ' From (select dDate,ShiftDownTimeDetails.'+@StrColumn+',(Sum(DownTime))As DownTime'        
  Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join (Select pDate As tDate ,'+@StrColumn+' From #ProdData )T1
   ON ShiftDownTimeDetails.dDate=T1.tDate And '+@StrShiftDown        
  Select @Strsql = @Strsql + ' where dDate=T1.tDate '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
  Select @Strsql = @Strsql + ' Group By dDate,ShiftDownTimeDetails.'+@StrColumn+''        
  Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.dDate And '+@StrTemp        
  Print @Strsql        
  Exec(@Strsql)         
         
  Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(t2.loss,0)'        
  Select @Strsql = @Strsql + 'from (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.'+@StrColumn+',sum(        
    CASE         
   WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0          
   THEN isnull(ShiftDownTimeDetails.Threshold,0)        
   ELSE ShiftDownTimeDetails.DownTime        
    END) AS LOSS '        
   Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join (Select pDate As tDate ,'+@StrColumn+' From #ProdData )T1 
   ON ShiftDownTimeDetails.dDate=T1.tDate And '+@StrShiftDown       
    Select @Strsql = @Strsql + ' where dDate=T1.tDate  And ML_Flag=1'        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee  + @StrGroupid       
  Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.'+@StrColumn        
  Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.dDate And '+@StrTemp          
  Print @Strsql        
  Exec(@Strsql)         
         
 ---mod 1 introduced with mod2 to neglect threshold ML from dtime        
  UPDATE #ProdData SET DownTime=DownTime-ManagementLoss            
        
        
  UPDATE #ProdData SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)        
  Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0        
        
 UPDATE #ProdData        
  SET        
   PEffy = (CN/UtilisedTime) ,        
   AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))        
  WHERE UtilisedTime <> 0        
  UPDATE #ProdData        
  SET             
   OEffy = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE'
						THEN (AEffy*100)
					WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE*PE'
						THEN (AEffy * ISNULL(PEffy,1))*100
					ELSE  (PEffy * AEffy * ISNULL(QEffy,1))*100
				END,        
   PEffy = PEffy * 100 ,        
   AEffy = AEffy * 100,        
   QEffy = QEffy * 100        
 
  update #ProdData set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

update #ProdData set AvgMcHrRate=McHrRate/Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float)
where Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float) <> 0


IF @View = 'Machine'
BEGIN
	Select @StrColumn = ' MachineID,machineDescription '  
END 

Update #ProdData set DownTime= CAST(dbo.f_FormatTime((ISNULL(DownTime,0)+ISNULL(ManagementLoss,0)),''+@timeformat+'') as float)

	IF @ComparisonType='CurrentDAY'  
	BEGIN 
	 
	 select @Strsql=''    
	 select @strsql=@strsql + ' select '+@StrColumn+',PDate,Case When '''+@Parameter+'''=''OEE'' then round(OEffy,2)     
	 When '''+@Parameter+'''=''AE'' then round(AEffy,2)         
	 When '''+@Parameter+'''=''PE'' then round(PEffy,2)          
	 When '''+@Parameter+'''=''QE'' then round(QEffy,2)         
	 When '''+@Parameter+'''=''AcceptedParts'' then AcceptedParts        
	 When '''+@Parameter+'''=''RejCount'' then RejCount        
	 When '''+@Parameter+'''=''ReworkPerformed'' then ReworkPerformed        
	 --When '''+@Parameter+'''=''DownTime'' then Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),'''+@timeformat+'''),2)    
	 When '''+@Parameter+'''=''DownTime'' then Round(DownTime,2)
	 When '''+@Parameter+'''=''PPM'' then round(PPM,2)  
	 When '''+@Parameter+'''=''AvgMcHrRate'' then round(AvgMcHrRate,2)
	 END as Parameter,RIGHT(''0'' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month] ,    
	 RIGHT(''0'' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day] From #ProdData     
	 order by '+@order+' '    
	 print(@strsql)    
	 exec(@strsql)    
	END

	IF @ComparisonType='DAY'  
	BEGIN 
	 
	 select @Strsql=''    
	 select @strsql=@strsql + ' select '+@StrColumn+',PDate,Case When '''+@Parameter+'''=''OEE'' then round(OEffy,2)     
	 When '''+@Parameter+'''=''AE'' then round(AEffy,2)         
	 When '''+@Parameter+'''=''PE'' then round(PEffy,2)          
	 When '''+@Parameter+'''=''QE'' then round(QEffy,2)         
	 When '''+@Parameter+'''=''AcceptedParts'' then AcceptedParts        
	 When '''+@Parameter+'''=''RejCount'' then RejCount        
	 When '''+@Parameter+'''=''ReworkPerformed'' then ReworkPerformed        
	 --When '''+@Parameter+'''=''DownTime'' then Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),'''+@timeformat+'''),2)    
	 When '''+@Parameter+'''=''DownTime'' then Round(DownTime,2)
	 When '''+@Parameter+'''=''PPM'' then round(PPM,2) 
	 When '''+@Parameter+'''=''AvgMcHrRate'' then round(AvgMcHrRate,2)
	 END as Parameter,RIGHT(''0'' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month] ,    
	 RIGHT(''0'' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day] From #ProdData     
	 order by '+@StrColumn+',PDate,'+@order+' '    
	 print(@strsql)    
	 exec(@strsql)    
	END

         
END        
        
If @ComparisonType='SHIFT' or  @ComparisonType='CurrentShift'        
BEGIN        
         
        
  select @Strsql=''    
 select @strsql=@strsql + ' Insert Into #ProdData('+@StrColumn+',Pdate,StartDate,EndDate,Shift)        
 Select '+@StrColumn+',Pdate,DStart,DEnd ,Shift From #TimePeriodDetails CROSS Join #PlantMcCompOpr '       
 
 Print @Strsql       
 Exec (@Strsql)
        
If isnull(@PlantID,'') <> ''        
Begin        
 Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'        
End        
        
If isnull(@Machineid,'') <> ''        
Begin        
 Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = N''' + @MachineID + ''')'        
End        
        
If isnull(@Component,'') <> ''    
Begin    
Select @StrComponent = ' And (ShiftProductionDetails.Componentid = N''' + @Component + ''')'    
End    
    
If isnull(@Employee,'') <> ''    
Begin    
Select @StrEmployee = ' And (ShiftProductionDetails.Operatorid = N''' + @Employee + ''')'    
End     
    
If isnull(@ShiftName,'') <> ''        
Begin        
Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @ShiftName + ''')'        
End      
 
If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID = N''' + @GroupID + ''')'  
End 

IF @View = 'Machine'
BEGIN
	Select @StrColumn = ' MachineID '  
END 

 Select @CurDate = CAST(datePart(yyyy,@StartDate) AS nvarchar(4)) + '-' + SUBSTRING(DATENAME(MONTH,@StartDate),1,3) + '-' + CAST(datePart(dd,@StartDate) AS nvarchar(2))        
         
 Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'        
 Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'        
 Select @Strsql = @Strsql+ ' From('        
 Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.'+@StrColumn+',
	 Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,      
	 Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) as MarkedForRework,
	 Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime        
	 From ShiftProductionDetails inner join #Proddata T1 on '+@StrShiftProd+' and ShiftProductionDetails.pDate=T1.Pdate 
	 and ShiftProductionDetails.Shift=T1.Shift'        
 --Select @Strsql = @Strsql+ ' Where ShiftProductionDetails.'+@StrColumn+' IS NOT NULL '      
 Select @Strsql = @Strsql+ '  Where 1=1 '
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
 Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.'+@StrColumn        
 Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift And '+@StrTemp       
 Print @Strsql        
 Exec(@Strsql)        
        
      
        
        
 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'        
 Select @Strsql = @Strsql+' FROM('        
 Select @Strsql = @Strsql+' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.'+@StrColumn+',Sum(isnull(Rejection_Qty,0))Rej'        
 Select @Strsql = @Strsql+' From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID    
                            inner join #Proddata T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift and
							'+@StrShiftProd      
 Select @Strsql = @Strsql+' Where ShiftProductionDetails.pDate=T1.Pdate '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
 Select @Strsql = @Strsql+' Group By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.'+@StrColumn+''        
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.pDate And '+@StrTemp+' And #ProdData.Shift=T2.Shift'        
 Print @Strsql        
 Exec(@Strsql)        
        
 Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'        
 Select @Strsql = @Strsql + ' From ('        
 Select @Strsql = @Strsql + ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.'+@StrColumn+',
								sum(ShiftProductionDetails.Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '        
 Select @Strsql = @Strsql + ' From ShiftProductionDetails     
inner join #Proddata T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift and '+@StrShiftProd        
 Select @Strsql = @Strsql + ' Where ShiftProductionDetails.pDate=T1.Pdate '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
 Select @Strsql = @Strsql + ' Group By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.'+@StrColumn      
 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.pDate And '+@StrTemp+' And #ProdData.Shift=T2.Shift'        
 Print @Strsql        
 Exec(@Strsql) 
 
 Select @Strsql = 'Update #ProdData Set McHrRate=ISNULL(T2.McHrRate,0)'        
 Select @Strsql = @Strsql + ' From ('        
 Select @Strsql = @Strsql + ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.'+@StrColumn+',
								Sum(isnull(ShiftProductionDetails.AcceptedParts,0) * isnull(ShiftProductionDetails.Price,0))as McHrRate'        
 Select @Strsql = @Strsql + ' From ShiftProductionDetails     
inner join #Proddata T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift and '+@StrShiftProd        
 Select @Strsql = @Strsql + ' Where ShiftProductionDetails.pDate=T1.Pdate '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
 Select @Strsql = @Strsql + ' Group By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.'+@StrColumn      
 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.pDate And '+@StrTemp+' And #ProdData.Shift=T2.Shift'        
 Print @Strsql        
 Exec(@Strsql) 


         
If isnull(@PlantID,'') <> ''        
Begin        
 Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'        
End        
        
If isnull(@Machineid,'') <> ''        
Begin        
 Select @Strmachine = ' And ( ShiftDownTimeDetails.MachineID = N''' + @MachineID + ''')'        
End        
        
If isnull(@Component,'') <> ''    
Begin    
Select @StrComponent = ' And (ShiftDownTimeDetails.Componentid = N''' + @Component + ''')'    
End    
    
If isnull(@Employee,'') <> ''    
Begin    
Select @StrEmployee = ' And (ShiftDownTimeDetails.Operatorid = N''' + @Employee + ''')'    
End      
    
 If isnull(@ShiftName,'') <> ''        
 Begin        
  Select @StrShift = ' And ( ShiftDownTimeDetails.Shift = N''' + @ShiftName + ''')'        
 End        
  
If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID = N''' + @GroupID + ''')'  
End 
     

 Select @Strsql =''        
 SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '        
 SELECT @StrSql=@StrSql+'From (SELECT ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.'+@StrColumn+',
						sum(datediff(s,starttime,endtime)) as MinorDownTime '        
 SELECT @StrSql=@StrSql+'FROM ShiftDownTimeDetails Inner Join #ProdData T1 ON '+@StrShiftDown+' and ShiftDownTimeDetails.ddate=T1.pdate
							 and ShiftDownTimeDetails.shift=T1.Shift    
  WHERE downid in (select downid from downcodeinformation where prodeffy = 1) '     
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid           
 SELECT @StrSql=@StrSql+'Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.'+@StrColumn+') as T2 
 Inner Join #ProdData ON '+@StrTemp+' and T2.ddate=#ProdData.pdate and T2.shift=#ProdData.Shift'        
 print @StrSql
 EXEC(@StrSql)      
    
    
        
 Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'        
 Select @Strsql = @Strsql + ' From (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.'+@StrColumn+',
 ( Sum(ShiftDownTimeDetails.DownTime) )As DownTime'        
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails     
 Inner Join #ProdData T1 ON '+@StrShiftDown+' and ShiftDownTimeDetails.ddate=T1.pdate and ShiftDownTimeDetails.shift=T1.Shift    
 where dDate=T1.Pdate '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
 Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.'+@StrColumn       
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.dDate And '+@StrTemp+' And #ProdData.Shift=T2.Shift'        
 Print @Strsql        
 Exec(@Strsql)         
        
 Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(t2.loss,0)'        
 Select @Strsql = @Strsql + 'from (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.'+@StrColumn+',sum(        
   CASE         
  WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0          
  THEN isnull(ShiftDownTimeDetails.Threshold,0)        
  ELSE ShiftDownTimeDetails.DownTime        
   END) AS LOSS '        
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails       
Inner Join #ProdData T1 ON '+@StrShiftDown+' and ShiftDownTimeDetails.ddate=T1.pdate and ShiftDownTimeDetails.shift=T1.Shift    
where dDate=T1.Pdate And ML_Flag=1 '        
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid        
 Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.'+@StrColumn       
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.dDate And '+@StrTemp+' And #ProdData.Shift=T2.Shift'        
 Print @Strsql        
 Exec(@Strsql)         
        
 UPDATE #ProdData SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)        
 Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0        
         
         
 UPDATE #ProdData        
 SET        
  PEffy = (CN/UtilisedTime) ,        
  AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0)-ManagementLoss)        
 WHERE UtilisedTime <> 0        
        
 UPDATE #ProdData        
 SET        
  OEffy = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE'
						THEN (AEffy*100)
					WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE*PE'
						THEN (AEffy * ISNULL(PEffy,1))*100
					ELSE  (PEffy * AEffy * ISNULL(QEffy,1))*100
				END,      
  PEffy = PEffy * 100 ,        
  AEffy = AEffy * 100,        
  QEffy = QEffy * 100        
           
UPDATE #ProdData SET DownTime=DownTime-ManagementLoss        

UPDATE #ProdData set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

update #ProdData set AvgMcHrRate=McHrRate/Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float)
where Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float) <> 0


IF @View = 'Machine'
BEGIN
	Select @StrColumn = ' MachineID,machineDescription '  
END 

  Update #ProdData set DownTime= CAST(dbo.f_FormatTime((ISNULL(DownTime,0)+ISNULL(ManagementLoss,0)),''+@timeformat+'') as float)
  
IF @ComparisonType='CurrentShift'
BEGIN   
 select @Strsql=''    
 select @strsql=@strsql + ' select '+@StrColumn+',PDate,Shift,Case When '''+@Parameter+'''=''OEE'' then round(OEffy,2)     
 When '''+@Parameter+'''=''AE'' then round(AEffy,2)         
 When '''+@Parameter+'''=''PE'' then round(PEffy,2)          
 When '''+@Parameter+'''=''QE'' then round(QEffy,2)         
 When '''+@Parameter+'''=''AcceptedParts'' then AcceptedParts        
 When '''+@Parameter+'''=''RejCount'' then RejCount        
 When '''+@Parameter+'''=''ReworkPerformed'' then ReworkPerformed        
 --When '''+@Parameter+'''=''DownTime'' then Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),'''+@timeformat+'''),2) 
 When '''+@Parameter+'''=''DownTime'' then Round(DownTime,2)
 When '''+@Parameter+'''=''PPM'' then round(PPM,2)  
 When '''+@Parameter+'''=''AvgMcHrRate'' then round(AvgMcHrRate,2)
 END as Parameter,RIGHT(''0'' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month] ,    
 RIGHT(''0'' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day] From #ProdData     
 order by '+@order+' '    
 print(@strsql)    
 exec(@strsql)    
END

IF @ComparisonType='Shift'
BEGIN   
 select @Strsql=''    
 select @strsql=@strsql + ' select '+@StrColumn+',PDate,Shift,Case When '''+@Parameter+'''=''OEE'' then round(OEffy,2)     
 When '''+@Parameter+'''=''AE'' then round(AEffy,2)         
 When '''+@Parameter+'''=''PE'' then round(PEffy,2)          
 When '''+@Parameter+'''=''QE'' then round(QEffy,2)         
 When '''+@Parameter+'''=''AcceptedParts'' then AcceptedParts        
 When '''+@Parameter+'''=''RejCount'' then RejCount        
 When '''+@Parameter+'''=''ReworkPerformed'' then ReworkPerformed        
 --When '''+@Parameter+'''=''DownTime'' then Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),'''+@timeformat+'''),2)      
 When '''+@Parameter+'''=''DownTime'' then Round(DownTime,2)
 When '''+@Parameter+'''=''PPM'' then round(PPM,2)    
 When '''+@Parameter+'''=''AvgMcHrRate'' then round(AvgMcHrRate,2)
 END as Parameter,RIGHT(''0'' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month] ,    
 RIGHT(''0'' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day] From #ProdData     
 order by '+@StrColumn+',PDate,Shift,'+@order+' '    
 print(@strsql)    
 exec(@strsql)    
END
      
END        
        
         
END 
