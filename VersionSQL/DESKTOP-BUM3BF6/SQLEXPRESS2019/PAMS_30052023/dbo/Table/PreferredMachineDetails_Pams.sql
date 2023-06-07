/****** Object:  Table [dbo].[PreferredMachineDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PreferredMachineDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PartID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[PreferredMachineid] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230411-164548] ON [dbo].[PreferredMachineDetails_Pams]
(
	[PartID] ASC,
	[OperationNo] ASC,
	[PreferredMachineid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
