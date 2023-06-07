/****** Object:  Procedure [dbo].[SP_MultipleMachineSelection]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[SP_MultipleMachineSelection] 'KTA Spindle Tooling Plant 2','SCREEN1','CELL 1,CELL 2'
*/

CREATE procedure [dbo].[SP_MultipleMachineSelection]
@PlantID NVARCHAR(50)='',
@Screen nvarchar(500)='',
@GroupID NVARCHAR(2000)=''
AS
BEGIN
Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
declare @StrGroupID as nvarchar(3000)
declare @StrScreen as nvarchar(200)
declare @StrGroupJoined as nvarchar(max)

SELECT @strPlantID = ''
SELECT @strSql = ''
SELECT @StrGroupID = ''
SELECT @StrScreen = ''

if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachineGroups.PlantID = N''' + @PlantID + ''''
End

if isnull(@Screen,'')<> ''
Begin
	SET @StrScreen = ' AND AssignMachinesToScreens_SSWL.screenname = N''' + @Screen + ''''
End

if isnull(@GroupID,'')<> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	SET @strGroupID = ' AND PlantMachineGroups.GroupID in (' + @GroupID +')'
End


select @strSql=''
select @strsql=@strSql+'IF EXISTS(SELECT * FROM AssignMachinesToScreens_SSWL  INNER JOIN PlantMachineGroups ON AssignMachinesToScreens_SSWL.MachineID=PlantMachineGroups.MachineID WHERE 1=1 '
select @strSql=@strSql+@StrScreen+@strPlantID+@StrGroupID
select @strSql=@strSql+') '
select @strSql=@strSql+'Begin '
SELECT @strSql=@strSql+'PRINT ''Machines EXIST IN AssignMachinesToScreens_SSWL TABLE'''
select @strSql=@strSql+'select DISTINCT AssignMachinesToScreens_SSWL.MachineID FROM AssignMachinesToScreens_SSWL  INNER JOIN PlantMachineGroups  ON AssignMachinesToScreens_SSWL.MachineID=PlantMachineGroups.MachineID where 1=1 '
select @strSql=@strSql+@strPlantID+@StrScreen+@StrGroupID
select @strSql=@strSql+' END'
PRINT(@STRSQL)
EXEC(@STRSQL)

select @strSql=''
select @strsql=@strSql+'IF NOT EXISTS(SELECT * FROM AssignMachinesToScreens_SSWL  INNER JOIN PlantMachineGroups ON AssignMachinesToScreens_SSWL.MachineID=PlantMachineGroups.MachineID WHERE 1=1 '
select @strSql=@strSql+@StrScreen+@strPlantID+@StrGroupID
select @strSql=@strSql+') '
select @strSql=@strSql+'Begin '
SELECT @strSql=@strSql+'print ''Global machines from PlantMachineGroups'''
SELECT @strSql=@strSql+'SELECT DISTINCT MACHINEID FROM PlantMachineGroups WHERE 1=1'
SELECT @strSql=@strSql+@strPlantID+@StrGroupID
select @strSql=@strSql+' END'
PRINT(@strSql)
EXEC(@strSql)

END
