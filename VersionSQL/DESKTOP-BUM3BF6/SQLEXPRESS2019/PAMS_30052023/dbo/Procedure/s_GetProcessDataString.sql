/****** Object:  Procedure [dbo].[s_GetProcessDataString]    Committed by VersionSQL https://www.versionsql.com ******/

  
  
/*************************************************  
exec s_GetProcessDataString 'START-E3-2-20210323-155845-1.88217-0.0491-0.04539-[-0.92456]-0-0-0.21391-232.27177-234.27829-232.29749-0-0-0-[0]-[0]-[0.92456]-END','127.0.0.1','','33'  
exec s_GetProcessDataString 'START-E3-1-20210327-093729-63.75406-0-1.05274-[1]-0-0-0-0-0-0-END','127.0.0.1','','33'  
START-11-mc-Comp-Opn-Opr-StDate-Sttime-END 
select * from rawdata order by slno desc
--delete from rawdata where slno >= 6902
select * from machinerunningstatus
type 1 --> START-1-mc-Comp-Opn-Opr-PalletCount-StDate-Sttime-NDDate-NDTime-Down1-Down2-END  
Type 2 --> START-2-mc-Comp-Opn-Opr-Down1-StDate-Sttime-NDDate-NDTime-END  
Type 42--> START-42-MC-Comp-Opn-Opr-Down1-StDate-Sttime-NDDate-NDTime-END  

*Procedure Created By Shilpa H.M On  11Oct07 to split the datastring and insert the data  
*into Rawdata table which will hold temporarily for further processing.  
*(that is to put into autodata table).  
mod 1 :-ER0159. By Mrudula to get the machine interfaceid from the input string.  
mod 2:-ER0176. By Mrudula on 10-mar-2009. process type 11 (Program Start) records and put it in rawdata table.  
 Insert in Rawdata with status=15.  
mod 3:- ER0162. By Mrudula on 11-mar-2009.  
 1)Change Smartdata procedure to handle optional stop and start string.  
 2)For begin use datatype 70 and for end use datatype 71  
 3)The string format is as good as spindle record. Hardcode the value for record type say 0  
mod 4:- ER0185. By Mrudula M. Rao on 04-june-2009. to handle milliseconds  
mod 5:- ER0184(6).By Mrudula M. Rao on 05-Jun-2009.  
  Process work  order number while processing the records in Smartdata  
  If the setting is 'Y' for workorder column in SmartDataPortRefreshDefaults table,  
  then look for workorder number along with the record. If the setting is N, Insert '0' workorder number in Rawdata  
mod 6:- DR0189 - Karthik G - Handle the errors raising while inserting records into rawdata table  
  i.e.. Like (a)Invalid Number Of Parameters in the string (b) Invalid DateTime format.  
mod 7:- For NR0053 by Mrudula M.Rao on 14-jul-2009.  
 Introduced datatype E1 and E2 for energy strings .  
mod 8:-For ER0179 by Mrudula M.Rao on 20-mar-2009.Modify processing of energy strings. The values will be enclosed within square "[ ]" bracket.  
 Read values within the bracket.  
mod 9:-For DR0195 by Mrudula M. Rao on 31-jul-2009.Ignore the leading zeroes for the interfaceid's  
    (machine,component,operation , operator, dcode) and pallet count.  
mod 10:-for ER0195 by Mrudula M. Rao on 11-sep-2009.  
 Introduce a new data string with datatype 17. This  signal will be sent from the machine if one of  its tool has reached its target count. The strign format is as follows.  
 START-17-MC-AlarmNumber-Stdate-Sttime-ToolCount-END and sample datastring looks as mentioned below.  
 "START-17-1-15-20090801-134551-1200-END" . The tool count is the either the target set for the tool or the actual production by the tool.  
mod 11:- For ER0204 by Mrudula M. Rao on 30-Oct-2009.Change processing of energy strings according to the latest format proven in PLC. The string format is "START-E2-MC-DATE-TIME-L5-KWH-KW-[PF]-AMPERE-END"  
mod 12:- For DR0227 by Mrudula M.Rao on 19-dec-2009.Fix bug in processing record type 6  
mod 13:- For ER0217 by Mrudula M. Rao on 22-Feb-2009.  
  1)Read Component and operation no from "ProgramUploadToMachine" table  
  If the setting ta procedure level and machine level is equal to YES.  
  Should read the CO from the last program transfer entry in ProgramUploadToMachine table.  
mod 14:- For ER0219 by KarthikG  on 26-Feb-2010. Introduce datatype 81 for logging help request, and 80 for completion of request. Format for string will be START-DTATYPE(80 OR 81)-MC-HelpReuestID-STDATE-STTIME-END-  
mod 15:- ER0227 By KarthikG on 15/Apr/2010 :: Increase the size of Component InterfaceID from 4 to 16.  
mod 16:- ER0242 By KarthikR on 21/Aug/2010 :: Add new column RequestingModuleName in programhistory table and insert module name.  
mod 17:- ER0265 - SyedArifM - 19-Oct-2010 :: To include the Maintanace Alarms For DataType=26  
mod 18:-  - SyedArifM - 19-Jan-2011 :: To change the Maintanace Alarms From DataType=26 to DataType=85  
mod 19:-  - SyedArifM - 19-Jan-2011 :: :: To include the Maintanace Alarms For DataType=26  
mod 20:- DR0306 - 22/Feb/2012 -Sneha k :: To handle multiple records created in the same xml file For TAFE.  
mod 21:- ER0327 - 20-Jul-2012 -Sneha k :: Introduced datatype 20 for Rajmane to handle rejections.   
ER0349 - 2013/Mar/13 - SwathiKS :: Introduced datatype 25 for SAF to handle Marked_for_Rework.   
DR0329 - 2013-Jul-03 - SwathiKS :: To Handle duplicates for Datatype=20 and Datatype=25.   
DR0304 - swathiKS - 11/Jan/2012 :: To Allow decimals in kw and kwh values in Energy Strings.(Datatype =75)          
NR0093 - 2013-Sep-10 - SwathiKS :: To introduce New Datatype=31 for SPC and process into Rawdata Table and   
Datatype=39 for FlowMeter Process into FlowCtrlAutodata Table.   
NR0094 - 2013-Sep-30 - SwathiKS :: To Process Datatype=7 into ExportToHMI_PullInfo.[MM Forge]  
ER0367 - 2013-Oct-11 - SwathiKS :: To handle Datatype=21 for MO Report.     
ER0369 - 2013-Oct-31 - SwathiKS :: To Handle Datatype=76 for HelpCode.     
DR0333 - 2013-Dec-10 - SwathiKS :: while Processing Datatype=20 (For Rejection) or Datatype=25 (For Marked_For_Rework) to avoid leading zeroes in Shiftid   
while inserting into AutodataRejections table.  
While processing Datatype=39 for FlowMeter, to avoid leading zeroes in PumpModel while inserting into FlowCtrlAutodata Table .     
NR0098 - SwathiKS - 13/Jun/2014 :: To include New datatype=38 for TIMF.              
ER0387 - swathiKS - 21/Jul/2014 :: To handle Alphanumeric values for Component Interfaceid.       
NR0105 - SwathiKS - 06/Aug/2014 :: To introduce datatype=10 for Saint-Gobain.      
ER0391 - SwathiKS - 25/Aug/2014 :: To introduce datatype=18 for Wipro and while processing datatype=17 change datatype to float instead of int for Toolcount.       
DR0347 - SwathiKS - 20/Sep/2014 :: To remove leading zeroes from shiftid while processing datatype=20 and datatype=25 i.e Convert @RejShift and @MReworkShift from nvarchar to int.   
ER0397 - SwathiKS - 19/Nov/2014 :: a> To include WorkOrderNo. in datatype=11 and Datatype=20 and Datatype=25.  
b> To include New Datatype=28 for Shanti Iron.  
ER0399 - SwathiKS - 24/Dec/2014 :: To include Datatype=8 for BoschCycletimeMonitor.  
ER0398 - Vasavi - 30/Jan/2015 :: To introduce DataType=13 For MMForge.  
NR0105 - Vasavi - 30/Jan/2015 :: To Introduce DataType=43 For Saint-Gobain.   
DR0362 - Vasavi - 02/Jun/2015 :: Not able to insert for datatype=11,20,25 when WorkOrder Number = No.  
NR0116 - Vasavi - 19/Jun/2015 :: To introduce DataType=23 and DataType=24 for jina.  
DR0366 - SwathiKS - 23/Jul/2015 :: To handle NULL Values in Machineid Column (Reported from Techno): While Processing Energy Strings i.e. Datatype=75 or E2 if Machineid not defined in the Master table  
then insert incoming Machineinterfaceid to the Machineid column of tcs_energyconsumption table.  
NR0117 - Vasavi - 27/Jul/2015 :: To introduce New Energy DataType=77 or E3 for Techno.  
ER0417 - Vasavi\SwathiKS - 09/Oct/2015 :: Specific To shanthi, Altered Datatype=6, to get rejection,rework and accept status and Process records into QualityInspectiondetails.    
NR0118 - SwathiKS - 27/Oct/2015 :: To introduce new datatype=35 and process records into MachineEventsAutodata table.  
NR0119 - SwathiKS - 27/Oct/2015 :: While Processing datatype=20 (For Rejections) insert datepart of "CreatedTimestamp" column using procedure [dbo].[s_GetRejectionTimestamp] and Timepart will be from Incoming variable.  
NR0120 - SwathiKS - 03/Nov/2015 :: To Process Datatype=37 into InspectionAutodata for BFL.  
ER0421 - SwathiKS - 30/Dec/2015 :: a> To include Datatype=45 For Unitta-Belt.  
b> For Operator Grouping, Removed converting @Operator as int instead handling leading zeroes by string functions.  
ER0426 - SwathiKS - 28/Jan/2016 :: while processing datatype=77 ignore L5 in string.  
NR0122 - Vasavi - 29/Jan/2016 :: To introduce New datatype=50 and datatype=51 for pari.  
ER0430 - SwathiKS - 27/Feb/2016 :: To handle duplicate records for Datatype=35.  
ER0435 - SwathiKS - 31/May/2016 :: Strings was not processing into AutodataAlarms Table in BoschBNG i.e.Datatype=6.  
ER0437 - SwathiKS - 15/Oct/2016 :: To allow decimal values in Volt1,Volt2 and Volt3 For Techno.  
NR0133 - SwathiKS - 15/Nov/2016 :: To Include New Dataype=15 To Capture Tool Data For Alicon.  
NR0134 - SwathiKS - 15/Nov/2016 :: To Include New Dataype=22 To Capture Start of Machine Down Reason For SONA.  
ER0441 - SwathiKS - 10/Dec/2016 :: If Datatype=1 AND Partscount="888" then consider it as "0" for Bosch Jaipur.  
ER0449 - SwathiKS - 06/May/2017 :: While Processing ENERGY string i.e Datatype=75 Insert Machineid as either "MachineID" or "MachineDescription" from Machieninformation table based on the Setting in Shopdefaults Table.(Bosch BNG)  
The above requirement was Reverted back and instead of datatype=75 or E2 now it has been moved under datatype=77 or E3.  
ER0450 - Vasavi - 01/Jul/2017 :: Introduce new datatype = 55 for kenna Metal.   
ER0450 - Vasavi\SwathiKS - 20/Jul/2017 :: a> Introduce new Datatype = 56 and Datatype = 57 for Shanthi. 
b> Dummy Cycle Insertion - If Downcode="999" then insert Datatype "2" Record as "Dummy cycle" (PreDefined Downcode In DowncodeinFormation Table) in Autodata.
ER0454 - Gopinath - 14/Oct/2017 :: To Introduce EnergySource in TCS_energyConsumption Table datatype=77 For Techno To hold EB/DG Values.
[NR0139] - swathiKS- 02/Nov/2017 :: To Introduce New datatype "46" and "47" for QualityBoard and datatype "65" for Assembly Board[John Crane].
ER0464 - Gopinath - 10/May/2018 :: To Display Machinewise Running Status Using New Table "MachineRunningStatus" Instead of "Rawdata" table for Performance Optimization.
NR0149 - Anjana/Swathi - 29/Sep/2018 :: a> To introduce datatype=44 for Peekay b> Handle Component and WorkOrderNo within [ ] for datatype 1,2,42,11,22
Anjana - To handle Datatype=86 for Winmach.
Anjana - To handle [] For Dimensionid in Datatype=31 for Endurance
ER0499 - Swathi - 03/Feb/2021 :: Peekay :: In Cleanup we are deleting Status<>0 records so Datatype=22 was not clearing in Rawdata as an enhancement Update Status=15 instead status=0. 
ER0502 - Swathi - 15/Mar/2021 :: AAAPL :: 1> Added New HelpRequest String Format To Capture Remarks "START-78-Machine-HelpRequest-Action1-Action2-D1-T1-REMARKS-END"
2> while processing Energy string i.e. E3 or 77 Consider EM_machineinformation instead of machineinformation
*******************************************************/  
--s_GetProcessDataString 'START-E3-202-20140330-22595903-2-4.0061r5-200-15.4385-[-0.56]-0.45-0.46-0.69-1-2-3-END','127.0.0.1','','33'  
--s_GetProcessDataString 'START-46-10-10-1-20-10-200-100-4-0-20171220-103710-END','127.0.0.1','','33'  
--s_GetProcessDataString 'START-47-10-20171219-103515-END','127.0.0.1','','33'  
--s_GetProcessDataString 'START-44-185-[7777]-40-2-U19645-3-20180929-194900-END','127.0.0.1','','33'  
--s_GetProcessDataString 'START-31-1-1-1-1-15.50-[+15.40]-20190326-062500000-END','127.0.0.1','','33'
--s_GetProcessDataString 'START-31-11-1-1-1-C01-[15.11100]-2-[15.01000]-[-0.10099]-20190329-123520-END','127.0.0.1','','33'  
--s_GetProcessDataString 'START-31-11-1-1-1-C01-[15.11100]-2-[15.01000]-[-0.10099]-20190329-123520-END','127.0.0.1','','33' 
--s_GetProcessDataString 'START-31-11-1-0004-11-[35.000004]-[15.109000]-1-[15.100001]-[-0.00899]-20190329-170141-END','127.0.0.1','','33' 
--s_GetProcessDataString 'START-1-204-[152]-1-1-0.3-[P003]-20200520-155833-20200520-161000-END','127.0.0.1','','33' 
--<?xml version="1.0" encoding="UTF-8"?>  
  
CREATE PROCEDURE [dbo].[s_GetProcessDataString]  
@datastring as varchar(4000),  
@IpAddress as nvarchar(50),  
@OutputPara int output,  
@LogicalPortNo Smallint=0  
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; ---ER0464
  
--declare the local variables  
 --DECLARE @Time AS DATETIME  
   
 DECLARE @Error AS int    --variable to store error number  
 DECLARE @orgstring As varchar(4000)  --original datastring  
 DECLARE @StrLen AS INT    --variable to store length of datastring  
 DECLARE @tp as nvarchar(10)   --store datatype  
 DECLARE @tp_int AS int    --type casting the datatype as int  
 DECLARE @component as nvarchar(50)  --variable holds component  
 DECLARE @operation as nvarchar(50)  --holds operation number  
 DECLARE @operator as nvarchar(50)  --holds operator id  
 DECLARE @PalletCount as nvarchar(10)  --holds the count of component  
 DECLARE @startdate as  nvarchar(12)   
 ---mod 4: increase the lengt to hold milliseconds   
 --DECLARE @starttime as  nvarchar(12)  
 DECLARE @starttime as  nvarchar(15)  
 ---mod 4  
 DECLARE @enddate as  nvarchar(12)  
 DECLARE @endtime As nvarchar(12)    
 DECLARE @downcode as  nvarchar(50)  --holds the down code  
 DECLARE @SubDataString as  nvarchar(3500) --holds datastring which support ICD's  
-- DECLARE @McInterfaceID As nvarchar(10)  
 DECLARE @McInterfaceID As nvarchar(50)  
 DECLARE @TempString as nvarchar(4000)  --temporary string holds the string to validate for specified length   
 DECLARE @ProgramID As nvarchar(10)  --holds program id  
 DECLARE @ToolDir int    --variable holds tool direction  
 --mod 5: Variable to hold workOrderNumber for the incoming record  
 Declare @WorkOrder as nvarchar(50) --Variable to hold workOrderNumber for the incoming record  
 --mod 17:  
 DECLARE @Address As nvarchar(10) --holds Address of DT 26  
 DECLARE @Addressint As Bigint --holds Address in interger for DT 26  
 DECLARE @Value As nvarchar(10) --holds Value of DT 26  
 DECLARE @Value1 As nvarchar(12) --holds Address+Value of DT 26  
 --mod 17:  
 --SyedArifM - 27-07-2011 - From Here  
 DECLARE @CurrentDate AS datetime  
 DECLARE @YYYYMMDD AS varchar(10)  
 DECLARE @HHMMSS AS varchar(12)  
 DECLARE @BasePath AS varchar(500)  
 Declare @BasePathErr AS varchar(255)  
 Declare @FileName varchar(255)  
 Declare @AllowXMLGeneration varchar(255)  
 Declare @FileContent_LogMsg varchar(500)  
 Declare @CurrentDatetxt As nvarchar(40)  
 DECLARE @FS int ,@OLEResult int, @FileID int  
 DECLARE @Slno_Rdata as nvarchar(50)--DR0306  
 SET @Slno_Rdata=''--DR0306  
 --SyedArifM - 27-07-2011 - Till Here  
  
  
 --ER0327 :: Begin - Sneha K  
 DECLARE @RejCode as int  
 DECLARE @RejQty as int  
 DECLARE @RejDate as nvarchar(50)  
 --DECLARE @RejShift as nvarchar(15)--DR0347  
    DECLARE @RejShift as int --DR0347  
 --ER0327 :: End - Sneha K  
  
   
 --ER0349 :: Begin   
 DECLARE @MReworkCode as int  
 DECLARE @MReworkQty as int  
 DECLARE @MReworkDate as datetime  
 --DECLARE @MReworkShift as nvarchar(15) --DR0347  
 DECLARE @MReworkShift as int --DR0347  
 Declare @MReworkid as bigint  
 --ER0349 :: End   
  
 Declare @MONumber as nvarchar(50) --ER0367  
 Declare @MOQty as nvarchar(50) --ER0367  
   
 --NR0093 From here  
 DECLARE @Dimension as nvarchar(50)  
 DECLARE @DimValue as nvarchar(50)  
 Declare @Pumpmodel as nvarchar(50)  
 Declare @PumpSeries as nvarchar(50)  
 Declare @MinFlow as float  
 Declare @MaxFlow as float  
 --NR0093 till Here  
  
 --ER0369 From here  
 declare @Line as nvarchar(50)  
 DECLARE @Node as nvarchar(50)  
 declare @eventNo as nvarchar(50)  
 declare @Action as nvarchar(50)  
 declare @Action1 as nvarchar(50)  
 declare @Action2 as nvarchar(50)  
 --ER0369 Till here  
  
 DECLARE @RequestType Smallint --NR0094  
  
 -------- NR0098 From here -----------  
 DECLARE @ModelID as nvarchar(50)  
 DECLARE @operatorID as nvarchar(50)  
 Declare @ODNDE as float  
 Declare @ODDE as float  
 Declare @TIRNDE as float  
 Declare @TIRDE as float  
 Declare @SerialNo as nvarchar(50)  
 Declare @SequenceNo as bigint  
 Declare @SeqNo as nvarchar(50)  
 Declare @MonthValue as nvarchar(50)  
 Declare @yearvalue as nvarchar(50)  
 -------- NR0098 Till Here -------------  
  
 --NR0105 From Here--  
 Declare @Length as float  
 declare @Breadth as float  
 declare @Depth as float  
 --NR0105 Till Here--  
  
  --NR0120 From here    
  Declare @FeatureID as nvarchar(50)    
  Declare @ParameterID nvarchar(50)    
  Declare @SampleID nvarchar(50)    
  Declare @ActualValue as float    
  Declare @Actualtime as datetime    
  --NR0120 Till Here    
    
  
 --ER0397 Added From Here  
 Declare @SlNo as nvarchar(50)  
 Declare @status as int  
 --ER0397 Added Till Here  
   
 --NR0116 Added From Here.  
 Declare @ReworkAccepted as int  
 Declare @ReworkRejected as int  
 Declare @ReworkPerformed as int  
 --NR0116 Added Till Here.  
  
 --NR0117 Added From Here.  
 declare @KWHVal as float  
 declare @KWValue as float  
 Declare @PFValue as Float  
 Declare @AmpValue as float  
 declare @MachineName as nvarchar(50)  
 declare @gtime as datetime  
 declare @count as int  
 declare @V1 as Float --ER0437  
 declare @V2 as Float --ER0437  
 declare @V3 as Float --ER0437  
 declare @KVA as Float  
 declare @AmpereR as Float  
 declare @AmpereB as Float  
 declare @AmpereY as Float  
 declare @Energy_MachineName as nvarchar(50) --ER0449  
 declare @energysrc as smallint --ER0454  
 --NR0117 Added Till Here.  
  
 --NR0119 form Here  
 Create table #RejTimestamp  
 (  
 IDD bigint Identity(1,1) NOT NULL,  
 CreatedTs datetime,  
 StartDate datetime,  
 HourID int,  
 HourStart datetime,  
 HourEnd datetime,  
 Target float  
 )  
 --NR0119 Till Here  
  
 --ER0450
declare @maincategory as nvarchar(50)  
declare @subcategory as nvarchar(50)  
declare @selection as nvarchar(50)  
declare @targetValue as float 
Declare @PercentValue as int
--ER0450
  
---ER0421 Added From Here  
Declare @ComponentName as nvarchar(50)  
Declare @OperationName as nvarchar(50)  
Declare @TableRecCount as int  
Declare @Reccount as int  
Declare @Target as int  
Declare @Hourname as nvarchar(50)  
Declare @Hourid as nvarchar(50)  
Declare @Hourstart as datetime  
Declare @HourEnd as datetime  
Declare @ShiftID as int  
Declare @Flag as int  
---ER0421 added Till here  
 declare @DetailNumber as int --Vasavi for kenna Metal  
 Declare @MachineEvent as Nvarchar(50) --NR0118  

 declare @V4 as Float
 declare @V5 as Float
 declare @V6 as Float


 Declare @RemoveLeadZeroInProcessString nvarchar(50)

 Set @RemoveLeadZeroInProcessString = (select isnull(ValueInText,'Y') from ShopDefaults where Parameter='RemoveLeadZeroInProcessString')
  IF isnull(@RemoveLeadZeroInProcessString,'')=''
  BEGIN
	Set @RemoveLeadZeroInProcessString='Y'
  END



 Declare @rejrecordid as bigint --ER0332 Added  
 ---mod 13:Flag to check whether to read CO from ProgramTransfer data or incoming string  
 Declare @Ignore_CO_From_Machine as nvarchar(5)  
 set @Ignore_CO_From_Machine='Y' ---Set this flag to 'Y' If at all Component and operation should be read from ProgramTransfer data  
     ---We use ProgramUploadToMachine table to read the present component and operation running on the machine.  
 --mod 13  
 set @WorkOrder='0' --set 0 as default value.  
 ---mod 5  
 --mod 6  
 declare @NoOfSep as int  
 set  @NoOfSep=10  
 ---mod 6  
   
 --To validate the string  
 SET @TempString=REPLACE(@datastring,'-','')  
   
 SET @StrLen=len(@datastring)-len(@TempString)  
 --select @StrLen  
 SET @Orgstring=@datastring  
 --Eliminate start  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
 --read datatype  
 SET @tp = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

 ---mod 1 get machine interfaceid  
 --mod 9: Eliminate leading zeros if any from machine interfaceid  
 --SET @McInterfaceID = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
