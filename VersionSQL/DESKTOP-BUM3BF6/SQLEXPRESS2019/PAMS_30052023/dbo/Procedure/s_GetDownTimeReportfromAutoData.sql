/****** Object:  Procedure [dbo].[s_GetDownTimeReportfromAutoData]    Committed by VersionSQL https://www.versionsql.com ******/

/*
Used in S_GetComparisionReports
--Created by: SangeetaKallur 28/09/2005
--Introduced for Comparison reports, Time axis - Shift or Day
--Altered by Mrudula to include @Exclude
Procedure Altered By SSK on 06-Dec-2006 :
	To Remove Constraint Name and adding it by Primary Key
mod 1 :- ER0182 By Kusuma M.H on 16-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
mod 2:-By Mrudula M. Rao on 01-feb-2010. For ER0210 Introduce PDT on 5150. 1) Handle PDT at Machine Level. 
*/
CREATE           PROCEDURE [dbo].[s_GetDownTimeReportfromAutoData]
	@StartTime DateTime,
	@EndTime DateTime,
	@MachineID  nvarchar(50) = '',
	---mod 1
---Replaced varchar with nvarchar to support unicode characters.
--	@DownID  varchar(8000) = '',
	@DownID  nvarchar(4000) = '',
	---mod 1
	@OperatorID  nvarchar(50) = '',
	@ComponentID  nvarchar(50) = '',
	@MachineIDLabel nvarchar(50) = 'ALL',
	@OperatorIDLabel nvarchar(50) = 'ALL',
	@DownIDLabel nvarchar(50) = 'ALL',
	@ComponentIDLabel nvarchar(50) = 'ALL',
	@ReportType nvarchar(20) = '',
	@PlantID nvarchar(50) = '',
	@Exclude int
AS
BEGIN
---mod 1
---Replaced varchar with nvarchar to support unicode characters.
--declare @strsql varchar(8000)
--declare @strdown varchar(8000)
declare @strsql nvarchar(4000)
declare @strdown nvarchar(4000)
---mod 1
declare @strMachine nvarchar(255)
declare @strcomponent nvarchar(255)
declare @strOperator nvarchar(255)
declare @strPlantID nvarchar(100)

---mod 2
DECLARE @StrPLD_DownId NVARCHAR(2000)
--mod 2

-- Temporary Table
CREATE TABLE #DownTimeData
(
	MachineID nvarchar(50)  PRIMARY KEY ,
	McInterfaceid nvarchar(4),
	DownTime float DEFAULT(0),
	DownFreq int DEFAULT(0)
	--CONSTRAINT downtimedata_key PRIMARY KEY (MachineId)
)

--mod 2:Table to get Planneddown times
Create table #PlannedDownTimes_auto
(
	StartTime DateTime,
	EndTime DateTime,
	Machine nvarchar(50)
)
--mod 2

select @strdown = ''
select @strmachine = ''
select @stroperator = ''
select @strcomponent = ''
select @strPlantID = ''

---mod 2
SELECT @StrPLD_DownId=''

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
BEGIN
	SELECT @StrPLD_DownId=' AND Downcodeinformation.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
END
---mod 2

if isnull(@machineid, '') <> ''
	begin
	---mod 1
--	select @strmachine =  ' and ( Machineinformation.machineid = ''' + @machineid + ''')'
	select @strmachine =  ' and ( Machineinformation.machineid = N''' + @machineid + ''')'
	---mod 1
	end
if isnull(@componentid, '') <> ''
	begin
	---mod 1
--	select @strcomponent =  ' and ( componentinformation.componentid = ''' + @componentid + ''')'
	select @strcomponent =  ' and ( componentinformation.componentid = N''' + @componentid + ''')'
	---mod 1
	end
if isnull(@operatorid,'')  <> ''
	BEGIN
	---mod 1
--	select @stroperator = ' and ( employeeinformation.employeeid = ''' + @OperatorID +''')'
	select @stroperator = ' and ( employeeinformation.employeeid = N''' + @OperatorID +''')'
	---mod 1
	END
if isnull(@downid,'')  <> '' and @Exclude=0
	BEGIN
	select @strdown = ' and ( downcodeinformation.downid in ( '+ @Downid +'))'
	END
if isnull(@downid,'')  <> '' and @Exclude=1
	BEGIN
	select @strdown = ' and ( downcodeinformation.downid not in ( '+ @Downid +'))'
	END
if isnull(@PlantID,'') <> ''
BEGIN
	---mod 1
--	SELECT @strPlantID = ' AND ( PlantMachine.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( PlantMachine.PlantID = N''' + @PlantID+ ''')'
	---mod 1
END
select @strsql = ''
select @strsql = 'INSERT INTO #DownTimeData (MachineID,McInterfaceid, DownTime,DownFreq)
			SELECT Machineinformation.MachineID,Machineinformation.interfaceid, 0,0 FROM Machineinformation
			LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
			WHERE Machineinformation.interfaceid > ''0'''
