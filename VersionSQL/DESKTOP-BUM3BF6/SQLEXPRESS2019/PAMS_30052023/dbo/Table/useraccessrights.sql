/****** Object:  Table [dbo].[useraccessrights]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[useraccessrights](
	[employeeid] [nvarchar](25) NULL,
	[domain] [nvarchar](50) NULL,
	[type] [nvarchar](50) NULL,
	[slno] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_useraccessrights] PRIMARY KEY CLUSTERED 
(
	[slno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
