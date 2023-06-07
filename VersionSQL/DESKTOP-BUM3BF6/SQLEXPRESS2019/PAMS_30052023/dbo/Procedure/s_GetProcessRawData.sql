/****** Object:  Procedure [dbo].[s_GetProcessRawData]    Committed by VersionSQL https://www.versionsql.com ******/

/****** Object:  StoredProcedure [dbo].[s_GetProcessRawData]    Script Date: 10/14/2010 14:58:58 ******/

/**************************************************************************************************
Select * from autodata order by id desc
Procedure created By Shilpa H.M On 16oct07 To Process the RawData records
Common Error Handlers are given for each  data type..
On error, insert the error in SmartData ErrorLog table and fetch the next record to process it.
Each error is given error no as mentioned in errorLog table.
Procedure altered by Shilpa on 6Nov08 to process spindle off/on records,events from hmi
DR0149:Altered to add company default,Proper check for sequence out of order records,Check for Loadunload
gap in Type 2 record
mod 1:-ER0159(3) by Mrudula on 02-jan-2009 . when SplitPalletRecord="N" in Smartdata port refresh defaults ,do not set pallet count equal to 1 if it is exceeding the cycle time .
mod 2:-DR0162 by Mrudula M. Rao on 10-feb-2009. Not putting company default operator if the incorrect operator  id is coming from the machine.
mod 3:- ER0162. By Mrudula M. Rao on 11-mar-2009.
		1)Change Smartdata procedure to handle optional stop and start string.
		2)For begin use datatype 70 and for end use datatype 71
		3)The string format is as good as spindle record. Hardcode the value for record type say 0
mod 4:-ER0176 By Mrudula M. Rao on 11-mar-2009.
	Do not select records with datatype 11 to process from rawdata.
mod 5:- DR0178 by Mrudula M. Rao on 26-Mar-2009.
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
	In brackets datatype of the incoming record.
mod 6:- DR0180, by Mrudula M. Rao om 02-apr-2009.
	1) Put 42 datatype records as 42( not as down record with datatype 2 ) in autodata.
mod 7:- By Mrudula on 17-apr-2009 for DR0182.
	1) Insert 42 type records in autodata_ICD .
	2) While inserting a production record if SpiltPalletRecord='N' Look for datatype 42 records in
	   Autodata_ICD table within starttime and endtime for the cycle.
	3) If any datatype 42 records found for the production cycle , deduct the sum of downtime from the
	   production time and insert the production record with same starttime and endtime.
	4) Once the production record is inserted , insert datatype 42 record as datatype 2 (down) record
	  in autodata.
	5) Do not insert Interpreted down records like MCTI and CYCTI for the
	   production cycle if 42 records are there.
mod 8:- By Mrudula M. Rao on 26-may-2008 for ER0101:Insert NO_DATA if gap > LU Threshold while inserting down record.
mod 9:- By Kusuma M.H on 01-Jun-2009 for ER0181:1)Qualify Machine with component and operation, to form unique combination of componentId,machineid and operation number.
mod 10:- ER0184(6).By Mrudula M. Rao on 05-Jun-2009.
	Insert workorder number from rawdata into autodata.
mod 11:- By Mrudula M. Rao on 30-jul-2009.Transaction count after EXECUTE indicates that a COMMIT or ROLLBACK TRANSACTION statement is missing.
	Previous count = 0, current count = 1.
Transaction hadling is not proper while processing 40,41,60,61,12 and 16 datatypes.
mod 12:- By Karthik G on 04-Aug-2009 for NR0058  To clear the old RawData records which are processed i.e.. where status in (1,15)
and clear data from SmartDataErrorLog leaving last 1000 records. Mod 13:- By Mrudula M. Rao for DR0198 on 05-aug-2009.Disable rawdata and smartdataerrorlog clean up task from smartdata job.
mod 14:- By Mrudula M. Rao for DR0199 on 12-aug-2009.Not putting company default for invalid operatorid ,
	 when setting in smartdataportrefreshdefaults for operator grouping is "Y" and
	 string is having a single operator without seperator.
mod 15:- By Mrudula M. Rao for DR0202 on 12-aug-2009.Remove 3 weeks restriction from smartdata.
	 Comment the check for 3 weeks data.
mod 16:-1) Job fails to move to the processing of next record on violation of primary key constraint. This error is coming when SplitpalletRecord = "Y" in smartdataportrefreshdefaults.
	2) When Loadunload Threshold value is less than the standard loadunload
	 value. and if the gap between the record exceeds Threshold loadunload , the NO_DATA record will result 
	into sttime>ndtime thus leading -ve loadunload for the down record inserted. 
	As a temporary solution consider loadunload threshold=standardloadunload whenevr loadunload threshold value is less than standard loadunload value.
mod 17:-for ER0195 by Mrudula M. Rao on 10-sep-2009. 
	Introduce a new data string with datatype 17. This  signal will be sent from the machine if one of  its tool has reached its target count. The strign format is as follows.
	START-17-MC-AlarmNumber-Stdate-Sttime-ToolCount-END and sample datastring looks as mentioned below.
	"START-17-1-15-20090801-134551-1200-END" . The tool count is the either the target set for the tool or the actual production by the tool. 
mod 18:-for DR0210 by Mrudula M. Rao on 11-sep-2009.When checking for out of sequence record, If the record is a production record we were not checking whether the sttime of the production
	 record is less than the last processed record's endtime. This was resulting in negative load 
	unload. To avoid this  check if the production records sttime is less than last processed records 
	end time. If it is so then it is out of sequence record.dont insert it into autodata.
mod 19:ER0258 modified by Karthick R on 29-sep-2010.
	If productionrecord comes after the down record then loadunload goes into downtime and loadunload become less than 5 sec.
    To avoid that we are reseting the end of downrecord also set the LU As StandardLoadunloadtime for MCO 
	.If MCO combination was not available for the record then use shopdefaults parameter 'DefaultvalueforSTDLUL'
	 as standardloadunload	 
ER0270 - 09-Nov-2010 - SwathiKS :: To Launch SCIThreshold and  DCLThreshold.
-- Created By Mrudula M. Rao 
	A)Short Circuit Interruption
	  1)If the cutting time of a production cycle is less than SCIThreshold defined in componentinformation for the component and operation, then put it as a down record with down code "SCI" , with cutting time as down time.
	  2) And the load unload part of the production cycle will be put as down record with code "SCILU"
	B)Dummy Cycle Loss
	  1)If the cutting time of a production cycle is less than  DCLThreshold  defined in componentinformation for the component and operation, then put it as a down record with down code "DCL" , with cutting time as down time.
	  2) And the load unload part of the production cycle will be put as down record with code "DCLU"
The logic mentioned above will be applicable only when splitPalletrecord="N"
Checking for sttime<ndtime while inserting SCI.SCILU,DCL and DCLU records
Consider pallet count while comparing SCI threshold  and cycletime. DCL threshold and cycletime
Rawdata status is not getting updated after insertion of record into autodata. Introduce BEGIN Transaction
Mod 21 : DR0266 By Karthick R on 04/01/2010.To solve the issue of inserting NO-Data record which is having starttime greatert than endtime
mod 22 : DR0271 by Karthik R on 01/03/2011.To Solve the issue of inserting negative no-data.
mod 23 : For ER0278 by KarthikR on 14/mar/2011.When CO changes the gap between the change has been considered as Setup change
		 only If gap is more than loadunloadthershold also in machineinformation AutoSetupchangeDown column should be Y
DR0274 - SwathiKS- 17/Mar/2011 ::In earlier logic , ICD has been sent with the production record itself.due to that logic , when some garbage value comes in @Splstring2 if Datatype is of Production Record it results in error.To handle that we added some more validation.
DR0293 - KarthikR - 26/Aug/2011 :: To avoid TimeMismatch Due to Loadunload Adjustment For BritishEngines.
DR0292 - SwathiKS - 26/Aug/2011 :: To Include Error Handler In datatype=4 For SprayingSystems.
DR0324 - SwathiKS - 20/Apr/2013 :: To handle duplicates when datatype=42 and datatype-16.
ER0354 - SwathiKS - 29/May/2013 :: To handle duplicates for datatype-6.
ER0361 - Satyendraj - 24/Jul/2013 :: Altered Procedure s_getprocessrawdata to update statistics on Autodata every 2 hours once.
NR0093 - SwathiKS - 05/Aug/2013 :: To handle Datatype=31 for SPC and Process into SPCAutodata Table.
ER0365 - SwathiKS - 12/Sep/2013 :: To Process ICD Records which has ICDStarttime = Production Record Starttime then Adding 100 milliseconds to ICDStarttime while inserting into Autodata.
ER0371- SwathiKS - 25/Nov/2013 :: To Handle Milliseconds instead of Seconds using function [dbo].[f_GetDatediffms] when @SplitpalletRecord = "Y" and @SupportICDDowns = "N".
DR0336 - SwathiKS - 22/Jan/2013 :: To Update Starttime (Adding 100 Milliseconds) of Autodata_ICD Table when Production Cycle Starttime=ICD starttime.
DR0344 - SwathiKS - 05/May/2014 :: a> To handle junk characters in DimensionValue while processing data from Rawdata to SPCAutodata.
b> To handle junk characters in @splstring2 while processing datatype=16.
ER0384 - SwathiKS - 01/Jul/2014 :: If Masterdata does not exists for incoming operator then rather than updating Company_Default Operator show incoming operator.
User will update inconsistent operators using Modify Data.This feature is enabled if comnanyName has "wipro".
ER0391 - SwathiKS - 25/Aug/2014 :: To introduce datatype=18 for Wipro and While Processing Datatype=17 Process "ToolCount" into "Actual" column of AutodataAlarms. 
NR0118 - SwathiKS - 27/Oct/2015 :: a> While Processing Datatype=1 Record Process datatype=35 to update sttime of records in MachineEventsAutodata table.				
b> For every cycle, check for SOLIDIFICATION STRING, if it does not exist, mark it as DUMMY CYCLE, type 2
Then,Check for all stages, if any stage is missing, mark it as DRY CYCLE, type 2
ER0443- SwathiKS - 24/01/2017 ::To Revert Back "ER0384" Requirement.
ER0442 - SwathiKS - 12/Dec/2016 :: If Master record does not exist for the incoming M-C-O in COP table then insert that record in COP table for Trelleborg. 
DR0376 - SwathiKS - 27/Jul/2017 :: To handle "Setup Change" for Bosch Bangalore. 
ER0463 - SwathiKS - 09/Apr/2018 ::  Altered S_GetProcessRawdata To Ignore Procesing of Datatype=22 for SPF
DR0385 - SwathiKS - 20/Jul/2018 :: a> when production Record comes after Down Record with small loadunload i.e. <= 5secs then Push the ndtime of Previous Down Record
and insert Stdloadunload as Loadunload for production Record if datediff(ss,@LastStarttime,@TempNdTime)-@TpmStdLoadunload)>0 else insert ActualLU as New DownRecord with dcode 'Loadunload'
B> To handle Duplicate MCO Insertion
Anjana - To handle enhancements in Datatype=31 for Endurance
ER0497 - Swathi KS - 29/01/2020 :: FOR RANE - If Previous Record is "Down" (Type 2) and Current record is "Production" (Type 1) then if Loadunload exists then 
PULL the Endtime of Previous Down Record (i.e. Update ndtime of Previous Down Record in Autodata table) and Add Loadunload time to the existing Loadunload of Down Record
and indicated the updated Record in "Post" Column in "Autodata" table.
and Loadunload will be "0" for the Current "Production Record" setting in shopdefaults table Parameter='VPPL_HandleSmallLoadunload' and valueintext should be PullDowntime.
ER0498::SwathiKS - 02/Feb/2021 :: For Shanti:: To include setting in shopdefaults table Parameter='LULMinThreshold' and valueintext 
May be ApplicationLevel or MCOLevel. this is used to Consider threshold value either Global Value (i.e. from Shopdefaults) or MinLULthreshold set in COP table.
If Previous Record is "Down" (Type 2) and Current record is "Production" (Type 1) and if ActLoadunload<MinLULthreshold then 
PUSH the Endtime of Previous Down Record (i.e. Update ndtime of Previous Down Record in Autodata table) and Add MinLULThreshold time as Loadunload to the Production Record instead of small loadunload exists.
DR0392:SwathiKS:29/9/2021::To handle Machineid NULL insertion into COP Table when Parameter = 'EnableCOPAutoInsert' is set to "Y" in Shopdefaults
**************************************************************************************************/
--exec s_GetProcessRawData
CREATE PROCEDURE [dbo].[s_GetProcessRawData]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

---select getdate()   	
--If(select count(*) from smartdataprocesshistory where status ='login')>0
--BEGIN
	--RETURNr
-- END	
--ELSE
-- BEGIN  commented for test
	CREATE TABLE #SD_RawData
	(
		 Slno  BIGINT,
		 DataType   Int,
		 IPAddress  Nvarchar(20),
		 Mc  Nvarchar(50),
		 Comp  Nvarchar(50),
		 Opn  Nvarchar(50),
		 Opr  Nvarchar(50),
		 Splstring1  Int,
		 Sttime  Datetime,
		 Ndtime  Datetime,
		 SplString2  Nvarchar(3500),
		 Status  Int
		--mod 10: column to get workorder number
		,WorkOrderNo nvarchar(50)
		--mod 10
	    ,Splstring3  Nvarchar(500),
		Splstring4 nvarchar(500),
		Splstring5 nvarchar(500),
		Splstring6 nvarchar(500),
		Splstring7 nvarchar(500),
		Splstring8 nvarchar(500),
		Splstring9 nvarchar(500),
		Splstring10 nvarchar(500),
		SPLString11 bit
	)	
	--Declaration of local variables to store the temporary table record values	
	DECLARE  @DataType As Int           		 -- To store the datatype of the incoming record
	DECLARE @IPAddress As Nvarchar(20)		 --To store IP Address	
	DECLARE  @Mc As Nvarchar(50)			 --MachineInterfaceId
	DECLARE  @Comp As Nvarchar(50)			 --ComponentId
	DECLARE  @Opn As Nvarchar(50)			 --OperationNo
	DECLARE  @Opr As Nvarchar(50)			 --OperatorId
	DECLARE	 @Splstring1 As Int			 --Special string to store PalletCount(Type 1) or ProgramId(Type3) or SpindleDir(Type4) Or ToolNo(Type 5)Or PAlarmNo(Type 6)
	DECLARE	 @Sttime As Datetime			 --StartTime
	DECLARE	 @Ndtime As Datetime			 --EndTime
	DECLARE	 @SplString2 As Nvarchar(3500)	 --Special String to store InCycledowns for type1 or down Code for Type 2
	DECLARE @Splstring3 as Nvarchar(500)
	DECLARE	 @Status As Int 			 --Status to know whether the string is processed or error occured on it or not processed
	DECLARE	 @Slno as Bigint
	--DECLARE  @Time As Datetime
	--Procedure App variables
	DECLARE  @Act_LoadUnload AS  Numeric(38,0)      --Actual Load Unload
	DECLARE  @Thr_LoadUnload As Numeric(38,0)      -- LoadUnload Threshold
	DECLARE  @LUforPrNxtToNODATA As  Numeric(38,0)      --LoadUnload for Production Record which is next to NO_DATA
	DECLARE  @Std_LoadUnload AS  Numeric(38,0)        -- CycleTime-MachiningTime(Standard LoadUnload)
	DECLARE  @machiningtime As Numeric(38,0)	
	DECLARE  @MachiningTimeThreshold As  Numeric(38,0)   --threshold machinig time for multiple component
	DECLARE  @OrgMachiningTimeThreshold As  Numeric(38,0)--machining time threshold for single comonent
	
	DECLARE  @downcode As Nvarchar(50)		   --read down code from downcodeinformation table
	DECLARE  @Comp_Down As Nvarchar(50)		
		
	--Decalre the DownTime table variables
	DECLARE  @ProdDownCodes Nvarchar(50)		--To store downcodes Of ICD's
	DECLARE  @Downstartdate Nvarchar(15)		--To store Down startdate
	DECLARE  @Downstarttime Nvarchar(10)		--TO store Down Starttime
	DECLARE  @Downenddate Nvarchar(15)		--To store Down End Date
	DECLARE  @Downendtime  Nvarchar(10)		--To store Down End Time
	
	DECLARE  @McInterfaceId AS VarChar(50)		--To store machine InterfaceID
	DECLARE  @Now As Nvarchar(30)			--To store presenttime	
	DECLARE  @dtStartDateTime As Datetime,@dtEndDateTime  As Datetime, @strDownCode  As Nvarchar(20)
	DECLARE  @dtStartTime As DateTime
	DECLARE  @TempNdTime As Datetime
	DECLARE  @SplitPalletRecord As Nvarchar(1)	--To know whether it supports Palletrecord(y/n)
	DECLARE  @SupportsICDnDowns As Nvarchar(1)	--To know whether it supports ICD's(y/n)
	DECLARE  @Cycle As Numeric(38,0)		--starttime-endtime(required in case of pallets)
	DECLARE  @TotalDown As Numeric(38,0)		--DownStartdate-DownEndDate
	DECLARE  @DownTimePerCycle As Numeric(38,0)	--TotalDown/palletcount(Down time for each pallet)
	DECLARE  @Increment As Integer			--Increment time for each component
	DECLARE  @AppErrCode As Integer			--Local variable to store error number for Application
	DECLARE  @Error AS Int 				--Local Variable to store error numbers for sequel errors
	DECLARE  @AlarmNo_Dec numeric(38,2)	
	Declare @Sep as nvarchar(2)			--Local variable to store operator separator character
	Declare @ICDinCycle as numeric(38,0)		--Local variable to store in cycle down for each component
	Declare @CompanyDefault as  nvarchar(10)		--Local variabe to store default operator when Opr is not present in employeeinfomation	
	---mod 8
	DECLARE @stndloadunload As  numeric(38,0) -- to store LoadUnload Threshold  while inserting down record.
	---mod 8
	--mod 7 --variable used while processing 42 (ICD) records
	declare @ICDdcode as nvarchar(50)
	declare @ICDstdate as datetime
	declare @ICDsttime as datetime
	declare @ICDnddate as datetime
	declare @ICDndtime as datetime
	declare @ICDcycletime  as numeric(38,0)
	declare @ICDloadunload as numeric(38,0) --variables used while processing 42 (ICD) records
	--mod 7
	---mod 10: To insert workorder number from rawdata into autodata
	DECLARE @WorkOrderNo as nvarchar(50)
	---mod 10
	--mod 19
	DECLARE @LastStarttime as Datetime
	--Declare @ActLUL_Flag as int
	--mod 19

	---ER0270
	DECLARE @SCIThreshold as float			---Local variable to store maximum threshold value to put Short circuit interruption down record
	DECLARE @DCLThreshold as float                  ---Local variable to store maximum threshold value to put Dummy cycle loss down record.
	---ER0270

	--DR0385
	Declare @VPPL_InsertLU as nvarchar(10)
	Select @VPPL_InsertLU='N'
	Select @VPPL_InsertLU = ISNULL(Valueintext,'N') from ShopDefaults where Parameter='VPPL_HandleSmallLoadunload'
	--DR0385

		--ER0497
	Declare @IgnoreLUForProdRecord AS  Numeric(38,0) --threshold LU to Pull the down record if ActLU<StdLU
	Select @IgnoreLUForProdRecord='5'
	Select @IgnoreLUForProdRecord = ISNULL(Valueintext,'5') from ShopDefaults where Parameter='IgnoreSmallLUForProdRecord'
	--ER0497

	--ER0498
	declare @MinLULThreshold as float
	Declare @LULMinThresholdSetting AS nvarchar(50) 
	Select @LULMinThresholdSetting='ApplicationLevel'
	Select @LULMinThresholdSetting = ISNULL(Valueintext,'ApplicationLevel') from ShopDefaults where Parameter='LULMinThreshold'
	--ER0498


	----------------------------
	Declare @WearOffSetNumber nvarchar(50)
	Declare	@MeasureDimension nvarchar(50)
	Declare	@CorrectionValue nvarchar(50)

	Declare	@Remarks nvarchar(50)
	Declare	@InspectionType nvarchar(50)
	Declare @OvalityMax nvarchar(50)
	Declare @OvalityMin nvarchar(50)

	Declare @IgnoreForCPCPK bit
	----------------------------
