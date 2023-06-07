/****** Object:  Table [dbo].[componentinformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[componentinformation](
	[componentid] [nvarchar](50) NOT NULL,
	[description] [nvarchar](100) NULL,
	[customerid] [nvarchar](50) NULL,
	[basicvalue] [float] NULL,
	[InterfaceID] [nvarchar](50) NULL,
	[InputWeight] [float] NULL,
	[ForegingWeight] [float] NULL,
 CONSTRAINT [PK_componentinformation] PRIMARY KEY CLUSTERED 
(
	[componentid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[componentinformation] ADD  CONSTRAINT [DF_componentinformation_basicvalue]  DEFAULT ((0)) FOR [basicvalue]
