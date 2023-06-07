/****** Object:  Procedure [dbo].[Focas_TroubleShootingGuide]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Focas_TroubleShootingGuide] '2'
CREATE PROCEDURE  [dbo].[Focas_TroubleShootingGuide]

	@ParentID int
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  ;with cte as
(select parent.TSID,parent.Topic,parent.ParentId,1 as [level],Parent.HelpText,Parent.ValueInText,Parent.ValueInText1
from troubleshootingguide as parent
where parent.parentid =@parentid

union all

select child.TSID,child.Topic,child.ParentId,L.[level]+ 1,Child.HelpText,Child.ValueInText,Child.ValueInText1
from troubleshootingguide as child inner join cte as L on child.parentid=L.TSID
where child.parentid is not null)
select * from cte order by TSID

END
