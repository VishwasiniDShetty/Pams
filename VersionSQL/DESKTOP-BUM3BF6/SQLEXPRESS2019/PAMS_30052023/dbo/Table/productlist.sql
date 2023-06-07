/****** Object:  Table [dbo].[productlist]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[productlist](
	[product] [nvarchar](50) NOT NULL,
	[isevaluation] [smallint] NULL,
	[ispermnant] [smallint] NULL,
	[pc_serial_number] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_productlist] PRIMARY KEY CLUSTERED 
(
	[product] ASC,
	[pc_serial_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[productlist] ADD  CONSTRAINT [DF_productlist_isevaluation]  DEFAULT ((0)) FOR [isevaluation]
ALTER TABLE [dbo].[productlist] ADD  CONSTRAINT [DF_productlist_ispermnant]  DEFAULT ((0)) FOR [ispermnant]
