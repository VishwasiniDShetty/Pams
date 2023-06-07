/****** Object:  Table [dbo].[DrawingNoAuditDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DrawingNoAuditDetails](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Machineid] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[InterfaceID] [nvarchar](50) NULL,
	[OldDrawingNo] [nvarchar](50) NULL,
	[NewDrawingNo] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[DrawingNoAuditDetails] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
