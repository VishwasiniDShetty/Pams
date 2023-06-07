/****** Object:  Procedure [dbo].[S_SetAutoDataProductionDown]    Committed by VersionSQL https://www.versionsql.com ******/

/*************************************************************************************************
Changed for marks 20-nov-2006
Changed BY Sangeeta Kallur ON 19-July-2007 FOR DR0012,DR0010
Changed BY Sangeeta Kallur ON 20-July-2007 FOR ER0024
		[Adding loadunload of a production record whose previous record is NO_DATA]
Changed BY Sangeeta Kallur ON 21-July-2007 FOR ER0026
	[No support for @SplitPalletRecord = 'y' and @SupportsICDnDowns = 'y'
	Enabling -> @SplitPalletRecord = 'y' and @SupportsICDnDowns = 'n']
Changed BY Sangeeta Kallur ON 23-July-2007 FOR ER0027
	To put time stamp and datastring in table called "SmartDataStrings"
Changed By Sangeeta Kallur ON 07-Aug-2007
	To Make SmartdataStrings insertion as optional and to COMMIT the insertion after that.
	To Make Error_Handler_Type2 for TYPE2 record.
Changed By Sangeeta Kallur ON 13-Aug-2007 : To reject out of sequence records
	 and to change the downcode In Cycle Down from 'UNKNOWN' to 'McTI'
Changed By Sangeeta Kallur ON 21-Aug-2007 : DR0041
	Production record should not split to 'McTI' when machiningtime threshold is zero.
Changed by SSK : 29/08/07 : To increase the performance of procedure.Performance hit was because of
Changed by SSK : 06/Sep/07 : DR0046 : Added new variable StdLU(CycleTime-MachiningTime) and using this to put NO_Data,where earlier we are using LUThreshold
	
Procedure altered by SSK :ER0094: 03/Nov/07 : To include Spindle ON/OFF and Power ON/OFF events
Procedure altered by SSK :ER0101: 11/Dec/07 : Down record:Insert NO_DATA if gap > LU Threshold
Procedure changed by Shilpa : 24-Dec-07 : Aviod overlapping records.
Procedure altered by Shilpa :29-may-08:DR0109:Commented charindex check for company default.
Check for company_default when operator_grouping setting is 'y' was not happening.
Procedure alterd by Shilpa:DR0117, to check whether actual time gap is greater than Std LU.
:ER0140,introduced setting splitpalletrecord='y' and supportsicdndowns='u' where we insert a down record
with downcode 'Unknown' if Cycletime exceeds Machiningtimethreshold.
ALtered proc for setting splitpalletrecord='y' and supportsicdndowns='n' where we insert a MCTi record
for each pallet record if Cycletime exceeds Machiningtimethreshold.
Dr0111:consider operatorgrouping column='' as 'n'
ER0150:Added one more record type-16 to intrpret binary signals from HMI
mod 1:- DR0180, by Mrudula M. Rao om 02-apr-2009.
	1) Put 42 datatype records as 42( not as down record with datatype 2 ) in autodata.
mod 2:- DR0178 by Mrudula M. Rao on 26-Mar-2009.
	Exsistence of out of sequence records resulting in -ve utilised time.
	We used to compare incoming records endtime with the last processed records end time.
	If incoming records end time is less than the last processed records endtime then incoming record is out of  sequence record.
	We were not checking for incoming records starttime less than last processed records endtime. This resulted in insertion of out of sequence records in autodata thus resulting in negative utilised time.
	Check if Incoming records starttime is less than last processed records end time .
	If incoming records starttime is less than lase processed records end time then it is out of sequence record.
	The above check holds good for datatype 2,42 and 62
	Data arrival pattern was like this
	 |-----| |-------| |------|
	|------------------------------| (42)
	                           |------| (1)
**************************************************************************************************/
--S_SetAutoDataProductionDown 'START-16-3-101-20081012-090500-END-','172.36.0.206','','2'
CREATE           Procedure [dbo].[S_SetAutoDataProductionDown]
(	@datastring varchar(4000),
	@mcIPAdd nvarchar(50)='',
	@OutputPara int output,
	@LogicalPortNo Smallint=0
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @Error AS int
	DECLARE @ctime As numeric(38,0)
	DECLARE @loadunload As  numeric(38,0)
	DECLARE @LUforPrNxtToNODATA As  numeric(38,0)--LoadUnload for Production Record which is next to NO_DATA
	DECLARE @stndloadunload As  numeric(38,0) -- LoadUnload Threshold
	DECLARE @machiningtime as  numeric(38,0)
	DECLARE @MachiningTimeThreshold as  numeric(38,0)
	DECLARE @OrgMachiningTimeThreshold as  numeric(38,0) --DR0041:SSK:21-Aug-07
	DECLARE @dtStartTime As DateTime
	DECLARE @dttmp As DateTime
	DECLARE @tp As nvarchar(10)
	DECLARE @TP_INT as int
	DECLARE @machine As nvarchar(10)
	DECLARE @component As nvarchar(10)
	DECLARE @operation As nvarchar(10)
	DECLARE @operator As nvarchar(50)
	DECLARE @startdate As nvarchar(12)
	DECLARE @starttime As nvarchar(12)
	DECLARE @enddate As nvarchar(12)
	DECLARE @endtime As nvarchar(12)
	DECLARE @ProgramID As nvarchar(10)
	DECLARE @PalletCount As int
	DECLARE @downcode As nvarchar(10)
	Declare @Comp_Down nvarchar(10)
	DECLARE @ndtime as Datetime
	DECLARE @sttime as datetime
	DECLARE @orgstring As varchar(4000)
	DECLARE @McInterfaceID As nvarchar(10)
	DECLARE @StdLU AS  numeric(38,0) -- CycleTime-MachiningTime
	DECLARE @dtStartDateTime as Datetime,@dtEndDateTime  as datetime, @strDownCode  as nvarchar(20)
	Declare @Sep as nvarchar(2)
	Declare @CompanyDefault nvarchar(10)
	
	SET @CompanyDefault = 'XYZ'
	--By SSK on 23/07/07 ::ER0027
	Create table #SD_OprGrp(Oper nvarchar(50))
	
	IF (SELECT TOP 1 ISNULL(TPMStrings_Y_N,'N') FROM SmartDataPortRefreshDefaults)='Y'
	BEGIN
		BEGIN TRANSACTION	
			Insert Into SmartDataStrings(DataString,InTime)
			Values(@datastring,getdate())
		COMMIT TRANSACTION
	END
	
	SET @orgstring = @datastring
	--eliminate START
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	--read datatype
	SET @tp = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	IF IsNumeric(@tp) = 0
	Begin
		RAISERROR ('Error-Record type is not in correct format[%s] - %s', 16, 1,@mcIPAdd,@orgstring)
		return -1;
	End
/**********************************************************************************************
Split Record type 1 and 2 string
Type 1--> START-1-MC-Comp-Opn-Opr-PalletCount-StDate-Sttime-NDDate-NDTime-Down1-Down2-END
Type 2--> START-2-MC-Comp-Opn-Opr-Down1-StDate-Sttime-NDDate-NDTime-END
Type 42--> START-42-MC-Comp-Opn-Opr-Down1-StDate-Sttime-NDDate-NDTime-END
Type 62--> START-62-MC-Comp-Opn-Opr-Down1-StDate-Sttime-NDDate-NDTime-END
**********************************************************************************************/
	set @tp_int = CAST(@tp as int)
If @tp_int = 1 OR @tp_int = 2 OR @tp_int = 42 OR @tp_int = 62 -- ER0094
BEGIN
	
	--machine
	SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	--Following condition added by Sangeeta Kallur on 19/07/07 :: DR0010
	SELECT @McInterfaceID=NULL;
	SELECT @McInterfaceID=ISNULL(InterfaceID,0) From MachineInformation where PortNo=@LogicalPortNo
	IF  (@LogicalPortNo<>0) AND (@machine <> @McInterfaceID)
	BEGIN
		RAISERROR ('Error-Machine InterfaceID is incorrect for this IP address[%s];Expected[%s];Actual[%s] - %s', 16, 1,@mcIPAdd,@McInterfaceID,@machine,@orgstring)
		return -1;
	END
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	--component
	SET @component = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	--operation
	SET @operation = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	--operator
	
	SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
Select @Sep=Groupseperator1 from smartdataportrefreshdefaults
if (select OperatorGrouping from smartdataportrefreshdefaults)='y'
Begin
If charindex(@Sep,@operator)>0	
Begin
	  If len(@operator)>=50
	  Begin
	    Raiserror('Error-Operatorid is exceeding 50 characters', 16, 1,@mcIPAdd,@McInterfaceID,@machine,@orgstring)
	    return -1
	  End
	  Insert into #SD_OprGrp Exec s_GetOprGroupId @operator
	  Select  @operator=oper from #SD_OprGrp
End
Else
Begin
		If NOT Exists (select interfaceid from employeeinformation where InterfaceID= @operator)
		 Begin
		   select  @CompanyDefault =  interfaceid from employeeinformation where Company_default = 1
		   SET @operator = @CompanyDefault
End
End
--S_SetAutoDataProductionDown 'start-1-1-1988-1-61-2-20080614-125500-20080614-132000-end','172.36.0.201','','1'
End
--down code
	If @tp_int = 2 or @tp_int = 42 or @tp_int = 62 -- ER0094
	Begin
		SET @downcode = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	  	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	End
	Else
	Begin		
	--Pallet Count/Component Count
		SET @PalletCount = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as int)
	  	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	End
	--startdate
	SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())     		
	--starttime
	SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	SET @starttime = dbo.f_GetTpmStrToTime(@starttime)     		
	--enddate
	SET @enddate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	SET @enddate = dbo.f_GetTpmStrToDate(@enddate,GetDate())     		
	--endtime
	SET @endtime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	SET @endtime = dbo.f_GetTpmStrToTime(@endtime)
	
	--validate date and time
	DECLARE @Now as nvarchar(30)
	SET @Now = DateName(year,getdate()) + '-' + DateName(month,getdate()) + '-' + DateName(day,getdate())
	If IsDate(@startdate) = 1 And IsDate(@starttime) = 1 And IsDate(@enddate) = 1 And IsDate(@endtime) = 1
	BEGIN
		If DateDiff(second , @startdate + ' ' + @starttime , @enddate + ' ' + @endtime) > 0
		BEGIN
			If DateDiff(day, @Now, @startdate) > 1 Or DateDiff(day, @Now,@enddate) > 1 Or DateDiff(day, @Now,@startdate) < -20 Or DateDiff(day, @Now, @enddate) < -20
			BEGIN
			 	RAISERROR ('Handling Dates- date is < 3Week or > 1 day-----> %s', 16,1, @orgstring)
				return -1;
	        	END	
		END
		ELSE
		BEGIN
			RAISERROR('Handling Dates--Starttime >= endtime %s ', 16,1, @orgstring)
			return -1;	
		END
	END
	ELSE
	BEGIN
		RaisError('Handling Dates---Date/time  is not in correct date/time format  %s', 16,1, @orgstring)
		return -1;
	END
	
	--Validate Machine-
	if not exists ( select machineid,InterfaceID from machineinformation where TPMTrakEnabled = 1 and InterfaceID = @machine)
	begin
		RAISERROR ( 'Machine-Interface ID is incorrect from Machine %s    : - %s',16,1,@mcIPAdd ,@orgstring)
		RETURN -1;
	end
	-- SSK :29/08/07 Starts here -----------------------------------------
	DECLARE @TmpSeq AS VarChar(50)
	SET @TmpSeq = NULL;
	-- validate dulpicate mc and sttime
	--select top 1 @TmpSeq = mc from Autodata where mc =@machine AND sttime = @startdate + ' ' + @starttime
	select top 1 @TmpSeq = machineid from Autodata_maxtime where machineid =@machine AND starttime = @startdate + ' ' + @starttime
	IF @@ROWCOUNT > 0
	begin
		RAISERROR ( 'SmartData-Duplicate Record Found From mc %s   :- %s',16,1,@mcIPAdd,@orgstring)
		RETURN -1;
	end
	SET @TmpSeq = NULL;
	--SELECT TOP 1 @TmpSeq=Mc from autodata where mc= @machine  and Ndtime > @startdate + ' ' + @starttime
	SELECT TOP 1 @TmpSeq=Machineid from autodata_maxtime where machineid= @machine  and Endtime > @startdate + ' ' + @starttime
	IF @@ROWCOUNT > 0
	BEGIN
		RAISERROR ('Sequence out of order for this IP address[%s]; - %s', 16, 1,@mcIPAdd,@orgstring)
		return -1;
	END
	-- SSK :29/08/07 Ends here -----------------------------------------
	--Inserts n down codes if any , to a temp table
	CREATE TABLE #SD_DownTime
	(
	   ProdDownCode  nvarchar(10),
	   DownStartDate  DateTime ,
	   DownEndDate  DateTime
	)
	
	DECLARE @ProdDownCodes nvarchar(10)
	DECLARE @Downstartdate nvarchar(15)
	DECLARE @Downstarttime nvarchar(10)
	DECLARE @Downenddate nvarchar(15)
	DECLARE @Downendtime  nvarchar(10)
	While @tp_int = 1 And CHARINDEX('END',@datastring) > 1
	BEGIN
		--down code
	    	SET @ProdDownCodes = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		
		--startdate
	    	SET @Downstartdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	  	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @Downstartdate = dbo.f_GetTpmStrToDate(@Downstartdate,GetDate())     		
		--starttime
		SET @Downstarttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @Downstarttime = dbo.f_GetTpmStrToTime(@Downstarttime)     		
	
	      	--enddate
		SET @Downenddate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @Downenddate = dbo.f_GetTpmStrToDate(@Downenddate,GetDate())     		
	
	   	--endtime
		SET @Downendtime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @Downendtime = dbo.f_GetTpmStrToTime(@Downendtime)
	
	
	        If (@ProdDownCodes <> '0'OR @ProdDownCodes <> '') And IsDate(@Downstartdate + ' ' + @Downstarttime) = 1 And IsDate(@Downenddate + ' ' + @Downendtime) = 1
		BEGIN
	            If DateDiff(second, @Downstartdate + ' ' + @Downstarttime, @Downenddate + ' ' + @Downendtime) > 0
		    BEGIN
	                    --insert into temp downtime table
			   INSERT INTO #SD_DownTime Values(@ProdDownCodes,@Downstartdate + ' ' + @Downstarttime, @Downenddate + ' ' + @Downendtime)
	            End
	        End
	 END --While
	--if (Select substring(Oper,charindex('\',Oper)+1,(len(Oper)-charindex('\',Oper)+1)) from #SD_OprGrp)=0
	--begin
	--DR109 by shilpa commented charindex part on 27-May-08
	--Dr0111 to check for operatorgrouping column for null
	--If (select OperatorGrouping from smartdataportrefreshdefaults) ='n' --and charindex(@Sep,@operator)=0
If (select OperatorGrouping from smartdataportrefreshdefaults) <>'y'
	Begin
		--Validate operator-Interface-ID
		
	  If NOT Exists (select interfaceid from employeeinformation where InterfaceID= @operator)
	   Begin
	     select  @CompanyDefault =  interfaceid from employeeinformation where Company_default = 1
	     SET @operator = @CompanyDefault
End
	End
--Validate the PalletCount variable for numeric and not zero
If @PalletCount <= 0
	SET @PalletCount = 1
If @PalletCount  > 1
	And DateDiff(second,@startdate + ' ' + @starttime, @enddate + ' ' + @endtime) < @PalletCount
SET @PalletCount = 1
END
/*****************************************************************************************
	Type 1 Record
	Insert production record
	
*****************************************************************************************/
If @tp_int = 1
BEGIN
		SET @ndtime = NULL;
		SET @loadunload = NULL;
		SET @LUforPrNxtToNODATA=NULL;--::ER0024
	        --Select end time of last record for that machine from database
--select @ndtime = (select top 1 ndtime from autodata where mc= @machine  and ndtime <= @startdate + ' ' + @starttime order by id desc)
select @ndtime=(select endtime from autodata_maxtime where machineid=@machine)	
	        --Count Loadunload  time for recent record comming from machine
SET @loadunload = DateDiff(second, @ndtime, @startdate + ' ' + @starttime)
		
		SET @stndloadunload = 600
		set @machiningtime  = 0.0
		SET @MachiningTimeThreshold = 0.0--600.0 :: DR0012
		SET @OrgMachiningTimeThreshold=0.0 --::DR0041
		SET @StdLU=0.0
	        -- Count standard loadunload time for that component
	        --select @stndloadunload = loadunload from componentoperationpricing inner join componentinformation on componentoperationpricing.componentid=componentinformation.componentid where componentinformation.interfaceid=@component and componentoperationpricing.interfaceid=@operation
		
		select @stndloadunload = loadunload,@StdLU=ISNULL((CycleTime-MachiningTime),0),@machiningtime = isnull(machiningtime,0)* @PalletCount,
		@OrgMachiningTimeThreshold=ISNULL(MachiningTimeThreshold,0),
		@MachiningTimeThreshold = (isnull(machiningtime,0) * @PalletCount * isnull(MachiningTimeThreshold,0)/100) + isnull(machiningtime,0)* @PalletCount + 60
		from componentoperationpricing inner join componentinformation on componentoperationpricing.componentid=componentinformation.componentid where componentinformation.interfaceid=@component and componentoperationpricing.interfaceid=@operation
	    	
		If IsNumeric(@stndloadunload) = 0
	 	SET @stndloadunload = 600.0
		If IsNumeric(@MachiningTimeThreshold)=0
		SET @MachiningTimeThreshold = 0.0
		If IsNumeric(@OrgMachiningTimeThreshold)=0
		SET @OrgMachiningTimeThreshold = 0.0
		--Following lines are commented by SSK on 20/July/07 :: DR0012
		--If IsNumeric(@MachiningTimeThreshold) = 0
	 	--SET @MachiningTimeThreshold = 600.0
			
		if (isnumeric(@loadunload)= 0) AND (@starttime<>'00:00:00') AND (DATEDIFF(s,@startdate + ' 00:00:00',@startdate + ' ' +  @starttime)>600)
		Begin
			
		       --if it is first record in database,insert No_DATA Record
		       	SET @loadunload = 0
			SET @LUforPrNxtToNODATA=@StdLU --SSK ::ER0024 :::: DR0046
			
			BEGIN TRANSACTION
			--SSK on 21/07/07 :: DR0010 :: :: DR0046
		      	insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
	(2,@machine ,@component ,@operation ,@operator ,'NO_DATA',@startdate ,@startdate + ' 00:00:00',@startdate,
			DATEADD(ss,-@StdLU,@startdate + ' ' +  @starttime) ,0, (DateDiff(s, @startdate + ' 00:00:00', @startdate + ' ' + @starttime)-@StdLU) ,@startdate +  ' 00:00:00')
			
			SET @Error = @@ERROR
			IF @Error <> 0 GOTO ERROR_HANDLER
	    	end
		
		-- if actual Loadunload time is greater then Standard Loadunload time, insert NO_DATA record
		/*Changed by SSK on 20/07/07 ::ER0024
			 To add loadunload for a production record whose previous record is NO_DATA.
			Shifting ndtime of NO_DATA to decrement it by @stndloadunload
		*/
		--Introduced and condition to check whether actual time gap is greater than Std LU.		
		If @loadunload > @stndloadunload and (@loadunload-@StdLU)>0           --DR0117
		 Begin
		       BEGIN TRANSACTION
		       insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
				(2,@machine ,@component ,@operation ,@operator ,'NO_DATA',
			           DateName(year,@ndtime)+ '-' +  DateName(month,@ndtime)+ '-' + DateName(day,@ndtime) ,
		        	   @ndtime ,@startdate,DATEADD(ss,-@StdLU,@startdate +  ' ' + @starttime),0,(@loadunload-@StdLU) ,@ndtime ) --DR0046
			SET @Error = @@ERROR
			IF @Error <> 0 GOTO ERROR_HANDLER
			SET @loadunload =0
			SET @LUforPrNxtToNODATA=@StdLU--SSK ::ER0024 :: DR0046
		 End
------------------------------------------------------------------------------------------------------------------
		DECLARE @SplitPalletRecord as nvarchar(1)
		DECLARE @SupportsICDnDowns as nvarchar(1)
		DECLARE @Cycle As numeric(38,0)
		Declare @ICDinCycle as numeric(38,0)
		DECLARE @TotalDown As numeric(38,0)
		SELECT  @SplitPalletRecord = SplitPalletRecord,@SupportsICDnDowns= SupportsICDnDowns FROM SmartdataPortRefreshDefaults
		IF @SplitPalletRecord = 'y' and @SupportsICDnDowns = 'y'
		BEGIN
			IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
			RAISERROR ('We does not suppot the Split Pallet Record = "y" and Supports ICD n Downs = "y" (Table-"SmartdataPortRefreshDefaults")-----> %s', 16,1, @orgstring)
			return -1;
		END
/************************************** ER0026 :: SSK :Commented following code and introduced above message ****
		--Current solution which splits records and allows for ICDs to be captured
		begin
			SET @sttime = @startdate + ' '  + @starttime
			SET @ndtime = @enddate + ' ' + @endtime
		
			--Calculate total down within cycle
			SET @TotalDown = 0
			SELECT @TotalDown = ISNULL(SUM(DateDiff(second,DownStartDate,DownEndDate)),0) FROM #SD_DownTime
		        --INSERT n DOWN RECORDS if any
			If @TotalDown > 0
			BEGIN
				DECLARE SD_CUR CURSOR FOR SELECT  ProdDownCode,DownStartDate,DownEndDate FROM #SD_DownTime
				OPEN SD_CUR
				FETCH NEXT FROM SD_CUR INTO @downcode,@dtStartDateTime, @dtEndDateTime
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @loadunload = DATEDiff(second,@dtStartDateTime,@dtEndDateTime)
					-- Validate DownCode
					SET @Comp_Down = 'UNKNOWN'
					IF NOT Exists (select  interfaceid from dbo.downcodeinformation where InterfaceID= @downcode)
						SET @downcode = @Comp_Down
				        insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime)
						values (2, @machine , @component , @operation , @operator , @downcode ,DateName(year,@dtStartDateTime)+ '-' +DateName(month,@dtStartDateTime)+ '-' + DateName(day,@dtStartDateTime),@dtStartDateTime,DateName(year,@dtEndDateTime)+ '-' +DateName(month,@dtEndDateTime)+ '-' + DateName(day,@dtEndDateTime),@dtEndDateTime,0, @loadunload ,@dtStartDateTime)
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER1
					FETCH NEXT FROM SD_CUR INTO @downcode,@dtStartDateTime, @dtEndDateTime
				End
				CLOSE SD_CUR
				DEALLOCATE SD_CUR
				DROP TABLE #SD_DownTime
			END
			-- Calculate Actual cycle time
			DECLARE @DownTimePerCycle As numeric(38,0)
			SET @DownTimePerCycle = @TotalDown / @PalletCount
			Declare @Increment As Integer
			
		        If Datediff(second,@sttime,@ndtime) > 0
		        BEGIN
			        -- Count Cycle time ( Difference between start time and end time )
				SET @Cycle = DateDiff(second, @sttime, @ndtime)
			        --count incremental time for each component and round the fractional part of seconds e.g.-- 6.6 sec = 7 sec
			        SET @Increment = @Cycle / @PalletCount
			        --Loop through 1 to Pallet count(Number of Component in a Pallet) and insert production record
			        Declare @i As Integer
				SET @i = 1
				SET @loadunload=@LUforPrNxtToNODATA/@PalletCount --By SSK ER0024
				WHILE @i <= @Cycle - (@PalletCount * @Increment)
				BEGIN
					SET @dtStartTime = @sttime
			           	SET @ndtime = DateAdd(second, @Increment + 1, @sttime)
			           	
					insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values 						(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime)-@DownTimePerCycle,@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1)
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER
					SET @sttime = @ndtime
			          	--SET @loadunload = 0 ' By SSK ER0024
			       		SET @i = @i + 1
				END
				SET @i = @Cycle - (@PalletCount * @Increment) + 1
				WHILE @i <=  @PalletCount
				BEGIN
					SET @dtStartTime = @sttime
			           	SET @ndtime = DateAdd(s, @Increment, @sttime)
			
			           	insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime)-@DownTimePerCycle,@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1)
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER
			     		SET @sttime = @ndtime
			          	--SET @loadunload = 0 'By SSK ER0024
			       		SET @i = @i + 1
				END
			END
**********************************************************************************/
		
------------------------------------------------------------------------------------------------------------------------------------
		IF @SplitPalletRecord = 'n' and @SupportsICDnDowns = 'n'
	----Marks changes :: insert ONE ICD based on machining threshold
		begin
		
			SET @sttime = @startdate + ' '  + @starttime
			SET @ndtime = @enddate + ' ' + @endtime
			
			IF ISNUMERIC(@LUforPrNxtToNODATA)=1 --by SSK ::ER0024
			SET @loadunload=@LUforPrNxtToNODATA
			--  Following Condition added by SSK :: (@MachiningTimeThreshold>60) :: DR0012
			If  (DateDiff(second, @sttime, @ndtime) > @MachiningTimeThreshold) and (@MachiningTimeThreshold>60) AND ( @OrgMachiningTimeThreshold > 0.0)--DR0041
			begin
			           --INSERT PRODUCTION RECORD
			           insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,@MachiningTime,@loadunload ,DateAdd(second,-@loadunload,@sttime),@PalletCount)
				     SET @Error = @@ERROR
				     IF @Error <> 0 GOTO ERROR_HANDLER
			            --Insert In Cycle Down Record
			            --Following IF Condition is introduced by SSK on 19-Jul-07 ::DR0012
				    If @MachiningTime>0
				    BEGIN
					    set @sttime = DateAdd(second,@MachiningTime,@sttime)
						set @ndtime = Dateadd(second,-1,@ndtime)
					    insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime)
					    values (2, @machine , @component , @operation , @operator , 'McTI' ,DateName(year,@sttime)+ '-' +DateName(month,@sttime)+ '-' + DateName(day,@sttime),@sttime,DateName(year,@ndtime)+ '-' +DateName(month,@ndtime)+ '-' + DateName(day,@ndtime),@ndtime,0, DateDiff(second, @sttime, @ndtime) ,@sttime)
				    END
				    SET @Error = @@ERROR
				    IF @Error <> 0 GOTO ERROR_HANDLER
			end
			Else
			Begin
			            --INSET PRODUCTION RECORD
			            insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime, DateDiff(second, @sttime, @ndtime),@loadunload ,DateAdd(second,-@loadunload,@sttime),@PalletCount)
				     SET @Error = @@ERROR
				     IF @Error <> 0 GOTO ERROR_HANDLER
			End
		END
