/****** Object:  Procedure [dbo].[s_GetFocasWearOffsetDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetFocasWearOffsetDetails] '2013-09-07','Win Chennai - SCP','ACE-02','WearOffsetZ'
CREATE procedure [dbo].[s_GetFocasWearOffsetDetails]
 @Starttime datetime,
 @PlantID nvarchar(50),
 @Machine nvarchar(50),
 @Param nvarchar(20)
AS
BEGIN

Create Table #WearOffsetDetails
(
	[Sl No] Bigint Identity(1,1) Not Null,
	[Prog No] int,
	[Tool No] int,
	[Offset No] int,
	[OffsetValueX] float,
	[OffsetValueZ] float,
	[TimeStamp] datetime
)

If @param = 'WearOffsetX'
BEGIN


	Insert into #WearOffsetDetails([Prog No],[Tool No],[OffsetValueX],[TimeStamp])
	select T2.Programnumber,T2.Toolno,T2.WearOffsetX,T2.machinetimestamp from
	(
	select T1.Programnumber,T1.Toolno,T1.WearOffsetX,min(F.machinetimestamp) as machinetimestamp from
	(
	select Distinct Machineid,Programnumber,Toolno,WearOffsetX from
	dbo.Focas_ToolOffsetHistory where machineid=@Machine and 
	machinetimestamp>=dbo.f_GetLogicalDay(@Starttime,'start') and machinetimestamp<=dbo.f_GetLogicalDay(@Starttime,'End')
	and WearOffsetX<>0 
	) AS T1 inner join Focas_ToolOffsetHistory F on T1.machineid=F.machineid and T1.Programnumber=F.Programnumber and T1.ToolNo=F.ToolNo and T1.WearOffsetX=F.WearOffsetX
	and F.machinetimestamp>=dbo.f_GetLogicalDay(@Starttime,'start') and F.machinetimestamp<=dbo.f_GetLogicalDay(@Starttime,'End')
	group by T1.Programnumber,T1.Toolno,T1.WearOffsetX 
	)T2 Order by T2.machinetimestamp

	Select [Sl No],[Prog No],[Tool No],Round([OffsetValueX],4) as [OffsetValueX],[TimeStamp] From #WearOffsetDetails
	Order by [TimeStamp]
END


If @param = 'WearOffsetZ'
BEGIN
	Insert into #WearOffsetDetails([Prog No],[Tool No],[OffsetValueZ],[TimeStamp])
	select T2.Programnumber,T2.Toolno,T2.WearOffsetZ,T2.machinetimestamp from
	(
	select T1.Programnumber,T1.Toolno,T1.WearOffsetZ,min(F.machinetimestamp) as machinetimestamp from
	(
	select Distinct Machineid,Programnumber,Toolno,WearOffsetZ from
	dbo.Focas_ToolOffsetHistory where machineid=@Machine and 
	machinetimestamp>=dbo.f_GetLogicalDay(@Starttime,'start') and machinetimestamp<=dbo.f_GetLogicalDay(@Starttime,'End')
	and WearOffsetZ<>0  
	) AS T1 inner join Focas_ToolOffsetHistory F on T1.machineid=F.machineid and T1.Programnumber=F.Programnumber and T1.ToolNo=F.ToolNo and T1.WearOffsetZ=F.WearOffsetZ
	and F.machinetimestamp>=dbo.f_GetLogicalDay(@Starttime,'start') and F.machinetimestamp<=dbo.f_GetLogicalDay(@Starttime,'End')
	group by T1.Programnumber,T1.Toolno,T1.WearOffsetZ 
	)T2 Order by T2.machinetimestamp

	Select [Sl No],[Prog No],[Tool No],Round([OffsetValueZ],4) as [OffsetValueZ],[TimeStamp] From #WearOffsetDetails
	Order by [TimeStamp]
END


End
