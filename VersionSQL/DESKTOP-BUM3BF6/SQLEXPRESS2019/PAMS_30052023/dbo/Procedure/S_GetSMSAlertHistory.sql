/****** Object:  Procedure [dbo].[S_GetSMSAlertHistory]    Committed by VersionSQL https://www.versionsql.com ******/

/*******************************************************
ER0262 - Swathi KS/SyedArifM - 12-Oct-2010 :: New excel Report For SMS Alert History Under SmartAgent.
					      Smartconsole ->Admin -> Export -> ExportData -> Type-SMS Alert History

--S_GetSMSAlertHistory '2010-10-02','2010-10-14','''MBC BEHRINGER'',''A55'''
--S_GetSMSAlertHistory '2010-10-02','2010-10-14','''MBC BEHRINGER'''
*******************************************************/

CREATE  PROCEDURE [dbo].[S_GetSMSAlertHistory]
   	@StartDate datetime,
	@EndDate Datetime,
	@MachineID nvarchar(500)
	
AS
BEGIN
Declare @strsql nvarchar(4000)
		

	SET NOCOUNT ON;
	
	
		Select @strsql='SELECT M.MachineID AS [MachineID],M.MobileNo as [MobileNo],
		M.Starttime AS [Starttime],M.Endtime as [Endtime],
		M.RequestedTime AS [RequestedTime],M.SendTime AS [SendTime],
		M.Message AS [Message] from messagehistory M
		left OUTER Join PlantMachine P on M.machineid = P.machineid
		where M.Starttime  >= '''+convert(nvarchar(25),@StartDate,120)+''' and M.Endtime <=  '''+convert(nvarchar(25),@EndDate,120)+'''  and
		M.machineID in ('+@MachineID+') and M.MsgStatus = 1 order by M.MachineID,M.SendTime'
		print(@strsql)
		Exec(@strsql)



END