------------------------------------------------------------------------------------------------------------------
		--split the pallet but record only one 'Unknown' down outside of the cycle
		-- |-----------------------------------------| -- original cycle as it happened
		-- |----P--||----P---||-----P----||----D-----| -- inserts into autodata
		
		IF @SplitPalletRecord = 'y' and @SupportsICDnDowns = 'u'
		Begin
			SET @sttime = @startdate + ' '  + @starttime
			SET @ndtime = @enddate + ' ' + @endtime
						
			Declare @Increment As Integer
			
			IF ISNUMERIC(@LUforPrNxtToNODATA)=1
			SET @loadunload=@LUforPrNxtToNODATA
		        If Datediff(second,@sttime,@ndtime) > 0
		        BEGIN
				  If  (DateDiff(second, @sttime, @ndtime) > @MachiningTimeThreshold) and (@MachiningTimeThreshold>60) AND ( @OrgMachiningTimeThreshold > 0.0)
				  Begin
					-- Count Cycle time ( Difference between start time and end time )
					SET @Cycle = DateDiff(second, @sttime, @ndtime)
					SET @ICDinCycle = @Cycle- @MachiningTime
			        --count incremental time for each component and round the fractional part of seconds e.g.-- 6.6 sec = 7 sec
			        SET @Increment = @MachiningTime / @PalletCount
			        --Loop through 1 to Pallet count(Number of Component in a Pallet) and insert production record
					--with actual cutting time equal to std Cutting time
			        Declare @i As Integer
					SET @i = 1
				
					WHILE @i <=  @PalletCount
					 BEGIN
						SET @dtStartTime = @sttime
						SET @ndtime = DateAdd(s, @Increment, @sttime)
				
			           		insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
							(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1)
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER
			     			SET @sttime = @ndtime
			          		SET @loadunload = 0
			       			SET @i = @i + 1
					  END--while
					
					SET @sttime = @startdate + ' '  + @starttime
					SET @ndtime = @enddate + ' ' + @endtime
					If  (DateDiff(second, @sttime, @ndtime)) > @MachiningTime
					  begin
						
						set @sttime = DateAdd(second,@MachiningTime,@sttime)
						insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
						(2,@machine ,@component ,@operation ,@operator ,'UNKNOWN',Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,0,@ICDinCycle ,@sttime)
					  End	
				END--if
			  Else	
	            Begin
				SET @sttime = @startdate + ' '  + @starttime
				SET @ndtime = @enddate + ' ' + @endtime
				IF ISNUMERIC(@LUforPrNxtToNODATA)=1
				SET @loadunload=@LUforPrNxtToNODATA
		
				SET @Cycle = DateDiff(second, @sttime, @ndtime)
			    SET @Increment = @Cycle / @PalletCount
			
				SET @i = 1
				--For uneven division of cycletime by pallet.
				WHILE @i <= @Cycle - (@PalletCount * @Increment)
				BEGIN
					SET @dtStartTime = @sttime
			           	SET @ndtime = DateAdd(second, @Increment + 1, @sttime)
			           	
					insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1)
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER
					SET @sttime = @ndtime
			          	SET @loadunload = 0
			       		SET @i = @i + 1
				END--while1
				SET @i = @Cycle - (@PalletCount * @Increment) + 1
				WHILE @i <=  @PalletCount
				BEGIN
					SET @dtStartTime = @sttime
			           	SET @ndtime = DateAdd(s, @Increment, @sttime)
			
			           	insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1) --dr0119
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER
			     		SET @sttime = @ndtime
			          	SET @loadunload = 0
			       		SET @i = @i + 1
				END--while2
			   End--else
			  End--if
		End--if