select @strsql = @strsql + @strPlantID + @strmachine + ' ORDER BY  Machineinformation.MachineID'
exec (@strsql)

--Get Down Time Details
--mod 2
--TYPE 1,2,3,4:Combine all 4 types.
select @strsql = ''
select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) , '
select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
select @strsql = @strsql + ' FROM'
select @strsql = @strsql + ' (SELECT A.mc, COUNT(A.mc) AS dwnfrq,
			SUM(CASE
			WHEN ( A.sttime>='''+convert(varchar(20),@starttime,120)+''' and A.ndtime<='''+convert(varchar(20),@endtime,120)+''')   THEN A.loadunload
			WHEN (A.sttime<'''+convert(varchar(20),@starttime,120)+''' and A.ndtime>'''+convert(varchar(20),@starttime,120)+'''and A.ndtime<='''+convert(varchar(20),@endtime,120)+''') THEN DateDiff(second, '''+convert(varchar(20),@StartTime,120)+''', ndtime)
			WHEN (A.sttime>='''+convert(varchar(20),@starttime,120)+'''and A.sttime<'''+convert(varchar(20),@endtime,120)+''' and A.ndtime>'''+convert(varchar(20),@endtime,120)+''') THEN DateDiff(second, stTime, '''+convert(varchar(20),@Endtime,120)+''')
			ELSE DateDiff(second, '''+convert(varchar(20),@StartTime,120)+''', '''+convert(varchar(20),@EndTime,120)+''') END )AS down
		      FROM    autodata A INNER JOIN
                      machineinformation ON A.mc = machineinformation.InterfaceID INNER JOIN
                      componentinformation ON A.comp = componentinformation.InterfaceID INNER JOIN
                      employeeinformation ON A.opr = employeeinformation.interfaceid INNER JOIN
                      downcodeinformation ON A.dcode = downcodeinformation.interfaceid LEFT OUTER JOIN
                      PlantMachine ON machineinformation.machineid = PlantMachine.MachineID LEFT OUTER JOIN
                      PlantEmployee ON employeeinformation.Employeeid = PlantEmployee.employeeID '
select @strsql = @strsql + ' where datatype=2 AND (
			( A.sttime>='''+convert(varchar(20),@starttime,120)+''' and A.ndtime<='''+convert(varchar(20),@endtime,120)+''')  
			OR(A.sttime<'''+convert(varchar(20),@starttime,120)+''' and A.ndtime>'''+convert(varchar(20),@starttime,120)+'''and A.ndtime<='''+convert(varchar(20),@endtime,120)+''')
			OR(A.sttime>='''+convert(varchar(20),@starttime,120)+'''and A.sttime<'''+convert(varchar(20),@endtime,120)+''' and A.ndtime>'''+convert(varchar(20),@endtime,120)+''')
			OR(A.sttime<'''+convert(varchar(20),@starttime,120)+''' and A.ndtime>'''+convert(varchar(20),@endtime,120)+'''))'
select @strsql = @strsql  + @strmachine + @strcomponent + @strdown + @stroperator + @strPlantID 
select @strsql = @strsql + ' group by A.mc)'
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid'
exec (@strsql)

