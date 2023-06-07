/****** Object:  Table [dbo].[ProductionCountDetails_KKPillar]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProductionCountDetails_KKPillar](
	[IDD] [bigint] IDENTITY(1,1) NOT NULL,
	[Mc] [nvarchar](50) NULL,
	[Comp] [nvarchar](50) NULL,
	[Opn] [nvarchar](50) NULL,
	[Opr] [nvarchar](50) NULL,
	[WorkOrderNo] [nvarchar](100) NULL,
	[PartCount] [float] NULL,
	[Date] [datetime] NULL,
	[Shift] [nvarchar](50) NULL
) ON [PRIMARY]
