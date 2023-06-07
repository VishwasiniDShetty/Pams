/****** Object:  Table [dbo].[Reworkinformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Reworkinformation](
	[Reworkid] [nvarchar](50) NULL,
	[Reworkno] [int] IDENTITY(1,1) NOT NULL,
	[Reworkdescription] [nvarchar](100) NULL,
	[ReworkCatagory] [nvarchar](50) NULL,
	[Reworkinterfaceid] [nvarchar](50) NULL
) ON [PRIMARY]
