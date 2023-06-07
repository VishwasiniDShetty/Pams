/****** Object:  Procedure [dbo].[s_GetCockpitData_WithTempTable]    Committed by VersionSQL https://www.versionsql.com ******/

  
/***************************************      History     *******************************************  
Procedure altered by Satyan on 15-feb-06 To include down threshold in ManagementLoss calculation  
Introduced PEGreen,PERed,AEGreen,AERed,OEGreen,OERed, Dec 4 2004 sjaiswal  
Procedure Altred On top of 4.5.0.0 by Sangeeta Kallur On May-2006  
[Originally this proc altered for testing]  
To support the down within the production cycle as they appear.  
Removed all the unwanted comments by SSK  
Procedure Altered [Count ,CN,TurnOver Calculations ]by SSK on 06/July/2006  
To combine SubOperations as One Cycle ie one component.  
Procedure Changed By MRao ::New column 'partsCount' is added in autodata  
which gives number of components in that cycle  
Procedure Changed By SSK on 06-Dec-2006 : To remove constraint name.  
Procedure Changed By Karthik G on 21-FEB-2007  
 To include 'TPMTrakEnabled'{Based on user settings we  
 will be considering only TPMTrakEnabled Machines or ALL} Concept.  
Procedure Changed By Sangeeta Kallur on 23-FEB-2007 ::For MultiSpindle type of machines [MAINI Req].  
mod 1:- DR0175, By Mrudula M. Rao on 13-mar-2009.Exception rule is not being applied when you select all machine  
  Initialize "@StrExMachine"  
mod 2 :- ER0181 By Kusuma M.H on 08-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.  
mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009. MCO qualification has been done on turnover calculation.  
mod 3 :- ER0182 By Kusuma M.H on 08-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.  
mod 4 :- ER0210 By KarthikG and Mrudula. Introduce PDT on 5150. 1) Handle PDT at Machine Level.  
   2) Handle interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.  
   3) Improve the performance.  
   4) Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
--dbcc freeproccache;dbcc dropcleanbuffers;  
NOte :- Not introduced interaction between ML while getting maximum down reason  
DR0236 - KarthikG - 19/Jun/2010 :: Use proper conditions in case statements to remove icd's from type 4 production records.  
DR0325 - SwathiKS - 27/May/2013 :: For Utilised calculation To consider difference between Autodata msttime and ndtime instead NetCycletime for Tyep1 Record with PDT.  
NR0090 - SwathiKS - 22/Jul/2013 :: To Display Totaltime Based on Setting in CockpitDefaults Table.  
i.e. If Parameter="DisplayTTFormat" and Valueintext = "Display TotalTime" then Show Totaltime=Datediff(s,Start,End)  
 If Parameter="DisplayTTFormat" and Valueintext = "Display TotalTime Less PDT" then Show Totaltime=Datediff(s,Start,End)-PDT  
DR0330 - SwathiKS - 05/Aug/2013 :: To Consider Predefined Downtimes from Planned Downtimes table while Displaying Totaltime Less PDT.  
NR0094 - SwathiKS - 27/Sep/2013 :: Based On setting in Cockpitdefaults Display ReturnPerHourUtilised OR LastPartID in Table and Iconic View.  
ER0362 - SwathiKS - 01/Aug/2013 :: Altered Procedure S_GetCockpitdata to reuse 'Remarks' Column to get LastCycletime based on CompanyName.  
ER0368 - SwathiKS - 23/Oct.2013 :: To Include QualityEficiency.  
DR0333 - SwathiKS - 10/Dec/2013 :: For New Holland, Rejections were not associated properly when Rejdate and RejShift are not null while Calculating QE.  
NR0097 - SwathiKS - 17/dec/2013 :: a> Ace - While Accounting ManagementLoss, To apply Threshold from Componentoperationprcing table for the Downs with "PickFomCO = 1" else apply threshold from Downcodeinformation tablw eith "Availeffy=1".  
b> Since we are splitting Production and Down Cycle across shifts while showing partscount we have to consider decimal values instead whole Numbers.  
ER0374 - SwathiKS/Satyen - 31/Jan/2014 :: a> Performance Optimization.  
b> Used "dbo.f_GetLogicalDaystart" instead of "dbo.f_GetLogicalDay" because this function is not behaving properly in third shift condition.  
select @enddate = dbo.f_GetLogicalDay(@endtime,'start')  
DR0339 - SwathiKS - 25/Feb/2014 :: While handling ICD-PDT Interaction for Type-1,we have to pick cycles which has ProductionStart=ICDStart and ProductionEnd=ICDEnd.  
ER0385 - SwathiKS - 04/Jul/2014 :: To Show Machine Status Running or Stopped in Iconic Cockpit.  
ER0417 - Vasavi\SwathiKS - 10/Oct/2015 :: a> To Use "Remarks2" column to insert PlantID and Show Simple Average at Plant Level in TimeConsolidated Report.  
b> Specific to Shanthi, kept Parameter Named Shanthi_TimeconsolidatedReport if Y then Use Returnperhour column to show MarkedForRework count and Consider OE as Ae*Pe*Qe and data will be refleted in Timeconsolidated Report.  
DR0370 - SwathiKS - 24/Dec/2015 :: To Ignore bad Records from Rawdata while looking for Machine Running Status for SAF.  
ER0448 (sv) - SwathiKS - 03/Feb/2017 :: To handle all shifttypes i.e [Yesterday to Today],[Today to Tomorrow],[Today to Today] and increase Remarks to nvarchar(40) to nvarchar(100) for Bosch Jaipur.
ER0459 - SwathiKS - 01/mar/2018 :: a> To show Proper JobCode For BaluAuto.
 b> Kun Aerospace - To Handle Machine Interfaceid>4 in Cockpit.
ER0464 - Gopinath - 10/may/2018 :: To Display Machinewise Running Status Using New Table "MachineRunningStatus" Instead of "Rawdata" table for Performance Optimization.

s_GetCockpitData_WithTempTable '2019-06-17 06:00:00 AM','2019-06-18 06:00:00 AM','',''  
****************************************************************************************************/  
CREATE PROCEDURE [dbo].[s_GetCockpitData_WithTempTable]  
 @StartTime datetime output,  
 @EndTime datetime output,  
 @MachineID nvarchar(50) = '',  
 @PlantID nvarchar(50)=''  
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
  
Declare @strPlantID as nvarchar(255)  
Declare @strSql as nvarchar(4000)  
Declare @strMachine as nvarchar(255)  
declare @timeformat as nvarchar(2000)  
Declare @StrTPMMachines AS nvarchar(500)  --karthik 21 feb 07  
Declare @StrExMachine As Nvarchar(255)  
SELECT @StrTPMMachines=''     --karthik 21 feb 07  
SELECT @strMachine = ''  
SELECT @strPlantID = ''  
SELECT @timeformat ='ss'  
--DR0175  
select @StrExMachine=''  
--DR0175  
Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')  
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')  
begin  
 select @timeformat = 'ss'  
end  

Declare @CompanyName as nvarchar(50) --ER0362  
Select @CompanyName = CompanyName from Company --ER0362  
  
--ER0417 From Here  
Declare @MarkedForRework as nvarchar(50)  
Select @MarkedForRework = Isnull(valueintext,'N') from Shopdefaults where Parameter='Shanthi_TimeConsolidatedReport'  
--ER0417 Till Here  
  
CREATE TABLE #CockPitData   
(  
 MachineID nvarchar(50),  
 MachineInterface nvarchar(50) PRIMARY KEY,  
 ProductionEfficiency float,  
 AvailabilityEfficiency float,  
 QualityEfficiency float, --ER0368  
 OverallEfficiency float,  
 Components float,  
 RejCount float,  --ER0368  
 TotalTime float,  
 UtilisedTime float,  
 ManagementLoss float,  
 DownTime float,  
 TurnOver float,  
 ReturnPerHour float,  
 ReturnPerHourtotal float,  
 CN float,  
 Remarks nvarchar(100),  
 Remarks1 nvarchar(50), --ER0368  
 Remarks2 nvarchar(50), --ER0368  
 PEGreen smallint,  
 PERed smallint,  
 AEGreen smallint,  
 AERed smallint,  
 OEGreen smallint,  
 OERed smallint,  
 QEGreen smallint, --ER0368  
 QERed smallint, --ER0368  
 MaxDownReason nvarchar(50) DEFAULT ('')  
 ---mod 4 Added MLDown to store genuine downs which is contained in Management loss  
 ,MLDown float  
 ---mod 4  
--CONSTRAINT CockpitData1_key PRIMARY KEY (machineinterface) : Commented By SSK On 06-Dec-2006  
)  
  
CREATE TABLE #Exceptions  
(  
 MachineID NVarChar(50),  
 ComponentID Nvarchar(50),  
 OperationNo Int,  
 StartTime DateTime,  
 EndTime DateTime,  
 IdealCount Int,  
 ActualCount Int,  
 --ExCount Int --NR0097 
 ExCount float --NR0097  
)  
--mod 4  
CREATE TABLE #PLD  
(  
 MachineID nvarchar(50),  
 --MachineInterface nvarchar(50), --ER0374  
 MachineInterface nvarchar(50) NOT NULL, --ER0374  
 pPlannedDT float Default 0,  
 dPlannedDT float Default 0,  
 MPlannedDT float Default 0,  
 IPlannedDT float Default 0,  
 DownID nvarchar(50)  
)  
Create table #PlannedDownTimes  
(  
 MachineID nvarchar(50) NOT NULL, --ER0374  
 MachineInterface nvarchar(50) NOT NULL, --ER0374  
 StartTime DateTime NOT NULL, --ER0374  
 EndTime DateTime NOT NULL, --ER0374  
 IgnoreCount bit default(0)--SV
)  
--mod 4  
  
--ER0374 From here  
ALTER TABLE #PLD  
 ADD PRIMARY KEY CLUSTERED  
  (   [MachineInterface]  
        
  ) ON [PRIMARY]  
  
  
