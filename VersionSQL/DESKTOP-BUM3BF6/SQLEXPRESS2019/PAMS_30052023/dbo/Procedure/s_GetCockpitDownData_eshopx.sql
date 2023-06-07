/****** Object:  Procedure [dbo].[s_GetCockpitDownData_eshopx]    Committed by VersionSQL https://www.versionsql.com ******/

/*************************************************************************************  
Created By sangeeta Kallur on 23-Mar-06  
Changed existing s_GetCockpitDownData  
To account type-1 ,type-2,type-3 and type-4 records And to get Threshold,MLE  
Procedure changed by SSK : 22-Nov-07 : DR0079  
mod 1 :- ER0210 By KarthikG Introduce PDT on 5150. Handle PDT at Machine Level.  
s_GetCockpitDownData '2010-08-01','2011-08-21','MBC PUMA 400XL'  
drop table #TempCockpitDownData  
To handle error  
DR0253 - KarthikR - 28/Aug/2010 :: The view data graph down tab after implementing PDT-  
       the row number and the bar graph are not matching.  
DR0273- SwathiKS - 12/Mar/2011 :: To Handle Error String or binary Data would be Truncated.  
ER0295 - SwathiKS - 02/Jul/2011 :: To Apply PDT For Loadunload.  
DR0292 - SwathiKS - 26/Aug/2011 :: To Avoid Negative Downtime in SmartCockpit->VDG.  
ER0370 - SwathiKS - 25/Nov/2013 :: To Show Current Cycle ICD Records Based on Setting in Cockpitdefaults Table,   
If Setting = "Y" then Calling  Procedure [dbo].[s_GetCurrentCycleICDRecords].  
NR0097 - SwathiKS - 17/dec/2013 :: Ace - While Accounting DownThreshold, To apply Threshold from Componentoperationprcing table for the Downs with   
"PickFomCO = 1" else apply threshold from Downcodeinformation table eith "Availeffy=1" and "PickFomCO <> 1" .  
ER0402 - SwathiKS - 01/Jan/2015 :: To Show Operators which does not have Master entry in Down Grid.  
ER0450 - SwathiKS - 04/Jul/2017 :: To introduce Mode (Robo/Manual) in VDG for kennametal.(.net cockpit)    
  
exec s_GetCockpitDownData_eshopx '2022-07-01 06:00:00','2022-07-30 14:00:00','SLT-08 LM205'  
***************************************************************************************/  
CREATE                  PROCEDURE [dbo].[s_GetCockpitDownData_eshopx]  
 @StartTime datetime,  
 @EndTime datetime,  
 @MachineID nvarchar(50)  
