/****** Object:  Procedure [dbo].[s_Get_CumulativeReport_Jina]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from Rejection_Rework_Details_Jina
--dbo.[s_Get_CumulativeReport_Jina]'2015-10-14 00:00:00.000','B','',''
CREATE PROCEDURE [dbo].[s_Get_CumulativeReport_Jina]
	@date datetime='',
	@Shift nvarchar(50)='',
	@Component nvarchar(50)='',
	@workOrderNum nvarchar(50)=''

AS
BEGIN
	
	SET NOCOUNT ON;

	Declare @ShiftID int;
	select @ShiftID=shiftid from shiftdetails where shiftdetails.ShiftName=@Shift and Running=1;

		
	create table #temp
	(
	[Code]int,
	[CumRej] int default 0,
	[CumRwk] int default 0,
	[Sum_CumRej] int default 0,
	[Sum_CumRwk] int default 0

	)

	create table #temp1
	(
	[Date] datetime,
	[Shift] nvarchar(50),
	[ShiftID] int,
	[Code]int,
	[Qty] int,
	Rejection_Rework_flag nvarchar(50),
	[Person_Flag] nvarchar(50)
	)
	
	
	insert into #temp(code)
	SELECT interfaceid FROM rejectioncodeinformation
	UNION
	SELECT Reworkinterfaceid FROM Reworkinformation;
	
	insert into #temp1([Date],[Shift],[ShiftID],[Code],[Qty],Rejection_Rework_flag,person_Flag)
	select t.Date,t.Shift,b.shiftid, t.Code,t.Rejection_Rework_Qty,Rejection_Rework_flag,person_Flag from [dbo].[Rejection_Rework_Details_Jina] t inner join ShiftDetails b on t.Shift=b.ShiftName 
	where t.[date]<=@date and b.shiftid<= @ShiftID and (t.WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='') and (t.Component=@Component or @Component= '') and b.running=1 


	if exists(select Parameter from ShopDefaults where ValueInText='Supervisor')
	BEGIN
	update #temp set [CumRej]=t.Qty from 
									(select t.Code,sum(t.[Qty])as QTY from [dbo].#temp1 t where  t.Rejection_Rework_flag='Rejection' and t.person_Flag='Supervisor'
									group by t.Code)t inner join #temp on  #temp.code=t.code

	update #temp set [CumRwk]=t.Qty from 
							(select t.Code,sum(t.[Qty])as QTY from [dbo].#temp1 t where  t.Rejection_Rework_flag='ReworkPerformed' and t.person_Flag='Supervisor'
							group by t.Code)t inner join #temp on  #temp.code=t.code
	END
	
	if exists(select Parameter from ShopDefaults where ValueInText='FinalInspection')
	BEGIN
	update #temp set [CumRej]=t.Qty from 
									(select t.Code,sum(t.[Qty])as QTY from [dbo].#temp1 t where  t.Rejection_Rework_flag='Rejection' and 
									(t.person_Flag='Supervisor' or t.person_Flag='QualityInspector') 
									group by t.Code)t inner join #temp on  #temp.code=t.code

	update #temp set [CumRwk]=t.Qty from 
							(select t.Code,sum(t.[Qty])as QTY from [dbo].#temp1 t where  (t.Rejection_Rework_flag='ReworkPerformed' or t.Rejection_Rework_flag='MarkedForRework')
							and (t.person_Flag='Supervisor' or t.person_Flag='QualityInspector') 
							group by t.Code)t inner join #temp on  #temp.code=t.code
	END
	


	update #temp set [Sum_CumRej]=t.[CumRej],[Sum_CumRwk]=t.[CumRwk] from 
	(select sum([CumRej]) as [CumRej] , sum([CumRwk]) as [CumRwk]   from [dbo].#temp
	)t 

	select * from #temp order by code;


	
 
  
	
END
