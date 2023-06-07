/****** Object:  Table [dbo].[MachineAlarmInformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineAlarmInformation](
	[AlarmType] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[AlarmCategory] [nvarchar](50) NULL,
	[AlarmNumber] [decimal](18, 2) NULL,
	[AlarmDescription] [nvarchar](100) NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[AlarmNumber_Binary] [decimal](18, 2) NULL
) ON [PRIMARY]
