/****** Object:  Procedure [dbo].[s_GetAggDrilldownPPM1stLevelDetails]    Committed by VersionSQL https://www.versionsql.com ******/

 
 
/*
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2019-01-01','','','','','','year','machinewise','','IgnoreCOMPONENTOPERATION' /* combine machines   */
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2019-01-01','','','','','','year','operatorwise' /* combine operators  */  
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2019-01-01','','','','','','year','componentwise'/* combine components */   
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2016-01-01','','','','','','year','plantwise'
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2016-01-01','','','','1ST  DRIVEN 36T','KARMAVEER','year'    
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2016-01-01','','','','','KARMAVEER','year'    
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2016-01-01','','','','','','year'    
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2016-01-01','','','','','','plantsyear'    
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2016-01-01','','','LBR HOBBING-A','1ST  DRIVEN 36T','','month'    
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2017-01-01','','','CNC Grinding','50 SHANK','','month'          
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2019-01-01','','','J300-1','','','year','Machinewise'  
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2019-01-01','','','','A02-L02 - I','','year'
exec [dbo].[s_GetAggDrilldownPPM1stLevelDetails] '2019-01-01','','','','','','Day','Cellwise' ,'cell2'   

*/     
CREATE PROCEDURE [dbo].[s_GetAggDrilldownPPM1stLevelDetails]      
 @StartDate As DateTime,      
 @ShiftName As NVarChar(50)='',      
 @PlantID As NVarChar(50)='',      
 @MachineID As nvarchar(50),      
 @Component As nvarchar(50)='', 
 @Employee As nvarchar(50)='',             
 @ComparisonType As nvarchar(50)='', -- year,month,day
 @View AS nvarchar(50)='Machinewise', -- Machinewise, Operatorwise, Componentwise
 @Groupid as nvarchar(50)='' ,
 @IgnoreMCO nvarchar(50)=''
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
ProdCount float DEFAULT 0,  
RejCount  float DEFAULT 0,  
AcceptedParts Int DEFAULT 0,  
Month nvarchar(10),
Day nvarchar(10),
MachineDescription NVarChar(150),
PPM float default 0  
)

create table #Plantsdata
(
Plantid nvarchar(50),
ComponentID nvarchar(50),
Operationno nvarchar(50),
ProdCount float DEFAULT 0,  
RejCount  float DEFAULT 0,  
AcceptedParts Int DEFAULT 0,  
Month nvarchar(10),
Day nvarchar(10),
PPM float default 0  
)

