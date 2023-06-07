/****** Object:  Procedure [dbo].[s_Push_Prodn_Down_ShiftAggregation]    Committed by VersionSQL https://www.versionsql.com ******/

/* 

exec [dbo].[s_Push_Prodn_Down_ShiftAggregation] '2022-07-19 10:00:00.000','','','','PUSH','','',''


*
* Procedure Created By SSK on 06/Nov/2006 :: For Shift Aggregation Process
* -------------------------------------------------------------------------------------------
*
* Procedure Changed By SSK on 08/Nov/2006 :: to add @Type parameter
* Procedure used in SmartManager - FrmMARKS.frm
* ------------------------------------------------------------------------------------------
*
* Procedure Changed By SSK on 22/Nov/2006 ::
* New Column 'PartsCount' as added into AutoData Which gives part Count.
* ie if cycle is of pallet type,it will give pallet count else count.
* ------------------------------------------------------------------------------------------
*
* Procedure changed by SSK on 23/Nov/2006 :
* Bz of change in column names of 'ShiftProductionDetails','ShiftDownTimeDetails' tables.
* Procedure Chnaged By SSK on 10-Jan-2007 :To Populate 'Acceptedparts' column.
* ------------------------------------------------------------------------------------------
*
* 
* Procedure Changed By Sangeeta Kallur on 01/Mar/2007 :
* For Considering MultiSpindle Macnes - Which affects Production Count   *
mod 1:- By Mrudula for DR0142 on 02-oct-2008.
a) To select the records which are greater than the last aggregated record
b) To insert last aggregated record in ShiftAggTrail table.
c) To Merge down aggregation with production aggregation  procedure
mod 2:- For ER0151 by Mrudula on 13-oct-2008. To process all the machines at once
mod 3:- for ER0151 by Mrudula 0m 31-oct-2008. To process all the machines for multiple days and shift,
mod 4:- for DR0148 by Mrudula on 27-Nov-2008.
   1) Update the last aggregated record'd endtime to 01-01-2000 12:00:00 am if shift start time  is greater than or equal to last aggregated record's endtime.
This is in order not to miss the records which are running across more than 2 shifts.
   2) PUT TRANSACTION
3)pUT ERROR HANDLE
mod 5 :- ER0181 By Kusuma M.H on 19-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 6 :- ER0182 By Kusuma M.H on 19-May-2009.Modify all the procedures to support unicode characters. Qualify with leading N.
mod 7 :- ER0184 By Kusuma M.H on 04-Jun-2009. 3)Process WorkOrderNumber while aggregation.
mod 8 :- DR0188 By Kusuma M.H on 19-Jun-2009. To make sure the aggregation procedure populates the column in float if the standard values from CO table are in float.
mod 9:- DR0213 by Mrudula M. Rao on 13-Oct-2009.Consider records with partscoint>0 while calculating average values to avoid divide by zero errors
mod 10:- For DR0221 by Mrudula M. Rao on 13-oct-2009.Change the datatype of the column in which we store opeartionno  to nvarchar if it is integer
mod 11:-For ER0210 by Mrudula M. Rao on 29-dec-2009.Introduce PDT on 5150.
1) Handle PDT at Machine Level
2) Handel interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.
3) Improve the performance.
4) Handle intearction between ICD and PDT for type 1 production record for the selected time period.
5) Qualify MCO while getting exception count.
mod 12:-DR0229 by Mrudula M. Rao on 12-jan-2009 . "Error in Aggregattion when multiple machines selected.
Machines selected will be in a string . While applying filter on machines should use in instaed of equal to"
mod 13: For DR0236 altered by karthick R on 23-06-2010  Use proper conditions in case statements to remove icd's from type 4 production records.
DR0265 - KarthickR - 15/Dec/2010 :: To Disable Warnings.
DR0272 - SwathiKS - 05/Mar/2011 :: To Add RecordType 3 and 4 While inserting into #TempShiftProductionDetails
          To Calculate AcceptedParts and Prod_qty For RecordType 1 and 2.
DR0302 - KarthikR - 19/dec/2011 :: To Increase Length of Strings.
DR0309 - SwathiKS/KarthikR - 16/Aug/2012 :: To include Shift validation while calculating Dowtime with PDT to handle Efficiency Mismatch.
ER0332 - SwathiKS/GeetanjaliK - 07/Nov/2012 :: To Aggregate Rejections from Autodatarejections table into Shiftrejectiondetails table.
--To include CriticalMachineEnabled and MachinewiseOwner columns into shiftproductiondetails.
--To include CriticalMachineEnabled column into shiftdowntimedetails.
DR0322-SwathiKS-06/Feb/2013::To handle Downtime Mismatch with Cockpit(with PDT)during Aggregation.
NR0083 - Satyen - 06/Feb/2013 :: To handle aggregation till end of shift.
ER0349 - SwathiKS- 16/Apr/2013 :: a> To handle Marked_For_Rework during aggregation.
 b> Introduced New Column "FormatedWONumber" To handle WorkOrderNumber Format JC(Fixed)\REG(1st 3 Digits Componentid)\6(Plant Code) (space) 123456(6 digits Workorder No.)
 c> To handle Delete Logic for "ShiftReworkDetails" Table.
DR0325 - SwathiKS - 27/May/2013 :: For Utilised calculation To consider difference between Autodata msttime and ndtime for Tyep1 Record with PDT.
DR0329 - SwathiKS - 06/Jul/2013 :: To associate correct production record with rejection record/rework record when rejections/rework records are not in the order of date-shift.
DR0343 - SwathiKS - 10/Apr/2014 :: Aggregated data was not visible in Jobcard if Datepart is sent with timepart so we are formatting to insert only datepart.
DR0359 - Satya/Vasavi - 16-Mar-2015 :: OMR Bagla :: Rejection/Rework not processing for some of the machines.
DR0368 - SwathiKS - 02-Sep-2015 :: To handle Aggregated data was not visible in JobCard and Reports.
DR0371 - SwathiKS - 12-Jan-16 :: Fix to handle while processing rejection and rework records, changed logic of getting last processed record from Shiftaggtrail for each machine.
ER0202 - SwathiKS - 11/Dec/2017 :: Altered Aggregation Proc. for Performance optimization For Bosch Jaipur,
a> While Calculating ICD
b> While Handling ICD-PDT Interaction
c> While Procesing Rejections and Rework Records.
d>Introduced Temp Table concept.
DR0389-SwathiKS-03/March/2021::Altered Aggregation Procedure To Handle Null ProdQty and To handle for Some days Aggregation was skipping.
DR0390-SwathiKS-17/August/2021::Altered Aggregation Procedure, To handle Downtime Mismatch During PDT

--s_Push_Prodn_Down_ShiftAggregation '2012-06-01 06:00:00 AM','','''CLASSIC MCY''','','delete','','2012-06-01'
--s_Push_Prodn_Down_ShiftAggregation '2013-jan-01 17:30:00','','''ACE-04''','','push','','2013-jan-05 17:30:00'
--s_Push_Prodn_Down_ShiftAggregation  '2021-08-01'   , '' ,'''440''' ,'','PUSH','','2021-08-01'

exec [dbo].[s_Push_Prodn_Down_ShiftAggregation] '2023-05-12 18:54:50.000','','','','PUSH','','2023-05-14 23:59:59.000',''

*****************************************************************************************************************/

CREATE   PROCEDURE [dbo].[s_Push_Prodn_Down_ShiftAggregation]
@Date as DateTime,
@Shift as Nvarchar(20),
--@MachineID as NvarChar(500),---mod 2:- Changed from nvarchar(50) to nvarchar(500) as list of machines will be passed --DR0302 Commented
@MachineID as NvarChar(600), --DR0302 Added
@PlantID As NvarChar(50),
@Type As Nvarchar(20)='PUSH',
---mod 1(a)
@LastAggrecord as datetime,
---mod 1(a)
---mod 3
@EndDate as datetime,
---mod
@GroupID nvarchar(50)='' --GNA

WITH RECOMPILE ---ER0202
AS
BEGIN
---MOD 4(2)
 
 SET NOCOUNT ON; ---ER0202


IF (@EndDate='' or isnull(@EndDate,'')='')
Begin
	SET @EndDate = CAST(datePart(yyyy,@Date) AS nvarchar(4)) + '-' + CAST(datePart(mm,@Date) AS nvarchar(2)) + '-' + CAST(datePart(dd,@Date) AS nvarchar(2))
END

DECLARE @ErrNo as int
---MOD 4(2)
Declare @StartTime as datetime
Declare @EndTime as datetime
--Declare @strMachine as nvarchar(600)  --DR0302 Commented
Declare @strMachine as nvarchar(2000) --DR0302 Added
Declare @strtemp as nvarchar(1000) --DR0302 Added 

Declare @strPlantID as nvarchar(250)
--Declare @StrSql as nvarchar(4000) --DR0302 Commented
Declare @StrSql as nvarchar(max) --DR0302 Added
---mod 11
Declare @Qparam1 as nvarchar(500)
Declare @Qparam2 as nvarchar(500)
Declare @Rejection as nvarchar(max)
--mod 11

Declare @MRework as nvarchar(4000) --ER0349
Declare @Companyname as nvarchar(50) --ER0349

declare @StrGroupID as nvarchar(255) --GNA
select @StrGroupID='' --GNA

CREATE TABLE #ShiftDetails
(
PDate datetime,
Shift nvarchar(20),
ShiftStart datetime,
ShiftEnd datetime,
Shiftid int --swathi
)
CREATE TABLE #Exceptions
(
MachineID NVarChar(50),
ComponentID Nvarchar(50),
---mod 10
---OperationNo Int,
OperationNo Nvarchar(50),
---mod 10
StartTime DateTime,
EndTime DateTime,
IdealCount Int,
ActualCount Int,
ExCount Int DEFAULT 0,
---mod 3
ExDate datetime,
ExShift nvarchar(50),
EXShiftStart datetime,
ExShiftEnd datetime,
ExLastAggrStart datetime
---mod 3
)
---mod 2 Table to hold the list of machines to be processed and their last aggregated record
create table #TempMCOODown
(
Mdate datetime,
MShift nvarchar(50),
MShiftStart datetime,
MShiftEnd datetime,
AMachine nvarchar(50),
LastAggstart datetime --default convert(nvarchar(20),'01-01-2000 12:00:00 AM',120)
)
create table #TempMCOODown2
(
Mdate datetime,
MShift nvarchar(50),
MShiftStart datetime,
MShiftEnd datetime,
AMachine nvarchar(50),
LastAggstart datetime, --default convert(nvarchar(20),'01-01-2000 12:00:00 AM',120)
Endtime datetime --SV
)
---Table to hold Type-2 production records having InCycledowns
create table #ICD
(   Idate datetime,
IShift nvarchar(50),
IShiftStart datetime,
IShiftEnd datetime,
Imc nvarchar(50),
Icomp nvarchar(50),
---mod 10
---Iopn int,
Iopn nvarchar(50),
---mod 10
Iopr nvarchar(50),
Isttime datetime,
Indtime datetime,
---mod 7
WorkOrderNumber nvarchar(50),
---mod 7
Imsttime datetime, --ER0202
PJCYear nvarchar(10)
)
create table #TempShiftProductionDetails
(
pDate datetime,
Shift nvarchar(50),
PShiftStart datetime,
PShiftEnd datetime,
PlantID nvarchar(50),
MachineID nvarchar(50),
ComponentID nvarchar(50),
---mod 10
---OperationNo int,
OperationNo nvarchar(50),
---mod 10
OperatorID nvarchar(50),
Prod_Qty int,
Sum_of_ActCycleTime float,
Sum_of_ActLoadUnload float,
---mod 8
-- CO_StdMachiningTime int,
-- CO_StdLoadUnload int,
CO_StdMachiningTime float,
CO_StdLoadUnload float,
---mod 8
Price float,
SubOperation int,
AcceptedParts int,
Dummy_Cycles int,
ActMachiningTime_Type12 float,
ActLoadUnload_Type12 float,
MaxMachiningTime float,
MinMachiningTime float,
MaxLoadUnloadTime float,
MinLoadUnloadTime float,
LastAggrStart datetime,
Minterface nvarchar(50),
Cinterface nvarchar(50),
Opninterface nvarchar(50),
OprInterface nvarchar(50),
---mod 7
WorkOrderNumber nvarchar(50),
---mod 7
--geet added from here
MachinewiseOwner nvarchar(50),
CriticalMachineEnabled bit,
--geet added till here
FormatedWONumber nvarchar(50), --ER0349 Added
GroupID nvarchar(50), --GNA
mchrrate float,
PDT float,
PJCYear nvarchar(10),
Finishedoperation int

)
----ER0332 added from here on 21st Aug 2012 by Geetanjali k
Create Table #TempShiftRejection
(
SR_Pdate datetime,
SR_Shift nvarchar(150),
SR_Mach_interface nvarchar(150),
SP_Machineid nvarchar(150),
SR_Comp_interface nvarchar(150),
Sp_Componentid nvarchar(150),
SR_Operation_interface nvarchar(150),
Sp_Opn nvarchar(150),
SR_Oprtor_interface nvarchar(150),
Sp_Oprtor nvarchar(150),
Rejectionreason nvarchar(150),
RejectionQty int,
SDTimestamp datetime,
ShiftProdid bigint default 0,
Recordid bigint,
--LastAggrStart datetime
WorkOrderNumber nvarchar(50), ----ER0202

)
Create Table #TempProdAccepted
(
PA_MachineID nvarchar(50),
PA_ComponentID nvarchar(50),
PA_OperationNo nvarchar(50),
PA_OperatorID nvarchar(50),
PA_Shift nvarchar(20),
PA_RejectionQty int,
Pa_id int,
PA_date datetime,
PA_Accepted bigint,
PA_ExtraRejQty int default 0,--ER0202
PA_WorkOrderNumber nvarchar(50), --ER0202
PA_PJCYear nvarchar(10)
)
----ER0332 added till here on 21st Aug 2012 by Geetanjali k

--ER0349 Added From Here
Create Table #TempShiftRework
(
SR_Pdate datetime,
SR_Shift nvarchar(150),
SR_Mach_interface nvarchar(150),
SP_Machineid nvarchar(150),
SR_Comp_interface nvarchar(150),
Sp_Componentid nvarchar(150),
SR_Operation_interface nvarchar(150),
Sp_Opn nvarchar(150),
SR_Oprtor_interface nvarchar(150),
Sp_Oprtor nvarchar(150),
Reworkreason nvarchar(150),
ReworkQty int,
SDTimestamp datetime,
ShiftProdid bigint default 0,
Recordid bigint,
WorkOrderNumber nvarchar(50) --ER0202
)

Create Table #TempProdAccepted1
(
PA_MachineID nvarchar(50),
PA_ComponentID nvarchar(50),
 
PA_OperationNo nvarchar(50),
PA_OperatorID nvarchar(50),
PA_Shift nvarchar(20),
PA_ReworkQty int,
Pa_id int,
PA_date datetime,
PA_Accepted bigint,
PA_MReworkQty int,
PA_ExtraRewQty int default 0 ,--ER0202
PA_WorkOrderNumber nvarchar(50), --ER0202
PA_PJCYear nvarchar(10)
)
--ER0349 Added Till Here


---mod 2
---mod 11:Table to store PDT at Machine and shift level
CREATE TABLE #PlannedDownTimes
(
StartTime  DateTime,
EndTime  DateTime,
MachineId nvarchar(50),
MachineInterface nvarchar(50),
Sdate Datetime,
ShiftStart Datetime,
ShiftEnd Datetime,
ShiftName nvarchar(50)
)

--DR0359
CREATE TABLE #Temp_MC_LastAggRejection
(
MachineId nvarchar(50),
MaxRejectionId int
)
CREATE TABLE #Temp_MC_LastAggRework
(
MachineId nvarchar(50),
MaxReworkId int
)
---mod 11
SET @StrSql = ''
SET @strMachine = ''
SET @strPlantID = ''
---mod 11
SELECT @Qparam1=''
SELECT @Qparam2=''
IF (SELECT ValueInText From CockpitDefaults Where Parameter='Ignore_Count_4m_PLD')='Y'
BEGIN
SELECT @Qparam1=' And A.ID NOT IN (SELECT ID From AutoData A inner Join #PlannedDownTimes
on #PlannedDownTimes.MachineInterface=A.MC
Where A.Ndtime>StartTime And A.NdTime<=EndTime And A.DataType=1 ) '
END
IF (SELECT ValueInText From CockpitDefaults Where Parameter='Ignore_PTime_4m_PLD')='Y'
BEGIN
SELECT @Qparam2=' And A.ID NOT IN (SELECT ID From AutoData A inner Join #PlannedDownTimes
on #PlannedDownTimes.MachineInterface=A.MC
Where A.Ndtime>StartTime And A.NdTime<=EndTime And A.DataType=1 ) '
END

select @Companyname=''
select @Companyname = isnull(Companyname,'A') from Company
print @Companyname



