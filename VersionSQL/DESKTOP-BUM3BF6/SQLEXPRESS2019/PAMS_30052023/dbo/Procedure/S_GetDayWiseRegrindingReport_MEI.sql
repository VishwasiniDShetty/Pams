/****** Object:  Procedure [dbo].[S_GetDayWiseRegrindingReport_MEI]    Committed by VersionSQL https://www.versionsql.com ******/

/*
-- Author:		Raksha
-- Create date: 15 Dec 2020
[dbo].[S_GetDayWiseRegrindingReport_MEI] '2020-12-17 00:00:00','2020-12-18 00:00:00','HMC-12',''

*/
CREATE PROCEDURE [dbo].[S_GetDayWiseRegrindingReport_MEI]
@StartDate datetime='',
@EndDate datetime='',
@MachineId nvarchar(50)='',
@Param nvarchar(50)=''

AS 
BEGIN

CREATE Table #Temp
(
	CycleEnd datetime,
	MachineId nvarchar(50),
	BroachId nvarchar(50),
	Operator nvarchar(50),
)

INSERT INTO #Temp(CycleEnd,MachineId,BroachId,Operator)
select distinct T1.CycleEnd,T1.MachineId,T2.componentid,T1.Operator from BroachLevelTransactionData_MEI T1
inner join componentinformation T2 on T1.BroachId=T2.InterfaceID
where (T1.MachineId=@MachineId or ISNULL(@machineId,'')='')
and T1.CycleStart >= @StartDate and T1.CycleEnd <= @EndDate

select cast(CycleEnd as date) as Date, cast(CycleEnd as time) as Time,MachineId,BroachId,Operator from #Temp

END
