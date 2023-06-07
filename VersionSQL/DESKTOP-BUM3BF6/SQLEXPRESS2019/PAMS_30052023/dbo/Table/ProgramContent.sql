/****** Object:  Table [dbo].[ProgramContent]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProgramContent](
	[ProgramFileName] [nvarchar](50) NOT NULL,
	[ProgramType] [nvarchar](50) NOT NULL,
	[FileContent] [image] NULL,
	[MachineID] [nvarchar](50) NULL,
	[Mode] [nvarchar](50) NULL,
	[UserName] [nvarchar](50) NULL,
	[PCname] [nvarchar](50) NULL,
	[TimeStamp] [datetime] NULL,
	[componentid] [nvarchar](50) NULL,
	[OperationNo] [int] NULL,
 CONSTRAINT [PK_ProgramContent] PRIMARY KEY CLUSTERED 
(
	[ProgramFileName] ASC,
	[ProgramType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[ProgramContent]  WITH CHECK ADD  CONSTRAINT [FK_ProgramContent_DNCprograms] FOREIGN KEY([ProgramFileName])
REFERENCES [dbo].[DNCprograms] ([ProgramFileName])
ALTER TABLE [dbo].[ProgramContent] CHECK CONSTRAINT [FK_ProgramContent_DNCprograms]