---mod 11
If @Type='PUSH'
BEGIN
if isnull(@MachineID,'')<> ''
begin
---SET @strMachine = ' AND MachineInformation.MachineID = ''' + @machineid + ''''
---mod 2 Aggregating multiple machines at one time
SET @strMachine = ' AND M.MachineID  in ( ' +  @machineid + ') '
---mod 2
end
if isnull(@PlantID,'')<> ''
Begin
---mod 6
-- SET @strPlantID = ' AND PlantMachine.PlantID = ''' + @PlantID + ''''
SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
---mod 6
--GNA
if isnull(@GroupID,'')<> ''
Begin
SET @strGroupID = ' AND PlantMachineGroups.GroupID = N''' + @GroupID + ''''
End
--GNA
End
END
ELSE
BEGIN
if isnull(@MachineID,'') <> ''
begin
---mod 6
-- SET @strMachine = ' AND ShiftProductionDetails.MachineID = ''' + @machineid + ''''
SET @strMachine = ' AND ShiftProductionDetails.MachineID = N''' + @machineid + ''''
---mod 6
end
if isnull(@PlantID,'')<> ''
Begin
---mod 6
-- SET @strPlantID = ' AND ShiftProductionDetails.PlantID = ''' + @PlantID + ''''
SET @strPlantID = ' AND ShiftProductionDetails.PlantID = N''' + @PlantID + ''''
---mod 6
End
--GNA
if isnull(@GroupID,'')<> ''
Begin
SET @strGroupID = ' AND PlantMachineGroups.GroupID = N''' + @GroupID + ''''
End
--GNA
END
If @Type='PUSH'
BEGIN
--Get Shift Start and Shift End
INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
--EXEC s_GetShiftTime @Date,@Shift
Exec  s_GetShiftTime @Date,''
--Select * from #ShiftDetails
----mod 1(a) If you find any last aggregated record
/*declare @LastAggStart as nvarchar(200)
select @LastAggStart=''
if isnull(@LastAggrecord,'')<>''  --- and  @MaxStarttime <>''
begin
select @LastAggStart = ' and A.mStTime > ''' + convert(nvarchar(20),@LastAggrecord,120)+ ''' '
end*/
---mod 1(a)
--Introduced TOP 1 to take care of input 'ALL' shifts
select @StartTime =(select TOP 1 shiftstart from #ShiftDetails ORDER BY shiftstart ASC)
select @EndTime =(select TOP 1 shiftend from #ShiftDetails ORDER BY shiftend DESC)

declare @firstshift as nvarchar(50)
select @firstshift=''
select @firstshift=(select TOP 1 shift from #ShiftDetails order by shiftstart ASC)
---mod 2 To build a temp table to store machines and respective last aggregated record
/*SELECT @StrSql=' insert into #TempMCOODown ( Mdate,MShift,MShiftStart,MShiftEnd,AMachine,LastAggstart)'
SELECT @StrSql=@StrSql + ' SELECT '''+Convert(NvarChar(20),@Date,120)+''','''+@Shift+''',''' + Convert(nvarchar(20),@StartTime,120) +''',''' + Convert(nvarchar(20),@EndTime,120) +''',M.Machineid,
case when max(S.endtime) is not null then max(S.endtime) else ''' + Convert(nvarchar(20),'01-01-2000 12:00:00 AM',120)+'''  end as LastAggstart  from Machineinformation M
left outer  join ShiftAggTrail as S on M.Machineid=S.Machineid where M.Machineid in ( ' + @MachineID + ')'
SELECT @StrSql=@StrSql + ' group by M.Machineid '*/
---select @firstshift

--Get the last aggregated date and shift for the machines. If there is no last aggregated details,starting point will be @Date
-- DR0371 Commented and added PlantId in the Filter Class From here
-- select @StrSql=''
-- SELECT @StrSql=' insert into #TempMCOODown2 ( Mdate,MShift,AMachine,LastAggstart)'
-- SELECT @StrSql=@StrSql + 'select T1.lastdate,case when S.Endtime=T1.LastAggstart then S.Shift else ''' +  @firstshift +'''  end as shift,T1.Machineid,T1.LastAggstart from Shiftaggtrail S right outer join (
-- --SELECT case when max(S.aggdate) is null then ''' + convert(nvarchar(20),@Date,120)+ ''' else max(S.aggdate) end as lastdate,M.Machineid, --DR0343
-- SELECT case when max(S.aggdate) is null then ''' + convert(nvarchar(10),@Date,120)+ ''' else max(S.aggdate) end as lastdate,M.Machineid, --DR0343
-- case when max(S.endtime) is not null then max(S.endtime) else ''' + Convert(nvarchar(20),'01-01-2000 12:00:00 AM',120)+'''   end as LastAggstart  from Machineinformation M
-- left outer join ShiftAggTrail as S on M.Machineid=S.Machineid where 1=1 ' -- where M.Machineid in ( ' + @MachineID + ')'
-- SELECT @StrSql=@StrSql + 'and isnull(recordid,0)=''0'' ' --ER0349 Added Line
-- SELECT @StrSql=@StrSql +@strMachine 
-- SELECT @StrSql=@StrSql + 'group by M.Machineid)  T1 on T1.Machineid=S.Machineid  and T1.lastdate=S.aggdate  and S.Endtime=T1.LastAggstart '
-- print @StrSql
-- exec (@StrSql)

select @StrSql=''
SELECT @StrSql=' insert into #TempMCOODown2 ( Mdate,MShift,AMachine,LastAggstart)'
SELECT @StrSql=@StrSql + 'select T1.lastdate,case when S.Endtime=T1.LastAggstart then S.Shift else ''' +  @firstshift +'''  end as shift,T1.Machineid,T1.LastAggstart from Shiftaggtrail S right outer join (
--SELECT case when max(S.aggdate) is null then ''' + convert(nvarchar(20),@Date,120)+ ''' else max(S.aggdate) end as lastdate,M.Machineid, --DR0343
SELECT case when max(S.aggdate) is null then ''' + convert(nvarchar(10),@Date,120)+ ''' else max(S.aggdate) end as lastdate,M.Machineid, --DR0343
case when max(S.endtime) is not null then max(S.endtime) else ''' + Convert(nvarchar(20),'01-01-2000 12:00:00 AM',120)+'''   end as LastAggstart  from Machineinformation M
LEFT OUTER JOIN PlantMachine ON M.MachineID=PlantMachine.MachineID
LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
left outer join ShiftAggTrail as S on M.Machineid=S.Machineid where 1=1 ' -- where M.Machineid in ( ' + @MachineID + ')'
SELECT @StrSql=@StrSql + 'and isnull(recordid,0)=''0'' ' --ER0349 Added Line
SELECT @StrSql=@StrSql +@strMachine+@strPlantID+@StrGroupID --GNA 
SELECT @StrSql=@StrSql + 'group by M.Machineid)  T1 on T1.Machineid=S.Machineid  and T1.lastdate=S.aggdate  and S.Endtime=T1.LastAggstart '
print @StrSql
exec (@StrSql)




-- DR0371 added PlantId in the Filter Class Till here

	--ER0202 Added From Here
	Update #TempMCOODown2 set Endtime=T1.Enddate from
	(Select Distinct AMachine,Case when Datepart(YEAR,@Enddate)='9999' then Dateadd(Day,Datepart(Day,@Enddate),case when LastAggstart<>'2000-01-01 12:00:00.000' then LastAggstart else Mdate end) Else @Enddate EnD as Enddate
	 from #TempMCOODown2
     )T1 inner join #TempMCOODown2 on #TempMCOODown2.AMachine=T1.AMachine


	Update #TempMCOODown2 set Endtime=case when T1.sttime='1900-01-01' then T1.LastAggstart else T1.endtime end from
	(select T.AMachine,autodata.mc,ISNULL(max(autodata.sttime),'1900-01-01') as sttime,T.LastAggstart,T.Endtime  from Autodata with(nolock)
	inner join Machineinformation M on autodata.mc=M.interfaceid
	inner join #TempMCOODown2 T on M.Machineid=T.AMachine
	where sttime>=T.LastAggstart and ndtime<=T.Endtime
	Group by T.AMachine,autodata.mc,T.LastAggstart,T.Endtime)T1 inner join #TempMCOODown2 on #TempMCOODown2.AMachine=T1.AMachine
	--ER0202 Added Till Here




/* --ER0202
Declare @Mdate as datetime
Declare @MShift as nvarchar(50)
Declare @AMachine as nvarchar(50)
Declare @curLastAggstart as datetime
declare @CurStrtTime as datetime
declare @CurEndTime as datetime
delete from #ShiftDetails
---In the following lines we are preparing the temp table which contains the date, shift and LastAggregated time stamp, and machine
Declare TemplateShift CURSOR FOR
SELECT distinct  Mdate,MShift,AMachine,LastAggstart
 from #TempMCOODown2 order by AMachine
OPEN TemplateShift
FETCH NEXT FROM TemplateShift INTO @Mdate,@MShift,@AMachine,@curLastAggstart
WHILE (@@fetch_status = 0)
 BEGIN
select @CurStrtTime=@Mdate
select @CurEndTime=@EndDate
---get shiftdefinition for all the days
while @CurStrtTime<=@EndDate
begin
---get shiftdetails for  @CurStrtTime
INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
EXEC s_GetShiftTime @CurStrtTime,''
SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
end
insert into #TempMCOODown (Mdate,MShift,MShiftStart,MShiftEnd,AMachine,LastAggstart)
--select Pdate, Shift,ShiftStart,ShiftEnd,@AMachine,@curLastAggstart from --DR0368
select convert(nvarchar(10),Pdate,120), Shift,ShiftStart,ShiftEnd,@AMachine,@curLastAggstart from --DR0368 To Format Pdate while Insertion
#ShiftDetails order by ShiftStart asc
delete from #ShiftDetails
 FETCH NEXT FROM TemplateShift INTO @Mdate,@MShift,@AMachine,@curLastAggstart
 end
--return
close TemplateShift
deallocate TemplateShift
--ER0202 */
 ------ER0202

 	Declare @Mdate as datetime
	Declare @MShift as nvarchar(50)
	Declare @AMachine as nvarchar(50)
	Declare @curLastAggstart as datetime
	Declare @CurEndDate as datetime

	declare @CurStrtTime as datetime
	declare @CurEndTime as datetime
	delete from #ShiftDetails
	---In the following lines we are preparing the temp table which contains the date, shift and LastAggregated time stamp, and machine
	
	Declare TemplateShift CURSOR FOR
	SELECT distinct  Mdate,MShift,AMachine,LastAggstart,Endtime
				  from #TempMCOODown2 order by AMachine
	OPEN TemplateShift
	FETCH NEXT FROM TemplateShift INTO @Mdate,@MShift,@AMachine,@curLastAggstart,@CurEndDate
		
	 WHILE (@@fetch_status = 0)
	  BEGIN
		
		select @CurStrtTime=@Mdate
		select @CurEndTime=@CurEndDate
				
		---get shiftdefinition for all the days
		while @CurStrtTime<=@CurEndTime
		begin
			---get shiftdetails for  @CurStrtTime
			INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
			EXEC s_GetShiftTime @CurStrtTime,''
			SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
		end
		insert into #TempMCOODown (Mdate,MShift,MShiftStart,MShiftEnd,AMachine,LastAggstart)
		--select Pdate, Shift,ShiftStart,ShiftEnd,@AMachine,@curLastAggstart from --DR0368
		select convert(nvarchar(10),Pdate,120), Shift,ShiftStart,ShiftEnd,@AMachine,@curLastAggstart from --DR0368 To Format Pdate while Insertion
		#ShiftDetails order by ShiftStart asc
	

		delete from #ShiftDetails
		
		
	  FETCH NEXT FROM TemplateShift INTO @Mdate,@MShift,@AMachine,@curLastAggstart,@CurEndDate
	  end
	
	close TemplateShift
	deallocate TemplateShift
--ER0202


---delete the machines for which aggregation has been done already.
delete from #TempMCOODown where LastAggstart=MShiftEnd


---update the last aggregated time to '01-01-2000 12:00:00 AM' if it is equal to shiftstarttime.
---This is required in order not to miss Type - 2  record
---mod 4(1).update the last aggregated time to '01-01-2000 12:00:00 AM' if it is greate than or equal to shiftstarttime.
---This is in order not to miss the records which are running across more than 2 shifts.
---update #TempMCOODown set  LastAggstart=Convert(nvarchar(20),'01-01-2000 12:00:00 AM',120) where MShiftStart=LastAggstart
update #TempMCOODown set LastAggstart=Convert(nvarchar(20),'01-01-2000 12:00:00 AM',120) where MShiftStart>=LastAggstart
---MOD 4(1)
---mod 2


--delete from #TempMCOODown where MShiftEnd > getdate() --NR0083 added




--ER0202 Introduced Temp table 
CREATE TABLE #T_autodata(  
 [mc] [nvarchar](50)not NULL,  
 [comp] [nvarchar](50) NULL,  
 [opn] [nvarchar](50) NULL,  
 [opr] [nvarchar](50) NULL,  
 [dcode] [nvarchar](50) NULL,  
 [sttime] [datetime] not NULL,  
 [ndtime] [datetime] not NULL,  
 [datatype] [tinyint] NULL ,  
 [cycletime] [int] NULL,  
 [loadunload] [int] NULL ,  
 [msttime] [datetime] not NULL,  
 [PartsCount] decimal(18,5) NULL ,  
 id  bigint not null,
 [WorkOrderNumber] nvarchar(50)  NULL,
 [PJCYear] nvarchar(10) null
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime,ndtime,msttime ASC  
)ON [PRIMARY]  
  
Declare @T_ST AS Datetime   
Declare @T_ED AS Datetime   
  
Select @T_ST=MIN(MShiftStart) FROM #TempMCOODown
Select @T_ED=max(MShiftEnd) FROM #TempMCOODown


Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id,WorkOrderNumber,PJCYear'  
select @strsql = @strsql + ' from autodata with(nolock) where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'  
print @strsql  
exec (@strsql)  
-----ER0202 Added Till Here


--select * from  #TempMCOODown
--Build String for Insertion[Production Details]
---Get all the MAchine,comp,opn,operator combination for all the shift and machine
--Calculate count,get master information for the comp and opn
-- CO_IdealCycleTime = Std.Machining Time OR Std.Cutting Time
--select * from  #TempMCOODown
---mod 7
-- SELECT @StrSql=' Insert into #TempShiftProductionDetails(pDate,Shift,PShiftStart,PShiftEnd,PlantID,MachineID,
-- ComponentID,OperationNo,OperatorID,Prod_Qty,CO_StdMachiningTime,CO_StdLoadUnload,
-- Price,SubOperation,AcceptedParts,LastAggrStart,Minterface,Cinterface ,Opninterface ,OprInterface)'
/************************************** DR0272 From Here
SELECT @StrSql=' Insert into #TempShiftProductionDetails(pDate,Shift,PShiftStart,PShiftEnd,PlantID,MachineID,
ComponentID,OperationNo,OperatorID,Prod_Qty,CO_StdMachiningTime,CO_StdLoadUnload,
Price,SubOperation,AcceptedParts,LastAggrStart,Minterface,Cinterface ,Opninterface ,OprInterface,WorkOrderNumber)'
DR0272 Till Here ***************************************/
 
If @Companyname <> 'SUPER AUTO FORGE PVT LTD-MEPZ' --ER0349 Added
Begin  --ER0349 Added

--DR0272 From Here
SELECT @StrSql=' Insert into #TempShiftProductionDetails(pDate,Shift,PShiftStart,PShiftEnd,PlantID,MachineID,
ComponentID,OperationNo,OperatorID,CO_StdMachiningTime,CO_StdLoadUnload,
Price,SubOperation,LastAggrStart,Minterface,Cinterface ,Opninterface ,OprInterface,WorkOrderNumber,
MachinewiseOwner ,CriticalMachineEnabled --geeta added
,FormatedWONumber,GroupID,mchrrate,PJCYear,Finishedoperation)' --ER0349 added New Column --GNA
--DR0272 Till Here
---mod 7
SELECT @StrSql= @StrSql
+ ' SELECT T.Mdate,T.Mshift,T.MShiftStart,T.MShiftEnd,PlantMachine.PlantID,T.Amachine,
componentinformation.componentid,componentoperationpricing.operationno, EmployeeInformation.EmployeeID,'
--SELECT @StrSql= @StrSql+ ' CAST(CEILING(CAST(Sum(A.PartsCount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer ) as opn,' --DR0272
SELECT @StrSql= @StrSql
+ ' (componentoperationpricing.machiningtime),(componentoperationpricing.CycleTime - componentoperationpricing.machiningtime),
componentoperationpricing.Price,componentoperationpricing.SubOperations, '
--SELECT @StrSql= @StrSql+ ' CAST(CEILING(CAST(Sum(A.PartsCount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer ) ' --DR0272
SELECT @StrSql= @StrSql
+ ' max(T.LastAggstart)
,machineinformation.InterfaceID,componentinformation.InterfaceID,componentoperationpricing.InterfaceID,EmployeeInformation.InterfaceID '
---mod 7
SELECT @StrSql= @StrSql
+ ' ,A.WorkOrderNumber'
SELECT @StrSql= @StrSql+',machineinformation.MachinewiseOwner ,machineinformation.CriticalMachineEnabled' --geeta added
---mod 7
SELECT @StrSql= @StrSql+',A.WorkOrderNumber,PlantMachineGroups.GroupID, machineinformation.mchrrate,A.PJCYear,componentoperationpricing.Finishedoperation ' --ER0349 Added --GNA
SELECT @StrSql= @StrSql
+ ' FROM #T_autodata A --ER0202 
INNER JOIN EmployeeInformation ON A.Opr=EmployeeInformation.InterfaceID
INNER JOIN machineinformation ON A.mc = machineinformation.InterfaceID
inner join #TempMCOODown T on T.Amachine=machineinformation.Machineid
LEFT OUTER JOIN PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID --GNA
INNER JOIN componentinformation ON A.comp = componentinformation.InterfaceID
INNER JOIN componentoperationpricing ON (A.opn = componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid) '
---mod 5
SELECT @StrSql= @StrSql
+ ' and machineinformation.machineid = componentoperationpricing.machineid '
---mod 5
--DR0272 From here.
--SELECT @StrSql = @StrSql+ ' WHERE A.ndtime > T.MShiftStart AND A.ndtime <=T.MShiftEnd '
SELECT @StrSql = @StrSql
+ ' WHERE ((A.ndtime > T.MShiftStart AND A.ndtime <=T.MShiftEnd) or
(A.msttime>=T.MShiftStart and A.msttime<T.MShiftEnd and A.ndtime>T.MShiftEnd) or
(A.msttime<T.MShiftStart and A.ndtime>T.MShiftEnd))
AND (A.datatype = 1)'
--DR0272 Till here.
SELECT @StrSql = @StrSql + @strPlantID + @StrGroupID --GNA
SELECT @StrSql = @StrSql + ' and A.mStTime >= T.LastAggstart '
--mod 11
SELECT @StrSql = @StrSql + @Qparam1
---mod 11
SELECT @StrSql = @StrSql + ' GROUP BY T.Mdate,T.Mshift,T.MShiftStart,T.MShiftEnd,PlantMachine.PlantID,T.Amachine,componentinformation.componentid, componentoperationpricing.operationno, EmployeeInformation.EmployeeID,
componentoperationpricing.cycletime, componentoperationpricing.machiningtime , componentoperationpricing.SubOperations,
componentoperationpricing.LoadUnload,componentoperationpricing.Price,machineinformation.InterfaceID ,componentinformation.InterfaceID ,componentoperationpricing.InterfaceID,EmployeeInformation.InterfaceID'
---mod 7
SELECT @StrSql = @StrSql + ',A.WorkOrderNumber,machineinformation.MachinewiseOwner ,machineinformation.CriticalMachineEnabled,PlantMachineGroups.GroupID, machineinformation.mchrrate,A.PJCYear,componentoperationpricing.Finishedoperation '--geeta added --GNA
---mod 7
print @StrSql
Exec (@StrSql)

END --ER0349 Added

If @Companyname = 'SUPER AUTO FORGE PVT LTD-MEPZ' --ER0349 Added
Begin  --ER0349 Added

--DR0272 From Here
SELECT @StrSql=' Insert into #TempShiftProductionDetails(pDate,Shift,PShiftStart,PShiftEnd,PlantID,MachineID,
ComponentID,OperationNo,OperatorID,CO_StdMachiningTime,CO_StdLoadUnload,
Price,SubOperation,LastAggrStart,Minterface,Cinterface ,Opninterface ,OprInterface,WorkOrderNumber,
MachinewiseOwner ,CriticalMachineEnabled --geeta added
,FormatedWONumber,GroupID,mchrrate)' --ER0349 Added New column
--DR0272 Till Here
---mod 7
SELECT @StrSql= @StrSql
+ ' SELECT T.Mdate,T.Mshift,T.MShiftStart,T.MShiftEnd,PlantMachine.PlantID,T.Amachine,
componentinformation.componentid,componentoperationpricing.operationno, EmployeeInformation.EmployeeID,'
--SELECT @StrSql= @StrSql
+ ' CAST(CEILING(CAST(Sum(A.PartsCount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer ) as opn,' --DR0272
SELECT @StrSql= @StrSql
+ ' (componentoperationpricing.machiningtime),(componentoperationpricing.CycleTime - componentoperationpricing.machiningtime),
componentoperationpricing.Price,componentoperationpricing.SubOperations, '
--SELECT @StrSql= @StrSql
+ ' CAST(CEILING(CAST(Sum(A.PartsCount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer ) ' --DR0272
SELECT @StrSql= @StrSql
+ ' max(T.LastAggstart)
,machineinformation.InterfaceID,componentinformation.InterfaceID,componentoperationpricing.InterfaceID,EmployeeInformation.InterfaceID '
---mod 7
SELECT @StrSql= @StrSql
+ ' ,A.WorkOrderNumber' 
SELECT @StrSql= @StrSql+',machineinformation.MachinewiseOwner ,machineinformation.CriticalMachineEnabled' --geeta added
---mod 7
SELECT @StrSql= @StrSql
+ ' ,''JC\'' + substring(isnull(componentinformation.componentid,''Invalid Component''),1,3) + ''\'' + isnull(PlantInformation.Plantcode,0) + '' '' + isnull(A.WorkOrderNumber,0)' --ER0349 Added
SELECT @StrSql= @StrSql
+ ' ,PlantMachineGroups.GroupID , --GNA
machineinformation.mchrrate
FROM #T_autodata A ---ER0202 
INNER JOIN EmployeeInformation ON A.Opr=EmployeeInformation.InterfaceID
INNER JOIN machineinformation ON A.mc = machineinformation.InterfaceID
inner join #TempMCOODown T on T.Amachine=machineinformation.Machineid
LEFT OUTER JOIN PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
LEFT OUTER JOIN PlantInformation on PlantInformation.Plantid=PlantMachine.plantid --ER0349 Added
LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID --GNA
INNER JOIN componentinformation ON A.comp = componentinformation.InterfaceID
INNER JOIN componentoperationpricing ON (A.opn = componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid) '
---mod 5
SELECT @StrSql= @StrSql
+ ' and machineinformation.machineid = componentoperationpricing.machineid '
---mod 5
--DR0272 From here.
--SELECT @StrSql = @StrSql+ ' WHERE A.ndtime > T.MShiftStart AND A.ndtime <=T.MShiftEnd '
SELECT @StrSql = @StrSql
+ ' WHERE ((A.ndtime > T.MShiftStart AND A.ndtime <=T.MShiftEnd) or
(A.msttime>=T.MShiftStart and A.msttime<T.MShiftEnd and A.ndtime>T.MShiftEnd) or
(A.msttime<T.MShiftStart and A.ndtime>T.MShiftEnd))
AND (A.datatype = 1)'
--DR0272 Till here.
SELECT @StrSql = @StrSql + @strPlantID + @StrGroupID --GNA
SELECT @StrSql = @StrSql + ' and A.mStTime >= T.LastAggstart '
--mod 11
SELECT @StrSql = @StrSql + @Qparam1
---mod 11
SELECT @StrSql = @StrSql + ' GROUP BY T.Mdate,T.Mshift,T.MShiftStart,T.MShiftEnd,PlantMachine.PlantID,T.Amachine,componentinformation.componentid, componentoperationpricing.operationno, EmployeeInformation.EmployeeID,
componentoperationpricing.cycletime, componentoperationpricing.machiningtime , componentoperationpricing.SubOperations,
componentoperationpricing.LoadUnload,componentoperationpricing.Price,machineinformation.InterfaceID ,componentinformation.InterfaceID ,componentoperationpricing.InterfaceID,EmployeeInformation.InterfaceID'
---mod 7
SELECT @StrSql = @StrSql + ',A.WorkOrderNumber,machineinformation.MachinewiseOwner ,machineinformation.CriticalMachineEnabled'--geeta added
---mod 7
SELECT @StrSql = @StrSql + ',PlantInformation.Plantcode,PlantMachineGroups.GroupID,machineinformation.mchrrate ' --ER0349 Added  --Added Groupid For GNA
print @StrSql
Exec (@StrSql)

END --ER0349 Added
-----------------------------ER0202
---------------DR0272 From Here.
SELECT @StrSql=''
--SELECT @StrSql=
--'UPDATE #TempShiftProductionDetails SET Acceptedparts = isnull(AcceptedParts,0) + isNull(t2.Components,0),Prod_Qty=isnull(Prod_Qty,0) + isNull(t2.Components,0)
--from
--(select   T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
--CAST(CEILING(CAST(Sum(A.PartsCount)as float)/ ISNULL(O.SubOperations,1))as integer ) as Components
--,T.WorkOrderNumber as WorkOrderNumber
--from #T_autodata A
--INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
--INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
--INNER JOIN componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
--and M.machineid = O.machineid
--Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
--where (A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart)
--and A.WorkOrderNumber = T.WorkOrderNumber'
 
--SELECT @StrSql=@StrSql +' group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
--,T.WorkOrderNumber,O.SubOperations
--) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
--And t2.CShift=#TempShiftProductionDetails.Shift
--And t2.CMachine = #TempShiftProductionDetails.MachineID
--And t2.CComponent=#TempShiftProductionDetails.Componentid
--And t2.COpnNo=#TempShiftProductionDetails.OperationNo
--And t2.COpr=#TempShiftProductionDetails.OperatorID
 
--AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber '
--print @StrSql
--Exec(@StrSql)


SELECT @StrSql=
'UPDATE #TempShiftProductionDetails SET Acceptedparts = isnull(AcceptedParts,0) + isNull(t2.Components,0),Prod_Qty=isnull(Prod_Qty,0) + isNull(t2.Components,0)
from
(select   T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
CAST(CEILING(CAST(Sum(A.PartsCount)as float)/ ISNULL(T.SubOperation,1))as integer ) as Components,T.WorkOrderNumber as WorkOrderNumber,T.PJCYear
from #T_autodata A -----ER0202 
Inner join #TempShiftProductionDetails T on
T.Minterface=A.mc and T.Cinterface=A.comp and T.Opninterface=A.opn and T.OprInterface=A.opr and A.WorkOrderNumber = T.WorkOrderNumber and A.PJCYear=T.PJCYear
where (A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart)'
SELECT @StrSql=@StrSql +' group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID,T.WorkOrderNumber,T.PJCYear,T.SubOperation
) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
AND t2.PJCYear = #TempShiftProductionDetails.PJCYear'
print @StrSql
Exec(@StrSql)


----------------------------------------ER0202

---------------DR0272 Till Here.
/*SELECT @StrSql=' Insert into #TempShiftProductionDetails (
pDate,Shift,PlantID,MachineID,
ComponentID,OperationNo,
OperatorID,Prod_Qty,
CO_StdMachiningTime,CO_StdLoadUnload,
Price,SubOperation,AcceptedParts,LastAggrStart
)'
SELECT @StrSql= @StrSql
+ ' SELECT T.Mdate,T.Mshift,PlantMachine.PlantID,T.Amachine, componentinformation.componentid,
componentoperationpricing.operationno, EmployeeInformation.EmployeeID,
CAST(CEILING(CAST(Sum(autodata.PartsCount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer ) as opn,
(componentoperationpricing.machiningtime),(componentoperationpricing.CycleTime - componentoperationpricing.machiningtime),
componentoperationpricing.Price,componentoperationpricing.SubOperations,
CAST(CEILING(CAST(Sum(autodata.PartsCount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer )
,max(T.LastAggstart)
FROM autodata
INNER JOIN EmployeeInformation ON autodata.Opr=EmployeeInformation.InterfaceID
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID
inner join #TempMCOODown T on T.Amachine=machineinformation.Machineid
LEFT OUTER JOIN PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
INNER JOIN  componentinformation ON autodata.comp = componentinformation.InterfaceID
INNER JOIN componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID) AND (componentinformation.componentid = componentoperationpricing.componentid)
WHERE autodata.ndtime > '''+Convert(NvarChar(20),@StartTime,120)+''' AND autodata.ndtime <='''+Convert(NvarChar(20),@EndTime,120)+'''  AND (autodata.datatype = 1)'
SELECT @StrSql = @StrSql+@strPlantID
SELECT @StrSql = @StrSql + ' and autodata.mStTime >= T.LastAggstart '
SELECT @StrSql = @StrSql+'GROUP BY  T.Mdate,T.Mshift,PlantMachine.PlantID,T.Amachine,componentinformation.componentid, componentoperationpricing.operationno, EmployeeInformation.EmployeeID,
componentoperationpricing.cycletime, componentoperationpricing.machiningtime , componentoperationpricing.SubOperations,
componentoperationpricing.LoadUnload,componentoperationpricing.Price' */
---select * from #TempShiftProductionDetails
---mod 11
/**********************************Get Planned Downtimes defined for the machines at shift level********************************/
insert into #PlannedDownTimes(StartTime ,EndTime ,MachineId ,MachineInterface,Sdate ,ShiftStart ,ShiftEnd,ShiftName)
select CASE When StartTime<T1.MShiftStart Then T1.MShiftStart Else StartTime End,
case When EndTime>T1.MShiftEnd Then T1.MShiftEnd Else EndTime End,
Planneddowntimes.Machine,M.Interfaceid,T1.Mdate,T1.MShiftStart,T1.MShiftEnd,T1.MShift
from Planneddowntimes inner join Machineinformation M on M.MachineId=Planneddowntimes.Machine
inner join  #TempMCOODown T1  on T1.AMachine=Planneddowntimes.Machine
WHERE PDTstatus =1 and (
(StartTime >= T1.MShiftStart  AND EndTime <=T1.MShiftEnd)
OR ( StartTime < T1.MShiftStart  AND EndTime <= T1.MShiftEnd AND EndTime > T1.MShiftStart )
OR ( StartTime >= T1.MShiftStart   AND StartTime <T1.MShiftEnd AND EndTime > T1.MShiftEnd )
OR ( StartTime < T1.MShiftStart  AND EndTime > T1.MShiftEnd) )
ORDER BY Machine,StartTime
/******************************************************************************************************************/


---mod 11
/**************************************************************************************************************/
/* FOLLOWING SECTION IS ADDED BY SANGEETA KALLUR
*/
/* commented for Mod 3
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
From ProductionCountException Ex
Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID
WHERE  Ex.MachineID  in ( '+  @machineid + ')  AND M.MultiSpindleFlag=1 AND
((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''' )
OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''')
OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime)+''')
OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' ))' */


