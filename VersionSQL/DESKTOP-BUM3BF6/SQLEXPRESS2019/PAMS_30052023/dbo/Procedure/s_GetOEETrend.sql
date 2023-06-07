/****** Object:  Procedure [dbo].[s_GetOEETrend]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************
select * from plantmachine order by plantid
[dbo].[s_GetOEETrend] '2011-04-01','2011-05-15','','','''ACE-02'',''ACE-03'',''ACE-04'',''ACE-05'',''ACE-07'',''ACE-08''','critical Machines','Format1'
[dbo].[s_GetOEETrend] '2012-02-01','2012-03-15','third','','''ACE-02''','critical Machines','Format1'
[dbo].[s_GetOEETrend] '2012-07-01','2012-09-15','','','','ALL Machines','Format3'
[dbo].[s_GetOEETrend] '2015-04-01','2015-05-01','','Win Chennai - LCC','''ACE-8''','All Machines','Format1'
ER0335 - SwathiKS- 02/nov/2012 :: Created New procedure to show Monthwise Efficiencies,Target for TPMTrakenabled and focussed Machines.
Flow :: Agg-> Comparison Reports -> Excel Reporting-2 Template ::OEE Trend.xls
ER0344 :: To handle shiftwise logic and string of machines
DR0368 - SwathiKS - 05-Sep-2015 :: To handle error string or binary data would be truncated in Wipro.
***************************************************************************************/
CREATE                      PROCEDURE [dbo].[s_GetOEETrend]
	@StartDate As DateTime,
	@EndDate As DateTime,
	@shift as nvarchar(25)='',
	@PlantID As NVarChar(50)='',
	@MachineID As nvarchar(500) = '',
	@Parameter As nvarchar(50)='', --'Critical Machines','ALL Machines'
	@Format As nvarchar(50) = '' --'Format1','Format2'
AS
BEGIN
----------------------------------------------------------------------------------------------------------
--* Declaration of Variables *--
----------------------------------------------------------------------------------------------------------
Declare @Strsql nvarchar(4000)
Declare @Strsql1 nvarchar(4000)
Declare @timeformat AS nvarchar(12)
Declare @Strmachine nvarchar(4000)
Declare @StrPlantID AS NVarchar(255)
Declare @StrShift AS NVarchar(255)
Declare @CurDate As DateTime
Declare @StratOfMonth As DateTime
Declare @EndOfMonth As DateTime
Declare @AddMonth As DateTime
declare @starttime as datetime
declare @endtime as datetime
declare @start nvarchar(50)
declare @oldyear nvarchar(50)
Select @Strsql = ''
select @oldyear=''
select @start=''
Select @Strsql1 = ''
Select @Strmachine = ''
Select @StrPlantID=''
Select @StrShift=''
-------------------------------------------------------------------------------------------------------------
-- * Building Strings * --
-------------------------------------------------------------------------------------------------------------
If isnull(@PlantID,'') <> ''
Begin
	Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
End
if isnull(@Machineid,'')  <> ''
BEGIN
	print @machineid
--	select @strmachine =  N'(' + @machineid +')' --ER0344 commented
	select @strmachine = ' and  m.machineid  in (' + @machineid + ')' --ER0344 added
	
