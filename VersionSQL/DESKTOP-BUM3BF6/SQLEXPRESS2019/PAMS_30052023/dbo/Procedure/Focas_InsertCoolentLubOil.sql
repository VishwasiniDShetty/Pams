/****** Object:  Procedure [dbo].[Focas_InsertCoolentLubOil]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[Focas_InsertCoolentLubOil]
   
	@machineID nvarchar(50)='',
	@CNCTimeStamp datetime,
	@CoolentLevel  decimal(18,3) = '',
	@LubOilLevel as decimal(18,3) = '',
	@PrevCoolentLevel as  decimal(18,3) = '',
	@PrevLubOilLevel as  decimal(18,3) = ''
	
AS
BEGIN
	
	SET NOCOUNT ON;  

	declare @PrevCoolent as decimal
	declare @PrevLubOil as decimal

	if @PrevCoolentLevel ='-1' or @PrevLubOilLevel = '-1'
	Begin
		 select  top 1  @PrevCoolent =coolentlevel, @PrevLubOil =LubOillevel from [dbo].[Focas_CoolentLubOilInfo] where machineID = @machineID order by id desc
	End 	
	ELSE
	BEGIN
		SET @PrevCoolent = ISNULL(@PrevCoolentLevel,0);
	    set @PrevLubOil =ISNULL(@PrevLubOilLevel,0);
	END

     insert into [dbo].[Focas_CoolentLubOilInfo](MachineID,CNCTimeStamp,CoolentLevel,LubOilLevel,PrevCoolentLevel,PrevLubOilLevel)
     select @machineID,@CNCTimeStamp,@CoolentLevel,@LubOilLevel,ISNULL(@PrevCoolent,0),ISNULL(@PrevLubOil,0)
  
     select * from [Focas_CoolentLubOilInfo]
   

END