---Get the production count exception defines for the selected period
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID,ComponentID,OperationNo,StartTime,EndTime,IdealCount,ActualCount,ExCount
,ExDate,ExShift,EXShiftStart,ExShiftEnd,ExLastAggrStart)
SELECT Ex.MachineID,Ex.ComponentID,Ex.OperationNo,StartTime,EndTime,IdealCount,ActualCount,0 ,
T.pDate,T.Shift,T.PShiftStart,T.PShiftEnd,T.LastAggrStart
From ProductionCountException Ex
Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
---mod 5
SELECT @StrSql= @StrSql
+ ' and M.machineid = O.machineid '
---mod 5
SELECT @StrSql= @StrSql
+ ' inner join(select distinct pDate,Shift,PShiftStart,PShiftEnd,MachineID,
ComponentID,OperationNo,LastAggrStart from    #TempShiftProductionDetails ) as T on T.MachineID=Ex.Machineid
and T.ComponentID=Ex.ComponentID and T.OperationNo=Ex.OperationNo
WHERE
M.MultiSpindleFlag=1 AND
((Ex.StartTime >=  T.PShiftStart AND Ex.EndTime <= T.PShiftEnd )
OR (Ex.StartTime < T.PShiftStart AND Ex.EndTime > T.PShiftStart AND Ex.EndTime <= T.PShiftEnd)
OR(Ex.StartTime >= T.PShiftStart AND Ex.EndTime > T.PShiftEnd AND Ex.StartTime < T.PShiftEnd)
OR(Ex.StartTime < T.PShiftStart AND Ex.EndTime > T.PShiftEnd ))'
---print @strsql
Exec (@strsql)
IF ( SELECT Count(*) from #Exceptions ) <> 0
BEGIN
--UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime
--UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )
UPDATE #Exceptions SET StartTime=EXShiftStart WHERE (StartTime<EXShiftStart)AND EndTime>EXShiftStart
UPDATE #Exceptions SET EndTime=ExShiftEnd WHERE (EndTime>ExShiftEnd AND StartTime<ExShiftEnd )
Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
(
SELECT T1.Edate as Edate,T1.Eshift as Eshift,T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
From (
select Tt1.ExDate as Edate,Tt1.ExShift as Eshift,Tt1.EXShiftStart as Eshiftst,
Tt1.ExShiftEnd as Eshiftnd,MachineInformation.MachineID,ComponentInformation.ComponentID,
ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,
Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata autodata ----ER0202 
Inner Join MachineInformation ON autodata.MC = MachineInformation.InterfaceID
Inner Join EmployeeInformation E ON autodata.Opr = E.InterfaceID
Inner Join ComponentInformation ON autodata.Comp = ComponentInformation.InterfaceID
Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID
And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
---mod 5
SELECT @StrSql= @StrSql
+ ' and MachineInformation.machineid = componentoperationpricing.machineid '
---mod 5
--inner join --(SELECT DISTINCT pDate,Shift,PShiftStart,PShiftEnd,MACHINEID,COMPONENTID,OPERATIONNO,LastAggrStart FROM #TempShiftProductionDetails) AS  Tm on  Tm.Machineid=MachineInformation.MachineID
--and Tm.componentid=ComponentInformation.ComponentID and Tm.OperationNo=ComponentOperationPricing.OperationNo
--and
SELECT @StrSql= @StrSql
+ ' Inner Join (
Select ExDate,ExShift,EXShiftStart,ExShiftEnd,ExLastAggrStart,MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
and Tt1.Machineid=ComponentOperationPricing.MachineID
Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1)
and autodata.msttime>=Tt1.ExLastAggrStart '
--Select @StrSql = @StrSql+ @strMachine
Select @StrSql = @StrSql+' Group by Tt1.ExDate,Tt1.ExShift,Tt1.EXShiftStart,Tt1.ExShiftEnd,MachineInformation.MachineID,
ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn '
Select @StrSql = @StrSql + ' ) as T1
  
Inner join componentinformation C on T1.Comp=C.interfaceid
  
Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
---mod 5
Select @StrSql = @StrSql+' Inner join machineinformation on machineinformation.machineid=T1.machineid  and O.Machineid=machineinformation.machineid '
---mod 5
Select @StrSql = @StrSql+' GROUP BY T1.Edate,T1.Eshift,T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
)AS T2
WHERE  T2.Edate=#Exceptions.ExDate and T2.Eshift=#Exceptions.ExShift and  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
print @StrSql
Exec(@StrSql)
IF (SELECT ValueInText From CockpitDefaults Where Parameter='Ignore_Count_4m_PLD')='Y'
BEGIN
Select @StrSql =''
Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
From
(
SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
T2.Exdate AS Edate,T2.EXShiftStart AS EshiftStart,
SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
From
(
select MachineInformation.MachineID,C.ComponentID,O.OperationNo,comp,opn,
T1.XStartTime as StartTime,T1.XEndTime as EndTime,T1.PLD_StartTime,T1.PLD_EndTime,T1.ExDate as ExDate,T1.EXShiftStart as EXShiftStart,
Sum(ISNULL(PartsCount,1))AS OrginalCount
from #T_autodata  A ----ER0202 
Inner Join MachineInformation   ON A.MC=MachineInformation.InterfaceID
--Inner Join EmployeeInformation   ON A.Opr=EmployeeInformation.InterfaceID
Inner Join ComponentInformation  C ON A.Comp = C.InterfaceID
Inner Join ComponentOperationPricing O on A.Opn=O.InterfaceID And C.ComponentID=O.ComponentID
Inner Join
 
(
SELECT Ex.MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
CASE
WHEN (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime) THEN Ex.StartTime
WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.StartTime
ELSE Td.StartTime
END AS PLD_StartTime,
CASE
WHEN (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime) THEN Ex.EndTime
WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.EndTime
ELSE  Td.EndTime
END AS PLD_EndTime,EX.EXShiftStart as EXShiftStart,Ex.ExShiftEnd as ExShiftEnd,Ex.ExDate as ExDate
From #Exceptions AS Ex CROSS JOIN #PlannedDownTimes AS Td
Where Td.MachineID=Ex.MachineID and ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'
Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = C.ComponentID AND T1.OperationNo= O.OperationNo
and T1.MachineID=O.MachineID
Where (A.ndtime>T1.PLD_StartTime AND A.ndtime<=T1.PLD_EndTime) and (A.datatype=1)
AND (A.ndtime >T1.EXShiftStart AND A.ndtime<=T1.ExShiftEnd )'
Select @StrSql = @StrSql +  @StrMachine
Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,C.ComponentID,O.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,T1.XStartTime,T1.XEndTime,T1.ExDate,T1.EXShiftStart,comp,opn
)AS T2
Inner join componentinformation C on T2.Comp=C.interfaceid
Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid
GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime,T2.Exdate,T2.EXShiftStart
)AS T3
WHERE  T3.Edate=#Exceptions.ExDate and T3.EshiftStart=#Exceptions.EXShiftStart and  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'
--PRINT @StrSql
EXEC(@StrSql)
END

UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
--select * from #Exceptions
---print 'update ex'
UPDATE #TempShiftProductionDetails SET AcceptedParts=ISNULL(AcceptedParts,0)-ISNULL(DummyC,0),
Dummy_Cycles = ISNULL(DummyC,0)
FROM
(
SELECT #TempShiftProductionDetails.pDate,#TempShiftProductionDetails.Shift,#TempShiftProductionDetails.MachineID,
#TempShiftProductionDetails.Componentid,#TempShiftProductionDetails.OperationNo,#TempShiftProductionDetails.OperatorID,
---mod 7
#TempShiftProductionDetails.WorkOrderNumber as WorkOrderNumber,#TempShiftProductionDetails.PJCYear,
---mod 7
(AcceptedParts*(Ti.Ratio))As DummyC FROM #TempShiftProductionDetails LEFT OUTER JOIN
(SELECT #Exceptions.ExDate as EDate,#Exceptions.ExShift as Eshift,#Exceptions.MachineID,#Exceptions.Componentid,
#Exceptions.OperationNo,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
FROM #Exceptions  Inner Join (
SELECT pDate,Shift,PShiftStart,PShiftEnd,MachineID,Componentid,OperationNo,SUM(AcceptedParts)AS tCount
FROM #TempShiftProductionDetails ---WHERE pDate=@Date And Shift=@Shift ---AND MachineID in (@MachineID)
Group By  pDate,Shift,PShiftStart,PShiftEnd,MachineID,Componentid,OperationNo
)T1 ON T1.MachineID=#Exceptions.MachineID AND T1.Componentid=#Exceptions.Componentid AND T1.OperationNo=#Exceptions.OperationNo
and T1.Pdate=#Exceptions.ExDate and T1.Shift=#Exceptions.ExShift
Group By  #Exceptions.ExDate,#Exceptions.ExShift,#Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo
)AS Ti ON #TempShiftProductionDetails.MachineID =Ti.MachineID AND  #TempShiftProductionDetails.Componentid=Ti.Componentid AND #TempShiftProductionDetails.OperationNo=Ti.OperationNo
WHERE #TempShiftProductionDetails.pDate=Ti.EDate And #TempShiftProductionDetails.Shift=Ti.Eshift ---AND #TempShiftProductionDetails.MachineID in ( @MachineID )
)As Tm Inner Join #TempShiftProductionDetails ON
#TempShiftProductionDetails.pDate       =Tm.pDate
   AND
#TempShiftProductionDetails.Shift
   =Tm.Shift       AND
#TempShiftProductionDetails.MachineID   =Tm.MachineID   AND
#TempShiftProductionDetails.Componentid =Tm.Componentid AND
#TempShiftProductionDetails.OperationNo =Tm.OperationNo AND
#TempShiftProductionDetails.OperatorID  =Tm.OperatorID
---mod 7
and #TempShiftProductionDetails.WorkOrderNumber = Tm.WorkOrderNumber
AND #TempShiftProductionDetails.PJCYear=Tm.PJCYear
---mod 7
END
--print 'maxmin'
/***************************************************************************************************************/
-- select * from #TempShiftProductionDetails
-- Type 1/2 ::Calculate Actual Cutting Time for Speed Ratio.
-- Type 1/2 ::Calculate Actual LoadUnload Time for Load Ratio.
---Commented below query for mod 11
/*UPDATE #TempShiftProductionDetails SET
ActMachiningTime_Type12 = isnull(ActMachiningTime_Type12,0) + isNull(t2.Cycle,0),
ActLoadUnload_Type12 = isnull(ActLoadUnload_Type12,0) + isNull(t2.LoadUnload,0),
MaxMachiningTime=Isnull(T2.MaxCycleTime,0),
MinMachiningTime=Isnull(T2.MinCycleTime,0),
MaxLoadUnloadTime=Isnull(T2.MaxLoadUnload,0),
MinLoadUnloadTime=Isnull(T2.MinLoadUnload,0)
from
(select   T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
sum(A.cycletime) as Cycle,sum(A.loadunload) as LoadUnload,
Max(Isnull(A.cycletime,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MaxCycleTime,
Min(Isnull(A.cycletime,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MinCycleTime,
Max(Isnull(A.LoadUnload,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MaxLoadUnload,
Min(Isnull(A.LoadUnload,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MinLoadUnload
---mod 7
,T.WorkOrderNumber as WorkOrderNumber
---mod 7
from autodata A
INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
---mod 5
and M.machineid = O.machineid
---mod 5
Inner join #TempShiftProductionDetails T on
T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
where (A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart)
---mod 7
and A.WorkOrderNumber = T.WorkOrderNumber
---mod 7
---mod 9 consider records with partscount >0
and A.partscount>0
---mod 9
group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
---mod 7
,T.WorkOrderNumber
---mod 7
) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
   And t2.COpr=#TempShiftProductionDetails.OperatorID
---mod 7
AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
---mod 7*/
---mod 11


--------------------------ER0202
--SELECT @StrSql=''
--SELECT @StrSql=  'UPDATE #TempShiftProductionDetails SET
--MaxMachiningTime=Isnull(T2.MaxCycleTime,0),
--MinMachiningTime=Isnull(T2.MinCycleTime,0),
--MaxLoadUnloadTime=Isnull(T2.MaxLoadUnload,0),
--MinLoadUnloadTime=Isnull(T2.MinLoadUnload,0)
--from
--(select   T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
--Max(Isnull(A.cycletime,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MaxCycleTime,
--Min(Isnull(A.cycletime,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MinCycleTime,
--Max(Isnull(A.LoadUnload,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MaxLoadUnload,
--Min(Isnull(A.LoadUnload,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MinLoadUnload
--,T.WorkOrderNumber as WorkOrderNumber
--from autodata A
--INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
--INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
--INNER JOIN componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
--and M.machineid = O.machineid
--Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
--where (A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart)
--and A.WorkOrderNumber = T.WorkOrderNumber
--and A.partscount>0 '
--SELECT @StrSql=@StrSql + @Qparam1
--SELECT @StrSql=@StrSql +' group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
--,T.WorkOrderNumber
 
--) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
--And t2.CShift=#TempShiftProductionDetails.Shift
--And t2.CMachine = #TempShiftProductionDetails.MachineID
--And t2.CComponent=#TempShiftProductionDetails.Componentid
--And t2.COpnNo=#TempShiftProductionDetails.OperationNo
--And t2.COpr=#TempShiftProductionDetails.OperatorID
--AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber '
--EXEC (@StrSql)

SELECT @StrSql=''
SELECT @StrSql=  'UPDATE #TempShiftProductionDetails SET
MaxMachiningTime=Isnull(T2.MaxCycleTime,0),
MinMachiningTime=Isnull(T2.MinCycleTime,0),
MaxLoadUnloadTime=Isnull(T2.MaxLoadUnload,0),
MinLoadUnloadTime=Isnull(T2.MinLoadUnload,0)
from
(select   T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
Max(Isnull(A.cycletime,0)/Isnull(A.PartsCount,1))* Avg(Isnull(T.SubOperation,1)) As MaxCycleTime,
Min(Isnull(A.cycletime,0)/Isnull(A.PartsCount,1))* Avg(Isnull(T.SubOperation,1)) As MinCycleTime,
Max(Isnull(A.LoadUnload,0)/Isnull(A.PartsCount,1))* Avg(Isnull(T.SubOperation,1)) As MaxLoadUnload,
Min(Isnull(A.LoadUnload,0)/Isnull(A.PartsCount,1))* Avg(Isnull(T.SubOperation,1)) As MinLoadUnload
,T.WorkOrderNumber as WorkOrderNumber,T.PJCYear
from #T_autodata A ----ER0202 
Inner join #TempShiftProductionDetails T on
T.Minterface=A.mc and T.Cinterface=A.comp and T.Opninterface=A.opn and T.OprInterface=A.opr and A.WorkOrderNumber = T.WorkOrderNumber and A.PJCYear=T.PJCYear
where (A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart)
and A.partscount>0 '
SELECT @StrSql=@StrSql + @Qparam1
SELECT @StrSql=@StrSql +' group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
,T.WorkOrderNumber,T.PJCYear
 
) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
AND T2.PJCYear=#TempShiftProductionDetails.PJCYear'
EXEC (@StrSql)
----------------------------------------------ER0202

------------------------------------------ER0202
--SELECT @StrSql=''
--SELECT @StrSql=  'UPDATE #TempShiftProductionDetails SET
--ActMachiningTime_Type12 = isnull(ActMachiningTime_Type12,0) + isNull(t2.Cycle,0),
--ActLoadUnload_Type12 = isnull(ActLoadUnload_Type12,0) + isNull(t2.LoadUnload,0)
--from
--(select   T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
--sum(A.cycletime) as Cycle,sum(A.loadunload) as LoadUnload
--,T.WorkOrderNumber as WorkOrderNumber
--from autodata A
--INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
--INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
--INNER JOIN componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
--and M.machineid = O.machineid
--Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
--where (A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart)
--and A.WorkOrderNumber = T.WorkOrderNumber
--and A.partscount>0 '
--SELECT @StrSql=@StrSql + @Qparam2
--SELECT @StrSql=@StrSql +' group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
--,T.WorkOrderNumber
 
--) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
--And t2.CShift=#TempShiftProductionDetails.Shift
--And t2.CMachine = #TempShiftProductionDetails.MachineID
--And t2.CComponent=#TempShiftProductionDetails.Componentid
--And t2.COpnNo=#TempShiftProductionDetails.OperationNo
--And t2.COpr=#TempShiftProductionDetails.OperatorID
 
--AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber '
--EXEC (@StrSql)
-----mod 11

SELECT @StrSql=''
SELECT @StrSql=  'UPDATE #TempShiftProductionDetails SET
ActMachiningTime_Type12 = isnull(ActMachiningTime_Type12,0) + isNull(t2.Cycle,0),
ActLoadUnload_Type12 = isnull(ActLoadUnload_Type12,0) + isNull(t2.LoadUnload,0)
from
(select   T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
sum(A.cycletime) as Cycle,sum(A.loadunload) as LoadUnload
,T.WorkOrderNumber as WorkOrderNumber,T.PJCYear
from #T_autodata A ---ER0202 
Inner join #TempShiftProductionDetails T on
T.Minterface=A.mc and T.Cinterface=A.comp and T.Opninterface=A.opn and T.OprInterface=A.opr and A.WorkOrderNumber = T.WorkOrderNumber and A.PJCYear=T.PJCYear
where (A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart)
and A.WorkOrderNumber = T.WorkOrderNumber AND A.PJCYear=T.PJCYear
and A.partscount>0 '
SELECT @StrSql=@StrSql + @Qparam2
SELECT @StrSql=@StrSql +' group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
,T.WorkOrderNumber,T.PJCYear
 
) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
AND T2.PJCYear=#TempShiftProductionDetails.PJCYear'
EXEC (@StrSql)
---mod 11

------------------------------------ER0202


------------------------------------ER0202
/***************************************Utilised time Calculation begins***********************************/
---- To calculate Utilised Time
--UPDATE #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
--from
--(select    T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
--sum(case when (A.msttime>=T.PShiftStart and A.ndtime<=T.PShiftEnd) then  A.cycletime + A.LoadUnload
  
--when (A.msttime<T.PShiftStart and A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd) then DateDiff(second, T.PShiftStart, ndtime)
--when (A.msttime>=T.PShiftStart and A.msttime<T.PShiftEnd and A.ndtime>T.PShiftEnd) then DateDiff(second, mstTime, T.PShiftEnd)
--when (A.msttime<T.PShiftStart and A.ndtime>T.PShiftEnd)then DateDiff(second, T.PShiftStart, T.PShiftEnd) End) as Cycle
--,T.WorkOrderNumber as WorkOrderNumber
--from autodata A
--INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
--INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
--INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid) and M.MachineID=O.MachineID
--Inner join #TempShiftProductionDetails T on
--A.mc= T.Minterface and A.comp=T.Cinterface and T.Opninterface=A.opn and A.Opr=T.OprInterface
--where ((A.msttime>=T.PShiftStart and A.ndtime<=T.PShiftEnd)
--or (A.msttime<T.PShiftStart and A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd)
--or (A.msttime>=T.PShiftStart and A.msttime<T.PShiftEnd and A.ndtime>T.PShiftEnd)
--or (A.msttime<T.PShiftStart and A.ndtime>T.PShiftEnd) )
--and A.datatype=1 and A.msttime>=T.LastAggrStart
--and A.WorkOrderNumber = T.WorkOrderNumber
--group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
--,T.WorkOrderNumber
--) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
--And t2.CShift=#TempShiftProductionDetails.Shift
--And t2.CMachine = #TempShiftProductionDetails.MachineID
--And t2.CComponent=#TempShiftProductionDetails.Componentid
--And t2.COpnNo=#TempShiftProductionDetails.OperationNo
--And t2.COpr=#TempShiftProductionDetails.OperatorID
--AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber

-- To calculate Utilised Time
UPDATE #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
from
(select    T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
sum(case when (A.msttime>=T.PShiftStart and A.ndtime<=T.PShiftEnd) then  A.cycletime + A.LoadUnload
when (A.msttime<T.PShiftStart and A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd) then DateDiff(second, T.PShiftStart, ndtime)
when (A.msttime>=T.PShiftStart and A.msttime<T.PShiftEnd and A.ndtime>T.PShiftEnd) then DateDiff(second, mstTime, T.PShiftEnd)
when (A.msttime<T.PShiftStart and A.ndtime>T.PShiftEnd)then DateDiff(second, T.PShiftStart, T.PShiftEnd) End) as Cycle
,T.WorkOrderNumber as WorkOrderNumber,T.PJCYear
from #T_autodata A ---ER0202 
Inner join #TempShiftProductionDetails T on
A.mc= T.Minterface and A.comp=T.Cinterface and T.Opninterface=A.opn and A.Opr=T.OprInterface and A.WorkOrderNumber = T.WorkOrderNumber AND A.PJCYear=T.PJCYear
where ((A.msttime>=T.PShiftStart and A.ndtime<=T.PShiftEnd)
or (A.msttime<T.PShiftStart and A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd)
or (A.msttime>=T.PShiftStart and A.msttime<T.PShiftEnd and A.ndtime>T.PShiftEnd)
or (A.msttime<T.PShiftStart and A.ndtime>T.PShiftEnd) )
and A.datatype=1 and A.msttime>=T.LastAggrStart

group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
,T.WorkOrderNumber,T.PJCYear
) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
AND T2.PJCYear=#TempShiftProductionDetails.PJCYear
---------------------------------------ER0202




/*-- Type 1
UPDATE #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
from
(select    T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
sum(A.cycletime + A.LoadUnload) as Cycle
---mod 7
,T.WorkOrderNumber as WorkOrderNumber
---mod 7
from autodata A
--INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
--INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
--INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
A.mc= T.Minterface and A.comp=T.Cinterface and T.Opninterface=A.opn and A.Opr=T.OprInterface
where (A.msttime>=T.PShiftStart and A.ndtime<=T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart )
---mod 7
and A.WorkOrderNumber = T.WorkOrderNumber
---mod 7
group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
---mod 7
,T.WorkOrderNumber
---mod 7
) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
---mod 7
AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
---mod 7
-- Type 2
UPDATE #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
from
(select   T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
SUM(DateDiff(second, T.PShiftStart, ndtime)) as Cycle
---mod 7
,T.WorkOrderNumber as WorkOrderNumber
---mod 7
from autodata A
--INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
--INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
--INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
A.mc= T.Minterface and A.comp=T.Cinterface and T.Opninterface=A.opn and A.Opr=T.OprInterface
where A.msttime<T.PShiftStart and A.ndtime>T.PShiftStart and A.ndtime<=T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart
---mod 7
and A.WorkOrderNumber = T.WorkOrderNumber
---mod 7
group by  T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
---mod 7
,T.WorkOrderNumber
---mod 7
) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
---mod 7
AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
---mod 7
-- Type 3
UPDATE #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
from
(select    T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
SUM(DateDiff(second, mstTime, T.PShiftEnd)) as Cycle
---mod 7
,T.WorkOrderNumber as WorkOrderNumber
---mod 7
from autodata A
--INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
--INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
--INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
A.mc= T.Minterface and A.comp=T.Cinterface and T.Opninterface=A.opn and A.Opr=T.OprInterface
where A.msttime>=T.PShiftStart and A.msttime<T.PShiftEnd and A.ndtime>T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart
---mod 7
and A.WorkOrderNumber = T.WorkOrderNumber
---mod 7
group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
---mod 7
,T.WorkOrderNumber
---mod 7
) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
---mod 7
AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
---mod 7
-- Type 4
UPDATE #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
from
(select   T.pDate AS CDate,T.Shift AS CShift, T.Machineid AS CMachine,T.componentid AS CComponent,T.OperationNo AS COpnNo,T.OperatorID AS COpr,
SUM(DateDiff(second, T.PShiftStart, T.PShiftEnd)) as Cycle
---mod 7
,T.WorkOrderNumber as WorkOrderNumber
---mod 7
from autodata A
--INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
--INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
---INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
A.mc= T.Minterface and A.comp=T.Cinterface and T.Opninterface=A.opn and A.Opr=T.OprInterface
where  A.msttime<T.PShiftStart and A.ndtime>T.PShiftEnd and A.datatype=1 and A.msttime>=T.LastAggrStart
---mod 7
and A.WorkOrderNumber = T.WorkOrderNumber
---mod 7
group by T.pDate,T.Shift,T.Machineid,T.componentid,T.OperationNo ,T.OperatorID
---mod 7
,T.WorkOrderNumber
---mod 7
) as t2 inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
---mod 7
AND t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
---mod 7
---select 'util'
---select * from #TempShiftProductionDetails where shift='third'
*/
/* Incylce Down */
/* If Down Records of TYPE-2*/
/*Select T1.Pdate AS CDate,T1.IShift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,
O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
SUM(
CASE
When A1.sttime <= T1.shftStart Then datediff(s, T1.shftStart,A1.ndtime )
When A1.sttime > T1.shftStart Then datediff(s , A1.sttime,A1.ndtime)
END) as Down
From AutoData A1 INNER Join
(Select T.pDate AS PDate,T.Shift AS IShift,T.PShiftStart as shftStart,T.PShiftEnd as shiftend,
mc,Comp,Opn,Opr,sttime,NdTime
From AutoData A
Inner Join MachineInformation M on A.mc=M.Interfaceid
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND
(C.componentid = O.componentid)
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
Inner join #TempShiftProductionDetails T on
T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo
and T.OperatorID=E.EmployeeID
Where DataType=1 And DateDiff(Second,sttime,ndtime)>A.CycleTime And
(sttime < T.PShiftStart And ndtime > T.PShiftStart AND ndtime <= T.PShiftEnd)
and A.msttime>=T.LastAggrStart  )
as T1 ON A1.mc=T1.mc And A1.Comp=T1.Comp And A1.Opn=T1.Opn And A1.Opr=T1.Opr
Inner Join MachineInformation M on A1.mc=M.Interfaceid
INNER JOIN  componentinformation C ON A1.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A1.opn = O.InterfaceID) AND (C.componentid = O.componentid)
INNER JOIN EmployeeInformation E ON A1.Opr=E.InterfaceID
 
Where A1.DataType=2
And  A1.Sttime > T1.Sttime And  A1.ndtime < T1.ndtime  AND  A1.ndtime > T1.shftStart
GROUP BY T1.Pdate,T1.IShift,M.Machineid,C.componentid,O.OperationNo,E.EmployeeID
RETURN*/


/********************* ER0202 Commented
--print 'icd'
Insert into #ICD
---mod 7
-- (Idate,IShift,IShiftStart,IShiftEnd,Imc,Icomp,Iopn,Iopr,Isttime,Indtime)
(Idate,IShift,IShiftStart,IShiftEnd,Imc,Icomp,Iopn,Iopr,Isttime,Indtime,WorkOrderNumber)
---mod 7
Select T.pDate AS PDate,T.Shift AS IShift,T.PShiftStart as shftStart,T.PShiftEnd as shiftend,
mc,Comp,Opn,Opr,sttime,NdTime
---mod 7
,T.WorkOrderNumber
---mod 7
From AutoData A
Inner Join MachineInformation M on A.mc=M.Interfaceid
INNER JOIN componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
---mod 5
and M.machineid = O.machineid
---mod 5
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
Inner join #TempShiftProductionDetails T on
T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo
and T.OperatorID=E.EmployeeID
Where DataType=1 And DateDiff(Second,sttime,ndtime)>A.CycleTime And
(msttime < T.PShiftStart And ndtime > T.PShiftStart AND ndtime <= T.PShiftEnd)
and A.msttime>=T.LastAggrStart
---mod 7
and A.WorkOrderNumber = T.WorkOrderNumber
---mod 7
ER0202***************************************/


--ER0202 Added TO Get All Production Records Which Contains ICD
Insert into #ICD
---mod 7
-- (Idate,IShift,IShiftStart,IShiftEnd,Imc,Icomp,Iopn,Iopr,Isttime,Indtime)
(Idate,IShift,IShiftStart,IShiftEnd,Imc,Icomp,Iopn,Iopr,Imsttime,Isttime,Indtime,WorkOrderNumber,PJCYear)
---mod 7
Select T.pDate AS PDate,T.Shift AS IShift,T.PShiftStart as shftStart,T.PShiftEnd as shiftend,
mc,Comp,Opn,Opr,msttime,sttime,NdTime
---mod 7
,T.WorkOrderNumber,T.PJCYear
---mod 7
From #T_autodata A --ER0202 
Inner Join MachineInformation M on A.mc=M.Interfaceid
INNER JOIN componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
---mod 5
and M.machineid = O.machineid
---mod 5
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
Inner join #TempShiftProductionDetails T on
T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo
and T.OperatorID=E.EmployeeID
Where DataType=1 And DateDiff(Second,sttime,ndtime)>A.CycleTime And
((msttime >= T.PShiftStart)And (ndtime <= T.PShiftEnd) or (msttime < T.PShiftStart And ndtime > T.PShiftStart AND ndtime <= T.PShiftEnd)
or(msttime >= T.PShiftStart And ndtime > T.PShiftEnd AND msttime < T.PShiftEnd)
or (msttime < T.PShiftStart And ndtime > T.PShiftEnd))
and A.msttime>=T.LastAggrStart
---mod 7
and A.WorkOrderNumber = T.WorkOrderNumber
AND A.PJCYear=T.PJCYear
---mod 7
--ER0202


/*ER0202 Type 2
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
FROM
(select  T1.Idate AS CDate,T1.IShift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,
O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
---mod 7
T1.WorkOrderNumber,
---mod 7
sum(CASE
When A1.sttime <= IShiftStart Then datediff(s, IShiftStart,A1.ndtime )
When A1.sttime > IShiftStart Then datediff(s , A1.sttime,A1.ndtime)
END) as Down  FROM #ICD  T1 inner join autodata A1 on A1.mc=T1.Imc and A1.comp=T1.Icomp and A1.opn=T1.Iopn
and A1.opr=T1.Iopr
Inner Join MachineInformation M on A1.mc=M.Interfaceid
INNER JOIN  componentinformation C ON A1.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A1.opn = O.InterfaceID) AND (C.componentid = O.componentid)
---mod 5
and M.machineid = O.machineid
---mod 5
INNER JOIN EmployeeInformation E ON A1.Opr=E.InterfaceID
where A1.datatype=2 and A1.sttime>T1.Isttime and A1.ndtime<T1.Indtime
and A1.ndtime>T1.IShiftStart
---mod 7
and A1.WorkOrderNumber = T1.WorkOrderNumber
---mod 7
Group by T1.Idate,T1.IShift,M.Machineid,C.componentid ,O.OperationNo ,E.EmployeeID
---mod 7
,T1.WorkOrderNumber
---mod 7
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift = #TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
---mod 7
and t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
---mod 7
ER0202*/


--ER0202 ICD Records Of TYPE2
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
FROM
(select  T1.Idate AS CDate,T1.IShift AS CShift, T1.Imc as CMachine,T1.Icomp as CComponent,
T1.Iopn AS COpnNo,T1.Iopr AS COpr,T1.WorkOrderNumber,T1.PJCYear,
sum(CASE
When A1.sttime <= IShiftStart Then datediff(s, IShiftStart,A1.ndtime )
When A1.sttime > IShiftStart Then datediff(s , A1.sttime,A1.ndtime)
END) as Down  FROM 
	(
	Select I.Icomp,I.Iopn,I.iopr,I.Imc,I.Isttime,I.Indtime,I.IShiftEnd,I.IShiftStart,I.WorkOrderNumber,I.PJCYear,I.Idate,I.IShift From #ICD I
	Inner join #TempShiftProductionDetails T on I.Idate=T.pDate And I.IShift = T.Shift And I.Imc = T.Minterface And I.Icomp=T.Cinterface And I.Iopn=T.Opninterface 
	And I.Iopr=T.OprInterface and I.WorkOrderNumber = T.WorkOrderNumber	  AND I.PJCYear=T.PJCYear
	Where (I.Imsttime < T.PShiftStart)And (I.Indtime > T.PShiftStart) AND (I.Indtime <= T.PShiftEnd)
	)  T1 
inner join #T_autodata A1 on A1.mc=T1.Imc and A1.comp=T1.Icomp and A1.opn=T1.Iopn and A1.opr=T1.Iopr and A1.WorkOrderNumber=T1.WorkOrderNumber AND A1.PJCYear=T1.PJCYear -----ER0202 
where A1.datatype=2 and (A1.sttime>T1.Isttime and A1.ndtime<T1.Indtime and A1.ndtime>T1.IShiftStart)
Group by T1.Idate,T1.IShift,T1.Imc,T1.Icomp,T1.Iopn,T1.Iopr,T1.WorkOrderNumber,T1.PJCYear
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift = #TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.Minterface
And t2.CComponent=#TempShiftProductionDetails.Cinterface
And t2.COpnNo=#TempShiftProductionDetails.Opninterface
And t2.COpr=#TempShiftProductionDetails.OprInterface
and t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
AND T2.PJCYear=#TempShiftProductionDetails.PJCYear
--ER0202



/*uncom UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
FROM
(Select T1.Pdate AS CDate,T1.IShift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,
O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
SUM(
CASE
When A1.sttime <= T1.shftStart Then datediff(s, T1.shftStart,A1.ndtime )
When A1.sttime > T1.shftStart Then datediff(s , A1.sttime,A1.ndtime)
END) as Down  FROM (
Select T.pDate AS PDate,T.Shift AS IShift,T.PShiftStart as shftStart,T.PShiftEnd as shiftend,
mc,Comp,Opn,Opr,sttime,NdTime
From AutoData A
Inner Join MachineInformation M on A.mc=M.Interfaceid
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND
(C.componentid = O.componentid)
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
Inner join #TempShiftProductionDetails T on
T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo
and T.OperatorID=E.EmployeeID
Where DataType=1 And DateDiff(Second,sttime,ndtime)>A.CycleTime And
(sttime < T.PShiftStart And ndtime > T.PShiftStart AND ndtime <= T.PShiftEnd)
and A.msttime>=T.LastAggrStart) AS t1
   INNER JOIN AUTODATA A1 ON  A1.mc=T1.mc And A1.Comp=T1.Comp And A1.Opn=T1.Opn And A1.Opr=T1.Opr
Inner Join MachineInformation M on A1.mc=M.Interfaceid
INNER JOIN  componentinformation C ON A1.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A1.opn = O.InterfaceID) AND (C.componentid = O.componentid)
INNER JOIN EmployeeInformation E ON A1.Opr=E.InterfaceID
 
Where A1.DataType=2 and   A1.Sttime > T1.Sttime And  A1.ndtime <  T1.ndtime  AND  A1.ndtime >  T1.shftStart  
 
GROUP BY T1.Pdate,T1.IShift,M.Machineid,C.componentid,O.OperationNo,E.EmployeeID
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
return uncom*/



/* ER0202
/* If Down Records of TYPE-3*/
--select 'type 3'
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
FROM
(Select T1.Pdate AS CDate,T1.IShift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
SUM(
CASE
When A1.ndtime > T1.shiftend Then datediff(s,A1.sttime, T1.shiftend )
When A1.ndtime <=T1.shiftend Then datediff(s , A1.sttime,A1.ndtime)
END) as Down
---mod 7
,T1.WorkOrderNumber as WorkOrderNumber
---mod 7
From AutoData A1 INNER Join
(Select T.pDate AS PDate,T.Shift AS IShift,T.PShiftStart as shftStart,T.PShiftEnd as shiftend,
mc,Comp,Opn,Opr,Sttime,NdTime
---mod 7
,A.WorkOrderNumber
---mod 7
From AutoData A
Inner Join MachineInformation M on A.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
---mod 5
and M.machineid = O.machineid
---mod 5
Inner join #TempShiftProductionDetails T on
T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
---mod 7
and A.WorkOrderNumber = T.WorkOrderNumber
---mod 7
Where DataType=1 And DateDiff(Second,sttime,ndtime)>A.CycleTime And
(sttime >= T.PShiftStart)And   (sttime<T.PShiftEnd) and (ndtime > T.PShiftEnd) and A.msttime>=T.LastAggrStart  ) as T1
ON A1.mc=T1.mc And A1.Comp=T1.Comp And A1.Opn=T1.Opn And A1.Opr=T1.Opr
Inner Join MachineInformation M on A1.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON A1.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A1.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A1.opn = O.InterfaceID) AND (C.componentid = O.componentid)
---mod 5
and M.machineid = O.machineid
---mod 5
Where A1.DataType=2
And (T1.Sttime < A1.sttime  )And ( T1.ndtime >  A1.ndtime) AND (A1.sttime  <  T1.shiftend)
---mod 7
and A1.WorkOrderNumber = T1.WorkOrderNumber
---mod 7
GROUP BY T1.Pdate,T1.IShift,M.Machineid,C.componentid,O.OperationNo,E.EmployeeID
---mod 7
,T1.WorkOrderNumber
---mod 7
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
---mod 7
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
---mod 7
ER0202*/

--ER0202 ICD Records of TYPE3
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
FROM
(select  T1.Idate AS CDate,T1.IShift AS CShift, T1.Imc as CMachine,T1.Icomp as CComponent,
T1.Iopn AS COpnNo,T1.Iopr AS COpr,T1.WorkOrderNumber,T1.PJCYear,
SUM(
CASE
When A1.ndtime > T1.IShiftEnd Then datediff(s,A1.sttime, T1.IShiftEnd )
When A1.ndtime <=T1.IShiftEnd Then datediff(s , A1.sttime,A1.ndtime)
END) as Down  FROM 
	(
	Select I.Icomp,I.Iopn,I.iopr,I.Imc,I.Isttime,I.Indtime,I.IShiftEnd,I.IShiftStart,I.WorkOrderNumber,I.PJCYear,I.Idate,I.IShift From #ICD I
	Inner join #TempShiftProductionDetails T on I.Idate=T.pDate And I.IShift = T.Shift And I.Imc = T.Minterface And I.Icomp=T.Cinterface And I.Iopn=T.Opninterface 
	And I.Iopr=T.OprInterface and I.WorkOrderNumber = T.WorkOrderNumber	AND I.PJCYear=T.PJCYear  
	Where (I.Isttime >= T.PShiftStart)And (I.Indtime > T.PShiftEnd) and (I.Isttime<T.PShiftEnd)
	)  T1 
inner join #T_autodata A1 on A1.mc=T1.Imc and A1.comp=T1.Icomp and A1.opn=T1.Iopn and A1.opr=T1.Iopr and A1.WorkOrderNumber=T1.WorkOrderNumber AND A1.PJCYear=T1.PJCYear ---ER0202 
where A1.datatype=2 and (T1.Isttime < A1.sttime  )And ( T1.Indtime >  A1.ndtime) AND (A1.sttime  <  T1.	IShiftEnd)
Group by T1.Idate,T1.IShift,T1.Imc,T1.Icomp,T1.Iopn,T1.Iopr,T1.WorkOrderNumber,T1.PJCYear
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift = #TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.Minterface
And t2.CComponent=#TempShiftProductionDetails.Cinterface
And t2.COpnNo=#TempShiftProductionDetails.Opninterface
And t2.COpr=#TempShiftProductionDetails.OprInterface
and t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
AND T2.PJCYear=#TempShiftProductionDetails.PJCYear
--ER0202


/*ER0202
/* If Down Records of TYPE-4*/
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
FROM
(Select T1.Pdate AS CDate,T1.IShift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
SUM(
CASE
 
--mod 13 :: From Here
-- When A1.sttime < T1.shftStart AND A1.ndtime<=T1.shiftend Then datediff(s, T1.shftStart,A1.ndtime )
-- When A1.ndtime > T1.shiftend AND A1.sttime>T1.shftStart Then datediff(s,A1.sttime, T1.shiftend )
-- When A1.sttime >= T1.shftStart AND A1.ndtime <= T1.shiftend Then datediff(s , A1.sttime,A1.ndtime)
-- When A1.sttime<T1.shftStart AND A1.ndtime>T1.shiftend   Then datediff(s , T1.shftStart,T1.shiftend)
When A1.sttime >= T1.shftStart AND A1.ndtime<=T1.shiftend Then datediff(s , A1.sttime,A1.ndtime)
When A1.sttime < T1.shftStart AND A1.ndtime<=T1.shiftend and A1.ndtime > T1.shftStart  Then datediff(s, T1.shftStart,A1.ndtime )
When A1.sttime>=T1.shftStart AND  A1.sttime<T1.shiftend and A1.ndtime > T1.shiftend  Then datediff(s,A1.sttime, T1.shiftend )
When A1.sttime<T1.shftStart AND A1.ndtime>T1.shiftend Then datediff(s , T1.shftStart,T1.shiftend)
--mod 13 :: Till Here
END) as Down
---mod 7
,T1.WorkOrderNumber as WorkOrderNumber
---mod 7
From
(Select T.pDate AS PDate,T.Shift AS IShift,T.PShiftStart as shftStart,T.PShiftEnd as shiftend,
mc,Comp,Opn,Opr,Sttime,NdTime
---mod 7
,A.WorkOrderNumber
---mod 7
From AutoData A
Inner Join MachineInformation M on A.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
---mod 5
and M.machineid = O.machineid
---mod 5
Inner join #TempShiftProductionDetails T on
T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
Where DataType=1 And DateDiff(Second,sttime,ndtime)>A.CycleTime And
---mod 7
T.WorkOrderNumber = A.WorkOrderNumber and
---mod 7
(Msttime < T.PShiftStart)And (ndtime > T.PShiftEnd) and A.Msttime>=T.LastAggrStart  )
as T1 INNER Join  AutoData A1 ON A1.mc=T1.mc And A1.Comp=T1.Comp And A1.Opn=T1.Opn And A1.Opr=T1.Opr
 
Inner Join MachineInformation M on A1.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON A1.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A1.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A1.opn = O.InterfaceID) AND (C.componentid = O.componentid)
---mod 5
and M.machineid = O.machineid
---mod 5
Where A1.DataType=2
And (T1.Sttime < A1.Msttime  )And ( T1.ndtime >  A1.ndtime) AND (A1.ndtime  >  T1.shftStart)AND (A1.Msttime  <  T1.shiftend)
---mod 7
and A1.WorkOrderNumber = T1.WorkOrderNumber
---mod 7
GROUP BY T1.Pdate,T1.IShift,M.Machineid,C.componentid,O.OperationNo,E.EmployeeID
---mod 7
,T1.WorkOrderNumber
---mod 7
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
---mod 7
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
---mod 7
*/

--ER0202 ICD Records of TYPE4
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
FROM
(select  T1.Idate AS CDate,T1.IShift AS CShift, T1.Imc as CMachine,T1.Icomp as CComponent,
T1.Iopn AS COpnNo,T1.Iopr AS COpr,T1.WorkOrderNumber,T1.PJCYear,
SUM(
CASE
When A1.sttime >= T1.IShiftStart AND A1.ndtime<=T1.IShiftEnd Then datediff(s , A1.sttime,A1.ndtime)
When A1.sttime < T1.IShiftStart AND A1.ndtime<=T1.IShiftEnd and A1.ndtime > T1.IShiftStart  Then datediff(s, T1.IShiftStart,A1.ndtime )
When A1.sttime>=T1.IShiftStart AND  A1.sttime<T1.IShiftEnd and A1.ndtime > T1.IShiftEnd  Then datediff(s,A1.sttime, T1.IShiftEnd )
When A1.sttime<T1.IShiftStart AND A1.ndtime>T1.IShiftEnd Then datediff(s , T1.IShiftStart,T1.IShiftEnd)
END) as Down  FROM 
	(
	Select I.Icomp,I.Iopn,I.iopr,I.Imc,I.Isttime,I.Indtime,I.IShiftEnd,I.IShiftStart,I.WorkOrderNumber,i.PJCYear,I.Idate,I.IShift From #ICD I
	Inner join #TempShiftProductionDetails T on I.Idate=T.pDate And I.IShift = T.Shift And I.Imc = T.Minterface And I.Icomp=T.Cinterface And I.Iopn=T.Opninterface 
	And I.Iopr=T.OprInterface and I.WorkOrderNumber = T.WorkOrderNumber	 and I.PJCYear=T.PJCYear 
	--Where (I.Imsttime < T.PShiftStart)And (I.Indtime > T.PShiftEnd) ---ER0202 
	Where (I.Isttime < T.PShiftStart)And (I.Indtime > T.PShiftEnd) ----ER0202 
	)  T1 
inner join #T_autodata A1 on A1.mc=T1.Imc and A1.comp=T1.Icomp and A1.opn=T1.Iopn and A1.opr=T1.Iopr and A1.WorkOrderNumber=T1.WorkOrderNumber AND A1.PJCYear=T1.PJCYear ----ER0202 
where A1.datatype=2 and (T1.Isttime < A1.Msttime  )And ( T1.Indtime >  A1.ndtime) AND (A1.ndtime  >  T1.IShiftStart)AND (A1.Msttime  <  T1.IShiftEnd)
Group by T1.Idate,T1.IShift,T1.Imc,T1.Icomp,T1.Iopn,T1.Iopr,T1.WorkOrderNumber,T1.PJCYear
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift = #TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.Minterface
And t2.CComponent=#TempShiftProductionDetails.Cinterface
And t2.COpnNo=#TempShiftProductionDetails.Opninterface
And t2.COpr=#TempShiftProductionDetails.OprInterface
and t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
AND T2.PJCYear=#TempShiftProductionDetails.PJCYear
--ER0202


---mod 11 : Remove times from utilised time overlapping with PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
--Production Time in PDT
--UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.PPDT,0)
--FROM(
--SELECT
--T.Sdate AS CDate,T.ShiftName as CShift,T.MachineId AS CMachine,C.componentid AS CComponent,
--O.OperationNo AS COpnNo,E.EmployeeID AS COpr,A.WorkOrderNumber as WorkOrderNumber,
--SUM(CASE
----WHEN A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime+A.loadunload) --DR0325 Commented
--WHEN A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.msttime,A.ndtime) --DR0325 Added
--WHEN ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
--WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
--WHEN ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
--END)  as PPDT,
--T1.PShiftStart as PShiftStart,T1.PShiftEnd  as PShiftEnd --DR0322 Added
--FROM AutoData A
--INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
--INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
--INNER JOIN componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid) and (M.MachineID=O.MachineID)
--Inner join #TempShiftProductionDetails T1 on  A.mc= T1.Minterface and A.comp=T1.Cinterface and T1.Opninterface=A.opn and A.Opr=T1.OprInterface --DR0322 Added Line
--inner  jOIN #PlannedDownTimes T on T.MachineInterface=A.Mc
--WHERE A.DataType=1  AND 
--(
--(A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
--OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
--OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
--OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
--and A.msttime>=T1.LastAggrStart --DR0322 Added Line
--group by T.Sdate,T.ShiftName,T.MachineId,C.componentid,O.OperationNo ,E.EmployeeID,A.WorkOrderNumber
--,T1.PShiftStart,T1.PShiftEnd --DR0322 Added Line
--)AS T2 
--Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
--And t2.CShift=#TempShiftProductionDetails.Shift
--AND t2.PShiftStart=#TempShiftProductionDetails.PShiftStart and t2.PShiftEnd=#TempShiftProductionDetails.PShiftEnd --DR0322 Added Line
--And t2.CMachine = #TempShiftProductionDetails.MachineID
--And t2.CComponent=#TempShiftProductionDetails.Componentid
--And t2.COpnNo=#TempShiftProductionDetails.OperationNo
--And t2.COpr=#TempShiftProductionDetails.OperatorID
--And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber



UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.PPDT,0),PDT=ISNULL(PDT,0)+isNull(t2.PPDT,0)
FROM(
SELECT
T.Sdate AS CDate,T.ShiftName as CShift,T1.Minterface AS CMachine,T1.Cinterface AS CComponent,
T1.Opninterface AS COpnNo,T1.OprInterface AS COpr,T1.WorkOrderNumber as WorkOrderNumber,T1.PJCYear,
SUM(CASE
WHEN A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime+A.loadunload) --DR0325 Commented --ER0202
--WHEN A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.msttime,A.ndtime) --DR0325 Added --ER0202
WHEN ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
WHEN ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
END)  as PPDT,
T1.PShiftStart as PShiftStart,T1.PShiftEnd  as PShiftEnd --DR0322 Added
FROM #T_autodata A --ER0202 
--INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
--INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
--INNER JOIN componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid) and (M.MachineID=O.MachineID)
Inner join #TempShiftProductionDetails T1 on  A.mc= T1.Minterface and A.comp=T1.Cinterface and T1.Opninterface=A.opn and A.Opr=T1.OprInterface
and A.WorkOrderNumber=T1.workordernumber and A.PJCYear=t1.PJCYear --DR0322 Added Line
inner  jOIN #PlannedDownTimes T on T.MachineInterface=A.Mc and T.Sdate=T1.pDate and T.shiftname=T1.Shift
WHERE A.DataType=1  AND 
(
(A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) ) 
and A.msttime>=T1.LastAggrStart --DR0322 Added Line
group by T.Sdate,T.ShiftName,T1.Minterface,T1.Cinterface,T1.Opninterface,T1.OprInterface,T1.WorkOrderNumber,T1.PJCYear
,T1.PShiftStart,T1.PShiftEnd --DR0322 Added Line
)AS T2 
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
And t2.CShift=#TempShiftProductionDetails.Shift
AND t2.PShiftStart=#TempShiftProductionDetails.PShiftStart and t2.PShiftEnd=#TempShiftProductionDetails.PShiftEnd --DR0322 Added Line
And t2.CMachine = #TempShiftProductionDetails.Minterface
And t2.CComponent=#TempShiftProductionDetails.Cinterface
And t2.COpnNo=#TempShiftProductionDetails.Opninterface
And t2.COpr=#TempShiftProductionDetails.OprInterface
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
and T2.PJCYear=#TempShiftProductionDetails.PJCYear



/* ER0202 Commented From Here
---mod 11:Add ICD's Overlapping  with PDT to UtilisedTime
---mod 11(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.IPDT,0)
FROM( SELECT
T.Sdate AS CDate,T.ShiftName as CShift,T.MachineId AS CMachine,C.componentid AS CComponent,
O.OperationNo AS COpnNo,E.EmployeeID AS COpr,autodata.WorkOrderNumber as WorkOrderNumber,
SUM(
CASE 
When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
END) as IPDT
,T.shiftstart as shiftstart,T.shiftend as shiftend --DR0322 added
From AutoData INNER Join
(Select T.pDate AS PDate,T.Shift AS IShift,T.PShiftStart as shftStart,T.PShiftEnd as shiftend,
mc,Comp,Opn,Opr,Sttime,NdTime,A.WorkOrderNumber
From AutoData A
Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
T.Minterface=A.mc and T.Cinterface=A.comp and T.Opninterface=A.opn and T.OprInterface=A.opr
and T.WorkOrderNumber = A.WorkOrderNumber
Where DataType=1 And DateDiff(Second,sttime,ndtime)>A.CycleTime And
(msttime >= T.PShiftStart)And  (ndtime <=T.PShiftEnd) and A.msttime>=T.LastAggrStart
) as T1
ON autodata.mc=T1.mc And autodata.Comp=T1.Comp And autodata.Opn=T1.Opn And autodata.Opr=T1.Opr
and autodata.WorkOrderNumber=T1.WorkOrderNumber
Inner Join MachineInformation M on autodata.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON autodata.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON autodata.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (autodata.opn = O.InterfaceID) AND (C.componentid = O.componentid)
and (M.machineid = O.machineid) inner join  #PlannedDownTimes T on T.MachineInterface=autodata.Mc and
T.Sdate=T1.Pdate and T.Shiftname=T1.IShift 
and T.ShiftStart=T1.shftStart and T.shiftend=T1.shiftend --DR0322 added Line
Where AutoData.DataType=2
And ((autodata.Sttime > T1.Sttime) And (autodata.ndtime <T1.ndtime) )
And ((autodata.sttime >= T.StartTime and autodata.ndtime <=T.EndTime)
    OR (autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime)
    OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime)
    OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime))
Group by T.Sdate,T.ShiftName,T.MachineId,C.componentid,O.OperationNo ,E.EmployeeID,autodata.WorkOrderNumber
,T.shiftstart,T.shiftend --DR0322 Added
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
AND t2.shiftstart=#TempShiftProductionDetails.PShiftStart and t2.shiftend=#TempShiftProductionDetails.PShiftend --DR0322 added
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber

/* If production  Records of TYPE-2*/
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.IPDT,0)
FROM( SELECT
T.Sdate AS CDate,T.ShiftName as CShift,T.MachineId AS CMachine,C.componentid AS CComponent,
O.OperationNo AS COpnNo,E.EmployeeID AS COpr,autodata.WorkOrderNumber as WorkOrderNumber,
SUM(
CASE 
When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
END) as IPDT
,T.shiftstart as shiftstart,T.shiftend as shiftend --DR0322 added
From AutoData INNER Join
(Select T.pDate AS PDate,T.Shift AS IShift,T.PShiftStart as shftStart,T.PShiftEnd as shiftend,
mc,Comp,Opn,Opr,Sttime,NdTime,A.WorkOrderNumber
From AutoData A
Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
T.Minterface=A.mc and T.Cinterface=A.comp and T.Opninterface=A.opn and T.OprInterface=A.opr
and T.WorkOrderNumber = A.WorkOrderNumber
Where DataType=1 And DateDiff(Second,sttime,ndtime)>A.CycleTime And
(msttime < T.PShiftStart)And  (ndtime >T.PShiftStart ) and (ndtime<=T.PShiftEnd) and A.msttime>=T.LastAggrStart
) as T1
ON autodata.mc=T1.mc And autodata.Comp=T1.Comp And autodata.Opn=T1.Opn And autodata.Opr=T1.Opr
and autodata.WorkOrderNumber=T1.WorkOrderNumber
Inner Join MachineInformation M on autodata.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON autodata.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON autodata.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (autodata.opn = O.InterfaceID) AND (C.componentid = O.componentid)
and (M.machineid = O.machineid) inner join  #PlannedDownTimes T on T.MachineInterface=autodata.Mc and
T.Sdate=T1.Pdate and T.Shiftname=T1.IShift
and T.ShiftStart=T1.shftStart and T.shiftend=T1.shiftend --DR0322 added Line
Where AutoData.DataType=2
And ((autodata.Sttime > T1.Sttime) And (autodata.ndtime <T1.ndtime) and autodata.ndtime >T1.shftStart )
And ((autodata.sttime >= T.StartTime and autodata.ndtime <=T.EndTime)
    OR (autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime)
    OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime)
    OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime))
AND
(( T.StartTime >= T1.shftStart )
And ( T.StartTime <  T1.ndtime ) )
Group by T.Sdate,T.ShiftName,T.MachineId,C.componentid,O.OperationNo ,E.EmployeeID,autodata.WorkOrderNumber
,T.shiftstart,T.shiftend --DR0322 Added
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
AND t2.shiftstart=#TempShiftProductionDetails.PShiftStart and t2.shiftend=#TempShiftProductionDetails.PShiftend --DR0322 added
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber


/* If production  Records of TYPE-3*/
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.IPDT,0)
FROM( SELECT
T.Sdate AS CDate,T.ShiftName as CShift,T.MachineId AS CMachine,C.componentid AS CComponent,
O.OperationNo AS COpnNo,E.EmployeeID AS COpr,autodata.WorkOrderNumber as WorkOrderNumber,
SUM(
CASE 
When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
END) as IPDT
,T.shiftstart as shiftstart,T.shiftend as shiftend --DR0322 added
From AutoData INNER Join
(Select T.pDate AS PDate,T.Shift AS IShift,T.PShiftStart as shftStart,T.PShiftEnd as shiftend,
mc,Comp,Opn,Opr,Sttime,NdTime,A.WorkOrderNumber
From AutoData A
Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
T.Minterface=A.mc and T.Cinterface=A.comp and T.Opninterface=A.opn and T.OprInterface=A.opr
and T.WorkOrderNumber = A.WorkOrderNumber
Where DataType=1 And DateDiff(Second,sttime,ndtime)>A.CycleTime And
(sttime >=T.PShiftStart)And  (sttime <T.PShiftEnd ) and (ndtime>T.PShiftEnd) and A.msttime>=T.LastAggrStart
) as T1
ON autodata.mc=T1.mc And autodata.Comp=T1.Comp And autodata.Opn=T1.Opn And autodata.Opr=T1.Opr
and autodata.WorkOrderNumber=T1.WorkOrderNumber
Inner Join MachineInformation M on autodata.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON autodata.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON autodata.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (autodata.opn = O.InterfaceID) AND (C.componentid = O.componentid)
and (M.machineid = O.machineid) inner join  #PlannedDownTimes T on T.MachineInterface=autodata.Mc and
T.Sdate=T1.Pdate and T.Shiftname=T1.IShift
and T.ShiftStart=T1.shftStart and T.shiftend=T1.shiftend --DR0322 added Line
Where AutoData.DataType=2
And ((autodata.Sttime > T1.Sttime) And (autodata.ndtime <T1.ndtime) and  (autodata.sttime< T1.shiftend) )
And ((autodata.sttime >= T.StartTime and autodata.ndtime <=T.EndTime)
    OR (autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime)
    OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime)
    OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime))
AND
(( T.EndTime > T1.Sttime )
And ( T.EndTime <=T1.shiftend ) )
Group by T.Sdate,T.ShiftName,T.MachineId,C.componentid,O.OperationNo ,E.EmployeeID,autodata.WorkOrderNumber
,T.shiftstart,T.shiftend --DR0322 Added
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
AND t2.shiftstart=#TempShiftProductionDetails.PShiftStart and t2.shiftend=#TempShiftProductionDetails.PShiftend --DR0322 added
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber


/* If production  Records of TYPE-4*/
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.IPDT,0)
FROM( SELECT
T.Sdate AS CDate,T.ShiftName as CShift,T.MachineId AS CMachine,C.componentid AS CComponent,
O.OperationNo AS COpnNo,E.EmployeeID AS COpr,autodata.WorkOrderNumber as WorkOrderNumber,
SUM(
CASE 
When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
END) as IPDT
,T.shiftstart as shiftstart,T.shiftend as shiftend --DR0322 added
From AutoData INNER Join
(Select T.pDate AS PDate,T.Shift AS IShift,T.PShiftStart as shftStart,T.PShiftEnd as shiftend,
mc,Comp,Opn,Opr,Sttime,NdTime,A.WorkOrderNumber
From AutoData A
Inner join #TempShiftProductionDetails T on
--T.Machineid=M.Machineid and T.Componentid=C.Componentid and T.OperationNo=O.OperationNo and T.OperatorID=E.EmployeeID
T.Minterface=A.mc and T.Cinterface=A.comp and T.Opninterface=A.opn and T.OprInterface=A.opr
and T.WorkOrderNumber = A.WorkOrderNumber
Where DataType=1 And DateDiff(Second,sttime,ndtime)>A.CycleTime And
(msttime <T.PShiftStart) And  (ndtime>T.PShiftEnd) and A.msttime>=T.LastAggrStart
) as T1
ON autodata.mc=T1.mc And autodata.Comp=T1.Comp And autodata.Opn=T1.Opn And autodata.Opr=T1.Opr
and autodata.WorkOrderNumber=T1.WorkOrderNumber
Inner Join MachineInformation M on autodata.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON autodata.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON autodata.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (autodata.opn = O.InterfaceID) AND (C.componentid = O.componentid)
and (M.machineid = O.machineid) inner join  #PlannedDownTimes T on T.MachineInterface=autodata.Mc and
T.Sdate=T1.Pdate and T.Shiftname=T1.IShift
and T.ShiftStart=T1.shftStart and T.shiftend=T1.shiftend --DR0322 added Line
Where AutoData.DataType=2
And ((autodata.Sttime > T1.Sttime) And (autodata.ndtime <T1.ndtime)  AND (autodata.ndtime  >T1.shftStart)AND (autodata.sttime  < T1.shiftend) )
And ((autodata.sttime >= T.StartTime and autodata.ndtime <=T.EndTime)
    OR (autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime)
    OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime)
    OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime))
