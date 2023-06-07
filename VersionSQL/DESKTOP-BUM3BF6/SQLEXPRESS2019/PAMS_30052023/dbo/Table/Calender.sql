/****** Object:  Table [dbo].[Calender]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Calender](
	[WeekDate] [datetime] NOT NULL,
	[WeekNumber] [int] NULL,
	[MonthVal] [int] NULL,
	[YearNo] [int] NULL,
 CONSTRAINT [PK_Calender] PRIMARY KEY CLUSTERED 
(
	[WeekDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
