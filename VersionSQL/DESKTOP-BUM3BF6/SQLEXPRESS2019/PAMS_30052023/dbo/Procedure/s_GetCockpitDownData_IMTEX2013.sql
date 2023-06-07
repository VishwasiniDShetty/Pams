/****** Object:  Procedure [dbo].[s_GetCockpitDownData_IMTEX2013]    Committed by VersionSQL https://www.versionsql.com ******/

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
s_GetCockpitDownData_IMTEX2013 '2012-09-02 06:05:00' , '2012-09-03 06:05:00','MCV 400'
***************************************************************************************/
CREATE                PROCEDURE [dbo].[s_GetCockpitDownData_IMTEX2013]
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
	DownID nvarchar(50),
	--DownDescription nvarchar(50),--DR0270
	DownDescription nvarchar(100),
	--DownThreshold numeric(9) , --DR0270
	DownThreshold numeric(18) ,
	DownTime nvarchar(50) ,
	--Remarks nvarchar(50), --DR0270
	Remarks nvarchar(255),
	[id] bigint,
	PDT int --ER0295
)
---DR0253 - KarthikR - 28/Aug/2010 Till here

--For Imtex
create table #FinalOutput
(
	StartTime datetime,
	EndTime datetime,
	DownID nvarchar(50),
	DownDescription nvarchar(100),
	DownTime nvarchar(50)
)


SELECT

--DR0292 Changes From Here.
--autodata.sttime,
--autodata.ndtime,
case when autodata.sttime<@starttime then @starttime else autodata.sttime end AS StartTime,
case when autodata.ndtime>@endtime then @endtime else autodata.ndtime end AS EndTime,
--DR0292 Changes Till Here.

employeeinformation.Employeeid AS OperatorID,
employeeinformation.[Name]  AS OperatorName,
downcodeinformation.downid AS DownID,
downcodeinformation.downdescription as [DownDescription],
CASE
WHEN downcodeinformation.AvailEffy=1 and downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold
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
INTO #Temp
FROM         autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid INNER JOIN
employeeinformation ON autodata.opr = employeeinformation.interfaceid
WHERE machineinformation.machineid = @MachineID AND autodata.datatype = 2 AND
(
(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
)
ORDER BY autodata.ndtime

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
	PDT --ER0295
) Select * from #temp order by starttime,endtime

---DR0253 - KarthikR - 28/Aug/2010 Till here
--Select * from #Temp
--DR0079 : Ends here
declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if (ISNULL(@TimeFormat,'')) = ''
SELECT @TimeFormat = 'ss'


insert into #FinalOutput
SELECT 
StartTime,
EndTime,
DownID,
DownDescription,
dbo.f_FormatTime(DownTime,'hh:mm:ss') as Downtime
From #TempCockpitDownData
order by starttime desc

select StartTime,EndTime,Downid,
case when right('00'+ convert(nvarchar,datepart(hour,DownTime)),2)= '00' 
	      then  right('00' + convert(nvarchar(2),datepart(minute,DownTime)),2) + ' min ' 
	when right('00' + convert(nvarchar(2),datepart(minute,DownTime)),2) = '00'
		 then right('00'+ convert(nvarchar,datepart(hour,DownTime)),2) + ' hr '
	else
	right('00'+ convert(nvarchar,datepart(hour,DownTime)),2) + ' hr ' +  right('00' + convert(nvarchar(2),datepart(minute,DownTime)),2) + ' min '
end as downtime
from #FinalOutput

END
