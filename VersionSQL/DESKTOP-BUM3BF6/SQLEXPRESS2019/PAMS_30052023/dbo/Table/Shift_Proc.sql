/****** Object:  Table [dbo].[Shift_Proc]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Shift_Proc](
	[SSession] [nvarchar](50) NOT NULL,
	[Machine] [nvarchar](50) NOT NULL,
	[Mdate] [datetime] NULL,
	[Mshift] [nvarchar](50) NULL,
	[MShiftStart] [datetime] NOT NULL,
	[MshiftEnd] [datetime] NULL,
	[UtilTime] [float] NULL,
	[MachineInt] [nvarchar](50) NULL,
 CONSTRAINT [PK_Shift_Proc] PRIMARY KEY CLUSTERED 
(
	[SSession] ASC,
	[Machine] ASC,
	[MShiftStart] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
