/****** Object:  Procedure [dbo].[s_GetMachineRuntimeChart]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].s_GetMachineRuntimeChart '2015-08-05 10:47:43.000','A','','',''
CREATE PROCEDURE [dbo].[s_GetMachineRuntimeChart]
	@Date datetime ='',
	@Shiftname nvarchar(50)='',  
	@PlantID nvarchar(50),  
	@Machineid nvarchar(1000)='',  
	@Param nvarchar(20)=''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if (@Date>getdate())
Begin
set @Date=getdate()
End

Create Table #LiveDetails  
(  
	[Sl No] Bigint Identity(1,1) Not Null,  
	[Machineid] nvarchar(50),  
	[MachineStatus] nvarchar(100),
	[ShiftDate] datetime,  
	[ShiftName] nvarchar(50),  
	[From time] datetime,  
	[To Time] datetime  
	
)  

CREATE TABLE #ShiftDetails   
(  
 SlNo bigint identity(1,1) NOT NULL,
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime  
)  

Create table #Day
(
[From Time] datetime,
[To time] datetime
)  


Declare @strsql nvarchar(4000)  
Declare @strmachine nvarchar(2000)  
Declare @StrPlantid as nvarchar(1000)  
Declare @CurStrtTime as datetime  
declare @shift as nvarchar(1000)  
  
Select @strsql = ''  
Select @strmachine = ''  
select @strPlantID = ''  
Select @shift =''  
  

  
if isnull(@PlantID,'') <> ''  
Begin  
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'  
End

Select @CurStrtTime=@Date

INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)   
EXEC s_GetShiftTime @CurStrtTime,@Shiftname  


	create table #temptest
	(
		ID int identity,
		Machineid nvarchar(50),
		[From time] datetime,
		[To Time] datetime,
		CurrentTime datetime,
		MachineStatus nvarchar(50),	

	)

	create table #temp
	(

		Machineid nvarchar(50),
		CurrentTime datetime,
		NextTime datetime,
		[Status] nvarchar(50),
		MachineStatus nvarchar(50),	
		Color nvarchar(50)	
	)

	   
	If (@Shiftname<>'DAY') and @param<>'Summary' 
	Begin  
		Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName)  
		SELECT distinct Machineinformation.machineid,S.PDate,S.shiftstart,S.shiftend,S.Shift FROM dbo.Machineinformation  
		left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid  
		Cross join #ShiftDetails S where (@machineid='' or MachineInformation.MachineID=@machineid) and (@PlantID='' or PlantMachine.PlantID=@PlantID)
	End



	if (@Shiftname='DAY') and @param<>'Summary'
	BEGIN

	Insert into #day([From Time],[To time])
	Select dbo.f_GetLogicalDay(@Date,'start'),dbo.f_GetLogicalDay(@Date,'End')

	Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName) 
	SELECT distinct Machineinformation.machineid,0,s.[From Time],s.[To time],0 FROM dbo.Machineinformation 
	left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid  
	Cross join #day S where (@machineid='' or MachineInformation.MachineID=@machineid) and (@PlantID='' or PlantMachine.PlantID=@PlantID)

	end


	insert into #temptest(CurrentTime,MachineStatus,MachineID,[From time],[To Time])
	select F.CNCTimeStamp, F.MachineStatus,F.MachineID,t.[From time],t.[To Time]
	from Focas_LiveData F inner join #LiveDetails T  on F.MachineID=T.MachineID
	where F.CNCTimeStamp between (T.[From time]) and (T.[To time])


	insert into #temp(CurrentTime,NextTime,MachineStatus,MachineID)
	select tnext.CurrentTime,t.CurrentTime,t.MachineStatus,t.MachineID
	from #temptest t join
	#temptest tnext
	on t.id = tnext.id + 1 order by t.id 

	update #temp  set MachineStatus='NODATA' where abs(DATEDIFF(Second,NextTime,CurrentTime))>  120


update #temp set Color =case WHEN MachineStatus in('Unavailable','Stopped','Stop', 'Interrupted','Aborted','Code = 0') THEN 'RED' 
								WHEN MachineStatus in('Unavailable (Alarm)') THEN 'RED1'
								WHEN MachineStatus in('Unavailable (Emergency)') THEN 'RED2' 
								WHEN MachineStatus in('Feed Hold','Idle') THEN 'YELLOW'		
								WHEN MachineStatus in('In Cycle' ,'In Progress') THEN 'GREEN'
								WHEN MachineStatus in('NODATA') THEN 'BLACK'
								 END from #temp
								
update #temp set Status =case	WHEN Color ='RED' THEN '1' 
									WHEN Color ='YELLOW' THEN '2'		
									WHEN Color ='GREEN' THEN '3'
									WHEN Color ='BLACK' THEN '4'
									WHEN Color ='RED1' THEN '5'
									WHEN Color ='RED2' THEN '6'
									END from #temp
	


	select * from #temp order by CurrentTime ;

	
END
