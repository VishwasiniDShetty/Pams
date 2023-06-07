/****** Object:  Table [dbo].[AutoDataAlarms]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[AutoDataAlarms](
	[MachineID] [nvarchar](10) NULL,
	[AlarmNumber] [decimal](18, 2) NULL,
	[Alarmtime] [datetime] NULL,
	[RecordType] [tinyint] NULL,
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Target] [int] NULL,
	[Actual] [int] NULL,
	[ComponentID] [nvarchar](100) NULL,
	[OperationID] [nvarchar](50) NULL,
 CONSTRAINT [PK_MachineAlarms] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
