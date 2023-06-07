/****** Object:  Procedure [dbo].[s_GetRejectionCodeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/*
--ER0391 - SwathiKS - 12/Sep/2014 :: Created New procedure to show Rejection Details from AutodataRejections table.
--Launch will be under Std -> Production and Downtime Report-Daily By Hour -> Format - Daily Rejection Report-Excel
---ER0504 - SwathiKS - 23/mar/2021 :: Included RejectionType for Precision Eng.
--[dbo].[s_GetRejectionCodeDetails] '2014-09-05','2014-09-06','','','',''
exec [dbo].[s_GetRejectionCodeDetails] @StartTime=N'2022-08-11 06:00:00',@EndTime=N'2022-08-13 06:00:00',@PlantID=N'',@machineID=N'M1,M2,M3',@GroupID=N'C1',@ComponentID=N'',@param=N''
*/
CREATE  PROCEDURE [dbo].[s_GetRejectionCodeDetails]
	@StartTime datetime,
	@EndTime datetime,
	@PlantID as nvarchar(50)='',
	@machineID as nvarchar(max)='',
	 @GroupID As nvarchar(max) = '',
	@ComponentID as nvarchar(100)='',
	@param nvarchar(50)=''
	
AS
BEGIN
Declare @strMachine as nvarchar(max)
Declare @strComponent as nvarchar(100)
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
Select @StrGroupID=''

Declare @StrTPMMachines AS nvarchar(500) 
SELECT @StrTPMMachines=''

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = ' AND M.TPMTrakEnabled = 1 '  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END 

