/****** Object:  Table [dbo].[ReworkReasonDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ReworkReasonDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ReworkCode] [nvarchar](50) NULL,
	[ReworkReason] [nvarchar](200) NULL
) ON [PRIMARY]