If @View='Plantwise'
BEGIN
 IF @ComparisonType='Year'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,ProdCount,AcceptedParts) '      
 Select @Strsql = @Strsql + 'Select S.PlantID, S.ComponentID,S.Operationno,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0))    
 From ShiftProductionDetails S where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')'
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.PlantID,S.ComponentID,S.Operationno Order by S.PlantID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)    
 
  select @strsql=''
 Select @Strsql = 'UPDATE #Plantsdata SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.Plantid,T1.ComponentID,T1.Operationno,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails S inner Join #Plantsdata T1 on T1.Plantid = S.Plantid  
		  and T1.ComponentID = S.ComponentID and T1.Operationno = S.Operationno  
          Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.Plantid,T1.ComponentID,T1.Operationno'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #Plantsdata ON #Plantsdata.Plantid=T2.Plantid and #Plantsdata.ComponentID=T2.ComponentID and #Plantsdata.Operationno=T2.Operationno '  
 Print @Strsql  
 Exec(@Strsql)    
 END

 IF @ComparisonType='Month'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,ProdCount,AcceptedParts) '      
 Select @Strsql = @Strsql + 'Select S.PlantID, S.ComponentID,S.Operationno,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0))     
 From ShiftProductionDetails S where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
 and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.PlantID,S.ComponentID,S.Operationno Order by S.PlantID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)   
 
 select @strsql=''
 Select @Strsql = 'UPDATE #Plantsdata SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.Plantid,T1.ComponentID,T1.Operationno,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails S inner Join #Plantsdata T1 on T1.PlantID = S.PlantID  
		  and T1.ComponentID = S.ComponentID and T1.Operationno = S.Operationno  
          Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
 and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.Plantid,T1.ComponentID,T1.Operationno'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #Plantsdata ON #Plantsdata.PlantID=T2.PlantID and #Plantsdata.ComponentID=T2.ComponentID and #Plantsdata.Operationno=T2.Operationno '  
 Print @Strsql  
 Exec(@Strsql)   
 END

 IF @ComparisonType='Day'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,ProdCount,AcceptedParts) '      
 Select @Strsql = @Strsql + 'Select S.PlantID, S.ComponentID,S.Operationno,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0))     
 From ShiftProductionDetails S where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.PlantID,S.ComponentID,S.Operationno Order by S.PlantID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)    
 
 select @strsql=''
 Select @Strsql = 'UPDATE #Plantsdata SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.Plantid,T1.ComponentID,T1.Operationno,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails S inner Join #Plantsdata T1 on T1.PlantID = S.PlantID  
		  and T1.ComponentID = S.ComponentID and T1.Operationno = S.Operationno  
          Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.Plantid,T1.ComponentID,T1.Operationno'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #Plantsdata ON #Plantsdata.PlantID=T2.PlantID and #Plantsdata.ComponentID=T2.ComponentID and #Plantsdata.Operationno=T2.Operationno '  
 Print @Strsql  
 Exec(@Strsql)  
 END

 update #Plantsdata set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

	IF @IgnoreMCO=''
	begin
		 Select Plantid,ComponentID,Operationno,ISNULL(AcceptedParts,0) as AcceptedParts,ISNULL(RejCount,0) as RejectedParts,round(PPM,2) as PPM from #Plantsdata
		 where RejCount>0  order by PlantID,ComponentID,Operationno
	 end
END

ELSE If @View='Cellwise'
BEGIN
 IF @ComparisonType='Year'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,ProdCount,AcceptedParts) '      
 Select @Strsql = @Strsql + 'Select S.GroupID, S.ComponentID,S.Operationno,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0))   
 From ShiftProductionDetails S where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')'
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.GroupID,S.ComponentID,S.Operationno Order by S.GroupID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)  
 
 select @strsql=''
 Select @Strsql = 'UPDATE #Plantsdata SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.Plantid,T1.ComponentID,T1.Operationno,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails S inner Join #Plantsdata T1 on T1.PlantID = S.GroupID  
		  and T1.ComponentID = S.ComponentID and T1.Operationno = S.Operationno  
          Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.Plantid,T1.ComponentID,T1.Operationno'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #Plantsdata ON #Plantsdata.PlantID=T2.PlantID and #Plantsdata.ComponentID=T2.ComponentID and #Plantsdata.Operationno=T2.Operationno '  
 Print @Strsql  
 Exec(@Strsql)     
 END

 IF @ComparisonType='Month'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,ProdCount,AcceptedParts) '      
 Select @Strsql = @Strsql + 'Select S.GroupID, S.ComponentID,S.Operationno,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0))     
 From ShiftProductionDetails S where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
 and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.GroupID,S.ComponentID,S.Operationno Order by S.GroupID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)   
  
 select @strsql=''
 Select @Strsql = 'UPDATE #Plantsdata SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.Plantid,T1.ComponentID,T1.Operationno,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails S inner Join #Plantsdata T1 on T1.PlantID = S.GroupID  
		  and T1.ComponentID = S.ComponentID and T1.Operationno = S.Operationno  
          Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
 and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.Plantid,T1.ComponentID,T1.Operationno'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #Plantsdata ON #Plantsdata.PlantID=T2.PlantID and #Plantsdata.ComponentID=T2.ComponentID and #Plantsdata.Operationno=T2.Operationno '  
 Print @Strsql  
 Exec(@Strsql)  
    
 END

 IF @ComparisonType='Day'
 BEGIN
 select @strsql='' 
 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,ProdCount,AcceptedParts) '      
 Select @Strsql = @Strsql + 'Select S.GroupID, S.ComponentID,S.Operationno,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0))   
 From ShiftProductionDetails S where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
 Select @Strsql = @Strsql+  ' GROUP By S.GroupID,S.ComponentID,S.Operationno Order by S.GroupID,S.ComponentID,S.Operationno'
 Print @Strsql      
 Exec(@Strsql)   
 
  select @strsql=''
 Select @Strsql = 'UPDATE #Plantsdata SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.Plantid,T1.ComponentID,T1.Operationno,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails S inner Join #Plantsdata T1 on T1.PlantID = S.GroupID  
		  and T1.ComponentID = S.ComponentID and T1.Operationno = S.Operationno  
          Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.Plantid,T1.ComponentID,T1.Operationno'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #Plantsdata ON #Plantsdata.PlantID=T2.PlantID and #Plantsdata.ComponentID=T2.ComponentID and #Plantsdata.Operationno=T2.Operationno '  
 Print @Strsql  
 Exec(@Strsql)     
 END

 update #Plantsdata set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

 IF @IgnoreMCO=''
 begin
	 Select Plantid,ComponentID,Operationno,ISNULL(AcceptedParts,0) as AcceptedParts,ISNULL(RejCount,0) as RejectedParts,round(PPM,2) as PPM from #Plantsdata
	 where RejCount>0 order by PlantID,ComponentID,Operationno
 END

