/****** Object:  Table [dbo].[Focas_downcodeInformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_downcodeInformation](
	[downid] [nvarchar](50) NULL,
	[downcode] [int] IDENTITY(1,1) NOT NULL,
	[downdescription] [nvarchar](100) NULL,
	[interfaceid] [nvarchar](50) NULL,
 CONSTRAINT [PK_downcodeDetails] PRIMARY KEY CLUSTERED 
(
	[downcode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
