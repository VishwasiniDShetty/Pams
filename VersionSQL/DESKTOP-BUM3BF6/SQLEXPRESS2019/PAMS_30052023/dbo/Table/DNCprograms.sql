/****** Object:  Table [dbo].[DNCprograms]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DNCprograms](
	[ProgramFileName] [nvarchar](50) NOT NULL,
	[CAMshaftNo] [nvarchar](50) NULL,
	[NoOfCAMs] [int] NULL,
	[NoOfEccentricity] [int] NULL,
	[EccentricityNo] [nvarchar](50) NULL,
	[Cylinder] [nvarchar](50) NULL,
	[Customer] [nvarchar](50) NULL,
	[CAMangle] [smallint] NULL,
 CONSTRAINT [PK_DNCprograms] PRIMARY KEY CLUSTERED 
(
	[ProgramFileName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
