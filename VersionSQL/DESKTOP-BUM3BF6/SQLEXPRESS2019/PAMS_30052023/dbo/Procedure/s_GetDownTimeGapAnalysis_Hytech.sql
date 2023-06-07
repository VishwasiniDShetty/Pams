/****** Object:  Procedure [dbo].[s_GetDownTimeGapAnalysis_Hytech]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************/
-- Author:		Anjana C V
-- Create date: 08 July 2019
-- Modified date: 08 July 2019
-- Description:  Get Aggregated BreakDown data at shift level for SONA
-- [s_GetDownTimeGapAnalysis_Hytech] '2019-02-01 06:00:00.000'
/************************************************************************************************************/ 
CREATE PROCEDURE [dbo].[s_GetDownTimeGapAnalysis_Hytech]
 @dDate DateTime,  
 @MachineID  nvarchar(50) = '', 
 @PlantID  nvarchar(50) = ''
AS  
BEGIN    
DECLARE @strsql nvarchar(4000)  
DECLARE @StrMachineID  nvarchar(50)  
DECLARE @StrPlantID  nvarchar(50)  
DECLARE @StOfMonth DATETIME
declare @i as nvarchar(10)
declare @colName as nvarchar(50)

SELECT @strsql =''
SELECT @StrMachineID =''
SELECT @StrPlantID =''
Select @i=1

CREATE TABLE #FinalTarget
(
	DMonth nvarchar(50),
	Ddate DateTime,
	Startdate DateTime, 
	Enddate DateTime, 
	PlantID nvarchar(50),
	MachineID nvarchar(50),
	MachineIntf nvarchar(50),
	Target float,
	UtilisedTime  Float DEFAULT 0,  
	DownTime  Float DEFAULT 0,  
	CN  Float DEFAULT 0,  
	ManagementLoss float default 0,  
	DowntimeAE float default 0 ,
	ProdCount Int DEFAULT 0,  
	AcceptedParts Int DEFAULT 0,  
	RejCount  Int DEFAULT 0,  
	ReworkPerformed Int DEFAULT 0,  
	MarkedForRework Int DEFAULT 0,  
	AEffy float,
	PEffy float,
	QEffy float,
	OEffy float,
	D1 float,
	D2 float,
	D3 float,
	D4 float,
	D5 float,
	D6 float,
	D7 float,
	D8 float,
	D9 float,
	D10 float,
	D11 float,
	D12 float,
	D13 float,
	D14 float,
	D15 float,
	D16 float
)

Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50),
	InterfaceId nvarchar(50),
)

CREATE TABLE #TimePeriodDetails    
(    
	StartDate  DateTime,    
	EndDate DateTime  
)