--Create temporary table to store ICD's in temporary variables
CREATE TABLE #SD_DownTime
	(
	   ProdDownCode  Nvarchar(50),
	   DownStartDate  DateTime ,
	   DownEndDate  DateTime
	)
Create table #SD_OprGrp(Oper nvarchar(50)) --Temporary table for operator grouping
	--SET @Time=GETDATE()
	--PRINT @Time
--select getdate()
	---mod 13: Commented below lines as it is leading to communication link failure
	--mod 12 From here
	--s_GetProcessRawData
	/*if datepart(hour,getdate())=23 and datepart(minute,getdate())>0 and datepart(minute,getdate())<5
	Begin
		Exec s_ClearRawData_ErrorLog
	End*/
	--mod 12 Till here
	---mod 13
--Insert records from Rawdata into temporary table to continuosly process it if that record status is 0
Insert into #SD_RawData
--select top 100 * from RawData WHERE DataType <> 3 and  Status=0 order by Slno Asc
--mod 4- Modified below query to not to select records with datatype 11
---select top 500 * from RawData WHERE Status=0 order by Slno Asc
--select top 500 * from RawData WHERE Status=0  and datatype<> 11 order by Slno Asc --ER0463
select top 500 * from RawData WHERE Status=0  and DataType NOT IN(11,22,0) order by Slno Asc --ER0463

---mod 4
	
	---select getdate()
	--Declare the cursor to process each record
	---mod 10 : Insert workorder number from rawdata into autodata
	--DECLARE SD_CUR CURSOR FOR SELECT Slno,DataType,IPAddress,Mc,Comp,Opn,Opr,Splstring1,Sttime,Ndtime,SplString2,Status FROM #SD_RawData
	DECLARE SD_CUR CURSOR FOR SELECT Slno,DataType,IPAddress,Mc,Comp,Opn,Opr,Splstring1,Sttime,Ndtime,SplString2,Status,WorkOrderNo,Splstring3,Splstring4,Splstring5,Splstring6,Splstring7,Splstring8,Splstring9,Splstring10,Splstring11  FROM #SD_RawData
	---mod 10
	OPEN SD_CUR
	--Fetch each record row  by row to process into local variables
	---mod 10
	---FETCH NEXT FROM SD_CUR INTO @Slno,@DataType,@IPAddress, @Mc,@Comp,@Opn,@Opr,@Splstring1,@Sttime,@Ndtime,@SplString2,@Status
	FETCH NEXT FROM SD_CUR INTO @Slno,@DataType,@IPAddress, @Mc,@Comp,@Opn,@Opr,@Splstring1,@Sttime,@Ndtime,@SplString2,@Status,@WorkOrderNo,@Splstring3,@WearOffSetNumber,@MeasureDimension,@CorrectionValue,@Remarks,@InspectionType,@OvalityMax,@OvalityMin,@IgnoreForCPCPK
	---mod 10
	--process in loop
	WHILE @@FETCH_STATUS = 0
	BEGIN


--------ER0443 Commented From Here
		---select getdate()
		-- if datatype is 1 or 2 or 42 or 62 validate for date,time and syntax check
--	  IF @DataType=1 or @Datatype=2 or @Datatype = 42 or @Datatype = 62
--	    BEGIN

--		--Operator Grouping concept
--		Select @Sep=Groupseperator1 from smartdataportrefreshdefaults
--		if (select OperatorGrouping from smartdataportrefreshdefaults)='y'
--		Begin
--		 If charindex(@Sep,@Opr)>0	
--		  Begin
--			  If len(@Opr)>=50
--			  Begin
--			    INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error-Operatorid is exceeding 50 characters',getdate())	
--			    --Raiserror('Error-Operatorid is exceeding 50 characters', 16, 1,@mcIPAdd,@McInterfaceID,@machine,@orgstring)
--			    SET @AppErrCode=13
--			    SET @ERROR=@@ERROR
--			    IF @ERROR <>0 or @AppErrCode=13 GOTO ERROR_HANDLER_GENERAL
--			  End
--			  Insert into #SD_OprGrp Exec s_GetOprGroupId @Opr
--			  Select  @Opr=oper from #SD_OprGrp
--		  End
--		  ---mod 14
--		 else
--		 begin
--				If Not exists (Select Companyname from company where companyname like '%wipro%') --ER0384
--				Begin --ER0384
--				   If NOT Exists (select interfaceid from employeeinformation where InterfaceID= @Opr)
--					 Begin					
--					   select  @CompanyDefault =  interfaceid from employeeinformation where Company_default = 1
--					   SET @Opr = @CompanyDefault
--					End
--				end --ER0384
--				Else --ER0384
--				begin --ER0384
--					SET @Opr = @Opr	--ER0384
--				end --ER0384
--		 end
--		  ---mod 14
--		--mod 2 END was missing in the loop
--		END
--		--mod 2
--		Else
--		  Begin
--			
--			If Not exists (Select Companyname from company where companyname like '%wipro%')--ER0384
--			Begin --ER0384
--				If NOT Exists (select interfaceid from employeeinformation where InterfaceID= @Opr)
--				 Begin
--					select  @CompanyDefault =  interfaceid from employeeinformation where Company_default = 1
--				    SET @Opr = @CompanyDefault
--				End
--			END--ER0384
--			Else --ER0384
--			begin --ER0384
--				SET @Opr = @Opr	 --ER0384
--			end --ER0384
--		 End-- for if select OperatorGrouping from smartdataportrefreshdefaults)='N'
--------ER0443 Commented Till Here

--------ER0443 Added From Here

	---select getdate()
	-- if datatype is 1 or 2 or 42 or 62 validate for date,time and syntax check
	  IF @DataType=1 or @Datatype=2 or @Datatype = 42 or @Datatype = 62
	    BEGIN
		--Operator Grouping concept
		Select @Sep=Groupseperator1 from smartdataportrefreshdefaults
		if (select OperatorGrouping from smartdataportrefreshdefaults)='y'
		Begin
		 If charindex(@Sep,@Opr)>0	
		  Begin
			  If len(@Opr)>=50
			  Begin
			    INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error-Operatorid is exceeding 50 characters',getdate())	
			    --Raiserror('Error-Operatorid is exceeding 50 characters', 16, 1,@mcIPAdd,@McInterfaceID,@machine,@orgstring)
			    SET @AppErrCode=13
			    SET @ERROR=@@ERROR
			    IF @ERROR <>0 or @AppErrCode=13 GOTO ERROR_HANDLER_GENERAL
			  End
			  Insert into #SD_OprGrp Exec s_GetOprGroupId @Opr
			  Select  @Opr=oper from #SD_OprGrp
		  End
		  ---mod 14
		 else
		 begin
		   If NOT Exists (select interfaceid from employeeinformation where InterfaceID= @Opr)
			 Begin
				
			   select  @CompanyDefault =  interfaceid from employeeinformation where Company_default = 1
			   SET @Opr = @CompanyDefault
		         End
		   end
		  ---mod 14
		--mod 2 END was missing in the loop
		END
		--mod 2
		Else
		  Begin
			
			If NOT Exists (select interfaceid from employeeinformation where InterfaceID= @Opr)
			 Begin
				
			   select  @CompanyDefault =  interfaceid from employeeinformation where Company_default = 1
			   SET @Opr = @CompanyDefault
		         End
		 End-- for if select OperatorGrouping from smartdataportrefreshdefaults)='
--------- ER0443 Added Till Here




		---Commented below END for mod 2
		-- End	--IfOPerator Grouping	
		---mod 2
		 --read the present time into local variable
		 SET @Now = DateName(year,getdate()) + '-' + DateName(month,getdate()) + '-' + DateName(day,getdate())
		 --validate the date and time
		 IF IsDate(@Sttime) = 1  And  IsDate(@Ndtime) = 1
	   	     BEGIN
			  If DateDiff(second , @Sttime ,@Ndtime) > 0
		   	     BEGIN
				--- mod 15: commented 3 weeks check
			  	  ---If DateDiff(day, @Now, Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime)) > 1 Or DateDiff(day, @Now,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime)) > 1  Or DateDiff(day, @Now,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime)) < -20 Or DateDiff(day, @Now, Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime)) < -20
				  If DateDiff(day, @Now, Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime)) > 1 Or DateDiff(day, @Now,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime)) > 1
				---mod 15
			    	     BEGIN
					  --insert into errorlog table if startdate is 3 weeks back or startdate is of tomorrows
			      		  INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Handling Dates- date is < 3Week or > 1 day',getdate())	
			       		  SET @AppErrCode=7
			   	          SET @ERROR=@@ERROR
			     		  IF @ERROR <>0 or @AppErrCode=7 GOTO ERROR_HANDLER_GENERAL
				     END	
		    	      END
			   ELSE
		   	      BEGIN
				   --insert into errorlog table if startdate > enddate
				   INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Handling Dates--Starttime >= endtime',getdate())	
				   SET @AppErrCode=8
				   SET @ERROR=@@ERROR
			           IF @ERROR <>0 or @AppErrCode=8 GOTO ERROR_HANDLER_GENERAL
		    	      END
		     END
	        ELSE
	            BEGIN
			  --insert into errorlog table if dates entered are not in correct format
			  INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Handling Dates---Date/time  is not in correct date/time format',getdate())	
			  SET @AppErrCode=9
		          SET @ERROR=@@ERROR
			  IF @ERROR <>0 or @AppErrCode=9 GOTO ERROR_HANDLER_GENERAL
		    END
		SET @McInterfaceId = NULL;
		
	    	-- validate dulpicate mc and sttime
	    	--select top 1 @McInterfaceId = mc from Autodata where mc = @Mc AND sttime = @Sttime
		--mod 16(1): Check autodata for mc,sttime combination where mc=	@Mc and sttime=@Sttime
		---select top 1 @McInterfaceId = machineid from Autodata_maxtime where machineid =@Mc AND starttime =  @Sttime
		select top 1 @McInterfaceId = mc from Autodata where  mc=@Mc and sttime=@Sttime
		--mod 16(1)
		IF @@ROWCOUNT > 0
	      	   BEGIN
			
			--Insert into error log file
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'SmartData-Duplicate Record Found From machine',getdate())
			SET @ERROR=@@ERROR
			SET @AppErrCode=5--Update the status value
			--If error then goto error handler
			IF @ERROR <>0 or @AppErrCode=5 GOTO ERROR_HANDLER_GENERAL
	           END
		
		SET @McInterfaceId = NULL;
		--Check for sequence of records to be processed
		
		---mod 5
		  IF @DataType=1
	    	  BEGIN
			---mod 5
			--SELECT TOP 1 @McInterfaceId=Mc from Autodata where mc= @Mc  and ndtime >= @Ndtime
			---mod 18:Check if sttime is <last processed records endtime
			---SELECT TOP 1 @McInterfaceId=Machineid from autodata_maxtime where machineid= @Mc  and Endtime > @Ndtime
			SELECT TOP 1 @McInterfaceId=Machineid from autodata_maxtime where machineid= @Mc  and Endtime > @Sttime
			--mod 18
		 	IF @@ROWCOUNT > 0
		     	    BEGIN
					
				  --Insert into error log file
				  INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Sequence out of order for this IP address',getdate())
				  SET @ERROR=@@ERROR
				  --Update the status value
				  SET @AppErrCode=6
				  --If error then goto error handler
				  IF @ERROR <>0 or @AppErrCode=6 GOTO ERROR_HANDLER_GENERAL
				
		    	    END
		   ---mod 5
		  END  		
		  IF @Datatype=2 or @Datatype = 42 or @Datatype = 62 --Checking for @Sttime<last processed records endtime
	          BEGIN
			---SELECT TOP 1 @McInterfaceId=Machineid from autodata_maxtime where machineid= @Mc  and Endtime > @Ndtime
			SELECT TOP 1 @McInterfaceId=Machineid from autodata_maxtime where machineid= @Mc  and Endtime >@Sttime
		 	IF @@ROWCOUNT > 0
		     	    BEGIN
					
				  --Insert into error log file
				  INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Sequence out of order for this IP address',getdate())
				  SET @ERROR=@@ERROR
				  --Update the status value
				  SET @AppErrCode=6
				  --If error then goto error handler
				  IF @ERROR <>0 or @AppErrCode=6 GOTO ERROR_HANDLER_GENERAL
				
		    	END
		
		  END
		---mod 5
		
		--Validate the palletcount
		---mod 1 . Added the following check for splitpalletrecord. If it is set to Y then only resetting the palletcount to 1 ,
		---If it exceeds the cycletime.
		If ISNULL((select  SplitPalletRecord FROM SmartdataPortRefreshDefaults),'N')='Y'
		BEGIN
			If @Splstring1  > 1 And DateDiff(second,@Sttime,@Ndtime) < @Splstring1
			SET @Splstring1 = 1
		END
		
		

		If @DataType = 1 and isnull(@SplString2,'a')<>'a' and difference(len(@SplString2),len(replace(@SplString2,'-','')))= 4   ---DR0274
	  	BEGIN  ---DR0274

		--While @DataType = 1 And @SplString2 <> '' ---DR0274
		  While @SplString2 <> ''
	   	    BEGIN
			--down code
		    	SET @ProdDownCodes = SUBSTRING(@SplString2,1,CHARINDEX('-',@SplString2) - 1)
			
			SET @SplString2 = SUBSTRING(@SplString2,CHARINDEX('-', @SplString2)+ 1,LEN(@SplString2) - CHARINDEX('-', @SplString2)+ 1)
			
			--startdate
		    	SET @Downstartdate = SUBSTRING(@SplString2,1,CHARINDEX('-',@SplString2) - 1)
			--DR0274 From Here.
			If isdate(@Downstartdate)<>1 
			BEGIN
		
			  INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Unexpected String Has Come in ICD',getdate())	
			  SET @AppErrCode=11
		          SET @ERROR=@@ERROR
			  IF @ERROR <>0 or @AppErrCode=11 GOTO ERROR_HANDLER_GENERAL	

			END
			--DR0274 Till Here.
		  	SET @SplString2 = SUBSTRING(@SplString2,CHARINDEX('-', @SplString2)+ 1,LEN(@SplString2) - CHARINDEX('-', @SplString2)+ 1)
			SET @Downstartdate = dbo.f_GetTpmStrToDate(@Downstartdate,GetDate())     		
			
			--starttime
			SET @Downstarttime = SUBSTRING(@SplString2,1,CHARINDEX('-',@SplString2) - 1)
			SET @SplString2 = SUBSTRING(@SplString2,CHARINDEX('-', @SplString2)+ 1,LEN(@SplString2) - CHARINDEX('-', @SplString2)+ 1)
			SET @Downstarttime = dbo.f_GetTpmStrToTime(@Downstarttime)     		
			
		      	--enddate
			SET @Downenddate = SUBSTRING(@SplString2,1,CHARINDEX('-',@SplString2) - 1)
			--DR0274 From Here.
			If isdate(@Downenddate)<>1 
			BEGIN

			  INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Unexpected String Has Come in ICD',getdate())	
			  SET @AppErrCode=11
		          SET @ERROR=@@ERROR
			  IF @ERROR <>0 or @AppErrCode=11 GOTO ERROR_HANDLER_GENERAL	
	
			END
			--DR0274 Till Here.
			SET @SplString2 = SUBSTRING(@SplString2,CHARINDEX('-', @SplString2)+ 1,LEN(@SplString2) - CHARINDEX('-', @SplString2)+ 1)
			SET @Downenddate = dbo.f_GetTpmStrToDate(@Downenddate,GetDate())     		
			
		   	--endtime
			SET @Downendtime = SUBSTRING(@SplString2,1,CHARINDEX('-',@SplString2) - 1)
			SET @SplString2 = SUBSTRING(@SplString2,CHARINDEX('-', @SplString2)+ 1,LEN(@SplString2) - CHARINDEX('-', @SplString2)+ 1)
			SET @Downendtime = dbo.f_GetTpmStrToTime(@Downendtime)
		
		
	          If (@ProdDownCodes <> '0'OR @ProdDownCodes <> '') And IsDate(@Downstartdate + ' ' + @Downstarttime) = 1 And IsDate(@Downenddate + ' ' + @Downendtime) = 1
		     BEGIN
	                  If DateDiff(second, @Downstartdate + ' ' + @Downstarttime, @Downenddate + ' ' + @Downendtime) > 0
		             BEGIN
	                          --insert into temp downtime table
			          INSERT INTO #SD_DownTime Values(@ProdDownCodes,@Downstartdate + ' ' + @Downstarttime, @Downenddate + ' ' + @Downendtime)
	                     END
	             END
	          END --While DOWN	
		
	END--IFTYPE1 OR 2 FOR VALIDATING THE START TIME AND END TIME
