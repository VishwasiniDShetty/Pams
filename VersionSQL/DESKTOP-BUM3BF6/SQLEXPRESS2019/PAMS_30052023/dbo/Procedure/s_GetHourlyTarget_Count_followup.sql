/****** Object:  Procedure [dbo].[s_GetHourlyTarget_Count_followup]    Committed by VersionSQL https://www.versionsql.com ******/

/***********************************************************************************    
Procedure written by Mrudula on 04-Feb-2009.For ER0170.    
Generate a report that gives hourwise target and actual count alung with the graph.    
Graph should display actual and target values at hour level.The report should be generated for    
the selected date , shift  and machine.    
ER0210-KarthikG-17/Dec/2009 :: Apply PDT.    
ER0214-KarthikG-17/Dec/2009 ::    
SmartManager -> Standard Report -> ProductionReport Machinewise-> Hour -> "BOSCH_BNG_CamShaft" (New format)    
New Excel report - Hourly count with ChangeOver, TechnicalFailure, OrganisationalLoss losses.    
Note :- if target or actual exceeds 120 it will be considered as 120.    
In general Technical Failure, OrganisationalLoss, ChangeOver are not calculated.    
These things are calculated only for 'BOSCH_BNG_CamShaft' parameter.    
ER0245 - 26/Aug/2010 - Karthikg :: New Excel Report in SM->Standard->Prod Report Machinewise-> hour-> BOSCH_HourlyCountWithAE_Losses (Format).    
Procedure 's_GetHourlyTarget_Count_followup' has been altered to add new parameter 'BOSCH_BNG_AELosses'    
ER0316 - SnehaK - 19/Dec/2011 :: To Apply Prediction Logic To Calculate Target based on %ideal.    
ER0321 - Karthik R - 19/Jan/2012 :: To round off target value  based on %ideal.    
ER0353 - SwathiKS - 20/Apr/2013 :: To introduce New Parameter "BOSCH_Nashik_AELosses" to show Downtime at Downid Level.    
                                   To enable Single shift.    
DR0372 - SwathiKS - 22/Jan/2016 :: To handle downtimes which are not reflecting in report for Bosch BNG .    
ER0503 - swathiKS - 16/Mar/2021 :: Bosch: To Include Hourwise Spindle1, Spindle2, Spindle3 RejectionCount

exec s_GetHourlyTarget_Count_followup '2017-01-14','2017-01-15','CNC GRINDING','',''    
exec s_GetHourlyTarget_Count_followup '2017-01-14','2017-01-15','CNC GRINDING','','BOSCH_BNG_CamShaft'    
exec s_GetHourlyTarget_Count_followup '2017-01-14','2017-01-14','CNC GRINDING','','BOSCH_BNG_AELosses' --Pass Same day    
s_GetHourlyTarget_Count_followup '2020-01-10','2020-01-10','Rota_1724','','BOSCH_BNG_RejCount' --Pass Same day    
***********************************************************************************/    
CREATE PROCEDURE [dbo].[s_GetHourlyTarget_Count_followup]    
 @StartDate datetime,    
 @EndDate datetime,    
 @MachineID nvarchar(50) = '',    
 @Shift nvarchar(50)='',    
 @Param nvarchar(50)=''--'','BOSCH_BNG_CamShaft','BOSCH_BNG_AELosses'    
AS    
BEGIN    
    
Declare @CurStrtTime as datetime      
declare @sqlstr as nvarchar(4000)    
    
 Create Table #ShiftTemp    
 (     
  Machineid nvarchar(50),    
  machineinterface nvarchar(50),    
  PDate datetime,    
  ShiftName nvarchar(20),    
  ShiftID int,    
  HourName nvarchar(50),    
  HourID int,    
  FromTime datetime,    
  ToTime Datetime,    
  Target float,    
  Actual float,    
  ChangeOver int default 0,    
  TechnicalFailure int default 0,    
  OrganisationalLoss int default 0,    
  Maxenergy float,    
  Minenergy float,    
  KWH float,
  Spindle1RejCount float default 0,
  Spindle2RejCount float default 0,   
  Spindle3RejCount float default 0    
 )    
     
 Create Table #PDT    
 (     
  Machineid nvarchar(50),    
  machineinterface nvarchar(50),    
  FromTime datetime,    
  ToTime Datetime,    
  StartTime_PDT Datetime,    
  EndTime_PDT Datetime,    
  DownReason nvarchar(50),    
  Actual float,    
  ChangeOver int,    
  TechnicalFailure int,    
  OrganisationalLoss int    
 )    
--From here ER0316    
CREATE TABLE #Target    
 (    
  MachineID NvarChar(50),    
  MachineInterface nvarchar(50),    
  ComponentID Nvarchar(50),    
  OperationNo Int,    
  sttime Datetime,    
  ndtime Datetime,    
--  StartTime DateTime,    
--  EndTime DateTime    
  hursttime datetime,    
  hurndtime datetime,    
--  shftsttime datetime,    
--  shftndtime datetime    
  hurId int,    
  shftId int,    
  Pdt int    
 )    
CREATE TABLE #Target_actime    
 (    
  MachineInterface nvarchar(50),    
  ComponentID Nvarchar(50),    
  OperationNo Int,    
  sttime Datetime,    
  ndtime Datetime,    
  hurId int,    
  shftId int    
      
 )    
    
    
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
 id  bigint not null    
)    
    
ALTER TABLE #T_autodata    
    
ADD PRIMARY KEY CLUSTERED    
(    
 mc,sttime,ndtime,msttime ASC    
)ON [PRIMARY]    
    
Declare @T_ST AS Datetime     
Declare @T_ED AS Datetime     
    
declare @Targetsource nvarchar(50)    
select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'    
--Till here ER0316    
DECLARE @strsql as varchar(4000)    
DECLARE @strmachine AS nvarchar(250)    
declare @counter as datetime    
declare @stdate as nvarchar(20)    
declare @ShftPL as int    
--From here ER0316    
Declare @curmachineid as nvarchar(50)    
Declare @curcomp  as nvarchar(50)    
Declare @curop  as int    
Declare @cursttime  as Datetime    
Declare @curndtime  as datetime    
Declare @curstarttime  as Datetime    
Declare @curEndtime  as datetime    
Declare @curhursttime as datetime    
Declare @curhurndtime as datetime    
Declare @curhurId as int    
Declare @curshftId as int    
Declare @cmachineid as nvarchar(50)    
Declare @compid  as nvarchar(50)    
Declare @operationid  as int    
Declare @sttime  as Datetime    
Declare @ndtime  as datetime    
Declare @CEndtime  as Datetime    
Declare @CStarttime  as datetime    
Declare @churId as int    
Declare @cshftId as int    
Declare @churndtime as datetime    
Declare @chursttime as datetime    
--Till here ER0316    
    
SELECT @strsql = ''    
SELECT @strmachine = ''    
    
Select @CurStrtTime=@StartDate      
Select @CurEndTime=@EndDate     
    
