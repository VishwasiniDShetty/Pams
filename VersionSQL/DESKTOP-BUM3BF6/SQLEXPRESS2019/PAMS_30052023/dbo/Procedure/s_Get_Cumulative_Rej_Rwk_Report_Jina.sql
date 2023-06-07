/****** Object:  Procedure [dbo].[s_Get_Cumulative_Rej_Rwk_Report_Jina]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from Rejection_Rework_Details_Jina
--[s_Get_Cumulative_Rej_Rwk_Report_Jina] '2015-09-15 00:00:00.000','2015-09-15 00:00:00.000','','','','','123','','SimpleSearch'
CREATE PROCEDURE [dbo].[s_Get_Cumulative_Rej_Rwk_Report_Jina]
	@Startdate datetime='',
	@EndDate datetime='',
	@StartShift nvarchar(50)='',
	@EndShift nvarchar(50)='',
	@machine nvarchar(50)='',
	@Component nvarchar(50)='',
	@workOrderNum nvarchar(50)='',
	@operation nvarchar(50)='',
	@param nvarchar(50)=''

AS
BEGIN
	
	SET NOCOUNT ON;

	create table #temp
	(
	[Code]int,
	RejReason nvarchar(50),
	[CumRej] int default 0,
	[Total] int default 0,
	[TotalOperation] float default 0,
	[TotalRej] float default 0,
	[percentageRej] float default 0
	)

	create table #temp1
	(
	[Code]int,
	[RwkReason] nvarchar(50),
	[CumRwk] int default 0,
	[Total] int default 0,
	[TotalOperation] float default 0,
	[TotalRwk] float default 0,
	[percentageRwk]  float default 0
	)

	create table #machines
	( 
		Machine nvarchar(50)
	)

	declare @StDate datetime;
	declare @Start datetime;
	declare @End datetime;
	create table #temp12
	(
	[Date] datetime,
	[Shift] nvarchar(50),
	[ShiftID] int,
	[Code]int,
	[Qty] int,
	Rejection_Rework_flag nvarchar(50),
	Person_Flag nvarchar(50)
	)

	Create Table #ShiftTemp
	(
	PDate datetime,
	ShiftName nvarchar(20) null,
	FromTime datetime,
	ToTime Datetime
	)

	 if isnull(@Machine,'')<> ''  
	 begin  
 		insert into #machines(machine)
		SELECT val FROM dbo.Split(@machine, ',')
	 end  

	insert into #temp(code,RejReason)
	SELECT interfaceid,rejectionId FROM rejectioncodeinformation;


	insert into #temp1(code,[RwkReason])
	SELECT Reworkinterfaceid,[ReworkId] FROM Reworkinformation;

	if exists(select parameter from shopdefaults where ValueInText='Supervisor')
	BEGIN

	if @param='SimpleSearch'
	Begin
	--for Rejection

	update #temp set [CumRej]=t.Qty from 
									(select t.Code,sum(t.Rejection_Rework_Qty)as QTY from [Rejection_Rework_Details_Jina] t where  t.Rejection_Rework_flag='Rejection' and t.person_Flag='Supervisor' and(t.WorkOrderNumber=@WorkOrderNum ) 
									group by t.Code)t inner join #temp on  #temp.code=t.code

	update #temp set [Total]=  t.Total from (select  sum([CumRej]) as Total  from #temp)t 	

	update #temp set [TotalOperation]=t.Qty from  (select sum(Qty) as Qty from Production_Summary_Jina
								where operation=(select max(operation) from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum )and operation<>'9999')  and (WorkOrderNumber=@WorkOrderNum ) )t	


		
	update #temp set [TotalRej]=isnull(t.Qty,0) from  (select sum(Rejection_Rework_Qty) as Qty from [Rejection_Rework_Details_Jina] where  Rejection_Rework_flag='Rejection' and person_Flag='Supervisor'and 
								 operation=(select max(operation) from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum )and operation<>'9999')  and (WorkOrderNumber=@WorkOrderNum ) )t	

	update #temp set [TotalOperation]=[TotalOperation]+isnull([TotalRej],0)
								
	update #temp set [percentageRej]=round(([CumRej]*100)/(isnull([TotalOperation],0)),4) from #temp where [TotalOperation]>0 ;				
																				
	--for Rework
	update #temp1 set [CumRwk]=t.Qty from 
							(select t.Code,sum(t.Rejection_Rework_Qty)as QTY from [Rejection_Rework_Details_Jina] t where (t.Rejection_Rework_flag='ReworkPerformed' ) 
							and t.person_Flag='Supervisor' and (t.WorkOrderNumber=@WorkOrderNum ) 
							group by t.Code)t inner join #temp1 on  #temp1.code=t.code

	update #temp1 set [Total]= t.Total from (select  sum([CumRwk]) as Total  from #temp1)t 

	update #temp1 set [TotalOperation]= isnull(t.Qty,0) from  (select sum(Qty) as Qty from Production_Summary_Jina
													where (operation=(select max(operation) from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum )and operation<>'9999'))  and (WorkOrderNumber=@WorkOrderNum )  )t

		update #temp1 set [percentageRwk]=	round(([CumRwk]*100)/(isnull([TotalOperation],0)),4) from #temp1 where TotalOperation >0;				
								

	select * from #temp where [CumRej]>0 order by [CumRej] desc;
	select * from #temp1  where [CumRwk]>0 order by [CumRwk] desc;

	select top 1 @Start = CreatedDate from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='') order by CreatedDate 
	select top 1 @End = CreatedDate from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='')  order by CreatedDate desc 
	select @Start as StartTime,@End as EndTime;
	
	End

	if @param='AdvancedSearch'
	Begin
	
	
		SET @StDate =@Startdate;
		While(@StDate <= @EndDate)
		BEGIN
			Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)
			Exec s_GetShiftTime @StDate,''
			SELECT @StDate = Dateadd(Day,1,@StDate)
		END


				
	delete from  #ShiftTemp  where PDate = @Startdate and ShiftName < @StartShift and @StartShift <>''
	delete from  #ShiftTemp  where PDate = @Enddate and  ShiftName > @EndShift and @EndShift <>''


				
	insert into #temp12([Date],[Shift],[Code],[Qty],Rejection_Rework_flag,Person_Flag)
	--select a.[Date],a.[Shift],a.Code,a.Rejection_Rework_Qty,a.Rejection_Rework_flag from [Rejection_Rework_Details_Jina] a inner join #ShiftTemp b on a.Shift=b.ShiftName and a.Date=b.PDate
	--where  a.Machine in (select machine from #machines) and (a.WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='') and (a.Component=@Component or @Component= '')
	select a.[Date],a.[Shift],a.Code,a.Rejection_Rework_Qty,a.Rejection_Rework_flag,a.Person_flag from [Rejection_Rework_Details_Jina] a inner join #ShiftTemp b on a.Shift=b.ShiftName and a.Date=b.PDate
	where (a.machine=@machine or @machine='')  and (a.Operation=@operation or @operation='') and (a.WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='') and (a.Component=@Component or @Component= '')


	update #temp set [CumRej]=isnull(t.Qty,0) from 
									(select t.Code,sum(t.QTY)as QTY from #temp12 t where  t.Rejection_Rework_flag='Rejection' and t.person_Flag='Supervisor'
									group by t.Code)t inner join #temp on  #temp.code=t.code

	update #temp set [Total]= isnull(t.Total,0) from (select  sum([CumRej]) as Total  from #temp)t 



	if (@operation='')
	Begin
	update #temp set [TotalOperation]= isnull(t.Qty,0) from  (select sum(a.Qty) as Qty from Production_Summary_Jina a inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName]
													where (a.machine=@machine or @machine='')  and  a.operation=(select max(a.operation) from Production_Summary_Jina a where (a.machine=@machine or @machine='') and (a.Component=@Component )and operation<>'9999')   and (a.Component=@Component ))t


	update #temp set [TotalRej]=t.Qty from  (select sum(Rejection_Rework_Qty) as Qty from [Rejection_Rework_Details_Jina]a  inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName] where  a.Rejection_Rework_flag='Rejection' and a.person_Flag='Supervisor'and 
								 a.operation=(select max(b.operation) from Production_Summary_Jina b where (b.machine=@machine or @machine='') and (b.Component=@Component )and operation<>'9999')  and (a.Component=@Component ))t

	update #temp set [TotalOperation]=[TotalOperation]+[TotalRej]
								
	End

	else
	Begin
	update #temp set [TotalOperation]= isnull(t.Qty,0) from  (select sum(a.Qty) as Qty from Production_Summary_Jina a inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName]
													where (a.machine=@machine or @machine='')  and  a.operation=(@operation)   and (a.Component=@Component))t
	
	update #temp set [TotalRej]=isnull(t.Qty,0) from  (select sum(Rejection_Rework_Qty) as Qty from [Rejection_Rework_Details_Jina]a  inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName] where  a.Rejection_Rework_flag='Rejection' and a.person_Flag='Supervisor'and 
								 a.operation=@operation  and (a.Component=@Component ))t

	update #temp set [TotalOperation]=[TotalOperation]+isnull([TotalRej],0)

	End

	update #temp set [percentageRej]=	round(([CumRej]*100)/([TotalOperation]),4) from #temp where [TotalOperation]>0;				
								


	update #temp1 set [CumRwk]=isnull(t.Qty,0) from 
							(select t.Code,sum(t.QTY)as QTY from #temp12 t where  t.Rejection_Rework_flag='ReworkPerformed' and t.person_Flag='Supervisor'
							group by t.Code)t inner join #temp1 on  #temp1.code=t.code

	update #temp1 set [Total]=  isnull(t.Total,0) from (select  sum([CumRwk]) as Total  from #temp1)t 



	if @operation=''
	Begin
	update #temp1 set [TotalOperation]= isnull(t.Qty,0) from  (select sum(a.Qty) as Qty from Production_Summary_Jina a  inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName]
													where (a.machine=@machine or @machine='')  and  a.operation=(select max(a.operation) from Production_Summary_Jina a where (a.machine=@machine or @machine='') and (a.Component=@Component )and operation<>'9999')   and (a.Component=@Component ))t
	
	update #temp1 set [TotalRwk]=isnull(t.Qty,0) from  (select sum(Rejection_Rework_Qty) as Qty from [Rejection_Rework_Details_Jina]a  inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName] where  a.Rejection_Rework_flag='Rejection' and a.person_Flag='Supervisor'and 
								 a.operation=(select max(b.operation) from Production_Summary_Jina b where (b.machine=@machine or @machine='') and (b.Component=@Component )and operation<>'9999')  and (a.Component=@Component ))t

	update #temp1 set [TotalOperation]=[TotalOperation]+isnull([TotalRwk],0)
	End
	
	else
	Begin
	update #temp1 set [TotalOperation]= isnull(t.Qty,0) from  (select sum(a.Qty) as Qty from Production_Summary_Jina a inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName]
													where (a.machine=@machine or @machine='')  and  a.operation=(@operation)  and (a.Component=@Component))t
	update #temp1 set [TotalRwk]=isnull(t.Qty,0) from  (select sum(Rejection_Rework_Qty) as Qty from [Rejection_Rework_Details_Jina]a  inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName] where  a.Rejection_Rework_flag='Rejection' and a.person_Flag='Supervisor'and 
								 a.operation=@operation  and (a.Component=@Component ))t

	update #temp1 set [TotalOperation]=[TotalOperation]+isnull([TotalRwk],0)
	End


	update #temp1 set [percentageRwk]=	round(([CumRwk]*100)/([TotalOperation]),4) from #temp1 where [TotalOperation]>0;		

	select * from #temp where [CumRej]>0 order by [CumRej] desc;
	select * from #temp1  where [CumRwk]>0 order by [CumRwk] desc;

	select top 1 @Start = CreatedDate from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='') order by CreatedDate 
	select top 1 @End = CreatedDate from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='')  order by CreatedDate desc 
	select @Start as StartTime,@End as EndTime;

	end
	
	END

	if exists(select parameter from shopdefaults where ValueInText='FinalInspection')
	BEGIN

	if @param='SimpleSearch'
	Begin
	--for Rejection

	update #temp set [CumRej]=t.Qty from 
									(select t.Code,sum(t.Rejection_Rework_Qty)as QTY from [Rejection_Rework_Details_Jina] t where  t.Rejection_Rework_flag='Rejection' and
									 (person_Flag='Supervisor' or Person_flag='QualityInspector') and(t.WorkOrderNumber=@WorkOrderNum ) 
									group by t.Code)t inner join #temp on  #temp.code=t.code

	update #temp set [Total]=  t.Total from (select  sum([CumRej]) as Total  from #temp)t 	

	update #temp set [TotalOperation]=t.Qty from  (select sum(Qty) as Qty from Production_Summary_Jina
								where operation=(select max(operation) from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum )and operation<>'9999')  and (WorkOrderNumber=@WorkOrderNum ) )t	


		
	update #temp set [TotalRej]=isnull(t.Qty,0) from  (select sum(Rejection_Rework_Qty) as Qty from [Rejection_Rework_Details_Jina] where  Rejection_Rework_flag='Rejection' and (person_Flag='Supervisor' or Person_flag='QualityInspector')and 
								 operation=(select max(operation) from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum )and operation<>'9999')  and (WorkOrderNumber=@WorkOrderNum ) )t	

	update #temp set [TotalOperation]=[TotalOperation]+isnull([TotalRej],0)
								
	update #temp set [percentageRej]=round(([CumRej]*100)/(isnull([TotalOperation],0)),4) from #temp where [TotalOperation]>0 ;				
																				
	--for Rework
	update #temp1 set [CumRwk]=t.Qty from 
							(select t.Code,sum(t.Rejection_Rework_Qty)as QTY from [Rejection_Rework_Details_Jina] t where (t.Rejection_Rework_flag='ReworkPerformed' or t.Rejection_Rework_flag='MarkedForRework')
							and (person_Flag='Supervisor' or Person_flag='QualityInspector') and (t.WorkOrderNumber=@WorkOrderNum ) 
							group by t.Code)t inner join #temp1 on  #temp1.code=t.code

	update #temp1 set [Total]= t.Total from (select  sum([CumRwk]) as Total  from #temp1)t 

	update #temp1 set [TotalOperation]= isnull(t.Qty,0) from  (select sum(Qty) as Qty from Production_Summary_Jina
													where (operation=(select max(operation) from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum )and operation<>'9999'))  and (WorkOrderNumber=@WorkOrderNum )  )t

		update #temp1 set [percentageRwk]=	round(([CumRwk]*100)/(isnull([TotalOperation],0)),4) from #temp1 where [TotalOperation]>0 ;					
								

	select * from #temp where [CumRej]>0 order by [CumRej] desc;
	select * from #temp1  where [CumRwk]>0 order by [CumRwk] desc;

	select top 1 @Start = CreatedDate from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='') order by CreatedDate 
	select top 1 @End = CreatedDate from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='')  order by CreatedDate desc 
	select @Start as StartTime,@End as EndTime;
	End

	if @param='AdvancedSearch'
	Begin
	
	delete from #ShiftTemp

		SET @StDate =@Startdate;
		While(@StDate <= @EndDate)
		BEGIN
			Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)
			Exec s_GetShiftTime @StDate,''
			SELECT @StDate = Dateadd(Day,1,@StDate)
		END


				
	delete from  #ShiftTemp  where PDate = @Startdate and ShiftName < @StartShift and @StartShift <>''
	delete from  #ShiftTemp  where PDate = @Enddate and  ShiftName > @EndShift and @EndShift <>''


				
	insert into #temp12([Date],[Shift],[Code],[Qty],Rejection_Rework_flag,Person_Flag)
	select a.[Date],a.[Shift],a.Code,a.Rejection_Rework_Qty,a.Rejection_Rework_flag,a.Person_flag from [Rejection_Rework_Details_Jina] a inner join #ShiftTemp b on a.Shift=b.ShiftName and a.Date=b.PDate
	where (a.machine=@machine or @machine='')  and (a.Operation=@operation or @operation='') and (a.WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='') and (a.Component=@Component or @Component= '')

	
	update #temp set [CumRej]=isnull(t.Qty,0) from 
									(select t.Code,sum(t.QTY)as QTY from #temp12 t where  t.Rejection_Rework_flag='Rejection' 
									and (person_Flag='Supervisor' or Person_flag='QualityInspector')
									group by t.Code)t inner join #temp on  #temp.code=t.code

	update #temp set [Total]= isnull(t.Total,0) from (select  sum([CumRej]) as Total  from #temp)t 



	if (@operation='')
	Begin
	update #temp set [TotalOperation]= isnull(t.Qty,0) from  (select sum(a.Qty) as Qty from Production_Summary_Jina a inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName]
													where (a.machine=@machine or @machine='')  and  a.operation=(select max(a.operation) from Production_Summary_Jina a where (a.machine=@machine or @machine='') and (a.Component=@Component )and operation<>'9999')   and (a.Component=@Component ))t


	update #temp set [TotalRej]=t.Qty from  (select sum(Rejection_Rework_Qty) as Qty from [Rejection_Rework_Details_Jina]a  inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName] where  a.Rejection_Rework_flag='Rejection'
	and (person_Flag='Supervisor' or Person_flag='QualityInspector')and a.operation=(select max(b.operation) from Production_Summary_Jina b
	 where (b.machine=@machine or @machine='') and (b.Component=@Component )and operation<>'9999')  and (a.Component=@Component ))t

	update #temp set [TotalOperation]=[TotalOperation]+[TotalRej]
								
	End

	else
	Begin
	update #temp set [TotalOperation]= isnull(t.Qty,0) from  (select sum(a.Qty) as Qty from Production_Summary_Jina a inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName]
													where (a.machine=@machine or @machine='')  and  a.operation=(@operation)   and (a.Component=@Component))t
	
	update #temp set [TotalRej]=isnull(t.Qty,0) from  (select sum(Rejection_Rework_Qty) as Qty from [Rejection_Rework_Details_Jina]a  inner join #ShiftTemp S 
						on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName] where  a.Rejection_Rework_flag='Rejection'
					 and (person_Flag='Supervisor' or Person_flag='QualityInspector')and  a.operation=@operation  and (a.Component=@Component ))t

	update #temp set [TotalOperation]=[TotalOperation]+isnull([TotalRej],0)

	End

	update #temp set [percentageRej]=	round(([CumRej]*100)/([TotalOperation]),4) from #temp where [TotalOperation]>0;				
								


	update #temp1 set [CumRwk]=isnull(t.Qty,0) from 
							(select t.Code,sum(t.QTY)as QTY from #temp12 t where   (t.Rejection_Rework_flag='ReworkPerformed' or t.Rejection_Rework_flag='MarkedForRework') and
							(person_Flag='Supervisor' or Person_flag='QualityInspector')
							group by t.Code)t inner join #temp1 on  #temp1.code=t.code

	update #temp1 set [Total]=  isnull(t.Total,0) from (select  sum([CumRwk]) as Total  from #temp1)t 



	if @operation=''
	Begin
	update #temp1 set [TotalOperation]= isnull(t.Qty,0) from  (select sum(a.Qty) as Qty from Production_Summary_Jina a  inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName]
													where (a.machine=@machine or @machine='')  and  a.operation=(select max(a.operation) from Production_Summary_Jina a where (a.machine=@machine or @machine='') 
													and (a.Component=@Component )and operation<>'9999')   and (a.Component=@Component ))t
	
	update #temp1 set [TotalRwk]=isnull(t.Qty,0) from  (select sum(Rejection_Rework_Qty) as Qty from [Rejection_Rework_Details_Jina]a  
	inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName] where 
	a.Rejection_Rework_flag='Rejection' and (person_Flag='Supervisor' or Person_flag='QualityInspector') and 
	a.operation=(select max(b.operation) from Production_Summary_Jina b where (b.machine=@machine or @machine='')
	and (b.Component=@Component )and operation<>'9999')  and (a.Component=@Component ))t

	update #temp1 set [TotalOperation]=[TotalOperation]+isnull([TotalRwk],0)
	End
	
	else
	Begin
	update #temp1 set [TotalOperation]= isnull(t.Qty,0) from  (select sum(a.Qty) as Qty from Production_Summary_Jina a inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName]
	where (a.machine=@machine or @machine='')  and  a.operation=(@operation)  and (a.Component=@Component))t

	update #temp1 set [TotalRwk]=isnull(t.Qty,0) from  (select sum(Rejection_Rework_Qty) as Qty from [Rejection_Rework_Details_Jina]a  inner join #ShiftTemp S on a.Date=S.[PDate] and a.[Shift]=S.[ShiftName]
	where  a.Rejection_Rework_flag='Rejection' and (person_Flag='Supervisor' or Person_flag='QualityInspector')and 
	a.operation=@operation  and (a.Component=@Component ))t

	update #temp1 set [TotalOperation]=[TotalOperation]+isnull([TotalRwk],0)
	End


	update #temp1 set [percentageRwk]=	round(([CumRwk]*100)/([TotalOperation]),4) from #temp1 where [TotalOperation]>0;		

	select * from #temp where [CumRej]>0 order by [CumRej] desc;
	select * from #temp1  where [CumRwk]>0 order by [CumRwk] desc;

	select top 1 @Start = CreatedDate from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='') order by CreatedDate 
	select top 1 @End = CreatedDate from Production_Summary_Jina where (WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='')  order by CreatedDate desc 
	select @Start as StartTime,@End as EndTime;

	end
	
	END

END
