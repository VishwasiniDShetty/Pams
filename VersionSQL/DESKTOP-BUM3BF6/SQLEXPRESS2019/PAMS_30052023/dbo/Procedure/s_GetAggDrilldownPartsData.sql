/****** Object:  Procedure [dbo].[s_GetAggDrilldownPartsData]    Committed by VersionSQL https://www.versionsql.com ******/

 
 
/*
exec [dbo].[s_GetAggDrilldownPartsData] '2019-01-01','','','dtc 400xl-3','','','year','machinewise'  /* combine machines   */
exec [dbo].[s_GetAggDrilldownPartsData] '2019-01-01','','','','','','year','operatorwise' /* combine operators  */  
exec [dbo].[s_GetAggDrilldownPartsData] '2019-01-01','','','','','','year','componentwise'/* combine components */   
exec [dbo].[s_GetAggDrilldownPartsData] '2016-01-01','','','','','','year','plantwise'
exec [dbo].[s_GetAggDrilldownPartsData] '2016-01-01','','','','1ST  DRIVEN 36T','KARMAVEER','year'    
exec [dbo].[s_GetAggDrilldownPartsData] '2016-01-01','','','','','KARMAVEER','year'    
exec [dbo].[s_GetAggDrilldownPartsData] '2016-01-01','','','','','','year'    
exec [dbo].[s_GetAggDrilldownPartsData] '2016-01-01','','','','','','plantsyear'    
exec [dbo].[s_GetAggDrilldownPartsData] '2016-01-01','','','LBR HOBBING-A','1ST  DRIVEN 36T','','month'    
exec [dbo].[s_GetAggDrilldownPartsData] '2017-01-01','','','CNC Grinding','50 SHANK','','month'          
exec [dbo].[s_GetAggDrilldownPartsData] '2019-01-01','','','J300-1','','','year','Machinewise'  
exec [dbo].[s_GetAggDrilldownPartsData] '2019-01-01','','','','A02-L02 - I','','year'
exec [dbo].[s_GetAggDrilldownPartsData] '2019-01-01','','','','','','year','Cellwise'    

*/     
CREATE PROCEDURE [dbo].[s_GetAggDrilldownPartsData]      
 @StartDate As DateTime,      
 @ShiftName As NVarChar(50)='',      
 @PlantID As NVarChar(50)='',      
 @MachineID As nvarchar(50),      
 @Component As nvarchar(50)='', 
 @Employee As nvarchar(50)='',             
 @ComparisonType As nvarchar(50)='', -- year,month,day
 @View AS nvarchar(50)='Machinewise', -- Machinewise, Operatorwise, Componentwise
 @Groupid as nvarchar(50)='' 
AS      
BEGIN      

----------------------------------------------------------------------------------------------------------      
--* Declaration of Variables *--      
----------------------------------------------------------------------------------------------------------      
Declare @Strsql nvarchar(4000)      
Declare @timeformat AS nvarchar(12)      
      
Declare @Strmachine nvarchar(255)      
Declare @StrPlantID AS NVarchar(255)      
Declare @StrShift AS NVarchar(255)      
Declare @StrComponent as nvarchar(255)
Declare @StrEmployee as nvarchar(255)   
Declare @StrGroupid as nvarchar(255)    

    
Select @Strsql = ''      
Select @Strmachine = ''      
Select @StrPlantID=''      
Select @StrShift=''      
Select @StrComponent=''
Select @StrEmployee=''
Select @StrGroupid=''   
        
