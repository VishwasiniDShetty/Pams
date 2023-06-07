/****** Object:  Table [dbo].[customerinformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[customerinformation](
	[customerid] [nvarchar](50) NOT NULL,
	[customername] [nvarchar](100) NULL,
	[address1] [nvarchar](100) NULL,
	[place] [nvarchar](100) NULL,
	[state] [nvarchar](100) NULL,
	[country] [nvarchar](100) NULL,
	[pin] [nvarchar](100) NULL,
	[phone] [nvarchar](100) NULL,
	[email] [nvarchar](100) NULL,
	[contactperson] [nvarchar](100) NULL,
	[address2] [nvarchar](50) NULL,
 CONSTRAINT [PK_customerinformation] PRIMARY KEY CLUSTERED 
(
	[customerid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
