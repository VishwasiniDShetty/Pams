/****** Object:  Procedure [dbo].[S_GetHelpRequestEmpShift]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================  
-- Author: satyendraj  
-- Create date: 6-DEC-2013  
-- Description: Get all the emp from MessageHistory based on plant and HelpCode and assosiated shifts to each emp  
--ER0380 - SwathiKS - 29/May/2014 :: To fix some employees were not listing for the selected plant and helpcode.
-- =============================================  
--S_GetHelpRequestEmpShift  'HPR-PRP','supervision'
CREATE PROCEDURE [dbo].[S_GetHelpRequestEmpShift]  
 @plantId nvarchar(50)='Win Chennai - LCC',  
 @helpRequestType nvarchar(50)= 'Material'  
AS  
BEGIN  
   
 SET NOCOUNT ON;   
 DECLARE @empid varchar(MAX)  
 SET @empid = ''    

--ER0380 from Here
-- select distinct @empid = @empid + ISNULL(hrr.MobileNo,'') + ',' + ISNULL(hrr.Level2MobNo,'') + ',' 
--From HelpRequestRule hrr   
-- INNER Join PlantInformation pi on pi.PlantCode = hrr.PlantID  
-- INNER JOIN HelpCodeMaster hcm on hcm.Help_Code = hrr.HelpCode 
-- where pi.PlantID = @plantId and hcm.Help_Description = @helpRequestType  


select @empid = @empid + ISNULL(hrr.MobileNo,'') + ',' + ISNULL(hrr.Level2MobNo,'') + ',' from
(Select distinct MobileNo,Level2MobNo,PlantID,HelpCode From HelpRequestRule) hrr   
INNER Join PlantInformation pi on pi.PlantCode = hrr.PlantID  
INNER JOIN HelpCodeMaster hcm on hcm.Help_Code = hrr.HelpCode 
where pi.PlantID = @plantId and hcm.Help_Description = @helpRequestType  
--ER0380 till Here


 Declare @tep_table table  
 (      
   EmpId nvarchar(50)      
 )  
 Declare @temp_emp table  
 (      
   EmpId nvarchar(50),     
   plantId nvarchar(50),  
   shiftId int  
 )  
 Insert into @tep_table(EmpId) Exec dbo.s_Split @empid,','   
 Insert into @temp_emp(EmpId,plantId,shiftId)  select EmpId,@plantId,shiftid from @tep_table cross join shiftdetails where shiftdetails.Running = 1  
  
 select DISTINCT emp.plantId, emp.EmpId,emp.shiftId, se.shiftid as IsAssigned from @temp_emp emp   --ER0380 ADDED DISTINCT
 left outer join HelpRequestShiftEmployee se   
 on emp.plantId = se.PlantID and emp.shiftId = se.shiftid and emp.EmpId = se.EmployeeID   
     
END  
