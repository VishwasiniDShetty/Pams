/****** Object:  Procedure [dbo].[s_GetToolChangeFrequency]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************************************************
 changed To Support SubOperations at CO Level{AutoAxel Request}.

 Procedure Changed By Sangeeta Kallur on 24-FEB-2007 :
	[MAINI Req] :Production Count Exception for multispindle Machines. 

 Procedure Changed By Sangeeta Kallur on 05-Mar-2007:
	To get more accurate/detailed tool change frequency report .
mod 1 :- ER0181 By Kusuma M.H on 28-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 28-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
***********************************************************************************************/

CREATE                PROCEDURE [dbo].[s_GetToolChangeFrequency]
	@StartTime datetime = '1-jan-2005',
	@EndTime datetime = '31-jan-2005',
	@MachineID nvarchar(50)= 'MCV320',
	@PlantID nvarchar(50)=''
AS
BEGIN

Declare @StrSql nvarchar(4000)
DECLARE @StrExMachine AS Nvarchar(250)
DECLARE @strMachine AS Nvarchar(250)

SELECT @StrMachine=''
SELECT @StrExMachine=''
SELECT @StrSql=''

Create Table #TempToolLife
(
	SlNo INT IDENTITY(1,1),
	Inserts nvarchar(50),
	StartTime DateTime,
	EndTime DateTime,
	NoOfInserts bigint,
	Operation nvarchar(100),
	NumberOfOperations bigint
)

Create Table #Copy_TempToolLife
(
	SlNo INT, 
	Inserts nvarchar(50),
	StartTime DateTime,
	EndTime DateTime
)
Create Table #OutPut
(
	Inserts nvarchar(50),
	StartTime DateTime,
	EndTime DateTime,
	NoOfInserts bigint,
	Operation nvarchar(100),
	NumberOfOperations bigint
)
Create Table #Temp
(
	Inserts nvarchar(50),
	MinStartTime DateTime,
	MaxEndTime DateTime,
	NoOfInserts bigint
)

CREATE TABLE #Exceptions
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	StartTime DateTime,
	EndTime DateTime,
	IdealCount Int,
	ActualCount Int,
	ExCount Int
)


If Isnull(@machineid,'') <> ''
Begin
	---mod 2
--	SELECT @strmachine = ' And ( M.MachineID = ''' + @MachineID + ''')'
--	SELECT @StrExMachine = ' And ( Ex.MachineID = ''' + @MachineID + ''')'
	SELECT @strmachine = ' And ( M.MachineID = N''' + @MachineID + ''')'
	SELECT @StrExMachine = ' And ( Ex.MachineID = N''' + @MachineID + ''')'
	---mod 2
End

	Insert Into #Temp(Inserts,MinStartTime,MaxEndTime,NoOfInserts)
	SELECT downcodeinformation.downid as Inserts,
	min(autodata.sttime)as sttime,
	max(autodata.ndtime)as ndtime,
	COUNT(downcodeinformation.downid)as 'NumberOfInserts'
	FROM
	autodata INNER JOIN downcodeinformation
		 ON autodata.dcode = downcodeinformation.interfaceid
		 INNER JOIN machineinformation
	         ON autodata.mc = machineinformation.InterfaceID
	WHERE     (autodata.sttime >= @StartTime)AND (autodata.ndtime <= @EndTime) 
		AND (downcodeinformation.downid LIKE N'TCH%') AND (autodata.datatype = 2)
		AND (machineinformation.machineid = @MachineID)
	Group by downcodeinformation.downid

	Insert Into #TempToolLife(Inserts,StartTime,EndTime)
	SELECT downcodeinformation.downid ,sttime,ndtime
	FROM
	autodata INNER JOIN downcodeinformation
		 ON autodata.dcode = downcodeinformation.interfaceid
		 INNER JOIN machineinformation
	         ON autodata.mc = machineinformation.InterfaceID
	WHERE     (autodata.sttime >= @StartTime)AND (autodata.ndtime <= @EndTime) 
		AND (downcodeinformation.downid LIKE N'TCH%') AND (autodata.datatype = 2)
		AND (machineinformation.machineid = @MachineID)
	Order By downcodeinformation.downid ,sttime
	
	Update #TempToolLife SET NoOfInserts=ISNULL(T1.NoOfInserts,0)
	FROM (
		SELECT Inserts,MinStartTime,MaxEndTime,NoOfInserts From #Temp
	) AS T1 Inner Join #TempToolLife ON T1.MinStartTime<=#TempToolLife.StartTime AND T1.MaxEndTime>=#TempToolLife.EndTime AND T1.Inserts=#TempToolLife.Inserts

	Insert Into #Copy_TempToolLife(SlNo,  Inserts ,StartTime ,EndTime )
	SELECT SlNo,  Inserts ,StartTime ,EndTime  FROM #TempToolLife  
	
	UPDATE #Copy_TempToolLife SET SlNo=SlNo-1

	UPDATE #TempToolLife SET EndTime=T1.StartTime
	From
		(
			SELECT Slno,Inserts,StartTime From #Copy_TempToolLife
		)AS T1 Inner Join #TempToolLife ON T1.SlNo= #TempToolLife.SlNo AND T1.Inserts=#TempToolLife.Inserts

	

Declare @Inserts nvarchar(50),@sttime datetime,@ndtime datetime,@NumberOfInserts bigint, @checkcount int

Declare Cur_InsertTime CURSOR FOR

SELECT 	Inserts,StartTime,EndTime,NoOfInserts From #TempToolLife

OPEN Cur_InsertTime
FETCH NEXT FROM Cur_InsertTime
INTO @Inserts ,@sttime,@ndtime,@NumberOfInserts

IF @@FETCH_STATUS <> 0
BEGIN
		SELECT * FROM #OutPut order by Inserts,operation
		CLOSE Cur_InsertTime
		DEALLOCATE Cur_InsertTime
		RETURN
END
	WHILE @@FETCH_STATUS = 0
	BEGIN
		select @checkcount = 0
		select @checkcount = (SELECT Sum(autodata.PartsCount)
		FROM autodata INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
		componentoperationpricing ON (componentinformation.componentid = componentoperationpricing.componentid and autodata.opn = componentoperationpricing.InterfaceID) INNER JOIN
		machineinformation ON autodata.mc = machineinformation.InterfaceID
		---mod 1
		and componentoperationpricing.machineid = machineinformation.machineid 
		---mod 1
		WHERE     (autodata.datatype = 1) 
				AND (machineinformation.machineid = @MachineID) 
				and autodata.sttime >= @sttime and autodata.ndtime <= @ndtime)
		--GROUP BY componentinformation.componentid, componentoperationpricing.operationno)
		if @checkcount > 0
		begin

SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0 
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
---mod 1
SELECT @StrSql = @StrSql + ' and M.machineid = O.machineid '
---mod 1
SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 AND
		((Ex.StartTime>=  ''' + convert(nvarchar(20),@sttime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@ndtime)+''' ) 
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@sttime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@sttime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@ndtime)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@sttime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@ndtime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@ndtime)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@sttime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@ndtime)+''' ))'
SELECT @StrSql = @StrSql + @StrExMachine
Exec (@strsql)
SELECT @strsql=''

