/****** Object:  Procedure [dbo].[s_GetAgg_OEEAndLossTimeReport_TAFE]    Committed by VersionSQL https://www.versionsql.com ******/

-- [dbo].[s_GetAgg_OEEAndLossTimeReport_TAFE] '2019-01-01 00:00:00.000'
CREATE  PROCEDURE [dbo].[s_GetAgg_OEEAndLossTimeReport_TAFE]
 @StartDate As DateTime,
 @MachineID As nvarchar(50) = ''
AS
BEGIN

 Declare @Strsql nvarchar(4000)
 Declare @Strmachine nvarchar(255)
 Declare @timeformat AS nvarchar(12)
 
 Select @Strsql = ''
 Select @Strmachine = ''
 Select @timeformat ='mm'

If isnull(@Machineid,'') <> ''
	Begin
		Select @Strmachine = ' And ( S.MachineID = N''' + @MachineID + ''')'
	End

Create Table #Target
(
Day DateTime,
StDay DateTime,
EndDay DateTime,
PlantID  NVarChar(50),
MachineID  NVarChar(50),
AvlTotalTime float,
AvlTime float,
D1  float,
D2  float,
D3  float,
D4  float,
D5  float,
D6  float,
D7  float,
D8  float,
D9  float,
D10  float,
D11  float,
D12  float,
D13  float,
D14  float,
D15  float,
D16  float,
D17  float,
D18  float,
D19  float, 
Hold float,
RejMat float,
RejPro float,
Hold_loss float,
RejMat_loss float,
RejPro_loss float,
LoadingTime float,
OperatingTime float,
NetOperatingTime float,
ValuableOperatingTime float,
AEffy  Float,
PEffy  Float,
QEffy  Float,
OEffy  Float,
StdCycleTime  Float,
UtilisedTime  Float,
DownTime  Float,
MgmtLoss  Float,
DownTimeAE Float,
CN  Float,
AcceptedParts Int,
RejCount  Int,
MarkedForRework Int
)

Create Table #FinalTarget
(
Day DateTime,
Tot_AvlTotalTime float,
Tot_AvlTime float,
D1  float,
D2  float,
D3  float,
D4  float,
D5  float,
D6  float,
D7  float,
D8  float,
D9  float,
D10  float,
D11  float,
D12  float,
D13  float,
D14  float,
D15  float,
D16  float,
D17  float,
D18  float,
D19  float, 
Tot_Hold float,
Tot_RejMat float,
Tot_RejPro float,
Tot_Hold_loss float,
Tot_RejMat_loss float,
Tot_RejPro_loss float,
LoadingTime float,
OperatingTime float,
NetOperatingTime float,
ValuableOperatingTime float,
Tot_AEffy  Float,
Tot_PEffy  Float,
Tot_QEffy  Float,
Tot_OEffy  Float
)

Create Table #FinalData
(
TotalTime float,
AvlTime float,
PlantClosure float,
LoadingTime  float,
Others float,
NoPronPlanned float,
OperatingTime float,
DownTime float,
NetOperatingTime float,
SpeedLoss  float,
ValuableOperatingTime float,
QualityLoss float
)

Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50),
	InterfaceId nvarchar(50),
	Catagory nvarchar(50),
	DownCatagory nvarchar(50)
)

Insert into #Downcode(Downid,InterfaceId,Catagory)
Select  downid,InterfaceId,Catagory from downcodeinformation
where interfaceid in ('4','7','9','18','19','20','21','22','23','24','25','26','27','28','29','31','32','33')
order by sortorder

Update #Downcode
set  DownCatagory = 'No PRODUCTION'
WHERE InterfaceId in ('7','9','18','19','20','21','22','23')

Update #Downcode
set  DownCatagory = 'BREAK DOWN'
WHERE InterfaceId in ('4','24','25','26','27')

Update #Downcode
set  DownCatagory = 'SPEED LOSS'
WHERE InterfaceId in ('28','29','31','32','33')

Select @Strsql=''
Select @Strsql = 'Insert Into #Target (Day,StDay,EndDay,PlantID,MachineID,AvlTotalTime,AvlTime,AcceptedParts,MarkedForRework)
				 SELECT Distinct S.pDate, dbo.f_GetLogicalDayStart(S.pDate), dbo.f_GetLogicalDayEnd(S.pDate),
				 S.PlantID,S.MachineID,DateDiff(MINUTE, dbo.f_GetLogicalDayStart(S.pDate), dbo.f_GetLogicalDayEnd(S.pDate)),
				-- DateDiff(MINUTE, dbo.f_GetLogicalDayStart(S.pDate), dbo.f_GetLogicalDayEnd(S.pDate)) ,
				0,
				 Sum(ISNULL(AcceptedParts,0)),Sum(ISNULL(Marked_For_Rework,0))
				 from ShiftProductionDetails S
				 Where S.pDate='''+Convert(NvarChar(20),@StartDate)+''' ' 
Select @Strsql=@Strsql+@Strmachine
Select @Strsql=@Strsql+' Group By S.pDate,S.PlantID,S.MachineID'
				 print @Strsql
	             Exec(@Strsql)

Select @Strsql=''
Select @Strsql = 'Insert Into #Target (Day,StDay,EndDay,PlantID,MachineID,AvlTotalTime,AvlTime)
				 SELECT Distinct S.dDate, dbo.f_GetLogicalDayStart(S.dDate), dbo.f_GetLogicalDayEnd(S.dDate),
				  S.PlantID,S.MachineID,DateDiff(MINUTE, dbo.f_GetLogicalDayStart(S.dDate), dbo.f_GetLogicalDayEnd(S.dDate)),
				 -- DateDiff(MINUTE, dbo.f_GetLogicalDayStart(S.dDate), dbo.f_GetLogicalDayEnd(S.dDate)) 
				  0
				  from ShiftDownTimeDetails S
				  Where S.dDate='''+Convert(NvarChar(20),@StartDate)++'''
		          And Convert(NvarChar(20),dDate)+MachineID  NOT IN
		          (SELECT Convert(Nvarchar(20),Day)+MachineID From #Target)' 
Select @Strsql=@Strsql+@Strmachine

print @Strsql
Exec(@Strsql)


  UPDATE  #Target SET StdCycleTime = t1.StdCycleTime
      From(
		  select distinct  pDate,MachineID,
		  (CO_StdMachiningTime+CO_StdLoadUnload) StdCycleTime
		  From ShiftProductionDetails
		  Where pDate=Convert(NvarChar(20),@StartDate)
	  )AS T1 Inner Join #Target ON #Target.[Day]=T1.Pdate And  #Target.MachineID=T1.MachineID
--=====================================================================================================================================--
   UPDATE #Target SET CN=ISNULL(T1.CN,0) 
	From(
		Select Pdate,MachineID ,sum(Prod_Qty * (CO_StdMachiningTime+CO_StdLoadUnload)) as  CN
		From ShiftProductionDetails 
		Where Pdate=Convert(NvarChar(20),@StartDate)
		Group By Pdate,MachineID )AS T1 Inner Join #Target ON #Target.[Day]=T1.Pdate And  #Target.MachineID=T1.MachineID

-- Calculate UtilisedTime for Date-Machine
	UPDATE #Target SET UtilisedTime = Isnull(#Target.UtilisedTime,0)+IsNull(T1.UtilisedTime,0)
	From (select pDate,MachineID,Sum(Sum_of_ActCycleTime)As UtilisedTime
	From ShiftProductionDetails
	Where pDate=Convert(NvarChar(20),@StartDate)
	Group By pDate,MachineID
	) as T1 Inner Join #Target ON #Target.[Day]=T1.pDate  And #Target.MachineID=T1.MachineID	

	UPDATE #Target SET UtilisedTime = Isnull(#Target.UtilisedTime,0)+IsNull(T1.MinorDownTime,0)
	From (SELECT ddate,MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime
	FROM ShiftDownTimeDetails WHERE PE_Flag = 1--downid in (select downid from downcodeinformation where prodeffy = 1)
	and ddate=Convert(NvarChar(20),@StartDate)
	group by ddate,machineid
	) as T1 Inner Join #Target ON #Target.[Day]=T1.ddate And #Target.MachineID=T1.MachineID
--=====================================================================================================================================--
	UPDATE #Target SET DownTimeAE = Isnull(#Target.DownTimeAE,0)+IsNull(T1.DownTime,0)
	 From (select dDate,MachineID,
	 Sum(DownTime)As DownTime
	 From ShiftDownTimeDetails 
	 where ddate=Convert(NvarChar(20),@StartDate)
	 Group By dDate,MachineID
	 ) as T1 Inner Join #Target ON #Target.[Day]=T1.dDate  And #Target.MachineID=T1.MachineID
         
 UPDATE #Target SET MgmtLoss = Isnull(#Target.MgmtLoss,0)+IsNull(T1.LOSS,0)
  From (
     select dDate,MachineID,
	 sum(
	 CASE
	 WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
	 THEN isnull(ShiftDownTimeDetails.Threshold,0)
	 ELSE ShiftDownTimeDetails.DownTime
	 END) AS LOSS
	 From ShiftDownTimeDetails
	 where ddate=Convert(NvarChar(20),@StartDate)
	 and ShiftDownTimeDetails.Ml_Flag=1
	 Group By dDate,MachineID
 ) as T1 Inner Join #Target ON #Target.[Day]=T1.dDate And #Target.MachineID=T1.MachineID

	UPDATE #Target SET DownTime = Isnull(#Target.Downtime,0) + IsNull(T1.DownTime,0)
	 From (select dDate,MachineID,
	 Sum(DownTime)As DownTime
	 From ShiftDownTimeDetails
	 where ddate=Convert(NvarChar(20),@StartDate)
	 Group By dDate,MachineID
	) as T1 Inner Join #Target ON #Target.[Day]=T1.dDate  And #Target.MachineID=T1.MachineID

 UPDATE #Target SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0)	
--=====================================================================================================================================--
UPDATE #Target SET RejCount=ISNULL(T1.Rej,0) 
 FROM(
	Select pDate,SD.MachineID,Sum(isnull(Rejection_Qty,0))Rej
	From ShiftProductionDetails SD 
	Left Outer Join ShiftRejectionDetails ON SD.ID=ShiftRejectionDetails.ID 
	Where pDate = Convert(NvarChar(20),@StartDate)
	Group By pDate,SD.MachineID	
 )AS T1 Inner Join #Target ON #Target.[Day]=T1.pDate And  #Target.MachineID=T1.MachineID 
		
 --=====================================================================================================================================--
--UPDATE #Target  set AvlTime = dbo.f_FormatTime((isnull(Utilisedtime,0) + isnull(DownTimeAE,0)) ,'mm')
UPDATE #Target  set AvlTime = dbo.f_FormatTime((isnull(Utilisedtime,0) + isnull(DownTimeAE,0)) ,'mm')

 UPDATE #Target SET AvlTime = AvlTime - dbo.f_FormatTime(isnull(T1.PDT,0),'mm')     
 from    
 (
  Select Machine,SUM(datediff(S, S.StartTime, S.EndTime)) as PDT ,T.[Day]
  from PlannedDownTimes S  
  inner join #Target T on T.MachineID = S.Machine and (S.StartTime>=T.StDay and S.EndTime<=T.EndDay)
  group by machine,T.[Day]
  )T1    
  Inner Join #Target on T1.Machine=#Target.Machineid and T1.[Day]=#Target.[Day]
--=====================================================================================================================================--

declare @i as nvarchar(10)
declare @colName as nvarchar(50)
Select @i=1


while @i <=19
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
						when @i=17 then 'D17'
						when @i=18 then 'D18'
					--	when @i=19 then 'D19'
					END

			Select @strsql = ''
			Select @strsql = @strsql + ' UPDATE  #Target SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t1.down,0)  
			from  
			( select dDate,ShiftDownTimeDetails.MachineID,
            Sum(ShiftDownTimeDetails.DownTime) As Down
			from ShiftDownTimeDetails    
			inner join  #Target F on ShiftDownTimeDetails.MachineID = F.MachineID 
			inner join downcodeinformation on ShiftDownTimeDetails.downid=downcodeinformation.downid 
			inner join #Downcode on #Downcode.downid= downcodeinformation.downid	
			Where ShiftDownTimeDetails.dDate='''+Convert(NvarChar(20),@StartDate)++'''
			 AND  #Downcode.Slno= ' + @i + '  
			group by dDate,ShiftDownTimeDetails.MachineID )
			as t1 Inner Join #Target ON #Target.[Day]=T1.dDate  And #Target.MachineID=T1.MachineID '	

			print @strsql
			exec(@Strsql)


	       select @i  =  @i + 1
END

UPDATE  #Target SET D19 = isNull(Utilisedtime,0)  - isNull(StdCycleTime,0)

--=====================================================================================================================================--
UPDATE #Target SET LoadingTime = AvlTime - dbo.f_FormatTime((D1+ D2+D3+D4+D5+D6+D7+D8),@TimeFormat), 
 OperatingTime =AvlTime - dbo.f_FormatTime(((D1+D2+D3+D4+D5+D6+D7+D8) + ( D9+D10+D11+D12+D13)),@TimeFormat),
 NetOperatingTime  = AvlTime - dbo.f_FormatTime((((D1+D2+D3+D4+D5+D6+D7+D8) + ( D9+D10+D11+D12+D13)) + (D14+D15+D16+D17+D18+D19)),@TimeFormat)
--=====================================================================================================================================--


UPDATE #Target SET Hold=ISNULL(T1.Hold,0) 
 FROM(
	Select pDate,SD.MachineID,Sum(isnull(Rejection_Qty,0)) Hold
	From ShiftProductionDetails SD 
	Left Outer Join ShiftRejectionDetails ON SD.ID=ShiftRejectionDetails.ID 
	Where pDate = Convert(NvarChar(20),@StartDate)
	and ShiftRejectionDetails.Rejection_Reason = 'Hold'
	Group By pDate,SD.MachineID	
 )AS T1 Inner Join #Target ON #Target.[Day]=T1.pDate And  #Target.MachineID=T1.MachineID 

 UPDATE #Target SET RejMat=ISNULL(T1.RejMat,0) 
 FROM(
	Select pDate,SD.MachineID,Sum(isnull(Rejection_Qty,0)) RejMat
	From ShiftProductionDetails SD 
	Left Outer Join ShiftRejectionDetails ON SD.ID=ShiftRejectionDetails.ID 
	Where pDate = Convert(NvarChar(20),@StartDate)
	and ShiftRejectionDetails.Rejection_Reason = 'RejMat'
	Group By pDate,SD.MachineID	
 )AS T1 Inner Join #Target ON #Target.[Day]=T1.pDate And  #Target.MachineID=T1.MachineID 

 UPDATE #Target SET RejPro=ISNULL(T1.RejPro,0) 
 FROM(
	Select pDate,SD.MachineID,Sum(isnull(Rejection_Qty,0)) RejPro
	From ShiftProductionDetails SD 
	Left Outer Join ShiftRejectionDetails ON SD.ID=ShiftRejectionDetails.ID 
	Where pDate = Convert(NvarChar(20),@StartDate)
	and ShiftRejectionDetails.Rejection_Reason = 'RejPro'
	Group By pDate,SD.MachineID	
 )AS T1 Inner Join #Target ON #Target.[Day]=T1.pDate And  #Target.MachineID=T1.MachineID 

 -- UPDATE #Target SET ValuableOperatingTime = (Hold+RejMat+RejPro)
--================================================ --
  UPDATE #Target SET Hold_loss=ISNULL(T1.Hold_loss,0) 
 FROM(
	Select pDate,SD.MachineID,Sum(isnull(Rejection_Qty,0) * (CO_StdMachiningTime+CO_StdLoadUnload)) Hold_loss
	From ShiftProductionDetails SD 
	Left Outer Join ShiftRejectionDetails ON SD.ID=ShiftRejectionDetails.ID 
	Where pDate = Convert(NvarChar(20),@StartDate)
	and ShiftRejectionDetails.Rejection_Reason = 'Hold'
	Group By pDate,SD.MachineID	
 )AS T1 Inner Join #Target ON #Target.[Day]=T1.pDate And  #Target.MachineID=T1.MachineID 

 UPDATE #Target SET RejMat_loss=ISNULL(T1.RejMat_loss,0) 
 FROM(
	Select pDate,SD.MachineID,Sum(isnull(Rejection_Qty,0) * (CO_StdMachiningTime+CO_StdLoadUnload)) RejMat_loss
	From ShiftProductionDetails SD 
	Left Outer Join ShiftRejectionDetails ON SD.ID=ShiftRejectionDetails.ID 
	Where pDate = Convert(NvarChar(20),@StartDate)
	and ShiftRejectionDetails.Rejection_Reason = 'RejMat'
	Group By pDate,SD.MachineID	
 )AS T1 Inner Join #Target ON #Target.[Day]=T1.pDate And  #Target.MachineID=T1.MachineID 

 UPDATE #Target SET RejPro_loss=ISNULL(T1.RejPro_loss,0) 
 FROM(
	Select pDate,SD.MachineID,Sum(isnull(Rejection_Qty,0) * (CO_StdMachiningTime+CO_StdLoadUnload)) RejPro_loss
	From ShiftProductionDetails SD 
	Left Outer Join ShiftRejectionDetails ON SD.ID=ShiftRejectionDetails.ID 
	Where pDate = Convert(NvarChar(20),@StartDate)
	and ShiftRejectionDetails.Rejection_Reason = 'RejPro'
	Group By pDate,SD.MachineID	
 )AS T1 Inner Join #Target ON #Target.[Day]=T1.pDate And  #Target.MachineID=T1.MachineID 

  UPDATE #Target SET ValuableOperatingTime =  AvlTime - dbo.f_FormatTime((((D1+D2+D3+D4+D5+D6+D7+D8) + ( D9+D10+D11+D12+D13)) + (D14+D15+D16+D17+D18+D19) + (Hold_loss+RejMat_loss+RejPro_loss)),@TimeFormat)
  
--=====================================================================================================================================--
/*
UPDATE #Target SET QEffy=IsNull(T1.QE,0)
 FROM(Select [Day],MachineID,
 CAST((Sum(AcceptedParts))As Float)/CAST((Sum(AcceptedParts)+Sum(RejCount)+Sum(MarkedForRework)) AS Float)As QE
 From #Target 
 where AcceptedParts>0 
 Group By [Day],MachineID )AS T1 Inner Join #Target ON #Target.[Day]=T1.[Day] And #Target.MachineID=T1.MachineID

UPDATE #Target
 SET  PEffy = (CN/UtilisedTime),
 AEffy = (UtilisedTime)/(UtilisedTime +ISNULL( DownTimeAE,0)-isnull(MgmtLoss,0))
*/
UPDATE #Target
 SET PEffy = ( OperatingTime/LoadingTime),
 AEffy = ( NetOperatingTime/LoadingTime)
 where ISNULL(LoadingTime,0) <> 0

 UPDATE #Target
 SET  QEffy= ( ValuableOperatingTime/NetOperatingTime)
 where ISNULL(NetOperatingTime,0) <> 0

 UPDATE #Target
 SET OEffy = PEffy * AEffy * QEffy * 100,
	 PEffy = PEffy * 100 ,
	 AEffy = AEffy * 100,
	 QEffy = QEffy * 100
--=====================================================================================================================================--
insert into #FinalTarget (Day,Tot_AvlTotalTime,Tot_AvlTime, D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11,D12,D13,
D14,D15,D16,D17,D18,D19,Tot_Hold,Tot_RejMat,Tot_RejPro,Tot_Hold_loss,Tot_RejMat_loss,Tot_RejPro_loss,LoadingTime,OperatingTime,
NetOperatingTime,ValuableOperatingTime,Tot_AEffy,Tot_PEffy,Tot_QEffy,Tot_OEffy )
select Day ,sum(AvlTotalTime) ,sum(AvlTime) ,sum(D1) ,sum(D2) ,sum(D3) ,sum(D4) ,sum(D5) ,sum(D6) ,sum(D7) ,sum(D8) ,sum(D9) ,sum(D10) ,sum(D11) ,
sum(D12) ,sum(D13) ,sum(D14) ,sum(D15) ,sum(D16) ,sum(D17) ,sum(D18) ,sum(D19) ,sum( Hold) ,sum(RejMat) ,sum(RejPro) ,sum( Hold_loss) ,sum(RejMat_loss) ,sum(RejPro_loss) ,
sum(LoadingTime) ,sum(OperatingTime) ,sum(NetOperatingTime) ,sum(ValuableOperatingTime) ,AVG(AEffy) ,AVG(PEffy) ,AVG(QEffy) ,AVG(OEffy) 
from #Target
group by Day

insert into #FinalData ( TotalTime,AvlTime,PlantClosure,LoadingTime,Others,NoPronPlanned )
--,Others,NoPronPlanned,DownTime,SpeedLoss ,QualityLoss)
SELECT Tot_AvlTotalTime,((Tot_AvlTime/Tot_AvlTotalTime)*100) as AvailableTime,
(((Tot_AvlTotalTime - Tot_AvlTime)/Tot_AvlTotalTime)*100) as PlantClosureTime,
((LoadingTime/Tot_AvlTotalTime)*100) as LoadingTime ,
((D1+D2+D6+D7+D8)/Tot_AvlTotalTime) * 100 AS Others ,
((D3+D4+D5)/Tot_AvlTotalTime) * 100 AS NoPronPlanned
from #FinalTarget
WHERE ISNULL(Tot_AvlTotalTime,0) <> 0

UPDATE #FinalData
SET OperatingTime = T.OperatingTime,
NetOperatingTime = T.NetOperatingTime,
ValuableOperatingTime = T.ValuableOperatingTime
from 
(
SELECT ((OperatingTime/LoadingTime)*100) as OperatingTime,
((NetOperatingTime/LoadingTime)*100) as NetOperatingTime,
((ValuableOperatingTime/LoadingTime)*100) as ValuableOperatingTime
from #FinalTarget
where ISNULL(LoadingTime,0) <> 0
)T

UPDATE #FinalData
SET DownTime = t.DownTime,
SpeedLoss =t.SpeedLoss,
QualityLoss = t.QualityLoss
FROM 
(
select ((D9+D10+D11+D12+D13)/Tot_AvlTime) * 100 as DownTime,
((D14+D15+D16+D17+D18+19)/Tot_AvlTime) * 100 as SpeedLoss,
((Tot_Hold_loss+Tot_RejMat_loss+Tot_RejPro_loss)/Tot_AvlTime) * 100 as QualityLoss
from #FinalTarget
where ISNULL(Tot_AvlTime,0) <> 0
)t

Insert into #Downcode(Downid,InterfaceId,Catagory,DownCatagory)
values ('VARIATION IN CYCLE TIME','100','SPEED LOSS','SPEED LOSS')

select * from #downcode ORDER BY Slno 

SELECT Day,PlantID,MachineID,AvlTotalTime,AvlTime,dbo.f_FormatTime(D1,@TimeFormat) as D1,dbo.f_FormatTime(D2,@TimeFormat) as D2 ,dbo.f_FormatTime(D3,@TimeFormat) as D3,
dbo.f_FormatTime(D4,@TimeFormat) as D4 ,dbo.f_FormatTime(D5,@TimeFormat) as D5,dbo.f_FormatTime(D6,@TimeFormat) as D6,dbo.f_FormatTime(D7,@TimeFormat) as D7 ,
dbo.f_FormatTime(D8,@TimeFormat) as D8, dbo.f_FormatTime(D9,@TimeFormat) as D9,dbo.f_FormatTime(D10,@TimeFormat) as D10, dbo.f_FormatTime(D11,@TimeFormat) as D11,
dbo.f_FormatTime(D12,@TimeFormat) as D12,dbo.f_FormatTime(D13,@TimeFormat) as D13, dbo.f_FormatTime(D14,@TimeFormat) as D14,dbo.f_FormatTime(D15,@TimeFormat) as D15,
dbo.f_FormatTime(D16,@TimeFormat) as D16,dbo.f_FormatTime(D17,@TimeFormat) as D17 ,dbo.f_FormatTime(D18,@TimeFormat) as D18, dbo.f_FormatTime(D19,@TimeFormat) as D19,
ISNULL(Hold,0) AS Hold,ISNULL(RejMat,0) AS RejMat,ISNULL(RejPro,0) AS RejPro,
ISNULL(LoadingTime,0) AS LoadingTime,ISNULL(OperatingTime,0) AS OperatingTime,
ISNULL(NetOperatingTime,0) AS NetOperatingTime,ISNULL(ValuableOperatingTime,0) AS ValuableOperatingTime,
ISNULL(AEffy,0) AS AEffy,ISNULL(PEffy,0) AS PEffy,ISNULL(QEffy,0) AS QEffy,ISNULL(OEffy,0) AS OEffy
from #Target

SELECT Day,Tot_AvlTotalTime,Tot_AvlTime,dbo.f_FormatTime(D1,@TimeFormat) as D1,dbo.f_FormatTime(D2,@TimeFormat) as D2 ,dbo.f_FormatTime(D3,@TimeFormat) as D3,
dbo.f_FormatTime(D4,@TimeFormat) as D4 ,dbo.f_FormatTime(D5,@TimeFormat) as D5,dbo.f_FormatTime(D6,@TimeFormat) as D6,dbo.f_FormatTime(D7,@TimeFormat) as D7 ,
dbo.f_FormatTime(D8,@TimeFormat) as D8, dbo.f_FormatTime(D9,@TimeFormat) as D9,dbo.f_FormatTime(D10,@TimeFormat) as D10, dbo.f_FormatTime(D11,@TimeFormat) as D11,
dbo.f_FormatTime(D12,@TimeFormat) as D12,dbo.f_FormatTime(D13,@TimeFormat) as D13, dbo.f_FormatTime(D14,@TimeFormat) as D14,dbo.f_FormatTime(D15,@TimeFormat) as D15,
dbo.f_FormatTime(D16,@TimeFormat) as D16,dbo.f_FormatTime(D17,@TimeFormat) as D17 ,dbo.f_FormatTime(D18,@TimeFormat) as D18, dbo.f_FormatTime(D19,@TimeFormat) as D19,
ISNULL(Tot_Hold,0) AS Tot_Hold,ISNULL(Tot_RejMat,0) AS Tot_RejMat,ISNULL(Tot_RejPro,0) AS Tot_RejPro,
ISNULL(LoadingTime,0) AS LoadingTime,ISNULL(OperatingTime,0) AS OperatingTime,
ISNULL(NetOperatingTime,0) AS NetOperatingTime,ISNULL(ValuableOperatingTime,0) AS ValuableOperatingTime,
ISNULL(Tot_AEffy,0) AS Tot_AEffy,ISNULL(Tot_PEffy,0) AS Tot_PEffy,ISNULL(Tot_QEffy,0) AS Tot_QEffy,ISNULL(Tot_OEffy,0) AS Tot_OEffy
from #FinalTarget

SELECT TotalTime as TotalTime,AvlTime as AvailableTime,ISNULL(PlantClosure,0) as PlantClosureTime,ISNULL(LoadingTime,0) AS LoadingTime,
ISNULL(Others,0) AS Others , ISNULL(NoPronPlanned,0) AS  NoPronPlanned,ISNULL(OperatingTime,0)  AS OperatingTime, ISNULL(DownTime,0) AS DownTime,
ISNULL(NetOperatingTime,0)  AS NetOperatingTime, ISNULL(SpeedLoss,0) AS SpeedLoss,
ISNULL(ValuableOperatingTime,0) AS ValuableOperatingTime , ISNULL(QualityLoss,0)  AS QualityLoss 
 from #FinalData
--=========================================================================================--			
END