ALTER TABLE #PlannedDownTimes  
 ADD PRIMARY KEY CLUSTERED  
  (   [MachineInterface],  
   [StartTime],  
   [EndTime]  
        
  ) ON [PRIMARY]  
  
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
  
---ER0374 from here  
--Select @T_ST=dbo.f_GetLogicalDay(@StartTime,'start')  
--Select @T_ED=dbo.f_GetLogicalDay(@EndTime,'End')  
Select @T_ST=dbo.f_GetLogicalDaystart(@StartTime)  
Select @T_ED=dbo.f_GetLogicalDayend(@EndTime)  
---ER0374 Till here  
  
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
--ER0374 Till Here  
  
  
--NR0094 From Here  
create table #Runningpart_Part  
(    
 Machineid nvarchar(50),    
 Componentid nvarchar(50),  
 StTime Datetime   
)    
  
Declare @LastComp as nvarchar(100)  
select @LastComp = Isnull(valueintext,'Display ReturnperHourUtilised') from cockpitdefaults where parameter='DisplayinIconicView'  
--NR0094 Till Here  
  
--ER0368 From here  
CREATE TABLE #ShiftDefn  
(  
 ShiftDate datetime,    
 Shiftname nvarchar(20),  
 ShftSTtime datetime,  
 ShftEndTime datetime,
 Machineid nvarchar(50), --SV 
 shiftid int --sv 
)  
  
declare @startdate as datetime  
declare @enddate as datetime  
declare @startdatetime nvarchar(20)  
  
--ER0374 From Here  
--select @startdate = dbo.f_GetLogicalDay(@StartTime,'start')  
--select @enddate = dbo.f_GetLogicalDay(@endtime,'start')  
select @startdate = dbo.f_GetLogicalDaystart(@StartTime)  
select @enddate = dbo.f_GetLogicalDaystart(@endtime)  
--ER0374 Till Here  
  
--SV From Here
--while @startdate<=@enddate  
--Begin  
--  
-- select @startdatetime = CAST(datePart(yyyy,@startdate) AS nvarchar(4)) + '-' +   
--     CAST(datePart(mm,@startdate) AS nvarchar(2)) + '-' +   
--     CAST(datePart(dd,@startdate) AS nvarchar(2))  
--  
-- INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)  
-- select @startdate,ShiftName,  
-- Dateadd(DAY,FromDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,  
-- DateAdd(Day,ToDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime  
-- from shiftdetails where running = 1 order by shiftid  
-- Select @startdate = dateadd(d,1,@startdate)  
--END  
--  
--create table #shift  
--(  
-- --ShiftDate Datetime, --DR0333  
-- ShiftDate nvarchar(10), --DR0333  
-- shiftname nvarchar(20),  
-- Shiftstart datetime,  
-- Shiftend datetime,  
-- shiftid int  
--)  
--  
--Insert into #shift (ShiftDate,shiftname,Shiftstart,Shiftend)  --select ShiftDate,shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333  
--select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333  
--  
--Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from  
--(Select SD.shiftid ,SD.shiftname from shiftdetails SD  
--inner join #shift S on SD.shiftname=S.shiftname where  
--running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname  
  
--ER0368 Till Here  
--SV Till Here


  
--------ER0385 From Here  
CREATE TABLE #MachineRunningStatus  
(  
 MachineID NvarChar(50),  
 MachineInterface nvarchar(50),  
 sttime Datetime,  
 ndtime Datetime,  
 DataType smallint,  
 ColorCode varchar(10)  
)  
  
Declare @CurrTime as DateTime  
SET @CurrTime = convert(nvarchar(20),getdate(),120)  
print @CurrTime  
--------ER0385 Till Here  
  
IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END  
if isnull(@machineid,'')<> ''  
begin  
 ---mod 3  
-- SET @strMachine = ' AND MachineInformation.MachineID = ''' + @machineid + ''''  
-- SELECT @StrExMachine=' AND Ex.MachineID = ''' + @Machineid + ''' '  
 SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''  
 SELECT @StrExMachine=' AND Ex.MachineID = N''' + @Machineid + ''' '  
 ---mod 3  
end  
if isnull(@PlantID,'')<> ''  
Begin  
 ---mod 3  
-- SET @strPlantID = ' AND PlantMachine.PlantID = ''' + @PlantID + ''''  
 SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''  
 ---mod 3  
End  




--SV Added From Here
while @startdate<=@enddate    
Begin    
    
INSERT INTO #ShiftDefn(Machineid,ShiftDate,Shiftname,ShftSTtime,ShftEndTime,shiftid)    
EXEC [dbo].[s_getLastWorkingShift] @Machineid,@PlantID,@startdate,'Shift'  
  
Select @startdate = dateadd(d,1,@startdate)   
  
END  

create table #shift    
(    
 --ShiftDate Datetime, --DR0333    
 ShiftDate nvarchar(10), --DR0333    
 shiftname nvarchar(20),    
 Shiftstart datetime,    
 Shiftend datetime,    
 shiftid int,
 Machineid nvarchar(50) --SV    
)    
    
Insert into #shift (Machineid,ShiftDate,shiftname,Shiftstart,Shiftend)    
--select ShiftDate,shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333    
select Machineid,convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333    
    
Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from    
(Select SD.shiftid ,SD.shiftname from shiftdetails SD    
inner join #shift S on SD.shiftname=S.shiftname where    
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname   
--SV Added Till Here




SET @strSql = 'INSERT INTO #CockpitData (  
 MachineID ,  
 MachineInterface,  
 ProductionEfficiency ,  
 AvailabilityEfficiency,  
 QualityEfficiency, --ER0368  
 OverallEfficiency,  
 Components ,  
 RejCount, --ER0368  
 TotalTime ,  
 UtilisedTime ,   
 ManagementLoss,  
 DownTime ,  
 TurnOver ,  
 ReturnPerHour ,  
 ReturnPerHourtotal,  
 CN,  
 PEGreen ,  
 PERed,  
 AEGreen ,  
 AERed ,  
 OEGreen ,  
 OERed,  
 QERed,  --ER0368  
 QEGreen, --ER0368  
 Remarks1, --ER0368  
 Remarks2 --ER0368  
 ) '  
SET @strSql = @strSql + ' SELECT MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,isnull(QERed,0),isnull(QEGreen,0),0,PlantID FROM MachineInformation --ER0368 --ER0417(To include Plantid in Remarks2 column)  
     LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID WHERE MachineInformation.interfaceid > ''0'' '  
SET @strSql =  @strSql + @strMachine + @strPlantID + @StrTPMMachines  
EXEC(@strSql)  
--mod 4 Get the Machines into #PLD  
SET @strSql = ''  
SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT)  
 SELECT MachineID ,Interfaceid,0  ,0 FROM MachineInformation WHERE  MachineInformation.interfaceid > ''0'' '  
SET @strSql =  @strSql + @strMachine + @StrTPMMachines  
EXEC(@strSql)  


/* Planned Down times for the given time period */  
SET @strSql = ''  
SET @strSql = 'Insert into #PlannedDownTimes  
 SELECT Machine,InterfaceID,  
  CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,  
  CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime  
 ,IgnoreCount   --SV Added Column
 FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
 WHERE PDTstatus =1 and(  
 (StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')  
 OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )  
 OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )  
 OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '  
SET @strSql =  @strSql + @strMachine + @StrTPMMachines + ' ORDER BY Machine,StartTime'  
EXEC(@strSql)  


--mod 4  
SET @strSql = ''  
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )  
  SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0  
  From ProductionCountException Ex  
  Inner Join MachineInformation M ON Ex.MachineID=M.MachineID  
  Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID  
  Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '  
---mod 2    
SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId '  
---mod 2  
SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 '  
SELECT @StrSql = @StrSql + @StrExMachine  
SELECT @StrSql = @StrSql +  
  'AND ((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''' )  
  OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''')  
  OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime)+''')  
  OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' ))'  
print @strsql  
Exec (@strsql)  
--select * from #Exceptions  
--return  
/*******************************      Utilised Calculation Starts ***************************************************/  
-- Get the utilised time  
--Optimize with innerjoin - mkestur 08/16/2004  
-- Type 1  
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)  
from  
(select      mc,sum(cycletime+loadunload) as cycle  
from #T_autodata autodata --ER0374  
where (autodata.msttime>=@StartTime)  
and (autodata.ndtime<=@EndTime)  
and (autodata.datatype=1)  
group by autodata.mc  
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
-- Type 2  
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)  
from  
(select  mc,SUM(DateDiff(second, @StartTime, ndtime)) cycle  
from #T_autodata autodata --ER0374  
where (autodata.msttime<@StartTime)  
and (autodata.ndtime>@StartTime)  
and (autodata.ndtime<=@EndTime)  
and (autodata.datatype=1)  
group by autodata.mc  
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
-- Type 3  
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)  
from  
(select  mc,sum(DateDiff(second, mstTime, @Endtime)) cycle  
from #T_autodata autodata --ER0374  
where (autodata.msttime>=@StartTime)  
and (autodata.msttime<@EndTime)  
and (autodata.ndtime>@EndTime)  
and (autodata.datatype=1)  
group by autodata.mc  
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
-- Type 4  
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0)  
from  
(select mc,  
sum(DateDiff(second, @StartTime, @EndTime)) cycle from #T_autodata autodata --ER0374  
where (autodata.msttime<@StartTime)  
and (autodata.ndtime>@EndTime)  
and (autodata.datatype=1)  
group by autodata.mc  
)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
/* Fetching Down Records from Production Cycle  */  
/* If Down Records of TYPE-2*/  
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)  
FROM  
(Select AutoData.mc ,  
SUM(  
CASE  
 When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )  
 When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)  