END  ----DR0274


--*************************************************************************************************
	--Type 1 Record
	--Insert production record
--exec s_GetProcessRawData
-------------------------------------------------------------------------------------------------
	   If @DataType = 1
	      BEGIN
		   SET @TempNdTime = NULL;		        --Temporary variable to store last endtime of autodata
		   SET @Act_LoadUnload = NULL;			
		   SET @LUforPrNxtToNODATA=NULL;
		--mod 19
			SET @LastStarttime=NULL;
		--mod 19
		   --Select end time of last record for that machine from database
	--select @TempNdTime = (select top 1 ndtime from autodata where mc= @Mc  and ndtime <=@Sttime order by id desc)
	select @TempNdTime=(select endtime from autodata_maxtime where machineid=@Mc)
	--mod 19
	select @LastStarttime=(select starttime from autodata_maxtime where machineid=@Mc)
	--mod 19	
		   --Count Loadunload  time for recent record comming from machine
	   SET @Act_LoadUnload = DateDiff(second, @TempNdTime, @Sttime)
			
   --Set the variables with default value
		   SET @Thr_LoadUnload = 600
		   set @machiningtime  = 0.0
		   SET @MachiningTimeThreshold = 0.0
		   SET @OrgMachiningTimeThreshold=0.0
		   SET @Std_LoadUnload=0.0


		  ---ER0270
		   SET @SCIThreshold=0.0
		   SET @DCLThreshold=0.0
		   ---ER0270
			-- mod 21	
			Declare  @coExist  as int
			SET @CoExist=0
			-- mod 21
			--mod 22
			Declare  @TpmStdLoadunload  as int
			SET @TpmStdLoadunload=0
			--mod 22
			--mod 23
			Declare @AutoSetupchange as int
			--Select @AutoSetupchange=isnull(count(*),0) from Machineinformation where AutoSetupchangeDown='Y' and interfaceid='2014' --DR0376
			Select @AutoSetupchange=isnull(count(*),0) from Machineinformation where AutoSetupchangeDown='Y'  --DR0376
			Print(@AutoSetupchange)
			
			Declare @comp_Setup as nvarchar(50)
			Declare @opn_Setup as nvarchar(50)
			Declare @Setupchangeflag as int
			Set @Setupchangeflag=0
			Declare @Downcode_interfaceid nvarchar(50)

			SET @Downcode_interfaceid=NULL

			--mod 23


		   --Assign the local variables with the specific data which is to be inserted into DB
			---mod 9 Introduce MCO in below query
--			select  @Thr_LoadUnload = loadunload,@Std_LoadUnload=ISNULL((CycleTime-MachiningTime),0),@machiningtime = isnull(machiningtime,0)* @Splstring1,
--		           @OrgMachiningTimeThreshold=ISNULL(MachiningTimeThreshold,0),
--		      	   @MachiningTimeThreshold = (isnull(machiningtime,0) * @Splstring1 * isnull(MachiningTimeThreshold,0)/100) + isnull(machiningtime,0)* @Splstring1 + 60
--		   		   from componentoperationpricing inner join componentinformation on componentoperationpricing.componentid=componentinformation.componentid where componentinformation.interfaceid=@Comp and componentoperationpricing.interfaceid=@Opn
			
/******************************ER0270 From here
				select  @Thr_LoadUnload = loadunload,@Std_LoadUnload=ISNULL((CycleTime-MachiningTime),0),@machiningtime = isnull(machiningtime,0)* @Splstring1,
				@OrgMachiningTimeThreshold=ISNULL(MachiningTimeThreshold,0),
				@MachiningTimeThreshold = (isnull(machiningtime,0) * @Splstring1 * isnull(MachiningTimeThreshold,0)/100) + isnull(machiningtime,0)* @Splstring1 + 60
		   		from componentoperationpricing inner join componentinformation on componentoperationpricing.componentid=componentinformation.componentid
				inner join machineinformation on machineinformation.machineid = componentoperationpricing.machineid
				where componentinformation.interfaceid=@Comp and componentoperationpricing.interfaceid=@Opn
				and machineinformation.Interfaceid=@Mc 
ER0270 Till here*******************************/
			  ---mod 9
				--print(@Std_LoadUnload)


		  --validate each variable
			--mod 21


				select   @CoExist=isnull(Count(*),0)
					from componentoperationpricing inner join componentinformation on componentoperationpricing.componentid=componentinformation.componentid
				inner join machineinformation on machineinformation.machineid = componentoperationpricing.machineid
				where componentinformation.interfaceid=@Comp and componentoperationpricing.interfaceid=@Opn
				and machineinformation.Interfaceid=@Mc
			--mod 21
		
			if  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'EnableCOPAutoInsert') = 'Y')
			BEGIN

				If @CoExist = 0
				BEGIN
					Declare @CI_ComponentID as nvarchar(50)
					Declare @COPSlNo as int
					Select @CI_ComponentID=''
					Select @CI_ComponentID = componentid From componentinformation where componentinformation.interfaceid=@Comp

				IF Exists (Select * from machineinformation where InterfaceID=@Mc)
				 BEGIN

					If ISNULL(@CI_ComponentID,'A')<>'A'
					BEGIN 

						IF Exists (Select * from componentoperationpricing where componentid=@CI_ComponentID And interfaceid=@Opn)
						BEGIN
							SET identity_insert  componentoperationpricing Off

							--Select @COPSlNo=Max(SlNo) From componentoperationpricing where componentid=@CI_ComponentID And interfaceid=@Opn --DR0392
							Select @COPSlNo=Max(SlNo) From componentoperationpricing where componentid=@CI_ComponentID And interfaceid=@Opn and machineid IS NOT NULL --DR0392

							-----------Inserts Components To COP Table from Item List Given.
							--Insert into Componentoperationpricing(componentid, operationno, description, machineid, price, cycletime, drawingno, InterfaceID, loadunload, machiningtime, SubOperations, StdSetupTime, 
							--MachiningTimeThreshold, TargetPercent, UpdatedBy, UpdatedTS, LowerEnergyThreshold, UpperEnergyThreshold, SCIThreshold, DCLThreshold, 
							--McTimeMonitorLThreshold, McTimeMonitorUThreshold, StdDieCloseTime, StdPouringTime, StdSolidificationTime, StdDieOpenTime)
							--Select Top 1 componentid, operationno, description,(Select machineid From machineinformation where Interfaceid=@Mc), price, cycletime, drawingno, InterfaceID, loadunload, machiningtime, SubOperations, StdSetupTime, 
							--MachiningTimeThreshold, TargetPercent, 'Service', getdate(), LowerEnergyThreshold, UpperEnergyThreshold, SCIThreshold, DCLThreshold, 
							--McTimeMonitorLThreshold, McTimeMonitorUThreshold, StdDieCloseTime, StdPouringTime, StdSolidificationTime, StdDieOpenTime From componentoperationpricing where componentid=@CI_ComponentID And interfaceid=@Opn
							--Order by Slno desc
							Insert into Componentoperationpricing(componentid, operationno, description, machineid, price, cycletime, drawingno, InterfaceID, loadunload, machiningtime, SubOperations, StdSetupTime, 
							MachiningTimeThreshold, TargetPercent, UpdatedBy, UpdatedTS, LowerEnergyThreshold, UpperEnergyThreshold, SCIThreshold, DCLThreshold, 
							McTimeMonitorLThreshold, McTimeMonitorUThreshold, StdDieCloseTime, StdPouringTime, StdSolidificationTime, StdDieOpenTime,MinLoadUnloadThreshold) --ER0498
							Select componentid, operationno, description,(Select machineid From machineinformation where Interfaceid=@Mc), price, cycletime, drawingno, InterfaceID, loadunload, machiningtime, SubOperations, StdSetupTime, 
							MachiningTimeThreshold, TargetPercent, 'Service', getdate(), LowerEnergyThreshold, UpperEnergyThreshold, SCIThreshold, DCLThreshold, 
							McTimeMonitorLThreshold, McTimeMonitorUThreshold, StdDieCloseTime, StdPouringTime, StdSolidificationTime, StdDieOpenTime,MinLoadUnloadThreshold From componentoperationpricing where componentid=@CI_ComponentID And interfaceid=@Opn --ER0498
							and Slno=@COPSlNo 

							SET identity_insert  componentoperationpricing ON
						END
					END
				 END
               END
             END

			select  @Thr_LoadUnload = loadunload,@Std_LoadUnload=ISNULL((CycleTime-MachiningTime),0),@machiningtime = isnull(machiningtime,0)* @Splstring1,
				@OrgMachiningTimeThreshold=ISNULL(MachiningTimeThreshold,0),
				@MachiningTimeThreshold = (isnull(machiningtime,0) * @Splstring1 * isnull(MachiningTimeThreshold,0)/100) + isnull(machiningtime,0)* @Splstring1 + 60,
				---ER0270 From here
				@SCIThreshold=isnull(CycleTime,0)*(ISNULL(SCIThreshold,0)/100)* @Splstring1,
			   	@DCLThreshold=isnull(CycleTime,0)*(ISNULL(DCLThreshold,0)/100)* @Splstring1
				---ER0270 Till here
				,@MinLULThreshold=ISNULL(MinLoadUnloadThreshold,0) ----ER0498
		   		from componentoperationpricing inner join componentinformation on componentoperationpricing.componentid=componentinformation.componentid
				inner join machineinformation on machineinformation.machineid = componentoperationpricing.machineid
				where componentinformation.interfaceid=@Comp and componentoperationpricing.interfaceid=@Opn
				and machineinformation.Interfaceid=@Mc 
			print (@SCIThreshold)

