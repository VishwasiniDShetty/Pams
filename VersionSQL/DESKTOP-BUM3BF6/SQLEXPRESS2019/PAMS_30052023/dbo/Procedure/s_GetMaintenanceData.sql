/****** Object:  Procedure [dbo].[s_GetMaintenanceData]    Committed by VersionSQL https://www.versionsql.com ******/

/*
Procedure Created By Sangeeta Kallur on 08 Jan-2007 .
To calculate Maintenance Parameters ie
	MTBF - Mean Time Between Failure
	MTTR - Mean Time To Repair
	MTTA - Mean Time To Access
mod 1 :- ER0182 By Kusuma M.H on 28-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
ER0210 By Karthikg on 08/Feb/2010 :: Introduce PDT on 5150. Handle PDT at Machine Level. 
DR0340 - SwathiKS - 28/Feb/2014 :: To handle Negative MTTR Values while handling PDT interaction.
s_GetMaintenanceData '2014-02-01 06:30:00 AM','2014-02-27 06:30:00 AM','Plantwise','Break down','','','Win Chennai - SCP'
*/
CREATE   PROCEDURE [dbo].[s_GetMaintenanceData]
	@StartTime Datetime ,
	@EndTime Datetime ,
	@Parameter Nvarchar(15),--@Parameter={'MachineWise' OR 'PlantWise' OR 'CellWise'}
	@DownID Nvarchar(50) = '',	
	@MachineID Nvarchar(50) = '',
	@CellID Nvarchar(50) = '',
	@PlantID Nvarchar(50)=''
AS
BEGIN
Declare @timeformat as Nvarchar(2000)
Declare @strDownID as Nvarchar(100)
Declare @strSql as nvarchar(4000)
Select @strDownID = ''
Select @timeformat ='ss'
Declare @StrPLD_DownId as Nvarchar(200)
Select @strSql=''
SELECT @StrPLD_DownId=''

--ER0210
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
BEGIN
	SELECT @StrPLD_DownId=' AND D.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'') '
END
--ER0210

if isnull(@DownID,'')<> ''
Begin
	---mod 1
