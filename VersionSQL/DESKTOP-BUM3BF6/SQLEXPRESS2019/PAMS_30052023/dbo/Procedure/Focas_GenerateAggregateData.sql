/****** Object:  Procedure [dbo].[Focas_GenerateAggregateData]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Focas_GenerateAggregateData]   '',''
CREATE PROCEDURE [dbo].[Focas_GenerateAggregateData]    
 @StartTime datetime,    
 @EndTime datetime
     
AS    
BEGIN 

Select @StartTime= Convert(nvarchar(10),@StartTime,120)
Select @EndTime= Convert(nvarchar(10),@EndTime,120)

Select @StartTime
Select @EndTime

while @StartTime<=@EndTime
Begin
EXEC [dbo].[FocasWeb_InsertShift&HourwiseSummary] @StartTime
Select @StartTime = dateadd(day,1,@StartTime)
Select @StartTime

End

End    
