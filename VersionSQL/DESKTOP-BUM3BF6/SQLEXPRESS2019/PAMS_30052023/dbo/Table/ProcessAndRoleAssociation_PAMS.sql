/****** Object:  Table [dbo].[ProcessAndRoleAssociation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProcessAndRoleAssociation_PAMS](
	[RowID] [bigint] IDENTITY(1,1) NOT NULL,
	[Process] [nvarchar](4000) NULL,
	[EmployeeRole] [nvarchar](50) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20221109-165330] ON [dbo].[ProcessAndRoleAssociation_PAMS]
(
	[Process] ASC,
	[EmployeeRole] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
