﻿/****** Object:  Procedure [dbo].[s_GetOEE_losses_BOSCH_BNG_CamShaft]    Committed by VersionSQL https://www.versionsql.com ******/

/* Procedure Created By Karthik G on 12/Jul/2009 for showing OEE and other Loss Foctors.
NR0056 - KarthikG - 05/Jun/2009 - Need new Excel Report showing OEE and other Loss Foctors.
Used in the report (SM->Agg report->Breakdown Report->OEE Losses.)
s_GetOEE_losses_BOSCH_BNG_CamShaft '2009-12-01','MCV 400','DownCategory',''
*/
CREATE 	procedure [dbo].[s_GetOEE_losses_BOSCH_BNG_CamShaft]
	@dDate as DateTime,
	@MachineID as nvarchar(50),
	@DownID_Category as nvarchar(50),--DownID,DownCategory
	@param as nvarchar(50)--'','BOSCH_BNG_CamShaft'
as
BEGIN
Declare @tempDate as datetime
Declare @InPutDate as datetime
Declare @Counter as int
Set @Counter = 1
set @InPutDate=@dDate
set @dDate = cast(cast(datepart(yyyy,@dDate)as nvarchar(4))+'-'+cast(datepart(mm,@dDate)as nvarchar(4))+'-01' as datetime)
CREATE TABLE #DownID_Category (DownID_Category nvarchar(50),idd int identity(4,1))
CREATE TABLE #YearMonthDay (YearMonthDay nvarchar(50),ColumnHeader DateTime)
CREATE TABLE #OEE_losses (YearMonthDay nvarchar(50),ColumnHeader DateTime,RowHeader nvarchar(50),RowValue Float,idd int)
Insert Into #DownID_Category select 'OEE'
Insert Into #DownID_Category select 'QualityLoss'
Insert Into #DownID_Category select 'PE loss'
if @DownID_Category = 'DownCategory'
Begin
	Insert Into #DownID_Category Select distinct Catagory from downcodeinformation where Catagory is not null order by Catagory
End
else if @DownID_Category = 'DownID'
Begin
	Insert Into #DownID_Category Select distinct DownID from downcodeinformation where DownID is not null order by DownID
End
Insert Into #YearMonthDay select 'Year', @dDate
Set @tempDate = @dDate
Set @dDate = DateAdd(mm,1,@dDate)
Set @dDate = DateAdd(d,-1,@dDate)
while @Counter <= 31
Begin
	Insert Into #YearMonthDay select 'Day', @tempDate
	set @tempDate = DateAdd(d,1,@tempDate)
	Set @Counter = @Counter + 1
End
set @tempDate = cast(cast(datepart(yyyy,@tempDate)as nvarchar(4))+'-01-01' as datetime)
Set @dDate = DateAdd(yyyy,1,@tempDate)
While @tempDate < @dDate
Begin
	Insert Into #YearMonthDay select 'Month', @tempDate
	Set @tempDate = DateAdd(mm,1,@tempDate)