END

ELSE
BEGIN 
If @ComparisonType='Year'      
BEGIN      
select @strsql='' 
Select @Strsql = 'Insert into #ProdData(Machineid,ComponentID,Operationno,Prodcount,AcceptedParts) '      
Select @Strsql = @Strsql + 'Select S.Machineid,S.ComponentID,S.Operationno, Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)) 
From ShiftProductionDetails S 
where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')'
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
Select @Strsql = @Strsql+  ' GROUP By S.Machineid,S.ComponentID,S.Operationno Order by S.Machineid,S.ComponentID,S.Operationno'
Print @Strsql      
Exec(@Strsql)

select @strsql=''
Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
Select @Strsql = @Strsql+' FROM('  
Select @Strsql = @Strsql+' Select T1.Machineid,T1.ComponentID,T1.Operationno,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
Select @Strsql = @Strsql+' From ShiftProductionDetails S inner Join #ProdData T1 on T1.machineid = S.machineid  
		and T1.ComponentID = S.ComponentID and T1.Operationno = S.Operationno  
        Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
Select @Strsql = @Strsql+' Group By T1.Machineid,T1.ComponentID,T1.Operationno'  
Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID and #ProdData.ComponentID=T2.ComponentID and #ProdData.Operationno=T2.Operationno '  
Print @Strsql  
Exec(@Strsql)    

END      
       
      
If @ComparisonType='Month' 
BEGIN      
      
select @strsql='' 
Select @Strsql = 'Insert into #ProdData(Machineid,ComponentID,Operationno,Prodcount,AcceptedParts) '      
Select @Strsql = @Strsql + 'Select S.Machineid,S.ComponentID,S.Operationno,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)) 
From ShiftProductionDetails S where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid      
Select @Strsql = @Strsql+  ' GROUP By S.Machineid,S.ComponentID,S.Operationno Order by S.Machineid,S.ComponentID,S.Operationno'
Print @Strsql      
Exec(@Strsql) 

 select @strsql=''
 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.Machineid,T1.ComponentID,T1.Operationno,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails S inner Join #ProdData T1 on T1.Machineid = S.Machineid  
		  and T1.ComponentID = S.ComponentID and T1.Operationno = S.Operationno  
          Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
 and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.Machineid,T1.ComponentID,T1.Operationno'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Machineid=T2.Machineid and #ProdData.ComponentID=T2.ComponentID and #ProdData.Operationno=T2.Operationno '  
 Print @Strsql  
 Exec(@Strsql)  
END      
      
If @ComparisonType='Day' 
BEGIN      
      
select @strsql='' 
Select @Strsql = 'Insert into #ProdData(Machineid,ComponentID,Operationno,Prodcount,AcceptedParts) '      
Select @Strsql = @Strsql + 'Select S.Machineid,S.ComponentID,S.Operationno, Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)) 
From ShiftProductionDetails S where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift + @StrComponent + @StrEmployee + @StrGroupid    
Select @Strsql = @Strsql+  ' GROUP By S.Machineid,S.ComponentID,S.Operationno Order by S.Machineid,S.ComponentID,S.Operationno'
Print @Strsql      
Exec(@Strsql) 