IF (SELECT Count(*) from #Exceptions) <> 0 
BEGIN
	UPDATE #Exceptions SET StartTime=@sttime WHERE (StartTime<@sttime)AND EndTime>@sttime  
	UPDATE #Exceptions SET EndTime=@ndtime WHERE (EndTime>@ndtime AND StartTime<@ndtime )

	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp 
	 	From (
			select M.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata 
			Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID 
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
	---mod 1
	SELECT @StrSql = @StrSql + ' and M.machineid = ComponentOperationPricing.machineid '
	---mod 1
	SELECT @StrSql = @StrSql + ' Inner Join (
				Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
				--Where StartTime>='''+Convert(NVarChar(20),@sttime)+''' and EndTime <='''+Convert(NVarChar(20),@ndtime)+''' 
			)AS Tt1 ON Tt1.MachineID=M.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
			Where (autodata.sttime>=Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
	Select @StrSql = @StrSql+ @strmachine
	Select @StrSql = @StrSql+' Group by M.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
		) as T1
	   	Inner join componentinformation C on T1.Comp=C.interfaceid 
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid  '
	---mod 1
	Select @StrSql = @StrSql+' Inner join machineinformation M on T1.machineid = M.machineid '
	---mod 1
	Select @StrSql = @StrSql+' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime 
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
	Exec(@StrSql)
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
	
END

			INSERT INTO #OutPut(Inserts,StartTime,EndTime,NoOfInserts,Operation,NumberOfOperations)
			SELECT @Inserts,@sttime,@ndtime,@NumberOfInserts,
			componentinformation.componentid + '  ' + CAST(componentoperationpricing.operationno AS nvarchar(20))AS Operation, 
			CAST(CEILING(CAST(sum(autodata.partscount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer ) AS NumberOfComponents
			FROM autodata INNER JOIN
			componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
			componentoperationpricing ON (componentinformation.componentid = componentoperationpricing.componentid and autodata.opn = componentoperationpricing.InterfaceID) INNER JOIN
			machineinformation ON autodata.mc = machineinformation.InterfaceID
			---mod 1
			and machineinformation.machineid = componentoperationpricing.machineid 
			---mod 1
			WHERE     (autodata.datatype = 1) AND (machineinformation.machineid = @MachineID) and autodata.sttime >= @sttime and autodata.ndtime <= @ndtime
			GROUP BY componentinformation.componentid, componentoperationpricing.operationno,componentoperationpricing.SubOperations

			
			UPDATE #OutPut SET NumberOfOperations=ISNULL(NumberOfOperations,0)-ISNULL(T1.ExCount,0)
			From (
				SELECT 	#OutPut.StartTime,#OutPut.EndTime,Inserts AS TCH ,Componentid + '  ' + CAST(Operationno AS nvarchar(20))AS Operation,Sum(ExCount)as ExCount
				FROM #Exceptions Inner Join #OutPut ON #Exceptions.Componentid + '  ' + CAST(#Exceptions.Operationno AS nvarchar(20))=#OutPut.Operation
				AND #Exceptions.StartTime>=#OutPut.StartTime AND  #Exceptions.EndTime<=#OutPut.EndTime				
				Where #Exceptions.StartTime>= @sttime AND #Exceptions.EndTime<=@ndtime And Inserts=@Inserts
				Group By Componentid,Operationno,Inserts,#OutPut.StartTime,#OutPut.EndTime
			)AS T1 Inner Join #OutPut ON T1.Operation = #OutPut.Operation AND T1.TCH=#OutPut.Inserts
			And T1.StartTime=#OutPut.StartTime AND T1.EndTime=#OutPut.EndTime
			Where T1.StartTime=@sttime And T1.EndTime=@Ndtime AND T1.TCH=@Inserts
			
			Delete From #Exceptions
		end
		else
		begin
			INSERT INTO #OutPut
			SELECT @Inserts,@sttime,@ndtime,@NumberOfInserts,'No Production', 0
		end

		FETCH NEXT FROM Cur_InsertTime INTO @Inserts ,@sttime,@ndtime,@NumberOfInserts
	END


CLOSE Cur_InsertTime
DEALLOCATE Cur_InsertTime


SELECT * FROM #OutPut order by Inserts,StartTime,operation
END