END) as Down  
From #T_autodata AutoData INNER Join --ER0374  
 (Select mc,Sttime,NdTime From #T_autodata AutoData  
  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
  (msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1  
ON AutoData.mc=T1.mc  
Where AutoData.DataType=2  
And ( autodata.Sttime > T1.Sttime )  
And ( autodata.ndtime <  T1.ndtime )  
AND ( autodata.ndtime >  @StartTime )  
GROUP BY AUTODATA.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface  
/* If Down Records of TYPE-3*/  
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)  
FROM  
(Select AutoData.mc ,  
SUM(CASE  
 When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )  
 When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)  
END) as Down   
From #T_autodata AutoData INNER Join --ER0374  
 (Select mc,Sttime,NdTime From #T_autodata AutoData  
  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
  (sttime >= @StartTime)And (ndtime > @EndTime) and (sttime<@EndTime) ) as T1  
ON AutoData.mc=T1.mc  
Where AutoData.DataType=2  
And (T1.Sttime < autodata.sttime  )  
And ( T1.ndtime >  autodata.ndtime)  
AND (autodata.sttime  <  @EndTime)  
GROUP BY AUTODATA.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface  
/* If Down Records of TYPE-4*/  
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)  
FROM  
(Select AutoData.mc ,  
SUM(CASE  
--DR0236 - KarthikG - 19/Jun/2010 :: From Here  
-- When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)  
-- When autodata.sttime < @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )  
-- When autodata.ndtime >= @EndTime AND autodata.sttime>@StartTime Then datediff(s,autodata.sttime, @EndTime )  
-- When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)  
 When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)  
 When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )  
 When autodata.sttime>=@StartTime And autodata.sttime < @EndTime AND autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )  
 When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)  
--DR0236 - KarthikG - 19/Jun/2010 :: Till Here  
END) as Down  
From #T_autodata AutoData INNER Join --ER0374  
 (Select mc,Sttime,NdTime From #T_autodata AutoData  
  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
  (msttime < @StartTime)And (ndtime > @EndTime) ) as T1  
ON AutoData.mc=T1.mc  
Where AutoData.DataType=2  
And (T1.Sttime < autodata.sttime  )  
And ( T1.ndtime >  autodata.ndtime)  
AND (autodata.ndtime  >  @StartTime)  
AND (autodata.sttime  <  @EndTime)  
GROUP BY AUTODATA.mc  
)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface  
  
--mod 4:Get utilised time over lapping with PDT.  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
  
  
     /*************************** ER0374 Commented From Here **********************  
 UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)  
 FROM(  
  --Production Time in PDT  
  SELECT autodata.MC,SUM  
   (CASE  
--   WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload) --DR0325 Commented  
   WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added  
   WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )  
   WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END)  as PPDT  
  FROM AutoData CROSS jOIN #PlannedDownTimes T  
  WHERE autodata.DataType=1 And T.MachineInterface=AutoData.mc AND  
   (  
   (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
   OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )  
  group by autodata.mc  
 )  
  as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface  
  
  
 --mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
  UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)  FROM (  
  Select AutoData.mc,  
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  From AutoData INNER Join  
   (Select mc,Sttime,NdTime From AutoData  
    Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
    (msttime >= @StartTime) AND (ndtime <= @EndTime)) as T1  
  ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T  
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
  And (( autodata.Sttime > T1.Sttime )  
  And ( autodata.ndtime <  T1.ndtime )  
  )  
  AND  
  ((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))  
  or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)  
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )  
  or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )  
  GROUP BY AUTODATA.mc  
  )AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface  
 ---mod 4(4)  
   
 /* Fetching Down Records from Production Cycle  */  
 /* If production  Records of TYPE-2*/  
 UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)  FROM (  
  Select AutoData.mc,  
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  From AutoData INNER Join  
   (Select mc,Sttime,NdTime From AutoData  
    Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
    (msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1  
  ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T  
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
  And (( autodata.Sttime > T1.Sttime )  
  And ( autodata.ndtime <  T1.ndtime )  
  AND ( autodata.ndtime >  @StartTime ))  
  AND  
  (( T.StartTime >= @StartTime )  
  And ( T.StartTime <  T1.ndtime ) )  
  GROUP BY AUTODATA.mc  
 )AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface  
   
 /* If production Records of TYPE-3*/  
 UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)  
 FROM  
 (Select AutoData.mc ,  
 SUM(  
 CASE    
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
 END) as IPDT  
 From AutoData INNER Join  
  (Select mc,Sttime,NdTime From AutoData  
  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
  (sttime >= @StartTime)And (ndtime > @EndTime) and autodata.sttime <@EndTime) as T1  
 ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T  
 Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
 And ((T1.Sttime < autodata.sttime  )  
 And ( T1.ndtime >  autodata.ndtime)  
 AND (autodata.msttime  <  @EndTime))  
 AND  
 (( T.EndTime > T1.Sttime )  
 And ( T.EndTime <=@EndTime ) )  
 GROUP BY AUTODATA.mc)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface  
   
   
 /* If production Records of TYPE-4*/  
 UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)  
 FROM  
 (Select AutoData.mc ,  
 SUM(  
 CASE    
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
 END) as IPDT  
 From AutoData INNER Join  
  (Select mc,Sttime,NdTime From AutoData  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
   (msttime < @StartTime)And (ndtime > @EndTime)) as T1  
 ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T  
 Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
 And ( (T1.Sttime < autodata.sttime  )  
  And ( T1.ndtime >  autodata.ndtime)  
  AND (autodata.ndtime  >  @StartTime)  
  AND (autodata.sttime  <  @EndTime))  
 AND  
 (( T.StartTime >=@StartTime)  
 And ( T.EndTime <=@EndTime ) )  
 GROUP BY AUTODATA.mc)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface  
     *************************** ER0374 Commented Till Here **********************/  
  
 ------------------------------------ ER0374 Added Till Here ---------------------------------  
 UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)  
 FROM(  
  --Production Time in PDT  
  SELECT autodata.MC,SUM  
   (CASE  
--   WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload) --DR0325 Commented  
   WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added  
   WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )  
   WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END)  as PPDT  
   FROM (select M.machineid,mc,msttime,ndtime from #T_autodata autodata  
    inner join machineinformation M on M.interfaceid=Autodata.mc  
     where autodata.DataType=1 And   
    ((autodata.msttime >= @starttime  AND autodata.ndtime <=@Endtime)  
    OR ( autodata.msttime < @starttime  AND autodata.ndtime <= @Endtime AND autodata.ndtime > @starttime )  
    OR ( autodata.msttime >= @starttime   AND autodata.msttime <@Endtime AND autodata.ndtime > @Endtime )  
    OR ( autodata.msttime < @starttime  AND autodata.ndtime > @Endtime))  
    )  
  AutoData inner jOIN #PlannedDownTimes T on T.Machineid=AutoData.machineid  
  WHERE   
   (  
   (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
   OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )  
  group by autodata.mc  
 )  
  as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface  
  
  --mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
  UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)  FROM (  
  Select T1.mc,SUM(  
   CASE    
    When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1  
    When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2  
    When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3  
    when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
   END) as IPDT from  
  (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A  
  Where A.DataType=2  
  and exists   
   (  
   Select B.Sttime,B.NdTime,B.mc From #T_autodata B  
   Where B.mc = A.mc and  
   B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And  
   (B.msttime >= @starttime AND B.ndtime <= @Endtime) and  
   --(B.sttime < A.sttime) AND (B.ndtime > A.ndtime) --DR0339  
     (B.sttime <= A.sttime) AND (B.ndtime >= A.ndtime) --DR0339  
   )  
   )as T1 inner join  
  (select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime,   
  case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes   
  where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))  
  or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)  
  or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)  
  or (( StartTime <@starttime) And ( EndTime >@Endtime )) )  
  )T  
  on T1.machine=T.machine AND  
  ((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))  
  or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)  
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )  
  or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc  
  )AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface  
  ---mod 4(4)  
   
 /* Fetching Down Records from Production Cycle  */  
 /* If production  Records of TYPE-2*/  
 UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)  FROM (  
  Select T1.mc,SUM(  
  CASE    
   When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1  
   When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2  
   When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3  
   when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT from  
  (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A  
  Where A.DataType=2  
  and exists   
  (  
  Select B.Sttime,B.NdTime From #T_autodata B  
  Where B.mc = A.mc and  
  B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And  
  (B.msttime < @StartTime And B.ndtime > @StartTime AND B.ndtime <= @EndTime)   
  And ((A.Sttime > B.Sttime) And ( A.ndtime < B.ndtime) AND ( A.ndtime > @StartTime ))  
  )  
  )as T1 inner join  
  (select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime,   
  case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes   
  where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))  
  or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)  
  or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)  
  or (( StartTime <@starttime) And ( EndTime >@Endtime )) )  
  )T  
  on T1.machine=T.machine AND  
  (( T.StartTime >= @StartTime ) And ( T.StartTime <  T1.ndtime )) group by T1.mc  
 )AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface  
   
 /* If production Records of TYPE-3*/  
 UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)FROM (  
 Select T1.mc,SUM(  
  CASE    
   When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1  
   When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2  
   When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3  
   when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT from  
  (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A  
  Where A.DataType=2  
  and exists   
  (  
  Select B.Sttime,B.NdTime From #T_autodata B  
  Where B.mc = A.mc and  
  B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And  
  (B.sttime >= @StartTime And B.ndtime > @EndTime and B.sttime <@EndTime) and  
  ((B.Sttime < A.sttime  )And ( B.ndtime > A.ndtime) AND (A.msttime < @EndTime))  
  )  
  )as T1 inner join  
--  Inner join #PlannedDownTimes T  
  (select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime,   
  case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes   
  where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))  
  or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)  
  or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)  
  or (( StartTime <@starttime) And ( EndTime >@Endtime )) )  
  )T  
  on T1.machine=T.machine  
  AND (( T.EndTime > T1.Sttime )And ( T.EndTime <=@EndTime )) group by T1.mc  
  )AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface  
   
   
 /* If production Records of TYPE-4*/  
 UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)FROM (  
 Select T1.mc,SUM(  
 CASE    
  When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1  
  When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2  
  When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3  
  when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
 END) as IPDT from  
 (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A  
 Where A.DataType=2  
 and exists   
 (  
 Select B.Sttime,B.NdTime From #T_autodata B  
 Where B.mc = A.mc and  
 B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And  
 (B.msttime < @StartTime And B.ndtime > @EndTime)  
 And ((B.Sttime < A.sttime)And ( B.ndtime >  A.ndtime)AND (A.ndtime  >  @StartTime) AND (A.sttime <  @EndTime))  
 )  
 )as T1 inner join  
  (select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime,   
  case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes   
  where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))  
  or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)  
  or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)  
  or (( StartTime <@starttime) And ( EndTime >@Endtime )) )  
  )T  
  on T1.machine=T.machine AND  
 (( T.StartTime >=@StartTime) And ( T.EndTime <=@EndTime )) group by T1.mc  
 )AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface  
  ------------------------------------ ER0374 Added Till Here ---------------------------------  
  
  