AND
(( T.StartTime >=T1.shftStart)
And ( T.EndTime <=T1.shiftend ) )
Group by T.Sdate,T.ShiftName,T.MachineId,C.componentid,O.OperationNo ,E.EmployeeID,autodata.WorkOrderNumber
,T.shiftstart,T.shiftend --DR0322 Added
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
AND t2.shiftstart=#TempShiftProductionDetails.PShiftStart and t2.shiftend=#TempShiftProductionDetails.PShiftend --DR0322 added
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.MachineID
And t2.CComponent=#TempShiftProductionDetails.Componentid
And t2.COpnNo=#TempShiftProductionDetails.OperationNo
And t2.COpr=#TempShiftProductionDetails.OperatorID
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
ER0202*/


----------------------------------------------ER0202
---mod 11:Add ICD's Overlapping  with PDT to UtilisedTime
---mod 11(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.IPDT,0),PDT=ISNULL(PDT,0)-isNull(t2.IPDT,0)
FROM( SELECT
T1.Idate AS CDate,T1.IShift as CShift,T1.Imc AS CMachine,T1.Icomp AS CComponent,
T1.Iopn AS COpnNo,T1.Iopr AS COpr,T1.WorkOrderNumber as WorkOrderNumber,T1.PJCYear,
SUM(
CASE 
When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
END) as IPDT
,T1.IShiftStart as shiftstart,T1.IShiftEnd as shiftend --DR0322 added
From #T_autodata AutoData INNER Join ----ER0202 
	(
	Select I.Icomp,I.Iopn,I.iopr,I.Imc,I.Isttime,I.Indtime,I.IShiftEnd,I.IShiftStart,I.WorkOrderNumber,I.PJCYear,I.Idate,I.IShift From #ICD I
	Inner join #TempShiftProductionDetails T on I.Idate=T.pDate And I.IShift = T.Shift And I.Imc = T.Minterface And I.Icomp=T.Cinterface And I.Iopn=T.Opninterface 
	And I.Iopr=T.OprInterface and I.WorkOrderNumber = T.WorkOrderNumber	 AND I.PJCYear=T.PJCYear
	Where (I.Imsttime >= T.PShiftStart)And (I.Indtime <= T.PShiftEnd)
	)  T1 
ON autodata.mc=T1.Imc And autodata.Comp=T1.Icomp And autodata.Opn=T1.IOpn And autodata.Opr=T1.IOpr and autodata.WorkOrderNumber=T1.WorkOrderNumber AND autodata.PJCYear=T1.PJCYear
inner join  #PlannedDownTimes T on T.MachineInterface=autodata.Mc and T.Sdate=T1.Idate and T.Shiftname=T1.IShift and T.ShiftStart=T1.IShiftStart and T.shiftend=T1.IShiftEnd
Where AutoData.DataType=2
And ((autodata.Sttime > T1.Isttime) And (autodata.ndtime <T1.Indtime) )
And ((autodata.sttime >= T.StartTime and autodata.ndtime <=T.EndTime)
    OR (autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime)
    OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime)
    OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime))
Group by T1.Idate,T1.IShift,T1.Imc,T1.Icomp,T1.Iopn,T1.Iopr,T1.WorkOrderNumber,T1.PJCYear,T1.IShiftStart,T1.IShiftEnd
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
AND t2.shiftstart=#TempShiftProductionDetails.PShiftStart and t2.shiftend=#TempShiftProductionDetails.PShiftend --DR0322 added
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.Minterface
And t2.CComponent=#TempShiftProductionDetails.Cinterface
And t2.COpnNo=#TempShiftProductionDetails.Opninterface
And t2.COpr=#TempShiftProductionDetails.OprInterface
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
AND T2.PJCYear=#TempShiftProductionDetails.PJCYear

/* If production  Records of TYPE-2*/
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.IPDT,0),PDT=ISNULL(PDT,0)-isNull(t2.IPDT,0)
FROM( SELECT
T1.Idate AS CDate,T1.IShift as CShift,T1.Imc AS CMachine,T1.Icomp AS CComponent,
T1.Iopn AS COpnNo,T1.Iopr AS COpr,T1.WorkOrderNumber as WorkOrderNumber,T1.PJCYear,
SUM(
CASE 
When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
END) as IPDT
,T1.IShiftStart as shiftstart,T1.IShiftEnd as shiftend --DR0322 added
From #T_autodata AutoData INNER Join ---ER0202 
	(
	Select I.Icomp,I.Iopn,I.iopr,I.Imc,I.Isttime,I.Indtime,I.IShiftEnd,I.IShiftStart,I.WorkOrderNumber,I.PJCYear,I.Idate,I.IShift From #ICD I
	Inner join #TempShiftProductionDetails T on I.Idate=T.pDate And I.IShift = T.Shift And I.Imc = T.Minterface And I.Icomp=T.Cinterface And I.Iopn=T.Opninterface 
	And I.Iopr=T.OprInterface and I.WorkOrderNumber = T.WorkOrderNumber	AND I.PJCYear=T.PJCYear  
	Where(I.imsttime < T.PShiftStart)And  (I.Indtime >T.PShiftStart ) and (i.indtime<=T.PShiftEnd)
	)  T1 
ON autodata.mc=T1.imc And autodata.Comp=T1.iComp And autodata.Opn=T1.iOpn And autodata.Opr=T1.iOpr and autodata.WorkOrderNumber=T1.WorkOrderNumber and autodata.PJCYear=t1.PJCYear
inner join  #PlannedDownTimes T on T.MachineInterface=autodata.Mc and T.Sdate=T1.idate and T.Shiftname=T1.IShift and T.ShiftStart=T1.IShiftStart and T.shiftend=T1.ishiftend --DR0322 added Line
Where AutoData.DataType=2
And ((autodata.Sttime > T1.Isttime) And (autodata.ndtime <T1.Indtime) and autodata.ndtime >T1.IShiftStart )
And ((autodata.sttime >= T.StartTime and autodata.ndtime <=T.EndTime)
    OR (autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime)
    OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime)
    OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime))
AND
(( T.StartTime >= T1.IShiftStart ) And ( T.StartTime <  T1.IShiftEnd ))
Group by T1.Idate,T1.IShift,T1.Imc,T1.Icomp,T1.Iopn,T1.Iopr,T1.WorkOrderNumber,t1.PJCYear,T1.IShiftStart,T1.IShiftEnd
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
AND t2.shiftstart=#TempShiftProductionDetails.PShiftStart and t2.shiftend=#TempShiftProductionDetails.PShiftend --DR0322 added
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.Minterface
And t2.CComponent=#TempShiftProductionDetails.Cinterface
And t2.COpnNo=#TempShiftProductionDetails.Opninterface
And t2.COpr=#TempShiftProductionDetails.OprInterface
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
and t2.PJCYear=#TempShiftProductionDetails.PJCYear


/* If production  Records of TYPE-3*/
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.IPDT,0),PDT=ISNULL(PDT,0)-isNull(t2.IPDT,0)
FROM( SELECT
T1.Idate AS CDate,T1.IShift as CShift,T1.Imc AS CMachine,T1.Icomp AS CComponent,
T1.Iopn AS COpnNo,T1.Iopr AS COpr,T1.WorkOrderNumber as WorkOrderNumber,T1.PJCYear,
SUM(
CASE 
When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
END) as IPDT
,T1.IShiftStart as shiftstart,T1.IShiftEnd as shiftend --DR0322 added
From #T_autodata AutoData INNER Join ---ER0202 
	(
	Select I.Icomp,I.Iopn,I.iopr,I.Imc,I.Isttime,I.Indtime,I.IShiftEnd,I.IShiftStart,I.WorkOrderNumber,I.PJCYear,I.Idate,I.IShift From #ICD I
	Inner join #TempShiftProductionDetails T on I.Idate=T.pDate And I.IShift = T.Shift And I.Imc = T.Minterface And I.Icomp=T.Cinterface And I.Iopn=T.Opninterface 
	And I.Iopr=T.OprInterface and I.WorkOrderNumber = T.WorkOrderNumber	 AND I.PJCYear=T.PJCYear 
	Where (I.isttime >=T.PShiftStart)And  (I.isttime <T.PShiftEnd ) and (I.indtime>T.PShiftEnd)
	)  T1 
ON autodata.mc=T1.imc And autodata.Comp=T1.iComp And autodata.Opn=T1.iOpn And autodata.Opr=T1.iOpr and autodata.WorkOrderNumber=T1.WorkOrderNumber and autodata.PJCYear=T1.PJCYear
inner join  #PlannedDownTimes T on T.MachineInterface=autodata.Mc and T.Sdate=T1.idate and T.Shiftname=T1.IShift and T.ShiftStart=T1.IShiftStart and T.shiftend=T1.IShiftEnd --DR0322 added Line
Where AutoData.DataType=2
And ((autodata.Sttime > T1.Isttime) And (autodata.ndtime <T1.Indtime) and  (autodata.sttime< T1.IShiftEnd) )
And ((autodata.sttime >= T.StartTime and autodata.ndtime <=T.EndTime)
    OR (autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime)
    OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime)
    OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime))