---------------------------------------------------------------------------------------------------------------------------------------------
		IF @SplitPalletRecord = 'n' and @SupportsICDnDowns = 'y'
	----Marks changes :: insert ONE ICD based on machining threshold and put n down
		begin
			--Calculate total down within cycle
			SET @TotalDown = 0
			SELECT @TotalDown = ISNULL(SUM(DateDiff(second,DownStartDate,DownEndDate)),0) FROM #SD_DownTime
			--INSERT n DOWN RECORDS if any
			If @TotalDown > 0
			BEGIN
				DECLARE SD_CUR CURSOR FOR SELECT  ProdDownCode,DownStartDate,DownEndDate FROM #SD_DownTime
				OPEN SD_CUR
				FETCH NEXT FROM SD_CUR INTO @downcode,@dtStartDateTime, @dtEndDateTime
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @loadunload = DATEDiff(second,@dtStartDateTime,@dtEndDateTime)
					-- Validate DownCode
					SET @Comp_Down = 'UNKNOWN'
					IF NOT Exists (select  interfaceid from dbo.downcodeinformation where InterfaceID= @downcode)
						SET @downcode = @Comp_Down
				        insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime)
						values (2, @machine , @component , @operation , @operator , @downcode ,DateName(year,@dtStartDateTime)+ '-' +DateName(month,@dtStartDateTime)+ '-' + DateName(day,@dtStartDateTime),@dtStartDateTime,DateName(year,@dtEndDateTime)+ '-' +DateName(month,@dtEndDateTime)+ '-' + DateName(day,@dtEndDateTime),@dtEndDateTime,0, @loadunload ,@dtStartDateTime)
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER1
					FETCH NEXT FROM SD_CUR INTO @downcode,@dtStartDateTime, @dtEndDateTime
				End
				CLOSE SD_CUR
				DEALLOCATE SD_CUR
				DROP TABLE #SD_DownTime
			END
			IF ISNUMERIC(@LUforPrNxtToNODATA)=1 --by SSK ::ER0024
			SET @loadunload=@LUforPrNxtToNODATA
			SET @sttime = @startdate + ' '  + @starttime
			SET @ndtime = @enddate + ' ' + @endtime
			 --Insert In production Cycle Record
	         insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime, DateDiff(second, @sttime, @ndtime) - @TotalDown ,@loadunload ,DateAdd(second,-@loadunload,@sttime),@PalletCount)
					
			SET @Error = @@ERROR
			IF @Error <> 0 GOTO ERROR_HANDLER
			
		END
