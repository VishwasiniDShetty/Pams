/****** Object:  Procedure [dbo].[s_GetFocasDaywiseLiveDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetFocasDaywiseLiveDetails] '2013-09-01','2013-09-30','Win Chennai - SCP','ACE-02','','programdetails'


CREATE procedure [dbo].[s_GetFocasDaywiseLiveDetails]
 @Starttime datetime,
 @Endtime datetime,
 @PlantID nvarchar(50),
 @Machine nvarchar(50),
 @prgno int,
 @Param nvarchar(20)
AS
BEGIN

Create Table #LiveDetails
(
	[Sl No] Bigint Identity(1,1) Not Null,
	[Machineid] nvarchar(50),
	[From Time] datetime,
	[To time] datetime,
	[Min Powerontime] float,
	[Max Powerontime] float,
	[Powerontime] float,
	[Min Cutting time] float,
	[Max Cutting time] float,
	[col1_id] INT,
	[col2_ID] INT,
	[Cutting time] float,
	[CycleCount] int,
	[Prog No] int,
	[Tool No] int,
	[BatchID] int
)

create table #Cuttingdetails
(
	[From Time] datetime,
	[Machineid] nvarchar(50),
	[col1_id] INT,
	[col2_ID] INT,
	[BatchID] int
)

Create table #Day
(
	[From Time] datetime,
	[To time] datetime
)

If @param = 'powerontime' or @param = 'Cuttingtime' or @param = 'CycleCount'
BEGIN
	while @StartTime<=@EndTime
	BEGIN
		Insert into #LiveDetails([Machineid],[From Time],[To time])
		Select @Machine,dbo.f_GetLogicalDay(@StartTime,'start'),dbo.f_GetLogicalDay(@StartTime,'End')
		SELECT @StartTime=DATEADD(DAY,1,@StartTime)
	END


	Update #LiveDetails set [Powerontime]  = isnull(#LiveDetails.[Powerontime] ,0) + isnull(T2.Powerontime,0),    
	[Cutting time]  = isnull([Cutting time] ,0) + isnull(T2.Cuttingtime,0) From    
	(select L.[From Time]  as TS,F.machineid,Max(F.Powerontime)-Min(F.Powerontime) as Powerontime,    
	Max(Cuttime)-Min(Cuttime) as Cuttingtime from dbo.Focas_LiveData F    
	inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time]  and F.cnctimestamp<=L.[To Time]     
	where F.Powerontime>0 and F.CutTime>0 group by F.machineid,L.[From Time]     
	)T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS and #LiveDetails.Machineid=T2.MachineID    
	    
	Update #LiveDetails Set [Cutting time] = [Cutting time]/60 where [Cutting time]>0     
end
 
If @param = 'powerontime'  
BEGIN
select [Sl No],[From Time],[To time],Isnull(Round([Powerontime],4),0) as [Powerontime] from #LiveDetails 
END

If  @param = 'Cuttingtime'
Begin
select [Sl No],[From Time],[To time],Isnull(Round([Cutting time],4),0) as [Cutting time] from #LiveDetails 
end

If @param = 'CycleCount'
Begin
select [Sl No],[From Time],[To time],Isnull([CycleCount],0) as [CycleCount] from #LiveDetails 
end

/*
If @param = 'powerontime'
BEGIN
	
	Update #LiveDetails set [Min Powerontime]  = isnull([Min Powerontime],0) + Isnull(T2.Powerontime,0)  From
	(select T1.TS,F.Powerontime from
	(select L.[From Time] as TS,F.machineid,Min(F.cnctimestamp) as CNCTS from dbo.Focas_LiveData F
	inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time]
	where F.machineid=@Machine and F.Programno<>0 and F.ToolNo<>0 and F.Powerontime>0 group by F.machineid,L.[From Time]
	)T1 inner join dbo.Focas_LiveData F on F.machineid=T1.machineid and F.CNCtimestamp=T1.CNCTS
	)T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS

	Update #LiveDetails set [Max Powerontime]  = isnull([Max Powerontime] ,0) + Isnull(T2.Powerontime,0)  From
	(select T1.TS,F.Powerontime from
	(select L.[From Time] as TS,F.machineid,Max(F.cnctimestamp) as CNCTS from dbo.Focas_LiveData F
	inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time]
	where F.machineid=@Machine and F.Programno<>0 and F.ToolNo<>0 and F.Powerontime>0 group by F.machineid,L.[From Time]
	)T1 inner join dbo.Focas_LiveData F on F.machineid=T1.machineid and F.CNCtimestamp=T1.CNCTS
	)T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS

	Update #LiveDetails set [Powerontime]  = [Max Powerontime] - [Min Powerontime] 
	
	Select [Sl No],[From Time],[To time],Isnull(Round([Powerontime],4),0) as [Powerontime] From #LiveDetails
END


If @param = 'Cuttingtime'
BEGIN
	
	Update #LiveDetails set [Min Cutting time]  = isnull([Min Cutting time] ,0) + Isnull(T2.Cuttingtime,0)  From
	(select T1.TS,F.Cuttingtime from
	(select L.[From Time] as TS,F.machineid,Min(machinetimestamp) as MachineTS from dbo.Focas_ToolOffsetHistory F
	inner join #LiveDetails L on L.machineid=F.machineid and F.machinetimestamp>=L.[From Time] and F.machinetimestamp<=L.[To Time]
	where F.machineid=@Machine and Programnumber<>0 and ToolNo<>0 and Cuttingtime>0 group by F.machineid,L.[From Time]
	)T1 inner join dbo.Focas_ToolOffsetHistory F on F.machineid=T1.machineid and F.machinetimestamp=T1.MachineTS
	)T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS

	Update #LiveDetails set [Max Cutting time]  = isnull([Max Cutting time] ,0) + isnull(T2.Cuttingtime,0)  From
	(select T1.TS,F.Cuttingtime from
	(select L.[From Time] as TS,F.machineid,Max(machinetimestamp) as MachineTS from dbo.Focas_ToolOffsetHistory F
	inner join #LiveDetails L on L.machineid=F.machineid and F.machinetimestamp>=L.[From Time] and F.machinetimestamp<=L.[To Time]
	where F.machineid=@Machine and Programnumber<>0 and ToolNo<>0 and Cuttingtime>0 group by F.machineid,L.[From Time]
	)T1 inner join dbo.Focas_ToolOffsetHistory F on F.machineid=T1.machineid and F.machinetimestamp=T1.MachineTS
	)T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS

	Update #LiveDetails set [Cutting time] = [Max Cutting time]- [Min Cutting time]
	
	Select [Sl No],[From Time],[To time],Isnull(Round([Cutting time],4),0) as [Cutting time] From #LiveDetails
END


If @param = 'CycleCount'
BEGIN
	
	Update #Livedetails set CycleCount = isnull(Cyclecount,0) + isnull(T.cycle,0) from
	( Select mc,L.[From Time] as TS,Sum(Partscount) as cycle from Autodata A
	  inner join Machineinformation M on M.interfaceid=A.mc
	  inner join Focas_ToolOffsetHistory F on F.machineid=M.machineid and F.ProgramNumber = A.comp
	  inner join #LiveDetails L on L.machineid=F.machineid and F.machinetimestamp>=L.[From Time] and F.machinetimestamp<=L.[To Time]
	  Where F.machineid=@machine and (A.ndtime>L.[From Time] and A.ndtime<=L.[To Time]) and A.datatype=1
	  Group by mc,L.[From Time]
	) T inner join #Livedetails on #LiveDetails.[From Time] = T.TS

	Select [Sl No],[From Time],[To time],Isnull([CycleCount],0) as [CycleCount] From #LiveDetails
END
*/