AND
(( T.EndTime > T1.Isttime )
And ( T.EndTime <=T1.IShiftEnd ) )
Group by T1.Idate,T1.IShift,T1.Imc,T1.Icomp,T1.Iopn,T1.Iopr,T1.WorkOrderNumber,T1.PJCYear,T1.IShiftStart,T1.IShiftEnd
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
AND t2.shiftstart=#TempShiftProductionDetails.PShiftStart and t2.shiftend=#TempShiftProductionDetails.PShiftend --DR0322 added
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.Minterface
And t2.CComponent=#TempShiftProductionDetails.Cinterface
And t2.COpnNo=#TempShiftProductionDetails.Opninterface
And t2.COpr=#TempShiftProductionDetails.OprInterface
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
and t2.PJCYear=#TempShiftProductionDetails.PJCYear


/* If production  Records of TYPE-4*/
UPDATE  #TempShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.IPDT,0),PDT=ISNULL(PDT,0)-isNull(t2.IPDT,0)
FROM( SELECT
T1.Idate AS CDate,T1.IShift as CShift,T1.Imc AS CMachine,T1.Icomp AS CComponent,
T1.Iopn AS COpnNo,T1.Iopr AS COpr,T1.WorkOrderNumber as WorkOrderNumber,T1.PJCYear,
SUM(
CASE 
When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
END) as IPDT
,T1.IShiftStart as shiftstart,T1.IShiftEnd as shiftend --DR0322 added
From #T_autodata AutoData INNER Join ---ER0202 
	(
	Select I.Icomp,I.Iopn,I.iopr,I.Imc,I.Isttime,I.Indtime,I.IShiftEnd,I.IShiftStart,I.WorkOrderNumber,I.PJCYear,I.Idate,I.IShift From #ICD I
	Inner join #TempShiftProductionDetails T on I.Idate=T.pDate And I.IShift = T.Shift And I.Imc = T.Minterface And I.Icomp=T.Cinterface And I.Iopn=T.Opninterface 
	And I.Iopr=T.OprInterface and I.WorkOrderNumber = T.WorkOrderNumber	 AND I.PJCYear=T.PJCYear 
	--Where (i.imsttime <T.PShiftStart) And  (i.indtime>T.PShiftEnd) ---ER0202 
	Where (i.isttime <T.PShiftStart) And  (i.indtime>T.PShiftEnd) ---ER0202 
	)  T1 
ON autodata.mc=T1.imc And autodata.Comp=T1.iComp And autodata.Opn=T1.iOpn And autodata.Opr=T1.iOpr and autodata.WorkOrderNumber=T1.WorkOrderNumber and autodata.PJCYear=T1.PJCYear
inner join  #PlannedDownTimes T on T.MachineInterface=autodata.Mc and T.Sdate=T1.idate and T.Shiftname=T1.IShift
and T.ShiftStart=T1.IShiftStart and T.shiftend=T1.IShiftEnd --DR0322 added Line
Where AutoData.DataType=2
And ((autodata.Sttime > T1.Isttime) And (autodata.ndtime <T1.Indtime)  AND (autodata.ndtime  >T1.IShiftStart)AND (autodata.sttime  < T1.IShiftEnd) )
And ((autodata.sttime >= T.StartTime and autodata.ndtime <=T.EndTime)
    OR (autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime)
    OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime)
    OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime))
AND
(( T.StartTime >=T1.IShiftStart)
And ( T.EndTime <=T1.IShiftEnd ) )
Group by T1.Idate,T1.IShift,T1.Imc,T1.Icomp,T1.Iopn,T1.Iopr,T1.WorkOrderNumber,T1.PJCYear,T1.IShiftStart,T1.IShiftEnd
)AS T2
Inner join #TempShiftProductionDetails on t2.CDate=#TempShiftProductionDetails.pDate
AND t2.shiftstart=#TempShiftProductionDetails.PShiftStart and t2.shiftend=#TempShiftProductionDetails.PShiftend --DR0322 added
And t2.CShift=#TempShiftProductionDetails.Shift
And t2.CMachine = #TempShiftProductionDetails.Minterface
And t2.CComponent=#TempShiftProductionDetails.Cinterface
And t2.COpnNo=#TempShiftProductionDetails.Opninterface
And t2.COpr=#TempShiftProductionDetails.OprInterface
And t2.WorkOrderNumber = #TempShiftProductionDetails.WorkOrderNumber
and t2.PJCYear=#TempShiftProductionDetails.PJCYear
----------------------------------------------------------ER0202
END



--select * from #TempMCOODown
--select * from #TempMCOODown2

----ER0349  Added Till Here
--select @StrSql=''
--select @StrSql=' 
--select T.Amachine,T.MShift,T.Mdate,datatype,max(A.msttime),
--case when max(A.ndtime)>T.MShiftEnd then T.MShiftEnd else max(A.ndtime) end ,''' + convert(nvarchar(20),getdate(),120)+'''
--from machineinformation M inner join #TempMCOODown T on T.Amachine=M.machineid
--inner join #T_autodata A on M.interfaceid=A.mc ---SV
----from autodata A inner join machineinformation M
----on M.interfaceid=A.mc
----inner join #TempMCOODown T on T.Amachine=M.machineid
--WHERE
--((A.mStTime>=T.MShiftStart And A.ndTime<=T.MShiftEnd)
--OR(A.mStTime<T.MShiftStart And A.ndTime>T.MShiftStart And A.ndTime<=T.MShiftEnd)
--OR(A.mStTime>=T.MShiftStart And A.mStTime<T.MShiftEnd And A.ndTime>T.MShiftEnd)
--OR(A.mStTime<T.MShiftStart And A.ndTime>T.MShiftEnd) )'
--SELECT @StrSql = @StrSql + ' and A.mStTime >= T.LastAggstart '
----SELECT @StrSql = @StrSql + ' and A.datatype=2 '
-----and M.machineid='''+ @machineid +'''
--select @StrSql=@StrSql + 'group by datatype,T.AMachine,T.MShift,T.Mdate,T.MShiftEnd'
--print @strsql
--exec (@StrSql)


--Declare @AggTrailInsertcount1 as int
--Set @AggTrailInsertcount1 = @@ROWCOUNT


--If @AggTrailInsertcount1 = 0
--Begin

--Select Machineid,Max(endtime) as Endtime Into #LastAggTrail1 from ShiftAggTrail group by Machineid

--Select T.Amachine,T.MShift,T.Mdate,'1',Max(T.MShiftStart),Max(T.MShiftEnd),getdate() from 
--#TempMCOODown T where exists (Select * from #LastAggTrail1 S where T.AMachine=S.Machineid AND Datediff(day,S.Endtime,T.MShiftEnd)>30) 
--group by T.Amachine,T.MShift,T.Mdate
----DR0389 Commented & Added For INAC BRASSS

--End

-- select T.SP_Machineid,T.SR_Shift,T.SR_PDate,'20', T.SDTimestamp,dateadd(s,10,T.SDTimestamp),getdate(),T.recordid from #TempShiftRejection T
-- Inner join ( select SP_Machineid,max(recordid) as recordid from #TempShiftRejection  where  shiftprodid<>'0' group by SP_Machineid,SR_Pdate,SR_Shift)T1 
-- on T.SP_Machineid = T1.SP_Machineid and T.recordid = T1.Recordid

-- select T.SP_Machineid,T.SR_Shift,T.SR_PDate,'25', T.SDTimestamp,dateadd(s,10,T.SDTimestamp),getdate(),T.recordid from #TempShiftRework T
-- Inner join ( select SP_Machineid,max(recordid) as recordid from #TempShiftRework  where  shiftprodid<>'0' group by SP_Machineid,SR_Pdate,SR_Shift)T1 
-- on T.SP_Machineid = T1.SP_Machineid and T.recordid = T1.Recordid




BEGIN TRANSACTION ---ER0202 REMOVED FROM THE TOP AND ADDED BEFORE INSERT STATEMENT

---mod 11
/***************************************Utilised time Calculation Ends***********************************/
---if exists (select * from shiftproductiondetails where Pdate=@Date and shift=@Shift ) --and Machineid in (@MachineID) )
---begin --Select * from #TempShiftProductionDetails
declare @Pshift as nvarchar(50)
declare @Pdate as datetime
declare @PShiftStart as datetime
declare @Plant nvarchar(50)
declare @Machine nvarchar(50)
declare @Component  nvarchar(50)
declare @Operation  integer
declare @OperatorID  nvarchar(50)
---mod 7
declare @WorkOrderNumber nvarchar(50)
declare @PJCYear nvarchar(10)
---mod 7
--geeta added from here
declare @MachinewiseOwner nvarchar(50)
declare @Grpid nvarchar(50) --GNA
declare @mchrrate float

declare @CriticalMachineEnabled bit
--geeta added till here
Declare RptShiftCursor CURSOR FOR
SELECT distinct pDate,Shift,PShiftStart,PlantID,MachineID,
ComponentID,OperationNo,OperatorID
---mod 7
--,WorkOrderNumber --ER0349 Commented
,FormatedWONumber, --ER0349 Added
---mod 7
PJCYear
,MachinewiseOwner ,CriticalMachineEnabled --geeta added
,GroupID --GNA
,mchrrate
from #TempShiftProductionDetails    order by MAchineid,PShiftStart asc
OPEN RptShiftCursor
FETCH NEXT FROM RptShiftCursor INTO @Pdate,@Pshift,@PShiftStart,@Plant,@Machine, @Component, @Operation,@OperatorID
---mod 7
,@WorkOrderNumber,@PJCYear
---mod 7
,@MachinewiseOwner ,@CriticalMachineEnabled --geeta added
,@Grpid --GNA
,@mchrrate

WHILE (@@fetch_status = 0)
 BEGIN
   if exists (select * from shiftproductiondetails where Pdate=@Pdate and shift=@Pshift and Machineid=@Machine
and   Componentid=@Component and operationno=@Operation and operatorID=@OperatorID
---mod 7
and WorkOrderNumber = @WorkOrderNumber and PJCYear=@PJCYear
---mod 7
and (isnull(MachinewiseOwner,'')= isnull(@MachinewiseOwner,'')) and (isnull(CriticalMachineEnabled,'')=isnull(@CriticalMachineEnabled,''))--geeta added
and mchrrate=@mchrrate)
   begin
--select 'In Exist Update'
---If Date,MAchine,comp,opn,operator,shift combination already exists then update it else insert
--update shiftproductiondetails set Prod_Qty=Prod_Qty+T1.Prod , --DR0389 added for InacBrass
update shiftproductiondetails set Prod_Qty=Prod_Qty+ISNULL(T1.Prod,0),-- DR0389 added for InacBrass
AcceptedParts=AcceptedParts+isnull(T1.Accept,0),
Dummy_Cycles=Dummy_Cycles+Isnull(T1.dummyCyc,0),
Sum_of_ActCycleTime=Sum_of_ActCycleTime+isnull(T1.SumAct,0),
ActMachiningTime_Type12=ActMachiningTime_Type12+isnull(T1.ActMAc,0),
ActLoadUnload_Type12=ActLoadUnload_Type12+isnull(T1.ActLoad,0),
MaxMachiningTime=isnull(T1.Maxmac,0),
MinMachiningTime=isnull(T1.MinMac,0),
MaxLoadUnloadTime=isnull(T1.MaxLoad,0),
MinLoadUnloadTime=isnull(T1.MinLoad,0),
PDT=T1.PDT,Finishedoperation=T1.Finishedoperation
from ( select T.Pdate as Pdate,T.Shift as Shift , T.Machineid as Machineid,T.Componentid as Componentid , T.operationno as operationno,
T.operatorID as operatorID,T.Prod_Qty as prod,T.AcceptedParts as Accept,T.Dummy_Cycles as dummyCyc
,T.Sum_of_ActCycleTime as SumAct,T.ActMachiningTime_Type12 as ActMAc,
T.ActLoadUnload_Type12 as ActLoad,
---mod 7
--T.WorkOrderNumber, --ER0349 Commented
T.FormatedWONumber,   --ER0349 Added
---mod 7
--Geeta added
T.MachinewiseOwner,
T.CriticalMachineEnabled,
--geeta added
T.mchrrate,
case when S.MaxMachiningTime>T.MaxMachiningTime then S.MaxMachiningTime
else T.MaxMachiningTime end as Maxmac,
case when S.MinMachiningTime<T.MinMachiningTime then S.MinMachiningTime
else T.MinMachiningTime end as MinMac,
case when S.MaxLoadUnloadTime>T.MaxLoadUnloadTime then S.MaxLoadUnloadTime
else T.MaxLoadUnloadTime end as MaxLoad,
case when S.MinLoadUnloadTime<T.MinLoadUnloadTime then S.MinLoadUnloadTime
else T.MinLoadUnloadTime end as MinLoad,ISNULL(T.PDT,0) as PDT,T.Finishedoperation from #TempShiftProductionDetails T
inner join shiftproductiondetails S on
S.pdate=T.Pdate and S.Shift=T.shift and S.Machineid=T.Machineid and
S.Componentid=T.Componentid and S.operationno=T.operationno and S.operatorID=T.operatorID
Where T.Pdate=@Pdate and T.shift=@Pshift and T.Machineid=@Machine
and   T.Componentid=@Component and T.operationno=@Operation and T.operatorID=@OperatorID
---mod 7
--and  T.WorkOrderNumber = @WorkOrderNumber --ER0349 Commented
and  T.FormatedWONumber = @WorkOrderNumber --ER0349 Added
and T.PJCYear=@PJCYear
---mod 7
--Geeta Added from here
and (isnull(T.MachinewiseOwner,'')= isnull(@MachinewiseOwner,''))
and (isnull(T.CriticalMachineEnabled,'')=isnull(@CriticalMachineEnabled,'')))
-- geeta added till here
as T1
inner join shiftproductiondetails S on S.pdate=T1.Pdate and S.Shift=T1.shift and S.Machineid=T1.Machineid and
S.Componentid=T1.Componentid and S.operationno=T1.operationno and S.operatorID=T1.operatorID
Where S.Pdate=@Pdate and S.shift=@Pshift and S.Machineid=@Machine
and   S.Componentid=@Component and S.operationno=@Operation and S.operatorID=@OperatorID
---mod 7
--and S.WorkOrderNumber = T1.WorkOrderNumber --ER0349 Commented
and S.WorkOrderNumber = T1.FormatedWONumber --ER0349 Added
---mod 7
--geeta added from here
--and S.MachinewiseOwner= T1.MachinewiseOwner
--and S.CriticalMachineEnabled=T1.CriticalMachineEnabled
--and S.mchrrate=T1.mchrrate
--geeta added till here
---mod 4(3)
set @ErrNo=@@ERROR
IF @ErrNo <> 0 GOTO ERROR_HANDLER
---MOD 4(3)
   end
   else
   begin
  
insert shiftproductiondetails (pDate,Shift,PlantID,MachineID,
ComponentID,OperationNo,
OperatorID,Prod_Qty,
Sum_of_ActCycleTime,
Sum_of_ActLoadUnload ,CO_StdMachiningTime ,CO_StdLoadUnload ,
Price ,
SubOperation ,AcceptedParts ,
Dummy_Cycles ,ActMachiningTime_Type12 ,
ActLoadUnload_Type12 ,MaxMachiningTime ,
---mod 7
--MinMachiningTime ,MaxLoadUnloadTime ,MinLoadUnloadTime )
MinMachiningTime ,MaxLoadUnloadTime ,MinLoadUnloadTime,WorkOrderNumber
---mod 7
,MachinewiseOwner ,CriticalMachineEnabled,GroupID,mchrrate,PDT,PJCYear,Finishedoperation)--geeta added --GNA
select pDate,Shift,PlantID,MachineID,
ComponentID,OperationNo,
OperatorID,Prod_Qty,
Sum_of_ActCycleTime,
Sum_of_ActLoadUnload ,CO_StdMachiningTime ,CO_StdLoadUnload ,
Price ,
SubOperation ,AcceptedParts ,
Dummy_Cycles ,ActMachiningTime_Type12 ,
ActLoadUnload_Type12 ,MaxMachiningTime ,
MinMachiningTime ,MaxLoadUnloadTime ,MinLoadUnloadTime
---mod 7
--,WorkOrderNumber --ER0349 Commented
,FormatedWONumber --ER0349 Added
---mod 7
,MachinewiseOwner,CriticalMachineEnabled --geeta added
,GroupID --GNA
,mchrrate,PDT,PJCYear,Finishedoperation
from #TempShiftProductionDetails
Where Pdate=@Pdate and shift=@Pshift and Machineid=@Machine
and   Componentid=@Component and operationno=@Operation and
operatorID=@OperatorID
---mod 7
--and  WorkOrderNumber=@WorkOrderNumber --ER0349 Commented
and  FormatedWONumber=@WorkOrderNumber --ER0349 Added
and PJCYear=@PJCYear
---mod 7
---mod 4(3)
set @ErrNo=@@ERROR
IF @ErrNo <> 0 GOTO ERROR_HANDLER
---MOD 4(3)
   end
  FETCH NEXT FROM RptShiftCursor INTO @Pdate,@Pshift,@PShiftStart,@Plant,@Machine, @Component, @Operation,@OperatorID
  ---mod 7
  ,@WorkOrderNumber,@PJCYear
  ---mod 7
 ,@MachinewiseOwner ,@CriticalMachineEnabled,@Grpid,@mchrrate --geeta added --GNA
 END
close RptShiftCursor
deallocate RptShiftCursor



/*insert shiftproductiondetails (pDate,Shift,PlantID,MachineID,
ComponentID,OperationNo,OperatorID)
select distinct @Date,@Shift,PlantID,machineid,componentid,operationno,operatorid from #TempShiftProductionDetails
where not exists (select distinct PlantID,machineid,componentid,operationno,operatorid from shiftproductiondetails
where Pdate=@Date and shift=@Shift and Machineid in (@MachineID) )*/
/*select distinct machineid+'::'+componentid+'::'+operationno+'::'+operatorID as disset from #TempShiftProductionDetails
where machineid+'::'+componentid+'::'+operationno+'::'+operatorID not exists (
select distinct machineid+'::'+componentid+'::'+operationno+'::'+operatorID
from shiftproductiondetails where Pdate=@Date and shift=@Shift and Machineid in (@MachineID) )*/
---end
--else
--begin
/*insert shiftproductiondetails (pDate,Shift,PlantID,MachineID,
ComponentID,OperationNo,
OperatorID,Prod_Qty,
Sum_of_ActCycleTime,
Sum_of_ActLoadUnload ,CO_StdMachiningTime ,CO_StdLoadUnload ,
Price ,
SubOperation ,AcceptedParts ,
Dummy_Cycles ,ActMachiningTime_Type12 ,
ActLoadUnload_Type12 ,MaxMachiningTime ,
MinMachiningTime ,MaxLoadUnloadTime ,MinLoadUnloadTime )
select pDate,Shift,PlantID,MachineID,
ComponentID,OperationNo,
OperatorID,Prod_Qty,
Sum_of_ActCycleTime,
Sum_of_ActLoadUnload ,CO_StdMachiningTime ,CO_StdLoadUnload ,
Price ,
SubOperation ,AcceptedParts ,
Dummy_Cycles ,ActMachiningTime_Type12 ,
ActLoadUnload_Type12 ,MaxMachiningTime ,
MinMachiningTime ,MaxLoadUnloadTime ,MinLoadUnloadTime from
#TempShiftProductionDetails
end*/
/****************************Coomented for mod 2************************************************
SELECT @StrSql=' Insert into ShiftProductionDetails (
pDate,Shift,PlantID,MachineID,
ComponentID,OperationNo,
OperatorID,Prod_Qty,
CO_StdMachiningTime,CO_StdLoadUnload,
Price,SubOperation,AcceptedParts
)
SELECT '''+Convert(NvarChar(20),@Date)+''','''+@Shift+''',PlantMachine.PlantID,machineinformation.MachineID, componentinformation.componentid,
componentoperationpricing.operationno, EmployeeInformation.EmployeeID,
CAST(CEILING(CAST(Sum(autodata.PartsCount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer ) as opn,
(componentoperationpricing.machiningtime),(componentoperationpricing.CycleTime - componentoperationpricing.machiningtime),
componentoperationpricing.Price,componentoperationpricing.SubOperations,
CAST(CEILING(CAST(Sum(autodata.PartsCount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer )
FROM autodata
INNER JOIN EmployeeInformation ON autodata.Opr=EmployeeInformation.InterfaceID
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID
LEFT OUTER JOIN PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
INNER JOIN  componentinformation ON autodata.comp = componentinformation.InterfaceID
INNER JOIN componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID) AND (componentinformation.componentid = componentoperationpricing.componentid)
WHERE autodata.ndtime > '''+Convert(NvarChar(20),@StartTime)+''' AND autodata.ndtime <='''+Convert(NvarChar(20),@EndTime)+'''  AND (autodata.datatype = 1)'
SELECT @StrSql = @StrSql+@strPlantID+@strMachine
SELECT @StrSql = @StrSql+'GROUP BY  PlantMachine.PlantID,machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno, EmployeeInformation.EmployeeID,
componentoperationpricing.cycletime, componentoperationpricing.machiningtime , componentoperationpricing.SubOperations,
componentoperationpricing.LoadUnload,componentoperationpricing.Price'
--Exec (@StrSql)
print @StrSql
return*/
/**************************************************************************************************************/
/* FOLLOWING SECTION IS ADDED BY SANGEETA KALLUR
*/
/*SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
From ProductionCountException Ex
Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID
WHERE  Ex.MachineID='''+@MachineID+''' AND M.MultiSpindleFlag=1 AND
((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''' )
OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''')
OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime)+''')
OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' ))'
Exec (@strsql)
IF ( SELECT Count(*) from #Exceptions ) <> 0
BEGIN
UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime
UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )
Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
(
SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
From (
select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
Inner Join EmployeeInformation E  ON autodata.Opr=E.InterfaceID
Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID
Inner Join (
Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
Select @StrSql = @StrSql+ @strMachine
Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
) as T1
  
Inner join componentinformation C on T1.Comp=C.interfaceid
  
Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid
 
GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
)AS T2
WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
Exec(@StrSql)
UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
END
UPDATE ShiftProductionDetails SET AcceptedParts=ISNULL(AcceptedParts,0)-ISNULL(DummyC,0),
Dummy_Cycles
= ISNULL(DummyC,0)
FROM
(
SELECT ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.MachineID,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID,(AcceptedParts*(Ti.Ratio))As DummyC
FROM ShiftProductionDetails LEFT OUTER JOIN
(
SELECT #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
FROM #Exceptions  Inner Join (
SELECT MachineID,Componentid,OperationNo,SUM(AcceptedParts)AS tCount
FROM ShiftProductionDetails WHERE pDate=@Date And Shift=@Shift AND MachineID=@MachineID
Group By  MachineID,Componentid,OperationNo
)T1 ON  T1.MachineID=#Exceptions.MachineID AND T1.Componentid=#Exceptions.Componentid AND T1.OperationNo=#Exceptions.OperationNo
Group By  #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo
)AS Ti ON ShiftProductionDetails.MachineID =Ti.MachineID AND  ShiftProductionDetails.Componentid=Ti.Componentid AND ShiftProductionDetails.OperationNo=Ti.OperationNo
WHERE ShiftProductionDetails.pDate=@Date And ShiftProductionDetails.Shift=@Shift AND ShiftProductionDetails.MachineID=@MachineID
)As Tm Inner Join ShiftProductionDetails ON
ShiftProductionDetails.pDate       =Tm.pDate
  AND
ShiftProductionDetails.Shift
  =Tm.Shift       AND
ShiftProductionDetails.MachineID   =Tm.MachineID   AND
ShiftProductionDetails.Componentid =Tm.Componentid AND
ShiftProductionDetails.OperationNo =Tm.OperationNo AND
ShiftProductionDetails.OperatorID  =Tm.OperatorID*/
/***************************************************************************************************************/
/*-- Type 1/2 ::Calculate Actual Cutting Time for Speed Ratio.
-- Type 1/2 ::Calculate Actual LoadUnload Time for Load Ratio.
UPDATE ShiftProductionDetails SET
ActMachiningTime_Type12 = isnull(ActMachiningTime_Type12,0) + isNull(t2.Cycle,0),
ActLoadUnload_Type12 = isnull(ActLoadUnload_Type12,0) + isNull(t2.LoadUnload,0),
MaxMachiningTime=Isnull(T2.MaxCycleTime,0),
MinMachiningTime=Isnull(T2.MinCycleTime,0),
MaxLoadUnloadTime=Isnull(T2.MaxLoadUnload,0),
MinLoadUnloadTime=Isnull(T2.MinLoadUnload,0)
from
(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
sum(A.cycletime) as Cycle,sum(A.loadunload) as LoadUnload,
Max(Isnull(A.cycletime,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MaxCycleTime,
Min(Isnull(A.cycletime,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MinCycleTime,
Max(Isnull(A.LoadUnload,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MaxLoadUnload,
Min(Isnull(A.LoadUnload,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MinLoadUnload
from autodata A
INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
where (A.ndtime>@StartTime and A.ndtime<=@EndTime and A.datatype=1 And M.Machineid=@MachineID)
group by M.Machineid,C.componentid,O.OperationNo ,E.EmployeeID
) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
And t2.CShift=ShiftProductionDetails.Shift
And t2.CMachine = ShiftProductionDetails.MachineID
And t2.CComponent=ShiftProductionDetails.Componentid
And t2.COpnNo=ShiftProductionDetails.OperationNo
       And t2.COpr=ShiftProductionDetails.OperatorID*/
