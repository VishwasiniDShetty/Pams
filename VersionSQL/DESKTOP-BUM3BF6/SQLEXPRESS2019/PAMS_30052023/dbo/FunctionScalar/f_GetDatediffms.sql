/****** Object:  Function [dbo].[f_GetDatediffms]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0371-SwathiKS- 28/Nov/2013 :: To get milliseconds difference between Starttime and endtime.
--select [dbo].[f_GetDatediffms] ('2013-07-11 10:27:02.150','2013-07-11 10:27:07.120')
CREATE Function [dbo].[f_GetDatediffms](@StartDate datetime,@EndDate datetime)
RETURNS bigint

AS
BEGIN

Declare @msdiff as int
set @msdiff =datepart(ms,@EndDate)-datepart(ms,@StartDate)

RETURN
(
select cast(datediff(ss,@StartDate,@EndDate) as bigint) * 1000 + isnull( @msdiff,0)
)

END
