/****** Object:  Procedure [dbo].[s_PMT_GetGroupwiseOperatorEfficiency]    Committed by VersionSQL https://www.versionsql.com ******/

--s_PMT_GetGroupwiseOperatorEfficiency '2019-06-05','','','','OEEGroup'
CREATE                                  PROCEDURE [dbo].[s_PMT_GetGroupwiseOperatorEfficiency]
	@StartDate As DateTime,
	@PlantID As NVarChar(50)='',
	@Groupid nvarchar(50)='',
	@Parameter As nvarchar(50)='',/* Shift,Day,Consolidated Etc*/
	@OEEParam As varchar(50)='' /* OEEGroup ,OEEOperator */
AS
BEGIN


declare @strsql as nvarchar(max)

Declare @Strmachine nvarchar(255)
Declare @StrPlantID AS NVarchar(255)
Declare @Strgroupid AS NVarchar(255)


Select @Strsql = ''
Select @Strmachine = ''
Select @StrPlantID=''
select @Strgroupid=''


Create Table #ProdData  
(  
  Groupid  NVarChar(50),  
 OperatorID  NVarChar(50),  
 ProdCount Int DEFAULT 0,  
 AcceptedParts Int DEFAULT 0,  
 RejCount  Int DEFAULT 0,  
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
 DowntimeAE float default 0  
)

If @OEEParam = 'OEEGroup'
 BEGIN
		Insert Into #ProdData(Groupid)  
		 (Select Groupid From ShiftProductionDetails
		 where Datepart(YEAR,pDate)=Datepart(YEAR,convert(nvarchar(20),@StartDate,120)) and Datepart(Month,pDate)=Datepart(Month,convert(nvarchar(20),@StartDate,120)))
		 UNION 
		 (Select Groupid from ShiftDownTimeDetails
		 where Datepart(YEAR,DDate)=Datepart(YEAR,convert(nvarchar(20),@StartDate,120)) and Datepart(Month,dDate)=Datepart(Month,convert(nvarchar(20),@StartDate,120))) 

		 If isnull(@PlantID,'') <> ''  
		 Begin   
		 Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID in (' + @PlantID + '))'
		 End  

		If isnull(@Groupid,'') <> ''  
		Begin  
		  Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID  in (' + @GroupID + '))'
		End 
 
		 Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'  
		 Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'  
		 Select @Strsql = @Strsql+ ' From('  
		 Select @Strsql = @Strsql+ ' Select T1.Groupid,Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,   
				Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) AS MarkedForRework,Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime  
									 From ShiftProductionDetails inner Join #ProdData T1 on T1.Groupid =  ShiftProductionDetails.Groupid'  
		 Select @Strsql = @Strsql+ ' where Datepart(YEAR,pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')    
		 and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
		 Select @Strsql = @Strsql+  @StrPlantID +@StrGroupid    
		 Select @Strsql = @Strsql+ ' GROUP By T1.Groupid'  
		 Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON  #ProdData.Groupid=T2.Groupid '  
		 Print @Strsql  
		 Exec(@Strsql)  
  
		 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
		 Select @Strsql = @Strsql+' FROM('  
		 Select @Strsql = @Strsql+' Select T1.Groupid,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
		 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.Groupid =  ShiftProductionDetails.Groupid 
				  Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'  
		 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')   
		 and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
		 Select @Strsql = @Strsql+  @StrPlantID + @StrGroupid    
		 Select @Strsql = @Strsql+' Group By T1.Groupid'  
		 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.Groupid=T2.Groupid '  
		 Print @Strsql  
		 Exec(@Strsql)  
  
  
		 Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'  
		 Select @Strsql = @Strsql + ' From ('  
		 Select @Strsql = @Strsql + ' Select T1.Groupid,sum(ShiftProductionDetails.Prod_Qty *(ShiftProductionDetails.CO_StdMachiningTime+ShiftProductionDetails.CO_StdLoadUnload)) AS CN '  
		 Select @Strsql = @Strsql + ' From ShiftProductionDetails inner Join #ProdData T1 '  
		 Select @Strsql = @Strsql + ' on T1.Groupid =  ShiftProductionDetails.Groupid  where   
		 datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
		 Select @Strsql = @Strsql+  @StrPlantID +@StrGroupid    
		 Select @Strsql = @Strsql + ' Group By T1.Groupid'  
		 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.Groupid=T2.Groupid '  
		 Print @Strsql  
		 Exec(@Strsql)  
  
  
		 If isnull(@PlantID,'') <> ''  
		 Begin  
		 --Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'  
		 Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID in (' + @PlantID + '))' 
		 End  

		If isnull(@Groupid,'') <> ''  
		Begin  
		 --Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID = N''' + @GroupID + ''')'  
		 Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID  in (' + @GroupID + '))'
		End 
  
		 Select @Strsql =''  
		 SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '  
		 Select @Strsql = @Strsql+ 'From (SELECT groupid,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '  
		 Select @Strsql = @Strsql+ 'WHERE datepart(YEAR,ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') and Datepart(Month,ddate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')  
		 and downid in (select downid from downcodeinformation where prodeffy = 1) '  
		 Select @Strsql = @Strsql+  @StrPlantID + @StrGroupid    
		 Select @Strsql = @Strsql+ ' Group By groupid'  
		 Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON #ProdData.Groupid=T2.Groupid'  
		 print @StrSql  
		 EXEC(@StrSql)  
 
  
		 Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'  
		 Select @Strsql = @Strsql + ' From (select T1.Groupid,(Sum(ShiftDowntimeDetails.DownTime))As DownTime'  
		 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join #ProdData T1 on T1.Groupid =  ShiftDowntimeDetails.Groupid   
		 where datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')  and Datepart(Month,dDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
		 Select @Strsql = @Strsql+  @StrPlantID+ @StrGroupid    
		 Select @Strsql = @Strsql + ' Group By T1.Groupid'  
		 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.Groupid=T2.Groupid'  
		 Print @Strsql  
		 Exec(@Strsql)   
  
   
		 Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'  
		 Select @Strsql = @Strsql + 'from (select T1.Groupid,sum(  
		   CASE   
		  WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0    
		  THEN isnull(ShiftDownTimeDetails.Threshold,0)  
		  ELSE ShiftDownTimeDetails.DownTime  
		   END) AS LOSS '  
		 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner JOIN #ProdData T1 on T1.Groupid =  ShiftDowntimeDetails.Groupid 
		 where ML_flag = 1  
		 and datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')  and Datepart(Month,dDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'    
		 Select @Strsql = @Strsql+  @StrPlantID + @StrGroupid    
		 Select @Strsql = @Strsql + ' Group By T1.Groupid'  
		 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.Groupid=T2.Groupid'  
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

		select Groupid,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy From #ProdData order by Groupid 

 END
