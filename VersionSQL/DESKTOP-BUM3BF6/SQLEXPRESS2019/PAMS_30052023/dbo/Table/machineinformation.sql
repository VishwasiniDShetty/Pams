/****** Object:  Table [dbo].[machineinformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[machineinformation](
	[machineid] [nvarchar](50) NOT NULL,
	[description] [nvarchar](150) NULL,
	[status] [smallint] NULL,
	[mchrrate] [float] NULL,
	[portno] [smallint] NULL,
	[settings] [nvarchar](50) NULL,
	[InterfaceID] [nvarchar](50) NULL,
	[IP] [nvarchar](20) NULL,
	[IPPortNO] [nvarchar](10) NULL,
	[mode] [smallint] NULL,
	[autoload] [smallint] NULL,
	[TPMTrakEnabled] [smallint] NULL,
	[PEGreen] [smallint] NOT NULL,
	[PERed] [smallint] NOT NULL,
	[AEGreen] [smallint] NOT NULL,
	[AERed] [smallint] NOT NULL,
	[OEGreen] [smallint] NOT NULL,
	[OERed] [smallint] NOT NULL,
	[BulkDataTransferPortNo] [nvarchar](50) NULL,
	[MultiSpindleFlag] [bit] NULL,
	[DeviceType] [smallint] NULL,
	[PPTransferEnabled] [bit] NULL,
	[SmartTransEnabled] [bit] NULL,
	[IgnoreCoFromMach] [nvarchar](10) NULL,
	[AutoSetupchangeDown] [nvarchar](25) NULL,
	[MachinewiseOwner] [nvarchar](50) NULL,
	[CriticalMachineEnabled] [bit] NULL,
	[DAPEnabled] [smallint] NULL,
	[Lowerpowerthreshold] [float] NULL,
	[upperpowerthreshold] [float] NULL,
	[QERED] [smallint] NULL,
	[QEGreen] [smallint] NULL,
	[EthernetEnabled] [bit] NOT NULL,
	[Nto1Device] [bit] NOT NULL,
	[DNCIP] [nvarchar](20) NULL,
	[DNCIPPortNo] [nvarchar](10) NULL,
	[DNCTransferEnabled] [smallint] NOT NULL,
	[MachineType] [nvarchar](50) NULL,
	[MachineMTB] [nvarchar](50) NULL,
	[ProgramFoldersEnabled] [bit] NOT NULL,
	[MachineModel] [nvarchar](50) NULL,
	[SpindleAxisNumber] [int] NULL,
	[OPCUAURL] [nvarchar](500) NULL,
	[ControllerType] [nvarchar](500) NOT NULL,
	[SerialNumber] [nvarchar](500) NULL,
	[OEETarget] [float] NULL,
	[EnablePartCountByMacro] [smallint] NULL,
	[IsTwinSpindle] [smallint] NULL,
	[ChannelId] [varchar](200) NULL,
	[Separator] [varchar](200) NULL,
	[MobileEnabled] [bit] NULL,
	[NoOfPallets] [smallint] NULL,
	[ProcessType] [nvarchar](50) NULL,
 CONSTRAINT [PK_machineinformation] PRIMARY KEY CLUSTERED 
(
	[machineid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_status]  DEFAULT ((0)) FOR [status]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_mchrrate]  DEFAULT ((0)) FOR [mchrrate]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_portno]  DEFAULT ((0)) FOR [portno]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_mode]  DEFAULT ((0)) FOR [mode]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_autoload]  DEFAULT ((0)) FOR [autoload]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [TpmTrackEnabledDefault]  DEFAULT ((0)) FOR [TPMTrakEnabled]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_PEGreen]  DEFAULT ((85)) FOR [PEGreen]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_PERed]  DEFAULT ((70)) FOR [PERed]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_AEGreen]  DEFAULT ((95)) FOR [AEGreen]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_AERed]  DEFAULT ((85)) FOR [AERed]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_OEGreen]  DEFAULT ((80)) FOR [OEGreen]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_OERed]  DEFAULT ((65)) FOR [OERed]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_MultiSpindleFlag]  DEFAULT ((0)) FOR [MultiSpindleFlag]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DF_machineinformation_DeviceType]  DEFAULT ((2)) FOR [DeviceType]
ALTER TABLE [dbo].[machineinformation] ADD  DEFAULT ((0)) FOR [PPTransferEnabled]
ALTER TABLE [dbo].[machineinformation] ADD  DEFAULT ((0)) FOR [SmartTransEnabled]
ALTER TABLE [dbo].[machineinformation] ADD  DEFAULT ('N') FOR [AutoSetupchangeDown]
ALTER TABLE [dbo].[machineinformation] ADD  CONSTRAINT [DAPEnabledDefault]  DEFAULT ((0)) FOR [DAPEnabled]
ALTER TABLE [dbo].[machineinformation] ADD  DEFAULT ((0)) FOR [EthernetEnabled]
ALTER TABLE [dbo].[machineinformation] ADD  DEFAULT ((0)) FOR [Nto1Device]
ALTER TABLE [dbo].[machineinformation] ADD  DEFAULT ((0)) FOR [DNCTransferEnabled]
ALTER TABLE [dbo].[machineinformation] ADD  DEFAULT ((0)) FOR [ProgramFoldersEnabled]
ALTER TABLE [dbo].[machineinformation] ADD  DEFAULT ('FANUC') FOR [ControllerType]
ALTER TABLE [dbo].[machineinformation] ADD  DEFAULT ((0)) FOR [MobileEnabled]