-- SET @McInterfaceID = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  

SET @McInterfaceID = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) 
SET @McInterfaceID = REPLACE(LTRIM(REPLACE(@McInterfaceID, '0', ' ')), ' ', '0')

 --mod 9  

 ---ER0502 Commented below & Added here
-- mod 7 :-If @tp is  E1 or  E2 set @tp to 75  
 if @tp='E1' or @tp='E2'  
 begin  
  set  @tp='75'  
 end  
  
 --NR0117 From here  
 if @tp='E3'  
 begin  
  set  @tp='77'  
 end  
 --NR0117 Till Here  
---ER0502 Commented below & Added here
  
 --mod 1   
--eliminate mc from string  

If  @tp='1' or @tp='2' OR @tp = '42' OR @tp = '11' OR  @tp = '22' or @tp='44'or @tp=20 or @tp_int=68 or @tp_int=96  -- ER0094  
BEGIN
	if CHARINDEX('-[', @datastring)>0
	Begin
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2) 
	End
	Else
	Begin
	 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End 
end
ELSE 
Begin 
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
End  

---ER0502 Commented & Added in the top
 ---- mod 7 :-If @tp is  E1 or  E2 set @tp to 75  
 --if @tp='E1' or @tp='E2'  
 --begin  
 -- set  @tp='75'  
 --end  
  
 ----NR0117 From here  
 --if @tp='E3'  
 --begin  
 -- set  @tp='77'  
 --end  
 ----NR0117 Till Here  
 ---ER0502 Commented & Added in the top
  
 --mod 7  
 --validate datatype:following statement is commented to check for othere datatypes  
 --IF IsNumeric(@tp) = 0 OR @tp> 6  
 IF IsNumeric(@tp) = 0  
 Begin  
  RAISERROR ('Error-Record type is not in correct format[%s]: - %s', 16, 1,@IpAddress,@orgstring)  
  return -1;  
 End  
   
 --validate IP Address  
 If @IpAddress=null or @IpAddress=''  
 Begin   
  RAISERROR ('IPAddress is not valid,Please check it[%s]: - %s', 16, 1,@IpAddress,@orgstring)  
  --RAISERROR ('Error inserting Spinddle record for %s', 16, 1,@orgstring)  
  return -1;  
 end   
   
-- select machine  
 ---Commented for mod 1 . To allow 2 machineinterfaceid's for the same IP address and port number  
  ---SELECT @McInterfaceID=NULL;  
  ---SELECT @McInterfaceID=ISNULL(InterfaceID,0) From MachineInformation where IP=@IpAddress and portno=@LogicalPortNo  
 ---till here for mod 1  
--For production record of datatype 1 and datatype 2  
SET @tp_int = CAST(@tp as int) 

/*****************************************************************************************  
 Split Record type 1 and 2 string  
Type 1--> START-1-mc-Comp-Opn-Opr-PalletCount-StDate-Sttime-NDDate-NDTime-Down1-Down2-END  
Type 2--> START-2-mc-Comp-Opn-Opr-Down1-StDate-Sttime-NDDate-NDTime-END  
Type 42--> START-42-MC-Comp-Opn-Opr-Down1-StDate-Sttime-NDDate-NDTime-END  
Type 62--> START-62-MC-Comp-Opn-Opr-Down1-StDate-Sttime-NDDate-NDTime-END  
Insert Into rawdata table  
*****************************************************************************************/  
If  @tp_int=1 or @tp_int=2 OR @tp_int = 42 OR @tp_int = 62 -- ER0094  
BEGIN  
 --to validat0e the datastring whether it contains the required number of data in the sring  
   
 --mod 6  
 if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
 begin  
  set @NoOfSep=12  
 end  
 --mod 6  
 --If @StrLen<10  
   
 If @StrLen<@NoOfSep  
 ---mod 6  
 BEGIN  
  RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
 END  
 --eliminate mc from string  
 --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
   
   
 ---get component from string if setting @Ignore_CO_From_Machine is Yes and no entry in ProgramUploadToMachine for @McInterfaceID  
 --It holds good when setting @Ignore_CO_From_Machine is No  
 --if isnull(@component,'')=''  
 --begin--ER0227  
 --SET @component = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
 --SET @component = convert(bigint,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  

 IF @RemoveLeadZeroInProcessString='Y'
 BEGIN
		if CHARINDEX(']-', @datastring)>0
		Begin
		print '1'
		 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
		 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
		 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
		END
		ELSE
		Begin
		print '2'
		 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
		 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
		 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
		End
  END
  ELSE
  BEGIN
		if CHARINDEX(']-', @datastring)>0
		Begin
		print '1'
		 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
		 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
		END
		ELSE
		Begin
		print '2'
		 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
		 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
		End
  END
 --end----ER0227  

 ---get operation from string if setting @Ignore_CO_From_Machine is Yes and no entry in ProgramUploadToMachine for @McInterfaceID  
 --It holds good when setting @Ignore_CO_From_Machine is No  
 --if isnull(@operation,'')=''  
 --begin  
 SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
 --end  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 ---Commented below lines for mod 13 reading component and operation if they are not selected  
 /*--component  
 --mod 9:Eliminate leading zeros from the component interfaceid  
 --- SET @component = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @component = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
 ---mod 9  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 --operation  
 ---mod 9:Eliminate leading zeros from the operation interfaceid  
 --SET @operation = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
 ---mod 9  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 Commented for mod 13 */  
 --operator  
 ---mod 9:Eliminate leading zeros from the operator interfaceid  
 ---SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 --SET @operator = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0421  
  SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
  SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
  
 ---mod 9  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
 --down code  
 If @tp_int = 2 or @tp_int = 42 or @tp_int = 62 -- ER0094  
 Begin  

  --mod 9:Eliminate leading zeros from the downcode interfaceid  
  ---SET @downcode = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @downcode = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  ---mod 9 

	--ER0450 From Here 
	IF @downcode='999'
	BEGIN
		SET @downcode = 'Dummy Cycle'
	END
	--ER0450 Till Here

	--NR0149 From Here
    --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	if CHARINDEX('-[', @datastring)>0
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
	End
	Else
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	End  
	--NR0149 Till Here	  
 End  
 Else  
 Begin  
   
 --Pallet Count/Component Count  
	--SET @PalletCount = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as int)  
	SET @PalletCount = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as nvarchar(10)) --Commented for GEA to allow decimal

	--NR0149 From Here
	--SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	if CHARINDEX('-[', @datastring)>0
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
	End
	Else
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  	End 
	End  
	--NR0149 Till Here

 ---mod 5: Get the WorkOrderNumber from the string if SD settings for WorkOrder is "Y"  
 if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
 begin  

  --NR0149 From Here
  --set @WorkOrder=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	if CHARINDEX(']-', @datastring)>0
	Begin
	SET @WorkOrder = SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1) 
	SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
	SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
	SET @WorkOrder=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
	SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1) 
	End
	--NR0149 Till Here
 end  
 --mod 5  
   
 --startdate  
 SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
 --mod 6  
 --s_GetProcessDataString 'START-1-2105-1108-3108-13-1-20090620-110034-20090620-110049-END','172.36.0.212','','11'  
 SET @Error = @@ERROR  
  IF @Error <> 0  
 Begin  
 RAISERROR('RawData::Invalid StartDate:[%s] - %s',16,1,@IpAddress,@Orgstring)  
 return -1;  
 End  
--mod 6  
 --starttime  
 SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 SET @starttime = dbo.f_GetTpmStrToTime(@starttime)         
   
 --mod 6  
 SET @Error = @@ERROR  
  IF @Error <> 0  
 Begin  
 RAISERROR('RawData::Invalid StartTime:[%s] - %s',16,1,@IpAddress,@Orgstring)  
 return -1;  
 End  
 --mod 6  
 --enddate  
 SET @enddate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 SET @enddate = dbo.f_GetTpmStrToDate(@enddate,GetDate())         
 --mod 6  
 SET @Error = @@ERROR  
  IF @Error <> 0  
 Begin  
 RAISERROR('RawData::Invalid EndDate:[%s] - %s',16,1,@IpAddress,@Orgstring)  
 return -1;  
 End  
 --mod 6  
 --endtime  
 SET @endtime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 SET @endtime = dbo.f_GetTpmStrToTime(@endtime)  
 --mod 6  
 SET @Error = @@ERROR  
  IF @Error <> 0  
 Begin  
 RAISERROR('RawData::Invalid EndTime:[%s] - %s',16,1,@IpAddress,@Orgstring)  
 return -1;  
 End  
 --mod 6  
 ---mod 13: Read CO from ProgramUploadToMachine If @Ignore_CO_From_Machine='Y'  
 If @Ignore_CO_From_Machine='Y'  
 BEGIN  
  If isnull((select IgnoreCoFromMach from machineinformation where interfaceid=@McInterfaceID),'N')='Y'  
  BEGIN  
   select top 1 @component=C.interfaceid,@operation=O.Interfaceid from ProgramUploadToMachine P inner join  
   machineinformation M on M.machineid=P.MachineID inner join componentinformation C  
   on C.componentid=P.ComponentId inner join componentoperationpricing O on  
   O.componentid=C.componentid and  
    O.operationno=P.operationno and O.Machineid=P.MachineID  
   where M.interfaceid=@McInterfaceID and  P.[timestamp]<@startdate+ ' ' + @starttime order by P.[timestamp] desc  
  END  
 END  
 --mod 13  

 
if @tp_int=1 or @tp_int=2 or @tp_int=42
begin
	declare @PJCYear nvarchar(10)
	SET @PJCYear = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
	SET @PJCYear=REPLACE(LTRIM(REPLACE(@PJCYear, '0', ' ')), ' ', '0')
    SET @datastring= SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
end

   
 --Inserts n down codes if any  
 If CHARINDEX('END',@datastring) > 1  
  BEGIN  
  set @SubDataString=SUBSTRING(@datastring,1,len(@datastring)-3)  
  --print @SubDataString  
  END  
              
 --Validate the PalletCount variable for numeric and not zero  
 If @PalletCount <= '0' 
    SET @PalletCount = '1'  
   
 If @PalletCount = '888' --ER0441  
    SET @PalletCount = '0' 

----------------------------------------------------------------------------------PAMS (PJCYear)------------------------------------

  
 If @tp_int=1  
 BEGIN  
  ---mod 5: Insert workOrderNumber also in rawdata  
  ---Insert into Rawdata(datatype,IPAddress,Mc,Comp,Opn,Opr,SPLSTRING1,Sttime,Ndtime,SPLSTRING2,Status)values  
 ---(@tp_int,@IpAddress,@McInterfaceID,@component,@operation,@operator,@PalletCount, @startdate+ ' ' + @starttime,@enddate+ ' ' + @endtime,@SubdataString,0) 

   Insert into Rawdata(datatype,IPAddress,Mc,Comp,Opn,Opr,SPLSTRING1,Sttime,Ndtime,SPLSTRING2,Status,WorkOrderNumber,SPLString3)values  
        (@tp_int,@IpAddress,@McInterfaceID,@component,@operation,@operator,@PalletCount, @startdate+ ' ' + @starttime,@enddate+ ' ' + @endtime,@SubdataString,0,@WorkOrder,@PJCYear)  
  ---mod 5  
  ---mod 6 
  	if exists(select * from company where CompanyName like '%MIVIN%')
   begin
  if not exists(select * from WorkOrderDetails_Mivin where DataType=@tp_int and Machineid=@McInterfaceID and ComponentID=@component and WorkOrder=@WorkOrder and operation=@operation)
  begin
         insert into WorkOrderDetails_Mivin(datatype,Machineid,ComponentID,workorder,updatedts,operation)
		 select distinct @tp_int,@McInterfaceID,@component,@WorkOrder,@startdate+ ' ' + @starttime,@operation
  end
  end

   SET @Error = @@ERROR  
  IF @Error <> 0  
    Begin  
    RAISERROR('Insert into RawData:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  --mod 6  
--SK  
--  set @Slno_Rdata=''  
  set @Slno_Rdata=@@identity--DR0306 Added  
  --SyedArifM - 27-07-2011 - From Here STOP  
  select top 1 @AllowXMLGeneration=ValueInText from Shopdefaults where Parameter = 'AllowXMLGeneration'  
  select top 1 @BasePath = ValueInText from Shopdefaults where Parameter = 'XMLFilePath'  
  IF @AllowXMLGeneration = 'Y'  
  Begin  
   IF @BasePath <> ''  
    Begin  
     SET @CurrentDate = GETDATE()  
     SET @YYYYMMDD = REPLACE(CONVERT(char(10), @CurrentDate, 111), '/', '-')  
     SET @HHMMSS = REPLACE( CONVERT(char(12), @CurrentDate, 114) ,':', '-')  
     SET @CurrentDatetxt = Convert(nvarchar,@CurrentDate,120)  
     --SET @FileName = @BasePath + @McInterfaceID + '_' + @YYYYMMDD + '_' + @HHMMSS + '.xml' --DR0306 Commented  
     SET @FileName = @BasePath + @McInterfaceID + '_' + @YYYYMMDD + '_' + @HHMMSS +'_'+ @Slno_Rdata + '.xml' --DR0306 Added  
--   select @FileName  
--   return  
     set @FileContent_LogMsg = '<?xml version="1.0" encoding="UTF-8"?><LS><Version>LSTPM1.0</Version><Plant></Plant><CellName>'+ @McInterfaceID +'</CellName><LSType>STOP</LSType><LSTime1>'+ @enddate+ ' ' + @endtime +'</LSTime1><LSTime2></LSTime2><Reason></Reason></LS>'  
       
     EXECUTE @OLEResult = sp_OACreate 'Scripting.FileSystemObject', @FS OUT  
     IF @OLEResult <> 0 --PRINT 'Scripting.FileSystemObject'  
     Begin  
      SET @FileContent_LogMsg = ''  
      Select @FileContent_LogMsg = 'Unable to create FileSystemObject.'  
     End  
     Else  
     Begin    
      --Open a file  
      execute @OLEResult = sp_OAMethod @FS, 'OpenTextFile', @FileID OUT, @FileName, 8, 1  
      IF @OLEResult <> 0 --PRINT 'OpenTextFile'  
      Begin  
       SET @FileContent_LogMsg = ''  
       Select @FileContent_LogMsg = 'Unable to OpenTextFile to create XML file in this path ' + @FileName  
      End  
      Else  
      Begin  
       --Write Text1  
       execute @OLEResult = sp_OAMethod @FileID, 'WriteLine', Null, @FileContent_LogMsg  
       IF @OLEResult <> 0 --PRINT 'WriteLine'  
       Begin  
        SET @FileContent_LogMsg = ''  
        Select @FileContent_LogMsg = 'Unable to Write XML file in this path ' + @FileName  
       End  
       Else  
       Begin  
        SET @FileContent_LogMsg = ''  
        Select @FileContent_LogMsg = 'XML file Created Successfully in this path ' + @FileName  
       End  
      End  
     End  
    
     EXECUTE @OLEResult = sp_OADestroy @FileID  
     EXECUTE @OLEResult = sp_OADestroy @FS  
    END  
    Else  
    Begin  
     SET @FileContent_LogMsg = ''  
     Select @FileContent_LogMsg = 'Export file path does not exist.'  
    
    END  
  Insert into XMLfilesyncLog(IP,MachineID,Message,[TimeStamp],[Action]) values  
  (@IpAddress,@McInterfaceID,@FileContent_LogMsg,@CurrentDate,'STOP')  
  End  
  --SyedArifM - 27-07-2011 - Till Here  
 END  


 If @tp_int=2 or @tp_int=42 or @tp_int=62  
 BEGIN  

  Insert into Rawdata(datatype,IPAddress,Mc,Comp,Opn,Opr,Sttime,Ndtime,SPLSTRING2,Status,WorkOrderNumber,SPLString3)values  
  (@tp_int,@IpAddress,@McInterfaceID,@component,@operation,@operator, @startdate+ ' ' + @starttime,@enddate+ ' ' + @endtime,@downcode,0,@WorkOrder,@PJCYear)  
  ---mod 5  
--SK  
--  set @Slno_Rdata=''  
  set @Slno_Rdata=@@identity  
  --print @Slno_Rdata  
  --return  
  --SyedArifM - 27-07-2011 - From Here - DOWNTIME  
  select top 1 @AllowXMLGeneration=ValueInText from Shopdefaults where Parameter = 'AllowXMLGeneration'  
  select top 1 @BasePath = ValueInText from Shopdefaults where Parameter = 'XMLFilePath'  
  IF @AllowXMLGeneration = 'Y'  
  Begin  
   IF @BasePath <> ''  
    Begin  
     SET @CurrentDate = GETDATE()  
     SET @YYYYMMDD = REPLACE(CONVERT(char(10), @CurrentDate, 111), '/', '-')  
     SET @HHMMSS = REPLACE( CONVERT(char(12), @CurrentDate, 114) ,':', '-') --+ '_'+ @Slno_Rdata  
     SET @CurrentDatetxt = Convert(nvarchar,@CurrentDate,120)  
--     SET @FileName = @BasePath + @McInterfaceID + '_' + @YYYYMMDD + '_' + @HHMMSS + '.xml' --DR0306 Commented  
     SET @FileName = @BasePath + @McInterfaceID + '_' + @YYYYMMDD + '_' + @HHMMSS + '_'+ @Slno_Rdata + '.xml' --DR0306 Added  
     
--select @FileName  
--return  
     set @FileContent_LogMsg = '<?xml version="1.0" encoding="UTF-8"?><LS><Version>LSTPM1.0</Version><Plant></Plant><CellName>'+ @McInterfaceID +'</CellName><LSType>DOWNTIME</LSType><LSTime1>'+ @startdate+ ' ' + @starttime +'</LSTime1><LSTime2>'+ @enddate
+ ' ' + @endtime +'</LSTime2><Reason>'+ @downcode +'</Reason></LS>'  
       
     EXECUTE @OLEResult = sp_OACreate 'Scripting.FileSystemObject', @FS OUT  
     IF @OLEResult <> 0 --PRINT 'Scripting.FileSystemObject'  
     Begin  
      SET @FileContent_LogMsg = ''  
      Select @FileContent_LogMsg = 'Unable to create FileSystemObject.'  
     End  
     Else  
     Begin    
      --Open a file  
      execute @OLEResult = sp_OAMethod @FS, 'OpenTextFile', @FileID OUT, @FileName, 8, 1  
      IF @OLEResult <> 0 --PRINT 'OpenTextFile'  
      Begin  
       SET @FileContent_LogMsg = ''  
       Select @FileContent_LogMsg = 'Unable to OpenTextFile to create XML file in this path ' + @FileName  
      End  
      Else  
      Begin  
       --Write Text1  
       execute @OLEResult = sp_OAMethod @FileID, 'WriteLine', Null, @FileContent_LogMsg  
       IF @OLEResult <> 0 --PRINT 'WriteLine'  
       Begin  
        SET @FileContent_LogMsg = ''  
        Select @FileContent_LogMsg = 'Unable to Write XML file in this path ' + @FileName  
       End  
       Else  
       Begin  
        SET @FileContent_LogMsg = ''  
        Select @FileContent_LogMsg = 'XML file Created Successfully in this path ' + @FileName  
       End  
      End  
     End  
    
     EXECUTE @OLEResult = sp_OADestroy @FileID  
     EXECUTE @OLEResult = sp_OADestroy @FS  
    END  
    Else  
    Begin  
     SET @FileContent_LogMsg = ''  
     Select @FileContent_LogMsg = 'Export file path does not exist.'  
    
    END  
  Insert into XMLfilesyncLog(IP,MachineID,Message,[TimeStamp],[Action]) values  
  (@IpAddress,@McInterfaceID,@FileContent_LogMsg,@CurrentDate,'DOWNTIME')  
  End  
  --SyedArifM - 27-07-2011 - Till Here  
 END  
   
   
 --For In cycle or spindle DOWN record insert into rawdata table.  
 /*If @tp_int=42  
    Begin  
    
 --s_Getprocessdatastring 'START-40-2-123-20081021-090200-END-','172.36.0.206'  
  Insert into Rawdata(datatype,IPAddress,Mc,Comp,Opn,Opr,Sttime,Ndtime,SPLString2,Status)Values  
 (@tp_int,@IPAddress,@MCInterfaceid,@Component,@Operation,@Operator,@Startdate + ' ' + @Starttime,@Enddate + ' ' + @Endtime,@Downcode,0)  
    End   
 --Type 62:In cycle or POWER_ON_OFF DOWN record  
 If @tp_int=62  
   Begin  
  Insert into Rawdata(datatype,IPAddress,MC,Comp,Opn,Opr,Sttime,Ndtime,SPLString2,status)Values  
 (@tp_int,@IPAddress,@MCInterfaceid,@Component,@Operation,@Operator,@Startdate + ' ' + @Starttime,@Enddate + ' ' + @Endtime,@Downcode,0)  
   End*/  
 SET @Error = @@ERROR  
 If @Error<>0  
    BEGIN  
  RAISERROR('Error In inserting the records in rawdata table[%s] - %s',16,1,@IpAddress,@Orgstring)  
  return -1;  
    END  
END--IFtype1r2r42r62  
/******************************************************************************  
 Type 40, 41 Record  
 START-DataType-MachineId-ToolDir-sDate-sTime-END-  
SPINDLE ON/OFF  
Optional stop:START-70-MachineID-0-StDate-StTime-END  
Optional start:START-71-MachineID-0-StDate-StTime-END  
*******************************************************************************/  
--mod 3. Processing optional stop and start records  
---If @tp_int = 40 or @tp_int = 41 -- ER0094  
If @tp_int = 40 or @tp_int = 41  or @tp_int = 70 or @tp_int = 71  
--mod 3  
BEGIN  
  If @StrLen<6  
  BEGIN  
       RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  DECLARE @ToolDir_ int  
    
      --machine:eliminate machine:later check it out  
  --SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
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
  Begin   
   Insert into Rawdata(datatype,IPAddress,MC,Sttime,SplString2,status)  
   VALUES(  
     @tp_int ,  
     @Ipaddress,  
     @Mcinterfaceid,  
     @startdate + ' ' + @starttime,  
     @ToolDir_,  
     0  
         )  
  End  
  ELSE  
  BEGIN  
   RAISERROR('Error In inserting the records in rawdata table[%s] - %s',16,1,@IpAddress,@Orgstring)  
      RETURN -1;  
  END  
  SET @Error = @@ERROR  
  IF @Error <> 0  
  BEGIN  
     RAISERROR('Error In inserting the records in rawdata table[%s] - %s',16,1,@IpAddress,@Orgstring)  
     RETURN -1;  
  END  
End  
/******************************************************************************  
 Type 60, 61 Record  
 START-DataType-MachineId-Date-Time-END-  
POWER ON/OFF  
*******************************************************************************/  
 If @tp_int = 60 or @tp_int = 61 -- ER0094  
 BEGIN  
  --machine:eliminate machine :later check  it out  
--  SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 -- SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
  --startdate  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
  --starttime  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)         
    
         If (IsDate(@startdate + ' ' + @starttime) = 1 )  
          Insert into Rawdata(datatype,IPAddress,MC,Sttime,status)  
   VALUES( 
     @tp_int,@IPAddress,@Mcinterfaceid,  
     @startdate + ' ' + @starttime,0       
            )  
  ELSE  
  BEGIN  
   RAISERROR ('Error inserting record into Rawdata for %s', 16, 1,@orgstring)  
      RETURN -1;  
  END  
  SET @Error = @@ERROR  
  IF @Error <> 0  
  BEGIN  
     RAISERROR ('Error inserting record into Rawdata for %s', 16, 1,@orgstring)  
     RETURN -1;  
  END  
 RETURN -1;  
 End  