select @strsql=''
Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
Select @Strsql = @Strsql+' FROM('  
Select @Strsql = @Strsql+' Select T1.Machineid,T1.ComponentID,T1.Operationno,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
Select @Strsql = @Strsql+' From ShiftProductionDetails S inner Join #ProdData T1 on T1.Machineid = S.Machineid  
		and T1.ComponentID = S.ComponentID and T1.Operationno = S.Operationno  
        Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
Select @Strsql = @Strsql+' Where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '  
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
Select @Strsql = @Strsql+' Group By T1.Machineid,T1.ComponentID,T1.Operationno'  
Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Machineid=T2.Machineid and #ProdData.ComponentID=T2.ComponentID and #ProdData.Operationno=T2.Operationno '  
Print @Strsql  
Exec(@Strsql)     
END      

IF @View = 'Machinewise' and @IgnoreMCO=''
begin

Select ComponentID,Operationno,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #ProdData
group by ComponentID,Operationno
having(SUM(RejCount))>0
order by ComponentID,Operationno
end

IF @View = 'Operatorwise' and @IgnoreMCO=''
begin

Select ComponentID,Operationno,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #ProdData
inner join machineinformation on #Proddata.Machineid=machineinformation.machineid
group by ComponentID,Operationno
having(SUM(RejCount))>0
order by ComponentID,Operationno

end

IF @View = 'Componentwise' and @IgnoreMCO=''
begin

Select #ProdData.MachineID,Operationno,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #ProdData 
inner join machineinformation on #Proddata.Machineid=machineinformation.machineid
group by #ProdData.MachineID,Operationno
having(SUM(RejCount))>0
order by #ProdData.MachineID,Operationno

end       
END

IF (@View='Plantwise' or @View='Cellwise') and @IgnoreMCO<>''
BEGIN

	If @IgnoreMCO='IgnoreComponent'
	Begin
		Select Operationno,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
		ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #Plantsdata
		group by Operationno
		having(SUM(RejCount))>0
		order by Operationno
	END
	If @IgnoreMCO='IgnoreOperation'
	Begin
		Select ComponentID,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
		ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #Plantsdata
		group by ComponentID
		having(SUM(RejCount))>0
		order by ComponentID
	END
	If @IgnoreMCO='IgnoreComponentOperation'
	Begin
		Select SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
		ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #Plantsdata
		having(SUM(RejCount))>0
	END
END

IF (@View = 'Machinewise' or @View = 'Operatorwise') and @IgnoreMCO<>''
BEGIN

	If @IgnoreMCO='IgnoreComponent'
	Begin
		Select Operationno,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
		ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #ProdData
		group by Operationno
		having(SUM(RejCount))>0
		order by Operationno
	END
	If @IgnoreMCO='IgnoreOperation'
	Begin
		Select ComponentID,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
		ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #ProdData
		group by ComponentID
		having(SUM(RejCount))>0
		order by ComponentID
	END
	If @IgnoreMCO='IgnoreComponentOperation'
	Begin
		Select SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
		ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #ProdData
		having(SUM(RejCount))>0
	END
END


IF @View = 'Componentwise' and @IgnoreMCO<>''
BEGIN
	If @IgnoreMCO='IgnoreMachine'
	Begin
		Select Operationno,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
		ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #ProdData
		group by Operationno
		having(SUM(RejCount))>0
		order by Operationno
	END
	If @IgnoreMCO='IgnoreOperation'
	Begin
		Select MachineID,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
		ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #ProdData
		group by MachineID
		having(SUM(RejCount))>0
		order by MachineID
	END
	If @IgnoreMCO='IgnoreMachineOperation'
	Begin
		Select SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejectedParts,
		ROUND((isnull(SUM(RejCount),0)/ISNULL(SUM(ProdCount),0))*1000000,2) as PPM from #ProdData
		having(SUM(RejCount))>0
	END
END

 
END
