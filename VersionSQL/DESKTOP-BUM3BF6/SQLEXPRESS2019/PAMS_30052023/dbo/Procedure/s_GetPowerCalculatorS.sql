/****** Object:  Procedure [dbo].[s_GetPowerCalculatorS]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from [dbo].[PowerCalculatorConstant]
--select * from powerCalculatorS
 --[dbo].[s_GetPowerCalculatorS] 'Jobber','0.3','0.5','50','100','2500',''
CREATE PROCEDURE [dbo].[s_GetPowerCalculatorS]
	@Model nvarchar(50)='',
	@Feed float,							--f
	@DepthOfCut float,						--ap
	@Diameter float,						--D
	@CuttingSpeed float,					--Vc
	@SpecificCuttingForce float ,			--kc
	@param nvarchar(50)=''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Create table #Calculator
(
	TangentialCuttingForce float default 0,
	NRPM float,
	Torque float,
	PowerRequired float,
	ContAvailRatedPower float,  --Pac
	[StMinRatedPower] float,    --Pas
	ContAvailRatedTorque float,
	[StMinRatedTorque] float,
	[BaseSpeedOnMotor] [float] NOT NULL,
	[BaseSpeedOnSpindle]  [float] NOT NULL,
	[ContPower] [float] NOT NULL,
	[StMinPower] [float] NOT NULL,
	[ContTorque] [float] NOT NULL,
	[StMinTorque] [float] NOT NULL,
	[StMin] [float]  NULL,
)

CREATE TABLE #PowerCalculatorS
(
	[Model] [nvarchar](50) NOT NULL,
	[MaxSpeedOnMotor] [float] NOT NULL,
	[MaxSpeedOnspindle] [float] NOT NULL,
	[BaseSpeedOnMotor] [float] NOT NULL,
	[BaseSpeedOnSpindle]  [float] NOT NULL,
	[ContPower] [float] NOT NULL,
	[StMinPower] [float] NOT NULL,
	[ContTorque] [float] NOT NULL,
	[StMinTorque] [float] NOT NULL,
	[StMin] [float]  NULL,

) 
insert into #PowerCalculatorS([Model],[MaxSpeedOnMotor],[MaxSpeedOnspindle],[BaseSpeedOnMotor],
[BaseSpeedOnSpindle],[ContPower],[StMinPower],[ContTorque],[StMinTorque],[StMin])
select [Model],[MaxSpeedOnMotor],[MaxSpeedOnspindle],[BaseSpeedOnMotor],
[BaseSpeedOnSpindle],[ContPower],[StMinPower],[ContTorque],[StMinTorque],[StMin] from PowerCalculatorS
where [Model]=@model

declare @TangentialCuttingForce as float;
declare @NRPM as float;
declare @Torque as float;
declare @PowerRequired as float;
declare @BaseSpeedOnSpindle as float;

select  @TangentialCuttingForce = @SpecificCuttingForce*@Feed*@DepthOfCut;
select @NRPM = (@CuttingSpeed*1000)/(PI() * @Diameter );
Select @Torque = (@TangentialCuttingForce*(@Diameter/2))/(1000);
--Select @PowerRequired = (2*PI()*@NRPM*@Torque)/(60000*0.9);

select @PowerRequired =((@CuttingSpeed*@DepthOfCut*@Feed*@SpecificCuttingForce)/(60000*0.8))*power((0.4/@Feed),0.24);
select @BaseSpeedOnSpindle = [BaseSpeedOnSpindle] from #powerCalculatorS ;

insert into #Calculator (TangentialCuttingForce,NRPM,Torque,PowerRequired,ContAvailRatedPower,[BaseSpeedOnMotor],
[BaseSpeedOnSpindle],[ContPower],[StMinPower],[ContTorque],[StMinTorque],[StMin])
select @TangentialCuttingForce,@NRPM,@Torque,@PowerRequired,0,[BaseSpeedOnMotor],
[BaseSpeedOnSpindle],[ContPower],[StMinPower],[ContTorque],[StMinTorque],[StMin] from #PowerCalculatorS

if(@NRPM < @BaseSpeedOnSpindle)
	BEGIN
		update #Calculator set ContAvailRatedPower = (@NRPM/@BaseSpeedOnSpindle)*S.[ContPower],[StMinRatedPower] = (@NRPM/@BaseSpeedOnSpindle)*S.[StMinPower] 
		,ContAvailRatedTorque=(S.[ContTorque]*(S.[MaxSpeedOnMotor]/S.[MaxSpeedOnspindle])),[StMinRatedTorque]=(S.[StMinTorque]*(S.[MaxSpeedOnMotor]/S.[MaxSpeedOnspindle]))
		from #PowerCalculatorS S;
	END
Else
	BEGIN
		update #Calculator set ContAvailRatedPower = S.[ContPower],[StMinRatedPower] = S.[StMinPower] ,
		ContAvailRatedTorque = ((60000 * S.[ContPower])/(2*PI()*@NRPM )),[StMinRatedTorque] = ((60000 * S.[StMinPower])/(2*PI()*@NRPM )) from #PowerCalculatorS S;
	END

select @model  as Model,TangentialCuttingForce as [Tf],round(NRPM,2) as N,round(Torque,2) as Torque ,round([PowerRequired],2) as [Pr],round(ContAvailRatedPower,2) as [Pac] , round([StMinRatedPower],2) as [Pas],
round(ContAvailRatedTorque,2) as [Tac],round([StMinRatedTorque],2) as [Tas],round([BaseSpeedOnMotor],2) as [BaseSpeedOnMotor],
round([BaseSpeedOnSpindle],2) as [BaseSpeedOnSpindle],round([ContPower],2) as [ContPower] ,round([StMinPower],2) as [StMinPower],round([ContTorque],2) as [ContTorque] ,round([StMinTorque],2) as [StMinTorque],[StMin] 
from #Calculator;

END
