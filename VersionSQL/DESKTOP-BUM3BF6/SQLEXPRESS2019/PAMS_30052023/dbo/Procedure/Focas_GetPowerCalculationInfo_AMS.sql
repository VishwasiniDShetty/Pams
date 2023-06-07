/****** Object:  Procedure [dbo].[Focas_GetPowerCalculationInfo_AMS]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Focas_GetPowerCalculationInfo_AMS]'80','628','0.184','','','5','ALUMINIUM','40 - 60','6','55','Milling','AMS-01'
--[dbo].[Focas_GetPowerCalculationInfo_AMS]'40','126','0.1','','','2','CAST IRON','210 - 230','','','DRILLING','AMS-01'
--[dbo].[Focas_GetPowerCalculationInfo_AMS]'24','14','','3.0','','','CAST IRON','230 - 250','','','BORING','AMS-01'
--[dbo].[Focas_GetPowerCalculationInfo_AMS]'30','120','0.1','','28','','STEEL','200 - 240','','','BORING','AMS-01'


CREATE PROCEDURE [dbo].[Focas_GetPowerCalculationInfo_AMS]
@CutterDaimeter float='', --D --tapDiameter
@CuttingSpeed float='', --Vc
@FeedPerTooth float='', --Sz--fz
@pitch float ='' , --p
@InitalBoreDia float='', --D1
@NoOfTooth float='', --Z
@Material nvarchar(50)='',
@MaterialHardness nvarchar(50) ='',
@DepthOfcut float='', --t
@widthOfcut float='',--b
@param nvarchar(50)='',
@Machine nvarchar(50)=''


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	

create table #Milling
(
SpindleSpeed float, --n = Vc * 1000/ pi * D
FeedPerMin float, --Sm=Sz*Z*n
FeedPerRevolution float, --S = Sm/n
ChipCrossSection float, --A=Sz*t
MRR float, --Q=(t*b*Sm)/1000
PowerRequiredAtSpindle float, --N--P=Q/30
CuttingForceAtSpindle float, -- Pz = 6120 * N /Vc
TorqueRequiredAtSpindle float, -- Ts= (975*N)/(n*9.8),
powerAvailable nvarchar(1000),
TorqueAvaiable nvarchar(max),
[message] nvarchar(4000),
[TorqueMessage] nvarchar(4000),
Color nvarchar(50) default 'red'
)

create table #DrillingTappingBoring
(
ToolRadius float, --R=D/2
SpindleSpeed float, --n = Vc*1000/pi *D
FeedPerMin float,  --Vf= fz*z*n
FeedPerRevolution float, --fn=Vf/n
Area float, -- A=3.142*D2/4
MRR float, -- Q=(A*Vf)/1000
PowerRequiredAtSpindle float,--N=Q/20; 
ThrustAtSpindle float, --Th=1.16KD(100* fn)power 0.85
TorqueRequiredAtSpindle float, 
ChipCrossSection float,
radialAllowance float,
CuttingForceAtSpindle float,
powerAvailable nvarchar(1000),
TorqueAvaiable nvarchar(max),
[message] nvarchar(4000),
[TorqueMessage] nvarchar(4000),
Color nvarchar(50) default 'red',
[Thrustmessage] nvarchar(4000) --SV added
)


create table #Focas_SpindleTrans_AMS
(
[Machine] [nvarchar](50),
[Type] [nvarchar](50) ,
[Baserpm] [float],
--[ShortTermPower] [float] NULL, --SV
[ShortTermPower1] [float] NULL,--SV
[ShortTermPower2] [float] NULL,--SV
[ShortTermPower3] [float] NULL,--SV
[Continiouspower] [float] NULL,
[Torque1] [float] NULL,
[Torque2] [float] NULL,
[Torque3] [float] NULL,
[Torque4] [float] NULL,
--SV From here
--[Message1] [nvarchar](50) NULL,
--[Message2] [nvarchar](50) NULL,
--[Message3] [nvarchar](50) NULL,
--[Message4] [nvarchar](50) NULL
[Message1] [nvarchar](500) NULL,
[Message2] [nvarchar](500) NULL,
[Message3] [nvarchar](500) NULL,
[Message4] [nvarchar](500) NULL,
[ShortTermPowerMsg1] [nvarchar](500) NULL,
[ShortTermPowerMsg2] [nvarchar](500) NULL,
[ShortTermPowerMsg3] [nvarchar](500) NULL
--SV Till Here
)


--SV From Here
--insert into #Focas_SpindleTrans_AMS([Machine],[Type],[Baserpm],[ShortTermPower],[Continiouspower],[Torque1],[Torque2] ,[Torque3],[Torque4],[Message1],[Message2],[Message3] ,[Message4])
--select  [Machine],[Type],[Baserpm],[ShortTermPower],[Continiouspower],[Torque1],[Torque2] ,[Torque3],[Torque4],[Message1],[Message2],[Message3] ,[Message4]
--from [dbo].Focas_SpindleTrans_AMS where Machine=@Machine

insert into #Focas_SpindleTrans_AMS([Machine],[Type],[Baserpm],[ShortTermPower1],[ShortTermPower2],[ShortTermPower3],[Continiouspower],[Torque1],[Torque2] ,[Torque3],[Torque4],[Message1],[Message2],[Message3] ,[Message4],
[ShortTermPowerMsg1],[ShortTermPowerMsg2],[ShortTermPowerMsg3])
select  [Machine],[Type],[Baserpm],[ShortTermPower1],[ShortTermPower2],[ShortTermPower3],[Continiouspower],[Torque1],[Torque2] ,[Torque3],[Torque4],[Message1],[Message2],[Message3] ,[Message4]
,[ShortTermPowerMsg1],[ShortTermPowerMsg2],[ShortTermPowerMsg3] from [dbo].Focas_SpindleTrans_AMS where Machine=@Machine
--SV Till Here

declare @KValue  as float
declare @value as float
declare @BaseSpeed as float
--declare @ShortTermPower as float --SV Commented
declare @ContiniousPower as float
declare @powerRequired as float
declare @torqueRequired as float
declare @SpindleSpeed as float
declare @ContinousPowerValue as float

--declare @ShortTermPowerValue as float --SV Commented

--SV
declare @SP1 as float
declare @SP2 as float
declare @SP3 as float
--SV

declare @torqueAvailable as nvarchar(max)
declare @T1 as float
declare @T2 as float
declare @T3 as float
declare @T4 as float


select @KValue =  Kvalue from [dbo].[Focas_PowerCalculatorConstants_AMS] where Material=@Material 
and Hardness = @MaterialHardness
select @value = isnull(res,0) from [dbo].Focas_PowerCalculatorConstants_AMS where Material=@Material 
and Hardness = @MaterialHardness 
select @BaseSpeed=1500;

--select @ShortTermPower =   ShortTermPower from #Focas_SpindleTrans_AMS --SV Commented
select @ContiniousPower = ContiniousPower   from #Focas_SpindleTrans_AMS

select @T1 = Torque1 from #Focas_SpindleTrans_AMS
select @T2 = Torque2 from #Focas_SpindleTrans_AMS
select @T3 = Torque3 from #Focas_SpindleTrans_AMS
select @T4 = Torque4 from #Focas_SpindleTrans_AMS

--SV
select @SP1 = [ShortTermPower1] from #Focas_SpindleTrans_AMS
select @SP2 = [ShortTermPower2] from #Focas_SpindleTrans_AMS
select @SP3 = [ShortTermPower3] from #Focas_SpindleTrans_AMS
--SV

if(@param='Milling')
BEGIN
insert into #Milling(SpindleSpeed,FeedPerMin,FeedPerRevolution,
ChipCrossSection,MRR,PowerRequiredAtSpindle,TorqueRequiredAtSpindle,CuttingForceAtSpindle)
values (0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)

update #Milling set SpindleSpeed = (isnull(@CuttingSpeed,0.0)*1000)/(pi() * @CutterDaimeter) 
update #Milling set FeedPerMin = isnull(@FeedPerTooth,0.0) * isnull(@NoOfTooth,0.0) * isnull(SpindleSpeed,0.0)
update #Milling set FeedPerRevolution= FeedPerMin/SpindleSpeed  where FeedPerMin > 0 and SpindleSpeed > 0 ;
update #Milling set ChipCrossSection =  isnull(@FeedPerTooth,0.0) * isnull(@DepthOfcut,0.0);
update #Milling set MRR = (isnull(@DepthOfcut,0.0) * isnull(@widthOfcut,0.0) * isnull(FeedPerMin,0.0))/1000;

update #Milling set PowerRequiredAtSpindle = isnull(MRR,0)/isnull(@value,0) where @value > 0 ;
update #Milling set CuttingForceAtSpindle = (isnull(6120,0.0)* PowerRequiredAtSpindle)/isnull(@CuttingSpeed,0.0) 
where isnull(@CuttingSpeed,0.0) > 0 
update #Milling set TorqueRequiredAtSpindle= (975 * PowerRequiredAtSpindle/  SpindleSpeed )*(9.8) 


select @powerRequired = powerrequiredAtSpindle from #Milling
select @torqueRequired = TorqueRequiredAtSpindle from #milling
select @SpindleSpeed =  spindleSpeed from #Milling

if(@SpindleSpeed > @BaseSpeed)
BEGIN

update #Milling set [message] = 'POWER IS AVAILABLE',color= 'Green';
--update #milling set powerAvailable = Convert(NVARCHAR(250),@ShortTermPower)  +'/' + Convert(NVARCHAR(250),@ContiniousPower) ; --SV
update #milling set powerAvailable = Convert(NVARCHAR(250),@SP1)  + '/' + Convert(NVARCHAR(250),@SP2) + '/' + Case when @SP3 IS NOT NULL then Convert(NVARCHAR(250),@SP3) + '/' ELSE '' END + Convert(NVARCHAR(250),@ContiniousPower) ; --SV

--SV From Here
-- if(@powerRequired <= @ShortTermPower and @powerrequired >= @ContiniousPower)
--BEGIN
--update #Milling set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + 'AND ITS IN SHORT TERM POWER DUTY', color= 'Green'
--END
--else if (@powerRequired <= @ContiniousPower)
--BEGIN
--update #Milling set [message] = 'REQUIRED POWER IS AVAILABLE '  + CHAR(13) + CHAR(10) + 'AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
--END
--else if(@powerRequired > @ShortTermPower)
--BEGIN
--update #Milling set [message] = 'POWER NOT AVAILABLE'  + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
--END

 if(@powerrequired >= @ContiniousPower and @powerRequired <= @SP1)
BEGIN
update #Milling set [message] = [ShortTermPowerMsg1], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if(@powerrequired >= @SP1 and @powerRequired <= @SP2)
BEGIN
update #Milling set [message] = [ShortTermPowerMsg2], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if(@powerrequired >= @SP2 and @powerRequired <= ISNULL(@SP3,0)) and ISNULL(@SP3,0)>0
BEGIN
update #Milling set [message] = [ShortTermPowerMsg3], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if (@powerRequired <= @ContiniousPower)
BEGIN
update #Milling set [message] = 'REQUIRED POWER IS AVAILABLE '  + CHAR(13) + CHAR(10) + 'AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
END
else if(@powerRequired > ISNULL(@SP3,0))  and ISNULL(@SP3,0)>0
BEGIN
update #Milling set [message] = 'POWER NOT AVAILABLE'  + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
END
Else
BEGIN
update #Milling set [message] = 'POWER NOT AVAILABLE' ,color= 'red'
END
--SV Till Here

END

select @ContinousPowerValue = round(((0 - @ContiniousPower )/( 0- @basespeed ))*(@SpindleSpeed),2)
--select @ShortTermPowerValue = round(((0- @ShortTermPower)/(0- @basespeed)) * (@SpindleSpeed),2) --SV Commented

if(@SpindleSpeed < @BaseSpeed)
BEGIN

--update #milling set powerAvailable = Convert(NVARCHAR(250),@ShortTermPowerValue)  +'/' + Convert(NVARCHAR(250),@ContinousPowerValue) ; --SV Commented
update #milling set powerAvailable = Convert(NVARCHAR(250),@SP1)  + '/' + Convert(NVARCHAR(250),@SP2) + '/' + Case when @SP3 IS NOT NULL then Convert(NVARCHAR(250),@SP3) + '/' ELSE '' END + Convert(NVARCHAR(250),@ContiniousPower) ; --SV
update #Milling set [message] = 'POWER IS AVAILABLE',color= 'Green';

--SV From Here
-- if( (@powerrequired >= @ContinousPowerValue ) and (@powerrequired <=@ShortTermPowerValue))
--BEGIN
--update #Milling set [message] = 'REQUIRED POWER IS AVAILABLE   '+ CHAR(13) + CHAR(10) +' AND ITS IN SHORT TERM POWER DUTY', color= 'Green'
--END
--else if(@powerrequired <= @ContinousPowerValue)
--BEGIN
--update #Milling set [message] = 'REQUIRED POWER IS AVAILABLE  '+ CHAR(13) + CHAR(10) + 'AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
--END
--else if(@powerrequired > @ShortTermPowerValue)
--BEGIN
--update #Milling set [message] = 'POWER NOT AVAILABLE  ' + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
--END

if(@powerrequired <= @ContinousPowerValue)
BEGIN
update #Milling set [message] = 'REQUIRED POWER IS AVAILABLE  '+ CHAR(13) + CHAR(10) + 'AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
END
else if(@powerrequired > @ContinousPowerValue)
BEGIN
update #Milling set [message] = 'POWER NOT AVAILABLE  ' + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
END
--SV Till Here

END

if(@torqueRequired < @T1)
BEGIN
update #Milling set [TorqueMessage] = [Message1] from #Focas_SpindleTrans_AMS
END
else if( @torqueRequired >= @T1 and @torqueRequired <= @T2)
BEGIN
update #Milling set [TorqueMessage] = [Message2] from #Focas_SpindleTrans_AMS
END
else if(@torqueRequired > @T2 and @torqueRequired <= ISNULL(@T3,0))
BEGIN
update #Milling set [TorqueMessage] = [Message3] from #Focas_SpindleTrans_AMS
END
else if(@torqueRequired > ISNULL(@T3,0) and @torquerequired <=@T4)
BEGIN
update #Milling set [TorqueMessage] = [Message4] from #Focas_SpindleTrans_AMS
END

update #milling set TorqueAvaiable =  Convert(NVARCHAR(250),@T1) +'/'+ Convert(NVARCHAR(250),@T2) +'/'+ Case when @T3 IS NOT NULL then Convert(NVARCHAR(250),@T3) + '/' ELSE '' END + replace(Convert(NVARCHAR(250),isnull(@T4,'')),'0','');



select @torqueAvailable =  TorqueAvaiable from #milling
IF (RIGHT(@torqueAvailable, 1) = '/')
set @torqueAvailable =   LEFT(@torqueAvailable, LEN(@torqueAvailable) - 1)

update #milling set TorqueAvaiable = @torqueAvailable

Update #milling set [message] = '[POWER]: ' + [message] from #milling --SV added
Update #milling set [TorqueMessage] = '[TORQUE]: ' + [TorqueMessage] from #milling --SV added

select round(SpindleSpeed,0) as SpindleSpeed, round(FeedPerMin,0) as FeedPerMin,round(FeedPerRevolution,2) as FeedPerRevolution ,
round(ChipCrossSection,2) as ChipCrossSection,round(MRR,0)as  MRR,round(PowerRequiredAtSpindle,1) as PowerRequiredAtSpindle,round(TorqueRequiredAtSpindle,0) as  TorqueRequiredAtSpindle,
round(CuttingForceAtSpindle,0) as CuttingForceAtSpindle, powerAvailable,	
TorqueAvaiable,'25' as  tangentialCuttingForce,[message],[TorqueMessage],color  from #Milling;
return;
END


if(@param='Drilling')
BEGIN

insert into  #DrillingTappingBoring(ToolRadius,SpindleSpeed,FeedPerMin,FeedPerRevolution,Area,MRR,PowerRequiredAtSpindle,ThrustAtSpindle,TorqueRequiredAtSpindle)
values (0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)

update #DrillingTappingBoring set  ToolRadius = isnull(@CutterDaimeter,0.0)/2,SpindleSpeed =(isnull(@CuttingSpeed,0.0)*1000)/(pi() * @CutterDaimeter)  ;
update #DrillingTappingBoring set FeedPerMin = @FeedPerTooth*@NoOfTooth*SpindleSpeed;
update #DrillingTappingBoring set FeedPerRevolution= FeedPerMin/SpindleSpeed  where FeedPerMin > 0 and SpindleSpeed > 0 ;
update #DrillingTappingBoring set Area = (3.142*@CutterDaimeter* @CutterDaimeter)/4;
update #DrillingTappingBoring set MRR = (Area * FeedPerMin)/1000;
update #DrillingTappingBoring set  PowerRequiredAtSpindle = MRR/@value where MRR>0;
update #DrillingTappingBoring set ThrustAtSpindle = 1.16*isnull(@KValue,0)*@CutterDaimeter*power((100 * FeedPerRevolution), 0.85);
update #DrillingTappingBoring set TorqueRequiredAtSpindle = (975*PowerRequiredAtSpindle*9.8)/(SpindleSpeed);

select @powerRequired = powerrequiredAtSpindle from #DrillingTappingBoring
select @SpindleSpeed =  spindleSpeed from #DrillingTappingBoring

if(@SpindleSpeed > @BaseSpeed)
BEGIN

update #DrillingTappingBoring set [message] = 'POWER IS AVAILABLE',color= 'Green';

---SV From Here
--update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@ShortTermPower)  +'/' + Convert(NVARCHAR(250),@ContiniousPower) ;

-- if(@powerRequired <= @ShortTermPower and @powerrequired >= @ContiniousPower)
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + 'AND ITS IN SHORT TERM POWER DUTY', color= 'Green'
--END
--else if (@powerRequired <= @ContiniousPower)
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE '  + CHAR(13) + CHAR(10) +'AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
--END
--else if(@powerRequired > @ShortTermPower)
--BEGIN
--update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ' + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
--END

Update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@SP1)  + '/' + Convert(NVARCHAR(250),@SP2) + '/' + Case when @SP3 IS NOT NULL then Convert(NVARCHAR(250),@SP3) + '/' ELSE '' END + Convert(NVARCHAR(250),@ContiniousPower) ; --SV

if(@powerrequired >= @ContiniousPower and @powerRequired <= @SP1)
BEGIN
update #DrillingTappingBoring set [message] = [ShortTermPowerMsg1], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if(@powerrequired >= @SP1 and @powerRequired <= @SP2)
BEGIN
update #DrillingTappingBoring set [message] = [ShortTermPowerMsg2], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if(@powerrequired >= @SP2 and @powerRequired <= ISNULL(@SP3,0)) and ISNULL(@SP3,0)>0
BEGIN
update #DrillingTappingBoring set [message] = [ShortTermPowerMsg3], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if (@powerRequired <= @ContiniousPower)
BEGIN
update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE '  + CHAR(13) + CHAR(10) +'AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
END
else if(@powerRequired > ISNULL(@SP3,0)) and ISNULL(@SP3,0)>0
BEGIN
update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ' + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
END
ELSE
BEGIN
update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE' ,color= 'red'
END

----SV Till Here

END

select @ContinousPowerValue = round(((0 - @ContiniousPower )/( 0- @basespeed ))*(@SpindleSpeed),2)
--select @ShortTermPowerValue = round(((0- @ShortTermPower)/(0- @basespeed)) * (@SpindleSpeed),2) --SV Commented

if(@SpindleSpeed < @BaseSpeed)
BEGIN

--update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@ShortTermPowerValue)  +'/' + Convert(NVARCHAR(250),@ContinousPowerValue) ; --SV Commented
update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@SP1)  + '/' + Convert(NVARCHAR(250),@SP2) + '/' + Case when @SP3 IS NOT NULL then Convert(NVARCHAR(250),@SP3) + '/' ELSE '' END + Convert(NVARCHAR(250),@ContiniousPower) ; --SV
update #DrillingTappingBoring set [message] = 'POWER IS AVAILABLE',color= 'Green';


---SV From Here
-- if( (@powerrequired >= @ContinousPowerValue ) and (@powerrequired <=@ShortTermPowerValue))
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE  ' + CHAR(13) + CHAR(10) + ' AND ITS IN SHORT TERM POWER DUTY', color= 'Green'
--END
--else if(@powerrequired <= @ContinousPowerValue)
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE  ' + CHAR(13) + CHAR(10) + ' AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
--END
--else if(@powerrequired > @ShortTermPowerValue)
--BEGIN
--update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE  ' + CHAR(13) + CHAR(10) + ' PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
--END

if(@powerrequired <= @ContinousPowerValue)
BEGIN
update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE  ' + CHAR(13) + CHAR(10) + ' AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
END
else if(@powerrequired > @ContinousPowerValue)
BEGIN
update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE  ' + CHAR(13) + CHAR(10) + ' PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
END
--SV Till Here
END

--SV from Here
Declare @ThrustAtSpindle  as float
Declare @ThrustAvailable as float 
Select @ThrustAtSpindle = Round((ThrustAtSpindle/10),0) from #DrillingTappingBoring
Select @ThrustAvailable='22'

if(@ThrustAtSpindle < @ThrustAvailable)
BEGIN
update #DrillingTappingBoring set [Thrustmessage] = 'THURST IS AVAILABLE', color= 'Green';
END
else if(@ThrustAtSpindle >= @ThrustAvailable)
BEGIN
update #DrillingTappingBoring set [Thrustmessage] = 'THURST IS NOT AVAILABLE',color= 'red'
END
--SV Till Here

Update #DrillingTappingBoring set [message] = '[POWER]: ' + [message] from #DrillingTappingBoring --SV added
Update #DrillingTappingBoring set [Thrustmessage] = '[THURST]: ' + [Thrustmessage] from #DrillingTappingBoring --SV added

select round(ToolRadius,0) as ToolRadius,round(SpindleSpeed,0) as SpindleSpeed,round(FeedPerMin,0) as FeedPerMin,round(FeedPerRevolution,1) as FeedPerRevolution,
round(MRR,0) as MRR,round(PowerRequiredAtSpindle,1) as PowerRequiredAtSpindle, 
round(ThrustAtSpindle,0) as ThrustAtSpindle,round(TorqueRequiredAtSpindle,0) as TorqueRequiredAtSpindle, powerAvailable,
--'16' as thrustAvailable,[message],color  --SV Commented
'22' as thrustAvailable,[message],color,[Thrustmessage]  --SV changed value and added [Thrustmessage]
from #DrillingTappingBoring;

END

if(@param = 'TAPPING')
BEGIN

insert into  #DrillingTappingBoring(ToolRadius,SpindleSpeed,FeedPerMin,FeedPerRevolution,Area,MRR,PowerRequiredAtSpindle,ThrustAtSpindle,TorqueRequiredAtSpindle,ChipCrossSection)
values (0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)

update #DrillingTappingBoring set  ToolRadius = isnull(@CutterDaimeter,0.0)/2,SpindleSpeed =(isnull(@CuttingSpeed,0.0)*1000)/(pi() * @CutterDaimeter)  ;
update #DrillingTappingBoring set FeedPerMin = @pitch*SpindleSpeed;
update #DrillingTappingBoring set FeedPerRevolution= FeedPerMin/SpindleSpeed  where FeedPerMin > 0 and SpindleSpeed > 0 ;
update #DrillingTappingBoring set ChipCrossSection = power(@pitch ,(0.5));
update #drillingTappingBoring set PowerRequiredAtSpindle = (0.431 * @CutterDaimeter * power(@pitch,2)*SpindleSpeed*@KValue)/power(10,4); 
update #DrillingTappingBoring set TorqueRequiredAtSpindle = (975*PowerRequiredAtSpindle * 9.8)/(SpindleSpeed)


select @powerRequired = powerrequiredAtSpindle from #DrillingTappingBoring
select @SpindleSpeed =  spindleSpeed from #DrillingTappingBoring
select @torqueRequired = TorqueRequiredAtSpindle from #DrillingTappingBoring

if(@SpindleSpeed > @BaseSpeed)
BEGIN

update #DrillingTappingBoring set [message] = 'POWER IS AVAILABLE',color= 'Green';

--SV from Here
--update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@ShortTermPower)  +'/' + Convert(NVARCHAR(250),@ContiniousPower) ;
-- if(@powerRequired <= @ShortTermPower and @powerrequired >= @ContiniousPower)
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE  ' + CHAR(13) + CHAR(10) + ' AND ITS IN SHORT TERM POWER DUTY', color= 'Green'
--END
--else if (@powerRequired <= @ContiniousPower)
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + 'AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
--END
--else if(@powerRequired > @ShortTermPower)
--BEGIN
--update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ' + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
--END

update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@SP1)  + '/' + Convert(NVARCHAR(250),@SP2) + '/' + Case when @SP3 IS NOT NULL then Convert(NVARCHAR(250),@SP3) + '/' ELSE '' END + Convert(NVARCHAR(250),@ContiniousPower) ; --SV
if(@powerrequired >= @ContiniousPower and @powerRequired <= @SP1)
BEGIN
update #DrillingTappingBoring set [message] = [ShortTermPowerMsg1], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if(@powerrequired >= @SP1 and @powerRequired <= @SP2)
BEGIN
update #DrillingTappingBoring set [message] = [ShortTermPowerMsg2], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if(@powerrequired >= @SP2 and @powerRequired <= ISNULL(@SP3,0)) and ISNULL(@SP3,0)>0
BEGIN
update #DrillingTappingBoring set [message] = [ShortTermPowerMsg3], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if (@powerRequired <= @ContiniousPower)
BEGIN
update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + 'AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
END
else if(@powerRequired > ISNULL(@SP3,0)) and ISNULL(@SP3,0)>0
BEGIN
update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ' + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
END
ELSE
BEGIN
update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ',color= 'red'
END

--SV Till Here
END

select @ContinousPowerValue = round(((0 - @ContiniousPower )/( 0- @basespeed ))*(@SpindleSpeed),2)
--select @ShortTermPowerValue = round(((0- @ShortTermPower)/(0- @basespeed)) * (@SpindleSpeed),2) --SV Commented

if(@SpindleSpeed < @BaseSpeed)
BEGIN


--update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@ShortTermPowerValue)  +'/' + Convert(NVARCHAR(250),@ContinousPowerValue) ; --SV Commented
update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@SP1) + '/' + Convert(NVARCHAR(250),@SP2) + '/' + Convert(NVARCHAR(250),@SP3) + '/' + Convert(NVARCHAR(250),@ContiniousPower) ;
update #DrillingTappingBoring set [message] = 'POWER IS AVAILABLE',color= 'Green';

--SV From Here
-- if( (@powerrequired >= @ContinousPowerValue ) and (@powerrequired <=@ShortTermPowerValue))
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + 'AND ITS IN SHORT TERM POWER DUTY', color= 'Green'
--END
--else if(@powerrequired <= @ContinousPowerValue)
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + 'AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
--END
--else if(@powerrequired > @ShortTermPowerValue)
--BEGIN
--update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ' + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
--END

if(@powerrequired <= @ContinousPowerValue)
BEGIN
update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + 'AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
END
else if(@powerrequired > @ContinousPowerValue)
BEGIN
update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ' + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red';
END
--SV Till here
END

if(@torqueRequired < @T1)
BEGIN
update #DrillingTappingBoring set [TorqueMessage] = [Message1] from #Focas_SpindleTrans_AMS
END
else if( @torqueRequired >= @T1 and @torqueRequired <= @T2)
BEGIN
update #DrillingTappingBoring set [TorqueMessage] = [Message2] from #Focas_SpindleTrans_AMS
END
else if(@torqueRequired > @T2 and @torqueRequired <= ISNULL(@T3,0))
BEGIN
update #DrillingTappingBoring set [TorqueMessage] = [Message3] from #Focas_SpindleTrans_AMS
END
else if(@torqueRequired > ISNULL(@T3,0) and @torquerequired <=@T4)
BEGIN
update #DrillingTappingBoring set [TorqueMessage] = [Message4] from #Focas_SpindleTrans_AMS
END

update #DrillingTappingBoring set TorqueAvaiable =  Convert(NVARCHAR(250),@T1) +'/'+ Convert(NVARCHAR(250),@T2) +'/'+ Case when @T3 IS NOT NULL then Convert(NVARCHAR(250),@T3) + '/' ELSE '' END + replace(Convert(NVARCHAR(250),isnull(@T4,'')),'0','');


select @torqueAvailable =  TorqueAvaiable from #DrillingTappingBoring
IF (RIGHT(@torqueAvailable, 1) = '/')
set @torqueAvailable =   LEFT(@torqueAvailable, LEN(@torqueAvailable) - 1)

update #DrillingTappingBoring set TorqueAvaiable = @torqueAvailable

Update #DrillingTappingBoring set [message] = '[POWER]: ' + [message] from #DrillingTappingBoring --SV added
Update #DrillingTappingBoring set [TorqueMessage] = '[TORQUE]: ' + [TorqueMessage] from #DrillingTappingBoring --SV added

select round(ToolRadius,0) as ToolRadius,round(SpindleSpeed,0) as SpindleSpeed,round(FeedPerMin,0) as FeedPerMin,round(FeedPerRevolution,1) as FeedPerRevolution,
round(MRR,0) as MRR,round(PowerRequiredAtSpindle,1) as PowerRequiredAtSpindle, round(ThrustAtSpindle,0) as ThrustAtSpindle,
round(TorqueRequiredAtSpindle,0) as TorqueRequiredAtSpindle,round(ChipCrossSection,1)  as ChipCrossSection, powerAvailable,
 TorqueAvaiable,[message],[TorqueMessage],color 
from #DrillingTappingBoring;

END

if(@param ='BORING')
BEGIN

insert into  #DrillingTappingBoring(ToolRadius,SpindleSpeed,FeedPerMin,FeedPerRevolution,Area,MRR,PowerRequiredAtSpindle,ThrustAtSpindle,TorqueRequiredAtSpindle,ChipCrossSection)
values (0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)

update #DrillingTappingBoring set SpindleSpeed =(isnull(@CuttingSpeed,0.0)*1000)/(pi() * @CutterDaimeter)  ;
update #DrillingTappingBoring set FeedPerMin = @FeedPerTooth*@KValue*SpindleSpeed;
update #DrillingTappingBoring set FeedPerRevolution= FeedPerMin/SpindleSpeed  where FeedPerMin > 0 and SpindleSpeed > 0 ;
update #DrillingTappingBoring set radialAllowance = (isnull(@CutterDaimeter,0)-isnull(@InitalBoreDia,0))/2;
update #DrillingTappingBoring set ChipCrossSection = radialAllowance * @FeedPerTooth;
update #DrillingTappingBoring set Area = (3.142 * ( power (@CutterDaimeter ,2) - power(@InitalBoreDia,2)))/4; 
update #DrillingTappingBoring set MRR = (Area * FeedPerMin)/1000; 
update #DrillingTappingBoring set  PowerRequiredAtSpindle = MRR/@value where MRR>0;
update #DrillingTappingBoring set TorqueRequiredAtSpindle = (975*(PowerRequiredAtSpindle/SpindleSpeed))*(9.8);
update #DrillingTappingBoring set CuttingForceAtSpindle = (isnull(6120,0.0)* PowerRequiredAtSpindle)/@CuttingSpeed;

select @powerRequired = powerrequiredAtSpindle from #DrillingTappingBoring
select @SpindleSpeed =  spindleSpeed from #DrillingTappingBoring
select @torqueRequired = TorqueRequiredAtSpindle from #DrillingTappingBoring

if(@SpindleSpeed > @BaseSpeed)
BEGIN

update #DrillingTappingBoring set [message] = 'POWER IS AVAILABLE',color= 'Green';

--SV From Here
--update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@ShortTermPower)  +'/' + Convert(NVARCHAR(250),@ContiniousPower) ;
-- if(@powerRequired <= @ShortTermPower and @powerrequired >= @ContiniousPower)
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + ' AND ITS IN SHORT TERM POWER DUTY', color= 'Green'
--END
--else if (@powerRequired <= @ContiniousPower)
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + ' AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
--END
--else if(@powerRequired > @ShortTermPower)
--BEGIN
--update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ' + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
--END

update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@SP1)  + '/' + Convert(NVARCHAR(250),@SP2) + '/' + Case when @SP3 IS NOT NULL then Convert(NVARCHAR(250),@SP3) + '/' ELSE '' END + Convert(NVARCHAR(250),@ContiniousPower) ; --SV
if(@powerrequired >= @ContiniousPower and @powerRequired <= @SP1)
BEGIN
update #DrillingTappingBoring set [message] = [ShortTermPowerMsg1], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if(@powerrequired >= @SP1 and @powerRequired <= @SP2)
BEGIN
update #DrillingTappingBoring set [message] = [ShortTermPowerMsg2], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if(@powerrequired >= @SP2 and @powerRequired <= ISNULL(@SP3,0)) and ISNULL(@SP3,0)>0
BEGIN
update #DrillingTappingBoring set [message] = [ShortTermPowerMsg3], color= 'Green' from #Focas_SpindleTrans_AMS
END
else if (@powerRequired <= @ContiniousPower)
BEGIN
update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + ' AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
END
else if(@powerRequired > ISNULL(@SP3,0)) and ISNULL(@SP3,0)>0
BEGIN
update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ' + CHAR(13) + CHAR(10) + 'PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
end
else
begin
update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ',color= 'red'
END
--SV Till Here

END

select @ContinousPowerValue = round(((0 - @ContiniousPower )/( 0- @basespeed ))*(@SpindleSpeed),2)
--select @ShortTermPowerValue = round(((0- @ShortTermPower)/(0- @basespeed)) * (@SpindleSpeed),2) --SV Commented

if(@SpindleSpeed < @BaseSpeed)
BEGIN

-- update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@ShortTermPowerValue)  +'/' + Convert(NVARCHAR(250),@ContinousPowerValue) ; --SV Commented
update #DrillingTappingBoring set powerAvailable = Convert(NVARCHAR(250),@SP1) + '/' + Convert(NVARCHAR(250),@SP2) + '/' + Convert(NVARCHAR(250),@SP3) + '/' + Convert(NVARCHAR(250),@ContiniousPower) ;
update #DrillingTappingBoring set [message] = 'POWER IS AVAILABLE',color= 'Green';

---SV From Here
-- if( (@powerrequired >= @ContinousPowerValue ) and (@powerrequired <=@ShortTermPowerValue))
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + 'AND ITS IN SHORT TERM POWER DUTY', color= 'Green'
--END
--else if(@powerrequired <= @ContinousPowerValue)
--BEGIN
--update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + ' AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
--END
--else if(@powerrequired > @ShortTermPowerValue)
--BEGIN
--update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ' + CHAR(13) + CHAR(10) + ' PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
--END

If(@powerrequired <= @ContinousPowerValue)
BEGIN
update #DrillingTappingBoring set [message] = 'REQUIRED POWER IS AVAILABLE ' + CHAR(13) + CHAR(10) + ' AND ITS IN CONTINOUS TERM POWER DUTY', color= 'Green';
END
else if(@powerrequired > @ContinousPowerValue)
BEGIN
update #DrillingTappingBoring set [message] = 'POWER NOT AVAILABLE ' + CHAR(13) + CHAR(10) + ' PLEASE CHANGE REQUIRED PARAMETER',color= 'red'
END
---SV Till Here

END


if(@torqueRequired < @T1)
BEGIN
update #DrillingTappingBoring set [TorqueMessage] = [Message1] from #Focas_SpindleTrans_AMS
END
else if( @torqueRequired >= @T1 and @torqueRequired <= @T2)
BEGIN
update #DrillingTappingBoring set [TorqueMessage] = [Message2] from #Focas_SpindleTrans_AMS
END
else if(@torqueRequired > @T2 and @torqueRequired <= ISNULL(@T3,0))
BEGIN
update #DrillingTappingBoring set [TorqueMessage] = [Message3] from #Focas_SpindleTrans_AMS
END
else if(@torqueRequired > ISNULL(@T3,0) and @torquerequired <=@T4)
BEGIN
update #DrillingTappingBoring set [TorqueMessage] = [Message4] from #Focas_SpindleTrans_AMS
END


update #DrillingTappingBoring set TorqueAvaiable =  Convert(NVARCHAR(250),@T1) +'/'+ Convert(NVARCHAR(250),@T2) +'/'+  Case when @T3 IS NOT NULL then Convert(NVARCHAR(250),@T3) + '/' ELSE '' END + replace(Convert(NVARCHAR(250),isnull(@T4,'')),'0','');

select @torqueAvailable =  TorqueAvaiable from #DrillingTappingBoring
IF (RIGHT(@torqueAvailable, 1) = '/')
set @torqueAvailable =   LEFT(@torqueAvailable, LEN(@torqueAvailable) - 1)

update #DrillingTappingBoring set TorqueAvaiable = @torqueAvailable

Update #DrillingTappingBoring set [message] = '[POWER]: ' + [message] from #DrillingTappingBoring --SV added
Update #DrillingTappingBoring set [TorqueMessage] = '[TORQUE]: ' + [TorqueMessage] from #DrillingTappingBoring --SV added

select round(SpindleSpeed,0) as SpindleSpeed,round(FeedPerMin,0) as FeedPerMin,round(FeedPerRevolution,2) as FeedPerRevolution,Area,round(MRR,0) as MRR,
round(PowerRequiredAtSpindle,1) as PowerRequiredAtSpindle,round(TorqueRequiredAtSpindle,0) as TorqueRequiredAtSpindle,ChipCrossSection,
round(CuttingForceAtSpindle,0) as CuttingForceAtSpindle,powerAvailable,
TorqueAvaiable,[message],[TorqueMessage],color 
from #DrillingTappingBoring;

END

END
