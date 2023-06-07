/****** Object:  Table [dbo].[Alert_Rules]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Alert_Rules](
	[SLNo] [bigint] IDENTITY(1,1) NOT NULL,
	[RuleID] [nvarchar](100) NOT NULL,
	[Description] [nvarchar](100) NULL,
	[Parameter] [nvarchar](100) NOT NULL,
	[Compare] [varchar](50) NOT NULL,
	[Threshold] [int] NULL,
	[ThresholdUnit] [nvarchar](50) NOT NULL,
	[EvaluateEvery] [int] NOT NULL,
	[EvaluateEveryUnit] [nvarchar](50) NOT NULL,
	[Enabled] [bit] NOT NULL,
	[AppliesTo] [nvarchar](500) NOT NULL,
	[EmailSubjectTemplate] [nvarchar](500) NULL,
	[EmailBodyTemplate] [nvarchar](500) NULL,
	[SMSTextTemplate] [nvarchar](500) NULL,
	[SMSEnabled] [bit] NULL,
	[EmailEnabled] [bit] NULL,
	[TelegramEnabled] [bit] NULL,
	[MobileEnabled] [bit] NULL,
 CONSTRAINT [PK_Alert_Rules] PRIMARY KEY CLUSTERED 
(
	[RuleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[Alert_Rules] ADD  CONSTRAINT [DF_Alert_Rules_Enabled]  DEFAULT ((0)) FOR [Enabled]
