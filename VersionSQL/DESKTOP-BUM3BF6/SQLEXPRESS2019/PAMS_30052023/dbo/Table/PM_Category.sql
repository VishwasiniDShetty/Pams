/****** Object:  Table [dbo].[PM_Category]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PM_Category](
	[Category] [nvarchar](50) NOT NULL,
	[InterfaceID] [int] NOT NULL,
 CONSTRAINT [IX_PM_Category] UNIQUE NONCLUSTERED 
(
	[InterfaceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
