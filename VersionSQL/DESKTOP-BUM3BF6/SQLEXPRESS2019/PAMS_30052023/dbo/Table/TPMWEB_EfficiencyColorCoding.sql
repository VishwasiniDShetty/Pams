/****** Object:  Table [dbo].[TPMWEB_EfficiencyColorCoding]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[TPMWEB_EfficiencyColorCoding](
	[Type] [nvarchar](50) NOT NULL,
	[PEGreen] [bigint] NOT NULL,
	[AEGreen] [bigint] NOT NULL,
	[OEEGreen] [bigint] NOT NULL,
	[QEGreen] [bigint] NOT NULL,
	[PERed] [bigint] NOT NULL,
	[AERed] [bigint] NOT NULL,
	[OEERed] [bigint] NOT NULL,
	[QERed] [bigint] NOT NULL
) ON [PRIMARY]
