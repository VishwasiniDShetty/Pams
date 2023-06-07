/****** Object:  Procedure [dbo].[s_Alert_GetMachinewiseDowntime]    Committed by VersionSQL https://www.versionsql.com ******/

--select datediff(second,'2017-04-10 09:30:00.000','2017-04-10 16:00:00')
--[dbo].[s_Alert_GetMachinewiseDowntime] '','','2017-05-04 13:45:00','BacktoBackDowns_AtCurtime'

CREATE PROCEDURE [dbo].[s_Alert_GetMachinewiseDowntime]
	@plantid as nvarchar(100)='',
	@machineID as nvarchar(100)='',
	@Starttime datetime,
	@param as nvarchar(50)= 'BacktoBackDowns_AtCurtime' --'BacktoBackDowns_ForShift' or 'BacktoBackDowns_AtCurtime' --ER0334 Added
AS
BEGIN

Declare @Startdate as Datetime
Declare @mcinterface as bigint
Declare @actualDown as bigint
Declare @TIMEFORMAT as NVARCHAR(10)
Declare @pdt as bigint
declare @Recordsttime as datetime 
declare @recordndtime as datetime 
declare @RecordDatatype as bigint 
declare @recordslno as bigint
declare @maxslno as bigint 
declare @curtime as datetime 
declare @strMachine as nvarchar(4000)
declare @strsql as nvarchar(4000)
Declare @strPlantID as nvarchar(255)


Select @strsql=''
Select @strMachine=''
select @strPlantID=''
select @curtime = @Starttime


CREATE TABLE #DowntimeData
(
	StartTime datetime,
	Max_Slno bigint,
	MachineID NvarChar(50),
	MachineInterface nvarchar(50),
	DownTime int,
	Recordsttime datetime, 
	Recordndtime datetime ,
	Datatype NvarChar(50)
)



SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION

set @pdt=0
Select @TIMEFORMAT=isnull(valueintext,'SS') from shopdefaults where parameter='TimeInFormat' order by parameter
PRINT(@TIMEFORMAT)

if isnull(@machineid,'')<> ''    
begin    
  SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''    
end  
 
if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

declare @CountOfMachines as int,@j as int


Declare @Type40Threshold int    
Declare @Type1Threshold int    
Declare @Type11Threshold int    
    
Set @Type40Threshold =0    
Set @Type1Threshold = 0    
Set @Type11Threshold = 0   

If @param = 'BacktoBackDowns_AtCurtime'
Begin

	Select @strsql = @strsql + 'insert into #DowntimeData(MachineID,MachineInterface)
	Select machineinformation.MachineID,machineinformation.interfaceID from  machineinformation  
	LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
	where 1=1 '
	SET @strSql =  @strSql + @strMachine
	exec(@strsql)

	update #DowntimeData set Max_slno=T1.Max_slno from
	(select rawdata.mc,max(rawdata.slno) as Max_slno from rawdata
	inner join #DowntimeData on #DowntimeData.MachineInterface=rawdata.mc 
	where rawdata.sttime< convert(nvarchar(20),@Starttime,120) and isnull(rawdata.ndtime,'1900-01-01')<convert(nvarchar(20),@Starttime,120) 
	and rawdata.datatype in(2,42,40,41,1,11,22) and datepart(year,rawdata.sttime)>'2000'
	group by rawdata.mc )T1 inner join #DowntimeData on T1.mc=#DowntimeData.MachineInterface


	update #DowntimeData set Recordsttime=T1.sttime,Recordndtime=T1.ndtime,Datatype=T1.Datatype from
	(select rawdata.mc,rawdata.sttime,rawdata.ndtime,#DowntimeData.Max_slno,rawdata.Datatype from rawdata
	inner join #DowntimeData on #DowntimeData.Max_slno=rawdata.slno 
	)T1 inner join #DowntimeData on T1.Max_slno=#DowntimeData.Max_slno

	Set @Type40Threshold =0    
	Set @Type1Threshold = 0    
	Set @Type11Threshold = 0    
	    
	Set @Type40Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')    
	Set @Type1Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')    
	Set @Type11Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')    
 
