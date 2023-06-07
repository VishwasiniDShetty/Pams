/****** Object:  Procedure [dbo].[SP_UserRoleRights_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*

[dbo].[SP_UserRoleRights_PAMS] @Role=N'Purchase',@Param=N'View'
[dbo].[SP_UserRoleRights_PAMS] @Role=N'''PPC'',''MR'',''Purchase''',@Param=N'ModuleView'
[dbo].[SP_UserRoleRights_PAMS] @Role=N'''PPC'',''MR'',''Purchase''',@Param=N'ScreenView'



*/
CREATE Procedure [dbo].[SP_UserRoleRights_PAMS]
@Role nvarchar(2000)='',
@ScreenName nvarchar(100)='',
@ModuleName nvarchar(100)='',
@AccessType nvarchar(50)='',
@Param nvarchar(50)=''

AS
BEGIN
declare @Strsql nvarchar(max)
declare @StrRole nvarchar(max)
select @Strsql=''
select @StrRole=''


if isnull(@Role,'')<>''
begin
	select @StrRole='And Rolename in ('+@Role+')'
end


create table #UserAccess
(
Role nvarchar(50),
ModuleName nvarchar(100),
moduledisplayName nvarchar(100),
screenName nvarchar(100),
screenDisplayName nvarchar(100),
accesstype nvarchar(50)
)

create table #UserAccess1
(
Role nvarchar(50),
ModuleName nvarchar(100),
moduledisplayName nvarchar(100),
screenName nvarchar(100),
screenDisplayName nvarchar(100),
accesstype nvarchar(50)
)

IF @Param='Save'
BEGIN
	
		IF not exists(select * from UserRoleRights_PAMS where  [Role]=@Role and ModuleName=@ModuleName and ScreenName=@ScreenName)
		BEGIN
			Insert into UserRoleRights_PAMS(Role,ModuleName,ScreenName,AccessType,UpdatedTS)
			values(@Role,@ModuleName,@ScreenName,@AccessType,GETDATE())
		END
		ELSE
		BEGIN
			Update UserRoleRights_PAMS set AccessType=@AccessType, UpdatedTS=GETDATE()
			where  [Role]=@Role and ModuleName=@ModuleName and ScreenName=@ScreenName
		end
end

if @Param='View'
begin
	insert into #UserAccess(Role,ModuleName,moduledisplayName,screenName,screenDisplayName)
	select @Role,m1.ModuleName,m1.moduledisplayName,m1.screenName,m1.screenDisplayName from ModuleScreenDetails_Pams m1

	update #UserAccess set accesstype=isnull(t1.accesstype,'')
	from
	(
	select distinct Role,ModuleName,ScreenName,AccessType from UserRoleRights_PAMS where role=@Role
	)t1 inner join #UserAccess t2 on t1.role=t2.role and t1.modulename=t2.ModuleName and t1.screenname=t2.screenName

	select * from #UserAccess order by ModuleName,screenName
end

if @Param='ModuleView'
begin
	select @Strsql=''
	select @strsql=@strsql+'insert into #UserAccess(Role,ModuleName,moduledisplayName) '
	select @strsql=@strsql+'select r1.RoleName,m1.ModuleName,m1.moduledisplayName from ModuleScreenDetails_Pams m1 cross join RoleInformation_Pams r1 where 1=1'
	select @strsql=@strsql+@StrRole
	print(@strsql)
	exec(@strsql)

	update #UserAccess set accesstype=isnull(t1.accesstype,'None')
	from
	(
	select distinct role,ModuleName,AccessType from UserRoleRights_PAMS where AccessType='View'
	)t1 inner join #UserAccess t2 on t1.role=t2.Role and t1.ModuleName=t2.ModuleName


	select distinct Role,ModuleName,moduledisplayName,isnull(accesstype,'None') as accesstype from #UserAccess

	--select @Strsql=''
	--select @strsql=@strsql+'insert into #UserAccess(ModuleName,moduledisplayName) '
	--select @strsql=@strsql+'select distinct m1.ModuleName,m1.moduledisplayName from ModuleScreenDetails_Pams m1 cross join RoleInformation_Pams r1 where 1=1'
	--print(@strsql)
	--exec(@strsql)


	--select @Strsql=''
	--select @Strsql=@Strsql+'
	--update #UserAccess set accesstype=isnull(t1.accesstype,''None'')
	--from
	--(
	--select distinct ModuleName,AccessType from UserRoleRights_PAMS where AccessType=''View'' and 1=1 '
	--select @Strsql=@Strsql+@StrRole
	--select @Strsql=@Strsql+')t1 inner join #UserAccess t2 on  t1.ModuleName=t2.ModuleName '
	--print(@strsql)
	--exec(@strsql)

	--select distinct Role,ModuleName,moduledisplayName,isnull(accesstype,'None') as accesstype from #UserAccess


	 
end
if @Param='ScreenView'
begin
	select @Strsql=''
	select @strsql=@strsql+'insert into #UserAccess1(Role,ModuleName,moduledisplayName,screenName,screenDisplayName) '
	select @strsql=@strsql+'select r1.RoleName,m1.ModuleName,m1.moduledisplayName,screenName,screenDisplayName from ModuleScreenDetails_Pams m1 cross join RoleInformation_Pams r1 where 1=1'
	select @strsql=@strsql+@StrRole
	print(@strsql)
	exec(@strsql)

	update #UserAccess1 set accesstype=isnull(t1.accesstype,'None')
	from
	(select distinct role,ModuleName,screenName,AccessType from UserRoleRights_PAMS 
	)t1 inner join #UserAccess1 t2 on t1.role=t2.Role and t1.ModuleName=t2.ModuleName and t1.screenName=t2.screenName

	select distinct Role,ModuleName,moduledisplayName,screenName,screenDisplayName,isnull(accesstype,'None') as accesstype from #UserAccess1

	--	select @Strsql=''
	--select @strsql=@strsql+'insert into #UserAccess1(ModuleName,moduledisplayName,screenName,screenDisplayName) '
	--select @strsql=@strsql+'select  distinct m1.ModuleName,m1.moduledisplayName,screenName,screenDisplayName from ModuleScreenDetails_Pams m1 cross join RoleInformation_Pams r1 where 1=1'
	--print(@strsql)
	--exec(@strsql)

	--select @Strsql=''
	--select @Strsql=@Strsql+'
	--update #UserAccess set accesstype=isnull(t1.accesstype,''None'')
	--from
	--(
	--select distinct ModuleName,screenName,AccessType from UserRoleRights_PAMS where AccessType=''View'' and 1=1 '
	--select @Strsql=@Strsql+@StrRole
	--select @Strsql=@Strsql+')t1 inner join #UserAccess t2 on  t1.ModuleName=t2.ModuleName and t1.screenName=t2.screenName '
	--print(@strsql)
	--exec(@strsql)

	--select distinct ModuleName,moduledisplayName,screenName,screenDisplayName,isnull(accesstype,'None') as accesstype from #UserAccess1

end

END