End
Insert into #OEE_losses Select YearMonthDay,ColumnHeader,DownID_Category,0,idd from #YearMonthDay cross join #DownID_Category order by YearMonthDay desc,ColumnHeader
update #OEE_losses set RowValue = 0
if @DownID_Category = 'DownCategory'
Begin
	--DownTime by Category - From Here====================================================================================
	Update #OEE_losses set RowValue = t1.DownTime from
	(Select dDate,DownCategory,sum(downtime) as DownTime from shiftdowntimedetails where MachineID = @MachineID
	and ML_Flag = 0 and datepart(mm,dDate) = datepart(mm,@InPutDate) and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate)
	group by dDate,DownCategory)
	as t1 inner join #OEE_losses on #OEE_losses.ColumnHeader = t1.dDate and
	#OEE_losses.RowHeader = t1.DownCategory and #OEE_losses.YearMonthDay = 'Day' 
	--from here
	and #OEE_losses.RowHeader not in ('LC7','LC16')
	--till here
	Update #OEE_losses set RowValue = t1.DownTime from
	(Select datepart(mm,dDate) as mnth,DownCategory,sum(downtime) as DownTime from shiftdowntimedetails
	where MachineID = @MachineID and ML_Flag = 0 and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate)
	group by datepart(mm,dDate),DownCategory)
	as t1 inner join #OEE_losses on Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and
	#OEE_losses.RowHeader = t1.DownCategory and #OEE_losses.YearMonthDay = 'Month'
	--from here
	and #OEE_losses.RowHeader not in ('LC7','LC16')
	--till here

	Update #OEE_losses set RowValue = t1.DownTime from
	(Select DownCategory,sum(downtime) as DownTime from shiftdowntimedetails
	where MachineID = @MachineID and ML_Flag = 0
	and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate) group by DownCategory)
	as t1 inner join #OEE_losses on #OEE_losses.RowHeader = t1.DownCategory and #OEE_losses.YearMonthDay = 'Year'
	--from here
	and #OEE_losses.RowHeader not in ('LC7','LC16')
	--till here

	--DownTime by Category - Till Here====================================================================================
End
else if @DownID_Category = 'DownID'
Begin
	--DownTime by Category - From Here ====================================================================================
	Update #OEE_losses set RowValue = t1.DownTime from
	(Select dDate,DownID,sum(downtime) as DownTime from shiftdowntimedetails where MachineID = @MachineID and ML_Flag = 0 and datepart(mm,dDate) = datepart(mm,@InPutDate) and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate) group by dDate,DownID)
	as t1 inner join #OEE_losses on #OEE_losses.ColumnHeader = t1.dDate and
	#OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Day'
	--from here
	and #OEE_losses.RowHeader not in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory not in ('LC7','LC16'))
	--till here

	Update #OEE_losses set RowValue = t1.DownTime from
	(Select datepart(mm,dDate) as mnth,DownID,sum(downtime) as DownTime from shiftdowntimedetails where MachineID = @MachineID and ML_Flag = 0 and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate) group by datepart(mm,dDate),DownID)
	as t1 inner join #OEE_losses on Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and
	#OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Month'
	--from here
	and #OEE_losses.RowHeader not in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory not in ('LC7','LC16'))
	--till here

	Update #OEE_losses set RowValue = t1.DownTime from
	(Select DownID,sum(downtime) as DownTime from shiftdowntimedetails where MachineID = @MachineID and ML_Flag = 0 and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate) group by DownID)
	as t1 inner join #OEE_losses on #OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Year'
	--from here
	and #OEE_losses.RowHeader not in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory not in ('LC7','LC16'))
	--till here
	--DownTime by Category - Till Here ====================================================================================
