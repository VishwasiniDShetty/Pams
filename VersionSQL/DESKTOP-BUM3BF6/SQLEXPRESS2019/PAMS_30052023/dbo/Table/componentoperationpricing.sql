/****** Object:  Table [dbo].[componentoperationpricing]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[componentoperationpricing](
	[componentid] [nvarchar](50) NULL,
	[operationno] [int] NULL,
	[description] [nvarchar](100) NULL,
	[machineid] [nvarchar](50) NULL,
	[price] [float] NULL,
	[cycletime] [float] NULL,
	[drawingno] [nvarchar](50) NULL,
	[InterfaceID] [nvarchar](4) NULL,
	[slno] [bigint] IDENTITY(1,1) NOT NULL,
	[loadunload] [bigint] NULL,
	[machiningtime] [float] NULL,
	[SubOperations] [int] NULL,
	[StdSetupTime] [float] NULL,
	[MachiningTimeThreshold] [int] NULL,
	[TargetPercent] [int] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[LowerEnergyThreshold] [float] NULL,
	[UpperEnergyThreshold] [float] NULL,
	[SCIThreshold] [float] NULL,
	[DCLThreshold] [float] NULL,
	[McTimeMonitorLThreshold] [float] NULL,
	[McTimeMonitorUThreshold] [float] NULL,
	[StdDieCloseTime] [float] NULL,
	[StdPouringTime] [float] NULL,
	[StdSolidificationTime] [float] NULL,
	[StdDieOpenTime] [float] NULL,
	[PalletCount] [int] NOT NULL,
	[MinLoadUnloadThreshold] [float] NULL,
	[FinishedOperation] [int] NULL,
	[Process] [nvarchar](max) NULL,
 CONSTRAINT [PK_componentoperationpricing] PRIMARY KEY CLUSTERED 
(
	[slno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [IX_MCO] ON [dbo].[componentoperationpricing]
(
	[machineid] ASC,
	[componentid] ASC,
	[operationno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[componentoperationpricing] ADD  CONSTRAINT [DF_componentoperationpricing_operationno]  DEFAULT ((0)) FOR [operationno]
ALTER TABLE [dbo].[componentoperationpricing] ADD  CONSTRAINT [DF_componentoperationpricing_price]  DEFAULT ((1)) FOR [price]
ALTER TABLE [dbo].[componentoperationpricing] ADD  CONSTRAINT [DF_componentoperationpricing_loadunload]  DEFAULT ((600)) FOR [loadunload]
ALTER TABLE [dbo].[componentoperationpricing] ADD  CONSTRAINT [DF_componentoperationpricing_machiningtime]  DEFAULT ((0)) FOR [machiningtime]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT ((1)) FOR [SubOperations]
ALTER TABLE [dbo].[componentoperationpricing] ADD  CONSTRAINT [DF_componentoperationpricing_test123]  DEFAULT ((0)) FOR [MachiningTimeThreshold]
ALTER TABLE [dbo].[componentoperationpricing] ADD  CONSTRAINT [DF_componentoperationpricing_TargetPercent]  DEFAULT ((100)) FOR [TargetPercent]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT ('pct') FOR [UpdatedBy]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT ((0)) FOR [LowerEnergyThreshold]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT ((0)) FOR [UpperEnergyThreshold]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT ((0)) FOR [StdDieCloseTime]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT ((0)) FOR [StdPouringTime]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT ((0)) FOR [StdSolidificationTime]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT ((0)) FOR [StdDieOpenTime]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT ((0)) FOR [PalletCount]
ALTER TABLE [dbo].[componentoperationpricing] ADD  DEFAULT ((0)) FOR [FinishedOperation]
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

CREATE TRIGGER [dbo].[AfterUpdate_componentoperationpricing_DrawingNo]
ON [dbo].[componentoperationpricing]
AFTER UPDATE
AS
IF UPDATE(DrawingNo)
INSERT INTO DrawingNoAuditDetails(Machineid, ComponentID, OperationNo,InterfaceID,OldDrawingNo,NewDrawingNo,UpdatedBy,UpdatedTS)
SELECT old.machineid, old.componentid,old.operationno,old.InterfaceID,old.drawingno,new.drawingno,new.UpdatedBy,getdate() 
FROM INSERTED new INNER JOIN DELETED OLD ON old.machineid = new.machineid and old.componentid=new.componentid and old.operationno=new.operationno 
where old.drawingno<>new.drawingno

ALTER TABLE [dbo].[componentoperationpricing] ENABLE TRIGGER [AfterUpdate_componentoperationpricing_DrawingNo]
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TRIGGER [dbo].[TR_COP_AUDIT] ON [dbo].[componentoperationpricing] FOR UPDATE
AS

DECLARE @bit INT ,
       @field INT ,
       @maxfield INT ,
       @char INT ,
       @fieldname NVARCHAR(128) ,
       @TableName NVARCHAR(128) ,
       @PKCols NVARCHAR(1000) ,
       @sql NVARCHAR(2000), 
       @UpdateDate NVARCHAR(21) ,
       @UserName NVARCHAR(128) ,
       @Type CHAR(1) ,
       @PKSelect NVARCHAR(1000),
	   @HIPAddr NVARCHAR(128),
	   @HName NVARCHAR(128)

SELECT top 1 @HName=hostname, -- permission changes are required for user tpmClient 
        @HIPAddr=CONVERT(nvarchar(128), client_net_address) 
FROM    sys.sysprocesses AS S
INNER JOIN    sys.dm_exec_connections AS decc ON S.spid = decc.session_id
where decc.session_id = @@SPID
--select @HIPAddr=CONVERT(nvarchar(128), CONNECTIONPROPERTY('client_net_address')) --CONNECTIONPROPERTY not available in SQL server 2005
--select @HIPAddr=CONVERT(nvarchar(128), client_net_address) from sys.dm_exec_connections where session_id=@@SPID

--change @TableName to match the table to be audited. 
SELECT @TableName = 'componentoperationpricing'

-- date and user
SELECT         @UserName = SYSTEM_USER 
SELECT      @UpdateDate = CONVERT (NVARCHAR(30),GETDATE(),126)

-- Action
IF EXISTS (SELECT * FROM inserted)
BEGIN
	SELECT top 1 @UserName=UpdatedBy FROM inserted
       IF EXISTS (SELECT * FROM deleted)
               SELECT @Type = 'U'
       ELSE
               SELECT @Type = 'I'
END
ELSE
       SELECT @Type = 'D'

-- get list of columns
SELECT * INTO #ins FROM inserted
SELECT * INTO #del FROM deleted

-- Get primary key columns for full outer join
SELECT @PKCols = COALESCE(@PKCols + ' and', ' on') 
               + ' i.' + c.COLUMN_NAME + ' = d.' + c.COLUMN_NAME
       FROM    INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,

              INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
       WHERE   pk.TABLE_NAME = @TableName
       AND     CONSTRAINT_TYPE = 'PRIMARY KEY'
       AND     c.TABLE_NAME = pk.TABLE_NAME
       AND     c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME

-- Get primary key select for insert
SELECT @PKSelect = COALESCE(@PKSelect+'+','') 
       + '''' + COLUMN_NAME 
       + ':''+convert(NVARCHAR(100),
coalesce(i.' + COLUMN_NAME +',d.' + COLUMN_NAME + '))+''''' 
       FROM    INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,
               INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
       WHERE   pk.TABLE_NAME = @TableName
       AND     CONSTRAINT_TYPE = 'PRIMARY KEY'
       AND     c.TABLE_NAME = pk.TABLE_NAME
       AND     c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME

IF @PKCols IS NULL
BEGIN
       RAISERROR('no PK on table %s', 16, -1, @TableName)
       RETURN
END

SELECT         @field = 0, 
       @maxfield = MAX(ORDINAL_POSITION) 
       FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @TableName
WHILE @field < @maxfield
BEGIN
       SELECT @field = MIN(ORDINAL_POSITION) 
               FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = @TableName 
               AND ORDINAL_POSITION > @field
       SELECT @bit = (@field - 1 )% 8 + 1
       SELECT @bit = POWER(2,@bit - 1)
       SELECT @char = ((@field - 1) / 8) + 1
       IF SUBSTRING(COLUMNS_UPDATED(),@char, 1) & @bit > 0
                                       OR @Type IN ('I','D')
       BEGIN
               SELECT @fieldname = COLUMN_NAME 
                       FROM INFORMATION_SCHEMA.COLUMNS 
                       WHERE TABLE_NAME = @TableName 
                       AND ORDINAL_POSITION = @field
				IF @fieldname in ('machiningtime', 'cycletime', 'TargetPercent', 'SubOperations') 
				BEGIN
               SELECT @sql = '
insert AuditTrail (    Type, 
               TableName, 
               PK, 
               FieldName, 
               OldValue, 
               NewValue, 
               UpdateDate, 
               UserName,
			   HostIpAddress)
select ''' + @Type + ''',''' 
       + @TableName + ''',' + @PKSelect
       + ',''' + @fieldname + ''''
       + ',convert(NVARCHAR(1000),d.' + @fieldname + ')'
       + ',convert(NVARCHAR(1000),i.' + @fieldname + ')'
       + ',''' + @UpdateDate + ''''
       + ',''' + @HName + ''''
	   + ',''' + @HIPAddr + ''''
       + ' from #ins i full outer join #del d'
       + @PKCols
       + ' where i.' + @fieldname + ' <> d.' + @fieldname 
       + ' or (i.' + @fieldname + ' is null and  d.'
                                + @fieldname
                                + ' is not null)' 
       + ' or (i.' + @fieldname + ' is not null and  d.' 
                                + @fieldname
                                + ' is null)' 
               EXEC (@sql)
			   END 
       END
END


ALTER TABLE [dbo].[componentoperationpricing] ENABLE TRIGGER [TR_COP_AUDIT]
