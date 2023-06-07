/****** Object:  Procedure [dbo].[Focas_PMCSignalStatusView]    Committed by VersionSQL https://www.versionsql.com ******/

    
--[dbo].[Focas_PMCSignalStatusView] '1','X'    
CREATE PROCEDURE [dbo].[Focas_PMCSignalStatusView]    
 @machineid as nvarchar(50),     
 @address as nvarchar(50)    
AS    
BEGIN    
     
SET NOCOUNT ON;    
    
select distinct ID,MachineId,[Address],Value,InsertedTime from Focas_PMCSignalStatus    
where InsertedTime = (select max(InsertedTime) from Focas_PMCSignalStatus where  MachineID=@machineid and [address] LIKE @address +'%' )    
and [address] LIKE @address +'%'   and MachineID=@machineid  
order by [address] asc    
    
END    
