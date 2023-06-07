/****** Object:  Table [dbo].[EWayBillDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[EWayBillDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Pams_DCNo] [nvarchar](50) NULL,
	[RequestDepartment] [nvarchar](50) NULL,
	[RequestNo] [nvarchar](50) NULL,
	[RequestedBy] [nvarchar](50) NULL,
	[VehicleNo] [nvarchar](50) NULL,
	[NatureOfTransport] [nvarchar](50) NULL,
	[ValidUpTo] [nvarchar](50) NULL,
	[PreparedBy] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[EwayBillNo] [nvarchar](50) NULL,
	[Value] [float] NULL,
	[DCStatus] [nvarchar](50) NULL,
	[AccountsUpdatedBy] [nvarchar](50) NULL,
	[AccountsUpdatedTS] [datetime] NULL,
	[AccountSatus] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[EWayBillDetails_Pams] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
