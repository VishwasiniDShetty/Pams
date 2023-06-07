/****** Object:  Procedure [dbo].[s_NammaVantageElectricalInfo]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_NammaVantageElectricalInfo]  'VANTAGE MSY 01','100','380','0.6','-6','95','6','Low alloyed steel','power'
--[dbo].[s_NammaVantageElectricalInfo]  'SMART MACHINE','100','1000','0.4','-6','95','3','Brass','power'
CREATE PROCEDURE [dbo].[s_NammaVantageElectricalInfo]   
      @machineId nvarchar(50) = '',
      @Diameter float=0,
      @SpindleSpeed float=0,
      @Feed float=0,
      @ToolRakeAngle float=0,
      @ToolApproachAngle float=0,
      @Depth float=0,
      @Material nvarchar(50)=0,
      @param nvarchar(50) =''
 
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
 
   IF @param='BasicData'   
Begin     
    select * from  MachineElectricalInfo where MachineID=@machineId 
End   
  If @param = 'DerivedData'
 
  Begin
  create table #Calculations   
 (   
  TorqueInShortTerm decimal(18,3),     
  PulleyRatio decimal(18,3),
  BaseSpeed1 decimal(18,3),
  BaseSpeed2 decimal(18,3) ,
  CuttingSpeed decimal(18,3)
 
)   
 
 
Insert into #calculations(TorqueInShortTerm,PulleyRatio,BaseSpeed1,BaseSpeed2)   
select ((powerrating*6000*10)/(2*PI()*[BaseSpeedForShortTerm])),([MotorPulleyDia in mm]/[SpindlePulleyDia in mm]),(([MotorPulleyDia in mm]/[SpindlePulleyDia in mm])*BaseSpeed1),(([MotorPulleyDia in mm]/[SpindlePulleyDia in mm])*BaseSpeed2) from machineelectricalinfo  
where MachineID=@MachineID
 
update #Calculations set CuttingSpeed = ((PI()*@Diameter*@SpindleSpeed)/1000)
 
select * from #Calculations
End
 
If @param = 'Power'
 
Begin
 
create table #Poweers
(
SpecificCuttingForce  decimal(18,3),
PowerRequired decimal(18,3),
ChipThickness  decimal(18,3),
ContinousPowerRating decimal(18,3),
ShortTermPowerRating decimal(18,3),
SpecificCuttingForceForRemoving decimal(18,3),
CurveRaise decimal(18,2)
)
 
declare @ChipThickness as decimal(18,3)
select  @ChipThickness = (sin((3.1416*@ToolApproachAngle)/180.))*(@feed)
declare @CuttingSpeed as Float
select  @CuttingSpeed = ((3.1416*@Diameter*@SpindleSpeed)/1000)
declare @ToolRake as  decimal(18,3)
select  @ToolRake=(1-((@ToolRakeAngle)/100))
declare @torque as decimal(18,3)
select  @torque= torque from MachineElectricalInfo where MachineID=@MachineID
declare @continousRating as decimal(18,3)
select  @continousRating= continuousRating from MachineElectricalInfo where MachineID=@MachineID
declare @powerrating as decimal(18,3)
select  @powerrating= PowerRating from MachineElectricalInfo where MachineID=@MachineID
declare @BaseSpeed1 as decimal(18,3)
select  @BaseSpeed1 = (([MotorPulleyDia in mm]/[SpindlePulleyDia in mm])*BaseSpeed1) from machineelectricalinfo where MachineID=@MachineID
declare @BaseSpeed2 as decimal(18,3)
select  @BaseSpeed2 = (([MotorPulleyDia in mm]/[SpindlePulleyDia in mm])*BaseSpeed2) from machineelectricalinfo where MachineID=@MachineID
declare @PulleyRatio as decimal(18,3)
select  @pulleyRatio = ([MotorPulleyDia in mm]/[SpindlePulleyDia in mm]) from MachineElectricalInfo where MachineID=@MachineID
declare @BaseSpeedForShortTerm as decimal(18,3)
select  @BaseSpeedForShortTerm = BaseSpeedForShortTerm from MachineElectricalInfo where MachineID=@MachineID
declare @TorqueInShortTerm as decimal(18,3)
select  @TorqueInShortTerm= ((powerrating*6000*10)/(2*PI()*[BaseSpeedForShortTerm])) from machineelectricalinfo where MachineID=@MachineID
--Insert into #Poweers(SpecificCuttingForce,PowerRequired)  
--select ((1/(power(@ChipThickness,[mc])))*[Kc1.1])*(round(@ToolRake,0)) as SpecificCuttingForce,(1.1*((@cuttingspeed*@depth*@feed*((1/(power(@ChipThickness,[mc])))*[Kc1.1])*(round(@ToolRake,0)))/60000)/1) as PowerRequired from PowerCalculatorConstant
--where @material=MaterialUsed
 
 Insert into #Poweers(SpecificCuttingForce,PowerRequired)  
select ((1/(power(@ChipThickness,[mc])))*[Kc1.1])*((@ToolRake)) as SpecificCuttingForce,(1.1*((@cuttingspeed*@depth*@feed*((1/(power(@ChipThickness,[mc])))*[Kc1.1])*((@ToolRake)))/60000)/1) as PowerRequired from PowerCalculatorConstant
where @material=MaterialUsed

declare @Pac as decimal(18,3) --Continuous
declare @Pas as decimal(18,3) --Short term
 
update #poweers set ChipThickness=@ChipThickness
update #Poweers set SpecificCuttingForceForRemoving =  [kc1.1] from PowerCalculatorConstant where @Material=MaterialUsed
update #Poweers set CurveRaise= mc from PowerCalculatorConstant where @Material=MaterialUsed
 
--Begin: Calculate Continuous Power required, Pac
if (@SpindleSpeed< @BaseSpeed1)
      begin
            set @Pac = (2*PI()*@SpindleSpeed*@torque)/(60000*@pulleyRatio)
      end
else if (@SpindleSpeed>@BaseSpeed2)
      begin
            set @Pac = 0.001*(7000-@SpindleSpeed/@pulleyRatio)+7.5
      end
else
      begin
            set @Pac = @continousRating
      end
--End: Calculate Continuous Power required, Pac
 
--Begin: Calculate Short Term Power required, Pas
if (@SpindleSpeed < (@BaseSpeedForShortTerm*@PulleyRatio))
      begin
            set @Pas = (2*PI()* @SpindleSpeed*@TorqueInShortTerm)/(60000*@pulleyRatio)
      end
else if (@SpindleSpeed>@basespeed2)
      begin
            set @Pas = 0.0017*(7000-@SpindleSpeed/@pulleyRatio)+ 9
      end
else
      begin
            set @Pas = @powerRating
      end
--End: Calculate Short Term Power required, Pas
 
update #Poweers set ContinousPowerRating = @Pac, ShortTermPowerRating = @Pas
 
--update #Poweers set ContinousPowerRating = IIF(@SpindleSpeed< @BaseSpeed1,(2*PI()*@Spindlespeed*@torque)/(60000*@pulleyRatio),IIF(@spindlespeed>@BaseSpeed2,0.001*(7000-@spindlespeed/@pulleyRatio)+7.5,@continousRating))
--update #Poweers set ShortTermPowerRating = IIF(@SpindleSpeed<(@BaseSpeedForShortTerm*@PulleyRatio),(2*PI()*@spindlespeed*@TorqueInShortTerm)/(60000*@pulleyRatio),IIF(@spindlespeed>@basespeed2,0.0017*(7000-@spindlespeed/@pulleyRatio)+9,@powerrating))
select * from #poweers
End
END
