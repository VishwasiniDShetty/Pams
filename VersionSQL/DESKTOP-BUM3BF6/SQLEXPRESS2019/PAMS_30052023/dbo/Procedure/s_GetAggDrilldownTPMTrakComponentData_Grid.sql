/****** Object:  Procedure [dbo].[s_GetAggDrilldownTPMTrakComponentData_Grid]    Committed by VersionSQL https://www.versionsql.com ******/

 
--[dbo].[s_GetAggDrilldownTPMTrakComponentData_Grid] '2018-01-24','','','','YEAR','','Group-3'  
--[dbo].[s_GetAggDrilldownTPMTrakComponentData_Grid] '2018-01-24','first','','','YEAR','','Group-3'    
  
--[dbo].[s_GetAggDrilldownTPMTrakComponentData_Grid] '2018-08-24','','','','MONTH','','Group-3'   
--[dbo].[s_GetAggDrilldownTPMTrakComponentData_Grid] '2018-08-24','first','','','MONTH','','Group-3'    
  
--[dbo].[s_GetAggDrilldownTPMTrakComponentData_Grid]  '2018-08-24','','','','DAY','','Group-3'  
--[dbo].[s_GetAggDrilldownTPMTrakComponentData_Grid] '2018-08-24','first','','','DAY','','Group-3'  
  
CREATE                      PROCEDURE [dbo].[s_GetAggDrilldownTPMTrakComponentData_Grid]  
 @StartDate As DateTime,  
 @ShiftName As NVarChar(50)='',  
 @PlantID As NVarChar(50)='',  
 @Component As nvarchar(50)='',   
 @ComparisonType As nvarchar(20), /*SHIFT,DAY,MONTH,YEAR*/  
 @Parameter As nvarchar(50)='',/* All KPIs,Parts Count,Down Time, AE, PE, OE ,QE,Rej Count */  
 @Groupid as nvarchar(50)=''  
AS  
BEGIN  
----------------------------------------------------------------------------------------------------------  
--* Declaration of Variables *--  
----------------------------------------------------------------------------------------------------------  
Declare @Strsql nvarchar(4000)  
Declare @timeformat AS nvarchar(12)  
  
Declare @StrPlantID AS NVarchar(255)  
Declare @StrShift AS NVarchar(255)  
Declare @StrComponent as nvarchar(255)  
  
Declare @CurDate As DateTime  
Declare @StratOfMonth As DateTime  
Declare @EndOfMonth As DateTime  
Declare @AddMonth As DateTime     
Declare @StrGroupid as nvarchar(255)     
  
Select @Strsql = ''  
Select @StrPlantID=''  
Select @StrShift=''  
Select @StrComponent=''  
Select @StrGroupid=''    
  
-------------------------------------------------------------------------------------------------------------  
                                                 -- * Building Strings * --  
-------------------------------------------------------------------------------------------------------------  
  
