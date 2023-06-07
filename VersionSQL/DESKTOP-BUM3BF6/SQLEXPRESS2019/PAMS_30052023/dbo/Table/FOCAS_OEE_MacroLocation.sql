/****** Object:  Table [dbo].[FOCAS_OEE_MacroLocation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FOCAS_OEE_MacroLocation](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[DataReadFlagLocation] [int] NOT NULL,
	[DataStartLocation] [int] NOT NULL,
	[DataEndLocation] [int] NOT NULL
) ON [PRIMARY]
