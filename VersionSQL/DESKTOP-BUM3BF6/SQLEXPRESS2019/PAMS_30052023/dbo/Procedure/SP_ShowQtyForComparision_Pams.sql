/****** Object:  Procedure [dbo].[SP_ShowQtyForComparision_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

create procedure SP_ShowQtyForComparision_Pams
@vendor nvarchar(50)='' ,
@Grnno nvarchar(50)='',
@MaterialID nvarchar(50)='',
@partid nvarchar(50)='' ,
@Process nvarchar(50)='', 
@Pamsdcno nvarchar(50)='',
@mjcno nvarchar(50)='' ,
@pjcno nvarchar(50)=''
as
begin
	create table #Temp
	(
	OrderedQty_KG FLOAT,
	OrderedQty_Number float,
	ReceivedQty_KG FLOAT,
	ReceivedQty_Number float
	)


end