If isnull(@PlantID,'') <> ''  
Begin  
Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )'  
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
 ComponentID  NVarChar(50),  
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
 PPM float default 0    
)  
  
  
If @ComparisonType='Year'  
BEGIN  
  
 Insert Into #ProdData(ComponentID)  
 (Select ComponentID From ShiftProductionDetails
 where Datepart(YEAR,pDate)=Datepart(YEAR,convert(nvarchar(20),@StartDate,120)))
 UNION 
 (Select ComponentID from ShiftDownTimeDetails
 where Datepart(YEAR,DDate)=Datepart(YEAR,convert(nvarchar(20),@StartDate,120))) 
  
 If isnull(@PlantID,'') <> ''  
 Begin  
 Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'  
 End  
  
 
 If isnull(@Component,'') <> ''  
 Begin  
 Select @StrComponent = ' And (ShiftProductionDetails.Componentid = N''' + @Component + ''')'  
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
 Select @Strsql = @Strsql+ ' Select T1.ComponentID,Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,   
        Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) AS MarkedForRework,Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime  
                             From ShiftProductionDetails inner Join #ProdData T1 on T1.ComponentID =  ShiftProductionDetails.ComponentID'  
 Select @Strsql = @Strsql+ ' where Datepart(YEAR,pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid 
 Select @Strsql = @Strsql+ ' GROUP By T1.ComponentID'  
 Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.ComponentID=T2.ComponentID '  
 Print @Strsql  
 Exec(@Strsql)  
  
 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.ComponentID,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.ComponentID = ShiftProductionDetails.ComponentID  
          Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid   
 Select @Strsql = @Strsql+' Group By T1.ComponentID'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.ComponentID=T2.ComponentID '  
 Print @Strsql  
 Exec(@Strsql)  
  
  
 Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'  
 Select @Strsql = @Strsql + ' From ('  
 Select @Strsql = @Strsql + ' Select T1.ComponentID,sum(ShiftProductionDetails.Prod_Qty *(ShiftProductionDetails.CO_StdMachiningTime+ShiftProductionDetails.CO_StdLoadUnload)) AS CN '  
 Select @Strsql = @Strsql + ' From ShiftProductionDetails inner Join #ProdData T1 '  
 Select @Strsql = @Strsql + ' on T1.ComponentID = ShiftProductionDetails.ComponentID where   
 datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') '  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid   
 Select @Strsql = @Strsql + ' Group By T1.ComponentID '  
 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.ComponentID=T2.ComponentID '  
 Print @Strsql  
 Exec(@Strsql)  
  
  
 If isnull(@PlantID,'') <> ''  
 Begin  
 Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'  
 End  
  
 If isnull(@Component,'') <> ''  
 Begin  
 Select @StrComponent = ' And (ShiftDownTimeDetails.Componentid = N''' + @Component + ''')'  
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
 Select @Strsql = @Strsql+ 'From (SELECT ComponentID,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '  
 Select @Strsql = @Strsql+ 'WHERE datepart(YEAR,ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') 
 and downid in (select downid from downcodeinformation where prodeffy = 1) '  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid     
 Select @Strsql = @Strsql+ ' Group By ComponentID'  
 Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON T2.ComponentID=#ProdData.ComponentID'  
 print @StrSql  
 EXEC(@StrSql)  
   
 Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'  
 Select @Strsql = @Strsql + ' From (select T1.ComponentID,(Sum(ShiftDowntimeDetails.DownTime))As DownTime'  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join #ProdData T1 on T1.ComponentID = ShiftDowntimeDetails.ComponentID    
 where datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID+@StrShift+@StrComponent + @StrGroupid     
 Select @Strsql = @Strsql + ' Group By T1.ComponentID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.ComponentID=T2.ComponentID'  
 Print @Strsql  
 Exec(@Strsql)   
  
   
 Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'  
 Select @Strsql = @Strsql + 'from (select T1.ComponentID, sum(  
   CASE   
  WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0    
  THEN isnull(ShiftDownTimeDetails.Threshold,0)  
  ELSE ShiftDownTimeDetails.DownTime  
   END) AS LOSS '  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner JOIN #ProdData T1 on T1.ComponentID = ShiftDowntimeDetails.ComponentID where ML_flag = 1  
 and datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')'    
 Select @Strsql = @Strsql+  @StrPlantID+@StrShift+@StrComponent + @StrGroupid     
 Select @Strsql = @Strsql + ' Group By T1.ComponentID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON  #ProdData.ComponentID=T2.ComponentID '  
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
  OEffy = PEffy * AEffy * QEffy * 100,  
  PEffy = PEffy * 100 ,  
  AEffy = AEffy * 100,  
  QEffy = QEffy * 100  
  
 update #ProdData set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0


 select ComponentID,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts ,
 round(isnull(RejCount,0),2) as RejCount,  
 round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(DownTime,@timeformat),2) as DownTime,round(PPM,2) as PPM
 ,ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen	 
From #ProdData,TPMWEB_EfficiencyColorCoding  
where TPMWEB_EfficiencyColorCoding.Type='ComponentID' 
order by ComponentID 
 
END  
   
  
If @ComparisonType='Month'  
BEGIN  
  
 Insert Into #ProdData(ComponentID)  
 (Select ComponentID From ShiftProductionDetails
 where Datepart(YEAR,pDate)=Datepart(YEAR,convert(nvarchar(20),@StartDate,120)) and Datepart(Month,pDate)=Datepart(Month,convert(nvarchar(20),@StartDate,120)))
 UNION 
 (Select ComponentID from ShiftDownTimeDetails
 where Datepart(YEAR,DDate)=Datepart(YEAR,convert(nvarchar(20),@StartDate,120)) and Datepart(Month,dDate)=Datepart(Month,convert(nvarchar(20),@StartDate,120))) 

 If isnull(@PlantID,'') <> ''  
 Begin  
 Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'  
 End  
 
 If isnull(@Component,'') <> ''  
 Begin  
 Select @StrComponent = ' And (ShiftProductionDetails.Componentid = N''' + @Component + ''')'  
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
 Select @Strsql = @Strsql+ ' Select T1.ComponentID,Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,   
        Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) AS MarkedForRework,Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime  
                             From ShiftProductionDetails inner Join #ProdData T1 on T1.ComponentID =  ShiftProductionDetails.ComponentID'  
 Select @Strsql = @Strsql+ ' where Datepart(YEAR,pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')    
 and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid     
 Select @Strsql = @Strsql+ ' GROUP By T1.ComponentID'  
 Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.ComponentID=T2.ComponentID '  
 Print @Strsql  
 Exec(@Strsql)  
  
 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.ComponentID,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.ComponentID = ShiftProductionDetails.ComponentID  
          Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')   
 and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid    
 Select @Strsql = @Strsql+' Group By T1.ComponentID'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.ComponentID=T2.ComponentID '  
 Print @Strsql  
 Exec(@Strsql)  
  
  
 Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'  
 Select @Strsql = @Strsql + ' From ('  
 Select @Strsql = @Strsql + ' Select T1.ComponentID,sum(ShiftProductionDetails.Prod_Qty *(ShiftProductionDetails.CO_StdMachiningTime+ShiftProductionDetails.CO_StdLoadUnload)) AS CN '  
 Select @Strsql = @Strsql + ' From ShiftProductionDetails inner Join #ProdData T1 '  
 Select @Strsql = @Strsql + ' on T1.ComponentID = ShiftProductionDetails.ComponentID where   
 datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent  + @StrGroupid    
 Select @Strsql = @Strsql + ' Group By T1.ComponentID '  
 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.ComponentID=T2.ComponentID '  
 Print @Strsql  
 Exec(@Strsql)  
  
  
 If isnull(@PlantID,'') <> ''  
 Begin  
 Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'  
 End  
  
 If isnull(@Component,'') <> ''  
 Begin  
 Select @StrComponent = ' And (ShiftDownTimeDetails.Componentid = N''' + @Component + ''')'  
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
 Select @Strsql = @Strsql+ 'From (SELECT ComponentID,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '  
 Select @Strsql = @Strsql+ 'WHERE datepart(YEAR,ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') and Datepart(Month,ddate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')  
 and downid in (select downid from downcodeinformation where prodeffy = 1) '  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid     
 Select @Strsql = @Strsql+ ' Group By ComponentID'  
 Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON T2.ComponentID=#ProdData.ComponentID'  
 print @StrSql  
 EXEC(@StrSql)  
 
  
 Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'  
 Select @Strsql = @Strsql + ' From (select T1.ComponentID,(Sum(ShiftDowntimeDetails.DownTime))As DownTime'  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join #ProdData T1 on T1.ComponentID = ShiftDowntimeDetails.ComponentID    
 where datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')  and Datepart(Month,dDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid     
 Select @Strsql = @Strsql + ' Group By T1.ComponentID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.ComponentID=T2.ComponentID'  
 Print @Strsql  
 Exec(@Strsql)   
  
   
 Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'  
 Select @Strsql = @Strsql + 'from (select T1.ComponentID, sum(  
   CASE   
  WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0    
  THEN isnull(ShiftDownTimeDetails.Threshold,0)  
  ELSE ShiftDownTimeDetails.DownTime  
   END) AS LOSS '  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner JOIN #ProdData T1 on T1.ComponentID = ShiftDowntimeDetails.ComponentID where ML_flag = 1  
 and datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')  and Datepart(Month,dDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'    
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent  + @StrGroupid    
 Select @Strsql = @Strsql + ' Group By T1.ComponentID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON  #ProdData.ComponentID=T2.ComponentID '  
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
  OEffy = PEffy * AEffy * QEffy * 100,  
  PEffy = PEffy * 100 ,  
  AEffy = AEffy * 100,  
  QEffy = QEffy * 100  

   update #ProdData set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0


select ComponentID,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts,
round(isnull(RejCount,0),2) as RejCount,  
round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(DownTime,@timeformat),2) as DownTime,round(PPM,2) as PPM 
,ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen	 
From #ProdData,TPMWEB_EfficiencyColorCoding  
where TPMWEB_EfficiencyColorCoding.Type='ComponentID' 
order by ComponentID  
 
END  
  
  
If @ComparisonType='Day'  
BEGIN  
  
 Insert Into #ProdData(ComponentID)  
 (Select ComponentID From ShiftProductionDetails
 where convert(nvarchar(10),@StartDate,120)=convert(nvarchar(10),Pdate,120))
 UNION 
 (Select ComponentID from ShiftDownTimeDetails
 where convert(nvarchar(10),@StartDate,120)=convert(nvarchar(10),Ddate,120)) 
  
  
 If isnull(@PlantID,'') <> ''  
 Begin  
 Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'  
 End  
  
 If isnull(@Component,'') <> ''  
 Begin  
 Select @StrComponent = ' And (ShiftProductionDetails.Componentid = N''' + @Component + ''')'  
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
 Select @Strsql = @Strsql+ ' Select T1.ComponentID,Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,   
        Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) AS MarkedForRework,Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime  
                             From ShiftProductionDetails inner Join #ProdData T1 on T1.ComponentID =  ShiftProductionDetails.ComponentID'  
 Select @Strsql = @Strsql+ ' where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftProductionDetails.Pdate,120) '   
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid     
 Select @Strsql = @Strsql+ ' GROUP By T1.ComponentID'  
 Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.ComponentID=T2.ComponentID '  
 Print @Strsql  
 Exec(@Strsql)  
  
 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select T1.ComponentID,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.ComponentID = ShiftProductionDetails.ComponentID  
          Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftProductionDetails.Pdate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent  + @StrGroupid    
 Select @Strsql = @Strsql+' Group By T1.ComponentID'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.ComponentID=T2.ComponentID '  
 Print @Strsql  
 Exec(@Strsql)  
  
  
 Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'  
 Select @Strsql = @Strsql + ' From ('  
 Select @Strsql = @Strsql + ' Select T1.ComponentID,sum(ShiftProductionDetails.Prod_Qty *(ShiftProductionDetails.CO_StdMachiningTime+ShiftProductionDetails.CO_StdLoadUnload)) AS CN '  
 Select @Strsql = @Strsql + ' From ShiftProductionDetails inner Join #ProdData T1 '  
 Select @Strsql = @Strsql + ' on T1.ComponentID = ShiftProductionDetails.ComponentID where   
 ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftProductionDetails.Pdate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid     
 Select @Strsql = @Strsql + ' Group By T1.ComponentID '  
 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.ComponentID=T2.ComponentID '  
 Print @Strsql  
 Exec(@Strsql)  
  
  
 If isnull(@PlantID,'') <> ''  
 Begin  
 Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'  
 End  
  
 If isnull(@Component,'') <> ''  
 Begin  
 Select @StrComponent = ' And (ShiftDownTimeDetails.Componentid = N''' + @Component + ''')'  
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
 Select @Strsql = @Strsql+ 'From (SELECT ComponentID,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '  
 Select @Strsql = @Strsql+ 'WHERE ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftDownTimeDetails.Ddate,120)  
 and downid in (select downid from downcodeinformation where prodeffy = 1) '  
 Select @Strsql = @Strsql+  @StrPlantID+@StrShift+@StrComponent  + @StrGroupid    
 Select @Strsql = @Strsql+ ' Group By ComponentID'  
 Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON T2.ComponentID=#ProdData.ComponentID'  
 print @StrSql  
 EXEC(@StrSql)  
  
   
 Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'  
 Select @Strsql = @Strsql + ' From (select T1.ComponentID,(Sum(ShiftDowntimeDetails.DownTime))As DownTime'  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join #ProdData T1 on T1.ComponentID = ShiftDowntimeDetails.ComponentID    
 where ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftDowntimeDetails.Ddate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID +@StrShift+@StrComponent + @StrGroupid     
 Select @Strsql = @Strsql + ' Group By T1.ComponentID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.ComponentID=T2.ComponentID'  
 Print @Strsql  
 Exec(@Strsql)   
  
   
 Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'  
 Select @Strsql = @Strsql + 'from (select T1.ComponentID, sum(  
   CASE   
  WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0    
  THEN isnull(ShiftDownTimeDetails.Threshold,0)  
  ELSE ShiftDownTimeDetails.DownTime  
   END) AS LOSS '  
 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner JOIN #ProdData T1 on T1.ComponentID = ShiftDowntimeDetails.ComponentID where ML_flag = 1  
 and ''' + convert(nvarchar(10),@StartDate,120)+ '''=convert(nvarchar(10),ShiftDowntimeDetails.Ddate,120)'    
 Select @Strsql = @Strsql+  @StrPlantID+@StrShift+@StrComponent + @StrGroupid     
 Select @Strsql = @Strsql + ' Group By T1.ComponentID'  
 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON  #ProdData.ComponentID=T2.ComponentID '  
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
  OEffy = PEffy * AEffy * QEffy * 100,  
  PEffy = PEffy * 100 ,  
  AEffy = AEffy * 100,  
  QEffy = QEffy * 100  
  
   update #ProdData set PPM=(isnull(RejCount,0)/ISNULL(ProdCount,0))*1000000 where ProdCount<>0

select ComponentID,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy,round(isnull(AcceptedParts,0),2) as AcceptedParts,
round(isnull(RejCount,0),2) as RejCount,  
round(isnull(ReworkPerformed,0),2) as ReworkPerformed,Round(dbo.f_FormatTime(DownTime,@timeformat),2) as DownTime,round(PPM,2) as PPM 
,ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen	 
From #ProdData,TPMWEB_EfficiencyColorCoding  
where TPMWEB_EfficiencyColorCoding.Type='ComponentID' 
order by ComponentID 

 
END  
  
   
END  
  
