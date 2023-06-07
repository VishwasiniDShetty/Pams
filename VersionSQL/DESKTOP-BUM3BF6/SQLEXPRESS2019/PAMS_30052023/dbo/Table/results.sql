/****** Object:  Table [dbo].[results]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[results](
	[pp] [float] NULL,
	[ppk] [float] NULL,
	[cp] [float] NULL,
	[cpk] [float] NULL,
	[s1] [float] NULL,
	[s2] [float] NULL,
	[avgucl] [float] NULL,
	[avglcl] [float] NULL,
	[rngucl] [float] NULL,
	[rnglcl] [float] NULL,
	[rbar] [float] NULL,
	[xdbar] [float] NULL,
	[result] [nvarchar](30) NULL,
	[lsl] [float] NULL,
	[usl] [float] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_pp]  DEFAULT ((0)) FOR [pp]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_ppk]  DEFAULT ((0)) FOR [ppk]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_cp]  DEFAULT ((0)) FOR [cp]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_cpk]  DEFAULT ((0)) FOR [cpk]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_s1]  DEFAULT ((0)) FOR [s1]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_s2]  DEFAULT ((0)) FOR [s2]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_avgucl]  DEFAULT ((0)) FOR [avgucl]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_avglcl]  DEFAULT ((0)) FOR [avglcl]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_rngucl]  DEFAULT ((0)) FOR [rngucl]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_rnglcl]  DEFAULT ((0)) FOR [rnglcl]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_rbar]  DEFAULT ((0)) FOR [rbar]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_xdbar]  DEFAULT ((0)) FOR [xdbar]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_lsl]  DEFAULT ((0)) FOR [lsl]
ALTER TABLE [dbo].[results] ADD  CONSTRAINT [DF_results_usl]  DEFAULT ((0)) FOR [usl]
