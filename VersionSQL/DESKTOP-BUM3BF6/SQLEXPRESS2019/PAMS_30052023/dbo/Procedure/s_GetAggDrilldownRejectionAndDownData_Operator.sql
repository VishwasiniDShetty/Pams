/****** Object:  Procedure [dbo].[s_GetAggDrilldownRejectionAndDownData_Operator]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec [dbo].[s_GetAggDrilldownRejectionAndDownData_Operator] '2017-05-01','2017-05-01','','','CNC GRINDING','','','currentShift','DownCode'     
exec [dbo].[s_GetAggDrilldownRejectionAndDownData_Operator] '2016-10-01','2016-10-01','','','','','','year','DownCode'   
exec [dbo].[s_GetAggDrilldownRejectionAndDownData_Operator] '2016-10-01','2016-10-01','','','','','','month','DownCode'   
exec [dbo].[s_GetAggDrilldownRejectionAndDownData_Operator] '2016-10-01','2016-10-01','','','','','','month','rejectioncode'   
exec [dbo].[s_GetAggDrilldownRejectionAndDownData] '2016-10-01','2016-10-01','','','','','','year','DownCode'   
*/
      
CREATE PROCEDURE [dbo].[s_GetAggDrilldownRejectionAndDownData_Operator]      
 @StartDate As DateTime, 
 @EndDate As DateTime,     
 @ShiftName As NVarChar(50)='',      
 @PlantID As NVarChar(2000)='',      
 @MachineID As nvarchar(50),      
 @Component As nvarchar(50)='', 
 @Employee As nvarchar(50)='',             
 @ComparisonType As nvarchar(50)='', /* year,month,day */
 @Param nvarchar(100)='',    --Rejection/Rework/Down
 @Groupid as nvarchar(2000)=''  
AS      
BEGIN      
----------------------------------------------------------------------------------------------------------      
--* Declaration of Variables *--      
----------------------------------------------------------------------------------------------------------      
Declare @Strsql nvarchar(4000)      
Declare @timeformat AS nvarchar(12)      
      
Declare @Strmachine nvarchar(255)      
Declare @StrPlantID AS NVarchar(4000)      
Declare @StrShift AS NVarchar(255)      
Declare @StrComponent as nvarchar(255)
Declare @StrEmployee as nvarchar(255)
Declare @CurDate As DateTime     
Declare @StrGroupid as nvarchar(4000)        

    
Select @Strsql = ''      
Select @Strmachine = ''      
Select @StrPlantID=''      
Select @StrShift=''      
Select @StrComponent=''
Select @StrEmployee='' 
Select @StrGroupid=''    
 

create table #Proddata
(
	Pdate DateTime,    
	StartDate  DateTime,    
	EndDate DateTime,    
	Shift  NVarChar(20),  
	OperatorID nvarchar(50),
	Catagory nvarchar(50),
	Code nvarchar(50),
	Qty float default 0 ,
	TotalQty float default 0 ,
	Down float default 0 ,
	ML_Time float default 0 ,
	TotalDown float default 0 
)

 CREATE TABLE #MachineInfo     
(    
OperatorID nvarchar(50)  
)  

If isnull(@PlantID,'') <> ''    
Begin    
--Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )' 
 Select @StrPlantID = ' And ( PlantMachine.PlantID in (' + @PlantID + '))' 
  
End    
    
