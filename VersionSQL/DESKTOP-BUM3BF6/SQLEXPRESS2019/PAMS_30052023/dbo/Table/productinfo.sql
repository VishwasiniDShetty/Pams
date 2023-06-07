/****** Object:  Table [dbo].[productinfo]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[productinfo](
	[pc_serial_number] [nvarchar](250) NOT NULL,
	[productkey] [nvarchar](250) NULL,
	[productpassword] [nvarchar](250) NULL,
	[Type] [nvarchar](50) NOT NULL,
	[LogDate] [datetime] NULL,
	[EvalPeriod] [int] NULL,
 CONSTRAINT [PK_productinfo] PRIMARY KEY CLUSTERED 
(
	[pc_serial_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[productinfo] ADD  CONSTRAINT [DF_productinfo_Type]  DEFAULT (N'Standard') FOR [Type]
