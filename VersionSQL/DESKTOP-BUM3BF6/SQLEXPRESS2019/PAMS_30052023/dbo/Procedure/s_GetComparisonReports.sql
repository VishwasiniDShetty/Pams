/****** Object:  Procedure [dbo].[s_GetComparisonReports]    Committed by VersionSQL https://www.versionsql.com ******/

/****** Object:  StoredProcedure [dbo].[s_GetComparisonReports]    Script Date: 08/10/2010 10:51:39 ******/

/*********************************     History     ***********************************************
												*
Created On 29-09-2005										*
Author M.Kestur,S.Kallur									*
Comparison Reports - To Compare DownTime DailyWise or ShiftWise				*
Machine, DownReason, component change length from 20 to 50 17-feb-2006			*
Changed by Sangeeta Kallur on 04-Apr-2006 :- Increased the length of shiftname 		*
Changed by Sangeeta Kallur on 13-June-2006 : To Include Hourly Production Calculations	*
*
Changed BY SSK :-Change in Count Caln to consider SubOperations at CO Level                   *
Changed by Mrudula Rao to get Operator details for dailywise count  and shiftwisecount        *
Changed by Mrudula to include/exclude downs.

ALtered by Mrudula to get DownTime in Hour format						*
												*
Procedure Changed By SSK on 23/Nov/2006 :
	Bz of Change in column names of ShiftProductionDetails,ShiftDownTimeDetails tables      *
Procedure Changed By Sangeeta Kallur on 27-FEB-2007 :						*
	:For MultiSpindle type of machines [MAINI Req] 						*
	{Effected Region - Production Count for
			(@ComparisonParam='ProdCount' And @TimeAxis='Hour')			*
			(@ComparisonParam='OprtProdCount' And @TimeAxis='Day')			*
			(@ComparisonParam='OprtShift' And @TimeAxis='Shift')		
Procedure Changed By Shilpa on 13-Dec-2007 :
	Introduced one more output set where @ComparisonParam='ProdGraph' ,
	@TimeAxis='Hour','Shift','MONTH'	*							}.
mod 1 :- ER0181 By Kusuma M.H on 16-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
Note :- (ER0181) For ComponentSearch machine qualification is not done as we are not fetching any master information.
Note :- (ER0181) For OprtProdCount(Day) machine qualification is not done as the operation number remains same for a component and operation run on different machines.
mod 2 :- ER0182 By Kusuma M.H on 16-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 3 :- By Mrudula M. Rao on 03-Feb-2010.ER0210 Introduce PDT on 5150. 1) Handle PDT at Machine Level.
mod 4 :-DR0241 By Karthik G on 28/jul/2010 .To change the way of getting no of components produced
More than one machine having same co details,It is picking the co  of unselected  machine.
Also one EmployeeID is added in all the plants.That is also causing duplication 
--DR0247 - By KarthikR - 10/Aug/2010 :: To handle Invalid MachineId error.
DR0277 -SwathiKS - 28/Apr/2011 :: To Update Target When @ComparisonParam = 'ProdCount' and @TimeAxis='Day'.
				  SM -> Standard -> Comparison Reports
DR0301 - SwathiKS - 21/Nov/2011 :: To Handle Error 'Incorrect Syntax Near 'ComponentidName' under Admin->ExportData->Shiftwisecount.
ER0330 - GeethanjaliK/Karthikr - 16/Aug/2012 :: To include shift as ouput parameter in @ComparisonParam = ProdCount and @TimeAxis= Hour.
************************************************************************************************/
-- s_GetComparisonReports   '2011-11-18 10:09:25','2011-11-19 10:09:25','OprtShift','A55' ,'', 'Shift','Z002.007 PINION 15:25 D=9mm SA6/12','11','','', '0' 
--s_GetComparisonReports '2011-Sep-2','2011-Sep-2','ProdCount','','','Hour','','','','','0'
CREATE                                    PROCEDURE [dbo].[s_GetComparisonReports]
	@StartTime as Datetime,			
	@EndTime as datetime,
	@ComparisonParam as nvarchar(20), /* ProdCount , DownTime , OprtProdCount , CompSearch ,OprtShift*/
	@Machine as nvarchar(50) = '',
	---mod 2
	---Replaced varchar with nvarchar to support unicode characters.
--	@DownReason as varchar(8000) = '',
	@DownReason as nvarchar(4000) = '',
	---mod 2
	@TimeAxis as nvarchar(20),/* Hour , Shift , Day , Month */
	@Component as nvarchar(50)='',
	@Operation as nvarchar(20)='',
	@ShiftName as nvarchar(20)='',
	@PlantID nvarchar(50)='',
	@Exclude int
AS
BEGIN
	CREATE TABLE #DownTemp
	(
		PDate datetime,
		ShiftName nvarchar(20),
		FromTime datetime,
		ToTime Datetime,
		DownTime  int,
		AE float,
		PE float,
		OE float,
		CompID Nvarchar(50),
		OpnID Nvarchar(20),
		CompCount  int,
		Machine nvarchar(50),
		Rejection float,
		OperatorID Nvarchar(50),
		TrgtCt int Default 0,
		Datecomp datetime
	)
	Create Table #ShiftTemp
	(
		PDate datetime,
		ShiftName nvarchar(20),
		FromTime datetime,
		ToTime Datetime,
		DownTime  int,
		CompID Nvarchar(50),
		OpnID Nvarchar(20),
		CompCount  int,
		Oprtname Nvarchar(50),
		Targetcount int Default 0
	)
	Create Table #OprProdData1
	(
		Pdate1 datetime,
		Fromtime datetime,
		Totime datetime,
		ComponentID Nvarchar(50),
		OperationID Nvarchar(50),
		CmpCount Int,
		OperatorID Nvarchar(50)
	)
	CREATE TABLE #Exceptions
	(
		MachineID NVarChar(50),
		ComponentID Nvarchar(50),
		OperationNo Int,
		OperatorID Nvarchar(50),
		StartTime DateTime,
		EndTime DateTime,
		IdealCount Int,
		ActualCount Int,
		ExCount Int
	)
--mod 3: Table to store PDTs at machine level.
CREATE TABLE #PlannedDownTimes
	(
		StartTime DateTime,
		EndTime DateTime,
		Machine nvarchar(50)
	)
---mod 3
---mod 2
---To support unicode characters replaced varchar with nvarchar.
--Declare @strsql varchar(8000)
Declare @strsql nvarchar(4000)
---mod 2
Declare @counter as datetime
declare @curstarttime as datetime
Declare @curendtime   as datetime
Declare @curMachineID AS NvarChar(50)
Declare @strPlantID as nvarchar(50)
Declare @Targetsource as nvarchar(50)

/* DR0301 From Here
Declare @strXmachine AS NvarChar(50)
Declare @strXcomponent AS NvarChar(50)
Declare @strXoperation AS NvarChar(50)
DR0301 Till Here */

--DR0301 From Here
Declare @strXmachine AS NvarChar(255)
Declare @strXcomponent AS NvarChar(255)
Declare @strXoperation AS NvarChar(255)
--DR0301 Till Here

---mod 3
Declare @StrPLD_DownId AS NvarChar(1000)
---mod 3
SELECT @strXmachine=''
SELECT @strXcomponent=''
SELECT @strXoperation=''
--mod 3
SELECT @StrPLD_DownId=''
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
	SELECT @StrPLD_DownId=' AND D.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
END
--mod 3
If isnull(@Machine,'') <> ''
BEGIN
	---mod 2
