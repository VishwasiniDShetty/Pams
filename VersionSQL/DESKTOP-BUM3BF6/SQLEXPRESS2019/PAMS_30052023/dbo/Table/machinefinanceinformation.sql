/****** Object:  Table [dbo].[machinefinanceinformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[machinefinanceinformation](
	[machineid] [nvarchar](50) NOT NULL,
	[machineprice] [float] NULL,
	[financedby] [nvarchar](100) NULL,
	[address] [nvarchar](100) NULL,
	[repaymentfrom] [smalldatetime] NULL,
	[to] [smalldatetime] NULL,
	[installmentamount] [float] NULL,
	[noofinstallments] [int] NULL,
	[contactperson] [nvarchar](100) NULL,
 CONSTRAINT [PK_machinefinanceinformation] PRIMARY KEY CLUSTERED 
(
	[machineid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[machinefinanceinformation] ADD  CONSTRAINT [DF_machinefinanceinformation_machineprice]  DEFAULT ((0)) FOR [machineprice]
ALTER TABLE [dbo].[machinefinanceinformation] ADD  CONSTRAINT [DF_machinefinanceinformation_installmentamount]  DEFAULT ((0)) FOR [installmentamount]
ALTER TABLE [dbo].[machinefinanceinformation] ADD  CONSTRAINT [DF_machinefinanceinformation_noofinstallments]  DEFAULT ((0)) FOR [noofinstallments]
