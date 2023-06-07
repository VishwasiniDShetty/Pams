/****** Object:  Table [dbo].[EventCategoryInformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[EventCategoryInformation](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineId] [nvarchar](50) NOT NULL,
	[AlarmType] [nvarchar](50) NOT NULL,
	[AlarmCategory] [nvarchar](50) NOT NULL,
	[AlarmDescription] [nvarchar](100) NULL,
 CONSTRAINT [PK_Event Category Information] PRIMARY KEY CLUSTERED 
(
	[MachineId] ASC,
	[AlarmType] ASC,
	[AlarmCategory] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
