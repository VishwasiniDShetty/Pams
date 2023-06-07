/****** Object:  Procedure [dbo].[s_GetMonthlyOverAllEfficiency]    Committed by VersionSQL https://www.versionsql.com ******/

/*
 Procedure Created By SSK On 14-July-2006
 To Get OEE Monthwise
*/


CREATE       PROCEDURE [dbo].[s_GetMonthlyOverAllEfficiency]
	@StartTime DateTime,
	@EndTime DateTime,
	@MachineID  nvarchar(50) = '',
	@ComponentID  nvarchar(50) = '',
	@OperatorID  nvarchar(50) = '',
	@MachineIDLabel nvarchar(50) ='ALL',
	@ComponentIDLabel nvarchar(50) = 'ALL',
	@OperatorIDLabel nvarchar(50) = 'ALL'
AS
BEGIN


DECLARE @strsql nvarchar(4000)
DECLARE @strmachine nvarchar(255)
DECLARE @stroperator nvarchar(255)
DECLARE @strcomponent nvarchar(255)

select @strsql = ''
select @strmachine = ''
select @strcomponent = ''
select @stroperator = ''

if isnull(@machineid,'') <> ''
	BEGIN
	SELECT @strmachine = ' AND ( workorderheader.machineid = ''' + @MachineID+ ''')'
	END
if isnull(@componentid, '') <> ''
	BEGIN
	SELECT @strcomponent = ' AND ( workorderheader.componentid = ''' + @ComponentID+ ''')'
	END
if isnull(@operatorid, '') <> ''
	BEGIN
	SELECT @stroperator = ' AND ( workorderproductiondetail.employeeid = ''' + @OperatorID + ''')'
	END

	Create Table #AEff
	(
	Dyear int,
	Dmonth int,
	ProdTime float,
	DownTime float,
        ML float,
	AvailEffy decimal(6,2),
	PlotMonth NvarChar(10),
	PlotDate DateTime,
	MLabel NvarChar(50),
	CLabel NVarChar(50),
	OLabel NVarChar(3)
	)

	Create Table #PEff
	(
	Dyear int,
	Dmonth int,
	ProdTime float,
	DownTime float,
	CN float,
	ProdEffy decimal(6,2),
	PlotMonth NvarChar(10),
	PlotDate DateTime,
	MLabel NvarChar(50),
	CLabel NVarChar(50),
	OLabel NVarChar(3)
	)

	Create Table #QEff
	(
	PlotDate DateTime,
	--MachineID nvarchar(50),
	Production float,
	Rejection float,
	QEff float
	)
	

	INSERT INTO #AEff(Dyear ,Dmonth ,ProdTime ,DownTime ,ML ,AvailEffy ,PlotMonth ,PlotDate ,MLabel ,CLabel ,OLabel )
	EXEC s_GetMonthlyAvailEfficiency @StartTime,@EndTime,@MachineID,@ComponentID,@OperatorID,@MachineIDLabel,@ComponentIDLabel,@OperatorIDLabel

	INSERT INTO #PEff(Dyear ,Dmonth ,ProdTime ,DownTime ,CN ,ProdEffy ,PlotMonth ,PlotDate ,MLabel ,CLabel ,OLabel )
	EXEC s_GetMonthlyProdEfficiency @StartTime,@EndTime,@MachineID,@ComponentID,@OperatorID,@MachineIDLabel,@ComponentIDLabel,@OperatorIDLabel

	Declare @CurSMonth AS DateTime
	Declare @CurEMonth AS DateTime

	SELECT @CurSMonth=dbo.f_GetPhysicalMonth(@StartTime,'Start')
	SELECT @CurEMonth=dbo.f_GetPhysicalMonth(@StartTime,'End')

	While(@CurSMonth<@EndTime)
	BEGIN
		SELECT @strsql = 'INSERT INTO #QEff ( PlotDate, Production, Rejection  )'
		SELECT @strsql = @strsql + ' SELECT  ''' + Convert(nvarchar(20),@CurSMonth) + ''', SUM(workorderproductiondetail.production) , '
		SELECT @strsql = @strsql + ' ISNULL(SUM(workorderproductiondetail.rejection), 0)  '
		SELECT @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderproductiondetail ON workorderheader.workorderno = workorderproductiondetail.workorderno'
		SELECT @strsql = @strsql + ' WHERE (('
		SELECT @strsql = @strsql + ' (workorderproductiondetail.timefrom>=''' + Convert(nvarchar(20),@CurSMonth) + ''')AND'
		SELECT @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + Convert(nvarchar(20),@CurEMonth) + ''')'
		SELECT @strsql = @strsql + '  ) OR ( '
		SELECT @strsql = @strsql + ' (workorderproductiondetail.timefrom<''' + COnvert(nvarchar(20),@CurSMonth) + ''')AND'
		SELECT @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + Convert(nvarchar(20),@CurEMonth) + ''') AND'
		SELECT @strsql = @strsql + ' (workorderproductiondetail.timeto>''' + Convert(nvarchar(20),@CurSMonth) + ''')))'
		SELECT @strsql = @strsql + @strmachine + @stroperator + @strcomponent
		SELECT @strsql = @strsql + ' GROUP BY Year(workorderProductiondetail.ProductionDate), Month(workorderProductiondetail.ProductionDate) '
		EXEC (@strsql)
		SELECT @CurSMonth= DateAdd(Month,1,@CurSMonth)
	END
	
	UPDATE #QEff SET QEff=((Production-Rejection)/Production)*100

	SELECT 
	#QEff.PlotDate,  
	(AvailEffy * ProdEffy * QEff )/10000 AS OEff ,
	@MachineIDLabel AS MachineIDLabel,
	@ComponentIDLabel AS ComponentIDLabel,
	@OperatorIDLabel AS OperatorIDLabel
	From #QEff 
	Inner Join #PEff ON #QEff.PlotDate=#PEff.PlotDate 
	Inner Join #AEff ON #QEff.PlotDate=#AEff.PlotDate
	 
	
END