/* SV Commented and Added at the Top

		  --validate each variable
			--mod 21
				select   @CoExist=isnull(Count(*),0)
					from componentoperationpricing inner join componentinformation on componentoperationpricing.componentid=componentinformation.componentid
				inner join machineinformation on machineinformation.machineid = componentoperationpricing.machineid
				where componentinformation.interfaceid=@Comp and componentoperationpricing.interfaceid=@Opn
				and machineinformation.Interfaceid=@Mc
			--mod 21
*/

			--mod 19
			--mod 21
			---if isnull(@Std_LoadUnload,0)=0 or @Std_LoadUnload=0
				if @CoExist=0
			--mod 21
			 begin
				--Declare @Std_LoadUnload as int
				Select @Std_LoadUnload=isnull(valueinint,0) from shopdefaults where parameter='DefaultvalueforSTDLUL'
				--print(@Std_LoadUnload)
				
				if isnull(@Std_LoadUnload,0)=0
					set @Std_LoadUnload=0
				--Set @Std_LoadUnload=isnull(@Std_LoadUnload,0)
				print(@Std_LoadUnload)
				--return
			 End
				

			--mod 19
		  IF IsNumeric(@Thr_LoadUnload) = 0
	 		SET @Thr_LoadUnload = 600.0

		---mod 16(2):If @Thr_LoadUnload<@Std_LoadUnload then set @Thr_LoadUnload=@Std_LoadUnload
		  if @Thr_LoadUnload<@Std_LoadUnload 
			set  @Thr_LoadUnload=@Std_LoadUnload
		---mod 16(2)
	
		  IF IsNumeric(@MachiningTimeThreshold)=0
	 		SET @MachiningTimeThreshold = 0.0
		  IF IsNumeric(@OrgMachiningTimeThreshold)=0
			SET @OrgMachiningTimeThreshold = 0.0

		--mod 19
		--Changes need to be done here
			--if Alu<=5 and lat record is down(where mc,sttime,type2)
			--update endtime of the last record to @sttime-Stdloadunloadshould be greater than 0
	
			--DR0385 COMMENTED AND ADDED FROM HERE			
			--mod 22
				--if @Act_LoadUnload<=5 and (isnumeric(@Splstring1)=1 and isnull(@Splstring1,2)<>2) and @Splstring1<>0
				--	begin
				--		Set @TpmStdLoadunload=@Std_LoadUnload*@Splstring1
				--	End

				--ER0498 From Here
				 IF @LULMinThresholdSetting='MCOLevel' ---This is for Shanti By Default @LULMinThresholdSetting='ApplicationLevel'
				 Begin
					Select @IgnoreLUForProdRecord=@MinLULThreshold
				 End
				 --ER0498 From Here

				SELECT  @SplitPalletRecord = SplitPalletRecord,@SupportsICDnDowns= SupportsICDnDowns FROM SmartdataPortRefreshDefaults --DR0385 COMMENTED BELOW AND ADDED HERE
				IF (@SplitPalletRecord = 'n' and @SupportsICDnDowns = 'n')
				Begin

					--if @Act_LoadUnload<=5 and (isnumeric(@Splstring1)>=1 and isnull(@Splstring1,5)<>5) and @Splstring1<>0 --ER0497
					if @Act_LoadUnload<=@IgnoreLUForProdRecord and (isnumeric(@Splstring1)>=1 and isnull(@Splstring1,5)<>5) and @Splstring1<>0  --ER0497
					begin
						Set @TpmStdLoadunload=@Std_LoadUnload*@Splstring1
					End
				End
				Else
				Begin
					--if @Act_LoadUnload<=5 and (isnumeric(@Splstring1)=1 and isnull(@Splstring1,2)<>2) and @Splstring1<>0  --ER0497
					if @Act_LoadUnload<=@IgnoreLUForProdRecord and (isnumeric(@Splstring1)=1 and isnull(@Splstring1,2)<>2) and @Splstring1<>0 --ER0497
					begin
						Set @TpmStdLoadunload=@Std_LoadUnload*@Splstring1
					End
				END
				--DR0385 COMMENTED AND ADDED TILL HERE	

				--ER0497 Added From Here For Rane
				IF @Act_LoadUnload>0 and ((Select count(*) from autodata where mc=@mc and sttime=@LastStarttime and datatype=2)=1) 
				BEGIN
						If @VPPL_InsertLU = 'PullDowntime'
						BEGIN
							BEGIN TRANSACTION
							--Pull the end time of the previous down record to ADD Actual load unload instead of a small load unload that exists.
							--Autodata.Post column we are marking 1 to indicate the record
							update autodata set ndtime=dateadd(ss,DateDiff(second, @TempNdTime, @Sttime),ndtime),
							loadunload=(loadunload+DateDiff(second, @TempNdTime, @Sttime)),post=1
							where mc=@mc and sttime=@LastStarttime and datatype=2

							Set @Act_LoadUnload=0

							SET @Error = @@ERROR
							IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
						END
				END
				--ER0497 Added Till Here For Rane

				----ER0498 From Here
				-- IF @LULMinThresholdSetting='MCOLevel' ---This is for Shanti By Default @LULMinThresholdSetting='ApplicationLevel'
				-- Begin
				--	Select @IgnoreLUForProdRecord=@MinLULThreshold
				--	Select @TpmStdLoadunload=@MinLULThreshold
				-- End
				-- --ER0498 From Here

				--if @Act_LoadUnload<=5 and (datediff(ss,@LastStarttime,@TempNdTime)-@Std_LoadUnload)>0 and ((Select count(*) from autodata where mc=@mc and sttime=@LastStarttime and datatype=2)=1)
			   --if @Act_LoadUnload<=5 and (datediff(ss,@LastStarttime,@TempNdTime)-@TpmStdLoadunload)>0 and ((Select count(*) from autodata where mc=@mc and sttime=@LastStarttime and datatype=2)=1) --ER0497 Commented
				if (@Act_LoadUnload<=@IgnoreLUForProdRecord) and (datediff(ss,@LastStarttime,@TempNdTime)-@TpmStdLoadunload)>0 and ((Select count(*) from autodata where mc=@mc and sttime=@LastStarttime and datatype=2)=1) and  (@VPPL_InsertLU <>'PullDowntime') --ER0497 instead of "5" kept setting in shopdefaults by default it will be 5
				--mod 22
				  Begin
				
				/* DR0293 Commented From here.
				update autodata set ndtime=dateadd(ss,-(@Std_LoadUnload),@Sttime),
					loadunload=datediff(ss,autodata.Sttime,autodata.NdTime)
					where mc=@mc and sttime=@LastStarttime and datatype=2
			
					--set @ActLUL_Flag=1
					--Actualloadunload is already calculated in the top so it should be reset to standard load unload according to the requirement
					Set @Act_LoadUnload=@Std_LoadUnload
				 DR0293 Commented Till here. */

				--DR0293 Modified From here.
					If @TpmStdLoadunload > @Act_LoadUnload 
					Begin				  

					--push the end time of the previous down record to introduce standard load unload instead of a small load unload that exists.
						update autodata set ndtime=dateadd(ss,-(@TpmStdLoadunload),@Sttime),
						loadunload=loadunload-@TpmStdLoadunload+@Act_LoadUnload----datediff(ss,autodata.Sttime,autodata.NdTime)
						where mc=@mc and sttime=@LastStarttime and datatype=2
			
						--set @ActLUL_Flag=1
						--Actualloadunload is already calculated in the top so it should be reset to standard load unload according to the requirement
						Set @Act_LoadUnload=@TpmStdLoadunload
				
					END
				--DR0293 Modified Till here
				END

				--DR0385 ADDED FROM HERE	
				--ELSE if (@Act_LoadUnload>0 and @Act_LoadUnload<=5) and (datediff(ss,@LastStarttime,@TempNdTime)-@TpmStdLoadunload)<0 and ((Select count(*) from autodata where mc=@mc and sttime=@LastStarttime and datatype=2)=1) --ER0497 commented
				ELSE if (@Act_LoadUnload>0 and @Act_LoadUnload<=@IgnoreLUForProdRecord) and (datediff(ss,@LastStarttime,@TempNdTime)-@TpmStdLoadunload)<0 and ((Select count(*) from autodata where mc=@mc and sttime=@LastStarttime and datatype=2)=1) --ER0497 instead of "5" kept setting in shopdefaults by default it will be 5
				BEGIN

						If @VPPL_InsertLU = 'Y'
						BEGIN
							BEGIN TRANSACTION
							Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,WorkOrderNumber,PJCYear) values
							(2,@Mc ,@Comp ,@Opn ,@Opr ,'LoadUnload', DateName(year,@TempNdTime)+ '-' +  DateName(month,@TempNdTime)+ '-' + DateName(day,@TempNdTime) ,
		        			@TempNdTime ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,0,DATEDIFF(ss,@TempNdTime,@Sttime),@TempNdTime,@WorkOrderNo,@Splstring3)

							Set @Act_LoadUnload=0

							SET @Error = @@ERROR
							IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
						END
				 END
				 --DR0385 COMMENTED AND ADDED FROM HERE	
		--mod 19 

		  --INSERT THE RECORD INTO DB
		  IF (isnumeric(@Act_LoadUnload)= 0) AND (@Sttime<>'00:00:00') AND (DATEDIFF(s,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) + ' 00:00:00',@Sttime)>600)
	 	     BEGIN
		
		       	  --if it is first record in database,insert No_DATA Record
			  SET @Act_LoadUnload = 0
			  SET @LUforPrNxtToNODATA=@Std_LoadUnload
			
			  BEGIN TRANSACTION
		      	      Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,WorkOrderNumber,PJCYear) values
	             		(2,@Mc ,@Comp ,@Opn ,@Opr ,'NO_DATA',Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) + ' 00:00:00',Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),
			              DATEADD(ss,-@Std_LoadUnload,@Sttime) ,0, (DateDiff(s, Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) + ' 00:00:00', @Sttime)-@Std_LoadUnload) ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) + ' 00:00:00',@WorkOrderNo,@Splstring3)
			
			     SET @Error = @@ERROR
			     IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
	  	     END
		
		 --mod 22
		 --IF @Act_LoadUnload > @Thr_LoadUnload 
		 IF @Act_LoadUnload > @Thr_LoadUnload and @TpmStdLoadunload = 0
		--mod 22
	 	    BEGIN
		          BEGIN TRANSACTION
			---mod 10:insert work order number also.@WorkOrderNo
		         -- Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
				-- (2,@Mc ,@Comp ,@Opn ,@Opr ,'NO_DATA',
			        --  DateName(year,@TempNdTime)+ '-' +  DateName(month,@TempNdTime)+ '-' + DateName(day,@TempNdTime) ,
		        	--  @TempNdTime ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),DATEADD(ss,-@Std_LoadUnload,@Sttime),0,(@Act_LoadUnload-@Std_LoadUnload) ,@TempNdTime )
				--mod 23

					--Return
				Declare @Downcodestr As Nvarchar(50)
					---Set @Downcodestr='NO_DATA'
					if @AutoSetupchange>=1 
						Begin
							Select @comp_Setup=comp,@opn_Setup=opn From autodata where Sttime=@LastStarttime and ndtime=@TempNdTime and Datatype=1
							--if (@comp_Setup<>@comp and @opn_Setup<>@Opn and @Act_LoadUnload<72000) --DR0376
							   if ((@comp_Setup<>@comp OR @opn_Setup<>@Opn) and @Act_LoadUnload<72000) --DR0376
								Begin
									---Set =1	
									Select @Setupchangeflag=isnull(count(*),0) from downcodeinformation where Downdescription='Setup Change'
									Select @Downcode_interfaceid= interfaceid from downcodeinformation where Downdescription='Setup Change'
							End
							
						End

					print(@comp_Setup)
					print(@opn_Setup)
					print(@Setupchangeflag)
					print(@Downcode_interfaceid)
					--Return
				/*Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber) values
				 (2,@Mc ,@Comp ,@Opn ,@Opr ,'NO_DATA',
			          DateName(year,@TempNdTime)+ '-' +  DateName(month,@TempNdTime)+ '-' + DateName(day,@TempNdTime) ,
		        	  @TempNdTime ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),DATEADD(ss,-@Std_LoadUnload,@Sttime),0,(@Act_LoadUnload-@Std_LoadUnload) ,@TempNdTime ,@WorkOrderNo)*/
				Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber,PJCYear) values
				 (2,@Mc ,@Comp ,@Opn ,@Opr ,Case @Setupchangeflag
													when 0 then  'NO_DATA'
													Else  isnull(@Downcode_interfaceid,'NO_DATA')
													End,
			          DateName(year,@TempNdTime)+ '-' +  DateName(month,@TempNdTime)+ '-' + DateName(day,@TempNdTime) ,
		        	  @TempNdTime ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),DATEADD(ss,-@Std_LoadUnload,@Sttime),0,(@Act_LoadUnload-@Std_LoadUnload) ,@TempNdTime ,@WorkOrderNo,@Splstring3)


				--mod 23
				--mod 10
			
			SET @Error = @@ERROR
			IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			
			SET @Act_LoadUnload =0
			SET @LUforPrNxtToNODATA=@Std_LoadUnload
	            END
			
		  --Dummy cylce insertion
		 If  (Select [NPCy-Tcs] from autodata_maxtime where [NPCy-Tcs]>=@Sttime and [NPCy-Tcs]<=@Ndtime) <> ''
		  Begin
			BEGIN TRANSACTION
			--mod 10 : Insert workorder number also
			---Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
				-- (2,@Mc ,@Comp ,@Opn ,@Opr ,'NPCy',DateName(year,@Sttime)+ '-' +  DateName(month,@Sttime)+ '-' + DateName(day,@Sttime) ,
		        	 -- @Sttime ,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime),@Ndtime,0,datediff(s,@Sttime,@Ndtime),@Sttime )
			Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber,PJCYear) values
				 (2,@Mc ,@Comp ,@Opn ,@Opr ,'NPCy',DateName(year,@Sttime)+ '-' +  DateName(month,@Sttime)+ '-' + DateName(day,@Sttime) ,
		        	  @Sttime ,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime),@Ndtime,0,datediff(s,@Sttime,@Ndtime),@Sttime,@WorkOrderNo,@Splstring3)
			---mod 10
			SET @Error = @@ERROR
			IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			  While @@TRANCOUNT <> 0
			   BEGIN
				COMMIT TRANSACTION
				UPDATE rawdata  set status=1 where Slno=@Slno	
			    END
			 Update autodata_maxtime set [NPCy-Tcs] ='' where machineid=@MC
			 GOTO FETCHCURSOR		
		  End	



		---------------------------------------------------- NR0118 Added From Here ---------------------------------------------
		IF (select count(*) from MachineEventsAutodata where MachineInterface=@Mc and Starttime>=@Sttime and Endtime<=@Ndtime)>'0'
		BEGIN


				IF Exists(select * from MachineEventsAutodata where MachineInterface=@Mc and Starttime>=@Sttime and Endtime<=@Ndtime )
				BEGIN
						Update MachineEventsAutodata set sttime = @sttime where MachineInterface=@Mc and Starttime>=@Sttime and Endtime<=@Ndtime
				END

				IF NOT Exists(select * from MachineEventsAutodata where MachineInterface=@Mc and Starttime>=@Sttime and Endtime<=@Ndtime and EventID='102' )
				begin
				
					BEGIN Transaction

					insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,WorkOrderNumber,PJCYear)
					values (2, @Mc , @Comp , @Opn , @Opr , 'Dummy Cycle' ,DateName(year,@Sttime)+ '-' +DateName(month,@Sttime)+ '-' + DateName(day,@Sttime),@Sttime,DateName(year,@Ndtime)+ '-' +DateName(month,@Ndtime)+ '-' + DateName(day,@Ndtime),@Ndtime,0, DateDiff(second, @Sttime, @Ndtime) ,@Sttime,@WorkOrderNo,@Splstring3)
					
					---on error go to error handler
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES

					While @@TRANCOUNT <> 0
					BEGIN
						--On succesful insertion commit transaction
						COMMIT TRANSACTION
						---set the record status = 1 to indicate that is processed
						UPDATE rawdata  set status=1 where Slno=@Slno	
					END
				
				---Exit the loop and process next record
				 GOTO FETCHCURSOR	
				
				END

				IF (select count(*) from MachineEventsAutodata where MachineInterface=@Mc and Starttime>=@Sttime and Endtime<=@Ndtime and EventID in('100','101','103'))<'3'
				begin
				
					BEGIN Transaction


					insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,WorkOrderNumber,PJCYear)
					values (2, @Mc , @Comp , @Opn , @Opr , 'Dry Cycle' ,DateName(year,@Sttime)+ '-' +DateName(month,@Sttime)+ '-' + DateName(day,@Sttime),@Sttime,DateName(year,@Ndtime)+ '-' +DateName(month,@Ndtime)+ '-' + DateName(day,@Ndtime),@Ndtime,0, DateDiff(second, @Sttime, @Ndtime) ,@Sttime,@WorkOrderNo,@Splstring3)

		
					---on error go to error handler
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES

					While @@TRANCOUNT <> 0
					BEGIN
						--On succesful insertion commit transaction
						COMMIT TRANSACTION
						---set the record status = 1 to indicate that is processed
						UPDATE rawdata  set status=1 where Slno=@Slno	
					END
				
				---Exit the loop and process next record
				 GOTO FETCHCURSOR	
				
			 END
		END
		---------------------------------------------------- NR0118 Added Till Here ---------------------------------------------


		--Ends here
		--READ THE SETTINGS IN SMARTDATAPORTREFRSHDEFAULTS TABLE
		--SELECT  @SplitPalletRecord = SplitPalletRecord,@SupportsICDnDowns= SupportsICDnDowns FROM SmartdataPortRefreshDefaults --DR0385 COMMENTED AND ADDED AT THE TOP
		IF @SplitPalletRecord = 'y' and @SupportsICDnDowns = 'y'
		   BEGIN
			IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
			
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'We does not suppot the Split Pallet Record = "y" and Supports ICD n Downs = "y" (Table-"SmartdataPortRefreshDefaults"',getdate())	
			
			 SET @AppErrCode=10
			 UPDATE rawdata  set status=@AppErrCode where Slno=@Slno	
			 GOTO FETCHCURSOR
		         --SET @ERROR=@@ERROR
			 --IF @ERROR <>0 or @AppErrCode=10 GOTO ERROR_HANDLER_FORTYPE1
		   END
		---mod 7
			---While inserting a production record if SpiltPalletRecord='N'
		---3) If any datatype 42 records found for the production cycle , deduct the sum of downtime from the
		  -- production time and insert the production record with same starttime and endtime.
		--4) Once the production record is inserted , insert datatype 42 record as datatype 2 (down) record
		 --- in autodata.
		--5) Do not insert Interpreted down records like MCTI and CYCTI for the
		 --  production cycle if 42 records are there.
		IF @SplitPalletRecord = 'n'
		BEGIN
			----ER0270 From Here
			 if (Select isnull(Valueintext,'N') from shopdefaults where parameter='CycleIgnoreThreshold')='Y'
				Begin
					IF (DateDiff(second, @Sttime, @Ndtime)<=@SCIThreshold )  and @SCIThreshold > 0.0
						BEGIN
						
						BEGIN Transaction
						
						---IF cutting time is less than SCIThreshold Put Load unload part as a down with downcode "SCILU"
						print @Sttime
						--return
						if datediff(second,DateAdd(second,-@Act_LoadUnload,@Sttime),@Sttime)>0.0
						begin
						
							insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,WorkOrderNumber,PJCYear)
							values (2, @Mc , @Comp , @Opn , @Opr , 'SCILU' ,DateName(year,DateAdd(second,-@Act_LoadUnload,@Sttime))+ '-' +DateName(month,DateAdd(second,-@Act_LoadUnload,@Sttime))+ '-' + DateName(day,DateAdd(second,-@Act_LoadUnload,@Sttime)),DateAdd(second,-@Act_LoadUnload,@Sttime),DateName(year,@Sttime)+ '-' +DateName(month,@Sttime)+ '-' + DateName(day,@Sttime),@Sttime,0,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@Sttime),@WorkOrderNo,@Splstring3)
					
						end
						
						
						---on error go to error handler
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
						---IF cutting time is less than SCIThreshold Put cutting time as down record with down code "SCI"
						
						if DateDiff(second, @Sttime, @Ndtime) >0
						begin
					
							insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,WorkOrderNumber,PJCYear)
							values (2, @Mc , @Comp , @Opn , @Opr , 'SCI' ,DateName(year,@Sttime)+ '-' +DateName(month,@Sttime)+ '-' + DateName(day,@Sttime),@Sttime,DateName(year,@Ndtime)+ '-' +DateName(month,@Ndtime)+ '-' + DateName(day,@Ndtime),@Ndtime,0, DateDiff(second, @Sttime, @Ndtime) ,@Sttime,@WorkOrderNo,@Splstring3)
							
						end
						
						---on error go to error handler
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
						While @@TRANCOUNT <> 0
						   BEGIN
							--On succesful insertion commit transaction
							COMMIT TRANSACTION
							---set the record status = 1 to indicate that is processed
							UPDATE rawdata  set status=1 where Slno=@Slno	
							END
						
						---Exit the loop and process next record
						 GOTO FETCHCURSOR	
						
						END
					
						IF  (DateDiff(second, @Sttime, @Ndtime)>@SCIThreshold AND DateDiff(second, @Sttime, @Ndtime)<=@DCLThreshold) and @DCLThreshold>0.0
						BEGIN
						
						BEGIN Transaction
					
						--IF cutting time duration lies between SCIThreshold and DCLThreshold then put load unload part as down record with downcode "DCLU"
						
						if datediff(second,DateAdd(second,-@Act_LoadUnload,@Sttime),@Sttime)>0.0
						begin
						
							insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,WorkOrderNumber,PJCYear)
							values (2, @Mc , @Comp , @Opn , @Opr , 'DCLU' ,DateName(year,DateAdd(second,-@Act_LoadUnload,@Sttime))+ '-' +DateName(month,DateAdd(second,-@Act_LoadUnload,@Sttime))+ '-' + DateName(day,DateAdd(second,-@Act_LoadUnload,@Sttime)),DateAdd(second,-@Act_LoadUnload,@Sttime),DateName(year,@Sttime)+ '-' +DateName(month,@Sttime)+ '-' + DateName(day,@Sttime),@Sttime,0,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@Sttime),@WorkOrderNo,@Splstring3)
						
						end
						
						 SET @Error = @@ERROR
						 IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
						--IF cutting time duration lies between SCIThreshold and DCLThreshold then put cutting time part as down record with downcode "DCL"
					
						if DateDiff(second, @Sttime, @Ndtime) >0
						begin
					
						insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,WorkOrderNumber,PJCYear)
						values (2, @Mc , @Comp , @Opn , @Opr , 'DCL' ,DateName(year,@Sttime)+ '-' +DateName(month,@Sttime)+ '-' + DateName(day,@Sttime),@Sttime,DateName(year,@Ndtime)+ '-' +DateName(month,@Ndtime)+ '-' + DateName(day,@Ndtime),@Ndtime,0, DateDiff(second, @Sttime, @Ndtime) ,@Sttime,@WorkOrderNo,@Splstring3)
						
						end
				
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
						
						--On succesful insertion commit transaction
						While @@TRANCOUNT <> 0
						   BEGIN
							COMMIT TRANSACTION
							---set the record status = 1 to indicate that is processed
							UPDATE rawdata  set status=1 where Slno=@Slno	
							END
						
						---Exit the loop and process next record
						 GOTO FETCHCURSOR	
						END
			End
			---ER0270 Till Here


			---Look for datatype 42 records in Autodata_ICD table within starttime and endtime for the cycle.
				--IF (select count(*) from Autodata_ICD where mc=@Mc and sttime>@Sttime and ndtime<@Ndtime )> 0 --ER0365
				IF (select count(*) from Autodata_ICD where mc=@Mc and sttime>=@Sttime and ndtime<@Ndtime )> 0 --ER0365
				BEGIN

					Update Autodata_ICD set sttime = Dateadd(ms,100,@sttime) where mc=@Mc and sttime=@Sttime ---DR0336 added

					--Calculate total IN CYCLE down within cycle
					SET @TotalDown = 0
					--SELECT @TotalDown = ISNULL((select SUM(DateDiff(second,sttime,ndtime)) from Autodata_ICD where mc=@Mc and sttime>@Sttime and ndtime<@Ndtime),0) --ER0365
					SELECT @TotalDown = ISNULL((select SUM(DateDiff(second,sttime,ndtime)) from Autodata_ICD where mc=@Mc and sttime>=@Sttime and ndtime<@Ndtime),0) --ER0365
					---select	@TotalDown,'total'
					
					---SELECT dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload  from Autodata_ICD where mc=@Mc and sttime>@Sttime and ndtime<@Ndtime
					IF ISNUMERIC(@LUforPrNxtToNODATA)=1
					SET @Act_LoadUnload=@LUforPrNxtToNODATA
				 	BEGIN TRANSACTION
				 	--Insert In production Cycle Record					---mod 10:insert work order number also.@WorkOrderNo
		        		---Insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
				         ---(@Datatype,@Mc , @Comp , @Opn, @Opr,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' +Datename(day,@Ndtime),@Ndtime, DateDiff(second, @Sttime, @Ndtime) - @TotalDown ,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@Sttime),@SplString1)
					Insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,WorkOrderNumber,PJCYear) values
				             (@Datatype,@Mc , @Comp , @Opn, @Opr,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' +Datename(day,@Ndtime),@Ndtime, DateDiff(second, @Sttime, @Ndtime) - @TotalDown ,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@Sttime),@SplString1,@WorkOrderNo,@Splstring3)
					---mod 10
				
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
					--INSERT 42 DATATYPE FROM AUTODATA_ICD AS DOWN INTO AUTODATA
					--DECLARE SD_ICDCUR CURSOR FOR SELECT dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload  from Autodata_ICD where mc=@Mc and sttime>@Sttime and ndtime<@Ndtime ---ER0365
					DECLARE SD_ICDCUR CURSOR FOR SELECT dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload  from Autodata_ICD where mc=@Mc and sttime>=@Sttime and ndtime<@Ndtime --ER0365
					OPEN SD_ICDCUR
					FETCH NEXT FROM SD_ICDCUR INTO @ICDdcode,@ICDstdate,@ICDsttime,@ICDnddate,@ICDndtime,@ICDcycletime,@ICDloadunload					
					WHILE @@FETCH_STATUS = 0
				    	BEGIN
						---mod 10:insert work order number also.@WorkOrderNo
						  --Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime)
						  ---SELECT  2, @Mc , @Comp , @Opn, @Opr ,@ICDdcode,@ICDstdate,@ICDsttime,@ICDnddate,@ICDndtime,@ICDcycletime,@ICDloadunload ,@ICDsttime
						
						--ER0365 Added From here
						 --Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber)
						 --SELECT  2, @Mc , @Comp , @Opn, @Opr ,@ICDdcode,@ICDstdate,@ICDsttime,@ICDnddate,@ICDndtime,@ICDcycletime,@ICDloadunload ,@ICDsttime,@WorkOrderNo 
						 ---DR0336 Commented From here
						--If @ICDsttime = @Sttime
						--BEGIN
						--	 Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber)
						--	 SELECT  2, @Mc , @Comp , @Opn, @Opr ,@ICDdcode,@ICDstdate,Dateadd(ms,100,@ICDsttime),@ICDnddate,@ICDndtime,@ICDcycletime,@ICDloadunload ,@ICDsttime,@WorkOrderNo 
						--END

						--Else 
						--BEGIN
						--	 Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber)
						--	 SELECT  2, @Mc , @Comp , @Opn, @Opr ,@ICDdcode,@ICDstdate,@ICDsttime,@ICDnddate,@ICDndtime,@ICDcycletime,@ICDloadunload ,@ICDsttime,@WorkOrderNo 
						--END
						--ER0365 Added Till here						
					    ---DR0336 Commented Till here

						--DR0336 From here
						Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber)
						SELECT  2, @Mc , @Comp , @Opn, @Opr ,@ICDdcode,@ICDstdate,@ICDsttime,@ICDnddate,@ICDndtime,@ICDcycletime,Datediff(s,@ICDsttime,@ICDndtime),@ICDsttime,@WorkOrderNo 
						--DR0336 Till here

						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER_FOR_SD_ICDCUR
						  FETCH NEXT FROM SD_ICDCUR INTO @ICDdcode,@ICDstdate,@ICDsttime,@ICDnddate,@ICDndtime,@ICDcycletime,@ICDloadunload					
					END
					close SD_ICDCUR
					deallocate SD_ICDCUR
					---Commit the transaction

					While @@TRANCOUNT <> 0
					BEGIN
						COMMIT TRANSACTION
						--UPDATE THE RAWDATA TABLE
						UPDATE rawdata  set status=1 where Slno=@Slno	
					END
					---Process next record
					GOTO FETCHCURSOR
					
				END

		END
		---mod 7
