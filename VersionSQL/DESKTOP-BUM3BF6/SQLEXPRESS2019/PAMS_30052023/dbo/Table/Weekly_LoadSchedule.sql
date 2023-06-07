/****** Object:  Table [dbo].[Weekly_LoadSchedule]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Weekly_LoadSchedule](
	[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Fromdate] [datetime] NOT NULL,
	[Todate] [datetime] NOT NULL,
	[Machine] [nvarchar](50) NOT NULL,
	[Component] [nvarchar](50) NOT NULL,
	[Operation] [int] NULL,
	[IdealCount] [int] NULL,
	[JobCardno] [nvarchar](25) NULL,
 CONSTRAINT [PK_Weekly_LoadSchedule] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Weekly_LoadSchedule] UNIQUE NONCLUSTERED 
(
	[Fromdate] ASC,
	[Todate] ASC,
	[Machine] ASC,
	[Component] ASC,
	[Operation] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
