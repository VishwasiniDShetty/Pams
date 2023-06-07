/****** Object:  Table [dbo].[PM_Information]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PM_Information](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Category] [nvarchar](50) NOT NULL,
	[SubCategory] [nvarchar](50) NULL,
	[SubCategoryID] [int] NOT NULL,
	[Frequency] [nvarchar](50) NULL,
	[MachineType] [nvarchar](50) NULL,
 CONSTRAINT [IX_PM_Information] UNIQUE NONCLUSTERED 
(
	[Category] ASC,
	[SubCategoryID] ASC,
	[MachineType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
