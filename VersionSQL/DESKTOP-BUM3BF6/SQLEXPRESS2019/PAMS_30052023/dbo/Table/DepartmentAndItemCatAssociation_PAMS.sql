/****** Object:  Table [dbo].[DepartmentAndItemCatAssociation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DepartmentAndItemCatAssociation_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[Department] [nvarchar](50) NULL
) ON [PRIMARY]
