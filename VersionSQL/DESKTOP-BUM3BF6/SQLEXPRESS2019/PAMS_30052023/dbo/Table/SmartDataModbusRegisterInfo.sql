/****** Object:  Table [dbo].[SmartDataModbusRegisterInfo]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SmartDataModbusRegisterInfo](
	[AutoID] [int] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[HoldingRegisterForCommunication] [int] NULL,
	[HoldingRegisterDateAndStatus] [int] NULL,
	[HoldingRegisterDateAndStatusAckAddress] [int] NULL,
	[HoldingRegisterStartAddress_M1] [int] NOT NULL,
	[BytesToRead_M1] [int] NOT NULL,
	[AckAddress_M1] [int] NOT NULL,
	[HoldingRegisterStartAddress_M2] [int] NULL,
	[BytesToRead_M2] [int] NULL,
	[AckAddress_M2] [int] NULL,
	[HoldingRegisterStartAddress_M3] [int] NULL,
	[BytesToRead_M3] [int] NULL,
	[AckAddress_M3] [int] NULL,
	[DownCodeRequestAddess] [int] NULL,
	[DownCodeStartingAddress] [int] NULL,
	[DownInterfaceIDStartingAddress] [int] NULL,
	[TotalNumberOfDownCodeAddress] [int] NULL,
	[Inserted Date/time] [datetime] NOT NULL,
	[Updated Date/Time] [datetime] NOT NULL,
	[LastUpdated By] [nvarchar](50) NOT NULL,
	[HMIRegister_M1] [nvarchar](max) NULL,
	[HMIRegister_M2] [nvarchar](max) NULL,
	[SharedMachineID] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[SmartDataModbusRegisterInfo] ADD  DEFAULT (getdate()) FOR [Inserted Date/time]
ALTER TABLE [dbo].[SmartDataModbusRegisterInfo] ADD  DEFAULT (getdate()) FOR [Updated Date/Time]
ALTER TABLE [dbo].[SmartDataModbusRegisterInfo] ADD  DEFAULT ('PCT') FOR [LastUpdated By]
