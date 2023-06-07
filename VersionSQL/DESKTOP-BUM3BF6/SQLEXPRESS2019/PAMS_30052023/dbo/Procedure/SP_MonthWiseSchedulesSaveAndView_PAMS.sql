/****** Object:  Procedure [dbo].[SP_MonthWiseSchedulesSaveAndView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MonthWiseSchedulesSaveAndView_PAMS 'TVSM, HOSUR','K6081570','','','','','View'
*/
CREATE procedure [dbo].[SP_MonthWiseSchedulesSaveAndView_PAMS]
@CustomerID nvarchar(50)='',
@PartID NVARCHAR(50)='',
@Year nvarchar(4)='',
@MonthName nvarchar(50)='',
@MonthValue nvarchar(1000)=0,
@PlannedQty float=0,
@Param nvarchar(50)='',
@UpdatedBy nvarchar(50)=''
as
begin
declare @strsql nvarchar(max)
declare @strYear nvarchar(1000)
declare @strMonth nvarchar(4000)
declare @strCustomer nvarchar(2000)
declare @strPartID nvarchar(2000)

SELECT @strsql=''
SELECT @strYear=''
SELECT @strMonth=''
SELECT @strCustomer=''
SELECT @strPartID=''

if isnull(@strYear,'')<>''
begin
	select @strYear='And MonthlyScheduleDetails_Pams.Year =	N'+@Year+''
END

IF ISNULL(@MonthValue,'')<>''
begin
	select @strMonth='And MonthlyScheduleDetails_Pams.MonthVal in('+@MonthValue+')'
end

if isnull(@CustomerID,'')<>''
begin
	select @strCustomer='And MonthlyScheduleDetails_Pams.CustomerID LIKE ''%'+@CustomerID+'%'' '
END

if isnull(@PartID,'')<>''
begin
	select @strPartID='And MonthlyScheduleDetails_Pams.PartID LIKE ''%'+@PartID+'%'' '
END


if @Param='View'
begin
	select @strsql=''
	select @strsql=@strsql+'select MonthlyScheduleDetails_Pams.CustomerID ,MonthlyScheduleDetails_Pams.PartID,c1.PartDescription as PartName,MonthlyScheduleDetails_Pams.YearNo,
	MonthlyScheduleDetails_Pams.MonthName ,MonthlyScheduleDetails_Pams.MonthVal ,MonthlyScheduleDetails_Pams.PlannedQty,MonthlyScheduleDetails_Pams.UpdatedBy ,MonthlyScheduleDetails_Pams.UpdatedTS,isnull(c2.bit,''0'') as GenerationBit from MonthlyScheduleDetails_Pams '
	select @strsql=@strsql+'LEFT JOIN FGDetails_PAMS c1 on c1.partid=MonthlyScheduleDetails_Pams.PartID
	left join (select distinct partid,Year,MonthValue,''1'' as bit from DayWiseScheduleDetails_PAMS ) c2 on MonthlyScheduleDetails_Pams.partid=c2.partid
	and MonthlyScheduleDetails_Pams.YearNo=c2.year and MonthlyScheduleDetails_Pams.MonthVal=c2.MonthValue
	where 1=1 '
	select @strsql=@strsql+@strYear+@strMonth+@strCustomer+@strPartID
	print(@strsql)
	exec(@strsql)
end

if @Param='Save'
begin
	if not exists(select * from MonthlyScheduleDetails_Pams where CustomerID=@CustomerID AND PartID=@PartID AND YearNo=@Year AND MonthVal=@MonthValue)
	BEGIN
		Insert into MonthlyScheduleDetails_Pams(CustomerID ,PartID ,YearNo ,MonthName ,MonthVal ,PlannedQty,UpdatedBy ,UpdatedTS)
		values(@CustomerID,@PartID,@Year,@MonthName,@MonthValue,@PlannedQty,@UpdatedBy,getdate())
	end
	else
	begin
		update MonthlyScheduleDetails_Pams set PlannedQty=@PlannedQty,UpdatedBy=@UpdatedBy,updatedTS=GETDATE()
		WHERE CustomerID=@CustomerID AND PartID=@PartID AND YearNo=@Year AND MonthVal=@MonthValue
	END
end
	
end
