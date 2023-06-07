/****** Object:  Table [dbo].[DCGateExitDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DCGateExitDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Vendor] [nvarchar](50) NULL,
	[PamsDCNumber] [nvarchar](50) NULL,
	[VehicleNumber] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[DriverPhoneNumber] [nvarchar](500) NULL,
	[SecurityName] [nvarchar](50) NULL,
	[DriverName] [nvarchar](50) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-124256] ON [dbo].[DCGateExitDetails_PAMS]
(
	[Vendor] ASC,
	[PamsDCNumber] ASC,
	[VehicleNumber] ASC,
	[UpdatedTS] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[DCGateExitDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
