/****** Object:  Table [dbo].[workorderproductiondetail]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[workorderproductiondetail](
	[workorderno] [varchar](50) NULL,
	[productiondate] [smalldatetime] NULL,
	[timefrom] [datetime] NULL,
	[timeto] [datetime] NULL,
	[employeeid] [varchar](50) NULL,
	[production] [float] NULL,
	[rejection] [float] NULL,
	[accepted] [float] NULL,
	[cycletime] [int] NULL,
	[mchrrate] [int] NULL,
	[price] [float] NULL,
	[ctime] [int] NULL,
	[loadunload] [int] NULL,
	[peffy] [float] NULL,
	[turnover] [float] NULL,
	[expectedturnover] [float] NULL,
	[aeffy] [float] NULL,
	[qeffy] [float] NULL,
	[oeffy] [float] NULL,
	[slno] [bigint] IDENTITY(1,1) NOT NULL,
	[productiontime] [int] NULL,
	[tottime] [int] NULL,
	[c1n1] [int] NULL,
 CONSTRAINT [PK_workorderproductiondetail] PRIMARY KEY CLUSTERED 
(
	[slno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_production]  DEFAULT ((0)) FOR [production]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_rejection]  DEFAULT ((0)) FOR [rejection]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_accepted]  DEFAULT ((0)) FOR [accepted]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_cycletime]  DEFAULT ((0)) FOR [cycletime]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_mchrrate]  DEFAULT ((0)) FOR [mchrrate]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_price]  DEFAULT ((0)) FOR [price]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_ctime]  DEFAULT ((0)) FOR [ctime]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_loadunload]  DEFAULT ((0)) FOR [loadunload]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_turnover]  DEFAULT ((0)) FOR [turnover]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_expectedturnover]  DEFAULT ((0)) FOR [expectedturnover]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_aeffy]  DEFAULT ((0)) FOR [aeffy]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_qeffy]  DEFAULT ((0)) FOR [qeffy]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_oeffy0]  DEFAULT ((0)) FOR [oeffy]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_productiontime]  DEFAULT ((0)) FOR [productiontime]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_tottime]  DEFAULT ((0)) FOR [tottime]
ALTER TABLE [dbo].[workorderproductiondetail] ADD  CONSTRAINT [DF_workorderproductiondetail_c1n1]  DEFAULT ((0)) FOR [c1n1]
ALTER TABLE [dbo].[workorderproductiondetail]  WITH NOCHECK ADD  CONSTRAINT [FK_workorderproductiondetail_workorderheader] FOREIGN KEY([workorderno])
REFERENCES [dbo].[workorderheader] ([workorderno])
ON DELETE CASCADE
NOT FOR REPLICATION 
ALTER TABLE [dbo].[workorderproductiondetail] CHECK CONSTRAINT [FK_workorderproductiondetail_workorderheader]
