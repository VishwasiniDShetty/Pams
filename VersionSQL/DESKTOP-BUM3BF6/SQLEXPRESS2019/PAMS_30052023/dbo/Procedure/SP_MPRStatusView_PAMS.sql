/****** Object:  Procedure [dbo].[SP_MPRStatusView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MPRStatusView_PAMS 'Purchase'
*/
CREATE PROCEDURE [dbo].[SP_MPRStatusView_PAMS]
@Param nvarchar(50)=''
as
begin
create table #PPCTemp
(
MPRNo nvarchar(50),
ConfirmedBy nvarchar(50),
Role NVARCHAR(50),
ConfirmationStatus nvarchar(50)
)

create table #StoresTemp
(
MPRNo nvarchar(50),
ConfirmedBy nvarchar(50),
Role NVARCHAR(50),
ConfirmationStatus nvarchar(50)
)

create table #MRTemp
(
MPRNo nvarchar(50),
ConfirmedBy nvarchar(50),
Role NVARCHAR(50),
ConfirmationStatus nvarchar(50)
)

create table #PurchaseTemp
(
MPRNo nvarchar(50),
ConfirmedBy nvarchar(50),
Role NVARCHAR(50),
ConfirmationStatus nvarchar(50)
)




if @Param='PPC'
begin
	Insert into #PPCTemp(MPRNo,ConfirmedBy,Role,ConfirmationStatus)
	select distinct MPRNo,ConfirmedBy,'MR',ConfirmationStatus from MPRConfirmationStatus_Store_PAMS WHERE ConfirmationStatus='hold'

	select distinct [MPRNo],[ConfirmedBy] ,[Role] ,[ConfirmationStatus]  from #PPCTemp
end

if @Param='Stores'
begin
	insert into #StoresTemp(MPRNo,ConfirmedBy,Role,ConfirmationStatus)
	select MPRNo,ConfirmedBy,'PPC',ConfirmationStatus from MPRConfirmationStatus_PPC_PAMS M1 
	WHERE NOT EXISTS(SELECT * FROM MPRConfirmationStatus_Store_PAMS M2 WHERE M1.MPRNo=M2.MPRNo) AND m1.ConfirmationStatus='Approved'
	UNION
	select MPRNo,ConfirmedBy,'MR',ConfirmationStatus from MPRConfirmationStatus_MR_PAMS M1 
	WHERE  EXISTS(SELECT * FROM MPRConfirmationStatus_Store_PAMS M2 WHERE M1.MPRNo=M2.MPRNo AND ConfirmationStatus='Approved') AND M1.ConfirmationStatus='hold'

	select distinct [MPRNo],[ConfirmedBy] ,[Role],[ConfirmationStatus]  from #StoresTemp
END

if @Param='MR'
begin
	insert into #MRTemp(MPRNo,ConfirmedBy,Role,ConfirmationStatus)
	select MPRNo,ConfirmedBy,'Stores',ConfirmationStatus from MPRConfirmationStatus_Store_PAMS M1 
	WHERE NOT EXISTS(SELECT * FROM MPRConfirmationStatus_MR_PAMS M2 WHERE M1.MPRNo=M2.MPRNo) AND M1.ConfirmationStatus='Approved'
	UNION
	select MPRNo,ConfirmedBy,'Purchase',ConfirmationStatus from MPRConfirmationStatus_Purchase_PAMS M1 
	WHERE  EXISTS(SELECT * FROM MPRConfirmationStatus_MR_PAMS M2 WHERE M1.MPRNo=M2.MPRNo AND ConfirmationStatus='Approved') AND M1.ConfirmationStatus='hold'

	select distinct [MPRNo],[ConfirmedBy] ,[Role] ,[ConfirmationStatus]  from #MRTemp
END

IF @Param='Purchase'
BEGIN
	Insert into #PurchaseTemp(MPRNo,ConfirmedBy,Role,ConfirmationStatus)
	select distinct MPRNo,ConfirmedBy,'MR',ConfirmationStatus from MPRConfirmationStatus_MR_PAMS WHERE ConfirmationStatus='Approved'

	select distinct [MPRNo],[ConfirmedBy] ,[Role] ,[ConfirmationStatus]  from #PurchaseTemp
END



end
