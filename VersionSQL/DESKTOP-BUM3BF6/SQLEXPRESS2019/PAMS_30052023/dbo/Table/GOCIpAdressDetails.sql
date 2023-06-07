/****** Object:  Table [dbo].[GOCIpAdressDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[GOCIpAdressDetails](
	[idd] [int] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[GocID] [int] NULL,
	[GocIpAddress] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[SyncedStatus] [smallint] NULL
) ON [PRIMARY]
