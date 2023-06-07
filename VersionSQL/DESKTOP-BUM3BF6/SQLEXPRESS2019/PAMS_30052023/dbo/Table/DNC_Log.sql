/****** Object:  Table [dbo].[DNC_Log]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DNC_Log](
	[idd] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[IPAddress] [nvarchar](50) NULL,
	[ClientName] [nvarchar](50) NULL,
	[UserName] [nvarchar](50) NULL,
	[LogMessage] [nvarchar](1000) NULL,
	[ErrorNumber] [nvarchar](50) NULL,
	[MessageType] [nvarchar](50) NULL,
	[TimeStamp] [datetime] NULL,
 CONSTRAINT [PK_DNC_Log] PRIMARY KEY CLUSTERED 
(
	[idd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