AS  
BEGIN  
---DR0253 - KarthikR - 28/Aug/2010 from here  
create table #TempCockpitDownData  
(  
 SerialNO bigint IDENTITY (1, 1) NOT NULL,  
 StartTime datetime,  
 EndTime datetime,  
 OperatorID nvarchar(50),  
 --OperatorName nvarchar(50), --DR0270  
 OperatorName nvarchar(150),  
 WorkOrderNumber nvarchar(50),
 DownID nvarchar(50),  
 --DownDescription nvarchar(50),--DR0270  
 DownDescription nvarchar(100),  
 --DownThreshold numeric(9) , --DR0270  
 DownThreshold numeric(18) ,  
 DownTime nvarchar(50) ,  
 --Remarks nvarchar(50), --DR0270  
 Remarks nvarchar(255),  
 [id] bigint,  
 PDT int, --ER0295  
 Mode int --ER0450  
  
)  
---DR0253 - KarthikR - 28/Aug/2010 Till here  
SELECT  
--DR0292 Changes From Here.  
--autodata.sttime,  
--autodata.ndtime,  
case when autodata.sttime<@starttime then @starttime else autodata.sttime end AS StartTime,  
case when autodata.ndtime>@endtime then @endtime else autodata.ndtime end AS EndTime,  
--DR0292 Changes Till Here.  
--ER0402 Changes From here  
--employeeinformation.Employeeid AS OperatorID,  
--employeeinformation.[Name]  AS OperatorName,  
Isnull(employeeinformation.Employeeid,autodata.opr) AS OperatorID,  
Isnull(employeeinformation.[Name],'---')  AS OperatorName,  
--ER0402 Changes Till here  
downcodeinformation.downid AS DownID,  
downcodeinformation.downdescription as [DownDescription],  
CASE  
--WHEN downcodeinformation.AvailEffy=1 and downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold --NR0097  
WHEN downcodeinformation.AvailEffy=1 AND downcodeinformation.ThresholdfromCO <>1 AND downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold --NR0097  
ELSE 0 END AS [DownThreshold],  
case  
When (autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime ) THEN loadunload  
WHEN ( autodata.sttime < @StartTime AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime ) THEN DateDiff(second, @StartTime, ndtime)  
WHEN ( autodata.sttime >= @StartTime AND autodata.sttime < @EndTime AND autodata.ndtime > @EndTime ) THEN  DateDiff(second, stTime, @EndTime)  
ELSE  
DateDiff(second, @StartTime, @EndTime)END AS DownTime,  
autodata.Remarks,  
autodata.id,  
0 as PDT --ER0295  
,0 as Mode,
WorkOrderNumber--ER0450    
INTO #Temp  
FROM         autodata INNER JOIN  
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
--INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402  
LEFT OUTER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402  
WHERE machineinformation.machineid = @MachineID AND autodata.datatype = 2 AND  
(  
(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)  
OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )  
OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )  
OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)  
)  
ORDER BY autodata.ndtime  
  
--------------------------- NR0097 Added From Here ----------------------------------  
update #Temp set [DownThreshold] = isnull([DownThreshold],0) + isnull(T1.DThreshold,0)  from  
(Select autodata.id,isnull(CO.Stdsetuptime,0)AS DThreshold from autodata  
inner join machineinformation M on autodata.mc = M.interfaceid  
inner join downcodeinformation D on autodata.dcode=D.interfaceid  
--INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402  
left outer join  employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402  
left outer join componentinformation CI on autodata.comp = CI.interfaceid  
left outer join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid  
where M.machineid = @MachineID and autodata.datatype=2 and D.ThresholdfromCO = 1  
And  
((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or  
 (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or  
 (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or  
 (autodata.sttime<@starttime and autodata.ndtime>@endtime))  
)T1 inner join #Temp on T1.id=#Temp.id  
-------------------------- NR0097 Added Till Here --------------------------------------  
  
/************************* ER0295 Commented From Here.**************************  
--mod 1  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN  
  Insert Into #Temp  
  (StartTime,EndTime,OperatorID,OperatorName,DownID,DownDescription,DownTime,id)  
  SELECT  
  StartTime,EndTime,'--','--',DownReason,DownReason,  
  CASE  
  WHEN (StartTime >= @StartTime AND EndTime <=@EndTime) THEN  DateDiff(second,StartTime,EndTime)  
  WHEN (StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime ) THEN DateDiff(second,@StartTime,EndTime)  
  WHEN (StartTime >= @StartTime AND StartTime <@EndTime AND EndTime > @EndTime ) THEN DateDiff(second,@StartTime,@EndTime)  
  ELSE  DateDiff(second,@StartTime,@EndTime) END,0  
  From PlannedDownTimes Where PDTstatus = 1 and machine = @MachineID and  
   ((StartTime >= @StartTime  AND EndTime <=@EndTime)  
   OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )  
   OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )  
   OR ( StartTime < @StartTime  AND EndTime > @EndTime))  
END  
--mod 1  
********************** ER0295 Commented Till Here. *********************/  
--ER0295 Modified From here  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'  
BEGIN  
update #Temp set DownTime = isnull(Downtime,0)-isnull(TT.plannedDT,0), PDT=isnull(TT.plannedDT,0)  
 from  
(  
 Select A.StartTime,A.EndTime,     
   sum(case  
   WHEN A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime  THEN A.DownTime  
   WHEN ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime  AND A.EndTime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.EndTime)  
   WHEN ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime  AND A.EndTime > T.EndTime  ) THEN DateDiff(second,A.StartTime,T.EndTime )  
   WHEN ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END) as plannedDT  
 From #Temp A CROSS jOIN PlannedDownTimes T  
   WHERE  T.machine=@machineid  and pdtstatus=1 and --datatype=2 and  
   ((A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime)  
   OR ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime AND A.EndTime > T.StartTime )  
   OR ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime AND A.EndTime > T.EndTime )  
   OR ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime))  
   group by A.StartTime,A.EndTime  
)TT  
INNER JOIN #Temp ON TT.StartTime=#Temp.StartTime and #Temp.EndTime=TT.EndTime  
END  
--ER0295 Modified Till Here.  
--DR0079 : Starts here  
---DR0253 - KarthikR - 28/Aug/2010 from here  
/*  
SELECT  
IDENTITY(int, 1, 1) AS SerialNo,*  
INTO #TempCockpitDownData  
FROM #Temp  
*/  
SET IDENTITY_INSERT #TempCockpitDownData Off  
insert into #TempCockpitDownData  
(  
 StartTime,  
 EndTime,  
 OperatorID,  
 OperatorName,  
 DownID,  
 DownDescription,  
 DownThreshold,  
 DownTime,  
 Remarks,  
 [id],  
 PDT, --ER0295  
 Mode,
 WorkOrderNumber--ER0450  
) Select * from #temp order by starttime,endtime  
---DR0253 - KarthikR - 28/Aug/2010 Till here  
--DR0079 : Ends here  
  
  
---ER0450 Added From Here  
Create Table #Mode  
(  
Machineid nvarchar(50),  
MachineInterface nvarchar(50),  
StartID bigint,  
EndID bigint,  
starttime datetime,  
endtime datetime,  
--Mode nvarchar(20)  
Mode int ,
WorkOrderNumber nvarchar(50)
)  
  
