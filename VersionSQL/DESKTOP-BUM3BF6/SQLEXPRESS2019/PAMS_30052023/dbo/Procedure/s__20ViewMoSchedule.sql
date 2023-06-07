/****** Object:  Procedure [dbo].[s_ ViewMoSchedule]    Committed by VersionSQL https://www.versionsql.com ******/

-- [dbo].[s_ ViewMoSchedule]'CNC GRINDING','','view'
CREATE PROCEDURE [dbo].[s_ ViewMoSchedule]
	@MachineID nvarchar(50)='',
	@MONumber nvarchar(50)='',
	@param nvarchar(50)=''  --View,Update
AS	
BEGIN
	
	SET NOCOUNT ON;


	create table #MOSchedule
	(
	MONumber nvarchar(50),
	MachineID  nvarchar(50),
	PartID nvarchar(50),
	OperationNo nvarchar(50),
	Quantity nvarchar(50),
	DateOfRequirement datetime,
	MOStatus nvarchar(50),
	[FileName] nvarchar(1000),
	FileModifiedDate datetime,
	LinkNo nvarchar(50),
	SortOrder int,
	[Status] nvarchar(50),
	MOflag int,
	ProjectNumber nvarchar(50),
	OpnDescription nvarchar(100)
	)

declare @Threshold as nvarchar(50)
select @Threshold = folderpath from FolderPathDefinition where FolderType='Threshold'


 IF EXISTS(select * from Company where companyName ='TSS')  
 BEGIN 
	insert into #MOSchedule(MoNumber,LinkNo,MachineID,PartID,OperationNo,Quantity,DateOfRequirement,MOStatus,[Filename],FileModifiedDate,MOflag,[Status] )
	select  MoNumber,LinkNo,MachineID,PartID,OperationNo,Quantity,DateOfRequirement,
	case When MOStatus='4' and [Status] in('N','M') then 'Open' when MOStatus='5' and [Status]='C'  then 'Closed'
	 when MOStatus='4' and [Status]='R' then 'Running' end as MOStatus,
	[Filename],FileModifiedDate,MOflag,[Status] from MOSchedule
	where machineID=@MachineID 
	and  (MOStatus in('4','5') and (Status in('N','M','R')) or (Status='C' and  datediff(MINUTE,LastModifiedDate,getdate())<=@Threshold))



	update #MOSchedule set SortOrder=(CASE  
	WHEN (MOStatus = 'Running') THEN '1' 
	WHEN (MOStatus = 'Closed') THEN '2' 
	WHEN (MOStatus = 'Open') THEN '3' 
	END)
END
ELSE
BEGIN

	insert into #MOSchedule(MoNumber,LinkNo,MachineID,PartID,OperationNo,Quantity,DateOfRequirement,MOStatus,[Filename],FileModifiedDate,MOflag,[Status],ProjectNumber, OpnDescription )
	select  MoNumber,LinkNo,MachineID,PartID,OperationNo,Quantity,DateOfRequirement,
	case When [Status] in('REL','MODIFIED','NEW') then 'Open' 
	 when [Status]='COMPLETED'  then 'Closed'
	 when [Status]='RUNNING' then 'Running' end as MOStatus,
	[Filename],FileModifiedDate,MOflag,[Status],ProjectNumber, OpnDescription from MOSchedule
	where machineID=@MachineID 
	and (Status in('REL','NEW','MODIFIED','RUNNING')) or (Status='COMPLETED' and  datediff(MINUTE,LastModifiedDate,getdate())<=@Threshold)


	update #MOSchedule set SortOrder=(CASE  
	WHEN (MOStatus = 'Running') THEN '1' 
	WHEN (MOStatus = 'Closed') THEN '2' 
	WHEN (MOStatus = 'Open') THEN '3' 
	END)

END


