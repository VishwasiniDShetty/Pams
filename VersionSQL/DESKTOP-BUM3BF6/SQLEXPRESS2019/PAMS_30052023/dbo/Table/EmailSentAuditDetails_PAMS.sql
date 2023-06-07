/****** Object:  Table [dbo].[EmailSentAuditDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[EmailSentAuditDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Type] [nvarchar](50) NULL,
	[EmailTo] [nvarchar](max) NULL,
	[Remarks] [nvarchar](2000) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[EmailSubject] [nvarchar](max) NULL,
	[EmailBody] [nvarchar](max) NULL,
	[EmailCC] [nvarchar](max) NULL,
	[FilePath] [nvarchar](max) NULL,
	[FileName] [nvarchar](50) NULL,
	[Status] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[EmailSentAuditDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[EmailSentAuditDetails_PAMS] ADD  DEFAULT ((0)) FOR [Status]
