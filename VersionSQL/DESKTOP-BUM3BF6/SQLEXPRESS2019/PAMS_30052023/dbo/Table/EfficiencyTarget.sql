/****** Object:  Table [dbo].[EfficiencyTarget]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[EfficiencyTarget](
	[MachineID] [nvarchar](50) NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[AE] [smallint] NULL,
	[PE] [smallint] NULL,
	[QE] [smallint] NULL,
	[OE] [smallint] NULL,
	[LogicalDayStart] [datetime] NULL,
	[LogicalDayEnd] [datetime] NULL,
	[TargetLevel] [char](10) NOT NULL,
 CONSTRAINT [PK_EfficiencyTarget_1] PRIMARY KEY CLUSTERED 
(
	[MachineID] ASC,
	[StartDate] ASC,
	[EndDate] ASC,
	[TargetLevel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[EfficiencyTarget]  WITH CHECK ADD  CONSTRAINT [FK_EfficiencyTarget_machineinformation] FOREIGN KEY([MachineID])
REFERENCES [dbo].[machineinformation] ([machineid])
ALTER TABLE [dbo].[EfficiencyTarget] CHECK CONSTRAINT [FK_EfficiencyTarget_machineinformation]