End
--OEE - From Here====================================================================================
Update #OEE_losses set RowValue = t1.CN from
(Select pDate,sum(AcceptedParts *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN from shiftproductiondetails where MachineID = @MachineID and datepart(mm,pDate) = datepart(mm,@InPutDate) and datepart(yyyy,pDate) = datepart(yyyy,@InPutDate) group by pDate)
as t1 inner join #OEE_losses on #OEE_losses.ColumnHeader = t1.pDate and #OEE_losses.RowHeader = 'OEE' and #OEE_losses.YearMonthDay = 'Day'
Update #OEE_losses set RowValue = t1.CN from
(Select datepart(mm,pDate) as mnth,sum(AcceptedParts *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN from shiftproductiondetails where MachineID = @MachineID and datepart(yyyy,pDate) = datepart(yyyy,@InPutDate) group by datepart(mm,pDate))
as t1 inner join #OEE_losses on Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and #OEE_losses.RowHeader = 'OEE' and #OEE_losses.YearMonthDay = 'Month'
Update #OEE_losses set RowValue = t1.CN from
(Select sum(AcceptedParts *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN from shiftproductiondetails where MachineID = @MachineID and datepart(yyyy,pDate) = datepart(yyyy,@InPutDate))
as t1 inner join #OEE_losses on #OEE_losses.RowHeader = 'OEE' and #OEE_losses.YearMonthDay = 'Year'
--OEE - Till Here ===================================================================================

--PE Loss - From Here============================================================================
Update #OEE_losses set RowValue = t1.PEloss from
(select pdate,Sum((Sum_of_ActCycleTime)-((CO_stdMachiningTime+CO_StdLoadUnload)*Prod_Qty)) as PEloss from shiftproductiondetails where machineid = @MachineID and datepart(yyyy,pDate) = datepart(yyyy,@InPutDate) and datepart(mm,pDate) = datepart(mm,@InPutDate) group by pdate)
as t1 inner join #OEE_losses on #OEE_losses.ColumnHeader = t1.pDate and #OEE_losses.RowHeader = 'PE Loss' and #OEE_losses.YearMonthDay = 'Day'
Update #OEE_losses set RowValue = t1.PEloss from
(Select datepart(mm,pDate) as mnth,Sum((Sum_of_ActCycleTime)-((CO_stdMachiningTime+CO_StdLoadUnload)*Prod_Qty)) as PEloss from shiftproductiondetails where MachineID = @MachineID and datepart(yyyy,pDate) = datepart(yyyy,@InPutDate) and datepart(mm,pDate) = datepart(mm,@InPutDate) group by datepart(mm,pDate))
as t1 inner join #OEE_losses on Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and #OEE_losses.RowHeader = 'PE Loss' and #OEE_losses.YearMonthDay = 'Month'
Update #OEE_losses set RowValue = t1.PEloss from
(Select Sum((Sum_of_ActCycleTime)-((CO_stdMachiningTime+CO_StdLoadUnload)*Prod_Qty)) as PEloss from shiftproductiondetails where MachineID = @MachineID and datepart(yyyy,pDate) = datepart(yyyy,@InPutDate))
as t1 inner join #OEE_losses on #OEE_losses.RowHeader = 'PE Loss' and #OEE_losses.YearMonthDay = 'Year'
--PE Loss - till Here============================================================================

--QualityLoss - From Here============================================================================
Update #OEE_losses set RowValue = t1.QualityLoss from
(select pdate,Sum((CO_stdMachiningTime+CO_StdLoadUnload)*Rejection_Qty) as QualityLoss from shiftproductiondetails spd inner join shiftrejectiondetails sdd on spd.ID = Sdd.ID where machineid = @MachineID and datepart(yyyy,pDate) = datepart(yyyy,@InPutDate) and datepart(mm,pDate) = datepart(mm,@InPutDate) group by pdate)
as t1 inner join #OEE_losses on #OEE_losses.ColumnHeader = t1.pDate and #OEE_losses.RowHeader = 'QualityLoss' and #OEE_losses.YearMonthDay = 'Day'
Update #OEE_losses set RowValue = t1.QualityLoss from
(Select datepart(mm,pDate) as mnth,Sum((CO_stdMachiningTime+CO_StdLoadUnload)*Rejection_Qty) as QualityLoss from shiftproductiondetails spd inner join shiftrejectiondetails sdd on spd.ID = Sdd.ID where MachineID = @MachineID and datepart(yyyy,pDate) = datepart(yyyy,@InPutDate) and datepart(mm,pDate) = datepart(mm,@InPutDate) group by datepart(mm,pDate))
as t1 inner join #OEE_losses on Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and #OEE_losses.RowHeader = 'QualityLoss' and #OEE_losses.YearMonthDay = 'Month'
Update #OEE_losses set RowValue = t1.QualityLoss from
(Select Sum((CO_stdMachiningTime+CO_StdLoadUnload)*Rejection_Qty) as QualityLoss from shiftproductiondetails spd inner join shiftrejectiondetails sdd on spd.ID = Sdd.ID where MachineID = @MachineID and datepart(yyyy,pDate) = datepart(yyyy,@InPutDate))
as t1 inner join #OEE_losses on #OEE_losses.RowHeader = 'QualityLoss' and #OEE_losses.YearMonthDay = 'Year'

if @DownID_Category = 'DownCategory'
Begin
	--DownTime by Category - From Here====================================================================================
	Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from
	(Select dDate,DownCategory,sum(downtime) as DownTime from shiftdowntimedetails where MachineID = @MachineID
	and ML_Flag = 0 and datepart(mm,dDate) = datepart(mm,@InPutDate) and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate)
	and DownCategory in ('LC7','LC16')
	group by dDate,DownCategory)
	as t1 inner join #OEE_losses on #OEE_losses.ColumnHeader = t1.dDate and
	#OEE_losses.RowHeader = 'QualityLoss' and #OEE_losses.YearMonthDay = 'Day' 
	--from here
	and #OEE_losses.RowHeader in ('LC7','LC16')
	--till here
	Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from
	(Select datepart(mm,dDate) as mnth,DownCategory,sum(downtime) as DownTime from shiftdowntimedetails
	where MachineID = @MachineID and ML_Flag = 0 and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate)
	and DownCategory in ('LC7','LC16')
	group by datepart(mm,dDate),DownCategory)
	as t1 inner join #OEE_losses on Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and
	#OEE_losses.RowHeader = t1.DownCategory and #OEE_losses.YearMonthDay = 'Month'
	--from here
	and #OEE_losses.RowHeader in ('LC7','LC16')
	--till here

	Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from
	(Select DownCategory,sum(downtime) as DownTime from shiftdowntimedetails
	where MachineID = @MachineID and ML_Flag = 0
	and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate) and DownCategory in ('LC7','LC16') 
	group by DownCategory)
	as t1 inner join #OEE_losses on #OEE_losses.RowHeader = t1.DownCategory and #OEE_losses.YearMonthDay = 'Year'
	--from here
	and #OEE_losses.RowHeader in ('LC7','LC16')
	--till here

	--DownTime by Category - Till Here====================================================================================