/*
-- Type 1/2 ::Calculate Actual LoadUnload Time for Load Ratio.
UPDATE ShiftProductionDetails SET ActLoadUnload_Type12 = isnull(ActLoadUnload_Type12,0) + isNull(t2.Cycle,0)
from
(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
sum(A.loadunload) as Cycle
from autodata A
INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
where (A.ndtime>@StartTime and A.ndtime<=@EndTime and A.datatype=1 And M.Machineid=@MachineID)
group by M.Machineid,C.componentid,O.OperationNo ,E.EmployeeID
) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.Date
And t2.CShift=ShiftProductionDetails.Shift
And t2.CMachine = ShiftProductionDetails.MachineID
And t2.CComponent=ShiftProductionDetails.Componentid
And t2.COpnNo=ShiftProductionDetails.OperationNo
And t2.COpr=ShiftProductionDetails.OperatorID
 
*/
/*-- To calculate Utilised Time
-- Type 1
UPDATE ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
from
(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
sum(A.cycletime + A.LoadUnload) as Cycle
from autodata A
INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
where (A.msttime>=@StartTime and A.ndtime<=@EndTime and A.datatype=1 And M.Machineid=@MachineID)
group by M.Machineid,C.componentid,O.OperationNo ,E.EmployeeID
) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
And t2.CShift=ShiftProductionDetails.Shift
And t2.CMachine = ShiftProductionDetails.MachineID
And t2.CComponent=ShiftProductionDetails.Componentid
And t2.COpnNo=ShiftProductionDetails.OperationNo
And t2.COpr=ShiftProductionDetails.OperatorID
-- Type 2
UPDATE ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
from
(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,SUM(DateDiff(second, @StartTime, ndtime)) as Cycle
from autodata A
INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
where A.msttime<@StartTime and A.ndtime>@StartTime and A.ndtime<=@EndTime and A.datatype=1 And M.Machineid=@MachineID
group by M.Machineid,C.componentid,O.OperationNo,E.EmployeeID
) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
And t2.CShift=ShiftProductionDetails.Shift
And t2.CMachine = ShiftProductionDetails.MachineID
And t2.CComponent=ShiftProductionDetails.Componentid
And t2.COpnNo=ShiftProductionDetails.OperationNo
And t2.COpr=ShiftProductionDetails.OperatorID
-- Type 3
UPDATE ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
from
(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,SUM(DateDiff(second, stTime, @Endtime)) as Cycle
from autodata A
INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
where A.msttime>=@StartTime and A.msttime<@EndTime and A.ndtime>@EndTime and A.datatype=1 And M.Machineid=@MachineID
group by M.Machineid,C.componentid,O.OperationNo,E.EmployeeID
) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
And t2.CShift=ShiftProductionDetails.Shift
And t2.CMachine = ShiftProductionDetails.MachineID
And t2.CComponent=ShiftProductionDetails.Componentid
And t2.COpnNo=ShiftProductionDetails.OperationNo
And t2.COpr=ShiftProductionDetails.OperatorID
-- Type 4
UPDATE ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
from
(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,SUM(DateDiff(second, @StartTime, @EndTime)) as Cycle
from autodata A
INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
where  A.msttime<@StartTime and A.ndtime>@EndTime and A.datatype=1 And M.Machineid=@MachineID
group by M.Machineid,C.componentid,O.OperationNo,E.EmployeeID
) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
And t2.CShift=ShiftProductionDetails.Shift
And t2.CMachine = ShiftProductionDetails.MachineID
And t2.CComponent=ShiftProductionDetails.Componentid
And t2.COpnNo=ShiftProductionDetails.OperationNo
And t2.COpr=ShiftProductionDetails.OperatorID*/
/* Incylce Down */
/* If Down Records of TYPE-2*/
/*UPDATE  ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
FROM
(Select @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
SUM(
CASE
When A.sttime <= @StartTime Then datediff(s, @StartTime,A.ndtime )
When A.sttime > @StartTime Then datediff(s , A.sttime,A.ndtime)
END) as Down
From AutoData A INNER Join (Select mc,Comp,Opn,Opr,Sttime,NdTime From AutoData
Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
(sttime < @StartTime And ndtime > @StartTime AND ndtime <= @EndTime)) as T1 ON A.mc=T1.mc And A.Comp=T1.Comp And A.Opn=T1.Opn And A.Opr=T1.Opr
Inner Join MachineInformation M on A.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
Where A.DataType=2
And  A.Sttime > T1.Sttime And  A.ndtime <  T1.ndtime  AND  A.ndtime >  @StartTime  And M.Machineid=@MachineID
GROUP BY M.Machineid,C.componentid,O.OperationNo,E.EmployeeID)AS T2
Inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
And t2.CShift=ShiftProductionDetails.Shift
And t2.CMachine = ShiftProductionDetails.MachineID
And t2.CComponent=ShiftProductionDetails.Componentid
And t2.COpnNo=ShiftProductionDetails.OperationNo
And t2.COpr=ShiftProductionDetails.OperatorID*/
/* If Down Records of TYPE-3*/
/*
UPDATE  ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
FROM
(Select @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
SUM(
CASE
When A.ndtime > @EndTime Then datediff(s,A.sttime, @EndTime )
When A.ndtime <=@EndTime Then datediff(s , A.sttime,A.ndtime)
END) as Down
From AutoData A INNER Join (Select mc,Comp,Opn,Opr,Sttime,NdTime From AutoData
Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
(sttime >= @StartTime)And (ndtime > @EndTime)) as T1 ON A.mc=T1.mc And A.Comp=T1.Comp And A.Opn=T1.Opn And A.Opr=T1.Opr
Inner Join MachineInformation M on A.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
Where A.DataType=2
And (T1.Sttime < A.sttime  )And ( T1.ndtime >  A.ndtime) AND (A.sttime  <  @EndTime) And M.Machineid=@MachineID
GROUP BY M.Machineid,C.componentid,O.OperationNo,E.EmployeeID)AS T2
Inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
And t2.CShift=ShiftProductionDetails.Shift
And t2.CMachine = ShiftProductionDetails.MachineID
And t2.CComponent=ShiftProductionDetails.Componentid
And t2.COpnNo=ShiftProductionDetails.OperationNo
And t2.COpr=ShiftProductionDetails.OperatorID*/
/* If Down Records of TYPE-4*/
/*UPDATE  ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
FROM
(Select @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
SUM(
CASE
When A.sttime < @StartTime AND A.ndtime<=@EndTime Then datediff(s, @StartTime,A.ndtime)
When A.ndtime >= @EndTime AND A.sttime>@StartTime Then datediff(s,A.sttime, @EndTime)
When A.sttime >= @StartTime AND
    A.ndtime <= @EndTime Then datediff(s , A.sttime,A.ndtime)
When A.sttime<@StartTime AND A.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
END) as Down
From AutoData A INNER Join (Select mc,Comp,Opn,Opr,Sttime,NdTime From AutoData
Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
(sttime < @StartTime)And (ndtime > @EndTime) ) as T1 ON A.mc=T1.mc And A.Comp=T1.Comp And A.Opn=T1.Opn And A.Opr=T1.Opr
Inner Join MachineInformation M on A.mc=M.Interfaceid
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
Where A.DataType=2
And (T1.Sttime < A.sttime  )And ( T1.ndtime >  A.ndtime) AND (A.ndtime  >  @StartTime)AND (A.sttime  <  @EndTime)And M.Machineid=@MachineID
GROUP BY M.Machineid,C.componentid,O.OperationNo,E.EmployeeID)AS T2
Inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
And t2.CShift=ShiftProductionDetails.Shift
And t2.CMachine = ShiftProductionDetails.MachineID
And t2.CComponent=ShiftProductionDetails.Componentid
And t2.COpnNo=ShiftProductionDetails.OperationNo
And t2.COpr=ShiftProductionDetails.OperatorID
***********************************************Commented till here for mod 2*************************************************/
select @strMachine = '' --DR0302 added
---DownAggregation starts here
if isnull(@MachineID,'')<> ''
begin
---mod 6
-- SET @strMachine = ' AND M.MachineID = ''' + @machineid + ''''
---mod 12
--SET @strMachine = ' AND M.MachineID = N''' + @machineid + ''''
SET @strMachine = ' AND M.MachineID in ( ' +  @machineid + ') '
---mod 12
---mod 6
end
if isnull(@PlantID,'')<> ''
Begin
---mod 6
-- SET @strPlantID = ' AND P.PlantID = ''' + @PlantID + ''''
SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
---mod 6
End

if isnull(@GroupID,'')<> ''
Begin
---mod 6
-- SET @strPlantID = ' AND P.PlantID = ''' + @PlantID + ''''
SET @StrGroupID = ' AND PlantMachineGroups.Groupid = N''' + @GroupID + ''''
---mod 6
End

select @StrSql=''
--print 'in down'
--Building String to get All Types of Down Records for shift.
---mod 11
Declare @StrPLD_DownId As NVarChar(500)
--Declare @Param1 As NVarChar(2000) --DR0302 Commented
Declare @Param1 As VarChar(max) --DR0302 Added
Declare @Param2 As NVarChar(max)
--Declare @Param3 As NVarChar(2500) --DR0302 Commented
Declare @Param3 As VarChar(max) --DR0302 Added
SELECT @StrPLD_DownId=''
SELECT @Param1 = ''
SELECT @Param2 = ''
SELECT @Param3 = ''
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
SELECT @StrPLD_DownId=' AND D.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
END
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
SELECT @Param1 = 'LEFT OUTER JOIN
(
SELECT A.Sttime as PLD_Sttime,A.Ndtime as PLD_Ndtime,M.MachineID as PLD_MachineID,T.MShift as shiftname, --DR0309 Added shiftName
sum(CASE
WHEN (sttime>=TP.StartTime AND ndtime<=TP.EndTime) THEN Loadunload --We are completly ignoring this record
WHEN (sttime<TP.StartTime AND ndtime<=TP.EndTime AND ndtime>TP.StartTime )THEN DATEDIFF(ss,TP.StartTime,ndtime)
WHEN (sttime>=TP.StartTime AND sttime<TP.EndTime AND ndtime>TP.EndTime) THEN DATEDIFF(ss,Sttime,TP.Endtime)
WHEN (sttime<TP.StartTime AND ndtime>TP.EndTime) THEN DATEDIFF(ss,TP.StartTime,TP.EndTime)
End) As PLD_LoadUnload,T.MShiftStart as MShiftStart ,T.MShiftEnd as MShiftEnd
From #T_AutoData A INNER JOIN MachineInformation M ON A.Mc=M.InterfaceID --ER0202 
inner join #TempMCOODown T on M.Machineid=T.AMachine
Left Outer Join PlantMachine  ON PlantMachine.machineid=M.machineid 
LEFT OUTER JOIN PlantMachineGroups  ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
INNER JOIN
Downcodeinformation D ON A.dcode=D.interfaceid inner JOIN #PlannedDownTimes TP
on TP.MachineInterface=A.mc and T.MShiftStart=TP.ShiftStart
Where A.Datatype=2 
and A.mStTime>=T.LastAggstart --DR0322 Added Line
and
(
(ndtime>T.MShiftStart and ndtime<=T.MShiftEnd) --DR0322 Added
OR(StTime>=T.MShiftStart And StTime<T.MShiftEnd And ndTime>T.MShiftEnd)
OR(StTime<T.MShiftStart And ndTime>T.MShiftEnd))
And (
(ndtime>TP.StartTime AND ndtime<=TP.EndTime) --DR0322 Added
OR (sttime>=TP.StartTime AND sttime<TP.EndTime AND ndtime>TP.EndTime)
OR (sttime<TP.StartTime AND ndtime>TP.EndTime))'
--DR0302 from here
--SELECT @Param1=@Param1 + @StrPlantID + @strmachine + @StrPLD_DownId
 SELECT @Param1=@Param1 + convert(nvarchar(1000),@StrPlantID) + convert(nvarchar(1000),@strmachine) + convert(nvarchar(1000),@StrPLD_DownId)+ convert(nvarchar(1000),@StrGroupID) --GNA
--DR0302 till here
SELECT @Param1=@Param1 + ' Group By A.Sttime,A.Ndtime,M.MachineID, T.MShiftStart,T.MShiftEnd,T.MShift --DR0309 Added Shift
) AS Td ON A.Sttime=Td.PLD_Sttime AND A.Ndtime=Td.PLD_Ndtime AND M.MachineID=Td.PLD_MachineID and 
td.MShiftStart= T.MShiftStart and Td.MShiftEnd =T.MShiftEnd and --DR0322 Added Line
Td.shiftname=T.Mshift' --DR0309 Added Shift
SELECT @Param2 = ' - ISNULL(Td.PLD_LoadUnload,0)'
--SELECT @Param3 = ' AND (DateDiff(second,CASE WHEN Sttime <T.MShiftStart THEN  T.MShiftStart ELSE Sttime END,
--CASE WHEN Ndtime >T.MShiftEnd THEN T.MShiftEnd ELSE NdTime End)-ISNULL(Td.PLD_LoadUnload,0))>0' ---DR0390 Commented
SELECT @Param3 = ' AND ((DateDiff(second,CASE WHEN Sttime <T.MShiftStart THEN  T.MShiftStart ELSE Sttime END,
CASE WHEN Ndtime >T.MShiftEnd THEN T.MShiftEnd ELSE NdTime End)-ISNULL(Td.PLD_LoadUnload,0))>0 OR ISNULL(Td.PLD_LoadUnload,0)>0)' ---DR0390 added
END
---mod 11

If @companyname <> 'SUPER AUTO FORGE PVT LTD-MEPZ' --ER0349 Added
Begin  --ER0349 Added

select @StrSql=''
SELECT @StrSql=' INSERT INTO ShiftDownTimeDetails(
dDate,Shift,
PlantID,MachineID,
ComponentID,
OperationNo,
OperatorID,
StartTime,
EndTime,
DownCategory,
DownID,
DownTime, --In Seconds
ML_Flag,
Threshold,
RetPerMcHour_Flag,StdSetupTime '
---mod 7
--mod 1 introduced PE_Flag column
--SELECT @StrSql=@StrSql + ',PE_Flag)'
--mod 1
SELECT @StrSql=@StrSql + ',PE_Flag,WorkOrderNumber,PJCYear'
--mod 7
SELECT @StrSql=@StrSql + ',CriticalMachineEnabled,Groupid,PDT)'--Geeta added --GNA
SELECT @StrSql=@StrSql + 'select T.Mdate,T.MShift,PlantMachine.PlantID,AMachine,
isnull(c.componentid,''Invalid Component'')  ,isnull(o.operationno,0) ,
 
E.EmployeeID,
CASE WHEN Sttime<T.MShiftStart THEN T.MShiftStart ELSE Sttime END,
CASE WHEN Ndtime>T.MShiftEnd THEN T.MShiftEnd ELSE NdTime End,'
SELECT @StrSql=@StrSql + 'D.Catagory,D.DownID,
DateDiff(second,CASE WHEN Sttime<T.MShiftStart THEN T.MShiftStart ELSE Sttime END,
CASE WHEN Ndtime>T.MShiftEnd THEN T.MShiftEnd ELSE NdTime End)'
---mod 11
--DR0302 from here
--SELECT @StrSql=@StrSql + @Param2
SELECT @StrSql=@StrSql + convert(nvarchar(max),@Param2)
--DR0302 till here
---mod 11
SELECT @StrSql=@StrSql +' ,isnull(D.AvailEffy,0),ISNULL(D.Threshold,0),
isnull(D.retpermchour,0),ISNULL(O.StdSetupTime,0) '
---mod 1 introduced PE_Flag column
SELECT @StrSql=@StrSql + ',ISNULL(D.prodeffy,0) '
---mod 1
---mod 7
SELECT @StrSql = @StrSql + ',Isnull(A.WorkOrderNumber,0),isnull(A.PJCYear,'''')'
---mod 7
SELECT @StrSql = @StrSql + ',M.CriticalMachineEnabled,PlantMachineGroups.Groupid' --geeta added
---DR0302 from here
If @Param2<>'' 
Begin 
	SELECT @StrSql = @StrSql + ',ISNULL(Td.PLD_LoadUnload,0)' --geeta added
END
Else
Begin
	SELECT @StrSql = @StrSql + ',0'
END
---DR0302 till here
SELECT @StrSql=@StrSql + ' FROM #T_autodata A ---ER0202 
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  machineinformation M ON A.mc = M.InterfaceID
inner join #TempMCOODown T on M.Machineid=T.AMachine
LEFT OUTER JOIN PlantMachine  ON M.MachineID=PlantMachine.MachineID
LEFT OUTER JOIN PlantMachineGroups  ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID --GNA
INNER JOIN DownCodeInformation D ON A.Dcode=D.InterfaceID
left outer join componentinformation C ON A.comp = C.InterfaceID
left outer  JOIN componentoperationpricing O ON (A.opn = O.InterfaceID  AND C.componentid = O.componentid)'
---mod 5
SELECT @StrSql=@StrSql + ' and M.machineid = O.machineid '
---mod 5
--INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID  AND C.componentid = O.componentid)'
---mod 11
---DR0302 from here
--SELECT @StrSql=@StrSql + @Param1
SELECT @StrSql=@StrSql + convert(nvarchar(max),@Param1)
--DR0302 till here
---mod 11
--DR0302 from here
Select @strtemp=''
/*SELECT @StrSql=@StrSql + ' WHERE Datatype=2 And
((StTime>=T.MShiftStart And ndTime<=T.MShiftEnd)
OR(StTime<T.MShiftStart And ndTime>T.MShiftStart And ndTime<=T.MShiftEnd)
OR(StTime>=T.MShiftStart And StTime<T.MShiftEnd And ndTime>T.MShiftEnd)
OR(StTime<T.MShiftStart And ndTime>T.MShiftEnd)) '*/
SELECT @strtemp= ' WHERE Datatype=2 And
((ndtime>T.MShiftStart and ndtime<=T.MShiftEnd) --DR0322 Added
OR(StTime>=T.MShiftStart And StTime<T.MShiftEnd And ndTime>T.MShiftEnd)
OR(StTime<T.MShiftStart And ndTime>T.MShiftEnd)) '
SELECT @StrSql=@StrSql +  convert(nvarchar(500),@strtemp) 

--DR0302 till here
SELECT @StrSql = @StrSql+@strPlantID+@StrGroupID---+@strMachine --GNA
---mod 11
--DR0302 from here
--SELECT @StrSql = @StrSql+ @Param3
SELECT @StrSql = @StrSql+convert(nvarchar(max),@Param3)
--DR0302 till here
---mod 11
 
---mod 3(a)
SELECT @StrSql = @StrSql + ' and A.mStTime >= T.LastAggstart '
---mod 3(a)
--select * from #TempMCOODown
PRINT @StrSql
Exec (@StrSql)
-------------------------workordernumber
END --ER0349 Added


If @companyname = 'SUPER AUTO FORGE PVT LTD-MEPZ' --ER0349 Added
Begin  --ER0349 Added

select @StrSql=''
SELECT @StrSql=' INSERT INTO ShiftDownTimeDetails(
dDate,Shift,
PlantID,MachineID,
ComponentID,
OperationNo,
OperatorID,
StartTime,
EndTime,
DownCategory,
DownID,
DownTime, --In Seconds
ML_Flag,
Threshold,
RetPerMcHour_Flag,StdSetupTime '
---mod 7
--mod 1 introduced PE_Flag column
--SELECT @StrSql=@StrSql + ',PE_Flag)'
--mod 1
SELECT @StrSql=@StrSql + ',PE_Flag,WorkOrderNumber'
--mod 7
SELECT @StrSql=@StrSql + ',CriticalMachineEnabled,Groupid,PDT)'--Geeta added
SELECT @StrSql=@StrSql + 'select T.Mdate,T.MShift,PlantMachine.PlantID,AMachine,
isnull(c.componentid,''Invalid Component'')  ,isnull(o.operationno,0) ,
 
E.EmployeeID,
CASE WHEN Sttime<T.MShiftStart THEN T.MShiftStart ELSE Sttime END,
CASE WHEN Ndtime>T.MShiftEnd THEN T.MShiftEnd ELSE NdTime End,'
SELECT @StrSql=@StrSql + 'D.Catagory,D.DownID,
DateDiff(second,CASE WHEN Sttime<T.MShiftStart THEN T.MShiftStart ELSE Sttime END,
CASE WHEN Ndtime>T.MShiftEnd THEN T.MShiftEnd ELSE NdTime End)'
---mod 11
--DR0302 from here
--SELECT @StrSql=@StrSql + @Param2
SELECT @StrSql=@StrSql + convert(nvarchar(max),@Param2)
--DR0302 till here
---mod 11
SELECT @StrSql=@StrSql +' ,isnull(D.AvailEffy,0),ISNULL(D.Threshold,0),
isnull(D.retpermchour,0),ISNULL(O.StdSetupTime,0) '
---mod 1 introduced PE_Flag column
SELECT @StrSql=@StrSql + ',ISNULL(D.prodeffy,0) '
---mod 1
---mod 7
--SELECT @StrSql = @StrSql + ',Isnull(A.WorkOrderNumber,0)' --ER0349 Commented
SELECT @StrSql = @StrSql + ',''JC\'' + substring(isnull(c.componentid,''Invalid Component''),1,3) + ''\'' + isnull(PI.Plantcode,0) + '' '' + Isnull(A.WorkOrderNumber,0)' --ER0349 Added
---mod 7
SELECT @StrSql = @StrSql + ',M.CriticalMachineEnabled,PlantMachineGroups.GroupID' --geeta added --GNA
---DR0302 from here
If @Param2<>'' 
Begin 
	SELECT @StrSql = @StrSql + ',ISNULL(Td.PLD_LoadUnload,0)' --geeta added
END
Else
Begin
	SELECT @StrSql = @StrSql + ',0'
END
---DR0302 till here
SELECT @StrSql=@StrSql + ' FROM #T_autodata A ---ER0202 
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  machineinformation M ON A.mc = M.InterfaceID
inner join #TempMCOODown T on M.Machineid=T.AMachine
LEFT OUTER JOIN PlantMachine  ON M.MachineID=PlantMachine.MachineID
LEFT OUTER JOIN PlantInformation PI on PI.plantid=PlantMachine.plantid --ER0349 added
LEFT OUTER JOIN PlantMachineGroups  ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID --GNA
INNER JOIN DownCodeInformation D ON A.Dcode=D.InterfaceID
left outer join componentinformation C ON A.comp = C.InterfaceID
left outer  JOIN componentoperationpricing O ON (A.opn = O.InterfaceID  AND C.componentid = O.componentid)'
---mod 5
SELECT @StrSql=@StrSql + ' and M.machineid = O.machineid '
---mod 5
--INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID  AND C.componentid = O.componentid)'
---mod 11
---DR0302 from here
--SELECT @StrSql=@StrSql + @Param1
SELECT @StrSql=@StrSql + convert(nvarchar(max),@Param1)
--DR0302 till here
---mod 11
--DR0302 from here
Select @strtemp=''
/*SELECT @StrSql=@StrSql + ' WHERE Datatype=2 And
((StTime>=T.MShiftStart And ndTime<=T.MShiftEnd)
OR(StTime<T.MShiftStart And ndTime>T.MShiftStart And ndTime<=T.MShiftEnd)
OR(StTime>=T.MShiftStart And StTime<T.MShiftEnd And ndTime>T.MShiftEnd)
OR(StTime<T.MShiftStart And ndTime>T.MShiftEnd)) '*/
SELECT @strtemp= ' WHERE Datatype=2 And
((ndtime>T.MShiftStart and ndtime<=T.MShiftEnd) --DR0322 Added
OR(StTime>=T.MShiftStart And StTime<T.MShiftEnd And ndTime>T.MShiftEnd)
OR(StTime<T.MShiftStart And ndTime>T.MShiftEnd)) '
SELECT @StrSql=@StrSql +  convert(nvarchar(500),@strtemp) 

--DR0302 till here
SELECT @StrSql = @StrSql+@strPlantID+@StrGroupID---+@strMachine --GNA
---mod 11
--DR0302 from here
--SELECT @StrSql = @StrSql+ @Param3
SELECT @StrSql = @StrSql+convert(nvarchar(max),@Param3)
--DR0302 till here
---mod 11
 
---mod 3(a)
SELECT @StrSql = @StrSql + ' and A.mStTime >= T.LastAggstart '
---mod 3(a)
--select * from #TempMCOODown
PRINT @StrSql
Exec (@StrSql)
-------------------------workordernumber
END --ER0349 Added

---mod 4(3)
set @ErrNo=@@ERROR
IF @ErrNo <> 0 GOTO ERROR_HANDLER
---MOD 4(3)
/*********************************Commented for  mod 2************************************************
SELECT @StrSql=' INSERT INTO ShiftDownTimeDetails(
dDate,Shift,
PlantID,MachineID,
ComponentID,
OperationNo,
OperatorID,
StartTime,
EndTime,
DownCategory,
DownID,
DownTime, --In Seconds
ML_Flag,
Threshold,
RetPerMcHour_Flag,StdSetupTime '
--mod 1 introduced PE_Flag column
SELECT @StrSql=@StrSql + ',PE_Flag)'
--mod 1
SELECT @StrSql=@StrSql + ' SELECT '''+Convert(NvarChar(20),@Date,120)+''','''+@Shift+''',P.PlantID,M.MachineID,
isnull(c.componentid,''Invalid Component'')  ,isnull(o.operationno,0) ,
 
E.EmployeeID,
CASE WHEN Sttime <'''+Convert(NvarChar(20),@StartTime,120)+''' THEN  '''+Convert(NvarChar(20),@StartTime,120)+''' ELSE Sttime END,
CASE WHEN Ndtime >'''+Convert(NvarChar(20),@EndTime,120)+''' THEN '''+Convert(NvarChar(20),@EndTime,120)+''' ELSE NdTime End,'
SELECT @StrSql=@StrSql + 'D.Catagory,D.DownID,
DateDiff(second,CASE WHEN Sttime <'''+Convert(NvarChar(20),@StartTime,120)+''' THEN  '''+Convert(NvarChar(20),@StartTime,120)+''' ELSE Sttime END,
CASE WHEN Ndtime >'''+Convert(NvarChar(20),@EndTime,120)+''' THEN '''+Convert(NvarChar(20),@EndTime,120)+''' ELSE NdTime End)'
SELECT @StrSql=@StrSql +' ,isnull(D.AvailEffy,0),ISNULL(D.Threshold,0),
isnull(D.retpermchour,0),ISNULL(O.StdSetupTime,0) '
---mod 1 introduced PE_Flag column
SELECT @StrSql=@StrSql + ',ISNULL(D.prodeffy,0) '
---mod 1
SELECT @StrSql=@StrSql + ' FROM autodata A
INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
INNER JOIN  machineinformation M ON A.mc = M.InterfaceID
LEFT OUTER JOIN PlantMachine P ON M.MachineID=P.MachineID
INNER JOIN DownCodeInformation D ON A.Dcode=D.InterfaceID
left outer join componentinformation C ON A.comp = C.InterfaceID
left outer  JOIN componentoperationpricing O ON (A.opn = O.InterfaceID  AND C.componentid = O.componentid)'
--INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
--INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID  AND C.componentid = O.componentid)'
SELECT @StrSql=@StrSql + ' WHERE Datatype=2 And
((StTime>='''+Convert(NvarChar(20),@StartTime,120)+''' And ndTime<='''+Convert(NvarChar(20),@EndTime,120)+''')
OR(StTime<'''+Convert(NvarChar(20),@StartTime,120)+''' And ndTime>'''+Convert(NvarChar(20),@StartTime,120)+''' And ndTime<='''+Convert(NvarChar(20),@EndTime,120)+''')
OR(StTime>='''+Convert(NvarChar(20),@StartTime,120)+''' And StTime<'''+Convert(NvarChar(20),@EndTime,120)+''' And ndTime>'''+Convert(NvarChar(20),@EndTime,120)+''')
OR(StTime<'''+Convert(NvarChar(20),@StartTime,120)+''' And ndTime>'''+Convert(NvarChar(20),@EndTime,120)+''')) '
SELECT @StrSql = @StrSql+@strPlantID+@strMachine
---mod 3(a)
SELECT @StrSql = @StrSql + @LastAggStart
---mod 3(a)
PRINT @StrSql
Exec (@StrSql)
***************************************Till here commented for mod 2******************************/
--s_Push_Prodn_Down_ShiftAggregation '01-Aug-08','','3I04','CNC','push',''
---DownAggregation Ends here
/*
if isnull(@MachineID,'')<> ''
begin
SET @strMachine = ' AND ShiftProductionDetails.MachineID = ''' + @machineid + ''''
end
if isnull(@PlantID,'')<> ''
Begin
SET @strPlantID = ' AND ShiftProductionDetails.PlantID = ''' + @PlantID + ''''
End
SELECT @StrSql=' SELECT  DISTINCT ID, pDate, PlantID, MachineID, Shift, ComponentID, OperationNo, OperatorID, Prod_Qty,
Repeat_Cycles, Dummy_Cycles, Rework_Performed,
Marked_for_Rework,AcceptedParts
FROM ShiftProductionDetails
        where pDATE='''+Convert(NvarChar(20),@Date)+''' AND SHIFT='''+@Shift+''''
SELECT @StrSql=@StrSql+@strPlantID+@strMachine + ' order by machineID '
exec(@StrSql)*/
/*select @StrSql=''
select @StrSql=' insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS)
--select @machineid,@Shift,@Date,2,@MaxSttime,@Maxndtime,getdate()
select '''+ @machineid +''','''+@Shift+''',''' +convert(nvarchar(20),@Date,120)+''',datatype,max(A.msttime),max(A.ndtime),''' + convert(nvarchar(20),getdate(),120)+'''
from autodata A inner join machineinformation M
on M.interfaceid=A.mc
WHERE
((A.mStTime>=''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime<=''' +convert(nvarchar(20),@EndTime,120)+''')
OR(A.mStTime<''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime>''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime<=''' +convert(nvarchar(20),@EndTime,120)+''')
OR(A.mStTime>=''' +convert(nvarchar(20),@StartTime,120)+''' And A.mStTime<''' +convert(nvarchar(20),@EndTime,120)+''' And A.ndTime>''' +convert(nvarchar(20),@EndTime,120)+''')
OR(A.mStTime<''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime>''' +convert(nvarchar(20),@EndTime,120)+''') )'
select @StrSql=@StrSql +  @LastAggStart --+ ' ) '
select @StrSql=@StrSql + @strMachine
---and M.machineid='''+ @machineid +'''
select @StrSql=@StrSql + 'group by datatype '
--print @strsql
exec (@StrSql)*/
/*select @StrSql=''
select @StrSql=' insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS)
--select @machineid,@Shift,@Date,2,@MaxSttime,@Maxndtime,getdate()
select '''+ @machineid +''','''+@Shift+''',''' +convert(nvarchar(20),@Date,120)+''',datatype,max(A.msttime),
case when max(A.ndtime)>''' +convert(nvarchar(20),@EndTime,120)+''' then ''' +convert(nvarchar(20),@EndTime,120)+''' else max(A.ndtime) end ,''' + convert(nvarchar(20),getdate(),120)+'''
from autodata A inner join machineinformation M
on M.interfaceid=A.mc
WHERE
((A.mStTime>=''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime<=''' +convert(nvarchar(20),@EndTime,120)+''')
OR(A.mStTime<''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime>''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime<=''' +convert(nvarchar(20),@EndTime,120)+''')
OR(A.mStTime>=''' +convert(nvarchar(20),@StartTime,120)+''' And A.mStTime<''' +convert(nvarchar(20),@EndTime,120)+''' And A.ndTime>''' +convert(nvarchar(20),@EndTime,120)+''')
OR(A.mStTime<''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime>''' +convert(nvarchar(20),@EndTime,120)+''') )'
select @StrSql=@StrSql +  @LastAggStart --+ ' ) '
select @StrSql=@StrSql + @strMachine
---and M.machineid='''+ @machineid +'''
select @StrSql=@StrSql + 'group by datatype '
--print @strsql
exec (@StrSql)*/
/*select @StrSql=''
select @StrSql=' insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS)
--select @machineid,@Shift,@Date,2,@MaxSttime,@Maxndtime,getdate()
select T.Amachine,'''+@Shift+''',''' +convert(nvarchar(20),@Date,120)+''',datatype,max(A.msttime),
case when max(A.ndtime)>''' +convert(nvarchar(20),@EndTime,120)+''' then ''' +convert(nvarchar(20),@EndTime,120)+''' else max(A.ndtime) end ,''' + convert(nvarchar(20),getdate(),120)+'''
from autodata A inner join machineinformation M
on M.interfaceid=A.mc
inner join #TempMCOODown T on T.Amachine=M.machineid
WHERE
((A.mStTime>=''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime<=''' +convert(nvarchar(20),@EndTime,120)+''')
OR(A.mStTime<''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime>''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime<=''' +convert(nvarchar(20),@EndTime,120)+''')
OR(A.mStTime>=''' +convert(nvarchar(20),@StartTime,120)+''' And A.mStTime<''' +convert(nvarchar(20),@EndTime,120)+''' And A.ndTime>''' +convert(nvarchar(20),@EndTime,120)+''')
OR(A.mStTime<''' +convert(nvarchar(20),@StartTime,120)+''' And A.ndTime>''' +convert(nvarchar(20),@EndTime,120)+''') )'
SELECT @StrSql = @StrSql + ' and A.mStTime >= T.LastAggstart '
--SELECT @StrSql = @StrSql + ' and A.datatype=2 '
---and M.machineid='''+ @machineid +'''
select @StrSql=@StrSql + 'group by datatype,T.AMachine '
--print @strsql
exec (@StrSql)*/
--ER0332  Added From Here 
Declare @Rejdate as datetime
declare @maxrecordid as nvarchar(500)
Set @rejdate = @date

