/****** Object:  Procedure [dbo].[ExportMacMaintance]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[ExportMacMaintance]'','2015-10-1','2015-11-21',''
CREATE PROCEDURE [dbo].[ExportMacMaintance]
		@Machine nvarchar(50)='',
		@Fromdate datetime='',
		@Todate datetime='',
		@Shift nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

select ROW_NUMBER() OVER(ORDER BY date ) AS SLNo ,Date,Shift,PartNo,Activity,Frequency,[TimeStamp] as CreatedTS  ,Remarks
 ,Machine,SubSystem from dbo.MacMaintTransaction where  convert(nvarchar(10),[TimeStamp],120)>=convert(nvarchar(10),@Fromdate,120)  
and convert(nvarchar(10),[TimeStamp],120)<=convert(nvarchar(10),@Todate,120) and  (Machine=@Machine or @Machine= '')  
and  (Shift=@Shift or @Shift= '')  

END
