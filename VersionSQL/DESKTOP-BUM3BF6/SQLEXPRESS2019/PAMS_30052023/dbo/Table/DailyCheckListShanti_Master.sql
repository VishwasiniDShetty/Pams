/****** Object:  Table [dbo].[DailyCheckListShanti_Master]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DailyCheckListShanti_Master](
	[SlNO] [int] NOT NULL,
	[Activity] [nvarchar](500) NOT NULL,
 CONSTRAINT [PK_DailyCheckListShanti_Master_SlNO] PRIMARY KEY CLUSTERED 
(
	[SlNO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
