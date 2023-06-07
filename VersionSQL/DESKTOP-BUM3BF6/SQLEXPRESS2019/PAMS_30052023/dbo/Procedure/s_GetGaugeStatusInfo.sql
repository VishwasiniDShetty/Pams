/****** Object:  Procedure [dbo].[s_GetGaugeStatusInfo]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************
Author :: MRao Date :: 06-July-2006
Changed By Shilpa on 19-Nov-2007 for DR0062
mod 1 :- ER0182 By Kusuma M.H on 28-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
ER0281 - SwathiKS - 28/Mar/2011 :: To Show Last Processed Date For Unique Combination of GuageID and GaugeSLNO.
***********************************************************/
--s_GetGaugeStatusInfo '2011-01-01','2011-05-28','','',''
CREATE           procedure [dbo].[s_GetGaugeStatusInfo]
	@StartTime as datetime,
	@EndTime as Datetime,
	@GaugeID as nvarchar(50)='',
	@GaugeSlNo as nvarchar(20)='',
	@param as nvarchar(20)='ALL'   --ER0281
as
BEGIN
	
declare @strsql nvarchar(4000)
declare @strgaugeid nvarchar(255)
declare @strgaugesn nvarchar(255)
select @strsql=''
select @strgaugesn=''
select @strgaugeid=''
Create table #Gaugemovementstatus
	(
		Gaugeid Nvarchar(50),
		GaugeSlno Nvarchar(50),
		status Nvarchar(50),
		ProcessDate Datetime,
		Contact nvarchar(50),
		Slno Bigint
	)
Insert into #Gaugemovementstatus
--select * from GaugeMovementStatus where gaugeid not in (select gaugeid from GaugeMovementStatus where status='scrapped') --ER0281
select * from GaugeMovementStatus where gaugeslno not in (select gaugeslno from GaugeMovementStatus where status='scrapped') --ER0281

if isnull(@GaugeID,'') <> ''
	begin
	---mod 1
--	SELECT @strgaugeid = ' AND (G.GaugeID = ''' +@GaugeID+ ''')'
	SELECT @strgaugeid = ' AND (G.GaugeID = N''' +@GaugeID+ ''')'
	---mod 1
	end
if isnull(@GaugeSlNo,'') <> ''
	begin
	---mod 1
--	SELECT @strgaugesn = ' AND (G.GaugeSlNo = ''' +@GaugeSlNo+ ''')'
	SELECT @strgaugesn = ' AND (G.GaugeSlNo = N''' +@GaugeSlNo+ ''')'
	---mod 1
	end
--select @strsql = 'SELECT G.GaugeID,G.GaugeSlNo,G.GaugeOwner,G.NextCalDue,M.Location'

--ER0281 From Here.
If @param = 'ALL' or @param=''
Begin
	select @strsql = 'SELECT G.GaugeID,G.GaugeSlNo,G.GaugeOwner,G.NextCalDue,M.status,M.Processdate,Datediff(d,G.NextCalDue,getdate()) as OverDue'
	select @strsql = @strsql + ' from GaugeInformation as G Left outer join #Gaugemovementstatus M ON '
	select @strsql = @strsql + ' G.GaugeID=M.GaugeID and G.GaugeSlNo=M.GaugeSlNo '
	--select @strsql = @strsql + ' where M.Location<>''Scrapped'' And G.NextCalDue>='''+Convert(NvarChar(20),@StartTime)+''' And G.NextCalDue<='''+Convert(NvarChar(20),@EndTime)+''' '
	select @strsql = @strsql + ' where M.status<>''Scrapped'' And G.NextCalDue>='''+Convert(NvarChar(20),@StartTime)+''' And G.NextCalDue<='''+Convert(NvarChar(20),@EndTime)+''''
	select @strsql = @strsql + @strgaugeid + @strgaugesn
	select @strsql = @strsql + ' order by G.GaugeID,G.GaugeSlNo,G.NextCalDue '
	print @strsql
	EXEC (@strsql)
end


If @param = 'Current Status'
Begin
	select @strsql = 'SELECT G.GaugeID,G.GaugeSlNo,G.GaugeOwner,G.NextCalDue,M.status,T1.Processdate,Datediff(d,G.NextCalDue,getdate()) as OverDue'
	select @strsql = @strsql + ' from GaugeInformation as G Left outer join #Gaugemovementstatus M ON '
	select @strsql = @strsql + ' G.GaugeID=M.GaugeID and G.GaugeSlNo=M.GaugeSlNo '
	select @strsql = @strsql + 'inner join(select GaugeID,GaugeSlNo,Max(processdate)as Processdate from Gaugemovementstatus group by  GaugeID,GaugeSlNo) T1 ' 
	select @strsql = @strsql + ' ON T1.GaugeID=M.GaugeID and T1.GaugeSlNo=M.GaugeSlNo and T1.Processdate=M.processdate '
	--select @strsql = @strsql + ' where M.Location<>''Scrapped'' And G.NextCalDue>='''+Convert(NvarChar(20),@StartTime)+''' And G.NextCalDue<='''+Convert(NvarChar(20),@EndTime)+''' '
	select @strsql = @strsql + ' where M.status<>''Scrapped'' And G.NextCalDue>='''+Convert(NvarChar(20),@StartTime)+''' And G.NextCalDue<='''+Convert(NvarChar(20),@EndTime)+''' '
	select @strsql = @strsql + @strgaugeid + @strgaugesn
	select @strsql = @strsql + ' order by G.GaugeID,G.GaugeSlNo,G.NextCalDue '
	print @strsql
	EXEC (@strsql)
end
--ER0281 Till Here.

END