---------------------------------------------------------------------------------------------------------------
--new one
	--split the pallet and insert MCTI record if cycletime exceeds machiningtimethreshold
	-- |-----------------------------------------| -- original cycle as it happened
	-- |---P---||---P----||---P-----||----P-----| -- inserts into autodata
	--     |-m-|     |-m-|      |-m-|       |-m-|--insert mcti record if cycle time exceeds machiningtimethreshold
		IF @SplitPalletRecord = 'y' and @SupportsICDnDowns = 'n'
		BEGIN
			set @sttime=@startdate + ' ' + @starttime
			set @ndtime=@enddate + ' ' + @endtime
			
			--Declare @Increment as integer
			--Declare @i as integer
			
			If isnumeric(@LUforPrNxtToNoDATA)=1
			Set @loadunload=@LUforPrNxtToNoDATA	
		
			If Datediff(second,@sttime,@ndtime)>0
			 Begin
				If (DateDiff(second, @sttime, @ndtime) > @MachiningTimeThreshold) and (@MachiningTimeThreshold>60) AND ( @OrgMachiningTimeThreshold > 0.0)
				  begin
						set @MachiningTime= @MachiningTime/@Palletcount
						Set @Cycle=Datediff(second,@sttime,@ndtime)
						Set @Increment=@Cycle/@Palletcount
						Set @i=1
						WHILE @i <= @Cycle - (@PalletCount * @Increment)
						BEGIN
							SET @dtStartTime = @sttime
							SET @ndtime = DateAdd(second, @Increment + 1, @sttime)
									
							insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
							(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,@MachiningTime,@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1)
						   					
							SET @Error = @@ERROR
							IF @Error <> 0 GOTO ERROR_HANDLER
					
							If @MachiningTime>0
							BEGIN
								set @sttime = DateAdd(second,@MachiningTime,@sttime)
								set @sttime = DateAdd(second,-1,@sttime)
								set @ndtime = Dateadd(second,-1,@ndtime)
								insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime)
								values (2, @machine , @component , @operation , @operator , 'McTI' ,DateName(year,@sttime)+ '-' +DateName(month,@sttime)+ '-' + DateName(day,@sttime),@sttime,DateName(year,@ndtime)+ '-' +DateName(month,@ndtime)+ '-' + DateName(day,@ndtime),@ndtime,0, DateDiff(second, @sttime, @ndtime) ,@sttime)
							END
											
							SET @Error = @@ERROR
							IF @Error <> 0 GOTO ERROR_HANDLER
							 SET @sttime = dateadd(second,1,@ndtime)
							 SET @loadunload = 0
			       			 SET @i = @i + 1
						  END--WHILE
				
						SET @i = @Cycle - (@PalletCount * @Increment) + 1
						WHILE @i <=  @PalletCount
						BEGIN
							SET @dtStartTime = @sttime
							SET @ndtime = DateAdd(s, @Increment, @sttime)
							
								insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
								(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,@MachiningTime,@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1)
						 		SET @Error = @@ERROR
								IF @Error <> 0 GOTO ERROR_HANDLER
								
								If @MachiningTime>0
								 BEGIN
								 set @sttime = DateAdd(second,@MachiningTime,@sttime)
								 set @ndtime = Dateadd(second,-1,@ndtime)
								 set @sttime = DateAdd(second,-1,@sttime)
								 insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime)
								 values (2, @machine , @component , @operation , @operator , 'McTI' ,DateName(year,@sttime)+ '-' +DateName(month,@sttime)+ '-' + DateName(day,@sttime),@sttime,DateName(year,@ndtime)+ '-' +DateName(month,@ndtime)+ '-' + DateName(day,@ndtime),@ndtime,0, DateDiff(second, @sttime, @ndtime) ,@sttime)
								 END	
							SET @sttime = dateadd(second,1,@ndtime)
			          		SET @loadunload = 0
			       			SET @i = @i + 1	
						END--while2			
				    End--if
				 Else
				  Begin
								
					SET @Cycle = DateDiff(second, @sttime, @ndtime)
					SET @Increment = @Cycle / @PalletCount
				
					SET @i = 1
					--For uneven division of cycletime by pallet.
					WHILE @i <= @Cycle - (@PalletCount * @Increment)
					BEGIN
						SET @dtStartTime = @sttime
			           	SET @ndtime = DateAdd(second, @Increment + 1, @sttime)
				           	
						insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
							(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1)
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER
						SET @sttime = @ndtime
			          		SET @loadunload = 0
			       			SET @i = @i + 1
					END--while1
					SET @i = @Cycle - (@PalletCount * @Increment) + 1
					WHILE @i <=  @PalletCount
					BEGIN
						SET @dtStartTime = @sttime
			           		SET @ndtime = DateAdd(s, @Increment, @sttime)
				
			           		insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
							(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1)----dr0119
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER
			     			SET @sttime = @ndtime
			          		SET @loadunload = 0
			       			SET @i = @i + 1
					END--while2
				   End--else
		  End--if
