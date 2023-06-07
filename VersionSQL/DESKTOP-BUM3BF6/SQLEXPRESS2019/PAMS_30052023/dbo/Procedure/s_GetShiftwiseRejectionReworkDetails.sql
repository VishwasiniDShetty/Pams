/****** Object:  Procedure [dbo].[s_GetShiftwiseRejectionReworkDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/******************************************************************************
---Shanthi Requirement.
ER0417-Vasavi-Created New Procedure to get total rejected,accepted and Marked for rework count.
DR0370 - SwathiKS - 23/Dec/2015 :: When a record started in First Shift ended in Second Shift then we were showing that record 
in First shift with Status 'Waiting For Operator Validation and in Second Shift as 'Accepted'. 
To handle above scenario now instead of all Recordtypes we were using Record Type1 and 2
while picking records from Autodata. 
ER0425-Vasavi-28/Jan/2016 ::To handle Status of records which falls across shift boundary and negative rework count.
********************************************************************************/
--exec [dbo].[s_GetShiftwiseRejectionReworkDetails]'2016-01-27','2016-01-29','','','vmc-07',''
--select * from autodata order by sttime desc
CREATE PROCEDURE [dbo].[s_GetShiftwiseRejectionReworkDetails]
	@StartDate datetime='',
	@EndDate datetime='',
	@ShiftIn nvarchar(20) = '',
	@GroupID As nvarchar(50) = '',
	@PlantID Nvarchar(50) ='',
	@MachineID nvarchar(50) = '',
	@Param nvarchar(20)='' 
AS
BEGIN
	
	SET NOCOUNT ON;

  CREATE TABLE #T_autodata
  (
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] NULL,
	[datatype] [tinyint] NULL ,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] NULL,
	[PartsCount] decimal(18,5) NULL ,
	[WorkOrderNumber] nvarchar(100),
	id  bigint not null
)


CREATE TABLE #ShiftProductionFromAutodata (
	PDate datetime,
	[Shift] nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime
)

create table #Machcomopnopr
		(
		id int identity ,
		sttime datetime,
		Shdate datetime not null,
		ShftName nvarchar(50),
		Machine nvarchar(50) NOT NULL,
		Machineint nvarchar(50),
		GroupId nvarchar(50),
		Component nvarchar(50) NOT NULL,
		CompInt nvarchar(50),
		Operation nvarchar(50) NOT NULL,
		opnInt nvarchar(50),
		OperatorID int,
		Operator nvarchar(50),
		WorkOrderNumber nvarchar(100),
		partscount decimal(18,5) NULL ,
		ShiftID int,
		ShftStrt datetime not null,
		ShftND datetime not null,
		[Status] nvarchar(50),
		TotalQuantity int,
		TotalAccept int default 0,
		TotalRejection int default 0,
		TotalRework int,
		ShiftQuantity decimal(18,5) NULL,--er0425 changed from int
		ShiftAccept int default 0,
		ShiftRejection int default 0,
		ShiftRework int,
		RecordCount int
	)

	Create table #Machcomopnoprtemp
	(
	id int,
	Machine nvarchar(50) NOT NULL,
	Machineint nvarchar(50),
	Component nvarchar(50) NOT NULL,
	CompInt nvarchar(50),
	Operation nvarchar(50) NOT NULL,
	opnInt nvarchar(50),
	WorkOrderNumber nvarchar(100),
	RecordCount int
	)

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 
declare @StartTime as Datetime
declare @EndTime as Datetime
declare @CurStrtTime as Datetime
declare @CurEndTime as Datetime
Declare @StrGroupID AS NVarchar(255)

select @StrGroupID=''
select @CurStrtTime=@StartDate
select @CurEndTime=@EndDate

