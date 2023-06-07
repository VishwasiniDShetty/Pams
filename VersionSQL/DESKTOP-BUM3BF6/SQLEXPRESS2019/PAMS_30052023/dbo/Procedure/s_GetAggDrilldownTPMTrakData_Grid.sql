/****** Object:  Procedure [dbo].[s_GetAggDrilldownTPMTrakData_Grid]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetAggDrilldownTPMTrakData_Grid] '2019-01-01','','','','','','YEAR','','cellwiseView','cell-2'  
--[dbo].[s_GetAggDrilldownTPMTrakData_Grid] '2019-01-01','','GNA AXLE II','','','','YEAR','','PlantwiseView','Group-3'  
--[dbo].[s_GetAggDrilldownTPMTrakData_Grid] '2019-01-01','first','','','','','YEAR','','MachinewiseView','Group-3'    
  
--[dbo].[s_GetAggDrilldownTPMTrakData_Grid] '2019-01-01','','','','','','MONTH','','MachinewiseView','Group-3'   
--[dbo].[s_GetAggDrilldownTPMTrakData_Grid] '2019-01-01','first','','','','','MONTH','','MachinewiseView','Group-3'    
  
--[dbo].[s_GetAggDrilldownTPMTrakData_Grid]  '2020-05-05','','','ACE-01','','','year','','MachinewiseView','' 
--[dbo].[s_GetAggDrilldownTPMTrakData_Grid]  '2020-01-19','','','ACE-02','','','day','','MachinewiseView',''  
--[dbo].[s_GetAggDrilldownTPMTrakData_Grid]  '2020-08-10','','','KI/HMC-05','','','day','','PlantwiseView',''
--[dbo].[s_GetAggDrilldownTPMTrakData_Grid]  '2020-08-10','','','KI/HMC-05','','','day','','CellwiseView',''
--[dbo].[s_GetAggDrilldownTPMTrakData_Grid] '2019-01-01','first','','','','','DAY','','MachinewiseView','Group-3'  

CREATE   PROCEDURE [dbo].[s_GetAggDrilldownTPMTrakData_Grid]  
 @StartDate As DateTime,  
 @ShiftName As NVarChar(50)='',  
 @PlantID As NVarChar(50)='',  
 @MachineID As nvarchar(50) = '',  
 @Component As nvarchar(50)='',   
 @Employee As nvarchar(50)='',    
 @ComparisonType As nvarchar(20), /*SHIFT,DAY,MONTH,YEAR*/  
 @Parameter As nvarchar(50)='', /* All KPIs,Parts Count,Down Time, AE, PE, OE ,QE,Rej Count */  
 @view nvarchar(50)='', --MachinewiseView or PlantwiseView
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
  
