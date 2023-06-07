/****** Object:  Table [dbo].[machinemakeinformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[machinemakeinformation](
	[machineid] [nvarchar](50) NOT NULL,
	[manufacturer] [nvarchar](100) NULL,
	[dateofmanufacture] [smalldatetime] NULL,
	[address] [nvarchar](100) NULL,
	[place] [nvarchar](100) NULL,
	[phone] [nvarchar](50) NULL,
	[contactperson] [nvarchar](100) NULL,
 CONSTRAINT [PK_machinemakeinformation] PRIMARY KEY CLUSTERED 
(
	[machineid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
