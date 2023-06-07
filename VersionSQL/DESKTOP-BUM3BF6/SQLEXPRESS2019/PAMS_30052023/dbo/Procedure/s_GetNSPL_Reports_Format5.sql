/****** Object:  Procedure [dbo].[s_GetNSPL_Reports_Format5]    Committed by VersionSQL https://www.versionsql.com ******/

/*********************************    History     ***********************************************
  Procedure Created By Sangeeta Kallur on 06-Feb-2007
  NSPL Specific Report formats ie Comparison Report Shiftwise,Comparison Report Weekly

  Machine|Employee|Component|Operation|7:30 to 8:30|8:30 to 9:30 .... |DownTime|Target|Total OutPut
  
mod 1:- Procedure Changed By Sangeeta Kallur on 22-FEB-2007 :: To include 'PartsCount' .
mod 2:-Procedure Changed By Sangeeta Kallur on 07-June-2007 :: To change format of Convert function ie to 120.
mod 3:-Procedure Altered by Mrudula to change the format of output
mod 4:-Procedure altered by Mrudula Rao to get target calculation in all the formats i.e. %ideal and default target per CO. 
       Changed on 05-sep-2007 for ER0017
Altered by SSK:DR0055:19/Oct/07 - Foramt : YYYYMMDDHH:MM TO HH:MM
Altered by SSK:ER0099:04/Dec/07 - Format-V
Altered by Shilpa:12/Dec/07 - Format-V to increase the nvarchar(5) to nvarchar(10)
mod 5 :- ER0181 By Kusuma M.H on 08-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 6 :- ER0182 By Kusuma M.H on 08-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 7 :-For DR0129 by Mrudula M. Rao on 08-Oct-2009.Problem in the join while making MCO  changes for target calculation, 
	   if the setting is %Ideal in smartshop defaults.
************************************************************************************************/
--exec s_GetNSPL_Reports_Format5 '06-Aug-2008','08-Aug-2008','','','','Shift'
CREATE PROCEDURE [dbo].[s_GetNSPL_Reports_Format5]
		@StartTime as Datetime,			
		@EndTime as datetime,
		@PlantID nvarchar(50)='',
		@Machine as nvarchar(50) = '',
		@ShiftName as nvarchar(20)='',
		@ComparisonParam as nvarchar(20) -- Shift / Week
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


CREATE TABLE #NSPLData
	(
		SHIFT NvarChar(20),
		Machine NvarChar(50),
		Employee NvarChar(50),
		Component NvarChar(50),
		Operation Int,
		FromTime DateTime,
		ToTime DateTime,
		ProdCount Int DEFAULT 0,
		DownTime Float DEFAULT 0,
		Target Int DEFAULT 0,
		TotalOutPut Int DEFAULT 0,
		LunchBreakFlag INT DEFAULT 0,
		TotalCycletimeLUIncrease Float,
		WorkingTime Float
	)


CREATE TABLE #NSPLTime
	(
		FromTime DateTime,
		ToTime DateTime,
		Reason NVarChar(50)
	)


CREATE TABLE #ShiftTemp
	(
		PDate datetime,
		ShiftName nvarchar(20),
		FromTime datetime,
		ToTime Datetime
	)

CREATE TABLE #Header
	(
		RowHeader NVarChar(100),
	)
Declare @strsql nvarchar(4000)
Declare @strmachine nvarchar(255)
Declare @strPlantID As nvarchar(50)

Declare @counter      As DateTime
Declare @curstarttime As Datetime
Declare @curendtime   As Datetime
Declare @ShftSt       As Datetime
Declare @ShftNd       As Datetime
Declare @DownStTime   As Datetime
Declare @DownNdTime   As Datetime
declare @Targetsource as nvarchar(50)
declare @strmachine2 as nvarchar(200)
declare @StrDiv as int
declare @strShift as nvarchar(200)

SELECT @strsql = ''
SELECT @strmachine = ''
select  @strPlantID = ''
select @strmachine2=''

SELECT @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')
SELECT @curstarttime=@StartTime	

select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'