/*****************************************************************************************  
 Type 3 Record  
 START-3-MC-ProgNo-END  
 Program Transfer  
******************************************************************************************/  
If @tp_int=3  
BEGIN  
 If @StrLen<3  
 BEGIN  
 RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
 END  
  --ProgramID  
         SET @ProgramID = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
  -- Insert Into Rawdata(Datatype,IPAddress,Mc,SPLSTRING1,Status)Values  
  --(@tp_int,@IpAddress,@McInterfaceID,@ProgramID,0)  
  --DECLARE @PortNO as int  
  --SET @PortNo = -1  
  --SELECT @PortNO = onlinemachinelist.portno FROM onlinemachinelist INNER JOIN machineinformation ON onlinemachinelist.machineid = machineinformation.machineid  WHERE machineinformation.InterfaceID = @McInterfaceID  
  --IF @PortNo <> -1  
  --Begin  
   select  @McInterfaceID ,@ProgramID , @LogicalPortNo  
--mod 16:-  
   --INSERT INTO ProgramHistory(MachineID, ProgramID,PortNo) VALUES ( @McInterfaceID ,@ProgramID , @LogicalPortNo)  
   INSERT INTO ProgramHistory(MachineID, ProgramID,PortNo,RequestingModuleName) VALUES ( @McInterfaceID ,@ProgramID , @LogicalPortNo, 'SmartData')  
--mod 16:-  
  --End  
 -- if error occurs raise the error  
  SET @Error = @@ERROR  
  If @Error<>0  
      BEGIN  
    RAISERROR('Error In inserting the records in rawdata table[%s] - %s',16,1,@IpAddress,@Orgstring)  
  return -1;  
      END  
END --type3  
   
/******************************************************************************  
 Type 4 Record  
 START-DataType-MC-ToolDir-sDate-sTime-EDate-ETime-END-  
SPINDLE ON/OFF  
*******************************************************************************/  
If @tp_int=4  
BEGIN  
 If @StrLen<7  
 BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
          return -1;  
 END  
   
 --ToolDir  
 SET @ToolDir = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS INT)  
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
 --PRINT @enddate  
 SET @enddate = dbo.f_GetTpmStrToDate(@enddate,GetDate())         
 --PRINT @enddate  
   
 --endtime  
 SET @endtime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 --PRINT @endtime  
 SET @endtime = dbo.f_GetTpmStrToTime(@endtime)  
--PRINT @endtime  
   
 Insert Into Rawdata(Datatype,IPAddress,Mc,SPLSTRING1,Sttime,Ndtime,Status)Values  
(@tp_int,@IpAddress,@McInterfaceID,@ToolDir,@startdate + ' '+ @starttime,@enddate+ ' ' + @endtime,0 )  
 SET @Error = @@ERROR  
 If @Error<>0  
    BEGIN  
  RAISERROR('Error In inserting the records in rawdata table[%s] - %s',16,1,@orgstring)  
  return -1;  
    END  
END--type4  
/************************************************************************************************  
 Type 5 Record  
 Tool Change - START-DataType-ToolNo-sDate-sTime-END-  
***********************************************************************************************/  
If @tp_int=5  
BEGIN  
    If @StrLen<5  
 BEGIN  
      RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)  
            return -1;  
 END  
   DECLARE @ToolNo As Int  
   
  --ToolNo  
      SET @ToolNo = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  --startdate  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
  --starttime  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
        Insert Into Rawdata(Datatype,IPAddress,Mc,SPLSTRING1,Sttime,Status)values  
   (@tp_int,@IpAddress,@McInterfaceID,@ToolNo,@startdate + ' ' +@starttime,0)  
    
        SET @Error = @@ERROR         If @Error<>0  
    BEGIN  
   RAISERROR('Error In inserting the records in rawdata table[%s] - %s',16,1,@IpAddress,@Orgstring)  
   return -1;  
    END  
END--type5  
  
/************************************************************************************************  
 Type 6 Record -->   
Alarm Type Format :: START-6-PALARMNo-PsDate-PsTime-END-  
Shanthi format :: Start-6-MachineID-P600-Component ID - Operation ID- Serial Number-Status-Current date -Current Time-End  
Sample string :: s_GetProcessDataString 'START-6-252-P600-99-2-ZD289C-1-20151031-000549-END  ','172.36.0.252','','33'  
***********************************************************************************************/  
If @tp_int=6  
BEGIN  
  
   --ER0417 Commented From Here  
--   If @StrLen<5  
--   BEGIN  
--    RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
--         return -1;  
--   END  
   --ER0417 Commented Till Here  
       
   --If  @StrLen = 5 --ER0417 Added Line --ER0435  
   If @StrLen = 6 --ER0417 Added Line --ER0435  
   BEGIN  --ER0417 Added Line  
  
     DECLARE @AlarmNo nvarchar(100)    
           
     --AlarmNo  
     SET @AlarmNo = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
     SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     select @AlarmNo,SUBSTRING(@datastring,2,CHARINDEX('-',@datastring) - 2)  
     --startdate  
     --mod 12  
         ---SET @startdate = SUBSTRING(@datastring,2,CHARINDEX('-',@datastring) - 2)  
     SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
     --mod 12  
     SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
     select @startdate,@datastring  
     --starttime  
     ---mod 12  
     ---SET @starttime = SUBSTRING(@datastring,2,CHARINDEX('-',@datastring) - 2)  
     SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
     select @starttime  
     SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     SET @starttime = dbo.f_GetTpmStrToTime(@starttime)     
     
       Insert Into Rawdata(Datatype,IPAddress,Mc,Sttime,SPLSTRING2,Status)values  
      (@tp_int,@IpAddress,@McInterfaceID,@startdate + ' ' +@starttime,@AlarmNo,0)  
      
      
    SET @Error = @@ERROR  
    If @Error<>0  
       BEGIN  
     RAISERROR('Error In inserting the records in rawdata table[%s] - %s',16,1,@orgstring)  
     return -1;  
    END  
   END  --ER0417 Added Line  
  
   ------------------------------------ ER0417 Added From Here ------------------------------------------  
   If  @StrLen = 10   
   Begin  
  
     declare @Number as nvarchar(50)  
     declare @StatusFlag as  int  
  
     SET @Number =convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
     SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
       
     SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
     SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')  
     SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
     SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
     SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  
     if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
     begin    
      set @WorkOrder=convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
	  SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
      SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     end  
  
     SET @StatusFlag = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
     SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  
     --Currentdate  
     SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
     SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
       
     --Currenttime  
     SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
     SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
       
       
     create table #ShiftTemp  
     (  
     StartDate datetime,  
     ShiftName nvarchar(50),  
     Starttime datetime,  
     EndTime datetime,  
     ShiftID int  
     )  
  
     Declare @CurrentTime datetime  
     set @CurrentTime= @startdate + ' ' + @starttime  
  
     insert into #ShiftTemp(StartDate,Shiftname,Starttime,Endtime,Shiftid)  
     exec [s_GetCurrentShiftTime] @CurrentTime,''  
  
     declare @Dt as nvarchar(50)  
     declare @ShiftName as nvarchar(50)  
     select @Dt= CONVERT(char(10), StartDate,126) from #ShiftTemp  
     select @ShiftName=shiftname from  #ShiftTemp   
           
  
    insert into [dbo].[QualityInspectDetails] (MachineID,ComponentID,OperationNo,WorkOrderNo,[Status],[CreatedTS],[Date],[Shift])  
    values(@McInterfaceID,@component,@operation,@WorkOrder,@StatusFlag,@startdate+' '+@starttime,@Dt,@ShiftName)  
  
   End  
   ---------------------- ER0417 Added Till Here -------------------------------------  
END--IFTYPE 6   
  
  
/************************************************************************************************  
Added by Shilpa for Bosch  
Type 16 Record --> Binary Signal which determines the machine events from HMI (For Bosch)  
START-DataType-Machineid-EventValue-Date-Time-END-  
***********************************************************************************************/  
If @tp_int = 16  
 BEGIN  
      DECLARE @EventValue nvarchar(100)  
    
      --machine:later check it out  
--      SET @machine = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
--  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
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
  BEGIN  
    --SET @EventValue = SUBSTRING(@EventValue,2,LEN(@EventValue)-1)  
    INSERT INTO Rawdata (Datatype,IPAddress,Mc, SPLSTRING2,Sttime,Status)  
    VALUES(@tp_int, @IPAddress ,@McInterfaceID, @EventValue,@startdate + ' ' + @starttime,0 )  
  END  
    
  SET @Error = @@ERROR  
  --print @Error  
   
  IF @Error <> 0  
  BEGIN    
     RAISERROR ('Error inserting Binary Signal record for %s', 16, 1,@orgstring)  
     RETURN -1;  
  END  
 End  --iftype16  

 /************************************************************************************************  
Type 36 Record -->inserting Spindle Runtime data to new table "SpindleRuntimeDataInfo"  
START-DataType-Machineid-Runtime-Date-Time-END-  
exec s_GetProcessDataString 'START-36-111-10.5-20200520-161000-END','127.0.0.1','','33' 
exec s_GetProcessDataString 'START-36-724-F002B10595-1-[130]-[255]-20220511-181505-20220511-181606-END','127.0.0.1','','33' 
***********************************************************************************************/  
If @tp_int = 36  
 BEGIN  
      
	IF @StrLen=6
	BEGIN
		  DECLARE @Runtime float 
	      
		  --Runtime  
		  SET @Runtime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
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
		  BEGIN 
			IF NOT EXISTS(Select * from SpindleRuntimeDataInfo where MachineID=@McInterfaceID and UpdatedTS = @startdate+' '+@starttime)
			begin
				INSERT INTO SpindleRuntimeDataInfo (Datatype,MachineID, Runtime,UpdatedTS)  
				VALUES(@tp_int,@McInterfaceID, @Runtime,@startdate + ' ' + @starttime) 
			end
		  END  
    END

	IF @StrLen=11
	BEGIN
		Declare @FlowValue1 Decimal(18,4)
		Declare @FlowValue2 Decimal(18,4)

		  SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
  
		  SET @FlowValue1 = SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  
		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
  
		  set @FlowValue2=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  
		  SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
  
		  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
		  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  
		  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)    
		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
		  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
		  SET @Enddate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)    
		  SET @Enddate = dbo.f_GetTpmStrToDate(@Enddate,getdate())  
  
		  SET @Endtime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)   
		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)    
		  SET @Endtime = dbo.f_GetTpmStrToTime(@Endtime)  

		 create table #ShiftTbl  
		 (  
			 StartDate datetime,  
			 ShiftName nvarchar(50),  
			 Starttime datetime,  
			 EndTime datetime,  
			 ShiftID int  
		 )  
  
		 Declare @CurTime datetime  
		 set @CurrentTime= @enddate + ' ' + @endtime  
  
		 insert into #ShiftTbl(StartDate,Shiftname,Starttime,Endtime,Shiftid)  
		 exec [s_GetCurrentShiftTime] @CurrentTime,''  

		 declare @ShiftName1 as nvarchar(50)  
		 select @ShiftName1=shiftname from  #ShiftTbl   

		 declare @ShiftID1 as nvarchar(50)  
		 select @ShiftID1=shiftID from  #ShiftTbl  


		  SELECT DISTINCT (@startdate+ ' ' + @starttime) as StartTime,(@enddate+ ' ' + @endtime) as Endtime,M.machineid,M.description,C.componentid,COP.operationno,@FlowValue1 as Flowvalue1,@FlowValue2 as Flowvalue2
		,isnull((case when M.description='HEAD CLEARANCE' then FM.HeadMaxFlowValue 
			--when M.description='SHAFT CLEARANCE' then 0  end),0) as MaxFlowValue,
			when M.description='SHAFT CLEARANCE' then FM.ShaftMaxFlowValue  end),0) as MaxFlowValue,
			isnull((case when M.description='HEAD CLEARANCE' then FM.HeadMinFlowValue 
			when M.description='SHAFT CLEARANCE' then 0  end),0) as MinFlowValue 	   into #FlowMeter
			from machineinformation M  
		INNER JOIN PlantMachine P ON M.machineid = P.MachineID
		INNER JOIN componentinformation C ON C.InterfaceID = @component
		INNER JOIN componentoperationpricing COP ON COP.InterfaceID = @operation  AND  COP.machineid = M.machineid AND COP.componentid = C.componentid 
		Left outer join Bosch_FlowMeterSpecification FM on FM.PartNumber=COP.componentid
		Where ( M.InterfaceID  = @McInterfaceID)
		ORDER BY M.machineid,C.componentid

		INSERT INTO BOSCH_FlowMeter (Mc,Comp,opn,FlowValue1,FlowValue2,Starttime,Endtime)
		VALUES (@McInterfaceID,@component,@operation,@FlowValue1,@FlowValue2,@startdate+ ' ' + @starttime,@enddate+ ' ' + @endtime)


		INSERT INTO BOSCH_FlowMeter_Details (machineid,componentid,operationno,StartTime,Endtime,Flowvalue1,Flowvalue2,Result1,Result2,ShiftName,ShiftID)
		select machineid,componentid,operationno,StartTime,Endtime,Flowvalue1,Flowvalue2,
		--(Case when (Flowvalue1>=(MinFlowValue-20) and Flowvalue1<=(MaxFlowValue+20)) then 'Ok' when Flowvalue1<(MinFlowValue-20) Then 'Less'  when Flowvalue1> (MaxFlowValue+20) Then 'More' End) as Result1, 
		--(Case when (Flowvalue2>=(MinFlowValue-20) and Flowvalue2<=(MaxFlowValue+20)) then 'Ok' when Flowvalue2<(MinFlowValue-20) Then 'Less'  when Flowvalue2> (MaxFlowValue+20) Then 'More' End) as Result2,
		(Case when (description='HEAD CLEARANCE' and (Flowvalue1>=(MinFlowValue-20) and Flowvalue1<=(MaxFlowValue+20))) then 'Ok' when ( description='HEAD CLEARANCE' and Flowvalue1<(MinFlowValue-20)) Then 'Less'  when (description='HEAD CLEARANCE' and Flowvalue1> (MaxFlowValue+20)) Then 'More'
			  when (description='SHAFT CLEARANCE' and (Flowvalue1>=(MinFlowValue) and Flowvalue1<=(MaxFlowValue+20))) then 'Ok' when ( description='SHAFT CLEARANCE' and Flowvalue1<(MinFlowValue)) Then 'Less'  when (description='SHAFT CLEARANCE' and Flowvalue1> (MaxFlowValue+20)) Then 'More' End) as Result1, 
		(Case when (description='HEAD CLEARANCE' and (Flowvalue2>=(MinFlowValue-20) and Flowvalue2<=(MaxFlowValue+20))) then 'Ok' when ( description='HEAD CLEARANCE' and Flowvalue2<(MinFlowValue-20)) Then 'Less'  when (description='HEAD CLEARANCE' and (Flowvalue2> (MaxFlowValue+20))) Then 'More'
			  when (description='SHAFT CLEARANCE' and (Flowvalue2>=(MinFlowValue) and Flowvalue2<=(MaxFlowValue+20))) then 'Ok' when ( description='SHAFT CLEARANCE' and Flowvalue2<(MinFlowValue)) Then 'Less'  when (description='SHAFT CLEARANCE' and (Flowvalue2> (MaxFlowValue+20))) Then 'More' End) as Result2,
		@ShiftName1,@ShiftID1 from #FlowMeter
	
	END
  SET @Error = @@ERROR  
  --print @Error  
   
  IF @Error <> 0  
  BEGIN    
     RAISERROR ('Error inserting Spindle Runtime record for %s', 16, 1,@orgstring)  
     RETURN -1;  
  END  
 End  --iftype36  
/***********************************************************************************************  
Added by Shilpa  for Bosch  
Type 9 record--> DNC transfer(Program Push logic)  
START-Datatype-Machineid-ProgramNo-END  
***********************************************************************************************/  
if @tp_int=9  
Begin  
 If @StrLen<3  
 BEGIN  
 RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
 END  
  --ProgramID  
         SET @ProgramID = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
 INSERT INTO ProgramHistory(MachineID, ProgramID,PortNo,ServiceProvided) VALUES ( @McInterfaceID ,@ProgramID , @LogicalPortNo,1)  
   
 -- if error occurs raise the error  
  SET @Error = @@ERROR  
  If @Error<>0  
      BEGIN  
    RAISERROR('Error In inserting the records in rawdata table[%s] - %s',16,1,@IpAddress,@Orgstring)  
  return -1;  
      END  
set @OutputPara=9  
 return 9;  
End  
/************************************************************************************************  
NR0049::Added by Shilpa for Bosch  
Type 9 Record --> Record to detect non-prodcutive cycle to indicate that production cycle is non-productive.  
START-DataType-Machineid-Date-Time-END-  
***********************************************************************************************/  
--print 'before 12'  
If @tp_int=12  
Begin  
  --print 'in 12'  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
  --starttime  
    
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
    
  if(isdate(@startdate + ' ' + @starttime) = 1)  
  Begin  
       Insert into rawdata(datatype,Ipaddress,mc,sttime,status)  
        values(@tp_int,@Ipaddress,@mcinterfaceid,@startdate + ' ' + @starttime,0)  
  End  
  set @error=@@error  
  if @error<>0  
  Begin  
     Raiserror('Error inserting the record which detects dummy cylce',16,@Orgstring)  
     Return -1;   
  End  
End--iftype12  
   
--print DATEDIFF(ms,@Time,getdate())  
--mod 2  
/**************************************************************************************************  
. By Mrudula for processing type 11 records  
Type 11--> START-11-mc-Comp-Opn-Opr-StDate-Sttime-END  
*****************************************************************************************************/  
If  @tp_int=11  -- ER0176  
BEGIN  
 --to validat0e the datastring whether it contains the required number of data in the sring  
 If @StrLen<8 --ER0397 Commented --DR0362 Uncommented  
 --If @StrLen<9 --ER0397 To add workordernumber to the datastring --DR0362 Commented  
 BEGIN  
  RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
 END  
 --component  
 --mod 9:  
 --mod 9:Eliminate leading zeros from the component interfaceid  
 --SET @component = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 --SET @component = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0387  

 --SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
 --SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
 
 IF @RemoveLeadZeroInProcessString='Y'
 BEGIN
	if CHARINDEX(']-', @datastring)>0
	Begin
	 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
	 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
	 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
	 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
	 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
	 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End
 END
 ELSE
 BEGIN
	if CHARINDEX(']-', @datastring)>0
	Begin
	 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
	 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
	 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
	 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End
 END
 --mod 9  
 --operation  
 --mod 9:Eliminate leading zeros from the operation interfaceid  
 ---SET @operation = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
 ---mod 9  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
 --select @datastring  
 --operator  
 --mod 9:Eliminate leading zeros from the operation interfaceid  
 ---SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 --SET @operator = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0421  
 SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
 SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
  
 ---mo d9  
-- SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	if CHARINDEX('-[', @datastring)>0
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
	End
	Else
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End 
   
   
 ---ER0397 Added From Here (To Get the WorkOrderNumber from the string if SD settings for WorkOrder is "Y")  
 if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
 begin  
  --set @WorkOrder=convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	if CHARINDEX(']-', @datastring)>0
	Begin
	SET @WorkOrder = SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1) 
	SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
	SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
	SET @WorkOrder=convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
	SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	End
 end  
 --ER0397 Added Till here  
  
 --startdate  
 SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
   
 --starttime  
 SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
 ---ER0397 Added From Here (To Get the WorkOrderNumber from the string if SD settings for WorkOrder is "Y")  
 --Insert into Rawdata(datatype,IPAddress,Mc,Comp,Opn,Opr,Sttime,Ndtime,Status)values  
 --(@tp_int,@IpAddress,@McInterfaceID,@component,@operation,@operator, @startdate+ ' ' + @starttime,@enddate+ ' ' + @endtime,15)  
 Insert into Rawdata(datatype,IPAddress,Mc,Comp,Opn,Opr,Sttime,Ndtime,Status,WorkOrderNumber)values  
 (@tp_int,@IpAddress,@McInterfaceID,@component,@operation,@operator,@startdate+ ' ' + @starttime,@enddate+ ' ' + @endtime,15,@workorder)  
 --ER0397 Added Till here  
  
  
--Sk  
--  set @Slno_Rdata=''  
  set @Slno_Rdata=@@identity  
  --SyedArifM - 27-07-2011 - From Here START  
  select top 1 @AllowXMLGeneration=ValueInText from Shopdefaults where Parameter = 'AllowXMLGeneration'  
  select top 1 @BasePath = ValueInText from Shopdefaults where Parameter = 'XMLFilePath'  
  IF @AllowXMLGeneration = 'Y'  
  Begin  
   IF @BasePath <> ''  
    Begin  
     SET @CurrentDate = GETDATE()  
     SET @YYYYMMDD = REPLACE(CONVERT(char(10), @CurrentDate, 111), '/', '-')  
     SET @HHMMSS = REPLACE( CONVERT(char(12), @CurrentDate, 114) ,':', '-')  
     SET @CurrentDatetxt = Convert(nvarchar,@CurrentDate,120)  
--     SET @FileName = @BasePath + @McInterfaceID + '_' + @YYYYMMDD + '_' + @HHMMSS +'.xml' DR0306 Commented  
     SET @FileName = @BasePath + @McInterfaceID + '_' + @YYYYMMDD + '_' + @HHMMSS +'_'+ @Slno_Rdata +'.xml' --DR0306 Added  
--   select @FileName  
--   return  
     set @FileContent_LogMsg = '<?xml version="1.0" encoding="UTF-8"?><LS><Version>LSTPM1.0</Version><Plant></Plant><CellName>'+ @McInterfaceID +'</CellName><LSType>START</LSType><LSTime1>'+ @startdate+ ' ' + @starttime +'</LSTime1><LSTime2></LSTime2><Rea
son></Reason></LS>'  
       
     EXECUTE @OLEResult = sp_OACreate 'Scripting.FileSystemObject', @FS OUT  
     IF @OLEResult <> 0 --PRINT 'Scripting.FileSystemObject'  
     Begin  
      SET @FileContent_LogMsg = ''  
      Select @FileContent_LogMsg = 'Unable to create FileSystemObject.'  
     End  
     Else  
     Begin    
      --Open a file  
      execute @OLEResult = sp_OAMethod @FS, 'OpenTextFile', @FileID OUT, @FileName, 8, 1  
      IF @OLEResult <> 0 --PRINT 'OpenTextFile'  
      Begin  
       SET @FileContent_LogMsg = ''  
       Select @FileContent_LogMsg = 'Unable to OpenTextFile to create XML file in this path ' + @FileName  
      End  
      Else  
      Begin  
       --Write Text1  
       execute @OLEResult = sp_OAMethod @FileID, 'WriteLine', Null, @FileContent_LogMsg  
       IF @OLEResult <> 0 --PRINT 'WriteLine'  
       Begin  
        SET @FileContent_LogMsg = ''  
        Select @FileContent_LogMsg = 'Unable to Write XML file in this path ' + @FileName  
       End  
       Else  
       Begin  
        SET @FileContent_LogMsg = ''  
        Select @FileContent_LogMsg = 'XML file Created Successfully in this path ' + @FileName  
       End  
      End  
     End  
    
     EXECUTE @OLEResult = sp_OADestroy @FileID  
     EXECUTE @OLEResult = sp_OADestroy @FS  
    END  
    Else  
    Begin  
     SET @FileContent_LogMsg = ''  
     Select @FileContent_LogMsg = 'Export file path does not exist.'  
    
    END  
  Insert into XMLfilesyncLog(IP,MachineID,Message,[TimeStamp],[Action]) values  
  (@IpAddress,@McInterfaceID,@FileContent_LogMsg,@CurrentDate,'START')  
  End  
  --SyedArifM - 27-07-2011 - Till Here  
