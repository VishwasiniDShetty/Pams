/****** Object:  Procedure [dbo].[SP_MachineLevelSPCMasterReplication_Shanthi]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MachineLevelSPCMasterReplication_Shanthi @SourceMachine=N'VMC-21',@SourceComponent=N'3906749-DX04',@SourceOperation=N'20',@TargetMachine=N'''VMC-17'',''VMC-30'',''HMC-13'''
*/
CREATE PROCEDURE [dbo].[SP_MachineLevelSPCMasterReplication_Shanthi]
@SourceMachine NVARCHAR(50)='',
@SourceComponent nvarchar(2000)='',
@SourceOperation nvarchar(50)='',
@TargetMachine NVARCHAR(100)=''
as
begin
declare @StrTargetMachine nvarchar(max)
declare @target nvarchar(2000)
declare @strsql nvarchar(max)
DECLARE @update_count int
declare @i int
declare @count int

select @strsql=''
select @StrTargetMachine=''
select @target=''


if isnull(@TargetMachine,'')<>''
begin
select @StrTargetMachine='And Machineid in ('+@TargetMachine+')'
end

create table #Target
(
AutoID BIGINT IDENTITY(1,1),
TargetMachine nvarchar(100)
)

select @strsql=''
select @strsql=@strsql+'Insert into #Target(TargetMachine) '
select @strsql=@strsql+'select distinct Machineid from machineinformation where 1=1 '
SELECT @strsql=@strsql+@StrTargetMachine
EXEC(@STRSQL)
PRINT(@STRSQL)


set @i=1
select @count=(select max(AutoID) from #Target)

while(@i<=@count)
BEGIN
select @i
select @target=''
select @target=(select TargetMachine from #Target where AutoID=@i)
select @target

if exists(select * from SPC_Characteristic where MachineID=@target and ComponentID=@SourceComponent AND OperationNo=@SourceOperation)
begin
print 'Update'
UPDATE SPC_Characteristic SET CharacteristicCode=(T1.CharacteristicCode),SpecificationMean=(T1.SpecificationMean),LSL=(T1.LSL),USL=(T1.USL),UOM=(T1.UOM),
SampleSize=(T1.SampleSize),Interval=(T1.Interval),InstrumentType=(T1.InstrumentType),InProcessInterval=(T1.InProcessInterval),InspectionDrawing=(T1.InspectionDrawing),
Datatype=(T1.Datatype),SetupApprovalInterval=(T1.SetupApprovalInterval),Specification=(T1.Specification),MacroLocation=(T1.MacroLocation),[UpperOperatingZoneLimit ]=(T1.[UpperOperatingZoneLimit ]),
[LowerOperatingZoneLimit ]=(T1.[LowerOperatingZoneLimit ]),[UpperWarningZoneLimit ]=(T1.[UpperWarningZoneLimit ]),[LowerWarningZoneLimit ]=(T1.[LowerWarningZoneLimit ]),CuUSL=(T1.CuUSL),CuLSL=(T1.CuLSL),
UTNO=(T1.UTNO),BLNo=(T1.BLNo),MPPNo=(T1.MPPNo),Model=(T1.model),CompInterfaceId=(T1.CompInterfaceId),OpnInterfaceId=(T1.OpnInterfaceId),ToolNumber=(T1.ToolNumber),
IsEnabled=(T1.IsEnabled),InspectedBy=(T1.InspectedBy),InputMethod=(T1.InputMethod),Channel=(T1.CHANNEL) FROM
(select @target AS TargetMachine,ComponentID,OperationNo,CharacteristicCode,CharacteristicID,SpecificationMean,LSL,USL,UOM,SampleSize,Interval,InstrumentType,InProcessInterval,InspectionDrawing,
Datatype,SetupApprovalInterval,Specification,MacroLocation,ID,[UpperOperatingZoneLimit ],[LowerOperatingZoneLimit ],[UpperWarningZoneLimit ],[LowerWarningZoneLimit ],CuUSL,CuLSL,UTNO,BLNo,MPPNo,Model,
CompInterfaceId,OpnInterfaceId,ToolNumber,IsEnabled,InspectedBy,InputMethod,Channel from SPC_Characteristic
where MachineID=@SourceMachine AND ComponentID=@SourceComponent AND OperationNo=@SourceOperation
)T1 INNER JOIN SPC_Characteristic S ON S.ComponentID=T1.ComponentID AND S.OperationNo=T1.OperationNo AND S.MachineID=@target and s.CharacteristicID=t1.CharacteristicID

SET @update_count = @@ROWCOUNT
print 'updated ' + CONVERT(varchar, @update_count) + ' records in table SPC_Characteristic'

end

if not exists(select * from SPC_Characteristic where MachineID=@target and ComponentID=@SourceComponent AND OperationNo=@SourceOperation)
begin
print 'Insert'
insert into SPC_Characteristic(MachineID,ComponentID,OperationNo,CharacteristicCode,CharacteristicID,SpecificationMean,LSL,USL,UOM,SampleSize,Interval,InstrumentType,InProcessInterval,InspectionDrawing,
Datatype,SetupApprovalInterval,Specification,MacroLocation,[UpperOperatingZoneLimit ],[LowerOperatingZoneLimit ],[UpperWarningZoneLimit ],[LowerWarningZoneLimit ],CuUSL,CuLSL,UTNO,BLNo,MPPNo,Model,
CompInterfaceId,OpnInterfaceId,ToolNumber,IsEnabled,InspectedBy,InputMethod,Channel)
select @target,ComponentID,OperationNo,CharacteristicCode,CharacteristicID,SpecificationMean,LSL,USL,UOM,SampleSize,Interval,InstrumentType,InProcessInterval,InspectionDrawing,
Datatype,SetupApprovalInterval,Specification,MacroLocation,[UpperOperatingZoneLimit ],[LowerOperatingZoneLimit ],[UpperWarningZoneLimit ],[LowerWarningZoneLimit ],CuUSL,CuLSL,UTNO,BLNo,MPPNo,Model,
CompInterfaceId,OpnInterfaceId,ToolNumber,IsEnabled,InspectedBy,InputMethod,Channel from SPC_Characteristic
where MachineID=@SourceMachine AND ComponentID=@SourceComponent AND OperationNo=@SourceOperation

SET @update_count = @@ROWCOUNT
print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table SPC_Characteristic'

end
SET @i=@i+1
end
END
