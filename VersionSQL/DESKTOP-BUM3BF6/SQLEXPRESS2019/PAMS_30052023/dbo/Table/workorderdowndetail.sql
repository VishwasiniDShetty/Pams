/****** Object:  Table [dbo].[workorderdowndetail]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[workorderdowndetail](
	[slno] [bigint] IDENTITY(1,1) NOT NULL,
	[WorkOrderNo] [nvarchar](50) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[ComponentID] [nvarchar](50) NOT NULL,
	[downcode] [nvarchar](50) NULL,
	[Downfromdate] [smalldatetime] NULL,
	[FromTime] [smalldatetime] NULL,
	[ToTime] [smalldatetime] NULL,
	[downtodate] [smalldatetime] NULL,
	[TotalDown] [int] NULL,
	[mchrrate] [int] NULL,
 CONSTRAINT [PK_workorderdowndetail] PRIMARY KEY CLUSTERED 
(
	[slno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[workorderdowndetail] ADD  CONSTRAINT [DF_workorderdowndetail_TotalDown]  DEFAULT ((0)) FOR [TotalDown]
ALTER TABLE [dbo].[workorderdowndetail] ADD  CONSTRAINT [DF_workorderdowndetail_mchrrate]  DEFAULT ((0)) FOR [mchrrate]
