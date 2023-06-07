/****** Object:  Table [dbo].[FocasWeb_DownFreq]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FocasWeb_DownFreq](
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[DownID] [nvarchar](50) NULL,
	[DownReason] [nvarchar](50) NULL,
	[DownFreq] [int] NULL,
	[Date] [datetime] NULL,
	[ShiftID] [int] NULL,
	[Shift] [nvarchar](50) NULL,
	[Downtime] [float] NULL
) ON [PRIMARY]
