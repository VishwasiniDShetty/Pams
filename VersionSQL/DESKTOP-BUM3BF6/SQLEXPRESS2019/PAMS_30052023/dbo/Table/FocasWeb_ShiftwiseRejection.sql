/****** Object:  Table [dbo].[FocasWeb_ShiftwiseRejection]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FocasWeb_ShiftwiseRejection](
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[Date] [datetime] NULL,
	[ShiftID] [int] NULL,
	[Shift] [nvarchar](50) NULL,
	[Rejection_Freq] [int] NULL,
	[Rejection_Qty] [int] NULL,
	[Rejection_Reason] [nvarchar](150) NULL,
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[FocasWeb_ShiftwiseRejection] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
