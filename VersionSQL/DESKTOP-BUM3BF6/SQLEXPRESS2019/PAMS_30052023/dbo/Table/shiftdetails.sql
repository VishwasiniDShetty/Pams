/****** Object:  Table [dbo].[shiftdetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[shiftdetails](
	[ShiftName] [nvarchar](20) NULL,
	[StartTime] [int] NULL,
	[NoofHrs] [int] NULL,
	[fromdate] [smalldatetime] NULL,
	[slno] [int] IDENTITY(1,1) NOT NULL,
	[Running] [smallint] NULL,
	[shiftid] [tinyint] NULL,
	[FromDay] [smallint] NULL,
	[ToDay] [smallint] NULL,
	[FromTime] [datetime] NULL,
	[ToTime] [datetime] NULL,
 CONSTRAINT [PK_shiftdetails] PRIMARY KEY CLUSTERED 
(
	[slno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[shiftdetails] ADD  CONSTRAINT [DF_shiftdetails_StartTime]  DEFAULT ((0)) FOR [StartTime]
ALTER TABLE [dbo].[shiftdetails] ADD  CONSTRAINT [DF_shiftdetails_NoofHrs]  DEFAULT ((0)) FOR [NoofHrs]
ALTER TABLE [dbo].[shiftdetails] ADD  CONSTRAINT [DF_shiftdetails_Running]  DEFAULT ((0)) FOR [Running]
ALTER TABLE [dbo].[shiftdetails] ADD  CONSTRAINT [DF_shiftdetails_shiftid]  DEFAULT ((0)) FOR [shiftid]
ALTER TABLE [dbo].[shiftdetails] ADD  CONSTRAINT [DF_shiftdetails_FromDay]  DEFAULT ((0)) FOR [FromDay]
ALTER TABLE [dbo].[shiftdetails] ADD  CONSTRAINT [DF_shiftdetails_ToDay]  DEFAULT ((0)) FOR [ToDay]