End--IF
---------------------------------------------------------------------------------------------------------------------------------------------
--[S_SetAutoDataProductionDown_FOR5.1.4.5] 'start-1-2-9999-9999-9999-2-20080613-100000-20080613-110000-end','172.36.0.201','','1'
--Commented by Shilpa for ER0140
--		IF @SplitPalletRecord = 'y' and @SupportsICDnDowns = 'n'
--		BEGIN
			/* ER0026 :: SSK:Commented below message & added logic for this condition**************************************************************
			IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
			RAISERROR ('We does not suppot the Split Pallet Record = "y" and Supports ICD n Downs = "n" (Table-"SmartdataPortRefreshDefaults")-----> %s', 16,1, @orgstring)
			return -1;
			****************************************************************/
		/*	SET @sttime = @startdate + ' '  + @starttime
			SET @ndtime = @enddate + ' ' + @endtime
		
			--Calculate total down within cycle
			SET @TotalDown = 0
			SELECT @TotalDown = ISNULL(SUM(DateDiff(second,DownStartDate,DownEndDate)),0) FROM #SD_DownTime
		
			-- Calculate Actual cycle time
			DECLARE @DownTimePerCycle As numeric(38,0)
			SET @DownTimePerCycle = @TotalDown / @PalletCount
			Declare @Increment As Integer
			
			IF ISNUMERIC(@LUforPrNxtToNODATA)=1 --by SSK ::ER0024
			SET @loadunload=@LUforPrNxtToNODATA
		        If Datediff(second,@sttime,@ndtime) > 0
		        BEGIN
			        -- Count Cycle time ( Difference between start time and end time )
				SET @Cycle = DateDiff(second, @sttime, @ndtime)
			        --count incremental time for each component and round the fractional part of seconds e.g.-- 6.6 sec = 7 sec
			        SET @Increment = @Cycle / @PalletCount
			        --Loop through 1 to Pallet count(Number of Component in a Pallet) and insert production record
			        Declare @i As Integer
				SET @i = 1
				
				WHILE @i <= @Cycle - (@PalletCount * @Increment)
				BEGIN

					SET @dtStartTime = @sttime
			           	SET @ndtime = DateAdd(second, @Increment + 1, @sttime)
			           	
					insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime)-@DownTimePerCycle,@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1)
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER
					SET @sttime = @ndtime
			          	SET @loadunload = 0
			       		SET @i = @i + 1
				END
				SET @i = @Cycle - (@PalletCount * @Increment) + 1
				WHILE @i <=  @PalletCount
				BEGIN
					SET @dtStartTime = @sttime
			           	SET @ndtime = DateAdd(s, @Increment, @sttime)
			
			           	insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						(@tp_int,@machine ,@component ,@operation ,@operator ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime)-@DownTimePerCycle,@loadunload ,DateAdd(second,-@loadunload,@dtStartTime),1)
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER
			     		SET @sttime = @ndtime
			          	SET @loadunload = 0
			       		SET @i = @i + 1
				END
			END
	        END  */
