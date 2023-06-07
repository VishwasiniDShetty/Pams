/****** Object:  Procedure [dbo].[s_GetComponent_Statistics]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************************************
Procedure Created  By Sangeeta Kallur on 21-Dec-2006 :-
To Get Min,Max,Avg and Range of Cutting Time and LoadUnload Time
Procedure Changed By Sangeeta Kallur on 22-FEB-07.To include 'PartsCount'
mod 1 :- for ER0178 by Mrudula on 15-may-2009.We have enabled partscount update facility in modify data. If partcoutn is 0 (if
	record is dummy cycle) there is problem in calculating min, max, avg values. to prevent
	run time errors temporarily consider only those records fo rwhich partcount is >0
ER0210 By Karthikg on 15/Mar/2010 :: Introduce PDT on 5150. Handle PDT at Machine Level.
s_GetComponent_Statistics '9/20/2010 12:41:12 PM','9/21/2010 6:00:00 AM','A77-2','Z209.133 HOUSING E-PAC',14
DR0297 - SwathiKS - 01/Oct/2011 :: To Handle Negative range value in VDG->Statistics window.
DR0301 - SwathiKS - 21/Nov/2011 :: a> To Calculate Loadunload based on MinLUForLR in shopdefaults.
				   b> To Add Alias Name as 'CO' for ComponentOperationpricing in @strsql to handle String length issue.
				   c> To Handle Mismatch of Range value.

s_GetComponent_Statistics '2022-06-01 06:00:00 AM','2022-06-02 06:00:00 AM','WFL M80 Mill Turn','8175-6521-300','10' 
**********************************************************************/
CREATE PROCEDURE [dbo].[s_GetComponent_Statistics]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50),
	@ComponentID nvarchar(50) ,
	@OperationNo nvarchar(50)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

