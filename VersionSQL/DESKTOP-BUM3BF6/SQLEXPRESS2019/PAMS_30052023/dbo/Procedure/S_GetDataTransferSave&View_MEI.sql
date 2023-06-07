/****** Object:  Procedure [dbo].[S_GetDataTransferSave&View_MEI]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[S_GetDataTransferSave&View_MEI] 'HMC-13','47131252-DX00',''
select * from BroachLevelMasterData_MEI where MachineId='HMC-12' and BroachId='3380314-DX04'

select * from TempBroachLevelTransactionData_MEI order by updatedTS desc
exec [dbo].[S_GetDataTransferSave&View_MEI] @MachineID=N'CNC-01',@BroachID=N'CARBIDE-TEST'
*/
CREATE PROCEDURE [dbo].[S_GetDataTransferSave&View_MEI]
@MachineID nvarchar(50)='',
@BroachID nvarchar(50)='',
@Param nvarchar(50)=''

AS
BEGIN

CREATE TABLE #ParameterList
(
	ParameterID nvarchar(50),
	ParameterDescription nvarchar(100),
	MacroNo nvarchar(50),
	Location nvarchar(50)
)


CREATE TABLE #Temp
(
	ID bigint identity(1,1),
	MachineID nvarchar(50),
	BroachID nvarchar(50),
	CompName nvarchar(50),
	ParameterID nvarchar(50),
	ParameterDescription nvarchar(100),
	CycleStart datetime,
	CycleEnd datetime,
	BatchId nvarchar(50),
	MacroNo nvarchar(50),
	Location nvarchar(50),
	OperationNo nvarchar(50),
	ParameterValue nvarchar(50),
	ChangedValue nvarchar(50)
)

INSERT INTO #ParameterList(ParameterID,ParameterDescription,MacroNo,Location)
select distinct ParameterId,ParameterDescription,MacroNo,Location from MachineLevelMasterData_MEI
where MachineId = @MachineID 
UNION
select distinct ParameterId,ParameterDescription,MacroNo,Location from BroachLevelMasterData_MEI
where MachineId = @MachineID  and BroachId = @BroachID 

--INSERT INTO #ParameterList(ParameterID,ParameterDescription,MacroNo,Location)
--select distinct ParameterId,ParameterDescription,MacroNo,Location from BroachLevelMasterData_MEI
--where MachineId = @MachineID  and BroachId = @BroachID 

INSERT INTO #Temp(MachineID,BroachID,ParameterID,ParameterDescription,MacroNo,Location,CompName)
Select distinct @MachineID,InterfaceID,ParameterID,ParameterDescription,MacroNo,Location,componentid from #ParameterList
inner join componentinformation on componentinformation.componentid=@BroachID

Update #Temp Set CycleStart=T1.SD , CycleEnd=T1.ED
from(
select A1.MachineId,A1.BroachId,A1.ParameterId,Max(A1.CycleStart) as SD, Max(A1.CycleEnd) as ED from BroachLevelTransactionData_MEI A1
inner join #Temp A2 on A1.MachineId=A2.MachineID and A1.BroachId=A2.BroachID and A1.ParameterId=A2.ParameterID
group by A1.MachineId,A1.BroachId,A1.ParameterId
)T1 inner join #Temp T2 on T1.MachineId=T2.MachineID and T1.BroachId=T2.BroachID and T1.ParameterId=T2.ParameterID


update #Temp set BatchId = T1.BatchId, OperationNo=T1.OperationNo , ParameterValue = T1.ParameterValue
from (
Select A1.MachineId,A1.BroachId,A1.ParameterId,A1.CycleStart,A1.CycleEnd,A1.BatchId,A1.OperationNo,A1.ParameterValue from BroachLevelTransactionData_MEI A1
inner join #Temp A2 on A1.MachineId=A2.MachineID and A1.BroachId=A2.BroachID and A1.ParameterId=A2.ParameterID and A1.CycleStart=A2.CycleStart and A1.CycleEnd=A2.CycleEnd
)T1 inner join #Temp T2 on T1.MachineId=T2.MachineID and T1.BroachId=T2.BroachID and T1.ParameterId=T2.ParameterID and T1.CycleStart=T2.CycleStart and T1.CycleEnd=T2.CycleEnd

update #Temp set ChangedValue=ParameterValue

--update #Temp set ChangedValue = T1.ParameterValue
--from (
--Select A1.MachineId,A1.BroachId,A1.ParameterId,A1.CycleStart,A1.CycleEnd,A1.ParameterValue,A2.MacroNo from TempBroachLevelTransactionData_MEI A1
--inner join #Temp A2 on A1.MachineId=A2.MachineID and A1.BroachId=A2.CompName and A1.ParameterId=A2.ParameterID and A1.CycleStart=A2.CycleStart and A1.CycleEnd=A2.CycleEnd
--)T1 inner join #Temp T2 on T1.MachineId=T2.MachineID and T1.BroachId=T2.CompName and T1.ParameterId=T2.ParameterID and T1.CycleStart=T2.CycleStart and T1.CycleEnd=T2.CycleEnd and T1.MacroNo=T2.MacroNo

update #Temp set ChangedValue = T1.ParameterValue
from (Select A.MachineId,A.BroachId,A.ParameterId,A.CycleStart,A.CycleEnd,A.ParameterValue,A3.MacroNo from TempBroachLevelTransactionData_MEI A
inner join (Select A1.MachineId,A1.BroachId,A1.ParameterId,A1.CycleStart,A1.CycleEnd,A2.MacroNo, max(UpdatedTS)as TS from TempBroachLevelTransactionData_MEI A1
inner join #Temp A2 on A1.MachineId=A2.MachineID and A1.BroachId=A2.CompName and A1.ParameterId=A2.ParameterID and A1.CycleStart=A2.CycleStart and A1.CycleEnd=A2.CycleEnd
group by A1.MachineId,A1.BroachId,A1.ParameterId,A1.CycleStart,A1.CycleEnd,A2.MacroNo
) A3 on A.MachineId=A3.MachineId and A.BroachId=A3.BroachId and A.ParameterId=A3.ParameterId and A.CycleStart=A3.CycleStart and A.CycleEnd=A3.CycleEnd and A.UpdatedTS=A3.TS
)T1 inner join #Temp T2 on T1.MachineId=T2.MachineID and T1.BroachId=T2.CompName and T1.ParameterId=T2.ParameterID and T1.CycleStart=T2.CycleStart and T1.CycleEnd=T2.CycleEnd and T1.MacroNo=T2.MacroNo


select distinct MachineID,CompName as BroachID,ParameterID,ParameterDescription,MacroNo,Location,BatchId,OperationNo,CycleStart,CycleEnd,ParameterValue,ChangedValue from #Temp

END
