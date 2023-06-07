/****** Object:  Procedure [dbo].[S_GetWheelHistoryCardReport_MEI]    Committed by VersionSQL https://www.versionsql.com ******/

/*
-- Author:		Raksha
-- Create date: 15 Dec 2020
[dbo].[S_GetWheelHistoryCardReport_MEI] '2020-12-17 00:00:00','2020-12-18 00:00:00','HMC-12','',''

*/
CREATE PROCEDURE [dbo].[S_GetWheelHistoryCardReport_MEI]
@StartDate datetime='',
@EndDate datetime='',
@MachineId nvarchar(50)='',
@WheelNo nvarchar(50)='',
@Param nvarchar(50)=''

AS 
BEGIN

CREATE Table #Temp
(
	ID bigint identity(1,1),
	CycleEnd datetime,
	MachineId nvarchar(50),
	BroachId nvarchar(50),
	Operator nvarchar(50),
	ToolSpecification nvarchar(50),
	ParameterValue nvarchar(50),
	DepthOfCut nvarchar(50),
	CumulativeDepthOfCut nvarchar(50),
	WorkShiftXaxis nvarchar(50)
)


INSERT INTO #Temp(CycleEnd,MachineId,BroachId,Operator)
select distinct T1.CycleEnd,T1.MachineId,T2.componentid,T1.Operator from BroachLevelTransactionData_MEI T1
inner join componentinformation T2 on T1.BroachId=T2.InterfaceID
where (T1.MachineId=@MachineId or ISNULL(@machineId,'')='')
and (T1.ParameterId='Wheel No' )
and (T1.ParameterValue=@WheelNo  or isnull(@WheelNo,'')='')
and T1.CycleStart >= @StartDate and T1.CycleEnd <= @EndDate

update #Temp set ToolSpecification=T1.description
from(
select A2.componentid,A2.description from #Temp A1
inner join componentinformation A2 on A2.componentid=A1.BroachId
)T1 inner join #Temp T2 on T1.componentid=T2.BroachId 


update #Temp set ParameterValue=T1.cnt
from(
select A1.MachineId,A1.BroachId,A1.CycleEnd,sum(cast(A1.ParameterValue as float)) as cnt from BroachLevelTransactionData_MEI A1
inner join #Temp A2 on A2.MachineId=A1.MachineId and A1.BroachId=A2.BroachId and A1.CycleEnd=A2.CycleEnd
where A1.ParameterId='Work Shift X axis Value'
group by A1.MachineId,A1.BroachId,A1.CycleEnd
)T1 inner join #Temp T2 on  T2.CycleEnd=T1.CycleEnd and T1.MachineId=T2.MachineId and T1.BroachId=T2.BroachId


update #Temp set DepthOfCut= case when T1.Depthcut > 0 then T1.Depthcut
								end
from(
select A1.MachineId,A1.BroachId,A1.CycleEnd,(cast(A2.ParameterValue as float) - cast(Lag(A2.ParameterValue) over (Order by A1.MachineId,A1.BroachId,A1.CycleEnd) as float)) as Depthcut from BroachLevelTransactionData_MEI A1
inner join #Temp A2 on A2.MachineId=A1.MachineId and A1.BroachId=A2.BroachId and A1.CycleEnd=A2.CycleEnd
where A1.ParameterId='Work Shift X axis Value'
)T1 inner join #Temp T2 on  T2.CycleEnd=T1.CycleEnd and T1.MachineId=T2.MachineId and T1.BroachId=T2.BroachId

update #Temp set CumulativeDepthOfCut= case when T1.CumulativeDC > 0 then T1.CumulativeDC
									else '0'
								end
from(
select A1.MachineId,A1.BroachId,A1.CycleEnd,
A1.DepthOfCut + isnull(cast(Lag(A1.DepthOfCut) over ( Order by A1.MachineId,A1.BroachId,A1.CycleEnd) as float),0) as CumulativeDC 
from #Temp A1
left join (select MachineId,BroachId,CycleEnd,DepthOfCut from #Temp where DepthOfCut is  not null) A2 on A2.MachineId=A1.MachineId and A1.BroachId=A2.BroachId and A1.CycleEnd=A2.CycleEnd

)T1 inner join #Temp T2 on  T2.CycleEnd=T1.CycleEnd and T1.MachineId=T2.MachineId and T1.BroachId=T2.BroachId


update #Temp set WorkShiftXaxis=T1.ParameterValue
from(
select A1.MachineId,A1.BroachId,A1.CycleEnd as d1,A1.ParameterValue from BroachLevelTransactionData_MEI A1
inner join #Temp A2 on A2.MachineId=A1.MachineId and A1.BroachId=A2.BroachId and A1.CycleEnd=A2.CycleEnd
where A1.ParameterId='Work Shift X axis Value'
)T1 inner join #Temp T2 on T2.CycleEnd=T1.d1 
and T1.MachineId=T2.MachineId and T1.BroachId=T2.BroachId

select cast(CycleEnd as date) as Date, cast(CycleEnd as time) as Time,MachineId,BroachId,Operator,
ToolSpecification,isnull(DepthOfCut,'0') as DepthOfCut,CumulativeDepthOfCut,
WorkShiftXaxis from #Temp
ORDER BY MachineId,BroachId,CycleEnd

END
