/****** Object:  Procedure [dbo].[S_FocasToolOffsetHistorySaveAndView]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[S_FocasToolOffsetHistorySaveAndView] 'AMIT-01','','','','','Save',''
*/
CREATE procedure [dbo].[S_FocasToolOffsetHistorySaveAndView]
@MachineID nvarchar(50)='',
@FromTime datetime='',
@ToTime datetime='',
@OffsetNo nvarchar(50)='',
@OffsetType nvarchar(50)='',
@Param nvarchar(50)='',
@Param1 nvarchar(50)=''

AS
BEGIN
	if @offsetNo='ALL'
	BEGIN
	set @offsetNo =''
	END

	create table #OffsetNo
	( OffsetNo nvarchar(50)
	)

	 if isnull(@OffsetNo,'')<> ''  and @OffsetNo <>'ALL'
	 begin  
 		insert into #OffsetNo(OffsetNo)
		SELECT val FROM dbo.Split(@OffsetNo, ',')
	 end

	IF @Param='View'
	BEGIN
		--Select * from Focas_ToolOffsetHistory where (MachineID=@MachineID or isnull(@MachineID,'')='')
		if @Param1='DashBoard'
		BEGIN
			select distinct MachineID,MachineTimeStamp,ProgramNumber,ToolNo,OffsetNo,WearOffsetX,WearOffsetZ,WearOffsetT,WearOffsetR,MachineMode,OffsetType  from [dbo].[Focas_ToolOffsetHistory]
			 where ( OffsetNo in (select offsetNo from #offsetNo)  or @OffsetNo='') and machineid=@machineid 
			 and (MachineTimeStamp>=@fromTime and MachineTimeStamp<=@ToTime) and (OffsetType=@OffsetType or isnull(@OffsetType,'')='') 
			 order by MachineTimeStamp asc;
		END

		if @Param1='top20'  --select top 20 records for table for each offset
		BEGIN
			select distinct T.MachineID,T.MachineTimeStamp,T.ProgramNumber,T.ToolNo,T.OffsetNo,T.WearOffsetX,T.WearOffsetZ,T.WearOffsetT,T.WearOffsetR,T.MachineMode,T.OffsetType
			from (
				 select T.MachineID,T.MachineTimeStamp,T.ProgramNumber,T.ToolNo,T.OffsetNo,T.WearOffsetX,T.WearOffsetZ,T.WearOffsetT,T.WearOffsetR,T.MachineMode,T.OffsetType,
						row_number() over(partition by T.OffsetNo order by T.MachineTimeStamp asc) as rn
				 from dbo.[Focas_ToolOffsetHistory] as T where ( T.OffsetNo in (select offsetNo from #offsetNo)  or @OffsetNo='')
				and T.machineid=@machineid and (T.OffsetType=@OffsetType or isnull(@OffsetType,'')='') 
				 ) as T
			where T.rn <= 20  
		END
	END
	IF @Param='Save'
	BEGIN

		Select * into #TempToolOffsetHistory from Focas_ToolOffsetHistoryTemp

		--IF EXISTS(Select * from Focas_ToolOffsetHistoryTemp A1 
		--	where (MachineID=@MachineID) and Not exists(Select * from Focas_ToolOffsetHistory A2  where A1.MachineID=A2.MachineID and A1.OffsetNo=A2.OffsetNo 
		--	and A1.WearOffsetX=A2.WearOffsetX and A1.WearOffsetZ=A2.WearOffsetZ and A1.WearOffsetR=A2.WearOffsetR and A1.WearOffsetT=A2.WearOffsetT 
		--	--and A1.CNCTimeStamp=A2.MachineTimeStamp and A1.OffsetType=A2.OffsetType)
		--	))
		--BEGIN
		--	INSERT INTO Focas_ToolOffsetHistory(MachineID,MachineTimeStamp,ProgramNumber,ToolNo,OffsetNo,WearOffsetX,WearOffsetZ,WearOffsetT,WearOffsetR,MachineMode,OffsetType)
		--	Select MachineID,CNCTimeStamp,ProgramNo,ToolNo,OffsetNo,WearOffsetX,WearOffsetZ,WearOffsetT,WearOffsetR,MachineMode,OffsetType from Focas_ToolOffsetHistoryTemp A1 
		--	where (MachineID=@MachineID) and Not exists(Select * from Focas_ToolOffsetHistory A2  where A1.MachineID=A2.MachineID and A1.OffsetNo=A2.OffsetNo 
		--	and A1.WearOffsetX=A2.WearOffsetX and A1.WearOffsetZ=A2.WearOffsetZ and A1.WearOffsetR=A2.WearOffsetR and A1.WearOffsetT=A2.WearOffsetT 
		--	--and A1.CNCTimeStamp=A2.MachineTimeStamp and A1.OffsetType=A2.OffsetType
		--	)
		--END

		IF EXISTS(Select * from #TempToolOffsetHistory A1 
						where (MachineID=@MachineID) and Not exists(Select A2.* from (select B1.* from Focas_ToolOffsetHistory B1
						inner join (Select MachineID,OffsetNo,max(MachineTimeStamp) as UTS from Focas_ToolOffsetHistory where MachineID=@MachineID
						group by  MachineID,OffsetNo) B2 on B1.MachineID=B2.MachineID and B1.OffsetNo=B2.OffsetNo  and B1.MachineTimeStamp=B2.UTS)A2
						where A1.MachineID=A2.MachineID and A1.OffsetNo=A2.OffsetNo 
						and A1.WearOffsetX=A2.WearOffsetX and A1.WearOffsetZ=A2.WearOffsetZ and A1.WearOffsetR=A2.WearOffsetR and A1.WearOffsetT=A2.WearOffsetT ))
		BEGIN
			INSERT INTO Focas_ToolOffsetHistory(MachineID,MachineTimeStamp,ProgramNumber,ToolNo,OffsetNo,WearOffsetX,WearOffsetZ,WearOffsetT,WearOffsetR,MachineMode,OffsetType)
			Select MachineID,CNCTimeStamp,ProgramNo,ToolNo,OffsetNo,WearOffsetX,WearOffsetZ,WearOffsetT,WearOffsetR,MachineMode,OffsetType from #TempToolOffsetHistory A1 
						where (MachineID=@MachineID) and Not exists(Select A2.* from (select B1.* from Focas_ToolOffsetHistory B1
						inner join (Select MachineID,OffsetNo,max(MachineTimeStamp) as UTS from Focas_ToolOffsetHistory where MachineID=@MachineID
						group by  MachineID,OffsetNo) B2 on B1.MachineID=B2.MachineID and B1.OffsetNo=B2.OffsetNo  and B1.MachineTimeStamp=B2.UTS)A2
						where A1.MachineID=A2.MachineID and A1.OffsetNo=A2.OffsetNo 
						and A1.WearOffsetX=A2.WearOffsetX and A1.WearOffsetZ=A2.WearOffsetZ and A1.WearOffsetR=A2.WearOffsetR and A1.WearOffsetT=A2.WearOffsetT )
		END

		delete from Focas_ToolOffsetHistoryTemp where id in (select distinct ID from #TempToolOffsetHistory)

	END
END