If isnull(@Machine,'') <> ''
BEGIN
	---mod 6
--	SELECT @strmachine = ' AND ( M.machineid = ''' + @Machine+ ''')'
--	SELECT @strmachine2 = ' AND ( machine = ''' + @Machine+ ''')'
	SELECT @strmachine = ' AND ( M.machineid = N''' + @Machine+ ''')'
	SELECT @strmachine2 = ' AND ( machine = N''' + @Machine+ ''')'
	---mod 6
END
IF isnull(@PlantID,'') <> ''
BEGIN
	---mod 6
--	SELECT @strPlantID = ' AND ( P.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( P.PlantID = N''' + @PlantID+ ''')'	
	---mod 6
END

IF ISNULL(@ShiftName,'')<> ''
BEGIN
	---mod 6
--	SELECT @strShift= 'AND (shift=''' +@ShiftName+ ''' ) '
	SELECT @strShift= 'AND (shift=N''' +@ShiftName+ ''' ) '
	---mod 6
END
 IF @ComparisonParam='Shift'
 BEGIN
	Insert Into #NSPLTime(FromTime,ToTime,Reason)
	SELECT 
	CASE Today
	WHEN 0 THEN convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' '+cast(datepart(hh,FromTime)as nvarchar(2))+':'+cast(datepart(mi,FromTime)as nvarchar(2))+':'+cast(datepart(ss,FromTime)as nvarchar(2))   )
	ELSE convert(datetime, cast(DATEPART(yyyy,dateadd(dd,1,@StartTime))as nvarchar(4))+'-'+cast(datepart(mm,dateadd(dd,1,dateadd(dd,1,@StartTime)))as nvarchar(2))+'-'+cast(datepart(dd,dateadd(dd,1,@StartTime))as nvarchar(2)) +' '+cast(datepart(hh,FromTime)as nvarchar(2))+':'+cast(datepart(mi,FromTime)as nvarchar(2))+':'+cast(datepart(ss,FromTime)as nvarchar(2))   )
	END,
	CASE Tommorrow
	WHEN 0 THEN  convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' '+cast(datepart(hh,ToTime)as nvarchar(2))+':'+cast(datepart(mi,ToTime)as nvarchar(2))+':'+cast(datepart(ss,ToTime)as nvarchar(2))   )
	ELSE convert(datetime, cast(DATEPART(yyyy,dateadd(dd,1,@StartTime))as nvarchar(4))+'-'+cast(datepart(mm,dateadd(dd,1,dateadd(dd,1,@StartTime)))as nvarchar(2))+'-'+cast(datepart(dd,dateadd(dd,1,@StartTime))as nvarchar(2)) +' '+cast(datepart(hh,ToTime)as nvarchar(2))+':'+cast(datepart(mi,ToTime)as nvarchar(2))+':'+cast(datepart(ss,ToTime)as nvarchar(2))   )
	END,DownReason	From PlannedDownListforLday


	Insert Into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)

	Exec s_GetShiftTime @counter,@ShiftName

	SELECT TOP 1 @counter=FromTime FROM #ShiftTemp ORDER BY FromTime ASC
	SELECT TOP 1 @EndTime=ToTime FROM #ShiftTemp ORDER BY FromTime DESC

	select @StrDiv=cast (ceiling (cast(datediff(second,@counter,@EndTime)as float ) /3600) as int)

	SELECT TOP 1 @DownStTime=FromTime, 
		@DownNdTime=ToTime FROM #NSPLTime Where  FromTime>=@counter And ToTime<=@EndTime
	
	SELECT @strsql='INSERT INTO #NSPLData(FromTime,Totime,Machine,Employee,Component,Operation,ProdCount,LunchBreakFlag)'
	SELECT @strsql = @strsql +' SELECT '''+convert(nvarchar(20),@DownStTime,120)+''','''+convert(nvarchar(20),@DownNdTime,120)+''',M.MachineID,E.EmployeeID,C.componentid,O.operationno,'
	--SELECT @strsql = @strsql +' CAST(CEILING(CAST(count(C.componentid)AS Float)/ISNULL(O.SubOperations,1)) AS INTEGER) ,1 '
	SELECT @strsql = @strsql +' CAST(CEILING(CAST(SUM(A.PartsCount)AS Float)/ISNULL(O.SubOperations,1)) AS INTEGER) ,1 '
	SELECT @strsql = @strsql +' from autodata A Inner Join EmployeeInformation E ON A.Opr=E.interfaceid'
	SELECT @strsql = @strsql +' inner join ComponentInformation C on A.comp=C.interfaceid '
	SELECT @strsql = @strsql +' inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
	SELECT @strsql = @strsql +' INNER JOIN machineinformation M on A.mc=M.interfaceid '
	---mod 5
	SELECT @strsql = @strsql +' and O.machineid=M.machineid '
	---mod 5
	SELECT @strsql = @strsql +' left OUTER Join PlantMachine P on m.machineid = P.machineid '
	SELECT @strsql = @strsql +' WHERE A.DataType=1 And A.ndtime>'''+convert(nvarchar(20),@DownStTime,120)+'''  and A.Ndtime<='''+ convert(nvarchar(20),@DownNdTime,120)+''' '
	SELECT @strsql = @strsql + @strmachine + @strPlantID
	SELECT @strsql = @strsql +' GROUP BY M.MachineID,E.EmployeeID,C.componentid,O.operationno,O.SubOperations'
	EXEC (@strsql)

	While(@counter < @EndTime)
		BEGIN
			SELECT @curstarttime=@counter 
			SELECT @curendtime=DATEADD(Second,3600,@counter)
			
			If @DownStTime>=@curstarttime And @DownStTime<=@curendtime
			BEGIN
				SELECT @curendtime=@DownStTime
			END

			if @curendtime >= @EndTime
			Begin
				set @curendtime = @EndTime
			end
			
			SELECT @strsql='INSERT INTO #NSPLData(FromTime,Totime,Machine,Employee,Component,Operation,ProdCount)'
			SELECT @strsql = @strsql +' SELECT '''+convert(nvarchar(20),@curstarttime,120)+''','''+convert(nvarchar(20),@curendtime,120)+''',M.MachineID,E.EmployeeID,C.componentid,O.operationno,'
			--SELECT @strsql = @strsql +' CAST(CEILING(CAST(count(C.componentid)AS Float)/ISNULL(O.SubOperations,1)) AS INTEGER)  '
			SELECT @strsql = @strsql +' CAST(CEILING(CAST(SUM(A.PartsCount)AS Float)/ISNULL(O.SubOperations,1)) AS INTEGER)  '			
			SELECT @strsql = @strsql +' from autodata A Inner Join EmployeeInformation E ON A.Opr=E.interfaceid'
			SELECT @strsql = @strsql +' inner join ComponentInformation C on A.comp=C.interfaceid '
			SELECT @strsql = @strsql +' inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
			SELECT @strsql = @strsql +' INNER JOIN machineinformation M on A.mc=M.interfaceid '
			---mod 5
			SELECT @strsql = @strsql +' and O.machineid=M.machineid '
			---mod 5
			SELECT @strsql = @strsql +' left OUTER Join PlantMachine P on m.machineid = P.machineid '
			SELECT @strsql = @strsql +' WHERE A.DataType=1 And A.ndtime>'''+convert(nvarchar(20),@curstarttime,120)+'''  and A.Ndtime<='''+ convert(nvarchar(20),@curendtime,120)+''' '
			SELECT @strsql = @strsql + @strmachine + @strPlantID
			SELECT @strsql = @strsql +' GROUP BY M.MachineID,E.EmployeeID,C.componentid,O.operationno,O.SubOperations'
			EXEC (@strsql)
			
			SELECT @counter = DATEADD(Second,3600,@counter)
			If @DownStTime>=@curstarttime And @DownStTime<=@curendtime
			BEGIN
				SELECT @counter=@DownNdTime
			END
		END
	---mod 6
--	UPDATE #NSPLData SET Shift=@ShiftName
	UPDATE #NSPLData SET Shift= N'' + @ShiftName + ''
	---mod 6

	SELECT TOP 1 @ShftSt=FromTime FROM #ShiftTemp ORDER BY FromTime ASC
	SELECT TOP 1 @ShftNd=ToTime FROM #ShiftTemp ORDER BY FromTime DESC

	SELECT @strsql =''
	SELECT @strsql =' Update #NSPLData Set DownTime=ISNULL(T1.DownTime,0)'
	SELECT @strsql = @strsql +' From(Select M.MachineID As Machine,E.EmployeeID AS Employee,C.componentid AS component, O.operationno AS operation,'
	SELECT @strsql = @strsql +' Sum('
	SELECT @strsql = @strsql +' CASE '
	SELECT @strsql = @strsql +' WHEN Sttime>='''+convert(nvarchar(20),@ShftSt,120)+''' And Ndtime<='''+ convert(nvarchar(20),@ShftNd,120)+''' THEN DateDiff(mi,Sttime,Ndtime)'
	SELECT @strsql = @strsql +' WHEN Sttime<'''+convert(nvarchar(20),@ShftSt,120)+''' And Ndtime>'''+convert(nvarchar(20),@ShftSt,120)+''' And Ndtime<='''+ convert(nvarchar(20),@ShftNd,120)+''' THEN DateDiff(mi,'''+convert(nvarchar(20),@ShftSt,120)+''',NdtimE)'
	SELECT @strsql = @strsql +' WHEN Sttime>='''+convert(nvarchar(20),@ShftSt,120)+''' And Sttime<'''+ convert(nvarchar(20),@ShftNd,120)+''' And Ndtime>'''+ convert(nvarchar(20),@ShftNd,120)+''' THEN DateDiff(mi,Sttime,'''+ convert(nvarchar(20),@ShftNd,120)+''')'
	SELECT @strsql = @strsql +' ELSE DateDiff(mi,'''+convert(nvarchar(20),@ShftSt,120)+''','''+ convert(nvarchar(20),@ShftNd,120)+''')'
	SELECT @strsql = @strsql +' END) AS DownTime'
	SELECT @strsql = @strsql +' From autodata A Inner Join EmployeeInformation E ON A.Opr=E.interfaceid'
	SELECT @strsql = @strsql +' Inner join ComponentInformation C on A.comp=C.interfaceid '
	SELECT @strsql = @strsql +' Inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
	SELECT @strsql = @strsql +' INNER JOIN machineinformation M on A.mc=M.interfaceid '
	---mod 5
	SELECT @strsql = @strsql +' and O.machineid=M.machineid '
	---mod 5
	SELECT @strsql = @strsql +' left OUTER Join PlantMachine P on m.machineid = P.machineid '
	SELECT @strsql = @strsql +' WHERE A.DataType=2 And ((A.Sttime>='''+convert(nvarchar(20),@ShftSt,120)+'''  and A.Ndtime<='''+ convert(nvarchar(20),@ShftNd,120)+''') OR (A.Sttime<'''+convert(nvarchar(20),@ShftSt,120)+''' And A.Ndtime>'''+convert(nvarchar(20),@ShftSt,120)+''' And A.Ndtime<='''+convert(nvarchar(20),@ShftNd,120)+''') OR (Sttime>='''+convert(nvarchar(20),@ShftSt,120)+''' And Sttime<'''+convert(nvarchar(20),@ShftNd,120)+''' And Ndtime>'''+convert(nvarchar(20),@ShftNd,120)+''') OR(A.Sttime<'''+convert(nvarchar(20),@ShftSt,120)+''' And A.Ndtime>'''+convert(nvarchar(20),@ShftNd,120)+''')) '
	SELECT @strsql = @strsql + @strmachine + @strPlantID
	SELECT @strsql = @strsql +' GROUP BY M.MachineID,E.EmployeeID,C.componentid,O.operationno )As T1 Inner Join #NSPLData on #NSPLData.Machine=T1.Machine And #NSPLData.Employee=T1.Employee And #NSPLData.component=T1.component And #NSPLData.operation=T1.operation'
--print @strsql	
EXEC (@strsql)

-- ER0099 : Starts here : Sangeeta
SELECT @strsql =''
	SELECT @strsql =' Update #NSPLData Set'
	SELECT @strsql = @strsql +' TotalCycletimeLUIncrease=ISNULL(T1.TCLUIncrease,0) , WorkingTime=ISNULL(T1.WT,0) '
	SELECT @strsql = @strsql +' From(Select M.MachineID As Machine,E.EmployeeID AS Employee,C.componentid AS component, O.operationno AS operation,'
	SELECT @strsql = @strsql +' 
Sum(A.LoadUnload- (O.Cycletime-O.Machiningtime)+(A.Cycletime)- (O.Machiningtime)) AS TCLUIncrease,Sum((A.Cycletime + A.LoadUnload))/60 AS WT '
	SELECT @strsql = @strsql +' From autodata A Inner Join EmployeeInformation E ON A.Opr=E.interfaceid'
	SELECT @strsql = @strsql +' Inner join ComponentInformation C on A.comp=C.interfaceid '
	SELECT @strsql = @strsql +' Inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
	SELECT @strsql = @strsql +' INNER JOIN machineinformation M on A.mc=M.interfaceid '
	---mod 5
	SELECT @strsql = @strsql +' and O.machineid=M.machineid '
	---mod 5
	SELECT @strsql = @strsql +' left OUTER Join PlantMachine P on m.machineid = P.machineid '
	SELECT @strsql = @strsql +' WHERE A.DataType=1 And ((A.Sttime>='''+convert(nvarchar(20),@ShftSt,120)+'''  and A.Ndtime<='''+ convert(nvarchar(20),@ShftNd,120)+''') OR 
	(A.Sttime<'''+convert(nvarchar(20),@ShftSt,120)+''' And A.Ndtime>'''+convert(nvarchar(20),@ShftSt,120)+''' And A.Ndtime<='''+convert(nvarchar(20),@ShftNd,120)+''') ) '
	SELECT @strsql = @strsql + @strmachine + @strPlantID
	SELECT @strsql = @strsql +' GROUP BY M.MachineID,E.EmployeeID,C.componentid,O.operationno )As T1 Inner Join #NSPLData on #NSPLData.Machine=T1.Machine And #NSPLData.Employee=T1.Employee And #NSPLData.component=T1.component And #NSPLData.operation=T1.operation'
--print @strsql	
EXEC (@strsql)

-- ER0099 : Ends here : Sangeeta
----ER0017
	--target calculation at hourwise
	select @strsql=''
	if isnull(@Targetsource,'')='Exact Schedule'
	BEGIN

		 select @strsql=''
		 select @strsql='update #NSPLData set Target= isnull(Target,0)+ ISNULL(t1.tcount,0) from 
				( select date as date1,machine,component,operation,sum(idealcount) as tcount from 
			  	loadschedule where date>=''' +convert(nvarchar(20),@starttime)+''' and date<=''' +convert(nvarchar(20),@starttime)+ ''' '
	         select @strsql= @strsql + @strmachine2+@strShift 
		 select @strsql=@strsql+ 'group by date,machine,component,operation ) as t1 inner join #NSPLData on
			  	 t1.machine=#NSPLData.Machine and t1.component=#NSPLData.Component 
			  	and t1.operation=#NSPLData.Operation '	
		---mod 5
		select @strsql = @strsql + ' and t1.machine = #NSPLData.machine '
		---mod 5
--		PRINT @strsql
		EXEC (@strsql)
		
		

		print @StrDiv
		
		 UPDATE #NSPLData SET Target=Target/ISNULL(@StrDiv,1)
		/*Update #NSPLData Set Target=ISNULL(T1.IdealCount,0)From
		(
			SELECT  Component,Operation,IdealCount FROM LoadSchedule 
		)AS T1 Inner Join #NSPLData ON #NSPLData.Component=T1.Component AND #NSPLData.Operation=T1.Operation
		*/
	END

	select @strsql=''
	if isnull(@Targetsource,'')='Default Target per CO'
	BEGIN
		PRINT @StrDiv
		select @strsql=''
		select @strsql='update #NSPLData set Target= isnull(Target,0)+ ISNULL(t1.tcount,0) from 
				( select DATE AS date1, machine,component,operation,sum(idealcount) as tcount from 
			  	loadschedule where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC) and SHIFT=(SELECT TOP 1 SHIFT FROM LOADSCHEDULE where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC) ORDER BY SHIFT DESC)'
	    select @strsql= @strsql + @strmachine2 
		select @strsql=@strsql+ ' group by date,machine,component,operation ) as t1 inner join #NSPLData on
			  	 t1.machine=#NSPLData.Machine and t1.component=#NSPLData.Component 
			  	and t1.operation=#NSPLData.Operation '		
		---mod 5
		select @strsql = @strsql + ' and t1.machine = #NSPLData.machine '
		---mod 5
		
		select @strsql='update #NSPLData set Target= isnull(Target,0)+ ISNULL(t3.tcount,0) from (
				select T2.date1,T2.shift,T2.machine,T2.component,T2.operation,loadschedule.idealcount as tcount from loadschedule inner join
				(select T1.DATE AS date1,max(loadschedule.shift) as shift,T1.machine,T1.component,T1.operation from 
				loadschedule  inner join (
				select  max(date) as date,machine,component,operation from loadschedule
				 group by
				 machine,component,operation) 
				as T1 on loadschedule.date=T1.DATE and
				loadschedule.machine=T1.machine and loadschedule.component=T1.component and loadschedule.operation=T1.operation
				where loadschedule.date=t1.date '

		If isnull(@Machine,'') <> ''
		BEGIN
			---mod 6
--			select @strsql= @strsql + ' AND ( Loadschedule.machine = ''' + @Machine+ ''')'
			select @strsql= @strsql + ' AND ( Loadschedule.machine = N''' + @Machine+ ''')'
			---mod 6
		END 
		select @strsql= @strsql+' group by T1.date,T1.machine,T1.component,T1.operation) as T2 on T2.date1=loadschedule.date and 
		T2.shift=loadschedule.shift and t2.machine=loadschedule.machine and T2.component=loadschedule.component
		and T2.operation=loadschedule.operation) as T3 inner join #NSPLData on
		T3.machine=#NSPLData.Machine and T3.component=#NSPLData.Component 
			  	and T3.operation=#NSPLData.Operation'
		---mod 5
		select @strsql = @strsql + ' and T3.machine = #NSPLData.machine '
		---mod 5
--		PRINT @strsql
		EXEC (@strsql)

		
		IF ISNULL(@ShiftName,'')<>'' 
		BEGIN
		 UPDATE #NSPLData SET Target=Target/ISNULL(@StrDiv,1)
		END
	
		
			
	END
	
	select @strsql=''
	IF ISNULL(@Targetsource,'')='% Ideal'
	BEGIN  
			select @strmachine2=''
		if isnull(@Machine,'') <> ''
		BEGIN
		---mod 6
--		SELECT @strmachine2 = ' AND ( CO.machineID = ''' + @Machine+ ''')'
		SELECT @strmachine2 = ' AND ( CO.machineID = N''' + @Machine+ ''')'
		---mod 6
		END
		
		
	       select @strsql=''
		select @strsql='update #NSPLData set Target= isnull(Target,0)+ ISNULL(t1.tcount,0) from 
				 ( select CO.componentid as component,CO.Operationno as operation,#NSPLData.Fromtime as strt, tcount=((datediff(second,#NSPLData.Fromtime,#NSPLData.Totime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100 '
		---mod 7: to get target at MCO level
		select @strsql=@strsql+ ' ,CO.Machineid as Machine '	
		---mod 7
		select @strsql=@strsql+ ' from componentoperationpricing CO inner join #NSPLData on CO.Componentid=#NSPLData.Component 
				and Co.operationno=#NSPLData.Operation  '
		
		---mod 7: to get target at MCO level
		select @strsql=@strsql+ ' and Co.Machineid=#NSPLData.machine'
		---mod 7

		select @strsql=@strsql+ '  ) as t1 inner join #NSPLData on
				t1.strt=#NSPLData.Fromtime and
			  	  t1.component=#NSPLData.Component 
			  	and t1.operation=#NSPLData.Operation '	
		---mod 5
		select @strsql = @strsql + ' and t1.machine = #NSPLData.machine '
		---mod 5

		/* select CO.componentid as component,CO.Operationno as operation,#NSPLData.Fromtime as strt, CO.suboperations,CO.cycletime,tcount=((datediff(second,#NSPLData.Fromtime,#NSPLData.Totime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
				from componentoperationpricing CO inner join #NSPLData on CO.Componentid=#NSPLData.Component 
				and Co.operationno=#NSPLData.Operation*/
--		PRINT @strsql
		EXEC (@strsql)
		--select * from #NSPLData
		---return
	
	END
	

	Update #NSPLData Set TotalOutPut=ISNULL(T1.TotalOutPut,0)From
	(
		SELECT  Machine,Employee,Component,Operation,Sum(ProdCount)As TotalOutPut FROM #NSPLData
		Group By  Machine,Employee,Component,Operation
	)AS T1 Inner Join #NSPLData ON  #NSPLData.Machine=T1.Machine And #NSPLData.Employee=T1.Employee And #NSPLData.Component=T1.Component AND #NSPLData.Operation=T1.Operation
END


Insert Into #Header Values('Hours')
Insert Into #Header Values('Down Time')
Insert Into #Header Values('Target')
Insert Into #Header Values('Total OutPut')
Insert Into #Header Values('Total CLU Inc')
Insert Into #Header Values('Working Time')

Select 
SHIFT ,
Machine,
Employee ,
Component ,
Operation ,
CASE RowHeader
	WHEN 'Down Time'   THEN 'Down Time'
	WHEN 'Target'      THEN 'Target'
	WHEN 'Total OutPut'THEN 'Total Output'
	WHEN 'Total CLU Inc'THEN 'Total CLU Inc'
	WHEN 'Working Time'THEN 'Working Time'
	--Else Right(Cast(CAST(YEAR(FromTime)as nvarchar(4))+CAST(Month(FromTime)as nvarchar(2))+CAST(Day(FromTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as NVarchar(50)),14)
	--Else Cast(CAST(YEAR(FromTime)as nvarchar(4))+CAST(Month(FromTime)as nvarchar(2))+CAST(Day(FromTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as NVarchar(50))
	Else Cast(CAST(YEAR(FromTime)as nvarchar(4))+ CASE WHEN DATALENGTH(Cast(datepart(mm,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(mm,FromTime)as nvarchar(2)) ELSE cast(datepart(mm,FromTime)as nvarchar(2))END + CASE WHEN DATALENGTH(Cast(datepart(dd,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(dd,FromTime)as nvarchar(2)) ELSE cast(datepart(dd,FromTime)as nvarchar(2))END + CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+ CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as NVarchar(50))
END AS RowHeader,

CASE RowHeader
	WHEN 'Down Time'   THEN Cast(DownTime AS Nvarchar(10))
	WHEN 'Target'      THEN Cast(Target AS Nvarchar(10))
	WHEN 'Total OutPut'THEN Cast(TotalOutPut AS Nvarchar(10))
	WHEN 'Total CLU Inc'THEN Cast(TotalCycletimeLUIncrease AS Nvarchar(10))  
	WHEN 'Working Time'THEN Cast(workingTime AS Nvarchar(10))
	Else 
		CASE LunchBreakFlag 
		WHEN 0 THEN Cast(ProdCount AS Nvarchar(5)) 
		WHEN 1 THEN 'LUNCH ('+Cast(ProdCount AS Nvarchar(5))+')' 
		ELSE 'LUNCH (0)'END
		
	END As RowValue,

FromTime ,
ToTime ,
ProdCount ,
LunchBreakFlag 

From #NSPLData CROSS JOIN #Header 


Order By FromTime

END 
