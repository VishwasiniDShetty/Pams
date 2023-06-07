/****** Object:  Table [dbo].[tcs_energyconsumption_maxgtime]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[tcs_energyconsumption_maxgtime](
	[machine] [nvarchar](50) NULL,
	[maxgtime] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[tcs_energyconsumption_maxgtime] ADD  DEFAULT ('1900-01-01') FOR [maxgtime]
