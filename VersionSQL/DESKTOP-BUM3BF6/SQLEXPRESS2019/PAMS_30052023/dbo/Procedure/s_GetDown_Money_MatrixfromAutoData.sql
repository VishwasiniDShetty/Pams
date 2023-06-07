/****** Object:  Procedure [dbo].[s_GetDown_Money_MatrixfromAutoData]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************************************************
mod 1:-By Mrudula M. Rao on 01-feb-2010. For ER0210 Introduce PDT on 5150. 1) Handle PDT at Machine Level. 
***********************************************************************************************/

CREATE          PROCEDURE [dbo].[s_GetDown_Money_MatrixfromAutoData]
	@StartTime DateTime,
	@EndTime DateTime,
	@MachineID  varchar(50) = '',
	@DownID  varchar(8000) = '',
	@OperatorID  varchar(50) = '',
	@ComponentID  varchar(50) = '',
	@PlantID varchar(50) = '',
	@Excludedown int
AS
BEGIN
declare @strsql varchar(8000)
declare @strdown varchar(8000)
declare @strMachine varchar(255)
declare @strcomponent varchar(255)
declare @strOperator varchar(255)
Declare @StrPlant varchar(255)

-- Temporary Table
CREATE TABLE #DownTimeData
(
	MachineID nvarchar(50) NOT NULL,
	--McInterfaceid nvarchar(4),
	McInterfaceid nvarchar(50),
	McHrRate float,
	DownID nvarchar(50) NOT NULL,
	DownTime float,
	LostMoney float
	
)

ALTER TABLE #DownTimeData
	ADD PRIMARY KEY CLUSTERED
	(
		MachineId, DownID
	)ON [PRIMARY]

CREATE TABLE #FinalData
(
	MachineID nvarchar(50) NOT NULL,
	DownID nvarchar(50) NOT NULL,
	DownLoss float,
	--downfreq int,
	TotalMachine float,
	TotalDown float
	
)

ALTER TABLE #FinalData
	ADD PRIMARY KEY CLUSTERED
	(
		MachineId, DownID
	)ON [PRIMARY]


--mod 1:Table to get Planneddown times
Create table #PlannedMoneyDownTimes
(
	StartTime DateTime,
	EndTime DateTime,
	Machine nvarchar(50)
)
--mod 1
select @strsql = ''
select @StrPlant=''

