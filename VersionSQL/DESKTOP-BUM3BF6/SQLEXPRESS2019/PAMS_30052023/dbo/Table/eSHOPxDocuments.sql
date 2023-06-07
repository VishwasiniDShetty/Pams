/****** Object:  Table [dbo].[eSHOPxDocuments]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[eSHOPxDocuments](
	[machineid] [nvarchar](50) NOT NULL,
	[Componentid] [nvarchar](50) NOT NULL,
	[OperationNo] [smallint] NULL,
	[DocumentType] [nvarchar](4000) NULL,
	[DocumentPath] [nvarchar](500) NULL,
	[DocumentName] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[Updated_TS] [smalldatetime] NULL
) ON [PRIMARY]