Declare @timeformat as nvarchar(500)
Declare @Param1 As NVarChar(1000)--ER0210
Declare @StrSql As NVarChar(4000)--ER0210
Select @StrSql=''
Select @Param1=''
Select @timeformat ='ss'
Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
If (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
	Select @timeformat = 'ss'
End

--DR0301 From here
Declare @Loadunload as nvarchar(500)
Select @Loadunload = (select TOP 1 ISNULL(ValueInInt,0) From ShopDefaults Where Parameter='MinLUForLR')
--DR0301 Till here

/* Planned Down times for the given time period */
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	SELECT Machine as MachineID,machineinformation.interfaceid as MachineInterface,
	CASE When StartTime<@StartTime Then @StartTime Else StartTime End As StartTime,
	CASE When EndTime>@EndTime Then @EndTime Else EndTime End As EndTime
	INTO #PlannedDownTimes
	FROM PlannedDownTimes inner join machineinformation on machineinformation.Machineid = PlannedDownTimes.machine
	WHERE PDTStatus = 1 and machineid = @MachineID And (
	(StartTime >= @StartTime  AND EndTime <=@EndTime)
	OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
	OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
	OR ( StartTime < @StartTime  AND EndTime > @EndTime) )
	ORDER BY StartTime
	SELECT @Param1=' AND ID Not In (Select ID From AutoData A CROSS JOIN #PlannedDownTimes  Where DataType=1 And A.mc =#PlannedDownTimes.MachineInterface and A.ndtime>StartTime And A.NdTime<=EndTime)'
END
--ER0210
SELECT @StrSql = @StrSql + 'SELECT
dbo.f_FormatTime(CO.machiningtime,''' + @timeformat + ''')  AS StdMachiningTime,
dbo.f_FormatTime(MAX(A.cycletime/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1),''' + @timeformat + ''') AS MaxCycleTime,
dbo.f_FormatTime(MIN(A.cycletime/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1),''' + @timeformat + ''') AS MinCycleTime,
--dbo.f_FormatTime(AVG(A.cycletime/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1),''' + @timeformat + ''') AS AvgCycleTime,
dbo.f_FormatTime((Sum(A.cycletime)/Sum(ISNULL(A.PartsCount,1)))* ISNULL(CO.SubOperations,1),''' + @timeformat + ''') AS AvgCycleTime,

--DR0297 From Here.
--dbo.f_FormatTime((MAX(A.cycletime/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1))-(MIN(A.cycletime)* ISNULL(CO.SubOperations,1)),''' + @timeformat + ''') AS RangeCycleTime,
dbo.f_FormatTime((MAX(A.cycletime/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1))-MIN(A.cycletime/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1),''' + @timeformat + ''') AS RangeCycleTime,
--DR0297 Till Here.
dbo.f_FormatTime((CO.cycletime - CO.machiningtime),''' + @timeformat + ''') AS StdLoadUnload,


/* DR0301 Commented From Here
dbo.f_FormatTime(MAX(A.loadunload/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1),''' + @timeformat + ''') AS MaxLoadUnload,
dbo.f_FormatTime(MIN(A.loadunload/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1),''' + @timeformat + ''') AS MinLoadUnload,
dbo.f_FormatTime(AVG(A.loadunload/ISNULL(A.PartsCount,1)) * ISNULL(CO.SubOperations,1),''' + @timeformat + ''' ) AS AvgLoadUnload,

dbo.f_FormatTime((MAX(A.loadunload/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1))-(MIN(A.loadunload)* ISNULL(CO.SubOperations,1)),''' + @timeformat + ''' ) AS RangeLoadUnload
DR0301 Commented Till Here */

--DR0301 From Here
dbo.f_FormatTime(MAX(case when A.loadunload >= ''' + @Loadunload + ''' then A.loadunload else 0 end /ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1),''' + @timeformat + ''') AS MaxLoadUnload,
dbo.f_FormatTime(MIN(case when A.loadunload >= ''' + @Loadunload + ''' then A.loadunload else 0 end/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1),''' + @timeformat + ''') AS MinLoadUnload,
--dbo.f_FormatTime(AVG(case when A.loadunload >= ''' + @Loadunload + ''' then A.loadunload else 0 end/ISNULL(A.PartsCount,1)) * ISNULL(CO.SubOperations,1),''' + @timeformat + ''' ) AS AvgLoadUnload,
dbo.f_FormatTime((case when Sum(A.loadunload) >= ''' + @Loadunload + ''' then Sum(A.loadunload) else 0 end/Sum(ISNULL(A.PartsCount,1))) * ISNULL(CO.SubOperations,1),''' + @timeformat + ''' ) AS AvgLoadUnload,
dbo.f_FormatTime((MAX(case when A.loadunload >= ''' + @Loadunload + ''' then A.loadunload else 0 end/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1))-(MIN(case when A.loadunload >= ''' + @Loadunload + ''' then A.loadunload else 0 end/ISNULL(A.PartsCount,1))* ISNULL(CO.SubOperations,1)),''' + @timeformat + ''' ) AS RangeLoadUnload
--DR0301 Till Here

FROM Autodata A
	INNER JOIN  machineinformation ON A.mc = machineinformation.InterfaceID
	INNER JOIN  componentinformation ON A.comp = componentinformation.InterfaceID
	INNER JOIN componentoperationpricing CO ON (A.opn = CO.InterfaceID)
		AND (componentinformation.componentid = CO.componentid)
AND (CO.Machineid = machineinformation.Machineid) --DR0301 Added
WHERE       A.ndtime > ''' + convert(nvarchar(20),@StartTime,120)+'''
	AND A.ndtime <= ''' + convert(nvarchar(20),@EndTime,120)+'''
	AND A.datatype = 1
	AND Machineinformation.MachineID =  ''' +@MachineID+ '''
	AND CO.ComponentID = ''' +@ComponentID+ '''
	AND CO.OperationNo = ''' +@OperationNo+ '''
	---mod 2
	AND A.partscount>0
	--mod 2
	--ER0210
	' + @Param1 + '
	--ER0210
GROUP BY componentinformation.componentid,
	 CO.operationno,
	 CO.cycletime,
	 CO.machiningtime,
	 CO.SubOperations'
--ER0210
print @strsql
Exec(@StrSql)
END
