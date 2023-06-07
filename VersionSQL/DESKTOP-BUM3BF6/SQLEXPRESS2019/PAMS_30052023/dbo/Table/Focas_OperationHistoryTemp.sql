/****** Object:  Table [dbo].[Focas_OperationHistoryTemp]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_OperationHistoryTemp](
	[OperationType] [nvarchar](500) NULL,
	[OperationValue] [nvarchar](1000) NULL,
	[ODateTime] [nvarchar](100) NULL,
	[MachineID] [nvarchar](50) NULL
) ON [PRIMARY]
