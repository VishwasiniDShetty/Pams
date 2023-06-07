/****** Object:  Procedure [dbo].[s_InsertUpdateLoginInfo]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_InsertUpdateLoginInfo] '','',''
CREATE PROCEDURE [dbo].[s_InsertUpdateLoginInfo]
@machine nvarchar(50)='',
@DeviceName nvarchar(4000)='',
@Message nvarchar(1000)='',
@FormBackground nvarchar(50)='',
@GridHeaderBackGround nvarchar(50)='',
@param nvarchar(50)=''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

if @param='Save'
BEGIN
	if exists(select * from dbo.LoginInfo_Trelleborg where Machine=@Machine)
		BEGIN
			update LoginInfo_Trelleborg set DeviceName=@DeviceName,[Message]=@Message,[FormBackground]=@FormBackground,[GridHeaderBackground]=@GridHeaderBackGround,[default]=1 where Machine=@Machine
		END
	Else
		BEGIN
			insert into LoginInfo_Trelleborg(DeviceName,Machine,[Message],[FormBackground],[GridHeaderBackground],[Default])
			select @DeviceName,@Machine,@Message,@FormBackground,@GridHeaderBackGround,'1'
		END	
END

if @param='View'
	BEGIN
		select Machine,DeviceName,[Message],[FormBackground],[GridHeaderBackground] from dbo.LoginInfo_Trelleborg

		--select * from LoginInfo_Trelleborg
		
	END

END