END  
--mod 4  
/*******************************      Utilised Calculation Ends ***************************************************/  
/*******************************Down Record***********************************/  
--**************************************** ManagementLoss and Downtime Calculation Starts **************************************  
---Below IF condition added by Mrudula for mod 4. TO get the ML if 'Ignore_Dtime_4m_PLD'<>"Y"  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_
4m_PLD')<>'Y')  
BEGIN  
  -- Type 1  
  UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
  from  
  (select mc,sum(  
  CASE  
  WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0  
  THEN isnull(downcodeinformation.Threshold,0)  
  ELSE loadunload  
  END) AS LOSS  
  from #T_autodata autodata  --ER0374  
  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
  where (autodata.msttime>=@StartTime)  
  and (autodata.ndtime<=@EndTime)  
  and (autodata.datatype=2)  
  and (downcodeinformation.availeffy = 1)   
  and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
  group by autodata.mc) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
  -- Type 2  
  UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
  from  
  (select      mc,sum(  
  CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0  
  then isnull(downcodeinformation.Threshold,0)  
  ELSE DateDiff(second, @StartTime, ndtime)  
  END)loss  
  --DateDiff(second, @StartTime, ndtime)  
  from #T_autodata autodata  --ER0374  
  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
  where (autodata.sttime<@StartTime)  
  and (autodata.ndtime>@StartTime)  
  and (autodata.ndtime<=@EndTime)  
  and (autodata.datatype=2)  
  and (downcodeinformation.availeffy = 1)  
  and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
  group by autodata.mc  
  ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
  -- Type 3  
  UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
  from  
  (select      mc,SUM(  
  CASE WHEN DateDiff(second,stTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0  
  then isnull(downcodeinformation.Threshold,0)  
  ELSE DateDiff(second, stTime, @Endtime)  
  END)loss  
  -- sum(DateDiff(second, stTime, @Endtime)) loss  
  from #T_autodata autodata --ER0374  
  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
  where (autodata.msttime>=@StartTime)  
  and (autodata.sttime<@EndTime)  
  and (autodata.ndtime>@EndTime)  
  and (autodata.datatype=2)  
  and (downcodeinformation.availeffy = 1)  
  and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
  group by autodata.mc  
  ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
  -- Type 4  
  UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
  from  
  (select mc,sum(  
  CASE WHEN DateDiff(second, @StartTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0  
  then isnull(downcodeinformation.Threshold,0)  
  ELSE DateDiff(second, @StartTime, @Endtime)  
  END)loss  
  --sum(DateDiff(second, @StartTime, @Endtime)) loss  
  from #T_autodata autodata --ER0374  
  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
  where autodata.msttime<@StartTime  
  and autodata.ndtime>@EndTime  
  and (autodata.datatype=2)  
  and (downcodeinformation.availeffy = 1)  
  and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
  group by autodata.mc  
  ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
  ---get the downtime for the time period  
  UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
  from  
  (select mc,sum(  
    CASE  
    WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload  
    WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)  
    WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)  
    WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)  
    END  
   )AS down  
  from #T_autodata autodata --ER0374  
  inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  where autodata.datatype=2 AND  
  (  
  (autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)  
  OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  
  OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  
  OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )  
  )  
  group by autodata.mc  
  ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
--mod 4  
End  
--mod 4  
---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN  
 ---step 1  
   
 UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select mc,sum(  
   CASE  
         WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload  
   WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)  
   WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)  
   WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)  
   END  
  )AS down  
 from #T_autodata autodata --ER0374  
 inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
 where autodata.datatype=2 AND  
 (  
 (autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)  
 OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  
 OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  
 OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )  
 ) AND (downcodeinformation.availeffy = 0)  
 group by autodata.mc  
 ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
 --select * from #CockpitData  
 ---step 2  
 ---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML  
 UPDATE #PLD set dPlannedDT =isnull(dPlannedDT,0) + isNull(TT.PPDT ,0)  
 FROM(  
  --Production PDT  
  SELECT autodata.MC, SUM  
     (CASE  
   WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END ) as PPDT  
  FROM #T_autodata AutoData --ER0374  
  CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND  
   (  
   (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
   OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
   )  
   /*AND  
   (  
   (autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)  
   OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )  
   OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )  
   OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)  
   ) */ AND (downcodeinformation.availeffy = 0)  
  group by autodata.mc  
 ) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface  
 --select * from #PLD  
 ---step 3  
 ---Management loss calculation  
 ---IN T1 Select get all the downtimes which is of type management loss  
 ---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record  
 ---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)  
 ---In T4 consolidate everything at machine level and update the same to #CockpitData for ManagementLoss and MLDown  
   
 UPDATE #CockpitData SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)  
 from  
 (select T3.mc,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (  
 select   t1.id,T1.mc,T1.Threshold,  
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0  
 then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)  
 else 0 End  as Dloss,  
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0  
 then isnull(T1.Threshold,0)  
 else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss  
  from  
   
 (   select id,mc,comp,opn,opr,D.threshold,  
  case when autodata.sttime<@StartTime then @StartTime else sttime END as sttime,  
         case when ndtime>@EndTime then @EndTime else ndtime END as ndtime  
  from #T_autodata autodata --ER0374  
  inner join downcodeinformation D  
  on autodata.dcode=D.interfaceid where autodata.datatype=2 AND  
  (  
  (autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)  
  OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  
  OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  
  OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )  
  ) AND (D.availeffy = 1)     
  and (D.ThresholdfromCO <>1)) as T1   --NR0097  
 left outer join  
 (SELECT autodata.id,  
         sum(CASE  
   WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END ) as PPDT  
  FROM #T_autodata AutoData --ER0374  
  CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND  
   (  
   (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
   OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
   )  
--   AND  
--   (  
--   (autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)  
--   OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )  
--   OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )  
--   OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)  
--   )  
   AND (downcodeinformation.availeffy = 1)   
   AND (downcodeinformation.ThresholdfromCO <>1) --NR0097   
   group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc  
 ) as t4 inner join #CockpitData on t4.mc = #CockpitData.machineinterface  
  
 UPDATE #CockpitData SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)  
END  
  
