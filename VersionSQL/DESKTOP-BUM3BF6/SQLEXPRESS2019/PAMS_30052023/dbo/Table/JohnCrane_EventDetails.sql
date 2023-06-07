/****** Object:  Table [dbo].[JohnCrane_EventDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[JohnCrane_EventDetails](
	[SlNo] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[WorkOrderNo] [nvarchar](50) NULL,
	[EventID] [int] NULL,
	[Quantity] [int] NULL,
	[EventTS] [datetime] NULL,
	[EventDate] [datetime] NULL
) ON [PRIMARY]
