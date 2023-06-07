/****** Object:  Table [dbo].[machineserviceinformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[machineserviceinformation](
	[machineid] [nvarchar](50) NOT NULL,
	[servicedby] [nvarchar](100) NULL,
	[address1] [nvarchar](100) NULL,
	[address2] [nvarchar](100) NULL,
	[place] [nvarchar](100) NULL,
	[phone] [nvarchar](100) NULL,
	[contactperson] [nvarchar](100) NULL,
 CONSTRAINT [PK_machineserviceinformation] PRIMARY KEY CLUSTERED 
(
	[machineid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
