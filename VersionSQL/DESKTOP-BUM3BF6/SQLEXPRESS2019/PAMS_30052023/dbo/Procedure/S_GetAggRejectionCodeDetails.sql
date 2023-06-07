/****** Object:  Procedure [dbo].[S_GetAggRejectionCodeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec [dbo].[S_GetAggRejectionCodeDetails] '2014-09-05','2014-09-06','','','',''
*/
CREATE procedure [dbo].[S_GetAggRejectionCodeDetails]
@StartTime datetime,
@EndTime datetime,
@PlantID as nvarchar(50)='',
@machineID as nvarchar(max)='',
@GroupID As nvarchar(max) = '',
@ComponentID as nvarchar(100)='',
@OperatorID as nvarchar(100)='',
@param nvarchar(50)=''

AS
BEGIN
Declare @strMachine as nvarchar(max)
Declare @strComponent as nvarchar(100)
Declare @strOperatorID as nvarchar(250)
Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @curdate as datetime
Declare @StrGroupID AS NVarchar(max)

declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)

SELECT @strMachine = ''
SELECT @strPlantID = ''
SELECT @strSql= ''
select @strComponent=''
select @strOperatorID=''
Select @StrGroupID=''

if isnull(@PlantID,'')<> ''
Begin	
	SET @strPlantID = 'and PM.PlantID = N''' + @PlantID + ''''	
End

--if isnull(@machineID,'')<> ''
--Begin	
--	SET @strMachine = 'and SPD.MachineID = N''' + @machineid + ''''	
--End

if isnull(@machineid,'') <> ''
begin
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	SET @strMachine = ' and SPD.MachineID in (' + @MachineID +')'
end


if isnull(@ComponentID,'')<> ''
Begin	
	SET @strComponent = 'and SPD.Componentid = N''' + @ComponentID + ''''	
End

if isnull(@OperatorID,'')<> ''
Begin	
	SET @strOperatorID = 'and SPD.OperatorID = N''' + @OperatorID + ''''	
End

If isnull(@GroupID ,'') <> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	Select @StrGroupID = ' And ( PlantMachineGroups.GroupID IN (' + @GroupID + ')) '
End


CREATE TABLE #Rejections
(
	[Date] [datetime],
	[Shift] [nvarchar](50),
	[MachineID] [nvarchar](50),
	[ComponentID] [nvarchar](100),
	[OperationNo] [nvarchar](50),
	--[Employeeid] [nvarchar](50),
	[EmployeeName] [nvarchar](50),
	[RejectionCatagory][nvarchar](50) ,
	[RejectionCode] [nvarchar](50),
	[RejectionQty] int,
	--[PDT] int,
	--[RejectionType] [nvarchar](50) --ER0504
)

CREATE TABLE #ShiftDefn
(
	ShiftDate datetime,		
	Shiftname nvarchar(20),
	ShftSTtime datetime,
	ShftEndTime datetime	
)

declare @startdate as datetime
declare @enddate as datetime

select @startdate = dbo.f_GetLogicalDaystart(@StartTime)
select @enddate = dbo.f_GetLogicalDayend(@endtime)

Select @strsql = ''
Select @strsql = @strsql + 'Insert into #Rejections (Date,Shift,MachineID,ComponentID,OperationNo,EmployeeName,RejectionCatagory,RejectionCode,RejectionQty)
select SPD.pDate as Date,SPD.Shift,SPD.MachineID,SPD.ComponentID,SPD.OperationNo, SPD.OperatorID as EmployeeName,RC.Catagory as RejectionCatagory,RC.rejectionid as RejectionCode,sum(isnull(R.Rejection_Qty,0)) as RejectionQty From ShiftProductionDetails SPD 
Left Outer Join ShiftRejectionDetails R ON SPD.ID=R.ID
inner join rejectioncodeinformation RC on R.Rejection_Reason=RC.rejectionid 
LEFT OUTER JOIN PlantMachine PM ON SPD.machineid = PM.MachineID 
LEFT JOIN PlantMachineGroups on spd.machineid = PlantMachineGroups.machineid
WHERE ( convert(nvarchar(10),SPD.pDate,120) >='''+ Convert(Nvarchar(10),@starttime,120)+''' and convert(nvarchar(10),SPD.pDate,120) <='''+convert(nvarchar(10),@EndTime,120)+''' )'
Select @strsql = @strsql + @strPlantID + @strMachine + @strComponent + @strOperatorID + @StrGroupID 
Select @strsql = @strsql + ' Group by SPD.pDate,SPD.Shift,SPD.MachineID,SPD.ComponentID,SPD.OperationNo, SPD.OperatorID,RC.Catagory,RC.rejectionid'
print @strsql
Exec(@strsql)


select Date,Shift,Machineid,Componentid,Operationno,EmployeeName,[RejectionCatagory],[RejectionCode],[RejectionQty] as [Rejection Qty] from  #Rejections 
where [RejectionQty] > 0
Order by Date,Shift,Machineid --ER0504


END
