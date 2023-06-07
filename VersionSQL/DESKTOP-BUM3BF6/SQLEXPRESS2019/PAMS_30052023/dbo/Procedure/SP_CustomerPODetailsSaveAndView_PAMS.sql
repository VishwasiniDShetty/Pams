/****** Object:  Procedure [dbo].[SP_CustomerPODetailsSaveAndView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_CustomerPODetailsSaveAndView_PAMS @FromDate=N'2022-01-01',@ToDate=N'2022-09-01',@PONO=N'''p1''',@Customer=N'''c1''',@Param=N'View'
*/
CREATE procedure [dbo].[SP_CustomerPODetailsSaveAndView_PAMS]
@FromDate date='',
@ToDate date='',
@PONO NVARCHAR(50)='',
@Customer nvarchar(500)='',
@PoStatus nvarchar(50)='',
@POdate date='',
@PartID NVARCHAR(50)='',
@PartDescription nvarchar(500)='',
@Quantity float=0,
@uom nvarchar(50)='',
@UpdatedTS datetime='',
@UpdatedBy NVARCHAR(50)='',
@AutoID INT=0,
@Param nvarchar(50)=''
as
begin
declare @StrPONO NVARCHAR(2000)
declare @StrCustomer nvarchar(2000)
declare @StrPOStatus nvarchar(2000)
DECLARE @Strsql nvarchar(max)

select @Strsql=''
select @StrPONO=''
select @StrCustomer=''
select @StrPOStatus=''

if isnull(@PONO,'')<>''
begin
	select @StrPONO='And PONO IN ('+@PONO+')'
END

if isnull(@Customer,'')<>''
begin
	select @StrCustomer='And Customer IN ('+@Customer+')'
END

if isnull(@PoStatus,'')<>''
begin
	select @StrPOStatus='And POSTATUS IN ('+@PoStatus+')'
END



if @Param='Save'
begin
	if not exists(select * from CustomerPODetailsTransaction_PAMS where pono=@PONO and PartID=@PartID)
	begin
		insert into CustomerPODetailsTransaction_PAMS(PODate,PONo,PartID,PartDescription,Customer,POStatus,Quantity,UOM,UpdatedBy,UpdatedTS)
		values(@POdate,@PONO,@PartID,@PartDescription,@Customer,@PoStatus,@Quantity,@uom,@UpdatedBy,@UpdatedTS)
	end
	else
	begin
		update CustomerPODetailsTransaction_PAMS set PartDescription=@PartDescription,PODate=@POdate,Customer=@Customer,POStatus=@PoStatus,Quantity=@Quantity,
		UOM=@uom,UpdatedBy=@UpdatedBy,UpdatedTS=@UpdatedTS WHERE pono=@PONO and PartID=@PartID
	END
END

IF @Param='View'
begin
	select @strsql='select distinct AUTOID,PODate,PONo,PartID,PartDescription,Customer,POStatus,Quantity,UOM,UpdatedBy,UpdatedTS from CustomerPODetailsTransaction_PAMS
	WHERE (PODATE>='''+CONVERT(NVARCHAR(20),@FromDate,120)+''' AND PODATE<='''+CONVERT(NVARCHAR(20),@ToDate,120)+''') '
	select @Strsql=@Strsql+@StrPONO+@StrCustomer+@StrPOStatus
	print(@strsql)
	exec(@strsql)
end

IF @Param='Delete'
begin
	delete from CustomerPODetailsTransaction_PAMS where AutoID=@AutoID
end


end