--	update #downtimeData Set Starttime=T2.StartDate
--	From #downtimeData inner join
--	(Select R.mc,Case 
--	when R.Datatype=1 then Dateadd(second,@Type1Threshold,R.ndtime)  --Dateadd(n,10,ndtime) 
--	when R.datatype=40 then Dateadd(second,@Type40Threshold,R.sttime)--Dateadd(n,10,sttime)
--	when R.datatype=11 then Dateadd(second,@Type11Threshold,R.sttime)
--	when R.datatype=2 or R.datatype=42 then R.sttime
--	End as StartDate
--	from rawdata R inner join #downtimeData D on R.mc=D.Machineinterface and R.slno=D.Max_Slno
--	where R.datatype in ('1','2','42','40','11')
--	)T2 On T2.mc=#downtimeData.Machineinterface

	update #downtimeData Set Starttime=T1.StartDate from (
	Select R.mc,Case when (
	case when R.datatype = 40 then datediff(second,R.sttime,@CurTime)- @Type40Threshold
	when R.datatype = 11 then datediff(second,R.sttime,@CurTime)- @Type11Threshold
	end) > 0 then R.sttime else @CurTime end as StartDate
	from rawdata R inner join #downtimeData D on R.mc=D.Machineinterface and R.slno=D.Max_Slno 
	where R.datatype in ('40','11')
	) as t1 inner join #downtimeData on t1.mc = #downtimeData.Machineinterface

	update #downtimeData Set Starttime=t1.StartDate from (
	Select R.mc,Case when (
	case 
	when R.datatype = 1 then datediff(second,R.ndtime,@CurTime)- @Type1Threshold
	end) > 0 then R.ndtime else @CurTime end as StartDate
	from rawdata R inner join #downtimeData D on R.mc=D.Machineinterface and R.slno=D.Max_Slno 
	where R.datatype in ('1')
	) as t1 inner join #downtimeData on t1.mc = #downtimeData.Machineinterface

	update #downtimeData Set Starttime=t1.StartDate from (
	Select R.mc,case 
	when R.datatype=2 or R.datatype=42 or R.datatype=22   then R.sttime end as StartDate
	from rawdata R inner join #downtimeData D on R.mc=D.Machineinterface and R.slno=D.Max_Slno 
	where R.datatype in ('2','42','22')
	) as t1 inner join #downtimeData on t1.mc = #downtimeData.Machineinterface

	Select row_number() over(Order by Machineinterface) as Idd,Machineinterface,Recordsttime,Recordndtime,datatype,Max_Slno into #Backtobackdowns_Curtime from #downtimeData
	where ISNULL(Max_Slno,'0')<>'0'


	Select @CountOfMachines = count(Machineinterface) from #Backtobackdowns_Curtime
	select @j=1


	select @Recordsttime = Recordsttime,@recordndtime = Recordndtime,@RecordDatatype=Datatype,@maxslno=Max_Slno,@recordslno=Max_Slno from #Backtobackdowns_Curtime  where idd=@j
	set @recordndtime = @Recordsttime 


	while @j<=@CountOfMachines
	Begin

		while  @recordsttime=@recordndtime and (@RecordDatatype= '2' or @RecordDatatype= '42' or @RecordDatatype= '22') and ISNULL(@recordslno,'0')<>'0'
		Begin

			
				select @recordslno = max(slno) from rawdata where slno<@maxslno and mc = 
				(select Machineinterface from #Backtobackdowns_Curtime where idd=@j)		

				select @RecordDatatype = datatype from rawdata where slno=@recordslno

				select @recordsttime = sttime from rawdata where (datatype=2 or  datatype=42 or  datatype=22) and 
				slno=@recordslno and ndtime = @recordsttime


				If @recordsttime <> '' 
				Begin
					update #downtimedata set starttime = @recordsttime where Machineinterface=(select Machineinterface from #Backtobackdowns_Curtime where idd=@j)
					set @recordndtime = @recordsttime
					set @maxslno=@recordslno
					set @RecordDatatype= @RecordDatatype
				end

				If isnull(@recordsttime,'1900-01-01') = '1900-01-01' 
				Begin	
					set @recordsttime = '1900-01-01'
				end			
		END

	Select @j = @j + 1
    END


	/*if last record was not found or starttime of the last record is less than starttime of intersted time period*/
	Update #DowntimeData set Starttime=@starttime where isnull(Max_slno,1)=1 or datatype not in ('1','2','42','40','11','22')

	/*calculating Actual down time*/
	update #downtimeData Set Downtime=datediff(second,Starttime,case when @curtime<Starttime then Starttime else @curtime end)  

	/*Appling PDT*/
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN
				
				update #downtimeData set downtime=downtime-down from #downtimedata
				inner join (
					Select t1.machineid,sum(isnull(datediff(ss,T1.StartTime,T1.EndTime),0))as down
					from
					(
					select D.machineid,
					Case when  D.Starttime <= pdt.StartTime then pdt.StartTime else  D.Starttime End as StartTime,
					Case when @curtime >= pdt.EndTime then pdt.EndTime else @curtime End as EndTime
					From Planneddowntimes pdt
					inner join #DowntimeData D on D.machineid=Pdt.machine
					where PDTstatus = 1  and --pdt.Machine=@machineid and
					((pdt.StartTime >= D.Starttime and pdt.EndTime <= @curtime)or
					(pdt.StartTime < D.Starttime and pdt.EndTime > D.Starttime and pdt.EndTime <=@curtime)or
					(pdt.StartTime >= D.Starttime and pdt.StartTime <@curtime and pdt.EndTime >@curtime) or
					(pdt.StartTime <  D.Starttime and pdt.EndTime >@curtime))
					) T1
					group by T1.machineid
				)t2 on t2.machineid=#downtimedata.machineId
	End

END

Select machineid,isnull(downtime,0) as downtime,StartTime from #downtimeData order by machineid 

Commit TRANSACTION

END
