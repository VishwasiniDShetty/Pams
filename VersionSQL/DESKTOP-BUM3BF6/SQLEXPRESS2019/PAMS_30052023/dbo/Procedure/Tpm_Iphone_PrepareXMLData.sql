/****** Object:  Procedure [dbo].[Tpm_Iphone_PrepareXMLData]    Committed by VersionSQL https://www.versionsql.com ******/

/******************************************* History ***************************************************************************/
--ER0329 =>20-jul-2012 :: By Geetanjali Kore :: To populate the data for Iphone by using tables PlantDetails,Machine1stLevelDetails,Machine2ndLevelDetails
--Select * from Shiftdetails where running=1
--  ER0368 - SwathiKS - 23/Oct/2013 :: Altered [dbo].[s_GetPlantEfficiency],Since S_GetCockpitdata has been Altered.
/*******************************************  ***************************************************************************/


CREATE procedure [dbo].[Tpm_Iphone_PrepareXMLData]

As 
Begin 
Create Table #Machine1stLevelDetails(
    TimeStamp [datetime],
    Plant [nvarchar](50) NULL,
    Line [nvarchar] (50)NULL,	
	Machine [nvarchar](50) NULL,
    RowHeader [nvarchar](50) NULL,
    RowID [int] NULL,   
	MCID [int] NULL,
    MonthValue [nvarchar](50) NULL, 
    ShiftValue [nvarchar](50) NULL, 
    DayValue [nvarchar](50) NULL,
    Type [nvarchar](50) NULL,
    PLID [int] not null

    	
) 

CREATE TABLE #Machine2ndLevelDetails(
	[Timestamp] [datetime] ,
	[Plant] [nvarchar](50) NULL,	
	[Machine] [nvarchar](50) NULL,
    [MCID] [int] NULL,
	[Rowheader] [nvarchar](50) NULL,
	[Columnheader] [nvarchar](50) NULL,
	[Description] [nvarchar](50) NULL,	
    [Value] [nvarchar](50) NULL,
	[Flag] [nvarchar](50) NULL,	
	[ColumnID] [int] NULL,
	[font] [nvarchar](10) NULL
) 

Create Table #GenerateRowheader_Downid(
            RowHeader [nvarchar](50) NULL,
            RowID [int]identity(1,1)
)

Create Table #GeneratePlantId_Shiftdetails(
            Plant_ShiftDetails [nvarchar](50) NULL,
            PlantID [int] identity(1,1)
)

-------------To populate the Components,AE,OEE,PE #Efficiency using procedure:s_GetCockpitData
CREATE TABLE #Efficiency
(
	MachineID nvarchar(50),
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	QualityEfficiency float, --ER0368
	OverallEfficiency float,
	Components float,
	RejCount float, --ER0368
	CN float,
	UtilisedTime float,
	TurnOver float,
	strUtilisedTime nvarchar(15),
	ManagementLoss nvarchar(15),
	DownTime nvarchar(15),
	TotalTime nvarchar(15),
	ReturnPerHour float,
	ReturnPerHourtotal float,
	Remarks nvarchar(40),
	PEGreen smallint,
	PERed smallint,
	AEGreen smallint,
	AERed smallint,
	OEGreen smallint,
	OERed smallint,
	QERed smallint, --ER0368
	QEGreen smallint, --ER0368
	starttime datetime,
	endtime datetime,
	MaxReasontime nvarchar(50) DEFAULT ('')
	,Remarks1 nvarchar(50),  --ER0368
	Remarks2 nvarchar(50)  --ER0368
	
)

