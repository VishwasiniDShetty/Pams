/****** Object:  Procedure [dbo].[s_InsertInspectionDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_InsertInspectionDetails] 'Trellebrog','WE5100400','1','1','5','12345','2.56','200','insert'
CREATE    PROCEDURE [dbo].[s_InsertInspectionDetails]
@mc nvarchar(50),
@comp nvarchar(50),
@opn nvarchar(50),
@opr nvarchar(50),
@CharID nvarchar(50),
@MoNumber nvarchar(50),
@BatchValue nvarchar(50),
@BatchID nvarchar(50),
@InstrumentNo nvarchar(50)='',
@Param nvarchar(50)
WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

declare @TS as datetime
Select @TS=getdate()

If @param='Insert'
BEGIN
	If Not Exists(Select * from SPCAutodata where mc=@mc and comp=@comp and opn=@opn and Dimension=@charID and MONumber=@MONumber and BatchID=@BatchID)
	Begin
		Insert into SPCAutodata( Mc, Comp, Opn, Opr, Dimension, [Value], [Timestamp], BatchTS, BatchID, MONumber,InstrumentNo)
		Select @Mc, @Comp, @Opn, @Opr, @CharID, @BatchValue, @TS, @TS, @BatchID,@MONumber,@InstrumentNo
	END

	If Exists(Select * from SPCAutodata where mc=@mc and comp=@comp and opn=@opn and Dimension=@charID and MONumber=@MONumber and BatchID=@BatchID)
	Begin
		update SPCAutodata set [Value] = @BatchValue,[Timestamp]=@TS,InstrumentNo=@InstrumentNo where mc=@mc and comp=@comp and opn=@opn and Dimension=@charID and MONumber=@MONumber and BatchID=@BatchID
	END
END

END