----------------------------- NR0097 Added From here ----------------------------------------------  
select autodata.id,autodata.mc,autodata.comp,autodata.opn,  
isnull(CO.Stdsetuptime,0)AS Stdsetuptime ,   
sum(case  
when autodata.sttime>=@starttime and autodata.ndtime<=@endtime then autodata.loadunload  
when autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime then Datediff(s,@starttime,ndtime)  
when autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime then  datediff(s,sttime,@endtime)  
when autodata.sttime<@starttime and autodata.ndtime>@endtime then  datediff(s,@starttime,@endtime)  
end) as setuptime,0 as ML,0 as Downtime  
into #setuptime  
from #T_autodata autodata --ER0374  
inner join machineinformation M on autodata.mc = M.interfaceid  
inner join downcodeinformation D on autodata.dcode=D.interfaceid  
left outer join componentinformation CI on autodata.comp = CI.interfaceid  
left outer join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid  
where autodata.datatype=2 and D.ThresholdfromCO = 1  
And  
((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or  
 (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or  
 (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or  
 (autodata.sttime<@starttime and autodata.ndtime>@endtime))  
group by autodata.id,autodata.mc,autodata.comp,autodata.opn,CO.Stdsetuptime  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN  
 update #setuptime set setuptime = isnull(setuptime,0) - isnull(t1.setuptime_pdt,0) from   
 (  
  select autodata.id,autodata.mc,autodata.comp,autodata.opn,  
  sum(datediff(s,CASE WHEN autodata.sttime >= T.StartTime THEN autodata.sttime else T.StartTime End,  
  CASE WHEN autodata.ndtime <= T.EndTime THEN autodata.ndtime else T.EndTime End))  
  as setuptime_pdt  
  from #T_autodata autodata --ER0374  
  inner join machineinformation M on autodata.mc = M.interfaceid  
  inner join componentinformation CI on autodata.comp = CI.interfaceid  
  inner join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid  
  inner join downcodeinformation D on autodata.dcode=D.interfaceid  
  CROSS jOIN #PlannedDownTimes T  
  where datatype=2 and T.MachineInterface=AutoData.mc   
  and D.ThresholdfromCO = 1 And  
  ((autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
    OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
    OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
    OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
  )AND  
  ((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or  
   (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or  
   (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or  
   (autodata.sttime<@starttime and autodata.ndtime>@endtime))  
  group by autodata.id,autodata.mc,autodata.comp,autodata.opn  
 ) as t1 inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn  
  
 Update #setuptime set Downtime = isnull(Downtime,0) + isnull(T1.Setupdown,0) from  
 (Select id,mc,comp,opn,  
 Case when setuptime>stdsetuptime then setuptime-stdsetuptime else 0 end as Setupdown  
 from #setuptime)T1  inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn  
End  
  
Update #setuptime set ML = Isnull(ML,0) + isnull(T1.SetupML,0) from  
(Select id,mc,comp,opn,  
Case when setuptime<stdsetuptime then setuptime else stdsetuptime end as SetupML  
from #setuptime)T1  inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn  
----------------------------- NR0097 Added Till here ----------------------------------------------  
  
  
---mod 4: Till here Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss  
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'  
BEGIN  
 UPDATE #PLD set dPlannedDT =isnull(dPlannedDT,0) + isNull(TT.PPDT ,0)  
 FROM(  
  --Production PDT  
  SELECT autodata.MC, SUM  
         (CASE  
   WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END ) as PPDT  
  FROM #T_autodata AutoData  --ER0374  
  CROSS jOIN #PlannedDownTimes T  
  Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID  
  WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND  
   (  
   (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
   OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
   )  
--   AND  
--   (  
--   (autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)  
--   OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )  
--   OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )  
--   OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)  
--   )--AND (D.availeffy = 0)  
  group by autodata.mc  
 ) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface  
END  
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N  
--************************************ Down and Management  Calculation Ends ******************************************  
---mod 4  
-- Get the value of CN  
-- Type 1  
/* Changed by SSK to Combine SubOperations  
*/  
UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)  
from  
(select mc,  
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1  
--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1  
FROM #T_autodata autodata --ER0374  
INNER JOIN  
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN  
componentinformation ON autodata.comp = componentinformation.InterfaceID AND  
componentoperationpricing.componentid = componentinformation.componentid  
--mod 2  
inner join machineinformation on machineinformation.interfaceid=autodata.mc  
and componentoperationpricing.machineid=machineinformation.machineid  
--mod 2  
where (((autodata.sttime>=@StartTime)and (autodata.ndtime<=@EndTime)) or  
((autodata.sttime<@StartTime)and (autodata.ndtime>@StartTime)and (autodata.ndtime<=@EndTime)) )  
and (autodata.datatype=1)  
group by autodata.mc  
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  

-- mod 4 Ignore count from CN calculation which is over lapping with PDT  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 UPDATE #CockpitData SET CN = isnull(CN,0) - isNull(t2.C1N1,0)  
 From  
 (  
  select mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1  
  From #T_autodata A --ER0374  
  Inner join machineinformation M on M.interfaceid=A.mc  
  Inner join componentinformation C ON A.Comp=C.interfaceid  
  Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID  
  Cross jOIN #PlannedDownTimes T  
  WHERE A.DataType=1 AND T.MachineInterface=A.mc  
  AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)  
  AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)  
  Group by mc  
 ) as T2  
 inner join #CockpitData  on t2.mc = #CockpitData.machineinterface  
END  
-- mod 4 


-----SV
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='N'  
BEGIN  
 UPDATE #CockpitData SET CN = isnull(CN,0) - isNull(t2.C1N1,0)  
 From  
 (  
  select mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1  
  From #T_autodata A --ER0374  
  Inner join machineinformation M on M.interfaceid=A.mc  
  Inner join componentinformation C ON A.Comp=C.interfaceid  
  Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID  
  Cross jOIN #PlannedDownTimes T  
  WHERE A.DataType=1 AND T.MachineInterface=A.mc  and T.IgnoreCount=1
  AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)  
  AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)  
  Group by mc  
 ) as T2  
 inner join #CockpitData  on t2.mc = #CockpitData.machineinterface  
END  
----SV

 
-- Get the TurnOver  
-- Type 1  
--*********************************************************************************  
-- Following Code is added by Sangeeta K . Mutlistpindle Concept affects Count And TurnOvER--  
--mod 4(3):Following IF condition is added to get the exception count if there are any exception rule defined.  
if (select count(*) from #Exceptions)> 0  
Begin  
--mod 4(3)  
 UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime  
 UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )  
 Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From  
(  
   SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,  
   --SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097  
   SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097  
    From (  
    select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount   
    from #T_autodata autodata --ER0374  
    Inner Join MachineInformation  ON autodata.MC=MachineInformation.InterfaceID  
    Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID  
    Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID'  
  ---mod 2  
   Select @StrSql = @StrSql +' and ComponentOperationPricing.machineid=machineinformation.machineid'  
  ---mod 2  
  Select @StrSql = @StrSql +' Inner Join (  
     Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions Ex Where OperationNo<>0 '  
  Select @StrSql = @StrSql + @StrExMachine  
  Select @StrSql = @StrSql +')AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo  
     and Tt1.MachineID=ComponentOperationPricing.MachineID  
    Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1)'  
  Select @StrSql = @StrSql + @StrMachine  
  Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn  
   ) as T1  
      Inner join componentinformation C on T1.Comp=C.interfaceid  
      Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = T1.machineID '  
  ---mod 2  
   Select @StrSql = @StrSql +' Inner join machineinformation M on T1.machineid = M.machineid '  
  ---mod 2  
     Select @StrSql = @StrSql +' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime  
  )AS T2  
  WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime  
  AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'  
  print @StrSql  
  Exec(@StrSql)  
--mod 4(1):Interaction with PDT  
  If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
  BEGIN  
    Select @StrSql =''  
    Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.compCount,0)  
    From  
    (  
     SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,  
     --SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as compCount --NR0097  
     SUM((CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as compCount --NR0097  
     From  
     (  
      select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,  
      Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount   
      from #T_autodata autodata --ER0374  
      Inner Join MachineInformation ON autodata.MC=MachineInformation.InterfaceID  
      Inner Join ComponentInformation ON autodata.Comp = ComponentInformation.InterfaceID  
      Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID And ComponentOperationPricing.MachineID = MachineInformation.MachineID  
      Inner Join   
      (  
       SELECT Ex.MachineID,Ex.ComponentID,Ex.OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,  
       CASE  
        WHEN (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime) THEN Ex.StartTime  
        WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.StartTime  
        ELSE Td.StartTime  
       END AS PLD_StartTime,  
       CASE  
        WHEN (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime) THEN Ex.EndTime  
        WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.EndTime  
        ELSE  Td.EndTime  
       END AS PLD_EndTime  
       From #Exceptions AS Ex inner JOIN #PlannedDownTimes AS Td on Ex.MachineID = Td.MachineID  
       Where ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR  
       (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR  
       (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR  
       (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'  
     Select @StrSql = @StrSql + @StrExMachine  
     Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND T1.OperationNo= ComponentOperationPricing.OperationNo and T1.Machineid=ComponentOperationPricing.MachineID  
      Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)  
     AND (autodata.ndtime > ''' + convert(nvarchar(20),@StartTime)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@EndTime)+''' )'  
     Select @StrSql = @StrSql + @StrMachine  
     Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn  
     )AS T2  
     Inner join componentinformation C on T2.Comp=C.interfaceid  
     Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and T2.MachineID = O.MachineID  
     GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime  
    )As T3  
    WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime  
    AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'  
    --PRINT @StrSql  
    EXEC(@StrSql)  
    
  END  
--mod 4(1):Interaction with PDT  
  UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))  
--mod 4(3):Following End is wrt to get the exception count if there are any exception rule defined.  
End  
--mod 4(3):  
--*********************************************************************************  
--TYPE1,TYPE2  
UPDATE #CockpitData SET turnover = isnull(turnover,0) + isNull(t2.revenue,0)  
from  
(select mc,  
SUM((componentoperationpricing.price/ISNULL(ComponentOperationPricing.SubOperations,1))* ISNULL(autodata.partscount,1)) revenue  
FROM #T_autodata autodata --ER0374  
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID AND componentoperationpricing.componentid = componentinformation.componentid  
---mod 2  
inner join machineinformation on componentoperationpricing.machineid=machineinformation.machineid  
--mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009.  
AND autodata.mc = machineinformation.interfaceid  
--mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009.  
---mod 2  
where (  
(autodata.sttime>=@StartTime and autodata.ndtime<=@EndTime)OR  
(autodata.sttime<@StartTime and autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime))and (autodata.datatype=1)  
group by autodata.mc  
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface  
  
  
--Excluding Exception count from turnover calculation  
UPDATE #CockpitData SET Turnover = ISNULL(Turnover,0) - ISNULL(t2.xTurnover,0)  
from  
( select Ex.MachineID,  
SUM((O.price)* ISNULL(ExCount,0)) as xTurnover  
From #Exceptions Ex  
INNER JOIN ComponentInformation C ON Ex.ComponentID=C.ComponentID  
INNER JOIN ComponentOperationPricing O ON Ex.OperationNO=O.OperationNO AND C.ComponentID=O.ComponentID  
---mod 2  
and O.machineid = Ex.machineid  
---mod 2  
GROUP BY Ex.MachineID) as T2  
Inner join #CockpitData on T2.MachineID = #CockpitData.MachineID  
  
--Mod 4 Apply PDT for TurnOver Calculation.  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 UPDATE #CockpitData SET turnover = isnull(turnover,0) - isNull(t2.revenue,0)  
 From  
 (  
  select mc,SUM((O.price * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))as revenue  
  From #T_autodata A --ER0374  
  Inner join machineinformation M on M.interfaceid=A.mc  
  Inner join componentinformation C ON A.Comp=C.interfaceid  
  Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID  
  CROSS jOIN #PlannedDownTimes T  
  WHERE A.DataType=1 And T.MachineInterface = A.mc  
  AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)  
  AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)  
  Group by mc  
 ) as T2  
 inner join #CockpitData  on t2.mc = #CockpitData.machineinterface  
END  
--Mod 4 


----SV
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='N'  
BEGIN  
 UPDATE #CockpitData SET turnover = isnull(turnover,0) - isNull(t2.revenue,0)  
 From  
 (  
  select mc,SUM((O.price * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))as revenue  
  From #T_autodata A --ER0374  
  Inner join machineinformation M on M.interfaceid=A.mc  
  Inner join componentinformation C ON A.Comp=C.interfaceid  
  Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID  
  CROSS jOIN #PlannedDownTimes T  
  WHERE A.DataType=1 And T.MachineInterface = A.mc  AND T.IgnoreCount=1
  AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)  
  AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)  
  Group by mc  
 ) as T2  
 inner join #CockpitData  on t2.mc = #CockpitData.machineinterface  
END  
-----SV
 
--Calculation of PartsCount Begins..  
UPDATE #CockpitData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)  
From  
(  
 --Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp --NR0097  
   Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp --NR0097  
     From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn   
   from #T_autodata autodata --ER0374  
     where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)  
     Group By mc,comp,opn) as T1  
 Inner join componentinformation C on T1.Comp = C.interfaceid  
 Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid  
 ---mod 2  
 inner join machineinformation on machineinformation.machineid =O.machineid  
 and T1.mc=machineinformation.interfaceid  
 ---mod 2  
 GROUP BY mc  
) As T2 Inner join #CockpitData on T2.mc = #CockpitData.machineinterface  
  
