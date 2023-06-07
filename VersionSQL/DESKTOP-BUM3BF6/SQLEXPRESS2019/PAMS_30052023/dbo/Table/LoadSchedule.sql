/****** Object:  Table [dbo].[LoadSchedule]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[LoadSchedule](
	[Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[date] [datetime] NOT NULL,
	[Shift] [nvarchar](50) NOT NULL,
	[Machine] [nvarchar](50) NOT NULL,
	[Component] [nvarchar](50) NOT NULL,
	[Operation] [int] NULL,
	[IdealCount] [int] NULL,
	[JobCardno] [nvarchar](25) NULL,
	[PDT] [int] NULL,
	[StdCycleTime] [float] NULL,
	[ShiftTarget] [float] NULL,
 CONSTRAINT [PK_LoadSchedule] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_LoadSchedule] UNIQUE NONCLUSTERED 
(
	[date] ASC,
	[Shift] ASC,
	[Machine] ASC,
	[Component] ASC,
	[Operation] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