End
else if @DownID_Category = 'DownID'
Begin
	--DownTime by Category - From Here ====================================================================================
	Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from
	(Select dDate,DownID,sum(downtime) as DownTime from shiftdowntimedetails where MachineID = @MachineID and ML_Flag = 0 and datepart(mm,dDate) = datepart(mm,@InPutDate) and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate) and DownCategory in ('LC7','LC16') group by dDate,DownID)
	as t1 inner join #OEE_losses on #OEE_losses.ColumnHeader = t1.dDate and
	#OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Day'
	--from here
	and #OEE_losses.RowHeader in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory in ('LC7','LC16'))
	--till here

	Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from
	(Select datepart(mm,dDate) as mnth,DownID,sum(downtime) as DownTime from shiftdowntimedetails where MachineID = @MachineID and ML_Flag = 0 and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate) and DownCategory in ('LC7','LC16') group by datepart(mm,dDate),DownID)
	as t1 inner join #OEE_losses on Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and
	#OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Month'
	--from here
	and #OEE_losses.RowHeader in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory in ('LC7','LC16'))
	--till here

	Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from
	(Select DownID,sum(downtime) as DownTime from shiftdowntimedetails where MachineID = @MachineID and ML_Flag = 0 and datepart(yyyy,dDate) = datepart(yyyy,@InPutDate) and DownCategory in ('LC7','LC16') group by DownID)
	as t1 inner join #OEE_losses on #OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Year'
	--from here
	and #OEE_losses.RowHeader in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory in ('LC7','LC16'))
	--till here
	--DownTime by Category - Till Here ====================================================================================
End

--QualityLoss - till Here============================================================================
if @DownID_Category = 'DownCategory'
Begin
	update #OEE_losses set RowHeader = t1.Description from 
	(select DownCategory,isnull(Description,DownCategory) as Description from downcategoryinformation) as t1 
	inner join #OEE_losses on t1.DownCategory = #OEE_losses.RowHeader
End

Select YearMonthDay,ColumnHeader,RowHeader,IsNull(RowValue,0) as RowValue from #OEE_losses
order by YearMonthDay,ColumnHeader,idd,RowHeader
END