--Apply Exception on Count..  
UPDATE #CockpitData SET components = ISNULL(components,0) - ISNULL(t2.comp,0)  
from  
( select MachineID,SUM(ExCount) as comp  
 From #Exceptions GROUP BY MachineID) as T2  
Inner join #CockpitData on T2.MachineID = #CockpitData.MachineID  
  
  
--Mod 4 Apply PDT for calculation of Count  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 UPDATE #CockpitData SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(  
  --select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( --NR0097  
  select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( --NR0097  
   select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn   
   from #T_autodata autodata --ER0374  
   CROSS JOIN #PlannedDownTimes T  
   WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc  
   AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)  
      Group by mc,comp,opn  
  ) as T1  
 Inner join Machineinformation M on M.interfaceID = T1.mc  
 Inner join componentinformation C on T1.Comp=C.interfaceid  
 Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID  
 GROUP BY MC  
 ) as T2 inner join #CockpitData on T2.mc = #CockpitData.machineinterface  
END  
--Mod 4  

-----SV
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='N'  
BEGIN  
 UPDATE #CockpitData SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(  
  --select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( --NR0097  
  select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( --NR0097  
   select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn   
   from #T_autodata autodata --ER0374  
   CROSS JOIN #PlannedDownTimes T  
   WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc  and T.IgnoreCount=1
   AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)  
      Group by mc,comp,opn  
  ) as T1  
 Inner join Machineinformation M on M.interfaceID = T1.mc  
 Inner join componentinformation C on T1.Comp=C.interfaceid  
 Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID  
 GROUP BY MC  
 ) as T2 inner join #CockpitData on T2.mc = #CockpitData.machineinterface  
END  
----SV


--Calculation of PartsCount Ends..  
--mod 4: Update Utilised Time and Down time  
UPDATE #CockpitData  
 SET UtilisedTime=(UtilisedTime-ISNULL(#PLD.pPlannedDT,0)+isnull(#PLD.IPlannedDT,0)),  
     DownTime=(DownTime-ISNULL(#PLD.dPlannedDT,0))  
 From #CockpitData Inner Join #PLD on #PLD.Machineid=#CockpitData.Machineid  
---mod 4  
  
---------------------------------- NR0097 From Here -------------------------------------------  
Update #CockpitData SET downtime = isnull(downtime,0)+ isnull(T1.down,0)  , ManagementLoss = isnull(ManagementLoss,0)+isnull(T1.ML,0) from  
(Select mc,Sum(ML) as ML,Sum(Downtime) as Down from #setuptime Group By mc)T1  
inner join #CockpitData on T1.mc = #CockpitData.machineinterface  
---------------------------------- NR0097 Till Here -------------------------------------------  
  
-- Calculate efficiencies  
UPDATE #CockpitData  
SET  
 ProductionEfficiency = (CN/UtilisedTime) ,  
 AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss),  
 TotalTime = DateDiff(second, @StartTime, @EndTime),  
 ReturnPerHour = (TurnOver/UtilisedTime)*3600,  
 ReturnPerHourtotal = (TurnOver/DateDiff(second, @StartTime, @EndTime))*3600,  
 Remarks = ' '  
WHERE UtilisedTime <> 0  
  
--NR0090 From Here  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='DisplayTTFormat')='Display TotalTime - Less PDT'   
BEGIN  
----------------------------------- DR0330 From Here -----------------------------------------------------  
---- UPDATE #CockpitData SET TotalTime = Totaltime -ISNULL(#PLD.pPlannedDT,0)- isnull(#PLD.IPlannedDT,0)- ISNULL(#PLD.dPlannedDT,0)  
-- UPDATE #CockpitData SET TotalTime = Totaltime -ISNULL(#PLD.pPlannedDT,0)-ISNULL(#PLD.dPlannedDT,0) + isnull(#PLD.IPlannedDT,0)  
-- From #CockpitData Inner Join #PLD on #PLD.Machineid=#CockpitData.Machineid   
  
-- UPDATE #CockpitData SET TotalTime = Case when Remarks<>'Machine Not In Production' then Totaltime - isnull(T1.PDT,0) else isnull(T1.PDT,0) End  
 UPDATE #CockpitData SET TotalTime = Totaltime - isnull(T1.PDT,0)   
 from  
 (Select Machine,SUM(datediff(S,Starttime,endtime))as PDT from Planneddowntimes  
  where starttime>=@starttime and endtime<=@endtime group by machine)T1  
  Inner Join #CockpitData on T1.Machine=#CockpitData.Machineid WHERE UtilisedTime <> 0   
----------------------------------- DR0330 Till Here -----------------------------------------------------  
End  
--NR0090 Till Here  
  
--UPDATE #CockpitData  
--SET  
-- ManagementLoss = ((TotalTime - ManagementLoss)- (DownTime- ManagementLoss))/(TotalTime-ManagementLoss)   
--WHERE UtilisedTime <> 0  
--ER0417 Commented and Added Below  
--UPDATE #CockpitData  
--SET  
-- OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,  
-- ProductionEfficiency = ProductionEfficiency * 100 ,  
-- AvailabilityEfficiency = AvailabilityEfficiency * 100  
--ER0417 Commented and Added Below  
--NR0094 From Here  
--UPDATE #CockpitData  
--SET Remarks = 'Machine Not In Production'  
--WHERE UtilisedTime = 0  
--NR0094 Till Here  
-------------------------------------------------------------------------------------------------------------------  
     /* Maximum Down Reason Time ,Calculation as goes down*/  
---Irrespective of whether the down is management loss or genuine down we are considering the down reason which is the largest  
----------------------------------------------------------------------------------------------------------------------  
CREATE TABLE #DownTimeData  
(  
 MachineID nvarchar(50) NOT NULL,  
 --McInterfaceid nvarchar(4),  --ER0459
 McInterfaceid nvarchar(50),  --ER0459
 DownID nvarchar(50) NOT NULL,  
 DownTime float,  
 DownFreq int  
 --CONSTRAINT downtimedata_key PRIMARY KEY (MachineId, DownID)  
)  
ALTER TABLE #DownTimeData  
 ADD PRIMARY KEY CLUSTERED  
 (  
  [MachineId], [DownID]  
 )ON [PRIMARY]  
--mod 4 commented below tables  for Optimization  
--CREATE TABLE #FinalData  
--(  
 --MachineID nvarchar(50) NOT NULL,  
 --DownID nvarchar(50) NOT NULL,  
 --DownTime float,  
 --downfreq int,  
 --TotalMachine float,  
 --TotalDown float,  
 --TotalMachineFreq float DEFAULT(0),  
 --TotalDownFreq float DEFAULT(0)  
 --CONSTRAINT finaldata_key PRIMARY KEY (MachineID, DownID)  
--)  
--ALTER TABLE #FinalData  
 --ADD PRIMARY KEY CLUSTERED  
 --(  
 -- [MachineId], [DownID]  
 --)ON [PRIMARY]  
--CREATE TABLE #MAXDownReasonTime(  
 --MachineID nvarchar(50),  
 --MaxReasonTime nvarchar(50) Default('')  
--)  
--mod 4 commented till here  for Optimization  
select @strsql = ''  
select @strsql = 'INSERT INTO #DownTimeData (MachineID,McInterfaceid, DownID, DownTime,DownFreq) SELECT Machineinformation.MachineID AS MachineID,Machineinformation.interfaceid, downcodeinformation.downid AS DownID, 0,0'  
select @strsql = @strsql+' FROM Machineinformation CROSS JOIN downcodeinformation LEFT OUTER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '  
select @strsql = @strsql+' Where MachineInformation.interfaceid > ''0'' '  
select @strsql = @strsql + @strPlantID +@strmachine + @StrTPMMachines + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'  
exec (@strsql)  
--********************************************* Get Down Time Details *******************************************************  
--Type 1,2,3 and 4.  
select @strsql = ''  
select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) '  
select @strsql = @strsql + ' FROM'  
select @strsql = @strsql + ' (SELECT mc,--count(mc)as dwnfrq,  
SUM(CASE  
WHEN (autodata.sttime>='''+convert(varchar(20),@starttime)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' ) THEN loadunload  
WHEN (autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime)+''') THEN DateDiff(second, '''+convert(varchar(20),@StartTime)+''', ndtime)  
WHEN (autodata.sttime>='''+convert(varchar(20),@starttime)+'''and autodata.sttime<'''+convert(varchar(20),@endtime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''') THEN DateDiff(second, stTime, '''+convert(varchar(20),@Endtime)+''')  
ELSE DateDiff(second,'''+convert(varchar(20),@starttime)+''','''+convert(varchar(20),@endtime)+''')  
END) as down  
,downcodeinformation.downid as downid'  
select @strsql = @strsql + ' from'  
select @strsql = @strsql + ' #T_autodata autodata INNER JOIN' --ER0374  
select @strsql = @strsql + ' machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID INNER JOIN'  
select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'  
select @strsql = @strsql + ' employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN'  
select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'  
select @strsql = @strsql + ' where  datatype=2 AND ((autodata.sttime>='''+convert(varchar(20),@starttime)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' )OR  
(autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime)+''')OR  
(autodata.sttime>='''+convert(varchar(20),@starttime)+'''and autodata.sttime<'''+convert(varchar(20),@endtime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''')OR  
(autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+'''))'  
select @strsql = @strsql  + @strPlantID + @strmachine  
select @strsql = @strsql + ' group by autodata.mc,downcodeinformation.downid )'  
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'  
exec (@strsql)  
--*********************************************************************************************************************  
--mod 4  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN  
 UPDATE #DownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)  
 FROM(  
  --Production PDT  
  SELECT autodata.MC,DownID, SUM  
         (CASE  
   WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END ) as PPDT  
  FROM #T_autodata AutoData --ER0374  
  CROSS jOIN #PlannedDownTimes T  
  Inner Join DownCodeInformation On AutoData.DCode=DownCodeInformation.InterfaceID  
  WHERE autodata.DataType=2 AND T.MachineInterface = AutoData.mc And  
   (  
   (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
   OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
   )  
--   AND  
--   (  
--   (autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)  
--   OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )  
--   OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )  
--   OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)  
--   )  
  group by autodata.mc,DownID  
 ) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId  
 Where #DownTimeData.DownTime>0  