if  (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN

	/* Planned Down times for the given time period at machine level*/
	 select @strsql=' Insert into #PlannedDownTimes_auto(Machine,StartTime,EndTime)
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
		exec (@strsql)

	Select @strsql=''
	Select @strsql=	'UPDATE #DownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0) 
		FROM(
			SELECT autodata.MC, SUM
			       (CASE
				WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PPDT
			FROM AutoData 
			INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
			INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			INNER JOIN #PlannedDownTimes_auto T on T.Machine=machineinformation.MachineId
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
	Select @strsql = @strsql  + @strPlantID + @strmachine + @strcomponent + @strdown + @stroperator + @StrPLD_DownId
	Select @strsql=	@strsql + 'group by autodata.mc
		) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid 
		Where #DownTimeData.DownTime>0'
	Exec (@strsql)
	
	---neglecting only type 1 records to PDT from frequency calculation.
	IF @reportType = 'DTime'
	BEGIN
		Select @strsql=''
		Select @strsql=	'UPDATE #DownTimeData set Downfreq = isnull(Downfreq,0) - isNull(TT.Freq ,0) 
			FROM(
				SELECT autodata.MC, Count(*)As Freq
				FROM AutoData CROSS jOIN #PlannedDownTimes_auto T
				INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
				INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
				Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
				INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID 
				INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid 
				WHERE autodata.DataType=2  
				AND (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime) 
				AND (autodata.sttime >= '''+convert(varchar(20),@starttime,120)+'''  AND autodata.ndtime <='''+convert(varchar(20),@endtime,120)+''') '
		Select @strsql = @strsql  + @strPlantID + @strmachine + @strcomponent + @strdown + @stroperator + @StrPLD_DownId
		Select @strsql=	@strsql + 'group by autodata.mc
			) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid '
	 	Exec (@strsql)
	END
END
--mod 2


/*Commented seperate calculations for different data types.
--TYPE1
select @strsql = ''
select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) , '
select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
select @strsql = @strsql + ' FROM'
select @strsql = @strsql + ' (SELECT autodata.mc, COUNT(autodata.mc) AS dwnfrq, SUM(autodata.loadunload) AS down
			     FROM         autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid LEFT OUTER JOIN
PlantMachine ON machineinformation.machineid = PlantMachine.MachineID LEFT OUTER JOIN
PlantEmployee ON employeeinformation.Employeeid = PlantEmployee.employeeID '
select @strsql = @strsql + ' where  autodata.sttime>='''+convert(varchar(20),@starttime)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' and datatype=2'
select @strsql = @strsql  + @strmachine + @strcomponent + @strdown + @stroperator + @strPlantID
select @strsql = @strsql + ' group by autodata.mc)'
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid'
exec (@strsql)
--TYPE2
select @strsql = ''
select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0),'
select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
select @strsql = @strsql+' FROM'
select @strsql = @strsql+' (SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, '''+convert(varchar(20),@StartTime)+''', ndtime))as down'
select @strsql = @strsql+' FROM         autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid LEFT OUTER JOIN
PlantMachine ON machineinformation.machineid = PlantMachine.MachineID LEFT OUTER JOIN
PlantEmployee ON employeeinformation.Employeeid = PlantEmployee.employeeID '
select @strsql=@strsql+' where  autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' and datatype=2'
select @strsql = @strsql  + @strmachine + @strcomponent + @strdown + @stroperator + @strPlantID
select @strsql=@strsql+' group by autodata.mc)'
select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid'
exec (@strsql)
--TYPE3
select @strsql = ''
select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0),'
select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
select @strsql = @strsql+' FROM'
select @strsql = @strsql+' (SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, stTime, '''+convert(varchar(20),@Endtime)+'''))as down'
select @strsql = @strsql+' FROM         autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid LEFT OUTER JOIN
PlantMachine ON machineinformation.machineid = PlantMachine.MachineID LEFT OUTER JOIN
PlantEmployee ON employeeinformation.Employeeid = PlantEmployee.employeeID '
select @strsql=@strsql+' where  autodata.sttime>='''+convert(varchar(20),@starttime)+'''and autodata.sttime<'''+convert(varchar(20),@endtime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''' and datatype=2'
select @strsql = @strsql  + @strmachine + @strcomponent + @strdown + @stroperator + @strPlantID
select @strsql=@strsql+' group by autodata.mc)'
select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid'
exec (@strsql)
--TYPE4
select @strsql = ''
select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0),'
select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
select @strsql = @strsql+' FROM'
select @strsql = @strsql+' (SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, '''+convert(varchar(20),@StartTime)+''', '''+convert(varchar(20),@EndTime)+'''))as down'
select @strsql = @strsql+' FROM         autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid LEFT OUTER JOIN
PlantMachine  ON machineinformation.machineid = PlantMachine.MachineID LEFT OUTER JOIN
PlantEmployee ON employeeinformation.Employeeid = PlantEmployee.employeeID '
select @strsql=@strsql+' where  autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''' and datatype=2'
select @strsql = @strsql  + @strmachine + @strcomponent + @strdown + @stroperator + @strPlantID
select @strsql=@strsql+' group by autodata.mc)'
select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid'
exec (@strsql)

*/
if @reportType = 'DTime'
	begin
	  select @StartTime as StartTime,
		@EndTime as EndTime,
		sum(DownTime) as DownTime,
		sum(DownFreq) as DownFreq,
		dbo.f_FormatTime(sum(DownTime),'hh:mm:ss') as FmtDownTime,
		@MachineIDLabel as MachineIDLabel ,
		@OperatorIDLabel  as OperatorIDLabel,
		@DownIDLabel  as DownIDLabel ,
		@ComponentIDLabel as ComponentIDLabel
	   FROM #DownTimeData
	end
Else if @reportType='DTimeOnly'
	begin
	  select @StartTime as StartTime,
		@EndTime as EndTime,
		sum(DownTime) as DownTime
		--sum(DownFreq) as DownFreq,
		--dbo.f_FormatTime(sum(DownTime),'hh:mm:ss') as FmtDownTime,
		--@MachineIDLabel as MachineIDLabel ,
		--@OperatorIDLabel  as OperatorIDLabel,
		--@DownIDLabel  as DownIDLabel ,
		--@ComponentIDLabel as ComponentIDLabel
	   FROM #DownTimeData
	end
end
