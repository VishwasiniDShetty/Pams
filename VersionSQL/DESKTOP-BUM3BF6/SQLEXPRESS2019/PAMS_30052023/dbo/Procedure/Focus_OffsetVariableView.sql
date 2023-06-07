/****** Object:  Procedure [dbo].[Focus_OffsetVariableView]    Committed by VersionSQL https://www.versionsql.com ******/

 CREATE PROCEDURE [dbo].[Focus_OffsetVariableView]  
 @MachineId nvarchar(50),  
 @OffSetValue nvarchar(50)='',  
 @StartLocation nvarchar(50)='',  
 @EndLocation nvarchar(50)='',  
 @param nvarchar(50) = ''  
  
  
AS  
BEGIN  
   
 SET NOCOUNT ON;  
  
if @param ='View'  
Begin  
  
if NOT EXISTS (select * from Focas_OffsetVariables where MachineID=@MachineId)
BEGIN
	with CTE(OffsetAxis) as  
	(  
	select 'X' UNION All select 'Z'  
	)
	select CTE.OffsetAxis,0 as StartLocation,0 as EndLocation from CTE 
End  ;

with CTE(OffsetAxis) as  
	(  
	select 'X' UNION All select 'Z'  
	)
	select CTE.OffsetAxis,F.StartLocation,F.EndLocation from CTE 
	left outer join Focas_OffsetVariables F on CTE.OffsetAxis=F.OffsetAxis  
	where F.MachineID=@MachineId   
END
  
if @param ='insert'    
Begin  

--update if exists or insert

IF EXISTS( Select * from Focas_OffsetVariables where MachineId = @machineId AND OffsetAxis = @offsetValue)
BEGIN

Update dbo.Focas_OffsetVariables SET StartLocation = @startLocation, EndLocation = @endlocation
where MachineId = @machineId AND OffsetAxis = @offsetValue
END
ELSE
BEGIN
 insert into Focas_OffsetVariables(MachineId,OffsetAxis, StartLocation, EndLocation)VALUES
			(@MachineId,@offsetValue, @StartLocation, @EndLocation)
END
/*
MERGE dbo.Focas_OffsetVariables AS F  
 USING (SELECT @machineId, @offsetValue, @startLocation, @endlocation)   
 AS src (MachineId,OffsetAxis, StartLocation,EndLocation)  
 ON F.OffsetAxis = src.OffsetAxis and F.MachineId=src.MachineId  
 WHEN MATCHED THEN   
 UPDATE SET OffsetAxis   = src.OffsetAxis,  
 StartLocation = src.StartLocation,  
EndLocation = src.EndLocation  
                    
      WHEN NOT MATCHED THEN     
          INSERT (MachineId,OffsetAxis, StartLocation, EndLocation)  
          VALUES (Src.MachineId,src.OffsetAxis, src.StartLocation, src.EndLocation);  
  
--select * from Focas_OffsetVariables  
*/
End  
  
End  
