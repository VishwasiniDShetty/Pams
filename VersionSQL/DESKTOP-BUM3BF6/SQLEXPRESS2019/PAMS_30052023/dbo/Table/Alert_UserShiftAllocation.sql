/****** Object:  Table [dbo].[Alert_UserShiftAllocation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Alert_UserShiftAllocation](
	[SlNo] [bigint] IDENTITY(1,1) NOT NULL,
	[UserID] [nvarchar](100) NOT NULL,
	[ShiftDate] [datetime] NOT NULL,
	[ShiftID] [smallint] NOT NULL,
 CONSTRAINT [PK_Alert_UserShiftAllocation] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[ShiftDate] ASC,
	[ShiftID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