If @Shift<>'' --ER0353 Added    
Begin         --ER0353 Added    
    
 while @CurStrtTime<=@CurEndTime      
 BEGIN     
    
 select @stdate = CAST(datePart(yyyy,@CurStrtTime) AS nvarchar(4)) + '-' + CAST(datePart(mm,@CurStrtTime) AS nvarchar(2)) + '-' + CAST(datePart(dd,@CurStrtTime) AS nvarchar(2))    
 select @counter=convert(datetime, cast(DATEPART(yyyy,@CurStrtTime)as nvarchar(4))+'-'+cast(datepart(mm,@CurStrtTime)as nvarchar(2))+'-'+cast(datepart(dd,@CurStrtTime)as nvarchar(2)) +' 00:00:00.000')    
    
 ---get the hour definitions for the date and shift    
 insert  #ShiftTemp (Machineid,MachineInterface,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)    
 select @MachineID,(select InterfaceID from MachineInformation where MachineID = @MachineID),    
 @counter,S.ShiftName,S.ShiftID,SH.Hourname,SH.HourID,    
 dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),    
 dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2))))),0,0    
 from shiftdetails S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid    
 where S.running=1 and S.Shiftname=@shift    
    
 SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)    
 END      
          
END    
    
If @Shift='' --ER0353 Added    
Begin         --ER0353 Added    
    
 while @CurStrtTime<=@CurEndTime      
 BEGIN     
    
 select @stdate = CAST(datePart(yyyy,@CurStrtTime) AS nvarchar(4)) + '-' + CAST(datePart(mm,@CurStrtTime) AS nvarchar(2)) + '-' + CAST(datePart(dd,@CurStrtTime) AS nvarchar(2))    
 select @counter=convert(datetime, cast(DATEPART(yyyy,@CurStrtTime)as nvarchar(4))+'-'+cast(datepart(mm,@CurStrtTime)as nvarchar(2))+'-'+cast(datepart(dd,@CurStrtTime)as nvarchar(2)) +' 00:00:00.000')    
    
 ---get the hour definitions for the date and shift    
 insert  #ShiftTemp (Machineid,MachineInterface,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)    
 select @MachineID,(select InterfaceID from MachineInformation where MachineID = @MachineID),    
 @counter,S.ShiftName,S.ShiftID,SH.Hourname,SH.HourID,    
 dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),    
 dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2))))),0,0    
 from shiftdetails S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid    
 where S.running=1     
    
 SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)      
 END      
       
END    
    
    
    
Select @T_ST=Min(FromTime) from #ShiftTemp    
Select @T_ED=Max(ToTime) from #ShiftTemp    
    

Select @strsql=''    
select @strsql ='insert into #T_autodata '    
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'    
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'    
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '    
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '    
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''    
     and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'    
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'    
print @strsql    
exec (@strsql)    
  
    
--From Here ER0316    
IF ISNULL(@Targetsource,'')='% Ideal'    
BEGIN    
    
insert into #target    
Select S.machineid,mc,comp,opn,msttime,ndtime,S.fromtime,S.totime,s.HourID,s.ShiftID,0 from  #ShiftTemp S    
inner join #T_autodata A on S.MachineInterface=A.mc where    
((A.ndtime>=S.fromtime  and  A.ndtime<=S.totime) )    
order by mc,sttime    
    
declare @RptCursor  cursor    
set  @RptCursor= CURSOR FOR    
  SELECT MachineInterface,    
  ComponentID ,    
  OperationNo ,    
  Sttime,ndtime,hurId,shftId    
  from  #target    
  order by MachineInterface,    
  Sttime,ndtime    
  OPEN @RptCursor    
FETCH NEXT FROM @RptCursor INTO @cmachineid, @compid, @operationid,@sttime,@ndtime,@churId,@cshftId    
  if (@@fetch_status = 0)    
  begin    
   -- initialize current variables      
    select @curmachineid = @cmachineid     
    select @curcomp = @compid    
    select @curop = @operationid    
    Select @cursttime=@sttime    
    Select @curndtime=@ndtime    
--    Select @curhursttime=@chursttime    
--    Select @curhurndtime=@churndtime    
    select @curhurId=@churId     
    select @curshftId=@cshftId     
    Select @curstarttime=@cstarttime    
    Select @curendtime=@cendtime    
  end     
 WHILE (@@fetch_status <> -1)    
  BEGIN    
     IF (@@fetch_status <> -2)    
       BEGIN    
     FETCH NEXT FROM @RptCursor INTO @cmachineid, @compid, @operationid,@sttime,@ndtime,@churId,@cshftId    
     if (@@fetch_status = 0) and (@curmachineid = @cmachineid) and (@curcomp = @compid) and (@curop = @operationid)    
      begin    
        Select @curndtime=@ndtime         
      end    
     else if (@@fetch_status = 0)    
      begin    
      insert into #Target_actime    
      Select @curmachineid as mc,@curcomp as comp,@curop as opn,    
       Case  when @cursttime<@curstarttime  then @cstarttime else @cursttime end as start,    
       case when @curndtime>@curendtime then @curendtime Else @curndtime End as  endt,@curhurId,@curshftId    
           
          
      select @curmachineid = @cmachineid     
      select @curcomp = @compid    
      select @curop = @operationid    
      Select @cursttime=@sttime    
      Select @curndtime=@ndtime    
--      Select @curhursttime=@chursttime    
--      Select @curhurndtime=@churndtime    
      select @curhurId=@churId     
      select @curshftId=@cshftId     
     end    
       END    
  END    
insert into #Target_actime    
      Select @curmachineid as mc,@curcomp as comp,@curop as opn,    
       Case  when @cursttime<@curstarttime then @curstarttime else @cursttime end as start,    
       case when @curndtime>@curendtime then @curendtime Else @curndtime End as  endt,    
--       Case  when @cursttime<@curhursttime then @curhursttime else @cursttime end as start,    
--       case when @curndtime>@curhurndtime then @curhurndtime Else @curndtime End as  endt,    
        @curhurId,@curshftId    
close @rptcursor    
deallocate @rptcursor    
    
update #Target_actime set ndtime=t1.Totime from #Target_actime inner join    
(Select #Target_actime.machineinterface,max(#Target_actime.ndtime)as ndtime,max(#ShiftTemp.Totime) as Totime from #Target_actime    
 inner join #ShiftTemp on #ShiftTemp.machineinterface=#Target_actime.machineinterface    
group by #Target_actime.machineinterface--,#ShiftTemp.totime    
)T1    
on T1.machineinterface=#Target_actime.machineinterface and t1.ndtime=#Target_actime.ndtime    
    
