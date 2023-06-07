/****** Object:  Procedure [dbo].[S_Get_JobCard_Jina]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[S_Get_JobCard_Jina] '2015-06-30','A','CNC-16','','','','111','View'
CREATE PROCEDURE [dbo].[S_Get_JobCard_Jina]
@date datetime,
@Shift nvarchar(50),
@machine nvarchar(max),
@Component nvarchar(50)='',
@operation nvarchar(50)='',--na
@operator nvarchar(100)='',--na
@WorkOrderNum nvarchar(50)='',
@param nvarchar(50)=''--na
	
AS
BEGIN

	SET NOCOUNT ON;


create table #temp
(
[ID] bigint,
[Date]  datetime,
[Shift] nvarchar(50),
[Machine] nvarchar(50),
[WorkOrderNumber] nvarchar(50),
[Component] nvarchar(50),
[Operation] nvarchar(50),
[Operator] nvarchar(50),
[Qty] int,
[Operator_Rejection] int,
[Operator_Rework] int,
[Supervisor_Rejection] int,
[Supervisor_Rework] int,
[QualityInspector_Rejection] int,
[QualityInspector_Rework] int,

)
create table #machines
( Machine nvarchar(50)
)

 if isnull(@Machine,'')<> ''  
 begin  
 	insert into #machines(machine)
	SELECT val FROM dbo.Split(@machine, ',')
 end  




insert into #temp([ID],[Date],[Shift],[Machine],[WorkOrderNumber],[Component],[Operation],[Operator],[Qty])
select a.ID,a.[Date],a.[Shift],a.[Machine],a.[WorkOrderNumber],a.[Component],a.[Operation],a.[Operator],a.[Qty] from Production_Summary_Jina a 
where a.[Date]=@date and a.[Shift]=@Shift and a.Machine in (select machine from #machines) and (a.WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='') and (a.Component=@Component or @Component= '')

update  #temp set [Operator_Rejection]=	t.QTY from
(select [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag,sum(Rejection_Rework_Qty)as QTY 
from [dbo].[Rejection_Rework_Details_Jina]
where  Rejection_Rework_flag='Rejection' 
group by [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag)t 
inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component]and t1.[Operation]=t.[Operation]  and t1.[Operator]=t.[Operator]  
where t.Person_Flag='Operator' 

update  #temp set [Supervisor_Rejection]=	t.QTY from
(select [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag,sum(Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina]
where  Rejection_Rework_flag='Rejection'
group by [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag)t 
inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component]and t1.[Operation]=t.[Operation] and t1.[Operator]=t.[Operator]  
where Person_Flag='Supervisor'

update  #temp set [QualityInspector_Rejection]=	t.QTY from
(select [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag,sum(Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina]
where  Rejection_Rework_flag='Rejection'
group by [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag)t 
inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component]and t1.[Operation]=t.[Operation] and t1.[Operator]=t.[Operator]  
where Person_Flag='QualityInspector'


update  #temp set [Operator_Rework]=t.QTY from
(select [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag,sum(Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina]
where  Rejection_Rework_flag='ReworkPerformed'
group by [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag)t
inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component] and t1.[Operation]=t.[Operation] and t1.[Operator]=t.[Operator]  
 where Person_Flag='Operator'

update  #temp set [Supervisor_Rework]=	t.QTY from
(select [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag,sum(Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina]
where  Rejection_Rework_flag='ReworkPerformed'
group by [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag)t 
inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component] and t1.[Operation]=t.[Operation] and t1.[Operator]=t.[Operator]  
where Person_Flag='Supervisor'

update  #temp set [QualityInspector_Rework] =	t.QTY from
(select [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag,sum(Rejection_Rework_Qty)as QTY from [dbo].[Rejection_Rework_Details_Jina]
where  Rejection_Rework_flag='MarkedForReWork'
group by [Date],[Shift],[Machine],[WorkorderNumber],[Component],[Operation],[Operator],Person_Flag)t 
inner join #temp t1 on t1.[Date]= t.[Date] and t1.[Shift]= t.[Shift] and t1.[Machine]=t.[Machine] and t1.[WorkorderNumber]= t.[WorkorderNumber] and t1.[Component]= t.[Component] and t1.[Operation]=t.[Operation] and t1.[Operator]=t.[Operator]  
where Person_Flag='QualityInspector'


select * from #temp;


End