If @param='ProgramDetails'
BEGIN

	while @StartTime<@EndTime
	BEGIN
		Insert into #day([From Time],[To time])
		Select  dbo.f_GetLogicalDay(@StartTime,'start'),dbo.f_GetLogicalDay(@StartTime,'End')
		SELECT @StartTime=DATEADD(DAY,1,@StartTime)
	END

	Insert into #Cuttingdetails([col1_id],[col2_ID],[From Time])
	select S1.id as s1id,min(S2.id) as s2id,C.[From Time]
	from Focas_ToolOffsetHistory s1,Focas_ToolOffsetHistory s2, #day C
	where s1.id<s2.id and S1.Programnumber<>0 and S1.Programnumber<9000  and s1.toolno<>0 and s1.cuttingtime>0 and s1.machinetimestamp>=C.[From Time] and S1.Machinetimestamp<=C.[To time]
	and S2.Programnumber<>0 and S2.Programnumber<9000  and s2.toolno<>0 and s2.cuttingtime>0 and S1.Programnumber<>S2.Programnumber and s2.machinetimestamp>=C.[From Time] and S2.Machinetimestamp<=C.[To time]
    and S1.machineid=@machine and S2.machineid=@machine group by S1.id,C.[From Time]

	
	Declare @Col1ID int,@Col2ID int,@Col2ID_prev int
	Declare @BatchID int,@BatchID_Prev int
	Declare @GetBatchID CURSOR 
	set @GetBatchID = CURSOR FOR
	select [col1_id],[Col2_id] from #Cuttingdetails order by [Col2_id]
	OPEN @GetBatchID

	FETCH NEXT FROM @GetBatchID INTO @Col1ID,@Col2ID

	set @BatchID_Prev =1
	set @Col2ID_prev = @Col2ID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		If  @Col2ID_prev=@Col2ID
		BEGIN
			Update #Cuttingdetails set [BatchID] = @BatchID_Prev where [col1_id]=@Col1ID
		END
		Else
		BEGIN
			set @BatchID_Prev = @BatchID_Prev + 1
			set @Col2ID_prev = @Col2ID
			Update #Cuttingdetails set [BatchID] = @BatchID_Prev where [col1_id]=@Col1ID	
		end

	FETCH NEXT FROM @GetBatchID INTO @Col1ID,@Col2ID

	END

	CLOSE @GetBatchID;
	DEALLOCATE @GetBatchID;

	Insert into #Livedetails(Machineid,[From Time],[To time],[col1_id],[Col2_id],[BatchID],[Prog No] )
	select T1.Machine,T1.[From Time],T1.[To time],T1.C1ID,T1.C2ID,T1.BID,0 from
	(
	select @Machine as Machine,D.[From Time],D.[To time],min([col1_id]) as C1ID,max([Col2_id]) as C2ID,[BatchID] as BID from #Cuttingdetails 
	right outer join #day D on D.[From Time] =#Cuttingdetails.[From Time] group by [BatchID],D.[From Time],D.[To time]
	)T1 Order by T1.[From Time]

	Update #Livedetails set CycleCount = isnull(Cyclecount,0) + isnull(T.cycle,0) from
	( Select mc,comp,L.[From Time] as TS,Sum(Partscount) as cycle from Autodata A
	  inner join Machineinformation M on M.interfaceid=A.mc
	  inner join dbo.Focas_ToolOffsetHistory F on F.machineid=M.machineid and F.ProgramNumber = A.comp
	  inner join #LiveDetails L on L.machineid=F.machineid and L.[prog no]=F.Programnumber and F.machinetimestamp>=L.[From Time] and F.machinetimestamp<=L.[To Time]
	  Where F.machineid=@machine and (A.ndtime>L.[From Time] and A.ndtime<=L.[To Time]) and A.datatype=1
	  Group by mc,comp,L.[From Time] 
	) T inner join #Livedetails on #LiveDetails.[From Time] = T.TS and #LiveDetails.[Prog No] = T.comp

	Update #LiveDetails set [Min Cutting time]  = isnull([Min Cutting time],0) + Isnull(T2.Cuttingtime,0),[Prog No] = isnull([Prog No],0) + isnull(T2.ProgramNumber,0)  From
	(select F.ProgramNumber,F.Cuttingtime,L.[col1_id] as ID from dbo.Focas_ToolOffsetHistory F
	inner join #LiveDetails L on L.[col1_id]=F.ID 
	)T2 inner join #LiveDetails on #LiveDetails.[col1_id] = T2.ID
	
	Update #LiveDetails set [Max Cutting time]  = isnull([Max Cutting time],0) + Isnull(T2.Cuttingtime,0) From
	(select F.ProgramNumber,F.Cuttingtime,L.[col2_id] as ID from dbo.Focas_ToolOffsetHistory F
	inner join #LiveDetails L on L.[col2_id]=F.ID 
	)T2 inner join #LiveDetails on #LiveDetails.[col2_id] = T2.ID

	Update #LiveDetails set [Cutting time] = isnull([Cutting time],0) + isnull(T1.Ctime,0) from
	( select [From Time] as TS,[Prog No] as comp,[Max Cutting time]- [Min Cutting time] as Ctime,[col1_id],[col2_id] from #LiveDetails
	where [Max Cutting time]- [Min Cutting time]>4 )T1
	inner join #LiveDetails on #LiveDetails.[From Time] = T1.TS and #LiveDetails.[Prog No] = T1.comp and #LiveDetails.[col1_id] = T1.[col1_id] and #LiveDetails.[col2_id] = T1.[col2_id]

	Select [Sl No],[From Time],[Prog No] ,Isnull([CycleCount],0) as [CycleCount],dbo.f_FormatTime(isnull(Round([Cutting time],4),0),'hh:mm:ss') as [Cutting time] From #LiveDetails
	Order by [From Time] 

