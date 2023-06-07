/****** Object:  Table [dbo].[processcapabilityheader]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[processcapabilityheader](
	[testid] [nvarchar](50) NOT NULL,
	[testdate] [datetime] NULL,
	[customerid] [nvarchar](50) NULL,
	[componentid] [nvarchar](50) NULL,
	[parameter] [nvarchar](100) NULL,
	[instrument] [nvarchar](100) NULL,
	[machineid] [nvarchar](50) NULL,
	[employeeid] [nvarchar](50) NULL,
	[usl] [float] NULL,
	[lsl] [float] NULL,
	[noofobs] [smallint] NULL,
	[groupsize] [smallint] NULL,
	[histinterval] [smallint] NULL,
	[result] [nvarchar](50) NULL,
	[pp] [float] NULL,
	[ppk] [float] NULL,
	[cp] [float] NULL,
	[cpk] [float] NULL,
	[s1] [float] NULL,
	[s2] [float] NULL,
	[rbar] [float] NULL,
	[xdbar] [float] NULL,
	[avgucl] [float] NULL,
	[avglcl] [float] NULL,
	[rngucl] [float] NULL,
	[rnglcl] [float] NULL,
 CONSTRAINT [PK_processcapabilityheader] PRIMARY KEY CLUSTERED 
(
	[testid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_usl]  DEFAULT ((0)) FOR [usl]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_lsl]  DEFAULT ((0)) FOR [lsl]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_pp]  DEFAULT ((0)) FOR [pp]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_ppk]  DEFAULT ((0)) FOR [ppk]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_cpk]  DEFAULT ((0)) FOR [cpk]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_s1]  DEFAULT ((0)) FOR [s1]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_s2]  DEFAULT ((0)) FOR [s2]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_rbar]  DEFAULT ((0)) FOR [rbar]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_xdbar]  DEFAULT ((0)) FOR [xdbar]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_avgucl]  DEFAULT ((0)) FOR [avgucl]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_avglcl]  DEFAULT ((0)) FOR [avglcl]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_rngucl]  DEFAULT ((0)) FOR [rngucl]
ALTER TABLE [dbo].[processcapabilityheader] ADD  CONSTRAINT [DF_processcapabilityheader_rnglcl]  DEFAULT ((0)) FOR [rnglcl]
