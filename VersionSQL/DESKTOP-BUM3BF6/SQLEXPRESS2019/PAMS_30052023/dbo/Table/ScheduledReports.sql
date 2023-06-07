/****** Object:  Table [dbo].[ScheduledReports]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ScheduledReports](
	[ReportID] [int] NULL,
	[ReportName] [nvarchar](100) NULL,
	[ReportFileName] [nvarchar](100) NULL,
	[ExportType] [nvarchar](100) NULL,
	[ExportFileName] [nvarchar](100) NULL,
	[ExportPath] [nvarchar](100) NULL,
	[DayBefores] [int] NULL,
	[Machine] [nvarchar](100) NULL,
	[Shift] [nvarchar](100) NULL,
	[Operator] [nvarchar](100) NULL,
	[EmailList] [nvarchar](255) NULL,
	[ScheTime] [nvarchar](100) NULL,
	[RunHistory] [smalldatetime] NULL,
	[Slno] [int] IDENTITY(1,1) NOT NULL,
	[PlantID] [nvarchar](50) NULL,
	[Email_Flag] [bit] NULL,
	[Email_List_TO] [nvarchar](4000) NULL,
	[Email_List_CC] [nvarchar](4000) NULL,
	[Email_List_BCC] [nvarchar](4000) NULL,
	[RunReportForEvery] [nvarchar](10) NULL,
	[GroupID] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ScheduledReports] ADD  CONSTRAINT [DF_ScheduledReports_ExportPath]  DEFAULT (N'C:\') FOR [ExportPath]
ALTER TABLE [dbo].[ScheduledReports] ADD  CONSTRAINT [DF_ScheduledReports_DayBefores]  DEFAULT ((1)) FOR [DayBefores]
ALTER TABLE [dbo].[ScheduledReports] ADD  CONSTRAINT [DF_ScheduledReports_runreportforevery]  DEFAULT (N'Day') FOR [RunReportForEvery]
