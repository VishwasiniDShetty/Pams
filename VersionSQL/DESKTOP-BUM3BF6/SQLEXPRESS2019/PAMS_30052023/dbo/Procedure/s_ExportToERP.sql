/****** Object:  Procedure [dbo].[s_ExportToERP]    Committed by VersionSQL https://www.versionsql.com ******/

/*------------Procedure Created By Karthik G on 05/Jul/2009 for Exporting agg data to ERP.
ER0184(5) - Karthikg - 05/Jun/2009 
--Selection and sequence of Columns to be exported are read from Shopdefaults table.
--Karthikg - 26/Jun/2009 - Altered the procedure to show RejectionCount.
mod 1:- By Mrudula M. Rao on 06-Jul-2009 for DR0191.Change the date and time format in Export to ERP. 
	Make use of following  format dd.mm.yyyy hh:mm:ss.
DR0203 - Karthik G - 14/Aug/2009 -- Log if Export Feature Expired.
-----------------------------------------------------------------------------------------*/
--s_ExportToERP 'Proddata'

CREATE       PROCEDURE [dbo].[s_ExportToERP]
	@param as nvarchar(50) = ''--Proddata,DownData
AS
BEGIN

Declare @sqlstr as nvarchar(4000)

--mod 1
Declare @i as int
Declare @DayOrShift as nvarchar(10)
Declare @DayOrShift_Value as int
Declare @CurrTime as DateTime
Declare @ExpireTime as DateTime --DR0203 - Karthik G - 14/Aug/2009
set @ExpireTime = '2009-Aug-30'

CREATE TABLE #DateShift
(
	sDate DateTime,
	ShiftID NVarChar(50),
	StartTime DateTime,
	EndTime DateTime
)
if @ExpireTime < GetDate() 
Begin
	select 'ExportToERP feature expired.' as Data
	return
End

if (Select Valueintext FROM ShopDefaults WHERE Parameter = 'ExportToERP_period') = 'Day'
Begin
	set @DayOrShift = 'Day'
	set @DayOrShift_Value = (Select ValueinInt FROM ShopDefaults WHERE Parameter = 'ExportToERP_period')
End

