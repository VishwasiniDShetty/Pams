/****** Object:  Table [dbo].[MachineWisePlnQtyDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineWisePlnQtyDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Year] [nvarchar](4) NULL,
	[MonthValue] [nvarchar](4) NULL,
	[WeekNumber] [nvarchar](4) NULL,
	[Date] [datetime] NULL,
	[MachineID] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[Operationno] [nvarchar](50) NULL,
	[PlanQty] [float] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Remarks] [nvarchar](max) NULL,
	[GrindingWheelDressingFrequency] [float] NULL,
	[GrindingWheelDressingTime] [float] NULL,
	[RegulatingDressingTimeInMin] [float] NULL,
	[ScheduledDates] [nvarchar](max) NULL,
	[Total_Time_Required_Hrs] [float] NULL,
	[Total_Time_RequiredPerDay_Hrs] [float] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-141927] ON [dbo].[MachineWisePlnQtyDetails_PAMS]
(
	[Year] ASC,
	[MonthValue] ASC,
	[WeekNumber] ASC,
	[Date] ASC,
	[MachineID] ASC,
	[PartID] ASC,
	[Operationno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[MachineWisePlnQtyDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