END ---TYPE 11  
---mod 2  
--mod 7  
/*******************************************************************************************************  
mod 7:- NR0053  
datatype E1 and E2  
String format:-START-@E2-@R0-@D-@T-@L5-@KWH-@KW-@PF-@A-END  
@E2-datatype E1 or E2: for E1 store datatype as 72 and for E2 store it as 72.  
This is because in rawdata the datatype column is int.  
@R0- Machineinterfaceid  
@D-Date  
@T- time  
@L5 - frequency  
@KWH - float value  
@KW - Power (float value)  
@PF-Power factor (float value)  
@A - Ampere (float value)  
mod 8:- ER0179  
New String format :- :-START-@E2-@R0-@D-@T-@L5-[@KWH]-[@KW]-[@PF]-[@A]-END  
mod 11:ER0204:- Change processing of string according to the new string format.  
  The string format is "START-E2-MC-DATE-TIME-L5-KWH-KW-[PF]-AMPERE-END"  
--START-75-202-20140329-23595901-2-4.00615-15.4385-[-0.56]-0.45-END  
*******************************************************************************************************/  
If @tp_int=75  
Begin  
  --startdate  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
    
  --starttime  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
    
    
  --NR0117 Commented From Here and added at the top.  
  /*declare @KWHVal as float  
  declare @KWValue as float  
  Declare @PFValue as Float  
  Declare @AmpValue as float  
  declare @MachineName as nvarchar(50)  
  */  
  --NR0117 Commented ill Here.  
    
  /*---mod 8 commented below code to process values enclosed within square bracket  
  --truncate the string till @KWH  
    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
    
  set @KWHVal=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
    
  set @KWValue=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  set @PFValue=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  set @AmpValue=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  --Commented till here for mod 5---mod 5 */  
  ---mod 8. Modify energy string value processing enclosed within square bracket  
    
  --truncate the string till @KWH  
  --mod 11:Commented below part as KWH and KW will not be enclosed in brackets  
  /*SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
    
    
  set @KWHVal=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 2)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
    
    
  set @KWValue=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 2)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)*/  
    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
    
  set @KWHVal=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
    
  set @KWValue=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)   
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
  --set @PFValue=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 2)  
  set @PFValue=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  
  SET @PFValue = CASE WHEN @PFValue>1 THEN 1 ELSE @PFValue END  
  ---mod 11 commented below part as ampere will not be enclosed within the brackets  
  /*  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
    
  set @AmpValue=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 2)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
    
  Commented till here for mod 11*/  
  ---mod 11  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
  set @AmpValue=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  select @MachineName= Machineid from machineinformation where interfaceid=@McInterfaceID  
  
  --DR0366 Added From Here  
  If isnull(@MachineName,'a')='a'  
  Begin  
   select @MachineName= nodeid from MachineNodeInformation where NodeInterface=@McInterfaceID   
  end  
  
  If isnull(@MachineName,'a')='a'  
  Begin  
   select @MachineName=@McInterfaceID  
  end  
  --DR0366 Added Till Here  
  
  if(isdate(@startdate + ' ' + @starttime) = 1)  
  Begin  
  Begin Transaction  
  
     
      --declare @gtime as datetime --NR0117 Commented   
   --declare @count as int --NR0117 Commented   
  
            select @gtime=isnull(maxgtime ,'1900-01-01') from tcs_energyconsumption_maxgtime where machine=@MachineName  
   select @count = count(machineid) from tcs_energyconsumption where machineid=@MachineName  
   print @count  
   print @gtime  
     
   If isnull(@gtime,'') <>'' and  @gtime < @startdate + ' ' + @starttime  
   begin   
       
     update tcs_energyconsumption set gtime1=@startdate + ' ' + @starttime,ampere1=Round(@AmpValue,2),  
     kwh1=Round(@KWHVal,5) where machineid=@MachineName and gtime=@gtime  
            end  
  
          If (@count = 0) or  (@gtime < @startdate + ' ' + @starttime)  
   begin  
    insert into dbo.tcs_energyconsumption (MachineID,gtime,ampere,watt,pf,KWH)  
    --values (@MachineName,@startdate + ' ' + @starttime,Round(@AmpValue,2),Round(@KWValue,2),Round(@PFValue,2),Round(@KWHVal,2)) --DR0304 Commented  
    values (@MachineName,@startdate + ' ' + @starttime,Round(@AmpValue,2),Round(@KWValue,5),Round(@PFValue,2),Round(@KWHVal,5)) --DR0304 Added              
    SET @Error = @@ERROR  
    IF @Error <> 0 GOTO ERROR_HANDLER  
   end  
  
  END  
    
  If @@TRANCOUNT <> 0  
  Begin  
   COMMIT TRANSACTION  
  end  
  
  IF @Error<> 0  
  BEGIN  
   ERROR_HANDLER:  
   IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION  
   INSERT INTO SmartDataErrorLog(IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@IPAddress,@McInterfaceID,@Error,getdate())    
   SET @Error=0  
  END  
end  
--  --- end for 75  
--mod 7  
---mod 10  
/************************************************************************************************  
Type 17 Record --> Tool change indication record  
START-DataType-ALARMNo-sDate-sTime-ToolCount-END-  
***********************************************************************************************/  
If @tp_int=17  
BEGIN  
 If @StrLen<6  
 BEGIN  
  RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
 END  
 --s_getprocessdatastring 'START-17-1000-0015-20090801-134551-0012-END','172.36.0.206','','1'  
         
  DECLARE @AlarmNo17 nvarchar(100)   
  declare @ToolCount as int  
         
   --AlarmNo  
   --SET @AlarmNo17 = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS INT) --ER0391  
   SET @AlarmNo17 = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS float) --ER0391  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     
   --startdate  
       SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())        
   
   --starttime  
   SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
   set @ToolCount=CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS INT)  
   --storing tool count in SPLSTRING1  
         
         Insert Into Rawdata(Datatype,IPAddress,Mc,SPLSTRING1,Sttime,SPLSTRING2,Status)values  
    (@tp_int,@IpAddress,@McInterfaceID,@ToolCount,@startdate + ' ' +@starttime,@AlarmNo17,0)  
    
    
  SET @Error = @@ERROR  
  If @Error<>0  
     BEGIN    RAISERROR('Error In inserting the records in rawdata table[%s] - %s',16,1,@orgstring)  
   return -1;  
     END  
END--IFTYPE 17  
---mod 10  
--mod 14  
/************************************************************************************************  
--START-DTATYPE(80 OR 81)-MC-HelpReuestID-STDATE-STTIME-END-  
--80 Acknowledge that help request is addressed  
--81 Log help request  
************************************************************************************************/  
If @tp_int = 80 or @tp_int = 81  
BEGIN  
  DECLARE @HelpReuestID nvarchar(100)  
    
  --HelpReuestID  
  SET @HelpReuestID = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
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
  BEGIN  
    INSERT INTO autodatadetails (Machine,RecordType,StartTime,DetailNumber)  
    VALUES(@McInterfaceID,@tp_int,@startdate + ' ' + @starttime,@HelpReuestID )  
  END  
    
  SET @Error = @@ERROR  
  --print @Error  
   
  IF @Error <> 0  
  BEGIN    
     RAISERROR ('Error inserting Help Reuest or Acknowledgement record for %s', 16, 1,@orgstring)  
     RETURN -1;  
  END  
End  
--mod 14  
--mod 17: From Here  
/************************************************************************************************  
--START-DTATYPE(26) 'START-Datatype-MC-Address-Value-StartDate-StartTime-END'  
--START-DTATYPE(85) 'START-Datatype-MC-Address-Value-StartDate-StartTime-END' - Change mod 18  
--'START-26-218-10000100-00001111-20100225-183008908-END'  
--'START-85-218-10000100-00001111-20100225-183008908-END' - Change mod 18  
--s_GetProcessDataString 'START-26-218-10000100-00001111-20100225-183008908-END','127.0.0.1','','33'  
--s_GetProcessDataString 'START-85-218-10000100-00001111-20100225-183008908-END','127.0.0.1','','33' - Change mod 18  
************************************************************************************************/  
 --If @tp_int=26 -- mod 18  
 If @tp_int=85 -- mod 18  
 Begin  
  If @StrLen<7  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
   
    
  SET @Address = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
  --select @Address  
    
   select @Address=case @Address  
    when '10000001' then '129'  
    when '10000010' then '130'  
    when '10000100' then '132'  
    when '10001000' then '136'  
   End   
    
  -- select @Address  
      
   SET @Value = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
   --select @Value  
    select @Value1=''  
    
    If SUBSTRING(@value,8,1)='1'  
    BEGIN  
     SELECT @value1 =@value1 + '.0,' --insert statement for Alaram  
    END  
     
    If SUBSTRING(@value,7,1)='1'  
    BEGIN  
     SELECT @value1 =@value1 + '.1,' --insert statement for Alaram  
    END  
     
    If SUBSTRING(@value,6,1)='1'  
    BEGIN  
     SELECT @value1 =@value1 + '.2,' --insert statement for Alaram  
    END  
     
    If SUBSTRING(@value,5,1)='1'  
    BEGIN  
     SELECT @value1 =@value1 + '.3,' --insert statement for Alaram  
    END  
     
    
   SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
   SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
    
   --Select @startdate  
   
   SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
   SET @starttime = dbo.f_GetTpmStrToTime(@starttime)         
    
   --Select @starttime  
    
   If 'END'=@datastring  
          BEGIN  
    --set @SubDataString=SUBSTRING(@datastring,1,len(@datastring)-3)  
    SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1) -- Remove  
    --select @datastring      
          END     
   WHILE CHARINDEX(',',@value1)>0  
    BEGIN  
      
    If (IsDate(@startdate + ' ' + @starttime) = 1)  
    BEGIN  
     INSERT INTO Rawdata (Datatype,IPAddress,Mc, SPLSTRING2,Sttime,Status)  
     VALUES(@tp_int, @IPAddress ,@McInterfaceID, @Address + SUBSTRING(@value1,1,CHARINDEX(',',@value1)-1),@startdate + ' ' + @starttime,0 )  
    END  
    
    SET @Error = @@ERROR  
    IF @Error <> 0  
    BEGIN    
       RAISERROR ('Error inserting Binary Signal record for %s', 16, 1,@orgstring)  
       RETURN -1;  
    END  
    SET @value1= SUBSTRING(@value1,CHARINDEX(',',@value1)+1,LEN(@value1)-CHARINDEX(',',@value1)+1)  
   End  
 End  
--mod 17: Till Here  
--mod 19: From Here  
/************************************************************************************************  
--START-DTATYPE(26) 'START-Datatype-MC-Address-Value-StartDate-StartTime-END'  
--'START-26-218-10000100-00001111-20100225-183008908-END'  
--s_GetProcessDataString 'START-26-218-10000100-00001111-20100225-183008908-END','127.0.0.1','','33'  
************************************************************************************************/  
 if @tp_int=26  
 Begin  
  If @StrLen<7  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
   
    
  SET @Address = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
   select @Addressint = [dbo].[udf_MSBbin_int](@Address)  
    
   SET @Value = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
   --select @Value  
    select @Value1=''  
    
    If SUBSTRING(@value,8,1)='1'  
    BEGIN  
     SELECT @value1 =@value1 + '.0,' --insert statement for Alaram  
    END  
     
    If SUBSTRING(@value,7,1)='1'  
    BEGIN  
     SELECT @value1 =@value1 + '.1,' --insert statement for Alaram  
    END  
     
    If SUBSTRING(@value,6,1)='1'  
    BEGIN  
     SELECT @value1 =@value1 + '.2,' --insert statement for Alaram  
    END  
     
    If SUBSTRING(@value,5,1)='1'  
    BEGIN  
     SELECT @value1 =@value1 + '.3,' --insert statement for Alaram  
    END  
     
    
   SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
   SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
    
   --Select @startdate  
   
   SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
   SET @starttime = dbo.f_GetTpmStrToTime(@starttime)         
    
   --Select @starttime  
    
   If 'END'=@datastring  
          BEGIN  
    --set @SubDataString=SUBSTRING(@datastring,1,len(@datastring)-3)  
    SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1) -- Remove  
    --select @datastring      
          END     
   WHILE CHARINDEX(',',@value1)>0  
    BEGIN  
      
    If (IsDate(@startdate + ' ' + @starttime) = 1)  
    BEGIN  
     INSERT INTO Rawdata (Datatype,IPAddress,Mc, SPLSTRING2,Sttime,Status)  
     VALUES(@tp_int, @IPAddress ,@McInterfaceID, @Addressint + SUBSTRING(@value1,1,CHARINDEX(',',@value1)-1),@startdate + ' ' + @starttime,0 )  
    END  
    
    SET @Error = @@ERROR  
    IF @Error <> 0  
    BEGIN    
       RAISERROR ('Error inserting Binary Signal record for %s', 16, 1,@orgstring)  
       RETURN -1;  
    END  
    SET @value1= SUBSTRING(@value1,CHARINDEX(',',@value1)+1,LEN(@value1)-CHARINDEX(',',@value1)+1)  
   End  
 End  
--mod 19: Till Here  
--ER0327 :: Begin - Sneha K  
/************************************************************************************************  
START-20-MachineID-CompID-OperationID-OperatorID-RejectionCode- RejectionQty-StDate-StTime-END(old one)  
START-20-MachineID-CompID-OperationID-OperatorID-RejectionCode- RejectionQty-RejDate-RejShift-StDate-StTime-END  
--'start-20-222-3333-4-5-77-78-20120720-041700-end'  
s_GetProcessDataString 'start-20-222-3333-4-5-77-78-20110420-C-20120720-041700-end','127.0.0.1','','33'  
s_GetProcessDataString 'start-20-3-2361990-1-1-55-78-20110420-1-20120720-041700-end','127.0.0.1','','33'  
************************************************************************************************/  
if @tp_int=20  
 Begin  
  If @StrLen<12 --ER0397 Commented --DR0362 Uncommented  
  --If @StrLen<13--ER0397 --DR0362 Commented  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  
  --SET @component = convert(bigint,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0387  
  ----SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0387  
  ----SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
  
  --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  --NR0157 From here

  IF @RemoveLeadZeroInProcessString='Y'
  BEGIN
	if CHARINDEX(']-', @datastring)>0
	Begin
		SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
		SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
		SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
		SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End
 END
 ELSe
 BEGIN
	if CHARINDEX(']-', @datastring)>0
	Begin
		SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
		SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End
 END
    --NR0157 Till here
  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  --SET @operator = convert(int,sUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0421  
  SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
  SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @RejCode = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @RejQty = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @RejDate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  If @RejDate = 0  
  BEGIN  
   SET @RejDate = '1900-01-01 00:00:00.000'  
  END  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  --SET @RejShift = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) --DR0333  
  SET @RejShift = Convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --DR0333  
  If @RejShift = 0  
  BEGIN  
   SET @RejShift = NULL  
  END  
  
     --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1) 
	if CHARINDEX('-[', @datastring)>0
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
	End
	Else
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End 


  ---ER0397 Added From Here (To Get the WorkOrderNumber from the string if SD settings for WorkOrder is "Y"  
  --if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
  --begin    
  -- SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  -- set @WorkOrder=convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  --end  
 if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
 begin  
	if CHARINDEX(']-', @datastring)>0
	Begin
	SET @WorkOrder = SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1) 
	SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
	SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
	SET @WorkOrder=convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
	SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	End
 end  
  ---ER0397 Added Till Here  
  
  --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
    
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
  --select @rejrecordid = isnull(max(recordid),0) from autodatarejections --ER0349 Commented  
    select @rejrecordid = isnull(max(recordid),0) from autodatarejections where flag='Rejection' --ER0349 Commented  
   
   If (IsDate(@startdate + ' ' + @starttime) = 1)  
   BEGIN  
     
    --ER0349 From Here  
    --insert into AutodataRejections(mc,comp,opn,opr,rejection_code,rejection_qty,createdts,rejdate,rejshift,recordid)  
    --values(@McInterfaceID,@component,@operation,@operator,@RejCode,@RejQty,@startdate+' '+@starttime,@RejDate,@Rejshift,@rejrecordid+1)  
  
    --ER0397 Commented From Here  
    --    IF NOT EXISTS(Select * from autodatarejections where mc=@McInterfaceID and comp=@component and opn=@operation and opr=@operator and rejection_code=@RejCode and rejection_qty=@RejQty and   
    --     createdts = @startdate+' '+@starttime and rejdate=@RejDate and rejshift=@Rejshift and flag='Rejection') --DR0329 added  
    --    BEGIN  --DR0329 added  
    --     insert into AutodataRejections(mc,comp,opn,opr,rejection_code,rejection_qty,createdts,rejdate,rejshift,recordid,flag)  
    --     values(@McInterfaceID,@component,@operation,@operator,@RejCode,@RejQty,@startdate+' '+@starttime,@RejDate,@Rejshift,@rejrecordid+1,'Rejection')  
    --    --ER0349 Till Here  
    --    END --DR0329 added  
    --ER0397 Commented Till Here  
      
    --NR0119 Added From Here  
    Declare @CreatedTs as datetime  
    Declare @RejectedTS as nvarchar(50)  
    Select @RejectedTS = dbo.f_GetTpmStrToDate(@RejDate,getdate())  +' '+ @starttime  
  
    If @RejDate <> '1900-01-01 00:00:00.000'  
    BEGIN  
     Insert into #RejTimestamp(CreatedTs)   
     Exec [dbo].[s_GetRejectionTimestamp] @RejectedTS  
  
     Select @CreatedTs = CreatedTs from #RejTimestamp  
    END  
    ELSE  
    BEGIN  
     Select @CreatedTs = @startdate+' '+@starttime  
    END  
    --NR0119 Added Till Here  
      
    --ER0397 Added From Here  
    IF NOT EXISTS(Select * from autodatarejections where mc=@McInterfaceID and comp=@component and opn=@operation and opr=@operator and rejection_code=@RejCode and rejection_qty=@RejQty and   
     createdts = @CreatedTs and rejdate=@RejDate and isnull(rejshift,'0')=isnull(@Rejshift,'0') and flag='Rejection' and WorkOrderNumber=@workorder) --DR0329 added --ER0397 Included WorkOrder  
    BEGIN  --DR0329 added  
     insert into AutodataRejections(mc,comp,opn,opr,rejection_code,rejection_qty,createdts,rejdate,rejshift,recordid,flag,WorkOrderNumber)  
     --values(@McInterfaceID,@component,@operation,@operator,@RejCode,@RejQty,@startdate+' '+@starttime,@RejDate,@Rejshift,@rejrecordid+1,'Rejection',@Workorder) ---NR0119 Commented  
     values(@McInterfaceID,@component,@operation,@operator,@RejCode,@RejQty,@CreatedTs,@RejDate,@Rejshift,@rejrecordid+1,'Rejection',@Workorder) ---NR0119 Added  
    --ER0349 Till Here  
    END --DR0329 added  
    --ER0397 Added Till Here  
   END  
  
  
   SET @Error = @@ERROR  
      If @Error<>0  
      BEGIN    RAISERROR('Error In inserting the records in AutodataRejections table[%s] - %s',16,1,@orgstring)  
   return -1;  
      END  
 End  
--ER0327 :: End - Sneha K  
  
/***************************************  ER0349 From Here *******************************************/  
--START-25-MachineID-CompID-OperationID-OperatorID-ReworkCode-ReworkQty-ReworkDate-ReworkShift-StDate-StTime-END  
  
if @tp_int=25  
 Begin  
  
  If @StrLen<12 --ER0397 Commented --DR0362 Uncommented   
  --If @StrLen<13 --ER0397 --DR0362 Commented  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  
  --SET @component = convert(bigint,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
  --SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
  --SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
  
  IF @RemoveLeadZeroInProcessString='Y'
  BEGIN
	if CHARINDEX(']-', @datastring)>0
	Begin
		SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
		SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
		SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
		SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End
 END
 ELSe
 BEGIN
	if CHARINDEX(']-', @datastring)>0
	Begin
		SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
		SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End
 END

  --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  --SET @operator = convert(int,sUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0421  
  SET @operator =SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
  SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @MReworkCode = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @MReworkQty = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @MReworkDate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   If @MReworkDate = 0  
  BEGIN  
   SET @MReworkDate = '1900-01-01 00:00:00.000'  
  END  
   
  --SET @MReworkShift = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) --DR0333  
  SET @MReworkShift = Convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --DR0333  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   If @MReworkShift = 0  
  BEGIN  
   SET @MReworkShift = NULL  
  END  
   
        --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 0,LEN(@datastring) - CHARINDEX('-', @datastring)+ 2)  

  ---ER0397 Added From Here (To Get the WorkOrderNumber from the string if SD settings for WorkOrder is "Y")  
  --if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
  --begin  
  -- set @WorkOrder=convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  -- SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  --end  
 --if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
 --begin  
	--if CHARINDEX('-[', @datastring)>0
	--Begin
	--	SET @WorkOrder = SUBSTRING(@datastring,CHARINDEX('-[',@datastring) + 2,CHARINDEX(']-', @datastring)-3) 
	--	SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	--END
	--ELSE
	--Begin
	--	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1) 
	--	SET @WorkOrder=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	--	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1) 
 
	--End
 --end   

 if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
 begin  
	if CHARINDEX(']-', @datastring)>0
	Begin
	SET @WorkOrder = SUBSTRING(@datastring,2,CHARINDEX(']-',@datastring) - 2) 
	SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
	SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
	SET @WorkOrder=convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) 
	SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	End
 end  

  --ER0397 Added Till here    
  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
    
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
  select @MReworkid = isnull(max(recordid),0) from autodatarejections where flag='MarkedforRework'  
  
   If (IsDate(@startdate + ' ' + @starttime) = 1)  
   BEGIN  
   
    ---ER0397 Commented From Here  
--    IF NOT EXISTS(Select * from autodatarejections where mc=@McInterfaceID and comp=@component and opn=@operation and opr=@operator and rejection_code=@MReworkCode and rejection_qty=@MReworkQty and   
--    createdts = @startdate+' '+@starttime and rejdate=@MReworkDate and rejshift=@MReworkShift and flag='MarkedforRework') --DR0329 added  
--    BEGIN  --DR0329 added  
--     insert into AutodataRejections(mc,comp,opn,opr,rejection_code,rejection_qty,createdts,rejdate,rejshift,recordid,flag)  
--     values(@McInterfaceID,@component,@operation,@operator,@MReworkCode,@MReworkQty,@startdate+' '+@starttime,@MReworkDate,@MReworkShift,@MReworkid+1,'MarkedforRework')  
--    END --DR0329 added  
    ---ER0397 Commented Till Here  
  
    ---ER0397 Added From Here  
    IF NOT EXISTS(Select * from autodatarejections where mc=@McInterfaceID and comp=@component and opn=@operation and opr=@operator and rejection_code=@MReworkCode and rejection_qty=@MReworkQty and   
    createdts = @startdate+' '+@starttime and rejdate=@MReworkDate and rejshift=@MReworkShift and WorkOrderNumber=@workorder and flag='MarkedforRework') --DR0329 added  
    BEGIN  --DR0329 added  
     insert into AutodataRejections(mc,comp,opn,opr,rejection_code,rejection_qty,createdts,rejdate,rejshift,recordid,flag,WorkOrderNumber)  
     values(@McInterfaceID,@component,@operation,@operator,@MReworkCode,@MReworkQty,@startdate+' '+@starttime,@MReworkDate,@MReworkShift,@MReworkid+1,'MarkedforRework',@workorder)  
    END --DR0329 added  
    ---ER0397 Added Till Here  
   END  
  
   SET @Error = @@ERROR  
      If @Error<>0  
      BEGIN    RAISERROR('Error In inserting the records in AutodataRejections table[%s] - %s',16,1,@orgstring)  
   return -1;  
      END  
 End  
