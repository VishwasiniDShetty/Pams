/****** Object:  Procedure [dbo].[s_GetPumpFlowMeterReport]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetPumpFlowMeterReport] '2015-11-19','Test Bench1','R 983 032 375','',''
--[dbo].[s_GetPumpFlowMeterReport] '2015-11-19','Test Bench1','','',''
--[dbo].[s_GetPumpFlowMeterReport] '2015-11-19','Test Bench1','R 983 032 375','second',''
--[dbo].[s_GetPumpFlowMeterReport] '2015-11-19','Test Bench1','','second',''

CREATE                 PROCEDURE [dbo].[s_GetPumpFlowMeterReport]
	@StartTime datetime,
	@MachineID nvarchar(50) = '',
	@PumpModel nvarchar(50)='',
	@shift nvarchar(20)='',
	@Param nvarchar(20)= ''
AS
BEGIN

Declare @strSql as nvarchar(4000)
Declare @strPumpModel as nvarchar(255)
Declare @strMachineid as nvarchar(255)

select @strSql=''
select @strPumpModel=''
Select @strMachineid=''


CREATE TABLE #ShiftDefn
(
	ShiftDate DateTime,		
	Shiftname nvarchar(20),
	ShftSTtime DateTime,
	ShftEndTime DateTime	
)

if isnull(@MachineID,'')<> ''
begin
	SET @strMachineid = ' AND FCM.MachineID = N''' + @MachineID + ''''
end

if isnull(@PumpModel,'')<> ''
Begin
	SET @strPumpModel = ' AND FCP.Model = N''' + @PumpModel + ''''
End

INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
Exec s_GetShiftTime @starttime,@shift

Create table #FlowDetails
(
Slno bigint identity(1,1),
Shiftname nvarchar(50),
Model nvarchar(50),
PumpSeries nvarchar(50),
MinFlow float,
Starttime datetime,
Endtime datetime,
Remarks nvarchar(50)
)

Select @strsql = @Strsql + 'Insert into #FlowDetails(Shiftname,Model,PumpSeries,MinFlow,Starttime,Endtime,Remarks)
Select distinct S.Shiftname,FCP.Model,FCA.PumpSeries,FCA.MinFlow,FCA.Starttime,FCA.Endtime,Case when FCA.MinFlow<FCP.Specifiedflow then ''NOT OK'' else ''OK''  end as 
Remarks from FlowCtrlAutodata FCA inner join FlowCtrl_MachineInfo FCM on FCA.Machineinterface=FCM.Interfaceid 
inner join FlowCtrl_PumpInfo FCP on FCA.PumpModel=FCP.Interfaceid 
Cross join #ShiftDefn S
where FCA.Starttime>=S.ShftSTtime and FCA.endtime<ShftEndTime '
Select @Strsql = @Strsql + @strMachineid + @strPumpModel
Select @Strsql = @Strsql + ' Order by S.Shiftname,FCP.Model,FCA.Starttime'
print @strsql
Exec (@strsql)


Select Slno,Shiftname,Model,PumpSeries,MinFlow,Starttime,Endtime,Remarks from #FlowDetails Order by Shiftname,Model,Starttime

End
