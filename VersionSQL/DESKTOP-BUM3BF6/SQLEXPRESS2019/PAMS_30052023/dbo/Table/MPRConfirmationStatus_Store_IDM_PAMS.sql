/****** Object:  Table [dbo].[MPRConfirmationStatus_Store_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MPRConfirmationStatus_Store_IDM_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[MPRNo] [nvarchar](50) NULL,
	[ConfirmedBy] [nvarchar](50) NULL,
	[ConfirmedTS] [datetime] NULL,
	[ConfirmationStatus] [nvarchar](100) NULL
) ON [PRIMARY]
