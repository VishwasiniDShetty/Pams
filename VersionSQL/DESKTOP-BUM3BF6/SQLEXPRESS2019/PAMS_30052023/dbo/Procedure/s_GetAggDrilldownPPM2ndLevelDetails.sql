/****** Object:  Procedure [dbo].[s_GetAggDrilldownPPM2ndLevelDetails]    Committed by VersionSQL https://www.versionsql.com ******/

 
 
/*
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2019-01-01','','','','','','year','machinewise'  /* combine machines   */
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2019-01-01','','','','','','year','operatorwise' /* combine operators  */  
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2019-01-01','','','','','','year','componentwise'/* combine components */   
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2016-01-01','','','','','','year','plantwise'
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2016-01-01','','','','1ST  DRIVEN 36T','KARMAVEER','year'    
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2016-01-01','','','','','KARMAVEER','year'    
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2016-01-01','','','','','','year'    
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2016-01-01','','','','','','plantsyear'    
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2016-01-01','','','LBR HOBBING-A','1ST  DRIVEN 36T','','month'    
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2017-01-01','','','CNC Grinding','50 SHANK','','month'          
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2019-01-01','','','J300-1','','','year','Machinewise'  
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2019-01-01','','','','A02-L02 - I','','year'
exec [dbo].[s_GetAggDrilldownPPM2ndLevelDetails] '2019-01-01','','','','','','year','Cellwise'    

*/     
CREATE PROCEDURE [dbo].[s_GetAggDrilldownPPM2ndLevelDetails]      
 @StartDate As DateTime,      
 @ShiftName As NVarChar(50)='',      
 @PlantID As NVarChar(50)='',      
 @MachineID As nvarchar(50),      
 @Component As nvarchar(50)='', 
 @Operation As nvarchar(50)='', 
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
Declare @StrOperation as nvarchar(255)
Declare @StrEmployee as nvarchar(255)   
Declare @StrGroupid as nvarchar(255)    

    
Select @Strsql = ''      
Select @Strmachine = ''      
Select @StrPlantID=''      
Select @StrShift=''      
Select @StrComponent=''
Select @StrEmployee=''
Select @StrGroupid=''   
Select @StrOperation=''
        
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

