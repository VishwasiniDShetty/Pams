/****** Object:  Table [dbo].[DepartmentMasterDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DepartmentMasterDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[DepartmentID] [nvarchar](50) NULL,
	[DepartmentName] [nvarchar](50) NULL,
	[DepartmentIncharge] [nvarchar](50) NULL
) ON [PRIMARY]