END

If @param='ToolDetails'
BEGIN
	while @StartTime<=@EndTime
	BEGIN
		Insert into #day([From Time],[To time])
		Select  dbo.f_GetLogicalDay(@StartTime,'start'),dbo.f_GetLogicalDay(@StartTime,'End')
		SELECT @StartTime=DATEADD(DAY,1,@StartTime)
	END

	Insert into #Cuttingdetails([col1_id],[col2_ID],[From Time])
	select S1.id as s1id,min(S2.id) as s2id,C.[From Time]
	from Focas_ToolOffsetHistory s1,Focas_ToolOffsetHistory s2, #day C
	where s1.id<s2.id and S1.Programnumber<>0 and s1.toolno<>0 and s1.cuttingtime>0 and s1.machinetimestamp>=C.[From Time] and S1.Machinetimestamp<=C.[To time]
	and S2.Programnumber<>0 and s2.toolno<>0 and s2.cuttingtime>0 and (S1.Programnumber<>S2.Programnumber or s1.toolno<>s2.toolno) and s2.machinetimestamp>=C.[From Time] and S2.Machinetimestamp<=C.[To time]
    and S1.machineid=@machine and S2.machineid=@machine and S1.Programnumber=@prgno group by S1.id,C.[From Time]


	set @GetBatchID = CURSOR FOR
	select [col1_id],[Col2_id] from #Cuttingdetails order by [Col2_id]
	OPEN @GetBatchID

	FETCH NEXT FROM @GetBatchID INTO @Col1ID,@Col2ID

	set @BatchID_Prev =1
	set @Col2ID_prev = @Col2ID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		If  @Col2ID_prev=@Col2ID
		BEGIN
			Update #Cuttingdetails set [BatchID] = @BatchID_Prev where [col1_id]=@Col1ID
		END
		Else
		BEGIN
			set @BatchID_Prev = @BatchID_Prev + 1
			set @Col2ID_prev = @Col2ID
			Update #Cuttingdetails set [BatchID] = @BatchID_Prev where [col1_id]=@Col1ID	
		end

	FETCH NEXT FROM @GetBatchID INTO @Col1ID,@Col2ID

	END

	CLOSE @GetBatchID;
	DEALLOCATE @GetBatchID;

	Insert into #Livedetails(Machineid,[From Time],[To time],[col1_id],[Col2_id],[BatchID],[Prog No],[Tool No])
	select T1.Machine,T1.[From Time],T1.[To time],T1.C1ID,T1.C2ID,T1.BID,0,0 from
	(
	select @Machine as Machine,D.[From Time],D.[To time],min([col1_id]) as C1ID,max([Col2_id]) as C2ID,[BatchID] as BID from #Cuttingdetails 
	right outer join #day D on D.[From Time] =#Cuttingdetails.[From Time] group by [BatchID],D.[From Time],D.[To time]
	)T1 Order by T1.[From Time]

	Update #LiveDetails set [Min Cutting time]  = isnull([Min Cutting time],0) + Isnull(T2.Cuttingtime,0),[Prog No] = isnull([Prog No],0) + isnull(T2.ProgramNumber,0)
	,[Tool No] = isnull([Tool No],0) + isnull(T2.ToolNo,0)  From
	(select F.ProgramNumber,F.ToolNo,F.Cuttingtime,L.[col1_id] as ID from dbo.Focas_ToolOffsetHistory F
	inner join #LiveDetails L on L.[col1_id]=F.ID 
	)T2 inner join #LiveDetails on #LiveDetails.[col1_id] = T2.ID
	
	Update #LiveDetails set [Max Cutting time]  = isnull([Max Cutting time],0) + Isnull(T2.Cuttingtime,0) from
	(select F.ProgramNumber,F.ToolNo,F.Cuttingtime,L.[col2_id] as ID from dbo.Focas_ToolOffsetHistory F
	inner join #LiveDetails L on L.[col2_id]=F.ID 
	)T2 inner join #LiveDetails on #LiveDetails.[col2_id] = T2.ID

	Update #LiveDetails set [Cutting time] = isnull([Cutting time],0) + isnull(T1.Ctime,0) from
	( select [From Time] as TS,[Prog No] as comp,[Tool No] as tool,[Max Cutting time]- [Min Cutting time] as Ctime,[col1_id],[col2_id] from #LiveDetails
	 where [Max Cutting time]- [Min Cutting time]>4 )T1
	inner join #LiveDetails on #LiveDetails.[From Time] = T1.TS and #LiveDetails.[Prog No] = T1.comp and #LiveDetails.[Tool No] = T1.Tool
	and #LiveDetails.[col1_id] = T1.[col1_id] and #LiveDetails.[col2_id] = T1.[col2_id]

	
	Select [Sl No],[From Time],[Prog No] ,[Tool No],dbo.f_FormatTime(isnull(Round([Cutting time],4),0),'hh:mm:ss') as [Cutting time] From #LiveDetails
	Order by [From Time] 

END

End


      
