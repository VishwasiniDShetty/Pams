/****** Object:  Procedure [dbo].[SP_ComplianceCheckListSaveAndView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_ComplianceCheckListSaveAndView_PAMS @Param=N'View',@Name=N'A.J Precision Systems'
*/
CREATE procedure [dbo].[SP_ComplianceCheckListSaveAndView_PAMS]
@code NVARCHAR(50)='',
@Name nvarchar(100)='',
@Particulars nvarchar(2000)='',
@FileName nvarchar(50)='',
@file1 varbinary(MAX)=null,
@Remarks nvarchar(2000)='',
@UpdatedBy nvarchar(50)='',
@FinalRemarks nvarchar(2000)='',
@Type nvarchar(50)='',
@Param nvarchar(50)='',
@Address nvarchar(max)=''
as

create table #Temp
(
Code nvarchar(50),
name nvarchar(50),
Particulars nvarchar(2000),
FileName nvarchar(100),
File1 varbinary(MAX),
Remarks nvarchar(2000),
UpdatedBy nvarchar(50),
UpdatedTS datetime,
FinalRemarks nvarchar(2000),
Type nvarchar(50),
Address nvarchar(max)
)
begin
	if @Param='View'
	begin
		insert into #Temp(nAME,Particulars)
		select distinct @Name,Perticulars from VendorOnboardingPerticularList_Pams

		if isnull(@Name,'')<>''
		begin
			update #Temp set name=isnull(t1.name,''),FileName=isnull(t1.FileName,''),File1=t1.File1,Remarks=isnull(t1.Remarks,''),UpdatedBy=isnull(t1.UpdatedBy,''),
			FinalRemarks=isnull(t1.FinalRemarks,''),Type=isnull(t1.Type,''),Address=isnull(t1.Address,'')
			from
			(
			select Code,Name,Particulars as Particulars,FileName,File1,Remarks,UpdatedBy,UpdatedTS,FinalRemarks,Type,Address from VendorComplianceCheckList_PAMS where name=@Name
			)t1 inner join #Temp t2 on t1.Particulars=t2.Particulars
		end
		select Code,Name,Particulars as Particulars,FileName,File1,Remarks,UpdatedBy, UpdatedTS,FinalRemarks,Type,Address from #Temp 

		--if isnull(@Name,'')=''
		--begin
		--	select '' as Code,'' AS Name,Perticulars AS Particulars,'' as FileName,'' File1,'' Remarks,'' UpdatedBy,'' UpdatedTS,'' FinalRemarks,'' Type, '' Address from VendorOnboardingPerticularList_Pams
		--end
		--else
		--begin
		--	select Code,Name,Particulars as Particulars,FileName,File1,Remarks,UpdatedBy,UpdatedTS,FinalRemarks,Type,Address from VendorComplianceCheckList_PAMS where name=@Name
		--end
	end

	if @Param='Save'
	begin
		if not exists(select * from VendorComplianceCheckList_PAMS where Name=@Name AND Particulars=@Particulars)
		BEGIN
			INSERT INTO VendorComplianceCheckList_PAMS(code,NAME,Particulars,FileName,FILE1,Remarks,UpdatedBy,UpdatedTS,DATE,TYPE,Address)
			VALUES(@code,@Name,@Particulars,@FileName,@file1,@Remarks,@UpdatedBy,GETDATE(),CAST(GETDATE() AS DATE),@Type,@Address)
		END
		ELSE
		BEGIN
			UPDATE VendorComplianceCheckList_PAMS SET FileName=@FileName,FILE1=@file1,Remarks=@Remarks,UpdatedBy=@UpdatedBy,UpdatedTS=GETDATE(),DATE=CAST(GETDATE() AS DATE),Address=@Address, FinalRemarks=@FinalRemarks
			where name=@Name AND Particulars=@Particulars 
		END
	end

	if @Param='AdminApprovalView'
	begin
		select distinct v1.Code,v1.name,v1.FinalRemarks,v1.Type,T2.Status from VendorComplianceCheckList_PAMS v1 
		inner join (select distinct VendorID as ID,VendorName AS Name,Approval as Status from VendorDetails_PAMS
					union 
					select distinct SupplierID AS ID,SupplierName AS Name,Approval as Status from SupplierDetails_PAMS
					) t2 on v1.name=t2.id
					order by Status
		--where t2.Status<>'Ok'

				--insert into #Temp(Code,name,FinalRemarks,Type,Status)
		--select distinct Code,name,FinalRemarks,Type,'NotOk' from VendorComplianceCheckList_PAMS v1 

		--update #Temp set Status=isnull(t1.Status)
		--from
		--(
		--select distinct VendorID,VendorName,Approval as Status from VendorDetails_PAMS
		--)

	end
end