Insert into #Mode(Machineid,MachineInterface,StartID,EndID,starttime,endtime,Mode)   
--select @Machineid,A1.machine,A1.id,min(A2.id),A1.Starttime,min(A2.Starttime),  
--case when A1.DetailNumber=1 then 'Robo'  
--when A1.DetailNumber=2 then 'Manual' end from Autodatadetails A1,Autodatadetails A2  
--where A1.id<A2.id and A1.Starttime>=@Starttime and A1.Starttime<=@Endtime  
--and A2.Starttime>=@Starttime and A2.Starttime<=@Endtime and A1.Machine=A2.Machine and A1.Recordtype=A2.Recordtype  
--and A1.Machine=(select interfaceid from Machineinformation where machineid=@machineid) and A1.Recordtype='55'  
--group by A1.machine,A1.id,A1.Starttime,A1.DetailNumber  
select @Machineid,A1.machine,A1.id,min(A2.id),A1.Starttime,min(A2.Starttime),  
A1.DetailNumber from Autodatadetails A1,Autodatadetails A2  
where A1.id<A2.id and A1.Starttime>=@Starttime and A1.Starttime<=@Endtime  
and A2.Starttime>=@Starttime and A2.Starttime<=@Endtime and A1.Machine=A2.Machine and A1.Recordtype=A2.Recordtype  
and A1.Machine=(select interfaceid from Machineinformation where machineid=@machineid) and A1.Recordtype='55'  
group by A1.machine,A1.id,A1.Starttime,A1.DetailNumber  
--ER0450 Added Till Here  
  
Insert into #Mode(Machineid,MachineInterface,StartID,EndID,starttime,endtime,Mode)   
Select Machineid,MachineInterface,EndID,EndID,Max(endtime),@Endtime,Mode from #Mode  
 group by Machineid,MachineInterface,EndID,Mode  