delete From #Target    
insert into #Target    
select sh.machineid,sh.machineinterface,t1.componentId,t1.Operationno,    
case when t1.sttime<=sh.Fromtime then sh.fromtime else t1.sttime end as Start,    
case when t1.ndtime>=sh.Totime then sh.totime else t1.ndtime end as Endt,sh.fromtime,sh.totime,sh.hourid,sh.shiftid,0    
from #target_actime t1    
inner join #ShiftTemp Sh on sh.machineinterface=T1.machineinterface    
where-- PDTstatus = 1  and    
((sh.fromTime >= t1.Sttime and sh.toTime <= t1.ndTime)or    
(sh.fromTime < t1.Sttime and sh.toTime > t1.Sttime and sh.toTime <=t1.ndTime)or    
(sh.fromTime >= t1.Sttime and sh.fromTime <t1.ndTime and sh.toTime >t1.ndTime) or    
(sh.fromTime <  t1.Sttime and sh.toTime >t1.ndTime))    
    
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N'    
BEGIN    
update #Target set pdt=t3.pdt    
from (    
Select t2.machineinterface,T2.Machine,T2.sttime,T2.ndtime,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt    
from    
(    
Select T1.*,Pdt.machine,    
Case when  T1.Sttime <= pdt.StartTime then pdt.StartTime else T1.Sttime End as StartTimepdt,    
Case when  T1.ndtime >= pdt.EndTime then pdt.EndTime else T1.ndtime End as EndTimepdt    
from #Target T1    
--inner join #ShiftTemp Sh on sh.machineinterface=T1.machineinterface    
inner join Planneddowntimes pdt on t1.machineid=Pdt.machine    
where PDTstatus = 1  and    
((pdt.StartTime >= t1.Sttime and pdt.EndTime <= t1.ndTime)or    
(pdt.StartTime < t1.Sttime and pdt.EndTime > t1.Sttime and pdt.EndTime <=t1.ndTime)or    
(pdt.StartTime >= t1.Sttime and pdt.StartTime <t1.ndTime and pdt.EndTime >t1.ndTime) or    
(pdt.StartTime <  t1.Sttime and pdt.EndTime >t1.ndTime))    
)T2    
group by  t2.machineinterface,T2.Machine,T2.sttime,T2.ndtime    
) T3    
inner join #Target T on T.machineinterface=T3.machineinterface    
and T.Sttime=T3.Sttime    
and  T.ndtime=T3.ndtime    
--    
End    
--ER0321 from here    
--update #ShiftTemp set target=T1.target    
update #ShiftTemp set target=Round(T1.target,0)    
--ER0321 till here    
from (    
Select  M.machineid,hurId,shftId,    
sum(    
(((datediff(second,T.sttime,T.ndtime)-isnull(pdt,0))*Co.suboperations)/Co.cycletime)*isnull(Co.targetpercent,100) /100) as target    
--select co.*    
from    
#target T    
inner join machineinformation M on M.Interfaceid=T.machineinterface    
inner join componentinformation C on C.interfaceid=T.componentid    
inner join componentoperationpricing CO on M.machineid=co.machineid and c.componentid=Co.componentid    
and Co.interfaceid=T.OperationNo    
group by M.Machineid,hurId,shftId    
)T1 inner join #ShiftTemp on T1.machineid=#ShiftTemp.machineid and T1.hurId=#ShiftTemp.HourId and T1.shftId=#ShiftTemp.ShiftId    
end    
else    
begin    
update #ShiftTemp set target=T1.target from(    
 select sum(SH.target)AS TARGET ,SH.Sdate,SH.hourid,SH.Machineid,    
 SH.Hourstart  as Hourstart ,SH.Hourend as Hourend from    
 shifthourtargets SH where SH.sdate=convert(datetime,@stdate) and SH.Machineid=@MachineID    
 group by SH.Sdate,SH.hourid,SH.Machineid,SH.Hourstart,SH.Hourend    
) as T1 inner join #ShiftTemp on #ShiftTemp.machineid=T1.Machineid and #ShiftTemp.hourid=T1.hourid    
and #ShiftTemp.Fromtime=T1.Hourstart and #ShiftTemp.totime=T1.Hourend    
end    
--Till Here ER0316    
    
    
if isnull(@Param,'') = 'BOSCH_BNG_AELosses'    
Begin    
 Select machineID,MachineInterface,pDate,HourID,ShiftID,FromTime,ToTime,DownCategoryInformation.DownCategory,0 as DownTime,0 as DownTimeByCategory,0 as DownTimeMaxOrder into #AE_Losses    
 from #ShiftTemp cross join DownCategoryInformation order by shiftid,hourid    
 UPDATE #AE_Losses SET DownTime = isnull(DownTime,0) + isNull(t1.down,0) from(    
  select mc,    
  sum(case    
  when autodata.msttime>=#AE_Losses.FromTime and autodata.ndtime<=#AE_Losses.ToTime then loadunload    
  when autodata.sttime<#AE_Losses.FromTime and autodata.ndtime>#AE_Losses.FromTime and autodata.ndtime<=#AE_Losses.ToTime then DateDiff(second, #AE_Losses.FromTime, ndtime)    
  when autodata.msttime>=#AE_Losses.FromTime and autodata.sttime<#AE_Losses.ToTime and autodata.ndtime>#AE_Losses.ToTime then DateDiff(second, mstTime, #AE_Losses.ToTime)    
  when autodata.msttime<#AE_Losses.FromTime and autodata.ndtime>#AE_Losses.ToTime then DateDiff(second, #AE_Losses.FromTime, #AE_Losses.ToTime)    
  end) as down,#AE_Losses.FromTime,#AE_Losses.ToTime,DownCategoryInformation.DownCategory    
  from #T_autodata Autodata --autodata    
  inner join #AE_Losses on autodata.mc = #AE_Losses.machineinterface    
  --inner join downcodeinformation on autodata.dcode = downcodeinformation.downid --DR0372    
  inner join downcodeinformation on autodata.dcode = downcodeinformation.interfaceid --DR0372    
  inner join DownCategoryInformation on downcodeinformation.Catagory = DownCategoryInformation.DownCategory and #AE_Losses.DownCategory = DownCategoryInformation.DownCategory    
  where (autodata.datatype=2) and    
  ((autodata.msttime>=#AE_Losses.FromTime and autodata.ndtime<=#AE_Losses.ToTime)or    
   (autodata.sttime<#AE_Losses.FromTime and autodata.ndtime>#AE_Losses.FromTime and autodata.ndtime<=#AE_Losses.ToTime)or    
   (autodata.msttime>=#AE_Losses.FromTime and autodata.sttime<#AE_Losses.ToTime and autodata.ndtime>#AE_Losses.ToTime)or    
   (autodata.msttime<#AE_Losses.FromTime and autodata.ndtime>#AE_Losses.ToTime))    
  group by autodata.mc,#AE_Losses.FromTime,#AE_Losses.ToTime,DownCategoryInformation.DownCategory    
 ) as t1 inner join #AE_Losses  on t1.mc = #AE_Losses.machineinterface  and t1.FromTime = #AE_Losses.FromTime    
 and t1.ToTime = #AE_Losses.ToTime and t1.DownCategory = #AE_Losses.DownCategory    
    
 select top 9 IDENTITY(int, 1,1) AS ID_Num, DownCategory,sum(DownTime) as DownTime into #AE_Losses_Inorder from #AE_Losses group by DownCategory order by sum(DownTime) desc    
    
 UPDATE #AE_Losses SET DownTimeByCategory = isnull(#AE_Losses.DownTimeByCategory,0) +  isnull(t1.DownTime,0),    
        DownTimeMaxOrder = isnull(#AE_Losses.DownTimeMaxOrder,0) +  isnull(t1.ID_Num,0)    
 from(select * from #AE_Losses_Inorder) as t1 inner join #AE_Losses on t1.DownCategory = #AE_Losses.DownCategory    
 update #AE_Losses set DownTime = cast(dbo.f_FormatTime(DownTime,'mm')as float),DownTimeByCategory = cast(dbo.f_FormatTime(DownTimeByCategory,'mm')as float)    
    
 select HourID,ShiftID,DownCategory,DownTime from #AE_Losses    
 where DownTimeMaxOrder <=9 and DownTimeMaxOrder <> 0    
 order by FromTime,DownTimeMaxOrder    
 return    
End    
    
--ER0353 Added From Here    
if isnull(@Param,'') = 'BOSCH_Nashik_AELosses'    
Begin    
 Select machineID,MachineInterface,pDate,HourID,ShiftID,FromTime,ToTime,T.Catagory as Downcategory,T.Downid as Downid,T.interfaceid as interfaceid,0 as DownTime,0 as DowntimeinSec into #AE_Losses1    
 from #ShiftTemp cross join (Select Downid,Catagory,interfaceid from Downcodeinformation DI inner join DownCategoryInformation DC    
 on DI.catagory=DC.Downcategory)T order by shiftid,hourid,T.Catagory    
    
    
 UPDATE #AE_Losses1 SET DownTime = isnull(DownTime,0) + isNull(t1.down,0) from(    
  select mc,    
  sum(case    
  when autodata.msttime>=#AE_Losses1.FromTime and autodata.ndtime<=#AE_Losses1.ToTime then loadunload    
  when autodata.sttime<#AE_Losses1.FromTime and autodata.ndtime>#AE_Losses1.FromTime and autodata.ndtime<=#AE_Losses1.ToTime then DateDiff(second, #AE_Losses1.FromTime, ndtime)    
  when autodata.msttime>=#AE_Losses1.FromTime and autodata.sttime<#AE_Losses1.ToTime and autodata.ndtime>#AE_Losses1.ToTime then DateDiff(second, mstTime, #AE_Losses1.ToTime)    
  when autodata.msttime<#AE_Losses1.FromTime and autodata.ndtime>#AE_Losses1.ToTime then DateDiff(second, #AE_Losses1.FromTime, #AE_Losses1.ToTime)    
  end) as down,#AE_Losses1.FromTime,#AE_Losses1.ToTime,#AE_Losses1.DownCategory,#AE_Losses1.downid    
  from #T_autodata autodata    
  inner join #AE_Losses1 on autodata.mc = #AE_Losses1.machineinterface    
  inner join downcategoryinformation DC on DC.downcategory=#AE_Losses1.DownCategory    
  inner join downcodeinformation D on autodata.dcode = D.interfaceid and D.catagory=DC.DownCategory    
  and #AE_Losses1.downid=D.downid    
  where (autodata.datatype=2) and    
  ((autodata.msttime>=#AE_Losses1.FromTime and autodata.ndtime<=#AE_Losses1.ToTime)or    
   (autodata.sttime<#AE_Losses1.FromTime and autodata.ndtime>#AE_Losses1.FromTime and autodata.ndtime<=#AE_Losses1.ToTime)or    
   (autodata.msttime>=#AE_Losses1.FromTime and autodata.sttime<#AE_Losses1.ToTime and autodata.ndtime>#AE_Losses1.ToTime)or    
   (autodata.msttime<#AE_Losses1.FromTime and autodata.ndtime>#AE_Losses1.ToTime))    
  group by autodata.mc,#AE_Losses1.FromTime,#AE_Losses1.ToTime,#AE_Losses1.DownCategory,#AE_Losses1.downid    
 ) as t1 inner join #AE_Losses1  on t1.mc = #AE_Losses1.machineinterface and t1.FromTime = #AE_Losses1.FromTime    
 and t1.ToTime = #AE_Losses1.ToTime and t1.DownCategory = #AE_Losses1.DownCategory and t1.downid = #AE_Losses1.downid    

 update #AE_Losses1 set DowntimeinSec=Downtime
    
 update #AE_Losses1 set DownTime = cast(dbo.f_FormatTime(DownTime,'mm')as float)    
    
 ----select HourID,ShiftID,DownCategory,downid,interfaceid,replace(DownTime,'0','') as DownTime  from #AE_Losses1    
 ----order by shiftid,hourid    
 
  select downid,interfaceid,shiftid,SUM(DowntimeinSec) as DowntimeinSec into #NonZeroDowns from #AE_Losses1 
  group by downid,interfaceid,shiftid
  
  select A.HourID,A.ShiftID,A.DownCategory,A.downid,A.interfaceid,replace(A.DownTime,'0','') as DownTime,A.DowntimeinSec  from #AE_Losses1  A
  inner join  #NonZeroDowns N on A.Downid=N.Downid and A.ShiftID=N.ShiftID
  Where A.downid not in(Select distinct downid from PredefinedDownCodeInfo) and N.DowntimeinSec>0
 order by A.shiftid,A.hourid
   
 return    
End    
--ER0353 added Till here    
    
    
update #ShiftTemp set Actual=T1.Actual1 from(    
 select M.machineid as machine,S.FromTime as hrstart,S.ToTime as hrend,sum(A.partscount/O.suboperations) as Actual1    
 from #T_autodata A    
 inner join machineinformation M on M.interfaceid=A.mc    
 inner join componentinformation C on C.interfaceid=A.comp    
 inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID    
 inner join #ShiftTemp S on M.Machineid= S.machineid    
 where A.datatype=1 and A.ndtime>S.FromTime and A.ndtime<=S.ToTime    
 group by M.machineid,S.FromTime ,S.ToTime    
) as T1 inner join #ShiftTemp on #ShiftTemp.machineid=T1.machine and #ShiftTemp.Fromtime=T1.hrstart and #ShiftTemp.totime=T1.hrend    
    
    
 insert into #PDT    
 select st.machineID,st.machineinterface,st.FromTime,st.ToTime,--pdt.StartTime,pdt.EndTime,    
 case when  st.FromTime > pdt.StartTime then st.FromTime else pdt.StartTime end,    
 case when  st.ToTime < pdt.EndTime then st.ToTime else pdt.EndTime end,pdt.DownReason,0,0,0,0    
 from #ShiftTemp st inner join PlannedDownTimes pdt    
 on st.machineID = pdt.Machine and PDTstatus = 1 and    
 ((pdt.StartTime >= st.FromTime  AND pdt.EndTime <=st.ToTime)    
 OR ( pdt.StartTime < st.FromTime  AND pdt.EndTime <= st.ToTime AND pdt.EndTime > st.FromTime )    
 OR ( pdt.StartTime >= st.FromTime   AND pdt.StartTime <st.ToTime AND pdt.EndTime > st.ToTime )    
 OR ( pdt.StartTime < st.FromTime  AND pdt.EndTime > st.ToTime))    
    
--ER0210-KarthikG-17/Dec/2009::From Here    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 update #PDT set Actual=isnull(#PDT.Actual,0) + isNull(t1.Actual ,0) from(    
  select M.machineid as machine,StartTime_PDT,EndTime_PDT,sum(A.partscount/O.suboperations) as Actual    
  from #T_autodata A    
  inner join machineinformation M on M.interfaceid=A.mc    
  inner join componentinformation C on C.interfaceid=A.comp    
  inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID    
  inner join #PDT  on M.Machineid= #PDT.machineid    
  where A.datatype=1 and A.ndtime>#PDT.StartTime_PDT and A.ndtime<=#PDT.EndTime_PDT    
  group by M.machineid,StartTime_PDT,EndTime_PDT    
 ) as t1 inner join #PDT on #PDT.machineid=t1.machine and #PDT.StartTime_PDT=t1.StartTime_PDT and #PDT.EndTime_PDT=t1.EndTime_PDT    
 Update #ShiftTemp set Actual = isnull(#ShiftTemp.Actual,0) - isNull(t1.Actual ,0) from(    
  Select MachineID,FromTime,ToTime,sum(Actual) as Actual from #PDT Group by MachineID,FromTime,ToTime    
 ) as t1 inner join #ShiftTemp on t1.machineID = #ShiftTemp.machineID and    
 t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime    
End    
    
    
-------------------------------- Getting Hourwise KWH For the Given Machine-------------------------    
Update #ShiftTemp    
set #ShiftTemp.MinEnergy = ISNULL(#ShiftTemp.MinEnergy,0)+ISNULL(t1.kwh,0) from     
(    
select T.MachineiD,T.FromTime,T.ToTime,round(kwh,2) as kwh from     
 (    
 select  tcs_energyconsumption.MachineiD,FromTime,ToTime,    
 min(gtime) as mingtime    
 from tcs_energyconsumption WITH(NOLOCK) inner join #ShiftTemp on     
 tcs_energyconsumption.machineID = #ShiftTemp.MachineID and tcs_energyconsumption.gtime >= #ShiftTemp.FromTime and tcs_energyconsumption.gtime <= #ShiftTemp.ToTime    
 where tcs_energyconsumption.kwh>0     
 group by  tcs_energyconsumption.MachineiD,FromTime,ToTime)T    
 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime     
 AND tcs_energyconsumption.MachineID = T.MachineID --DR0359    
) as t1  inner join #ShiftTemp on t1.machineiD = #ShiftTemp.machineID and t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime    
    
Update #ShiftTemp    
set #ShiftTemp.MaxEnergy = ISNULL(#ShiftTemp.MaxEnergy,0)+ISNULL(t1.kwh,0) from     
(    
select T.MachineiD,T.FromTime,T.ToTime,round(kwh,2)as kwh from     
 (    
 select  tcs_energyconsumption.MachineiD,FromTime,ToTime,    
 max(gtime) as maxgtime    
 from tcs_energyconsumption WITH(NOLOCK) inner join #ShiftTemp on     
 tcs_energyconsumption.machineID = #ShiftTemp.MachineID and tcs_energyconsumption.gtime >= #ShiftTemp.FromTime and tcs_energyconsumption.gtime <= #ShiftTemp.ToTime    
 where tcs_energyconsumption.kwh>0     
 group by  tcs_energyconsumption.MachineiD,FromTime,ToTime    
 )T    
 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime      
 AND tcs_energyconsumption.MachineID = T.MachineID     
) as t1  inner join #ShiftTemp on t1.machineiD = #ShiftTemp.machineID and t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime    
    
Update #ShiftTemp set #ShiftTemp.KWH = ISNULL(#ShiftTemp.KWH,0)+ISNULL(t1.kwh,0)from     
(    
 select MachineiD,FromTime,ToTime,round((MaxEnergy - MinEnergy),2) as kwh from #ShiftTemp     
) as t1 inner join #ShiftTemp on t1.machineiD = #ShiftTemp.machineID and t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime    

---ER0503 Added Hourwise Rejcount    
Update #ShiftTemp set Spindle1RejCount = isnull(Spindle1RejCount,0) + isnull(T1.RejQty,0)    
From    
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
inner join Machineinformation M on A.mc=M.interfaceid    
inner join #ShiftTemp T1 on T1.MachineInterface=A.mc    
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
where A.CreatedTS>=T1.Fromtime and A.CreatedTS<T1.ToTime and A.flag = 'Rejection'    
--and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' 
and R.interfaceid='1'   
group by A.mc,T1.Fromtime
)T1 inner join #ShiftTemp B on B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime     
 
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 Update #ShiftTemp set Spindle1RejCount = isnull(Spindle1RejCount,0) - isnull(T1.RejQty,0) from    
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
 inner join Machineinformation M on A.mc=M.interfaceid    
 inner join #ShiftTemp T1 on T1.MachineInterface=A.mc   
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
 Cross join #PDT P    
 where  A.flag = 'Rejection' and P.Machineid=M.Machineid and   
 --and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and    
 A.CreatedTS>=T1.Fromtime and A.CreatedTS<T1.ToTime And    
 A.CreatedTS>=P.StartTime_PDT and A.CreatedTS<P.EndTime_PDT  and R.interfaceid='1'   
 group by A.mc,T1.Fromtime
 )T1 inner join #ShiftTemp B on B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime     
END     
   
--Update #ShiftTemp set Spindle1RejCount = isnull(Spindle1RejCount,0) + isnull(T1.RejQty,0)    
--From    
--( Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
--inner join Machineinformation M on A.mc=M.interfaceid    
--inner join #ShiftTemp T1 on T1.MachineInterface=A.mc   
--inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
----inner join #ShiftDefn S on (convert(nvarchar(10),(A.RejDate),120)=convert(nvarchar(10),S.shiftdate,120)) and A.RejShift=S.shiftid 
--where A.flag = 'Rejection' and A.Rejshift in (T1.shiftid) and convert(nvarchar(10),(A.RejDate),120) in (convert(nvarchar(10),T1.PDate,120)) and  
--Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  and R.interfaceid='1'   
--group by A.mc,T1.Fromtime
--)T1 inner join #ShiftTemp B on  B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime   
    
--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
--BEGIN    
-- Update #ShiftTemp set Spindle1RejCount = isnull(Spindle1RejCount,0) - isnull(T1.RejQty,0) from    
-- (Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
-- inner join Machineinformation M on A.mc=M.interfaceid    
-- inner join #ShiftTemp T1 on T1.MachineInterface=A.mc  
-- inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
-- --inner join #ShiftDefn S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid      
-- Cross join #PDT P    
-- where  A.flag = 'Rejection' and P.Machineid=M.Machineid and    
-- A.Rejshift in (T1.shiftid) and convert(nvarchar(10),(A.RejDate),120) in (convert(nvarchar(10),T1.PDate,120)) and 
-- Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
-- and P.StartTime_PDT>=T1.Fromtime and P.EndTime_PDT<=T1.ToTime and R.interfaceid='1'  
-- group by A.mc,T1.Fromtime)T1 inner join #ShiftTemp B on  B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime   
--END 


Update #ShiftTemp set Spindle3RejCount = isnull(Spindle3RejCount,0) + isnull(T1.RejQty,0)    
From    
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
inner join Machineinformation M on A.mc=M.interfaceid    
inner join #ShiftTemp T1 on T1.MachineInterface=A.mc    
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
where A.CreatedTS>=T1.Fromtime and A.CreatedTS<T1.ToTime and A.flag = 'Rejection'    
--and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' 
and R.interfaceid='3'   
group by A.mc,T1.Fromtime
)T1 inner join #ShiftTemp B on B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime     
 
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 Update #ShiftTemp set Spindle3RejCount = isnull(Spindle3RejCount,0) - isnull(T1.RejQty,0) from    
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
 inner join Machineinformation M on A.mc=M.interfaceid    
 inner join #ShiftTemp T1 on T1.MachineInterface=A.mc   
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
 Cross join #PDT P    
 where  A.flag = 'Rejection' and P.Machineid=M.Machineid and  
 --and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and    
 A.CreatedTS>=T1.Fromtime and A.CreatedTS<T1.ToTime And    
 A.CreatedTS>=P.StartTime_PDT and A.CreatedTS<P.EndTime_PDT  and R.interfaceid='3'   
 group by A.mc,T1.Fromtime
 )T1 inner join #ShiftTemp B on B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime     
END     
   
--Update #ShiftTemp set Spindle3RejCount = isnull(Spindle3RejCount,0) + isnull(T1.RejQty,0)    
--From    
--( Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
--inner join Machineinformation M on A.mc=M.interfaceid    
--inner join #ShiftTemp T1 on T1.MachineInterface=A.mc   
--inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
----inner join #ShiftDefn S on (convert(nvarchar(10),(A.RejDate),120)=convert(nvarchar(10),S.shiftdate,120)) and A.RejShift=S.shiftid 
--where A.flag = 'Rejection' and A.Rejshift in (T1.shiftid) and convert(nvarchar(10),(A.RejDate),120) in (convert(nvarchar(10),T1.PDate,120)) and  
--Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  and R.interfaceid='3'   
--group by A.mc,T1.Fromtime
--)T1 inner join #ShiftTemp B on  B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime   
    
--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
--BEGIN    
-- Update #ShiftTemp set Spindle3RejCount = isnull(Spindle3RejCount,0) - isnull(T1.RejQty,0) from    
-- (Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
-- inner join Machineinformation M on A.mc=M.interfaceid    
-- inner join #ShiftTemp T1 on T1.MachineInterface=A.mc  
-- inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
-- --inner join #ShiftDefn S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid      
-- Cross join #PDT P    
-- where  A.flag = 'Rejection' and P.Machineid=M.Machineid and    
-- A.Rejshift in (T1.shiftid) and convert(nvarchar(10),(A.RejDate),120) in (convert(nvarchar(10),T1.PDate,120)) and 
-- Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
-- and P.StartTime_PDT>=T1.Fromtime and P.EndTime_PDT<=T1.ToTime and R.interfaceid='3'  
-- group by A.mc,T1.Fromtime)T1 inner join #ShiftTemp B on  B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime   
--END  

Update #ShiftTemp set Spindle2RejCount = isnull(Spindle2RejCount,0) + isnull(T1.RejQty,0)    
From    
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
inner join Machineinformation M on A.mc=M.interfaceid    
inner join #ShiftTemp T1 on T1.MachineInterface=A.mc    
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
where A.CreatedTS>=T1.Fromtime and A.CreatedTS<T1.ToTime and A.flag = 'Rejection'    
--and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' 
and R.interfaceid='2'   
group by A.mc,T1.Fromtime
)T1 inner join #ShiftTemp B on B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime     
 
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 Update #ShiftTemp set Spindle2RejCount = isnull(Spindle2RejCount,0) - isnull(T1.RejQty,0) from    
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
 inner join Machineinformation M on A.mc=M.interfaceid    
 inner join #ShiftTemp T1 on T1.MachineInterface=A.mc   
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
 Cross join #PDT P    
 where  A.flag = 'Rejection' and P.Machineid=M.Machineid and  
 --and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and    
 A.CreatedTS>=T1.Fromtime and A.CreatedTS<T1.ToTime And    
 A.CreatedTS>=P.StartTime_PDT and A.CreatedTS<P.EndTime_PDT  and R.interfaceid='2'   
 group by A.mc,T1.Fromtime
 )T1 inner join #ShiftTemp B on B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime     