Declare @CurDate As DateTime  
Declare @StratOfMonth As DateTime  
Declare @EndOfMonth As DateTime  
Declare @AddMonth As DateTime  
  
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
 Select @StrGroupid = ' And ( PlantMachineGroups.GroupID = N''' + @GroupID + ''')'  
End 
  
SELECT @timeformat ='mm'  
  
Select @timeformat = isnull((select valueintext2 from CockpitDefaults where parameter='TPMTrakAppSettings' and ValueinText='Downtime'),'mm')  
if (@timeformat <>'hh' and @timeformat <>'mm')  
begin  
 select @timeformat = 'mm'  
end    
      
  
  
Create Table #ProdData  
(  
 MachineID  NVarChar(50),
 machineDescription NVarChar(50), 
 ProdCount float DEFAULT 0,  
 AcceptedParts float DEFAULT 0,  
 RejCount  float DEFAULT 0,  
 ReworkPerformed float DEFAULT 0,  
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
 
 Create Table #PlantLevelDetails 
(  
 PlantID  NVarChar(50),  
 ProdCount float DEFAULT 0,  
 AcceptedParts float DEFAULT 0,  
 RejCount  float DEFAULT 0,  
 ReworkPerformed float DEFAULT 0,  
 MarkedForRework Int DEFAULT 0,  
 AEffy  Float DEFAULT 0,  
 PEffy  Float DEFAULT 0,  
 QEffy  Float DEFAULT 0,  
 OEffy  Float DEFAULT 0,  
 UtilisedTime  Float DEFAULT 0,  
 DownTime  Float DEFAULT 0,  
 CN  Float DEFAULT 0,  
 ManagementLoss float default 0,  
 DowntimeAE float default 0 ,
 PPM float default 0  ,
 McHrRate float default 0,
 AvgMcHrRate float default 0
)   
  
CREATE TABLE #MachineInfo   
(  
MachineID nvarchar(50)PRIMARY KEY ,
machineDescription NVarChar(150)  
)  
  
  
  
Select @Strsql =''  
Select @Strsql ='Insert Into #MachineInfo(MachineID,machineDescription)'  
Select @Strsql =@Strsql+' Select   Distinct MachineInformation.MachineID,machineinformation.Description From MachineInformation'  
Select @Strsql =@Strsql+' Left Outer Join PlantMachine ON MachineInformation.MachineID=PlantMachine.MachineID
						  LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID'  
Select @Strsql =@Strsql+' Where MachineInformation.MachineID Is Not NULL'  
Select @Strsql =@Strsql+@StrPlantID+@Strmachine + @StrGroupid  
Select @Strsql =@Strsql+' Order By MachineInformation.MachineID'  
print @Strsql  
Exec (@Strsql)  
  
  
If @ComparisonType='Year'  
BEGIN  
  
 Insert Into #ProdData(MachineID,machineDescription)  
 Select MachineID,machineDescription From #MachineInfo  
  
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
  
  
 Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'  
 Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'  
 Select @Strsql = @Strsql+ ' From('  
 Select @Strsql = @Strsql+ ' Select T1.MachineID,Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,   
        Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) AS MarkedForRework,Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime  
                             From ShiftProductionDetails inner Join #ProdData T1 on T1.MachineID =  ShiftProductionDetails.Machineid'  
 Select @Strsql = @Strsql+ ' where Datepart(YEAR,pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid 
 Select @Strsql = @Strsql+ ' GROUP By T1.MachineID'  
 Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
 Print @Strsql  
 Exec(@Strsql)  
  

 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.MachineID,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.machineid = ShiftProductionDetails.machineid  
          Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.MachineID'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
 Print @Strsql  
 Exec(@Strsql)  
  
  
 Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'  
 Select @Strsql = @Strsql + ' From ('  
 Select @Strsql = @Strsql + ' Select T1.MachineID,sum(ShiftProductionDetails.Prod_Qty *(ShiftProductionDetails.CO_StdMachiningTime+ShiftProductionDetails.CO_StdLoadUnload)) AS CN '  
 Select @Strsql = @Strsql + ' From ShiftProductionDetails inner Join #ProdData T1 '  
 Select @Strsql = @Strsql + ' on T1.machineid = ShiftProductionDetails.machineid where   
 datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent  + @StrGroupid 
 Select @Strsql = @Strsql + ' Group By T1.MachineID '  
 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
 Print @Strsql  
 Exec(@Strsql)  
  
  -- Add McHrRate--
   Select @Strsql = 'UPDATE #ProdData SET McHrRate=ISNULL(T2.McHrRate,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.MachineID,Sum((isnull(ShiftProductionDetails.AcceptedParts,0)) * (isnull(ShiftProductionDetails.Price,0)))as McHrRate'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.machineid = ShiftProductionDetails.machineid'  
 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.MachineID'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
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
 Select @Strsql = @Strsql+ 'From (SELECT MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '  
 Select @Strsql = @Strsql+ 'WHERE datepart(YEAR,ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') and downid in (select downid from downcodeinformation where prodeffy = 1) '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent  + @StrGroupid 
 Select @Strsql = @Strsql+ ' Group By MachineID'  
 Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'  
 print @StrSql  
 EXEC(@StrSql)  
   
 Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'  
 Select @Strsql = @Strsql + ' From (select T1.MachineID,(Sum(ShiftDowntimeDetails.DownTime))As DownTime'  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join #ProdData T1 on T1.machineid = ShiftDowntimeDetails.machineid    
 where datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent  + @StrGroupid 
 Select @Strsql = @Strsql + ' Group By T1.MachineID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID'  
 Print @Strsql  
 Exec(@Strsql)   
  
   
 Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'  
 Select @Strsql = @Strsql + 'from (select T1.Machineid, sum(  
   CASE   
  WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0    
  THEN isnull(ShiftDownTimeDetails.Threshold,0)  
  ELSE ShiftDownTimeDetails.DownTime  
   END) AS LOSS '  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner JOIN #ProdData T1 on T1.machineid = ShiftDowntimeDetails.machineid where ML_flag = 1  
 and datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'    
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql + ' Group By T1.MachineID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON  #ProdData.MachineID=T2.MachineID '  
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


 If @View = 'MachinewiseView'
 Begin

	 select #ProdData.MachineID,machineDescription,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts,
	 round(isnull(RejCount,0),2) as RejCount,  
	 round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),@timeformat),2) as DownTime,round(PPM,2) as PPM,
	 round(AvgMcHrRate,2) as AvgMcHrRate,
	 ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEGreen,0) as OEGreen,
	 isnull(OERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen From #ProdData 
	 Left outer join machineinformation on #ProdData.MachineID=machineinformation.machineid
	 order by #ProdData.MachineID  
 End

  If @View = 'PlantwiseView'
 Begin

	 insert into #PlantLevelDetails(PlantID,AcceptedParts,RejCount,MarkedForRework,CN,UtilisedTime,DownTime,ManagementLoss,ProdCount,McHrRate)
	 Select PM.PlantID,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejCount,SUM(MarkedForRework) as MarkedForRework,SUM(CN) as CN,
	 SUM(UtilisedTime) as UtilisedTime,SUM(DownTime) AS DownTime ,sum(ManagementLoss),SUM(Prodcount),SUM(McHrRate)
	 from #ProdData P
	 inner join PlantMachine PM on P.MachineID=PM.MachineID
	 Group by PM.PlantID

	 UPDATE #PlantLevelDetails SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)  
	 Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0  
  
	 UPDATE #PlantLevelDetails  
	 SET  
	  PEffy = (CN/UtilisedTime) ,  
	  AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))  
	 WHERE UtilisedTime <> 0  

	 UPDATE #PlantLevelDetails  
	 SET  
	  --Round(OEffy,2)  
	  OEffy = PEffy * AEffy * QEffy * 100,  
	  PEffy = PEffy * 100 ,  
	  AEffy = AEffy * 100,  
	  QEffy = QEffy * 100  

	 update #PlantLevelDetails set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

	 update #PlantLevelDetails set AvgMcHrRate=McHrRate/Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float)
	where Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float) <> 0

	 select PlantID,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts,
	 round(isnull(RejCount,0),2) as RejCount,  
	 round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),@timeformat),2) as DownTime,round(PPM,2) as PPM ,
	 round(AvgMcHrRate,2) as AvgMcHrRate,
	 ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
	 isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen	 
	 From #PlantLevelDetails,TPMWEB_EfficiencyColorCoding  
	 where TPMWEB_EfficiencyColorCoding.Type='PlantID'
	 order by PlantID  
 End  
 
 If @View = 'CellwiseView'
 Begin

	 insert into #PlantLevelDetails(PlantID,AcceptedParts,RejCount,MarkedForRework,CN,UtilisedTime,DownTime,ManagementLoss,ProdCount,McHrRate)
	 Select PMG.GroupID,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejCount,SUM(MarkedForRework) as MarkedForRework,SUM(CN) as CN,
	 SUM(UtilisedTime) as UtilisedTime,SUM(DownTime) AS DownTime ,sum(ManagementLoss),SUM(prodcount), SUM(McHrRate)
	 from #ProdData P
	 inner join PlantMachine PM on P.MachineID=PM.MachineID
	 inner join PlantMachineGroups PMG on PM.MachineID=PMG.MachineID and PM.PlantID=PMG.PlantID
	 Group by PMG.GroupID

	 UPDATE #PlantLevelDetails SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)  
	 Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0  
  
	 UPDATE #PlantLevelDetails  
	 SET  
	  PEffy = (CN/UtilisedTime) ,  
	  AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))  
	 WHERE UtilisedTime <> 0  

	 UPDATE #PlantLevelDetails  
	 SET  
	  --Round(OEffy,2)  
	  OEffy = PEffy * AEffy * QEffy * 100,  
	  PEffy = PEffy * 100 ,  
	  AEffy = AEffy * 100,  
	  QEffy = QEffy * 100  

	  update #PlantLevelDetails set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

	  update #PlantLevelDetails set AvgMcHrRate=McHrRate/Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float)
	  where Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float) <> 0


	 select PlantID,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts,
	 round(isnull(RejCount,0),2) as RejCount,  
	 round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),@timeformat),2) as DownTime,round(PPM,2) as PPM,
	 round(AvgMcHrRate,2) as AvgMcHrRate ,
	 ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
	 isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen	 
	 From #PlantLevelDetails,TPMWEB_EfficiencyColorCoding  
	 where TPMWEB_EfficiencyColorCoding.Type='CellID'
	 order by PlantID  
 End  
   
END  
   
  
If @ComparisonType='Month'  
BEGIN  
  
 Insert Into #ProdData(MachineID,machineDescription)  
 Select MachineID,machineDescription From #MachineInfo  
  
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
   
 Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'  
 Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'  
 Select @Strsql = @Strsql+ ' From('  
 Select @Strsql = @Strsql+ ' Select T1.MachineID,Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,   
        Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) AS MarkedForRework,Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime  
                             From ShiftProductionDetails inner Join #ProdData T1 on T1.MachineID =  ShiftProductionDetails.Machineid'  
 Select @Strsql = @Strsql+ ' where Datepart(YEAR,pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')  and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+ ' GROUP By T1.MachineID'  
 Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
 Print @Strsql  
 Exec(@Strsql)  
  
 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.MachineID,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.machineid = ShiftProductionDetails.machineid  
          Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')   
 and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.MachineID'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
 Print @Strsql  
 Exec(@Strsql)  
  
  
 Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'  
 Select @Strsql = @Strsql + ' From ('  
 Select @Strsql = @Strsql + ' Select T1.MachineID,sum(ShiftProductionDetails.Prod_Qty *(ShiftProductionDetails.CO_StdMachiningTime+ShiftProductionDetails.CO_StdLoadUnload)) AS CN '  
 Select @Strsql = @Strsql + ' From ShiftProductionDetails inner Join #ProdData T1 '  
 Select @Strsql = @Strsql + ' on T1.machineid = ShiftProductionDetails.machineid where   
 datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql + ' Group By T1.MachineID '  
 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
 Print @Strsql  
 Exec(@Strsql)  
  

   Select @Strsql = 'UPDATE #ProdData SET McHrRate=ISNULL(T2.McHrRate,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.MachineID,Sum((isnull(ShiftProductionDetails.AcceptedParts,0)) * (isnull(ShiftProductionDetails.Price,0)))as McHrRate'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.machineid = ShiftProductionDetails.machineid'  
  Select @Strsql = @Strsql+ ' where Datepart(YEAR,pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')  and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'    
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.MachineID'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
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
 Select @Strsql = @Strsql+ 'From (SELECT MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '  
 Select @Strsql = @Strsql+ 'WHERE datepart(YEAR,ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') and Datepart(Month,ddate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')  
 and downid in (select downid from downcodeinformation where prodeffy = 1) '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+ ' Group By MachineID'  
 Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'  
 print @StrSql  
 EXEC(@StrSql)  
 
  
 Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'  
 Select @Strsql = @Strsql + ' From (select T1.MachineID,(Sum(ShiftDowntimeDetails.DownTime))As DownTime'  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join #ProdData T1 on T1.machineid = ShiftDowntimeDetails.machineid    
 where datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')  and Datepart(Month,dDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql + ' Group By T1.MachineID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID'  
 Print @Strsql  
 Exec(@Strsql)   
  
   
 Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'  
 Select @Strsql = @Strsql + 'from (select T1.Machineid, sum(  
   CASE   
  WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0    
  THEN isnull(ShiftDownTimeDetails.Threshold,0)  
  ELSE ShiftDownTimeDetails.DownTime  
   END) AS LOSS '  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner JOIN #ProdData T1 on T1.machineid = ShiftDowntimeDetails.machineid where ML_flag = 1  
 and datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')  and Datepart(Month,dDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'    
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql + ' Group By T1.MachineID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON  #ProdData.MachineID=T2.MachineID '  
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


 If @View = 'MachinewiseView'
 Begin
	 select #ProdData.MachineID,machineDescription,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,
	 round(isnull(AcceptedParts,0),2) as AcceptedParts,round(isnull(RejCount,0),2) as RejCount,  
	 round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),@timeformat),2) as DownTime,ROUND(PPM,2) as PPM ,
	 round(AvgMcHrRate,2) as AvgMcHrRate,
	ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEGreen,0) as OEGreen,
	isnull(OERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen From #ProdData 
	Left outer join machineinformation on #ProdData.MachineID=machineinformation.machineid
	order by #ProdData.MachineID  
 END

 If @View = 'PlantwiseView'
 Begin

	 insert into #PlantLevelDetails(PlantID,AcceptedParts,RejCount,MarkedForRework,CN,UtilisedTime,DownTime,ManagementLoss,ProdCount,McHrRate)
    Select PM.PlantID,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejCount,SUM(MarkedForRework) as MarkedForRework,SUM(CN) as CN,
    SUM(UtilisedTime) as UtilisedTime,SUM(DownTime) AS DownTime ,sum(ManagementLoss),SUM(Prodcount), SUM(McHrRate)
	 from #ProdData P
	 inner join PlantMachine PM on P.MachineID=PM.MachineID
	 Group by PM.PlantID

	 UPDATE #PlantLevelDetails SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)  
	 Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0  
  
	 UPDATE #PlantLevelDetails  
	 SET  
	  PEffy = (CN/UtilisedTime) ,  
	  AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))  
	 WHERE UtilisedTime <> 0  

	 UPDATE #PlantLevelDetails  
	 SET  
	  --Round(OEffy,2)  
	  OEffy = PEffy * AEffy * QEffy * 100,  
	  PEffy = PEffy * 100 ,  
	  AEffy = AEffy * 100,  
	  QEffy = QEffy * 100  

	  update #PlantLevelDetails set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

	  
	  update #PlantLevelDetails set AvgMcHrRate=McHrRate/Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float)
	  where Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float) <> 0


	 select Plantid,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts,
	 round(isnull(RejCount,0),2) as RejCount,  
	 round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),@timeformat),2) as DownTime,ROUND(PPM,2) as PPM ,
	 round(AvgMcHrRate,2) as AvgMcHrRate,
	 ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
	 isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen	 
	 From #PlantLevelDetails,TPMWEB_EfficiencyColorCoding  
	 where TPMWEB_EfficiencyColorCoding.Type='PlantID'
	 order by Plantid  
 End 
 
 If @View = 'CellwiseView'
 Begin

	 insert into #PlantLevelDetails(PlantID,AcceptedParts,RejCount,MarkedForRework,CN,UtilisedTime,DownTime,ManagementLoss,ProdCount,McHrRate)
     Select PMG.GroupID,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejCount,SUM(MarkedForRework) as MarkedForRework,SUM(CN) as CN,
     SUM(UtilisedTime) as UtilisedTime,SUM(DownTime) AS DownTime ,sum(ManagementLoss),sum(ProdCount), SUM(McHrRate)
	 from #ProdData P
	 inner join PlantMachine PM on P.MachineID=PM.MachineID
	 inner join PlantMachineGroups PMG on PM.MachineID=PMG.MachineID and PM.PlantID=PMG.PlantID
	 Group by PMG.GroupID

	 UPDATE #PlantLevelDetails SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)  
	 Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0  
  
	 UPDATE #PlantLevelDetails  
	 SET  
	  PEffy = (CN/UtilisedTime) ,  
	  AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))  
	 WHERE UtilisedTime <> 0  

	 UPDATE #PlantLevelDetails  
	 SET  
	  --Round(OEffy,2)  
	  OEffy = PEffy * AEffy * QEffy * 100,  
	  PEffy = PEffy * 100 ,  
	  AEffy = AEffy * 100,  
	  QEffy = QEffy * 100  

	  update #PlantLevelDetails set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

	  update #PlantLevelDetails set AvgMcHrRate=McHrRate/Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float)
	  where Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float) <> 0

	 select Plantid,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts,
	 round(isnull(RejCount,0),2) as RejCount,  
	 round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),@timeformat),2) as DownTime,ROUND(PPM,2) as PPM,
	 round(AvgMcHrRate,2) as AvgMcHrRate,
	 ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
	 isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen	 
	 From #PlantLevelDetails ,TPMWEB_EfficiencyColorCoding  
	 where TPMWEB_EfficiencyColorCoding.Type='CellID'
	 order by Plantid  
 End 
   
END  
  
  
If @ComparisonType='Day'  
BEGIN  
  
 Insert Into #ProdData(MachineID,machineDescription)  
 Select MachineID,machineDescription From #MachineInfo  
  
  
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
   
 Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'  
 Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'  
 Select @Strsql = @Strsql+ ' From('  
 Select @Strsql = @Strsql+ ' Select T1.MachineID,Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,   
        Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) AS MarkedForRework,Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime  
                             From ShiftProductionDetails inner Join #ProdData T1 on T1.MachineID =  ShiftProductionDetails.Machineid'  
 Select @Strsql = @Strsql+ ' where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftProductionDetails.Pdate,120) '   
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+ ' GROUP By T1.MachineID'  
 Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
 Print @Strsql  
 Exec(@Strsql)  
  
 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.MachineID,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.machineid = ShiftProductionDetails.machineid  
          Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftProductionDetails.Pdate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.MachineID'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
 Print @Strsql  
 Exec(@Strsql)  
  
  
 Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'  
 Select @Strsql = @Strsql + ' From ('  
 Select @Strsql = @Strsql + ' Select T1.MachineID,sum(ShiftProductionDetails.Prod_Qty *(ShiftProductionDetails.CO_StdMachiningTime+ShiftProductionDetails.CO_StdLoadUnload)) AS CN '  
 Select @Strsql = @Strsql + ' From ShiftProductionDetails inner Join #ProdData T1 '  
 Select @Strsql = @Strsql + ' on T1.machineid = ShiftProductionDetails.machineid where   
 ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftProductionDetails.Pdate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql + ' Group By T1.MachineID '  
 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
 Print @Strsql  
 Exec(@Strsql)  
  
 Select @Strsql = 'UPDATE #ProdData SET McHrRate=ISNULL(T2.McHrRate,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.MachineID,Sum((isnull(ShiftProductionDetails.AcceptedParts,0)) * (isnull(ShiftProductionDetails.Price,0)))as McHrRate'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.machineid = ShiftProductionDetails.machineid'  
  Select @Strsql = @Strsql+ ' where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftProductionDetails.Pdate,120) '   
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql+' Group By T1.MachineID'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID '  
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
 Select @Strsql = @Strsql+ 'From (SELECT MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '  
 Select @Strsql = @Strsql+ 'WHERE ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftDownTimeDetails.Ddate,120)  
 and downid in (select downid from downcodeinformation where prodeffy = 1) '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent  + @StrGroupid 
 Select @Strsql = @Strsql+ ' Group By MachineID'  
 Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'  
 print @StrSql  
 EXEC(@StrSql)  
  
   
 Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'  
 Select @Strsql = @Strsql + ' From (select T1.MachineID,(Sum(ShiftDowntimeDetails.DownTime))As DownTime'  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join #ProdData T1 on T1.machineid = ShiftDowntimeDetails.machineid    
 where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftDowntimeDetails.Ddate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql + ' Group By T1.MachineID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID'  
 Print @Strsql  
 Exec(@Strsql)   
  
   
 Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'  
 Select @Strsql = @Strsql + 'from (select T1.Machineid, sum(  
   CASE   
  WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0    
  THEN isnull(ShiftDownTimeDetails.Threshold,0)  
  ELSE ShiftDownTimeDetails.DownTime  
   END) AS LOSS '  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner JOIN #ProdData T1 on T1.machineid = ShiftDowntimeDetails.machineid where ML_flag = 1  
 and ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftDowntimeDetails.Ddate,120)'    
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine+@StrShift+@StrEmployee+@StrComponent + @StrGroupid  
 Select @Strsql = @Strsql + ' Group By T1.MachineID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON  #ProdData.MachineID=T2.MachineID '  
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


 If @View = 'MachinewiseView'
 Begin 

	 select #ProdData.MachineID,machineDescription,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts,
	 round(isnull(RejCount,0),2) as RejCount,  
	 round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),@timeformat),2) as DownTime,ROUND(PPM,2) as PPM ,
	 round(AvgMcHrRate,2) as AvgMcHrRate,
	ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEGreen,0) as OEGreen,
	isnull(OERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen From #ProdData 
	Left outer join machineinformation on #ProdData.MachineID=machineinformation.machineid
	order by #ProdData.MachineID  
 END
 
  If @View = 'PlantwiseView'
 Begin

	 insert into #PlantLevelDetails(PlantID,AcceptedParts,RejCount,MarkedForRework,CN,UtilisedTime,DownTime,ManagementLoss,ProdCount,McHrRate)
	 Select PM.PlantID,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejCount,SUM(MarkedForRework) as MarkedForRework,SUM(CN) as CN,
	 SUM(UtilisedTime) as UtilisedTime,SUM(DownTime) AS DownTime,sum(ManagementLoss),sum(prodcount),Sum(McHrRate)
	 from #ProdData P
	 inner join PlantMachine PM on P.MachineID=PM.MachineID
	 Group by PM.PlantID

	 UPDATE #PlantLevelDetails SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)  
	 Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0  
  
	 UPDATE #PlantLevelDetails  
	 SET  
	  PEffy = (CN/UtilisedTime) ,  
	  AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))  
	 WHERE UtilisedTime <> 0  

	 UPDATE #PlantLevelDetails  
	 SET  
	  --Round(OEffy,2)  
	  OEffy = PEffy * AEffy * QEffy * 100,  
	  PEffy = PEffy * 100 ,  
	  AEffy = AEffy * 100,  
	  QEffy = QEffy * 100  

	  update #PlantLevelDetails set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

	  update #PlantLevelDetails set AvgMcHrRate=McHrRate/Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float)
	  where Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float) <> 0


	 select Plantid,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts,
	 round(isnull(RejCount,0),2) as RejCount,  
	 round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),@timeformat),2) as DownTime,ROUND(PPM,2) as PPM,
	 round(AvgMcHrRate,2) as AvgMcHrRate,
	 ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
	 isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen	 
	 From #PlantLevelDetails,TPMWEB_EfficiencyColorCoding   
	 where TPMWEB_EfficiencyColorCoding.Type='PlantID' order by Plantid  
 End  
 
 If @View = 'CellwiseView'
 Begin

	 insert into #PlantLevelDetails(PlantID,AcceptedParts,RejCount,MarkedForRework,CN,UtilisedTime,DownTime,ManagementLoss,ProdCount,McHrRate)
	 Select PMG.GroupID,SUM(AcceptedParts) as AcceptedParts,SUM(RejCount) as RejCount,SUM(MarkedForRework) as MarkedForRework,SUM(CN) as CN,
	 SUM(UtilisedTime) as UtilisedTime,SUM(DownTime) AS DownTime,sum(ManagementLoss),SUM(ProdCount), SUM(McHrRate)
	 from #ProdData P
	 inner join PlantMachine PM on P.MachineID=PM.MachineID
	 inner join PlantMachineGroups PMG on PM.MachineID=PMG.MachineID and PM.PlantID=PMG.PlantID
	 Group by  PMG.GroupID

	 UPDATE #PlantLevelDetails SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)  
	 Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0  
  
	 UPDATE #PlantLevelDetails  
	 SET  
	  PEffy = (CN/UtilisedTime) ,  
	  AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))  
	 WHERE UtilisedTime <> 0  

	 UPDATE #PlantLevelDetails  
	 SET  
	  --Round(OEffy,2)  
	  OEffy = PEffy * AEffy * QEffy * 100,  
	  PEffy = PEffy * 100 ,  
	  AEffy = AEffy * 100,  
	  QEffy = QEffy * 100  

	  update #PlantLevelDetails set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

	  update #PlantLevelDetails set AvgMcHrRate=McHrRate/Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float)
	  where Cast(dbo.f_FormatTime((UtilisedTime + ISNULL( DownTime,0)),'hh') as float) <> 0

	 select Plantid,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts,
	 round(isnull(RejCount,0),2) as RejCount,  
	 round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(ISNULL(DownTime,0)+ISNULL(ManagementLoss,0),@timeformat),2) as DownTime,ROUND(PPM,2) as PPM ,
	 round(AvgMcHrRate,2) as AvgMcHrRate,
	 ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
	 isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen	 
	 From #PlantLevelDetails,TPMWEB_EfficiencyColorCoding  
	 where TPMWEB_EfficiencyColorCoding.Type='CellID' order by Plantid  
 End  
   
END  
  
   
END  
  
