/****** Object:  Table [dbo].[SMTPMailDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SMTPMailDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[FromEmail] [nvarchar](max) NULL,
	[Password] [nvarchar](max) NULL,
	[SMTPHostName] [nvarchar](2000) NULL,
	[SMTPPort] [nvarchar](500) NULL,
	[EnableSsl] [bit] NULL,
	[Threshold] [nvarchar](100) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[SMTPMailDetails_Pams] ADD  DEFAULT ((0)) FOR [EnableSsl]
ALTER TABLE [dbo].[SMTPMailDetails_Pams] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