----------------------------------------------------------------------------------------------------		
		----Marks changes :: insert ONE ICD based on machining threshold
		IF @SplitPalletRecord = 'n' and @SupportsICDnDowns = 'n'
		    BEGIN
			
			  IF ISNUMERIC(@LUforPrNxtToNODATA)=1
			    SET @Act_LoadUnload=@LUforPrNxtToNODATA
			  -- (@MachiningTimeThreshold>60)
			  If  (DateDiff(second, @Sttime, @Ndtime) > @MachiningTimeThreshold) and (@MachiningTimeThreshold>60) AND ( @OrgMachiningTimeThreshold > 0.0)
			     BEGIN
				   --INSERT PRODUCTION RECORD
				    BEGIN TRANSACTION
				    ---mod 10:insert work order number also.@WorkOrderNo
			            --Insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
					--(@DataType,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' +Datename(day,@Ndtime),@Ndtime,@MachiningTime,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@Sttime),@SplString1)
				     Insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,WorkOrderNumber,PJCYear) values
						(@DataType,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' +Datename(day,@Ndtime),@Ndtime,@MachiningTime,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@Sttime),@SplString1,@WorkOrderNo,@Splstring3)
				    --mod 10
				
				
				   SET @Error = @@ERROR
				   IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			
				   --Insert In Cycle Down Record
			           If @MachiningTime>0
				      BEGIN
					    set @Sttime = DateAdd(second,@MachiningTime,@Sttime)
					    set @ndtime = Dateadd(second,-1,@ndtime)
					    ---mod 10:insert work order number also.@WorkOrderNo
					    ---insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime)
					    ---values (2, @Mc , @Comp , @Opn , @Opr , 'McTI' ,DateName(year,@Sttime)+ '-' +DateName(month,@Sttime)+ '-' + DateName(day,@Sttime),@Sttime,DateName(year,@Ndtime)+ '-' +DateName(month,@Ndtime)+ '-' + DateName(day,@Ndtime),@Ndtime,0, DateDiff(second, @Sttime, @Ndtime) ,@Sttime)
					    insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber,PJCYear)
					    values (2, @Mc , @Comp , @Opn , @Opr , 'McTI' ,DateName(year,@Sttime)+ '-' +DateName(month,@Sttime)+ '-' + DateName(day,@Sttime),@Sttime,DateName(year,@Ndtime)+ '-' +DateName(month,@Ndtime)+ '-' + DateName(day,@Ndtime),@Ndtime,0, DateDiff(second, @Sttime, @Ndtime) ,@Sttime,@WorkOrderNo,@Splstring3)
					    --mod 10
				      END
				    SET @Error = @@ERROR
				    IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			      END 	
			 Else
			      BEGIN
			            --INSET PRODUCTION RECORD
				     BEGIN TRANSACTION
				     ---mod 10:insert work order number also.@WorkOrderNo
			             ---Insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						--(@DataType,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' +Datename(day,@Ndtime),@Ndtime, DateDiff(second, @Sttime, @Ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@Sttime),@SplString1 )
				      Insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,workordernumber,PJCYear) values
						(@DataType,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' +Datename(day,@Ndtime),@Ndtime, DateDiff(second, @Sttime, @Ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@Sttime),@SplString1,@WorkOrderNo ,@Splstring3)
				     ---mod 10
				
				     SET @Error = @@ERROR
				     IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			      END
		    END--IF(N,N)
--------------------------------------------------------------------------------------------------
--split the pallet but record only one 'Unknown' down outside of the cycle
		-- |-----------------------------------------| -- original cycle as it happened
		-- |----P--||----P---||-----P----||----D-----| -- inserts into autodata
		
		IF @SplitPalletRecord = 'y' and @SupportsICDnDowns = 'u'
		Begin
			
			--SET @sttime = @startdate + ' '  + @starttime
			--SET @ndtime = @enddate + ' ' + @endtime
						
			IF ISNUMERIC(@LUforPrNxtToNODATA)=1
			SET @Act_LoadUnload=@LUforPrNxtToNODATA
		        If Datediff(second,@sttime,@ndtime) > 0
		        BEGIN
				  If  (DateDiff(second, @sttime, @ndtime) > @MachiningTimeThreshold) and (@MachiningTimeThreshold>60) AND ( @OrgMachiningTimeThreshold > 0.0)
				  Begin
					    BEGIN TRANSACTION
					-- Count Cycle time ( Difference between start time and end time )
					SET @Cycle = DateDiff(second, @sttime, @ndtime)
					SET @ICDinCycle = @Cycle- @MachiningTime
			        	--count incremental time for each component and round the fractional part of seconds e.g.-- 6.6 sec = 7 sec
			        	SET @Increment = @MachiningTime / @Splstring1
			       		 --Loop through 1 to Pallet count(Number of Component in a Pallet) and insert production record
					--with actual cutting time equal to std Cutting time
			       		 Declare @i As Integer
					SET @i = 1
				
					WHILE @i <=  @Splstring1
					 BEGIN
						SET @dtStartTime = @sttime
						SET @ndtime = DateAdd(s, @Increment, @sttime)
						---mod 10:insert work order number also.@WorkOrderNo
			           		---insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
							--(@DataType,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1)
						insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,workordernumber,PJCYear) values
							(@DataType,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1,@WorkOrderNo,@Splstring3)
						--mod 10
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			     			SET @sttime = @ndtime
			          		SET @Act_LoadUnload = 0
			       			SET @i = @i + 1
					  END--while
					
					--SET @sttime = @startdate + ' '  + @starttime
					--SET @ndtime = @enddate + ' ' + @endtime
					If  (DateDiff(second, @sttime, @ndtime)) > @MachiningTime
					  begin
						
						set @sttime = DateAdd(second,@MachiningTime,@sttime)
						---mod 10:insert work order number also.@WorkOrderNo
						---insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
						---(2,@Mc ,@Comp ,@Opn ,@Opr ,'UNKNOWN',Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,0,@ICDinCycle ,@sttime)
						insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber) values
						(2,@Mc ,@Comp ,@Opn ,@Opr ,'UNKNOWN',Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,0,@ICDinCycle ,@sttime,@WorkOrderNo)
						---mod 10
					  End	
				END--if
			  Else	
	            Begin
				--SET @sttime = @startdate + ' '  + @starttime
				--SET @ndtime = @enddate + ' ' + @endtime
				    BEGIN TRANSACTION
				IF ISNUMERIC(@LUforPrNxtToNODATA)=1
				SET @Act_LoadUnload=@LUforPrNxtToNODATA
		
				SET @Cycle = DateDiff(second, @sttime, @ndtime)
			    	SET @Increment = @Cycle / @Splstring1
			
				SET @i = 1
				--For uneven division of cycletime by pallet.
				WHILE @i <= @Cycle - (@Splstring1 * @Increment)
				BEGIN
					SET @dtStartTime = @sttime
			           	SET @ndtime = DateAdd(second, @Increment + 1, @sttime)
			           	---mod 10:insert work order number also.@WorkOrderNo
					---insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						--(@DataType,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1)
					insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,workordernumber,PJCYear) values
						(@DataType,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1,@WorkOrderNo,@Splstring3)
					--mod 10
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
					SET @sttime = @ndtime
			          	SET @Act_LoadUnload = 0
			       		SET @i = @i + 1
				END--while1
				SET @i = @Cycle - (@Splstring1 * @Increment) + 1
				WHILE @i <=  @Splstring1
				BEGIN
					SET @dtStartTime = @sttime
			           	SET @ndtime = DateAdd(s, @Increment, @sttime)
					---mod 10:insert work order number also.@WorkOrderNo
			           	---insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
						--(@DataType,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1) --dr0119
					insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,workordernumber,PJCYear) values
						(@DataType,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1,@WorkOrderNo,@Splstring3) --dr0119
					---mod 10
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			     		SET @sttime = @ndtime
			          	SET @Act_LoadUnload = 0
			       		SET @i = @i + 1
				END--while2
			   End--else
			  End--if
		End--if
