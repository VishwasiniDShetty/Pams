/****** Object:  Table [dbo].[downcodeinformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[downcodeinformation](
	[downid] [nvarchar](50) NULL,
	[downno] [int] IDENTITY(1,1) NOT NULL,
	[downdescription] [nvarchar](100) NULL,
	[Catagory] [nvarchar](50) NULL,
	[interfaceid] [nvarchar](50) NULL,
	[availeffy] [smallint] NULL,
	[retpermchour] [smallint] NULL,
	[Threshold] [numeric](18, 0) NULL,
	[prodeffy] [smallint] NULL,
	[ThresholdfromCO] [int] NOT NULL,
	[SortOrder] [int] NULL,
	[Group1] [nvarchar](50) NULL,
	[Group2] [nvarchar](50) NULL,
	[Owner] [nvarchar](500) NULL,
 CONSTRAINT [PK_downcodeinformation] PRIMARY KEY CLUSTERED 
(
	[downno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [IX_DownID] ON [dbo].[downcodeinformation]
(
	[downid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[downcodeinformation] ADD  CONSTRAINT [DF_downcodeinformation_availeffy]  DEFAULT ((0)) FOR [availeffy]
ALTER TABLE [dbo].[downcodeinformation] ADD  CONSTRAINT [DF_downcodeinformation_retpermchour]  DEFAULT ((0)) FOR [retpermchour]
ALTER TABLE [dbo].[downcodeinformation] ADD  DEFAULT ((0)) FOR [prodeffy]
ALTER TABLE [dbo].[downcodeinformation] ADD  DEFAULT ('0') FOR [ThresholdfromCO]
ALTER TABLE [dbo].[downcodeinformation]  WITH NOCHECK ADD  CONSTRAINT [FK_downcodeinformation_DownCategoryInformation] FOREIGN KEY([Catagory])
REFERENCES [dbo].[DownCategoryInformation] ([DownCategory])
ALTER TABLE [dbo].[downcodeinformation] CHECK CONSTRAINT [FK_downcodeinformation_DownCategoryInformation]
