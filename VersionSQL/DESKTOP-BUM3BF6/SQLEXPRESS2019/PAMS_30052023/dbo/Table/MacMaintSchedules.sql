/****** Object:  Table [dbo].[MacMaintSchedules]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MacMaintSchedules](
	[ActivityID] [int] IDENTITY(1,1) NOT NULL,
	[Machine] [nvarchar](50) NULL,
	[SubSystem] [nvarchar](1000) NULL,
	[PartNo] [nvarchar](2000) NULL,
	[ImagePath] [nvarchar](2000) NULL,
	[Activity] [nvarchar](50) NULL,
	[Standard] [nvarchar](2000) NULL,
	[Frequency] [nvarchar](50) NULL,
	[Date] [datetime] NULL,
	[Shift] [nvarchar](50) NULL,
	[TimeStamp] [datetime] NULL,
	[Shift1] [bit] NULL,
	[Shift2] [bit] NULL,
	[Shift3] [bit] NULL,
	[Day] [bit] NULL,
	[Week] [bit] NULL,
	[Month] [bit] NULL,
	[ImageNotes] [nvarchar](3000) NULL,
 CONSTRAINT [PK_MacMaintSchedules] PRIMARY KEY CLUSTERED 
(
	[ActivityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
