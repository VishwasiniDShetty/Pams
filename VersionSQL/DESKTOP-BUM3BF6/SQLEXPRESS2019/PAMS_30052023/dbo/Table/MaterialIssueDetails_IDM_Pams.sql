/****** Object:  Table [dbo].[MaterialIssueDetails_IDM_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MaterialIssueDetails_IDM_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[IDMType] [nvarchar](50) NULL,
	[IDMItemType] [nvarchar](50) NULL,
	[RequestFromDepartment] [nvarchar](50) NULL,
	[RequestToDepartment] [nvarchar](50) NULL,
	[RequestedBy] [nvarchar](50) NULL,
	[RequestedQty] [float] NULL,
	[RequestedTS] [datetime] NULL,
	[IssuedQty] [float] NULL,
	[IssuedBy] [nvarchar](50) NULL,
	[IssuedTS] [datetime] NULL,
	[IssuedLocation] [nvarchar](50) NULL,
	[IssuedRemarks] [nvarchar](max) NULL,
	[IssuedStatus] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
