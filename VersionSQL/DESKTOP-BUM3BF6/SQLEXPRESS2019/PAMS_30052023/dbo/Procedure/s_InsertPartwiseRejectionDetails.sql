/****** Object:  Procedure [dbo].[s_InsertPartwiseRejectionDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_InsertPartwiseRejectionDetails] '2015-01-10','A','1','1','10A','8','2','Testing'
CREATE     PROCEDURE [dbo].[s_InsertPartwiseRejectionDetails]
@date datetime,
@shift nvarchar(50),
@Machine nvarchar(50),
@Operation nvarchar(50)='',
@Partnumber nvarchar(4000),
@TotalHours int='',
@Rejqty int='',
@Remarks nvarchar(4000)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;


	If Not Exists(Select * from Focas_PartwiseRejectionInfo where Machine=@Machine and date=@date and Shift=@shift and Partnumber=@Partnumber and Operation=@operation)
	Begin
		Insert into Focas_PartwiseRejectionInfo( Date, Shift, Machine, Operation, PartNumber, TotalHours, RejQty, Remarks)
		Select @Date, @Shift, @Machine, @Operation, @PartNumber, @TotalHours, @RejQty, @Remarks

	END

	If Exists(Select * from Focas_PartwiseRejectionInfo where Machine=@Machine and date=@date and Shift=@shift and Partnumber=@Partnumber and Operation=@operation)
	Begin
		update Focas_PartwiseRejectionInfo set TotalHours=@TotalHours, RejQty=@RejQty, Remarks=@Remarks where Machine=@Machine and date=@date and Shift=@shift and Partnumber=@Partnumber and Operation=@operation
	END


END
