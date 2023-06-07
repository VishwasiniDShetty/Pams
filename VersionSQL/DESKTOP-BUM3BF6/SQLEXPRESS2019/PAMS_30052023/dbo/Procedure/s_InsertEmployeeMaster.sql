/****** Object:  Procedure [dbo].[s_InsertEmployeeMaster]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec s_InsertEmployeeMaster @Param=N'InsertEmpInfo',@EmployeeID=N'ABGAMN',@employeeno=N'0',@name=N'ABGAMN',
@designation=N'OPERATOR1',@qualification=N'ITI',@address1=N'',@address2=N'',@phone=N'',@operate=N'0',
@setting=N'0',@maintain=N'0',@status=1,
@isadmin=1,@upassword=N'',@interfaceid=N'75',@Company_default=1,@Email=N''
--[dbo].[s_InsertComponentMaster] 'InsertCompOpnInfo','AMIT-1','TESTComp-1','ACE','','102','','','1','ACE VTL-01,ACE VTL-02','','150','','1','300','100','','','','','','','','','','','','','','','',''

*/
CREATE  PROCEDURE [dbo].[s_InsertEmployeeMaster]
@Param nvarchar(50)='',
@EmployeeID nvarchar(50)='',
@InterfaceID nvarchar(100)='',
@employeeno nvarchar(50)='',
@name nvarchar(100)='',
@Designation nvarchar(50)='',
@Qualification  nvarchar(50)='',
@address1 nvarchar(1000)='',
@address2 nvarchar(50)='',
@phone nvarchar(50)='',
@operate nvarchar(50)='',
@setting nvarchar(50)='',
@maintain nvarchar(50)='',
@status nvarchar(50)='',
@isadmin nvarchar(50)='',
@upassword nvarchar(50)='',
@Company_Default int='',
@Email nvarchar(100)='',
@plantID nvarchar(100)='',
@Role nvarchar(500)='',
@PamsRole nvarchar(500)='',
@Department nvarchar(500)=''

AS
BEGIN

If @Param = 'InsertEmpInfo'
BEGIN

		IF EXISTS(select * from employeeinformation where EmployeeID<>@EmployeeID and interfaceid=@InterfaceID)
		BEGIN
			RAISERROR('This interfaceID already exists for another Employee',16,1)
			return -1;
		END


		if not exists(select * from employeeinformation where EmployeeID=@EmployeeID)
            BEGIN
				insert into employeeinformation([Employeeid],[employeeno],[Name],[designation],[qualification],[address1],[address2],[phone],
				[operate],[setting],[maintain],[status],[isadmin],upassword,[interfaceid],[Company_default] ,[Email], [EmployeeRole],[Department])
				values(@Employeeid ,@employeeno,@Name,@designation ,@qualification,@address1,@address2,@phone,@operate,@setting ,@maintain,@status ,@isadmin ,@upassword 
				,@interfaceid ,@Company_default,@Email, @Role,@Department)
            END 
            else
            BEGIN
				if (@isadmin='' or isnull(@isadmin,'')='')
				begin
				 select @isadmin = isadmin from employeeinformation where EmployeeID=@EmployeeID
				end

				update employeeinformation set [name]=@Name, interfaceid=@InterfaceID,designation=@Designation,qualification=@Qualification,address1=@address1,phone=@phone,
				operate=@operate,setting=@setting,maintain=@maintain,[status]=@status,isadmin=@isadmin,upassword=@upassword,
				Email=@Email,Company_default=@Company_default, [EmployeeRole]=@Role,[Department]=@Department
				 where EmployeeID= @EmployeeID
            END

		--if not exists(select * from plantEmployee where PlantID=@PlantID and EmployeeID = @EmployeeID)
		--BEGIN
		--insert into plantEmployee(PlantID,EmployeeID)
		--Values(@PlantID,@EmployeeID)
		--END
		--select * from plantEmployee

END

If @Param = 'InsertPamsERPEmpInfo'
BEGIN

		IF EXISTS(select * from employeeinformation where EmployeeID<>@EmployeeID and interfaceid=@InterfaceID)
		BEGIN
			RAISERROR('This interfaceID already exists for another Employee',16,1)
			return -1;
		END


		if not exists(select * from employeeinformation where EmployeeID=@EmployeeID)
            BEGIN
				insert into employeeinformation([Employeeid],[employeeno],[Name],[designation],[qualification],[address1],[address2],[phone],
				[operate],[setting],[maintain],[status],[isadmin],upassword,[interfaceid],[Company_default] ,[Email], [Role],[Department])
				values(@Employeeid ,@employeeno,@Name,@designation ,@qualification,@address1,@address2,@phone,@operate,@setting ,@maintain,@status ,@isadmin ,@upassword 
				,@interfaceid ,@Company_default,@Email, @PamsRole,@Department)
            END 
            else
            BEGIN
				if (@isadmin='' or isnull(@isadmin,'')='')
				begin
				 select @isadmin = isadmin from employeeinformation where EmployeeID=@EmployeeID
				end

				update employeeinformation set [name]=@Name, interfaceid=@InterfaceID,designation=@Designation,qualification=@Qualification,address1=@address1,phone=@phone,
				operate=@operate,setting=@setting,maintain=@maintain,[status]=@status,isadmin=@isadmin,upassword=@upassword,
				Email=@Email,Company_default=@Company_default, [Role]=@PamsRole, [Department]=@Department
				 where EmployeeID= @EmployeeID
            END

		--if not exists(select * from plantEmployee where PlantID=@PlantID and EmployeeID = @EmployeeID)
		--BEGIN
		--insert into plantEmployee(PlantID,EmployeeID)
		--Values(@PlantID,@EmployeeID)
		--END
		--select * from plantEmployee

END




END
