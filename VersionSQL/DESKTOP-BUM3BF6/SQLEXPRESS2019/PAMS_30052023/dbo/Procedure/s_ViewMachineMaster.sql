/****** Object:  Procedure [dbo].[s_ViewMachineMaster]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from machineinformation
--exec [s_ViewMachineMaster] @machineid=N'M'
--exec [s_ViewMachineMaster] @machineid=N'TEST01'
 --[dbo].[s_ViewMachineMaster] 'machineinfo','ACE VTL-02'
CREATE       PROCEDURE [dbo].[s_ViewMachineMaster]
@Param nvarchar(50)='',
@machineid nvarchar(50)=''
AS
BEGIN

If @machineid <> '' 
BEGIN


if @param=''
BEGIN


SELECT machineid, isnull(description,'') as description, status,  isnull (mchrrate,0) as mchrrate, portno, isnull (settings, '') as settings, InterfaceID, IP, IPPortNO, 
mode, autoload, TPMTrakEnabled, isnull(PEGreen,85) as PEGreen,  isnull(PERed,60) as PERed ,isnull( AEGreen,85) as AEGreen, 
isnull(AERed,50) as AERed, isnull(OEGreen,80) as OEGreen, 
isnull(OERed, 55) as OERed,isnull( BulkDataTransferPortNo,'') as BulkDataTransferPortNo, isnull(MultiSpindleFlag,0) as MultiSpindleFlag, DeviceType, isnull(PPTransferEnabled,0) as PPTransferEnabled,isnull( SmartTransEnabled,0) as SmartTransEnabled , IgnoreCoFromMach, AutoSetupchangeDown, 
MachinewiseOwner, isnull(CriticalMachineEnabled,0) as CriticalMachineEnabled, DAPEnabled, isnull(Lowerpowerthreshold,0.00) as Lowerpowerthreshold,  isnull(upperpowerthreshold,0.00) as upperpowerthreshold, isnull( QERED,65)as QERED,isnull( QEGreen,80) as QEGreen, isnull(EthernetEnabled,0) as EthernetEnabled, isnull(Nto1Device,0) as Nto1Device
,DNCTransferEnabled,DNCIP,DNCIPPortNo,MobileEnabled,OPCUAURL
FROM machineinformation where Machineid like  @machineid+'%' 
END

if @param='MachineColorCode'
BEGIN
SELECT machineid,isnull(PEGreen,85) as PEGreen,  isnull(PERed,60) as PERed ,isnull( AEGreen,85) as AEGreen, 
isnull(AERed,50) as AERed, isnull(OEGreen,80) as OEGreen, 
isnull(OERed, 55) as OERed,isnull( QERED,65) as QERED ,isnull( QEGreen,80) as QEGreen
FROM machineinformation where Machineid=@machineid 

END

if @param='MachineControlinfo'
BEGIN
SELECT MachineId,ControlName, pStartId, pEndId, FileNameFrom,isnull( ReceiveAtMachineFilePath,0) as ReceiveAtMachineFilePath,isnull(SentFromMachineFilePath,0) as SentFromMachineFilePath
FROM MachineControlInformation where Machineid=@machineid 
END

if @param='machineMakeinfo'
BEGIN
select MachineID,isnull(manufacturer,'') as manufacturer,isnull(dateofmanufacture,getdate()) as  dateofmanufacture,isnull([address],'') as address , 
isnull(place,'') as place,phone as phone  ,isnull(contactperson,'') as contactperson from machinemakeinformation where Machineid=@machineid
END


if @param='machineEfficiencyTarget'
BEGIN
SELECT EfficiencyTarget.MachineID, StartDate, EndDate, AE, PE, QE, OE, LogicalDayStart, LogicalDayEnd, TargetLevel,MachinewiseOwner,isnull(CriticalMachineEnabled,0) as CriticalMachineEnabled
 FROM EfficiencyTarget inner join machineinformation on  machineinformation.MachineID = EfficiencyTarget.MachineID where EfficiencyTarget.Machineid=@machineid 
END
END


If @machineid = ''
BEGIN
SELECT machineid, isnull(description,'') as description, status, isnull (mchrrate,0) as mchrrate, portno, isnull (settings, '') as settings, InterfaceID, IP, IPPortNO, mode, autoload, TPMTrakEnabled, isnull(PEGreen,85) as PEGreen,  isnull(PERed,60) as PERed ,isnull( AEGreen,85) as AEGreen, 
isnull(AERed,50) as AERed, isnull(OEGreen,80) as OEGreen, 
isnull(OERed, 55) as OERed,isnull( BulkDataTransferPortNo,'') as BulkDataTransferPortNo, isnull(MultiSpindleFlag,0) as MultiSpindleFlag, DeviceType, isnull(PPTransferEnabled,0) as PPTransferEnabled,isnull( SmartTransEnabled,0) as SmartTransEnabled , IgnoreCoFromMach, AutoSetupchangeDown, 
MachinewiseOwner, isnull(CriticalMachineEnabled,0) as CriticalMachineEnabled, DAPEnabled, isnull(Lowerpowerthreshold,0.00) as Lowerpowerthreshold,  isnull(upperpowerthreshold,0.00) as upperpowerthreshold, isnull( QERED,65) as QERED,isnull( QEGreen,80) as QEGreen , isnull(EthernetEnabled,0) as EthernetEnabled, isnull(Nto1Device,0) as Nto1Device
,DNCTransferEnabled,DNCIP,DNCIPPortNo,MobileEnabled,OPCUAURL
FROM machineinformation Order by Machineid

END

END