--	Select @strDownID = ' AND D.DownID = ''' + @DownID + ''''
	Select @strDownID = ' AND D.DownID = N''' + @DownID + ''' '
	---mod 1
End
Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
If (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
	Select @timeformat = 'ss'
End
	Create Table #MParam
	(
		SlNo Int IDENTITY(1,1),
		MachineID  Nvarchar(50),
		CellID Nvarchar(50),
		PlantID Nvarchar(50),
		DownID Nvarchar(50),
		StartTime Datetime,
		EndTime Datetime,
		MTTR BigInt DEFAULT 0,
		MTBF BigInt DEFAULT 0
	)
	Create Table #TempMParam
	(
		SlNo Int ,
		MachineID Nvarchar(50),
		DownID Nvarchar(50),
		StartTime Datetime
	)
	Create Table #OutPut
	(
		MachineID Nvarchar(50),
	        DownID Nvarchar(50),
		MTTR BigInt,
		MTBF BigInt,
		baseMTTR BigInt,	
		baseMTBF BigInt
	)

	IF @Parameter='MachineWise'
	BEGIN
		Select @strSql='Insert Into #MParam(MachineID,DownID,StartTime,EndTime,MTTR)
		Select M.MachineID,D.DownID,A.Sttime,A.Ndtime,DateDiff(Second,A.Sttime,A.Ndtime) From AutoData A
			Inner Join MachineInformation M on A.Mc=M.Interfaceid
			Inner Join DownCodeInformation D On A.Dcode=D.Interfaceid
		Where A.DataType=2 And A.Sttime>='''+Convert(NvarChar(20),@StartTime,120)+''' And  A.Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+''' And
		M.MachineID='''+@MachineID+''''
		Select @strSql=@strSql+@strDownID
		Select @strSql=@strSql+' Order By M.MachineID,D.DownID,A.Sttime'
		Exec(@strSql)
	END
	ELSE
	IF @Parameter='PlantWise'
	BEGIN
		Select @strSql='Insert Into #MParam(PlantID,MachineID,DownID,StartTime,EndTime,MTTR)
		Select P.PlantID,M.MachineID,D.DownID,A.Sttime,A.Ndtime,DateDiff(Second,A.Sttime,A.Ndtime) From AutoData A
			Inner Join MachineInformation M on A.Mc=M.Interfaceid
			Inner Join PlantMachine P ON P.MachineID=M.MachineID
			Inner Join DownCodeInformation D On A.Dcode=D.Interfaceid
		Where A.DataType=2 And A.Sttime>='''+Convert(NvarChar(20),@StartTime,120)+''' And  A.Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+'''
			And P.PlantID='''+@PlantID+''''
		Select @strSql=@strSql+@strDownID
		Select @strSql=@strSql+' Order By P.PlantID,M.MachineID,D.DownID,A.Sttime'
		Exec(@strSql)
	END
	ELSE
	IF @Parameter='CellWise'
	BEGIN
		Select @strSql='Insert Into #MParam(CellID,MachineID,DownID,StartTime,EndTime,MTTR)
		Select C.CellID,M.MachineID,D.DownID,A.Sttime,A.Ndtime,DateDiff(Second,A.Sttime,A.Ndtime) From AutoData A
			Inner Join MachineInformation M on A.Mc=M.Interfaceid
			Inner Join CellHistory C ON C.MachineID=M.MachineID
			Inner Join DownCodeInformation D On A.Dcode=D.Interfaceid
		Where A.DataType=2 And A.Sttime>='''+Convert(NvarChar(20),@StartTime,120)+''' And  A.Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+'''
			And C.CellID='''+@CellID+''''
		Select @strSql=@strSql+@strDownID
		Select @strSql=@strSql+' Order By C.CellID,M.MachineID,D.DownID,A.Sttime'
		Exec(@strSql)
	END
	


	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN
		/* Planned Down times for the given time period */
		SELECT Machine,
			CASE When StartTime<@StartTime Then @StartTime Else StartTime End As StartTime,
			CASE When EndTime>@EndTime Then @EndTime Else EndTime End As EndTime
			INTO #PlannedDownTimes
		FROM PlannedDownTimes
		WHERE PDTstatus = 1 And ((StartTime >= @StartTime  AND EndTime <=@EndTime) 
		OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
		OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
		OR ( StartTime < @StartTime  AND EndTime > @EndTime)) 
		And machine in (Select distinct MachineID from #MParam)
	END

	
	-----DR0340 Added From Here
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN
		Select @strSql=''
		Select @strSql='update #MParam set MTTR = isnull(#MParam.MTTR,0) - isNull(t1.MTTR ,0) from (
			Select A.machineid,A.StartTime,A.EndTime,A.DownID,			
			sum(DateDiff(Second,Case when A.StartTime > T.StartTime then A.StartTime else T.StartTime End,Case when a.EndTime < T.EndTime then a.EndTime else T.EndTime End)) as MTTR
			From  #MParam A inner join DownCodeinformation D on D.DownID = A.DownID CROSS jOIN PlannedDownTimes T
			WHERE A.MachineID = T.Machine  and pdtstatus=1 and 
			((A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime)
			OR ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime AND A.EndTime > T.StartTime )
			OR ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime AND A.EndTime > T.EndTime )
			OR ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime))'
		Select @strSql=@strSql+@StrPLD_DownId
		Select @strSql=@strSql+@strDownID
		Select @strSql= @strSql + ' group by A.StartTime,A.EndTime,A.MachineID,A.Downid
		) as t1 inner join #MParam on #MParam.MachineID = t1.MachineID and #MParam.StartTime = t1.StartTime and  #MParam.EndTime = t1.EndTime and #MParam.Downid = t1.Downid'
		print @strsql
		exec(@strSql)
	END
	-----DR0340 Added Till Here



