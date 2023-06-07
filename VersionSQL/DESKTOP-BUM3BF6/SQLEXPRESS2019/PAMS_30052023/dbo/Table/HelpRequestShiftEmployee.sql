/****** Object:  Table [dbo].[HelpRequestShiftEmployee]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[HelpRequestShiftEmployee](
	[SlNo] [int] IDENTITY(1,1) NOT NULL,
	[PlantID] [nvarchar](50) NOT NULL,
	[EmployeeID] [nvarchar](25) NOT NULL,
	[shiftid] [int] NOT NULL,
 CONSTRAINT [PK_HelpRequestShiftEmployee] PRIMARY KEY CLUSTERED 
(
	[PlantID] ASC,
	[EmployeeID] ASC,
	[shiftid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