END
--ER0344 added  from here
If isnull(@shift,'') <> ''
Begin
	Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @shift + ''')'
End
--ER0344 added till here
Select @timeformat ='ss'
Select @timeformat = isnull((Select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
Select @timeformat = 'ss'
End
--------------------------------------------------------------------------------------------------------
					-- * Creation of Temp Tables * --
--------------------------------------------------------------------------------------------------------
	Create Table #Comparisonoutput
	(
		Pdate DateTime,
		StartDate  DateTime,
		EndDate DateTime,
		Shift  NVarChar(20),
		MachineID  NVarChar(50),
		ProdCount Int DEFAULT 0,
		AcceptedParts Int DEFAULT 0,
		RejCount  Int DEFAULT 0,
		RepeatCycle Int DEFAULT 0,
		DummyCycle Int DEFAULT 0,
		ReworkPerformed Int DEFAULT 0,
		MarkedForRework Int DEFAULT 0,
		AEffy  Float DEFAULT 0,
		PEffy  Float DEFAULT 0,
		QEffy  Float DEFAULT 0,
		OEffy  Float DEFAULT 0,
		UtilisedTime  Float DEFAULT 0,
		DownTime  Float DEFAULT 0,
		CN  Float DEFAULT 0,
		ManagementLoss float default 0,
		DowntimeAE float default 0,
		GroupID NVARCHAR(50)
	)
	Create table #PlantMachineInfo
	(
		
		Machineid nvarchar(50),
		PlantID nvarchar(50),
		Machinewiseowner nvarchar(50),
		TargetOE Float DEFAULT 0
	)
	Create Table #ConsolidatedOutput
	(
		MachineID  NVarChar(50),
		ProdCount  Int,
		AcceptedParts Int,
		RejCount  Int,
		MarkedForRework Int,
		AEffy  Float,
		PEffy  Float,
		QEffy Float,
		OEffy Float,
		UtilisedTime  Float,
		DownTime  Float,
		CN  Float DEFAULT 0,
		MgmtLoss float default 0,
		DowntimeAE float default 0,
		shift nvarchar(25)
	)
	CREATE TABLE #DownDetails
	(
	MachineID nvarchar(50) NOT NULL,
	--DownID nvarchar(50) NOT NULL,--DR0368
	DownID nvarchar(1000) NOT NULL, --DR0368
	DownTime float
	)
	Create Table #Finaloutput
	(
		Pdate nvarchar(20),
		StartDate  DateTime,
		EndDate DateTime,
		shift nvarchar(25),
		PlantID Nvarchar(50),
		MachineID  NVarChar(50),
		OwnerName Nvarchar(50),
		MachinewiseTarget int,
		PrevyearOEE Float DEFAULT 0,
		AEffy  Float DEFAULT 0,
		PEffy  Float DEFAULT 0,
		QEffy  Float DEFAULT 0,
		OEffy  Float DEFAULT 0,
	)
--------------------------------------------------------------------------------------------------------
					-- * Populating of Temp Tables * --
--------------------------------------------------------------------------------------------------------	


	
	Insert into #DownDetails
	exec s_GetShiftAgg_DowntimeMatrix @startdate,@enddate,'','','DTimeforOEETrend',@plantid,'0' ----ER0344 added
--	exec s_GetShiftAgg_DowntimeMatrix @startdate,@enddate,@Machineid,'','DTimeforOEETrend',@plantid,'0' --ER0344 commented

	If @Format = 'Format1' or  @Format='Format4' or @format='Format5'
	Begin
			insert into #Comparisonoutput
			Exec s_GetShiftAgg_ComparisonReports @startdate,@enddate,@shift,@PlantID,'','','','','OEE_MONTH','All KPIs'
-- Exec s_GetShiftAgg_ComparisonReports1 '2011-01-01','2011-12-30','','','','','','OEE_MONTH','All KPIs'
--ER0344 commented from here
--			If @Parameter= 'Critical Machines'
--			Begin
--				Insert into #PlantMachineInfo(Machineid,Plantid,targetoe)
--				select distinct M.Machineid,P.Plantid,0 from
--				Machineinformation M
--				inner join PlantMachine P on M.machineid=P.Machineid
--				inner join shiftproductiondetails SPD on SPD.machineid=M.machineid --and  SPD.machineid=M.machineid
--				where M.TPMTrakEnabled='1' and SPD.CriticalMachineEnabled = '1' and m.machineid in ( @machineid )
--print @machineid
--			END
--			
--			If @parameter='ALL Machines'
--			Begin
--				Insert into #PlantMachineInfo(Machineid,Plantid,targetoe)
--				select distinct M.Machineid,P.Plantid,0 from
--				Machineinformation M
--				inner join PlantMachine P on M.machineid=P.Machineid
--				inner join shiftproductiondetails SPD on SPD.machineid=M.machineid
--				where M.TPMTrakEnabled=1
--			END
--ER0344 commented till here
--ER0344 added from here
			If @Parameter= 'Critical Machines'
			Begin
			SELECT @StrSql1= N''
			SELECT @StrSql1='Insert into #PlantMachineInfo(Machineid,Plantid,targetoe)'
			SELECT @StrSql1=@StrSql1+' select distinct M.Machineid,P.Plantid,0 from
							Machineinformation M
							inner join PlantMachine P on M.machineid=P.Machineid
							inner join shiftproductiondetails SPD on SPD.machineid=M.machineid
							where M.TPMTrakEnabled=''1'' and SPD.CriticalMachineEnabled = ''1'' '+@strmachine
			print @StrSql1
			exec (@StrSql1)
				
			END
			
			If @parameter='ALL Machines'
			Begin
			SELECT @StrSql=''
			SELECT @StrSql='Insert into #PlantMachineInfo(Machineid,Plantid,targetoe)
							select distinct M.Machineid,P.Plantid,0 from
							Machineinformation M
							inner join PlantMachine P on M.machineid=P.Machineid
							inner join shiftproductiondetails SPD on SPD.machineid=M.machineid
							where M.TPMTrakEnabled=1  '+ @strmachine
			print @StrSql
			exec (@StrSql)
			END
--ER0344 added till here
			update #PlantMachineInfo set Machinewiseowner = T2.Machinewiseowner from
			(
			  select distinct Machineid,Machinewiseowner from shiftproductiondetails  where pdate>=@startdate and pdate<=@enddate
			)T2 inner join #PlantMachineInfo P on T2.Machineid=P.Machineid
			
			update #PlantMachineInfo set TargetOE = isnull(TargetOE,0) + isnull(T2.OE,0) from
			(
			  select Machineid,Max(OE) as OE from EfficiencyTarget E  where
--ER0344 added from here
			  datepart(yyyy,startdate) + '-' + datepart(mm,startdate) >=datepart(yyyy,@startdate) + '-' + datepart(mm,@startdate)
			 and datepart(yyyy,enddate) + '-' + datepart(mm,enddate)<=datepart(yyyy,@enddate) + '-' + datepart(mm,@enddate)
--ER0344 added till here
			  group by Machineid
			)T2 inner join #PlantMachineInfo P on T2.Machineid=P.Machineid
	END

	

	If  @Format = 'Format1' or @Format='Format4'
	BEGIN
		-------------------------------- To Calculate Previous Year OEE -------------------------------
		select @start=dateadd(year,-1,@startdate)
		--select @starttime = dateadd(year,-1,@startdate)
		select @endtime = dateadd(year,-1,@EndDate)

		select @oldyear=(select datepart(yyyy,@start))
		select @starttime=''
		select @endtime=''

		select @starttime=@oldyear+'-'+'01'+'-'+'01'
		select @endtime=@oldyear+'-'+'12'+'-'+'31'
		select @oldyear=''		
	
		
		SELECT @StrSql='INSERT INTO #ConsolidatedOutput(
		 MachineID ,PEffy ,AEffy ,QEffy,OEffy ,
		 ProdCount ,AcceptedParts,RejCount,MarkedForRework,UtilisedTime ,DownTime ,CN )
		 SELECT Distinct M.MachineID,0,0,0,0,0,0,0,0 ,0,0,0
		 FROM Machineinformation M
		 Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		 Where M.Interfaceid>''0'''
		 SELECT @StrSql=@StrSql+ @StrPlantID+ @Strmachine
		 Print @StrSql
		 EXEC(@StrSql)
		
		SELECT @StrSql='Update #ConsolidatedOutput Set ProdCount=ISNULL(T2.ProdCount,0)
		From (Select MachineID,Sum(Prod_Qty)AS ProdCount From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ConsolidatedOutput ON T2.MachineID=#ConsolidatedOutput.MachineID'
		print @StrSql
		EXEC(@StrSql)
		
		
		SELECT @StrSql='Update #ConsolidatedOutput Set AcceptedParts=ISNULL(T2.AcceptedParts,0)
		From (Select MachineID,Sum(AcceptedParts)AS AcceptedParts From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ConsolidatedOutput ON T2.MachineID=#ConsolidatedOutput.MachineID'
		print @StrSql
		EXEC(@StrSql)
		
		SELECT @StrSql='Update #ConsolidatedOutput Set MarkedForRework=ISNULL(T2.MarkedForRework,0)
		From (Select MachineID,Sum(Marked_For_Rework)AS MarkedForRework From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ConsolidatedOutput ON T2.MachineID=#ConsolidatedOutput.MachineID'
		print @StrSql
		EXEC(@StrSql)
		
	
		SELECT @StrSql='Update #ConsolidatedOutput Set RejCount=ISNULL(T2.RejCount,0)
		From (Select MachineID,Sum(Rejection_Qty)AS RejCount From ShiftProductionDetails
		Inner Join ShiftRejectionDetails On ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		Where pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ConsolidatedOutput ON T2.MachineID=#ConsolidatedOutput.MachineID'
		EXEC(@StrSql)
		Update #ConsolidatedOutput Set CN=ISNULL(T2.CN,0)
		From (
		Select MachineID,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN
		From ShiftProductionDetails
		Where pDate>=@starttime and pDate<=@endtime
		Group By MachineID )AS T2 Inner Join #ConsolidatedOutput ON T2.MachineID=#ConsolidatedOutput.MachineID
		
		
		
		SELECT @StrSql='UPDATE #ConsolidatedOutput SET UtilisedTime = IsNull(T2.UtilisedTime,0)
		From (select MachineID,Sum(Sum_of_ActCycleTime)As UtilisedTime
		From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID) as T2 Inner Join #ConsolidatedOutput ON T2.MachineID=#ConsolidatedOutput.MachineID'
		EXEC(@StrSql)
		
		SELECT @StrSql='UPDATE #ConsolidatedOutput SET UtilisedTime = Isnull(#ConsolidatedOutput.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
		From (SELECT MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime
			FROM ShiftDownTimeDetails WHERE PE_Flag = 1
		and ddate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+''''
		SELECT @StrSql=@StrSql+' group by machineid) as T2 Inner Join #ConsolidatedOutput ON T2.MachineID=#ConsolidatedOutput.MachineID'
		EXEC(@StrSql)
		SELECT @StrSql='Update #ConsolidatedOutput Set DownTime=ISNULL(#ConsolidatedOutput.DownTime,0) + ISNULL(T2.DownTime,0)  --DR0292
		From (Select MachineID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
		Where dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+''' '-- And ML_Flag=0'
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ConsolidatedOutput ON T2.MachineID=#ConsolidatedOutput.MachineID'
		EXEC(@StrSql)
			SELECT @StrSql='Update #ConsolidatedOutput Set DownTimeAE=ISNULL(#ConsolidatedOutput.DownTimeAE,0) + ISNULL(T2.DownTime,0) --DR0292
			From (Select MachineID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
			Where dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+''' '
			SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ConsolidatedOutput ON T2.MachineID=#ConsolidatedOutput.MachineID'
			EXEC(@StrSql)
			SELECT @StrSql=' UPDATE #ConsolidatedOutput SET MgmtLoss = Isnull(#ConsolidatedOutput.MgmtLoss,0)+IsNull(T1.LOSS,0)
			From (select MachineID,
			sum(
				 CASE
				WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
				THEN isnull(ShiftDownTimeDetails.Threshold,0)
				ELSE ShiftDownTimeDetails.DownTime
				 END) AS LOSS
				From ShiftDownTimeDetails
				Where dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+''' and ShiftDownTimeDetails.Ml_Flag=1 '
			SELECT @StrSql=@StrSql+' Group By MachineID
			) as T1 Inner Join #ConsolidatedOutput ON  #ConsolidatedOutput.MachineID=T1.MachineID '
			EXEC(@StrSql)
		---mod 1
		UPDATE #ConsolidatedOutput SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0) --DR0292
	
		UPDATE #ConsolidatedOutput SET QEffy= ISNULL(#ConsolidatedOutput.QEffy,0) + IsNull(T1.QE,0) --DR0292
		FROM(Select MachineID,
		CAST((Sum(AcceptedParts))As Float)/CAST((Sum(IsNull(AcceptedParts,0))+Sum(IsNull(MarkedForRework,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
		From #ConsolidatedOutput Where AcceptedParts<>0 Group By MachineID
		)AS T1 Inner Join #ConsolidatedOutput ON  #ConsolidatedOutput.MachineID=T1.MachineID
		
		UPDATE #ConsolidatedOutput
		SET
			PEffy = (CN/UtilisedTime) ,
			AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTimeAE,0)-isnull(MgmtLoss,0))
		WHERE UtilisedTime <> 0
		UPDATE #ConsolidatedOutput
		SET
			OEffy = PEffy * AEffy * 100,
			PEffy = PEffy * 100 ,
			AEffy = AEffy * 100,
			QEffy = QEffy * 100
		Insert into #Finaloutput(Pdate,Startdate,enddate,shift,PlantID,Machineid,OwnerName,MachinewiseTarget,PrevyearOEE,AEffy,PEffy,QEffy,OEffy)
		select ltrim((right(convert(varchar, C.StartDate, 106), 8))),C.StartDate,C.EndDate,c.shift,P.PlantID,P.MachineID,P.Machinewiseowner,P.TargetOE,Round(CO.OEffy,2),round(C.AEffy,2),round(C.PEffy,2),Round(C.QEffy,2),Round(C.OEffy,2)
		from #Comparisonoutput C
		inner join #PlantMachineInfo P on C.Machineid=P.Machineid
		inner join #ConsolidatedOutput CO on C.Machineid=CO.Machineid
	
		If @format = 'Format1'
		Begin
			select * from #Finaloutput order by startdate,enddate,Machineid
		end
		If @format= 'Format4'
		Begin
			select pdate,Machineid,AEffy,PEffy,QEffy,OEffy,PrevyearOEE,MachinewiseTarget From #Finaloutput order by Machineid,startdate
		end
	END
	IF @format = 'Format2' and @Parameter= 'Critical Machines'
	Begin
		/************************************************************************************
						To Get Previous Year Efficiency details.
		*************************************************************************************/
				--select @starttime = dateadd(year,-1,@startdate)
				--select @endtime = dateadd(year,-1,@EndDate)

		select @start=dateadd(year,-1,@startdate)
		select @endtime = dateadd(year,-1,@EndDate)

		select @oldyear=(select datepart(yyyy,@start))
		select @starttime=''
		select @endtime=''

		select @starttime=@oldyear+'-'+'01'+'-'+'01'
		select @endtime=@oldyear+'-'+'12'+'-'+'31'
		select @oldyear=''
					

				INSERT INTO #ConsolidatedOutput(
				  PEffy ,AEffy ,QEffy,OEffy ,
				 ProdCount ,AcceptedParts,RejCount,MarkedForRework,UtilisedTime ,DownTime ,CN )
				 SELECT 0,0,0,0,0,0,0,0 ,0,0,0

				 
				
				
				SELECT @StrSql='Update #ConsolidatedOutput Set ProdCount=ISNULL(T2.ProdCount,0)
				From (Select Sum(Prod_Qty)AS ProdCount From ShiftProductionDetails
				where ShiftProductionDetails.CriticalMachineEnabled=1 and
				 pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				print @StrSql
				EXEC(@StrSql)		

				
				SELECT @StrSql='Update #ConsolidatedOutput Set AcceptedParts=ISNULL(T2.AcceptedParts,0)
				From (Select Sum(AcceptedParts)AS AcceptedParts From ShiftProductionDetails
				where ShiftProductionDetails.CriticalMachineEnabled=1 and
				 pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				print @StrSql
				EXEC(@StrSql)
				
				SELECT @StrSql='Update #ConsolidatedOutput Set MarkedForRework=ISNULL(T2.MarkedForRework,0)
				From (Select Sum(Marked_For_Rework)AS MarkedForRework From ShiftProductionDetails
				where ShiftProductionDetails.CriticalMachineEnabled=1
				and
				pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				print @StrSql
				EXEC(@StrSql)
				
			
				SELECT @StrSql='Update #ConsolidatedOutput Set RejCount=ISNULL(T2.RejCount,0)
				From (Select Sum(Rejection_Qty)AS RejCount From ShiftProductionDetails
				Inner Join ShiftRejectionDetails On ShiftProductionDetails.ID=ShiftRejectionDetails.ID
				where ShiftProductionDetails.CriticalMachineEnabled=1
				and
				pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				EXEC(@StrSql)
				Update #ConsolidatedOutput Set CN=ISNULL(T2.CN,0)
				From (
				Select sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN
				From ShiftProductionDetails
				where ShiftProductionDetails.CriticalMachineEnabled=1
				and pDate>=@starttime and pDate<=@endtime)T2

				
				
				SELECT @StrSql='UPDATE #ConsolidatedOutput SET UtilisedTime = IsNull(T2.UtilisedTime,0)
				From (select Sum(Sum_of_ActCycleTime)As UtilisedTime
				From ShiftProductionDetails
				where ShiftProductionDetails.CriticalMachineEnabled=1
				and
				pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				EXEC(@StrSql)
				
				SELECT @StrSql='UPDATE #ConsolidatedOutput SET UtilisedTime = Isnull(#ConsolidatedOutput.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
				From (SELECT sum(datediff(s,starttime,endtime)) as MinorDownTime
					FROM ShiftDownTimeDetails
				where PE_Flag = 1 and ShiftDownTimeDetails.CriticalMachineEnabled=1
				and dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				EXEC(@StrSql)
				SELECT @StrSql='Update #ConsolidatedOutput Set DownTime=ISNULL(#ConsolidatedOutput.DownTime,0) + ISNULL(T2.DownTime,0)  --DR0292
				From (Select Sum(DownTime)AS DownTime From ShiftDownTimeDetails
				where ShiftDownTimeDetails.CriticalMachineEnabled=1 and
				dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				EXEC(@StrSql)
				SELECT @StrSql='Update #ConsolidatedOutput Set DownTimeAE=ISNULL(#ConsolidatedOutput.DownTimeAE,0) + ISNULL(T2.DownTime,0) --DR0292
				From (Select Sum(DownTime)AS DownTime From ShiftDownTimeDetails
				where ShiftDownTimeDetails.CriticalMachineEnabled=1
				and
				dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				EXEC(@StrSql)
				SELECT @StrSql=' UPDATE #ConsolidatedOutput SET MgmtLoss = Isnull(#ConsolidatedOutput.MgmtLoss,0)+IsNull(T2.LOSS,0)
				From (select
				sum(
					 CASE
					WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
					THEN isnull(ShiftDownTimeDetails.Threshold,0)
					ELSE ShiftDownTimeDetails.DownTime
					 END) AS LOSS
					From ShiftDownTimeDetails
				where ShiftDownTimeDetails.CriticalMachineEnabled=1
				and
				dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+'''
				and ShiftDownTimeDetails.Ml_Flag=1)T2'	
				EXEC(@StrSql)
			
				UPDATE #ConsolidatedOutput SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0) --DR0292
				UPDATE #ConsolidatedOutput SET QEffy= ISNULL(#ConsolidatedOutput.QEffy,0) + IsNull(T1.QE,0) --DR0292
				FROM(Select
				CAST((Sum(AcceptedParts))As Float)/CAST((Sum(IsNull(AcceptedParts,0))+Sum(IsNull(MarkedForRework,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
				From #ConsolidatedOutput Where AcceptedParts<>0
				)AS T1
				
				UPDATE #ConsolidatedOutput
				SET
					PEffy = (CN/UtilisedTime) ,
					AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))
				WHERE UtilisedTime <> 0
		
				UPDATE #ConsolidatedOutput
				SET
					OEffy = PEffy * AEffy * 100,
					PEffy = PEffy * 100 ,
					AEffy = AEffy * 100,
					QEffy = QEffy * 100
-- [dbo].[s_GetOEETrend] '2012-02-01','2012-02-28','','','''ACE-05''','Critical Machines','Format1'
-- [dbo].[s_GetOEETrend] '2012-02-01','2012-02-28','','','''ACE-05''','Critical Machines','Format2'
		/************************************************************************************
						To Get Current Year Efficiency details.
		*************************************************************************************/
		select @Starttime = @startdate
		select @endtime = @EndDate
		SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@Starttime,'Start')
		select @AddMonth=DateAdd(mm,11,@StartDate) --ER0344 added
		SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@AddMonth,'End')
--		SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@endtime,'End')


		
		While @StratOfMonth<=@EndOfMonth
		BEGIN
			INSERT INTO #Comparisonoutput ( Startdate, Enddate)
			SELECT @StratOfMonth,dbo.f_GetPhysicalMonth(@StratOfMonth,'End')
			SELECT @StratOfMonth=DateAdd(mm,1,@StratOfMonth)
		END

		
--ER0344 added from here
		If isnull(@shift,'') <> ''
		Begin
			Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @shift + ''')'
		End

--ER0344 added till here
		Select @Strsql = 'Update #Comparisonoutput Set ProdCount=ISNULL(T1.ProdCount,0),AcceptedParts=ISNULL(T1.AcceptedParts,0),'
		Select @Strsql = @Strsql+ 'RepeatCycle=ISNULL(T1.Repeat_Cycles,0),DummyCycle=ISNULL(T1.Dummy_Cycles,0),'
		Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T1.Rework_Performed,0),MarkedForRework=ISNULL(T1.MarkedForRework,0),UtilisedTime=ISNULL(T1.UtilisedTime,0)'
		Select @Strsql = @Strsql+ ' From('
		Select @Strsql = @Strsql+ ' Select T.startdate,T.enddate,Sum(ISNULL(Prod_Qty,0))ProdCount,Sum(ISNULL(AcceptedParts,0))AcceptedParts,Sum(ISNULL(Repeat_Cycles,0))AS Repeat_Cycles ,Sum(ISNULL(Dummy_Cycles,0))AS Dummy_Cycles,
									Sum(ISNULL(Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(Marked_For_Rework,0)) AS MarkedForRework,Sum(Sum_of_ActCycleTime)As UtilisedTime
		                            From ShiftProductionDetails
									cross join (select startdate,enddate from #Comparisonoutput)T
									where
									ShiftProductionDetails.CriticalMachineEnabled=1 and
								    pdate>=T.startdate and pdate<=T.enddate
									and pDate>= ''' + convert(nvarchar(20),@StartDate,120)+ '''  And pDate<= ''' + convert(nvarchar(20),@endDate,120)+ ''''
		Select @Strsql = @Strsql+ @strshift --ER0344 added
		Select @Strsql = @Strsql+ '	 group by T.startdate,T.enddate
									) T1 '
		Select @Strsql = @Strsql+ ' inner join #Comparisonoutput on T1.startdate=#Comparisonoutput.startdate
									and T1.enddate=#Comparisonoutput.enddate '
		Print @Strsql
		Exec(@Strsql)

	
		
		If isnull(@shift,'') <> ''
		Begin
			---mod 3
		--	Select @StrShift = ' And ( ShiftProductionDetails.Shift = ''' + @ShiftName + ''')'
			Select @StrShift = ' And ( ShiftDowntimeDetails.Shift = N''' + @shift + ''')'
			---mod 3
		End
		Select @Strsql =''
		SELECT @StrSql='UPDATE #Comparisonoutput SET UtilisedTime = Isnull(#Comparisonoutput.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '
		Select @Strsql = @Strsql+ 'From (SELECT datepart(mm,ddate)as dmonth,datepart(yyyy,ddate)as dyear,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '
		Select @Strsql = @Strsql+ 'WHERE downid in (select downid from downcodeinformation where prodeffy = 1)  and shiftdowntimedetails.criticalmachineenabled=1'
		Select @Strsql = @Strsql+ @strshift --ER0344 added
		Select @Strsql = @Strsql+ '	Group By datepart(mm,ddate),datepart(yyyy,ddate)'
		Select @Strsql = @Strsql+ ') as T2 Inner Join #Comparisonoutput ON T2.dmonth=datepart(mm,#Comparisonoutput.Startdate) and T2.dyear=datepart(yyyy,#Comparisonoutput.EndDate)'
		print @strsql
		EXEC(@StrSql)
		If isnull(@shift,'') <> ''
		Begin
			Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @shift + ''')'
		End
		Select @Strsql = 'UPDATE #Comparisonoutput SET RejCount=ISNULL(T1.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T.startdate,T.enddate,Sum(isnull(Rejection_Qty,0))Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails
								   Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
								   cross join (select startdate,enddate from #Comparisonoutput)T'
		Select @Strsql = @Strsql+' Where
								    ShiftProductionDetails.CriticalMachineEnabled=1 and pDate>=T.StartDate And pDate<= T.EndDate
								and pDate>= ''' + convert(nvarchar(20),@StartDate,120)+ '''  And pDate<= ''' + convert(nvarchar(20),@endDate,120)+ ''''
		Select @Strsql = @Strsql+ @strshift --ER0344 added
		Select @Strsql = @Strsql+' Group By T.startdate,T.enddate )T1
									inner join #Comparisonoutput on T1.startdate=#Comparisonoutput.startdate
									and T1.enddate=#Comparisonoutput.enddate'
		Print @Strsql
		Exec(@Strsql)
		
		Select @Strsql = 'Update #Comparisonoutput Set CN=ISNULL(T2.CN,0)'
		Select @Strsql = @Strsql + ' From ('
		Select @Strsql = @Strsql + ' Select T.startdate,T.enddate,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '
		Select @Strsql = @Strsql + ' From ShiftProductionDetails
									 cross join (select startdate,enddate from #Comparisonoutput)T '
		Select @Strsql = @Strsql + ' Where
									 ShiftProductionDetails.CriticalMachineEnabled=1 and  pDate>=T.StartDate And pDate<= T.EndDate
									and pDate>= ''' + convert(nvarchar(20),@StartDate,120)+ '''  And pDate<= ''' + convert(nvarchar(20),@endDate,120)+ ''''
		Select @Strsql = @Strsql+ @strshift --ER0344 added
		Select @Strsql = @Strsql + ' Group By T.startdate,T.enddate '
		Select @Strsql = @Strsql + ' )AS T2 inner join #Comparisonoutput on T2.startdate=#Comparisonoutput.startdate
									and T2.enddate=#Comparisonoutput.enddate '
		Print @Strsql
		Exec(@Strsql)
		
		If isnull(@shift,'') <> ''
		Begin
			Select @StrShift = ' And ( ShiftDowntimeDetails.Shift = N''' + @shift + ''')'
		End
		
		Select @Strsql = 'UPDATE #Comparisonoutput SET DownTime = IsNull(T2.DownTime,0)'
		Select @Strsql = @Strsql + ' From (select T.startdate,T.enddate,(Sum(DownTime))As DownTime'
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails
									 cross join (select startdate,enddate from #Comparisonoutput)T
									where 	shiftdowntimedetails.criticalmachineenabled=1 and  dDate>=T.StartDate And dDate<= T.EndDate
									and dDate>= ''' + convert(nvarchar(20),@StartDate,120)+ '''  And dDate<= ''' + convert(nvarchar(20),@endDate,120)+ ''''
		Select @Strsql = @Strsql+ @strshift --ER0344 added
		Select @Strsql = @Strsql + ' Group By T.startdate,T.enddate'
		Select @Strsql = @Strsql + ' ) AS T2 inner join #Comparisonoutput on T2.startdate=#Comparisonoutput.startdate
									and T2.enddate=#Comparisonoutput.enddate '
		Print @Strsql
		Exec(@Strsql)	
		Select @Strsql = 'UPDATE #Comparisonoutput SET ManagementLoss =  isNull(T2.loss,0)'
		Select @Strsql = @Strsql + 'from (select T.startdate,T.enddate, sum(
		 CASE
		WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
		THEN isnull(ShiftDownTimeDetails.Threshold,0)
		ELSE ShiftDownTimeDetails.DownTime
		 END) AS LOSS '
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails
										 cross join (select startdate,enddate from #Comparisonoutput)T
where ML_flag = 1 and shiftdowntimedetails.criticalmachineenabled=1
										 and dDate>=T.StartDate And dDate<= T.EndDate
									and dDate>= ''' + convert(nvarchar(20),@StartDate,120)+ '''  And dDate<= ''' + convert(nvarchar(20),@endDate,120)+ ''''
		Select @Strsql = @Strsql+ @strshift --ER0344 added
		Select @Strsql = @Strsql + ' Group By T.startdate,T.enddate'
		Select @Strsql = @Strsql + ' ) AS T2 inner join #Comparisonoutput on T2.startdate=#Comparisonoutput.startdate
									and T2.enddate=#Comparisonoutput.enddate'
		Print @Strsql
		Exec(@Strsql)	
		---mod 1 introduced with mod2 to neglect threshold ML from dtime
		UPDATE #Comparisonoutput SET DownTime=DownTime-ManagementLoss
		UPDATE #Comparisonoutput SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)
		Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0
		UPDATE #Comparisonoutput
		SET
			PEffy = (CN/UtilisedTime) ,
			AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))
		WHERE UtilisedTime <> 0
		UPDATE #Comparisonoutput
		SET
			OEffy = PEffy * AEffy * QEffy * 100,
			PEffy = PEffy * 100 ,
			AEffy = AEffy * 100,
			QEffy = QEffy * 100

	
		
		Insert into #Finaloutput(Pdate,Startdate,enddate,MachinewiseTarget,PrevyearOEE,AEffy,PEffy,QEffy,OEffy)
		select ltrim((right(convert(varchar,StartDate, 106), 8))),C.StartDate,C.EndDate,0,round(CO.Oeffy,2),round(C.AEffy,2),round(C.PEffy,2),Round(C.QEffy,2),Round(C.OEffy,2)
		from #Comparisonoutput C,#ConsolidatedOutput CO where 1=1
		Update #Finaloutput set MachinewiseTarget = isnull(MachinewiseTarget,0) + isnull(T2.target,0)
		from
		(select Avg(T1.target) as target from
		(Select Machineid,Max(oe)as target from efficiencytarget
		 --where startdate>=@starttime and enddate<=@enddate
		where
		 datepart(yyyy,startdate) + '-' + datepart(mm,startdate) >=datepart(yyyy,@starttime) + '-' + datepart(mm,@starttime)
		 and datepart(yyyy,enddate) + '-' + datepart(mm,enddate)<=datepart(yyyy,@enddate) + '-' + datepart(mm,@enddate)
		 group by Machineid)T1)T2
	
		select Pdate,AEffy,PEffy,QEffy,OEffy,PrevyearOEE,MachinewiseTarget From #Finaloutput order by startdate,enddate
	END
	If @Format='Format3' and @parameter='ALL Machines'
	Begin
-- [dbo].[s_GetOEETrend] '2012-02-01','2012-02-28','','','''ACE-05''','all Machines','Format3'
		/************************************************************************************
						To Get Previous Year Efficiency details.
		*************************************************************************************/
				--select @starttime = dateadd(year,-1,@startdate)
				--select @endtime = dateadd(year,-1,@EndDate)
				
				select @start=dateadd(year,-1,@startdate)
				--select @starttime = dateadd(year,-1,@startdate)
				select @endtime = dateadd(year,-1,@EndDate)

				select @oldyear=(select datepart(yyyy,@start))
				select @starttime=''
				select @endtime=''

				select @starttime=@oldyear+'-'+'01'+'-'+'01'
				select @endtime=@oldyear+'-'+'12'+'-'+'31'
				select @oldyear=''

				INSERT INTO #ConsolidatedOutput(
				  PEffy ,AEffy ,QEffy,OEffy ,
				 ProdCount ,AcceptedParts,RejCount,MarkedForRework,UtilisedTime ,DownTime ,CN )
				 SELECT 0,0,0,0,0,0,0,0 ,0,0,0
				
				
				SELECT @StrSql='Update #ConsolidatedOutput Set ProdCount=ISNULL(T2.ProdCount,0)
				From (Select Sum(Prod_Qty)AS ProdCount From ShiftProductionDetails
				inner join Machineinformation M on M.machineid=ShiftProductionDetails.Machineid
				where M.tpmtrakenabled=1
				and pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				print @StrSql
				EXEC(@StrSql)
				
				SELECT @StrSql='Update #ConsolidatedOutput Set AcceptedParts=ISNULL(T2.AcceptedParts,0)
				From (Select Sum(AcceptedParts)AS AcceptedParts From ShiftProductionDetails
				inner join Machineinformation M on M.machineid=ShiftProductionDetails.Machineid
				where M.tpmtrakenabled=1
				and pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				print @StrSql
				EXEC(@StrSql)
				
				SELECT @StrSql='Update #ConsolidatedOutput Set MarkedForRework=ISNULL(T2.MarkedForRework,0)
				From (Select Sum(Marked_For_Rework)AS MarkedForRework From ShiftProductionDetails
				inner join Machineinformation M on M.machineid=ShiftProductionDetails.Machineid
				where M.tpmtrakenabled=1
				and pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				print @StrSql
				EXEC(@StrSql)
				
			
				SELECT @StrSql='Update #ConsolidatedOutput Set RejCount=ISNULL(T2.RejCount,0)
				From (Select Sum(Rejection_Qty)AS RejCount From ShiftProductionDetails
				Inner Join ShiftRejectionDetails On ShiftProductionDetails.ID=ShiftRejectionDetails.ID
				inner join Machineinformation M on M.machineid=ShiftProductionDetails.Machineid
				where M.tpmtrakenabled=1
				and pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				EXEC(@StrSql)
				Update #ConsolidatedOutput Set CN=ISNULL(T2.CN,0)
				From (
				Select sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN
				From ShiftProductionDetails
				inner join Machineinformation M on M.machineid=ShiftProductionDetails.Machineid
				where M.tpmtrakenabled=1
				and pDate>=@starttime and pDate<=@endtime)T2
				
				
				
				SELECT @StrSql='UPDATE #ConsolidatedOutput SET UtilisedTime = IsNull(T2.UtilisedTime,0)
				From (select Sum(Sum_of_ActCycleTime)As UtilisedTime
				From ShiftProductionDetails
				inner join Machineinformation M on M.machineid=ShiftProductionDetails.Machineid
				where M.tpmtrakenabled=1
				and pDate>='''+Convert(NvarChar(20),@starttime)+''' and pDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				EXEC(@StrSql)
				
				SELECT @StrSql='UPDATE #ConsolidatedOutput SET UtilisedTime = Isnull(#ConsolidatedOutput.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
				From (SELECT sum(datediff(s,starttime,endtime)) as MinorDownTime
					FROM ShiftDownTimeDetails
				inner join Machineinformation M on M.machineid=ShiftDownTimeDetails.Machineid
				where PE_Flag = 1 and M.tpmtrakenabled=1
				and dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				EXEC(@StrSql)
				SELECT @StrSql='Update #ConsolidatedOutput Set DownTime=ISNULL(#ConsolidatedOutput.DownTime,0) + ISNULL(T2.DownTime,0)  --DR0292
				From (Select Sum(DownTime)AS DownTime From ShiftDownTimeDetails
				inner join Machineinformation M on M.machineid=ShiftDownTimeDetails.Machineid
				where M.tpmtrakenabled=1
				and dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
				EXEC(@StrSql)
					SELECT @StrSql='Update #ConsolidatedOutput Set DownTimeAE=ISNULL(#ConsolidatedOutput.DownTimeAE,0) + ISNULL(T2.DownTime,0) --DR0292
					From (Select Sum(DownTime)AS DownTime From ShiftDownTimeDetails
					inner join Machineinformation M on M.machineid=ShiftDownTimeDetails.Machineid
					where  M.tpmtrakenabled=1
					and dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+''')T2'
					EXEC(@StrSql)
					SELECT @StrSql=' UPDATE #ConsolidatedOutput SET MgmtLoss = Isnull(#ConsolidatedOutput.MgmtLoss,0)+IsNull(T2.LOSS,0)
					From (select
					sum(
						 CASE
						WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
						THEN isnull(ShiftDownTimeDetails.Threshold,0)
						ELSE ShiftDownTimeDetails.DownTime
						 END) AS LOSS
						From ShiftDownTimeDetails
					 inner join Machineinformation M on M.machineid=ShiftDownTimeDetails.Machineid
					where  M.tpmtrakenabled=1
					and dDate>='''+Convert(NvarChar(20),@starttime)+''' and dDate<='''+Convert(NvarChar(20),@endtime)+'''
					and ShiftDownTimeDetails.Ml_Flag=1)T2'	
					EXEC(@StrSql)
				
				UPDATE #ConsolidatedOutput SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0) --DR0292
			
				UPDATE #ConsolidatedOutput SET QEffy= ISNULL(#ConsolidatedOutput.QEffy,0) + IsNull(T1.QE,0) --DR0292
				FROM(Select
				CAST((Sum(AcceptedParts))As Float)/CAST((Sum(IsNull(AcceptedParts,0))+Sum(IsNull(MarkedForRework,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
				From #ConsolidatedOutput Where AcceptedParts<>0
				)AS T1
				
				UPDATE #ConsolidatedOutput
				SET
					PEffy = (CN/UtilisedTime) ,
					AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTimeAE,0)-isnull(MgmtLoss,0))
				WHERE UtilisedTime <> 0
				UPDATE #ConsolidatedOutput
				SET
					OEffy = PEffy * AEffy * 100,
					PEffy = PEffy * 100 ,
					AEffy = AEffy * 100,
					QEffy = QEffy * 100
	   /************************************************************************************
						To Get Current Year Efficiency details.
		*************************************************************************************/
		select @Starttime = @startdate
		select @endtime = @EndDate
		SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@Starttime,'Start')
		select @AddMonth=DateAdd(mm,11,@StartDate)--ER0344 added
		SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@AddMonth,'End')
--		SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@endtime,'End')
		
		While @StratOfMonth<=@EndOfMonth
		BEGIN
			INSERT INTO #Comparisonoutput ( Startdate, Enddate)
			SELECT @StratOfMonth,dbo.f_GetPhysicalMonth(@StratOfMonth,'End')
			SELECT @StratOfMonth=DateAdd(mm,1,@StratOfMonth)
		END
-------- [dbo].[s_GetOEETrend] '2012-01-01','2012-02-29','third','','','all Machines','Format3'
		If isnull(@shift,'') <> ''
		Begin
			Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @shift + ''')'
		End
		Select @Strsql = 'Update #Comparisonoutput Set ProdCount=ISNULL(T1.ProdCount,0),AcceptedParts=ISNULL(T1.AcceptedParts,0),'
		Select @Strsql = @Strsql+ 'RepeatCycle=ISNULL(T1.Repeat_Cycles,0),DummyCycle=ISNULL(T1.Dummy_Cycles,0),'
		Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T1.Rework_Performed,0),MarkedForRework=ISNULL(T1.MarkedForRework,0),UtilisedTime=ISNULL(T1.UtilisedTime,0)'
		Select @Strsql = @Strsql+ ' From('
		Select @Strsql = @Strsql+ ' Select T.startdate,T.enddate,Sum(ISNULL(Prod_Qty,0))ProdCount,Sum(ISNULL(AcceptedParts,0))AcceptedParts,Sum(ISNULL(Repeat_Cycles,0))AS Repeat_Cycles ,Sum(ISNULL(Dummy_Cycles,0))AS Dummy_Cycles,
									Sum(ISNULL(Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(Marked_For_Rework,0)) AS MarkedForRework,Sum(Sum_of_ActCycleTime)As UtilisedTime
		                            From ShiftProductionDetails
									inner join Machineinformation M on M.machineid=ShiftProductionDetails.Machineid
									cross join (select startdate,enddate from #Comparisonoutput)T
									where M.tpmtrakenabled=1
									and pdate>=T.startdate and pdate<=T.enddate
									and pDate>= ''' + convert(nvarchar(20),@StartDate,120)+ '''  And pDate<= ''' + convert(nvarchar(20),@endDate,120)+ ''''
		Select @Strsql = @Strsql+@StrShift --ER0344 added
		Select @Strsql = @Strsql+ ' group by T.startdate,T.enddate
									) T1 '
		Select @Strsql = @Strsql+ ' inner join #Comparisonoutput on T1.startdate=#Comparisonoutput.startdate
									and T1.enddate=#Comparisonoutput.enddate '
		Print @Strsql
		Exec(@Strsql)
		
		If isnull(@shift,'') <> ''
		Begin
			Select @StrShift = ' And ( ShiftDownTimeDetails.Shift = N''' + @shift + ''')'
		End
		Select @Strsql =''
		SELECT @StrSql='UPDATE #Comparisonoutput SET UtilisedTime = Isnull(#Comparisonoutput.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '
		Select @Strsql = @Strsql+ 'From (SELECT datepart(mm,ddate)as dmonth,datepart(yyyy,ddate)as dyear,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails
									inner join Machineinformation M on M.machineid=ShiftDownTimeDetails.Machineid and M.tpmtrakenabled=1  '
		Select @Strsql = @Strsql+ 'WHERE downid in (select downid from downcodeinformation where prodeffy = 1) '
		Select @Strsql = @Strsql+@StrShift --ER0344 added
		Select @Strsql = @Strsql+ '	 Group By datepart(mm,ddate),datepart(yyyy,ddate)'
		Select @Strsql = @Strsql+ ') as T2 Inner Join #Comparisonoutput ON T2.dmonth=datepart(mm,#Comparisonoutput.Startdate) and T2.dyear=datepart(yyyy,#Comparisonoutput.EndDate)'
		print @strsql
		EXEC(@StrSql)
		
		If isnull(@shift,'') <> ''
		Begin
			Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @shift + ''')'
		End
		Select @Strsql = 'UPDATE #Comparisonoutput SET RejCount=ISNULL(T1.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T.startdate,T.enddate,Sum(isnull(Rejection_Qty,0))Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails inner join Machineinformation M on M.machineid= Shiftproductiondetails.Machineid
									Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
									cross join (select startdate,enddate from #Comparisonoutput)T'
		Select @Strsql = @Strsql+' Where M.tpmtrakenabled=1
								    and pDate>=T.StartDate And pDate<= T.EndDate
									and pDate>= ''' + convert(nvarchar(20),@StartDate,120)+ '''  And pDate<= ''' + convert(nvarchar(20),@endDate,120)+ ''''
		Select @Strsql = @Strsql+@StrShift --ER0344 added
		Select @Strsql = @Strsql+' Group By T.startdate,T.enddate )T1
									inner join #Comparisonoutput on T1.startdate=#Comparisonoutput.startdate
									and T1.enddate=#Comparisonoutput.enddate'
		Print @Strsql
		Exec(@Strsql)
		
		Select @Strsql = 'Update #Comparisonoutput Set CN=ISNULL(T2.CN,0)'
		Select @Strsql = @Strsql + ' From ('
		Select @Strsql = @Strsql + ' Select T.startdate,T.enddate,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '
		Select @Strsql = @Strsql + ' From ShiftProductionDetails inner join Machineinformation M on M.machineid= Shiftproductiondetails.Machineid
									 cross join (select startdate,enddate from #Comparisonoutput)T '
		Select @Strsql = @Strsql + ' Where M.tpmtrakenabled=1
									 and pDate>=T.StartDate And pDate<= T.EndDate
									and pDate>= ''' + convert(nvarchar(20),@StartDate,120)+ '''  And pDate<= ''' + convert(nvarchar(20),@endDate,120)+ ''''
		Select @Strsql = @Strsql+@StrShift --ER0344 added
		Select @Strsql = @Strsql + ' Group By T.startdate,T.enddate '
		Select @Strsql = @Strsql + ' )AS T2 inner join #Comparisonoutput on T2.startdate=#Comparisonoutput.startdate
									and T2.enddate=#Comparisonoutput.enddate '
		Print @Strsql
		Exec(@Strsql)
		
		If isnull(@shift,'') <> ''
		Begin
			Select @StrShift = ' And ( ShiftDownTimeDetails.Shift = N''' + @shift + ''')'
		End
		Select @Strsql = 'UPDATE #Comparisonoutput SET DownTime = IsNull(T2.DownTime,0)'
		Select @Strsql = @Strsql + ' From (select T.startdate,T.enddate,(Sum(DownTime))As DownTime'
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner join Machineinformation M on M.machineid= ShiftDownTimeDetails.Machineid
									 cross join (select startdate,enddate from #Comparisonoutput)T
									 where M.tpmtrakenabled=1 and dDate>=T.StartDate And dDate<= T.EndDate
									and dDate>= ''' + convert(nvarchar(20),@StartDate,120)+ '''  And dDate<= ''' + convert(nvarchar(20),@endDate,120)+ ''''
		Select @Strsql = @Strsql+@StrShift --ER0344 added
		Select @Strsql = @Strsql + ' Group By T.startdate,T.enddate'
		Select @Strsql = @Strsql + ' ) AS T2 inner join #Comparisonoutput on T2.startdate=#Comparisonoutput.startdate
									and T2.enddate=#Comparisonoutput.enddate '
		Print @Strsql
		Exec(@Strsql)	
		Select @Strsql = 'UPDATE #Comparisonoutput SET ManagementLoss =  isNull(T2.loss,0)'
		Select @Strsql = @Strsql + 'from (select T.startdate,T.enddate, sum(
		 CASE
		WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
		THEN isnull(ShiftDownTimeDetails.Threshold,0)
		ELSE ShiftDownTimeDetails.DownTime
		 END) AS LOSS '
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails inner join Machineinformation M on M.machineid= ShiftDownTimeDetails.Machineid
										 cross join (select startdate,enddate from #Comparisonoutput)T
where M.tpmtrakenabled=1 And ML_flag = 1
										 and dDate>=T.StartDate And dDate<= T.EndDate
									and dDate>= ''' + convert(nvarchar(20),@StartDate,120)+ '''  And dDate<= ''' + convert(nvarchar(20),@endDate,120)+ ''''
		Select @Strsql = @Strsql+@StrShift --ER0344 added till here
		Select @Strsql = @Strsql + ' Group By T.startdate,T.enddate'
		Select @Strsql = @Strsql + ' ) AS T2 inner join #Comparisonoutput on T2.startdate=#Comparisonoutput.startdate
									and T2.enddate=#Comparisonoutput.enddate'
		Print @Strsql
		Exec(@Strsql)	
		---mod 1 introduced with mod2 to neglect threshold ML from dtime
		UPDATE #Comparisonoutput SET DownTime=DownTime-ManagementLoss
		UPDATE #Comparisonoutput SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)
		Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0
		UPDATE #Comparisonoutput
		SET
			PEffy = (CN/UtilisedTime) ,
			AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))
		WHERE UtilisedTime <> 0
		UPDATE #Comparisonoutput
		SET
			OEffy = PEffy * AEffy * QEffy * 100,
			PEffy = PEffy * 100 ,
			AEffy = AEffy * 100,
			QEffy = QEffy * 100
		Insert into #Finaloutput(Pdate,Startdate,enddate,MachinewiseTarget,PrevyearOEE,AEffy,PEffy,QEffy,OEffy)
		select ltrim((right(convert(varchar,StartDate, 106), 8))),C.StartDate,C.EndDate,0,round(CO.Oeffy,2),round(C.AEffy,2),round(C.PEffy,2),Round(C.QEffy,2),Round(C.OEffy,2)
		from #Comparisonoutput C,#ConsolidatedOutput CO where 1=1
		update #Finaloutput set MachinewiseTarget = isnull(MachinewiseTarget,0) + isnull(T2.target,0)
		from
		(select avg(T1.target) as target from
		(select Machineid,max(oe) as target from efficiencytarget
		 --where startdate>=@startdate and enddate<=@enddate
		 where
		 datepart(yyyy,startdate) + '-' + datepart(mm,startdate) >=datepart(yyyy,@startdate) + '-' + datepart(mm,@startdate)
		 and datepart(yyyy,enddate) + '-' + datepart(mm,enddate)<=datepart(yyyy,@enddate) + '-' + datepart(mm,@enddate)
		 group by Machineid)T1)T2
		
		select Pdate,AEffy,PEffy,QEffy,OEffy,PrevyearOEE,MachinewiseTarget From #Finaloutput order by startdate,enddate
	END
	If @Format='Format5'
	Begin
				
		select P.Machineid,Downid,downtime from #DownDetails D inner join #PlantMachineInfo P on D.Machineid=P.Machineid
		order by P.Machineid asc,downtime desc
	ENd
END
