/****** Object:  Table [dbo].[AutodataRejections]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[AutodataRejections](
	[mc] [nvarchar](50) NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[Rejection_Code] [nvarchar](50) NULL,
	[Rejection_Qty] [int] NULL,
	[CreatedTS] [datetime] NULL,
	[RejDate] [datetime] NULL,
	[RejShift] [nvarchar](15) NULL,
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[recordid] [bigint] NOT NULL,
	[Flag] [nvarchar](20) NULL,
	[WorkOrderNumber] [nvarchar](50) NULL,
	[RejectionType] [nvarchar](50) NULL
) ON [PRIMARY]
