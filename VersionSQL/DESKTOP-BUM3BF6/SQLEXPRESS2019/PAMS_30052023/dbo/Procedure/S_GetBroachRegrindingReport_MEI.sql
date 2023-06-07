/****** Object:  Procedure [dbo].[S_GetBroachRegrindingReport_MEI]    Committed by VersionSQL https://www.versionsql.com ******/

/*
-- Author:		Raksha
-- Create date: 15 Dec 2020
[dbo].[S_GetBroachRegrindingReport_MEI] '2020-12-16 00:00:00','2020-12-18 00:00:00','HMC-12','3380314-DX04'
exec [dbo].[S_GetBroachRegrindingReport_MEI] @StartDate=N'2021-01-03 14:40:28',@EndDate=N'2021-03-22 14:40:28',@MachineId=N'CNC-01',@BroachId=N'CARBIDE-TEST'
*/
CREATE PROCEDURE [dbo].[S_GetBroachRegrindingReport_MEI]
@StartDate datetime='',
@EndDate datetime='',
@MachineId nvarchar(50)='',
@BroachId nvarchar(50)='',
@Param nvarchar(50)=''

AS 
BEGIN


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON

CREATE Table #Temp
(
	ID bigint Identity(1,1),
	CycleEnd datetime,
	MachineId nvarchar(50),
	BroachId nvarchar(50),
	BroachName nvarchar(50),
	Operator nvarchar(50),
	ParameterId nvarchar(50),
	ParameterValue nvarchar(50) default '0',
	ParameterDescription nvarchar(100),
	NoOfRegrinding nvarchar(50) default '0',
	DepthOfCut nvarchar(50) default '0',
	NoOfPass nvarchar(50) default '0'
)

CREATE TABLE #ParameterList
(
	ParameterID nvarchar(50),
	ParameterDescription nvarchar(100),
)

CREATE TABLE #FinalOutput
(
	Date datetime,
	MachineID nvarchar(50),
	BroachId nvarchar(50),
	ParameterID nvarchar(50),
	ParameterValue nvarchar(50)

)

INSERT INTO #ParameterList(ParameterID,ParameterDescription)
select distinct ParameterId,ParameterDescription from MachineLevelMasterData_MEI
where MachineId = @MachineID 
UNION
select distinct ParameterId,ParameterDescription from BroachLevelMasterData_MEI
where MachineId = @MachineID  and BroachId = @BroachID 

--INSERT INTO #ParameterList(ParameterID,ParameterDescription)
--select distinct ParameterId,ParameterDescription from BroachLevelMasterData_MEI
--where MachineId = @MachineID  and BroachId = @BroachID 

INSERT INTO #Temp(MachineID,BroachID,BroachName,ParameterID,CycleEnd,Operator)
select distinct	 MachineID,BroachID,T3.componentid,T2.ParameterID,CycleEnd,Operator from BroachLevelTransactionData_MEI T1
inner join componentinformation T3 on T1.BroachId=T3.InterfaceID
inner join #ParameterList T2 on T1.ParameterId = T2.ParameterID 
where MachineId=@MachineId and componentid =@BroachId
and T1.CycleStart >= @StartDate and T1.CycleEnd <= @EndDate
 

Update #Temp set ParameterValue=isnull(T1.cnt,'0')
from(
select A1.MachineId,A1.BroachId,A1.CycleEnd,A1.ParameterID,sum(cast(A1.ParameterValue as float)) as cnt from BroachLevelTransactionData_MEI A1
inner join #Temp A2 on A2.MachineId=A1.MachineId and A1.BroachId=A2.BroachId and A1.CycleEnd=A2.CycleEnd and A1.ParameterId=A2.ParameterId
group by A1.MachineId,A1.BroachId,A1.CycleEnd,A1.ParameterID
)T1 inner join #Temp T2 on  T2.CycleEnd=T1.CycleEnd and T1.MachineId=T2.MachineId and T1.BroachId=T2.BroachId and T1.ParameterId=T2.ParameterId 

Update #Temp Set NoOfRegrinding=T1.cnt
from (
select A1.MachineId,A1.BroachId,count(distinct A1.BatchId) as cnt from BroachLevelTransactionData_MEI A1
inner join #Temp A2 on A2.MachineId=A1.MachineId and A1.BroachId=A2.BroachId
group by A1.MachineId,A1.BroachId
)T1 inner join #Temp T2 on T1.MachineId=T2.MachineId and T1.BroachId=T2.BroachId 

update #Temp set NoOfPass=T1.cnt
from(
select A1.MachineId,A1.BroachId,count(distinct A1.CycleStart) as cnt from BroachLevelTransactionData_MEI A1
inner join #Temp A2 on A2.MachineId=A1.MachineId and A1.BroachId=A2.BroachId
group by A1.MachineId,A1.BroachId
)T1 inner join #Temp T2 on T1.MachineId=T2.MachineId and T1.BroachId=T2.BroachId 


update #Temp set DepthOfCut= case when T1.Depthcut > 0 then T1.Depthcut
								else '0'
								end
from(
select A2.Id,A2.MachineId,A2.BroachId,A2.CycleEnd,A2.ParameterId,(cast(A2.ParameterValue as float) - cast(Lag(A2.ParameterValue) over (Order by A2.Id asc) as float)) as Depthcut 
from #Temp A2
inner join BroachLevelTransactionData_MEI A1 on A2.MachineId=A1.MachineId and A1.BroachId=A2.BroachId and A1.CycleEnd=A2.CycleEnd and A1.ParameterId=A2.ParameterId
where A2.ParameterValue <> '0' and A1.ParameterId='Work Shift X axis Value'
)T1 inner join #Temp T2 on T1.Id=T2.Id


if exists(select * from #Temp)
begin
	INSERT INTO #FinalOutput(Date,MachineID,BroachId,ParameterID,ParameterValue)
	(select distinct CycleEnd,MachineId,BroachName,ParameterId,ParameterValue from #Temp)
	UNION
	(select distinct CycleEnd,MachineId,BroachName,'NoOfRegrinding',NoOfRegrinding from #Temp)
	UNION
	(select distinct CycleEnd,MachineId,BroachName,'DepthOfCut',DepthOfCut from #Temp)
	UNION
	(select distinct CycleEnd,MachineId,BroachName,'NoOfPass',NoOfPass from #Temp)
	UNION
	(select distinct CycleEnd,MachineId,BroachName,'Operator',Operator from #Temp)

		Declare 
		@columns NVARCHAR(MAX) = '',
		@sql     NVARCHAR(MAX) = '';

		SELECT @columns = @columns + QUOTENAME(convert(nvarchar(20),T.Date,120)) + ',' FROM #FinalOutput T group by T.Date
		SET @columns = LEFT(@columns, LEN(@columns) - 1);

		print @columns

		set @sql = ''
		SET @sql ='
		SELECT MachineId,BroachId,ParameterID,'+ @columns +' FROM   
		(
			SELECT MachineId,BroachId,ParameterID,ParameterValue as s1,Date
			FROM #FinalOutput 
		) AS t 
		PIVOT(max(s1) FOR Date IN ('+ @columns + ')) AS pivot_table'

		EXECUTE sp_executesql @sql;

end


END
