/****** Object:  Procedure [dbo].[Focas_GetOffsetDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from [Focas_ToolOffsetHistory]
--[dbo].[Focas_GetOffsetDetails]'CNC GRINDING','2015-01-01','2016-04-15','','DashBoard'
CREATE PROCEDURE [dbo].[Focas_GetOffsetDetails]
@machineid nvarchar(50)='',
@FromTime datetime='',
@ToTime datetime='',
@OffsetNo nvarchar(50)='',
@Param nvarchar(50)=''  --DashBoard
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


if @offsetNo='ALL'
BEGIN
set @offsetNo =''
END

create table #OffsetNo
( OffsetNo nvarchar(50)
)

 if isnull(@OffsetNo,'')<> ''  and @OffsetNo <>'ALL'
 begin  
 	insert into #OffsetNo(OffsetNo)
	SELECT val FROM dbo.Split(@OffsetNo, ',')
 end


if @param='DashBoard'
BEGIN

select distinct MachineID,MachineTimeStamp,WearOffsetX,WearOffsetZ,MachineMode ,ProgramNumber,OffsetNo  from [dbo].[Focas_ToolOffsetHistory]
 where ( OffsetNo in (select offsetNo from #offsetNo)  or @OffsetNo='') and machineid=@machineid 
 and MachineTimeStamp>=@fromTime and MachineTimeStamp<=@ToTime order by MachineTimeStamp asc;


END

if @param='top20'  --select top 20 records for table for each offset
BEGIN
select distinct T.MachineID,T.MachineTimeStamp,
       T.WearOffsetX,
       T.WearOffsetZ,T.OffsetNo,T.MachineMode,T.ProgramNumber
from (
     select T.machineid,T.MachineTimeStamp,
            T.WearOffsetX,
            T.WearOffsetZ,T.Offsetno,T.MachineMode,T.ProgramNumber,
            row_number() over(partition by T.OffsetNo order by T.MachineTimeStamp asc) as rn
     from dbo.[Focas_ToolOffsetHistory] as T where ( T.OffsetNo in (select offsetNo from #offsetNo)  or @OffsetNo='')
	and T.machineid=@machineid
     ) as T
where T.rn <= 20  


END


END
