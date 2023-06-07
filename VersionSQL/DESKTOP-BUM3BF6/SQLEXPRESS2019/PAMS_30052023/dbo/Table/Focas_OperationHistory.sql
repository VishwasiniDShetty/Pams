/****** Object:  Table [dbo].[Focas_OperationHistory]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_OperationHistory](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[OperationType] [nvarchar](300) NULL,
	[OperationValue] [nvarchar](500) NULL,
	[ODateTime] [nvarchar](100) NULL,
	[MachineID] [nvarchar](50) NULL,
	[TypeNumber] [int] NULL,
 CONSTRAINT [PK_Focas_OperationHistory] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
