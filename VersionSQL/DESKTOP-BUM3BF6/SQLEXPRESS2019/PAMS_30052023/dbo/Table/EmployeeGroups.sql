/****** Object:  Table [dbo].[EmployeeGroups]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[EmployeeGroups](
	[GroupID] [nvarchar](50) NOT NULL,
	[OperatorID] [nvarchar](50) NOT NULL,
	[Slno] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[EmployeeGroups]  WITH CHECK ADD  CONSTRAINT [FK_EmployeeGroups_employeeinformation] FOREIGN KEY([OperatorID])
REFERENCES [dbo].[employeeinformation] ([Employeeid])
ALTER TABLE [dbo].[EmployeeGroups] CHECK CONSTRAINT [FK_EmployeeGroups_employeeinformation]