END  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'  
BEGIN  
 UPDATE #DownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)  
 FROM(  
  --Production PDT  
  SELECT autodata.MC,DownId, SUM  
         (CASE  
   WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END ) as PPDT  
  FROM #T_autodata AutoData --ER0374  
  CROSS jOIN #PlannedDownTimes T  
  Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID  
  WHERE autodata.DataType=2 And T.MachineInterface = AutoData.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND  
   (  
   (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
   OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
   )  
--   AND  
--   (  
--   (autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)  
--   OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )  
--   OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )  
--   OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)  
--   )  
  group by autodata.mc,DownId  
 ) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId  
 Where #DownTimeData.DownTime>0  
END  
--mod 4  
--mod 4 commented below queries for Optimization  
/*INSERT INTO #FinalData (MachineID, DownID, DownTime)  
 select MachineID, DownID, DownTime  
 from #DownTimeData*/  
/*INSERT INTO #MAXDownReasonTime (MachineID,MaxReasonTime)  
select A.MachineID,  
SUBSTRING(MAx(A.DownID),1,6)+ '-'+ SUBSTRING(dbo.f_FormatTime(A.DownTime,'hh:mm:ss'),1,5) as MaxDownReasonTime  
FROM #FinalData A  
INNER JOIN (SELECT B.machineid,MAX(B.DownTime)as DownTime FROM #FinalData B group by machineid) as T2  
ON A.MachineId = T2.MachineId and A.DownTime = t2.DownTime  
Where A.DownTime > 0  
group by A.MachineId,A.DownTime  
UPDATE #CockpitData  
SET MaxDownReason = MaxReasonTime  
From #MaxDownReasonTime  
INNER JOIN #CockPitData  
ON #MaxDownReasonTime.MachineID = #CockpitData.MachineID*/  
  