END     
   
--Update #ShiftTemp set Spindle2RejCount = isnull(Spindle2RejCount,0) + isnull(T1.RejQty,0)    
--From    
--( Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
--inner join Machineinformation M on A.mc=M.interfaceid    
--inner join #ShiftTemp T1 on T1.MachineInterface=A.mc   
--inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
----inner join #ShiftDefn S on (convert(nvarchar(10),(A.RejDate),120)=convert(nvarchar(10),S.shiftdate,120)) and A.RejShift=S.shiftid 
--where A.flag = 'Rejection' and A.Rejshift in (T1.shiftid) and convert(nvarchar(10),(A.RejDate),120) in (convert(nvarchar(10),T1.PDate,120)) and  
--Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  and R.interfaceid='2'   
--group by A.mc,T1.Fromtime
--)T1 inner join #ShiftTemp B on  B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime   
    
--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
--BEGIN    
-- Update #ShiftTemp set Spindle2RejCount = isnull(Spindle2RejCount,0) - isnull(T1.RejQty,0) from    
-- (Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Fromtime from AutodataRejections A    
-- inner join Machineinformation M on A.mc=M.interfaceid    
-- inner join #ShiftTemp T1 on T1.MachineInterface=A.mc  
-- inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
-- --inner join #ShiftDefn S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid      
-- Cross join #PDT P    
-- where  A.flag = 'Rejection' and P.Machineid=M.Machineid and    
-- A.Rejshift in (T1.shiftid) and convert(nvarchar(10),(A.RejDate),120) in (convert(nvarchar(10),T1.PDate,120)) and 
-- Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
-- and P.StartTime_PDT>=T1.Fromtime and P.EndTime_PDT<=T1.ToTime and R.interfaceid='2'  
-- group by A.mc,T1.Fromtime)T1 inner join #ShiftTemp B on  B.MachineInterface=T1.mc and B.Fromtime=T1.Fromtime   
--END         
---ER0503 Added Hourwise Rejcount    
    