--------------------------------------------------------------------------------------------------
		--Marks changes :: put n downs that came along the prodn record and out one prodn record
		IF @SplitPalletRecord = 'n' and @SupportsICDnDowns = 'y'
		    BEGIN
			
			--Calculate total down within cycle
			SET @TotalDown = 0
			SELECT @TotalDown = ISNULL(SUM(DateDiff(second,DownStartDate,DownEndDate)),0) FROM #SD_DownTime
			
			--INSERT n DOWN RECORDS if any
			If @TotalDown > 0
			BEGIN
				  BEGIN TRANSACTION
				DECLARE SD_CURDOWN CURSOR FOR SELECT  ProdDownCode,DownStartDate,DownEndDate FROM #SD_DownTime
				OPEN SD_CURDOWN
				FETCH NEXT FROM SD_CURDOWN INTO @downcode,@dtStartDateTime, @dtEndDateTime
				WHILE @@FETCH_STATUS = 0
				    BEGIN
					
					  SET @Act_LoadUnload = DATEDiff(second,@dtStartDateTime,@dtEndDateTime)
					  -- Validate DownCode
					  SET @Comp_Down = 'UNKNOWN'
					  IF NOT Exists (select  interfaceid from dbo.downcodeinformation where InterfaceID= @downcode)
					
					  SET @downcode = @Comp_Down
					  ---mod 10:insert work order number also.@WorkOrderNo
					  ---Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime)
							--values (2, @Mc , @Comp , @Opn, @Opr , @downcode ,DateName(year,@dtStartDateTime)+ '-' +DateName(month,@dtStartDateTime)+ '-' + DateName(day,@dtStartDateTime),@dtStartDateTime,DateName(year,@dtEndDateTime)+ '-' +DateName(month,@dtEndDateTime)+ '-' + DateName(day,@dtEndDateTime),@dtEndDateTime,0, @Act_LoadUnload ,@dtStartDateTime)
					  Insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber)
							values (2, @Mc , @Comp , @Opn, @Opr , @downcode ,DateName(year,@dtStartDateTime)+ '-' +DateName(month,@dtStartDateTime)+ '-' + DateName(day,@dtStartDateTime),@dtStartDateTime,DateName(year,@dtEndDateTime)+ '-' +DateName(month,@dtEndDateTime)+ '-' + DateName(day,@dtEndDateTime),@dtEndDateTime,0, @Act_LoadUnload ,@dtStartDateTime,@WorkOrderNo)
					  ---mod 10
					
					
					  SET @Error = @@ERROR
					  IF @Error <> 0 GOTO ERROR_HANDLER_FORCURDOWN
					  FETCH NEXT FROM SD_CURDOWN INTO @downcode,@dtStartDateTime, @dtEndDateTime
				    END
				
			END
			IF ISNUMERIC(@LUforPrNxtToNODATA)=1
				SET @Act_LoadUnload=@LUforPrNxtToNODATA
			 	BEGIN TRANSACTION
			 --Insert In production Cycle Record
				---mod 10:insert work order number also.@WorkOrderNo
	        		---Insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
			             ---(@Datatype,@Mc , @Comp , @Opn, @Opr,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' +Datename(day,@Ndtime),@Ndtime, DateDiff(second, @Sttime, @Ndtime) - @TotalDown ,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@Sttime),@SplString1)
				Insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,workordernumber,PJCYear) values
			             (@Datatype,@Mc , @Comp , @Opn, @Opr,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' +Datename(day,@Ndtime),@Ndtime, DateDiff(second, @Sttime, @Ndtime) - @TotalDown ,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@Sttime),@SplString1,@WorkOrderNo,@Splstring3)
			
				---mod 10
			
				SET @Error = @@ERROR
				IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			
	            END--if(n,y)
-------------------------------------------------------------------------------------------------------
--split the pallet and insert MCTI record if cycletime exceeds machiningtimethreshold
	-- |-----------------------------------------| -- original cycle as it happened
	-- |---P---||---P----||---P-----||----P-----| -- inserts into autodata
	--     |-m-|     |-m-|      |-m-|       |-m-|--insert mcti record if cycle time exceeds machiningtimethreshold
		IF @SplitPalletRecord = 'y' and @SupportsICDnDowns = 'n'
		BEGIN
			--set @sttime=@startdate + ' ' + @starttime
			--set @ndtime=@enddate + ' ' + @endtime
			
			--Declare @Increment as integer
			--Declare @i as integer
			
			If isnumeric(@LUforPrNxtToNoDATA)=1
			Set @Act_LoadUnload=@LUforPrNxtToNoDATA	
			print 'sv'
			print  @Act_loadunload
			If Datediff(second,@sttime,@ndtime)>0 
			 Begin
				If (DateDiff(second, @sttime, @ndtime) > @MachiningTimeThreshold) and (@MachiningTimeThreshold>60) AND ( @OrgMachiningTimeThreshold > 0.0) 
				  begin
					    BEGIN TRANSACTION
						set @MachiningTime= @MachiningTime/@Splstring1
						print 'swathi'
						--Set @Cycle=Datediff(second,@sttime,@ndtime)--ER0371
						Set @Cycle=[dbo].[f_GetDatediffms](@sttime,@ndtime) --ER0371
						print @cycle
						Set @Increment=@Cycle/@Splstring1
						print @Increment
						Set @i=1
						WHILE @i <= @Cycle - (@Splstring1 * @Increment)
						BEGIN
							print '1st while'
							SET @dtStartTime = @sttime
							--SET @ndtime = DateAdd(second, @Increment + 1, @sttime) --ER0371
							SET @ndtime = DateAdd(ms, @Increment + 1, @sttime) --ER0371
							print @sttime
							 print @ndtime   
							---mod 10:insert work order number also.@WorkOrderNo	
							---insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
							--(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,@MachiningTime,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1)
							insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,workordernumber,PJCYear) values
							--(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,@MachiningTime,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1,@WorkOrderNo) --ER0371
							(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,@MachiningTime,@Act_LoadUnload ,DateAdd(ms,-(@Act_LoadUnload*1000),@dtStartTime),1,@WorkOrderNo,@Splstring3) --ER0371
						   	---mod 10
						   					
							SET @Error = @@ERROR
							IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
					
							If @MachiningTime>0
							BEGIN
								--ER0370 From Here
								--set @sttime = DateAdd(second,@MachiningTime,@sttime)
								--set @sttime = DateAdd(second,-1,@sttime)
								--set @ndtime = Dateadd(second,-1,@ndtime)
								set @sttime = DateAdd(ms,@MachiningTime*1000,@sttime)
								set @sttime = DateAdd(ms,-1,@sttime)
								set @ndtime = Dateadd(ms,-1,@ndtime)
								--ER0370 Till Here
								---mod 10:insert work order number also.@WorkOrderNo	
								---insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime)
								--values (2, @Mc , @Comp , @Opn , @Opr , 'McTI' ,DateName(year,@sttime)+ '-' +DateName(month,@sttime)+ '-' + DateName(day,@sttime),@sttime,DateName(year,@ndtime)+ '-' +DateName(month,@ndtime)+ '-' + DateName(day,@ndtime),@ndtime,0, DateDiff(second, @sttime, @ndtime) ,@sttime)
								insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber)
								values (2, @Mc , @Comp , @Opn , @Opr , 'McTI' ,DateName(year,@sttime)+ '-' +DateName(month,@sttime)+ '-' + DateName(day,@sttime),@sttime,DateName(year,@ndtime)+ '-' +DateName(month,@ndtime)+ '-' + DateName(day,@ndtime),@ndtime,0, DateDiff(second, @sttime, @ndtime) ,@sttime,@WorkOrderNo) 
								---mod 10
							END
											
							SET @Error = @@ERROR
							IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
							 --SET @sttime = dateadd(second,1,@ndtime)--ER0371
							 SET @sttime = dateadd(ms,1,@ndtime) --ER0371
							 SET @Act_LoadUnload = 0
			       			 SET @i = @i + 1
						  END--WHILE
				
						SET @i = @Cycle - (@Splstring1 * @Increment) + 1
						WHILE @i <=  @Splstring1
						BEGIN
							print '2nd while'
							SET @dtStartTime = @sttime
							--SET @ndtime = DateAdd(s, @Increment, @sttime) --ER0371
							SET @ndtime = DateAdd(ms, @Increment, @sttime) --ER0371
							print @sttime
				            print @ndtime   
								---mod 10:insert work order number also.@WorkOrderNo	
								---insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
								---(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,@MachiningTime,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1)
								insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,workordernumber,PJCYear) values
								--(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,@MachiningTime,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1,@WorkOrderNo)--ER0371
								(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,@MachiningTime,@Act_LoadUnload ,DateAdd(ms,-(@Act_LoadUnload*1000),@dtStartTime),1,@WorkOrderNo,@Splstring3)--ER0371
								---mod 10
						 		SET @Error = @@ERROR
								IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
								
								If @MachiningTime>0
								 BEGIN

									 set @sttime = DateAdd(ms,@MachiningTime * 1000,@sttime)
									 set @ndtime = Dateadd(ms,-1,@ndtime)
									 set @sttime = DateAdd(ms,-1,@sttime)

									---mod 10:insert work order number also.@WorkOrderNo	
									--- insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime)
									--- values (2, @Mc , @Comp , @Opn , @Opr , 'McTI' ,DateName(year,@sttime)+ '-' +DateName(month,@sttime)+ '-' + DateName(day,@sttime),@sttime,DateName(year,@ndtime)+ '-' +DateName(month,@ndtime)+ '-' + DateName(day,@ndtime),@ndtime,0, DateDiff(second, @sttime, @ndtime) ,@sttime)
									 insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber)
									 values (2, @Mc , @Comp , @Opn , @Opr , 'McTI' ,DateName(year,@sttime)+ '-' +DateName(month,@sttime)+ '-' + DateName(day,@sttime),@sttime,DateName(year,@ndtime)+ '-' +DateName(month,@ndtime)+ '-' + DateName(day,@ndtime),@ndtime,0, DateDiff(second, @sttime, @ndtime) ,@sttime,@WorkOrderNo)									 ---mod 10
								 END	

							--SET @sttime = dateadd(second,1,@ndtime) --ER0371
							SET @sttime = dateadd(ms,1,@ndtime) --ER0371
			          		SET @Act_LoadUnload = 0
			       			SET @i = @i + 1	
						END--while2			
				    End--if
				 Else
				  Begin
					BEGIN TRANSACTION			
					--SET @Cycle = DateDiff(second, @sttime, @ndtime) --ER0371
					SET @Cycle = [dbo].[f_GetDatediffms](@sttime, @ndtime) --ER0371
					SET @Increment = @Cycle / @Splstring1
				
					SET @i = 1
					--For uneven division of cycletime by pallet.
					WHILE @i <= @Cycle - (@Splstring1 * @Increment)
					BEGIN
						print '3rd while'
						SET @dtStartTime = @sttime
			           	--SET @ndtime = DateAdd(second, @Increment + 1, @sttime) --ER0371
						SET @ndtime = DateAdd(ms, @Increment + 1, @sttime) --ER0371
						print @sttime
				        print @ndtime   	
						---mod 10:insert work order number also.@WorkOrderNo	
						--insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
							--(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1)
						insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,Workordernumber,PJCYear) values
					   -- (@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1,@WorkOrderNo)  --ER0371
					    (@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(ms,-(@Act_LoadUnload*1000),@dtStartTime),1,@WorkOrderNo,@Splstring3) --ER0371
						---mod 10
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
						SET @sttime = @ndtime
			          		SET @Act_LoadUnload = 0
			       			SET @i = @i + 1
					END--while1
					SET @i = @Cycle - (@Splstring1 * @Increment) + 1
					WHILE @i <=  @Splstring1
					BEGIN
						print '4th while'
						SET @dtStartTime = @sttime
			           	--SET @ndtime = DateAdd(s, @Increment, @sttime) --ER0371
						SET @ndtime = DateAdd(ms, @Increment, @sttime) --ER0371
						---mod 10:insert work order number also.@WorkOrderNo	
			           		---insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
							--(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1)----dr0119
						insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount,Workordernumber,PJCYear) values
						--(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1,@WorkOrderNo)----dr0119  --ER0371
						(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@sttime) + '-' + Datename(month,@sttime) + '-' + Datename(day,@sttime),@sttime,Datename(year,@ndtime) + '-' + Datename(month,@ndtime) + '-' +Datename(day,@ndtime),@ndtime,DateDiff(second, @sttime,@ndtime),@Act_LoadUnload ,DateAdd(ms,-(@Act_LoadUnload*1000),@dtStartTime),1,@WorkOrderNo,@Splstring3)----dr0119  --ER0371
						---mod 10
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			     			SET @sttime = @ndtime
			          		SET @Act_LoadUnload = 0
			       			SET @i = @i + 1
					END--while2
				   End--else
		  End--if
End--IF
-------------------------------------------------------------------------------------------------------
	/*	IF @SplitPalletRecord = 'y' and @SupportsICDnDowns = 'n'
		    BEGIN
		
			--Calculate total down within cycle
			SET @TotalDown = 0
			SELECT @TotalDown = ISNULL(SUM(DateDiff(second,DownStartDate,DownEndDate)),0) FROM #SD_DownTime
		
			-- Calculate Actual cycle time
			SET @DownTimePerCycle = @TotalDown / @SplString1
			
			
			IF ISNUMERIC(@LUforPrNxtToNODATA)=1
			SET @Act_LoadUnload=@LUforPrNxtToNODATA
		        If Datediff(second,@Sttime,@Ndtime) > 0
		           BEGIN
				   BEGIN TRANSACTION
			         -- Count Cycle time ( Difference between start time and end time )
				 SET @Cycle = DateDiff(second, @Sttime, @Ndtime)
			         --count incremental time for each component and round the fractional part of seconds e.g.-- 6.6 sec = 7 sec
			         SET @Increment = @Cycle / @SplString1
			         --Loop through 1 to Pallet count(Number of Component in a Pallet) and insert production record
			
				 SET @i = 1
				
				 WHILE @i <= @Cycle - (@SplString1 * @Increment)
				      BEGIN
						SET @dtStartTime = @Sttime
				           	SET @Ndtime = DateAdd(second, @Increment + 1, @Sttime)
				           	
						insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
							(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' +Datename(day,@Ndtime),@Ndtime,DateDiff(second, @Sttime,@Ndtime)-@DownTimePerCycle,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1)
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
						SET @Sttime = @Ndtime
				          	SET @Act_LoadUnload = 0
				       		SET @i = @i + 1
				       END--while
				
				SET @i = @Cycle - (@SplString1 * @Increment) + 1
				
				WHILE @i <=  @SplString1
				       BEGIN
						SET @dtStartTime = @Sttime
				           	SET @Ndtime = DateAdd(s, @Increment, @Sttime)
				
				           	insert into autodata (datatype,mc,comp,opn,opr,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,PartsCount) values
							(@Datatype,@Mc ,@Comp ,@Opn ,@Opr ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' +Datename(day,@Ndtime),@Ndtime,DateDiff(second, @Sttime,@Ndtime)-@DownTimePerCycle,@Act_LoadUnload ,DateAdd(second,-@Act_LoadUnload,@dtStartTime),1)
						SET @Error = @@ERROR
						IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
				     		SET @Sttime = @Ndtime
				          	SET @Act_LoadUnload = 0
				       		SET @i = @i + 1
					END
			   END
	          END--if(y,n)*/
	
	    While @@TRANCOUNT <> 0
		BEGIN
			COMMIT TRANSACTION
			--UPDATE THE RAWDATA TABLE
			UPDATE rawdata  set status=1 where Slno=@Slno	
		END
	
END --for Data Type 1 record
--**************************************************************************************************
--Type 2 record
--Down record
---------------------------------------------------------------------------------------------------
If @Datatype = 2 	
	BEGIN	
	 	Declare @ndtimedown as datetime
		
		SET @downcode=@SplString2
		--START Validate Downcodes
		SET @Comp_Down = 'UNKNOWN'
		IF NOT Exists (select  interfaceid from dbo.downcodeinformation where InterfaceID= @downcode)
		SET @downcode = @Comp_Down
		SET @ndtimedown = NULL;
		select @ndtimedown=(select endtime from autodata_maxtime where machineid=@Mc)	
		--select @ndtimedown = (select top 1 ndtime from autodata where mc=@Mc and ndtime<= @Sttime order by id desc)
		---mod 9 introduce MCO in above query
		-- mod 8: LU Threshold : Starts
--		select @stndloadunload = ISNULL(loadunload,0)
--		from componentoperationpricing inner join componentinformation on componentoperationpricing.componentid=componentinformation.componentid
--		where componentinformation.interfaceid=@Comp and componentoperationpricing.interfaceid=@Opn
		---mod 8
		select @stndloadunload = ISNULL(loadunload,0) from componentoperationpricing
			inner join componentinformation on componentoperationpricing.componentid=componentinformation.componentid
			inner join machineinformation on machineinformation.machineid = componentoperationpricing.machineid
			where componentinformation.interfaceid=@Comp and componentoperationpricing.interfaceid=@Opn
			and machineinformation.Interfaceid = @Mc
		---mod 9
		   If Isdate(@ndtimedown) = 1
		      BEGIN
				BEGIN TRANSACTION	
				--mod 8: Check diff between last record endtime and current records starttime is greater than @stndloadunload
				
				IF DateDiff(second, @ndtimedown, @Sttime)> @stndloadunload
				BEGIN
					---Insert one NO_DATA record from last records end time and current records starttime
				   	SET @Act_LoadUnload = DateDiff(second, @ndtimedown, @Sttime)
					---mod 10:insert work order number also.@WorkOrderNo
				  	--- insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
			           	---(@Datatype, @Mc , @Comp , @Opn , @Opr ,'NO_DATA' , Datename(year,@ndtimedown) + '-' + Datename(month,@ndtimedown) + '-' + Datename(day,@ndtimedown),@ndtimedown ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) , @Sttime  ,0, @Act_LoadUnload ,@ndtimedown)
					insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber,PJCYear) values
			           	(@Datatype, @Mc , @Comp , @Opn , @Opr ,'NO_DATA' , Datename(year,@ndtimedown) + '-' + Datename(month,@ndtimedown) + '-' + Datename(day,@ndtimedown),@ndtimedown ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) , @Sttime  ,0, @Act_LoadUnload ,@ndtimedown,@WorkOrderNo,@Splstring3)
					---mod 10
				
					--Insert current down record
				   	SET @Act_LoadUnload = DateDiff(second,  @Sttime,@Ndtime)
					---mod 10:insert work order number also.@WorkOrderNo	
				   	--insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
			           	--(@Datatype, @Mc , @Comp , @Opn , @Opr ,@downcode ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime , Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime) ,@Ndtime ,0, @Act_LoadUnload ,@Sttime)
					insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber,PJCYear) values
			           	(@Datatype, @Mc , @Comp , @Opn , @Opr ,@downcode ,Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime),@Sttime , Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime) ,@Ndtime ,0, @Act_LoadUnload ,@Sttime,@WorkOrderNo,@Splstring3)
					---mod 10
				
				END 				ELSE -- If the diff between last record endtime and current records starttime is not greater than @stndloadunload
				BEGIN
				---mod 8
			   		SET @Act_LoadUnload = DateDiff(second, @ndtimedown, @Ndtime)
					---mod 10:insert work order number also.@WorkOrderNo
			   		--insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
			           		--(@Datatype, @Mc , @Comp , @Opn , @Opr ,@downcode , Datename(year,@ndtimedown) + '-' + Datename(month,@ndtimedown) + '-' + Datename(day,@ndtimedown),@ndtimedown ,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime) , @Ndtime ,0, @Act_LoadUnload ,@ndtimedown)
					insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber,PJCYear) values
			           		(@Datatype, @Mc , @Comp , @Opn , @Opr ,@downcode , Datename(year,@ndtimedown) + '-' + Datename(month,@ndtimedown) + '-' + Datename(day,@ndtimedown),@ndtimedown ,Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime) , @Ndtime ,0, @Act_LoadUnload ,@ndtimedown,@WorkOrderNo,@Splstring3)
					--mod 10
					SET @Error = @@ERROR
					IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
				---mod 8
				END
				---mod 8
		      END	
		  Else
		      BEGIN
				BEGIN TRANSACTION
			    	SET @Act_LoadUnload = DateDiff(second, @Sttime,@Ndtime)
				---mod 10:insert work order number also.@WorkOrderNo
			     	---insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
			    		--(@Datatype, @Mc , @Comp , @Opn , @Opr ,@downcode, Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) , @Sttime , Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime) ,@Ndtime,0,  @Act_LoadUnload ,@Sttime)
				insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber,PJCYear) values
			    		(@Datatype, @Mc , @Comp , @Opn , @Opr ,@downcode, Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) , @Sttime , Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime) ,@Ndtime,0,  @Act_LoadUnload ,@Sttime,@WorkOrderNo,@Splstring3)
				---mod 10
				SET @Error = @@ERROR
				IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
		      END
		
		while @@TRANCOUNT <> 0
		BEGIN	
			COMMIT TRANSACTION
			UPDATE rawdata  set status=1 where Slno=@Slno	
	 	END
			
