/****** Object:  Procedure [dbo].[SP_ViewAndSaveMachineCompAssociation_CUMI]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_ViewAndSaveMachineCompAssociation_CUMI '2022-11-30 06:00:00.000','2022-12-01 06:00:00.000','','','','','','erp','',@Param=N'View'
*/
CREATE procedure [dbo].[SP_ViewAndSaveMachineCompAssociation_CUMI]
@FromTime datetime='',
@ToTime datetime='',
@ComponentID NVARCHAR(50)='',
@MachineID NVARCHAR(50)='',
@OperationNo nvarchar(50)='',
@CycleTime float=0,
@LoadUnload float=0,
@UpdatedBy nvarchar(50)='',
@UpdatedTS DATETIME='',
@MachiningTime float=0,
@Param nvarchar(50)
as
begin
--Declare @T_ST AS Datetime 
--Declare @T_ED AS Datetime 

--Select @T_ST=dbo.f_GetLogicalDay(@FromTime,'Start')
--Select @T_ED=dbo.f_GetLogicalDay(@ToTime,'End')

	if @Param='Count'
	begin
		SELECT DISTINCT COUNT(*) as NewEntries FROM componentoperationpricing WHERE UpdatedBy='ERP'

		SELECT DISTINCT COUNT(*) as TotalEntries FROM componentoperationpricing
	end

	if @Param='View'
	begin
		select c1.machineid,c2.InterfaceID as CompInterface,c1.componentid,c2.description,c1.operationno,c1.cycletime,c1.machiningtime,(c1.cycletime-c1.machiningtime) as StdLoadunload,c1.UpdatedBy,c1.UpdatedTS from componentoperationpricing c1
		inner join componentinformation c2 on c1.componentid=c2.componentid
		where (c1.componentid like '%'+@ComponentID+'%')
		and (machineid=@MachineID or isnull(@MachineID,'')='') 
		AND (UpdatedBy=@UpdatedBy OR ISNULL(@UpdatedBy,'')='')
		and (convert(nvarchar(20),UpdatedTS,120)>=convert(nvarchar(20),@FromTime,120) and convert(nvarchar(20),UpdatedTS,120)<=convert(nvarchar(20),@ToTime,120))
	end

	if @Param='ExportView'
	begin
		select c1.machineid,c2.InterfaceID as CompInterface,c1.componentid,c2.description,c1.operationno,c1.cycletime,c1.machiningtime,(c1.cycletime-c1.machiningtime) as StdLoadunload,c1.UpdatedBy,c1.UpdatedTS from componentoperationpricing c1
		inner join componentinformation c2 on c1.componentid=c2.componentid
	end

	if @Param='Update'
	begin
		update componentoperationpricing set cycletime=isnull(@MachiningTime,0)+isnull(@LoadUnload,0),
		MachiningTime=isnull(@MachiningTime,0),UpdatedBy=@UpdatedBy,UpdatedTS=GETDATE()
		where machineid=@MachineID and componentid=@ComponentID and operationno=@OperationNo

		select 'Updated' as Flag
	end

	IF @Param='Delete'
	begin
		if not exists(select mc,comp,opn from autodata a inner join machineinformation m1 on a.mc=m1.InterfaceID inner join componentinformation c1 on c1.InterfaceID=a.comp
		inner join componentoperationpricing c2 on c2.machineid=m1.machineid and c2.componentid=c1.componentid where c2.machineid=@MachineID and c2.componentid=@ComponentID and c2.operationno=@OperationNo)
		begin
			delete from componentoperationpricing where machineid=@MachineID and componentid=@ComponentID and operationno=@OperationNo
			select 'Deleted' as Flag
		end
		else
		begin
			select 'Cannot delete as Production has happened for the selected component' as Flag
			return
		end
	end
end