--mod 4 commented till here for Optimization  
---mod 4 Update for MaxDownReasonTime  
Update #CockpitData SET MaxDownReason = MaxDownReasonTime  
From (select A.MachineID as MachineID,  
SUBSTRING(MAx(A.DownID),1,6)+ '-'+ SUBSTRING(dbo.f_FormatTime(A.DownTime,'hh:mm:ss'),1,5) as MaxDownReasonTime  
FROM #DownTimeData A  
INNER JOIN (SELECT B.machineid,MAX(B.DownTime)as DownTime FROM #DownTimeData B group by machineid) as T2  
ON A.MachineId = T2.MachineId and A.DownTime = t2.DownTime  
Where A.DownTime > 0  
group by A.MachineId,A.DownTime)as T3 inner join #CockpitData on T3.MachineID = #CockpitData.MachineID  
---mod 4  
  
--ER0362 From here  
If @companyName = 'VISHWAKARMA'  
Begin  
  
 Update #CockpitData Set Remarks = T1.LastCycle from   
 (  
  Select M.Machineid,convert(varchar,A.ndtime,120) as LastCycle from   
  (  
   Select mc,max(id) as idd from autodata where datatype=1 group by mc  
  )T inner join Autodata  A on A.mc=T.mc and A.id=T.idd inner join Machineinformation M on M.interfaceid=A.mc  
 ) T1 inner join #CockpitData on T1.MachineID = #CockpitData.MachineID   
END  
--ER0362 Till here  
--NR0094 From Here  
ELSE If @companyName <> 'VISHWAKARMA' and @LastComp = 'Display JobCode'  
Begin  

--ER0459 From Here  
-- select @strsql=''  
-- SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,StTime)    
--   select Machineinformation.machineid,C.Componentid,Max(A.StTime) as Sttime from Autodata A    
--   inner join Machineinformation on A.mc=Machineinformation.interfaceid    
--   inner join Componentinformation C on A.comp=C.interfaceid    
--   inner join Componentoperationpricing CO on A.opn=CO.interfaceid    
--   and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid    
--   where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''   '    
-- SELECT @strsql = @strsql + @strmachine    
-- SELECT @strsql = @strsql +'group by Machineinformation.Machineid,C.Componentid Order by Machineinformation.machineid'  
-- print @strsql  
-- exec (@strsql)    
  
	select @strsql=''
	SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,StTime)  
	  select Machineinformation.machineid,C.Componentid,Max(A.StTime) as Sttime from 
	  (
		Select mc,max(sttime) as sttime from #T_autodata 
		where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+''' 
		group by mc
	  ) A  
	  inner join #T_autodata T on T.mc=A.mc and T.sttime=A.sttime
	  inner join Machineinformation on T.mc=Machineinformation.interfaceid  
	  inner join Componentinformation C on T.comp=C.interfaceid  
	  inner join Componentoperationpricing CO on T.opn=CO.interfaceid  
	  and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid '  
	SELECT @strsql = @strsql + @strmachine  
	SELECT @strsql = @strsql +'group by Machineinformation.Machineid,C.Componentid Order by Machineinformation.machineid'
	print @strsql
	exec (@strsql) 
---ER0459 Till Here

 Update #Cockpitdata Set Remarks = Isnull(Remarks,0) + isnull(T.Comp,0) from  
 (select componentid as Comp,isnull(machineid ,'') as machineid from #Runningpart_Part)T inner join #Cockpitdata   
 on #Cockpitdata.machineid=T.machineid   
  
 Update #Cockpitdata Set Remarks = 0 where Isnull(Remarks,'a')='a'  or UtilisedTime = 0  
END  
Else If @companyName <> 'VISHWAKARMA' and @LastComp <> 'Display JobCode'  
BEGIN  
 UPDATE #CockpitData SET Remarks = 'Machine Not In Production' WHERE UtilisedTime = 0  
END  
--NR0094 Till Here  
  
--ER0368 From here  
Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)  
From  
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
inner join Machineinformation M on A.mc=M.interfaceid  
inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid   
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
where A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime and A.flag = 'Rejection'  
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'  
group by A.mc,M.Machineid  
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid   
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from  
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
 inner join Machineinformation M on A.mc=M.interfaceid  
 inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid   
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
 Cross join Planneddowntimes P  
 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid   
 and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and  
 A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime And  
 A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime  
 group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid   
END  
 
---SV
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='N'  
BEGIN  
 Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from  
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
 inner join Machineinformation M on A.mc=M.interfaceid  
 inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid   
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
 Cross join Planneddowntimes P  
 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid  and P.IgnoreCount=1   
 and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and  
 A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime And  
 A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime  
 group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid   
END  
---SV 

Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)  
From  
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
inner join Machineinformation M on A.mc=M.interfaceid  
inner join (select distinct machineid from #Cockpitdata) #Cockpitdata on #Cockpitdata.machineid=M.machineid   
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333  
and S.Machineid=M.machineid
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and  --DR0333  
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
group by A.mc,M.Machineid  
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid   
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from  
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
 inner join Machineinformation M on A.mc=M.interfaceid  
 inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid   
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
 inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333  
 and S.Machineid=M.machineid
 Cross join Planneddowntimes P  
 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and  
 A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and --DR0333  
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
 and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend  
 group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid   
END  

---SV
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='N'  
BEGIN  
 Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from  
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
 inner join Machineinformation M on A.mc=M.interfaceid  
 inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid   
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
 inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333  
 Cross join Planneddowntimes P  
 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and  P.IgnoreCount=1 AND
 A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and --DR0333  
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
 and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend  
 group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid   
END
--SV
  
UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0)   
FROM(Select MachineID,  
CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE  
From #Cockpitdata Where Components<>0 Group By MachineID  
)AS T1 Inner Join #Cockpitdata ON  #Cockpitdata.MachineID=T1.MachineID  
  
--ER0417 added From here  
UPDATE #CockpitData  
SET  
 OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * QualityEfficiency)*100,   
 ProductionEfficiency = ProductionEfficiency * 100 ,  
 AvailabilityEfficiency = AvailabilityEfficiency * 100,  
 QualityEfficiency = QualityEfficiency*100   
--ER0417 added till here  
  
--ER0368 Till here  
  
--ER0385 From Here  
Declare @Type40Threshold int  
Declare @Type1Threshold int  
Declare @Type11Threshold int  
  
Set @Type40Threshold =0  
Set @Type1Threshold = 0  
Set @Type11Threshold = 0  
  
Set @Type40Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')  
Set @Type1Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')  
Set @Type11Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')  
print @Type40Threshold  
print @Type1Threshold  
print @Type11Threshold  
  
 -----------ER0464 --g: using MachineRunningStatus table instead of rawdata From here
--Insert into #machineRunningStatus  
--select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,'White' from rawdata  
--inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime  
--and datatype in(2,42,40,41,1,11) and datepart(year,sttime)>'2000' group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno --For SAF DR0370  
--right outer join #CockpitData fd on fd.MachineInterface = rawdata.mc  
--order by rawdata.mc  


Insert into #machineRunningStatus    
select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,ColorCode from MachineRunningStatus mr    
right outer join #CockpitData fd on fd.MachineInterface = mr.MachineInterface
order by MachineInterface
 ------------ER0464 --g: using MachineRunningStatus table instead of rawdata Till Here
  
update #machineRunningStatus set ColorCode = case when (datediff(second,sttime,@CurrTime)- @Type11Threshold)>0  then 'Red' else 'Green' end where datatype in (11)  
update #machineRunningStatus set ColorCode = 'Green' where datatype in (41)  
update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2)  
  
update #machineRunningStatus set ColorCode = t1.ColorCode from (  
Select mrs.MachineID,Case when (  
case when datatype = 40 then datediff(second,sttime,@CurrTime)- @Type40Threshold  
when datatype = 1 then datediff(second,ndtime,@CurrTime)- @Type1Threshold  
end) > 0 then 'Red' else 'Green' end as ColorCode  
from #machineRunningStatus mrs   
where  datatype in (40,1)  
) as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID  
  
update #machineRunningStatus set ColorCode ='Red' where isnull(sttime,'1900-01-01')='1900-01-01'  
  
update #CockpitData set Remarks1 = T1.MCStatus from   
(select Machineid,  
Case when Colorcode='White' then 'Stopped'  
when Colorcode='Red' then 'Stopped'  
when Colorcode='Green' then 'Running' end as MCStatus from #machineRunningStatus)T1  
inner join #CockpitData on T1.MachineID = #CockpitData.MachineID  
--ER0385 Till Here  
  
--ER0417 Added From here  
If @MarkedForRework='Y'  
BEGIN  
  
 Create table #MarkedForRework  
 (  
  MC nvarchar(50),  
  Machineid nvarchar(50),  
  Slno nvarchar(50),  
  Qty int  
 )  
  
  
  
 Insert into #MarkedForRework(MC,Machineid,Slno,Qty)  
 Select A.mc,#Cockpitdata.machineid,A.WorkOrderNumber,Count(*) from AutodataRejections A  
 inner join Machineinformation M on A.mc=M.interfaceid  
 inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid   
 inner join Reworkinformation R on A.Rejection_code=R.Reworkinterfaceid  
 inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid   
 where A.flag = 'MarkedforRework' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and   
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
 group by A.mc,#Cockpitdata.machineid,A.WorkOrderNumber  
  
 Update #MarkedForRework set Qty = T1.Qty from  
 (Select M.Machineid,M.Slno,'0' as Qty from #MarkedForRework M   
  inner join QualityInspectDetails QD on M.MC=QD.MachineId and M.Slno=QD.WorkOrderNo   
  inner join #shift S on convert(nvarchar(10),(QD.Date),126)=S.shiftdate and QD.Shift=S.shiftname  
 )T1 inner join #MarkedForRework on #MarkedForRework.Machineid=T1. Machineid and #MarkedForRework.Slno=T1.Slno  
  
 Update #Cockpitdata set ReturnPerHour = 0  
  
 Update #Cockpitdata set ReturnPerHour  = isnull(T1.MarkedForReworkQty,0)  
 From  
 ( Select Machineid,Sum(Qty) as MarkedForReworkQty from #MarkedForRework group by Machineid  
 )T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid   
  
END  
--ER0417 Added Till here  
  
  
--ER0362 ADDED FROM HERE  
  
--SELECT  
--MachineID,  
--ProductionEfficiency,  
--AvailabilityEfficiency,  
--OverAllEfficiency,  
--Components,  
--CN,  
--UtilisedTime,  
--TurnOver,  
--dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,  
--dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,  
--dbo.f_FormatTime(DownTime,@timeformat) as DownTime,  
--dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,  
--ReturnPerHour,  
--ReturnPerHourTOTAL,  
--Remarks,  
--PEGreen,  
--PERed,  
--AEGreen,  
--AERed,  
--OEGreen,  
--OERed,  
--@StartTime as StartTime,  
--@EndTime as EndTime,  
--MaxDownReason as MaxReasonTime  
--FROM #CockpitData  
--order by machineid asc  
  
---ER0417 From here  
--If @companyName = 'VISHWAKARMA'  
--Begin  
--  
-- SELECT  
-- MachineID,  
-- ProductionEfficiency,  
-- AvailabilityEfficiency,  
-- QualityEfficiency, --ER0368  
-- OverAllEfficiency,  
-- --Components, --NR0097  
-- Round(Components,2) as Components, --NR0097  
-- RejCount, --ER0368  
-- CN,  
-- UtilisedTime,  
-- TurnOver,  
-- dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,  
-- dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,  
-- dbo.f_FormatTime(DownTime,@timeformat) as DownTime,  
-- dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,  
-- ReturnPerHour,  
-- ReturnPerHourTOTAL,  
-- case when Remarks = 'Machine Not In Production' then ' ' else Remarks end as Remarks,  
-- PEGreen,  
-- PERed,  
-- AEGreen,  
-- AERed,  
-- OEGreen,  
-- OERed,  
-- QERed, --ER0368  
-- QEGreen, --ER0368  
-- @StartTime as StartTime,  
-- @EndTime as EndTime,  
-- MaxDownReason as MaxReasonTime  
-- ,Remarks1,  --ER0368  
-- Remarks2  --ER0368  
-- FROM #CockpitData  
-- order by machineid asc  
--END  
--ELSE  
--Begin  
-- SELECT  
-- MachineID,  
-- ProductionEfficiency,  
-- AvailabilityEfficiency,  
-- QualityEfficiency, --ER0368  
-- OverAllEfficiency,  
-- --Components, --NR0097  
-- Round(Components,2) as Components, --NR0097  
-- RejCount, --ER0368  
-- CN,  
-- UtilisedTime,  
-- TurnOver,  
-- dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,  
-- dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,  
-- dbo.f_FormatTime(DownTime,@timeformat) as DownTime,  
-- dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,  
-- ReturnPerHour,  
-- ReturnPerHourTOTAL,  
-- Remarks,  
-- PEGreen,  
-- PERed,  
-- AEGreen,  
-- AERed,  
-- OEGreen,  
-- OERed,  
-- QERed, --ER0368  
-- QEGreen, --ER0368  
-- @StartTime as StartTime,  
-- @EndTime as EndTime,  
-- MaxDownReason as MaxReasonTime  
-- ,Remarks1,  --ER0368  
-- Remarks2  --ER0368  
-- FROM #CockpitData  
-- order by machineid asc  
--END  
----ER0362 ADDED TILL HERE  
If @companyName = 'VISHWAKARMA' and @MarkedForRework='N'  
Begin  
  
 SELECT  
 MachineID,  
 ProductionEfficiency,  
 AvailabilityEfficiency,  
 QualityEfficiency, --ER0368  
 OverAllEfficiency,  
 --Components, --NR0097  
 Round(Components,2) as Components, --NR0097  
 RejCount, --ER0368  
 CN,  
 UtilisedTime,  
 TurnOver,  
 dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,  
 dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,  
 dbo.f_FormatTime(DownTime,@timeformat) as DownTime,  
 dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,  
 ReturnPerHour,  
 ReturnPerHourTOTAL,  
 case when Remarks = 'Machine Not In Production' then ' ' else Remarks end as Remarks,  
 PEGreen,  
 PERed,  
 AEGreen,  
 AERed,  
 OEGreen,  
 OERed,  
 QERed, --ER0368  
 QEGreen, --ER0368  
 @StartTime as StartTime,  
 @EndTime as EndTime,  
 MaxDownReason as MaxReasonTime  
 ,Remarks1,  --ER0368  
 Remarks2  --ER0368  
 FROM #CockpitData  
 order by machineid asc  
END  
ELSE If @companyName <> 'VISHWAKARMA' and @MarkedForRework='N'  
Begin  
 SELECT  
 MachineID,  
 ProductionEfficiency,  
 AvailabilityEfficiency,  
 QualityEfficiency, --ER0368  
 OverAllEfficiency,  
 --Components, --NR0097  
 Round(Components,2) as Components, --NR0097  
 RejCount, --ER0368  
 CN,  
 UtilisedTime,  
 TurnOver,  
 dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,  
 dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,  
 dbo.f_FormatTime(DownTime,@timeformat) as DownTime,  
 dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,  
 ReturnPerHour,  
 ReturnPerHourTOTAL,  
 Remarks,  
 PEGreen,  
 PERed,  
 AEGreen,  
 AERed,  
 OEGreen,  
 OERed,  
 QERed, --ER0368  
 QEGreen, --ER0368  
 @StartTime as StartTime,  
 @EndTime as EndTime,  
 MaxDownReason as MaxReasonTime  
 ,Remarks1,  --ER0368  
 Remarks2  --ER0368  
 FROM #CockpitData  
 order by machineid asc  
END  
Else If @companyName <> 'VISHWAKARMA' and @MarkedForRework='Y'  
Begin  
 SELECT  
 MachineID,  
 ProductionEfficiency,  
 AvailabilityEfficiency,  
 QualityEfficiency, --ER0368  
 OverAllEfficiency,  
 --Components, --NR0097  
 Round(Components,2) as Components, --NR0097  
 RejCount, --ER0368  
 CN,  
 UtilisedTime,  
 TurnOver,  
 dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,  
 dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,  
 dbo.f_FormatTime(DownTime,@timeformat) as DownTime,  
 dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,  
 ReturnPerHour,  
 ReturnPerHourTOTAL,  
 Remarks,  
 PEGreen,  
 PERed,  
 AEGreen,  
 AERed,  
 OEGreen,  
 OERed,  
 QERed, --ER0368  
 QEGreen, --ER0368  
 @StartTime as StartTime,  
 @EndTime as EndTime,  
 MaxDownReason as MaxReasonTime  
 ,Remarks1,  --ER0368  
 Remarks2  --ER0368  
 FROM #CockpitData  
 order by machineid asc  
END  
--ER0362 ADDED TILL HERE  
--ER0417 Added till here  
  
END  
  
