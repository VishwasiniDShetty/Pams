/****** Object:  Table [dbo].[rbar]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[rbar](
	[ucl] [float] NULL,
	[lcl] [float] NULL,
	[mean] [float] NULL,
	[r] [float] NULL,
	[slno] [int] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[rbar] ADD  CONSTRAINT [DF_rbar_ucl]  DEFAULT ((0)) FOR [ucl]
ALTER TABLE [dbo].[rbar] ADD  CONSTRAINT [DF_rbar_lcl]  DEFAULT ((0)) FOR [lcl]
ALTER TABLE [dbo].[rbar] ADD  CONSTRAINT [DF_rbar_mean]  DEFAULT ((0)) FOR [mean]
ALTER TABLE [dbo].[rbar] ADD  CONSTRAINT [DF_rbar_r]  DEFAULT ((0)) FOR [r]
ALTER TABLE [dbo].[rbar] ADD  CONSTRAINT [DF_rbar_slno]  DEFAULT ((0)) FOR [slno]