Having(Max(endtime))<@Endtime  
  
  
--ER0370 From Here  
Declare @ICDSetting as nvarchar(50)  
Select @ICDSetting = isnull(Valueintext,'N') From CockpitDefaults Where Parameter ='Current_Cycle_ICD_Records'  
IF @ICDSetting = 'Y'  
BEGIN  
  
IF EXISTS(SELECT * FROM Company where CompanyName Like 'kennametal%')      
Begin    
insert into #TempCockpitDownData  
(  
 StartTime,  
 EndTime,  
 OperatorID,  
 OperatorName,  
 DownID,  
 DownDescription,  
 DownThreshold,  
 DownTime,  
 Remarks,  
 [id],  
 PDT, --ER0295  
 Mode,
 WorkOrderNumber--ER0450  
) exec [dbo].[s_GetCurrentCycleICDRecords_eshopx] @starttime,@Endtime,@Machineid  
END  
Else  
Begin  
insert into #TempCockpitDownData  
(  
 StartTime,  
 EndTime,  
 OperatorID,  
 OperatorName,  
 DownID,  
 DownDescription,  
 DownThreshold,  
 DownTime,  
 Remarks,  
 [id],  
 PDT,
 WorkOrderNumber--ER0295  
) exec [dbo].[s_GetCurrentCycleICDRecords_eshopx] @starttime,@Endtime,@Machineid  
End  
END  
--ER0370 Till Here  
  
---ER0450 Added From Here  
update #TempCockpitDownData SET Mode=ISNULL(Mode,0)+ISNULL(T2.MachineMode,0) From  
(select T.StartTime,T.EndTime,A.Mode as MachineMode,Max(A.Starttime) as ModeStart from #Mode A  
cross join #TempCockpitDownData T   
where T.Endtime>A.starttime and T.endtime<=A.endtime  
Group by T.StartTime,T.EndTime,A.Mode)T2 INNER JOIN #TempCockpitDownData ON   
t2.StartTime=#TempCockpitDownData.StartTime and #TempCockpitDownData.EndTime=T2.EndTime  
---ER0450 Added Till Here  
  
  
  
declare @TimeFormat as nvarchar(50)  
SELECT @TimeFormat = ''  
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')  
if (ISNULL(@TimeFormat,'')) = ''  
SELECT @TimeFormat = 'ss'  
  
  
SELECT SerialNO,  
StartTime,  
EndTime,  
OperatorID,  
OperatorName, 
WorkOrderNumber,
#TempCockpitDownData.DownID, 
D.Catagory,
#TempCockpitDownData.DownDescription,  
dbo.f_FormatTime(DownTime, @TimeFormat  ) as DownTime ,  
dbo.f_FormatTime(DownThreshold,@TimeFormat) AS DownThreshold,  
CASE  
WHEN (DownTime > DownThreshold AND DownThreshold > 0) THEN dbo.f_FormatTime(abs(DownTime-DownThreshold),@TimeFormat)  
ELSE '0' END AS MLE,  
Remarks,id,DownTime as SortDownTime ,  
dbo.f_FormatTime(PDT, @TimeFormat  ) as PDT 
 --ER0295  
,convert(decimal (18, 2),dbo.f_FormatTime(DownTime,'ss')) as DownTimeForGraph  
,convert(decimal (18, 2),dbo.f_FormatTime(DownThreshold,'ss')) AS DownThresholdForGraph  
,CONVERT(decimal (18, 2),dbo.f_FormatTime(PDT ,'ss')) AS PDTForGraph  
, CASE convert(nvarchar(50), Mode)   
  WHEN 1 THEN 'Robot'   
  WHEN 2 THEN 'Manual'   
  ELSE ''   
END as Mode --ER0450  
,(case when D.Catagory like '%SETUP%' Then 1 Else 0 End) as SetupChange
From #TempCockpitDownData  
left join downcodeinformation D on #TempCockpitDownData.DownID=D.downid
order by StartTime  
  
END  
  