--	SELECT @strXmachine = ' AND ( EX.machineid = ''' + @Machine+ ''')'
	SELECT @strXmachine = ' AND ( EX.machineid = N''' + @Machine+ ''')'
	---mod 2
END
If isnull(@Component, '') <> ''
BEGIN
	---mod 2
--	SELECT @strXcomponent = ' AND ( EX.componentid = ''' + @Component+ ''')'
	SELECT @strXcomponent = ' AND ( EX.componentid = N''' + @Component + ''')'
	---mod 2
END
If isnull(@Operation, '') <> ''
BEGIN
	---mod 2
--	SELECT @strXoperation = ' AND ( EX.Operationno = ''' + @Operation + ''')'
	SELECT @strXoperation = ' AND ( EX.Operationno = N''' + @Operation + ''')'
	---mod 2
END
select @curstarttime=@StartTime
select @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')
SET @strPlantID = ''
if isnull(@PlantID,'') <> ''
BEGIN	
	---mod 2
--	SELECT @strPlantID = ' AND ( P.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( P.PlantID = N''' + @PlantID+ ''')'
	---mod 2
END


select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'
IF @TimeAxis='Hour'
Begin
---mod 2
---To support unicode characters replaced varchar with nvarchar.
--	Declare @TrSql varchar(8000)
	Declare @TrSql nvarchar(4000)	
---mod 2
	Declare @strmachine nvarchar(255)
	Declare @stroperation nvarchar(255)
	Declare @strcomponent nvarchar(255)
	Declare @strShift nvarchar(255)
	Declare @strmachine2 nvarchar(255)
	Declare @stroperation2 nvarchar(255)
	Declare @strcomponent2 nvarchar(255)
	select @TrSql=''
	SELECT @strsql = ''
	SELECT @strmachine = ''
	SELECT @strcomponent = ''
	SELECT @stroperation = ''
	SELECT @strShift=''
	SELECT @strmachine2 = ''
	SELECT @strcomponent2= ''
	SELECT @stroperation2 = ''
	If isnull(@Machine,'') <> ''
	BEGIN
		---mod 2
--		SELECT @strmachine = ' AND ( M.machineid = ''' + @Machine+ ''')'
		SELECT @strmachine = ' AND ( M.machineid = N''' + @Machine + ''')'
		---mod 2
	END
	If isnull(@Component, '') <> ''
	BEGIN
		---mod 2
--		SELECT @strcomponent = ' AND ( C.componentid = ''' + @Component+ ''')'
		SELECT @strcomponent = ' AND ( C.componentid = N''' + @Component + ''')'
		---mod 2
	END
	If isnull(@Operation, '') <> ''
	BEGIN
		---mod 2
--		SELECT @stroperation = ' AND ( O.Operationno = ''' + @Operation + ''')'
		SELECT @stroperation = ' AND ( O.Operationno = N''' + @Operation + ''')'
		---mod 2
	END
	IF ISNULL(@ShiftName,'')<> ''
	BEGIN
		---mod 2
--		SELECT @strShift= 'AND (shift=''' +@ShiftName+ ''' ) '
		SELECT @strShift= 'AND (shift = N''' + @ShiftName + ''' ) '
		---mdo 2
	END
	if isnull(@Machine,'') <> ''
	BEGIN
		---mod 2
--		SELECT @strmachine2 = ' AND ( machine = ''' + @Machine+ ''')'
		SELECT @strmachine2 = ' AND ( machine = N''' + @Machine + ''')'
		---mod 2
	END
	if isnull(@Component, '') <> ''
	BEGIN	
		---mod 2
--		SELECT @strcomponent2 = ' AND ( component = ''' + @Component+ ''')'
		SELECT @strcomponent2 = ' AND ( component = N''' + @Component + ''')'
		---mod 2
	END
	if isnull(@Operation, '') <> ''
	BEGIN
		---mod 2
--		SELECT @stroperation2 = ' AND ( Operation = ''' + @Operation + ''')'
		SELECT @stroperation2 = ' AND ( Operation = N''' + @Operation + ''')'
		---mod 2
	end
			
	Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)
	Exec s_GetShiftTime @counter,@ShiftName
	
	--select * from #ShiftTemp
IF @ComparisonParam='ProdCount' or @ComparisonParam='ProdGraph'
BEGIN
	Declare @StrDiv int
	SELECT TOP 1 @counter=FromTime FROM #ShiftTemp ORDER BY FromTime ASC
	SELECT TOP 1 @EndTime=ToTime FROM #ShiftTemp ORDER BY FromTime DESC
	
	select @StrDiv=cast (ceiling (cast(datediff(second,@counter,@EndTime)as float ) /3600) as int)
	
	While(@counter < @EndTime)
		BEGIN
			SELECT @curstarttime=@counter
			SELECT @curendtime=DATEADD(Second,3600,@counter)
			if @curendtime >= @EndTime
			Begin
				set @curendtime = @EndTime
			End
			SELECT @strsql = ' INSERT INTO #DownTemp(FromTime,Totime,Machine,CompID,OpnID,CompCount)'
			SELECT @strsql = @strsql +' SELECT '''+convert(nvarchar(20),@curstarttime)+''','''+convert(nvarchar(20),@curendtime)+''',M.MachineID,C.componentid,O.operationno,'
			SELECT @strsql = @strsql +' CAST(CEILING(CAST(sum(A.partscount)AS Float)/ISNULL(O.SubOperations,1)) AS INTEGER) '			
			SELECT @strsql = @strsql +' from autodata A '
			SELECT @strsql = @strsql +' inner join ComponentInformation C on A.comp=C.interfaceid '
			SELECT @strsql = @strsql +' inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
			SELECT @strsql = @strsql +' INNER JOIN machineinformation M on A.mc=M.interfaceid '
			---mod 1
			SELECT @strsql = @strsql +' and M.machineid = O.machineid '
			---mod 1
			SELECT @strsql = @strsql +' left OUTER Join PlantMachine P on m.machineid = P.machineid '
			SELECT @strsql = @strsql +' WHERE A.DataType=1 And A.ndtime>'''+convert(nvarchar(20),@curstarttime)+''' and A.Ndtime<='''+ convert(nvarchar(20),@curendtime)+''' '
			SELECT @strsql = @strsql + @strmachine + @strcomponent + @stroperation + @strPlantID
			SELECT @strsql = @strsql + ' GROUP BY M.MachineID,C.componentid,O.operationno,O.SubOperations'
			EXEC (@strsql)
			print @strsql

			---mod 3
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
			BEGIN
				select @strsql=' Insert into #PlannedDownTimes
				SELECT
				CASE When StartTime<''' + convert(nvarchar(20),@curstarttime,120) + ''' Then ''' + convert(nvarchar(20),@curstarttime,120) + '''  Else StartTime End As StartTime,
				CASE When EndTime>''' + convert(nvarchar(20),@curendtime,120) + '''  Then ''' + convert(nvarchar(20),@curendtime,120) + '''  Else EndTime End As EndTime,Machine
				FROM PlannedDownTimes
				WHERE (
				(StartTime >= ''' + convert(nvarchar(20),@curstarttime,120) + '''  AND EndTime <=''' + convert(nvarchar(20),@curendtime,120) + ''')
				OR ( StartTime < ''' + convert(nvarchar(20),@curstarttime,120) + '''  AND EndTime <= ''' + convert(nvarchar(20),@curendtime,120) + ''' AND EndTime > ''' + convert(nvarchar(20),@curstarttime,120) + ''' )
				OR ( StartTime >= ''' + convert(nvarchar(20),@curstarttime,120) + '''   AND StartTime <''' + convert(nvarchar(20),@curendtime,120) + ''' AND EndTime > ''' + convert(nvarchar(20),@curendtime,120) + ''' )
				OR ( StartTime < ''' + convert(nvarchar(20),@curstarttime,120) + '''  AND EndTime > ''' + convert(nvarchar(20),@curendtime,120) + ''') ) and PDTStatus=1 '
				if isnull(@Machine,'')<>''
				begin
					select @strsql=@strsql+' AND (PlannedDownTimes.machine =N'''+@Machine+''') '
				ENd
				select @strsql=@strsql+' ORDER BY StartTime'
				print @strsql
				exec (@strsql)
			END
			---mod 3
			
		--*******************************************************************************************************
				-- FOLLWING CODE IS ADDED BY SANGEETA KALLUR ON 27-FEB-2007 --
		SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
				SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
				From ProductionCountException Ex
				Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
				Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
				Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
		---mod 1
		SELECT @StrSql = @StrSql +' and M.machineid=O.machineid '
		---mod 1
		SELECT @StrSql = @StrSql +' WHERE  M.MultiSpindleFlag=1 AND
				((Ex.StartTime >= ''' + convert(nvarchar(20),@curstarttime) + ''' AND Ex.EndTime <= ''' + convert(nvarchar(20),@curendtime) + ''' )
				OR (Ex.StartTime < ''' + convert(nvarchar(20),@curstarttime) + ''' AND Ex.EndTime > ''' + convert(nvarchar(20),@curstarttime) + ''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@curendtime) + ''')
				OR (Ex.StartTime >= ''' + convert(nvarchar(20),@curstarttime) + ''' AND Ex.EndTime > ''' + convert(nvarchar(20),@curendtime) + ''' AND Ex.StartTime< ''' + convert(nvarchar(20),@curendtime) + ''')
				OR (Ex.StartTime < ''' + convert(nvarchar(20),@curstarttime) + ''' AND Ex.EndTime > ''' + convert(nvarchar(20),@curendtime) + ''' ))'
		SELECT @StrSql = @StrSql + @StrxMachine + @strXcomponent + @strXoperation
		Exec (@strsql)
		SELECT @strsql=''
		IF (SELECT Count(*) from #Exceptions) <> 0
		BEGIN
			UPDATE #Exceptions SET StartTime=@curstarttime WHERE (StartTime<@curstarttime)AND EndTime>@curstarttime
			UPDATE #Exceptions SET EndTime=@curendtime WHERE (EndTime>@curendtime AND StartTime<@curendtime )
			Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
				   (SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
				    SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 				From (
						select M.MachineID,C.ComponentID,O.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
						Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
						Inner Join ComponentInformation  C ON autodata.Comp = C.InterfaceID
						Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID '
			---mod 1
			Select @StrSql = @StrSql +' and M.machineid=O.machineid '
			---mod 1
			Select @StrSql = @StrSql +'Inner Join (
					Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
					)AS Tt1 ON Tt1.MachineID=M.MachineID AND Tt1.ComponentID = C.ComponentID AND Tt1.OperationNo= O.OperationNo and Tt1.MachineID=O.MachineID
					Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
			Select @StrSql = @StrSql+ @strmachine + @strcomponent + @stroperation
			Select @StrSql = @StrSql+' Group by M.MachineID,C.ComponentID,O.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
				    ) as T1
	   			    Inner join componentinformation C on T1.Comp=C.interfaceid
	   			    Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid  and  T1.MachineID=O.MachineID '
			---mod 1
			Select @StrSql = @StrSql +' Inner join machineinformation on  machineinformation.machineid = T1.machineid  '
			---mod 1
	  		Select @StrSql = @StrSql +' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
				    )AS T2
				    WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
				    AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
			Exec(@StrSql)
print @StrSql
			
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
			BEGIN
			Select @StrSql =''
			Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
			From
			(
				SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
				SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
				From
				(
					select M.MachineID,C.ComponentID,O.OperationNo,comp,opn,
					Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
					Inner Join MachineInformation  M ON autodata.MC=M.InterfaceID
					Inner Join ComponentInformation  C ON autodata.Comp = C.InterfaceID
					Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID And O.MachineId=M.MachineID
					Inner Join	
					(
						SELECT MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
						CASE
							WHEN (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime) THEN Ex.StartTime
							WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.StartTime
							ELSE Td.StartTime
						END AS PLD_StartTime,
						CASE
							WHEN (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime) THEN Ex.EndTime
							WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.EndTime
							ELSE  Td.EndTime
						END AS PLD_EndTime
			
						From #Exceptions AS Ex Inner JOIN #PlannedDownTimes AS Td on Td.Machine=Ex.MachineID
						Where ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
						(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
						(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
						(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'
				Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=M.MachineID AND T1.ComponentID = C.ComponentID AND T1.OperationNo= O.OperationNo and T1.MachineID=O.MachineID
					Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
				AND (autodata.ndtime > ''' + convert(nvarchar(20),@curStartTime,120)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@curendtime,120)+''' )'
				Select @StrSql = @StrSql + @strmachine + @strcomponent + @stroperation
				Select @StrSql = @StrSql+' Group by M.MachineID,C.ComponentID,O.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn
				)AS T2
				Inner join componentinformation C on T2.Comp=C.interfaceid
				Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID=T2.MachineID
				GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime
			)As T3
			WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
			AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'
			
			EXEC(@StrSql)
			
			END
			UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
		END

		---mod 3: Ignore count overlapping with PDT
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
			UPDATE #DownTemp SET CompCount = ISNULL(CompCount,0) - ISNULL(T2.comp,0)
			from
			(
				select Min(StartTime)StartTime,Max(EndTime)EndTime,M.MachineID,C.ComponentID As ComponentID,O.OperationNo As OperationNo,CEILING (CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(O.SubOperations,1)) as comp
			 	From Autodata A
					Inner join componentinformation C on A.Comp=C.interfaceid
			   		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid
					Inner Join MachineInformation M On A.mc=M.Interfaceid and O.MachineId=M.MachineID
					Inner jOIN #PlannedDownTimes T On T.Machine=M.MachineID WHERE A.DataType=1
					AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
					AND(A.ndtime > @curStartTime  AND A.ndtime <=@curEndTime)
			   Group By M.MachineID,C.ComponentID,O.OperationNo,O.SubOperations
			) as T2 inner join #DownTemp on T2.MachineID=#DownTemp.Machine AND #DownTemp.CompID=T2.ComponentID AND #DownTemp.OpnId=T2.OperationNo
			AND T2.StartTime>= #DownTemp.FromTime And T2.EndTime<=#DownTemp.ToTime
		END
		
		DELETE FROM #PlannedDownTimes --delete PDT's for the hour
		---mod 3
		
		UPDATE #DownTemp SET CompCount=ISNULL(CompCount,0)-ISNULL(T1.Xcount,0)
		From(
			SELECT Min(StartTime)StartTime,Max(EndTime)EndTime,MachineID,ComponentID,OperationNo,SUM(ExCount)Xcount
			FROM #Exceptions
			GROUP BY MachineID,ComponentID,OperationNo
		)T1 Inner Join #DownTemp ON
		T1.MachineID=#DownTemp.Machine AND T1.ComponentID=#DownTemp.CompID
		AND T1.OperationNo=#DownTemp.OpnId AND T1.StartTime>= #DownTemp.FromTime And T1.EndTime<=#DownTemp.ToTime
		DELETE FROM #Exceptions
--*******************************************************************************************************
			UPDATE #DownTemp SET PDate=@counter where FromTime=@curstarttime and ToTime=@curendtime
			SELECT @counter = DATEADD(Second,3600,@counter)
	END
		
		  UPDATE #DownTemp set Datecomp=@StartTime
	      UPDATE #DownTemp SET ShiftName=@ShiftName
		
		if isnull(@Targetsource,'')='Exact Schedule'
		BEGIN
			 select @TrSql=''
			 select @TrSql='update #DownTemp set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
					( select date as date1,machine,component,operation,sum(idealcount) as tcount from
				  	loadschedule where date>=''' +convert(nvarchar(20),@starttime)+''' and date<=''' +convert(nvarchar(20),@starttime)+ ''' '
		     select @TrSql= @TrSql + @strmachine2 + @strcomponent2 + @stroperation2 + @strShift
			 select @TrSql=@TrSql+ 'group by date,machine,component,operation ) as t1 inner join #DownTemp on
				  	t1.date1=#DownTemp.DateComp  and t1.machine=#DownTemp.Machine and t1.component=#DownTemp.CompID
				  	and t1.operation=#DownTemp.OpnId '	
			PRINT @TrSql
			EXEC (@TrSql)
			
			 UPDATE #DownTemp SET TrgtCt=TrgtCt/ISNULL(@StrDiv,1)
			
		END
		if isnull(@Targetsource,'')='Default Target per CO'
		BEGIN
			PRINT @Targetsource
			select @TrSql=''
			select @TrSql='update #DownTemp set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
					( select DATE AS date1, machine,component,operation,sum(idealcount) as tcount from
				  	loadschedule where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC) and SHIFT=(SELECT TOP 1 SHIFT FROM LOADSCHEDULE ORDER BY SHIFT DESC)'
		    select @TrSql= @TrSql + @strmachine2 + @strcomponent2 + @stroperation2
			select @TrSql=@TrSql+ ' group by date,machine,component,operation ) as t1 inner join #DownTemp on
				  	t1.machine=#DownTemp.Machine and t1.component=#DownTemp.CompID
				  	and t1.operation=#DownTemp.OpnId '	
			PRINT @TrSql
			EXEC (@TrSql)
			IF ISNULL(@ShiftName,'')<>''
			BEGIN
			 UPDATE #DownTemp SET TrgtCt=TrgtCt/ISNULL(@StrDiv,1)
			END
			IF ISNULL(@ShiftName,'')=''
			BEGIN
			 UPDATE #DownTemp SET TrgtCt=TrgtCt*(SELECT COUNT(*) FROM  SHIFTDETAILS WHERE RUNNING=1)/ISNULL(@StrDiv,1)
			--UPDATE  #DownTemp SET TrgtCt=TrgtCt*(SELECT COUNT(*) FROM  SHIFTDETAILS WHERE RUNNING=1)
			END
			
		END

		IF ISNULL(@Targetsource,'')='% Ideal'
		BEGIN
			select @strmachine2=''
			if isnull(@Machine,'') <> ''
			BEGIN
			---mod 2
--			SELECT @strmachine2 = ' AND ( CO.machineID = ''' + @Machine+ ''')'
			SELECT @strmachine2 = ' AND ( CO.machineID = N''' + @Machine+ ''')'
			---mod 2
			END
			select @strcomponent2=''
			if isnull(@Component, '') <> ''
			BEGIN
			---mod 2
--			SELECT @strcomponent2 = ' AND (CO.componentID = ''' + @Component+ ''')'
			SELECT @strcomponent2 = ' AND (CO.componentID = N''' + @Component+ ''')'
			---mod 2
			END
			select @stroperation2=''
			if isnull(@Operation, '') <> ''
			BEGIN
			---mod 2
--			SELECT @stroperation2 = ' AND ( CO.operationno = ''' + @Operation + ''')'
			SELECT @stroperation2 = ' AND ( CO.operationno = N''' + @Operation + ''')'
			---mod 2
			END
			
		    select @TrSql=''
			---mod 1
			---Incuded machine in the select list.
--			select @TrSql='update #DownTemp set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
--					( select CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#DownTemp.Fromtime,#DownTemp.Totime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
--					from componentoperationpricing CO inner join #DownTemp on CO.Componentid=#DownTemp.CompID
--					and Co.operationno=#DownTemp.OpnID  '
			select @TrSql='update #DownTemp set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
					( select CO.machineid as machine,CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#DownTemp.Fromtime,#DownTemp.Totime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
					from componentoperationpricing CO inner join #DownTemp on CO.Componentid=#DownTemp.CompID
					and CO.operationno=#DownTemp.OpnID  '
			select @TrSql= @TrSql + ' and CO.machineid = #DownTemp.machine '
			---mod 1
			select @TrSql= @TrSql + @strmachine2 + @strcomponent2 + @stroperation2
			select @TrSql=@TrSql+ ') as t1 inner join #DownTemp on
				  	  t1.component=#DownTemp.CompID
				  	and t1.operation=#DownTemp.OpnId '
			---mod 1	
			select @TrSql=@TrSql + ' and t1.machine = #DownTemp.machine '
			---mod 1
			PRINT @TrSql
			EXEC (@TrSql)
			--select * from #DownTemp
			---return
		
		END
	END

/*	IF @ComparisonParam='AE' or @ComparisonParam='PE' or @ComparisonParam='OE'
	BEGIN
		declare @NdTim as datetime
		declare @Strttm as datetime
		select @NdTim=(select top 1 ToTime from #ShiftTemp order by ToTime desc)
		select @Strttm=(select top 1 FromTime from #ShiftTemp order by FromTime asc)*/
		/*DECLARE @EffiShiftName nvarchar(50)
	
		DECLARE PRptCursor  Cursor  For
		SELECT ShiftName,FromTime,ToTime From #ShiftTemp
		Open PRptCursor
		FETCH NExt From PRptCursor into @EffiShiftName,@counter,@EndTime
		While(@@Fetch_Status=0)
		BEGIN
			While(@counter < @EndTime)
			BEGIN
				SELECT @curstarttime=@counter
				SELECT @curendtime=DATEADD(Second,3600,@counter)
				if @curendtime >= @EndTime
				Begin
					set @curendtime = @EndTime
				end */  /*
				INSERT INTO #DownTemp(Pdate,ShiftName,FromTime,Totime,Machine,AE,PE,OE,CompCount)
				EXEC dbo.s_GetEfficiencyFromAutodata @Strttm ,@NdTim ,@Machine,@PlantID*/
		
				/*UPDATE #DownTemp SET PDate=@counter where FromTime=@curstarttime and ToTime=@curendtime
				UPDATE #DownTemp SET ShiftName=@EffiShiftName where FromTime=@curstarttime and ToTime=@curendtime
				SELECT @counter = DATEADD(Second,3600,@counter)
				
			END
			
		FETCH NExt From PRptCursor into @EffiShiftName,@counter,@EndTime
		END
		close PRptCursor
		deallocate PRptCursor*/
	  /* SELECT	cast(cast(DateName(month,pdate) as nvarchar(3))+ ' '+cast(datepart(dd,Pdate)as nvarchar(2))+ ' Shift-' +cast(ShiftName as nvarchar(20)) as Nvarchar(50)) as Day,
--cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))+'-'+ cast(ShiftName as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as nvarchar(50)) as Day,
		Cast(CAST(YEAR(FromTime)as nvarchar(4))+CAST(Month(FromTime)as nvarchar(2))+CAST(Day(FromTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as NVarchar(50)) as Shift,
		PDate,ShiftName,FromTime,
		ToTime,	
		Machine as MachineID,AE,PE,OE
		 FROM #DownTemp
	   return;
	END */
---By Mrudula to get hourly down time----------
	IF @ComparisonParam='DownTime'
	BEGIN
		
		SELECT TOP 1 @counter=FromTime FROM #ShiftTemp ORDER BY FromTime ASC
		SELECT TOP 1 @EndTime=ToTime FROM #ShiftTemp ORDER BY FromTime DESC
		While(@counter <= @EndTime)
			BEGIN
				SELECT @curstarttime=@counter
				SELECT @curendtime=DATEADD(Second,3600,@counter)
				if @curendtime >= @EndTime
				Begin
					set @curendtime = @EndTime
				end
				Insert into #DownTemp(FromTime,Totime,Downtime)
				
				Exec s_GetDownTimeReportfromAutoData @curstarttime,@curendtime,@Machine,@DownReason,'','','','','','','DTimeOnly',@PlantID,@Exclude
				UPDATE #DownTemp SET PDate=@counter where FromTime=@curstarttime and ToTime=@curendtime
				SELECT @counter = DATEADD(Second,3600,@counter)
			END
		UPDATE #DownTemp SET ShiftName=@ShiftName
	END
	
----end MMR--------------------------------------------------	
end
if @TimeAxis='Day'
Begin
		
		IF @ComparisonParam='DownTime'
		BEGIN
		While(@counter <= @EndTime)
			BEGIN
				select @curstarttime=dbo.f_GetLogicalDay(@curstarttime,'start')
				select @curendtime=dbo.f_GetLogicalDay(@curstarttime,'end')
				Insert into #DownTemp(FromTime,Totime,Downtime)
				Exec s_GetDownTimeReportfromAutoData @curstarttime,@curendtime,@Machine,@DownReason,'','','','','','','DTimeOnly',@PlantID,@Exclude
				UPDATE #DownTemp SET PDate=@counter where FromTime=@curstarttime and ToTime=@curendtime
				SELECT @curstarttime = Dateadd(Day,1,@curstarttime)
				SELECT @counter = Dateadd(Day,1,@counter)
			END
		END
		IF @ComparisonParam='ProdCount' or @ComparisonParam='ProdGraph'
		BEGIN
		While(@counter <= @EndTime)
			BEGIN
				select @curstarttime=dbo.f_GetLogicalDay(@curstarttime,'start')
				select @curendtime=dbo.f_GetLogicalDay(@curstarttime,'end')
				--Insert into #DownTemp(FromTime,Totime,CompID,OpnID,CompCount) --DR0277
				Insert into #DownTemp(FromTime,Totime,Machine,CompID,OpnID,CompCount)	--DR0277
				--EXEC s_GetComponentProdDataFromAutodata @curstarttime,@curendtime,@Machine,@Component,@Operation,@PlantID --DR0277
				EXEC s_GetComponentProdDataFromAutodata @curstarttime,@curendtime,@Machine,@Component,@Operation,@PlantID,'ProdCount' --DR0277
				UPDATE #DownTemp SET PDate=@counter where FromTime=@curstarttime and ToTime=@curendtime
				

				SELECT @curstarttime = Dateadd(Day,1,@curstarttime)
				SELECT @counter = Dateadd(Day,1,@counter)	
			END
		---mod 2
		---Replaced varchar with nvarchar to support unicode characters.
--		Declare @TrSql3 varchar(8000)
		Declare @TrSql3 nvarchar(4000)
		---mod 2
		Declare @strmachine3 nvarchar(255)
		Declare @stroperation3 nvarchar(255)
		Declare @strcomponent3 nvarchar(255)
		select @TrSql3=''
		SELECT @strmachine3 = ''
		SELECT @strcomponent3= ''
		SELECT @stroperation3 = ''
		if isnull(@Machine,'') <> ''
			BEGIN
			---mod 2
--			SELECT @strmachine3 = ' AND ( machine = ''' + @Machine+ ''')'
			SELECT @strmachine3 = ' AND ( machine = N''' + @Machine+ ''')'
			---mod 2
			END
		if isnull(@Component, '') <> ''
			BEGIN
			---mod 2
--			SELECT @strcomponent3 = ' AND ( component = ''' + @Component+ ''')'
			SELECT @strcomponent3 = ' AND ( component = N''' + @Component+ ''')'
			---mod 2
			END
		if isnull(@Operation, '') <> ''
			BEGIN
			---mod 2
--			SELECT @stroperation3 = ' AND ( Operation = ''' + @Operation + ''')'
			SELECT @stroperation3 = ' AND ( Operation = N''' + @Operation + ''')'
			---mod 2
			END
		

	
		if isnull(@Targetsource,'')='Exact Schedule'
		BEGIN
			 select @TrSql3=''
			 select @TrSql3='update #DownTemp set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
					( select date as date1,machine,component,operation,sum(idealcount) as tcount from
				  	loadschedule where date >= ''' +convert(nvarchar(20),@starttime)+''' and date<=''' +convert(nvarchar(20),@EndTime)+ ''' '
		         select @TrSql3= @TrSql3 + @strmachine3 + @strcomponent3 + @stroperation3
			 select @TrSql3=@TrSql3+ 'group by date,machine,component,operation ) as t1 inner join #DownTemp on
				  	t1.date1=#DownTemp.Pdate  and t1.component=#DownTemp.CompID
				  	and t1.operation=#DownTemp.OpnId '	
			---mod 1
			select @TrSql3 = @TrSql3 + ' and t1.machine = #DownTemp.machine '
			---mod 1
			PRINT @TrSql3
			EXEC (@TrSql3)
--			select * from #DownTemp	
		END
		if isnull(@Targetsource,'')='Default Target per CO'
		BEGIN
			PRINT @Targetsource
			select @TrSql3=''
			select @TrSql3='update #DownTemp set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
					( select DATE AS date1, machine,component,operation,sum(idealcount) as tcount from
				  	loadschedule where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC) and SHIFT=(SELECT TOP 1 SHIFT FROM LOADSCHEDULE ORDER BY SHIFT DESC)'
		    select @TrSql3= @TrSql3 + @strmachine3 + @strcomponent3 + @stroperation3
			select @TrSql3=@TrSql3+ ' group by date,machine,component,operation ) as t1 inner join #DownTemp on
				  	t1.component=#DownTemp.CompID
				  	and t1.operation=#DownTemp.OpnId '	
			---mod 1
			select @TrSql3 = @TrSql3 + ' and t1.machine = #DownTemp.machine '
			---mod 1
			PRINT @TrSql3
			EXEC (@TrSql3)
			
			UPDATE #DownTemp SET TrgtCt=TrgtCt*(SELECT COUNT(*) FROM  SHIFTDETAILS WHERE RUNNING=1)
			
		END
		IF ISNULL(@Targetsource,'')='% Ideal'
		BEGIN
			select @strmachine3=''
			if isnull(@Machine,'') <> ''
			BEGIN
			---mod 2
--			SELECT @strmachine3 = ' AND ( CO.machineID = ''' + @Machine+ ''')'
			SELECT @strmachine3 = ' AND ( CO.machineID = N''' + @Machine+ ''')'
			---mod 2
			END
			select @strcomponent3=''
			if isnull(@Component, '') <> ''
			BEGIN
			---mod 2
--			SELECT @strcomponent3 = ' AND (CO.componentID = ''' + @Component+ ''')'
			SELECT @strcomponent3 = ' AND (CO.componentID = N''' + @Component+ ''')'
			---mod 2
			END
			select @stroperation3=''
			if isnull(@Operation, '') <> ''
			BEGIN
			---mdo 2
--			SELECT @stroperation3 = ' AND ( CO.operationno = ''' + @Operation + ''')'
			SELECT @stroperation3 = ' AND ( CO.operationno = N''' + @Operation + ''')'
			---mod 2
			END
			
		    select @TrSql3=''
		     
			---mod 1
			---Included machine in the select list.
--			select @TrSql3='update #DownTemp set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
--					 ( select CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#DownTemp.Fromtime,#DownTemp.Totime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
--					from componentoperationpricing CO inner join #DownTemp on CO.Componentid=#DownTemp.CompID
--					and Co.operationno=#DownTemp.OpnID  '
			select @TrSql3='update #DownTemp set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
					 ( select CO.machineid as machine,CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#DownTemp.Fromtime,#DownTemp.Totime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
					from componentoperationpricing CO inner join #DownTemp on CO.Componentid=#DownTemp.CompID
					and Co.operationno=#DownTemp.OpnID  '
			select @TrSql3= @TrSql3 + ' and CO.machineid = #DownTemp.machine '
			---mod 1
			select @TrSql3= @TrSql3 + @strmachine3 + @strcomponent3 + @stroperation3
			select @TrSql3=@TrSql3+ '  ) as t1 inner join #DownTemp on
				  	  t1.component=#DownTemp.CompID
				  	and t1.operation=#DownTemp.OpnId '
			---mod 1
			select @TrSql3 = @TrSql3 + ' and t1.machine = #DownTemp.machine '
			---mod 1	
			PRINT @TrSql3
			EXEC (@TrSql3)
			
		
		END
				
		END
--***********Updated by Mrudula to get Operator details,used in Exporting the data****--
		IF @ComparisonParam='OprtProdCount'
		BEGIN
			
			While(@counter <= @EndTime)
			BEGIN
				declare @strsqlt nvarchar(2000)
				declare @strmachinet nvarchar(255)
				declare @stroperationt nvarchar(255)
				declare @strcomponentt nvarchar(255)
								
				--Insert into #OprtTemp(FromTime,Totime,CompID,OpnID,CompCount,OperatorID)
				select  @curstarttime=dbo.f_GetLogicalDay( @curstarttime,'start')
				select @curendtime=dbo.f_GetLogicalDay( @curstarttime,'end')			
				
				select @strsqlt = ''
				select @strmachinet = ''
				select @strcomponentt = ''
				select @stroperationt = ''
				if isnull(@Machine,'') <> ''
				begin
				---mod 2
--				select @strmachinet = ' AND ( M.machineid = ''' + @Machine+ ''')'
				select @strmachinet = ' AND ( M.machineid = N''' + @Machine+ ''')'
				---mod 2
				end
			        if isnull(@Component, '') <> ''
				begin
				---mod 2
--				select @strcomponentt = ' AND ( C.componentid = ''' + @Component+ ''')'
				select @strcomponentt = ' AND ( C.componentid = N''' + @Component+ ''')'
				---mod 2
				end
				if isnull(@Operation, '') <> ''
				begin
				---mod 2
--				select @stroperationt = ' AND ( O.Operationno = ''' + @Operation + ''')'
				select @stroperationt = ' AND ( O.Operationno = N''' + @Operation + ''')'
				---mod 2
				end
				--mod 4
				/*
				SELECT @strsqlt='INSERT INTO #OprProdData1(Pdate1,Fromtime,Totime,ComponentID,OperationID,CmpCount,OperatorID)'
				select @strsqlt = @strsqlt + 'select '''+convert(nvarchar(20),@counter)+''','''+convert(nvarchar(20), @curstarttime)+''','''+convert(nvarchar(20), @curendtime)+''','
				select @strsqlt = @strsqlt + ' C.componentid,O.operationno,CAST(CEILING(CAST(sum(A.partscount)as float)/ ISNULL(o.SubOperations,1))as integer ),E.EmployeeID from '
				select @strsqlt = @strsqlt +'autodata A '
				select @strsqlt = @strsqlt +' inner join ComponentInformation C on A.comp=C.interfaceid '
				select @strsqlt = @strsqlt +' inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
				select @strsqlt = @strsqlt +' INNER JOIN machineinformation M on A.mc=M.interfaceid'
				---mod 1
				select @strsqlt = @strsqlt +' and M.machineid=O.machineid '
				---mod 1
				SELECT @strsqlt = @strsqlt +' LEFT OUTER Join PlantMachine P on m.machineid = P.machineid '
				select @strsqlt = @strsqlt +' INNER JOIN EmployeeInformation E on A.Opr=E.interfaceid'
				select @strsqlt = @strsqlt +' LEFT OUTER JOIN PlantEmployee ON E.Employeeid = PlantEmployee.employeeID '
				select @strsqlt = @strsqlt +' WHERE A.DataType=1 And A.ndtime>'''+convert(nvarchar(20), @curstarttime)+'''  and A.Ndtime<='''+ convert(nvarchar(20),@curendtime)+''' '
				select @strsqlt = @strsqlt + @strmachinet + @strcomponentt + @stroperationt + @strPlantID
				select @strsqlt = @strsqlt + ' GROUP BY C.componentid,O.operationno,o.SubOperations,E.EmployeeID'
				print @strsqlt
				EXEC (@strsqlt)
					
				*/
				SELECT @strsqlt='INSERT INTO #OprProdData1(Pdate1,Fromtime,Totime,ComponentID,OperationID,CmpCount,OperatorID)'
				select @strsqlt = @strsqlt + 'select '''+convert(nvarchar(20),@counter)+''','''+convert(nvarchar(20), @curstarttime)+''','''+convert(nvarchar(20), @curendtime)+''','
				select @strsqlt = @strsqlt + ' C.componentid,O.operationno,CAST(CEILING(CAST(sum(T1.partscount)as float)/ ISNULL(o.SubOperations,1))as integer ),E.EmployeeID from '

				select @strsqlt = @strsqlt +'(Select mc,comp,opn,opr,sum(partscount)as partscount from  '
				select @strsqlt = @strsqlt +'autodata inner join machineinformation M on Autodata.mc=M.interfaceid'
				select @strsqlt = @strsqlt +' WHERE DataType=1 And ndtime>'''+convert(nvarchar(20), @curstarttime)+'''  and Ndtime<='''+ convert(nvarchar(20),@curendtime)+''' '
				select @strsqlt = @strsqlt + @strmachinet 
				select @strsqlt = @strsqlt + ' GROUP BY mc,comp,opn,opr) T1'
				select @strsqlt = @strsqlt +' inner join ComponentInformation C on T1.comp=C.interfaceid '
				select @strsqlt = @strsqlt +' inner join ComponentOperationPricing O on T1.opn=O.interfaceid and C.componentid=O.componentid '
				select @strsqlt = @strsqlt +' INNER JOIN machineinformation M on T1.mc=M.interfaceid'
				select @strsqlt = @strsqlt +' and M.machineid=O.machineid '
				--select @strsqlt = @strsqlt +' INNER JOIN EmployeeInformation E on A.Opr=E.interfaceid
--							      LEFT OUTER JOIN PlantMachine P ON M.machineid = P.MachineID LEFT OUTER JOIN
--						              PlantEmployee ON E.Employeeid = PlantEmployee.employeeID '
				select @strsqlt = @strsqlt +' INNER JOIN EmployeeInformation E on T1.Opr=E.interfaceid'
				select @strsqlt = @strsqlt +' LEFT OUTER JOIN PlantMachine P ON M.machineid = P.MachineID'

				if isnull(@PlantID,'') <> ''
				BEGIN	
					select @strsqlt = @strsqlt +' LEFT OUTER JOIN PlantEmployee ON E.Employeeid = PlantEmployee.employeeID '
				End
				
				select @strsqlt = @strsqlt + '  where 1=1 '+@strmachinet + @strcomponentt + @stroperationt + @strPlantID
				select @strsqlt = @strsqlt + ' GROUP BY C.componentid,O.operationno,o.SubOperations,E.EmployeeID'
				print @strsqlt
				EXEC (@strsqlt)



			--mod 4
				---mod 3
				---mod 3
				If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
				BEGIN
					select @strsql=' Insert into #PlannedDownTimes
					SELECT
					CASE When StartTime<''' + convert(nvarchar(20),@curstarttime,120) + ''' Then ''' + convert(nvarchar(20),@curstarttime,120) + '''  Else StartTime End As StartTime,
					CASE When EndTime>''' + convert(nvarchar(20),@curendtime,120) + '''  Then ''' + convert(nvarchar(20),@curendtime,120) + '''  Else EndTime End As EndTime,Machine
					FROM PlannedDownTimes
					WHERE (
					(StartTime >= ''' + convert(nvarchar(20),@curstarttime,120) + '''  AND EndTime <=''' + convert(nvarchar(20),@curendtime,120) + ''')
					OR ( StartTime < ''' + convert(nvarchar(20),@curstarttime,120) + '''  AND EndTime <= ''' + convert(nvarchar(20),@curendtime,120) + ''' AND EndTime > ''' + convert(nvarchar(20),@curstarttime,120) + ''' )
					OR ( StartTime >= ''' + convert(nvarchar(20),@curstarttime,120) + '''   AND StartTime <''' + convert(nvarchar(20),@curendtime,120) + ''' AND EndTime > ''' + convert(nvarchar(20),@curendtime,120) + ''' )
					OR ( StartTime < ''' + convert(nvarchar(20),@curstarttime,120) + '''  AND EndTime > ''' + convert(nvarchar(20),@curendtime,120) + ''') ) and PDTStatus=1 '
					if isnull(@Machine,'')<>''
					begin
						select @strsql=@strsql+' AND (PlannedDownTimes.machine =N'''+@Machine+''') '
					ENd
					select @strsql=@strsql+' ORDER BY StartTime'
					print @strsql
					exec (@strsql)
				END
				---mod 3
					--*******************************************************************************************************
				-- FOLLWING CODE IS ADDED BY SANGEETA KALLUR ON 27-FEB-2007 --
				SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
				SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
				From ProductionCountException Ex
				Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
				Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
				Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
				---mod 1
				SELECT @StrSql = @StrSql + ' and M.machineid=O.machineid '
				---mod 1
				SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 AND
						((Ex.StartTime>=  ''' + convert(nvarchar(20),@curstarttime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@curendtime)+''' )
						OR (Ex.StartTime< ''' + convert(nvarchar(20),@curstarttime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@curstarttime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@curendtime)+''')
						OR(Ex.StartTime>= ''' + convert(nvarchar(20),@curstarttime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@curendtime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@curendtime)+''')
						OR(Ex.StartTime< ''' + convert(nvarchar(20),@curstarttime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@curendtime)+''' ))'
				SELECT @StrSql = @StrSql + @StrxMachine + @strXcomponent + @strXoperation
				Exec (@strsql)
				SELECT @strsql=''



				IF (SELECT Count(*) from #Exceptions) <> 0
				BEGIN
					UPDATE #Exceptions SET StartTime=@curstarttime WHERE (StartTime<@curstarttime)AND EndTime>@curstarttime
					UPDATE #Exceptions SET EndTime=@curendtime WHERE (EndTime>@curendtime AND StartTime<@curendtime )
					Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
					(
						SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
						SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
					 	From (
							select M.MachineID,C.ComponentID,O.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
							Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
							Inner Join ComponentInformation C ON autodata.Comp = C.InterfaceID
							Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID '
					---mod 1
					SELECT @StrSql = @StrSql + ' and M.machineid=O.machineid '
					---mod 1
					SELECT @StrSql = @StrSql + ' Inner Join (
								Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
								)AS Tt1 ON Tt1.MachineID=M.MachineID AND Tt1.ComponentID = C.ComponentID AND Tt1.OperationNo= O.OperationNo and Tt1.MachineID=O.MachineID
							Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
					Select @StrSql = @StrSql+ @strmachinet + @strcomponentt + @stroperationt
					Select @StrSql = @StrSql+' Group by M.MachineID,C.ComponentID,O.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
						) as T1
					   	Inner join componentinformation C on T1.Comp=C.interfaceid
					   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and T1.MachineID=O.MachineID
					  	GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
					)AS T2
					WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
					AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
					Exec(@StrSql)


					---mod 3
					If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
					BEGIN
					
					Select @StrSql =''
					Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
					From
					(
						SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
						SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
						From
						(
							select M.MachineID,C.ComponentID,O.OperationNo,comp,opn,
							Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
							Inner Join MachineInformation  M ON autodata.MC=M.InterfaceID
							Inner Join ComponentInformation  C ON autodata.Comp = C.InterfaceID
							Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID and O.MachineID=M.MachineID
							Inner Join	
							(
								SELECT MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
								CASE
									WHEN (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime) THEN Ex.StartTime
									WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.StartTime
									ELSE Td.StartTime
								END AS PLD_StartTime,
								CASE
									WHEN (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime) THEN Ex.EndTime
									WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.EndTime
									ELSE  Td.EndTime
								END AS PLD_EndTime
					
								From #Exceptions AS Ex INNER JOIN #PlannedDownTimes AS Td on Td.Machine=Ex.MachineID
								Where ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
								(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
								(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
								(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'
						Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=M.MachineID AND T1.ComponentID = C.ComponentID AND T1.OperationNo= O.OperationNo and T1.MachineID=O.MachineID
						Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
						AND (autodata.ndtime > ''' + convert(nvarchar(20),@curStartTime,120)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@curendtime,120)+''' )'
						Select @StrSql = @StrSql + @strmachinet + @strcomponentt + @stroperationt
						Select @StrSql = @StrSql+' Group by M.MachineID,C.ComponentID,O.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn
						)AS T2
						Inner join componentinformation C on T2.Comp=C.interfaceid
						Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and T2.MachineID=O.MachineID
						GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime
					)As T3
					WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
					AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'
					
						EXEC(@StrSql)
					END
					---mod 3
					UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
					
				END


			----Day-----
				---mod 3
				If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
				BEGIN
					 Select @StrSql = 'UPDATE #OprProdData1 SET CmpCount = ISNULL(CmpCount,0) - ISNULL(T2.comp,0)
					from
					(
						select Min(StartTime)StartTime,Max(EndTime)EndTime,E.EmployeeID,C.ComponentID As ComponentID,O.OperationNo As OperationNo,
						CEILING (CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(O.SubOperations,1)) as comp
					 	From Autodata A
						Inner join componentinformation C on A.Comp=C.interfaceid
				   		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid
						Inner Join EmployeeInformation E On A.Opr=E.Interfaceid
						Inner join MachineInformation M ON A.Mc=M.InterfaceID  and O.MachineID=M.MachineID
						Inner jOIN #PlannedDownTimes T on T.Machine=M.MachineID  WHERE A.DataType=1
						AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
						AND(A.ndtime > '''+Convert(NVarChar(20),@curStartTime,120)+'''  AND A.ndtime <='''+Convert(NVarChar(20),@curEndTime,120)+''') '
				    Select @StrSql = @StrSql + @strmachinet + @strcomponentt + @stroperationt	
				    Select @StrSql = @StrSql + ' Group By C.ComponentID,O.OperationNo,O.SubOperations,E.EmployeeID
						) as T2 inner join #OprProdData1 on T2.EmployeeID=#OprProdData1.OperatorID AND #OprProdData1.Componentid=T2.ComponentID AND #OprProdData1.OperationID=T2.OperationNo
					AND T2.StartTime>= #OprProdData1.FromTime And T2.EndTime<=#OprProdData1.ToTime'
					EXEC (@StrSql)
				END
				delete from #PlannedDownTimes

				---mod 3
				UPDATE #OprProdData1 SET CmpCount = ISNULL(Tt.OpnCount,0)
				FROM
				(
					SELECT StartTime,EndTime,OperatorID,Ti.Componentid,Ti.OperationNo,(CmpCount-(CmpCount*(Ti.Ratio)))AS OpnCount
					FROM #OprProdData1 Left Outer Join
					(
						SELECT Min(FromTime)StartTime,Max(ToTime)EndTime,
						#Exceptions.Componentid,#Exceptions.OperationNo,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
						FROM #Exceptions  Inner Join (
							SELECT FromTime,ToTime,Componentid,OperationID,SUM(CmpCount)AS tCount
							FROM #OprProdData1
							Where FromTime=@curstarttime And ToTime=@curendtime
							Group By  Componentid,OperationID ,FromTime,ToTime
							)T1 ON  T1.Componentid=#Exceptions.Componentid AND T1.OperationID=#Exceptions.OperationNo
						Group By  #Exceptions.Componentid,#Exceptions.OperationNo
					)Ti ON  Ti.Componentid=#OprProdData1.Componentid AND Ti.OperationNo=#OprProdData1.OperationID
					AND Ti.StartTime >=#OprProdData1.FromTime AND Ti.EndTime<=#OprProdData1.ToTime
				) AS Tt Inner Join #OprProdData1 ON
				Tt.Componentid=#OprProdData1.Componentid AND Tt.OperationNo=#OprProdData1.OperationID AND Tt.OperatorID=#OprProdData1.OperatorID
				AND Tt.StartTime>=#OprProdData1.FromTime AND Tt.EndTime<=#OprProdData1.ToTime
				DELETE FROM #Exceptions
	
		--*******************************************************************************************************
			SELECT @curstarttime = Dateadd(Day,1, @curstarttime)
			SELECT @counter = Dateadd(Day,1,@counter)	
		END
			SELECT @strsqlt=''
			SELECT @strsqlt='Insert into #DownTemp(PDate,FromTime,Totime,CompID,OpnID,CompCount,OperatorID)'
			SELECT @strsqlt=@strsqlt+ ' select  Pdate1,Fromtime, Totime,ComponentID,OperationID,CmpCount,OperatorID From #OprProdData1'
			EXEC (@strsqlt)
	END ---End for @ComparisonParam='OprtProdCount'
		IF @ComparisonParam='CompSearch'
		BEGIN
			DECLARE @strsqltc as nvarchar(2000)
			declare @strmachinetc nvarchar(255)
			declare @stroperationtc nvarchar(255)
			
			select @strsqltc = ''
			select @strmachinetc = ''
			select @stroperationtc = ''
			if isnull(@Machine,'') <> ''
			begin
			---mod 2
--			select @strmachinetc = ' AND ( M.machineid = ''' + @Machine+ ''')'
			select @strmachinetc = ' AND ( M.machineid = N''' + @Machine+ ''')'
			----mod 2
			end
			
			if isnull(@Operation, '') <> ''
			begin
			---mod 2
--			select @stroperationtc = ' AND ( O.Operationno = ''' + @Operation + ''')'
			select @stroperationtc = ' AND ( O.Operationno = N''' + @Operation + ''')'
			---mod 2
			end
			
			SELECT @strsqltc='select  top 5 C.Componentid,O.Operationno,M.Machineid, '
			SELECT @strsqltc = @strsqltc + 'CAST(YEAR(A.nddate)as nvarchar(4))+'+ '''-''' + '+CAST(Month(A.nddate)as nvarchar(2))+'+ '''-'''+ '+CAST(Day(A.nddate)as nvarchar(2)) as Date from '
			SELECT @strsqltc = @strsqltc + 'autodata A LEFT OUTER JOIN componentinformation C on A.comp=C.Interfaceid '
			select @strsqltc = @strsqltc + 'LEFT OUTER join Componentoperationpricing O on A.opn=O.Interfaceid and C.componentid=O.componentid '
			SELECT @strsqltc = @strsqltc + 'inner join machineinformation M on A.mc=M.Interfaceid '
			SELECT @strsqltc = @strsqltc +' LEFT OUTER Join PlantMachine P on m.machineid = P.machineid '
			---mod 2
--			SELECT @strsqltc = @strsqltc + 'WHERE C.Componentid=''' + @Component+ ''' '
			SELECT @strsqltc = @strsqltc + 'WHERE C.Componentid = N''' + @Component+ ''' '
			---mod 2
			SELECT @strsqltc = @strsqltc + @strmachinetc + @stroperationtc + @strPlantID
			SELECT @strsqltc = @strsqltc + 'Group by M.Machineid,C.Componentid,O.Operationno,A.nddate '
			SELECT @strsqltc = @strsqltc + 'Order by M.Machineid ASC,A.nddate Desc '
			
			print @strsqltc
			EXEC (@strsqltc)
			
		END
			
End
-------------------------------------------------------------------------------------------------------------------------			

if @TimeAxis='Shift'
Begin
	DECLARE @Mch_Value AS nvarchar(50)
	DECLARE @Reason_Value as Nvarchar(50)
	DECLARE @Comp_Value as nvarchar(50)
	DECLARE @Opn_Value as nvarchar(20)
	DECLARE @TmpStTime as datetime
	DECLARE @TmpNdTime as DateTime
	DECLARE @TmpPdate as DateTime
	DECLARE @TmpShiftName as nvarchar(40)
	DECLARE PRptCursor  Cursor  For
	SELECT PDate,ShiftName,FromTime,ToTime From #DownTemp
	IF @ComparisonParam='DownTime'
	BEGIN
		While(@counter <= @EndTime)
			BEGIN
				
				Insert into #DownTemp(PDate,ShiftName, FromTime, ToTime)
				Exec s_GetShiftTime @counter,@ShiftName
				SELECT @counter = Dateadd(Day,1,@counter)
			
			END
		Open PRptCursor
		FETCH NExt From PRptCursor into @TmpPdate,@TmpShiftName,@TmpStTime,@TmpNdTime
		While(@@Fetch_Status=0)
			BEGIN
				Insert into #ShiftTemp(FromTime,Totime,Downtime)
				Exec s_GetDownTimeReportfromAutoData @TmpStTime,@TmpNdTime,@Machine,@DownReason,'','','','','','','DTimeOnly',@PlantID,@Exclude
				Update #ShiftTemp SET PDate=@TmpPdate,ShiftName=@TmpShiftName Where FromTime=@TmpStTime and Totime=@TmpNdTime
				FETCH NExt From PRptCursor into @TmpPdate,@TmpShiftName,@TmpStTime,@TmpNdTime
			END
			
		close PRptCursor
		deallocate PRptCursor
	END

	IF @ComparisonParam='ProdCount' or @ComparisonParam='ProdGraph'
	BEGIN
		DECLARE RptCursor  Cursor  For
		SELECT PDate,ShiftName,FromTime,ToTime From #DownTemp
	   	While(@counter <= @EndTime)
		BEGIN
			Insert into #DownTemp(PDate,ShiftName, FromTime, ToTime)
			Exec s_GetShiftTime @counter,@ShiftName
			SELECT @counter = Dateadd(Day,1,@counter)
		END
			
		Open RptCursor
		FETCH NExt From RptCursor into @TmpPdate,@TmpShiftName,@TmpStTime,@TmpNdTime
		While(@@Fetch_Status=0)
			BEGIN
				Insert into #ShiftTemp(FromTime,Totime,CompID,OpnID,CompCount)
				EXEC s_GetComponentProdDataFromAutodata @TmpStTime,@TmpNdTime,@Machine,@Component,@Operation,@PlantID
				Update #ShiftTemp SET PDate=@TmpPdate,ShiftName=@TmpShiftName Where FromTime=@TmpStTime and Totime=@TmpNdTime
				FETCH NExt From RptCursor into @TmpPdate,@TmpShiftName,@TmpStTime,@TmpNdTime
			END
		close RptCursor
		deallocate RptCursor
	Declare @strmachine1 nvarchar(255)
	Declare @stroperation1 nvarchar(255)
	Declare @strcomponent1 nvarchar(255)
	Declare @strShift1 nvarchar(255)
	declare @TrSql1 nvarchar(2000)
	SELECT @strmachine1 = ''
	SELECT @strcomponent1 = ''
	SELECT @stroperation1 = ''
	SELECT @strShift1=''
	if isnull(@Machine,'') <> ''
		BEGIN
		---mod 2
--		SELECT @strmachine1 = ' AND ( machine = ''' + @Machine+ ''')'
		SELECT @strmachine1 = ' AND ( machine = N''' + @Machine+ ''')'
		---mod 2
		END
	if isnull(@Component, '') <> ''
		BEGIN
		---mod 2
--		SELECT @strcomponent1 = ' AND ( component = ''' + @Component+ ''')'
		SELECT @strcomponent1 = ' AND ( component = N''' + @Component+ ''')'
		---mod 2
		END
	if isnull(@Operation, '') <> ''
		BEGIN
		---mod 2
--		SELECT @stroperation1 = ' AND ( operation = ''' + @Operation + ''')'
		SELECT @stroperation1 = ' AND ( operation = N''' + @Operation + ''')'
		---mod 2
		END
	if isnull(@ShiftName,'')<> ''
		BEGIN
		---mod 2
--		SELECT @strShift1=' AND (shift=''' +@ShiftName+ ''') '
		SELECT @strShift1=' AND (shift=N''' +@ShiftName+ ''') '
		---mod 2
		END
		
	if isnull(@Targetsource,'')='Exact Schedule'
	 BEGIN
		select @strsqlt=''
	
	--select * from #shifttemp
	     select @TrSql1 = 'update #shifttemp set Targetcount= ISNULL(targetcount,0) + ISNULL(t1.tcount,0) from
						( select date as date1,shift,machine,component,operation,idealcount as tcount from
						loadschedule where date>=''' +convert(nvarchar(20),@starttime)+''' and date<=''' +convert(nvarchar(20),@EndTime)+ ''' '
		 select @TrSql1 = @TrSql1 + @strmachine1 + @strcomponent1 + @stroperation1 + @strShift1
	     select @TrSql1 = @TrSql1+ ') as t1 inner join #shifttemp on
						t1.date1=#shifttemp.pdate and t1.shift=#Shifttemp.shiftName and t1.component=#shifttemp.CompID
						and t1.operation=#shiftTemp.OpnId '
		print @TrSql1
		exec(@TrSql1)	
	END
	
		IF isnull(@Targetsource,'')='Default Target per CO'
		BEGIN
			PRINT @Targetsource
			select @TrSql1=''
			select @TrSql1='update #Shifttemp set Targetcount= isnull(Targetcount,0)+ ISNULL(t1.tcount,0) from
					( select DATE AS date1, machine,component,operation,sum(idealcount) as tcount from
				  	loadschedule where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC) and SHIFT=(SELECT TOP 1 SHIFT FROM LOADSCHEDULE ORDER BY SHIFT DESC)'
		        select @TrSql1= @TrSql1 + @strmachine1 + @strcomponent1 + @stroperation1
			select @TrSql1=@TrSql1+ ' group by date,machine,component,operation ) as t1 inner join #Shifttemp on
				  	t1.component=#Shifttemp.CompID
				  	and t1.operation=#Shifttemp.OpnId '	
			PRINT @TrSql1
			EXEC (@TrSql1)
			--select * from #Shifttemp
			--return
						
		END
		IF ISNULL(@Targetsource,'')='% Ideal'
		BEGIN
			select @strmachine1=''
			if isnull(@Machine,'') <> ''
			BEGIN
			---mod 2
--			SELECT @strmachine1 = ' AND ( CO.machineID = ''' + @Machine+ ''')'
			SELECT @strmachine1 = ' AND ( CO.machineID = N''' + @Machine+ ''')'
			---mod 2
			END
			select @strcomponent1=''
			if isnull(@Component, '') <> ''
			BEGIN
			---mod 2
--			SELECT @strcomponent1 = ' AND (CO.componentID = ''' + @Component+ ''')'
			SELECT @strcomponent1 = ' AND (CO.componentID = N''' + @Component+ ''')'
			---mod 2
			END
			select @stroperation1=''
			if isnull(@Operation, '') <> ''
			BEGIN
			---mod 2
--			SELECT @stroperation1 = ' AND ( CO.operationno = ''' + @Operation + ''')'
			SELECT @stroperation1 = ' AND ( CO.operationno = N''' + @Operation + ''')'
			---mod 2
			END
			--select TrgtCt from #DownTemp
		    select @TrSql1=''
			select @TrSql1='update #Shifttemp set Targetcount= isnull(Targetcount,0)+ ISNULL(t1.tcount,0) from
					 ( select CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#Shifttemp.Fromtime,#Shifttemp.Totime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
					from componentoperationpricing CO inner join #Shifttemp on CO.Componentid=#Shifttemp.CompID
					and Co.operationno=#Shifttemp.OpnID '
			select @TrSql1= @TrSql1 + @strmachine1 + @strcomponent1 + @stroperation1
			select @TrSql1=@TrSql1+ '  ) as t1 inner join #Shifttemp on
				  	t1.component=#Shifttemp.CompID
				  	and t1.operation=#Shifttemp.OpnId '	
			PRINT @TrSql1
			EXEC (@TrSql1)
			--select * from #Shifttemp
			--return
		
		END
	END
	
	IF @ComparisonParam='OprtShift'
	BEGIN
		select @strsqlt = ''
		select @strmachinet = ''
		select @strcomponentt = ''
		select @stroperationt = ''
		
		if isnull(@Machine,'') <> ''
		begin
		---mod 2
--		select @strmachinet = ' AND ( M.machineid = ''' + @Machine+ ''')'
		select @strmachinet = ' AND ( M.machineid = N''' + @Machine+ ''')'
		---mod 2
		end
	        if isnull(@Component, '') <> ''
		begin
		---mod 2
--		select @strcomponentt = ' AND ( C.componentid = ''' + @Component+ ''')'
		select @strcomponentt = ' AND ( C.componentid = N''' + @Component+ ''')'
		---mod 2
		end
		if isnull(@Operation, '') <> ''
		begin
		---mod 2
--		select @stroperationt = ' AND ( O.Operationno = ''' + @Operation + ''')'
		select @stroperationt = ' AND ( O.Operationno = N''' + @Operation + ''')'
		---mod 2
		end
		DECLARE RptCursor  Cursor  For
		SELECT PDate,ShiftName,FromTime,ToTime From #DownTemp
		While(@counter <= @EndTime)
			BEGIN
					
				Insert into #DownTemp(PDate,ShiftName, FromTime, ToTime)
				Exec s_GetShiftTime @counter,@ShiftName
				SELECT @counter = Dateadd(Day,1,@counter)
				
			END
					
		Open RptCursor
		FETCH NExt From RptCursor into @TmpPdate,@TmpShiftName,@TmpStTime,@TmpNdTime
		While(@@Fetch_Status=0)
			BEGIN

				SELECT @strsqlt='INSERT INTO #ShiftTemp(FromTime,Totime,CompID,OpnID,CompCount,Oprtname)'
				select @strsqlt = @strsqlt + 'select '''+convert(nvarchar(20),@TmpStTime)+''','''+convert(nvarchar(20), @TmpNdTime)+''','
				select @strsqlt = @strsqlt + 'C.componentid,O.operationno,CAST(CEILING(CAST(sum(A.partscount)as float)/ ISNULL(o.SubOperations,1))as integer ),E.EmployeeID from '
			---mod 4
				--select @strsqlt = @strsqlt +' autodata A '
					select @strsqlt = @strsqlt +'(Select mc,comp,opn,opr,sum(partscount)as partscount from  '
					select @strsqlt = @strsqlt +'autodata inner join machineinformation M on Autodata.mc=M.interfaceid'
					select @strsqlt = @strsqlt +' WHERE DataType=1 And ndtime>'''+convert(nvarchar(25), @TmpStTime,120)+'''  and Ndtime<='''+ convert(nvarchar(25),@TmpNdTime,120)+''' '
					select @strsqlt = @strsqlt + @strmachinet 
					 select @strsqlt = @strsqlt + ' GROUP BY mc,comp,opn,opr) A'
			--mod 4
				select @strsqlt = @strsqlt +' inner join ComponentInformation C on A.comp=C.interfaceid '
				select @strsqlt = @strsqlt +' inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
				select @strsqlt = @strsqlt +' INNER JOIN machineinformation M on A.mc=M.interfaceid'
				---mod 1
				select @strsqlt = @strsqlt +' and M.machineid=O.machineid '
				---mod 1
			---Mod 4
--select @strsqlt = @strsqlt +' INNER JOIN EmployeeInformation E on A.Opr=E.interfaceid
--							      LEFT OUTER JOIN PlantMachine P ON M.machineid = P.MachineID LEFT OUTER JOIN
--						              PlantEmployee ON E.Employeeid = PlantEmployee.employeeID '
				select @strsqlt = @strsqlt +' INNER JOIN EmployeeInformation E on A.Opr=E.interfaceid'
				select @strsqlt = @strsqlt +' LEFT OUTER JOIN PlantMachine P ON M.machineid = P.MachineID'

				if isnull(@PlantID,'') <> ''
				BEGIN	
					select @strsqlt = @strsqlt +' LEFT OUTER JOIN PlantEmployee ON E.Employeeid = PlantEmployee.employeeID '
				End

			--select @strsqlt = @strsqlt +' WHERE A.DataType=1 And A.ndtime>'''+convert(nvarchar(20), @TmpStTime)+'''  and A.Ndtime<='''+ convert(nvarchar(20),@TmpNdTime)+''' '
				select @strsqlt = @strsqlt +' WHERE 1=1'
			--mod 4
				select @strsqlt = @strsqlt + @strmachinet + @strcomponentt + @stroperationt + @strPlantID
				select @strsqlt = @strsqlt + ' GROUP BY C.componentid,O.operationno,o.SubOperations,E.EmployeeID'
				print(@strsql)
				
				EXEC (@strsqlt)
				

				
				---mod 3
				If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
				BEGIN
					select @strsql=' Insert into #PlannedDownTimes
					SELECT
					CASE When StartTime<''' + convert(nvarchar(20),@TmpStTime,120) + ''' Then ''' + convert(nvarchar(20),@TmpStTime,120) + '''  Else StartTime End As StartTime,
					CASE When EndTime>''' + convert(nvarchar(20),@TmpStTime,120) + '''  Then ''' + convert(nvarchar(20),@TmpNdTime,120) + '''  Else EndTime End As EndTime,Machine
					FROM PlannedDownTimes
					WHERE (
					(StartTime >= ''' + convert(nvarchar(20),@TmpStTime,120) + '''  AND EndTime <=''' + convert(nvarchar(20),@TmpNdTime,120) + ''')
					OR ( StartTime < ''' + convert(nvarchar(20),@TmpStTime,120) + '''  AND EndTime <= ''' + convert(nvarchar(20),@TmpNdTime,120) + ''' AND EndTime > ''' + convert(nvarchar(20),@TmpStTime,120) + ''' )
					OR ( StartTime >= ''' + convert(nvarchar(20),@TmpStTime,120) + '''   AND StartTime <''' + convert(nvarchar(20),@TmpNdTime,120) + ''' AND EndTime > ''' + convert(nvarchar(20),@TmpNdTime,120) + ''' )
					OR ( StartTime < ''' + convert(nvarchar(20),@TmpStTime,120) + '''  AND EndTime > ''' + convert(nvarchar(20),@TmpNdTime,120) + ''') ) and PDTStatus=1 '
					if isnull(@Machine,'')<>''
					begin
						select @strsql=@strsql+' AND (PlannedDownTimes.machine =N'''+@Machine+''') '
					ENd
					select @strsql=@strsql+' ORDER BY StartTime'
					print @strsql
					exec (@strsql)
				END
				---mod 3
				
			--*******************************************************************************************************
					-- FOLLWING CODE IS ADDED BY SANGEETA KALLUR ON 27-FEB-2007 --
			SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
					SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
					From ProductionCountException Ex
					Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
					Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
					Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
			---mod 1
			SELECT @StrSql = @StrSql + ' and O.machineid=Ex.machineid '
			---mod 1
			SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 AND
					((Ex.StartTime>=  ''' + convert(nvarchar(20),@TmpStTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@TmpNdTime)+''' )
					OR (Ex.StartTime< ''' + convert(nvarchar(20),@TmpStTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@TmpStTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@TmpNdTime)+''')
					OR(Ex.StartTime>= ''' + convert(nvarchar(20),@TmpStTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@TmpNdTime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@TmpNdTime)+''')
					OR(Ex.StartTime< ''' + convert(nvarchar(20),@TmpStTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@TmpNdTime)+''' ))'
			SELECT @StrSql = @StrSql + @StrxMachine + @strXcomponent + @strXoperation
			print @strsql
			Exec (@strsql)
			


			

			SELECT @strsql=''
			IF (SELECT Count(*) from #Exceptions) <> 0
			BEGIN
				UPDATE #Exceptions SET StartTime=@TmpStTime WHERE (StartTime<@TmpStTime)AND EndTime>@TmpStTime
				UPDATE #Exceptions SET EndTime=@TmpNdTime WHERE (EndTime>@TmpNdTime AND StartTime<@TmpNdTime )
				Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
				(
					SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
					SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
				 	From (
						select M.MachineID,C.ComponentID,O.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
						Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
						Inner Join ComponentInformation C ON autodata.Comp = C.InterfaceID
						Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID '
				---mod 1
				SELECT @StrSql = @StrSql + ' and M.machineid=O.machineid '
				---mod 1
				SELECT @StrSql = @StrSql +' Inner Join (
							Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
							)AS Tt1 ON Tt1.MachineID=M.MachineID AND Tt1.ComponentID = C.ComponentID AND Tt1.OperationNo= O.OperationNo and Tt1.MachineID=O.MachineId
						Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
				Select @StrSql = @StrSql+ @strmachinet + @strcomponentt + @stroperationt
				Select @StrSql = @StrSql+' Group by M.MachineID,C.ComponentID,O.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
					) as T1
				   	Inner join componentinformation C on T1.Comp=C.interfaceid
				   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and T1.MachineId=O.MachineID
				  	GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
				)AS T2
				WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
				AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
				Exec(@StrSql)
				
				---mod 3
				If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
				BEGIN
				
				Select @StrSql =''
				Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
				From
				(
					SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
					SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
					From
					(
						select M.MachineID,C.ComponentID,O.OperationNo,comp,opn,
						Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
						Inner Join MachineInformation  M ON autodata.MC=M.InterfaceID
						Inner Join ComponentInformation  C ON autodata.Comp = C.InterfaceID
						Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID and O.MachineId=M.MachineID
						Inner Join	
						(
							SELECT MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
							CASE
								WHEN (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime) THEN Ex.StartTime
								WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.StartTime
								ELSE Td.StartTime
							END AS PLD_StartTime,
							CASE
								WHEN (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime) THEN Ex.EndTime
								WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.EndTime
								ELSE  Td.EndTime
							END AS PLD_EndTime
				
							From #Exceptions AS Ex Inner JOIN #PlannedDownTimes AS Td on Td.Machine=Ex.MachineID
							Where ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
							(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
							(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
							(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'
						Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=M.MachineID AND T1.ComponentID = C.ComponentID AND T1.OperationNo= O.OperationNo and T1.MachineId=O.MachineID
						Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
						AND (autodata.ndtime > ''' + convert(nvarchar(20),@TmpStTime,120)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@TmpNdTime,120)+''' )'
						Select @StrSql = @StrSql + @strmachinet + @strcomponentt + @stroperationt
						Select @StrSql = @StrSql+' Group by M.MachineID,C.ComponentID,O.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn
						)AS T2
						Inner join componentinformation C on T2.Comp=C.interfaceid
						Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid  and T2.MachineID=O.MachineID
						GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime
					)As T3
					WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
					AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'
					
					EXEC(@StrSql)
					
					END
					---mod 3
				UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
				
			END

			
			---mod 3
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'

	/*	--DR0247 - By KarthikR - 10/Aug/2010	
			BEGIN
				Select @StrSql = ' UPDATE #ShiftTemp SET CompCount = ISNULL(CompCount,0) - ISNULL(T2.comp,0)
				from
				(
					select Min(StartTime)StartTime,Max(EndTime)EndTime,E.EmployeeID,C.ComponentID As ComponentID,O.OperationNo As OperationNo,
					CEILING (CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(O.SubOperations,1)) as comp
				 	From Autodata A
						Inner join componentinformation C on A.Comp=C.interfaceid
				   		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid
						Inner Join EmployeeInformation E On A.Opr=E.Interfaceid
						Inner Join MachineInformation M on A.Mc=M.Interfaceid and O.MachineId=M.MachineId
						Inner jOIN #PlannedDownTimes T On T.MachineId=M.MachineId  WHERE A.DataType=1  ----DR0247 - By KarthikR - 10/Aug/2010	
						AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
						AND(A.ndtime > '''+Convert(NVarChar(20),@TmpStTime,120)+'''  AND A.ndtime <='''+Convert(NVarChar(20),@TmpNdTime,120)+''') '
				Select @StrSql = @StrSql + @strmachinet + @strcomponentt + @stroperationt
				Select @StrSql = @StrSql +' Group By C.ComponentID,O.OperationNo,O.SubOperations, E.EmployeeID
				) as T2 inner join #ShiftTemp on T2.EmployeeID=#ShiftTemp.OprtName AND #ShiftTemp.Compid=T2.ComponentID AND #ShiftTemp.OpnID=T2.OperationNo
				AND T2.StartTime>= #ShiftTemp.FromTime And T2.EndTime<=#ShiftTemp.ToTime'
			print(@StrSql)				
			EXEC(@StrSql)
			END
*/
			
			BEGIN
				Select @StrSql = ' UPDATE #ShiftTemp SET CompCount = ISNULL(CompCount,0) - ISNULL(T2.comp,0)
				from
				(
					select Min(StartTime)StartTime,Max(EndTime)EndTime,E.EmployeeID,C.ComponentID As ComponentID,O.OperationNo As OperationNo,
					CEILING (CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(O.SubOperations,1)) as comp
				 	From Autodata A
						Inner join componentinformation C on A.Comp=C.interfaceid
				   		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid
						Inner Join EmployeeInformation E On A.Opr=E.Interfaceid
						Inner Join MachineInformation M on A.Mc=M.Interfaceid and O.MachineId=M.MachineId
						Inner jOIN #PlannedDownTimes T On T.Machine=M.MachineId  WHERE A.DataType=1 
						AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
						AND(A.ndtime > '''+Convert(NVarChar(20),@TmpStTime,120)+'''  AND A.ndtime <='''+Convert(NVarChar(20),@TmpNdTime,120)+''') '
				Select @StrSql = @StrSql + @strmachinet + @strcomponentt + @stroperationt
				Select @StrSql = @StrSql +' Group By C.ComponentID,O.OperationNo,O.SubOperations, E.EmployeeID
				) as T2 inner join #ShiftTemp on T2.EmployeeID=#ShiftTemp.OprtName AND #ShiftTemp.Compid=T2.ComponentID AND #ShiftTemp.OpnID=T2.OperationNo
				AND T2.StartTime>= #ShiftTemp.FromTime And T2.EndTime<=#ShiftTemp.ToTime'
			print(@StrSql)				
			EXEC(@StrSql)
			END
--DR0247 - By KarthikR - 10/Aug/2010	
			delete from #PlannedDownTimes

			---mod 3
				
			UPDATE #ShiftTemp SET COmpCount = ISNULL(Tt.OpnCount,0)
				FROM
				(
					SELECT StartTime,EndTime,OprtName,Ti.Componentid,Ti.OperationNo,(COmpCount-(COmpCount*(Ti.Ratio)))AS OpnCount
					FROM #ShiftTemp Left Outer Join
					(
						SELECT Min(FromTime)StartTime,Max(ToTime)EndTime,
						#Exceptions.Componentid,#Exceptions.OperationNo,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
						FROM #Exceptions  Inner Join (
							SELECT FromTime,ToTime,Compid,OpnID,SUM(COmpCount)AS tCount
							FROM #ShiftTemp
							Where FromTime=@TmpStTime And ToTime=@TmpNdTime
							Group By  Compid,OpnID,FromTime,ToTime
							)T1 ON  T1.Compid=#Exceptions.Componentid AND T1.OpnID=#Exceptions.OperationNo
						Group By  #Exceptions.Componentid,#Exceptions.OperationNo
					)Ti ON  Ti.Componentid=#ShiftTemp.Compid AND Ti.OperationNo=#ShiftTemp.OpnID
					AND Ti.StartTime >=#ShiftTemp.FromTime AND Ti.EndTime<=#ShiftTemp.ToTime
				) AS Tt Inner Join #ShiftTemp ON
				Tt.Componentid=#ShiftTemp.Compid AND Tt.OperationNo=#ShiftTemp.OpnID AND Tt.OprtName=#ShiftTemp.OprtName
				AND Tt.StartTime>=#ShiftTemp.FromTime AND Tt.EndTime<=#ShiftTemp.ToTime
				DELETE FROM #Exceptions
--*******************************************************************************************************
				Update #ShiftTemp SET PDate=@TmpPdate,ShiftName=@TmpShiftName
				Where FromTime= '' + cast(@TmpStTime as NVARCHAR(20))+ '' and Totime=''+ cast(@TmpNdTime as NVARCHAR(20)) +''
				FETCH NExt From RptCursor into @TmpPdate,@TmpShiftName,@TmpStTime,@TmpNdTime
			END
			
		close RptCursor
		deallocate RptCursor
	END
			
/*
IF @ComparisonParam='AE' or @ComparisonParam='PE' or @ComparisonParam='OE'
	BEGIN
		Delete from #ShiftTemp
		While(@counter <= @EndTime)
		BEGIN
			Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)
			Exec s_GetShiftTime @counter,@ShiftName
			SELECT @counter = Dateadd(Day,1,@counter)
		END
		DECLARE EffiRptCursor  Cursor  For
			SELECT Pdate,ShiftName,FromTime,ToTime From #ShiftTemp
		Open EffiRptCursor
		FETCH NExt From EffiRptCursor into @TmpPdate,@TmpShiftName,@curstarttime,@curendtime
		While(@@Fetch_Status=0)
		BEGIN
				INSERT INTO #DownTemp(FromTime,Totime,Machine,AE,PE,OE,CompCount)
				EXEC dbo.s_GetEfficiencyFromAutodata @curstarttime ,@curendtime ,@Machine,@PlantID
		
				UPDATE #DownTemp SET PDate=@TmpPdate where FromTime=@curstarttime and ToTime=@curendtime
				UPDATE #DownTemp SET ShiftName=@TmpShiftName where FromTime=@curstarttime and ToTime=@curendtime
			FETCH NExt From EffiRptCursor into @TmpPdate,@TmpShiftName,@curstarttime,@curendtime
		END
		close EffiRptCursor
		deallocate EffiRptCursor
		DECLARE @strShiftName  nvarchar(200)
		SET @strShiftName = ''
		SET @strmachine = ''
		if isnull(@Machine,'') <> ''
			BEGIN
			SELECT @strmachine = ' AND ( ShiftProductionDetails.machineid = ''' + @Machine+ ''')'
			END
		if isnull(@ShiftName, '') <> ''
			BEGIN
			SELECT @strShiftName = ' AND ( ShiftProductionDetails.Shift = ''' + @ShiftName+ ''')'
			END
		SELECT @StrSql= ' UPDATE #DownTemp SET #DownTemp.Rejection = ISNULL(t.RejectionSUM,0) '
		SELECT @StrSql=@StrSql+ ' From '
		SELECT @StrSql=@StrSql+ '(Select ShiftProductionDetails.Date,Shift,MachineID,SUM(ShiftRejectionDetails.Rejection_Qty) as RejectionSum'
		SELECT @StrSql=@StrSql+ ' From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON'
		SELECT @StrSql=@StrSql+ ' ShiftProductionDetails.ID=ShiftRejectionDetails.ID'
		SELECT @StrSql=@StrSql+ ' WHERE ShiftProductionDetails.Date >='''+ Convert(Nvarchar(20),@StartTime)+''''
		SELECT @StrSql=@StrSql+ ' AND ShiftProductionDetails.Date <='''+ Convert(Nvarchar(20),@EndTime)+''''
		SELECT @StrSql=@StrSql + @strmachine + @strShiftName
		SELECT @StrSql=@StrSql +' GROUP by ShiftProductionDetails.Date,ShiftProductionDetails.MachineID,ShiftProductionDetails.shift) as t '
		SELECT @StrSql=@StrSql +' inner join #DownTemp on #DownTemp.Pdate = t.Date and #DownTemp.shiftname = t.shift and #DownTemp.machine = t.machineID '
		Print (@StrSql)
		EXEC(@StrSql)		
	
	SELECT cast(cast(DateName(month,pdate) as nvarchar(3))+ ' '+cast(datepart(dd,Pdate)as nvarchar(2))+ ' Shift-' +cast(ShiftName as nvarchar(20)) as Nvarchar(50)) as Day,
		'Shift-'+cast(ShiftName as nvarchar(20)) as Shift,
				PDate,ShiftName,FromTime,Totime,Machine,AE,PE,
		'OEE' = CASE
			WHEN isnull(CompCount,0) <> 0 then OE * (CompCount - isnull(rejection,0))/CompCount
			END,
	CompCount,Rejection
	FROM #DownTemp
	return;
	END
*/
END
IF @TimeAxis='Month'
BEGIN
	IF  @ComparisonParam='DownTime'
	BEGIN
		While (@Counter <=@EndTime)	
		BEGIN
			SELECT @curstarttime=dbo.f_GetLogicalMonth(@curstarttime,'Start')
			IF @curstarttime<@StartTime
				BEGIN
					SELECT @curstarttime=dbo.f_GetLogicalMonth(@StartTime,'Start')
				END
			SELECT @curendtime=dbo.f_GetLogicalMonth(@curstarttime,'End')
			IF @curendtime > @EndTime
				BEGIN
				 SELECT @curendtime=dbo.f_GetLogicalDay(@EndTime,'End')
				END
			Insert into #DownTemp(FromTime,Totime,Downtime)
			Exec s_GetDownTimeReportfromAutoData @curstarttime,@curendtime,@Machine,@DownReason,'','','','','','','DTimeOnly',@PlantID,@Exclude
			UPDATE #DownTemp SET PDate=@counter where FromTime=@curstarttime and ToTime=@curendtime
			SELECT @curstarttime = Dateadd(Month,1,@curstarttime)
			SELECT @counter = Dateadd(Month,1,@counter)
		END
	END
	IF  @ComparisonParam='ProdCount' or @ComparisonParam='ProdGraph'
	BEGIN
		While (@Counter <=@EndTime)	
		BEGIN
			SELECT @curstarttime=dbo.f_GetLogicalMonth(@curstarttime,'Start')
			IF @curstarttime<@StartTime
				BEGIN
					SELECT @curstarttime=dbo.f_GetLogicalMonth(@StartTime,'Start')
				END
			SELECT @curendtime=dbo.f_GetLogicalMonth(@curstarttime,'End')
			IF @curendtime > @EndTime
				BEGIN
				 SELECT @curendtime=dbo.f_GetLogicalDay(@EndTime,'End')
				END
			Insert into #DownTemp(FromTime,Totime,CompID,OpnID,CompCount)
			EXEC s_GetComponentProdDataFromAutodata @curstarttime,@curendtime,@Machine,@Component,@Operation,@PlantID
			UPDATE #DownTemp SET PDate=@counter where FromTime=@curstarttime and ToTime=@curendtime
			SELECT @curstarttime = Dateadd(Month,1,@curstarttime)
			SELECT @counter = Dateadd(Month,1,@counter)
		END
	END
END


IF @Machine<> ' '
	BEGIN
	SELECT @Mch_Value = @Machine
	END
ELSE
	BEGIN
	SELECT @Mch_Value ='ALL'
	END

IF @DownReason <> ' '
	BEGIN
	SELECT @Reason_Value=@DownReason
	END
ELSE
	BEGIN
	SELECT @Reason_Value='ALL'
	END
IF @Component<>' '
	BEGIN
	SELECT @Comp_Value=@Component
	END
ELSE
	BEGIN
	SELECT @Comp_Value='ALL'
	END
IF @Operation<>' '
	BEGIN
	SELECT @Opn_Value=@Operation
	END
ELSE
	BEGIN
	SELECT @Opn_Value='ALL'
	END
IF @ComparisonParam='DownTime'
BEGIN
	declare @timeformat as nvarchar(2000)
	select @timeformat ='ss'
	select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
	if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
	begin
		select @timeformat = 'ss'	end
	IF @TimeAxis='Day'
	BEGIN
		SELECT
			cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))as nvarchar(20)) as Day,
			ShiftName as Shift,
			FromTime,
			ToTime,
			(DownTime/60) as MinDownTime,
			dbo.f_FormatTime(DownTime,@timeformat) as FrmtDownTime,
			@Reason_Value AS DownReason,
			@Mch_Value as MachineID
		From	#DownTemp order by fromtime asc
		
	END
	IF @TimeAxis='Shift'
	BEGIN
		SELECT
			
			cast(cast(DateName(month,pdate) as nvarchar(3))+ ' '+cast(datepart(dd,Pdate)as nvarchar(2))+ ' Shift-' +cast(ShiftName as nvarchar(20))as Nvarchar(50)) as Day,
			'Shift-'+cast(ShiftName as nvarchar(20)) as Shift,
			FromTime,
			ToTime,
			(DownTime/60) as MinDownTime,
			dbo.f_FormatTime(DownTime,@timeformat) as FrmtDownTime,
			@Reason_Value as DownReason,
			@Mch_Value as MachineID
			
		From	#ShiftTemp
		
	END
	IF @TimeAxis='Month'
	BEGIN
		SELECT
			
			
			cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(yyyy,Pdate)as nvarchar(4))as nvarchar(20)) as Day,
			ShiftName as Shift,
			FromTime,
			ToTime,
			(DownTime/60) as MinDownTime,
			dbo.f_FormatTime(DownTime,@timeformat) as FrmtDownTime,		@Reason_Value AS DownReason,
			@Mch_Value as MachineID
		From	#DownTemp
		
	END
	IF @TimeAxis='Hour'
	BEGIN
		SELECT
			cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))+'-'+ cast(ShiftName as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as nvarchar(50)) as Day,
			Cast(CAST(YEAR(FromTime)as nvarchar(4))+CAST(Month(FromTime)as nvarchar(2))+CAST(Day(FromTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as NVarchar(50)) as Shift,
			--cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))as nvarchar(50))as Day,--+'-'+ cast(ShiftName as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as nvarchar(50)) as Day,
		        --Cast(CAST(YEAR(FromTime)as nvarchar(4))+CAST(Month(FromTime)as nvarchar(2))+CAST(Day(FromTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as NVarchar(50)) as Shift,
			FromTime,
			ToTime,
			(DownTime/60) as MinDownTime,
			dbo.f_FormatTime(DownTime,@timeformat) as FrmtDownTime,
			@Reason_Value AS DownReason,
			@Mch_Value as MachineID
				
		From	#DownTemp order by fromtime asc
		
	END
END
IF @ComparisonParam='ProdCount'
BEGIN
		
	IF @TimeAxis='Day'
	BEGIN
	SELECT	cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))as nvarchar(20)) as Day,
		ShiftName as Shift,
		FromTime,
		ToTime,	
		CompID AS CompID,
		OpnID AS OpnID,
		@Mch_Value as MachineID,
		@Comp_Value AS Component,
		@Opn_Value as Operation,
		CompCount ,
		TrgtCt as Target
		FROM #DownTemp
	
	END
	IF  @TimeAxis='Hour'
	BEGIN
   

--ER0330 Commented From Here on 16th Aug By Geetanjali 
	--	SELECT	cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))+'-'+ cast(ShiftName as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as nvarchar(50)) as Day,
	--		Cast(CAST(YEAR(FromTime)as nvarchar(4))+CAST(Month(FromTime)as nvarchar(2))+CAST(Day(FromTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as NVarchar(50)) as Shift, 
	--		FromTime,
	--		ToTime,	
	--		CompID AS CompID,
	--		OpnID AS OpnID,
	--		Machine as MachineID,
	--		@Comp_Value AS Component,
	--		@Opn_Value as Operation,
	--		CompCount,
	--		TrgtCt as Target
	--		FROM #DownTemp 
  --ER0330 Commented Till Here on 16th Aug By Geetanjali 

  --ER0330 Added from Here on 16th Aug By Geetanjali 
	 Update #DownTemp set ShiftName =T1.ShiftName From #DownTemp inner join 
	       ( Select  D.Pdate,S.ShiftName from #Downtemp D, #ShiftTemp S where D.Pdate>=S.fromtime and D.Pdate<S.ToTime )T1
	        on T1.Pdate=#DownTemp.Pdate

	 SELECT	ShiftName,PDate,cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))+'-'+ cast(ShiftName as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as nvarchar(50)) as Day,
			Cast(CAST(YEAR(FromTime)as nvarchar(4))+CAST(Month(FromTime)as nvarchar(2))+CAST(Day(FromTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as NVarchar(50)) as Shift, 
			FromTime,
			ToTime,	
			CompID AS CompID,
			OpnID AS OpnID,
			Machine as MachineID,
			@Comp_Value AS Component,
			@Opn_Value as Operation,
			CompCount,
			TrgtCt as Target
			FROM #DownTemp order by FromTime Asc 
--ER0330 Added Till Here on 16th Aug By Geetanjali 

	END	
	IF @TimeAxis='Shift'
	BEGIN
	SELECT	cast(cast(DateName(month,pdate) as nvarchar(3))+ ' '+cast(datepart(dd,Pdate)as nvarchar(2))+ ' Shift-' +cast(ShiftName as nvarchar(20)) as Nvarchar(50)) as Day,
		'Shift-'+cast(ShiftName as nvarchar(20)) as Shift,
		FromTime,
		ToTime,			CompID as CompID,
		OpnID AS OpnID,
		@Mch_Value as MachineID,
		@Comp_Value AS Component,
		@Opn_Value as Operation,
		CompCount,
		Targetcount as Target
		FROM #ShiftTemp
	
	END
	IF @TimeAxis='Month'
	BEGIN
	SELECT	cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(yyyy,Pdate)as nvarchar(4)) as nvarchar(20))as Day,
		ShiftName as Shift,
		FromTime,
		ToTime,	
		CompID AS CompID,
		OpnID AS OpnID,
		@Mch_Value as MachineID,
		@Comp_Value AS Component,
		@Opn_Value as Operation,
		CompCount,
		TrgtCt as Target
		FROM #DownTemp
	
	END
	
END
IF @ComparisonParam='OprtProdCount'
BEGIN
		
	IF @TimeAxis='Day'
	BEGIN
	SELECT	cast(cast(Datepart(year,pdate)as nvarchar(4))+'-'+cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(day,Pdate)as nvarchar(2)) as nvarchar(20))as Day,
		ShiftName as Shift,
		FromTime,
		ToTime,	
		CompID AS CompID,
		OpnID AS OpnID,
		@Mch_Value as MachineID,
		@Comp_Value AS Component,
		@Opn_Value as Operation,
		CompCount,
		OperatorID
		FROM #DownTemp order by FromTime Desc
	
	END
END
if @ComparisonParam='OprtShift'
BEGIN
	IF @TimeAxis='Shift'
	BEGIN
		SELECT	cast(cast(Datepart(year,pdate)as nvarchar(4))+'-'+cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(day,Pdate)as nvarchar(2)) as nvarchar(20))as Day,
		ShiftName as Shift,
		FromTime,
		ToTime,	
		CompID AS CompID,
		OpnID AS OpnID,
		@Mch_Value as MachineID,
		@Comp_Value AS Component,
		@Opn_Value as Operation,
		CompCount,
		Oprtname  FROM #ShiftTemp order by FromTime desc
	END
END
IF @ComparisonParam='ProdGraph'
BEGIN
		
	IF @TimeAxis='Day'
	BEGIN
	SELECT	cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))as nvarchar(20)) as Day,
		ShiftName as Shift,
		FromTime,
		ToTime,	
		@Mch_Value as MachineID,
		sum(CompCount) as CompCount
		FROM #DownTemp   group by  FromTime,Totime,pdate,ShiftName
	
	END
	IF  @TimeAxis='Hour'
	BEGIN
	
	SELECT	cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))+'-'+ cast(ShiftName as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as nvarchar(50)) as Day,
		Cast(CAST(YEAR(FromTime)as nvarchar(4))+CAST(Month(FromTime)as nvarchar(2))+CAST(Day(FromTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as NVarchar(50)) as Shift,
		FromTime,
		ToTime,	
		Machine as MachineID,
		sum(CompCount) as CompCount
		FROM #DownTemp Group by FromTime,Totime,pdate,ShiftName,Machine
	END
	
	IF @TimeAxis='Shift'
	BEGIN	SELECT	cast(cast(DateName(month,pdate) as nvarchar(3))+ ' '+cast(datepart(dd,Pdate)as nvarchar(2))+ ' Shift-' +cast(ShiftName as nvarchar(20)) as Nvarchar(50)) as Day,
		'Shift-'+cast(ShiftName as nvarchar(20)) as Shift,
		FromTime,
		ToTime,	
		@Mch_Value as MachineID,
		sum(CompCount) as Compcount
		FROM #ShiftTemp group by FromTime,Totime,pdate,ShiftName
	
	END
	IF @TimeAxis='Month'
	BEGIN
	
	SELECT	cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(yyyy,Pdate)as nvarchar(4)) as nvarchar(20))as Day,
		ShiftName as Shift,
		FromTime,
		ToTime,	
		@Mch_Value as MachineID,
		sum(CompCount) as Compcount
		FROM #DownTemp Group by FromTime,Totime,pdate,ShiftName
	
	END
	
END
END