-------------To populate the DownTime and totalTime into #DowntimeTbl using procedure:s_GetDownTimeMatrixfromAutoData
CREATE TABLE #DowntimeTbl
(
 	    MachineID nvarchar(50),        
	    Downcode nvarchar(4000),
		DownID nvarchar(4000),
		DownTime float,
		DownFreq int,
		TotalMachine float,
		TotalDown float,
        Hours  float,		
		MachineIDLabel nvarchar(50) ,
		OperatorIDLabel nvarchar(50),
		DownIDLabel nvarchar(50) ,
		ComponentIDLabel nvarchar(50),
		StartTime nvarchar(50),
		EndTime nvarchar(50),
		TotalMachineFreq float DEFAULT(0),
		TotalDownFreq float DEFAULT(0)
	)
Create Table #CompOpnCount
	(
    Startdate datetime,
    EndDate datetime,
	MachineID Nvarchar(50),
	ComponentID Nvarchar(50),
	OperationID Nvarchar(50),
	CmpCount Int,
    Mid int default(1),
    Mheader int Default(1),
    MainComponentID Nvarchar(50)
     
	)
Create table #GetShiftTime
	(
	dDate DateTime,
	ShiftName NVarChar(50),
	StartTime DateTime,
	EndTime DateTime
	)




Declare @strsql as nvarchar(4000)
Declare @gettime as datetime
Declare @gettime1 as datetime
declare @sttime_1 as datetime
declare @ndtime_1 as datetime
Declare @ShiftStartTime as datetime
Declare @ShiftEndTime as datetime
Declare @StartTime as datetime
Declare @EndTime as datetime
Declare @Startmonth as datetime
Declare @Endmonth as datetime
Declare @monthpart as nvarchar(10)
Declare @yearpart as nvarchar(10)
Declare @cnt as int
Set @cnt=1

Select @gettime1=getdate()	

print (@gettime1)

/****************************** To Insert into PlantDetails Table  START ********************************************/

Truncate table PlantDetails

Insert into #GeneratePlantId_Shiftdetails(Plant_ShiftDetails) (Select distinct(PlantInformation.PlantID) from PlantInformation)


select @strsql=''

select @strsql= @strsql+'Insert into PlantDetails (Plant,Machine,MCID,Type,PLID) (Select PlantInformation.PlantID,PlantMachine.MachineID,machineinformation.InterfaceID,''MCS'',#GeneratePlantId_Shiftdetails.PlantId from PlantMachine inner join PlantInformation  on PlantInformation.PlantId=PlantMachine.PlantID inner join machineinformation on PlantMachine.MachineID=machineinformation.machineid INNER JOIN #GeneratePlantId_Shiftdetails on #GeneratePlantId_Shiftdetails.Plant_ShiftDetails= PlantInformation.PlantID )'
select @strsql= @strsql+'order by  PlantInformation.PlantID'
exec(@strsql)
--Select * from PlantDetails


/****************************** To Insert into PlantDetails Table END ********************************************/

 
select @strsql=''
select @strsql= @strsql+'Insert into #GenerateRowheader_Downid(RowHeader) values (''Nos'')'
select @strsql= @strsql+''+'Insert into #GenerateRowheader_Downid(RowHeader) values(''AE%'')'
select @strsql= @strsql+''+'Insert into #GenerateRowheader_Downid (RowHeader) values (''PE%'')'
select @strsql= @strsql+'Insert into #GenerateRowheader_Downid (RowHeader) values (''OEE%'')'
exec(@strsql)


/****************************** To Insert into #Machine1stLevelDetails Table  START ********************************************/


select @strsql=''
select @strsql= @strsql+'Insert into  #Machine1stLevelDetails(Plant,Line,Machine,MCID,Type,Rowheader,RowId,MonthValue,ShiftValue,DayValue,PLID)  (Select PlantInformation.PlantID,''Gen'',PlantMachine.MachineID,machineinformation.InterfaceID,''Gen'',#GenerateRowheader_Downid.Rowheader,#GenerateRowheader_Downid.RowId,''0'',''0'',''0'',#GeneratePlantId_Shiftdetails.PlantId  from PlantMachine inner join PlantInformation  on PlantInformation.PlantId=PlantMachine.PlantID inner join machineinformation on PlantMachine.MachineID=machineinformation.machineid inner join #GeneratePlantId_Shiftdetails on #GeneratePlantId_Shiftdetails.Plant_ShiftDetails=PlantInformation.PlantId cross join #GenerateRowheader_Downid )'
select @strsql= @strsql+'order by  PlantInformation.PlantID'
exec(@strsql)