END--IFTYPE2	
--************************************************************************************************
--TYPE 4 RECORD
--TOOL CHANGE RECORD
--------------------------------------------------------------------------------------------------
	If @Datatype = 4
	    BEGIN
		 If (IsDate(@Sttime) = 1 And IsDate(@Ndtime) = 1)
		    AND Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @Mc)
		       BEGIN TRANSACTION
			 INSERT INTO AutodataDetails (Machine, RecordType, Starttime,Endtime,DetailNumber)
			   VALUES(
					@Mc ,
					@Datatype,
					@Sttime,
					@Ndtime,
					@Splstring1
			          )
		
		SET @Error = @@ERROR
		IF @Error <> 0
		   BEGIN	
			GOTO ERROR_HANDLER_FOR_ALLTYPES
		   END
	--DR0292 Added From Here.
		ELSE
		   BEGIN
			
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting Spinddle record(Date or machine id problem)',getdate())
			UPDATE rawdata  set status=12 where mc=@Mc and sttime=@Sttime 	
			GOTO FETCHCURSOR
		   END
		--DR0292 Added Till Here.
		While @@TRANCOUNT <> 0
		   BEGIN	
			--print 'in type 4'
			COMMIT TRANSACTION
			UPDATE rawdata  set status=1 where Slno=@Slno	
	 	   END
	    End--TYPE 4 END
--**************************************************************************************************
--TYPE 5 RECORD
--TOOL DIR RECORD
----------------------------------------------------------------------------------------------------
	If @Datatype = 5
	    BEGIN	
		If IsDate(@Sttime) = 1   AND Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @Mc)
		   BEGIN
			 BEGIN TRANSACTION
	    		INSERT INTO AutodataDetails  (Machine, RecordType, Starttime, DetailNumber)
		        VALUES(
				@Mc ,
				@Datatype ,
				@Sttime,
				@Splstring1
			     )

				  update SpcAutodata set toolchangetime=@Sttime
                                   From(
                                                Select max(ID) as ID from SPCAutodata A1
                                                inner join (Select Mc,Max(TimeStamp) as TimeStamp from SpcAutodata where Mc=@Mc and Timestamp<=@Sttime
                                                Group by MC) A2 on A1.Mc=A2.Mc and A1.Timestamp=A2.TimeStamp
                                                where A1.MC=@Mc
                                   )T1 inner join SpcAutodata T2 on T1.ID=T2.ID                


			SET @Error = @@ERROR
			IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
		   END
		ELSE
		   BEGIN
			
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting Spinddle record(Date or machine id problem)',getdate())
			UPDATE rawdata  set status=12 where mc=@Mc and sttime=@Sttime 	
			GOTO FETCHCURSOR
		   END
	  	While @@TRANCOUNT <> 0
		   BEGIN	
			
			COMMIT TRANSACTION
			UPDATE rawdata  set status=1 where Slno=@Slno	
	 	   END
	
		
	END --TYPE 5 RECORD
--*******************************************************************************************
--Type 6 record
--Alarm No records
----------------------------------------------------------------------------------------------
If @Datatype = 6
BEGIN

		 --ER0354 Commented From here
--	     If (IsDate(@Sttime) = 1)
--		 BEGIN
--		 BEGIN TRANSACTION
--				WHILE CHARINDEX('P',@Splstring2,1) >= 1
--				BEGIN	
--			 		if CHARINDEX('P',@Splstring2,2) >= 1
--					   BEGIN
--						
--						SET @AlarmNo_Dec = CAST(SUBSTRING(@Splstring2,2,CHARINDEX('P',@Splstring2,2) - 2) as Numeric(38,2))
--				  		SET @Splstring2 = SUBSTRING(@Splstring2,CHARINDEX('P', @Splstring2,2),LEN(@Splstring2) - CHARINDEX('P', @Splstring2,2)+ 1)
--						INSERT INTO AutoDataAlarms (MachineID, AlarmNumber,Alarmtime,RecordType)
--						VALUES( @Mc , @AlarmNo_Dec,@Sttime, @Datatype)
--					   END
--					ELSE
--					   BEGIN
--						SET @AlarmNo_Dec = CAST(SUBSTRING(@Splstring2,2,LEN(@Splstring2)-1) as Numeric(38,2))
--						SET @Splstring2 = SUBSTRING(@Splstring2,2,LEN(@Splstring2)-1)
--						INSERT INTO AutoDataAlarms (MachineID, AlarmNumber,Alarmtime,RecordType)
--						 VALUES( @Mc , @AlarmNo_Dec,@Sttime, @Datatype)				
--					   END
--				 END
--				 SET @Error = @@ERROR
--	        	 IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
--	       END
--		ELSE
--		BEGIN
--			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting Alarm record(Date problem)',getdate())
--			UPDATE rawdata  set status=13 where mc=@Mc and sttime=@Sttime 	
--			GOTO FETCHCURSOR
--		END
		--ER0354 Commented Till here

--		ER0354 Added From here


	     If (IsDate(@Sttime) = 1)
		 BEGIN
				WHILE CHARINDEX('P',@Splstring2,1) >= 1
				BEGIN	
			 		if CHARINDEX('P',@Splstring2,2) >= 1
					BEGIN						
						SET @AlarmNo_Dec = CAST(SUBSTRING(@Splstring2,2,CHARINDEX('P',@Splstring2,2) - 2) as Numeric(38,2))
			  			SET @Splstring2 = SUBSTRING(@Splstring2,CHARINDEX('P', @Splstring2,2),LEN(@Splstring2) - CHARINDEX('P', @Splstring2,2)+ 1)
					END
					ELSE
					BEGIN
						SET @AlarmNo_Dec = CAST(SUBSTRING(@Splstring2,2,LEN(@Splstring2)-1) as Numeric(38,2))
						SET @Splstring2 = SUBSTRING(@Splstring2,2,LEN(@Splstring2)-1)		
					END

					If Not exists( Select * from autodataalarms where machineid=@Mc and alarmnumber=@AlarmNo_Dec and alarmtime=	@Sttime)	
					BEGIN
						BEGIN TRANSACTION
						INSERT INTO AutoDataAlarms (MachineID, AlarmNumber,Alarmtime,RecordType)
						VALUES( @Mc , @AlarmNo_Dec,@Sttime, @Datatype)		
					END
					ELSE
					BEGIN
						INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'SmartData-Duplicate Record Found From machine',getdate())
						SET @ERROR=@@ERROR
						SET @AppErrCode=5
						IF @ERROR <>0 or @AppErrCode=5 GOTO ERROR_HANDLER_GENERAL	
					END
				 END
	    END
		ELSE
		BEGIN
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting Alarm record(Date problem)',getdate())
			UPDATE rawdata  set status=13 where mc=@Mc and sttime=@Sttime 	
			GOTO FETCHCURSOR
		END

		SET @Error = @@ERROR
	    IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
--		ER0354 Added Till here

		While @@TRANCOUNT <> 0
		BEGIN	
		COMMIT TRANSACTION
		UPDATE rawdata  set status=1 where Slno=@Slno	
 	   END	
END

--*****************************************************************************************
--Type 42 record
--Insert In cycle or spindle DOWN record with same st and nd time as type 2 record
--------------------------------------------------------------------------------------------
	If @Datatype = 42 	
	BEGIN
		--print @SplString2
		--START Validate Downcodes
		SET @downcode=@SplString2
		SET @Comp_Down = 'UNKNOWN'
--		BEGIN TRANSACTION --DR0324 commented

		IF NOT Exists (select  interfaceid from dbo.downcodeinformation where InterfaceID= @downcode)
			SET @downcode = @Comp_Down
			--End Validate Downcodes
	        SET @Act_LoadUnload = DateDiff(second, @Sttime, @Ndtime)
			---mod 7(1):- Insert 42 datatype recorsd into autodata_ICD
			
		If Not exists( Select * from autodata_ICD where mc=@Mc and sttime =	@Sttime) --DR0324 Added
		Begin --DR0324 Added
			BEGIN TRANSACTION --DR0324 Added
			--insert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
			insert into autodata_ICD (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,PJCYear) values
			---mod 7(1)
			---mod 6 :- Insert datatype 42 record as type 42 only instead of datatype 2 record
			--(2, @Mc , @comp ,@opn , @opr , @downcode , Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) ,@Sttime , Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime) , @Ndtime ,0,  @Act_LoadUnload , @Sttime)
			(42, @Mc , @comp ,@opn , @opr , @downcode , Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) ,@Sttime , Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime) , @Ndtime ,0,  @Act_LoadUnload,@Splstring3)
			---mod 6
		
			--DR0324 Commented From here
--			Set @Error = @@Error
--			If @Error<>0
--			 Begin
--			   INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting In cycle or spindle DOWN record ',getdate())
--			   UPDATE rawdata  set status=12 where mc=@Mc and sttime=@Sttime
--			   GOTO FETCHCURSOR
--			 End
			--DR0324 Commented Till here
		END --DR0324 added
		--DR0324 added From Here
		ELSE
		Begin
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'SmartData-Duplicate Record Found From machine',getdate())
			SET @ERROR=@@ERROR
			SET @AppErrCode=5
			IF @ERROR <>0 or @AppErrCode=5 GOTO ERROR_HANDLER_GENERAL	
		END
 		--DR0324 added Till Here

		  --DR0324 Added From here
			Set @Error = @@Error
			If @Error<>0
			 Begin
			   INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting In cycle or spindle DOWN record ',getdate())
			   UPDATE rawdata  set status=12 where mc=@Mc and sttime=@Sttime
			   GOTO FETCHCURSOR
			 End
			--DR0324 Added Till here

		While @@TRANCOUNT <> 0
		   BEGIN	
			COMMIT TRANSACTION
			UPDATE rawdata  set status=1 where Slno=@Slno	
	 	   END	
	 END  --for type 42 record
/*****************************************************************************************
	Type 62 Record
	Insert In cycle or POWER_ON_OFF DOWN record with same st and nd time as type 2 record
*****************************************************************************************/
	If @Datatype = 62 -- ER0094	
	BEGIN
		SET @downcode = 'POWER_OFF'
		--End Validate Downcodes
	        SET @Act_LoadUnload = DateDiff(second, @Sttime, @Ndtime)
	    BEGIN TRANSACTION
		---mod 10:insert work order number also.@WorkOrderNo
		--inSert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime) values
			--(2, @Mc , @comp ,@opn , @opr , @downcode ,  Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) , @Sttime , Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime) ,@Ndtime ,0,  @Act_LoadUnload , @Sttime)
		inSert into autodata (datatype,mc,comp,opn,opr,dcode,stdate,sttime,nddate,ndtime,cycletime,loadunload,msttime,workordernumber) values
			(2, @Mc , @comp ,@opn , @opr , @downcode ,  Datename(year,@Sttime) + '-' + Datename(month,@Sttime) + '-' + Datename(day,@Sttime) , @Sttime , Datename(year,@Ndtime) + '-' + Datename(month,@Ndtime) + '-' + Datename(day,@Ndtime) ,@Ndtime ,0,  @Act_LoadUnload , @Sttime,@WorkOrderNo)
		---mod 10
		SET @Error = @@ERROR
		IF @Error <> 0
		BEGIN
		  INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error inserting Power Off record',getdate())
		  UPDATE rawdata  set status=14 where mc=@Mc and sttime=@Sttime
		  GOTO FETCHCURSOR		
		END
While @@TRANCOUNT <> 0
		   BEGIN	
			COMMIT TRANSACTION
			UPDATE rawdata  set status=1 where Slno=@Slno	
	 	   END	
	 END  --for type 62 record
--*****************************************************************************************
/******************************************************************************************
Processing Spindle Stop(40),spindle(Start),Optional Stop(70) and optional Start(71) records.
*******************************************************************************************/
	---mod 3 Introduce datatype 70 and 71 along with 40 and 41
	---If @Datatype = 40 or @Datatype = 41 -- ER0094
	If @Datatype = 40 or @Datatype = 41  or @Datatype = 70 or @Datatype = 71
	---mod 3
	BEGIN    		
		
		---mod 11:Commented below begin transaction		
		---BEGIN TRANSACTION
		--mod 11
	        If (IsDate(@Sttime) = 1 )
		AND Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @Mc)
		Begin
			
			---mod 11
			BEGIN TRANSACTION
			---mod 11
		        INSERT INTO AutodataDetails (Machine, RecordType, Starttime,DetailNumber)
			VALUES(
					@Mc ,
					@Datatype,
					@Sttime,
					@Splstring2
			         )
			
		End
		ELSE
		BEGIN
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error inserting SPINDLE ON/OFF record)',getdate())
			UPDATE rawdata  set status=12 where mc=@Mc and sttime=@Sttime 	
		   	GOTO FETCHCURSOR	
		END
		SET @Error = @@ERROR
		IF @Error <> 0
		BEGIN
		  INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error inserting Spindle record',getdate())
		  UPDATE rawdata  set status=12 where mc=@Mc and sttime=@Sttime
		  GOTO FETCHCURSOR		
		END
While @@TRANCOUNT <> 0
		   BEGIN	
			COMMIT TRANSACTION
			UPDATE rawdata  set status=1 where Slno=@Slno	
	 	   END	
	End--if 40 or 41 or 70 or 71
--********************************************************************************************************
--Non-Productive cycle
--********************************************************************************************************
if @Datatype=12
Begin
---mod 11:commented below BEGIN TRANSACTION
---Begin transaction
--mod 11
If (Isdate(@sttime)=1)	
Begin	
	   ---mod 11
	   BEGIN TRAnSACTION
	   ---mod 11
	   Insert into autodatadetails(machine,recordtype,starttime)
	   Values(@Mc,@Datatype,@sttime)
End	
Else
Begin
	INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error inserting record which indicates next record is Non-productive cycle',getdate())
	UPDATE rawdata  set status=14 where mc=@Mc and sttime=@Sttime 	
	GOTO FETCHCURSOR	
End		
	
	SET @Error = @@ERROR
	IF @Error <> 0
	BEGIN
		INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error inserting record which indicates next record is Non-productive cycle record',getdate())
		UPDATE rawdata  set status=14 where mc=@Mc and sttime=@Sttime 	
		 GOTO FETCHCURSOR	
	END
	 While @@TRANCOUNT <> 0
	 BEGIN	
			COMMIT TRANSACTION
			UPDATE rawdata  set status=1 where Slno=@Slno	
	  END	
End--datatype12
	
--******************************************************************************************
--*********************************************************
	If @Datatype = 60 or @Datatype = 61 -- ER0094
	BEGIN
	    		
		---mod 11:commented below BEGIN TRANSACTION
		---BEGIN TRANSACTION
		---mod 11
	        If (IsDate(@Sttime) = 1 )
		AND Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @Mc)
		begin
			---mod 11
			BEGIN TRANSACTION
			---mod 11
		        INSERT INTO AutodataDetails (Machine, RecordType, Starttime)
			VALUES(
					@Mc ,
					@Datatype,
					@Sttime					
			         )
		end
		ELSE
		BEGIN
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error inserting POWER_ON_OFF record',getdate())
		 	UPDATE rawdata  set status=14 where mc=@Mc and sttime=@Sttime 	
			GOTO FETCHCURSOR	
		END
		SET @Error = @@ERROR
		IF @Error <> 0
		BEGIN
		   INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error inserting POWER_ON_OFF record',getdate())
		   UPDATE rawdata  set status=14 where mc=@Mc and sttime=@Sttime 	
		   GOTO FETCHCURSOR	
		END
		   While @@TRANCOUNT <> 0
		   BEGIN	
			COMMIT TRANSACTION
			UPDATE rawdata  set status=1 where Slno=@Slno	
	 	   END	
	
	End
