/****** Object:  Table [dbo].[MaterialRequestDetails_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MaterialRequestDetails_IDM_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[IDMType] [nvarchar](50) NULL,
	[IDMItemType] [nvarchar](50) NULL,
	[RequestFromDepartment] [nvarchar](50) NULL,
	[RequestToDepartment] [nvarchar](50) NULL,
	[RequestedBy] [nvarchar](50) NULL,
	[RequestedQty] [float] NULL,
	[RequestedTS] [datetime] NULL,
	[Remarks] [nvarchar](50) NULL,
	[Size] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL
) ON [PRIMARY]
