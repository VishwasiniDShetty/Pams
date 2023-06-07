/****** Object:  Table [dbo].[tcs_energyconsumption]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[tcs_energyconsumption](
	[MachineID] [nvarchar](50) NULL,
	[gtime] [datetime] NOT NULL,
	[ampere] [float] NOT NULL,
	[watt] [float] NOT NULL,
	[pf] [float] NOT NULL,
	[idd] [int] IDENTITY(1,1) NOT NULL,
	[KWH] [float] NULL,
	[gtime1] [datetime] NULL,
	[ampere1] [float] NULL,
	[KWH1] [float] NULL,
	[Volt1] [float] NULL,
	[Volt2] [float] NULL,
	[Volt3] [float] NULL,
	[AmpereR] [float] NULL,
	[AmpereY] [float] NULL,
	[AmpereB] [float] NULL,
	[KVA] [float] NULL,
	[EnergySource] [smallint] NULL,
	[Volt4] [float] NULL,
	[Volt5] [float] NULL,
	[Volt6] [float] NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [idx_tcsEnergyData] ON [dbo].[tcs_energyconsumption]
(
	[MachineID] ASC,
	[gtime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON




CREATE TRIGGER [dbo].[tr_tcsEnergyconsumption_gtime]
   ON [dbo].[tcs_energyconsumption]
   AFTER INSERT
AS

Declare @Machineid as nvarchar(50)
Declare @gtime1 as datetime
Declare @error as int
Declare @count as int
Begin

	--mod 1(1)
		Select @Machineid=machineid,@gtime1=gtime from inserted
		
		
		update tcs_energyconsumption_maxgtime set
		maxgtime=@gtime1 from inserted
		where machine=@machineid and maxgtime<@gtime1
		
	
		set @count=@@rowcount
		Set @Error=@@Error
	
		If @Error <> 0 goto Err_Handler
		
		--mod 1(2)
		--If @count=0
		If @count=0 and (select count(*) from tcs_energyconsumption_maxgtime where  machine=@machineid)= 0
		--mod 1(2)
		Begin
			Insert into tcs_energyconsumption_maxgtime (machine,maxgtime)
			values(@Machineid,@gtime1)
			set @count=@@rowcount
		End
	--END --mod 1(1)
	
--If @Error <> 0 goto Err_Handler
return
Err_Handler:
If @@trancount<> 0 rollback transaction
return



END





ALTER TABLE [dbo].[tcs_energyconsumption] ENABLE TRIGGER [tr_tcsEnergyconsumption_gtime]
