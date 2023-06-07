/****** Object:  Table [dbo].[DNC_OnlineMachineList]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DNC_OnlineMachineList](
	[MachineID] [nvarchar](50) NOT NULL,
	[PortNo] [smallint] NULL,
	[StartTime] [smalldatetime] NULL,
	[Settings] [nvarchar](50) NULL,
	[Status] [nvarchar](50) NULL,
	[ClientPC] [nvarchar](50) NULL,
 CONSTRAINT [PK_DNC_OnlineMachineList] PRIMARY KEY CLUSTERED 
(
	[MachineID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