if @param='View'
BEGIN

	 IF NOT EXISTS(select * from Company where companyName ='TSS')  
	 BEGIN 
			if @MONumber =''
			BEGIN
					if (select count(*) from #MOSchedule where  MOStatus in ('Running' ,'Open'))=1
					BEGIN
						print 'count equal to 1'
						delete from MO where machineID=@machineID
						insert into MO(MoNumber,LinkNo,MachineID,PartID,OperationNo,DateOfRequirement,MOStatus,FileModifiedDate,[Status],Quantity,ProjectNumber,OpnDescription)
						select  MoNumber,LinkNo,MachineID,PartID,OperationNo,DateOfRequirement,MOStatus,FileModifiedDate,[Status],Quantity,ProjectNumber,OpnDescription from 
						#MOSchedule where  MOStatus in ('Running','Open')

						select * from MO where machineID=@machineID;
					END
					else if (select count(*) from #MOSchedule where MOStatus in ('Running','Open'))>'1'
						BEGIN

						print 'count greater than 1'
						select M.MoNumber,M.LinkNo,M.MachineID,M.PartID,M.OperationNo,M.DateOfRequirement,M.Quantity,
						M.MOStatus,M.FileModifiedDate,M.[Status],M.ProjectNumber,M.OpnDescription from MO  M inner join #MOSchedule MOS on M.MONumber=MOS.MONumber where M.machineID=@machineID
						END	
					else
						BEGIN
						print 'not exists'
						--select * from MO where machineID=@machineID;
						select M.MoNumber,M.LinkNo,M.MachineID,M.PartID,M.OperationNo,M.DateOfRequirement,M.Quantity,
						M.MOStatus,M.FileModifiedDate,M.[Status],M.ProjectNumber,M.OpnDescription from MO  M inner join #MOSchedule MOS
						 on M.MONumber=MOS.MONumber where MOS.machineID=@machineID and M.MOStatus in ('Running','Open');
						END
			END

			if @MONumber <> ''
				BEGIN
					delete from MO where machineID=@machineID
					insert into MO(MoNumber,LinkNo,MachineID,PartID,OperationNo,DateOfRequirement,MOStatus,FileModifiedDate,[Status],Quantity,ProjectNumber,OpnDescription)
					select  MoNumber,LinkNo,MachineID,PartID,OperationNo,DateOfRequirement,MOStatus,FileModifiedDate,[Status],Quantity,ProjectNumber,OpnDescription from 
					#MOSchedule where  MOStatus in ('Running','Open') and MoNumber=@MONumber and MachineID=@MachineID
					select * from MO where machineID=@machineID;
				END
	END
	Else
	BEGIN
	if @MONumber =''
			BEGIN
					if (select count(*) from #MOSchedule where  MOStatus in ('Running' ))=1
					BEGIN
						print 'count equal to 1'
						delete from MO where machineID=@machineID
						insert into MO(MoNumber,LinkNo,MachineID,PartID,OperationNo,DateOfRequirement,MOStatus,FileModifiedDate,[Status],Quantity,ProjectNumber,OpnDescription)
						select  MoNumber,LinkNo,MachineID,PartID,OperationNo,DateOfRequirement,MOStatus,FileModifiedDate,[Status],Quantity,ProjectNumber,OpnDescription from 
						#MOSchedule where  MOStatus in ('Running')

						select * from MO where machineID=@machineID;
					END
					else if (select count(*) from #MOSchedule where MOStatus in ('Running'))>'1'
						BEGIN

						print 'count greater than 1'
						select M.MoNumber,M.LinkNo,M.MachineID,M.PartID,M.OperationNo,M.DateOfRequirement,M.Quantity,
						M.MOStatus,M.FileModifiedDate,M.[Status],M.ProjectNumber,M.OpnDescription from MO  M inner join #MOSchedule MOS on M.MONumber=MOS.MONumber where M.machineID=@machineID
						END	
					else
						BEGIN
						print 'not exists'
						--select * from MO where machineID=@machineID;
						select M.MoNumber,M.LinkNo,M.MachineID,M.PartID,M.OperationNo,M.DateOfRequirement,M.Quantity,
						M.MOStatus,M.FileModifiedDate,M.[Status],M.ProjectNumber,M.OpnDescription from MO  M inner join #MOSchedule MOS
						 on M.MONumber=MOS.MONumber where MOS.machineID=@machineID and M.MOStatus in ('Running');
						END
			END

			if @MONumber <> ''
				BEGIN
					delete from MO where machineID=@machineID
					insert into MO(MoNumber,LinkNo,MachineID,PartID,OperationNo,DateOfRequirement,MOStatus,FileModifiedDate,[Status],Quantity,ProjectNumber,OpnDescription)
					select  MoNumber,LinkNo,MachineID,PartID,OperationNo,DateOfRequirement,MOStatus,FileModifiedDate,[Status],Quantity,ProjectNumber,OpnDescription from 
					#MOSchedule where  MOStatus in ('Running') and MoNumber=@MONumber and MachineID=@MachineID
					select * from MO where machineID=@machineID;
				END


	END


END


--select * from #MOSchedule where MONumber not in (select MoNumber from MO where machineID=@machineID) order by SortOrder --Swathi As on  19/Nov/2015
select * from #MOSchedule where MONumber not in (select MoNumber from MO where machineID=@machineID) order by SortOrder,DateOfRequirement --Swathi As on  19/Nov/2015

END
