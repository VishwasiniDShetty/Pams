/****** Object:  Procedure [dbo].[s_Alert_CycleStartEnd]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[s_Alert_CycleStartEnd]
AS
BEGIN
/*
exec [s_Alert_CycleStartEnd]
SELECT TOP 10 * FROM rawdata WHERE datatype=11 AND mc=30 ORDER BY slno DESC
*/

SELECT RuleID, Parameter, CASE Parameter 
WHEN 'Cycle Start' THEN 11
WHEN 'Cycle Complete' THEN 1
WHEN 'Down' THEN 2
END ID INTO #EnabledRules
FROM Alert_Rules WHERE Enabled=1


/*
SELECT * FROM #EnabledRules
--DROP TABLE #EnabledRules
--DROP TABLE #Result
*/

CREATE TABLE #Result(
 MachineID nvarchar(50),
 ComponentID nvarchar(50),
 RuleID nvarchar(50),
 ComponentCount nvarchar(50),
 DataType int,
 Sttime datetime,
 ndtime datetime
)

INSERT INTO #Result
SELECT tmp.machineid, ci.componentid, tmp.RuleID, rd.SPLSTRING1, tmp.DataType, tmp.sttime, tmp.ndtime FROM
(
SELECT mi.machineid, mi.InterfaceID Mc, er.RuleID, DataType, MAX(Sttime) sttime, MAX(Ndtime) ndtime
FROM RawData rd 
INNER JOIN machineinformation mi ON rd.mc=mi.InterfaceID 
INNER JOIN #EnabledRules er ON er.ID=rd.DataType
WHERE DataType IN (1,11)
GROUP BY mi.machineid, mi.InterfaceID, er.RuleID, DataType
) tmp 
INNER JOIN RawData rd ON rd.mc=tmp.Mc AND rd.Datatype=tmp.Datatype AND rd.sttime=tmp.sttime 
INNER JOIN componentinformation ci ON rd.Comp=ci.InterfaceID

SELECT MachineID, ComponentID, ComponentCount, RuleID, DataType, sttime, ndtime
FROM #Result res
WHERE NOT EXISTS 
(
 SELECT 1 
 FROM Alert_Notification_History anh 
 WHERE anh.MachineID=res.MachineID 
       AND anh.RuleID=res.RuleID 
       AND isnull(anh.AlertStartTS, '1-1-1')=isnull(res.Sttime,'1-1-1') 
)

END
