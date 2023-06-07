/****** Object:  Procedure [dbo].[s_GetEnery_KPIs]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************************************
NR0152:- By Mrudula M. Rao on 16-jan-2009, to get energy level statistics.
used in web based project
**********************************************************************/
CREATE           PROCEDURE [dbo].[s_GetEnery_KPIs]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)
AS
BEGIN
Declare @timeformat as nvarchar(500)
Select @timeformat ='ss'
Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
If (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
	Select @timeformat = 'ss'
End
SELECT @MachineID as MachineID,
dbo.f_FormatTime(sum(datediff(s,E.starttime,E.endtime)),@timeformat) AS UtilisedTime,
sum(E.Energy) as TotalEnergy,
sum(E.UnitCost) as TotalCost,
Count(E.MachineID) as TotCount,
round(sum((case when E.Energy>=C.LThreshold then 1 END)* C.UThreshold)/isnull(sum(case when E.energy>=C.LThreshold then E.energy END),1)* 100,2)  as EnergyEff
FROM CycleEnergyConsumption E
	inner JOIN  COEnergyThreshold C on
	E.componentid=C.componentid and C.OperationNo=E.Operationno
	
WHERE       E.Starttime >= @StartTime
	AND E.Endtime<= @EndTime
	AND E.MachineID = @MachineID
	
END
