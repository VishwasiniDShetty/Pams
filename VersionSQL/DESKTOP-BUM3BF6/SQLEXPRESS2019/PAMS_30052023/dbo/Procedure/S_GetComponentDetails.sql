/****** Object:  Procedure [dbo].[S_GetComponentDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[S_GetComponentDetails] '0'
CREATE PROCEDURE  [dbo].[S_GetComponentDetails] 
@Flag  int
AS

BEGIN

DECLARE @Error AS int	
DECLARE @count AS int	

-----------To Remove Duplicates from ItemMaster From Here-------
SELECT distinct  ItemNo, Iteminterfaceid,Itemdescription,customerid ,Operationno, Opndescription, [CNC M/C], Price, Drawingno, Opninterfaceid, LoadUnloadTime, CycleTime, 
SubOperations, StdSetupTime, MachiningTimeThreshold, TargetPercent,LoadUnloadTimeThreshold,SCIThreshold,DCLThreshold,ID,FinishedOperation,MinLoadUnloadThreshold,Process
into #tmpcomponent
FROM ItemMaster

delete from ItemMaster

insert into ItemMaster
SELECT distinct  ItemNo, Iteminterfaceid, Itemdescription,customerid ,Operationno, Opndescription, [CNC M/C], Price, Drawingno, Opninterfaceid, LoadUnloadTime, CycleTime, 
SubOperations, StdSetupTime, MachiningTimeThreshold, TargetPercent,LoadUnloadTimeThreshold,SCIThreshold,DCLThreshold,ID,FinishedOperation,MinLoadUnloadThreshold,Process from #tmpcomponent

drop table #tmpcomponent
----------To Remove Duplicates from ItemMaster Till Here-----------


------To Remove single quotes with item interfaceid's in ItemMaster Table.
update itemmaster set  iteminterfaceid = replace(iteminterfaceid,'''','')


Update itemmaster set customerid = T.cust from
(select top 1 customerid as cust from customerinformation)T
where isnull(itemmaster.customerid,'a')='a'


------Handling Error Conditions From here---------------------------
select @count = count(*) from  ItemMaster where itemno is null
If @count > 0
BEGIN
	RAISERROR('ItemNo or ComponentID is Null',16,1)
	return -1;
END

set @count=0
select @count = count(*) from  ItemMaster where iteminterfaceid is null
If @count > 0
BEGIN
	RAISERROR('ItemInterfaceid or ComponentInterfaceid is Null',16,1)
	return -1;
END

set @count=0
select @count = count(*) from  ItemMaster where [CNC M/C] is null
If @count > 0
BEGIN
	RAISERROR('Machineid is Null',16,1)
	return -1;
END

--set @count=0
--select Iteminterfaceid,Count(Iteminterfaceid) as CountOfItems into #CompInterface from ItemMaster group by Iteminterfaceid
--
--DECLARE @ItemInterfaceList nvarchar(Max)
--SELECT @ItemInterfaceList = COALESCE(@ItemInterfaceList + ', ', '') + Iteminterfaceid FROM #CompInterface where CountOfItems>1
--
--
--If ISNULL(@ItemInterfaceList,'a') <> 'a'
--BEGIN
--	RAISERROR('Duplicate ItemInterfaceid or ComponentInterfaceid found for %s',16,1,@ItemInterfaceList)
--	return -1;
--END

set @count=0
select [CNC M/C]+ '-' + Itemno+ '-'+ cast(Opninterfaceid as nvarchar(50)) as MCO,Count(Opninterfaceid) as CountOfopn into #opnInterface from ItemMaster group by [CNC M/C]+ '-' + Itemno+ '-'+ cast(Opninterfaceid as nvarchar(50))

DECLARE @OpnInterfaceList nvarchar(Max)
SELECT @OpnInterfaceList = COALESCE(@OpnInterfaceList + ', ', '') + MCO FROM #opnInterface where CountOfopn>1

If ISNULL(@OpnInterfaceList,'a') <> 'a' 
BEGIN
	RAISERROR('Duplicate Machine-Component-Operationinterfaceid found for %s',16,1,@OpnInterfaceList)
	return -1;
END
---------Handling Error Conditions Till here-----------------------

-----------To Insert Components which are not in Componentinformation table.
--Insert into Componentinformation --SV
Insert into Componentinformation( componentid, description, customerid, basicvalue, InterfaceID, InputWeight, ForegingWeight) --SV
select T.itemno,T.itemdescription,T.customerid,'0',T.iteminterfaceid,'0','0' from --SV
(select distinct itemno,iteminterfaceid,itemdescription,customerid from itemmaster
where itemno not in (select distinct componentid from componentinformation))T


SET identity_insert  componentoperationpricing Off

-----------Inserts Components To COP Table from Item List Given.
Insert into Componentoperationpricing(componentid, operationno, description, machineid, price, cycletime, drawingno, InterfaceID, loadunload, machiningtime, SubOperations, StdSetupTime, 
                      MachiningTimeThreshold, TargetPercent, UpdatedBy, UpdatedTS, LowerEnergyThreshold, UpperEnergyThreshold, SCIThreshold, DCLThreshold, 
                      McTimeMonitorLThreshold, McTimeMonitorUThreshold, StdDieCloseTime, StdPouringTime, StdSolidificationTime, StdDieOpenTime,FinishedOperation,MinLoadUnloadThreshold,Process
)
select  distinct * from
(
select T.itemno as itemno, T.operationno as operationno,T.opndescription as opndescription, T.[CNC M/C] as Machineid,
isnull(T.price,1) as Price, (T.cycletime+T.Loadunloadtime) as Cycletime, T.drawingno, T.opninterfaceid as opninterfaceid, T.LoadUnloadTimeThreshold as Loadunloadtime, 
T.cycletime as Machiningtime, isnull(T.SubOperations,1) as SubOperations,
isnull(T.StdSetupTime,0) as StdSetupTime, isnull(T.MachiningTimeThreshold,0) as MachiningTimeThreshold, isnull(T.TargetPercent,100) as TargetPercent, 'PCT' as UpdatedBy, getdate() as UpdatedTS,0 as LowerEnergyThreshold,
0 as UpperEnergyThreshold,T.SCIThreshold,T.DCLThreshold,0 as McTimeMonitorLThreshold,0 as McTimeMonitorUThreshold,0 as StdDieCloseTime,0 as StdPouringTime,0 as StdSolidificationTime,0 as StdDieOpenTime,FinishedOperation,MinLoadUnloadThreshold,Process
FROM 
	(select distinct itemno,operationno,Opndescription,Opninterfaceid,[CNC M/C],price,Cycletime,drawingno,
	SubOperations,StdSetupTime,MachiningTimeThreshold,TargetPercent,Loadunloadtime,LoadUnloadTimeThreshold,SCIThreshold,DCLThreshold,FinishedOperation,MinLoadUnloadThreshold,Process from itemmaster
	where isnull(itemno+[CNC M/C]+ convert(nvarchar(20),operationno),'')  not in 
	(select isnull(componentoperationpricing.Componentid+componentoperationpricing.machineid+ convert(nvarchar(20),componentoperationpricing.operationno),'')
	from componentoperationpricing inner join Componentinformation on componentoperationpricing.componentid=Componentinformation.componentid)
	)T
)T1
--Updates Component Details in COP Table if Machine-Component Combination already exists.
if(@Flag=1)
begin
	update Componentoperationpricing set Cycletime=T.cycletime+T.Loadunloadtime,Loadunload=T.LoadUnloadTimeThreshold,
	Machiningtime=T.cycletime,SCIThreshold=T.SCIThreshold,DCLThreshold=T.DCLThreshold,FinishedOperation=t.finishedoperation,MinLoadUnloadThreshold=t.MinLoadUnloadThreshold,Process=t.Process from 
	(select distinct itemno,operationno,opndescription,opninterfaceid,[CNC M/C],Cycletime,Loadunloadtime,LoadUnloadTimeThreshold,SCIThreshold, DCLThreshold,FinishedOperation,MinLoadUnloadThreshold,Process from itemmaster
	where isnull(itemno+[CNC M/C]+ convert(nvarchar(20),operationno),'')  in 
	(select isnull(componentoperationpricing.Componentid+componentoperationpricing.machineid+ convert(nvarchar(20),componentoperationpricing.operationno),'')
	from componentoperationpricing 
	inner join Componentinformation on componentoperationpricing.componentid=Componentinformation.componentid 
	))T 
	where T.itemno=Componentoperationpricing.componentid and T.[CNC M/C]=Componentoperationpricing.machineid
	AND  T.Opninterfaceid=componentoperationpricing.InterfaceID

	update componentinformation set description=T.Itemdescription,customerid=T.customerid from 
	(select distinct itemno,Iteminterfaceid,Itemdescription,customerid from itemmaster
	where itemno in (select distinct componentid from componentinformation) 
	)T 
	where T.itemno=componentinformation.componentid and T.Iteminterfaceid=componentinformation.InterfaceID
End

SET identity_insert  componentoperationpricing ON


END