/***************************************  ER0349 Till Here *******************************************/  
  
/*************************************** 
 From Here *******************************************/  
------SPC string:  
------START-DT-MC-COMP-OPRN-EMP-DIMENSION-[VALUE]-OffsetNo-[MeanValue]-[CorrectionValue]-DATE-TIME-END  
------START-31-0001-00000456-01-0123-13.5000-[+13.60]-20130902-122728817-END  
---   s_GetProcessDataString 'START-31-0001-00000456-01-0123-[13.5000]-[13.60]-008-[89]-[650]-20220512-094216817-abc-I1-END','127.0.0.1','','33'  
---   s_GetProcessDataString 'START-31-0001-00000456-01-0123-[13.5000]-[13.60]-008-[89]-[650]-20220512-094010817-END','127.0.0.1','','33'  
---   s_GetProcessDataString 'START-31-0001-00000456-01-0123-[13.5000]-[13.60]-008-[89]-[650]-20220512-094011817-[11]-[11]-abcd-I2-END','127.0.0.1','','33'  
----  s_GetProcessDataString 'START-31-0001-00000456-01-0123-[13.5000]-[13.60]-008-[89]-[650]-20220512-094011817-[11]-[11]-END','127.0.0.1','','33'  
---   s_GetProcessDataString 'START-31-0001-00000456-01-0123-[13.5000]-[13.60]-008-[89]-[650]-20220512-094012817-END','127.0.0.1','','33'  

if @tp_int=31  
 Begin  
  
  Declare @WearOffSetNumber nvarchar(50)
  Declare @MeasureDimension nvarchar(50)
  Declare @CorrectionValue nvarchar(50)
  Declare @Remarks nvarchar(50)
  Declare @InspectionType nvarchar(50)
  Declare @OvalitMax nvarchar(50)
  Declare @OvalityMin nvarchar(50)
  declare @HeatCode nvarchar(50)
  set @HeatCode=0

  Declare @IgnoreForCPCPK bit
  Set @IgnoreForCPCPK= 0


  If @StrLen<10  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  
  --SET @component = convert(bigint,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  


  --SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
  --SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  

 if (SUBSTRING( @datastring,1,1)) = '['
Begin
print '1'
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('[', @datastring)+ 1,LEN(@datastring) - CHARINDEX('[', @datastring)+ 1) 
 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)
END
ELSE
Begin
print '2'
 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
End
   
  --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  --SET @operator = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0421  
  SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
  SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421   
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)   
  --SET @Dimension = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
  --SET @Dimension = convert(nvarchar(20),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1))  --anjana
  --IF ISNUMERIC(@Dimension)=1  SET @Dimension = cast(@Dimension as decimal(5,0)) --anjana
  --SET @Dimension = convert(nvarchar(20),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
 -- SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2) 
 -- if CHARINDEX('-[', @datastring)>0
   if (SUBSTRING( @datastring,1,1)) = '['
	Begin
	 print '-['
	 -- SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
	  SET @datastring = SUBSTRING(@datastring,CHARINDEX('[', @datastring)+ 1,LEN(@datastring) - CHARINDEX('[', @datastring)+ 1)  
	  --SET @Dimension = convert(nvarchar(20),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1))  
	 -- SET @Dimension = cast(convert(nvarchar(20),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) as decimal(5,0)) --g:
           SET @Dimension = convert(nvarchar(20),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1))  --anjana handle numeric and non numeric dimension
	   IF ISNUMERIC(@Dimension)=1  SET @Dimension = cast(@Dimension as decimal(5,0)) --anjana handle numeric and non numeric dimension
     -- SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)
	  SET @datastring = SUBSTRING(@datastring,CHARINDEX(']', @datastring)+ 1,LEN(@datastring) - CHARINDEX(']', @datastring)+ 1)
	End
Else
	Begin
	 print '-'
	 --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1) 
	 --print @datastring  
	 --SET @Dimension = convert(nvarchar(20),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
	-- SET @Dimension = cast(convert(nvarchar(20),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) as decimal(5,0)) --g:
        SET @Dimension = convert(nvarchar(20),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))   --anjana handle numeric and non numeric dimension
	IF ISNUMERIC(@Dimension)=1  SET @Dimension = cast(@Dimension as decimal(5,0)) --anjana handle numeric and non numeric dimension
    --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2) 
End 
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
  set @DimValue=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)   
  set @WearOffSetNumber=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)     
  set @MeasureDimension=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
 
  set @CorrectionValue=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  

  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime) 
  

  if (select isnull(valueintext,'N') from ShopDefaults where Parameter='EnableOvality')='Y'
  BEGIN
	  if (SUBSTRING( @datastring,1,1)) = '['
	  Begin
		  print '-['
		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('[', @datastring)+ 1,LEN(@datastring) - CHARINDEX('[', @datastring)+ 1)  
		  set @OvalitMax=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  

		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2) 
		  set @OvalityMin=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  

		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	  END
  END


  if (select isnull(valueintext,'N') from ShopDefaults where Parameter='EnableIgnoreForCPCPK')='Y'
  BEGIN
	  select @IgnoreForCPCPK = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  

	  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  END

 if (select isnull(valueintext,'N') from ShopDefaults where Parameter='EnableHeatCode')='Y'
  BEGIN
	  if (SUBSTRING( @datastring,1,1)) = '['
	  Begin
	  SET @datastring = SUBSTRING(@datastring,CHARINDEX('[', @datastring)+ 1,LEN(@datastring) - CHARINDEX('[', @datastring)+ 1)  
	  set @HeatCode=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1) 
	  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	 end
	 else
	 begin
	  set @HeatCode = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
	  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	 end
  end

 
  if CHARINDEX('-',@datastring) > 0  
  begin  
      set @Remarks = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
      SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	  set @InspectionType = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
      SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
  end 


  If (IsDate(@startdate + ' ' + @starttime) = 1)  
  BEGIN  
   Insert into Rawdata(datatype,IPAddress,Mc,Comp,Opn,Opr,SPLSTRING3,Sttime,SPLSTRING2,Status,SPLSTRING4,SPLSTRING5,SPLSTRING6,SPLString7,SPLString8,SPLString9,SPLString10,SPLString11,WorkOrderNumber)values  
   (@tp_int,@IpAddress,@McInterfaceID,@component,@operation,@operator,@Dimension,@startdate+ ' ' + @starttime,@DimValue,0,@WearOffSetNumber,@MeasureDimension,@CorrectionValue,@Remarks,@InspectionType,@OvalitMax,@OvalityMin,@IgnoreForCPCPK,@HeatCode)  
  END  
  
  SET @Error = @@ERROR  
     If @Error<>0  
     BEGIN    RAISERROR('Error In inserting the records in AutodataRejections table[%s] - %s',16,1,@orgstring)  
  return -1;  
     END  
 End    
------Flow meter string:  
------START-DT-MC-PUMPMODEL-PUMPSERIES-OPERATOR-MINFLOW-MAXFLOW-STDATE-STTIME-ENDDATE-ENDTIME-END  
------START-39-1122-1357-308812345-00005556-[10.260]-[12.260]-20130902-154656-20130902-154827-END  
  
if @tp_int=39  
 Begin  
  
  If @StrLen<10  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  
  --SET @Pumpmodel= SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) --DR0333  
  SET @Pumpmodel= Convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --DR0333  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @PumpSeries= SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  --SET @operator = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0421  
  SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) --ER0421  
  SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
  
  SET @MinFlow = SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
  
  set @MaxFlow=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
  SET @Enddate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)    
  SET @Enddate = dbo.f_GetTpmStrToDate(@Enddate,getdate())  
  
  SET @Endtime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)   
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)    
  SET @Endtime = dbo.f_GetTpmStrToTime(@Endtime)  
  
  If (IsDate(@startdate + ' ' + @starttime) = 1)  
  BEGIN   
   Declare @FlowRowCount as int  
   Select @FlowRowCount = Count(*) from FlowCtrlAutodata where Machineinterface=@McInterfaceID and Pumpmodel=@Pumpmodel and PumpSeries=@PumpSeries   
   If @FlowRowCount = 0  
   BEGIN  
    Insert into FlowCtrlAutodata(Machineinterface,Pumpmodel,PumpSeries,Operator,MinFlow,MaxFlow,Starttime,Endtime)values  
    (@McInterfaceID,@Pumpmodel,@PumpSeries,@operator,@MinFlow,@MaxFlow,@startdate+ ' ' + @starttime,@Enddate+ ' ' +@Endtime)  
   END  
   ELSE  
   BEGIN  
    Declare @FlowPumpSeries as nvarchar(20),@InsertPumpseries nvarchar(20)  
    Select Top 1 @FlowPumpSeries = PumpSeries from FlowCtrlAutodata where Machineinterface=@McInterfaceID and Pumpmodel=@Pumpmodel and PumpSeries like @PumpSeries + '%' Order by ID desc  
    print @FlowPumpSeries  
    If charindex('-',@FlowPumpSeries)> 0   
    Begin  
     select @InsertPumpseries = Substring(@FlowPumpSeries,charindex('-',@FlowPumpSeries)+1,len(@FlowPumpSeries))  
     print @InsertPumpseries  
     select @InsertPumpseries = @InsertPumpseries + 1  
     Insert into FlowCtrlAutodata(Machineinterface,Pumpmodel,PumpSeries,Operator,MinFlow,MaxFlow,Starttime,Endtime)values  
     (@McInterfaceID,@Pumpmodel,@PumpSeries + '-' + @InsertPumpseries,@operator,@MinFlow,@MaxFlow,@startdate+ ' ' + @starttime,@Enddate+ ' ' +@Endtime)  
    End  
    Else  
    Begin  
    Insert into FlowCtrlAutodata(Machineinterface,Pumpmodel,PumpSeries,Operator,MinFlow,MaxFlow,Starttime,Endtime)values  
    (@McInterfaceID,@Pumpmodel,@PumpSeries + '-' + '1',@operator,@MinFlow,@MaxFlow,@startdate+ ' ' + @starttime,@Enddate+ ' ' +@Endtime)  
    end  
  
   END  
  END  
  SET @Error = @@ERROR  
     If @Error<>0  
     BEGIN    RAISERROR('Error In inserting the records in AutodataRejections table[%s] - %s',16,1,@orgstring)  
  return -1;  
     END  
 End  
/*************************************** NR0093 Till Here *******************************************/  
  
--NR0094 From Here  
If @tp_int = 7  
BEGIN  
    
  --@RequestType  
  SET @RequestType = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
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
  BEGIN  
  
    INSERT INTO ExportToHMI_PullInfo (MachineID,RequestType,RequestedTimeStamp)  
    VALUES(@McInterfaceID,@RequestType,@startdate + ' ' + @starttime)  
  END  
    
  SET @Error = @@ERROR  
  --print @Error  
   
  IF @Error <> 0  
  BEGIN    
     RAISERROR ('Error inserting ExportToHMI record for %s', 16, 1,@orgstring)  
     RETURN -1;  
  END  
End  
--NR0094 Till here  
  
--ER0367 From Here  
If @tp_int = 21  
BEGIN  
    
  --@MoNumber  
  SET @MONumber = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  --@MOQty  
  SET @MOQty = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
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
  BEGIN  
    IF NOT EXISTS(Select * from MODetails where MachineInterface=@McInterfaceID and MOTimeStamp=@startdate + ' ' + @starttime)  
    BEGIN  
    INSERT INTO MODetails (MachineInterface,MONumber,MOQty,MOTimeStamp)  
    VALUES(@McInterfaceID,@MONumber,@MOQty,@startdate + ' ' + @starttime)  
    END  
    ELSE  
    BEGIN  
    UPDATE MODetails SET MOQty = @MOQty,MONumber = @MONumber where   
    MachineInterface=@McInterfaceID and MOTimeStamp=@startdate + ' ' + @starttime  
    END  
  END  
    
  SET @Error = @@ERROR  
  
  IF @Error <> 0  
  BEGIN    
     RAISERROR ('Error inserting MO record for %s', 16, 1,@orgstring)  
     RETURN -1;  
  END  
End  
--ER0367 Till here  
  
