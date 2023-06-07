/****** Object:  Procedure [dbo].[S_GetSPCDetails_Renishaw]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[S_GetSPCDetails_Renishaw]
	@Startdate datetime,
	@Enddate datetime,
	@machine nvarchar(50)='',
	@Dimension nvarchar(50) = '',
	@Component nvarchar(50) = '',
	@Operation nvarchar(50) = '',
	@Param nvarchar(50)	 = ''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

CREATE TABLE #SPC
(
id int identity(1,1) not null,
Machine nvarchar(50),
Equator nvarchar(50),
Component nvarchar(50),
Operation nvarchar(50),
Operator nvarchar(50),
Dimension nvarchar(50),
BatchTs datetime,
LSL float,
USL float,
Mean float,
ActualValue float,
MeasuredValue float,
LotNumber nvarchar(50),
SerialNumber nvarchar(50),
Deviation float
)

INSERT INTO #SPC (Machine,Equator,Component,Dimension,Operation,Operator,LotNumber,SerialNumber,BatchTs,LSL,USL,Mean,ActualValue,Deviation)
select  A.mc, R.equator ,A.Comp, A.Dimension, A.Opn, A.opr, A.LotNumber,A.SerialNumber,A.BatchTS, S.LSL,S.USL,S.SpecificationMean,cast(A.Value as float),
case when A.Value<S.SpecificationMean then (S.SpecificationMean-A.Value) else 0 end from SPCAutodata A
inner join SPC_Characteristic S on  A.mc=S.MachineID and A.Comp=S.ComponentID and A.Opn=S.OperationNo and A.Dimension=S.CharacteristicCode
Left outer join Renishaw_EquatorMaster R on A.Mc=R.Machineid
where (A.mc=@machine or isnull(@machine,'')='') and (A.Dimension =@Dimension or isnull(@Dimension,'')='') and 
(A.Comp = @Component or isnull(@Component,'')='') and (A.Opn = @Operation or isnull(@operation,'')='')
and A.BatchTS>=@Startdate and A.BatchTS<=@Enddate
order by A.BatchTS

Select * from #SPC order by BatchTs

END