if isnull(@PlantID,'')<> ''
Begin	
	SET @strPlantID = 'and P.PlantID = N''' + @PlantID + ''''	
End

--if isnull(@machineID,'')<> ''
--Begin	
--	SET @strMachine = 'and M.MachineID = N''' + @machineid + ''''	
--End

if isnull(@machineid,'') <> ''
begin
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	SET @strMachine = ' AND M.MachineID in (' + @MachineID +')'
end

if isnull(@ComponentID,'')<> ''
Begin	
	SET @strComponent = 'and C.Componentid = N''' + @ComponentID + ''''	
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
	[Machineid] [nvarchar](50),
	[Componentid] [nvarchar](100),
	[Operationno] [nvarchar](50),
	[Employeeid] [nvarchar](50),
	[EmployeeName] [nvarchar](50),
	[Rejection Catagory][nvarchar](50) ,
	[Rejection Code] [nvarchar](50),
	[RejectionQty] int,
	[PDT] int,
	[RejectionType] [nvarchar](50), --ER0504
	[CreatedTS] DATETIME
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
declare @startdatetime nvarchar(20)

select @starttime = convert(nvarchar(10),@starttime,110) + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' +CAST(cast(datePart(ss,FromTime)as int)+1 as nvarchar(2))
from shiftdetails where running = 1 and shiftid=(select top 1 shiftid from shiftdetails where running = 1 order by shiftid asc)

select @endtime = convert(nvarchar(10),@endtime,110) + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))
from shiftdetails where running = 1 and shiftid=(select top 1 shiftid from shiftdetails where running = 1 order by shiftid desc)

print '@starttime @endtime'
print @starttime
print @endtime

select @startdate = dbo.f_GetLogicalDaystart(@StartTime)
select @enddate = dbo.f_GetLogicalDayend(@endtime)

print '@startdate @enddate'
print @startdate
print @enddate

while @startdate<=@enddate
Begin

	select @startdatetime = CAST(datePart(yyyy,@startdate) AS nvarchar(4)) + '-' + 
     CAST(datePart(mm,@startdate) AS nvarchar(2)) + '-' + 
     CAST(datePart(dd,@startdate) AS nvarchar(2))

	INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
	select @startdate,ShiftName,
	Dateadd(DAY,FromDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
	DateAdd(Day,ToDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
	from shiftdetails where running = 1 order by shiftid
	Select @startdate = dateadd(d,1,@startdate)
END

create table #shift
(
	ShiftDate nvarchar(10), 
	shiftname nvarchar(20),
	Shiftstart datetime,
	Shiftend datetime,
	shiftid int
)

Insert into #shift (ShiftDate,shiftname,Shiftstart,Shiftend)
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn --where ShftSTtime>=@StartTime and ShftEndTime<=@endtime 

Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #shift S on SD.shiftname=S.shiftname where
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname



Select @strsql = ''
Select @strsql = @strsql + 'Insert into #Rejections
Select A.RejDate as Date, A.RejShift as Shift, M.machineid as Machineid, C.Componentid as Componentid, O.Operationno as Operationno, E.Employeeid as Employeeid,E.Name as EmployeeName, 
R.Catagory as [Rejection Catagory],R.rejectionid as [Rejection Code], SUM(A.Rejection_Qty) as [RejectionQty],0,A.RejectionType,A.CreatedTS
FROM AutodataRejections A 
inner join Rejectioncodeinformation R on A.Rejection_Code=R.interfaceid
inner join Machineinformation M on A.mc=M.interfaceid
inner join Componentinformation C on A.comp=C.interfaceid
inner join Componentoperationpricing O on A.opn=O.interfaceid and C.Componentid=O.Componentid and O.Machineid=M.machineid
inner join Employeeinformation E on a.opr=E.interfaceid
Left Outer join Plantmachine P on M.machineid=P.machineid
LEFT JOIN PlantMachineGroups on M.machineid = PlantMachineGroups.machineid
inner join #shift S on '''' + convert(nvarchar(10),(A.RejDate),126) + '''' =S.shiftdate and A.RejShift=S.shiftid 
where A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and A.flag = ''Rejection''
and Isnull(A.Rejshift,''a'')<>''a'' and Isnull(A.RejDate,''1900-01-01 00:00:00.000'')<>''1900-01-01 00:00:00.000'' '
Select @strsql = @strsql + @strPlantID + @strMachine + @StrTPMMachines + @strComponent + @StrGroupID
Select @strsql = @strsql + ' Group by A.RejDate,A.RejShift,M.machineid,C.Componentid,O.Operationno,E.Employeeid,E.Name, R.Catagory,R.rejectionid,A.RejectionType,A.CreatedTS'
print @strsql
Exec(@strsql)


Select @strsql = ''
Select @strsql = @strsql + 'Insert into #Rejections
Select #shift.ShiftDate as Date, #shift.shiftid as Shift, M.machineid as Machineid, C.Componentid as Componentid, O.Operationno as Operationno,
 E.Employeeid as Employeeid,E.Name as EmployeeName,R.Catagory as [Rejection Catagory],R.rejectionid as [Rejection Code], SUM(AutodataRejections.Rejection_Qty) as [RejectionQty],0,AutodataRejections.RejectionType,
 AutodataRejections.CreatedTS
FROM AutodataRejections cross join #shift 
inner join Rejectioncodeinformation R on AutodataRejections.Rejection_Code=R.interfaceid
inner join Machineinformation M on AutodataRejections.mc=M.interfaceid
inner join Componentinformation C on AutodataRejections.comp=C.interfaceid
inner join Componentoperationpricing O on AutodataRejections.opn=O.interfaceid and C.Componentid=O.Componentid and O.Machineid=M.machineid
inner join Employeeinformation E on AutodataRejections.opr=E.interfaceid
Left Outer join Plantmachine P on M.machineid=P.machineid
LEFT JOIN PlantMachineGroups on M.machineid = PlantMachineGroups.machineid
where AutodataRejections.CreatedTS>=#shift.Shiftstart and AutodataRejections.CreatedTS<=#shift.Shiftend and AutodataRejections.flag = ''Rejection''
and Isnull(AutodataRejections.Rejshift,''a'')=''a'' and Isnull(AutodataRejections.RejDate,''1900-01-01 00:00:00.000'')=''1900-01-01 00:00:00.000'' '
Select @strsql = @strsql + @strPlantID + @strMachine + @StrTPMMachines  + @strComponent + @StrGroupID 
Select @strsql = @strsql + ' Group by #shift.ShiftDate, #shift.shiftid,M.machineid,C.Componentid,O.Operationno, E.Employeeid,E.Name, R.Catagory,R.rejectionid,AutodataRejections.RejectionType,AutodataRejections.CreatedTS'
print @strsql
Exec(@strsql)

---ER0504 
Select @strsql = ''
Select @strsql = @strsql + 'Insert into #Rejections
Select A.RejDate as Date, A.RejShift as Shift, M.machineid as Machineid, C.Componentid as Componentid, O.Operationno as Operationno, E.Employeeid as Employeeid,E.Name as EmployeeName, 
R.Catagory as [Rejection Catagory],R.rejectionid as [Rejection Code], SUM(A.Rejection_Qty) as [RejectionQty],0,A.RejectionType,A.CreatedTS
FROM AutodataRejectionsBeforeMachining A 
inner join Rejectioncodeinformation R on A.Rejection_Code=R.interfaceid
inner join Machineinformation M on A.mc=M.interfaceid
inner join Componentinformation C on A.comp=C.interfaceid
inner join Componentoperationpricing O on A.opn=O.interfaceid and C.Componentid=O.Componentid and O.Machineid=M.machineid
inner join Employeeinformation E on a.opr=E.interfaceid
Left Outer join Plantmachine P on M.machineid=P.machineid
LEFT JOIN PlantMachineGroups on M.machineid = PlantMachineGroups.machineid
inner join #shift S on '''' + convert(nvarchar(10),(A.RejDate),126) + '''' =S.shiftdate and A.RejShift=S.shiftid 
where A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and A.flag = ''Rejection''
and Isnull(A.Rejshift,''a'')<>''a'' and Isnull(A.RejDate,''1900-01-01 00:00:00.000'')<>''1900-01-01 00:00:00.000'' '
Select @strsql = @strsql + @strPlantID + @strMachine + @StrTPMMachines + @strComponent + @StrGroupID 
Select @strsql = @strsql + ' Group by A.RejDate,A.RejShift,M.machineid,C.Componentid,O.Operationno,E.Employeeid,E.Name,R.Catagory,R.rejectionid,A.RejectionType,A.CreatedTS'
print @strsql
Exec(@strsql)
--ER0504

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN

	Update #Rejections set [RejectionQty] = isnull([RejectionQty],0) - isnull(T1.RejQty,0),[PDT] = isnull([PDT],0)+ isnull(T1.RejQty,0) from
	(
	Select date,shift,machineid,componentid,operationno,Employeeid,EmployeeName,[Rejection Catagory],[Rejection Code],isnull(SUM([RejectionQty]),0) as RejQty
	from #Rejections inner join #shift S on #Rejections.Date=S.shiftdate and #Rejections.shift=S.shiftid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and P.machine=#Rejections.Machineid and 
	P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend
	group by date,shift,machineid,componentid,operationno,Employeeid,EmployeeName,[Rejection Catagory],[Rejection Code]
	)T1 
	inner join #Rejections on #Rejections.Date=T1.Date and #Rejections.Shift=T1.shift 
	and #Rejections.machineid=T1.machineid and #Rejections.componentid=T1.componentid
	and #Rejections.operationno=T1.operationno and #Rejections.Employeeid=T1.Employeeid and #Rejections.EmployeeName=T1.EmployeeName and #Rejections.[Rejection Catagory]=T1.[Rejection Catagory] and #Rejections.[Rejection Code]=T1.[Rejection Code]
END

select Date,Shift,Machineid,Componentid,Operationno,Employeeid,EmployeeName,[Rejection Catagory],[Rejection Code],[RejectionQty] as [Rejection Qty],
[PDT] as [Rejection during PDT],RejectionType,CreatedTS AS Rejection_BookedTime from  #Rejections Order by Date,Shift,Machineid --ER0504


end
