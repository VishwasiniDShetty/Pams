/****** Object:  Table [dbo].[ProcessParameterMaster_MGTL]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProcessParameterMaster_MGTL](
	[IDD] [bigint] IDENTITY(1,1) NOT NULL,
	[ParameterID] [int] NULL,
	[ParameterName] [nvarchar](100) NULL,
	[MinValue] [nvarchar](50) NULL,
	[MaxValue] [nvarchar](50) NULL,
	[WarningValue] [nvarchar](50) NULL,
	[RedBit] [nvarchar](50) NULL,
	[Redvalue] [nvarchar](50) NULL,
	[Greenbit] [nvarchar](50) NULL,
	[GreenValue] [nvarchar](50) NULL,
	[YellowBit] [nvarchar](50) NULL,
	[YellowValue] [nvarchar](50) NULL,
	[Red1bit] [nvarchar](50) NULL,
	[Red1HValue] [nvarchar](50) NULL,
	[Red1LValue] [nvarchar](50) NULL,
	[Unit] [nvarchar](50) NULL,
	[TemplateType] [nvarchar](50) NULL,
	[IsVisible] [nvarchar](50) NULL,
	[SortOrder] [int] NULL,
	[ReadOnOperation] [nvarchar](50) NULL,
 CONSTRAINT [IX_ProcessParameterMaster_MGTL] UNIQUE NONCLUSTERED 
(
	[IDD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