-----------------------------------------------------------------------------------------------------------------------------------------------
	while @@TRANCOUNT <> 0
		COMMIT TRANSACTION
	return 1;
	
ERROR_HANDLER:
	IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
	RETURN @Error
ERROR_HANDLER1:
	CLOSE SD_CUR
	DEALLOCATE SD_CUR
	DROP TABLE #SD_DownTime
	IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
	RETURN @Error
END --for Data Type 1 record
/*****************************************************************************************
	Type 2 Record
	Insert DOWN record
*****************************************************************************************/
If @tp_int = 2 	
BEGIN
	--START Validate Downcodes
	SET @Comp_Down = 'UNKNOWN'
	IF NOT Exists (select  interfaceid from dbo.downcodeinformation where InterfaceID= @downcode)
		SET @downcode = @Comp_Down
	--End Validate Downcodes
	SET @ndtime = NULL;
	--select @ndtime = (select top 1 ndtime from autodata where mc=@machine and ndtime<= @startdate +  ' ' + @starttime order by id desc)
	select @ndtime=(select endtime from autodata_maxtime where machineid=@machine)	
	-- ER0101 : LU Threshold : Starts
	select @stndloadunload = ISNULL(loadunload,0)
	from componentoperationpricing inner join componentinformation on componentoperationpricing.componentid=componentinformation.componentid
	where componentinformation.interfaceid=@component and componentoperationpricing.interfaceid=@operation