If isnull(@GroupID ,'') <> ''
Begin
Select @StrGroupID = ' And ( PlantMachineGroups.GroupID = N''' + @GroupID + ''')'
End


while @CurStrtTime<=@EndDate
BEGIN
	INSERT #ShiftProductionFromAutodata(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @CurStrtTime,@ShiftIn
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
END

Select @T_ST=min(ShiftStart) from #ShiftProductionFromAutodata 
Select @T_ED=max(ShiftEnd) from #ShiftProductionFromAutodata 

insert into #T_autodata
SELECT mc, comp, opn, opr, dcode,sttime,ndtime, datatype, cycletime, loadunload, msttime,  partscount,[WorkOrderNumber],id
from autodata where DataType=1 and(( sttime >= convert(nvarchar(25),@T_ST,120) and ndtime <=  convert(nvarchar(25),@T_ED,120)) OR 
(sttime <convert(nvarchar(25),@T_ST,120)and ndtime >convert(nvarchar(25),@T_ED,120))OR 
(sttime <convert(nvarchar(25),@T_ST,120) and ndtime >convert(nvarchar(25),@T_ST,120)
and ndtime<=convert(nvarchar(25),@T_ED,120))OR ( sttime >=convert(nvarchar(25),@T_ST,120) 
and ndtime >convert(nvarchar(25),@T_ED,120) and sttime<convert(nvarchar(25),@T_ED,120)))

insert into #Machcomopnopr(Machine,GroupId,MachineInt,Component,CompInt,Operation,OpnInt,Operator,OperatorID,WorkOrderNumber,Shdate,ShftName,ShftStrt,ShftND,partscount,sttime) 
SELECT distinct  Machineinformation.Machineid,PlantMachineGroups.GroupID,Machineinformation.interfaceid,
componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,
componentoperationpricing.interfaceid,Employeeinformation.Employeeid,employeeinformation.interfaceid,autodata.WorkOrderNumber, Pdate, [Shift], ShiftStart, ShiftEnd,Partscount,autodata.sttime
from #T_autodata autodata 
inner join machineinformation on machineinformation.interfaceid=autodata.mc 
inner join componentinformation ON autodata.comp = componentinformation.InterfaceID  
INNER JOIN componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid) 
and componentoperationpricing.machineid=machineinformation.machineid 
inner join employeeinformation on autodata.opr=employeeinformation.interfaceid
Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
LEFT JOIN PlantMachineGroups on machineinformation.machineid = PlantMachineGroups.machineid AND (PlantMachineGroups.GroupID=@GroupID OR ISNULL(@GroupID,'')='')
cross join #ShiftProductionFromAutodata where 
--DR0370 Commented From Here
--(( sttime >= shiftstart and ndtime <= shiftend ) OR 
--( sttime < shiftstart and ndtime > shiftend )OR 
--( sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend )
--OR ( sttime >= shiftstart and ndtime > shiftend and sttime<shiftend ) ) 
--DR0370 Commented Till Here
( ndtime > shiftstart and ndtime <= shiftend) --DR0370 Added
and machineinformation.interfaceid>0 
and (machineinformation.machineID=@MachineID or @MachineID='')  



update #Machcomopnopr SET ShiftID=T.ShiftID from 
(select distinct S.ShiftID,ShiftName from shiftdetails S inner join #Machcomopnopr AR on S.ShiftName=AR.ShftName)T 
inner join #Machcomopnopr on T.ShiftName=#Machcomopnopr.ShftName


update #Machcomopnopr set RecordCount=T.RecordCount from
(select Machine,Component,Operation,WorkorderNumber,
count(*) as RecordCount from #Machcomopnopr group by  Machine,Component,Operation,WorkorderNumber)T inner join 
#Machcomopnopr MCO on MCO.Machine=T.Machine and MCO.Component=T.Component and MCO.Operation=T.Operation and MCO.WorkOrderNumber=T.WorkorderNumber

--select  Machine,Component,Operation,T.WorkorderNumber,count(*) as RecordCount from(
--select t.WorkOrderNumber
--from #Machcomopnopr t join
--     #Machcomopnopr tnext
--     on t.id = tnext.id + 1 and t.WorkOrderNumber=tnext.WorkOrderNumber and t.ShftStrt<>tnext.Shftnd ) T inner join  #Machcomopnopr
--	on   t.WorkOrderNumber=#Machcomopnopr.WorkOrderNumber
--group by  Machine,Component,Operation,T.WorkorderNumber

update #Machcomopnopr set Status= Case(T.[Status]) When 1 then 'Accepted' END from
(select  Machine,Component,Operation,WorkorderNumber,QD.[Status] as [Status] from #Machcomopnopr MC inner join QualityInspectDetails QD on 
MC.MachineInt=QD.MachineId and MC.CompInt=QD.ComponentID and MC.OpnInt=QD.OperationNO and MC.WorkOrderNumber=QD.WorkOrderNo 
and QD.CreatedTS>=@T_ST and QD.CreatedTS<=@T_ED and RecordCount=1)T inner join #Machcomopnopr MCO 
on MCO.Machine=T.Machine and MCO.Component=T.Component and MCO.Operation=T.Operation and MCO.WorkOrderNumber=T.WorkorderNumber  and MCO.RecordCount=1

update #Machcomopnopr set Status='Rejected'
 from
(select Machine,Component,Operation,MC.WorkorderNumber,Shdate ,ShftName from #Machcomopnopr MC inner join AutodataRejections QD on 
MC.MachineInt=QD.mc and MC.CompInt=QD.comp and MC.OpnInt=QD.opn and MC.WorkOrderNumber=QD.WorkOrderNumber
where QD.Flag='Rejection' and QD.CreatedTS>=@T_ST and QD.CreatedTS<=@T_ED and RecordCount=1)T inner join #Machcomopnopr MCO 
on MCO.Machine=T.Machine and MCO.Component=T.Component and MCO.Operation=T.Operation and MCO.WorkOrderNumber=T.WorkorderNumber
and MCO.Shdate=T.Shdate and MCO.ShftName=T.ShftName  and MCO.RecordCount=1


insert into #Machcomopnoprtemp(ID,Machine,MachineInt,Component,CompInt,Operation,OpnInt,WorkOrderNumber)
select max(id),Machine,Machineint,Component,CompInt,Operation,OpnInt,WorkOrderNumber from #Machcomopnopr where RecordCount>1
group by Machine,MachineInt,Component,CompInt,Operation,OpnInt,WorkOrderNumber



update #Machcomopnopr set [Status]= Case(T.[Status]) When 1 then 'Accepted'
 When 2 then 'Rejected' Else Null END from
(select ID, Machine,Component,Operation,WorkorderNumber,QD.[Status] as [Status] from #Machcomopnoprtemp MC inner join QualityInspectDetails QD on 
MC.MachineInt=QD.MachineId and MC.CompInt=QD.ComponentID and MC.OpnInt=QD.OperationNO and MC.WorkOrderNumber=QD.WorkOrderNo and QD.[Status] in(1,2)
and QD.CreatedTS>=@T_ST and QD.CreatedTS<=@T_ED)T inner join #Machcomopnopr MCO 
on MCO.Machine=T.Machine and MCO.Component=T.Component and MCO.Operation=T.Operation and MCO.WorkOrderNumber=T.WorkorderNumber  and MCO.RecordCount>1 and MCO.id=T.id


update #Machcomopnopr set [Status]='Marked For Rework' from 
 (select MC.id,Machine,Component,Operation,MC.WorkorderNumber,Shdate ,ShftName from #Machcomopnopr MC inner join AutodataRejections QD on 
MC.MachineInt=QD.mc and MC.CompInt=QD.comp and MC.OpnInt=QD.opn and MC.WorkOrderNumber=QD.WorkOrderNumber
where QD.Flag='MarkedforRework' and QD.CreatedTS>=@T_ST and QD.CreatedTS<=@T_ED and [Status] is null)T inner join #Machcomopnopr MCO on MCO.id=T.id and 
MCO.Machine=T.Machine and MCO.Component=T.Component and MCO.Operation=T.Operation and MCO.WorkOrderNumber=T.WorkorderNumber
and MCO.Shdate=T.Shdate and MCO.ShftName=T.ShftName




update #Machcomopnopr set [Status]='Waiting For Operator Validation' from 
(select 
T.ID,T.Machine,T.Component,T.Operation,T.WorkorderNumber from #Machcomopnoprtemp MCO
inner join #Machcomopnopr T on MCO.Machine=T.Machine and MCO.Component=T.Component and MCO.Operation=T.Operation and MCO.WorkOrderNumber=T.WorkorderNumber
and T.id=MCO.id where T.status Not in('Accepted','Rejected','Marked For Rework'))T inner join #Machcomopnopr on T.id=#Machcomopnopr.id --ER0425 included MarkedForRework



update #Machcomopnopr set [Status]='Waiting For Operator Validation' from 
(select id from #Machcomopnopr where Status is null )T inner join #Machcomopnopr on T.id=#Machcomopnopr.id

--ER0425-Commented From here
--update #Machcomopnopr set TotalQuantity= T.Total from
--(select count(Status) as Total,Machine,Shdate from #Machcomopnopr group by Machine,Shdate)T inner join 
--#Machcomopnopr on T.Machine=#Machcomopnopr.Machine and T.Shdate=#Machcomopnopr.Shdate

--ER0425-Added From here
update #Machcomopnopr set TotalQuantity= T.Total from
(select Sum(PartsCount) as Total,Machine,Shdate from #Machcomopnopr group by Machine,Shdate)T inner join 
#Machcomopnopr on T.Machine=#Machcomopnopr.Machine and T.Shdate=#Machcomopnopr.Shdate
--ER0425-Added till here 

update #Machcomopnopr set TotalAccept= isnull(T.Total,0) from
(select isnull(count(Status),0) as Total,Machine,Shdate from #Machcomopnopr where Status='Accepted'
group by Machine,Shdate)T inner join 
#Machcomopnopr on T.Machine=#Machcomopnopr.Machine and T.Shdate=#Machcomopnopr.Shdate

update #Machcomopnopr set TotalRejection= isnull(T.Total,0) from
(select isnull(count(Status),0)  as Total,Machine,Shdate from #Machcomopnopr where Status='Rejected' group by Machine,Shdate)T inner join 
#Machcomopnopr on T.Machine=#Machcomopnopr.Machine and T.Shdate=#Machcomopnopr.Shdate

update #Machcomopnopr set TotalRework= isnull(T.Total,0) from
(select Sum(Partscount)-TotalAccept-TotalRejection as Total,Machine,Shdate from #Machcomopnopr group by TotalAccept,TotalRejection,Machine,Shdate )T
inner join #Machcomopnopr on T.Machine=#Machcomopnopr.Machine and T.Shdate=#Machcomopnopr.Shdate




--ER0425-Commented From here
--update #Machcomopnopr set ShiftQuantity= T.Total from
--(select count(Status) as Total,Machine,Shdate,ShftName from #Machcomopnopr group by Machine,Shdate,ShftName)T inner join 
--#Machcomopnopr on T.Machine=#Machcomopnopr.Machine and T.Shdate=#Machcomopnopr.Shdate and T.ShftName=#Machcomopnopr.ShftName


--ER0425-Added From here
update #Machcomopnopr set ShiftQuantity= T.Total from
(select Round(Sum(Partscount),0) as Total,Machine,Shdate,ShftName from #Machcomopnopr group by Machine,Shdate,ShftName)T inner join 
#Machcomopnopr on T.Machine=#Machcomopnopr.Machine and T.Shdate=#Machcomopnopr.Shdate and T.ShftName=#Machcomopnopr.ShftName
--ER0425-Added till here  
update #Machcomopnopr set ShiftAccept= isnull(T.Total,0) from
(select isnull(count(Status),0) as Total,Machine,Shdate,ShftName  from #Machcomopnopr where Status='Accepted'
group by Machine,Shdate,ShftName)T inner join 
#Machcomopnopr on T.Machine=#Machcomopnopr.Machine  and T.Shdate=#Machcomopnopr.Shdate and T.ShftName=#Machcomopnopr.ShftName

update #Machcomopnopr set ShiftRejection= isnull(T.Total,0) from
(select isnull(count(Status),0)  as Total,Machine,Shdate,ShftName from #Machcomopnopr where Status='Rejected' group by Machine,Shdate,ShftName)T inner join 
#Machcomopnopr on T.Machine=#Machcomopnopr.Machine  and T.Shdate=#Machcomopnopr.Shdate and T.ShftName=#Machcomopnopr.ShftName


update #Machcomopnopr set ShiftRework= isnull(T.Total,0) from
(select Round(Sum(Partscount),0)-ShiftAccept-ShiftRejection as Total,Machine,Shdate,ShftName from #Machcomopnopr group by ShiftAccept,ShiftRejection,Machine,Shdate,ShftName)T--ER0425 Added Round
inner join #Machcomopnopr on T.Machine=#Machcomopnopr.Machine  and T.Shdate=#Machcomopnopr.Shdate and T.ShftName=#Machcomopnopr.ShftName

--ER0425-Added From here
update #Machcomopnopr set  Status=T.Status
from(select t.Status,t.WorkOrderNumber
from #Machcomopnopr t join
     #Machcomopnopr tnext
     on t.id = tnext.id + 1 and t.WorkOrderNumber=tnext.WorkOrderNumber and t.ShftStrt=tnext.Shftnd ) T inner join  #Machcomopnopr
	on   t.WorkOrderNumber=#Machcomopnopr.WorkOrderNumber ;
--ER0425-Added till here  


select * from #Machcomopnopr 
order by  Shdate,Machine,Shiftid,sttime
    

END
