/****** Object:  Procedure [dbo].[s_ViewEmployeeMaster]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_ViewEmployeeMaster] '','ViewEmployeeInfo'  
--[dbo].[s_ViewComponentMaster] '','ViewCompOpnInfo'  
CREATE       PROCEDURE [dbo].[s_ViewEmployeeMaster]  
@EmployeeID nvarchar(50)='',  
@Param nvarchar(50)=''   
AS  
BEGIN  
  
If @Param = 'ViewEmployeeInfo'  
Begin  
  
 If @EmployeeID <> ''  
 BEGIN  
    SELECT    
    U.[Employeeid]  
      ,U.[employeeno]  
      ,U.[Name], 
--	  STUFF((  
--    SELECT ', '+PlantID FROM PlantEmployee WHERE PlantEmployee.EmployeeID = U.Employeeid FOR XML PATH('')  
--), 1, 1, '') Plants 
 STUFF((  
    SELECT N', '+PlantID FROM PlantEmployee WHERE PlantEmployee.EmployeeID = U.Employeeid
	FOR XML PATH(N''), TYPE).value('(./text())[1]','varchar(max)'),1, 1, N'') Plants
      ,U.[designation]  
      ,U.[qualification]  
      ,U.[address1]  
      ,U.[address2]  
      ,U.[phone]  
      ,U.[operate]  
      ,U.[setting]  
      ,U.[maintain]  
      ,U.[status]  
      ,U.[isadmin]  
      ,U.[upassword]  
      ,U.[interfaceid]  
      ,U.[Company_default]  
      ,U.[Email]  
      ,U.[MobileNo]  
      ,U.[EmployeeImage] 
	  ,U.[Role]
	  ,U.[EmployeeRole]
	  ,U.[Department]
 FROM (SELECT * FROM employeeinformation where EmployeeID like  @EmployeeID + '%') U  
 Order by EmployeeID  
 END  
  
  
 If @EmployeeID = ''  
 BEGIN  
SELECT    
    U.[Employeeid]  
      ,U.[employeeno]  
      ,U.[Name], 
--	  STUFF((  
--    SELECT ', '+PlantID FROM PlantEmployee WHERE PlantEmployee.EmployeeID = U.Employeeid FOR XML PATH('')  
--), 1, 1, '') Plants 
	STUFF((  
    SELECT N', '+PlantID FROM PlantEmployee WHERE PlantEmployee.EmployeeID = U.Employeeid
	FOR XML PATH(N''), TYPE).value('(./text())[1]','varchar(max)'),1, 1, N'') Plants
      ,U.[designation]  
      ,U.[qualification]  
      ,U.[address1]  
      ,U.[address2]  
      ,U.[phone]  
      ,U.[operate]  
      ,U.[setting]  
      ,U.[maintain]  
      ,U.[status]  
      ,U.[isadmin]  
      ,U.[upassword]  
      ,U.[interfaceid]  
      ,U.[Company_default]  
      ,U.[Email]  
      ,U.[MobileNo]  
      ,U.[EmployeeImage]
	  ,U.[Role]  
	  ,U.[EmployeeRole]
	  ,U.[Department]
 FROM (SELECT * FROM employeeinformation) U  
 Order by EmployeeID  
 END  
ENd  
  
  
  
END  
  