/* ******************************* DR0340 Commented From Here *****************************************
--ER0210
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN
		Select @strSql=''
		Select @strSql='update #MParam set MTTR = isnull(#MParam.MTTR,0) - isNull(t1.MTTR ,0) from (
			Select M.MachineID,M.StartTime,
			sum(DateDiff(Second,Case when M.StartTime > T.StartTime then M.StartTime else T.StartTime End,Case when M.EndTime < T.EndTime then M.EndTime else T.EndTime End)) as MTTR
			from #MParam M  inner join DownCodeinformation D on D.DownID = M.DownID cross join #PlannedDownTimes T
			Where M.MachineID = T.Machine And
			(M.StartTime >= T.StartTime  AND M.EndTime <=T.EndTime) 
			OR ( M.StartTime < T.StartTime  AND M.EndTime <= T.EndTime AND M.EndTime > T.StartTime )
			OR ( M.StartTime >= T.StartTime   AND M.StartTime <T.EndTime AND M.EndTime > T.EndTime )
			OR ( M.StartTime < T.StartTime  AND M.EndTime > T.EndTime)'
		Select @strSql=@strSql+@StrPLD_DownId
		Select @strSql=@strSql+@strDownID
		Select @strSql=@strSql+'Group by M.MachineID,M.StartTime
		) as t1 inner join #MParam on #MParam.MachineID = t1.MachineID and #MParam.StartTime = t1.StartTime'
		print @strsql
		exec(@strSql)
	END
--ER0210
* ******************************* DR0340 Commented Till Here *****************************************/


	Insert Into #TempMParam(SLno,MachineID,DownID,StartTime)
	Select Slno-1,MachineID,DownID,StartTime From #MParam
	Order By Slno


	--ER0210 from here
	Select  #MParam.Slno,#MParam.MachineID,#MParam.DownID,
	#MParam.StartTime As StartTime,ISNULL(#TempMParam.StartTime,#MParam.EndTime) As EndTime,
	ISNULL(DateDiff(second,#MParam.StartTime,#TempMParam.StartTime),0)AS MTBF
	Into #TempTable
	From #MParam Left Outer Join #TempMParam ON #MParam.Slno=#TempMParam.Slno
			And #MParam.MachineID=#TempMParam.MachineID
			And #MParam.DownID=#TempMParam.DownID



	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN
		SELECT @strSql ='UPDATE #TempTable set MTBF =isnull(MTBF,0) - isNull(TT.PPDT ,0) 
			FROM(
			
			SELECT M.MachineID,D.DownID,#TempTable.StartTime,#TempTable.EndTime, SUM
				   (CASE
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PPDT
			FROM AutoData CROSS jOIN #PlannedDownTimes T CROSS Join #TempTable
			Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
			Inner Join MachineInformation M ON AutoData.Mc = M.InterfaceID
			WHERE autodata.DataType=2  AND M.MachineID=T.Machine AND 
				( 
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime) 
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) 
				)
				AND
				(
				(autodata.sttime >= '''+Convert(NvarChar(20),@StartTime,120)+'''  AND autodata.ndtime <='''+Convert(NvarChar(20),@EndTime,120)+''') 
				OR ( autodata.sttime < '''+Convert(NvarChar(20),@StartTime,120)+'''  AND autodata.ndtime <= '''+Convert(NvarChar(20),@EndTime,120)+''' AND autodata.ndtime > '''+Convert(NvarChar(20),@StartTime,120)+''' )
				OR ( autodata.sttime >= '''+Convert(NvarChar(20),@StartTime,120)+'''   AND autodata.sttime <'''+Convert(NvarChar(20),@EndTime,120)+''' AND autodata.ndtime > '''+Convert(NvarChar(20),@EndTime,120)+''' )
				OR ( autodata.sttime < '''+Convert(NvarChar(20),@StartTime,120)+'''  AND autodata.ndtime > '''+Convert(NvarChar(20),@EndTime,120)+''') 
				)
				AND
				(
				(autodata.sttime >= #TempTable.StartTime  AND autodata.ndtime <=#TempTable.EndTime) 
				OR ( autodata.sttime < #TempTable.StartTime  AND autodata.ndtime <= #TempTable.EndTime AND autodata.ndtime > #TempTable.StartTime )
				OR ( autodata.sttime >= #TempTable.StartTime   AND autodata.sttime <#TempTable.EndTime AND autodata.ndtime > #TempTable.EndTime )
				OR ( autodata.sttime < #TempTable.StartTime  AND autodata.ndtime > #TempTable.EndTime) 
				)'
		SELECT @strSql = @strSql + @StrPLD_DownId +  @strDownID
		SELECT @strSql = @strSql + ' group by M.MachineID,D.DownID,#TempTable.StartTime,#TempTable.EndTime
		) as TT INNER JOIN #TempTable ON TT.MachineID = #TempTable.MachineID AND  TT.DownID = #TempTable.DownID AND TT.StartTime = #TempTable.StartTime AND TT.EndTime=#TempTable.EndTime
		WHERE (isnull(MTBF,0) - isNull(TT.PPDT ,0)) >0'
		EXEC(@strSql)
print @strSql
	END
	--ER0210 till here


/*
--ER0210
	UPDATE #MParam SET MTBF=T1.MTBF
	From (
		Select  #MParam.Slno,#MParam.MachineID,#MParam.DownID,DateDiff(second,#MParam.StartTime,#TempMParam.StartTime)AS MTBF
		From #MParam
		Inner Join #TempMParam ON
			#MParam.Slno=#TempMParam.Slno
			And #MParam.MachineID=#TempMParam.MachineID
			And #MParam.DownID=#TempMParam.DownID
	     )AS T1
	Inner Join #MParam ON #MParam.Slno=T1.Slno And #MParam.MachineID=T1.MachineID And #MParam.DownID=T1.DownID
	
	UPDATE #MParam SET MTBF=T1.MTBF
	From (
		Select  #TempTable.Slno,#TempTable.MachineID,#TempTable.DownID,MTBF
		From #TempTable 
 	     )AS T1
	Inner Join #MParam ON #MParam.Slno=T1.Slno And #MParam.MachineID=T1.MachineID And #MParam.DownID=T1.DownID


	Insert Into #OutPut(MachineID,DownID,MTTR,MTBF,baseMTTR,baseMTBF)
	Select MachineID,
	       DownID,
	       Sum(MTTR)/Count(*) As MTTR,
	       Sum(MTBF)/Count(*) As MTBF,0,0
	From #MParam
		Group By MachineID,DownID
		Order By DownID,MachineID

	Update #OutPut Set baseMTTR=ISNULL(T1.MTTR,0),
			   baseMTBF=ISNULL(T1.MTBF,0)
	FROM(
		Select DownId,Avg(MTTR)As MTTR,Avg(MTBF)As MTBF
			From #OutPut Group By DownID
		)AS T1 Inner Join #OutPut On T1.DownId=#OutPut.DownId
*/--ER0210


	UPDATE #MParam SET MTBF=T1.MTBF	From (
		Select  #TempTable.Slno,#TempTable.MachineID,#TempTable.DownID,MTBF	From #TempTable 
 	)AS T1 Inner Join #MParam ON 
	#MParam.Slno=T1.Slno And #MParam.MachineID=T1.MachineID And #MParam.DownID=T1.DownID


	Insert Into #OutPut(MachineID,DownID,MTTR,MTBF,baseMTTR,baseMTBF)
	Select MachineID,DownID,Sum(MTTR)/Count(*) As MTTR,Sum(MTBF)/Count(*) As MTBF,0,0
	From #MParam Group By MachineID,DownID Order By DownID,MachineID
	



	Update #OutPut Set baseMTTR=ISNULL(T1.MTTR,0),baseMTBF=ISNULL(T1.MTBF,0)	FROM(
		Select DownId,Avg(MTTR)As MTTR,Avg(MTBF)As MTBF From #OutPut Group By DownID
	)AS T1 Inner Join #OutPut On T1.DownId=#OutPut.DownId


	Select MachineID,DownID,
	dbo.f_FormatTime(MTTR,@timeformat)MTTR,
	dbo.f_FormatTime(MTBF,@timeformat)MTBF,
	dbo.f_FormatTime(baseMTTR,@timeformat)baseMTTR,
	dbo.f_FormatTime(baseMTBF,@timeformat)baseMTBF From #OutPut
	Order By DownID,MachineID
	
END
