/****** Object:  Procedure [dbo].[s_ViewInspectionDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--exec [s_ViewInspectionDetails] @Param=N'View',@MoNumber=N'444444',@ItemNo=N'TD2SMM1498 D',@operationNo=N'10',@machineid=N'ACE-01'
--[dbo].[s_ViewInspectionDetails] 'P09','980081','835-329-3035-01-C1','1','View','4'
--[dbo].[s_ViewInspectionDetails] 'SP29','985013','TLDOA1145-CP-I','1','View','4'

CREATE PROCEDURE [dbo].[s_ViewInspectionDetails]
@machineid nvarchar(50),
@MoNumber nvarchar(50),
@ItemNo nvarchar(50),
@operationNo nvarchar(50),
@Param nvarchar(50)='',
@NoOfColumnsToShow int='4'
WITH RECOMPILE
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


SET NOCOUNT ON;



create table #InspecHeader
(
	DocNo nvarchar(50),
	ItemNo nvarchar(50),
	DrawingNo nvarchar(50),
	Rev nvarchar(50),
	Product nvarchar(50),
	MoNumber nvarchar(50),
	Inprocessfreq nvarchar(50),
	MachineCenter nvarchar(50),
	UOM nvarchar(50),
	Temp nvarchar(50),
	Operationno nvarchar(50),
	InspectionDrawing nvarchar(4000),
	Datatype nvarchar(50),
	VersionNo nvarchar(50)
)

create table #InspecDetails
(
	CharteristicID nvarchar(50),
	CharacteristicCode nvarchar(100),
	LSL float,
	USL float,
	SpecificationMean nvarchar(50),
	InstrumentType nvarchar(50),
	InstrumentNo nvarchar(50),
	BatchID int,
	BatchIDRef nvarchar(50),
	BatchValue nvarchar(50) default 'xxx',
	InProcessInterval nvarchar(50) default 0,
	Datatype nvarchar(50)
)


create table #TempInspecValueHeader
(
	HeaderID int identity(1,1) Not Null,
	HeaderValue int
)

create table #InspecValueHeader
(
	HeaderID int identity(1,1) Not Null,
	HeaderValue int,
	H nvarchar(50)
)


create table #MinQualityInspecheader
(
	HeaderID int identity(1,2) Not Null,
	HeaderValue nvarchar(50)
)

create table #MaxQualityInspecheader
(
	HeaderID int identity(2,2) Not Null,
	HeaderValue nvarchar(50)
)

create table #QualityInspecheader
(
	HeaderID int,-- identity(1,1) Not Null,
	HeaderValue nvarchar(50)
)

create table #QualityInspecDetails
(
	HeaderID int,
	CharteristicID nvarchar(50),
	CharacteristicCode nvarchar(100),
	BatchID nvarchar(50),
	BatchValue nvarchar(50)
)


If @param='InstrumentNo'
BEGIN
    Select Distinct InstrumentNo from SPCAutodata where InstrumentNo IS NOT NULL
END

IF @param='View'
BEGIN


	declare @InspectionPath as nvarchar(4000)
	declare @Machineselection as int
	declare @FileExt as nvarchar(50)

	select @InspectionPath = folderpath from FolderPathDefinition where FolderType='InspectionPath'
	select @FileExt = FileExtension from FolderPathDefinition where FolderType='InspectionPath'
	select @MachineSelection = isnull(folderpath,0) from FolderPathDefinition where FolderType='MachineSelected'

	If @MachineSelection = 1
	BEGIN
		SELECT @InspectionPath=@InspectionPath + '\' + RTRIM(lTRIM(@machineid)) +'\' 
	end
		If @MachineSelection = 0
	BEGIN
		SELECT @InspectionPath=@InspectionPath + '\'
	end

If EXISTS (Select * from SPC_Characteristic SPC  where SPC.componentid=@ItemNo and SPC.Operationno=@operationNo )

BEGIN

		 --  Insert into #InspecHeader(DocNo,ItemNo,DrawingNo,Rev,Product,MoNumber,Inprocessfreq,MachineCenter,UOM,Temp,Operationno,InspectionDrawing,VersionNo)
		 --  select top 1 'SAR-M-WE5100400',@ItemNo,SPC.InspectionDrawing as DrawingNumber,'-' as Rev,SPC.Product,@MoNumber as MoNumber,SPC.InProcessInterval as Inprocessfreq,'' as MachineCenter,'MM' as UOM,'18-28 C ' as Temp
		 --  ,@operationNo,@InspectionPath + RTRIM(lTRIM(SPC.InspectionDrawing)) + @FileExt,SPC.VersionNo from  SPC_Characteristic SPC 
		 --  --inner join MOSchedule MO on SPC.componentid=MO.PartID and SPC.Operationno=MO.Operationno
		 --  --where MO.machineid=@machineid and SPC.componentid=@ItemNo and SPC.operationno=@operationNo and MO.MONumber=@MONumber
			--where SPC.componentid=@ItemNo and SPC.operationno=@operationNo

		   select DocNo,ItemNo,DrawingNo,Rev,Product,MoNumber,Inprocessfreq,MachineCenter,UOM,Temp,Operationno,InspectionDrawing,VersionNo from #InspecHeader

	
		   Insert into #TempInspecValueHeader(HeaderValue)
		   select  top (@NoOfColumnsToShow -1) T.batchid from
		   (select distinct  batchid from SPCAutodata  where MC=@machineid and COMP=@ItemNo and OPN=@operationNo and MONumber=@MONumber
		   and BatchID not like ('M%'))T
		   order by cast(dbo.SplitAlphanumeric(T.BatchID,'^0-9')as int) desc



		   Insert into #InspecValueHeader(HeaderValue)
		   select HeaderValue from #TempInspecValueHeader order by cast(dbo.SplitAlphanumeric(HeaderValue,'^0-9')as int)

		   declare @BatchIDCount as int
		   Select @BatchIDCount=ISNULL(count(*),0) from #InspecValueHeader


	   --	declare @InProcessInterval as int
	   --	Set @InProcessInterval = (select top 1 isnull(InProcessInterval,300) from SPC_Characteristic SPC 
	   --	inner join MOSchedule MO on SPC.componentid=MO.PartID and SPC.Operationno=MO.Operationno
	   --	where MO.Machineid=@machineid and SPC.componentid=@ItemNo and SPC.Operationno=@operationNo and MO.MONumber=@MONumber)

		   declare @SetupApprovalInterval as int
		 --  Set @SetupApprovalInterval = (select top 1 isnull(SetupApprovalInterval,7) from SPC_Characteristic SPC 
		 --  --inner join MOSchedule MO on SPC.componentid=MO.PartID and SPC.Operationno=MO.Operationno
		 --  --where MO.Machineid=@machineid and SPC.componentid=@ItemNo and SPC.Operationno=@operationNo and MO.MONumber=@MONumber)
			--where SPC.componentid=@ItemNo and SPC.Operationno=@operationNo)

		     Set @SetupApprovalInterval = (select top 1 isnull(MAX(SetupApprovalInterval),0) from SPC_Characteristic SPC 
		   --inner join MOSchedule MO on SPC.componentid=MO.PartID and SPC.Operationno=MO.Operationno
		   --where MO.Machineid=@machineid and SPC.componentid=@ItemNo and SPC.Operationno=@operationNo and MO.MONumber=@MONumber)
			where SPC.componentid=@ItemNo and SPC.Operationno=@operationNo)


	   --	Declare @Count as int
	   --	select @Count=1

	   --	If @BatchIDCount>0
	   --	Begin
	   --		WHILE @BatchIDCount<4
	   --		BEGIN
	   --			Insert into #InspecValueHeader(HeaderValue)
	   --			SELECT case when MAX(HEADERVALUE)=1 then @InProcessInterval else MAX(HEADERVALUE)+@InProcessInterval end FROM #InspecValueHeader 
	   --			SET @BatchIDCount = @BatchIDCount + 1
	   --		END
	   --	end
	   --
	   --	If @BatchIDCount=0
	   --	Begin
	   --		Insert into #InspecValueHeader(HeaderValue)values(1)
	   --
	   --		while @BatchIDCount<3
	   --		Begin
	   --			Insert into #InspecValueHeader(HeaderValue)
	   -- 			SELECT case when MAX(HEADERVALUE)=1 then @InProcessInterval else MAX(HEADERVALUE)+@InProcessInterval end FROM #InspecValueHeader 
	   --			SET @BatchIDCount = @BatchIDCount + 1
	   --		End
	   --
	   --	END

		   Declare @NoOfRecordsToPick as int
		   Declare @MaxheaderVal as int
		   Select @MaxheaderVal = ISNULL(MAX(HEADERVALUE),0) FROM #InspecValueHeader 

		   Declare @MaxTransactionValue as nvarchar(50)
		   SET @MaxTransactionValue = (Select top 1 T.batchid from
		   (select distinct  batchid from SPCAutodata where MC=@machineid and COMP=@ItemNo and OPN=@operationNo and MONumber=@MONumber
		   and BatchID not like ('M%'))T
		   order by cast(dbo.SplitAlphanumeric(T.BatchID,'^0-9')as int) desc)

	
		   Declare @LastTransactionValue as nvarchar(50)
		   SET @LastTransactionValue = (Select top 1 T.batchid from
		   (select batchid,Max(timestamp) as TS from SPCAutodata where MC=@machineid and COMP=@ItemNo and OPN=@operationNo and MONumber=@MONumber
		   group by batchid)T
		   order by T.Ts desc)

	

		   IF ISNULL(@MaxTransactionValue,'a')='a'
		   BEGIN
			SET @MaxTransactionValue = 0
		   END

		   IF ISNULL(@LastTransactionValue,'a')='a'
		   BEGIN
			SET @LastTransactionValue = 0
		   END


		   Declare @MOQuantity as int
		   Select @MOQuantity = Max(MO.Quantity) from  SPC_Characteristic SPC 
		   left outer join MOSchedule MO on SPC.componentid=MO.PartID --and SPC.Operationno=MO.Operationno
		   --where MO.Machineid=@machineid and SPC.componentid=@ItemNo and SPC.Operationno=@operationNo and MO.MONumber=@MONumber
		  where MO.Machineid=@machineid and SPC.componentid=@ItemNo and SPC.Operationno=@operationNo and MO.MONumber=@MONumber

		   IF ISNULL(@MOQuantity,'0')='0'
		   BEGIN
			SET @MOQuantity = 100
		   END

		 --  IF ISNULL(@SetupApprovalInterval,'0')='0'
		 --  BEGIN
			--SET @SetupApprovalInterval = 2
		 --  END

		   IF ISNULL(@SetupApprovalInterval,'0')='0'
		   BEGIN
			SET @SetupApprovalInterval = 0
		   END

		   If @MOQuantity <= @MaxTransactionValue
		   BEGIN


			   Truncate table #TempInspecValueHeader
			   Truncate Table #InspecValueHeader

			   Insert into #TempInspecValueHeader(HeaderValue)
			   select  top (@NoOfColumnsToShow) T.batchid from
			   (select distinct  batchid from SPCAutodata where MC=@machineid and COMP=@ItemNo and OPN=@operationNo and MONumber=@MONumber
			   and BatchID not like ('M%'))T
			   order by cast(dbo.SplitAlphanumeric(T.BatchID,'^0-9')as int) desc

			   Insert into #InspecValueHeader(HeaderValue)
			   select HeaderValue from #TempInspecValueHeader order by cast(dbo.SplitAlphanumeric(HeaderValue,'^0-9')as int)
		   END
		   ELSE
		   BEGIN
			   If @BatchIDCount>0
			   Begin

	
				   Select @NoOfRecordsToPick = @NoOfColumnsToShow - @BatchIDCount

				   WHILE @BatchIDCount<@NoOfColumnsToShow
				   BEGIN
				
					   If @MaxheaderVal < @SetupApprovalInterval
					   begin 
						   Insert into #InspecValueHeader(HeaderValue)
						   SELECT @MaxheaderVal+1
					   end


					   If @MaxheaderVal >= @SetupApprovalInterval
					   Begin

						   Insert into #InspecValueHeader(HeaderValue)
						   EXEC [dbo].[s_GenerateInProcessInterval] @machineid,@MoNumber,@ItemNo,@operationNo,@MaxheaderVal,@NoOfRecordsToPick,''
							If @@ROWCOUNT=0
							Begin
								Break;
							ENd
					   End

					   Select @MaxheaderVal = MAX(HEADERVALUE) FROM #InspecValueHeader 
					   SELECT @BatchIDCount = count(*) from #InspecValueHeader
					   Select @NoOfRecordsToPick = @NoOfColumnsToShow - @BatchIDCount

					   If @MaxheaderVal > @MOQuantity
					   BEGIN
						   BREAK;
					   END

				   END
			   END

			   IF @BatchIDCount=0 
			   Begin


				   Select @NoOfRecordsToPick = @NoOfColumnsToShow - @BatchIDCount

				   WHILE @BatchIDCount<@NoOfColumnsToShow
				   BEGIN

					   If @MaxheaderVal < @SetupApprovalInterval
					   begin 
						   Insert into #InspecValueHeader(HeaderValue)
						   SELECT @MaxheaderVal+1
					   end

					   If @MaxheaderVal >= @SetupApprovalInterval
					   Begin
						   Insert into #InspecValueHeader(HeaderValue)
						   EXEC [dbo].[s_GenerateInProcessInterval] @machineid,@MoNumber,@ItemNo,@operationNo,@MaxheaderVal,@NoOfRecordsToPick,''
						   If @@ROWCOUNT=0
						   Begin
								Break;
							ENd
					   End

					   Select @MaxheaderVal =MAX(HEADERVALUE) FROM #InspecValueHeader 
					   SELECT @BatchIDCount = count(*) from #InspecValueHeader
					   Select @NoOfRecordsToPick = @NoOfColumnsToShow - @BatchIDCount

					   If @MaxheaderVal > @MOQuantity
					   BEGIN
						   BREAK;
					   END
				   END
			   END
		   END

		   update #InspecValueHeader set H=cast(headervalue as nvarchar(50)) +'[InstrumentNo]'


		   Insert into #InspecDetails(CharteristicID,CharacteristicCode,LSL,USL,SpecificationMean,BatchID,Datatype,InstrumentType,batchidref)
		   select SPC.CharacteristicID,SPC.CharacteristicCode,SPC.LSL,SPC.USL,SPC.SpecificationMean,I.headervalue,isnull(SPC.Datatype,2),SPC.InstrumentType,I.H from  SPC_Characteristic SPC 
		   --left outer join MOSchedule MO on SPC.componentid=MO.PartID and SPC.Operationno=MO.Operationno
		   cross join #InspecValueHeader I 
		   --where MO.Machineid=@machineid and SPC.componentid=@ItemNo and SPC.Operationno=@operationNo and MO.MONumber=@MONumber
			where SPC.componentid=@ItemNo and SPC.Operationno=@operationNo 
		   order by cast(dbo.SplitAlphanumeric(SPC.CharacteristicID,'^0-9')as int),cast(dbo.SplitAlphanumeric(I.headervalue,'^0-9')as int) 


		   Update #InspecDetails set BatchValue = T.BatchVal  from 
		   (Select I.CharteristicID,I.BatchID,isnull(A.value,'xxx') as BatchVal from #InspecDetails I
		    Left Outer join SPCAutodata A on A.Dimension=I.CharteristicID and A.BatchID=I.BatchID
		    --left outer join MOSchedule MO on A.mc=MO.Machineid and A.comp=MO.PartID and A.opn=MO.Operationno and MO.MONumber=A.MONumber
		    Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
		    where A.mc=@machineid and A.comp=@ItemNo and A.opn=@operationNo and A.MONumber=@MONumber and A.batchid not like ('M%') )T
		   inner join #InspecDetails I on T.CharteristicID=I.CharteristicID and T.BatchID=I.BatchID


	

		  Update #InspecDetails set InstrumentNo =  T1.InstrumentNo  from 
		  (select T.CharteristicID,T.BatchID,T.InstrumentNo
		  from (
				 select A.dimension as CharteristicID,A.BatchID,A.InstrumentNo,
				  row_number() over(partition by A.dimension order by A.BatchTS desc) as rn
				  from  SPCAutodata A 
				  --left outer join MOSchedule MO on A.mc=MO.Machineid and A.comp=MO.PartID and A.opn=MO.Operationno and MO.MONumber=A.MONumber
				  Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
				  where  A.InstrumentNo<>'' and A.InstrumentNo IS NOT NULL and A.mc=@machineid and A.comp=@ItemNo and A.opn=@operationNo and A.MONumber=@MONumber
			  ) as T inner join #InspecDetails I on T.CharteristicID=I.CharteristicID 
		  where T.rn <= 1)T1
		  inner join #InspecDetails I on T1.CharteristicID=I.CharteristicID  where I.InstrumentNo IS NULL


		   --Update #InspecDetails set InProcessInterval = T.InProcessInterval  from 
		   --(Select I.CharteristicID,I.BatchID,case when I.BatchID<=@SetupApprovalInterval then 1 else 0 end as InProcessInterval from #InspecDetails I
		   -- inner Join SPC_Characteristic SPC on I.CharteristicID=SPC.CharacteristicID
		   -- where SPC.componentid=@ItemNo and SPC.Operationno=@operationNo)T
		   --inner join #InspecDetails I on T.CharteristicID=I.CharteristicID and T.BatchID=I.BatchID

		    Update #InspecDetails set InProcessInterval = T.InProcessInterval  from 
		   (Select I.CharteristicID,I.BatchID,case when I.BatchID<=SPC.SetupApprovalInterval then 1 else 0 end as InProcessInterval from #InspecDetails I
		    inner Join SPC_Characteristic SPC on I.CharteristicID=SPC.CharacteristicID
		    where SPC.componentid=@ItemNo and SPC.Operationno=@operationNo)T
		   inner join #InspecDetails I on T.CharteristicID=I.CharteristicID and T.BatchID=I.BatchID


		   Update #InspecDetails set InProcessInterval = T.InProcessInterval  from 
		   (Select I.CharteristicID,I.BatchID,case (I.BatchID  % SPC.InProcessInterval)
		    when  0 then 1 else I.InProcessInterval end as InProcessInterval from #InspecDetails I
		    inner Join SPC_Characteristic SPC on I.CharteristicID=SPC.CharacteristicID
		    where SPC.componentid=@ItemNo and SPC.Operationno=@operationNo and SPC.InProcessInterval IS NOT NULL and SPC.InProcessInterval>0 )T
		   inner join #InspecDetails I on T.CharteristicID=I.CharteristicID and T.BatchID=I.BatchID



--		   Insert into #QualityInspecheader(HeaderValue)
--		   select  top 4 T.batchid from
--		   (select distinct  batchid from SPCAutodata  where MC=@machineid and COMP=@ItemNo and OPN=@operationNo and MONumber=@MONumber
--		   and batchid like ('Q%'))T
--		   order by T.BatchID

--		   If @QBatchIDCount = 0
--		   Begin
--			 Insert into #QualityInspecheader(HeaderValue)
--			 Select 'Q1'
--		   End

--		   If @QBatchIDCount > 0
--		   Begin
--		   	 Select @MaxQBatchID = MAX(HeaderValue) from #QualityInspecheader
--
--			 Insert into #QualityInspecheader(HeaderValue)
--			 select 'Q' + cast((SUBSTRING(@MaxQBatchID,2,len(@MaxQbatchid)) + 1) as nvarchar(10))
--		   End

		   select Top 4  T.batchid into #MinBatchID from
		   (select distinct  batchid from SPCAutodata  where MC=@machineid and COMP=@ItemNo and OPN=@operationNo and MONumber=@MONumber
		   and batchid like ('M%'))T
		   order by T.BatchID desc


		   Declare @CountOFRecInSPCAutodata as int
		   Select @CountOFRecInSPCAutodata = ISNULL(Count(*),0) from #MinBatchID

		   Declare @LastRecInSPCAutodata as nvarchar(50)
		   Select @LastRecInSPCAutodata	= (Select Top 1 ISNULL(T.batchid,'a') from #MinBatchID  T order by T.BatchID desc)

	   
		   declare @MaxRecordToGenerate as int
		   Select @MaxRecordToGenerate = case when @LastRecInSPCAutodata<>'a' then cast((SUBSTRING(@LastRecInSPCAutodata,4,len(@LastRecInSPCAutodata)) + 1) as nvarchar(10)) else '1' END 

		   Declare @MinRecordToGenerate as int,@RefMinRecordToGenerate as int
		   Select @MinRecordToGenerate = @MaxRecordToGenerate - @CountOFRecInSPCAutodata
		   If @MinRecordToGenerate <= '0'
		   Begin
			Select @MinRecordToGenerate = 1
		   END
		   Select @RefMinRecordToGenerate = @MinRecordToGenerate

		   declare @MinBatchIDCount as int,@MaxBatchIDCount as int,@MaxQBatchID as nvarchar(50),@MaxQHeaderID as int
		   Select @MinBatchIDCount=ISNULL(count(*),0) from SPCAutodata where MC=@machineid and COMP=@ItemNo and OPN=@operationNo and MONumber=@MONumber
		   and batchid like ('Min%') 
		   Select @MaxBatchIDCount=ISNULL(count(*),0) from SPCAutodata where MC=@machineid and COMP=@ItemNo and OPN=@operationNo and MONumber=@MONumber
		   and batchid like ('Max%') 

			
	
		   If @MinBatchIDCount = 0 AND @MaxBatchIDCount = 0
		   Begin
			 Insert into #QualityInspecheader(HeaderID,HeaderValue)
			 Select '1','Min1'
	
			 Insert into #QualityInspecheader(HeaderID,HeaderValue)
			 Select '2','Max1'
		   End

		   If @MinBatchIDCount > 0 or @MaxBatchIDCount > 0  
		   Begin
			 
			 Select @MaxQHeaderID = 1

			 WHILE @RefMinRecordToGenerate<= @MaxRecordToGenerate
			 BEGIN

			 Insert into #QualityInspecheader(HeaderID,HeaderValue)
			 select @MaxQHeaderID,'Min' + cast(@RefMinRecordToGenerate as nvarchar(10))
		     Select @MaxQHeaderID = ISNULL(MAX(HeaderID),1) + 2 from #QualityInspecheader where HeaderValue like ('Min%') 
			 Select @RefMinRecordToGenerate = @RefMinRecordToGenerate + 1

			 END
			 
			 Select @MaxQHeaderID = 2

			 WHILE @MinRecordToGenerate<= @MaxRecordToGenerate
			 BEGIN

			 Insert into #QualityInspecheader(HeaderID,HeaderValue)
			 select @MaxQHeaderID,'Max' + cast(@MinRecordToGenerate as nvarchar(10))
		     Select @MaxQHeaderID = ISNULL(MAX(HeaderID),1) + 2 from #QualityInspecheader where HeaderValue like ('Max%') 
			 Select @MinRecordToGenerate = @MinRecordToGenerate + 1

			 END

		   ENd

		   Insert into #QualityInspecDetails(HeaderID,CharteristicID,CharacteristicCode,BatchID)
		   select I.HeaderID,SPC.CharacteristicID,SPC.CharacteristicCode,I.headervalue from  SPC_Characteristic SPC 
		   --left outer join MOSchedule MO on SPC.componentid=MO.PartID and SPC.Operationno=MO.Operationno
		   cross join #QualityInspecheader I 
		   --where MO.Machineid=@machineid and SPC.componentid=@ItemNo and SPC.Operationno=@operationNo and MO.MONumber=@MONumber
			where SPC.componentid=@ItemNo and SPC.Operationno=@operationNo 
		   order by cast(dbo.SplitAlphanumeric(SPC.CharacteristicID,'^0-9')as int),I.HeaderID

		   
		   Update #QualityInspecDetails set BatchValue = T.BatchVal  from 
		   (Select I.CharteristicID,I.BatchID,isnull(A.value,'xxx') as BatchVal from #QualityInspecDetails I
		    Left Outer join SPCAutodata A on A.Dimension=I.CharteristicID and A.BatchID=I.BatchID
		    --left outer join MOSchedule MO on A.mc=MO.Machineid and A.comp=MO.PartID and A.opn=MO.Operationno and MO.MONumber=A.MONumber
		    Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
		    where A.mc=@machineid and A.comp=@ItemNo and A.opn=@operationNo and A.MONumber=@MONumber and A.BatchID like ('M%'))T
		   inner join #QualityInspecDetails I on T.CharteristicID=I.CharteristicID and T.BatchID=I.BatchID



		   DECLARE @DynamicPivotQuery AS NVARCHAR(2000),@DynamicPivotQuery1 AS NVARCHAR(2000),@DynamicPivotQuery2 AS NVARCHAR(2000);
		   DECLARE @ColumnName AS NVARCHAR(2000);
		  DECLARE @SelectColumnName AS NVARCHAR(2000),@SelectColumnName1 AS NVARCHAR(2000),@SelectColumnName2 AS NVARCHAR(2000);

   
			SELECT @SelectColumnName= ISNULL(@SelectColumnName + ',','') 
		    + QUOTENAME(HeaderValue)
			FROM (select distinct HeaderValue from #InspecValueHeader) AS BatchValues 



		   SET @DynamicPivotQuery = 
		   N'
		   SELECT CharteristicID,CharacteristicCode,LSL,USL,SpecificationMean,InstrumentType,' + @SelectColumnName + ',Datatype into ##I
		   FROM (select CharteristicID,CharacteristicCode,LSL,USL,SpecificationMean,InstrumentType,batchid,case when batchvalue=''xxx'' then ''|'' + InProcessInterval 
		   when batchvalue<>''xxx'' then batchvalue + ''|'' + InProcessInterval end as batchvalue,Datatype
		   from #InspecDetails inner join #InspecValueHeader on #InspecDetails.batchid=#InspecValueHeader.HeaderValue
		   )as s 
		   PIVOT (max(batchvalue)
		   FOR [batchid] IN (' + @SelectColumnName + ')) AS PVTTable1
		   order by cast(dbo.SplitAlphanumeric(CharteristicID,''^0-9'')as int)'


		   EXEC sp_executesql @DynamicPivotQuery



		   IF @MaxTransactionValue <> '0'
		   BEGIN
			   SELECT @SelectColumnName1= ISNULL(@SelectColumnName1 + ',','') 
		    + QUOTENAME(h)
			FROM (select distinct H from #InspecValueHeader where H=@MaxTransactionValue + '[InstrumentNo]') AS BatchValues 
		   END

		   IF @MaxTransactionValue = '0'
		   BEGIN
			   SELECT @SelectColumnName1= ISNULL(@SelectColumnName1 + ',','') 
		    + QUOTENAME(h)
			FROM (select top 1 H from #InspecValueHeader order by HeaderID) AS BatchValues 
		   END


		   SET @DynamicPivotQuery1 = 
		   N'
		   SELECT ' + @SelectColumnName1 + ' as InstrumentNo,CharteristicID as RefColumn into  ##I1
		   FROM (select CharteristicID,batchidref,InstrumentNo
		   from #InspecDetails inner join #InspecValueHeader on #InspecDetails.batchidref=#InspecValueHeader.H
		   )as s 
		   PIVOT (max(InstrumentNo)
		   FOR [batchidref] IN (' + @SelectColumnName1 + ')) AS PVTTable2
		   order by cast(dbo.SplitAlphanumeric(CharteristicID,''^0-9'')as int)'

		   EXEC sp_executesql @DynamicPivotQuery1
--
--		   SELECT @SelectColumnName2= ISNULL(@SelectColumnName2 + ',','') 
--		    + QUOTENAME(HeaderValue)
--			FROM (select HeaderValue from #QualityInspecheader) AS BatchValues 

			SELECT @SelectColumnName2 = COALESCE(@SelectColumnName2 + ', ', '') + 
			ISNULL(HeaderValue, 'N/A')
			FROM #QualityInspecheader order by headerid


		   SET @DynamicPivotQuery2 = 
		   N'
		   SELECT ' + @SelectColumnName2 + ',CharteristicID as RefColumn into  ##I2
		   FROM (select CharteristicID,batchid,batchvalue
		   from #QualityInspecDetails inner join #QualityInspecheader on #QualityInspecheader.HeaderValue=#QualityInspecDetails.batchid
		   )as s 
		   PIVOT (max(batchvalue)
		   FOR [batchid] IN (' + @SelectColumnName2 + ')) AS PVTTable2
		   order by cast(dbo.SplitAlphanumeric(CharteristicID,''^0-9'')as int)'

		   EXEC sp_executesql @DynamicPivotQuery2


		   DECLARE @sqlText nvarchar(1000); 

		  SET @sqlText = N'SELECT ##I1.InstrumentNo,##I.*,##I2. ' + @SelectColumnName2 + ' FROM  ##I 
		   left outer join ##I1 on ##I.CharteristicID=##I1.RefColumn
		   left outer join ##I2 on ##I.CharteristicID=##I2.RefColumn
		   left outer join SPC_Characteristic SPC on ##I.CharteristicID=SPC.CharacteristicID
		   where SPC.componentid=''' + @ItemNo + ''' and SPC.Operationno=''' + @operationNo + '''
		   order by cast(dbo.SplitAlphanumeric(SPC.SortOrder,''^0-9'')as int)'
		  Exec (@sqlText)


		   IF OBJECT_ID('tempdb.dbo.##I', 'U') IS NOT NULL
		   BEGIN
		    drop table ##I
		   END


		   IF OBJECT_ID('tempdb.dbo.##I1', 'U') IS NOT NULL
		   BEGIN
		    drop table ##I1
		   END

		  IF OBJECT_ID('tempdb.dbo.##I2', 'U') IS NOT NULL
		   BEGIN
		    drop table ##I2
		   END

END
ELSE
BEGIN
  
    RAISERROR('Master(SPC_Characteristic Table) does not exist for the given Component-Operation',16,1)
    return -1;

END

END

END
