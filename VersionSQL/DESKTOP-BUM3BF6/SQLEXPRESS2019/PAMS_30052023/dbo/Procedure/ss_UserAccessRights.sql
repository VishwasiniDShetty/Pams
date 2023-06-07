/****** Object:  Procedure [dbo].[ss_UserAccessRights]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[ss_UserAccessRights]'sairoj','WebView'
--[dbo].[ss_UserAccessRights]'sairoj','View'
CREATE PROCEDURE [dbo].[ss_UserAccessRights]
@user nvarchar(50)='',
@param nvarchar(50)=''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

create table #temp
(
domain nvarchar(50),
DisplayText nvarchar(100),
Code nvarchar(50),
Isvisible bit default 0,
employeeid nvarchar(100),
DomainName nvarchar(50)
)

if(@param='View')
BEGIN
insert into #temp(Domain,DisplayText,code,DomainName)
select distinct UAD.Domain,UAD.DisplayText,UAD.Code,UAD.DomainName from
(select * from [dbo].[ss_UserAccessDefault] where isnull(WebColumn,'') != 'web') UAD
left outer join useraccessrights_Web UAR on UAD.Code = UAR.domain and UAD.Domain = UAR.[type]

update #temp set employeeid= T.Employeeid ,Isvisible = 1 from
(select UAR.Employeeid,UAR.domain,UAR.[type] from useraccessrights_Web UAR inner join #temp t1 on t1.domain= UAR.[type] and t1.Code =UAR.domain where UAR.employeeid=@user )T
inner join #temp on T.domain= #temp.Code and T.type= #temp.domain

select domain,displayText,code,Isvisible,@user as Employeeid,DomainName from #temp;

END

if(@param='WebView')
BEGIN
insert into #temp(Domain,DisplayText,code,DomainName)
select distinct UAD.Domain,UAD.DisplayText,UAD.Code,UAD.DomainName from
(select * from [dbo].[ss_UserAccessDefault] where WebColumn='web') UAD
left outer join useraccessrights_Web UAR on UAD.Code = UAR.domain and UAD.Domain = UAR.[type]

update #temp set employeeid= T.Employeeid ,Isvisible = 1 from
(select UAR.Employeeid,UAR.domain,UAR.[type] from useraccessrights_Web UAR inner join #temp t1 on t1.domain= UAR.[type] and t1.Code =UAR.domain where UAR.employeeid=@user )T
inner join #temp on T.domain= #temp.Code and T.type= #temp.domain

select domain,displayText,code,Isvisible,@user as Employeeid,DomainName from #temp;

END


END