If isnull(@PlantID,'') <> ''      
Begin      
 Select @StrPlantID = ' And (S.PlantID = N''' + @PlantID + ''' )'      
End      
      
If isnull(@Machineid,'') <> ''      
Begin      
 Select @Strmachine = ' And (S.MachineID = N''' + @MachineID + ''')'      
End      
If isnull(@ShiftName,'') <> ''
Begin
Select @StrShift = ' And (S.Shift = N''' + @ShiftName + ''')'
End

If isnull(@Component,'') <> ''
Begin
Select @StrComponent = ' And (S.Componentid = N''' + @Component + ''')'
End

If isnull(@Employee,'') <> ''
Begin
Select @StrEmployee = ' And (S.OperatorID = N''' + @Employee + ''')'
End      

 If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( S.GroupID = N''' + @GroupID + ''')'  
End 
 
create table #Proddata
(
Machineid nvarchar(50),
ComponentID nvarchar(50),
Operationno nvarchar(50),
OperatorID nvarchar(50),
AcceptedParts float,
AvgCycletime float,
Month nvarchar(10),
Day nvarchar(10),
MachineDescription NVarChar(150)  
)

create table #Plantsdata
(
Plantid nvarchar(50),
ComponentID nvarchar(50),
Operationno nvarchar(50),
AcceptedParts float,
AvgCycletime nvarchar(50),
Month nvarchar(10),
Day nvarchar(10)
)

If @View='Plantwise'
BEGIN
 IF @ComparisonType='Year'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,AcceptedParts,AvgCycletime) '      
 Select @Strsql = @Strsql + 'Select S.PlantID, S.ComponentID,S.Operationno,Sum(ISNULL(S.AcceptedParts,0)) AcceptedParts,Sum(S.Sum_of_ActCycleTime) As ActCycleTime      
 From ShiftProductionDetails S where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')'
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.PlantID,S.ComponentID,S.Operationno Order by S.PlantID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)      
 END

 IF @ComparisonType='Month'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,AcceptedParts,AvgCycletime) '      
 Select @Strsql = @Strsql + 'Select S.PlantID, S.ComponentID,S.Operationno,Sum(ISNULL(S.AcceptedParts,0)) AcceptedParts,Sum(S.Sum_of_ActCycleTime) As ActCycleTime      
 From ShiftProductionDetails S where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
 and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.PlantID,S.ComponentID,S.Operationno Order by S.PlantID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)      
 END

 IF @ComparisonType='Day'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,AcceptedParts,AvgCycletime) '      
 Select @Strsql = @Strsql + 'Select S.PlantID, S.ComponentID,S.Operationno,Sum(ISNULL(S.AcceptedParts,0)) AcceptedParts,Sum(S.Sum_of_ActCycleTime) As ActCycleTime      
 From ShiftProductionDetails S where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.PlantID,S.ComponentID,S.Operationno Order by S.PlantID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)      
 END

 update #Plantsdata set AvgCycletime = AvgCycletime/AcceptedParts where AcceptedParts>0

 Select Plantid,ComponentID,Operationno,AcceptedParts,dbo.f_FormatTime(AvgCycletime,'hh:mm:ss') as AvgCycletime from #Plantsdata
 order by PlantID,ComponentID,Operationno
END

ELSE If @View='Cellwise'
BEGIN
 IF @ComparisonType='Year'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,AcceptedParts,AvgCycletime) '      
 Select @Strsql = @Strsql + 'Select S.GroupID, S.ComponentID,S.Operationno,Sum(ISNULL(S.AcceptedParts,0)) AcceptedParts,Sum(S.Sum_of_ActCycleTime) As ActCycleTime      
 From ShiftProductionDetails S where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')'
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.GroupID,S.ComponentID,S.Operationno Order by S.GroupID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)      
 END

 IF @ComparisonType='Month'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,AcceptedParts,AvgCycletime) '      
 Select @Strsql = @Strsql + 'Select S.GroupID, S.ComponentID,S.Operationno,Sum(ISNULL(S.AcceptedParts,0)) AcceptedParts,Sum(S.Sum_of_ActCycleTime) As ActCycleTime      
 From ShiftProductionDetails S where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
 and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.GroupID,S.ComponentID,S.Operationno Order by S.GroupID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)      
 END

 IF @ComparisonType='Day'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,AcceptedParts,AvgCycletime) '      
 Select @Strsql = @Strsql + 'Select S.GroupID, S.ComponentID,S.Operationno,Sum(ISNULL(S.AcceptedParts,0)) AcceptedParts,Sum(S.Sum_of_ActCycleTime) As ActCycleTime      
 From ShiftProductionDetails S where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.GroupID,S.ComponentID,S.Operationno Order by S.GroupID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)      
 END

 update #Plantsdata set AvgCycletime = AvgCycletime/AcceptedParts where AcceptedParts>0

 Select Plantid,ComponentID,Operationno,AcceptedParts,dbo.f_FormatTime(AvgCycletime,'hh:mm:ss') as AvgCycletime from #Plantsdata
 order by PlantID,ComponentID,Operationno
END

ELSE
BEGIN 
If @ComparisonType='Year'      
BEGIN      
select @strsql='' 
Select @Strsql = 'Insert into #ProdData(Machineid,ComponentID,Operationno,OperatorID,AcceptedParts,AvgCycletime) '      
Select @Strsql = @Strsql + 'Select S.Machineid,S.ComponentID,S.Operationno, S.OperatorID, Sum(ISNULL(S.AcceptedParts,0)) AcceptedParts,Sum(S.Sum_of_ActCycleTime) As ActCycleTime      
From ShiftProductionDetails S 
where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')'
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
Select @Strsql = @Strsql+  ' GROUP By S.Machineid,S.ComponentID,S.OperatorID,S.Operationno Order by S.Machineid,S.ComponentID,S.OperatorID,S.Operationno'
Print @Strsql      
Exec(@Strsql)
END      
       
      
If @ComparisonType='Month' 
BEGIN      
      
select @strsql='' 
Select @Strsql = 'Insert into #ProdData(Machineid,ComponentID,Operationno,OperatorID,AcceptedParts,AvgCycletime) '      
Select @Strsql = @Strsql + 'Select S.Machineid,S.ComponentID,S.Operationno, S.OperatorID, Sum(ISNULL(S.AcceptedParts,0)) AcceptedParts,Sum(S.Sum_of_ActCycleTime) As ActCycleTime      
From ShiftProductionDetails S where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid      
Select @Strsql = @Strsql+  ' GROUP By S.Machineid,S.ComponentID,S.OperatorID,S.Operationno Order by S.Machineid,S.ComponentID,S.OperatorID,S.Operationno'
Print @Strsql      
Exec(@Strsql) 
END      
      
If @ComparisonType='Day' 
BEGIN      
      
select @strsql='' 
Select @Strsql = 'Insert into #ProdData(Machineid,ComponentID,Operationno,OperatorID,AcceptedParts,AvgCycletime) '      
Select @Strsql = @Strsql + 'Select S.Machineid,S.ComponentID,S.Operationno, S.OperatorID, Sum(ISNULL(S.AcceptedParts,0)) AcceptedParts,Sum(S.Sum_of_ActCycleTime) As ActCycleTime      
From ShiftProductionDetails S where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
Select @Strsql = @Strsql+  ' GROUP By S.Machineid,S.ComponentID,S.OperatorID,S.Operationno Order by S.Machineid,S.ComponentID,S.OperatorID,S.Operationno'
Print @Strsql      
Exec(@Strsql) 
END      

IF @View = 'Machinewise'
begin
Select ComponentID,OperatorID,Operationno,SUM(AcceptedParts) AcceptedParts,dbo.f_FormatTime(cast(SUM(AvgCycletime)/SUM(AcceptedParts) as nvarchar(50)),'hh:mm:ss') as AvgCycletime 
from #ProdData
group by ComponentID,OperatorID,Operationno
having(SUM(AcceptedParts))>0
order by ComponentID,OperatorID,Operationno
end
IF @View = 'Operatorwise'
begin
Select #ProdData.MachineID,ComponentID,Operationno,SUM(AcceptedParts) AcceptedParts,dbo.f_FormatTime(cast(SUM(AvgCycletime)/SUM(AcceptedParts) as nvarchar(50)),'hh:mm:ss') as AvgCycletime 
,machineinformation.description as MachineDescription from #ProdData
inner join machineinformation on #Proddata.Machineid=machineinformation.machineid
group by #ProdData.MachineID,ComponentID,Operationno,machineinformation.description
having(SUM(AcceptedParts))>0
order by #ProdData.MachineID,ComponentID,Operationno
end
IF @View = 'Componentwise'
begin
Select #ProdData.MachineID,OperatorID,Operationno,SUM(AcceptedParts) AcceptedParts,dbo.f_FormatTime(cast(SUM(AvgCycletime)/SUM(AcceptedParts) as nvarchar(50)),'hh:mm:ss') as AvgCycletime 
,machineinformation.description as MachineDescription from #ProdData
inner join machineinformation on #Proddata.Machineid=machineinformation.machineid
group by #ProdData.MachineID,OperatorID,Operationno,machineinformation.description
having(SUM(AcceptedParts))>0
order by #ProdData.MachineID,OperatorID,Operationno
end
       
END 
END
