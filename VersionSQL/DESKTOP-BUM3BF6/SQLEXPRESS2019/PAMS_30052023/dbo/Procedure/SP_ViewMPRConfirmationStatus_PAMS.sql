/****** Object:  Procedure [dbo].[SP_ViewMPRConfirmationStatus_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

create procedure [dbo].[SP_ViewMPRConfirmationStatus_PAMS]
@Role nvarchar(50)='',
@Param nvarchar(50)=''
as
begin
select * from MPRConfirmationStatus_MR_PAMS
end