IF ISNULL(@PlantID,'')<>''
BEGIN
 SELECT @StrPlant=' And PlantMachine.PlantID='''+ @PlantID +''''
END
Select @strsql = 'INSERT INTO #DownTimeData (MachineID,McInterfaceid,McHrRate, DownID, DownTime,LostMoney) 
		  SELECT Machineinformation.MachineID AS MachineID,Machineinformation.interfaceid,Machineinformation.mchrrate, downcodeinformation.downid AS DownID, 0,0 FROM Machineinformation CROSS JOIN downcodeinformation LEFT OUTER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '

if isnull(@downid, '') <> '' and isnull(@machineid,'') <> '' and @Excludedown=0
	begin
	select @strsql =  @strsql + ' where  downcodeinformation.downid in (' + @downid + ')'
	select @strsql =  @strsql + ' and ( machineinformation.machineid = ''' + @machineid + ''')'
	end
--change
if isnull(@downid, '') <> '' and isnull(@machineid,'') <> '' and @Excludedown=1
	begin
	select @strsql =  @strsql + ' where  downcodeinformation.downid not in (' + @downid + ')'
	select @strsql =  @strsql + ' and ( machineinformation.machineid = ''' + @machineid + ''')'
	end
--change
if isnull(@downid, '') <> '' and isnull(@machineid,'') = '' and @Excludedown=0
	begin
	select @strsql =  @strsql + ' where  downcodeinformation.downid in( ' + @downid + ' )'
	end
--change
if isnull(@downid, '') <> '' and isnull(@machineid,'') = '' and @Excludedown=1
	begin
	select @strsql =  @strsql + ' where  downcodeinformation.downid not in( ' + @downid + ')'
	end


if isnull(@downid, '') = '' and isnull(@machineid,'') <> ''
	begin
	select @strsql =  @strsql + ' where ( machineinformation.machineid = ''' + @machineid + ''')'
	end

select @strsql = @strsql + @StrPlant + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'
--print @strsql
exec (@strsql)
---select * from #DownTimeData
select @strdown = ''
select @strmachine = ''
select @stroperator = ''
select @strcomponent = ''

if isnull(@machineid, '') <> ''
	begin
	select @strmachine =  ' and ( Machineinformation.machineid = ''' + @machineid + ''')'
	end
if isnull(@componentid, '') <> ''
	begin
	select @strcomponent =  ' and ( componentinformation.componentid = ''' + @componentid + ''')'
	end
if isnull(@operatorid,'')  <> ''
	BEGIN
	select @stroperator = ' and ( employeeinformation.employeeid = ''' + @OperatorID +''')'
	END
if isnull(@downid,'')  <> '' and @Excludedown=0
	BEGIN
	select @strdown = ' and ( downcodeinformation.downid in (' + @Downid +'))'
	END
if isnull(@downid,'')  <> '' and @Excludedown=1
	BEGIN
	select @strdown = ' and ( downcodeinformation.downid not in (' + @Downid +'))'
	END

---mod 1
--Get Down Time Details
---Commented for mod 1 by Mrudula : Combine downtime calculation for all 4 types of record.
---Combine type 1,2,3,4
select @strsql = ''
select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) '
select @strsql = @strsql + ' FROM'
select @strsql = @strsql + ' (SELECT mc,count(mc)as dwnfrq,sum(case 
			   when autodata.sttime>='''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime,120)+''' then loadunload
			   when  autodata.sttime<'''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime,120)+''' then datediff(second,'''+convert(varchar(20),@StartTime,120)+''', ndtime)
			   When autodata.sttime>='''+convert(varchar(20),@starttime,120)+''' and autodata.sttime<'''+convert(varchar(20),@endtime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime,120)+''' then DateDiff(second, stTime, '''+convert(varchar(20),@Endtime,120)+''')
			   When autodata.sttime<'''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime,120)+''' then DateDiff(second, '''+convert(varchar(20),@StartTime,120)+''', '''+convert(varchar(20),@EndTime,120)+''')
			   END) as down,downcodeinformation.downid as downid'
select @strsql = @strsql + ' from'
select @strsql = @strsql + '  autodata INNER JOIN'
select @strsql = @strsql + ' machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID INNER JOIN'
select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'
select @strsql = @strsql + ' employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN'
select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
select @strsql = @strsql + ' where datatype=2 AND ((autodata.sttime>='''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime,120)+''') OR
			    (autodata.sttime<'''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime,120)+''') OR 
			     (autodata.sttime>='''+convert(varchar(20),@starttime,120)+''' and autodata.sttime<'''+convert(varchar(20),@endtime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime,120)+''') OR
			     (autodata.sttime<'''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime,120)+'''))'
select @strsql = @strsql  + @StrPlant + @strmachine + @strcomponent + @strdown --+ @stroperator
select @strsql = @strsql + ' group by autodata.mc,downcodeinformation.downid )'
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
--print @strsql
exec (@strsql)

if  (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN

	/* Planned Down times for the given time period at machine level*/
	 select @strsql=' Insert into #PlannedMoneyDownTimes(Machine,StartTime,EndTime)
		SELECT Machine,
		CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120) + ''' Then ''' + convert(nvarchar(20),@StartTime,120) + '''  Else StartTime End As StartTime,
		CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120) + '''  Then ''' + convert(nvarchar(20),@EndTime,120) + '''  Else EndTime End As EndTime
		FROM PlannedDownTimes
		WHERE (
		(StartTime >= ''' + convert(nvarchar(20),@StartTime,120) + '''  AND EndTime <=''' + convert(nvarchar(20),@EndTime,120) + ''') 
		OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120) + '''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120) + ''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120) + ''' )
		OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120) + '''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120) + ''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120) + ''' )
		OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120) + '''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120) + ''') ) and pdtstatus=1 '
		if isnull(@MachineID,'')<>''
		begin
			select @strsql=@strsql+' AND (PlannedDownTimes.machine =N'''+@MachineID+''') ' 
		ENd
		select @strsql=@strsql+' ORDER BY StartTime'
		--print @strsql
		exec (@strsql)

	--- deduct opvelapping PDT down from downtime.
	Select @strsql=''
	Select @strsql=	'UPDATE #DownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0) 
	FROM(
		SELECT autodata.MC,DownId, SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM AutoData 
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
		Inner jOIN #PlannedMoneyDownTimes T on T.Machine=machineinformation.MachineID 
		Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
		INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID 
		INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid 
		WHERE autodata.DataType=2  AND( 
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime) 
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) 
			)AND(
			(autodata.sttime >= '''+convert(varchar(20),@starttime,120)+'''  AND autodata.ndtime <='''+convert(varchar(20),@endtime,120)+''') 
			OR ( autodata.sttime < '''+convert(varchar(20),@starttime,120)+'''  AND autodata.ndtime <= '''+convert(varchar(20),@endtime,120)+''' AND autodata.ndtime > '''+convert(varchar(20),@starttime,120)+''' )
			OR ( autodata.sttime >= '''+convert(varchar(20),@starttime,120)+'''   AND autodata.sttime <'''+convert(varchar(20),@endtime,120)+''' AND autodata.ndtime > '''+convert(varchar(20),@endtime,120)+''' )
			OR ( autodata.sttime < '''+convert(varchar(20),@starttime,120)+'''  AND autodata.ndtime > '''+convert(varchar(20),@endtime,120)+''') )'
		Select @strsql = @strsql  + @StrPlant + @strmachine + @strcomponent + @strdown + @stroperator 
			
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
		BEGIN
			Select @strsql = @strsql  +' AND Downcodeinformation.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
		END

		Select @strsql=	@strsql + 'group by autodata.mc,DownId
			) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId
			Where #DownTimeData.DownTime>0'

		--print @strsql
		Exec (@strsql)
		

END
---mod 1

/*--TYPE1 i
select @strsql = ''
select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) '
--select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
select @strsql = @strsql + ' FROM'
select @strsql = @strsql + ' (SELECT mc,count(mc)as dwnfrq,sum(loadunload)as down,downcodeinformation.downid as downid'
select @strsql = @strsql + ' from'
select @strsql = @strsql + '  autodata INNER JOIN'
select @strsql = @strsql + ' machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID INNER JOIN'
select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'
select @strsql = @strsql + ' employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN'
select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
select @strsql = @strsql + ' where  autodata.sttime>='''+convert(varchar(20),@starttime)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' and datatype=2 '
select @strsql = @strsql  + @StrPlant + @strmachine + @strcomponent + @strdown --+ @stroperator
select @strsql = @strsql + ' group by autodata.mc,downcodeinformation.downid )'
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
exec (@strsql)

