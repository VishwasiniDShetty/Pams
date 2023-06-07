/****** Object:  Table [dbo].[Aggregate_Error]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Aggregate_Error](
	[SLID] [int] IDENTITY(1,1) NOT NULL,
	[ErrNo] [int] NULL,
	[Machineid] [varchar](500) NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[Remarks] [nvarchar](100) NULL
) ON [PRIMARY]
