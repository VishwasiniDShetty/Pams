/****** Object:  Table [dbo].[BOSCH_FlowMeter_Details]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[BOSCH_FlowMeter_Details](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[Starttime] [datetime] NULL,
	[Endtime] [datetime] NULL,
	[FlowValue1] [decimal](18, 0) NULL,
	[Result1] [nvarchar](50) NULL,
	[FlowValue2] [decimal](18, 0) NULL,
	[Result2] [nvarchar](50) NULL,
	[ShiftName] [nvarchar](50) NULL,
	[ShiftID] [nvarchar](50) NULL
) ON [PRIMARY]
