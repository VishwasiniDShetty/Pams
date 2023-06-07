/****** Object:  Table [dbo].[Focas_ParametersToReadOPCUA]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_ParametersToReadOPCUA](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Parameter] [nvarchar](100) NOT NULL,
	[NodeId] [nvarchar](100) NOT NULL,
	[IsEnabled] [bit] NULL,
	[Feature] [nvarchar](50) NULL
) ON [PRIMARY]