If Isdate(@ndtime) = 1
	BEGIN
		BEGIN TRANSACTION	
	
		IF DateDiff(second, @ndtime, @startdate + ' ' + @starttime)> @stndloadunload
		BEGIN
		
		   SET @loadunload = DateDiff(second, @ndtime, @startdate + ' ' + @starttime)
		   insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
	           (@tp_int, @machine , @component , @operation , @operator ,'NO_DATA' , Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' + Datename(day,@ndtime),@ndtime ,@startdate , @startdate + ' ' + @starttime ,0, @loadunload ,@ndtime)
		
		   SET @loadunload = DateDiff(second,  @startdate + ' ' + @starttime,@enddate + ' ' + @endtime)
		   insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
	           (@tp_int, @machine , @component , @operation , @operator ,@downcode , Datename(year,@startdate) + '-' + Datename(month,@startdate) + '-' + Datename(day,@startdate),@startdate+' '+@starttime ,@enddate , @enddate + ' ' + @endtime ,0, @loadunload ,@startdate + ' ' + @starttime)
		
		END
		ELSE
		BEGIN
		   SET @loadunload = DateDiff(second, @ndtime, @enddate + ' ' + @endtime)
	   insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
	           (@tp_int, @machine , @component , @operation , @operator ,@downcode , Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' + Datename(day,@ndtime),@ndtime ,@enddate , @enddate + ' ' + @endtime ,0, @loadunload ,@ndtime)
		END
		
		SET @Error = @@ERROR
		IF @Error <> 0 GOTO ERROR_HANDLER_Type2
	END
-- ER0101 : LU Threshold : Ends
Else
	Begin
		BEGIN TRANSACTION
	    SET @loadunload = DateDiff(second, @startdate + ' ' + @starttime, @enddate + ' ' + @endtime)
	    insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
		    (@tp_int, @machine , @component ,  @operation , @operator , @downcode , @startdate , @startdate + ' ' +  @starttime , @enddate , @enddate +  ' '  +  @endtime ,0,  @loadunload , @startdate +  ' ' +  @starttime)
	SET @Error = @@ERROR
		IF @Error <> 0 GOTO ERROR_HANDLER_Type2
	End
	while @@TRANCOUNT <> 0
		COMMIT TRANSACTION
	return 2;
ERROR_HANDLER_Type2:
	IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
	RETURN @Error
END  --for type 2 record
/*****************************************************************************************
	Type 42 Record
	Insert In cycle or spindle DOWN record with same st and nd time as type 2 record
*****************************************************************************************/
	If @tp_int = 42 	--ER0094
	BEGIN
		--START Validate Downcodes
		SET @Comp_Down = 'UNKNOWN'
		IF NOT Exists (select  interfaceid from dbo.downcodeinformation where InterfaceID= @downcode)
			SET @downcode = @Comp_Down
		--End Validate Downcodes
	        SET @loadunload = DateDiff(second, @startdate + ' ' + @starttime, @enddate + ' ' + @endtime)
	        insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
			---mod 1 :- Insert datatype 42 record as type 42 only instead of datatype 2 record
			---(2, @machine , @component ,  @operation , @operator , @downcode , @startdate , @startdate + ' ' +  @starttime , @enddate , @enddate +  ' '  +  @endtime ,0,  @loadunload , @startdate +  ' ' +  @starttime)
			(42, @machine , @component ,  @operation , @operator , @downcode , @startdate , @startdate + ' ' +  @starttime , @enddate , @enddate +  ' '  +  @endtime ,0,  @loadunload , @startdate +  ' ' +  @starttime)
			--mod 1
		return 42;
	 END  --for type 42 record
/*****************************************************************************************
	Type 62 Record
	Insert In cycle or POWER_ON_OFF DOWN record with same st and nd time as type 2 record
*****************************************************************************************/
	If @tp_int = 62 -- ER0094	
	BEGIN
		SET @downcode = 'POWER_OFF'
		--End Validate Downcodes
	        SET @loadunload = DateDiff(second, @startdate + ' ' + @starttime, @enddate + ' ' + @endtime)
	        inSert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
			(2, @machine , @component ,  @operation , @operator , @downcode , @startdate , @startdate + ' ' +  @starttime , @enddate , @enddate +  ' '  +  @endtime ,0,  @loadunload , @startdate +  ' ' +  @starttime)
		return 62;
	 END  --for type 62 record
/******************************************************************************
	Type 40, 41 Record
	START-DataType-MachineId-ToolDir-sDate-sTime-END-
SPINDLE ON/OFF
*******************************************************************************/
	If @tp_int = 40 or @tp_int = 41 -- ER0094
	BEGIN
		DECLARE @ToolDir_ int
		
	    	--machine
		SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		--ToolDir
	    	SET @ToolDir_ = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS INT)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		--startdate
		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())     		
		--starttime
		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)     		
		
	        If (IsDate(@startdate + ' ' + @starttime) = 1 )
		AND
Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @machine)
		        INSERT INTO AutodataDetails (Machine, RecordType, Starttime,DetailNumber)
			VALUES(
					@machine ,
					@tp_int,
					@startdate + ' ' + @starttime,
					@ToolDir_
			         )
		ELSE
		BEGIN
			RAISERROR ('Error inserting SPINDLE ON/OFF record for %s', 16, 1,@orgstring)
		   	RETURN @tp_int;
		END
		SET @Error = @@ERROR
		IF @Error <> 0
		BEGIN
		   RAISERROR ('Error inserting Spinddle record for %s', 16, 1,@orgstring)
		   RETURN @tp_int;
		END
	RETURN @tp_int;
	End
/******************************************************************************
	Type 60, 61 Record
	START-DataType-MachineId-Date-Time-END-
POWER ON/OFF
*******************************************************************************/
	If @tp_int = 60 or @tp_int = 61 -- ER0094
	BEGIN
		--machine
		SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	
		--startdate
		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())     		
		--starttime
		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)     		
		
	        If (IsDate(@startdate + ' ' + @starttime) = 1 )
		AND
Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @machine)
		        INSERT INTO AutodataDetails (Machine, RecordType, Starttime)
			VALUES(
					@machine ,
					@tp_int,
					@startdate + ' ' + @starttime					
			         )
		ELSE
		BEGIN
			RAISERROR ('Error inserting POWER_ON_OFF record for %s', 16, 1,@orgstring)
		   	RETURN @tp_int;
		END
		SET @Error = @@ERROR
		IF @Error <> 0
		BEGIN
		   RAISERROR ('Error inserting POWER_ON_OFF record for %s', 16, 1,@orgstring)
		   RETURN @tp_int;
		END
	RETURN @tp_int;
	End
/*****************************************************************************************
	Type 3 Record
	START-3-MC-ProgNo-END
	Program Transfer
******************************************************************************************/
	If @tp_int = 3
	BEGIN
		--MachineID
		SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		--ProgramID
	        SET @ProgramID = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		DECLARE @PortNO as int
		SET @PortNo = -1
		SELECT @PortNO = onlinemachinelist.portno FROM onlinemachinelist INNER JOIN machineinformation ON onlinemachinelist.machineid = machineinformation.machineid  WHERE machineinformation.InterfaceID = @machine
		IF @PortNo <> -1
		Begin
			INSERT INTO ProgramHistory(MachineID, ProgramID,PortNo) VALUES ( @machine ,@ProgramID , @PortNo)
		End
		SET @Error = @@ERROR
		IF @Error != 0
		BEGIN
		   RAISERROR ('Error-Error inserting Program Transfer record- %d', 16, 1,@orgstring)
		   RETURN -1;
		END
		SET @OutputPara = 3
	    return 3;
	 END
