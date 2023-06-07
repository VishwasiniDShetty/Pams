/****** Object:  View [dbo].[ShiftAggMoneyLoss]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE VIEW [dbo].[ShiftAggMoneyLoss]
AS
SELECT     dbo.ShiftDownTimeDetails.dDate, dbo.ShiftDownTimeDetails.Shift, dbo.ShiftDownTimeDetails.PlantID, dbo.ShiftDownTimeDetails.MachineID, 
                      CONVERT(float, dbo.ShiftDownTimeDetails.DownTime) / 3600 * dbo.machineinformation.mchrrate AS MoneyLost, dbo.machineinformation.mchrrate, 
                      dbo.ShiftDownTimeDetails.DownTime
FROM         dbo.ShiftDownTimeDetails INNER JOIN
                      dbo.machineinformation ON dbo.ShiftDownTimeDetails.MachineID = dbo.machineinformation.machineid
