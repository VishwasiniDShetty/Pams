/****** Object:  View [dbo].[v_WOData]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE    VIEW [dbo].[v_WOData]
AS
SELECT     TOP 100 PERCENT dbo.autodata.msttime,dbo.autodata.sttime, dbo.autodata.ndtime, dbo.autodata.mc, dbo.autodata.comp, dbo.autodata.opn, dbo.autodata.opr,
dbo.componentinformation.customerid, dbo.componentinformation.componentid, dbo.componentoperationpricing.operationno,
dbo.employeeinformation.Employeeid, dbo.machineinformation.machineid, dbo.machineinformation.mchrrate, dbo.autodata.datatype,
dbo.autodata.post, dbo.autodata.stdate, dbo.autodata.nddate, dbo.autodata.dcode, dbo.autodata.cycletime, dbo.autodata.loadunload, dbo.downcodeinformation.downid
FROM         dbo.employeeinformation INNER JOIN
dbo.componentinformation INNER JOIN
dbo.componentoperationpricing ON dbo.componentinformation.componentid = dbo.componentoperationpricing.componentid INNER JOIN
dbo.machineinformation INNER JOIN
dbo.autodata ON dbo.machineinformation.InterfaceID = dbo.autodata.mc ON dbo.componentoperationpricing.InterfaceID = dbo.autodata.opn AND
dbo.componentinformation.InterfaceID = dbo.autodata.comp ON dbo.employeeinformation.interfaceid = dbo.autodata.opr LEFT JOIN
dbo.downcodeinformation ON dbo.autodata.dcode = dbo.downcodeinformation.interfaceid
ORDER BY dbo.machineinformation.machineid