---------------------------------------------------------------------------------------------------
--Binary signal for HMI
	If @Datatype = 16
	Begin
			print 'record 16'
			---mod 11:commented below BEGIN TRANSACTION
			---Begin Transaction
			---mod 11

		If (IsDate(@Sttime) = 1) and (isnumeric(@SPLSTRING2))= 1 --DR0344
		BEGIN --DR0344
			If Not exists( Select * from autodataalarms where machineid=@Mc and alarmnumber=@SPLSTRING2 and alarmtime=	@Sttime)	
			Begin
				---mod 11
				BEGIN TRANSACTION
				---mod 11
				INSERT INTO AutoDataAlarms (MachineID, AlarmNumber,Alarmtime,RecordType)
				VALUES( @Mc , @SPLSTRING2,@Sttime, @Datatype)
			End
			--DR0324 Added From Here
			Else 
			BEGIN
		  			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'SmartData-Duplicate Record Found From machine',getdate())
					SET @ERROR=@@ERROR
					SET @AppErrCode=5
					IF @ERROR <>0 or @AppErrCode=5 GOTO ERROR_HANDLER_GENERAL	
			END
			--DR0324 Added Till Here
		END
		ELSE --DR0344
		Begin --DR0344
				   INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error inserting Binary Signal record',getdate())
				   --UPDATE rawdata  set status=14 where mc=@Mc and sttime=@Sttime 	 --DR0344
					UPDATE rawdata  set status=14 where Slno=@Slno	 	 --DR0344
				   GOTO FETCHCURSOR	
		END --DR0344

	   While @@TRANCOUNT <> 0
	   BEGIN	
		COMMIT TRANSACTION
		UPDATE rawdata  set status=1 where Slno=@Slno	
 	   END	
	End
-------------------------------------------------------------------------------------------------------

---mod 17
--Type 17 record
--Tool change records
---START-17-MC-PAlarmNumber-PStdate-PSttime-ToolCount-END
----------------------------------------------------------------------------------------------
If @Datatype = 17
BEGIN

/* ER0391 From here
	    If (IsDate(@Sttime) = 1)
	    BEGIN
		BEGIN TRANSACTION

				INSERT INTO AutoDataAlarms (MachineID, AlarmNumber,Alarmtime,RecordType,Actual) --ER0391
				VALUES( @Mc,@Splstring2,@Sttime,6,@Splstring1)		--ER0391
		
				SET @Error = @@ERROR
				IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
	    END
		ELSE
	    BEGIN
				INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting Alarm record(Date problem)',getdate())
			   UPDATE rawdata  set status=13 where mc=@Mc and sttime=@Sttime 	
			   GOTO FETCHCURSOR
	    END
	
	    While @@TRANCOUNT <> 0
	    BEGIN	
		COMMIT TRANSACTION
		UPDATE rawdata  set status=1 where Slno=@Slno	
 	    END	
ER0391 Till Here */

--ER0391 From here
	   If (IsDate(@Sttime) = 1)
	   BEGIN
			If Not exists( Select * from autodataalarms where machineid=@Mc and alarmnumber=@Splstring2 and alarmtime=@Sttime)	
			Begin
					BEGIN TRANSACTION
					INSERT INTO AutoDataAlarms (MachineID, AlarmNumber,Alarmtime,RecordType,Actual) 
					VALUES( @Mc,@Splstring2,@Sttime,6,@Splstring1)		
			END
			Else 
			BEGIN
	  				INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'SmartData-Duplicate Record Found From machine',getdate())
					SET @ERROR=@@ERROR
					SET @AppErrCode=5
					IF @ERROR <>0 or @AppErrCode=5 GOTO ERROR_HANDLER_GENERAL	
			END
	   END
	   ELSE
	   BEGIN
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting Alarm record(Date problem)',getdate())
			UPDATE rawdata  set status=13 where mc=@Mc and sttime=@Sttime 	
			GOTO FETCHCURSOR
	    END
	
		SET @Error = @@ERROR
	    IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES

	    While @@TRANCOUNT <> 0
	    BEGIN	
		COMMIT TRANSACTION
		UPDATE rawdata  set status=1 where Slno=@Slno	
 	    END	

--ER0391 Till here

END
-----------------------------------------------------------------------------------------------------------
---mod 17

------------------------------------ NR0093 ADDED FROM HERE --------------------------------------------
IF @Datatype=31
BEGIN

Declare @BatchTS as datetime
Declare @BatchID as int
Declare @ID as Bigint
Declare @Samplesize as int,@Threshold as int

	--If (IsDate(@Sttime) = 1) --DR0344
	If (IsDate(@Sttime) = 1) and (isnumeric(@SPLSTRING2))= 1 --DR0344
	BEGIN

		BEGIN TRANSACTION

		Select @ID=0
		Select @ID = ISNULL(MAX(ID),0) from SPCAutodata where mc=@mc and Comp=@comp and opn=@opn and Dimension=@splstring3 

		Select @BatchTS = ''
		Select @BatchTS = ISNULL([BatchTS],'1900-01-01') from SPCAutodata where ID=@ID

		select @BatchID= 0
		Select @BatchID = ISNULL(Count(*),0) from SPCAutodata where mc=@mc and Comp=@comp and opn=@opn and Dimension=@splstring3 and [batchTS]=@BatchTS

		--/*------- IgnoreForCPCPK calculation  12-Apr-2022---------*/
		--Declare @DefaultIgnoreForCPCPKCount int
		--Set @DefaultIgnoreForCPCPKCount=5
		--Select  @DefaultIgnoreForCPCPKCount = (Select ValueInInt from ShopDefaults where Parameter='SPC_IgnoreForCPCPK' and ValueInText='IgnoreForCPCPKCount')
		
		--Declare @IgnoreForCPCPKCount int
		--Declare @IgnoreForCPCPK int
		--Set @IgnoreForCPCPKCount=0
		--Set @IgnoreForCPCPK=0

		--Select @IgnoreForCPCPKCount = (select count(*) from Spcautodata A where MC=@Mc and ID >
		--										(Select max(ID) as ID from Spcautodata A1
		--										inner join (select Mc,Max(ToolChangeTime) as ToolChangeTime from SpcAutodata
		--										where Mc=@Mc Group by Mc) A2 on A1.Mc=A2.Mc and A1.ToolChangeTime=A2.ToolChangeTime
		--										where A1.Mc=@Mc)
		--							)
		--IF @IgnoreForCPCPKCount < @DefaultIgnoreForCPCPKCount
		--BEGIN
		--	Set @IgnoreForCPCPK=1
		--END   
		--Else
		--Begin
		--	Set @IgnoreForCPCPK=0
		--end
		--/*------- IgnoreForCPCPK calculation  12-Apr-2022 ---------*/

		
		declare @compid nvarchar(50)
		if  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
			BEGIN
			select @compid= @comp
			END
		ELSE 
			BEGIN
			select @compid=componentid from componentinformation where InterfaceID=@Comp
			END

		declare @machid nvarchar(50)
		select @machid=machineid from machineinformation where InterfaceID=@Mc

		--select isnull(SampleSize, 5),isnull(Interval, 60)*60 from SPC_Characteristic where MachineID=@machid and ComponentID=@compid and OperationNo=@Opn and CharacteristicID=@splstring3
		--select @Samplesize = isnull(SampleSize, 5) from SPC_Characteristic where MachineID=@machid and ComponentID=@compid and OperationNo=@Opn and CharacteristicID=@splstring3--g:
		--select @Threshold = isnull(Interval, 60)*60 from SPC_Characteristic where MachineID=@machid and ComponentID=@compid and OperationNo=@Opn and CharacteristicID=@splstring3 --g:
		
		IF EXISTS (select * FROM SPC_Characteristic where MachineID=@machid and ComponentID=@compid and OperationNo=@Opn and CharacteristicID=@splstring3)
		BEGIN
			select @Samplesize = isnull(SampleSize, 5) from SPC_Characteristic where MachineID=@machid and ComponentID=@compid and OperationNo=@Opn and CharacteristicID=@splstring3
			select @Threshold = isnull(Interval, 60)*60 from SPC_Characteristic where MachineID=@machid and ComponentID=@compid and OperationNo=@Opn and CharacteristicID=@splstring3 
		END
		ELSE 
		BEGIN
			select @Samplesize = 5
			select @Threshold = (480 * 60)
		END

		If @BatchID >= @samplesize --'5'  --SAmple Size
		BEGIN
			SET @BatchID = '0'
		END

		IF @BatchID = '0'
		BEGIN
			Insert into SPCAutodata([mc],[comp],[opn],[opr],[Dimension],[Value],[Timestamp],[BatchTS],WearOffSetNumber,MeasureDimension,CorrectionValue,Remarks,InspectionType,OvalityMax,OvalityMin,IgnoreForCPCPK)
			Select @MC,@COMP,@OPN,@OPR,@splstring3,@SPLSTRING2,@sttime,@sttime,@WearOffSetNumber,@MeasureDimension,@CorrectionValue,@Remarks,@InspectionType,@OvalityMax,@OvalityMin,@IgnoreForCPCPK

			SET @Error = @@ERROR
			IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
		END
		ELSE IF @BatchID < @samplesize --'5' --Sample Size
		BEGIN	
			If Datediff(s,@BatchTS,@sttime)<= @Threshold --600 --Threshold Setting
			BEGIN
				Insert into SPCAutodata([mc],[comp],[opn],[opr],[Dimension],[Value],[Timestamp],[BatchTS],WearOffSetNumber,MeasureDimension,CorrectionValue,Remarks,InspectionType,OvalityMax,OvalityMin,IgnoreForCPCPK)
				Select @MC,@COMP,@OPN,@OPR,@splstring3,@SPLSTRING2,@sttime,@BatchTS,@WearOffSetNumber,@MeasureDimension,@CorrectionValue,@Remarks,@InspectionType,@OvalityMax,@OvalityMin,@IgnoreForCPCPK

				SET @Error = @@ERROR
				IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			END
			ELSE
			BEGIN
				Insert into SPCAutodata([mc],[comp],[opn],[opr],[Dimension],[Value],[Timestamp],[BatchTS],WearOffSetNumber,MeasureDimension,CorrectionValue,Remarks,InspectionType,OvalityMax,OvalityMin,IgnoreForCPCPK)
				Select @MC,@COMP,@OPN,@OPR,@splstring3,@SPLSTRING2,@sttime,@sttime,@WearOffSetNumber,@MeasureDimension,@CorrectionValue,@Remarks,@InspectionType,@OvalityMax,@OvalityMin,@IgnoreForCPCPK

				SET @Error = @@ERROR
				IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
			END
		 END
	END
	ELSE
    BEGIN
		   INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting SPC record(Date problem)',getdate())
		   UPDATE rawdata  set status=13 where Slno=@Slno	
		   GOTO FETCHCURSOR
    END

	While @@TRANCOUNT <> 0
	BEGIN	
		COMMIT TRANSACTION
		UPDATE rawdata  set status=1 where Slno=@Slno	
	END

END
------------------------------------ NR0093 ADDED TILL HERE --------------------------------------------

------------------------- ER0391 From Here ---------------------------------
If @Datatype = 18
BEGIN
	   If (IsDate(@Sttime) = 1)
	   BEGIN
			If Not exists( Select * from autodataalarms where machineid=@Mc and alarmnumber=@comp and alarmtime=@Sttime)	
			Begin
					BEGIN TRANSACTION
					INSERT INTO AutoDataAlarms (MachineID, AlarmNumber,Alarmtime,RecordType,Target,Actual,ComponentID,OperationID)
					VALUES( @Mc,@comp,@Sttime,18,@SPLSTRING1,@SPLSTRING2,@Splstring3,@WearOffSetNumber)		
			END
			Else 
			BEGIN
	  				INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'SmartData-Duplicate Record Found From machine',getdate())
					SET @ERROR=@@ERROR
					SET @AppErrCode=5
					IF @ERROR <>0 or @AppErrCode=5 GOTO ERROR_HANDLER_GENERAL	
			END
	   END
	   ELSE
	   BEGIN
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting Alarm record(Date problem)',getdate())
			UPDATE rawdata  set status=13 where mc=@Mc and sttime=@Sttime 	
			GOTO FETCHCURSOR
	    END
	
		SET @Error = @@ERROR
	    IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES

	    While @@TRANCOUNT <> 0
	    BEGIN	
		COMMIT TRANSACTION
		UPDATE rawdata  set status=1 where Slno=@Slno	
 	    END	
END
------------------------- ER0391 Till Here ---------------------------------


--**************************************************************************************************
--TYPE 15 RECORD
--TOOL Change RECORD For Alicon
----------------------------------------------------------------------------------------------------
If @Datatype = 15
	    BEGIN	

		If IsDate(@Sttime) = 1   AND Exists (SELECT machineid FROM dbo.machineinformation WHERE InterfaceID = @Mc)
		   BEGIN
			 BEGIN TRANSACTION
	    		INSERT INTO AutodataDetails  (Machine, RecordType, Starttime,Endtime, DetailNumber,SequenceNo)
		        VALUES(@Mc ,@Datatype,@Sttime,@Ndtime,@Splstring1,@SPLSTRING2)

			SET @Error = @@ERROR
			IF @Error <> 0 GOTO ERROR_HANDLER_FOR_ALLTYPES
		   END
		ELSE
		BEGIN
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,'Error in inserting ToolChange record(Date or machine id problem)',getdate())
			UPDATE rawdata  set status=12 where mc=@Mc and sttime=@Sttime 	
			GOTO FETCHCURSOR
		END

	  	While @@TRANCOUNT <> 0
		   BEGIN	
			
			COMMIT TRANSACTION
			UPDATE rawdata  set status=1 where Slno=@Slno	
	 	   END
	
		
END --TYPE 15 RECORD


-------------------------------------------------------------------------------------------------------
--ERROR HANDLERS
-------------------------------------------------------------------------------------------------------
--select getdate()
IF @Error<> 0
	   BEGIN
	
	        ERROR_HANDLER_FOR_ALLTYPES:
			IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
			UPDATE rawdata  set status=11 where Slno=@Slno	
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,@Error,getdate())
			SET @Error=0
			GOTO FETCHCURSOR
	
	       ERROR_HANDLER_FORCURDOWN:
			CLOSE SD_CURDOWN
			DEALLOCATE SD_CURDOWN
			--DROP TABLE #SD_DownTime
			IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,@Error,getdate())
			UPDATE rawdata  set status=11 where Slno=@Slno	
			SET @Error=0
			GOTO FETCHCURSOR
	    	ERROR_HANDLER_GENERAL:
			SET @Error=0
			UPDATE rawdata  set status=@AppErrCode where Slno=@Slno	
			GOTO FETCHCURSOR
		--mod 7 : Error handler for the cursor while inserting 42 records into autodata
		ERROR_HANDLER_FOR_SD_ICDCUR:
			CLOSE SD_ICDCUR
			DEALLOCATE SD_ICDCUR
			--DROP TABLE #SD_DownTime
			IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
			INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,@Error,getdate())
			UPDATE rawdata  set status=11 where Slno=@Slno	
			SET @Error=0
			GOTO FETCHCURSOR
		---mod 7
	   END--IF ERROR	
SET @Error = @@ERROR
IF @Error <> 0 GOTO ERROR_HANDLER_FORMAINCURSOR
--FETCH NEXT ROWS TO PROCESS
	FETCHCURSOR:
delete from #SD_DownTime
delete from #SD_OprGrp
---mod 10: to insert work order number also
---FETCH NEXT FROM SD_CUR INTO @Slno,@DataType,@IPAddress,@Mc,@Comp,@Opn,@Opr,@Splstring1,@Sttime,@Ndtime,@SplString2,@Status
FETCH NEXT FROM SD_CUR INTO @Slno,@DataType,@IPAddress,@Mc,@Comp,@Opn,@Opr,@Splstring1,@Sttime,@Ndtime,@SplString2,@Status,@WorkOrderNo,@Splstring3,@WearOffSetNumber,@MeasureDimension,@CorrectionValue,@Remarks,@InspectionType,@OvalityMax,@OvalityMin,@IgnoreForCPCPK
---mod 10
END--Whilefetch
	
	DROP TABLE #SD_DownTime
	drop table #SD_OprGrp
	IF @Error<>0
	BEGIN	
	    ERROR_HANDLER_FORMAINCURSOR:
		CLOSE SD_CUR
		DEALLOCATE SD_CUR
		DROP TABLE #SD_RawData
		IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
		INSERT INTO SmartDataErrorLog(RawdataId,IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@Slno,@IPAddress,@Mc,@ERROR,getdate())
		UPDATE rawdata  set status=11 where Slno=@Slno	
		RETURN @Error
	END
--END--PROCEDURE  commented
--PRINT DATEDIFF(MS,@Time,GETDATE())

--ER0361 Added From Here
IF Exists (SELECT StatName = st.name ,StatDate = ISNULL(STATS_DATE(st.id, st.indid),1)
FROM sysindexes st WITH (nolock)
WHERE DATEDIFF(minute, ISNULL(STATS_DATE(st.id, st.indid),1), GETDATE()) > 120
and st.name = 'PK_AUTODATA')
begin
    UPDATE STATISTICS autodata               
End
--ER0361 Added Till here
	
	
END
