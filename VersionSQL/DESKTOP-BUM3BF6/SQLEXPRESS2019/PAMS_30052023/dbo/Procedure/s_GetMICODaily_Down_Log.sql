/****** Object:  Procedure [dbo].[s_GetMICODaily_Down_Log]    Committed by VersionSQL https://www.versionsql.com ******/

/*****************************************************************************************************
Used in SM_MICO_DailyDownLog.rpt
mod 1:-for DR0167 by Mrudula M. Rao on 28-feb-2009.Error detected by database dll. When plant is selected
mod 2 :- ER0181 By Kusuma M.H on 08-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 3 :- ER0182 By Kusuma M.H on 08-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
ER0210 By Karthikg on 22/Feb/2010 :: Introduce PDT on 5150. Handle PDT at Machine Level. 
s_GetMICODaily_Down_Log '01-dec-2009','MCV 400','','',''
*******************************************************************************************************/
CREATE           Procedure [dbo].[s_GetMICODaily_Down_Log]
	@StartDate Datetime,
	@MachineID nvarchar(50),
	@ComponentID  nvarchar(50) = '',
	@OperationNo  nvarchar(50) = '',
	@PlantID nvarchar(50)=''
As
Begin

Create table #ShiftDetails(
	PDate smalldatetime,
	shiftName nvarchar(20),
	shiftStart datetime,
	shiftEnd datetime
)

create table #DownTimeData
(
StartTime datetime,
EndTime datetime,
machineid nvarchar(50),
McInterfaceid nvarchar(50),
downid nvarchar(50),
DownDescription nvarchar(50),
downtime float,
TotalDown float
--StdSetup float,
--SetupEff float
)
--ER0210
create table #PlannedDownTimesDown
(	
	Machine nvarchar(50),
	StartTime datetime,
	EndTime datetime
)
--ER0210

insert into #ShiftDetails(Pdate,shiftName,shiftStart,shiftEnd)
	EXEC s_GetShiftTime @StartDate
declare @strmachine nvarchar(255)
declare @strPlantID nvarchar(255)
declare @strsql nvarchar(4000)
SET @strPlantID = ''
set @strmachine=''
If isnull(@MachineID,'') <> ''
BEGIN
	---mod 3