--TYPE2
select @strsql = ''
select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0) '
--select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
select @strsql = @strsql+' FROM'
select @strsql = @strsql+' (SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, '''+convert(varchar(20),@StartTime)+''', ndtime))as down,downcodeinformation.downid as downid'
select @strsql = @strsql+' from'
select @strsql=@strsql+'  autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
select @strsql=@strsql+' where  autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' and datatype=2'
select @strsql = @strsql  + @StrPlant + @strmachine + @strcomponent + @strdown + @stroperator
select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'
select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
exec (@strsql)
--TYPE3
select @strsql = ''
select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0) '
--select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
select @strsql = @strsql+' FROM'
select @strsql = @strsql+' (SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, stTime, '''+convert(varchar(20),@Endtime)+'''))as down,downcodeinformation.downid as downid'
select @strsql = @strsql+' from'
select @strsql = @strsql+'  autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
select @strsql=@strsql+' where  autodata.sttime>='''+convert(varchar(20),@starttime)+'''and autodata.sttime<'''+convert(varchar(20),@endtime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''' and datatype=2'
select @strsql = @strsql  + @StrPlant + @strmachine + @strcomponent + @strdown + @stroperator
select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'
select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
exec (@strsql)
--TYPE4
select @strsql = ''
select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0) '
--select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
select @strsql = @strsql+' FROM'
select @strsql = @strsql+' (SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, '''+convert(varchar(20),@StartTime)+''', '''+convert(varchar(20),@EndTime)+'''))as down,downcodeinformation.downid as downid'
select @strsql = @strsql+' from'
select @strsql = @strsql+'  autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID  INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
select @strsql=@strsql+' where  autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''' and datatype=2'
select @strsql = @strsql  + @StrPlant+@strmachine + @strcomponent + @strdown + @stroperator
select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'
select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
exec (@strsql)*/

update #DownTimeData set LostMoney=((downtime/3600)*McHrRate)

exec (@strsql)
---select * from #DownTimeData
INSERT INTO #FinalData (MachineID, DownID, DownLoss, TotalMachine, TotalDown)
	select MachineID, DownID, LostMoney,0,0
	from #DownTimeData
UPDATE #FinalData
SET

TotalMachine =(SELECT SUM(DownLoss) FROM #FinalData as FD WHERE Fd.machineID = #FinalData.machineid),
TotalDown = (SELECT SUM(DownLoss) FROM #FinalData as FD WHERE Fd.DownID = #FinalData.DownID)

select 	MachineID,
	#FinalData.DownID as DownCode,
	DownDescription as DownID,
	downLoss as downLoss,
	TotalMachine as TotalMachine,
	TotalDown as TotalDown,
	@StartTime as StartTime,
	@EndTime as EndTime
	
FROM #FinalData
INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid
WHERE (TotalDown > 0) and (TotalMachine > 0)
Order By  TotalDown desc,downcodeinformation.DownID, TotalMachine desc, machineid

END
