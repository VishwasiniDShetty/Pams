/****** Object:  Procedure [dbo].[s_GetBFLInspectionData]    Committed by VersionSQL https://www.versionsql.com ******/

--NR0120 - SwathiKS - 03/Nov/2015 :: To Show Inspectiondetails from InspectionAutodata for the given M-C-O and Time Period.
 --[dbo].[s_GetBFLInspectionData] '2015-11-02','2015-11-03','Metal','','','GetCOList'
 --[dbo].[s_GetBFLInspectionData] '2015-11-03','2015-11-04','Metal','8301','1','GridandReport'
 --[dbo].[s_GetBFLInspectionData] '','','Metal','8301','1','HeaderDetails'
CREATE    PROCEDURE [dbo].[s_GetBFLInspectionData]
@Start datetime,
@end datetime,
@Machineid nvarchar(50),
@Componentid nvarchar(50)='',
@Operationno nvarchar(50)='',
@Param nvarchar(50) =''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

declare @Starttime as datetime
declare @endtime as datetime

select @Starttime  = dbo.f_GetLogicalDay(@Start,'start')
select @endtime = dbo.f_GetLogicalDay(@end,'end')


If @param='GetCOList'
BEGIN
	Select Distinct CO.Componentid,CO.Operationno from InspectionAutodata A
	inner join machineinformation M on M.interfaceid=A.mc
	inner join Componentinformation CI on CI.interfaceid=A.comp
	inner join Componentoperationpricing CO on CO.interfaceid=A.opn and 
	CO.machineid=M.machineid and CO.componentid=CI.Componentid
	inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.componentid=SP.Componentid
	and CO.operationno=SP.operationno and A.Parameterid=SP.CharacteristicID
	where (A.[ActualTime]>=@starttime and A.[ActualTime]<=@Endtime)and M.machineid=@machineid 
	Order by CO.Componentid,CO.Operationno
END

If @param='HeaderDetails'
Begin

	select top 1 'Probe' as [Measuring Method],CI.Customerid,@Componentid as PartNo,CO.DrawingNo as DieNo,CI.Description as PartName,SP.InspectionDrawing
	from SPC_Characteristic SP
	inner join Componentinformation CI on CI.Componentid=SP.Componentid
	inner join Componentoperationpricing CO on CO.interfaceid=SP.Operationno and 
	CO.machineid=SP.machineid and CO.componentid=CI.Componentid 
	where SP.Machineid=@Machineid and SP.Componentid=@Componentid and SP.Operationno=@Operationno

End


If @param='GridandReport'
Begin

	Create table #InspecDetails
	(
		BatchID bigint,
		BatchTS datetime,
		CharacteristicCode nvarchar(50),
		Specification nvarchar(50),
		Mean nvarchar(50),
		LSL float,
		USL float,
		ActualValue decimal(18,4),
		Result nvarchar(50)
	)


	Insert into #InspecDetails(BatchID,BatchTS,CharacteristicCode,Specification,Mean,LSL,USL,ActualValue,Result)
	select A.Sampleid,A.Actualtime,SP.CharacteristicCode,SP.Specification,SP.SpecificationMean,SP.LSL,SP.USL,A.ActualValue,
	Case when A.ActualValue>=LSL and A.ActualValue<=USL then 'OK' else 'NOT OK' end from InspectionAutodata A
	inner join machineinformation M on M.interfaceid=A.mc
	inner join Componentinformation CI on CI.interfaceid=A.comp
	inner join Componentoperationpricing CO on CO.interfaceid=A.opn and 
	CO.machineid=M.machineid and CO.componentid=CI.Componentid
	inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.componentid=SP.Componentid
	and CO.operationno=SP.operationno and A.Parameterid=SP.CharacteristicID
	where (A.[ActualTime]>=@starttime and A.[ActualTime]<=@Endtime)and SP.machineid=@machineid 
	and SP.componentid=@componentid and SP.operationno=@operationno 
	Order by A.sampleid 

	Select BatchID,BatchTS,CharacteristicCode,Specification,Mean,LSL,USL,ActualValue,Result from #InspecDetails
END

END
