/****** Object:  Table [dbo].[machinedailyperformance]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[machinedailyperformance](
	[machineid] [nvarchar](50) NULL,
	[productiondate] [smalldatetime] NULL,
	[turnover] [float] NULL,
	[down] [float] NULL,
	[productioneffy] [float] NULL,
	[availablityeffy] [float] NULL,
	[slno] [int] IDENTITY(1,1) NOT NULL,
	[dailytarget] [float] NULL,
	[financialyear] [nvarchar](50) NULL,
	[ExpectedTurnover] [float] NULL,
 CONSTRAINT [PK_machinedailyperformance] PRIMARY KEY CLUSTERED 
(
	[slno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[machinedailyperformance] ADD  CONSTRAINT [DF_machinedailyperformance_turnover]  DEFAULT ((0)) FOR [turnover]
ALTER TABLE [dbo].[machinedailyperformance] ADD  CONSTRAINT [DF_machinedailyperformance_down]  DEFAULT ((0)) FOR [down]
ALTER TABLE [dbo].[machinedailyperformance] ADD  CONSTRAINT [DF_machinedailyperformance_productioneffy]  DEFAULT ((0)) FOR [productioneffy]
ALTER TABLE [dbo].[machinedailyperformance] ADD  CONSTRAINT [DF_machinedailyperformance_availablityeffy]  DEFAULT ((0)) FOR [availablityeffy]
ALTER TABLE [dbo].[machinedailyperformance] ADD  CONSTRAINT [DF_machinedailyperformance_dailytarget]  DEFAULT ((0)) FOR [dailytarget]
ALTER TABLE [dbo].[machinedailyperformance] ADD  CONSTRAINT [DF_machinedailyperformance_ExpectedTurnover]  DEFAULT ((0)) FOR [ExpectedTurnover]
