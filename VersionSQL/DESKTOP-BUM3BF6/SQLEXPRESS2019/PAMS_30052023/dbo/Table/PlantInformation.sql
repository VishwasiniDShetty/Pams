/****** Object:  Table [dbo].[PlantInformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PlantInformation](
	[PlantID] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](50) NULL,
	[SlNo] [int] IDENTITY(1,1) NOT NULL,
	[PlantCode] [nvarchar](50) NULL,
 CONSTRAINT [PK_PlantInformation] PRIMARY KEY CLUSTERED 
(
	[PlantID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
