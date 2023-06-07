/****** Object:  Table [dbo].[ControlInformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ControlInformation](
	[cID] [int] IDENTITY(1,1) NOT NULL,
	[ControlName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_ControlInformation] PRIMARY KEY CLUSTERED 
(
	[ControlName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