--ER0210-KarthikG-17/Dec/2009::Till Here    
/*select M.machineid as machine,S.FromTime as hrstart ,S.ToTime as hrend,sum(A.partscount/O.suboperations) as Actual1 from autodata A    
inner join machineinformation M on M.interfaceid=A.mc    
inner join componentinformation C on C.interfaceid=A.comp    
inner join componentoperationpricing O on O.interfaceid=A.opn    
and C.componentid=O.componentid    
inner join #ShiftTemp S on M.Machineid= S.machineid    
where A.datatype=1 and A.ndtime>S.FromTime and A.ndtime<=S.ToTime    
group by M.machineid,S.FromTime ,S.ToTime*/    
---update #ShiftTemp to get actual count    
-- get the target count    
--select * from #ShiftTemp    
/*select sum(SH.target)AS TARGET ,SH.Sdate,SH.hourid,SH.Machineid,    
SH.Hourstart  as Hourstart ,SH.Hourend as Hourend from    
shifthourtargets SH where SH.sdate=convert(datetime,@stdate) and SH.Machineid=@MachineID    
group by SH.Sdate,SH.hourid,SH.Machineid,SH.Hourstart,SH.Hourend    
*/    
--From here ER0316    
--update #ShiftTemp set target=T1.target from(    
-- select sum(SH.target)AS TARGET ,SH.Sdate,SH.hourid,SH.Machineid,    
-- SH.Hourstart  as Hourstart ,SH.Hourend as Hourend from    
-- shifthourtargets SH where SH.sdate=convert(datetime,@stdate) and SH.Machineid=@MachineID    
-- group by SH.Sdate,SH.hourid,SH.Machineid,SH.Hourstart,SH.Hourend    
--) as T1 inner join #ShiftTemp on #ShiftTemp.machineid=T1.Machineid and #ShiftTemp.hourid=T1.hourid    
--and #ShiftTemp.Fromtime=T1.Hourstart and #ShiftTemp.totime=T1.Hourend    
--Till here ER0316    
if isnull(@Param,'') = ''    
Begin    
 select machineID,MachineInterface,pDate,ShiftName,    
 ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual    
 from #ShiftTemp order by pdate,shiftid,hourid --sv    
 return    
