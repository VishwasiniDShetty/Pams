/****** Object:  Table [dbo].[Focas_UserDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_UserDetails](
	[InsertID] [int] IDENTITY(1,1) NOT NULL,
	[UserDetails] [nvarchar](100) NULL,
	[date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[InsertID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[Focas_UserDetails] ADD  DEFAULT (getdate()) FOR [date]