If isnull(@Machineid,'') <> ''    
Begin    
 Select @Strmachine = ' And ( MachineInformation.MachineID = N''' + @MachineID + ''')'    
End 

If isnull(@Groupid,'') <> ''  
Begin  
 --Select @StrGroupid = ' And ( PlantMachineGroups.GroupID = N''' + @GroupID + ''')'  
 Select @StrGroupid = ' And ( PlantMachineGroups.GroupID in (' + @GroupID + '))' 
End 

SELECT @timeformat ='mm'

Select @timeformat = isnull((select valueintext2 from CockpitDefaults where parameter='TPMTrakAppSettings' and ValueinText='Downtime'),'mm')
if (@timeformat <>'hh' and @timeformat <>'mm')
begin
	select @timeformat = 'mm'
end


Select @Strsql =''    
Select @Strsql ='Insert Into #MachineInfo(OperatorID)'        
Select @Strsql =@Strsql+'select distinct OperatorID from shiftproductiondetails 
where pDate between DATEADD(yy, DATEDIFF(yy, 0,' + quotename(@startdate,'''') + '), 0) and DATEADD(yy, DATEDIFF(yy, 0,' + quotename(@startdate,'''') + ') + 1, -1)
and (MachineID=' + QUOTENAME(@machineid, '''') + ' or ''''=' + QUOTENAME(@machineid, '''') + ') 
and (PlantID=' + QUOTENAME(@PlantID, '''') + ' or ''''=' + QUOTENAME(@PlantID, '''') + ') 
and (OperatorID=' + quotename(@Employee, '''') + ' or ''''=' + quotename(@Employee, '''') + ')
and (ComponentID=' + quotename(@Component, '''') + ' or ''''=' + quotename(@Component, '''') + ')
and (GroupID=' + quotename(@GroupID, '''') + ' or ''''=' + quotename(@Groupid, '''') + ')
UNION
'
Select @Strsql =@Strsql+'select distinct OperatorID from shiftdowntimedetails 
where dDate between DATEADD(yy, DATEDIFF(yy, 0,' + quotename(@startdate,'''') + '), 0) and DATEADD(yy, DATEDIFF(yy, 0,' + quotename(@startdate,'''') + ') + 1, -1)
and (MachineID=' + QUOTENAME(@machineid, '''') + ' or ''''=' + QUOTENAME(@machineid, '''') + ') 
and (PlantID=' + QUOTENAME(@PlantID, '''') + ' or ''''=' + QUOTENAME(@PlantID, '''') + ') 
and (OperatorID=' + quotename(@Employee, '''') + ' or ''''=' + quotename(@Employee, '''') + ')
and (ComponentID=' + quotename(@Component, '''') + ' or ''''=' + quotename(@Component, '''') + ')
and (GroupID=' + quotename(@GroupID, '''') + ' or ''''=' + quotename(@Groupid, '''') + ')
'
--Select @Strsql ='Insert Into #MachineInfo(OperatorID)'    
--Select @Strsql =@Strsql+' Select   Distinct MachineInformation.MachineID From MachineInformation'    
--Select @Strsql =@Strsql+' Left Outer Join PlantMachine ON MachineInformation.MachineID=PlantMachine.MachineID'    
--Select @Strsql =@Strsql+' Where MachineInformation.MachineID Is Not NULL'    
--Select @Strsql =@Strsql+@StrPlantID+@Strmachine    
--Select @Strsql =@Strsql+' Order By MachineInformation.MachineID'    
print @Strsql    
Exec (@Strsql)    
    
       
If isnull(@PlantID,'') <> ''      
Begin      
 --Select @StrPlantID = ' And (ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'  
 Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID in (' + @PlantID + '))'    
End      
      
If isnull(@Machineid,'') <> ''      
Begin      
 Select @Strmachine = ' And (ShiftProductionDetails.MachineID = N''' + @MachineID + ''')'      
End 
     
If isnull(@ShiftName,'') <> ''
Begin
Select @StrShift = ' And (ShiftProductionDetails.Shift = N''' + @ShiftName + ''')'
End

If isnull(@Component,'') <> ''
Begin
Select @StrComponent = ' And (ShiftProductionDetails.Componentid = N''' + @Component + ''')'
End

If isnull(@Employee,'') <> ''
Begin
Select @StrEmployee = ' And (ShiftProductionDetails.Operatorid = N''' + @Employee + ''')'
End      

If isnull(@Groupid,'') <> ''  
Begin  
 --Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID = N''' + @GroupID + ''')' 
  Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID  in (' + @GroupID + '))' 
End 
  
    
CREATE TABLE #TimePeriodDetails    
(    
PDate datetime,    
Shift nvarchar(20),    
StartDate  DateTime,    
EndDate DateTime,   
)  

CREATE TABLE #categoryInfo     
(   
OperatorID nvarchar(50), 
Catagory nvarchar(50),
Code nvarchar(50) 
) 


Declare @StratOfMonth As DateTime    
Declare @EndOfMonth As DateTime    

IF @ComparisonType='Month'    
BEGIN   
 
   Select @StartDate = cast(datepart(yyyy,@StartDate) as nvarchar(4))+ '-01' + '-01'    
   select @EndDate = dateadd(Month,11,@StartDate)    
  
  SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')    
  SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@EndDate,'End')    
  While @StratOfMonth<=@EndOfMonth    
  BEGIN    
   INSERT INTO #TimePeriodDetails ( StartDate, Enddate )    
   SELECT @StratOfMonth,dbo.f_GetPhysicalMonth(@StratOfMonth,'End')    
    
   SELECT @StratOfMonth=DateAdd(mm,1,@StratOfMonth)      
       
  END    
END    
 
IF @ComparisonType='CurrentMonth'    
BEGIN      

  SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')    
  SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@EndDate,'End')    
   
   INSERT INTO #TimePeriodDetails ( StartDate, Enddate )    
   SELECT @StratOfMonth,dbo.f_GetPhysicalMonth(@StratOfMonth,'End')    
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

If @ComparisonType='SHIFT' --or @ComparisonType='OEE_Month'    
BEGIN    

  Select @StartDate = cast(datepart(yyyy,@StartDate) as nvarchar(4))+ '-01' + '-01'    
  select @EndDate = dateadd(Month,11,@StartDate)    
  
  SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')    
  SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@EndDate,'End')    

 WHILE @StratOfMonth<=@EndOfMonth
 BEGIN
	 INSERT #TimePeriodDetails(Pdate, Shift, StartDate,EndDate)    
	 EXEC s_GetShiftTime @StratOfMonth,@ShiftName    
	 SELECT  @StratOfMonth = DATEADD(DAY,1,@StratOfMonth)
END
 
END    

If @ComparisonType='CurrentSHIFT' --or @ComparisonType='OEE_Month'    
BEGIN    

	 INSERT #TimePeriodDetails(Pdate, Shift, StartDate,EndDate)    
	 EXEC s_GetShiftTime @StartDate,@ShiftName    
 
END 


IF @Param='RejectionCategory' or @Param='RejectionCode'
BEGIN
		If @ComparisonType='Year'      
		BEGIN      		   
		select @strsql='' 
		Select @Strsql = 'Insert into #ProdData(OperatorID,Catagory,Code,Qty,TotalQty) '      
		Select @Strsql = @Strsql+' Select ShiftProductionDetails.OperatorID,R.Catagory,R.Rejectionid,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej,0'
		Select @Strsql = @Strsql+' From ShiftProductionDetails 
		Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		inner Join Rejectioncodeinformation R on R.rejectionid = ShiftRejectionDetails.Rejection_Reason'
		Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '
		Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql+' Group By ShiftProductionDetails.OperatorID,R.Catagory,R.Rejectionid'
		Print @Strsql      
		Exec(@Strsql)      

		Select @Strsql = 'UPDATE #ProdData SET TotalQty=ISNULL(TotalQty,0)+ ISNULL(T2.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.OperatorID,T1.Catagory,ISNULL(Sum(Qty),0) as Rej'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.OperatorID=T2.OperatorID and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

		IF @param='RejectionCategory'
		Begin
			Select distinct OperatorID,Catagory,TotalQty from #ProdData
			order by OperatorID,Catagory
		End
		IF @param='RejectionCode'
		Begin
			Select OperatorID,Catagory,Code,Qty from #ProdData
			order by OperatorID,Catagory,Code
		End

		return
		END      

		
		Insert into #categoryInfo(OperatorID,Catagory,Code)
		Select Distinct OperatorID,R.Catagory,R.Rejectionid from Rejectioncodeinformation R CROSS Join #MachineInfo

		Insert into #ProdData(OperatorID,Pdate,StartDate,EndDate,Shift,Catagory,Code,Qty,TotalQty)
		Select OperatorID,Pdate,StartDate,EndDate,Shift,Catagory,Code,0,0 From #TimePeriodDetails CROSS Join #categoryInfo    
		       
		      
		If @ComparisonType='Month' or @ComparisonType='CurrentMonth'
		BEGIN      

		select @strsql='' 
		Select @Strsql = 'Update #ProdData SET Qty=ISNULL(Qty,0) + ISNULL(T2.Rej,0) from('      
		Select @Strsql = @Strsql+' Select ShiftProductionDetails.OperatorID,T.Pdate,T.StartDate,T.EndDate,R.Catagory,R.Rejectionid,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails 
		Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		inner Join Rejectioncodeinformation R on R.rejectionid = ShiftRejectionDetails.Rejection_Reason
		inner join #Proddata T on ShiftProductionDetails.OperatorID=T.OperatorID and T.catagory=R.Catagory and T.Code=R.rejectionid'
		Select @Strsql = @Strsql+' Where ShiftProductionDetails.pDate>=T.StartDate And ShiftProductionDetails.pDate<= T.EndDate'
		Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql+' Group By ShiftProductionDetails.OperatorID,T.Pdate,T.StartDate,T.EndDate,R.Catagory,R.Rejectionid)T2
		Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate and #ProdData.EndDate=T2.EndDate and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.Catagory and #ProdData.code=T2.Rejectionid'
		Print @Strsql      
		Exec(@Strsql)      

		Select @Strsql = 'UPDATE #ProdData SET TotalQty=ISNULL(TotalQty,0)+ ISNULL(T2.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.StartDate,T1.EndDate,T1.OperatorID,T1.Catagory,ISNULL(Sum(Qty),0) as Rej'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.StartDate,T1.EndDate'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate and #ProdData.EndDate=T2.EndDate and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

		IF @param='RejectionCategory'
		Begin
			Select distinct OperatorID,Startdate,Enddate,Substring(Datename(Month,Startdate),1,3) as NameOftheMonth,Catagory,TotalQty from #ProdData
			order by OperatorID,Startdate,Catagory
		End
		IF @param='RejectionCode'
		Begin
			Select OperatorID,Startdate,Enddate,Substring(Datename(Month,Startdate),1,3) as NameOftheMonth,Catagory,Code,Qty from #ProdData
			order by OperatorID,Startdate,Catagory,Code
		End

		END      
		      
		      
		If @ComparisonType='Day' or @ComparisonType='CurrentDay' 
		BEGIN      

		select @strsql='' 
		Select @Strsql = 'Update #ProdData SET Qty=ISNULL(Qty,0) + ISNULL(T2.Rej,0) from('      
		Select @Strsql = @Strsql+' Select ShiftProductionDetails.OperatorID,T.Pdate,R.Catagory,R.Rejectionid,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails 
		Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		inner Join Rejectioncodeinformation R on R.rejectionid = ShiftRejectionDetails.Rejection_Reason
		inner join #Proddata T on ShiftProductionDetails.OperatorID=T.OperatorID and T.catagory=R.Catagory and T.Code=R.rejectionid'
		Select @Strsql = @Strsql+' Where convert(nvarchar(10),ShiftProductionDetails.pDate,120)=convert(nvarchar(10),T.Pdate,120)'
		Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql+' Group By ShiftProductionDetails.OperatorID,T.Pdate,R.Catagory,R.Rejectionid)T2
		Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.Catagory and #ProdData.code=T2.Rejectionid'
		Print @Strsql      
		Exec(@Strsql)      

		Select @Strsql = 'UPDATE #ProdData SET TotalQty=ISNULL(TotalQty,0)+ ISNULL(T2.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.Pdate,T1.OperatorID,T1.Catagory,ISNULL(Sum(Qty),0) as Rej'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.Pdate'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

		IF @param='RejectionCategory'
		Begin
			Select distinct OperatorID,PDate,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day],Catagory,TotalQty from #ProdData
			order by OperatorID,PDate,Catagory
		End
		IF @param='RejectionCode'
		Begin
			Select OperatorID,PDate,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day],Catagory,Code,Qty from #ProdData
			order by OperatorID,PDate,Catagory,Code
		End

		END   

		If @ComparisonType='Shift' or @ComparisonType='CurrentShift' 
		BEGIN      

		select @strsql='' 
		Select @Strsql = 'Update #ProdData SET Qty=ISNULL(Qty,0) + ISNULL(T2.Rej,0) from('      
		Select @Strsql = @Strsql+' Select ShiftProductionDetails.OperatorID,T.Pdate,T.Shift,R.Catagory,R.Rejectionid,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails 
		Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		inner Join Rejectioncodeinformation R on R.rejectionid = ShiftRejectionDetails.Rejection_Reason
		inner join #Proddata T on ShiftProductionDetails.OperatorID=T.OperatorID and T.catagory=R.Catagory and T.Code=R.rejectionid'
		Select @Strsql = @Strsql+' Where convert(nvarchar(10),ShiftProductionDetails.pDate,120)=convert(nvarchar(10),T.Pdate,120) and ShiftProductionDetails.Shift=T.Shift'
		Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql+' Group By ShiftProductionDetails.OperatorID,T.Pdate,T.Shift,R.Catagory,R.Rejectionid)T2
		Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate and #ProdData.Shift=T2.Shift and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.Catagory and #ProdData.code=T2.Rejectionid'
		Print @Strsql      
		Exec(@Strsql)      

		Select @Strsql = 'UPDATE #ProdData SET TotalQty=ISNULL(TotalQty,0)+ ISNULL(T2.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.Pdate,T1.Shift,T1.OperatorID,T1.Catagory,ISNULL(Sum(Qty),0) as Rej'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.Pdate,T1.Shift'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate and #ProdData.Shift=T2.Shift and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

		IF @param='RejectionCategory'
		Begin
			Select distinct OperatorID,PDate,Shift,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],
			RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day] ,Catagory,TotalQty from #ProdData
			order by OperatorID,PDate,Shift,Catagory
		End
		IF @param='RejectionCode'
		Begin
			Select OperatorID,PDate,Shift,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],
			RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day] ,Catagory,Code,Qty from #ProdData
			order by OperatorID,PDate,Shift,Catagory,Code
		End

		END   
   
END

IF @Param='Reworkcategory' or @Param='ReworkCode'
BEGIN
  
     

		If @ComparisonType='Year'      
		BEGIN      		   
		select @strsql='' 
		Select @Strsql = 'Insert into #ProdData(OperatorID,Catagory,Code,Qty,TotalQty) '      
		Select @Strsql = @Strsql+' Select ShiftProductionDetails.OperatorID,R.ReworkCatagory,R.Reworkid,Sum(isnull(ShiftReworkDetails.Rework_Qty,0))as Rej,0'
		Select @Strsql = @Strsql+' From ShiftProductionDetails 
		Left Outer Join ShiftReworkDetails ON ShiftProductionDetails.ID=ShiftReworkDetails.ID
		inner Join Reworkinformation R on R.Reworkid = ShiftReworkDetails.Rework_Reason'
		Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '
		Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql+' Group By ShiftProductionDetails.OperatorID,R.ReworkCatagory,R.Reworkid'
		Print @Strsql      
		Exec(@Strsql)      

		Select @Strsql = 'UPDATE #ProdData SET TotalQty=ISNULL(TotalQty,0)+ ISNULL(T2.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.OperatorID,T1.Catagory,ISNULL(Sum(Qty),0) as Rej'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.OperatorID=T2.OperatorID and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

		IF @param='Reworkcategory'
		Begin
			Select distinct OperatorID,Catagory,TotalQty from #ProdData
			order by OperatorID,Catagory
		End
		IF @param='ReworkCode'
		Begin
			Select OperatorID,Catagory,Code,Qty from #ProdData
			order by OperatorID,Catagory,Code
		End
		
		return
		END      
		       
	
		Insert into #categoryInfo(OperatorID,Catagory,Code)
		Select Distinct OperatorID,R.ReworkCatagory,R.Reworkid from Reworkinformation R CROSS Join #MachineInfo

		Insert into #ProdData(OperatorID,Pdate,StartDate,EndDate,Shift,Catagory,Code,Qty,TotalQty)
		Select OperatorID,Pdate,StartDate,EndDate,Shift,Catagory,Code,0,0 From #TimePeriodDetails CROSS Join #categoryInfo  	
      
		If @ComparisonType='Month' or @ComparisonType='CurrentMonth'
		BEGIN      

		select @strsql='' 
		Select @Strsql = 'Update #ProdData SET Qty=ISNULL(Qty,0) + ISNULL(T2.Rej,0) from('      
		Select @Strsql = @Strsql+' Select ShiftProductionDetails.OperatorID,T.Pdate,T.StartDate,T.EndDate,R.ReworkCatagory,R.Reworkid,Sum(isnull(ShiftReworkDetails.Rework_Qty,0))as Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails 
		Left Outer Join ShiftReworkDetails ON ShiftProductionDetails.ID=ShiftReworkDetails.ID
		inner Join Reworkinformation R on R.Reworkid = ShiftReworkDetails.Rework_Reason
		inner join #Proddata T on ShiftProductionDetails.OperatorID=T.OperatorID and T.catagory=R.ReworkCatagory and T.Code=R.Reworkid'
		Select @Strsql = @Strsql+' Where ShiftProductionDetails.pDate>=T.StartDate And ShiftProductionDetails.pDate<= T.EndDate'
		Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql+' Group By ShiftProductionDetails.OperatorID,T.Pdate,T.StartDate,T.EndDate,R.ReworkCatagory,R.Reworkid)T2
		Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate and #ProdData.EndDate=T2.EndDate and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.ReworkCatagory and #ProdData.code=T2.Reworkid'
		Print @Strsql      
		Exec(@Strsql)      

		Select @Strsql = 'UPDATE #ProdData SET TotalQty=ISNULL(TotalQty,0)+ ISNULL(T2.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.StartDate,T1.EndDate,T1.OperatorID,T1.Catagory,ISNULL(Sum(Qty),0) as Rej'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.StartDate,T1.EndDate'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate and #ProdData.EndDate=T2.EndDate and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

		IF @param='Reworkcategory'
		Begin
			Select distinct OperatorID,Startdate,Enddate,Substring(Datename(Month,Startdate),1,3) as NameOftheMonth,Catagory,TotalQty from #ProdData
			order by OperatorID,Startdate,Catagory
		End
		IF @param='ReworkCode'
		Begin
			Select OperatorID,Startdate,Enddate,Substring(Datename(Month,Startdate),1,3) as NameOftheMonth,Catagory,Code,Qty from #ProdData
			order by OperatorID,Startdate,Catagory,Code
		End

		END      
		      
		      
		If @ComparisonType='Day' or @ComparisonType='CurrentDay' 
		BEGIN      

		select @strsql='' 
		Select @Strsql = 'Update #ProdData SET Qty=ISNULL(Qty,0) + ISNULL(T2.Rej,0) from('      
		Select @Strsql = @Strsql+' Select ShiftProductionDetails.OperatorID,T.Pdate,R.ReworkCatagory,R.Reworkid,Sum(isnull(ShiftReworkDetails.Rework_Qty,0))as Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails 
		Left Outer Join ShiftReworkDetails ON ShiftProductionDetails.ID=ShiftReworkDetails.ID
		inner Join Reworkinformation R on R.Reworkid = ShiftReworkDetails.Rework_Reason
		inner join #Proddata T on ShiftProductionDetails.OperatorID=T.OperatorID and T.catagory=R.ReworkCatagory and T.Code=R.Reworkid'
		Select @Strsql = @Strsql+' Where ShiftProductionDetails.pDate=T.Pdate'
		Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql+' Group By ShiftProductionDetails.OperatorID,T.Pdate,R.ReworkCatagory,R.Reworkid)T2
		Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.ReworkCatagory and #ProdData.code=T2.Reworkid'
		Print @Strsql      
		Exec(@Strsql)      

		Select @Strsql = 'UPDATE #ProdData SET TotalQty=ISNULL(TotalQty,0)+ ISNULL(T2.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.Pdate,T1.OperatorID,T1.Catagory,ISNULL(Sum(Qty),0) as Rej'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.Pdate'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

		IF @param='Reworkcategory'
		Begin
			Select distinct OperatorID,PDate,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day],Catagory,TotalQty from #ProdData
			order by OperatorID,PDate,Catagory
		End
		IF @param='ReworkCode'
		Begin
			Select OperatorID,PDate,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day],Catagory,Code,Qty from #ProdData
			order by OperatorID,PDate,Catagory,Code
		End

		END   

		If @ComparisonType='Shift' or @ComparisonType='CurrentShift' 
		BEGIN      

		select @strsql='' 
		Select @Strsql = 'Update #ProdData SET Qty=ISNULL(Qty,0) + ISNULL(T2.Rej,0) from('      
		Select @Strsql = @Strsql+' Select ShiftProductionDetails.OperatorID,T.Pdate,T.Shift,R.ReworkCatagory,R.Reworkid,Sum(isnull(ShiftReworkDetails.Rework_Qty,0))as Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails 
		Left Outer Join ShiftReworkDetails ON ShiftProductionDetails.ID=ShiftReworkDetails.ID
		inner Join Reworkinformation R on R.Reworkid = ShiftReworkDetails.Rework_Reason
		inner join #Proddata T on ShiftProductionDetails.OperatorID=T.OperatorID and T.catagory=R.ReworkCatagory and T.Code=R.Reworkid'
		Select @Strsql = @Strsql+' Where ShiftProductionDetails.pDate=T.Pdate and ShiftProductionDetails.Shift=T.Shift'
		Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql+' Group By ShiftProductionDetails.OperatorID,T.Pdate,T.Shift,R.ReworkCatagory,R.Reworkid)T2
		Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate and #ProdData.Shift=T2.Shift and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.ReworkCatagory and #ProdData.code=T2.Reworkid'
		Print @Strsql      
		Exec(@Strsql)      

		Select @Strsql = 'UPDATE #ProdData SET TotalQty=ISNULL(TotalQty,0)+ ISNULL(T2.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.Pdate,T1.Shift,T1.OperatorID,T1.Catagory,ISNULL(Sum(Qty),0) as Rej'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.Pdate,T1.Shift'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate and #ProdData.Shift=T2.Shift and #ProdData.OperatorID=T2.OperatorID 
		and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

		IF @param='Reworkcategory'
		Begin
			Select distinct OperatorID,PDate,Shift,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],
			RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day] ,Catagory,TotalQty from #ProdData
			order by OperatorID,PDate,Shift,Catagory
		End
		IF @param='ReworkCode'
		Begin
			Select OperatorID,PDate,Shift,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],
			RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day] ,Catagory,Code,Qty from #ProdData
			order by OperatorID,PDate,Shift,Catagory,Code
		End

		END   
   
END


IF @Param='DownCategory' or @Param='DownCode'
BEGIN

		If isnull(@PlantID,'') <> ''      
		Begin      
		 --Select @StrPlantID = ' And (ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'   
		 Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID in (' + @PlantID + '))'    
		End      
		      
		If isnull(@Machineid,'') <> ''      
		Begin      
		 Select @Strmachine = ' And (ShiftDownTimeDetails.MachineID = N''' + @MachineID + ''')'      
		End 
		     
		If isnull(@ShiftName,'') <> ''
		Begin
		Select @StrShift = ' And (ShiftDownTimeDetails.Shift = N''' + @ShiftName + ''')'
		End

		If isnull(@Component,'') <> ''
		Begin
		Select @StrComponent = ' And (ShiftDownTimeDetails.Componentid = N''' + @Component + ''')'
		End

		If isnull(@Employee,'') <> ''
		Begin
		Select @StrEmployee = ' And (ShiftDownTimeDetails.Operatorid = N''' + @Employee + ''')'
		End  
			
		If isnull(@Groupid,'') <> ''  
		Begin  
		 --Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID = N''' + @GroupID + ''')'
		 Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID  in (' + @GroupID + '))'   
		End 
 
     
		If @ComparisonType='Year'      
		BEGIN      
		   
		select @strsql='' 
		Select @Strsql = 'Insert into #ProdData(OperatorID,Catagory,Code,Down,TotalDown) '      
		Select @Strsql = @Strsql+' Select OperatorID,DownCategory,Downid,Sum(isnull(DownTime,0)),0'
		Select @Strsql = @Strsql+' From ShiftDownTimeDetails' 
		Select @Strsql = @Strsql+' Where datepart(YEAR,ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '
		Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql+' Group By OperatorID,DownCategory,Downid'
		Print @Strsql      
		Exec(@Strsql)      


		Select @Strsql = 'UPDATE #ProdData SET Down = isNull(#ProdData.Down,0) - isNull(T2.loss,0) ,
			              ML_Time = isNull(#ProdData.ML_Time,0) + isNull(T2.loss,0) '
		Select @Strsql = @Strsql + 'from (select T1.OperatorID, T1.Code,sum(
		CASE 
		WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0  
		THEN isnull(ShiftDownTimeDetails.Threshold,0)
		ELSE ShiftDownTimeDetails.DownTime
		END) AS LOSS '
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails INNER JOIN #ProdData T1 on T1.OperatorID = ShiftDowntimeDetails.OperatorID 
		and T1.Code = ShiftDowntimeDetails.Downid where ML_flag = 1 and datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'		
		Select @Strsql = @Strsql + @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql + ' Group By T1.OperatorID,T1.Code'
		Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON  #ProdData.OperatorID=T2.OperatorID and #ProdData.Code=T2.Code '
		Print @Strsql
		Exec(@Strsql)	
		--=========================================================================--

		IF (Select ValueInInt from CockpitDefaults WHERE Parameter = 'ExcludeTPMTrakDown') = 1
		BEGIN
		Select @Strsql = 'UPDATE #ProdData SET TotalDown=ISNULL(TotalDown,0)+ ISNULL(T2.Down,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.OperatorID,T1.Catagory,ISNULL(Sum(ISNULL(Down,0)+ISNULL(ML_Time,0)),0) as Down'
		Select @Strsql = @Strsql+' From #ProdData T1
								 where code not in (select DownId from PredefinedDownCodeInfo) '
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.OperatorID=T2.OperatorID and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)
       END
	   ELSE 
	   BEGIN
	   
		Select @Strsql = 'UPDATE #ProdData SET TotalDown=ISNULL(TotalDown,0)+ ISNULL(T2.Down,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.OperatorID,T1.Catagory,ISNULL(Sum(ISNULL(Down,0)+ISNULL(ML_Time,0)),0) as Down'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.OperatorID=T2.OperatorID and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)
	   END 

		IF @param='Downcategory'
		Begin
			Select distinct OperatorID,Catagory,Round(dbo.f_FormatTime(TotalDown,@timeformat),2) as TotalDown from #ProdData
				order by OperatorID,Catagory
		End

       IF @param='DownCode'
		Begin

			IF (Select ValueInInt from CockpitDefaults WHERE Parameter = 'ExcludeTPMTrakDown') = 1
			BEGIN
				Select OperatorID,Catagory,Code,Round(dbo.f_FormatTime((ISNULL(Down,0)+ISNULL(ML_Time,0)),@timeformat),2) as Down from #ProdData
				where code not in (select DownId from PredefinedDownCodeInfo) 
				order by OperatorID,Catagory,Code
				return
			End
		    
			ELSE 
			BEGIN

				Select OperatorID,Catagory,Code,Round(dbo.f_FormatTime((ISNULL(Down,0)+ISNULL(ML_Time,0)),@timeformat),2) as Down from #ProdData
				order by OperatorID,Catagory,Code
				return
			 end
	   END
  END
	--=========================================================================--
	
		Insert into #categoryInfo(OperatorID,Catagory,Code)
		Select Distinct OperatorID,R.Catagory,R.Downid from Downcodeinformation R CROSS Join #MachineInfo where R.Catagory IS NOT NULL

		Insert into #ProdData(OperatorID,Pdate,StartDate,EndDate,Shift,Catagory,Code,Qty,TotalQty)
		Select OperatorID,Pdate,StartDate,EndDate,Shift,Catagory,Code,0,0 From #TimePeriodDetails CROSS Join #categoryInfo 
	      
		If @ComparisonType='Month' or @ComparisonType='CurrentMonth'
		BEGIN      

		Select @Strsql = 'UPDATE #ProdData SET Down = IsNull(T2.DownTime,0)'    
		Select @Strsql = @Strsql + ' From (select T1.StartDate As StartDate ,T1.EndDate As EndDate,T1.OperatorID,T1.Catagory,T1.Code,(Sum(ShiftDownTimeDetails.DownTime))As DownTime'    
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails 
		inner join #Proddata T1 on ShiftDownTimeDetails.OperatorID=T1.OperatorID and T1.catagory=ShiftDownTimeDetails.DownCategory and T1.Code=ShiftDownTimeDetails.Downid    
		where ShiftDownTimeDetails.dDate>=T1.StartDate And ShiftDownTimeDetails.dDate<= T1.EndDate'    
		Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
		Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate,T1.OperatorID,T1.Catagory,T1.Code'    
		Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And #ProdData.OperatorID=T2.OperatorID 
		And #ProdData.Catagory=T2.Catagory And #ProdData.Code=T2.Code'    
		Print @Strsql    
		Exec(@Strsql)  
    

		Select @Strsql = 'UPDATE #ProdData SET Down = isNull(#ProdData.Down,0) - isNull(T2.loss,0) ,
			              ML_Time = isNull(#ProdData.ML_Time,0) + isNull(T2.loss,0) '
		Select @Strsql = @Strsql + 'from (select T1.StartDate As StartDate ,T1.EndDate As EndDate,T1.OperatorID,T1.Catagory,T1.Code,sum(
		CASE 
		WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0  
		THEN isnull(ShiftDownTimeDetails.Threshold,0)
		ELSE ShiftDownTimeDetails.DownTime
		END) AS LOSS '
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails 
		INNER JOIN #ProdData T1 on T1.OperatorID = ShiftDowntimeDetails.OperatorID and T1.catagory=ShiftDownTimeDetails.DownCategory and T1.Code = ShiftDowntimeDetails.Downid 
		where ShiftDownTimeDetails.ML_flag = 1 and ShiftDownTimeDetails.dDate>=T1.StartDate And ShiftDownTimeDetails.dDate<= T1.EndDate '		
		Select @Strsql = @Strsql + @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate,T1.OperatorID,T1.Catagory,T1.Code'
		Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And #ProdData.OperatorID=T2.OperatorID 
		And #ProdData.Catagory=T2.Catagory And #ProdData.Code=T2.Code'
		Print @Strsql
		Exec(@Strsql)	

		--=========================================================================--

		IF (Select ValueInInt from CockpitDefaults WHERE Parameter = 'ExcludeTPMTrakDown') = 1
		BEGIN
		Select @Strsql = 'UPDATE #ProdData SET TotalDown=ISNULL(TotalDown,0)+ ISNULL(T2.Down,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,T1.OperatorID,T1.Catagory,ISNULL(Sum(ISNULL(Down,0)+ISNULL(ML_Time,0)),0) as Down'
		Select @Strsql = @Strsql+' From #ProdData T1
									   where code not in (select DownId from PredefinedDownCodeInfo) '
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.StartDate,T1.EndDate'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate and 
		#ProdData.OperatorID=T2.OperatorID and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

       END
	   ELSE 
	   BEGIN
	   
		Select @Strsql = 'UPDATE #ProdData SET TotalDown=ISNULL(TotalDown,0)+ ISNULL(T2.Down,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,T1.OperatorID,T1.Catagory,ISNULL(Sum(ISNULL(Down,0)+ISNULL(ML_Time,0)),0) as Down'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.StartDate,T1.EndDate'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate and 
		#ProdData.OperatorID=T2.OperatorID and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)
	   END 

		IF @param='Downcategory'
		Begin
			Select distinct OperatorID,Startdate,Enddate,Substring(Datename(Month,Startdate),1,3) as NameOftheMonth,Catagory,Round(dbo.f_FormatTime(TotalDown,@timeformat),2) as TotalDown from #ProdData
				 order by OperatorID,Startdate,Catagory
		End

       IF @param='DownCode'
		Begin

			IF (Select ValueInInt from CockpitDefaults WHERE Parameter = 'ExcludeTPMTrakDown') = 1
			BEGIN
				Select OperatorID,Startdate,Enddate,Substring(Datename(Month,Startdate),1,3) as NameOftheMonth,Catagory,Code,Round(dbo.f_FormatTime((ISNULL(Down,0)+ISNULL(ML_Time,0)),@timeformat),2) as Down from #ProdData
				 where code not in (select DownId from PredefinedDownCodeInfo) 
				 order by OperatorID,Startdate,Catagory,Code
				return
			End
		    
			ELSE 
			BEGIN

				Select OperatorID,Startdate,Enddate,Substring(Datename(Month,Startdate),1,3) as NameOftheMonth,Catagory,Code,Round(dbo.f_FormatTime((ISNULL(Down,0)+ISNULL(ML_Time,0)),@timeformat),2) as Down from #ProdData
				 order by OperatorID,Startdate,Catagory,Code
				return
			 end
	   END
  END
	--=========================================================================--
		      
		If @ComparisonType='Day' or @ComparisonType='CurrentDay' 
		BEGIN       

		Select @Strsql = 'UPDATE #ProdData SET Down = IsNull(T2.DownTime,0)'    
		Select @Strsql = @Strsql + ' From (select T1.Pdate,T1.OperatorID,T1.Catagory,T1.Code,(Sum(ShiftDownTimeDetails.DownTime))As DownTime'    
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails 
		inner join #Proddata T1 on ShiftDownTimeDetails.OperatorID=T1.OperatorID and T1.catagory=ShiftDownTimeDetails.DownCategory and T1.Code=ShiftDownTimeDetails.Downid    
		where ShiftDownTimeDetails.dDate=T1.Pdate'    
		Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
		Select @Strsql = @Strsql + ' Group By T1.Pdate,T1.OperatorID,T1.Catagory,T1.Code'    
		Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate And #ProdData.OperatorID=T2.OperatorID 
		And #ProdData.Catagory=T2.Catagory And #ProdData.Code=T2.Code'    
		Print @Strsql    
		Exec(@Strsql)  
    

		Select @Strsql = 'UPDATE #ProdData SET Down = isNull(#ProdData.Down,0) - isNull(T2.loss,0) ,
			              ML_Time = isNull(#ProdData.ML_Time,0) + isNull(T2.loss,0) '
		Select @Strsql = @Strsql + 'from (select T1.Pdate,T1.OperatorID,T1.Catagory,T1.Code,sum(
		CASE 
		WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0  
		THEN isnull(ShiftDownTimeDetails.Threshold,0)
		ELSE ShiftDownTimeDetails.DownTime
		END) AS LOSS '
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails 
		INNER JOIN #ProdData T1 on T1.OperatorID = ShiftDowntimeDetails.OperatorID and T1.catagory=ShiftDownTimeDetails.DownCategory and T1.Code = ShiftDowntimeDetails.Downid 
		where ShiftDownTimeDetails.ML_flag = 1 and ShiftDownTimeDetails.dDate=T1.Pdate '		
		Select @Strsql = @Strsql + @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql + ' Group By T1.Pdate,T1.OperatorID,T1.Catagory,T1.Code'
		Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate And #ProdData.OperatorID=T2.OperatorID 
		And #ProdData.Catagory=T2.Catagory And #ProdData.Code=T2.Code'
		Print @Strsql
		Exec(@Strsql)	

		--=========================================================================--

		IF (Select ValueInInt from CockpitDefaults WHERE Parameter = 'ExcludeTPMTrakDown') = 1
		BEGIN
				Select @Strsql = 'UPDATE #ProdData SET TotalDown=ISNULL(TotalDown,0)+ ISNULL(T2.Down,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.Pdate,T1.OperatorID,T1.Catagory,ISNULL(Sum(ISNULL(Down,0)+ISNULL(ML_Time,0)),0) as Down'
		Select @Strsql = @Strsql+' From #ProdData T1
									   where code not in (select DownId from PredefinedDownCodeInfo) '
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.Pdate'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate And 
		#ProdData.OperatorID=T2.OperatorID and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

       END
	   ELSE 
	   BEGIN
	   
		Select @Strsql = 'UPDATE #ProdData SET TotalDown=ISNULL(TotalDown,0)+ ISNULL(T2.Down,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.Pdate,T1.OperatorID,T1.Catagory,ISNULL(Sum(ISNULL(Down,0)+ISNULL(ML_Time,0)),0) as Down'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.Pdate'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate And 
		#ProdData.OperatorID=T2.OperatorID and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)
	   END 

		IF @param='Downcategory'
		Begin
			Select distinct OperatorID,PDate,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day],
			Catagory,Round(dbo.f_FormatTime(TotalDown,@timeformat),2) as TotalDown from #ProdData
				order by OperatorID,PDate,Catagory
		End

       IF @param='DownCode'
		Begin

			IF (Select ValueInInt from CockpitDefaults WHERE Parameter = 'ExcludeTPMTrakDown') = 1
			BEGIN
				Select OperatorID,PDate,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day],
				Catagory,Code,Round(dbo.f_FormatTime((ISNULL(Down,0)+ISNULL(ML_Time,0)),@timeformat),2) as Down from #ProdData
				where code not in (select DownId from PredefinedDownCodeInfo) 
				order by OperatorID,PDate,Catagory,Code
				return
			End
		    
			ELSE 
			BEGIN

					Select OperatorID,PDate,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day],
					Catagory,Code,Round(dbo.f_FormatTime((ISNULL(Down,0)+ISNULL(ML_Time,0)),@timeformat),2) as Down from #ProdData
				order by OperatorID,PDate,Catagory,Code
				return
			 end
	   END
  END
	--=========================================================================--

		If @ComparisonType='Shift' or @ComparisonType='CurrentShift' 
		BEGIN       

		Select @Strsql = 'UPDATE #ProdData SET Down = IsNull(T2.DownTime,0)'    
		Select @Strsql = @Strsql + ' From (select T1.Pdate,T1.Shift,T1.OperatorID,T1.Catagory,T1.Code,(Sum(ShiftDownTimeDetails.DownTime))As DownTime'    
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails 
		inner join #Proddata T1 on ShiftDownTimeDetails.OperatorID=T1.OperatorID and T1.catagory=ShiftDownTimeDetails.DownCategory and T1.Code=ShiftDownTimeDetails.Downid    
		where ShiftDownTimeDetails.dDate=T1.Pdate and ShiftDownTimeDetails.Shift=T1.Shift'    
		Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
		Select @Strsql = @Strsql + ' Group By T1.Pdate,T1.Shift,T1.OperatorID,T1.Catagory,T1.Code'    
		Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate And  #ProdData.Shift=T2.Shift And #ProdData.OperatorID=T2.OperatorID 
		And #ProdData.Catagory=T2.Catagory And #ProdData.Code=T2.Code'    
		Print @Strsql    
		Exec(@Strsql)  
    

		Select @Strsql = 'UPDATE #ProdData SET Down = isNull(#ProdData.Down,0) - isNull(T2.loss,0) ,
			              ML_Time = isNull(#ProdData.ML_Time,0) + isNull(T2.loss,0) '
		Select @Strsql = @Strsql + 'from (select T1.Pdate,T1.Shift,T1.OperatorID,T1.Catagory,T1.Code,sum(
		CASE 
		WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0  
		THEN isnull(ShiftDownTimeDetails.Threshold,0)
		ELSE ShiftDownTimeDetails.DownTime
		END) AS LOSS '
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails 
		INNER JOIN #ProdData T1 on T1.OperatorID = ShiftDowntimeDetails.OperatorID and T1.catagory=ShiftDownTimeDetails.DownCategory and T1.Code = ShiftDowntimeDetails.Downid 
		where ShiftDownTimeDetails.ML_flag = 1 and ShiftDownTimeDetails.dDate=T1.Pdate and ShiftDownTimeDetails.Shift=T1.Shift '		
		Select @Strsql = @Strsql + @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid
		Select @Strsql = @Strsql + ' Group By T1.Pdate,T1.Shift,T1.OperatorID,T1.Catagory,T1.Code'
		Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate And #ProdData.Shift=T2.Shift And #ProdData.OperatorID=T2.OperatorID 
		And #ProdData.Catagory=T2.Catagory And #ProdData.Code=T2.Code'
		Print @Strsql
		Exec(@Strsql)	

	--=========================================================================--

		IF (Select ValueInInt from CockpitDefaults WHERE Parameter = 'ExcludeTPMTrakDown') = 1
		BEGIN
		Select @Strsql = 'UPDATE #ProdData SET TotalDown=ISNULL(TotalDown,0)+ ISNULL(T2.Down,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.Pdate,T1.Shift,T1.OperatorID,T1.Catagory,ISNULL(Sum(ISNULL(Down,0)+ISNULL(ML_Time,0)),0) as Down'
		Select @Strsql = @Strsql+' From #ProdData T1
									   where code not in (select DownId from PredefinedDownCodeInfo) '
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.Pdate,T1.Shift'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate And #ProdData.Shift=T2.Shift And 
		#ProdData.OperatorID=T2.OperatorID and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)

       END
	   ELSE 
	   BEGIN
	   
		Select @Strsql = 'UPDATE #ProdData SET TotalDown=ISNULL(TotalDown,0)+ ISNULL(T2.Down,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.Pdate,T1.Shift,T1.OperatorID,T1.Catagory,ISNULL(Sum(ISNULL(Down,0)+ISNULL(ML_Time,0)),0) as Down'
		Select @Strsql = @Strsql+' From #ProdData T1'
		Select @Strsql = @Strsql+' Group By T1.OperatorID,T1.Catagory,T1.Pdate,T1.Shift'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Pdate=T2.Pdate And #ProdData.Shift=T2.Shift And 
		#ProdData.OperatorID=T2.OperatorID and #ProdData.Catagory=T2.Catagory'
		Print @Strsql
		Exec(@Strsql)
	   END 

		IF @param='Downcategory'
		Begin
			Select distinct OperatorID,PDate,Shift,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day],Catagory,Round(dbo.f_FormatTime(TotalDown,@timeformat),2) as TotalDown from #ProdData
				order by OperatorID,PDate,Shift,Catagory
		End

       IF @param='DownCode'
		Begin

			IF (Select ValueInInt from CockpitDefaults WHERE Parameter = 'ExcludeTPMTrakDown') = 1
			BEGIN
				Select OperatorID,PDate,Shift,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day],Catagory,Code,Round(dbo.f_FormatTime((ISNULL(Down,0)+ISNULL(ML_Time,0)),@timeformat),2) as Down from #ProdData
				where code not in (select DownId from PredefinedDownCodeInfo)
				order by OperatorID,PDate,Shift,Catagory,Code
				return
			End
		    
			ELSE 
			BEGIN

				Select OperatorID,PDate,Shift,RIGHT('0' + Cast(Month(Pdate) as nvarchar(2)),2) as [Month],RIGHT('0' + Cast(Day(Pdate) as nvarchar(2)),2) as [Day],Catagory,Code,Round(dbo.f_FormatTime((ISNULL(Down,0)+ISNULL(ML_Time,0)),@timeformat),2) as Down from #ProdData
				order by OperatorID,PDate,Shift,Catagory,Code
				return
			 end
	   END
  END
	--=========================================================================--

END
       
END 