if isnull(@machineid,'') <> ''  
Begin  
	Select @strmachineid = ' and ( M.MachineID = N''' + @MachineID + ''')'  
End

if isnull(@PlantID,'') <> ''  
Begin  
	Select @StrPlantID = ' and ( P.PlantId = N''' + @PlantID + ''')'  
End 
 
Insert into #Downcode(Downid,InterfaceId)
Select top 16 downid,InterfaceId 
 from downcodeinformation 
 where SortOrder<=16 and ( isnull(SortOrder,0) <> 0) order by sortorder

SELECT @StOfMonth=[dbo].f_GetLogicalMonth(@dDate,'Start') 
print '---@StOfMonth---'
print @StOfMonth
WHILE @StOfMonth < [dbo].f_GetLogicalMonth(@dDate,'End')
BEGIN
    Insert Into #TimePeriodDetails(StartDate,EndDate)
	SELECT @StOfMonth,[dbo].f_GetLogicalDayEnd(Dateadd(MINUTE,1,@StOfMonth))
    SELECT @StOfMonth=Dateadd(DAY,1,@StOfMonth)
END

Select @Strsql =''        
        
Select @Strsql ='Insert Into #FinalTarget(MachineID,MachineIntf,PlantID,DMonth,Ddate,StartDate,EndDate)'        
Select @Strsql =@Strsql+' Select   Distinct M.MachineID,M.InterfaceId,P.PlantId ,
						 convert(CHAR(4), T.StartDate, 100) + CONVERT(CHAR(4), T.StartDate, 120)  , 
						 convert(nvarchar(10),T.StartDate,120),T.StartDate, T.EndDate
						 From MachineInformation M
						 Left Outer Join PlantMachine P ON M.MachineID=P.MachineID
						 CROSS JOIN #TimePeriodDetails T
						 Where M.MachineID Is Not NULL'        
Select @Strsql =@Strsql+@StrPlantID+@StrMachineID
Select @Strsql =@Strsql+' Order By M.MachineID'        
print @Strsql        
Exec (@Strsql) 

If isnull(@PlantID,'') <> ''  
Begin  
	Select @StrPlantID = ' And ( SP.PlantID = N''' + @PlantID + ''' )'  
End  
  
If isnull(@Machineid,'') <> ''  
Begin  
	Select @StrmachineId = ' And ( SP.MachineID = N''' + @MachineID + ''')'  
End 
 
Select @Strsql = ''
Select @Strsql = 'Update #FinalTarget 
				Set ProdCount=ISNULL(T2.ProdCount,0), 
				AcceptedParts=ISNULL(T2.AcceptedParts,0),
				ReworkPerformed=ISNULL(T2.Rework_Performed,0), 
				MarkedForRework=ISNULL(T2.MarkedForRework,0),
				UtilisedTime=ISNULL(T2.UtilisedTime,0)
				From( 
				 Select T1.MachineID,T1.dDate,Sum(ISNULL(SP.Prod_Qty,0))ProdCount,Sum(ISNULL(SP.AcceptedParts,0))AcceptedParts,   
				 Sum(ISNULL(SP.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(SP.Marked_For_Rework,0)) AS MarkedForRework,Sum(SP.Sum_of_ActCycleTime)As UtilisedTime  
                 From ShiftProductionDetails SP inner Join #FinalTarget T1 on T1.MachineID =  SP.Machineid 
				 where T1.Ddate = convert(nvarchar(10),SP.Pdate,120) '   
 Select @Strsql = @Strsql+  @StrPlantID + @StrmachineId 
 Select @Strsql = @Strsql+ ' GROUP By T1.MachineID,T1.dDate
							 )As T2 Right Outer Join #FinalTarget ON #FinalTarget.MachineID=T2.MachineID 
							 AND #FinalTarget.dDate=T2.dDate '  
 Print @Strsql  
 Exec(@Strsql)  
  
Select @Strsql = '' 
 Select @Strsql = 'UPDATE #FinalTarget SET RejCount=ISNULL(T2.Rej,0) 
				   FROM( 
				    Select T1.MachineID,T1.dDate,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej
					From ShiftProductionDetails SP inner Join #FinalTarget T1 on T1.machineid = SP.machineid  
					Left Outer Join ShiftRejectionDetails ON SP.ID=ShiftRejectionDetails.ID
					Where T1.Ddate = convert(nvarchar(10),SP.Pdate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID + @StrmachineId 
 Select @Strsql = @Strsql+' Group By T1.MachineID,T1.dDate
						  )AS T2 Inner Join #FinalTarget ON #FinalTarget.MachineID=T2.MachineID 
							 AND #FinalTarget.dDate=T2.dDate '  
 Print @Strsql  
 Exec(@Strsql)  
  
 Select @Strsql = '' 
 Select @Strsql = 'Update #FinalTarget Set CN=ISNULL(T2.CN,0)
					From (
					 Select T1.MachineID,T1.dDate,sum(SP.Prod_Qty *(SP.CO_StdMachiningTime+SP.CO_StdLoadUnload)) AS CN 
					 From ShiftProductionDetails SP inner Join #FinalTarget T1 
					 on T1.machineid = SP.machineid 
					 where  T1.Ddate = convert(nvarchar(10),SP.Pdate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID + @StrmachineId 
 Select @Strsql = @Strsql + ' Group By T1.MachineID,T1.dDate 
							 )AS T2 Inner Join #FinalTarget ON #FinalTarget.MachineID=T2.MachineID 
							 AND #FinalTarget.dDate=T2.dDate '  
 Print @Strsql  
 Exec(@Strsql)  

   --UPDATE #FinalTarget SET Target=
  --(DATEDIFF(second, Startdate, Enddate)/componentoperationpricing.cycletime) as TotalProdQty
 
 Select @Strsql = ''
 Select @Strsql = 'Update #FinalTarget Set Target=ISNULL(T2.tcount,0)
					From ( 
					SELECT F.MachineID,F.dDate,
					SUM(T.tcount) as tcount
					--((datediff(second,T1.StartDate,T1.EndDate)*SUM(T.suboperations))/SUM(T.cycletime))*isnull(SUM(T.targetpercent),100) /100 as tcount
					FROM #FinalTarget F
					INNER JOIN (
					select DISTINCT CO.componentid as component,CO.Operationno as operation,CO.machineid,T1.Ddate,
					--CO.suboperations,CO.cycletime,CO.targetpercent
					((datediff(second,T1.StartDate,T1.EndDate)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100 as tcount
					from ShiftProductionDetails SP
					inner Join #FinalTarget T1 on T1.machineid = SP.machineid and T1.Ddate = SP.Pdate 
					inner Join componentoperationpricing CO on CO.Componentid=SP.Componentid and Co.operationno=SP.operationno and SP.machineid=CO.machineid ' 
					Select @Strsql = @Strsql+  @StrPlantID + @StrmachineId 
					Select @Strsql = @Strsql + ' ) T ON F.MachineID=T.MachineID  AND F.dDate=T.dDate 
					    Group By F.MachineID,F.dDate 
						)AS T2 Inner Join #FinalTarget ON #FinalTarget.MachineID=T2.MachineID 
						AND #FinalTarget.dDate=T2.dDate '  
 Print @Strsql  
 Exec(@Strsql)  


 If isnull(@PlantID,'') <> ''  
 Begin  
 Select @StrPlantID = ' And ( SD.PlantID = N''' + @PlantID + ''' )'  
 End  
  
 If isnull(@Machineid,'') <> ''  
 Begin  
 Select @StrMachineID = ' And ( SD.MachineID = N''' + @MachineID + ''')'  
 End  

 Select @Strsql =''  
 SELECT @StrSql='UPDATE #FinalTarget SET UtilisedTime = Isnull(#FinalTarget.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) 
				 From (
				  SELECT T1.MachineID,T1.dDate,sum(datediff(s,starttime,endtime)) as MinorDownTime 
				  FROM ShiftDownTimeDetails SD
				  Inner Join #FinalTarget T1 on T1.machineid = SD.machineid    
				  WHERE T1.Ddate = convert(nvarchar(10),SD.Ddate,120)  
				  and downid in (select downid from downcodeinformation where prodeffy = 1) '  
 Select @Strsql = @Strsql+  @StrPlantID + @StrmachineId 
 Select @Strsql = @Strsql+ ' Group By T1.MachineID,T1.dDate
				 ) as T2 Inner Join #FinalTarget ON T2.MachineID=#FinalTarget.MachineID
							 AND #FinalTarget.dDate=T2.dDate '  
 print @StrSql  
 EXEC(@StrSql)  
  
 Select @Strsql = '' 
 Select @Strsql = 'UPDATE #FinalTarget SET DownTime = IsNull(T2.DownTime,0) 
				   From (
					select T1.MachineID,T1.dDate,(Sum(SD.DownTime))As DownTime
					From ShiftDownTimeDetails SD Inner Join #FinalTarget T1 on T1.machineid = SD.machineid    
					where T1.Ddate = convert(nvarchar(10),SD.Ddate,120) '  
 Select @Strsql = @Strsql+  @StrPlantID + @StrmachineId 
 Select @Strsql = @Strsql + ' Group By T1.MachineID,T1.dDate 
							 ) AS T2 Inner Join #FinalTarget ON #FinalTarget.MachineID=T2.MachineID
							 AND #FinalTarget.dDate=T2.dDate '  
 Print @Strsql  
 Exec(@Strsql)   
  
 Select @Strsql = '' 
 Select @Strsql = 'UPDATE #FinalTarget SET ManagementLoss =  isNull(T2.loss,0)
				  from (
					select T1.Machineid,T1.dDate, sum(  CASE  WHEN (SD.DownTime) > isnull(SD.Threshold,0) and isnull(SD.Threshold,0) > 0    
					THEN isnull(SD.Threshold,0)   ELSE SD.DownTime   END) AS LOSS 
					From ShiftDownTimeDetails SD inner JOIN #FinalTarget T1 on T1.machineid = SD.machineid where ML_flag = 1  
					and T1.Ddate = convert(nvarchar(10),SD.Ddate,120)'    
 Select @Strsql = @Strsql+  @StrPlantID + @StrmachineId 
 Select @Strsql = @Strsql + ' Group By T1.MachineID,T1.dDate 
					 ) AS T2 Inner Join #FinalTarget ON  #FinalTarget.MachineID=T2.MachineID 
							 AND #FinalTarget.dDate=T2.dDate '  
 Print @Strsql  
 Exec(@Strsql)   
   
 UPDATE #FinalTarget SET DownTime=DownTime-ManagementLoss   

 UPDATE #FinalTarget SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)  
 Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0  
  
 UPDATE #FinalTarget  
 SET   PEffy = (CN/UtilisedTime) ,  
	   AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))  
 WHERE UtilisedTime <> 0  

 UPDATE #FinalTarget  
 SET 
  OEffy = PEffy * AEffy * QEffy * 100,  
  PEffy = PEffy * 100 ,  
  AEffy = AEffy * 100,  
  QEffy = QEffy * 100  

while @i <=16
Begin

 Select @ColName = Case when @i=1 then 'D1'
						when @i=2 then 'D2'
						when @i=3 then 'D3'
						when @i=4 then 'D4'
						when @i=5 then 'D5'
						when @i=6 then 'D6'
						when @i=7 then 'D7'
						when @i=8 then 'D8'
						when @i=9 then 'D9'
						when @i=10 then 'D10'
						when @i=11 then 'D11'
						when @i=12 then 'D12'
						when @i=13 then 'D13'
						when @i=14 then 'D14'
						when @i=15 then 'D15'
						when @i=16 then 'D16' 
					END

			Select @strsql = ''
			Select @strsql = @strsql + ' UPDATE  #FinalTarget SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t1.down,0)  
			from  
			( select SD.dDate,SD.MachineID,
            Sum(SD.DownTime) As Down
			from ShiftDownTimeDetails SD    
			inner join  #FinalTarget F on SD.MachineID = F.MachineID 
			inner join downcodeinformation on SD.downid=downcodeinformation.downid 
			inner join #Downcode on #Downcode.downid= downcodeinformation.downid	
			Where SD.dDate= F.dDate  AND  #Downcode.Slno= ' + @i + '  
			group by SD.dDate,SD.MachineID )
			as t1 Inner Join #FinalTarget ON #FinalTarget.dDate=T1.dDate  And #FinalTarget.MachineID=T1.MachineID '	
			Select @Strsql = @Strsql+  @StrPlantID + @StrmachineId 
			print @strsql
			exec(@Strsql)

			select @i  =  @i + 1
END  

SELECT * FROM #downcode ORDER BY Slno 

SELECT * FROM #FINALTARGET ORDER BY MachineID,Ddate

END