ELSE
 BEGIN
		 Insert Into #ProdData(Groupid,OperatorID)  
		 (Select Groupid,OperatorID From ShiftProductionDetails
		 where Datepart(YEAR,pDate)=Datepart(YEAR,convert(nvarchar(20),@StartDate,120)) and Datepart(Month,pDate)=Datepart(Month,convert(nvarchar(20),@StartDate,120)))
		 UNION 
		 (Select Groupid,OperatorID from ShiftDownTimeDetails
		 where Datepart(YEAR,DDate)=Datepart(YEAR,convert(nvarchar(20),@StartDate,120)) and Datepart(Month,dDate)=Datepart(Month,convert(nvarchar(20),@StartDate,120))) 

		 If isnull(@PlantID,'') <> ''  
		 Begin   
		 Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID in (' + @PlantID + '))'
		 End  

		If isnull(@Groupid,'') <> ''  
		Begin  
		  Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID  in (' + @GroupID + '))'
		End 
 
		 Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'  
		 Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'  
		 Select @Strsql = @Strsql+ ' From('  
		 Select @Strsql = @Strsql+ ' Select T1.Groupid,T1.OperatorID,Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,   
				Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) AS MarkedForRework,Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime  
									 From ShiftProductionDetails inner Join #ProdData T1 on T1.OperatorID =  ShiftProductionDetails.OperatorID and T1.Groupid =  ShiftProductionDetails.Groupid'  
		 Select @Strsql = @Strsql+ ' where Datepart(YEAR,pDate)=Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')    
		 and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
		 Select @Strsql = @Strsql+  @StrPlantID +@StrGroupid    
		 Select @Strsql = @Strsql+ ' GROUP By T1.Groupid,T1.OperatorID'  
		 Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.OperatorID=T2.OperatorID and #ProdData.Groupid=T2.Groupid '  
		 Print @Strsql  
		 Exec(@Strsql)  
  
		 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
		 Select @Strsql = @Strsql+' FROM('  
		 Select @Strsql = @Strsql+' Select T1.Groupid,T1.OperatorID,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
		 Select @Strsql = @Strsql+' From ShiftProductionDetails inner Join #ProdData T1 on T1.OperatorID = ShiftProductionDetails.OperatorID and T1.Groupid =  ShiftProductionDetails.Groupid 
				  Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'  
		 Select @Strsql = @Strsql+' Where datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')   
		 and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
		 Select @Strsql = @Strsql+  @StrPlantID + @StrGroupid    
		 Select @Strsql = @Strsql+' Group By T1.Groupid,T1.OperatorID'  
		 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.OperatorID=T2.OperatorID and #ProdData.Groupid=T2.Groupid '  
		 Print @Strsql  
		 Exec(@Strsql)  
  
  
		 Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'  
		 Select @Strsql = @Strsql + ' From ('  
		 Select @Strsql = @Strsql + ' Select T1.Groupid,T1.OperatorID,sum(ShiftProductionDetails.Prod_Qty *(ShiftProductionDetails.CO_StdMachiningTime+ShiftProductionDetails.CO_StdLoadUnload)) AS CN '  
		 Select @Strsql = @Strsql + ' From ShiftProductionDetails inner Join #ProdData T1 '  
		 Select @Strsql = @Strsql + ' on T1.OperatorID = ShiftProductionDetails.OperatorID and T1.Groupid =  ShiftProductionDetails.Groupid  where   
		 datepart(YEAR,Pdate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') and Datepart(Month,pDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
		 Select @Strsql = @Strsql+  @StrPlantID +@StrGroupid    
		 Select @Strsql = @Strsql + ' Group By T1.Groupid,T1.OperatorID '  
		 Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.OperatorID=T2.OperatorID and #ProdData.Groupid=T2.Groupid '  
		 Print @Strsql  
		 Exec(@Strsql)  
  
  
		 If isnull(@PlantID,'') <> ''  
		 Begin  
		 --Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'  
		 Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID in (' + @PlantID + '))' 
		 End  

		If isnull(@Groupid,'') <> ''  
		Begin  
		 --Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID = N''' + @GroupID + ''')'  
		 Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID  in (' + @GroupID + '))'
		End 
  
		 Select @Strsql =''  
		 SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '  
		 Select @Strsql = @Strsql+ 'From (SELECT groupid,OperatorID,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '  
		 Select @Strsql = @Strsql+ 'WHERE datepart(YEAR,ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''') and Datepart(Month,ddate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')  
		 and downid in (select downid from downcodeinformation where prodeffy = 1) '  
		 Select @Strsql = @Strsql+  @StrPlantID + @StrGroupid    
		 Select @Strsql = @Strsql+ ' Group By groupid,OperatorID'  
		 Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON T2.OperatorID=#ProdData.OperatorID and #ProdData.Groupid=T2.Groupid'  
		 print @StrSql  
		 EXEC(@StrSql)  
 
  
		 Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'  
		 Select @Strsql = @Strsql + ' From (select T1.Groupid,T1.OperatorID,(Sum(ShiftDowntimeDetails.DownTime))As DownTime'  
		 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join #ProdData T1 on T1.OperatorID = ShiftDowntimeDetails.OperatorID  and T1.Groupid =  ShiftDowntimeDetails.Groupid   
		 where datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')  and Datepart(Month,dDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'  
		 Select @Strsql = @Strsql+  @StrPlantID+ @StrGroupid    
		 Select @Strsql = @Strsql + ' Group By T1.Groupid,T1.OperatorID'  
		 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.OperatorID=T2.OperatorID and #ProdData.Groupid=T2.Groupid'  
		 Print @Strsql  
		 Exec(@Strsql)   
  
   
		 Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'  
		 Select @Strsql = @Strsql + 'from (select T1.Groupid,T1.OperatorID, sum(  
		   CASE   
		  WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0    
		  THEN isnull(ShiftDownTimeDetails.Threshold,0)  
		  ELSE ShiftDownTimeDetails.DownTime  
		   END) AS LOSS '  
		 Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner JOIN #ProdData T1 on T1.OperatorID = ShiftDowntimeDetails.OperatorID and T1.Groupid =  ShiftDowntimeDetails.Groupid 
		 where ML_flag = 1  
		 and datepart(YEAR,Ddate)= Datepart(YEAR,''' + convert(nvarchar(20),@StartDate,120)+ ''')  and Datepart(Month,dDate)=Datepart(Month,''' + convert(nvarchar(20),@StartDate,120)+ ''')'    
		 Select @Strsql = @Strsql+  @StrPlantID + @StrGroupid    
		 Select @Strsql = @Strsql + ' Group By T1.Groupid,T1.OperatorID'  
		 Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON  #ProdData.OperatorID=T2.OperatorID and #ProdData.Groupid=T2.Groupid'  
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

		select Groupid,OperatorID,round(OEffy,2) as OEffy,round(AEffy,2) as AEffy,round(PEffy,2) as PEffy ,round(QEffy,2) as QEffy From #ProdData order by Groupid,OperatorID  
END 

END