--ER0369 Added Till here  
 If @tp_int = 76  
 BEGIN  
  
  --To Read Line  
  select @Line= Plantcode from PlantInformation P   
  inner join Plantmachine PM on P.Plantid=PM.Plantid  
  inner join Machineinformation M on M.Machineid=PM.Machineid  
  where M.IP=@IpAddress  
  
  If @strlen = 7   
  BEGIN  
   
   --Event  
   SET @EventNo= convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     
   --Action  
   SET @Action= convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
   --startdate  
   SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('RawData::Invalid StartDate:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
   --starttime  
   SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   SET @starttime = dbo.f_GetTpmStrToTime(@starttime)         
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('RawData::Invalid StartTime:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  
            if((Select Count(*) from HelpCodeDetails where Plantid=@Line and Machineid=@McInterfaceID and DataType=@tp_int and HelpCode=@EventNo   
                and Action1=@Action and Starttime=@startdate + ' '+ @starttime)=0)  
   Begin  
    Insert Into HelpCodeDetails(Plantid,Machineid,DataType,HelpCode,Action1,Starttime)Values  
    (@Line,@McInterfaceID,@tp_int,@EventNo,@Action,@startdate + ' '+ @starttime)  
   End  
  
            Else  
   Begin  
    RAISERROR('RawData::Duplicate Value:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('Insert into HelpCodeDetails:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  END  
  
  
  If @strlen = 10  
  BEGIN   
  
   --Event  
   SET @EventNo= convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     
   --Action1  
   SET @Action1= convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
   --Action2  
   SET @Action2= convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
   --startdate  
   SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('RawData::Invalid StartDate:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  
   --starttime  
   SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   SET @starttime = dbo.f_GetTpmStrToTime(@starttime)         
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('RawData::Invalid StartTime:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  
   --enddate  
   SET @enddate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   SET @enddate = dbo.f_GetTpmStrToDate(@enddate,GetDate())         
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('RawData::Invalid EndDate:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  
   --endtime  
   SET @endtime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   SET @endtime = dbo.f_GetTpmStrToTime(@endtime)  
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('RawData::Invalid EndTime:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  
            If((Select Count(*) from HelpCodeDetails where Plantid=@Line and Machineid=@McInterfaceID and DataType=@tp_int and HelpCode=@EventNo and  
                Action1=@Action1 and Action2=@Action2 and Starttime=@startdate + ' '+ @starttime and endtime=@Enddate + ' '+ @Endtime)=0)  
            Begin      
     Insert Into HelpCodeDetails(Plantid,Machineid,DataType,HelpCode,Action1,Action2,Starttime,endtime)Values  
     (@Line,@McInterfaceID,@tp_int,@EventNo,@Action1,@Action2,@startdate + ' '+ @starttime,@Enddate + ' '+ @Endtime)               
            End  
              
   Else  
   Begin  
    RAISERROR('RawData::Duplicate Value:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('Insert into HelpCodeDetails:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  END  
 END  
--ER0369 Added Till here  
  
-------------------------------------- NR0098 Added From Here --------------------------------------------------  
  
/*****************************************************************************************  
TI string:  
START-38-MC ID-MODEL ID-OPERATOR ID-OD NDE VALUE-OD DE VALUE-TIR NDE VALUE-TIR DE VALUE-ND DATE-ND TIME-END  
START-38-1-175-12-339.448-339.448-0.051-0.052-06112014-101010-END  
********************************************************************************************/  
if @tp_int=38  
 Begin  
  
  If @StrLen<9  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
      return -1;  
  END  
  
  SET @ModelID= Convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))   
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  --SET @operatorID = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0421  
  SET @operatorID = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
  SET @operatorID = REPLACE(LTRIM(REPLACE(@operatorID, '0', ' ')), ' ', '0') --ER0421  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @ODNDE = convert(float,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @ODDE = convert(float,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @TIRNDE = convert(float,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @TIRDE = convert(float,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
  Select @MonthValue = Case   
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='01' then 'A'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='02' then 'B'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='03' then 'C'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='04' then 'D'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='05' then 'E'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='06' then 'F'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='07' then 'G'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='08' then 'H'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='09' then 'I'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='10' then 'J'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='11' then 'K'  
        when right('00'+convert(nvarchar,datepart(month,@startdate)),2)='12' then 'L' end  
  
  
  Select @SequenceNo = ISnull((TI_Autodata.SequenceNo),0) from   
  (Select Max(ID) as IDD from TI_Autodata where ModelID=@ModelID)T inner join TI_Autodata on TI_Autodata.ID=T.IDD  
  
  select @yearvalue = ''  
  select @yearvalue = (TI_Autodata.SerialNo) from   
  (Select Max(ID) as IDD from TI_Autodata where ModelID=@ModelID)T inner join TI_Autodata on TI_Autodata.ID=T.IDD  
  
  
  IF substring(@yearvalue,len(@yearvalue)-5,2) <> substring(convert(nvarchar,datepart(year,@startdate)),3,4)   
  Begin  
   Select @SequenceNo = 1  
  END  
  else   
  Begin  
   Select @SequenceNo = isnull(@SequenceNo,0) + 1  
  END  
  
  Select @SeqNo = @SequenceNo  
  Select @SerialNo = @ModelID +  @MonthValue + substring(convert(nvarchar,datepart(year,@startdate)),3,4) + right('0000'+ @SeqNo,4)  
  
  If (IsDate(@startdate + ' ' + @starttime) = 1)  
  BEGIN   
   Insert into TI_Autodata(MachineID, ModelID, OperatorID, ODNDE, ODDE, TIRNDE, TIRDE, [Timestamp], SerialNo, SequenceNo)  
   values(@McInterfaceID,@ModelID,@operatorID,@ODNDE,@ODDE,@TIRNDE,@TIRDE,@startdate + ' '+ @starttime,@SerialNo,@SequenceNo)      
  END  
  
  SET @Error = @@ERROR  
     If @Error<>0  
     BEGIN    RAISERROR('Error In inserting the records in TI_Autodata table[%s] - %s',16,1,@orgstring)  
  return -1;  
     END  
 End  
/*************************************** NR0098 Till Here *******************************************/  
  
/************************ NR0105 Added From Here ****************************/  
  
--Saint Gobain string:  
--START-10-MachineID-Length-Breadth-Depth-StDate-StTime-END  
--START-10-0001-1000-0250-0005-20140806-165444247-END  
  
if @tp_int=10  
Begin  
  
  If @StrLen<6  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
      return -1;  
  END  
  
  
  SET @Length = convert(float,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @Breadth = convert(float,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @Depth= convert(float,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  SET @Error = @@ERROR  
  IF @Error <> 0  
  Begin  
   RAISERROR('SG_Autodata_Insert String::Invalid StartDate:[%s] - %s',16,1,@IpAddress,@Orgstring)  
   return -1;  
  End  
  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  SET @Error = @@ERROR  
  IF @Error <> 0  
  Begin  
   RAISERROR('SG_Autodata_Insert String::Invalid StartTime:[%s] - %s',16,1,@IpAddress,@Orgstring)  
   return -1;  
  End  
  
  If ((Select Count(*) from SG_Autodata where MC=@McInterfaceID and Starttime=@startdate + ' '+ @starttime)=0)  
  BEGIN   
   Insert into SG_Autodata(MC,[Length],[Breadth], [Depth], [Volume], [Starttime],[Datatype])  
   values(@McInterfaceID,@Length,@Breadth,@Depth,(@Length*@Breadth*@Depth),@startdate + ' '+ @starttime,@tp_int)      
  END  
  Else  
  Begin  
   RAISERROR('SG_Autodata_Insert String::Duplicate Value:[%s] - %s',16,1,@IpAddress,@Orgstring)  
   return -1;  
  End  
  
  SET @Error = @@ERROR  
  IF @Error <> 0  
  Begin  
   RAISERROR('Insert into SG_Autodata:[%s] - %s',16,1,@IpAddress,@Orgstring)  
   return -1;  
  End  
  
END  
/************************ NR0105 Added Till Here ****************************/  
  
/************************** ER0391 From Here **********************************************/  
/*
--Type 18 Record --> Tool change indication record  
--START-18-MC-TOOL NO.(120.1)-CURRENT TARGET-CURRENT ACTUAL-DATE-TIME-END  
  
  exec s_GetProcessDataString 'START-18-m1-111-10-9-20220906-141700-c1-40-END','127.0.0.1','','33'  
  exec s_GetProcessDataString 'START-18-m1-111-10-9-20220906-142000-[c2]-50-END','127.0.0.1','','33'  

*/
If @tp_int=18  
BEGIN  

  If @StrLen<7  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
      return -1;  
  END  
     
	IF @StrLen=8
	BEGIN
	  DECLARE @CurrentTool as float   
	  Declare @CurrentTarget as int  
	  Declare @CurrentActual as int  
         
	   --ToolNo  
	   SET @CurrentTool = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS float)   
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
	   --Target  
	   SET @CurrentTarget = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS float)   
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
	   --Actual  
	   SET @CurrentActual = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS float)   
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     
	   --startdate  
		  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	   SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())        
   
	   --starttime  
	   SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	   SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  

			Insert Into Rawdata(Datatype,IPAddress,Mc,comp,SPLSTRING1,SPLSTRING2,Sttime,Status)values  
		 (@tp_int,@IpAddress,@McInterfaceID,@CurrentTool,@CurrentTarget,@CurrentActual,@startdate + ' ' +@starttime,0)  
    
	END
	IF @StrLen>8
	BEGIN
		DECLARE @CurrentToolNo as float   
         
	   --ToolNo  
	   SET @CurrentToolNo = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS float)   
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
	   --Target  
	   SET @CurrentTarget = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS float)   
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
	   --Actual  
	   SET @CurrentActual = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) AS float)   
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     
	   --startdate  
		  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	   SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())        
   
	   --starttime  
	   SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
	   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	   SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  


	    IF @RemoveLeadZeroInProcessString='Y'
		 BEGIN
				if CHARINDEX(']-', @datastring)>0
				Begin
				print '1'
				 SET @datastring = SUBSTRING(@datastring,CHARINDEX('[', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
				 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
				 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
				 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
				END
				ELSE
				Begin
				print '2'
				 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
				 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
				 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
				End
		  END
		  ELSE
		  BEGIN
				if CHARINDEX(']-', @datastring)>0
				Begin
				print '1'
				 SET @datastring = SUBSTRING(@datastring,CHARINDEX('[', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
				 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
				 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
				END
				ELSE
				Begin
				print '2'
				 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
				 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
				End
		  END

		  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
		  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

			Insert Into Rawdata(Datatype,IPAddress,Mc,comp,SPLSTRING1,SPLSTRING2,Sttime,Status,SPLString3,SPLString4)values  
		    (@tp_int,@IpAddress,@McInterfaceID,@CurrentToolNo,@CurrentTarget,@CurrentActual,@startdate + ' ' +@starttime,0,@component,@operation)  
	END
    
  SET @Error = @@ERROR  
  If @Error<>0  
  BEGIN      
   RAISERROR('Error In inserting the records in rawdata table[%s] - %s',16,1,@orgstring)  
   return -1;  
  END  
END  
/************************** ER0391 Till Here **********************************************/  
  
  
/************************** ER0397 Added from Here **********************************************/  
--Request String format :: START-28-MC-COMP-OPN-SLNO-STARTDATE-STARTTIME-END  
if @tp_int=28  
 Begin  
  
  Declare @ReasonCode as nvarchar(50)  
  declare @PrevOpnFromAutodata as nvarchar(50)  
  Declare @NextOpnFromCOP as nvarchar(50)  
  Declare @PrevCompFromAutodata as nvarchar(50)  
  declare @AutodataRecordCount as int  
  declare @ReworkCount as int  
  
  If @StrLen<8  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  
  SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))   
  SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--To Remove Leading Zeroes  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  
  SET @SlNo = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
    
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
  If (IsDate(@startdate + ' ' + @starttime) = 1)  
  BEGIN  
   insert into QualityRequestMaster(datatype,mc,comp,opn,Slno,Starttime)  
   values(@tp_int,@McInterfaceID,@component,@operation,@SlNo,@startdate+' '+@starttime)  
  END  
  
  
  If isnull(@component,'a')<>'a' and @operation<>'0'  
  BEGIN  
     
    If not exists(Select top 1 * from Autodata where comp=@component and opn=@operation and WorkOrderNumber=@SlNo)  
    BEGIN  
  
     set @PrevOpnFromAutodata = (Select isnull(max(opn),0) from Autodata where comp=@component and WorkOrderNumber=@SlNo)  
  
     If exists(Select top 1 * from autodatarejections where comp=@component and opn=@PrevOpnFromAutodata and WorkOrderNumber=@SlNo)  
     Begin  
  
  
       set @AutodataRecordCount=(Select isnull(count(*),0) from autodata where comp=@component and opn=@PrevOpnFromAutodata and WorkOrderNumber=@SlNo and datatype=1)  
       set @ReworkCount=(Select isnull(count(*),0) from autodatarejections where comp=@component and opn=@PrevOpnFromAutodata and WorkOrderNumber=@SlNo and flag='MarkedforRework')  
       Set @Reasoncode = (Select top 1 flag from autodatarejections where comp=@component and opn=@PrevOpnFromAutodata and WorkOrderNumber=@SlNo order by id desc)  
  
        If @Reasoncode='Rejection'  
        Begin  
         Select '<' + @SlNo + '-' + @component + '@' + @PrevOpnFromAutodata + '#' + '4>' --(Rejection)  
         return;  
        End  
  
       If @AutodataRecordCount=@ReworkCount  
       Begin  
        If @Reasoncode='MarkedforRework'  
        Begin  
         If exists(select * from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
         inner join Componentinformation C on C.Componentid=CO.Componentid where M.interfaceid=@McInterfaceID and C.interfaceid=@component and CO.operationno=@PrevOpnFromAutodata)  
         Begin  
          Select '<' + @SlNo + '-' + @component + '@' + @PrevOpnFromAutodata + '#' + '5>' --(MarkedforRework)  
          return;  
         end  
         Else  
         Begin  
          Select '<' + @SlNo + '-' + @component + '@' + @PrevOpnFromAutodata + '#' + '7>' --(Not Allowed on this machine)  
          return;  
         end         
        End  
        End  
        else  
        Begin  
        set @PrevOpnFromAutodata = (Select isnull(max(opn),0) from Autodata where comp=@component and WorkOrderNumber=@SlNo)  
  
        set @NextOpnFromCOP = (select top 1 isnull(operationno,0) from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
        inner join Componentinformation C on C.Componentid=CO.Componentid where C.interfaceid=@component and CO.Operationno>@PrevOpnFromAutodata order by operationno)  
  
        If isnull(@NextOpnFromCOP,'a') = 'a'  
        Begin  
        Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '9>' --(Next operation not exists for that component)  
        return;    
        end  
  
  
        If @operation=@NextOpnFromCOP  
        Begin  
  
         If not exists(select * from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
        inner join Componentinformation C on C.Componentid=CO.Componentid where M.interfaceid=@McInterfaceID and C.interfaceid=@component and CO.operationno=@operation)  
         Begin  
          Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '2>' --(this operation is not allowed on this machine)  
          return;  
         end  
         else  
         Begin  
          Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '1>' --(OK)  
          return;  
         End  
  
        End  
        Else  
        Begin  
         Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '8>' --(out of sequence)  
         return;         
        end  
          
        End     
  
     End  
  
     If Not exists(Select top 1 * from autodatarejections where comp=@component and opn=@PrevOpnFromAutodata and WorkOrderNumber=@SlNo)  
     Begin   
      set @PrevOpnFromAutodata = (Select isnull(max(opn),0) from Autodata where comp=@component and WorkOrderNumber=@SlNo)  
  
      set @NextOpnFromCOP = (select top 1 isnull(operationno,0) from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
      inner join Componentinformation C on C.Componentid=CO.Componentid where C.interfaceid=@component and CO.Operationno>@PrevOpnFromAutodata order by operationno)  
  
      If isnull(@NextOpnFromCOP,'a') = 'a'  
      Begin  
       Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '9>' --(Next operation not exists for that component)  
       return;    
      end  
  
  
      If @operation=@NextOpnFromCOP  
      Begin  
  
       If not exists(select * from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
       inner join Componentinformation C on C.Componentid=CO.Componentid where M.interfaceid=@McInterfaceID and C.interfaceid=@component and CO.operationno=@operation)  
       Begin  
        Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '2>' --(this operation is not allowed on this machine)  
        return;  
       end  
       else  
       Begin  
        Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '1>' --(OK)  
        return;  
       End  
  
      End  
      Else  
      Begin  
       Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '8>' --(out of sequence)  
       return;         
      end  
     End  
    END  
    ELSE IF exists(Select top 1 * from Autodata where comp=@component and opn=@operation and WorkOrderNumber=@SlNo)  
    BEGIN  
       
     If exists(Select top 1 * from autodatarejections where comp=@component and opn=@operation and WorkOrderNumber=@SlNo)  
     Begin  
  
      set @AutodataRecordCount=(Select isnull(count(*),0) from autodata where comp=@component and opn=@operation and WorkOrderNumber=@SlNo and datatype=1)  
      set @ReworkCount=(Select isnull(count(*),0) from autodatarejections where comp=@component and opn=@operation and WorkOrderNumber=@SlNo and flag='MarkedforRework')  
   
      Set @Reasoncode = (Select top 1 flag from autodatarejections where comp=@component and opn=@operation and WorkOrderNumber=@SlNo order by id desc)  
  
  
  
       If @Reasoncode='Rejection'  
       Begin  
        Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '4>'  --(Rejection)  
        return;  
       End  
  
      If @AutodataRecordCount = @ReworkCount  
      Begin   
  
       If @Reasoncode='MarkedforRework'  
       Begin  
  
        If exists(select * from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
        inner join Componentinformation C on C.Componentid=CO.Componentid where M.interfaceid=@McInterfaceID and C.interfaceid=@component and CO.operationno=@operation)  
        Begin  
         Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '5>' --(MarkedforRework)  
         return;  
        end  
        Else  
        Begin  
         Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '7>' --(Not Allowed on this machine)  
         return;  
        end  
       End  
  
      End  
      Else  
      Begin  
       Select '<' +  @SlNo + '-' + @component + '@' + @operation + '#' + '3>' --(already there)  
       return;  
      End  
  
     End  
     Else  
     Begin  
      Select '<' +  @SlNo + '-' + @component + '@' + @operation + '#' + '3>' --(already there)  
      return;  
     End  
    END  
   
   END  
  
  If isnull(@component,'a')='a' or @operation='0'  
  BEGIN  
     
    If exists(Select top 1 * from Autodata where WorkOrderNumber=@SlNo)  
    BEGIN  
  
     set @PrevOpnFromAutodata = (Select isnull(max(opn),0) from Autodata where WorkOrderNumber=@SlNo)  
     set @PrevCompFromAutodata = (Select top 1 comp from Autodata where WorkOrderNumber=@SlNo and opn=@PrevOpnFromAutodata order by id desc)  
     set @AutodataRecordCount=(Select isnull(count(*),0) from autodata where comp=@PrevCompFromAutodata and opn=@PrevOpnFromAutodata and WorkOrderNumber=@SlNo and datatype=1)  
     set @ReworkCount=(Select isnull(count(*),0) from autodatarejections where comp=@PrevCompFromAutodata and opn=@PrevOpnFromAutodata and WorkOrderNumber=@SlNo and flag='MarkedforRework')  
    
  
     If exists(Select * from autodatarejections where comp=@PrevCompFromAutodata and opn=@PrevOpnFromAutodata and WorkOrderNumber=@SlNo)  
     Begin  
      Set @Reasoncode = (Select top 1 flag from autodatarejections where comp=@PrevCompFromAutodata and opn=@PrevOpnFromAutodata and WorkOrderNumber=@SlNo order by id desc)  
  
  
  
        If @Reasoncode='Rejection'  
        Begin  
         Select '<' +  @SlNo + '-' + @PrevCompFromAutodata + '@' + @PrevOpnFromAutodata + '#' + '4>'  --(Rejection)  
         return;  
        End  
  
      IF @AutodataRecordCount=@ReworkCount  
      Begin  
  
        If @Reasoncode='MarkedforRework'  
        Begin  
  
         If exists(select * from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
         inner join Componentinformation C on C.Componentid=CO.Componentid where M.interfaceid=@McInterfaceID and C.interfaceid=@PrevCompFromAutodata and CO.operationno=@PrevOpnFromAutodata)  
         Begin  
          Select '<' + @SlNo + '-' + @PrevCompFromAutodata + '@' + @PrevOpnFromAutodata + '#' + '5>' --(MarkedforRework)  
          return;  
         end  
         Else  
         Begin  
          Select '<' + @SlNo + '-' + @PrevCompFromAutodata + '@' + @PrevOpnFromAutodata + '#' + '7>' --(Not Allowed on this machine)  
          return;  
         end  
        End  
  
      End  
      else  
      Begin  
       set @PrevOpnFromAutodata = (Select isnull(max(opn),0) from Autodata where comp=@component and WorkOrderNumber=@SlNo)  
  
       set @NextOpnFromCOP = (select top 1 isnull(operationno,0) from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
       inner join Componentinformation C on C.Componentid=CO.Componentid where C.interfaceid=@component and CO.Operationno>@PrevOpnFromAutodata order by operationno)  
  
  
       If not exists(select * from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
       inner join Componentinformation C on C.Componentid=CO.Componentid where M.interfaceid=@McInterfaceID and C.interfaceid=@PrevCompFromAutodata and CO.operationno=@NextOpnFromCOP)  
       Begin  
        Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '2>' --(this operation is not allowed on this machine)  
        return;  
       end  
       else  
       Begin  
        Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '1>' --(OK)  
        return;  
       End  
  End  
  
  
     End  
     Else  
     Begin  
  
       set @PrevOpnFromAutodata = (Select isnull(max(opn),0) from Autodata where comp=@component and WorkOrderNumber=@SlNo)  
  
       set @NextOpnFromCOP = (select top 1 isnull(operationno,0) from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
       inner join Componentinformation C on C.Componentid=CO.Componentid where C.interfaceid=@component and CO.Operationno>@PrevOpnFromAutodata order by operationno)  
  
  
       If not exists(select * from componentoperationpricing CO inner join Machineinformation M on M.machineid=CO.machineid  
       inner join Componentinformation C on C.Componentid=CO.Componentid where M.interfaceid=@McInterfaceID and C.interfaceid=@PrevCompFromAutodata and CO.operationno=@NextOpnFromCOP)  
       Begin  
        Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '2>' --(this operation is not allowed on this machine)  
        return;  
       end  
       else  
       Begin  
        Select '<' + @SlNo + '-' + @component + '@' + @operation + '#' + '1>' --(OK)  
        return;  
       End  
     End  
  
    END  
    Else  
    Begin  
     Select  '<' + @SlNo + '-' + '@' + '#' + '6>' --(Slno Not exists in autodata)  
    end  
  
  END  
  
  
  SET @Error = @@ERROR  
     If @Error<>0  
     BEGIN    
   RAISERROR('Error In inserting the records in QualityRequestMaster table[%s] - %s',16,1,@orgstring)  
   return -1;  
     END  
 End  
/***************************************  ER0397 Till Here *******************************************/  
  
  
/***************************************  ER0399 Till Here *******************************************/  
-- START-8-MC-COMP-OPN-STARTDATE-STARTTIME-END  
if @tp_int=8  
 Begin  
  
  If @StrLen<7  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  
        SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))   
  SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--To Remove Leading Zeroes  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
    
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
  If (IsDate(@startdate + ' ' + @starttime) = 1)  
  BEGIN  
   Insert into AutodataDetails(Machine, RecordType, Starttime, CompInterfaceID, OpnInterfaceID)values  
   (@McInterfaceID,@tp_int,@startdate+ ' ' + @starttime,@component,@operation)  
  END  
  
  SET @Error = @@ERROR  
     If @Error<>0  
     BEGIN    RAISERROR('Error In inserting the records in AutodataDetails table[%s] - %s',16,1,@orgstring)  
  return -1;  
     END  
 End  
  
  
/*************************************** ER0398 Added from here **************************************/  
---START-13-MC-STARTDATE-STARTTIME-END --For MMForge  
if @tp_int=13  
 Begin  
  
  If @StrLen<5  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  
    
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
    
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
  If (IsDate(@startdate + ' ' + @starttime) = 1)  
  BEGIN  
   Insert into Machinenodeautodata(DataType,NodeInterface,StartTime)values  
   (@tp_int,@McInterfaceID,@startdate+ ' ' + @starttime)  
  END  
  
  SET @Error = @@ERROR  
     If @Error<>0  
     BEGIN  
    RAISERROR('Error In inserting the records in Machinenodeautodata table[%s] - %s',16,1,@orgstring)  
   return -1;  
     END  
 End  
/********************************** ER0398 Added till here****************************/  
  
  
/********************************** NR0105 Added from here****************************/  
---START-43-MC-STARTDATE-STARTTIME-ENDDATE-ENDTIME-END --For Saint Gobain  
if @tp_int=43  
 Begin  
  
  If @StrLen<7  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  
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
 SET @endtime = dbo.f_GetTpmStrToTime(@endtime)  
  
  If (IsDate(@startdate + ' ' + @starttime) = 1)  
  BEGIN  
   Insert into CuttingDetails(MachineID,DataType,[StartTime],[EndTime])values  
   (@McInterfaceID,@tp_int,@startdate+ ' ' + @starttime,@Enddate + ' ' + @Endtime)  
  END  
  
  SET @Error = @@ERROR  
     If @Error<>0  
     BEGIN    RAISERROR('Error In inserting the records in CuttingDetails table[%s] - %s',16,1,@orgstring)  
  return -1;  
     END  
 End  
  
/*****************************NR0105 Added Till here ***************************/  
  
/*****************************NR0116 Added from here ***************************/  
/************************************************************************************************  
START-23-MachineID-CompID-OperationID-OperatorID-RejectionCode- RejectionQty-RejDate-RejShift-WorkOrderNo-StDate-StTime-END  
s_GetProcessDataString 'START-24-0001-00007681-001-0003-0004-0002-20150706-02-1234-20150706-164338050-END','172.36.0.252','','33'  
************************************************************************************************/  
if @tp_int=23  
 Begin  
   
  If @StrLen<12  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  
  --SET @component = convert(bigint,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0387  
  SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))--ER0387  
  SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  --SET @operator = convert(int,sUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0421  
  SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) --ER0421  
  SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @RejCode = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @RejQty = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @RejDate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   If @RejDate = 0  
  BEGIN  
   SET @RejDate = '1900-01-01 00:00:00.000'  
  END  
   
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @RejShift = Convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))   
  If @RejShift = 0  
  BEGIN  
   SET @RejShift = NULL  
  END    
   
  if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
  begin    
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   set @WorkOrder=convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
  end  
  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
    
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
    
    select @rejrecordid = isnull(max(recordid),0) from autodatarejections where flag='ReworkPerformed'   
  
   If (IsDate(@startdate + ' ' + @starttime) = 1)  
   BEGIN  
  
   
    IF NOT EXISTS(Select * from [AutodataRejections] where mc=@McInterfaceID and comp=@component and opn=@operation and opr=@operator and rejection_code=@RejCode and rejection_qty=@RejQty   
      and rejdate=@RejDate and rejshift=@Rejshift and flag='ReworkPerformed' and WorkOrderNumber=@workorder)   
    BEGIN    
  
     insert into [AutodataRejections](mc,comp,opn,opr,rejection_code,rejection_qty,createdts,rejdate,rejshift,recordid,flag,WorkOrderNumber)  
     values(@McInterfaceID,@component,@operation,@operator,@RejCode,@RejQty,@startdate+' '+@starttime,@RejDate,@Rejshift,@rejrecordid+1,'ReworkPerformed',@Workorder)      
    END   
    else  
    Begin  
      update [AutodataRejections] set Rejection_Qty=@RejQty  
      where mc=@McInterfaceID and comp=@component and Opn=@operation and Opr=@operator and Rejection_Code=@RejCode and   
      WorkOrderNumber=@WorkOrder and Flag='reworkPerformed' and Rejdate=@rejdate and RejShift=@rejShift  
    End  
   END  
   SET @Error = @@ERROR  
      If @Error<>0  
      BEGIN    RAISERROR('Error In inserting the records in [AutodataRejections] table[%s] - %s',16,1,@orgstring)  
   return -1;  
      END  
 End  
  
  
/***************************************  NR0116 From Here *******************************************/  
--START-24-MachineID-CompID-OperationID-OperatorID-ReworkAccepted-ReworkRejected-ReworkDate-ReworkShift-WorkOrderNo-StDate-StTime-END  
--s_GetProcessDataString 'START-24-0001-00007681-001-0003-0004-0002-20150706-02-1234-20150706-164338050-END','172.36.0.252','','33'  
if @tp_int=24  
 Begin  
   
  If @StrLen<12   
    
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
       return -1;  
  END  
  
    
  SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')  
  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  --SET @operator = convert(int,sUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0421  
  SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) --ER0421  
  SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @ReworkAccepted = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @ReworkRejected = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @MReworkDate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
    
  SET @MReworkShift = Convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))   
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
    
  if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
  begin  
   set @WorkOrder=convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  end  
    
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
    
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
   
  
   If (IsDate(@startdate + ' ' + @starttime) = 1)  
   BEGIN  
   
      
    IF NOT EXISTS(Select * from ReworkPerformedSummary_Jina where mc=@McInterfaceID and comp=@component and opn=@operation and opr=@operator  --and  createdts = @startdate+' '+@starttime  
     and rejdate=@MReworkDate and rejshift=@MReworkShift and WorkOrderNumber=@workorder  )  
    BEGIN    
     insert into ReworkPerformedSummary_Jina(mc,comp,opn,opr,ReworkAccepted,ReworkRejected,ReworkPerformed,createdts,rejdate,rejshift,WorkOrderNumber)  
     values(@McInterfaceID,@component,@operation,@operator,@ReworkAccepted,@ReworkRejected,@ReworkAccepted+@ReworkRejected,@startdate+' '+@starttime,@MReworkDate,@MReworkShift,@workorder)  
    END   
    else  
    BEGIN    
     update  ReworkPerformedSummary_Jina set ReworkAccepted=@ReworkAccepted ,ReworkRejected=@ReworkRejected,ReworkPerformed=(@ReworkAccepted+@ReworkRejected)  
     where mc=@McInterfaceID and comp=@component and opn=@operation and opr=@operator and WorkOrderNumber=@WorkOrder and rejdate=@MReworkDate and RejShift=@rejShift  
    END   
   END  
  
   SET @Error = @@ERROR  
      If @Error<>0  
      BEGIN    RAISERROR('Error In inserting the records in ReworkPerformedSummary table[%s] - %s',16,1,@orgstring)  
   return -1;  
      END  
 End  
/***************************************  NR0116 Till Here *******************************************/  
  
------------------------------------ NR0117 Added From Here -----------------------------------------  
/************************************************************************  
String format :-  "START-E3-MC-D-T-L5-KWH-KVA-WATT-[PF]-AR-AY-AB-V1-V2-V3-END"  
  
  
E3-datatype   
MC- Machineinterfaceid  
D-Date  
T- time  
L5 - frequency  
KWH - KiloWattPerHour (float value)  
KVA - KiloVoltAmpere (float value)  
KW - Power (float value)  
PF-Power factor (float value)  
A - Ampere (float value)  
AR,AY,AB -AmpereR,AmpereY,AmpereB(float value)  
V1,V2,V3 - Voltages (int value)  
  
The Sample string format is  
        
 exec s_GetProcessDataString 'START-77-202-20140329-23595901-2-4.00615-15.4385-1-[-0.56]-0.45-3-3-100-200-300-1-45-46-47-END ','127.0.0.1','','33'  
--START-77-202-20140329-23595901-2-4.00615-15.4385-1-[-0.56]-0.45-3-3-100-200-300-1-44-45-46-END  
*******************************************************************************************************/  
If @tp_int=77  
Begin  
  --startdate  
  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
    
  --starttime  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
    

	--company name based
	if exists(select * from company where CompanyName='TECHNOSYSTEMS')
	BEGIN
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1) --ER0426
	END    
    
  set @KWHVal=cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as float)      
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
  set @KVA=cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as float)      
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
  set @KWValue=cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  as float)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
        
  
  set @PFValue=SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)  
  SET @PFValue = CASE WHEN @PFValue>1 THEN 1 ELSE @PFValue END  
   
  SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
  set @AmpereR=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
 -- SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
  set @AmpereY=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   
  --SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
  set @AmpereB=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
  
  set @V1=cast(cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as float) as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  set @V2=cast(cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as float) as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  set @V3=cast(cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as float) as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)    




  set @V4=cast(cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as float) as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)


  set @V5=cast(cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as float) as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
 

  set @V6=cast(cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as float) as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)


  

  --ER0454
  set @energysrc = 1 -- set EB/DG default to EB  
  if CHARINDEX('-',@datastring) > 0 --g  
  begin  
      set @energysrc = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as smallint)  
      SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  end  
  ---ER0454
  --select @MachineName= Machineid from machineinformation where interfaceid=@McInterfaceID --ER0449    
  Select @Energy_MachineName = ISNULL(Valueintext,'Machineid') from Shopdefaults where Parameter='Energy_MachineName'  --ER0449  
  
  --ER0449 Added From Here  
  --IF @Energy_MachineName = 'Machineid'  
  --BEGIN  
  --select @MachineName= Machineid from machineinformation where interfaceid=@McInterfaceID   
  --END  
  
  --IF @Energy_MachineName = 'MachineDescription'  
  --BEGIN  
  --select @MachineName= Machineid from machineinformation where Description=@McInterfaceID   
  --END  
  --ER0449 Added Till Here  
  
  --ER0502 added From here
    IF @Energy_MachineName = 'Machineid'  
  BEGIN  
  select @MachineName= Machineid from EM_Machineinformation where interfaceid=@McInterfaceID   
  END  
  
  IF @Energy_MachineName = 'MachineDescription'  
  BEGIN  
  select @MachineName= Machineid from EM_Machineinformation where Description=@McInterfaceID   
  END 
  --ER0502 added From here
    
  If isnull(@MachineName,'a')='a'  
  Begin  
   select @MachineName=@McInterfaceID  
  end  
    
  
  if(isdate(@startdate + ' ' + @starttime) = 1)  
  Begin  
  Begin Transaction  
    
   select @gtime=isnull(maxgtime ,'1900-01-01') from tcs_energyconsumption_maxgtime where machine=@MachineName  
   select @count = count(machineid) from tcs_energyconsumption where machineid=@MachineName  

     
	If isnull(@gtime,'') <>'' and  @gtime < @startdate + ' ' + @starttime  
	begin          
		update tcs_energyconsumption set gtime1=@startdate + ' ' + @starttime,ampere1=Round(@AmpValue,2),  
		kwh1=Round(@KWHVal,5) where machineid=@MachineName and gtime=@gtime  
	end  

	If (@count = 0) or  (@gtime < @startdate + ' ' + @starttime)  or @gtime is null
	begin  
		insert into dbo.tcs_energyconsumption (MachineID,gtime,ampere,watt,pf,KWH,Volt1,Volt2,Volt3,KVA,AmpereR,AmpereY,AmpereB, EnergySource,Volt4,Volt5,Volt6)  
		values (@MachineName,@startdate + ' ' + @starttime,0.0,Round(@KWValue,5),Round(@PFValue,2),Round(@KWHVal,5),@V1,@V2,@V3,round(@KVA/1000,2),@AmpereR,@AmpereY,@AmpereB, @energysrc,@V4,@V5,@V6)   
		SET @Error = @@ERROR  
		IF @Error <> 0 GOTO ERROR_HANDLER1  
	end  
  
  END  
    
  If @@TRANCOUNT <> 0  
  Begin  
   COMMIT TRANSACTION  
  end  
  
  IF @Error<> 0  
  BEGIN  
   ERROR_HANDLER1:  
   IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION  
   INSERT INTO SmartDataErrorLog(IPAddress,Mc,ErrorMsg,[TimeStamp]) values(@IPAddress,@McInterfaceID,@Error,getdate())    
   SET @Error=0  
  END  