If isnull(@Operation,'') <> ''  
Begin  
 Select @StrOperation = ' And ( S.Operationno = N''' + @Operation + ''')'  
End
 
create table #Proddata
(
Machineid nvarchar(50),
ComponentID nvarchar(50),
Operationno nvarchar(50),
OperatorID nvarchar(50),
RejectionID nvarchar(50),
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
RejectionID nvarchar(50),
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
		 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,RejectionID,ProdCount,AcceptedParts,RejCount)'  
		 Select @Strsql = @Strsql+' Select S.Plantid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)),Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))'  
		 Select @Strsql = @Strsql+' From ShiftProductionDetails S 
				  Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
		 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
		 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrOperation + @StrGroupid  
		 Select @Strsql = @Strsql+' Group By S.Plantid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason'  
		 Print @Strsql  
		 Exec(@Strsql)     
	 END
	 IF @ComparisonType='Month'
	 BEGIN
		 select @strsql=''
		 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,RejectionID,ProdCount,AcceptedParts,RejCount)'  
		 Select @Strsql = @Strsql+' Select S.Plantid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)),Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))'  
		 Select @Strsql = @Strsql+' From ShiftProductionDetails S 
				  Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
		 Select @Strsql = @Strsql+' Where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
		 and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
		 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrOperation + @StrGroupid  
		 Select @Strsql = @Strsql+' Group By S.Plantid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason'  
		 Print @Strsql  
		 Exec(@Strsql)     
	 END
	 IF @ComparisonType='Day'
	 BEGIN
		 select @strsql=''
		 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,RejectionID,ProdCount,AcceptedParts,RejCount)'  
		 Select @Strsql = @Strsql+' Select S.Plantid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)),Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))'  
		 Select @Strsql = @Strsql+' From ShiftProductionDetails S 
				  Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
		 Select @Strsql = @Strsql+' Where  ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '  
		 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrOperation + @StrGroupid  
		 Select @Strsql = @Strsql+' Group By S.Plantid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason'  
		 Print @Strsql  
		 Exec(@Strsql)
	 END

	IF @operation='' and @Component<>''
	Begin
		Select P.ComponentID,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
		ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #Plantsdata P
		inner join(select ComponentID,SUM(ProdCount) as ProdCount from #Plantsdata group by ComponentID)T on T.ComponentID=P.ComponentID
		group by P.ComponentID,P.RejectionID
		having(SUM(P.RejCount))>0
		order by P.ComponentID,P.RejectionID
	END
	IF @Component='' and @operation<>''
	Begin
		Select P.Operationno,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
		ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #Plantsdata P
		inner join(select Operationno,SUM(ProdCount) as ProdCount from #Plantsdata group by Operationno)T on T.Operationno=P.Operationno
		group by P.Operationno,P.RejectionID
		having(SUM(P.RejCount))>0
		order by P.Operationno,P.RejectionID
	END
	Else
	Begin
		Select P.Plantid,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
		ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #Plantsdata P
		inner join(select Plantid,SUM(ProdCount) as ProdCount from #Plantsdata group by Plantid)T on T.Plantid=P.Plantid
		group by P.Plantid,P.RejectionID
		having(SUM(P.RejCount))>0
		order by P.Plantid,P.RejectionID
	END
END

ELSE If @View='Cellwise'
BEGIN
	 IF @ComparisonType='Year'
	 BEGIN
		 select @strsql=''
		 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,RejectionID,ProdCount,AcceptedParts,RejCount)'  
		 Select @Strsql = @Strsql+' Select S.Groupid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)),Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))'  
		 Select @Strsql = @Strsql+' From ShiftProductionDetails S 
				  Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
		 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
		 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent+ @StrOperation + @StrGroupid  
		 Select @Strsql = @Strsql+' Group By S.Groupid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason'  
		 Print @Strsql  
		 Exec(@Strsql)     
	 END
	 IF @ComparisonType='Month'
	 BEGIN
		 select @strsql=''
		 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,RejectionID,ProdCount,AcceptedParts,RejCount)'  
		 Select @Strsql = @Strsql+' Select S.Groupid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)),Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))'  
		 Select @Strsql = @Strsql+' From ShiftProductionDetails S 
				  Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
		 Select @Strsql = @Strsql+' Where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
		 and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
		 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent+ @StrOperation + @StrGroupid  
		 Select @Strsql = @Strsql+' Group By S.Groupid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason'  
		 Print @Strsql  
		 Exec(@Strsql)     
	 END
	 IF @ComparisonType='Day'
	 BEGIN
		 select @strsql=''
		 Select @Strsql = 'Insert into #Plantsdata(Plantid,ComponentID,Operationno,RejectionID,ProdCount,AcceptedParts,RejCount)'  
		 Select @Strsql = @Strsql+' Select S.Groupid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)),Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))'  
		 Select @Strsql = @Strsql+' From ShiftProductionDetails S 
				  Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
		 Select @Strsql = @Strsql+' Where  ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '  
		 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent+ @StrOperation + @StrGroupid  
		 Select @Strsql = @Strsql+' Group By S.Groupid,S.ComponentID,S.Operationno,ShiftRejectionDetails.Rejection_Reason'  
		 Print @Strsql  
		 Exec(@Strsql)
	 END

	IF @operation='' and @Component<>''
	Begin
		Select P.ComponentID,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
		ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #Plantsdata P
		inner join(select ComponentID,SUM(ProdCount) as ProdCount from #Plantsdata group by ComponentID)T on T.ComponentID=P.ComponentID
		group by P.ComponentID,P.RejectionID
		having(SUM(P.RejCount))>0
		order by P.ComponentID,P.RejectionID
	END
	IF @Component='' and @operation<>''
	Begin
		Select P.Operationno,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
		ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #Plantsdata P
		inner join(select Operationno,SUM(ProdCount) as ProdCount from #Plantsdata group by Operationno)T on T.Operationno=P.Operationno
		group by P.Operationno,P.RejectionID
		having(SUM(P.RejCount))>0
		order by P.Operationno,P.RejectionID
	END
	Else
	Begin
		Select P.Plantid,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
		ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #Plantsdata P
		inner join(select Plantid,SUM(ProdCount) as ProdCount from #Plantsdata group by Plantid)T on T.Plantid=P.Plantid
		group by P.Plantid,P.RejectionID
		having(SUM(P.RejCount))>0
		order by P.Plantid,P.RejectionID
	END

END

ELSE
BEGIN 
	If @ComparisonType='Year'      
	BEGIN      
		select @strsql=''
		Select @Strsql = 'Insert into #ProdData(Machineid,ComponentID,Operationno,OperatorID,RejectionID,ProdCount,AcceptedParts,RejCount)'  
		Select @Strsql = @Strsql+' Select S.Machineid,S.ComponentID,S.Operationno,S.OperatorID,ShiftRejectionDetails.Rejection_Reason,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)),Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))'  
		Select @Strsql = @Strsql+' From ShiftProductionDetails S 
				Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
		Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
		Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent+ @StrOperation + @StrGroupid  
		Select @Strsql = @Strsql+' Group By S.Machineid,S.ComponentID,S.Operationno,S.OperatorID,ShiftRejectionDetails.Rejection_Reason'  
		Print @Strsql  
		Exec(@Strsql)
	END                  
	If @ComparisonType='Month' 
	BEGIN      
		select @strsql=''
		Select @Strsql = 'Insert into #ProdData(Machineid,ComponentID,Operationno,OperatorID,RejectionID,ProdCount,AcceptedParts,RejCount)'  
		Select @Strsql = @Strsql+' Select S.Machineid,S.ComponentID,S.Operationno,S.OperatorID,ShiftRejectionDetails.Rejection_Reason,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)),Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))'  
		Select @Strsql = @Strsql+' From ShiftProductionDetails S 
		Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
		Select @Strsql = @Strsql+' Where Datepart(YEAR,S.pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120) + ''')
		and Datepart(Month,S.pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
		Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent+ @StrOperation + @StrGroupid  
		Select @Strsql = @Strsql+' Group By S.Machineid,S.ComponentID,S.Operationno,S.OperatorID,ShiftRejectionDetails.Rejection_Reason'  
		Print @Strsql  
		Exec(@Strsql)
	END           
	If @ComparisonType='Day' 
	BEGIN      
		 select @strsql=''
		 Select @Strsql = 'Insert into #ProdData(Machineid,ComponentID,Operationno,OperatorID,RejectionID,ProdCount,AcceptedParts,RejCount)'  
		 Select @Strsql = @Strsql+' Select S.Machineid,S.ComponentID,S.Operationno,S.OperatorID,ShiftRejectionDetails.Rejection_Reason,Sum(ISNULL(S.Prod_Qty,0)),Sum(ISNULL(S.AcceptedParts,0)),Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))'  
		 Select @Strsql = @Strsql+' From ShiftProductionDetails S 
				  Left Outer Join ShiftRejectionDetails ON S.ID=ShiftRejectionDetails.ID'  
		 Select @Strsql = @Strsql+' Where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),S.Pdate,120) '  
		 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent+ @StrOperation + @StrGroupid  
		 Select @Strsql = @Strsql+' Group By S.Machineid,S.ComponentID,S.Operationno,S.OperatorID,ShiftRejectionDetails.Rejection_Reason'  
		 Print @Strsql  
		 Exec(@Strsql)
	END      

	IF @View = 'Machinewise' 
	begin
		IF @operation='' and @Component<>''
		Begin
			Select P.ComponentID,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
			ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #ProdData P
			inner join(select ComponentID,SUM(ProdCount) as ProdCount from #ProdData group by ComponentID)T on T.ComponentID=P.ComponentID
			group by P.ComponentID,P.RejectionID
			having(SUM(P.RejCount))>0
			order by P.ComponentID,P.RejectionID
		END
		IF @Component='' and @operation<>''
		Begin
			Select P.Operationno,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
			ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #ProdData P
			inner join(select Operationno,SUM(ProdCount) as ProdCount from #ProdData group by Operationno)T on T.Operationno=P.Operationno
			group by P.Operationno,P.RejectionID
			having(SUM(P.RejCount))>0
			order by P.Operationno,P.RejectionID
		END
		Else
		Begin
			Select P.MachineID,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
			ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #ProdData P
			inner join(select MachineID,SUM(ProdCount) as ProdCount from #ProdData group by MachineID)T on T.MachineID=P.MachineID
			group by P.MachineID,P.RejectionID
			having(SUM(P.RejCount))>0
			order by P.MachineID,P.RejectionID
		END
	END
	IF @View = 'Operatorwise' 
	begin

		IF @operation='' and @Component<>''
		Begin
			Select P.ComponentID,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
			ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #ProdData P
			inner join(select ComponentID,SUM(ProdCount) as ProdCount from #ProdData group by ComponentID)T on T.ComponentID=P.ComponentID
			group by P.ComponentID,P.RejectionID
			having(SUM(P.RejCount))>0
			order by P.ComponentID,P.RejectionID
		END
		IF @Component='' and @operation<>''
		Begin
			Select P.Operationno,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
			ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #ProdData P
			inner join(select Operationno,SUM(ProdCount) as ProdCount from #ProdData group by Operationno)T on T.Operationno=P.Operationno
			group by P.Operationno,P.RejectionID
			having(SUM(P.RejCount))>0
			order by P.Operationno,P.RejectionID
		END
		Else
		Begin
			Select P.OperatorID,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
			ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #ProdData P
			inner join(select OperatorID,SUM(ProdCount) as ProdCount from #ProdData group by OperatorID)T on T.OperatorID=P.OperatorID
			group by P.OperatorID,P.RejectionID
			having(SUM(P.RejCount))>0
			order by P.OperatorID,P.RejectionID
		END
	END
	IF @View = 'Componentwise'
	begin

		IF @MachineID<>'' and @Operation=''
		Begin
			Select P.MachineID,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
			ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #ProdData P
			inner join(select MachineID,SUM(ProdCount) as ProdCount from #ProdData group by MachineID)T on T.MachineID=P.MachineID
			group by P.MachineID,P.RejectionID
			having(SUM(P.RejCount))>0
			order by P.MachineID,P.RejectionID
		END
		IF @MachineID='' and @Operation<>''
		Begin
			Select P.Operationno,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
			ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #ProdData P
			inner join(select Operationno,SUM(ProdCount) as ProdCount from #ProdData group by Operationno)T on T.Operationno=P.Operationno
			group by P.Operationno,P.RejectionID
			having(SUM(P.RejCount))>0
			order by P.Operationno,P.RejectionID
		END
		Else
		Begin
			Select P.ComponentID,P.RejectionID,isnull(SUM(P.RejCount),0) as RejCount,
			ROUND((isnull(SUM(P.RejCount),0)/ISNULL(sum(T.ProdCount),0))*1000000,2) as PPM from #ProdData P
			inner join machineinformation on P.Machineid=machineinformation.machineid
			inner join(select ComponentID,SUM(ProdCount) as ProdCount from #ProdData group by ComponentID)T on T.ComponentID=P.ComponentID
			group by P.ComponentID,P.RejectionID
			having(SUM(P.RejCount))>0
			order by P.ComponentID,P.RejectionID
		END
	END
       
END


END
