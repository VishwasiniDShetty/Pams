/****** Object:  Table [dbo].[ActivityMasterYearlyData_MGTL]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ActivityMasterYearlyData_MGTL](
	[ActivityID] [int] NOT NULL,
	[Activity] [nvarchar](100) NULL,
	[FreqID] [int] NULL,
	[ActivityDate] [datetime] NULL,
	[year] [int] NULL,
	[MachineID] [nvarchar](50) NULL
) ON [PRIMARY]
