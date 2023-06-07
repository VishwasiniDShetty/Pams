/****** Object:  Table [dbo].[AuditTrail]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[AuditTrail](
	[Type] [char](1) NULL,
	[TableName] [nvarchar](128) NULL,
	[PK] [nvarchar](1000) NULL,
	[FieldName] [nvarchar](128) NULL,
	[OldValue] [nvarchar](1000) NULL,
	[NewValue] [nvarchar](1000) NULL,
	[UpdateDate] [datetime] NULL,
	[UserName] [nvarchar](128) NULL,
	[HostIpAddress] [nvarchar](128) NULL
) ON [PRIMARY]
