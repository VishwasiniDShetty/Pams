/****** Object:  Table [dbo].[temp]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[temp](
	[tempid] [nvarchar](50) NOT NULL,
	[noofdays] [int] NULL,
	[noofrecords] [int] NULL,
 CONSTRAINT [PK_temp] PRIMARY KEY CLUSTERED 
(
	[tempid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[temp] ADD  CONSTRAINT [DF_temp_noofdays]  DEFAULT ((0)) FOR [noofdays]
ALTER TABLE [dbo].[temp] ADD  CONSTRAINT [DF_temp_noofrecords]  DEFAULT ((0)) FOR [noofrecords]