/*********** To get current shift timings Start From here  **************/

Select @gettime=(select dbo.f_GetLogicalDaystart(getdate()))
insert into #GetShiftTime Exec s_GetShiftTime @gettime,''
Declare Finder  cursor for 
Select StartTime,Endtime from #GetShiftTime order by StartTime
Open Finder
FETCH NEXT FROM Finder INTO @sttime_1,@ndtime_1
while (@@fetch_status= 0)
Begin

If (@gettime1>=@sttime_1 and @gettime1<=@ndtime_1)
begin

select @ShiftStartTime=@sttime_1
Select @ShiftEndTime=@ndtime_1
End

FETCH NEXT FROM Finder INTO @sttime_1,@ndtime_1

End
Close Finder
Deallocate Finder
--print @ShiftStartTime
--print @ShiftEndTime


Truncate table #Efficiency

Insert #Efficiency exec s_GetCockpitData @ShiftStartTime, @ShiftEndTime,'',''


/*********** To get current shift timings Ends  here  **************/

select @strsql=''
select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.ShiftValue=isnull(#Machine1stLevelDetails.ShiftValue,0)+T1.components from
                        (Select Components,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''Nos'''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.ShiftValue=isnull(#Machine1stLevelDetails.ShiftValue,0)+T1.ProductionEfficiency from
            (Select ProductionEfficiency,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''PE%'''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.ShiftValue=isnull(#Machine1stLevelDetails.ShiftValue,0)+T1.AvailabilityEfficiency from
            (Select AvailabilityEfficiency,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''AE%'''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.ShiftValue=isnull(#Machine1stLevelDetails.ShiftValue,0)+T1.OverallEfficiency from
            (Select OverallEfficiency,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''OEE%'''

exec (@strsql)

/*********** To get Logical Day timings Start From here  **************/

select @StartTime=dbo.f_GetLogicalDaystart(getdate())
select @EndTime=dbo.f_GetLogicalDayend(getdate())
--print @ShiftStartTime
--print @ShiftEndTime
--print @StartTime 
--print @EndTime

Truncate table #Efficiency ----------To Reload the table for logical day

Insert #Efficiency exec s_GetCockpitData @StartTime,@EndTime,'',''

/*********** To get Logical Day timings Start From here  **************/

select @strsql=''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.DayValue=isnull(#Machine1stLevelDetails.DayValue,0)+T1.components from
                        (Select Components,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''Nos'''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.DayValue=isnull(#Machine1stLevelDetails.DayValue,0)+T1.ProductionEfficiency from
                        (Select ProductionEfficiency,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''PE%'''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.DayValue=isnull(#Machine1stLevelDetails.DayValue,0)+T1.AvailabilityEfficiency from
                        (Select AvailabilityEfficiency,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''AE%'''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.DayValue=isnull(#Machine1stLevelDetails.DayValue,0)+T1.OverallEfficiency from
                        (Select OverallEfficiency,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''OEE%'''

exec (@strsql)



Select @monthpart=(Select datepart(m,@gettime1))
print(@monthpart)
Select @yearpart=(Select datepart(yyyy,@gettime1))
print(@yearpart)
select @Startmonth=@yearpart+'-'+@monthpart+'-01'

If((@monthpart=1) or (@monthpart=3) or (@monthpart=5 )or (@monthpart=7) or (@monthpart=8) or (@monthpart=10) or (@monthpart=12))
begin
select @Endmonth=@yearpart+'-'+@monthpart+'-31'
End
Else If(@monthpart=4 or @monthpart=6 or @monthpart=9 or  @monthpart=11 )
begin
select @Endmonth=@yearpart+'-'+@monthpart+'-30'
End
Else If(@monthpart=2 and @yearpart/4=0 )
begin
select @Endmonth=@yearpart+'-'+@monthpart+'-29'
End
else
begin
select @Endmonth=@yearpart+'-'+@monthpart+'-28'
End
print @ShiftStartTime
print @ShiftEndTime
print @StartTime 
print @EndTime
print @Startmonth
print @Endmonth

Truncate table #Efficiency
Insert #Efficiency exec s_GetCockpitData @Startmonth,@Endmonth,'',''

/*********** To get Logical Day timings Start From here  **************/

select @strsql=''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.MonthValue=isnull(#Machine1stLevelDetails.MonthValue,0)+T1.components from
                        (Select Components,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''Nos'''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.MonthValue=isnull(#Machine1stLevelDetails.MonthValue,0)+T1.ProductionEfficiency from
                        (Select ProductionEfficiency,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''PE%'''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.MonthValue=isnull(#Machine1stLevelDetails.MonthValue,0)+T1.AvailabilityEfficiency from
                        (Select AvailabilityEfficiency,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''AE%'''

select @strsql= @strsql+'update #Machine1stLevelDetails set #Machine1stLevelDetails.MonthValue=isnull(#Machine1stLevelDetails.MonthValue,0)+T1.OverallEfficiency from
                        (Select OverallEfficiency,MachineId from #Efficiency)T1 inner join  #Machine1stLevelDetails on T1.MachineID=#Machine1stLevelDetails.Machine where #Machine1stLevelDetails.RowHeader=''OEE%'''
exec (@strsql)

update #Machine1stLevelDetails set #Machine1stLevelDetails.TimeStamp=@gettime1



Truncate table dbo.Machine1stLevelDetails

--Insert into dbo.Machine1stLevelDetails (TimeStamp,Plant,Line,Machine,MonthValue,DayValue,ShiftValue,RowHeader,PLID,MCID,RowID,MCType)
--                                (Select TimeStamp,Plant,Line,Machine,ltrim(STR(MonthValue,len(MonthValue),2)),ltrim(STR(DayValue,len(DayValue),2)),ltrim(STR(ShiftValue,len(ShiftValue),2)),RowHeader,PLID,MCID,RowID,Type from #Machine1stLevelDetails)

Insert into dbo.Machine1stLevelDetails (TimeStamp,Plant,Line,Machine,MonthValue,DayValue,ShiftValue,RowHeader,PLID,MCID,RowID,MCType)
                                (Select TimeStamp,Plant,Line,Machine,round((MonthValue),2),round(DayValue,2),round(ShiftValue,2),RowHeader,PLID,MCID,RowID,Type from #Machine1stLevelDetails)
--Insert into dbo.Machine1stLevelDetails (TimeStamp,Plant,Line,Machine,MonthValue,DayValue,ShiftValue,RowHeader,PLID,MCID,RowID,MCType)
--                                (Select TimeStamp,Plant,Line,Machine,MonthValue,DayValue,ShiftValue,RowHeader,PLID,MCID,RowID,Type from #Machine1stLevelDetails)

/****************** End of Populating the data for Table:: Machine1stLevelDetails *****************/



/****************************** To Insert into #Machine2ndLevelDetails Table  START ********************************************/


Truncate table #GenerateRowheader_Downid
Insert into #GenerateRowheader_Downid(RowHeader)values ('Total Down Time')
--Insert into #GenerateRowheader_Downid(RowHeader) (Select Distinct(Downid) from DownCodeInformation) -- Geeta commented
Insert into #GenerateRowheader_Downid(RowHeader) (Select top 10(Downid) from DownCodeInformation) -- Geeta Added


Truncate table #GeneratePlantId_Shiftdetails
Insert into #GeneratePlantId_Shiftdetails(Plant_ShiftDetails) values ('Shift')
Insert into #GeneratePlantId_Shiftdetails(Plant_ShiftDetails) values ('Day')
Insert into #GeneratePlantId_Shiftdetails(Plant_ShiftDetails) values ('Month')

Select @strsql=''
select @strsql=@strsql+'Insert into #Machine2ndLevelDetails(Plant,Machine,MCID,Flag,Description,Rowheader,Columnheader,ColumnId,Value,font) (Select PlantInformation.PlantId,PlantMachine.MachineID,machineinformation.InterfaceID,''Nor'',#GenerateRowheader_Downid.RowHeader,#GenerateRowheader_Downid.RowID,#GeneratePlantId_Shiftdetails.Plant_ShiftDetails,#GeneratePlantId_Shiftdetails.PlantId,''0'',''Nor'' from PlantInformation inner join PlantMachine on PlantMachine.PlantId=PlantInformation.PlantId inner join machineinformation on PlantMachine.MachineID=machineinformation.machineid cross join #GenerateRowheader_Downid cross join #GeneratePlantId_Shiftdetails)'
select @strsql= @strsql+'order by  PlantInformation.PlantID'
exec(@strsql)

While (@cnt<=3)
Begin
print @StartTime
print @EndTime
print @ShiftStartTime
print @ShiftEndTime
print @Startmonth
print @Endmonth

--Delete from #CompOpnCount
Truncate table #CompOpnCount
if(@cnt=1)
begin
Insert into #CompOpnCount(Startdate,EndDate,MachineID,ComponentID,OperationID,CmpCount) exec s_GetComponentProdDataFromAutoData @ShiftStartTime, @ShiftEndTime,'','','','','Prodcount'
Update #CompOpnCount set MainComponentid=Substring(Componentid,1,4)+'('+OperationId+')'
End

if(@cnt=2)
begin
Insert into #CompOpnCount(Startdate,EndDate,MachineID,ComponentID,OperationID,CmpCount) exec s_GetComponentProdDataFromAutoData @StartTime,@EndTime,'','','','','Prodcount'
Update #CompOpnCount set MainComponentid=Substring(Componentid,1,4)+'('+OperationId+')'
End

if(@cnt=3)
begin
Insert into #CompOpnCount(Startdate,EndDate,MachineID,ComponentID,OperationID,CmpCount) exec s_GetComponentProdDataFromAutoData @Startmonth,@Endmonth,'','','','','Prodcount'
Update #CompOpnCount set MainComponentid=Substring(Componentid,1,4)+'('+OperationId+')'
End


Declare @MId nvarchar(50)
Declare @MId_1 nvarchar(50)
Declare @ComponentId nvarchar(50)
Declare @ComponentId_1 nvarchar(50)
Declare @operationId nvarchar(50)
Declare @operationId_1 nvarchar(50)



Declare  CompId  Cursor for
Select MachineID,Componentid,Operationid from #CompOpnCount
Open compid
FETCH NEXT FROM compid INTO @Mid,@ComponentId,@operationId
while (@@fetch_status= 0)
Begin              

	Set @MId_1=@Mid
	set @ComponentId_1=@ComponentId
	set @operationId_1=@operationId

	FETCH NEXT FROM compid INTO @Mid,@ComponentId,@operationId
	if(@@fetch_status= 0)
	begin
		If (@MId_1=@Mid)
		Begin
		Update #CompOpnCount set MHeader=D.MH from (Select Max(Mid)+1 as MH from #CompOpnCount where Machineid=@Mid )D where Machineid=@Mid_1 and  @ComponentId=ComponentId and @operationId=operationId

		update #CompOpnCount set Mid=Mid+1 where  Machineid=@Mid
		End
	End
End
Close compid
Deallocate compid


If(@cnt=1)
begin
	select @strsql=''
	select @strsql=@strsql+'Insert into #Machine2ndLevelDetails(Plant,Machine,MCID,Flag,Description,Value,Columnheader,ColumnId,font,Rowheader)
	(Select PlantInformation.PlantId,PlantMachine.MachineID,machineinformation.InterfaceID,''Sw'',#compOpnCount.MainComponentid,#compOpnCount.CmpCount,''Shift'',''1'',''Nor'',#compOpnCount.Mheader
	from PlantInformation inner join PlantMachine on PlantMachine.PlantId=PlantInformation.PlantId inner join machineinformation on PlantMachine.MachineID=machineinformation.machineid  inner join #CompOpnCount on MachineInformation.Machineid=#CompOpnCount.MachineId  )'
	select @strsql= @strsql+'order by  PlantInformation.PlantID'
	exec(@strsql)
End

If(@cnt=2)
begin
	select @strsql=''
	select @strsql=@strsql+'Insert into #Machine2ndLevelDetails(Plant,Machine,MCID,Flag,Description,Value,Columnheader,ColumnId,font,Rowheader)
	(Select PlantInformation.PlantId,PlantMachine.MachineID,machineinformation.InterfaceID,''Sw'',#compOpnCount.MainComponentid,#compOpnCount.CmpCount,''Day'',''2'',''Nor'',#compOpnCount.Mheader
	from PlantInformation inner join PlantMachine on PlantMachine.PlantId=PlantInformation.PlantId inner join machineinformation on PlantMachine.MachineID=machineinformation.machineid  inner join #CompOpnCount on MachineInformation.Machineid=#CompOpnCount.MachineId  )'
	select @strsql= @strsql+'order by  PlantInformation.PlantID'
	exec(@strsql)
End

If(@cnt=3)
begin
	select @strsql=''
	select @strsql=@strsql+'Insert into #Machine2ndLevelDetails(Plant,Machine,MCID,Flag,Description,Value,Columnheader,ColumnId,font,Rowheader)
	(Select PlantInformation.PlantId,PlantMachine.MachineID,machineinformation.InterfaceID,''Sw'',#compOpnCount.MainComponentid,#compOpnCount.CmpCount,''Month'',''3'',''Nor'',#compOpnCount.Mheader
	from PlantInformation inner join PlantMachine on PlantMachine.PlantId=PlantInformation.PlantId inner join machineinformation on PlantMachine.MachineID=machineinformation.machineid  inner join #CompOpnCount on MachineInformation.Machineid=#CompOpnCount.MachineId  )'
	select @strsql= @strsql+'order by  PlantInformation.PlantID'
	exec(@strsql)
End

set @Cnt=@cnt+1

End

--Select * from #Machine2ndLevelDetails where flag='Sw'  order by Plant
--return

update #Machine2ndLevelDetails set #Machine2ndLevelDetails.font='Bold' where #Machine2ndLevelDetails.Description='Total Down Time'


/*********** To get current shift timings Start From here  **************/




--Truncate table #DowntimeTbl

/*********** To get current shift timings Ends  here  **************/
--print'Shift'
--print @ShiftStartTime
--print @ShiftEndTime
Truncate Table #DowntimeTbl

Insert #DowntimeTbl exec s_GetDownTimeMatrixfromAutoData @ShiftStartTime,@ShiftEndTime,'','','','','All','All','All','ALL','DTime','','0'


select @strsql=''
select @strsql= @strsql+'update #Machine2ndLevelDetails set #Machine2ndLevelDetails.Value=isnull(#Machine2ndLevelDetails.Value,0)+DT.DownTime from
                        (Select MachineId,DownID,DownTime from #DowntimeTbl)DT inner join  #Machine2ndLevelDetails on DT.MachineID=#Machine2ndLevelDetails.Machine and DT.DownID=#Machine2ndLevelDetails.Description where #Machine2ndLevelDetails.Columnheader=''Shift'''
select @strsql= @strsql+'update #Machine2ndLevelDetails set #Machine2ndLevelDetails.Value=isnull(#Machine2ndLevelDetails.Value,0)+DT.TotalMachine from
                        (Select MachineId,DownID,TotalMachine from #DowntimeTbl)DT inner join  #Machine2ndLevelDetails on DT.MachineID=#Machine2ndLevelDetails.Machine and #Machine2ndLevelDetails.Description=''Total Down Time'' where #Machine2ndLevelDetails.Columnheader=''Shift'''

exec (@strsql)

Truncate Table #DowntimeTbl

--print'Day'
--print @StartTime 
--print @EndTime

Insert #DowntimeTbl exec s_GetDownTimeMatrixfromAutoData @StartTime,@EndTime,'','','','','All','All','All','ALL','DTime','','0'
--Select MachineId,DownID,DownTime from #DowntimeTbl
select @strsql=''
select @strsql= @strsql+'update #Machine2ndLevelDetails set #Machine2ndLevelDetails.Value=isnull(#Machine2ndLevelDetails.Value,0)+DT.DownTime from
                        (Select MachineId,DownID,DownTime from #DowntimeTbl)DT inner join  #Machine2ndLevelDetails on DT.MachineID=#Machine2ndLevelDetails.Machine and DT.DownID=#Machine2ndLevelDetails.Description where #Machine2ndLevelDetails.Columnheader=''Day'''
select @strsql= @strsql+'update #Machine2ndLevelDetails set #Machine2ndLevelDetails.Value=isnull(#Machine2ndLevelDetails.Value,0)+DT.TotalMachine from
                        (Select MachineId,DownID,TotalMachine from #DowntimeTbl)DT inner join  #Machine2ndLevelDetails on DT.MachineID=#Machine2ndLevelDetails.Machine and #Machine2ndLevelDetails.Description=''Total Down Time'' where #Machine2ndLevelDetails.Columnheader=''Day'''
exec (@strsql)


Truncate Table #DowntimeTbl
--print 'month'
--print @Startmonth
--print @Endmonth
Insert #DowntimeTbl exec s_GetDownTimeMatrixfromAutoData @Startmonth,@Endmonth,'','','','','All','All','All','ALL','DTime','','0'
select @strsql=''
select @strsql= @strsql+'update #Machine2ndLevelDetails set #Machine2ndLevelDetails.Value=isnull(#Machine2ndLevelDetails.Value,0)+DT.DownTime from
                        (Select MachineId,DownID,DownTime from #DowntimeTbl)DT inner join  #Machine2ndLevelDetails on DT.MachineID=#Machine2ndLevelDetails.Machine and DT.DownID=#Machine2ndLevelDetails.Description where #Machine2ndLevelDetails.Columnheader=''Month'''
select @strsql= @strsql+'update #Machine2ndLevelDetails set #Machine2ndLevelDetails.Value=isnull(#Machine2ndLevelDetails.Value,0)+DT.TotalMachine from
                        (Select MachineId,DownID,TotalMachine from #DowntimeTbl)DT inner join  #Machine2ndLevelDetails on DT.MachineID=#Machine2ndLevelDetails.Machine and #Machine2ndLevelDetails.Description=''Total Down Time'' where #Machine2ndLevelDetails.Columnheader=''Month'''

exec (@strsql)
update #Machine2ndLevelDetails set #Machine2ndLevelDetails.TimeStamp=@gettime1



Truncate table Machine2ndLevelDetails
Insert into Machine2ndLevelDetails(Timestamp,Plant,Machine,MCID,Rowheader,Columnheader,ColumnId,Description,Value,Flag,font) 
                  --(Select Timestamp,Plant,Machine,MCID,Rowheader,Columnheader,ColumnId,Description,Value,Flag,font from #Machine2ndLevelDetails )  --Geeta Commented                     

(Select Timestamp,Plant,Machine,MCID,Rowheader,Columnheader,ColumnId,Description,
[dbo].[f_FormatTime] (convert(numeric(38,0),cast(Value AS float)),'hh:mm:ss'),Flag,font from #Machine2ndLevelDetails )    --Geeta Added                  


--Select * From Machine2ndLevelDetails

/****************** End of Populating the data for Table:: Machine2ndLevelDetails *****************/


End