end  
 ------------------------------------ NR0117 Added Till Here --------------------------------------------------------------------  
  
  
  
----------------------------------------------- NR0118 Added From Here ----------------------------------------  
--Type 35 Record  
--START-DataType-MC-EventID-sDate-sTime-EDate-ETime-END  
If @tp_int=35  
BEGIN  
  
 If @StrLen<8  
 BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
   return -1;  
 END  
  
 --Event  
 SET @MachineEvent =SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
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
  
   
 IF NOT EXISTS(Select * from MachineEventsAutodata where MachineInterface=@McInterfaceID and EventID=@MachineEvent and Starttime=@startdate + ' '+ @starttime and Endtime=@enddate+ ' ' + @endtime) --ER0430  
 BEGIN --ER0430  
  
 Insert Into MachineEventsAutodata(RecordType,MachineInterface,EventID,Starttime,Endtime)Values  
 (@tp_int,@McInterfaceID,@MachineEvent,@startdate + ' '+ @starttime,@enddate+ ' ' + @endtime)  
  
 END --ER0430  
  
 SET @Error = @@ERROR  
 If @Error<>0  
 BEGIN  
  RAISERROR('Error In inserting the records in MachineEventsAutodata table[%s] - %s',16,1,@orgstring)  
  return -1;  
 END  
END  
-------------------------------------------- NR0118 Added Till Here --------------------------------------------------------------------  
  
------------------------------- NR0120 Added From Here -----------------------------------------------------    
--START-37-MC-COMP-OPRN-Featureid-DIMENSIONid-<VALUE>-DATE-TIME-END    
    
If @tp_int=37    
BEGIN    
    
  If @StrLen<10    
  BEGIN    
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)    
   return -1;    
  END    
    
    
  SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))     
  SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--To Remove Leading Zeroes    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)    
    
  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)    
    
  SET @FeatureID = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)    
    
  SET @ParameterID = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-@', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-@', @datastring)+ 2)    
    
  set @ActualValue=SUBSTRING(@datastring,1,CHARINDEX('/-',@datastring) - 1)    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('/-', @datastring)+ 2,LEN(@datastring) - CHARINDEX('/-', @datastring)+ 2)    
    
    
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)    
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)    
    
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)    
      
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())    
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)    
    
   If (IsDate(@startdate + ' ' + @starttime) = 1)    
   BEGIN     
      
    If ((Select Count(*) from InspectionAutodata)>0)    
    Begin    
    
     Select @Actualtime = (Select Top 1 Actualtime from InspectionAutodata order by ID desc)    
     Select @SampleID = (Select Top 1 Sampleid from InspectionAutodata order by ID desc)    
    
     If @Actualtime <> @startdate+ ' ' + @starttime    
     Begin    
      Select @SampleID = @SampleID + 1    
     end    
  
    END    
    Else    
    BEGIN    
     Select @SampleID = 1    
    END    
    
    Insert into InspectionAutodata( MC, COMP, OPN, FeatureID, ParameterID, ActualValue, Actualtime, SampleID)values    
    (@McInterfaceID,@component,@operation,@FeatureID,@ParameterID,@ActualValue,@startdate+ ' ' + @starttime,@SampleID)    
   END    
    
  SET @Error = @@ERROR    
  If @Error<>0    
  BEGIN        
   RAISERROR('Error In inserting the records in InspectionAutodata table[%s] - %s',16,1,@orgstring)    
   return -1;    
  END    
    
END    
------------------------------- NR0120 Added Till Here -----------------------------------------------------    
  
  
------------------------------ ER0421 Added From Here ------------------------------------------------  
---- String Format:: START-DT-MC-COMP-OPN-STDATE-STTIME-SHIFTID-TARGET-FLAG-END  
if @tp_int=45  
Begin  
   
  If @StrLen<10  
  BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
      return -1;  
  END  
  
  SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
    
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
  SET @ShiftID = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @Target= convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @Flag = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  
  
   If (IsDate(@startdate + ' ' + @starttime) = 1)  
   BEGIN  
  
    Select @MachineName = Machineid from Machineinformation where interfaceid=@McInterfaceID  
    Select @ComponentName = Componentid from Componentinformation where interfaceid=@component  
    Select @OperationName = operationno from Componentoperationpricing where Machineid=@MachineName and Componentid=@ComponentName and interfaceid=@operation  
  
    Select @Starttime = @startdate + ' ' + @starttime  
    Select @Reccount=1  
      
    Insert into #RejTimestamp(Startdate,HourID,HourStart,HourEnd,Target)   
    Exec [dbo].[s_GetRejectionTimestamp] @Starttime,@Shiftid,@Flag,@Target,'Hourlytarget'  
  
    Select @TableRecCount = Count(*) from #RejTimestamp  
  
    While @Reccount<=@TableRecCount  
    BEGIN  
       
     Select @Startdate = Startdate,@HourID=HourID,@Hourname ='Hour'+@HourID,@HourStart=HourStart,@HourEnd=HourEnd,@Target=Target from #RejTimestamp where IDD = @Reccount  
  
  
     IF NOT EXISTS(Select * from ShiftHourTargets where Machineid=@MachineName and ComponentID=@ComponentName and OperationNo=@OperationName and Sdate=@Startdate  
     and Shiftid=@shiftid and HourID=@HourID)   
     BEGIN    
  
      insert into ShiftHourTargets(Machineid, ComponentID, OperationNo, Sdate, ShiftID, HourName, HourID, HourStart, HourEnd, Target)  
      values(@MachineName,@ComponentName,@OperationName,@Startdate,@shiftid,@Hourname,@HourID,@HourStart,@HourEnd,@Target)  
     END   
     else  
     Begin  
       update ShiftHourTargets Set Target = @Target  
       where Machineid=@MachineName and ComponentID=@ComponentName and OperationNo=@OperationName and Sdate=@Startdate   
       and Shiftid=@shiftid and HourID=@HourID  
     End  
   
    Select @Reccount = @Reccount + 1  
    END  
   END  
  
   SET @Error = @@ERROR  
      If @Error<>0  
      BEGIN      
    RAISERROR('Error In inserting the records in [ShiftHourTargets] table[%s] - %s',16,1,@orgstring)  
    return -1;  
      END  
 End  
------------------------------ ER0421 Added Till Here ------------------------------------------------  
  
------------------------------NR0122 Added From Here-------------------------------------------------------  
--s_GetProcessDataString 'START-50-1-10-20160129-150000-END','127.0.0.1','','33'  
--START-50-MC ID-OPR ID-LOGIN DATE- TIME-END  
if @tp_int=50  
BEGIN  
  
If @StrLen<6  
 BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
   return -1;  
 END  
 SET @operator = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))    
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
  BEGIN  
    INSERT INTO Login_historyDetails (Machine,RecordType,Login_TS,Operator)  
    VALUES(@McInterfaceID,@tp_int,@startdate + ' ' + @starttime,@operator )  
  END  
    
  SET @Error = @@ERROR  
  --print @Error  
   
  IF @Error <> 0  
  BEGIN    
     RAISERROR ('Error inserting Login_historyDetails record for %s', 16, 1,@orgstring)  
     RETURN -1;  
  END  
  
END  
  
------------------------------NR0122 Added Till Here--------------------------------------------------------  
  
  
-------------------------------NR0122 Added From Here-------------------------------------------------------  
--s_GetProcessDataString 'START-51-1-10-20160129-160000-20160126-165000-END  ','127.0.0.1','','33'  
--START-51-MC ID-OPR ID-LOGIN DATE- TIME-LOGOUT DATE-TIME-END  
if @tp_int=51  
BEGIN  
If @StrLen<8  
 BEGIN  
   RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)  
   return -1;  
 END  
  
 SET @operator = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))    
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
  
    If (IsDate(@startdate + ' ' + @starttime) = 1)  
  BEGIN  
    INSERT INTO Login_historyDetails (Machine,RecordType,Login_TS,LogOut_TS,Operator)  
    VALUES(@McInterfaceID,@tp_int,@startdate + ' ' + @starttime,@enddate + ' ' + @endtime,@operator )  
  END  
    
  SET @Error = @@ERROR  
  --print @Error  
   
  IF @Error <> 0  
  BEGIN    
     RAISERROR ('Error inserting Login_historyDetails record for %s', 16, 1,@orgstring)  
     RETURN -1;  
  END  
END  
-------------------------------NR0122 Added Till Here---------------------------------------------------------  
  
  
/************************************************************************************************  
NR0133::Type 15 Record  
 Tool Change - START-15-MachineID-ToolNo-SeqNo-StDate-StTime-EdDate-EdTime-END  
***********************************************************************************************/  
If @tp_int=15  
BEGIN  
  
 If @StrLen<8  
 BEGIN  
      RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)  
            return -1;  
 END  
  
   DECLARE @ToolSeqNo As Int  
   
  --ToolNo  
     SET @ToolNo = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  --ToolNo  
     SET @ToolSeqNo = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
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
  
        Insert Into Rawdata(Datatype,IPAddress,Mc,SPLSTRING1,SPLSTRING2,Sttime,ndtime,Status)values  
   (@tp_int,@IpAddress,@McInterfaceID,@ToolNo,@ToolSeqNo,@startdate + ' ' +@starttime,@enddate + ' ' +@endtime,0)  
    
        SET @Error = @@ERROR           
    If @Error<>0  
    BEGIN  
   RAISERROR('Error In inserting the Datatype-15 records in rawdata table[%s] - %s',16,1,@IpAddress,@Orgstring)  
   return -1;  
    END  
END--type15  
  
  
  
/************************************************************************************************  
NR0134 :: Type 22 Record  
 SONA To Show DownReason - START-22-MachineID-COMP-OPN-OPR-DOWNCODE-StDate-StTime-END  
***********************************************************************************************/  
If @tp_int=22  
BEGIN  
  
 --SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
 --SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
  
 --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

if CHARINDEX(']-', @datastring)>0
Begin
 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
END
ELSE
Begin
 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
End


 SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
  SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 SET @downcode = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
 
	-- SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	if CHARINDEX('-[', @datastring)>0
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
	End
	Else
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End  

  if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
  begin 
-- SET @WorkOrder = convert(nvarchar,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
--SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	if CHARINDEX(']-', @datastring)>0
	Begin
	SET @WorkOrder = SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1) 
	SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
	SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
	END
	ELSE
	Begin
	SET @WorkOrder=convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
	SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	End
  END
  
 --startdate  
 SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())   
        
 SET @Error = @@ERROR  
 IF @Error <> 0  
 Begin  
 RAISERROR('RawData::Invalid StartDate:[%s] - %s',16,1,@IpAddress,@Orgstring)  
 return -1;  
 End  
  
 --starttime  
 SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 SET @starttime = dbo.f_GetTpmStrToTime(@starttime)         
   
 --mod 6  
 SET @Error = @@ERROR  
 IF @Error <> 0  
 Begin  
 RAISERROR('RawData::Invalid StartTime:[%s] - %s',16,1,@IpAddress,@Orgstring)  
 return -1;  
 End  
  
 Insert into Rawdata(datatype,IPAddress,Mc,Comp,Opn,Opr,Sttime,SPLSTRING2,WorkOrderNumber,Status)values  
  --(@tp_int,@IpAddress,@McInterfaceID,@component,@operation,@operator,@startdate+ ' ' + @starttime,@downcode,@WorkOrder,0)  --ER0499
  (@tp_int,@IpAddress,@McInterfaceID,@component,@operation,@operator,@startdate+ ' ' + @starttime,@downcode,@WorkOrder,15)  --ER0499  
  
 SET @Error = @@ERROR           
 If @Error<>0  
 BEGIN  
 RAISERROR('Error In inserting the Datatype-22 records into rawdata table[%s] - %s',16,1,@IpAddress,@Orgstring)  
 return -1;  
 END  
  
END --End OF Type 22  
  
  
------------------------------------------------------------------------DataType=55-----------------------------------------------------------------------------------  
/************************************************************************************************  
ER0450::Type 55 Record  
 Tool Change - START - 55 - MACHINE ID - CODE - CURRENT DATE - CURRENT TIME - END  
***********************************************************************************************/  
If @tp_int=55  
BEGIN  
  
 If @StrLen<5  
 BEGIN  
      RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)  
            return -1;  
 END  
  
  -- DECLARE @ToolSeqNo As Int  
   
  --ToolNo  
     SET @DetailNumber = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  
  
  --startdate  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())    
       
  --starttime  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
    
        Insert Into autodatadetails(RecordType,Machine,DetailNumber,Starttime)values  
   (@tp_int,@McInterfaceID,@DetailNumber,@startdate + ' ' +@starttime)  
    
      SET @Error = @@ERROR           
   If @Error<>0  
   BEGIN  
    RAISERROR('Error In inserting the Datatype - 55 records in autodatadetails table[%s] - %s',16,1,@Orgstring)  
    return -1;  
   END  
END--type55  
-----------------------------------------------------------------------End of DataType=55----------------------------------------------------------------------------------  
  
------------------------------------------------------------------------ [ER0450]  DataType = 56 -----------------------------------------------------------------------------------  
--Type 56 Record - For ShanthiIron When PM is 70% and 100% then PLC will send Datatype 56 and will be stod in PM_Autodatadetails table and   
--Alert_Notification_History Table for Sending SMS and Email.  
  
--Alert Notification - START - 56 - MACHINE ID - MAIN CATEGORY CODE - SUB CATEGORY CODE - SELECTION CODE - TARGET - ACTUAL - PERCENTVALUE - DATE - TIME - END  
  
If @tp_int=56  
BEGIN  
 
 
 If @StrLen<8  
 BEGIN  
      RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)  
            return -1;  
 END  
   
  SET @maincategory = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @subcategory = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @selection = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @targetValue = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @ActualValue = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 
  SET @PercentValue = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
 
  --startdate  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  select @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())    

  --starttime  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  select @starttime = dbo.f_GetTpmStrToTime(@starttime)  

	If (IsDate(@startdate + ' ' + @starttime) = 1)    
	BEGIN    
		   Insert Into PM_AutodataDetails(RecordType,MainCategory,SubCategory,Machine,SelectionCode,Starttime,[target],Actual)values  
		  (@tp_int,@maincategory,@subcategory,@McInterfaceID,@selection,@startdate + ' ' +@starttime,@targetValue,@ActualValue)  
		  
		  select @MachineName= Machineid from machineinformation where interfaceid=@McInterfaceID   
		  
		  declare @mainbusinesscategory as nvarchar(100)  
		  declare @subbusinesscategory as nvarchar(100)  
		  
		  select top 1 @mainbusinesscategory =[Category] from [dbo].[PM_Category] where [InterfaceID]=@maincategory  
		  select top 1 @subbusinesscategory = [SubCategory] from [dbo].[PM_Information] where [Category]= @mainbusinesscategory and [SubCategoryID]=@subcategory  
		  
		  
		  IF not exists(select * from Alert_Notification_History where RuleID='Preventive Maintenance' and Machineid=@MachineName and [AlertStartTS]=@startdate + ' ' +@starttime)  
		  BEGIN  		  
--			  Declare @TargetPercent as int
--			  Select @TargetPercent = (Round(((@ActualValue/@targetValue)*100),0))

			Insert Into Alert_Notification_History([RuleID],[MachineID],[AlertType],  
			[SMSEnabled],[EmailEnabled],[CreatedTime],[Subject],[BodyMessage],[MobileNo],[AlertStartTS],[Status],[RetryCount])  
			select Track,@MachineName,'SMS','1','0',getdate(),[Message]+ ' [' + convert(nvarchar(10),@startdate,120) + ' ' + convert(nvarchar(10),@starttime,120) + ']',  
			Case when @TargetValue<>@ActualValue then 
			@MachineName + ': ' + cast(@PercentValue  as nvarchar(50)) + '%' + ' Target Reached' + ' [Target]: ' + cast(@TargetValue as nvarchar(50)) +' Days' + ' [Actual]: ' + cast(@ActualValue as nvarchar(50)) +' Days' +  ' [Remaining Days]: ' + Cast((@TargetValue-@ActualValue) as nvarchar(50)) + ' Days' 
			Else
			@MachineName + ': ' + cast(@PercentValue  as nvarchar(50)) + '%' + ' Target Reached' + ' [Target]: ' + cast(@TargetValue as nvarchar(50)) +' Days' + ' [Actual]: ' + cast(@ActualValue as nvarchar(50)) +' Days'
			End,[MobileNo],@startdate + ' ' +@starttime,0,0  
			from [dbo].[BusinessRules] where track='Preventive Maintenance' and [Resource]=@MachineName  	  
		  END  
   END

  SET @Error = @@ERROR           
  If @Error<>0  
  BEGIN  
  RAISERROR('Error In inserting the Datatype - 56 records in PM_AutodataDetails table[%s] - %s',16,1,@Orgstring)  
  return -1;  
  END  
END--type 56  
----------------------------------------------------------------------- End of DataType = 56 ----------------------------------------------------------------------------------  
  
  
  
------------------------------------------------------------------------ [ER0450] DataType = 57 -----------------------------------------------------------------------------------  
--Type 57 Record - For Shanthi Iron When PM is OK then Datatype 57 will come from PLC for each Category and SubCategory and it will be stored in PM_Autodatadetails table.  
--s_GetProcessDataString 'START-57-2-1-1-2-1-1000-20170719-162650-END','127.0.0.1','','33'  
--Alert Notification - START - 57 - MACHINE ID - OPERATORID - MAIN CATEGORY CODE - SUB CATEGORY CODE - SELECTION CODE - TARGET - ACTUAL - DATE - TIME - END  
  
If @tp_int=57  
BEGIN  
  
 If @StrLen<9  
 BEGIN  
      RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)  
      return -1;  
 END  
   
	SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') 
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @maincategory = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @subcategory = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @selection = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @targetValue = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @ActualValue = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  --startdate  
  SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())    
       
  --starttime  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
  
     Insert Into PM_AutodataDetails(RecordType,Machine,OprInterfaceID,MainCategory,SubCategory,SelectionCode,Starttime,[target],Actual)values  
  (@tp_int,@McInterfaceID,@operator,@maincategory,@subcategory,@selection,@startdate + ' ' +@starttime,@targetValue,@ActualValue)  
  
  
  SET @Error = @@ERROR           
  If @Error<>0  
  BEGIN  
  RAISERROR('Error In inserting the Datatype - 57 records in PM_AutodataDetails table[%s] - %s',16,1,@Orgstring)  
  return -1;  
  END  
END--type 57  
----------------------------------------------------------------------- End of DataType = 57 ----------------------------------------------------------------------------------  
  
  
  
------------------------------------------------------------------------[ER0450] DataType = 58 -----------------------------------------------------------------------------------  
--Type 58 Record - For Shanthi Iron When PM is NOTOK then Datatype 58 will come from PLC for each Category and SubCategory WITH REASON and it will be stored in PM_Autodatadetails table.  
--Alert Notification - START - 58 - MACHINE ID - OPERATORID - MAIN CATEGORY CODE - SUB CATEGORY CODE - SELECTION CODE - TARGET - ACTUAL - REASON - DATE - TIME - END  
  
If @tp_int=58  
BEGIN  
  
 If @StrLen<10  
 BEGIN  
      RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)  
      return -1;  
 END  
   
  
	Declare @Reason as nvarchar(50)  
  
	SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') 
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @maincategory = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @subcategory = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @selection = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @targetValue = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @ActualValue = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  SET @Reason = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
  --startdate  
SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())    
       
  --starttime  
  SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
  SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  SET @starttime = dbo.f_GetTpmStrToTime(@starttime)  
  
  
     Insert Into PM_AutodataDetails(RecordType,Machine,OprInterfaceID,MainCategory,SubCategory,SelectionCode,Starttime,[target],Actual,Reason)values  
  (@tp_int,@McInterfaceID,@operator,@maincategory,@subcategory,@selection,@startdate + ' ' +@starttime,@targetValue,@ActualValue,@Reason)  
  
  
  SET @Error = @@ERROR           
  If @Error<>0  
  BEGIN  
  RAISERROR('Error In inserting the Datatype - 58 records in PM_AutodataDetails table[%s] - %s',16,1,@Orgstring)  
  return -1;  
  END  
END--type 58  
----------------------------------------------------------------------- End of DataType = 58 ----------------------------------------------------------------------------------  

------------------------------------------------ [ER0450] datatype=59------------------------------------------------------------
---START-59-MCID-OPERATOR-DATE-TIME-END
If @tp_int=59
BEGIN

		If @StrLen<4
		BEGIN
		RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)
		return -1;
		END	

		SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') 
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

		--startdate
		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())  
   		
		--starttime
		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)

		Insert Into PM_AutodataDetails(RecordType,Machine,OprInterfaceID,Starttime)values  
		(@tp_int,@McInterfaceID,@operator,@startdate + ' ' +@starttime)  

		Select @operator = Employeeid from Employeeinformation where interfaceid=@operator
		select @MachineName= Machineid from machineinformation where interfaceid=@McInterfaceID   
		--declare @PMTS as datetime
		--Select @PMTS = Max(Starttime) from PM_AutodataDetails Where (Machine=@McInterfaceID and RecordType=56 and Target=Actual) 