if (Select Valueintext FROM ShopDefaults WHERE Parameter = 'ExportToERP_period') = 'Shift'
Begin
	set @DayOrShift = 'Shift'
	set @DayOrShift_Value = (Select ValueinInt FROM ShopDefaults WHERE Parameter = 'ExportToERP_period')
	--Select @DayOrShift
	--Select @DayOrShift_Value
	set @CurrTime = getdate()
	--select @CurrTime
	Insert into #DateShift exec S_getshifttimesa @CurrTime
	Delete #DateShift where Endtime > @CurrTime

	while @DayOrShift_Value > (Select count(*) from #DateShift)
	begin
		set @CurrTime = dateadd(d,-1,@CurrTime)
		Insert into #DateShift exec S_getshifttimesa @CurrTime
	End

	Update #DateShift set sdate = cast(cast(datepart(yyyy,sdate)as nvarchar(4))+'-'+cast(datepart(mm,sdate)as nvarchar(4))+'-'+cast(datepart(dd,sdate)as nvarchar(4)) as datetime)
	Set @sqlstr = 'Select top ' + cast(@DayOrShift_Value as nvarchar(4)) + '* from #DateShift order by EndTime desc'
	--exec(@sqlstr)
End


if @param = 'Proddata'
Begin
	set @sqlstr = 'Select '
	set @i = 1
	While @i <50
	Begin
		if exists(Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i)
		Begin
			--set @sqlstr = @sqlstr + ' IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i),'') + ',0) as ' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i),'') + ','
			---mod 1
			---set @sqlstr = @sqlstr + ' Cast(IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i),'') + ',0)as nvarchar(100))+ char(9) +' 
			--Check if column is a date if not do not convert
			if Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i and ValueInText not in ('pdate','updatedts')),'')<> ''
			begin
				set @sqlstr = @sqlstr + ' Cast(IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i),'') + ',0)as nvarchar(100))+ char(9) +' 
			end 
			
			
			--If column is date then convert into dd.mm.yyyy hh:mm:ss format
			if Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i and ValueInText  in ('pdate','updatedts')),'')<> ''
			begin
				set @sqlstr = @sqlstr + ' case when isdate(IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i),'') + ',0))=1 then 
						convert(nvarchar(20),IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i),'') + ',0),104)+ '' ''+ convert(nvarchar(20),IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i),'') + ',0),108) else
						Cast(IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_pData' and ValueInInt = @i),'') + ',0)as nvarchar(50)) end + char(9) +' 
			end
			--mod 1
		end
		set @i = @i + 1
	End

	set @sqlstr = left(@sqlstr,len(@sqlstr)-1)
	set @sqlstr = @sqlstr + 'AS Data from shiftproductiondetails spd '

	if @DayOrShift = 'Shift' 
		Begin
			set @sqlstr = @sqlstr + ' inner join (Select top ' + cast(@DayOrShift_Value as nvarchar(4)) + ' ShiftID,sdate from #DateShift order by EndTime desc) ds on spd.Shift=ds.ShiftID and spd.pDate=ds.sDate '
			--DR0203 - Karthik G - 14/Aug/2009
			--set @sqlstr = @sqlstr + ' and pdate < ''2009-Aug-10'''
			set @sqlstr = @sqlstr + ' and pdate < ''' + cast(@ExpireTime as nvarchar(20)) + ''''
			--DR0203 - Karthik G - 14/Aug/2009
			set @sqlstr = @sqlstr + ' left outer join (Select ID as rID,sum(Rejection_Qty) as RejectionCount from shiftrejectiondetails group by ID) srd on spd.ID=srd.rID'
		End
	else
		Begin
			set @sqlstr = @sqlstr + ' left outer join (Select ID as rID,sum(Rejection_Qty) as RejectionCount from shiftrejectiondetails group by ID) srd on spd.ID=srd.rID'
			set @sqlstr = @sqlstr + ' where pdate > Getdate()-1-'+ cast(@DayOrShift_Value as nvarchar(4)) + ' and pdate < Getdate()-1 '
			--DR0203 - Karthik G - 14/Aug/2009
			--set @sqlstr = @sqlstr + ' and pdate < ''2009-Aug-10'''
			set @sqlstr = @sqlstr + ' and pdate < ''' + cast(@ExpireTime as nvarchar(20)) + ''''
			--DR0203 - Karthik G - 14/Aug/2009
		End
	--set @sqlstr = @sqlstr + ' order by pdate,Shift,MachineID,WorkOrderNumber'

	Print @sqlstr
	exec(@sqlstr)
End

if @param = 'DownData'
Begin
	set @sqlstr = 'Select '
	set @i = 1
	While @i <50
	Begin
		if exists(Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i)
		Begin
			--set @sqlstr = @sqlstr + ' IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i),'') + ',0) as ' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i),'') + ','
			--mod 1
			----set @sqlstr = @sqlstr + ' Cast(IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i),'') + ',0)as nvarchar(100))+ char(9) +' 
			--Check if column is a date if not do not convert
			if Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i and ValueInText not in ('ddate','updatedts','Starttime','endtime')),'')<> ''
			begin
				set @sqlstr = @sqlstr + ' Cast(IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i),'') + ',0)as nvarchar(100))+ char(9) +' 
			end 
			
			--If column is date then convert into dd.mm.yyyy hh:mm:ss format
			if Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i and ValueInText  in ('ddate','updatedts','Starttime','endtime')),'')<> ''
			begin
				set @sqlstr = @sqlstr + ' case when isdate(IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i),'') + ',0))=1 then 
						convert(nvarchar(20),IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i),'') + ',0),104)+ '' ''+ convert(nvarchar(20),IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i),'') + ',0),108) else
						Cast(IsNull(' + Isnull((Select ValueInText FROM ShopDefaults WHERE Parameter = 'ExportToERP_dData' and ValueInInt = @i),'') + ',0)as nvarchar(50)) end + char(9) +' 
			end
			--mod 1
		end
		set @i = @i + 1
	End

	set @sqlstr = left(@sqlstr,len(@sqlstr)-1)
	set @sqlstr = @sqlstr + 'AS Data from shiftdowntimedetails sdd '

	if @DayOrShift = 'Shift' 
		Begin
			set @sqlstr = @sqlstr + ' inner join (Select top ' + cast(@DayOrShift_Value as nvarchar(4)) + ' ShiftID,sdate from #DateShift order by EndTime desc) ds on sdd.Shift=ds.ShiftID and sdd.dDate=ds.sDate 
						 and sdd.ddate < ''' + cast(@ExpireTime as nvarchar(20)) + ''' '
		End
	else
		Begin
			set @sqlstr = @sqlstr + ' where ddate > Getdate()-1-'+ cast(@DayOrShift_Value as nvarchar(4)) + ' and ddate < Getdate()-1 and sdd.ddate < ''' + cast(@ExpireTime as nvarchar(20)) + ''''
		End
	set @sqlstr = @sqlstr + ' order by ddate,Shift,MachineID,WorkOrderNumber'

	Print @sqlstr
	exec(@sqlstr)
End



END


--
