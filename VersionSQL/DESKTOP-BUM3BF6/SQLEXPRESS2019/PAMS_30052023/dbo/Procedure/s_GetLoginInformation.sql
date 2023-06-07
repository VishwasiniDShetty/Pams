/****** Object:  Procedure [dbo].[s_GetLoginInformation]    Committed by VersionSQL https://www.versionsql.com ******/

-- [dbo].[s_GetLoginInformation]'','pct','admin','login'  
CREATE PROCEDURE [dbo].[s_GetLoginInformation]  
@deviceName nvarchar(50)='',  
@UserName nvarchar(50)='',  
@password nvarchar(50)='',  
@param nvarchar(50)=''  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
if @param='MachineList'  
 BEGIN  
 select distinct Machine from [dbo].[LoginInfo_Trelleborg] where [default]='1' and deviceName=@deviceName;  
  
 select distinct  MachineID from eshopxmachines;  
 END  
  
if @param='LOGIN'  
 BEGIN  
  if exists(select * from employeeinformation WHERE EmployeeID=@UserName and [upassword]=@password)  
   BEGIN  
   Select 'Valid' as Valid, EmployeeRole from employeeinformation WHERE EmployeeID=@UserName and [upassword]=@password
   END  
  Else  
   BEGIN  
   Select 'InValid' as Valid  
   END  
  
  --if exists(select * from employeeinformation WHERE isadmin=1 and @username='pct')  
  -- BEGIN  
  --  Select 'SuperAdmin' as IsAdmin  
  -- END  
    if exists(select * from employeeinformation WHERE isadmin=1 and EmployeeID=@username)  
   BEGIN  
    Select 'Admin' as IsAdmin
   END  
   else  
   BEGIN  
    select 'NonAdmin'as IsAdmin  
   END  
   
 END  
  
  
END  
  
