/****** Object:  Procedure [dbo].[Focas_GetSpindleDetails]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[Focas_GetSpindleDetails]      
 @StartTime datetime,      
 @EndTime datetime,      
 @MachineID nvarchar(50) = '',
 @param nvarchar(50)='',
 @AxisNo nvarchar(50)=''       
AS      
BEGIN      


If @AxisNo=''
Begin
	SET @AxisNo='X'
End

If @param='OEMSpindleDetails'
Begin

Declare @Curtime as datetime
Select @Curtime = getdate()


select SpindleSpeed,SpindleLoad,CNCTimeStamp,Temperature from Focas_SpindleInfo where (CNCTimeStamp between @StartTime and @EndTime)      
and MachineID = @MachineID and AxisNo=@AxisNo order by CNCTimeStamp  

Return

End
     
select SpindleSpeed,SpindleLoad,CNCTimeStamp,Temperature from Focas_SpindleInfo where (CNCTimeStamp between @StartTime and @EndTime)      
and MachineID = @MachineID and AxisNo=@AxisNo order by CNCTimeStamp      
      
End 
