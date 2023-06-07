/****** Object:  Procedure [dbo].[S_GetReIndexing]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE procedure [dbo].[S_GetReIndexing]
As
Begin

/*vasavi commented
--DBCC DBREINDEX ('autodata')
DBCC DBREINDEX('autodata','',100) 
DBCC DBREINDEX ('componentinformation','',100) 
DBCC DBREINDEX ('componentoperationpricing','',100) 
DBCC DBREINDEX ('machineinformation','',100) 
UPDATE STATISTICS autodata

UPDATE STATISTICS componentinformation

UPDATE STATISTICS componentoperationpricing*/
--Vasavi added from here

create table #fragmentation_in_percent
(
[Schema]  nvarchar(100),
[Table]  nvarchar(200),
[Index]  nvarchar(200),
avg_fragmentation_in_percent  float,
page_count  int
)

insert into #fragmentation_in_percent([Schema],[Table],[Index],avg_fragmentation_in_percent,page_count)
select dbschemas.[name] as 'Schema',dbtables.[name] as 'Table', dbindexes.[name] as 'Index',indexstats.avg_fragmentation_in_percent,
indexstats.page_count from sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) as indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes as dbindexes on dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
where indexstats.database_id = DB_ID() and (  dbtables.[name]='Autodata' or dbtables.[name]='ComponentInformation'
or dbtables.[name]='componentoperationpricing' or dbtables.[name]='Machineinformation' or dbtables.[name]='Focas_LiveData')
order by indexstats.avg_fragmentation_in_percent desc



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_NAME = N'Autodata')
BEGIN
		if exists(select * from #fragmentation_in_percent where [Table]='Autodata' and [Index]='IX_MCSTTIME' and avg_fragmentation_in_percent>30)
			BEGIN
			ALTER INDEX IX_MCSTTIME ON [dbo].[autodata] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY  = OFF, ONLINE = OFF, FILLFACTOR = 100 )
			END
		else if exists(select * from #fragmentation_in_percent where [Table]='Autodata' and [Index]='IX_MCSTTIME' and avg_fragmentation_in_percent>5) 
			BEGIN
			print 'REORGANIZE'
			ALTER INDEX IX_MCSTTIME ON [dbo].[autodata] REORGANIZE WITH ( LOB_COMPACTION = ON )
			END


		if exists(select * from #fragmentation_in_percent where [Table]='Autodata' and [Index]='PK_autodata' and avg_fragmentation_in_percent>30)
			BEGIN
			ALTER INDEX PK_autodata ON autodata  REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = ON,  ONLINE = OFF, FILLFACTOR = 100 )
			END
		else if exists(select * from #fragmentation_in_percent where [Table]='Autodata' and [Index]='PK_autodata' and avg_fragmentation_in_percent>5) 
			BEGIN
			print '1'
			ALTER INDEX PK_autodata ON [dbo].[autodata] REORGANIZE WITH ( LOB_COMPACTION = ON )
			END

			
		if exists(select * from #fragmentation_in_percent where [Table]='Autodata' and [Index]='PK_autodata1' and avg_fragmentation_in_percent>30)
			BEGIN
			ALTER INDEX PK_autodata1 ON autodata  REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = ON,  ONLINE = OFF, FILLFACTOR = 100 )
			END
		else if exists(select * from #fragmentation_in_percent where [Table]='Autodata' and [Index]='PK_autodata1' and avg_fragmentation_in_percent>5) 
			BEGIN
			print '1'
			ALTER INDEX PK_autodata1 ON [dbo].[autodata] REORGANIZE WITH ( LOB_COMPACTION = ON )
			END


UPDATE STATISTICS autodata
END

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_NAME = N'componentinformation')
BEGIN
		if exists(select * from #fragmentation_in_percent where [Table]='componentinformation' and [Index]='PK_componentinformation' and avg_fragmentation_in_percent>30)
			BEGIN
				ALTER INDEX [PK_componentinformation] ON [dbo].[componentinformation] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF , FILLFACTOR = 100 )
			END
		else  if exists(select * from #fragmentation_in_percent where [Table]='componentinformation' and [Index]='PK_componentinformation' and avg_fragmentation_in_percent>5)
			BEGIN
			print '1'
				ALTER INDEX [PK_componentinformation] ON [dbo].[componentinformation] REORGANIZE WITH ( LOB_COMPACTION = ON )
			END



UPDATE STATISTICS componentinformation

END
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_NAME = N'componentoperationpricing')
BEGIN
	if exists(select * from #fragmentation_in_percent where [Table]='componentoperationpricing' and [Index]='PK_componentoperationpricing' and avg_fragmentation_in_percent>30)
		BEGIN
			ALTER INDEX PK_componentoperationpricing ON componentoperationpricing REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = ON,ONLINE = OFF, FILLFACTOR = 100 )
		END
	else if exists(select * from #fragmentation_in_percent where [Table]='componentoperationpricing' and [Index]='PK_componentoperationpricing' and avg_fragmentation_in_percent>5)
		BEGIN
		print '1'
			ALTER INDEX PK_componentoperationpricing ON [dbo].componentoperationpricing REORGANIZE WITH ( LOB_COMPACTION = ON )
		END

UPDATE STATISTICS componentoperationpricing
END

if exists(select * from #fragmentation_in_percent where [Table]='machineinformation' and [Index]='PK_machineinformation' and avg_fragmentation_in_percent>30)
BEGIN
	ALTER INDEX PK_machineinformation ON machineinformation REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = ON,  ONLINE = OFF, FILLFACTOR = 100 )
END
else if  exists(select * from #fragmentation_in_percent where [Table]='machineinformation' and [Index]='PK_machineinformation' and avg_fragmentation_in_percent>5)
BEGIN
	ALTER INDEX PK_machineinformation ON  machineinformation REORGANIZE WITH ( LOB_COMPACTION = ON )
END

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_NAME = N'Focas_LiveData')
BEGIN
	if exists(select * from #fragmentation_in_percent where [Table]='Focas_Livedata' and [Index]='PK_Focas_Livedata' and avg_fragmentation_in_percent>30)
		BEGIN
			ALTER INDEX PK_Focas_Livedata ON Focas_LiveData REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = ON,  ONLINE = OFF, FILLFACTOR = 100 )
		END
	else if exists(select * from #fragmentation_in_percent where [Table]='Focas_Livedata' and [Index]='PK_Focas_Livedata' and avg_fragmentation_in_percent>5)
		BEGIN
		ALTER INDEX PK_Focas_Livedata ON  Focas_LiveData REORGANIZE WITH ( LOB_COMPACTION = ON )
		END

	if exists(select * from #fragmentation_in_percent where [Table]='Focas_Livedata' and [Index]='MC_CNCTime' and avg_fragmentation_in_percent>30)
		BEGIN
		ALTER INDEX MC_CNCTime ON Focas_LiveData REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = ON,  ONLINE = OFF, FILLFACTOR = 100 )
		END
	else if exists(select * from #fragmentation_in_percent where [Table]='Focas_Livedata' and [Index]='MC_CNCTime' and avg_fragmentation_in_percent>5)
		BEGIN
			ALTER INDEX MC_CNCTime ON  Focas_LiveData REORGANIZE WITH ( LOB_COMPACTION = ON )
		END
UPDATE STATISTICS Focas_LiveData
END

/*
DECLARE @db_id smallint;
DECLARE @object_idCI int;
DECLARE @object_idCOP int;
DECLARE @object_idMI int;
DECLARE @object_idAD int;
Declare @i as smallint;
declare @table as nvarchar(100);
Declare @indexname as nvarchar(50);
Create table #reindextable 
(
slno smallint identity(1,1),
Tablename nvarchar(100),
FragPercent int,
indexname nvarchar(100)
)
SET @db_id = DB_ID();
SET @object_idAD = OBJECT_ID(N'autodata')
SET @object_idCI = OBJECT_ID(N'componentinformation')
SET @object_idCOP = OBJECT_ID(N'componentoperationpricing')
SET @object_idMI = OBJECT_ID(N'machineinformation')

print @db_id
print @object_idAD
print @object_idMI
print @object_idCI
print @object_idCOP
insert into #reindextable (Tablename,FragPercent,indexname)
 Select distinct T.TableName,T.AvgFragpercent ,T.IndexName from (
SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName, 
ind.name AS IndexName, indexstats.index_type_desc AS IndexType, 
indexstats.avg_fragmentation_in_percent as AvgFragpercent
FROM sys.dm_db_index_physical_stats(@db_id, NULL, NULL, NULL, NULL) indexstats 
INNER JOIN sys.indexes ind  
ON ind.object_id = indexstats.object_id 
AND ind.index_id = indexstats.index_id 
WHERE  ind.object_id in (@object_idAD,@object_idCI,@object_idCOP,@object_idMI)
)T
	select * from #reindextable
	set @i=1;
	while (@i<=(Select Max(slno) from #reindextable))
	begin
		Set @table=''
		--Set @table =(Select TableName from #reindextable where slno=@i and FragPercent>30)
		Set @table =(Select TableName from #reindextable where slno=@i )
		if(@table<>'')
		begin

			BEGIN TRY
				DBCC DBREINDEX (@table)
print @table
		   END TRY
			BEGIN CATCH			
			END CATCH			
		end
		--Set @table =(Select TableName from #reindextable where slno=@i and (FragPercent<30 and FragPercent>10))
		--Set @table =(Select TableName from #reindextable where slno=@i and (FragPercent< ))
		--if(@table<>'')
		--begin
			--Set @indexname=(Select indexname from #reindextable where slno=@i)
			--DBCC INDEXDEFRAG (@db_id,@table,@indexname)
		--end
		set @i=@i+1
	End */

End
