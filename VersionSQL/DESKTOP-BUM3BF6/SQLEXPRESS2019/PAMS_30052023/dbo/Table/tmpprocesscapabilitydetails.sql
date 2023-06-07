/****** Object:  Table [dbo].[tmpprocesscapabilitydetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[tmpprocesscapabilitydetails](
	[slno] [int] NULL,
	[measuredvalue] [float] NULL,
	[sln] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_tmpprocesscapabilitydetails] PRIMARY KEY CLUSTERED 
(
	[sln] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[tmpprocesscapabilitydetails] ADD  CONSTRAINT [DF_tmpprocesscapabilitydetails_slno]  DEFAULT ((0)) FOR [slno]
ALTER TABLE [dbo].[tmpprocesscapabilitydetails] ADD  CONSTRAINT [DF_tmpprocesscapabilitydetails_measuredvalue]  DEFAULT ((0)) FOR [measuredvalue]
