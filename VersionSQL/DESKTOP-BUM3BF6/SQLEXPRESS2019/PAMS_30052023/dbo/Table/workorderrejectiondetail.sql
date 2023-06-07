/****** Object:  Table [dbo].[workorderrejectiondetail]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[workorderrejectiondetail](
	[workorderno] [nvarchar](50) NULL,
	[rejectiondate] [smalldatetime] NULL,
	[employeeid] [nvarchar](50) NULL,
	[rejectionid] [nvarchar](50) NULL,
	[quantity] [float] NULL,
	[slno] [bigint] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_workorderrejectiondetail] PRIMARY KEY CLUSTERED 
(
	[slno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[workorderrejectiondetail] ADD  CONSTRAINT [DF_workorderrejectiondetail_quantity]  DEFAULT ((0)) FOR [quantity]