/******************************************************************************
	Type 4 Record
	START-DataType-ToolDir-MachineId-sDate-sTime-EDate-ETime-END-
SPINDLE ON/OFF
*******************************************************************************/
	If @tp_int = 4
	BEGIN
		DECLARE @ToolDir int
		--ToolDir
	    	SET @ToolDir = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS INT)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	    	--machine
		SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		--startdate
		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())     		
		--starttime
		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)     		
	--enddate
		SET @enddate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @enddate = dbo.f_GetTpmStrToDate(@enddate,GetDate())     		
	   	--endtime
		SET @endtime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @endtime = dbo.f_GetTpmStrToTime(@endtime)     		
	
	        If (IsDate(@startdate + ' ' + @starttime) = 1 And IsDate(@enddate + ' ' + @endtime) = 1)
		AND
Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @machine)
		        INSERT INTO AutodataDetails (Machine, RecordType, Starttime,Endtime,DetailNumber)
			VALUES(
					@machine ,
					@tp_int,
					@startdate + ' ' + @starttime,
					@enddate + ' ' + @endtime,
					@ToolDir
			         )
		SET @Error = @@ERROR
		IF @Error <> 0
		BEGIN
		   RAISERROR ('Error inserting Spinddle record for %s', 16, 1,@orgstring)
		   RETURN -1;
		END
	RETURN 4;
	End
/************************************************************************************************
	Type 5 Record
	Tool Change - START-DataType-ToolNo-MachineId-sDate-sTime-END-
***********************************************************************************************/
	If @tp_int = 5
	BEGIN
		DECLARE @ToolNo As Int
		--ToolNo
	    	SET @ToolNo = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	    	--machine
		SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		--startdate
		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())     		
		--starttime
		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)     		
		If IsDate(@startdate + ' ' + @starttime) = 1   AND Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @machine)
		BEGIN
	    		INSERT INTO AutodataDetails  (Machine, RecordType, Starttime, DetailNumber)
		        VALUES(
				@machine ,
				@tp_int ,
				@startdate + ' ' + @starttime,
				@ToolNo
			     )
			SET @Error = @@ERROR
			IF @Error <> 0
			begin
			   RAISERROR ('Error inserting Spinddle record for %s', 16, 1,@orgstring)
			   return -1;
			end
		END
		ELSE
		Begin
			RAISERROR ('Error in inserting Spinddle record(Date or machine id problem) for %s', 16, 1,@orgstring)
			Return -1;
		end
	    RETURN 5;
	End
/************************************************************************************************
	Type 6 Record --> Alarm Type
START-DataType-PMC-PALARMNo-PsDate-PsTime-END-
***********************************************************************************************/
If @tp_int = 6
	BEGIN
	    	DECLARE @AlarmNo nvarchar(100)
		DECLARE @AlarmNo_Dec numeric(38,2)
		
	    	--machine
	    	SET @machine = SUBSTRING(@datastring,2,CHARINDEX('-',@datastring) - 2)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		--AlarmNo
		SET @AlarmNo = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		--startdate
	    	SET @startdate = SUBSTRING(@datastring,2,CHARINDEX('-',@datastring) - 2)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())     		
		--starttime
		SET @starttime = SUBSTRING(@datastring,2,CHARINDEX('-',@datastring) - 2)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)     		
		-- SELECT  @machine,  @AlarmNo ,  @startdate, @starttime   	
	     If (IsDate(@startdate + ' ' + @starttime) = 1)
		AND
Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @machine)
		BEGIN
			WHILE CHARINDEX('P',@AlarmNo,1) >= 1
			BEGIN	print 'In While'
			 	if CHARINDEX('P',@AlarmNo,2) >= 1
				BEGIN print 'In If'
					SET @AlarmNo_Dec = CAST(SUBSTRING(@AlarmNo,2,CHARINDEX('P',@AlarmNo,2) - 2) as Numeric(38,2))
				  	SET @AlarmNo = SUBSTRING(@AlarmNo,CHARINDEX('P', @AlarmNo,2),LEN(@AlarmNo) - CHARINDEX('P', @AlarmNo,2)+ 1)
					INSERT INTO AutoDataAlarms (MachineID, AlarmNumber,Alarmtime,RecordType)
					    VALUES( @machine , @AlarmNo_Dec,@startdate + ' ' + @starttime, @tp_int)
				END
				else
				Begin
					SET @AlarmNo_Dec = CAST(SUBSTRING(@AlarmNo,2,LEN(@AlarmNo)-1) as Numeric(38,2))
					SET @AlarmNo = SUBSTRING(@AlarmNo,2,LEN(@AlarmNo)-1)
					INSERT INTO AutoDataAlarms (MachineID, AlarmNumber,Alarmtime,RecordType)
					  VALUES( @machine , @AlarmNo_Dec,@startdate + ' ' + @starttime, @tp_int)				
				End
			END
		END
		SET @Error = @@ERROR
		IF @Error <> 0
		BEGIN
		   RAISERROR ('Error inserting ALARM record for %s', 16, 1,@orgstring)
		   RETURN -1;
		END
RETURN 6;
	End
/************************************************************************************************
Added by Shilpa for Bosch
Type 16 Record --> Binary Signal which determines the machine events from HMI (For Bosch)
START-DataType-Machineid-EventValue-Date-Time-END-
***********************************************************************************************/
If @tp_int = 16
	BEGIN
	    	DECLARE @EventValue nvarchar(100)
		
	    	--machine
	    	SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		--Event Value
		SET @EventValue = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		--startdate
		
	    	SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())     		
		--starttime
		
		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)     		
	     If (IsDate(@startdate + ' ' + @starttime) = 1)
		AND Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @machine)
		BEGIN
		     If Not exists( Select * from autodataalarms where machineid=@machine and alarmnumber=@eventvalue
			and alarmtime=	@startdate + ' ' + @starttime)
			Begin
				--SET @EventValue = SUBSTRING(@EventValue,2,LEN(@EventValue)-1)
				INSERT INTO AutoDataAlarms (MachineID, AlarmNumber,Alarmtime,RecordType)
				VALUES( @machine , @EventValue,@startdate + ' ' + @starttime, @tp_int)
			End
		END
		
		SET @Error = @@ERROR
		--print @Error
	
		IF @Error <> 0
		BEGIN		
		   RAISERROR ('Error inserting Binary Signal record for %s', 16, 1,@orgstring)
		   RETURN -1;
		END
RETURN 16;
	End
END    -- for stored procedure
--&&&&&&&&&&&&&&&&&&&&for DNC Transfer &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
/*if @tp_int=9
Begin
		--MachineID
		SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		--ProgramID
	        SET @ProgramID = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		
		/*SET @PortNo = -1
		SELECT @PortNO = onlinemachinelist.portno FROM onlinemachinelist INNER JOIN machineinformation ON onlinemachinelist.machineid = machineinformation.machineid  WHERE machineinformation.InterfaceID = @machine
		IF @PortNo <> -1
		Begin
			INSERT INTO ProgramHistory(MachineID, ProgramID,PortNo) VALUES ( @machine ,@ProgramID , @PortNo)
		End
		SET @Error = @@ERROR
		IF @Error != 0
		BEGIN
		   RAISERROR ('Error-Error inserting Program Transfer record- %d', 16, 1,@orgstring)
		   RETURN -1;
		END*/
--	SET @OutputPara = 9
--    return 9;
--End*/
--&&&&&&&&&&&&&&&&&&&&&&&&& Till Here &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
----------------------------------
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
