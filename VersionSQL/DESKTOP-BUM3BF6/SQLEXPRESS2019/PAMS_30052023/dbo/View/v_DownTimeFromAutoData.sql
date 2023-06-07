/****** Object:  View [dbo].[v_DownTimeFromAutoData]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   VIEW [dbo].[v_DownTimeFromAutoData]
AS
SELECT     TOP 100 PERCENT dbo.autodata.sttime, dbo.autodata.ndtime, dbo.autodata.mc, dbo.autodata.comp, dbo.autodata.opn, dbo.autodata.opr, 
                      dbo.componentinformation.customerid, dbo.componentinformation.componentid, dbo.componentoperationpricing.operationno, 
                      dbo.employeeinformation.Employeeid AS eid, dbo.downcodeinformation.downid AS did, dbo.machineinformation.machineid, 
                      dbo.machineinformation.mchrrate AS mcrate,dbo.autodata.datatype, dbo.autodata.post
FROM         dbo.downcodeinformation INNER JOIN
                      dbo.employeeinformation INNER JOIN
                      dbo.componentinformation INNER JOIN
                      dbo.componentoperationpricing ON dbo.componentinformation.componentid = dbo.componentoperationpricing.componentid INNER JOIN
                      dbo.machineinformation INNER JOIN
                      dbo.autodata ON dbo.machineinformation.InterfaceID = dbo.autodata.mc ON dbo.componentoperationpricing.InterfaceID = dbo.autodata.opn AND 
                      dbo.componentinformation.InterfaceID = dbo.autodata.comp ON dbo.employeeinformation.interfaceid = dbo.autodata.opr ON 
                      dbo.downcodeinformation.interfaceid = dbo.autodata.dcode
WHERE     (dbo.autodata.datatype = 2) AND (dbo.autodata.post = 0)
ORDER BY dbo.machineinformation.machineid