--DR0359 Commented below, now taking max recordid for each machine from ShiftAggTrail into temp table and 
--joining this table to pick the records from autodrejection table.
--set @maxrecordid = (select isnull(max(recordid),0) from shiftaggtrail where datatype=20)

-----DR0371 Commented and Added From here
--insert into #Temp_MC_LastAggRejection (MachineId, MaxRejectionID)
--select T1.AMachine,isnull(max(T2.recordid),0) as recordid from #TempMCOODown2 T1 left outer join ShiftAggTrail T2 on T1.AMachine = T2.machineid 
--Where T2.Datatype = 20 OR T2.Datatype is null group by T1.AMachine

insert into #Temp_MC_LastAggRejection (MachineId, MaxRejectionID)
select T1.AMachine,0 from #TempMCOODown2 T1 

Update #Temp_MC_LastAggRejection set MaxRejectionID=T.recordid from
(select T1.MachineId,isnull(max(T2.recordid),0) as recordid from #Temp_MC_LastAggRejection T1 left outer join ShiftAggTrail T2 on T1.MachineId = T2.machineid 
Where T2.Datatype = 20 OR T2.Datatype is null group by T1.MachineId)T inner join #Temp_MC_LastAggRejection on #Temp_MC_LastAggRejection.MachineId=T.MachineId
-----DR0371 Added Till here

----ER0202
--while @rejdate<=@enddate
--Begin
--INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
 
--Exec  s_GetShiftTime @Date,''
--set @rejdate = dateadd(d,1,@rejdate)
--end
----ER0202

-----ER0202 Added From Here
Declare @AggRejEndDate as datetime
Select @AggRejEndDate = Case when Datepart(YEAR,@Enddate)='9999' then Dateadd(Day,3,@Date) else @Enddate END
while @rejdate<=@AggRejEndDate
Begin
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)	
	Exec  s_GetShiftTime @rejdate,''
	set @rejdate = dateadd(d,1,@rejdate)
end
-----ER0202 Added Till Here

update #ShiftDetails set shiftid = T1.shiftid
from (select distinct shiftname,shiftid from shiftdetails where running=1)T1
inner join #ShiftDetails on #ShiftDetails.shift=T1.shiftname

----DR0359 Commented 
/*
Select @Rejection=''
Select @Rejection='Insert into #TempShiftRejection(SR_Pdate,SR_Shift,SP_Machineid,SR_Mach_interface,Sp_Componentid,SR_Comp_interface,Sp_Opn,SR_Operation_interface,Sp_Oprtor,SR_Oprtor_interface,
Rejectionreason,RejectionQty,SDTimestamp,Recordid) Select #ShiftDetails.pdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
rejectioncodeinformation.Rejectionid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid From #ShiftDetails,AutodataRejections
inner join rejectioncodeinformation on rejectioncodeinformation.interfaceid=isnull(AutodataRejections.Rejection_Code,''9999'')
inner join EmployeeInformation on AutodataRejections.opr=EmployeeInformation.interfaceid
inner join machineinformation on AutodataRejections.mc=machineinformation.Interfaceid
left outer join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
inner join componentinformation on AutodataRejections.comp=componentinformation.Interfaceid
inner join  componentoperationpricing on (AutodataRejections.opn=componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid)
and machineinformation.machineid = componentoperationpricing.machineid
where AutodataRejections.CreatedTs>=#ShiftDetails.ShiftStart and AutodataRejections.CreatedTs<=#ShiftDetails.ShiftEnd and
AutodataRejections.Rejdate=''1900-01-01 12:00:00 AM'' and AutodataRejections.RejShift is NUll
and AutodataRejections.recordid > ''' + @maxrecordid + '''
and  AutodataRejections.flag = ''Rejection'' ----ER0349 Added
group by #ShiftDetails.pdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid ,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
rejectioncodeinformation.Rejectionid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid'
print(@Rejection)  
exec (@Rejection)
*/

--DR0359-Added
Insert into #TempShiftRejection(SR_Pdate,SR_Shift,SP_Machineid,SR_Mach_interface,Sp_Componentid,SR_Comp_interface,Sp_Opn,SR_Operation_interface,Sp_Oprtor,SR_Oprtor_interface,
Rejectionreason,RejectionQty,SDTimestamp,Recordid,WorkOrderNumber) Select #ShiftDetails.pdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
rejectioncodeinformation.Rejectionid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid,AutodataRejections.WorkOrderNumber From #ShiftDetails,AutodataRejections
inner join rejectioncodeinformation on rejectioncodeinformation.interfaceid=isnull(AutodataRejections.Rejection_Code,'9999')
inner join EmployeeInformation on AutodataRejections.opr=EmployeeInformation.interfaceid
inner join machineinformation on AutodataRejections.mc=machineinformation.Interfaceid
left outer join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
inner join componentinformation on AutodataRejections.comp=componentinformation.Interfaceid
inner join  componentoperationpricing on (AutodataRejections.opn=componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid)
and machineinformation.machineid = componentoperationpricing.machineid
INNER JOIN #Temp_MC_LastAggRejection on #Temp_MC_LastAggRejection.Machineid = machineinformation.Machineid
where AutodataRejections.CreatedTs>=#ShiftDetails.ShiftStart and AutodataRejections.CreatedTs<=#ShiftDetails.ShiftEnd and
--AutodataRejections.Rejdate='1900-01-01 12:00:00 AM' and AutodataRejections.RejShift is NUll --ER0202
AutodataRejections.Rejdate='1900-01-01 00:00:00' and AutodataRejections.RejShift is NUll --ER0202
and AutodataRejections.recordid > #Temp_MC_LastAggRejection.MaxRejectionID
and  AutodataRejections.flag = 'Rejection'
group by #ShiftDetails.pdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid ,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
rejectioncodeinformation.Rejectionid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid,AutodataRejections.WorkOrderNumber

--DR0359-Added
Insert into #TempShiftRejection(SR_Pdate,SR_Shift,SP_Machineid,SR_Mach_interface,Sp_Componentid,SR_Comp_interface,Sp_Opn,SR_Operation_interface,Sp_Oprtor,SR_Oprtor_interface,
Rejectionreason,RejectionQty,SDTimestamp,Recordid,WorkOrderNumber) 
 Select AutodataRejections.Rejdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
rejectioncodeinformation.Rejectionid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid,AutodataRejections.WorkOrderNumber 
From AutodataRejections
inner join rejectioncodeinformation on rejectioncodeinformation.interfaceid=isnull(AutodataRejections.Rejection_Code,'9999')
inner join #ShiftDetails on AutodataRejections.RejShift = #ShiftDetails.shiftid
inner join EmployeeInformation on AutodataRejections.opr=EmployeeInformation.interfaceid
inner join machineinformation on AutodataRejections.mc=machineinformation.Interfaceid
left outer join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
inner join componentinformation on AutodataRejections.comp=componentinformation.Interfaceid
inner join  componentoperationpricing on (AutodataRejections.opn=componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid)
and machineinformation.machineid = componentoperationpricing.machineid
INNER JOIN #Temp_MC_LastAggRejection on #Temp_MC_LastAggRejection.Machineid = machineinformation.Machineid
--where AutodataRejections.Rejdate<>'1900-01-01 12:00:00 AM' and AutodataRejections.RejShift is not NUll --ER0202
where AutodataRejections.Rejdate<>'1900-01-01 00:00:00' and AutodataRejections.RejShift is not NUll --ER0202
and AutodataRejections.recordid > #Temp_MC_LastAggRejection.MaxRejectionID
and  AutodataRejections.flag = 'Rejection' ----ER0349 Added
group by AutodataRejections.Rejdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid ,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
rejectioncodeinformation.Rejectionid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid,AutodataRejections.WorkOrderNumber

--DR0359 commented below
/*
Select @Rejection=''
Select @Rejection='Insert into #TempShiftRejection(SR_Pdate,SR_Shift,SP_Machineid,SR_Mach_interface,Sp_Componentid,SR_Comp_interface,Sp_Opn,SR_Operation_interface,Sp_Oprtor,SR_Oprtor_interface,
Rejectionreason,RejectionQty,SDTimestamp,Recordid)  (Select AutodataRejections.Rejdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
rejectioncodeinformation.Rejectionid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid From AutodataRejections
inner join rejectioncodeinformation on rejectioncodeinformation.interfaceid=isnull(AutodataRejections.Rejection_Code,''9999'')
inner join #ShiftDetails on AutodataRejections.RejShift = #ShiftDetails.shiftid
inner join EmployeeInformation on AutodataRejections.opr=EmployeeInformation.interfaceid
inner join machineinformation on AutodataRejections.mc=machineinformation.Interfaceid
left outer join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
inner join componentinformation on AutodataRejections.comp=componentinformation.Interfaceid
inner join  componentoperationpricing on (AutodataRejections.opn=componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid)
and machineinformation.machineid = componentoperationpricing.machineid
where AutodataRejections.Rejdate<>''1900-01-01 12:00:00 AM'' and AutodataRejections.RejShift is not NUll
and AutodataRejections.recordid > ''' + @maxrecordid + ''' 
and  AutodataRejections.flag = ''Rejection'' ----ER0349 Added
group by AutodataRejections.Rejdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid ,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
rejectioncodeinformation.Rejectionid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid)'
print(@Rejection)  
exec(@Rejection)
*/


--ER0202
Select @strsql=''
Select @strsql=@strsql +'insert into #TempProdAccepted
(
PA_Date,
PA_Shift,
PA_MachineID,
PA_ComponentID, 
PA_OperationNo,
PA_OperatorID,
PA_Accepted,
Pa_id,
Pa_WorkOrderNumber
)'
Select @strsql=@strsql +'Select distinct SPD.Pdate,SPD.shift,SPD.MachineID,SPD.ComponentID,SPD.OperationNo,
SPD.OperatorID,SPD.Acceptedparts,SPD.id,
SPD.WorkOrderNumber --SV
from ShiftProductionDetails  SPD inner join #TempShiftRejection SRD on SPD.MachineID= SRD.SP_Machineid
and SPD.ComponentID=SRD.Sp_Componentid and SPD.OperationNo=SRD.Sp_Opn and
SPD.OperatorID=SRD.Sp_Oprtor and SPD.pdate=SRD.SR_Pdate and SPD.shift=SRD.SR_Shift
and SRD.WorkOrderNumber=SPD.WorkOrderNumber
order by SPD.id'
exec(@strsql)
--ER0202

