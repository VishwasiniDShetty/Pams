/****** Object:  Procedure [dbo].[s_Eshopx_ViewAndInsertRejections]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_Eshopx_ViewAndInsertRejections] '','','','','','','','','delete','Rejection','','1'
--[dbo].[s_Eshopx_ViewAndInsertRejections] '2018-01-03','A','SUPERCUT-51','039205-001 - AA','70','','','','view','Rejection'


--[dbo].[s_Eshopx_ViewAndInsertRejections] '2018-01-03','A','SUPERCUT-51','039205-001 - AA','70','DINESH KUMAR. S ','Material problem','1','insert','MarkedforRework'
--[dbo].[s_Eshopx_ViewAndInsertRejections] '2018-01-03','A','SUPERCUT-51','039205-001 - AA','70','','','','view','MarkedforRework'

--[dbo].[s_Eshopx_ViewAndInsertRejections] '2018-01-03','A','SUPERCUT-51','039205-001 - AA','70','DINESH KUMAR. S ','Material problem','1','insert','Rejection'
--[dbo].[s_Eshopx_ViewAndInsertRejections] '2018-Nov-23','First','CT44','PQ1400800-T46','1','357','1','40','View','Rejection','831514'
--[dbo].[s_Eshopx_ViewAndInsertRejections] '2018-Nov-23','First','CT44','PQ1400800-T46','1','357','1','40','Insert','Rejection','831514'
--[dbo].[s_Eshopx_ViewAndInsertRejections] '2018-Nov-23','First','CT44','PQ1400800-T46','1','357','1','20','Insert','Rejection',''

CREATE PROCEDURE [dbo].[s_Eshopx_ViewAndInsertRejections]
@RejDate Datetime='',
@Rejshift nvarchar(50)='',
@MachineID nvarchar(50)='',
@ComponentID nvarchar(50)='',
@Operationno nvarchar(50)='',
@Operatorid nvarchar(50)='',
@RejectionCode nvarchar(50)='',
@RejQty int='',
@Param nvarchar(50)='',
@Type nvarchar(50), --Rejection/MarkedforRework
@WorkOrderNumber nvarchar(50)='',
@Recordid bigint=''
AS
BEGIN

SET NOCOUNT ON;

IF @Type = 'Rejection'
BEGIN
		If @Param='View'
		Begin
		Select A.RejDate,S.Shiftname,M.Machineid,O.Componentid,O.Operationno,R.Catagory,R.rejectionid,A.Rejection_Qty,
		A.WorkOrderNumber,A.recordid as id --g:
		from AutodataRejections A
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
		Inner join machineinformation M on M.interfaceid=A.mc    
		Inner join componentinformation C ON A.Comp=C.interfaceid    
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID 
		Left Outer join Employeeinformation E on E.interfaceid=A.opr
		inner join (Select Shiftid,Shiftname from Shiftdetails where running=1) S on A.Rejshift=S.Shiftid
		Where  A.flag='Rejection' and Convert(nvarchar(10),A.RejDate,120)=Convert(nvarchar(10),@RejDate,120) and S.Shiftname=@Rejshift and O.Machineid=@MachineID
		and O.componentid=@ComponentID and O.operationno=@Operationno 
		and (A.WorkOrderNumber=@WorkOrderNumber or @WorkOrderNumber='') --g:
		and E.Employeeid = @Operatorid --g:
		order by A.id
		End


		IF @param='Insert'
		Begin

		Declare @McInterfaceID as nvarchar(50),@component as nvarchar(50),@operation as nvarchar(50),@operator as nvarchar(50),@RejCode as nvarchar(50)
		Declare @rejrecordid as bigint,@Rejshiftid as int

		Select @McInterfaceID = interfaceid from machineinformation where Machineid=@MachineID
		Select @component = interfaceid from componentinformation where componentid=@ComponentID
		Select @operation = interfaceid from ComponentOperationPricing where Machineid=@MachineID and componentid=@ComponentID and Operationno=@Operationno
		select @RejCode = interfaceid from Rejectioncodeinformation where rejectionid=@RejectionCode
		Select @operator = interfaceid from Employeeinformation where employeeid=@operatorid
		Select @Rejshiftid = Shiftid From Shiftdetails Where Shiftname=@Rejshift and Running=1
		select @rejrecordid = isnull(max(recordid),0) from autodatarejections where flag='Rejection' --ER0349 Commented


		--IF NOT EXISTS(Select * from autodatarejections where mc=@McInterfaceID and comp=@component and opn=@operation and opr=@operator and rejection_code=@RejCode and rejection_qty=@RejQty and 
		--Convert(nvarchar(10),RejDate,120)=Convert(nvarchar(10),@RejDate,120) and isnull(rejshift,'0')=isnull(@Rejshiftid,'0') and flag='Rejection'
		--and WorkOrderNumber=@WorkOrderNumber) 

			insert into AutodataRejections(mc,comp,opn,opr,rejection_code,rejection_qty,createdts,rejdate,rejshift,recordid,flag,
			WorkOrderNumber) --g:
			values(@McInterfaceID,@component,@operation,@operator,@RejCode,@RejQty,getdate(),@RejDate,@Rejshiftid,@rejrecordid+1,'Rejection',
			@WorkOrderNumber) --g:
		--END 

		End

		If @Param='delete'
		begin
			Delete From AutodataRejections where recordid=@Recordid and Flag='Rejection'
		End

END

IF @Type = 'MarkedforRework'
BEGIN
		If @Param='View'
		Begin
		Select A.RejDate,S.Shiftname,M.Machineid,O.Componentid,O.Operationno,R.ReworkCatagory,R.Reworkid,A.Rejection_Qty,
		A.WorkOrderNumber --g:
		from AutodataRejections A
		inner join Reworkinformation R on A.Rejection_code=R.Reworkinterfaceid    
		Inner join machineinformation M on M.interfaceid=A.mc    
		Inner join componentinformation C ON A.Comp=C.interfaceid    
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID 
		Left Outer join Employeeinformation E on E.interfaceid=A.opr
		inner join (Select Shiftid,Shiftname from Shiftdetails where running=1) S on A.Rejshift=S.Shiftid
		Where  A.flag='MarkedforRework' and Convert(nvarchar(10),A.RejDate,120)=Convert(nvarchar(10),@RejDate,120) and S.Shiftname=@Rejshift and O.Machineid=@MachineID
		and O.componentid=@ComponentID and O.operationno=@Operationno
		and (A.WorkOrderNumber=@WorkOrderNumber or @WorkOrderNumber='') --g:
		and E.Employeeid = @Operatorid --g:
		order by A.id
		End


		IF @param='Insert'
		Begin

		Select @McInterfaceID = interfaceid from machineinformation where Machineid=@MachineID
		Select @component = interfaceid from componentinformation where componentid=@ComponentID
		Select @operation = interfaceid from ComponentOperationPricing where Machineid=@MachineID and componentid=@ComponentID and Operationno=@Operationno
		select @RejCode = Reworkinterfaceid from Reworkinformation where Reworkid=@RejectionCode
		Select @operator = interfaceid from Employeeinformation where employeeid=@operatorid
		Select @Rejshiftid = Shiftid From Shiftdetails Where Shiftname=@Rejshift and Running=1
		select @rejrecordid = isnull(max(recordid),0) from autodatarejections where flag='MarkedforRework' --ER0349 Commented


		--IF NOT EXISTS(Select * from autodatarejections where mc=@McInterfaceID and comp=@component and opn=@operation and opr=@operator and rejection_code=@RejCode and rejection_qty=@RejQty and 
		--Convert(nvarchar(10),RejDate,120)=Convert(nvarchar(10),@RejDate,120) and isnull(rejshift,'0')=isnull(@Rejshiftid,'0') and flag='MarkedforRework'
		--and WorkOrderNumber=@WorkOrderNumber) 

			insert into AutodataRejections(mc,comp,opn,opr,rejection_code,rejection_qty,createdts,rejdate,rejshift,recordid,flag,
			WorkOrderNumber)
			values(@McInterfaceID,@component,@operation,@operator,@RejCode,@RejQty,getdate(),@RejDate,@Rejshiftid,@rejrecordid+1,'MarkedforRework',
			@WorkOrderNumber) 
		--END 

		End
END

END