--		Select PMI.SubCategory,D.Downid into #Reason From PM_AutodataDetails PM
--		inner join PM_Category PC on PM.MainCategory=PC.InterfaceID
--		inner join PM_Information PMI on PC.Category=PMI.Category and PM.SubCategory=PMI.SubCategoryID
--		inner join Downcodeinformation D on PM.Reason=D.Interfaceid
--		Where PM.Machine=@McInterfaceID and PM.RecordType=58 and PM.Starttime>=@PMTS

		Select PMI.SubCategory,D.Downid into #Reason From PM_AutodataDetails PM
		inner join PM_Category PC on PM.MainCategory=PC.InterfaceID
		inner join PM_Information PMI on PC.Category=PMI.Category and PM.SubCategory=PMI.SubCategoryID
		inner join Downcodeinformation D on PM.Reason=D.Interfaceid
		Where PM.Machine=@McInterfaceID and PM.RecordType=58 and Convert(nvarchar(10),PM.Starttime,120)=Convert(nvarchar(10),@startdate,120)

		Declare @PMReasons as nvarchar(Max)
		Select @PMReasons = COALESCE(@PMReasons + ', ', '') + SubCategory + '-' + Downid FROM #Reason

		  if not exists(select * from Alert_Notification_History where RuleID='Preventive Maintenance' and Machineid=@MachineName and [AlertStartTS]=@startdate + ' ' +@starttime)  
		  BEGIN  

		  Insert Into Alert_Notification_History([RuleID],[MachineID],[AlertType],  
		  [SMSEnabled],[EmailEnabled],[CreatedTime],[Subject],[BodyMessage],[MobileNo],[AlertStartTS],[Status],[RetryCount])  
		  select Track,@MachineName,'SMS','1','0',getdate(),[Message]+ ' [' + convert(nvarchar(10),@startdate,120) + ' ' + convert(nvarchar(10),@starttime,120) + ']',  
		  @MachineName + ': ' + 'PM Is Completed On ' + @startdate + ' ' +@starttime + ' By ' + @operator + ' PM NOTOK FOR ' + @PMReasons,[MobileNo],@startdate + ' ' +@starttime,0,0  
		  from [dbo].[BusinessRules] where track='Preventive Maintenance' and [Resource]=@MachineName  
		  
		  END  
  
		SET @Error = @@ERROR 	       
		If @Error<>0
		BEGIN
		RAISERROR('Error In inserting the Datatype - 59 records in PM_AutodataDetails table[%s] - %s',16,1,@Orgstring)
		return -1;
		END
END
------------------------------------------------datatype=59------------------------------------------------------------ 



-------------------------------------------------------- [NR0139] Datatype=46--------------------------------------------------------------------------
---START-46-MCID-Lines Inspected-NC Lines-EQP-IQP-EQP Thershold-IQP Thershold-Transaction Lines Inspected -Transaction NC Lines-Date-Time-END

If @tp_int=46
BEGIN

		If @StrLen<9
		BEGIN
		RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)
		return -1;
		END	

		Declare @Linesinspected as int
		Declare @EQP as int
		Declare @IQP as int
		Declare @EQPThreshold as int
		Declare @IQPThreshold as int
		Declare @NCLines as int
		Declare @TransLinesInspected as int
		Declare @TransNCLines as int


	    SET @Linesinspected = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

	    SET @NCLines = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @EQP = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @IQP = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @EQPThreshold = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @IQPThreshold = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @TransLinesInspected = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @TransNCLines = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		--startdate
		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())  
   		
		--starttime
		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)

		IF NOT EXISTS(Select * from JohnCrane_LineInspection where datatype=@tp_int and MachineID=@McInterfaceID and [TimeStamp]=@startdate + ' ' +@starttime)
		BEGIN
	    Insert Into JohnCrane_LineInspection(Datatype, MachineID, LineInspected, NCLines, EQP, IQP,EQPThreshold,IQPThreshold,TransLinesInspected,TransNCLines,[TimeStamp])values
		(@tp_int,@McInterfaceID,@Linesinspected,@NCLines,@EQP,@IQP,@EQPThreshold,@IQPThreshold,@TransLinesInspected,@TransNCLines,@startdate + ' ' +@starttime)
		END

		SET @Error = @@ERROR 	       
		If @Error<>0
		BEGIN
		RAISERROR('Error In inserting the Datatype - 46 records in JohnCrane_LineInspection table[%s] - %s',16,1,@Orgstring)
		return -1;
		END
END--type 46

------------------------------------------------ [NR0139] datatype=47------------------------------------------------------------
---START-47-MCID-DATE-TIME-END
If @tp_int=47
BEGIN

		If @StrLen<3
		BEGIN
		RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)
		return -1;
		END	

		--startdate
		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())  
   		
		--starttime
		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)

		IF NOT EXISTS(Select * from JohnCrane_LineInspection where datatype=@tp_int and MachineID=@McInterfaceID and [TimeStamp]=@startdate + ' ' +@starttime)
		BEGIN
	    Insert Into JohnCrane_LineInspection(Datatype, MachineID, [TimeStamp])values
		(@tp_int,@McInterfaceID,@startdate + ' ' +@starttime)
		END

		SET @Error = @@ERROR 	       
		If @Error<>0
		BEGIN
		RAISERROR('Error In inserting the Datatype - 47 records in JohnCrane_LineInspection table[%s] - %s',16,1,@Orgstring)
		return -1;
		END
END
------------------------------------------------datatype=47------------------------------------------------------------  
 
--------------------------------------------------------[NR0139] Datatype=65--------------------------------------------------------------------------
---START-65-MCID-WorkOrderNo-Qty-EventID-EventDate-EventTime-END

If @tp_int=65
BEGIN

		If @StrLen<5
		BEGIN
		RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)
		return -1;
		END	

		Declare @Qty as int
		Declare @EventID as int
		Declare @EventDate as nvarchar(12)  
		Declare @EventTime as nvarchar(15)  
		declare @LogicalEventDate as datetime
		declare @WorkOrderNo as nvarchar(50)

	    SET @WorkOrderNo = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @WorkOrderNo=REPLACE(LTRIM(REPLACE(@WorkOrderNo, '0', ' ')), ' ', '0')
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

	    SET @Qty = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @EventID = cast(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)as int)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		--startdate
		SET @EventDate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @EventDate = dbo.f_GetTpmStrToDate(@EventDate,GetDate())  

		--starttime
		SET @EventTime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @EventTime = dbo.f_GetTpmStrToTime(@EventTime)

		Select @LogicalEventDate = @EventDate + ' ' +@EventTime
		Select @LogicalEventDate = dbo.f_GetLogicalDay(@LogicalEventDate,'start')


		IF NOT EXISTS(Select * from JohnCrane_EventDetails where MachineID=@McInterfaceID and WorkOrderNo=@WorkOrderNo and EventTS=@EventDate + ' ' +@EventTime)
		BEGIN
	    Insert Into JohnCrane_EventDetails(MachineID, WorkOrderNo, EventID, Quantity, EventTS, EventDate)values
		(@McInterfaceID,@WorkOrderNo,@EventID,@Qty,@EventDate + ' ' +@EventTime,@LogicalEventDate)
		END

		SET @Error = @@ERROR 	       
		If @Error<>0
		BEGIN
		RAISERROR('Error In inserting the Datatype - 65 records in JohnCrane_EventDetails table[%s] - %s',16,1,@Orgstring)
		return -1;
		END
END--type 65

If @tp_int=44
BEGIN   

		declare @EventTS as datetime	
		If @StrLen<5
		BEGIN
		RAISERROR('Invalid Number Of Parameters in the string[%s]: - %s',16,1,@IpAddress,@Orgstring)
		return -1;
		END	
     
		
		--SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
  --      SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')  
  --      SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

		if CHARINDEX(']-', @datastring)>0
		Begin
		print '1'
		SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
		SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
		END
		ELSE
		Begin
		print '2'
		SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
        SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')  
        SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
		End

		SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
      
        SET @operator =SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
        SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
        SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		
	    SET @WorkOrderNo = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @WorkOrderNo=REPLACE(LTRIM(REPLACE(@WorkOrderNo, '0', ' ')), ' ', '0')
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
   
        SET @MachineEvent =SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
        SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
		     
		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)	
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())  
		
		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)
		
		SELECT @EventTS= CONVERT(datetime,(@startdate + ' ' +@starttime))

		select @McInterfaceID = machineid from machineinformation where InterfaceID = @McInterfaceID
		select @component = componentid from componentinformation where InterfaceID = @component

		If ISNULL(@McInterfaceID,'a')<>'a' and ISNULL(@component,'a')<>'a'
		Begin
			IF NOT EXISTS(Select * from SetupTransaction_Peekay where mc=@McInterfaceID and WorkOrderNo=@WorkOrderNo and EventTS=@startdate + ' ' +@starttime)
			BEGIN		
				if @MachineEvent ='1'
				begin
				 set @MachineEvent ='SetupStart'
				end
				if @MachineEvent ='2'
				begin
				 set @MachineEvent ='SetupEnd'
				end
				if @MachineEvent ='3'
				begin
				 set @MachineEvent ='CycleEnd'
				end	

				Insert Into SetupTransaction_Peekay( mc,comp,opn,RecordType,WorkOrderNo,Opr,EventID,EventTS)values
				(@McInterfaceID,@component,@operation,@tp,@WorkOrderNo,@operator,@MachineEvent,@EventTS)		
			END
		END

		SET @Error = @@ERROR 	       
		If @Error<>0
		BEGIN
		RAISERROR('Error In inserting the Datatype - 44 records in SetupTransaction_Peekay table[%s] - %s',16,1,@Orgstring)
		return -1;
		END
		
END--type 44
 


if @tp_int = 86
	Begin

	 Declare @Edge nvarchar(50)
	 Declare @ToolTarget int
	 Declare @ToolActual int
		If @StrLen<10
		BEGIN
			RAISERROR('Invalid Number Of Parameters in the string[%s] - %s',16,1,@IpAddress,@Orgstring)
		    	return -1;
		END

		SET @component = convert(bigint,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		
		SET @ToolNo = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @Edge = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	    
		--SET @ToolTarget = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
		SET @ToolTarget = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		
		--SET @ToolActual = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
		SET @ToolActual = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)

		If (IsDate(@startdate + ' ' + @starttime) = 1)
		BEGIN
			Insert into Rawdata(datatype,IPAddress,Mc,Comp,Opn,SPLSTRING1,SPLString3,SPLSTRING4,SPLSTRING5,Sttime,Status)values
			(@tp_int,@IpAddress,@McInterfaceID,@component,@operation,@ToolNo,@Edge,@ToolTarget,@ToolActual,@startdate+ ' ' + @starttime,0)
		END

		SET @Error = @@ERROR
	    If @Error<>0
	    BEGIN 			RAISERROR('Error In inserting the records in AutodataRejections table[%s] - %s',16,1,@orgstring)
		return -1;
	    END
	End

---------------ER0502 Added From here For AAAPL
 If @tp_int = 78 
 BEGIN  
  
  --To Read Line  
  select @Line= Plantcode from PlantInformation P   
  inner join Plantmachine PM on P.Plantid=PM.Plantid  
  inner join Machineinformation M on M.Machineid=PM.Machineid  
  where M.IP=@IpAddress  
 
   --Event  
   SET @EventNo= convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
     
   --Action1  
   SET @Action1= convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
   --Action2  
   SET @Action2= convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
  
   --startdate  
   SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())         
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('RawData::Invalid StartDate:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  
   --starttime  
   SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
   SET @starttime = dbo.f_GetTpmStrToTime(@starttime)         
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('RawData::Invalid StartTime:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  

   SET @Remarks= convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
   SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	If Exists(Select * from HelpCodeDetails where Plantid=@Line and Machineid=@McInterfaceID and DataType=76 and HelpCode=@EventNo and  
	Action1=@Action1 and isnull(Action2,'00')=isnull(@Action2,'00') and Starttime=@startdate + ' '+ @starttime)  
	Begin      
		Update HelpCodeDetails set Remarks=@Remarks  
		where Plantid=@Line and Machineid=@McInterfaceID and DataType=76 and HelpCode=@EventNo and  
		Action1=@Action1 and isnull(Action2,'00')=isnull(@Action2,'00') and Starttime=@startdate + ' '+ @starttime
	End  
  
   SET @Error = @@ERROR  
   IF @Error <> 0  
   Begin  
    RAISERROR('Insert into HelpCodeDetails:[%s] - %s',16,1,@IpAddress,@Orgstring)  
    return -1;  
   End  
  END  
   
----ER0502 Added Till here For AAAPL
  
If @tp_int=96
BEGIN   

	IF @RemoveLeadZeroInProcessString='Y'
	 BEGIN
			if CHARINDEX(']-', @datastring)>0
			Begin
			print '1'
			 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
			 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
			 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
			END
			ELSE
			Begin
			print '2'
			 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
			 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
			 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
			End
	  END
	  ELSE
	  BEGIN
			if CHARINDEX(']-', @datastring)>0
			Begin
			print '1'
			 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
			 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
			END
			ELSE
			Begin
			print '2'
			 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
			 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
			End
	  END

		SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
      
        SET @operator =SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
        SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
        SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		 
		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)	
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())  
		
		SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @starttime = dbo.f_GetTpmStrToTime(@starttime)
		
		SET @enddate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)	
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @enddate = dbo.f_GetTpmStrToDate(@enddate,GetDate())  
		
		SET @endtime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @endtime = dbo.f_GetTpmStrToTime(@endtime)
		
		if not exists(select * from SetupTransaction_KTA where mc=@McInterfaceID and comp=@component and opn=@operation and opr=@operator and SetupStartTime=@startdate + ' ' +@starttime and SetupEndTime=@enddate+ ' ' +@endtime)
		BEGIN
			Insert into SetupTransaction_KTA (mc,comp,opn,opr,SetupStartTime,SetupEndTime)
			Select  @McInterfaceID,@component,@operation,@operator,@startdate + ' ' +@starttime,@enddate+ ' ' +@endtime
		END

		SET @Error = @@ERROR 	       
		If @Error<>0
		BEGIN
		RAISERROR('Error In inserting the Datatype - 96 records in SetupTransaction_KTA table[%s] - %s',16,1,@Orgstring)
		return -1;
		END
		
END--type 44
 
 -----------------------------------START-66-MachineInterface-CompInterface-OperatorInterface-ParameterID-ActValue-LowValue-HighValue-Date-Time-END ----------------------------------------------------
If @tp_int=66
BEGIN   

declare @ParmeterID NVARCHAR(50)
declare @ActValue FLOAT
declare @LowValue FLOAT
declare @HighValue FLOAT
DECLARE @CycleStartDate nvarchar(12)
DECLARE @CycleStartTime nvarchar(15)

	 if (SUBSTRING( @datastring,1,1)) = '['
	Begin
	print '1'
	 SET @datastring = SUBSTRING(@datastring,CHARINDEX('[', @datastring)+ 1,LEN(@datastring) - CHARINDEX('[', @datastring)+ 1) 
	 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
	 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
	 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)
	END
	ELSE
	Begin
	print '2'
	 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
	 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
	 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End
 
	SET @operator = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
	SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
  
	if CHARINDEX('-[', @datastring)>0
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
	End
	Else
	Begin
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	End 

	SET @ParameterID = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
	
	SET @ActValue = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @LowValue = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	SET @HighValue = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

	
	SET @CycleStartDate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)	
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	SET @CycleStartDate = dbo.f_GetTpmStrToDate(@CycleStartDate,GetDate())  
		
	SET @CycleStartTime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	SET @CycleStartTime = dbo.f_GetTpmStrToTime(@CycleStartTime)



	if not exists(select * from ProcessParameterTransaction_BajajIoT where MachineID=@McInterfaceID and ComponentID=@component
	and ParameterID=@ParameterID and UpdatedtimeStamp=@CycleStartDate + ' ' +@CycleStartTime)
	begin
		INSERT INTO ProcessParameterTransaction_BajajIoT(DataType,MachineID,ComponentID,OperatorID,ParameterID,ParameterValue,MinValue,MaxValue,UpdatedtimeStamp)VALUES
		(@tp_int,@McInterfaceID,@component,@operator,@ParameterID,@ActValue,@LowValue,@HighValue,@CycleStartDate + ' ' +@CycleStartTime)
   end

end

 -----------------------------------START-66-MachineInterface-CompInterface-OperatorInterface-ParameterID-ActualValue-LowValue-HighValue-Date-Time-END ----------------------------------------------------


/********************************
To process Focas Live data  : DataType 67
String format : START-DT-MC-PROGRAMNO-MODE-STATUS-POT-OT-CT-PARTCOUNTER-DATE-TIME-END

Exec s_GetProcessDataString 'START-67-1-O1200-4-1-1234-123-12345-900-20221010-112000-END','127.0.0.1','','33'  

************************************/
If @tp_int=67
BEGIN   
	
	Declare @MMode int
	Declare @MStatus int
	Declare @ProgramNo nvarchar(50)
	Declare @PowerOnTime float
	Declare @OperatingTime float
	Declare @CutTime float
	Declare @PartsCount int
	Declare @BatchTS datetime

	Declare @PreviousBatchTS datetime
	Declare @PreviousProgramNo nvarchar(50)
	Declare @PreviousPartsCount int
	Declare @LastID datetime

	Set  @LastID = (Select max(ID)  from Focas_LiveData)
	Set  @PreviousBatchTS = (select Top 1 BatchTS from Focas_LiveData where ID=@LastID)
	Set  @PreviousProgramNo = (select Top 1 ProgramNo from Focas_LiveData where ID=@LastID)
	Set  @PreviousPartsCount = (select Top 1 PartsCount from Focas_LiveData where ID=@LastID)

	select @MachineName= Machineid from machineinformation where interfaceid=@McInterfaceID  

	SET @ProgramNo = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
	
	SET @MMode = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

	SET @MStatus = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

	SET @PowerOnTime = convert(float,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

	SET @OperatingTime = convert(float,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

	SET @CutTime = convert(float,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

	SET @PartsCount = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

	SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

	SET @starttime = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)
	SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)

	SET @startdate = dbo.f_GetTpmStrToDate(@startdate,getdate())
	SET @starttime = dbo.f_GetTpmStrToTime(@starttime)

	IF isnull(@LastID,'')<>''
	BEGIN
		if ((@PreviousProgramNo <> @ProgramNo) or (@PreviousPartsCount > @PartsCount))
		BEGIN
			Set @BatchTS = (@startdate + ' ' + @starttime)
		END
		else
		BEGIN
			Set @BatchTS = @PreviousBatchTS
		END
	END
	ELSE
	BEGIN
		Set @BatchTS = (@startdate + ' ' + @starttime)
	END

	If ((IsDate(@startdate + ' ' + @starttime) = 1) and isnull(@MachineName,'')<>'')
	BEGIN
		Insert into Focas_Livedata(MachineID,ProgramNo,MachineMode,MachineStatus,PowerOnTime,OperatingTime,CutTime,PartsCount,CNCTimeStamp,BatchTS)
		Select @MachineName as MachineName,@ProgramNo as ProgramNo,
		(case when @MMode=1 then 'MEM' when @MMode=2 then 'SINGLE AUTO' when @MMode=3 then 'MDI' when @MMode=4 then 'JOG' when @MMode=5 then 'EDIT' when @MMode=6 then 'HND' END) as MachineMode,
		(case when @MStatus=1 then 'RUNNING' when @MStatus=2 then 'STOPPED' END) as MachineStatus,
		@PowerOnTime as PowerOnTime,@OperatingTime as OperatingTime,@CutTime as CutTime,@PartsCount as PartsCount,(@startdate+ ' ' + @starttime) as CNCTimeStamp,@BatchTS as BatchTS
	END	
END
 
/********************************
To process ProductionCountDetails_KKPillar data  : DataType 68
String format : START-68-MC-COMP-OPN-OPR-WO-ProductionCount-Date-Shift-END

Exec s_GetProcessDataString 'START-68-407-3811-20-1-8-20220901-1-END','127.0.0.1','','33'  

************************************/

If @tp_int=68
BEGIN   

	IF @RemoveLeadZeroInProcessString='Y'
	 BEGIN
			if CHARINDEX(']-', @datastring)>0
			Begin
				print '1'
				 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
				 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
				 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
			END
			ELSE
			Begin
				print '2'
				 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
				 SET @component = REPLACE(LTRIM(REPLACE(@component, '0', ' ')), ' ', '0')--ER0387 To Remove Leading Zeroes  
				 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
			End
	  END
	  ELSE
	  BEGIN
			if CHARINDEX(']-', @datastring)>0
			Begin
			print '1'
			 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1)) --ER0387  
			 SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
			END
			ELSE
			Begin
			print '2'
			 SET @component = convert(nvarchar(50),SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --ER0387  
			 SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
			End
	  END

		SET @operation = convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1))  
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  
      
        SET @operator =SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)--ER0421  
        SET @operator = REPLACE(LTRIM(REPLACE(@operator, '0', ' ')), ' ', '0') --ER0421  
        --SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		 
		if CHARINDEX('-[', @datastring)>0
		Begin
			SET @datastring = SUBSTRING(@datastring,CHARINDEX('-[', @datastring)+ 2,LEN(@datastring) - CHARINDEX('-[', @datastring)+ 2)  
		End
		Else
		Begin
			SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1) 
		End  

		---mod 5: Get the WorkOrderNumber from the string if SD settings for WorkOrder is "Y"  
		if (select isnull(Workorder,'N') from smartdataportrefreshdefaults)='y'  
		begin  
			if CHARINDEX(']-', @datastring)>0
			Begin
				SET @WorkOrder = SUBSTRING(@datastring,1,CHARINDEX(']-',@datastring) - 1) 
				SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
				SET @datastring = SUBSTRING(@datastring,CHARINDEX(']-', @datastring)+ 2,LEN(@datastring) - CHARINDEX(']-', @datastring)+ 2)  
			END
			ELSE
			Begin
				SET @WorkOrder=SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) 
				SET @WorkOrder=REPLACE(LTRIM(REPLACE(@WorkOrder, '0', ' ')), ' ', '0')
				SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1) 
			End
		end 

		SET @PalletCount = CAST(SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1) as nvarchar(10)) --Commented for GEA to allow decimal
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)  

		SET @startdate = SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)	
		SET @datastring = SUBSTRING(@datastring,CHARINDEX('-', @datastring)+ 1,LEN(@datastring) - CHARINDEX('-', @datastring)+ 1)
		SET @startdate = dbo.f_GetTpmStrToDate(@startdate,GetDate())  
		
		 SET @ShiftID = Convert(int,SUBSTRING(@datastring,1,CHARINDEX('-',@datastring) - 1)) --DR0333  

		 IF not exists(select * from ProductionCountDetails_KKPillar where Mc=@McInterfaceID and Comp=@component and Opn=@operation and Opr=@operator and WorkOrderNo=@WorkOrder
			and convert(nvarchar(10),[Date],120)=@startdate and [Shift]=@ShiftID)
		 BEGIN
			Insert into ProductionCountDetails_KKPillar(Mc,Comp,Opn,Opr,WorkOrderNo,PartCount,[Date],[Shift])
			 Select  @McInterfaceID as McInterfaceID,@component as component,@operation as operation,@operator as operator,@WorkOrder as WorkOrderNo,
			 @PalletCount as PartCount,@startdate as ShiftDate,@ShiftID as ShiftID
		 END
	
		SET @Error = @@ERROR 	       
		If @Error<>0
		BEGIN
			RAISERROR('Error In inserting the Datatype - 68 records in ProductionCountDetails_KKPillar table[%s] - %s',16,1,@Orgstring)
			return -1;
		END
		
END--type 44
 

--ER0464 g: To use this table instead of RawData for getting machine status in other procs
IF @tp_int in (1, 2, 11, 40, 41, 42) 
BEGIN

	IF NOT EXISTS (SELECT * FROM MachineRunningStatus WHERE MachineInterface = @McInterfaceID)
	BEGIN
		INSERT INTO MachineRunningStatus VALUES (@McInterfaceID, @startdate + ' ' +@starttime, @enddate + ' ' + @endtime, @tp_int, 'White')
	END
	ELSE
	BEGIN
		UPDATE MachineRunningStatus SET sttime =  @startdate + ' ' +@starttime, ndtime = @enddate + ' ' + @endtime, datatype = @tp_int WHERE MachineInterface=@McInterfaceID
	END
END
--ER0464 g: To use this table instead of RawData for getting machine status in other procs

END--procedure  