/* ER0202 commented From Here
Select @strsql=''
Select @strsql=@strsql +'insert into #TempProdAccepted
(
PA_Date,
PA_Shift,
PA_MachineID,
PA_ComponentID,
 
PA_OperationNo,
PA_OperatorID,
PA_Accepted,
Pa_id
)'
Select @strsql=@strsql +'Select distinct SPD.Pdate,SPD.shift,SPD.MachineID,SPD.ComponentID,SPD.OperationNo,
SPD.OperatorID,SPD.Acceptedparts,SPD.id
from ShiftProductionDetails  SPD inner join #TempShiftRejection SRD on SPD.MachineID= SRD.SP_Machineid
and SPD.ComponentID=SRD.Sp_Componentid and SPD.OperationNo=SRD.Sp_Opn and
SPD.OperatorID=SRD.Sp_Oprtor and SPD.pdate=SRD.SR_Pdate and SPD.shift=SRD.SR_Shift
order by SPD.id'
exec(@strsql)


declare @AcpQty as int
declare @RejQty as int
declare @SPid as int
declare @recordid as int
declare @rejmachine as nvarchar(50)
declare @rejcomp as nvarchar(50),@rejopn as nvarchar(50),@rejopr as nvarchar(50)  --DR0329 Added
declare @rejectiondate as datetime,@rejshift as nvarchar(50) --DR0329 Added

--DR0359 commented below
--DR0329 Added Till Here
/* 
set @AcpQty = (select top 1 PA_Accepted  from #TempProdAccepted order by Pa_id)
set @SPid  = (select top 1 Pa_id from #TempProdAccepted order by Pa_id)
--set @recordid = (select top 1 isnull(recordid,0) from #TempShiftRejection order by recordid) ----DR0329 Commented
--set @RejQty = (select top 1 RejectionQty from #TempShiftRejection order by recordid) ----DR0329 Commented
set @recordid = (select top 1 isnull(recordid,0) from #TempShiftRejection order by SR_Pdate,SR_Shift,recordid) --DR0329 Added
*/
--DR0359 added  below -----------------------------------------
set @AcpQty = (select top 1 PA_Accepted from #TempProdAccepted  SPD
inner join #TempShiftRejection SRD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where PA_Accepted<>0 and SRD.shiftprodid=0 order by Pa_id,recordid)
set @spid = (select top 1 PA_id from #TempProdAccepted SPD
inner join #TempShiftRejection SRD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where PA_Accepted<>0 and SRD.shiftprodid=0  order by Pa_id,recordid)
set @recordid = (select top 1  isnull(recordid,0) from #TempShiftRejection SRD
inner join #TempProdAccepted SPD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pA_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
--where shiftprodid=0 order by SR_Pdate,SR_Shift,recordid) --DR0329 Added
where shiftprodid=0 order by Pa_id,recordid) --satya
------------------------------------------------------------------

set @RejQty = (select RejectionQty from #TempShiftRejection where recordid=@recordid) --DR0329 Added
set @rejmachine=(select SP_Machineid from #TempShiftRejection where recordid=@recordid)
----DR0329 Added From here
set @rejectiondate= (select SR_Pdate from #TempShiftRejection where recordid=@recordid) 
set @rejshift= (select SR_Shift from #TempShiftRejection where recordid=@recordid)
set @rejcomp=(select Sp_Componentid from #TempShiftRejection where recordid=@recordid)
set @rejopn=(select Sp_Opn from #TempShiftRejection where recordid=@recordid)
set @rejopr=(select Sp_Oprtor from #TempShiftRejection where recordid=@recordid)
-- --DR0329 Added till here


print @AcpQty
print @SPid
print @recordid
print @RejQty
print @rejmachine
print @rejectiondate
print @rejshift
print @rejcomp
print @rejopn
print @rejopr

while @recordid <>  0
begin

Update #TempProdAccepted set PA_Accepted= @acpqty-@RejQty
 
where pa_date=@rejectiondate and pa_shift=@rejshift and 
PA_MachineID=@rejmachine and PA_ComponentID=@rejcomp and PA_OperationNo=@rejopn and
PA_OperatorID =@rejopr and Pa_id = @spid and @acpqty>=@rejqty --DR0329 Added

If @@Rowcount <> 0   
begin
 
Update #TempShiftRejection set ShiftProdid = @spid where recordid=@recordid
--case when @acpqty>=@rejqty then @spid else -1 end where recordid=@recordid --DR0359
 
end             
If @@Rowcount = 0   
begin
 
Update #TempShiftRejection set ShiftProdid = -1 where recordid=@recordid
 
end       
--DR0329 Added Till here

If @acpqty < @rejqty
begin
insert into aggregate_Error(errno,machineid,StartDate,EndDate,remarks)
values(@spid,@rejmachine,@Date,@EndDate,'Rejection Qty greater than Accepted Parts.')
end

set @acpqty = ''
set @spid = ''
set @rejqty = ''
set @rejmachine = ''
set @rejectiondate='' --DR0329 Added
set @rejshift='' --DR0329 Added
set @recordid='' --DR0329 added
set @rejcomp='' --DR0329 added
set @rejopn='' --DR0329 added
set @rejopr='' --DR0329 added

set @acpqty = (select top 1 PA_Accepted from #TempProdAccepted  SPD
inner join #TempShiftRejection SRD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where PA_Accepted<>0 and SRD.shiftprodid=0 order by Pa_id,recordid) --DR0359
--where PA_Accepted<>0 and SRD.shiftprodid=0 order by Pa_id)
 

set @spid = (select top 1 PA_id from #TempProdAccepted SPD
inner join #TempShiftRejection SRD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where PA_Accepted<>0 and SRD.shiftprodid=0  order by Pa_id,recordid) --DR0359
--where PA_Accepted<>0 and SRD.shiftprodid=0  order by Pa_id)
 

set @recordid = (select top 1  isnull(recordid,0) from #TempShiftRejection SRD
inner join #TempProdAccepted SPD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pA_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
 
where shiftprodid=0 order by Pa_id,recordid) --DR0359 Added
--where shiftprodid=0 order by SR_Pdate,SR_Shift,recordid) --DR0329 Added
--DR0329 Commented From here
-- set @RejQty = (select top 1  isnull(RejectionQty,0) from #TempShiftRejection SRD
-- inner join #TempProdAccepted SPD on SPD.pa_MachineID= SRD.SP_Machineid
-- and SPD.pA_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
-- SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
-- where shiftprodid=0 order by recordid) 
-- print @recordid
--DR0329 Commented Till here

set @rejmachine=(select SP_Machineid from #TempShiftRejection where recordid=@recordid)
print @rejmachine
--DR0329 Added From Here
set @RejQty = (select RejectionQty from #TempShiftRejection where recordid=@recordid)
print @RejQty
set @rejectiondate= (select SR_Pdate from #TempShiftRejection where recordid=@recordid)
print @rejectiondate
set @rejshift= (select SR_Shift from #TempShiftRejection where recordid=@recordid)
print @rejshift
set @rejcomp=(select Sp_Componentid from #TempShiftRejection where recordid=@recordid)
print @rejcomp
set @rejopn=(select Sp_Opn from #TempShiftRejection where recordid=@recordid)
print @rejopn
set @rejopr=(select Sp_Oprtor from #TempShiftRejection where recordid=@recordid)
print @rejopr
--DR0329 Added Till Here
end
--END WHILE 

Update dbo.ShiftProductionDetails set AcceptedParts= PA_Accepted from #TempProdAccepted
inner join ShiftProductionDetails Sp on #TempProdAccepted.Pa_id=sp.id
   
insert into ShiftRejectionDetails(ID,Rejection_Qty,Rejection_Reason,UpdatedBy,UpdatedTS)
Select ShiftProdid,RejectionQty,Rejectionreason,'PCT',getdate() from #TempShiftRejection
--where  shiftprodid<>'0' and shiftprodid<>'-1' and recordid > @maxrecordid
where  shiftprodid > 0 --DR0359

ER0202*/



---ER0202
Update #TempProdAccepted set PA_Accepted= ISNULL(SPD.PA_Accepted,0)-ISNULL(SRD.RejQty,0),PA_ExtraRejQty = ISNULL(SRD.ExtraRejqty,0) From
(
	select SRD.SP_Machineid,SRD.Sp_Componentid,SRD.Sp_Opn,SRD.Sp_Oprtor,SRD.SR_Pdate,SRD.SR_Shift,SRD.WorkOrderNumber,
	Case WHEN (ISNULL(SUM(SPD.PA_Accepted),0)>0 and ISNULL(SUM(SPD.PA_Accepted),0)>=ISNULL(SUM(SRD.RejectionQty),0)) THEN SUM(RejectionQty) 
	When (ISNULL(SUM(SPD.PA_Accepted),0)>0 and ISNULL(SUM(SPD.PA_Accepted),0)<ISNULL(SUM(SRD.RejectionQty),0)) THEN SUM(SPD.PA_Accepted) END as Rejqty,
	Case When (ISNULL(SUM(SPD.PA_Accepted),0)>0 and ISNULL(SUM(SPD.PA_Accepted),0)<ISNULL(SUM(SRD.RejectionQty),0)) THEN (ISNULL(SUM(SRD.RejectionQty),0)-ISNULL(SUM(SPD.PA_Accepted),0)) else 0 END as ExtraRejqty from 
		(
			Select SP_Machineid,Sp_Componentid,Sp_Opn,Sp_Oprtor,SR_Pdate,SR_Shift,WorkOrderNumber,SUM(RejectionQty) as RejectionQty from #TempShiftRejection
			Group by SP_Machineid,Sp_Componentid,Sp_Opn,Sp_Oprtor,SR_Pdate,SR_Shift,WorkOrderNumber
		) SRD 
	inner join #TempProdAccepted SPD on SPD.PA_MachineID= SRD.SP_Machineid and SPD.PA_ComponentID=SRD.Sp_Componentid and SPD.PA_OperationNo=SRD.Sp_Opn and
	SPD.PA_OperatorID=SRD.Sp_Oprtor and SPD.PA_date=SRD.SR_Pdate and SPD.PA_Shift=SRD.SR_Shift and SPD.PA_WorkOrderNumber=SRD.WorkOrderNumber
	Group by SRD.SP_Machineid,SRD.Sp_Componentid,SRD.Sp_Opn,SRD.Sp_Oprtor,SRD.SR_Pdate,SRD.SR_Shift,SRD.WorkOrderNumber
)SRD
inner join #TempProdAccepted SPD on SPD.PA_MachineID= SRD.SP_Machineid and SPD.PA_ComponentID=SRD.Sp_Componentid and SPD.PA_OperationNo=SRD.Sp_Opn and
SPD.PA_OperatorID=SRD.Sp_Oprtor and SPD.PA_date=SRD.SR_Pdate and SPD.PA_Shift=SRD.SR_Shift and SPD.PA_WorkOrderNumber=SRD.WorkOrderNumber --where (SPD.PA_Accepted<>0 and SPD.PA_Accepted>=SRd.Rejqty)

Update #TempShiftRejection set ShiftProdid= ISNULL(SRD.ShiftProdid,0)+ISNULL(T1.ProdId,0) From
(select SRD.SP_Machineid,SRD.Sp_Componentid,SRD.Sp_Opn,SRD.Sp_Oprtor,SRD.SR_Pdate,SRD.SR_Shift,SPD.Pa_id as ProdId,SRD.WorkOrderNumber from #TempShiftRejection SRD 
inner join #TempProdAccepted SPD on SPD.PA_MachineID= SRD.SP_Machineid
and SPD.PA_ComponentID=SRD.Sp_Componentid and SPD.PA_OperationNo=SRD.Sp_Opn and
SPD.PA_OperatorID=SRD.Sp_Oprtor and SPD.PA_date=SRD.SR_Pdate and SPD.PA_Shift=SRD.SR_Shift and SPD.PA_WorkOrderNumber=SRD.WorkOrderNumber--where (SPD.PA_Accepted<>0 and SPD.PA_Accepted>SRD.RejectionQty)
)T1 inner join #TempShiftRejection SRD on T1.SP_Machineid= SRD.SP_Machineid and T1.Sp_Componentid=SRD.Sp_Componentid and T1.Sp_Opn=SRD.Sp_Opn and
T1.Sp_Oprtor=SRD.Sp_Oprtor and T1.SR_Pdate=SRD.SR_Pdate and T1.SR_Shift=SRD.SR_Shift and T1.WorkOrderNumber=SRD.WorkOrderNumber

Update dbo.ShiftProductionDetails set AcceptedParts= PA_Accepted from #TempProdAccepted
inner join ShiftProductionDetails Sp on #TempProdAccepted.Pa_id=sp.id
   
insert into ShiftRejectionDetails(ID,Rejection_Qty,Rejection_Reason,UpdatedBy,UpdatedTS)
Select ShiftProdid,SUM(RejectionQty),Rejectionreason,'PCT',getdate() from #TempShiftRejection
where  shiftprodid > 0 group by ShiftProdid,Rejectionreason

insert into aggregate_Error(errno,machineid,StartDate,remarks)
Select Distinct Pa_id,PA_MachineID,PA_date,'Rejection Qty greater than Accepted Parts.' from #TempProdAccepted
Where PA_ExtraRejQty>0
----ER0202


--ER0349 Commented From Here
-- set @recordid= ''
-- set @recordid = (select max(recordid) from #TempShiftRejection where shiftprodid<>0)
-- If @recordid <> ''
-- begin
-- insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS,Recordid)
-- select SP_Machineid,SR_Shift,getdate(),'20', SDTimestamp,dateadd(s,10,SDTimestamp),getdate(),@recordid from #TempShiftRejection
-- where recordid=@recordid
-- end
--ER0349 Commented From Here
--ER0332  Added Till Here

--ER0349 Added From Here 
Declare @MReworkdate as datetime
declare @maxMreworkid as nvarchar(500)

Set @MReworkdate = @date

--set @maxMreworkid = (select isnull(max(recordid),0) from shiftaggtrail where datatype=25)--DR0359 Commented
--DR0359 Added satya

--DR0371 commented and Added From Here
--insert into #Temp_MC_LastAggRework (MachineId, MaxReworkID)--vasavi--DR0359
--select T1.AMachine,isnull(max(T2.recordid),0) as recordid from #TempMCOODown2 T1 LEFT OUTER join ShiftAggTrail T2 on T1.AMachine = T2.machineid 
--Where T2.Datatype = 25 OR T2.Datatype is null  group by T1.AMachine


insert into #Temp_MC_LastAggRework (MachineId, MaxReworkID)
select T1.AMachine,0 from #TempMCOODown2 T1 

Update #Temp_MC_LastAggRework set MaxReworkID=T.recordid from
(select T1.MachineId,isnull(max(T2.recordid),0) as recordid from #Temp_MC_LastAggRework T1 left outer join ShiftAggTrail T2 on T1.MachineId = T2.machineid 
Where T2.Datatype = 25 OR T2.Datatype is null group by T1.MachineId)T inner join #Temp_MC_LastAggRework on #Temp_MC_LastAggRework.MachineId=T.MachineId
--DR0371 Added Till Here

delete from #ShiftDetails

----ER0202
--while @MReworkdate<=@enddate
--Begin
--INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
 
--Exec  s_GetShiftTime @Date,''
--set @MReworkdate = dateadd(d,1,@MReworkdate)
--end
----ER0202

-----ER0202 Added From Here
Declare @AggRewEndDate as datetime
Select @AggRewEndDate = Case when Datepart(YEAR,@Enddate)='9999' then Dateadd(Day,3,@Date) else @Enddate END
while @MReworkdate<=@AggRewEndDate
Begin
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)	
	Exec  s_GetShiftTime @MReworkdate,''
	set @MReworkdate = dateadd(d,1,@MReworkdate)
end
-----ER0202 Added Till Here



update #ShiftDetails set shiftid = T1.shiftid
from (select distinct shiftname,shiftid from shiftdetails where running=1)T1
inner join #ShiftDetails on #ShiftDetails.shift=T1.shiftname

--DR0359 Commented TODO
/*
Select @MRework=''
Select @MRework='Insert into #TempShiftRework(SR_Pdate,SR_Shift,SP_Machineid,SR_Mach_interface,Sp_Componentid,SR_Comp_interface,Sp_Opn,SR_Operation_interface,Sp_Oprtor,SR_Oprtor_interface,
Reworkreason,ReworkQty,SDTimestamp,Recordid) Select #ShiftDetails.pdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
Reworkinformation.Reworkid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid From #ShiftDetails,AutodataRejections
inner join Reworkinformation on Reworkinformation.reworkinterfaceid=isnull(AutodataRejections.Rejection_Code,''9999'')
inner join EmployeeInformation on AutodataRejections.opr=EmployeeInformation.interfaceid
inner join machineinformation on AutodataRejections.mc=machineinformation.Interfaceid
left outer join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
inner join componentinformation on AutodataRejections.comp=componentinformation.Interfaceid
inner join  componentoperationpricing on (AutodataRejections.opn=componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid)
and machineinformation.machineid = componentoperationpricing.machineid
where AutodataRejections.CreatedTs>=#ShiftDetails.ShiftStart and AutodataRejections.CreatedTs<=#ShiftDetails.ShiftEnd and
AutodataRejections.Rejdate=''1900-01-01 12:00:00 AM'' and AutodataRejections.RejShift is NUll
and AutodataRejections.recordid > ''' + @maxMreworkid + ''' and  AutodataRejections.flag = ''MarkedforRework''
group by #ShiftDetails.pdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid ,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
Reworkinformation.Reworkid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid'
print(@MRework)  
exec (@MRework)
*/
--DR0359 Added from here
Insert into #TempShiftRework(SR_Pdate,SR_Shift,SP_Machineid,SR_Mach_interface,Sp_Componentid,SR_Comp_interface,Sp_Opn,SR_Operation_interface,Sp_Oprtor,SR_Oprtor_interface,
Reworkreason,ReworkQty,SDTimestamp,Recordid,WorkOrderNumber) Select #ShiftDetails.pdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
Reworkinformation.Reworkid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid,AutodataRejections.WorkOrderNumber From #ShiftDetails,AutodataRejections
inner join Reworkinformation on Reworkinformation.reworkinterfaceid=isnull(AutodataRejections.Rejection_Code,'9999')
inner join EmployeeInformation on AutodataRejections.opr=EmployeeInformation.interfaceid
inner join machineinformation on AutodataRejections.mc=machineinformation.Interfaceid
left outer join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
inner join componentinformation on AutodataRejections.comp=componentinformation.Interfaceid
inner join  componentoperationpricing on (AutodataRejections.opn=componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid)
and machineinformation.machineid = componentoperationpricing.machineid
INNER JOIN #Temp_MC_LastAggRework on #Temp_MC_LastAggRework.Machineid = machineinformation.Machineid
where AutodataRejections.CreatedTs>=#ShiftDetails.ShiftStart and AutodataRejections.CreatedTs<=#ShiftDetails.ShiftEnd and
--AutodataRejections.Rejdate='1900-01-01 12:00:00 AM' and AutodataRejections.RejShift is NUll --ER0202
AutodataRejections.Rejdate='1900-01-01 00:00:00' and AutodataRejections.RejShift is NUll --ER0202
and AutodataRejections.recordid > #Temp_MC_LastAggRework.MaxReworkId --DR0359
 and  AutodataRejections.flag = 'MarkedforRework'
group by #ShiftDetails.pdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid ,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
Reworkinformation.Reworkid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid,AutodataRejections.WorkOrderNumber
--DR0359 Added till here




--DR0359 Commented TODO
/*
Select @MRework=''
Select @MRework='Insert into #TempShiftRework(SR_Pdate,SR_Shift,SP_Machineid,SR_Mach_interface,Sp_Componentid,SR_Comp_interface,Sp_Opn,SR_Operation_interface,Sp_Oprtor,SR_Oprtor_interface,
Reworkreason,ReworkQty,SDTimestamp,Recordid)  (Select AutodataRejections.Rejdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
Reworkinformation.Reworkid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid From AutodataRejections
inner join Reworkinformation on Reworkinformation.reworkinterfaceid=isnull(AutodataRejections.Rejection_Code,''9999'')
inner join #ShiftDetails on AutodataRejections.RejShift = #ShiftDetails.shiftid
inner join EmployeeInformation on AutodataRejections.opr=EmployeeInformation.interfaceid
inner join machineinformation on AutodataRejections.mc=machineinformation.Interfaceid
left outer join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
inner join componentinformation on AutodataRejections.comp=componentinformation.Interfaceid
inner join  componentoperationpricing on (AutodataRejections.opn=componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid)
and machineinformation.machineid = componentoperationpricing.machineid
where AutodataRejections.Rejdate<>''1900-01-01 12:00:00 AM'' and AutodataRejections.RejShift is not NUll
and AutodataRejections.recordid > ''' + @maxMreworkid + ''' and  AutodataRejections.flag = ''MarkedforRework''
group by AutodataRejections.Rejdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid ,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
Reworkinformation.Reworkid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid)'
print(@MRework)  
exec(@MRework)
*/

--DR0359-Added
Insert into #TempShiftRework(SR_Pdate,SR_Shift,SP_Machineid,SR_Mach_interface,Sp_Componentid,SR_Comp_interface,Sp_Opn,SR_Operation_interface,Sp_Oprtor,SR_Oprtor_interface,
Reworkreason,ReworkQty,SDTimestamp,Recordid,WorkOrderNumber)  Select AutodataRejections.Rejdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
Reworkinformation.Reworkid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid,AutodataRejections.WorkOrderNumber From AutodataRejections
inner join Reworkinformation on Reworkinformation.reworkinterfaceid=isnull(AutodataRejections.Rejection_Code,'9999')
inner join #ShiftDetails on AutodataRejections.RejShift = #ShiftDetails.shiftid
inner join EmployeeInformation on AutodataRejections.opr=EmployeeInformation.interfaceid
inner join machineinformation on AutodataRejections.mc=machineinformation.Interfaceid
left outer join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
inner join componentinformation on AutodataRejections.comp=componentinformation.Interfaceid
inner join  componentoperationpricing on (AutodataRejections.opn=componentoperationpricing.InterfaceID)
AND (componentinformation.componentid = componentoperationpricing.componentid)
and machineinformation.machineid = componentoperationpricing.machineid
INNER JOIN #Temp_MC_LastAggRework on #Temp_MC_LastAggRework.Machineid = machineinformation.Machineid
--where AutodataRejections.Rejdate<>'1900-01-01 12:00:00 AM' and AutodataRejections.RejShift is not NUll --ER0202
where AutodataRejections.Rejdate<>'1900-01-01 00:00:00' and AutodataRejections.RejShift is not NUll --ER0202
and AutodataRejections.recordid > #Temp_MC_LastAggRework.MaxReworkId --DR0359
 and  AutodataRejections.flag = 'MarkedforRework'
group by AutodataRejections.Rejdate,#ShiftDetails.Shift,machineinformation.Machineid,machineinformation.Interfaceid,
componentinformation.Componentid,componentinformation.Interfaceid,componentoperationpricing.Operationno,
componentoperationpricing.Interfaceid ,EmployeeInformation.Employeeid,EmployeeInformation.Interfaceid,
Reworkinformation.Reworkid,AutodataRejections.Rejection_Qty,AutodataRejections.CreatedTS,AutodataRejections.Recordid,AutodataRejections.WorkOrderNumber
--DR0359-Added

Select @strsql=''
Select @strsql=@strsql +'insert into #TempProdAccepted1
(
PA_Date,
PA_Shift,
PA_MachineID,
PA_ComponentID,
PA_OperationNo,
PA_OperatorID,
PA_Accepted,
PA_id,
PA_MReworkQty,
PA_workordernumber
)'
Select @strsql=@strsql +'Select distinct SPD.Pdate,SPD.shift,SPD.MachineID,SPD.ComponentID,SPD.OperationNo,
SPD.OperatorID,SPD.Acceptedparts,SPD.id,SPD.Marked_for_Rework,SPD.workordernumber from ShiftProductionDetails  SPD
inner join #TempShiftRework SRD on SPD.MachineID= SRD.SP_Machineid
and SPD.ComponentID=SRD.Sp_Componentid and SPD.OperationNo=SRD.Sp_Opn and
SPD.OperatorID=SRD.Sp_Oprtor and SPD.pdate=SRD.SR_Pdate and SPD.shift=SRD.SR_Shift and SPD.workordernumber=SRD.workordernumber
order by SPD.id'
exec(@strsql)


/* ER0202
declare @MReworkQty as int
declare @Mreworkmachine as nvarchar(50)
declare @SPDMReworkQty as int
declare @Markedreworkdate as datetime,@Markedreworkshift as nvarchar(50) --DR0329 Added
declare @Mreworkcomp as nvarchar(50),@Mreworkopn as nvarchar(50),@Mreworkopr as nvarchar(50)  --DR0329 Added

set @AcpQty=''
set @SPid =''
set @recordid=''
set @SPDMReworkQty=''
--DR0329 Added From here
set @Markedreworkdate='' 
set @Markedreworkshift=''
set @MReworkQty=''
set @Mreworkmachine=''
set @Mreworkcomp=''
set @Mreworkopn=''
set @Mreworkopr=''
 --DR0329 Added Till here

 --DR0359 commented below
 /*
set @AcpQty = (select top 1 PA_Accepted  from #TempProdAccepted1 order by Pa_id)

set @SPDMReworkQty = (select top 1 PA_MReworkQty from #TempProdAccepted1 order by Pa_id)
set @SPid  = (select top 1 Pa_id from #TempProdAccepted1 order by Pa_id)

--set @MReworkQty = (select top 1 ReworkQty from #TempShiftRework order by recordid) --DR0329 commented
--set @recordid = (select top 1 isnull(recordid,0) from #TempShiftRework order by recordid)--DR0329 commented
--set @Mreworkmachine = (select top 1 SP_Machineid from #TempShiftRework order by recordid)--DR0329 commented
----DR0329 Added From here
set @recordid = (select top 1 isnull(recordid,0) from #TempShiftRework order by SR_Pdate,SR_Shift,recordid)  
*/
---------------------------- DR0359 added below
set @acpqty = (select top 1 PA_Accepted from #TempProdAccepted1  SPD
inner join #TempShiftRework SRD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where PA_Accepted<>0 and SRD.shiftprodid=0 order by Pa_id,recordid)
print @acpqty

set @SPDMReworkQty = (select top 1 PA_MReworkQty from #TempProdAccepted1  SPD
inner join #TempShiftRework SRD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where PA_Accepted<>0 and SRD.shiftprodid=0 order by Pa_id,recordid)
print @SPDMReworkQty

set @spid = (select top 1 PA_id from #TempProdAccepted1 SPD
inner join #TempShiftRework SRD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where PA_Accepted<>0 and SRD.shiftprodid=0  order by Pa_id,recordid)
print @spid

set @recordid = (select top 1  isnull(recordid,0) from #TempShiftRework SRD
inner join #TempProdAccepted1 SPD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pA_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where shiftprodid=0 order by Pa_id,recordid)--DR0329 added
print @recordid
----------------------------------

set @MReworkQty = (select ReworkQty from #TempShiftRework where recordid=@recordid) 
set @Mreworkmachine = (select SP_Machineid from #TempShiftRework where recordid=@recordid)
set @Markedreworkdate = (select SR_Pdate from #TempShiftRework where recordid=@recordid)
set @Markedreworkshift = (select SR_Shift from #TempShiftRework where recordid=@recordid)
set @Mreworkcomp = (select Sp_Componentid from #TempShiftRework where recordid=@recordid)
set @Mreworkopn = (select Sp_Opn from #TempShiftRework where recordid=@recordid)
set @Mreworkopr = (select Sp_Oprtor from #TempShiftRework where recordid=@recordid)
----DR0329 Added Til Here

while @recordid <>  0
begin

Update #TempProdAccepted1 set PA_Accepted= @acpqty-@MReworkQty,PA_MReworkQty=@SPDMReworkQty+ @MReworkQty
-- where Pa_id = @spid and @acpqty>=@MReworkQty --DR0329 commented
where pa_date=@Markedreworkdate and pa_shift=@Markedreworkshift and
PA_MachineID=@Mreworkmachine and PA_ComponentID=@Mreworkcomp and PA_OperationNo=@Mreworkopn and PA_OperatorID= @Mreworkopr 
and Pa_id = @spid and @acpqty>=@MReworkQty --DR0329 Added
If @@Rowcount<>0  --DR0329 Added
Begin --DR0329 added
Update #TempShiftRework set ShiftProdid =
case when @acpqty>=@MReworkQty then @spid else '-1' end where recordid=@recordid
END ---DR0329 Added
--DR0329 Added From here
If @@Rowcount = 0   
begin
 
Update #TempShiftRework set ShiftProdid = '-1' where recordid=@recordid
end       
--DR0329 Added Till here


If @acpqty < @MReworkQty
begin
insert into aggregate_Error(errno,machineid,StartDate,EndDate,remarks)
values(@spid,@Mreworkmachine,@Date,@EndDate,'Marked_For_Rework Qty greater than Accepted Parts.')
end


set @acpqty = ''
set @spid = ''
set @MReworkQty = ''
set @Mreworkmachine = ''
set @SPDMReworkQty = ''
set @Markedreworkdate='' --DR0329 added
set @Markedreworkshift='' --DR0329 added
set @recordid='' --DR0329 Added
set @Mreworkcomp = '' --DR0329 Added
set @Mreworkopn ='' --DR0329 Added
set @Mreworkopr ='' --DR0329 Added

set @acpqty = (select top 1 PA_Accepted from #TempProdAccepted1  SPD
inner join #TempShiftRework SRD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where PA_Accepted<>0 and SRD.shiftprodid=0 order by Pa_id,recordid) --DR0359
--where PA_Accepted<>0 and SRD.shiftprodid=0 order by Pa_id)
print @acpqty

set @SPDMReworkQty = (select top 1 PA_MReworkQty from #TempProdAccepted1  SPD
inner join #TempShiftRework SRD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where SRD.shiftprodid=0 order by Pa_id,recordid) --DR0359
--where SRD.shiftprodid=0 order by Pa_id)
print @SPDMReworkQty

set @spid = (select top 1 PA_id from #TempProdAccepted1 SPD
inner join #TempShiftRework SRD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where PA_Accepted<>0 and SRD.shiftprodid=0  order by Pa_id,recordid) --DR0359
--where PA_Accepted<>0 and SRD.shiftprodid=0  order by Pa_id)
print @spid

--DR0329 Commented From here
-- set @MReworkQty = (select top 1  ReworkQty from #TempShiftRework SRD
-- inner join #TempProdAccepted1 SPD on SPD.pa_MachineID= SRD.SP_Machineid
-- and SPD.pa_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
-- SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
-- where shiftprodid=0 order by recordid)
-- print @MReworkQty
--DR0329 Commented Till here

set @recordid = (select top 1  isnull(recordid,0) from #TempShiftRework SRD
inner join #TempProdAccepted1 SPD on SPD.pa_MachineID= SRD.SP_Machineid
and SPD.pA_ComponentID=SRD.Sp_Componentid and SPD.pa_OperationNo=SRD.Sp_Opn and
SPD.pa_OperatorID=SRD.Sp_Oprtor and SPD.pa_date=SRD.SR_Pdate and SPD.pa_shift=SRD.SR_Shift
where shiftprodid=0 order by Pa_id,recordid)   --DR0359
--where shiftprodid=0 order by SR_Pdate,SR_Shift,recordid)--DR0329 added
print @recordid
set @Mreworkmachine=(select SP_Machineid from #TempShiftRework where recordid=@recordid)
print @Mreworkmachine

set @Markedreworkdate = (select SR_Pdate from #TempShiftRework where recordid=@recordid)--DR0329 Added
print @Markedreworkdate

set @Markedreworkshift = (select SR_Shift from #TempShiftRework where recordid=@recordid)--DR0329 Added
print @Markedreworkshift

set @MReworkQty = (select ReworkQty from #TempShiftRework where recordid=@recordid) --DR0329 Added
print @MReworkQty

set @Mreworkcomp = (select Sp_Componentid from #TempShiftRework where recordid=@recordid)--DR0329 Added
print @Mreworkcomp

set @Mreworkopn = (select Sp_Opn from #TempShiftRework where recordid=@recordid)--DR0329 Added
print @Mreworkopn

set @Mreworkopr = (select Sp_Oprtor from #TempShiftRework where recordid=@recordid)--DR0329 Added
print @Mreworkopr
end


Update dbo.ShiftProductionDetails set AcceptedParts= PA_Accepted,Marked_for_rework=PA_MReworkQty from #TempProdAccepted1
inner join ShiftProductionDetails Sp on #TempProdAccepted1.Pa_id=sp.id

insert into ShiftReworkDetails(ID,Rework_Qty,Rework_Reason,UpdatedBy,UpdatedTS)
Select ShiftProdid,ReworkQty,Reworkreason,'PCT',getdate() from #TempShiftRework
where  shiftprodid > 0 -- DR0359 commented
--where  shiftprodid<>'0' and shiftprodid<>'-1'  and recordid > @maxMreworkid
*/


---ER0202
Update #TempProdAccepted1 set PA_Accepted= ISNULL(SPD.PA_Accepted,0)-ISNULL(SRD.Rewqty,0),PA_MReworkQty=ISNULL(PA_MReworkQty,0)+ ISNULL(SRD.Rewqty,0),PA_ExtraRewQty = ISNULL(SRD.ExtraRewqty,0) From
(
	select SRD.SP_Machineid,SRD.Sp_Componentid,SRD.Sp_Opn,SRD.Sp_Oprtor,SRD.SR_Pdate,SRD.SR_Shift,SRD.WorkOrderNumber,
	Case WHEN (ISNULL(SUM(SPD.PA_Accepted),0)>0 and ISNULL(SUM(SPD.PA_Accepted),0)>=ISNULL(SUM(SRD.ReworkQty),0)) THEN SUM(SRD.ReworkQty) 
	When (ISNULL(SUM(SPD.PA_Accepted),0)>0 and ISNULL(SUM(SPD.PA_Accepted),0)<ISNULL(SUM(SRD.ReworkQty),0)) THEN SUM(SPD.PA_Accepted) END as Rewqty,
	Case When (ISNULL(SUM(SPD.PA_Accepted),0)>0 and ISNULL(SUM(SPD.PA_Accepted),0)<ISNULL(SUM(SRD.ReworkQty),0)) THEN (ISNULL(SUM(SRD.ReworkQty),0)-ISNULL(SUM(SPD.PA_Accepted),0)) else 0 END as ExtraRewqty from 
		(
			Select SP_Machineid,Sp_Componentid,Sp_Opn,Sp_Oprtor,SR_Pdate,SR_Shift,SUM(ReworkQty) as ReworkQty,WorkOrderNumber from #TempShiftRework
			group by SP_Machineid,Sp_Componentid,Sp_Opn,Sp_Oprtor,SR_Pdate,SR_Shift,WorkOrderNumber
		) SRD 
	inner join #TempProdAccepted1 SPD on SPD.PA_MachineID= SRD.SP_Machineid and SPD.PA_ComponentID=SRD.Sp_Componentid and SPD.PA_OperationNo=SRD.Sp_Opn and
	SPD.PA_OperatorID=SRD.Sp_Oprtor and SPD.PA_date=SRD.SR_Pdate and SPD.PA_Shift=SRD.SR_Shift
	Group by SRD.SP_Machineid,SRD.Sp_Componentid,SRD.Sp_Opn,SRD.Sp_Oprtor,SRD.SR_Pdate,SRD.SR_Shift,SRD.WorkOrderNumber
)SRD
inner join #TempProdAccepted1 SPD on SPD.PA_MachineID= SRD.SP_Machineid
and SPD.PA_ComponentID=SRD.Sp_Componentid and SPD.PA_OperationNo=SRD.Sp_Opn and
SPD.PA_OperatorID=SRD.Sp_Oprtor and SPD.PA_date=SRD.SR_Pdate and SPD.PA_Shift=SRD.SR_Shift and SPD.PA_WorkOrderNumber=SRD.WorkOrderNumber --where (SPD.PA_Accepted<>0 and SPD.PA_Accepted>=SRd.Rewqty)

Update #TempShiftRework set ShiftProdid= ISNULL(SRD.ShiftProdid,0)+ISNULL(T1.ProdId,0) From
(select SRD.SP_Machineid,SRD.Sp_Componentid,SRD.Sp_Opn,SRD.Sp_Oprtor,SRD.SR_Pdate,SRD.SR_Shift,SPD.Pa_id as ProdId,SRD.WorkOrderNumber from #TempShiftRework SRD 
inner join #TempProdAccepted1 SPD on SPD.PA_MachineID= SRD.SP_Machineid
and SPD.PA_ComponentID=SRD.Sp_Componentid and SPD.PA_OperationNo=SRD.Sp_Opn and
SPD.PA_OperatorID=SRD.Sp_Oprtor and SPD.PA_date=SRD.SR_Pdate and SPD.PA_Shift=SRD.SR_Shift 
and SPD.PA_WorkOrderNumber=SRD.WorkOrderNumber
where (SPD.PA_Accepted<>0 and SPD.PA_Accepted>SRD.ReworkQty)
)T1 inner join #TempShiftRework SRD on T1.SP_Machineid= SRD.SP_Machineid and T1.Sp_Componentid=SRD.Sp_Componentid and T1.Sp_Opn=SRD.Sp_Opn and
T1.Sp_Oprtor=SRD.Sp_Oprtor and T1.SR_Pdate=SRD.SR_Pdate and T1.SR_Shift=SRD.SR_Shift and T1.WorkOrderNumber=SRD.WorkOrderNumber

Update dbo.ShiftProductionDetails set AcceptedParts= PA_Accepted,Marked_for_rework=PA_MReworkQty from #TempProdAccepted1
inner join ShiftProductionDetails Sp on #TempProdAccepted1.Pa_id=sp.id
 
 insert into ShiftReworkDetails(ID,Rework_Qty,Rework_Reason,UpdatedBy,UpdatedTS)
Select ShiftProdid,SUM(ReworkQty),Reworkreason,'PCT',getdate() from #TempShiftRework
where  shiftprodid > 0 group by ShiftProdid,Reworkreason

insert into aggregate_Error(errno,machineid,StartDate,remarks)
Select Pa_id,PA_MachineID,PA_date,'Marked_For_Rework Qty greater than Accepted Parts.' from #TempProdAccepted1
where PA_ExtraRewQty>0
----ER0202


--ER0349  Added Till Here
select @StrSql=''
select @StrSql=' insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS)
--select @machineid,@Shift,@Date,2,@MaxSttime,@Maxndtime,getdate()
select T.Amachine,T.MShift,T.Mdate,datatype,max(A.msttime),
case when max(A.ndtime)>T.MShiftEnd then T.MShiftEnd else max(A.ndtime) end ,''' + convert(nvarchar(20),getdate(),120)+'''
from machineinformation M inner join #TempMCOODown T on T.Amachine=M.machineid
inner join #T_autodata A on M.interfaceid=A.mc ---SV
--from autodata A inner join machineinformation M
--on M.interfaceid=A.mc
--inner join #TempMCOODown T on T.Amachine=M.machineid
WHERE
((A.mStTime>=T.MShiftStart And A.ndTime<=T.MShiftEnd)
OR(A.mStTime<T.MShiftStart And A.ndTime>T.MShiftStart And A.ndTime<=T.MShiftEnd)
OR(A.mStTime>=T.MShiftStart And A.mStTime<T.MShiftEnd And A.ndTime>T.MShiftEnd)
OR(A.mStTime<T.MShiftStart And A.ndTime>T.MShiftEnd) )'
SELECT @StrSql = @StrSql + ' and A.mStTime >= T.LastAggstart '
--SELECT @StrSql = @StrSql + ' and A.datatype=2 '
---and M.machineid='''+ @machineid +'''
select @StrSql=@StrSql + 'group by datatype,T.AMachine,T.MShift,T.Mdate,T.MShiftEnd'
print @strsql
exec (@StrSql)


Declare @AggTrailInsertcount as int
Set @AggTrailInsertcount = @@ROWCOUNT


If @AggTrailInsertcount = 0
Begin

Select Machineid,Max(endtime) as Endtime Into #LastAggTrail from ShiftAggTrail group by Machineid

--DR0389 Commented For INAC BRASSS
--insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS)
--Select T.Amachine,T.MShift,T.Mdate,'1',Max(T.MShiftStart),Max(T.MShiftEnd),getdate() from 
--#TempMCOODown T where exists (Select * from #LastAggTrail S where T.AMachine=S.Machineid AND T.MShiftEnd>S.Endtime) 
--group by T.Amachine,T.MShift,T.Mdate

insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS)
Select T.Amachine,T.MShift,T.Mdate,'1',Max(T.MShiftStart),Max(T.MShiftEnd),getdate() from 
#TempMCOODown T where exists (Select * from #LastAggTrail S where T.AMachine=S.Machineid AND Datediff(day,S.Endtime,T.MShiftEnd)>30) 
group by T.Amachine,T.MShift,T.Mdate
--DR0389 Commented & Added For INAC BRASSS

End


--DR0359 update ShiftAggTrail for type 20 for each mc,date and shift  -->maxRecordId
 insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS,Recordid)
 select T.SP_Machineid,T.SR_Shift,T.SR_PDate,'20', T.SDTimestamp,dateadd(s,10,T.SDTimestamp),getdate(),T.recordid from #TempShiftRejection T
 Inner join ( select SP_Machineid,max(recordid) as recordid from #TempShiftRejection  where  shiftprodid<>'0' group by SP_Machineid,SR_Pdate,SR_Shift)T1 
 on T.SP_Machineid = T1.SP_Machineid and T.recordid = T1.Recordid


  --DR0359 update ShiftAggTrail for type 25 
 insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS,Recordid)
 select T.SP_Machineid,T.SR_Shift,T.SR_PDate,'25', T.SDTimestamp,dateadd(s,10,T.SDTimestamp),getdate(),T.recordid from #TempShiftRework T
 Inner join ( select SP_Machineid,max(recordid) as recordid from #TempShiftRework  where  shiftprodid<>'0' group by SP_Machineid,SR_Pdate,SR_Shift)T1 
 on T.SP_Machineid = T1.SP_Machineid and T.recordid = T1.Recordid
 

--DR0359 commente below 
/*
    --ER0349 Added From Here
set @recordid= ''
set @recordid = (select max(recordid) from #TempShiftRejection where shiftprodid<>0)

If @recordid <> ''
begin
 
Declare @AggRefMachine as nvarchar(50)
Declare @Aggrefdate as datetime

set @AggRefMachine = ''
set @AggRefMachine = (select SP_Machineid from #TempShiftRejection where recordid=@recordid)

set @Aggrefdate=''
set @Aggrefdate = (select max(aggdate) from shiftaggtrail where machineid=@AggRefMachine)

If @Aggrefdate<>''
begin
insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS,Recordid)
select SP_Machineid,SR_Shift,@Aggrefdate,'20', SDTimestamp,dateadd(s,10,SDTimestamp),getdate(),@recordid from #TempShiftRejection
where recordid=@recordid
end
end

--ER0349 Added From Here
set @recordid= ''
set @recordid = (select max(recordid) from #TempShiftRework where shiftprodid<>0)

If @recordid <> ''
begin
 
Declare @AggRefMachine1 as nvarchar(50)
Declare @Aggrefdate1 as datetime

set @AggRefMachine1 = ''
set @AggRefMachine1 = (select SP_Machineid from #TempShiftRework where recordid=@recordid)

set @Aggrefdate1=''
set @Aggrefdate1 = (select max(aggdate) from shiftaggtrail where machineid=@AggRefMachine1)

If @Aggrefdate1<>''
begin
insert into ShiftAggTrail(MachineId,Shift,Aggdate,datatype,Starttime,endtime,AggregateTS,Recordid)
select SP_Machineid,SR_Shift,@Aggrefdate1,'25', SDTimestamp,dateadd(s,10,SDTimestamp),getdate(),@recordid from #TempShiftRework
where recordid=@recordid
end
end
--ER0349 Added From Here
*/

---mod 4(3)
set @ErrNo=@@ERROR
IF @ErrNo <> 0 GOTO ERROR_HANDLER
---MOD 4(3)
END
ELSE
IF @Type='DELETE'
BEGIN
SELECT @StrSql='Delete from ShiftRejectionDetails where ID IN(Select ID From ShiftProductionDetails Where pDate='''+Convert(NvarChar(20),@Date)+'''  and Shift='''+@Shift+''''+@strPlantID+@strMachine+' )'
exec(@StrSql)
--ER0349 from Here
SELECT @StrSql=''
SELECT @StrSql='Delete from ShiftReworkDetails where ID IN(Select ID From ShiftProductionDetails Where pDate='''+Convert(NvarChar(20),@Date)+'''  and Shift='''+@Shift+''''+@strPlantID+@strMachine+' )'
print @strsql
exec(@StrSql)
--ER0349 Till here

SELECT @StrSql=''
---mod 6
-- SELECT @StrSql='Delete from ShiftProductionDetails where pDATE='''+Convert(NvarChar(20),@Date)+''' AND SHIFT='''+@Shift+''''
SELECT @StrSql='Delete from ShiftProductionDetails where pDATE='''+Convert(NvarChar(20),@Date)+''' AND SHIFT=N'''+@Shift+''''
---mod 6
SELECT @StrSql=@StrSql+@strPlantID+@strMachine
exec(@StrSql)
delete from shiftdowntimedetails where ddate=@Date and shift=@Shift and machineid=@machineid
--********************************************************
END
---MOD 4(3)
while @@TRANCOUNT <> 0
COMMIT TRANSACTION
RETURN 
ERROR_HANDLER:
IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
select @ErrNo
insert into aggregate_Error(ErrNo,Machineid,StartDate,EndDate)
values(@ErrNo,@MachineID,@Date,@EndDate)
RETURN
---MOD 4(3)
END