End    

if isnull(@Param,'') = 'BOSCH_BNG_RejCount'    
Begin     
	select machineID,MachineInterface,pDate,ShiftName,    
	ShiftID,HourName,HourID,FromTime,ToTime,Spindle1RejCount,Spindle2RejCount,Spindle3RejCount
	from #ShiftTemp order by machineID,FromTime,shiftid,hourid    
	return
END

    
if isnull(@Param,'') = 'BOSCH_BNG_CamShaft'    
Begin    
 /*    
 --Calculating ChangeOver DownTime    
 UPDATE #ShiftTemp SET ChangeOver = isnull(ChangeOver,0) + isNull(t1.down,0) from(    
  select mc,    
  sum(case    
  when autodata.msttime>=#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime then loadunload    
  when autodata.sttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime then DateDiff(second, #ShiftTemp.FromTime, ndtime)    
  when autodata.msttime>=#ShiftTemp.FromTime and autodata.sttime<#ShiftTemp.ToTime and autodata.ndtime>#ShiftTemp.ToTime then DateDiff(second, mstTime, #ShiftTemp.ToTime)    
  when autodata.msttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.ToTime then DateDiff(second, #ShiftTemp.FromTime, #ShiftTemp.ToTime)    
  end) as down,#ShiftTemp.FromTime,#ShiftTemp.ToTime    
  from autodata inner join #ShiftTemp on autodata.mc = #ShiftTemp.machineinterface    
  where (autodata.datatype=2) and    
  ((autodata.msttime>=#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime)or    
   (autodata.sttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime)or    
   (autodata.msttime>=#ShiftTemp.FromTime and autodata.sttime<#ShiftTemp.ToTime and autodata.ndtime>#ShiftTemp.ToTime)or    
   (autodata.msttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.ToTime))    
  group by autodata.mc,#ShiftTemp.FromTime,#ShiftTemp.ToTime    
 ) as t1 inner join #ShiftTemp on t1.mc = #ShiftTemp.machineinterface and t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime    
 --Calculating TechnicalFailure DownTime    
 UPDATE #ShiftTemp SET TechnicalFailure = isnull(TechnicalFailure,0) + isNull(t1.down,0) from(    
  select mc,    
  sum(case    
  when autodata.msttime>=#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime then loadunload    
  when autodata.sttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime then DateDiff(second, #ShiftTemp.FromTime, ndtime)    
  when autodata.msttime>=#ShiftTemp.FromTime and autodata.sttime<#ShiftTemp.ToTime and autodata.ndtime>#ShiftTemp.ToTime then DateDiff(second, mstTime, #ShiftTemp.ToTime)    
  when autodata.msttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.ToTime then DateDiff(second, #ShiftTemp.FromTime, #ShiftTemp.ToTime)    
  end) as down,#ShiftTemp.FromTime,#ShiftTemp.ToTime    
  from autodata inner join #ShiftTemp on autodata.mc = #ShiftTemp.machineinterface    
  where (autodata.datatype=2) and    
  ((autodata.msttime>=#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime)or    
   (autodata.sttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime)or    
   (autodata.msttime>=#ShiftTemp.FromTime and autodata.sttime<#ShiftTemp.ToTime and autodata.ndtime>#ShiftTemp.ToTime)or    
   (autodata.msttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.ToTime))    
  group by autodata.mc,#ShiftTemp.FromTime,#ShiftTemp.ToTime    
 ) as t1 inner join #ShiftTemp on t1.mc = #ShiftTemp.machineinterface and t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime    
 --Calculating OrganisationalLoss DownTime    
 UPDATE #ShiftTemp SET OrganisationalLoss = isnull(OrganisationalLoss,0) + isNull(t1.down,0) from(    
  select mc,    
  sum(case    
  when autodata.msttime>=#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime then loadunload    
  when autodata.sttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime then DateDiff(second, #ShiftTemp.FromTime, ndtime)    
  when autodata.msttime>=#ShiftTemp.FromTime and autodata.sttime<#ShiftTemp.ToTime and autodata.ndtime>#ShiftTemp.ToTime then DateDiff(second, mstTime, #ShiftTemp.ToTime)    
  when autodata.msttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.ToTime then DateDiff(second, #ShiftTemp.FromTime, #ShiftTemp.ToTime)    
  end) as down,#ShiftTemp.FromTime,#ShiftTemp.ToTime    
  from autodata inner join #ShiftTemp on autodata.mc = #ShiftTemp.machineinterface    
  where (autodata.datatype=2) and    
  ((autodata.msttime>=#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime)or    
   (autodata.sttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.FromTime and autodata.ndtime<=#ShiftTemp.ToTime)or    
   (autodata.msttime>=#ShiftTemp.FromTime and autodata.sttime<#ShiftTemp.ToTime and autodata.ndtime>#ShiftTemp.ToTime)or    
   (autodata.msttime<#ShiftTemp.FromTime and autodata.ndtime>#ShiftTemp.ToTime))    
  group by autodata.mc,#ShiftTemp.FromTime,#ShiftTemp.ToTime    
 ) as t1 inner join #ShiftTemp on t1.mc = #ShiftTemp.machineinterface and t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime    
 If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'    
 BEGIN--Y    
  --Calculating ChangeOver DownTime within PDT    
  UPDATE #PDT SET ChangeOver = isnull(ChangeOver,0) + isNull(t1.down,0) from(    
   select mc,    
   sum(case    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then loadunload    
   when autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, ndtime)    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, mstTime, #PDT.EndTime_PDT)    
   when autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, #PDT.EndTime_PDT)    
   end) as down,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
   from autodata inner join #PDT on autodata.mc = #PDT.machineinterface    
   where (autodata.datatype=2) and    
   ((autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT)or    
    (autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT))    
   group by autodata.mc,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
  ) as t1 inner join #PDT on t1.mc = #PDT.machineinterface and t1.StartTime_PDT = #PDT.StartTime_PDT and t1.EndTime_PDT = #PDT.EndTime_PDT    
      
  --Calculating TechnicalFailure DownTime within PDT    
  UPDATE #PDT SET TechnicalFailure = isnull(TechnicalFailure,0) + isNull(t1.down,0) from(    
   select mc,    
   sum(case    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then loadunload    
   when autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, ndtime)    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, mstTime, #PDT.EndTime_PDT)    
   when autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, #PDT.EndTime_PDT)    
   end) as down,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
   from autodata inner join #PDT on autodata.mc = #PDT.machineinterface    
   where (autodata.datatype=2) and    
   ((autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT)or    
    (autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT))    
   group by autodata.mc,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
  ) as t1 inner join #PDT on t1.mc = #PDT.machineinterface and t1.StartTime_PDT = #PDT.StartTime_PDT and t1.EndTime_PDT = #PDT.EndTime_PDT    
      
  --Calculating OrganisationalLoss DownTime within PDT    
  UPDATE #PDT SET OrganisationalLoss = isnull(OrganisationalLoss,0) + isNull(t1.down,0) from(    
   select mc,    
   sum(case    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then loadunload    
   when autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, ndtime)    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, mstTime, #PDT.EndTime_PDT)    
   when autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, #PDT.EndTime_PDT)    
   end) as down,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
   from autodata inner join #PDT on autodata.mc = #PDT.machineinterface    
   where (autodata.datatype=2) and    
   ((autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT)or    
    (autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT))    
   group by autodata.mc,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
  ) as t1 inner join #PDT on t1.mc = #PDT.machineinterface and t1.StartTime_PDT = #PDT.StartTime_PDT and t1.EndTime_PDT = #PDT.EndTime_PDT    
 End    
--    
 If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'    
 BEGIN--Some Down Reason    
  --Calculating ChangeOver DownTime within PDT    
  UPDATE #PDT SET ChangeOver = isnull(ChangeOver,0) + isNull(t1.down,0) from(    
   select mc,    
   sum(case    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then loadunload    
   when autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, ndtime)    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, mstTime, #PDT.EndTime_PDT)    
   when autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, #PDT.EndTime_PDT)    
   end) as down,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
   from autodata inner join #PDT on autodata.mc = #PDT.machineinterface    
   Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')    
   where (autodata.datatype=2) and    
   ((autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT)or    
    (autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT))    
   group by autodata.mc,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
  ) as t1 inner join #PDT on t1.mc = #PDT.machineinterface and t1.StartTime_PDT = #PDT.StartTime_PDT and t1.EndTime_PDT = #PDT.EndTime_PDT    
  --Calculating TechnicalFailure DownTime within PDT    
  UPDATE #PDT SET TechnicalFailure = isnull(TechnicalFailure,0) + isNull(t1.down,0) from(    
   select mc,    
   sum(case    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then loadunload    
   when autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, ndtime)    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, mstTime, #PDT.EndTime_PDT)    
   when autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, #PDT.EndTime_PDT)    
   end) as down,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
   from autodata inner join #PDT on autodata.mc = #PDT.machineinterface    
   Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')    
   where (autodata.datatype=2) and    
   ((autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT)or    
    (autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT))    
   group by autodata.mc,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
  ) as t1 inner join #PDT on t1.mc = #PDT.machineinterface and t1.StartTime_PDT = #PDT.StartTime_PDT and t1.EndTime_PDT = #PDT.EndTime_PDT    
  --Calculating OrganisationalLoss DownTime within PDT    
  UPDATE #PDT SET OrganisationalLoss = isnull(OrganisationalLoss,0) + isNull(t1.down,0) from(    
   select mc,    
   sum(case    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then loadunload    
   when autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, ndtime)    
   when autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, mstTime, #PDT.EndTime_PDT)    
   when autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT then DateDiff(second, #PDT.StartTime_PDT, #PDT.EndTime_PDT)    
   end) as down,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
   from autodata inner join #PDT on autodata.mc = #PDT.machineinterface    
   Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')    
   where (autodata.datatype=2) and    
   ((autodata.msttime>=#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.sttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.StartTime_PDT and autodata.ndtime<=#PDT.EndTime_PDT)or    
    (autodata.msttime>=#PDT.StartTime_PDT and autodata.sttime<#PDT.EndTime_PDT and autodata.ndtime>#PDT.EndTime_PDT)or    
    (autodata.msttime<#PDT.StartTime_PDT and autodata.ndtime>#PDT.EndTime_PDT))    
   group by autodata.mc,#PDT.StartTime_PDT,#PDT.EndTime_PDT    
  ) as t1 inner join #PDT on t1.mc = #PDT.machineinterface and t1.StartTime_PDT = #PDT.StartTime_PDT and t1.EndTime_PDT = #PDT.EndTime_PDT    
 END    
 -- detecting overlapping ChangeOver downtime    
 Update #ShiftTemp set ChangeOver = isnull(#ShiftTemp.ChangeOver,0) - isNull(t1.ChangeOver ,0) from(    
  Select MachineID,FromTime,ToTime,sum(ChangeOver) as ChangeOver from #PDT Group by MachineID,FromTime,ToTime    
 ) as t1 inner join #ShiftTemp on t1.machineID = #ShiftTemp.machineID and    
 t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime    
 -- detecting overlapping TechnicalFailure downtime    
 Update #ShiftTemp set TechnicalFailure = isnull(#ShiftTemp.TechnicalFailure,0) - isNull(t1.TechnicalFailure ,0) from(    
  Select MachineID,FromTime,ToTime,sum(TechnicalFailure) as TechnicalFailure from #PDT Group by MachineID,FromTime,ToTime    
 ) as t1 inner join #ShiftTemp on t1.machineID = #ShiftTemp.machineID and    
 t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime    
 -- detecting overlapping OrganisationalLoss downtime    
 Update #ShiftTemp set OrganisationalLoss = isnull(#ShiftTemp.OrganisationalLoss,0) - isNull(t1.OrganisationalLoss ,0) from(    
  Select MachineID,FromTime,ToTime,sum(OrganisationalLoss) as OrganisationalLoss from #PDT Group by MachineID,FromTime,ToTime    
 ) as t1 inner join #ShiftTemp on t1.machineID = #ShiftTemp.machineID and    
 t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime    
 */    
 --The Maximum allowed Target or Actual is 120    
    
    
 --Update #ShiftTemp set Target = 120 where Target > 120    
 --Update #ShiftTemp set Actual = 120 where Actual > 120    
    
 select machineID,MachineInterface,pDate,ShiftName,    
 ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual,    
 dbo.f_FormatTime(ChangeOver,'mm') as ChangeOver,    
 dbo.f_FormatTime(TechnicalFailure,'mm') as TechnicalFailure,    
 dbo.f_FormatTime(OrganisationalLoss,'mm') as OrganisationalLoss,    
 KWH    
 from #ShiftTemp order by machineID,FromTime,shiftid,hourid    
End    
End    
    
