/****** Object:  Procedure [dbo].[S_ViewJobCardRejectionRework]    Committed by VersionSQL https://www.versionsql.com ******/

-- Batch submitted through debugger: SQLQuery19.sql|7|0|C:\Users\vasavip\AppData\Local\Temp\~vs3EF0.sql

--select * from [Rejection_Rework_Details_Jina]
--select * from Production_Summary_Jina
--[dbo].[S_ViewJobCardRejectionRework] '2015-06-30 00:00:00.000','A','CNC-15','LA25BWD03-LKD','2','108','444','View'
CREATE PROCEDURE [dbo].[S_ViewJobCardRejectionRework]
@date datetime='',
@Shift nvarchar(50)='',
@machine nvarchar(50)='',
@Component nvarchar(50)='',
@operation nvarchar(50)='',
@operator nvarchar(100)='',
@WorkOrderNum nvarchar(50)='',
@param nvarchar(50)=''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


create table #temp
(
[Date]  datetime,
[Shift] nvarchar(50),
[Machine] nvarchar(50),
[WorkOrderNumber] nvarchar(50),
[Component] nvarchar(50),
[Operation] nvarchar(50),
[Operator] nvarchar(50),
[Qty] int
)

create table #temp1
(
Code int,
Reason nvarchar(50),
Rej_Operator int default 0,
Rej_Supervisor int default 0,
Rej_FinalInspection int default 0,
Rwk_Operator int default 0,
Rwk_Supervisor int default 0,
Rwk_FinalInspection int default 0,
Sum_Rej_Operator int default 0,
Sum_Rej_Supervisor int default 0,
Sum_Rej_FinalInspection int default 0,
Sum_Rwk_Operator int default 0,
Sum_Rwk_Supervisor int default 0,
Sum_Rwk_FinalInspection int default 0

)

insert into #temp([Date],[Shift],[Machine],[WorkOrderNumber],[Component],[Operation],[Operator],[Qty])
select a.[Date],a.[Shift],a.[Machine],a.[WorkOrderNumber],a.[Component],a.[Operation],a.[Operator],a.[Qty] from Production_Summary_Jina a 
where a.[Date]=@date and a.[Shift]=@Shift and a.Machine =@machine and a.[WorkOrderNumber]=@WorkOrderNum and a.[Component]=@Component and a.Operation=@operation and a.[Operator]=@operator

insert into #temp1(Code,Reason)
select  b.interfaceid,b.rejectionID  from rejectioncodeinformation b --on a.code=b.InterfaceID
--where a.[Date]=@date and a.[Shift]=@Shift and a.Machine =@machine and a.[WorkOrderNumber]=@WorkOrderNum and a.[Component]=@Component and a.Operation=@operation and a.[Operator]=@operator
--order by b.interfaceid asc
update #temp1 set Rej_Operator=t.Qty from
 (select t.Code,sum(t.Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina] t
 inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component]and t1.[Operation]=t.[Operation]  and t1.[Operator]=t.[Operator]  
where  Rejection_Rework_flag='Rejection' and Person_Flag='Operator' 
group by t.Code)t inner join #temp1 on  #temp1.Code=t.Code

update #temp1 set Rej_Supervisor=t.Qty from
 (select t.Code,sum(t.Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina] t
 inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component]and t1.[Operation]=t.[Operation]  and t1.[Operator]=t.[Operator]  
where  Rejection_Rework_flag='Rejection' and Person_Flag='Supervisor' 
group by t.Code)t inner join #temp1 on  #temp1.Code=t.Code

update #temp1 set Rej_FinalInspection=t.Qty from
 (select t.Code,sum(t.Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina] t
 inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component]and t1.[Operation]=t.[Operation]  and t1.[Operator]=t.[Operator]  
where  Rejection_Rework_flag='Rejection' and Person_Flag='QualityInspector' 
group by t.Code)t inner join #temp1 on  #temp1.Code=t.Code


update #temp1 set Rwk_Operator=t.Qty from
 (select t.Code,sum(t.Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina] t
 inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component]and t1.[Operation]=t.[Operation]  and t1.[Operator]=t.[Operator]  
where  Rejection_Rework_flag='ReworkPerformed' and Person_Flag='Operator' 
group by t.Code)t inner join #temp1 on  #temp1.Code=t.Code

update #temp1 set Rwk_Supervisor=t.Qty from
 (select t.Code,sum(t.Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina] t
 inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component]and t1.[Operation]=t.[Operation]  and t1.[Operator]=t.[Operator]  
where  Rejection_Rework_flag='ReworkPerformed' and Person_Flag='Supervisor' 
group by t.Code)t inner join #temp1 on  #temp1.Code=t.Code

update #temp1 set Rwk_FinalInspection=t.Qty from
 (select t.Code,sum(t.Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina] t
 inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component]and t1.[Operation]=t.[Operation]  and t1.[Operator]=t.[Operator]  
where  Rejection_Rework_flag='MarkedForReWork' and Person_Flag='QualityInspector' 
group by t.Code)t inner join #temp1 on  #temp1.Code=t.Code


update #temp1 set Sum_Rej_Operator=t.Sum_Rej_Operator,Sum_Rej_Supervisor=t.Sum_Rej_Supervisor,Sum_Rej_FinalInspection=t.Sum_Rej_FinalInspection,
Sum_Rwk_Operator=t.Sum_Rwk_Operator,Sum_Rwk_Supervisor=t.Sum_Rwk_Supervisor,Sum_Rwk_FinalInspection=t.Sum_Rwk_FinalInspection
from
(select sum(Rej_Operator)as Sum_Rej_Operator,Sum(Rej_Supervisor) as Sum_Rej_Supervisor,Sum(Rej_FinalInspection) as Sum_Rej_FinalInspection,Sum(Rwk_Operator) as Sum_Rwk_Operator,
Sum(Rwk_Supervisor) as Sum_Rwk_Supervisor,Sum(Rwk_FinalInspection) as Sum_Rwk_FinalInspection from #temp1)t

select * from #temp1 order by Code asc;

END