--	SELECT @strmachine = ' AND ( M.machineid = ''' + @MachineID+ ''')'
	SELECT @strmachine = ' AND ( M.machineid = N''' + @MachineID+ ''')'
	---mod 3
END
if isnull(@PlantID,'') <> ''
BEGIN
	---mod 1
	---SELECT @strPlantID = ' AND ( P.PlantID = ''' + @PlantID+ ''')'
	---mod 3
--	SELECT @strPlantID = ' AND ( PlantMachine.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( PlantMachine.PlantID = N''' + @PlantID+ ''')'
	---mod 3
	---mod 1
END
Declare TmplogCursorDwn Cursor For SELECT Pdate,shiftName,shiftStart,shiftEnd  from #ShiftDetails order by ShiftStart ASc
Declare @CurShift as nvarchar(50)
Declare @CurStart as datetime
Declare @CurEnd as datetime
Declare @PrevShift as nvarchar(50)
Declare @Counter as datetime
Declare @curstarttime as datetime
Declare @curendtime as datetime
Declare @Prevend as datetime
Declare @PrevStart as datetime
Declare @DiffTime as int
Declare @CurDate as datetime
select @PrevStart=Getdate()
select @Prevend=@PrevStart
OPEN TmplogCursorDwn
FETCH NEXT FROM TmplogCursorDwn INTO @CurDate,@CurShift,@CurStart,@CurEnd
WHILE @@FETCH_STATUS = 0
	BEGIN	
		select @Counter=@CurStart
		While (@Counter<@CurEnd)
		BEGIN
			SELECT @curstarttime=@counter
			if isnull(@Prevend,'')<>'' and isnull(@PrevStart,'')<>''
				Begin
				    if datediff(second,@PrevStart,@Prevend)<3600
				    Begin
					select @DiffTime=datediff(second,@PrevStart,@Prevend)
					select @curendtime=Dateadd(second,3600+(3600-@DiffTime),@counter)
				    END
				    Else
				    BEGIN
					 SELECT @curendtime=DATEADD(Second,3600,@counter)
				    END
				end
			--SELECT @curendtime=DATEADD(Second,3600,@counter)
			if @curendtime >= @CurEnd
			Begin
				set @curendtime = @CurEnd
			end
			
			if datediff(second,@curstarttime,@curendtime)>3600
			BEGIN
				select @curendtime=dateadd(second,-((datediff(second,@curstarttime,@curendtime))-3600),@curendtime)
			END
				Select @strsql=''
				Select @strsql = 'INSERT INTO #DownTimeData (StartTime,EndTime,MachineID,McInterfaceid, DownID, DownTime)
			 			 SELECT '''+convert(nvarchar(20),@curstarttime,20)+''','''+convert(nvarchar(20),@curendtime)+''',Machineinformation.MachineID AS MachineID,Machineinformation.interfaceid, downcodeinformation.downid AS DownID, 0
						 FROM Machineinformation CROSS JOIN downcodeinformation LEFT OUTER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '
				
				if isnull(@machineid,'') <> ''
				begin
				---mod 3
--				select @strsql =  @strsql + ' where ( machineinformation.machineid = ''' + @machineid + ''')'
				select @strsql =  @strsql + ' where ( machineinformation.machineid = N''' + @machineid + ''')'
				---mod 3
				end
			
				select @strsql = @strsql + @strPlantID + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'
	
				Exec (@strsql)
				
--ER0210 From Here
/*
				--Get Down Time Details
				--TYPE1 i
				select @strsql = ''
				select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) '
				--select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
				select @strsql = @strsql + ' FROM'
				select @strsql = @strsql + ' (SELECT mc,sum(loadunload)as down,downcodeinformation.downid as downid'
				select @strsql = @strsql + ' from'
				select @strsql = @strsql + '  autodata INNER JOIN'
				select @strsql = @strsql + ' machineinformation M ON autodata.mc = M.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID INNER JOIN'
				select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'
				select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
				select @strsql = @strsql + ' where  autodata.sttime>='''+convert(varchar(20),@curstarttime,20)+''' and autodata.ndtime<='''+convert(varchar(20),@curendtime,20)+''' and datatype=2 '
				select @strsql = @strsql  + @strmachine + @StrPlantID
				select @strsql = @strsql + ' group by autodata.mc,downcodeinformation.downid )'
				select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid '
				select @strsql = @strsql + ' where #DownTimeData.StartTime='''+convert(nvarchar(20),@curstarttime)+''' and #DownTimeData.EndTime= '''+convert(nvarchar(20),@curendtime)+''' '
				exec (@strsql)
--				print (@strsql)
				
				--TYPE2
				select @strsql = ''
				select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0)'
				--select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
				select @strsql = @strsql+' FROM'
				select @strsql = @strsql+' (SELECT mc,sum(DateDiff(second, '''+convert(varchar(20),@curstarttime,20)+''', ndtime))as down,downcodeinformation.downid as downid'
				select @strsql = @strsql+' from'
				select @strsql=@strsql+'  autodata INNER JOIN
				machineinformation  M ON autodata.mc = M.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID INNER JOIN
				componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
				downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
				select @strsql=@strsql+' where  autodata.sttime<'''+convert(varchar(20),@curstarttime,20)+''' and autodata.ndtime>'''+convert(varchar(20),@curstarttime,20)+'''and autodata.ndtime<='''+convert(varchar(20),@curendtime,20)+''' and datatype=2'
				select @strsql = @strsql   + @strmachine+ @StrPlantID
				select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'
				select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
				select @strsql = @strsql + ' where #DownTimeData.StartTime='''+convert(nvarchar(20),@curstarttime)+''' and #DownTimeData.EndTime= '''+convert(nvarchar(20),@curendtime)+''' '
				exec (@strsql)
--				print (@strsql)
	
				--TYPE3
				select @strsql = ''
				select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0)'
				--select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
				select @strsql = @strsql+' FROM'
				select @strsql = @strsql+' (SELECT mc,sum(DateDiff(second, stTime, '''+convert(varchar(20),@curendtime)+'''))as down,downcodeinformation.downid as downid'
				select @strsql = @strsql+' from'
				select @strsql = @strsql+'  autodata INNER JOIN
				machineinformation  M ON autodata.mc = M.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID INNER JOIN
				componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
				employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
				downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
				select @strsql=@strsql+' where  autodata.sttime>='''+convert(varchar(20),@curstarttime)+'''and autodata.sttime<'''+convert(varchar(20),@curendtime)+''' and autodata.ndtime>'''+convert(varchar(20),@curendtime)+''' and datatype=2'
				select @strsql = @strsql  + @strmachine+ @StrPlantID
				select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'
				select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
				select @strsql = @strsql + ' where #DownTimeData.StartTime='''+convert(nvarchar(20),@curstarttime)+''' and #DownTimeData.EndTime= '''+convert(nvarchar(20),@curendtime)+''' '
				exec (@strsql)
--				print (@strsql)
	
				--TYPE4
				select @strsql = ''
				select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0)'
				--select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
				select @strsql = @strsql+' FROM'
				select @strsql = @strsql+' (SELECT mc,sum(DateDiff(second, '''+convert(varchar(20),@curstarttime)+''', '''+convert(varchar(20),@curendtime)+'''))as down,downcodeinformation.downid as downid'
				select @strsql = @strsql+' from'
				select @strsql = @strsql+'  autodata INNER JOIN
				machineinformation M ON autodata.mc = M.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID  INNER JOIN
				componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
				employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
				downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
				select @strsql=@strsql+' where  autodata.sttime<'''+convert(varchar(20),@curstarttime)+''' and autodata.ndtime>'''+convert(varchar(20),@curendtime)+''' and datatype=2'
				select @strsql = @strsql  +@strmachine + @StrPlantID
				select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'
				select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
				select @strsql = @strsql + ' where #DownTimeData.StartTime='''+convert(nvarchar(20),@curstarttime)+''' and #DownTimeData.EndTime='''+convert(nvarchar(20),@curendtime)+''' '
				exec (@strsql)
--				print (@strsql)
*/
				--Get Down Time Details
				--TYPE1 1,2,3,4
				select @strsql = ''
				select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) '
				select @strsql = @strsql + ' FROM'
				select @strsql = @strsql + ' (SELECT mc,sum(case 
							      When autodata.sttime>='''+convert(varchar(20),@curstarttime,120)+''' and autodata.ndtime<='''+convert(varchar(20),@curendtime,120)+''' then  loadunload
							      When autodata.sttime<'''+convert(varchar(20),@curstarttime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@curstarttime,120)+'''and autodata.ndtime<='''+convert(varchar(20),@curendtime,120)+''' then DateDiff(second, '''+convert(varchar(20),@curstarttime,120)+''', ndtime) 
							      When autodata.sttime>='''+convert(varchar(20),@curstarttime,120)+'''and autodata.sttime<'''+convert(varchar(20),@curendtime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@curendtime,120)+''' then  DateDiff(second, stTime, '''+convert(varchar(20),@curendtime,120)+''') 
							      When autodata.sttime<'''+convert(varchar(20),@curstarttime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@curendtime,120)+''' then DateDiff(second, '''+convert(varchar(20),@curstarttime,120)+''', '''+convert(varchar(20),@curendtime,120)+''') end )as down,downcodeinformation.downid as downid'
		 		select @strsql = @strsql + ' from'
				select @strsql = @strsql + '  autodata INNER JOIN'
				select @strsql = @strsql + ' machineinformation M ON autodata.mc = M.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID INNER JOIN'
				---select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'
				select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
				select @strsql = @strsql + ' where datatype=2 AND ((autodata.sttime>='''+convert(varchar(20),@curstarttime,20)+''' and autodata.ndtime<='''+convert(varchar(20),@curendtime,120)+''') 
							     OR (autodata.sttime<'''+convert(varchar(20),@curstarttime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@curstarttime,120)+'''and autodata.ndtime<='''+convert(varchar(20),@curendtime,120)+''') 
							     OR (autodata.sttime>='''+convert(varchar(20),@curstarttime,120)+'''and autodata.sttime<'''+convert(varchar(20),@curendtime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@curendtime,120)+''') 
							     OR (autodata.sttime<'''+convert(varchar(20),@curstarttime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@curendtime,120)+''') ) '
				If isnull(@MachineID,'') <> ''
				BEGIN
					select @strsql = @strsql  + ' AND ( M.machineid = N''' + @MachineID+ ''')'
				END
				select @strsql = @strsql  + @StrPlantID 
				select @strsql = @strsql + ' group by autodata.mc,downcodeinformation.downid )'
				select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid '
				select @strsql = @strsql + ' where #DownTimeData.StartTime='''+convert(nvarchar(20),@curstarttime,120)+''' and #DownTimeData.EndTime= '''+convert(nvarchar(20),@curendtime,120)+''' '
				exec (@strsql)
				print (@strsql)


			if  (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
			BEGIN
				insert into #PlannedDownTimesDown(Machine,StartTime,EndTime)  
				select Machine,
				CASE When StartTime<@CurStarttime Then @CurStarttime Else StartTime End,
				case When EndTime>@CurEndtime Then @CurEndtime Else EndTime End 
				FROM PlannedDownTimes
				WHERE PDTstatus = 1 and 
				((StartTime >= @CurStarttime  AND EndTime <=@CurEndtime) 
				OR ( StartTime < @CurStarttime  AND EndTime <= @CurEndtime AND EndTime > @CurStarttime )
				OR ( StartTime >= @CurStarttime   AND StartTime <@CurEndtime AND EndTime > @CurEndtime )
				OR ( StartTime < @CurStarttime  AND EndTime > @CurEndtime))
				And machine in (Select distinct machineID from #DownTimeData)
				ORDER BY StartTime

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
					FROM AutoData CROSS jOIN #PlannedDownTimesDown T
					INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
					INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
					Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
					WHERE autodata.DataType=2  AND T.Machine = machineinformation.MachineID AND
						((autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime) 
						OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
						OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
						OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) 
						)AND(
						(autodata.sttime >= '''+convert(varchar(20),@curstarttime,120)+'''  AND autodata.ndtime <='''+convert(varchar(20),@curendtime,120)+''') 
						OR ( autodata.sttime < '''+convert(varchar(20),@curstarttime,120)+'''  AND autodata.ndtime <= '''+convert(varchar(20),@curendtime,120)+''' AND autodata.ndtime > '''+convert(varchar(20),@curstarttime,120)+''' )
						OR ( autodata.sttime >= '''+convert(varchar(20),@curstarttime,120)+'''   AND autodata.sttime <'''+convert(varchar(20),@curendtime,120)+''' AND autodata.ndtime > '''+convert(varchar(20),@curendtime,120)+''' )
						OR ( autodata.sttime < '''+convert(varchar(20),@curstarttime,120)+'''  AND autodata.ndtime > '''+convert(varchar(20),@curendtime,120)+''') )'

					If isnull(@MachineID,'') <> ''
					BEGIN
						select @strsql = @strsql  + ' AND ( machineinformation.machineid = N''' + @MachineID+ ''')'
					END
					Select @strsql = @strsql  +  @StrPlantID 
						
					If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
					BEGIN
						Select @strsql = @strsql  +' AND Downcodeinformation.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
					END
			
					Select @strsql=	@strsql + 'group by autodata.mc,DownId
						) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId
						Where #DownTimeData.DownTime>0'
					Exec (@strsql)

					delete from #PlannedDownTimesDown

			END
--ER0210 Till Here




				select @PrevStart=@curstarttime
				select @Prevend=@curendtime
				select @Counter=dateadd(second,3600,@Counter)
		END
		FETCH NEXT FROM TmplogCursorDwn INTO @CurDate,@CurShift,@CurStart,@CurEnd
	END
close TmplogCursorDwn
deallocate TmplogCursorDwn

update #DownTimeData set DownTime=DownTime/60
update #DownTimeData set TotalDown = (SELECT SUM(DownTime) FROM #DownTimeData as FD WHERE Fd.DownID = #DownTimeData.DownID)
---OutPut
select StartTime,
	EndTime ,
	Cast(CAST(YEAR(StartTime)as nvarchar(4))+CAST(Month(StartTime)as nvarchar(2))+CAST(Day(StartTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,StartTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,StartTime)as nvarchar(2)) ELSE cast(datepart(hh,StartTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,StartTime)as nvarchar))=2 THEN '0'+cast(datepart(n,StartTime)as nvarchar(2)) ELSE cast(datepart(n,StartTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,EndTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,EndTime)as nvarchar(2)) ELSE cast(datepart(hh,EndTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,EndTime)as nvarchar))=2 THEN '0'+cast(datepart(n,EndTime)as nvarchar(2)) ELSE cast(datepart(n,EndTime)as nvarchar(2))END  as NVarchar(50)) as Shift,
	machineid ,
	#DownTimeData.downid ,
	D.Downdescription as descrdown,
	downtime ,
	TotalDown from #DownTimeData INNER JOIN Downcodeinformation D ON #DownTimeData.downid=D.DownID
	where TotalDown>0  Group by #DownTimeData.downid,D.Downdescription ,machineid,StartTime,EndTime,downtime,TotalDown --order by StartTime asc--,TotalDown asc
END	
