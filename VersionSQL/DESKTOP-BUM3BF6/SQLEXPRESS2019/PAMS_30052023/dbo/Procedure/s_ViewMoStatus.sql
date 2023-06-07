/****** Object:  Procedure [dbo].[s_ViewMoStatus]    Committed by VersionSQL https://www.versionsql.com ******/

-- [dbo].[s_ViewMoStatus] 'CT10','',''
CREATE PROCEDURE [dbo].[s_ViewMoStatus]
	@MachineID nvarchar(50)='',
	@MONumber nvarchar(50)='',
	@PartID nvarchar(50)='',
	@param nvarchar(50)=''  --View,Update
AS	
BEGIN
	
	SET NOCOUNT ON;


	create table #MOSchedule
	(
	slno int identity(1,1) not null,
	MONumber nvarchar(50),
	MachineID  nvarchar(50),
	PartID nvarchar(50),
	OperationNo nvarchar(50),
	Quantity nvarchar(50),
	FileModifiedDate datetime,
	MOStatus nvarchar(50),
    LastModifiedDate datetime
	)



insert into #MOSchedule(MoNumber,MachineID,PartID,OperationNo,FileModifiedDate)
select  MoNumber,MachineID,PartID,OperationNo,Min(FileModifiedDate) from MOSchedule
where (MachineID=@MachineID or ISNULL(@machineid,'')='') and (MONumber=@MONumber or ISNULL(@MONumber,'')='')
and (PartID=@PartID or ISNULL(@PartID,'')='')
group by MoNumber,MachineID,PartID,OperationNo order by machineid,PartID,MONumber

update #MOSchedule set Quantity=T1.Quantity from
(select M1.MoNumber,M1.MachineID,M1.PartID,M1.OperationNo,M1.FileModifiedDate,M.quantity from MOSchedule M
inner join #MOSchedule M1 on M.MachineID=M1.MachineID and M.PartID=M1.PartID and m.MONumber=M1.MONumber and M.FileModifiedDate=m1.FileModifiedDate
)T1 inner join #MOSchedule M on M.MachineID=T1.MachineID and M.PartID=T1.PartID and m.MONumber=T1.MONumber and M.FileModifiedDate=T1.FileModifiedDate

update #MOSchedule set LastModifiedDate=T1.LastModifiedDate from
(select M1.MoNumber,M1.MachineID,M1.PartID,M1.OperationNo,Max(M.LastModifiedDate)  as LastModifiedDate from MOSchedule M
inner join #MOSchedule M1 on M.MachineID=M1.MachineID and M.PartID=M1.PartID and m.MONumber=M1.MONumber 
group by M1.MoNumber,M1.MachineID,M1.PartID,M1.OperationNo
)T1 inner join #MOSchedule M on M.MachineID=T1.MachineID and M.PartID=T1.PartID and m.MONumber=T1.MONumber


update #MOSchedule set MOStatus=T1.MOStatus from
(select M1.MoNumber,M1.MachineID,M1.PartID,M1.OperationNo,Case When M.MOStatus='4' and M.Status in('N','M') then 'Open' when M.MOStatus='5' and M.Status='C'  then 'Closed'
 when M.MOStatus='4' and M.Status='R' then 'Running' end as MOStatus from MOSchedule M
inner join #MOSchedule M1 on M.MachineID=M1.MachineID and M.PartID=M1.PartID and m.MONumber=M1.MONumber 
)T1 inner join #MOSchedule M on M.MachineID=T1.MachineID and M.PartID=T1.PartID and m.MONumber=T1.MONumber

select slno,MoNumber,MachineID,PartID,Quantity as [Count],FileModifiedDate as [Entry To Eshopx],MOStatus as LastStatus,LastModifiedDate as [Date&Time] from #MOSchedule 
order by slno

END
