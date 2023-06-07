/****** Object:  Procedure [dbo].[s_GetBoschAndonVisibleMachines]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0423 - Vasavi - 1/Jan/2016 :: To Display Images based on machine Selection.
--[dbo].[s_GetBoschAndonVisibleMachines]'LINE-1','','','','View'
CREATE PROCEDURE [dbo].[s_GetBoschAndonVisibleMachines]
	@plant nvarchar(50)='',
	@description nvarchar(50)='',
	@report nvarchar(100)='',
	@flag bit='',
	@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	create table #Cockpittotal
	(
	plantID nvarchar(50),
	[Description] nvarchar(50),
	Report nvarchar(100),
	Flag bit
	)
	if @param='View'
	BEGIN

	Insert into #Cockpittotal
	SELECT P.Plantid,'ACE FT','ShiftProduction',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('%FT%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'ACE FT','OEELoss',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('%FT%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'ACE ST','ShiftProduction',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('%ST%')
	group by P.Plantid


	Insert into #Cockpittotal
	SELECT P.Plantid,'ACE ST','OEELoss',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('%ST%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'AMS A','ShiftProduction',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('A%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'AMS A','OEELoss',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('A%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'AMS B','ShiftProduction',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('%B%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'AMS B','OEELoss',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('%B%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM DIA 6','ShiftProduction',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('KM DIA 6')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM DIA 6','OEELoss',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('KM DIA 6')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM DIA 1.43','ShiftProduction',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('KM DIA 1.43')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM DIA 1.43','OEELoss',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('KM DIA 1.43')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM DIA 2.2','ShiftProduction',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('KM DIA 2.2')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM DIA 2.2','OEELoss',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('KM DIA 2.2')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM A/F MILLING','ShiftProduction',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('KM A/F MILLING')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM A/F MILLING','OEELoss',0 FROM Machineinformation C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.[Description] like ('KM A/F MILLING')
	group by P.Plantid

	update #Cockpittotal set flag=T.flag from 
	(select plantid,machineid,Report,flag from [Bosch_AccessRights])T inner join #Cockpittotal on 
	T.plantid=#Cockpittotal.plantid and T.MachineID=#Cockpittotal.Description and T.Report=#Cockpittotal.Report

	select [Description] as MachineID,Report,Flag from #Cockpittotal where plantID=@plant order by Plantid,Report,[Description]
  END

  if @param='delete'
  BEGIN
  delete from [Bosch_AccessRights] where plantid=@plant;
  END

  if @param='Save'
  BEGIN
  insert into [Bosch_AccessRights]( plantid,machineid,Report,flag)
  select @plant,@description,@report,@flag
  END

  if @param='ViewSelection'
  BEGIN

  select MachineID+'_'+Report as MachineID  from    [Bosch_AccessRights] where plantid=@plant order by Plantid,MachineID

  END


END
