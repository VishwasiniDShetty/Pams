/****** Object:  Procedure [dbo].[s_GetShiftwiseProductionReport_Format6]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************************************************************************************************************
--NR0066- By SwathiKS on 12/May/2010 :: New Excel report for listing First and last production record of shift, by machine and date.
--s_GetShiftwiseProductionReport_Format6 '2009-12-01','2009-12-02','','LT 20-1',''
**************************************************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetShiftwiseProductionReport_Format6]
	@StartDate As DateTime,
	@EndDate As DateTime,
	@ShiftID as nvarchar(5)='',
	@MachineID As nvarchar(50) = '',
	@PlantID As NVarChar(50)=''

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


select  @StartDate = convert(nvarchar(4),datepart(yyyy,@StartDate))+ '-' + convert(nvarchar(2),datepart(mm,@StartDate))+'-'+ convert(nvarchar(2),datepart(dd,@StartDate))
select @EndDate  = convert(nvarchar(4),datepart(yyyy,@EndDate))+ '-' + convert(nvarchar(2),datepart(mm,@EndDate))+'-'+ convert(nvarchar(2),datepart(dd,@EndDate))


Declare @Strsql nvarchar(4000)

Declare @Strmachine nvarchar(255)
Declare @StrPlantID AS NVarchar(255)
Declare @StrShift as nvarchar(255)

Select @Strsql = ''
Select @Strmachine = ''
Select @StrPlantID = ''
Select @StrShift = ''

If isnull(@PlantID,'') <> ''
Begin
	Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
End
If isnull(@Machineid,'') <> ''
Begin
	Select @Strmachine = ' And ( MachineInformation.MachineID = N''' + @MachineID + ''')'
End
	

If isnull( @ShiftID ,'') <> ''
Begin
	Select @StrShift  = ' And ( ShiftDetails.ShiftName = N''' + @ShiftID + ''')'
End
	
Create Table #ShiftDetails
(
	Pdate DateTime,
       	ShiftName  NVarChar(20),
	--Shiftid smallint,
	ShiftStartTime  DateTime,
	ShiftEndTime DateTime,
	
)	
	
CREATE TABLE #MachineRecords
(
	Machineinterface nvarchar(50)
	--Record smallint
)
	

while(@startdate<=@enddate)
BEGIN
	INSERT #ShiftDetails(Pdate,ShiftName,ShiftStarttime,ShiftEndTime)
	EXEC s_GetShiftTime @StartDate,@ShiftID
	set @startdate = dateadd(d,1,@startdate)
END


Select @Strsql = 'insert into #MachineRecords '
Select @Strsql = @Strsql + 'select machineinformation.interfaceid from machineinformation inner join plantmachine on machineinformation.machineid=plantmachine.machineid '
Select @Strsql = @Strsql + 'where 1=1 ' + @Strmachine +@StrPlantID
print @Strsql
exec (@Strsql)


select 
t1.pdate as [Date],machineinformation.machineid as Machine,
t1.shiftname as ShiftName,
t1.Shiftstarttime,t1.Shiftendtime,
case when autodata.sttime=T1.FirstRecord then 'First'
     when autodata.sttime=t1.LastRecord then 'Last'
end as Record,
autodata.mc AS MachineID,machineinformation.machineid as MachineName,
autodata.comp AS ComponentID,componentinformation.componentid as ComponentName,
autodata.opn AS OperationID,componentoperationpricing.operationno as OperationNo,autodata.opr AS OperatorID,
employeeinformation.employeeid as OperatorName,autodata.stdate AS StartDate,
autodata.sttime AS StartTime,autodata.nddate AS EndDate,
autodata.ndtime AS EndTime,autodata.cycletime AS ActCycleTime,
autodata.loadunload As ActLoadUnloadTime,autodata.Remarks,
componentoperationpricing.machiningtime as IdealMachiningTime, 
componentoperationpricing.cycletime as IdealCycleTime,
(componentoperationpricing.cycletime - componentoperationpricing.machiningtime) as IdealLoadunload 
from (
	select pdate,shiftname,shiftstarttime,shiftendtime,Machineinterface,min(autodata.sttime)as FirstRecord,max(autodata.sttime)as LastRecord from #ShiftDetails 
	cross join  #MachineRecords
	inner join autodata on autodata.mc=#MachineRecords.Machineinterface 
	where autodata.datatype=1 and (autodata.sttime)>#ShiftDetails.shiftstarttime and (autodata.ndtime)<#ShiftDetails.shiftendtime
	group by pdate,machineinterface,shiftname,shiftstarttime,shiftendtime
)as t1 
inner join autodata on autodata.mc=t1.machineinterface and (autodata.sttime=t1.FirstRecord or autodata.sttime=t1.LastRecord)
inner join machineinformation ON t1.machineinterface = machineinformation.InterfaceID and autodata.mc=machineinformation.InterfaceID
inner join componentinformation on autodata.comp=componentinformation.InterfaceID
inner join componentoperationpricing on autodata.opn=componentoperationpricing.InterfaceID and componentoperationpricing.componentid=componentinformation.componentid and componentoperationpricing.MachineID = machineinformation.MachineID
left outer join employeeinformation on autodata.opr= employeeinformation.InterfaceID
order by pdate,machineinterface,shiftname,stdate,nddate,sttime,ndtime


/*
select * from(
select pdate,shiftname,shiftstarttime,shiftendtime,machineinterface,min(autodata.sttime)as FirstRecord,max(autodata.sttime)as LastRecord from #ShiftDetails 
cross join  #MachineRecords
inner join autodata on autodata.mc=#MachineRecords.Machineinterface 
where autodata.datatype=1 and (autodata.sttime)>#ShiftDetails.shiftstarttime and (autodata.ndtime)<#ShiftDetails.shiftendtime
group by pdate,shiftname,shiftstarttime,shiftendtime,machineinterface
)as t1 inner join autodata on autodata.mc=t1.machineinterface and autodata.sttime=t1.FirstRecord or autodata.sttime=t1.LastRecord
order by pdate,machineinterface
--having min(autodata.sttime)>#ShiftDetails.shiftstarttime and max(autodata.ndtime)<#ShiftDetails.shiftendtime
*/



end
