/****** Object:  Procedure [dbo].[s_GetSPCAutodata]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE    PROCEDURE [dbo].[s_GetSPCAutodata]
@Starttime datetime,
@Machineid nvarchar(50),
@Componentid nvarchar(50),
@Operationno int,
@Dimension nvarchar(50),
@GroupSize int,
@ShiftName nvarchar(50)='',
@Endtime datetime,
@View nvarchar(50)='' ,
@Param nvarchar(50) = '',
@ParamCPCPK nvarchar(50)=''

AS
BEGIN

Create table #SPC
(
	[SLNO] bigint IDENTITY (1, 1) NOT NULL,
	[BatchTS] Datetime,
	[Value] float,
	[BatchID] int,
	[Remarks] nvarchar(max),

)

CREATE TABLE #ShiftDefn  
(  
	ShiftDate datetime,    
	Shiftname nvarchar(20),  
	ShftSTtime datetime,  
	ShftEndTime datetime   
)  

CREATE TABLE #ShiftDefn2  
(  
	ShiftDate datetime,    
	Shiftname nvarchar(20),  
	ShftSTtime datetime,  
	ShftEndTime datetime   
)  

Declare @Samplesize as int
Select @samplesize = Isnull(Valueintext,5) from shopdefaults where parameter='SPC_SampleSize'
print @samplesize

declare @start datetime
declare @end datetime

DECLARE @Stime as Datetime,
@Etime as Datetime

IF @ParamCPCPK=''
BEGIN
	If @view=''
	BEGIN
		IF (@Param = 'SelectedDateTime' OR @Param='')
		BEGIN
			if  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
			BEGIN
				Insert into #SPC([BatchTS],[Value],[Remarks])
				select Top (@samplesize*@GroupSize) [BatchTS],[Value],[Remarks] 
				from SPCAutodata A
				inner join machineinformation M on M.interfaceid=A.mc
				inner join Componentinformation CI on CI.interfaceid=A.comp
				inner join SPC_Characteristic SP on M.machineid=SP.machineid 
				and CI.Componentid=SP.Componentid
				and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
				where ([BatchTS]>=@starttime and [BatchTS]<=@endtime) and SP.machineid=@machineid and SP.componentid=@componentid 
				and SP.operationno=@operationno and SP.CharacteristicCode=@Dimension
				Order by [Timestamp] asc, [BatchTS] asc,[Value] desc
			END
			ELSE 
			BEGIN
				Insert into #SPC([BatchTS],[Value],[Remarks])
				select Top (@samplesize*@GroupSize) [BatchTS],[Value],[Remarks] from SPCAutodata A
				inner join machineinformation M on M.interfaceid=A.mc
				inner join Componentinformation CI on CI.interfaceid=A.comp
				inner join Componentoperationpricing CO on CO.interfaceid=A.opn and 
				CO.machineid=M.machineid and CO.componentid=CI.Componentid
				inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.componentid=SP.Componentid
				and CO.operationno=SP.operationno and A.Dimension=SP.CharacteristicID
				where ([BatchTS]>=@starttime and [BatchTS]<=@endtime) and SP.machineid=@machineid and SP.componentid=@componentid 
				and SP.operationno=@operationno and SP.CharacteristicCode=@Dimension
				Order by [Timestamp] asc, [BatchTS] asc,[Value] desc
			END
		END

		IF (@Param = 'SelectedDateShift')
		BEGIN

		select @start=@Starttime
		select @end=@Endtime

		while @start<=@end
		begin
			Insert into #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
			Exec s_GetShiftTime @start,@ShiftName
			SELECT @start = DATEADD(DAY,1,@start)
		end

		INSERT INTO #ShiftDefn2(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
		SELECT * FROM #ShiftDefn WHERE (ShftSTtime>=@Starttime AND ShftEndTime<=@Endtime)

			SELECT @Stime = min(ShftSTtime) from #ShiftDefn2
			SELECT @Etime = max(ShftEndTime) from #ShiftDefn2

			IF  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
			BEGIN
				Insert into #SPC([BatchTS],[Value],[Remarks])
				select Top (@samplesize*@GroupSize) [BatchTS],[Value],[Remarks] 
				from SPCAutodata A
				inner join machineinformation M on M.interfaceid=A.mc
				inner join Componentinformation CI on CI.interfaceid=A.comp
				inner join SPC_Characteristic SP on M.machineid=SP.machineid 
				and CI.Componentid=SP.Componentid
				and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
				where [BatchTS]>=@Stime and [BatchTS]<=@Etime and SP.machineid=@machineid and SP.componentid=@componentid 
				and SP.operationno=@operationno and SP.CharacteristicCode=@Dimension
				Order by [Timestamp] asc, [BatchTS] asc,[Value] desc
			END
			ELSE 
			BEGIN
				Insert into #SPC([BatchTS],[Value],[Remarks])
				select Top (@samplesize*@GroupSize) [BatchTS],[Value],[Remarks] from SPCAutodata A
				inner join machineinformation M on M.interfaceid=A.mc
				inner join Componentinformation CI on CI.interfaceid=A.comp
				inner join Componentoperationpricing CO on CO.interfaceid=A.opn and 
				CO.machineid=M.machineid and CO.componentid=CI.Componentid
				inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.componentid=SP.Componentid
				and CO.operationno=SP.operationno and A.Dimension=SP.CharacteristicID
				where [BatchTS]>=@Stime and [BatchTS]<=@Etime and SP.machineid=@machineid and SP.componentid=@componentid 
				and SP.operationno=@operationno and SP.CharacteristicCode=@Dimension
				Order by [Timestamp] asc, [BatchTS] asc,[Value] desc
			END
		END
	END

	If @view='PickLastestValues'
	BEGIN
			Insert into #SPC([BatchTS],[Value],[Remarks])
			select Top (@samplesize*@GroupSize) [BatchTS],[Value],[Remarks] from SPCAutodata A
			inner join machineinformation M on M.interfaceid=A.mc
			inner join Componentinformation CI on CI.interfaceid=A.comp
			inner join SPC_Characteristic SP on M.machineid=SP.machineid 
			and CI.Componentid=SP.Componentid
			and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
			where SP.machineid=@machineid and SP.componentid=@componentid 
			and SP.operationno=@operationno and SP.CharacteristicCode=@Dimension and A.Value>0
			Order by [Timestamp] asc,[BatchTS] asc,[Value] asc
	END
END

IF @ParamCPCPK='CPCPKView'
BEGIN
	If @view=''
	BEGIN
		IF (@Param = 'SelectedDateTime' OR @Param='')
		BEGIN
			if  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
			BEGIN
				Insert into #SPC([BatchTS],[Value],[Remarks])
				select Top (@samplesize*@GroupSize) [BatchTS],[Value],[Remarks] 
				from SPCAutodata A
				inner join machineinformation M on M.interfaceid=A.mc
				inner join Componentinformation CI on CI.interfaceid=A.comp
				inner join SPC_Characteristic SP on M.machineid=SP.machineid 
				and CI.Componentid=SP.Componentid
				and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
				where ([BatchTS]>=@starttime and [BatchTS]<=@endtime) and SP.machineid=@machineid and SP.componentid=@componentid 
				and SP.operationno=@operationno and SP.CharacteristicCode=@Dimension and A.IgnoreForCPCPK <> 1
				Order by [Timestamp] asc, [BatchTS] asc,[Value] desc
			END
			ELSE 
			BEGIN
				Insert into #SPC([BatchTS],[Value],[Remarks])
				select Top (@samplesize*@GroupSize) [BatchTS],[Value],[Remarks] from SPCAutodata A
				inner join machineinformation M on M.interfaceid=A.mc
				inner join Componentinformation CI on CI.interfaceid=A.comp
				inner join Componentoperationpricing CO on CO.interfaceid=A.opn and 
				CO.machineid=M.machineid and CO.componentid=CI.Componentid
				inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.componentid=SP.Componentid
				and CO.operationno=SP.operationno and A.Dimension=SP.CharacteristicID
				where ([BatchTS]>=@starttime and [BatchTS]<=@endtime) and SP.machineid=@machineid and SP.componentid=@componentid 
				and SP.operationno=@operationno and SP.CharacteristicCode=@Dimension and A.IgnoreForCPCPK <> 1
				Order by [Timestamp] asc, [BatchTS] asc,[Value] desc
			END
		END

		IF (@Param = 'SelectedDateShift')
		BEGIN


		select @start=@Starttime
		select @end=@Endtime

		while @start<=@end
		begin
			Insert into #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
			Exec s_GetShiftTime @start,@ShiftName
			SELECT @start = DATEADD(DAY,1,@start)
		end

		INSERT INTO #ShiftDefn2(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
		SELECT * FROM #ShiftDefn WHERE (ShftSTtime>=@Starttime AND ShftEndTime<=@Endtime)


			

			SELECT @Stime = min(ShftSTtime) from #ShiftDefn2
			SELECT @Etime = max(ShftEndTime) from #ShiftDefn2

			IF  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
			BEGIN
				Insert into #SPC([BatchTS],[Value],[Remarks])
				select Top (@samplesize*@GroupSize) [BatchTS],[Value],[Remarks] 
				from SPCAutodata A
				inner join machineinformation M on M.interfaceid=A.mc
				inner join Componentinformation CI on CI.interfaceid=A.comp
				inner join SPC_Characteristic SP on M.machineid=SP.machineid 
				and CI.Componentid=SP.Componentid
				and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
				where [BatchTS]>=@Stime and [BatchTS]<=@Etime and SP.machineid=@machineid and SP.componentid=@componentid 
				and SP.operationno=@operationno and SP.CharacteristicCode=@Dimension and A.IgnoreForCPCPK <> 1
				Order by [Timestamp] asc, [BatchTS] asc,[Value] desc
			END
			ELSE 
			BEGIN
				Insert into #SPC([BatchTS],[Value],[Remarks])
				select Top (@samplesize*@GroupSize) [BatchTS],[Value],[Remarks] from SPCAutodata A
				inner join machineinformation M on M.interfaceid=A.mc
				inner join Componentinformation CI on CI.interfaceid=A.comp
				inner join Componentoperationpricing CO on CO.interfaceid=A.opn and 
				CO.machineid=M.machineid and CO.componentid=CI.Componentid
				inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.componentid=SP.Componentid
				and CO.operationno=SP.operationno and A.Dimension=SP.CharacteristicID
				where [BatchTS]>=@Stime and [BatchTS]<=@Etime and SP.machineid=@machineid and SP.componentid=@componentid 
				and SP.operationno=@operationno and SP.CharacteristicCode=@Dimension and A.IgnoreForCPCPK <> 1
				Order by [Timestamp] asc, [BatchTS] asc,[Value] desc
			END
		END
	END

	If @view='PickLastestValues'
	BEGIN
			Insert into #SPC([BatchTS],[Value],[Remarks])
			select Top (@samplesize*@GroupSize) [BatchTS],[Value],[Remarks] from SPCAutodata A
			inner join machineinformation M on M.interfaceid=A.mc
			inner join Componentinformation CI on CI.interfaceid=A.comp
			inner join SPC_Characteristic SP on M.machineid=SP.machineid 
			and CI.Componentid=SP.Componentid
			and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
			where SP.machineid=@machineid and SP.componentid=@componentid 
			and SP.operationno=@operationno and SP.CharacteristicCode=@Dimension and A.Value>0 and A.IgnoreForCPCPK <> 1
			Order by [Timestamp] asc,[BatchTS] asc,[Value] asc
	END
END


Declare @SPC_BatchingRecords as nvarchar(50)
Select @SPC_BatchingRecords = Isnull(Valueintext,'BasedOnSampleSize') from shopdefaults where parameter='SPC_BatchingRecords'
select @SPC_BatchingRecords='BasedOnSampleSize'

Declare @BatchTS Datetime,@BatchTS_Prev datetime
Declare @BatchID int,@BatchID_Prev int,@SLNO bigint
Declare @GetBatchID CURSOR 

If @SPC_BatchingRecords='BasedOnSampleSize'
BEGIN
	set @GetBatchID = CURSOR FOR
	Select [SLNO],[BatchTS] from #SPC order by [BatchTS]
	OPEN @GetBatchID

	FETCH NEXT FROM @GetBatchID INTO @SLNO,@BatchTS

	set @BatchID =1
	set @BatchID_Prev=1

	WHILE @@FETCH_STATUS = 0
	BEGIN
		If  @BatchID<@Samplesize
		BEGIN
			Update #SPC set [BatchID] = @BatchID_Prev where SLNO=@SLNO
			set @BatchID = @BatchID + 1
		END
		Else
		BEGIN
			Update #SPC set [BatchID] = @BatchID_Prev where SLNO=@SLNO	
			set @BatchID_Prev = @BatchID_Prev + 1
			set @BatchID = 1	
		end

	FETCH NEXT FROM @GetBatchID INTO @SLNO,@BatchTS
	END
END
ELSE
BEGIN
	set @GetBatchID = CURSOR FOR
	Select [SLNO],[BatchTS] from #SPC order by [BatchTS]
	OPEN @GetBatchID

	FETCH NEXT FROM @GetBatchID INTO @SLNO,@BatchTS

	set @BatchID_Prev =1
	set @BatchTS_Prev = @BatchTS

	WHILE @@FETCH_STATUS = 0
	BEGIN
		If  @BatchTS_Prev=@BatchTS
		BEGIN
			Update #SPC set [BatchID] = @BatchID_Prev where SLNO=@SLNO
		END
		Else
		BEGIN
			set @BatchID_Prev = @BatchID_Prev + 1
			set @BatchTS_Prev = @BatchTS
			Update #SPC set [BatchID] = @BatchID_Prev where SLNO=@SLNO		
		end

	FETCH NEXT FROM @GetBatchID INTO @SLNO,@BatchTS
	END
END
CLOSE @GetBatchID;
DEALLOCATE @GetBatchID;

Select * from #SPC where [BatchID] <= @GroupSize 

END
