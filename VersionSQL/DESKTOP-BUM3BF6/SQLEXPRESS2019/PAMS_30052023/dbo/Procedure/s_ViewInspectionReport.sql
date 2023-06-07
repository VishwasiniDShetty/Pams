/****** Object:  Procedure [dbo].[s_ViewInspectionReport]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec [dbo].[s_ViewInspectionReport] '2021-12-21 06:00:00.000','2021-12-23 06:00:00.000','CM02P','490-126-3001-01','1','','P21171540','GridAndReport','With InstrumentNo'
exec [dbo].[s_ViewInspectionReport] '2021-12-21 06:00:00.000','2021-12-23 06:00:00.000','CM02P','490-126-3001-01','1','','P21171540','GridAndReport','Without InstrumentNo'

exec [dbo].[s_ViewInspectionReport] '2022-09-10 06:00:00.000','2022-09-15 06:00:00.000','G16','TXYGBB0192-WS','1','','P22260823','GridAndReport','With InstrumentNo'
exec [dbo].[s_ViewInspectionReport] '2022-09-10 06:00:00.000','2022-09-15 06:00:00.000','G16','TXYGBB0192-WS','1','','P22260823','GridAndReport','Without InstrumentNo'

exec [dbo].[s_ViewInspectionReport] '2019-11-15 06:00:00.000','2019-11-17 06:00:00.000','CM07P','TXYFBB0524-B1','1','','980800','GridAndReport','With InstrumentNo'
exec [dbo].[s_ViewInspectionReport] '2019-11-15 06:00:00.000','2019-11-17 06:00:00.000','CM07P','TXYFBB0524-B1','1','','980800','GridAndReport','Without InstrumentNo'

*/
CREATE    PROCEDURE [dbo].[s_ViewInspectionReport]
@Fromtime datetime,
@Totime Datetime,
@machineid nvarchar(50),
@ItemNo nvarchar(50)='',
@operationNo nvarchar(50)='',
@DimensionID nvarchar(50)='',
@MONumber nvarchar(50)='',
@param nvarchar(50)='',
@Type nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

declare @Starttime as datetime
declare @endtime as datetime

select @Starttime  = dbo.f_GetLogicalDay(@Fromtime,'start')
select @endtime = dbo.f_GetLogicalDay(@Totime,'end')

IF OBJECT_ID('tempdb.dbo.##I', 'U') IS NOT NULL
BEGIN
drop table ##I
END


IF OBJECT_ID('tempdb.dbo.##I1', 'U') IS NOT NULL
BEGIN
drop table ##I1
END


If @param='MONumber'
BEGIN
	   select distinct MO.Monumber from SPCAutodata A 
	   inner join machineinformation M on M.machineid=A.mc
	   inner join MOschedule MO on A.MONumber=MO.MONumber
	   where (A.[BatchTS]>=@Starttime and A.[BatchTS]<=@endtime) 
	   --and M.machineid=@machineid  --Swathi commented to display MONumbers irrespective of Machine for the given timeperiod.
	   and M.machineid=@machineid  -- Anjana Uncommented : July 6th 2020
END

If @param = 'Dimension'
Begin
select distinct CharacteristicCode from SPC_Characteristic where  componentid= @ItemNo and OperationNo= @operationNo
End


If @param='GetCOList'
BEGIN
	Select Distinct sp.Componentid,sp.Operationno 
	from spcautodata A
	inner join machineinformation M on M.machineid=A.mc		
	inner join SPC_Characteristic SP on  A.comp=SP.Componentid	
	inner join MOschedule MO on A.MONumber=MO.MONumber
	where
	-- (A.[BatchTS]>=@Starttime and A.[BatchTS]<=@endtime)and 
	--M.machineid=@machineid and --Swathi commented machine filter
	MO.MONumber=@MONumber
	Order by sp.Componentid,sp.Operationno
END

--If @param='GetCOList'
--BEGIN
--	Select Distinct CO.Componentid,CO.Operationno from spcautodata A
--	inner join machineinformation M on M.machineid=A.mc
--	inner join Componentinformation CI on CI.componentid=A.comp
--	inner join Componentoperationpricing CO on CO.operationno=A.opn and 
--	CO.machineid=M.machineid and CO.componentid=CI.Componentid
--	inner join SPC_Characteristic SP on  CO.componentid=SP.Componentid
--	and CO.operationno=SP.operationno and A.Dimension=SP.CharacteristicID
--	inner join MOschedule MO on A.MONumber=MO.MONumber
--	where (A.[BatchTS]>=@Starttime and A.[BatchTS]<=@endtime)and 
--	M.machineid=@machineid and MO.MONumber=@MONumber
--	Order by CO.Componentid,CO.Operationno
--END


if @param='GridAndReport'
BEGIN
create table #InspecDetails
(
	CharteristicID nvarchar(50),
	CharacteristicCode nvarchar(100),
	LSL float,
	USL float,
	SpecificationMean nvarchar(50),
	InstrumentType nvarchar(50),
	InstrumentNo nvarchar(50) default 'NA',
	BatchID nvarchar(50),
	InstrumentBatchID nvarchar(50),
	BatchValue nvarchar(50),
	SortOrder int
)

create table #InspecValueHeader
(
	HeaderID int identity(1,1) Not Null,
	HeaderValue nvarchar(50),
	H nvarchar(50)
)

create table #TempInspecValueHeader
(
	HeaderID int identity(1,1) Not Null,
	HeaderValue nvarchar(50),
	BatchTS datetime
)

	declare @CharID as nvarchar(50),@SortOrder as nvarchar(50)

	Insert into #TempInspecValueHeader(HeaderValue,BatchTS)
     Select distinct A.batchid,MAX(A.BatchTS) from SPCAutodata A 
	--inner join MOSchedule MO on A.mc=MO.Machineid and A.comp=MO.PartID and A.opn=MO.Operationno and MO.MONumber=A.MONumber
	inner Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
	where 
	--A.BatchTS>=@Starttime and A.BatchTS<=@endtime and
	-- A.mc=@machineid and --Commented machine filter
	 A.comp=@ItemNo and A.opn=@operationNo and (@DimensionID='' or SPC.CharacteristicCode=@DimensionID)
	and A.MONumber=@MONumber group by A.Batchid
	order by MAX(A.BatchTS)



	Insert into #InspecValueHeader(HeaderValue,H)
	select HeaderValue,HeaderValue + 'I' from #TempInspecValueHeader order by headerid




	Insert into #InspecDetails(CharteristicID,CharacteristicCode,LSL,USL,SpecificationMean,InstrumentType,BatchID,InstrumentBatchID,SortOrder)
	Select SPC.CharacteristicID,SPC.CharacteristicCode,SPC.LSL,SPC.USL,SPC.SpecificationMean,SPC.InstrumentType,I.headervalue,I.H,SPC.SortOrder 
	from SPC_Characteristic SPC
     --left outer join MOSchedule MO on SPC.componentid=MO.PartID and SPC.Operationno=MO.Operationno
    cross join #InspecValueHeader I  
    where SPC.componentid=@ItemNo and SPC.Operationno=@operationNo and (@DimensionID='' or SPC.CharacteristicCode=@DimensionID)
    order by cast(dbo.SplitAlphanumeric(SPC.CharacteristicID,'^0-9')as int),cast(dbo.SplitAlphanumeric(I.headerid,'^0-9')as int) 




	--select @CharID = MAX(CharteristicID) from #InspecDetails 
	SET @CharID = (Select top 1 CharteristicID from #InspecDetails order by cast(dbo.SplitAlphanumeric(CharteristicID,'^0-9')as int) desc )
	SET @SortOrder = (Select top 1 SortOrder from #InspecDetails order by cast(dbo.SplitAlphanumeric(SortOrder,'^0-9')as int) desc )


	Insert into #InspecDetails(CharteristicID,CharacteristicCode,BatchID,SortOrder)
	Select cast(@CharID  as int) + 1,'SampleSize',I.headervalue,cast(@SortOrder as int)+1 from #InspecValueHeader I

	SET @CharID = (Select top 1 CharteristicID from #InspecDetails order by cast(dbo.SplitAlphanumeric(CharteristicID,'^0-9')as int) desc )
	SET @SortOrder = (Select top 1 SortOrder from #InspecDetails order by cast(dbo.SplitAlphanumeric(SortOrder,'^0-9')as int) desc )


	Insert into #InspecDetails(CharteristicID,CharacteristicCode,BatchID,SortOrder)
	Select cast(@CharID  as int) + 1,'LotSize',I.headervalue,cast(@SortOrder as int)+1 from #InspecValueHeader I


	Update #InspecDetails set BatchValue = T.SampleSize  from 
	(Select I.BatchID,Max(S.SampleSize) as SampleSize from  #InspecDetails I
	Left Outer join SPCAutodata A on  A.BatchID=I.BatchID
    --left outer join MOSchedule MO on A.mc=MO.Machineid and A.comp=MO.PartID and A.opn=MO.Operationno and MO.MONumber=A.MONumber
    left outer join SPC_SampleInfo S on A.mc=S.mc and A.comp=S.comp and A.opn=S.opn and S.MONumber=A.MONumber and A.opr=S.opr and A.batchid=S.Batchid
    Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
    where 
	--A.mc=@machineid and --Commented machine filter
	A.comp=@ItemNo and A.opn=@operationNo and A.MONumber=@MONumber and A.batchid like ('M%')
	group by I.BatchID
	)T inner join #InspecDetails I on T.BatchID=I.BatchID where I.CharacteristicCode='SampleSize' 

	Update #InspecDetails set BatchValue = T.LottSize  from 
	(Select I.BatchID,Max(S.LottSize) as LottSize from  #InspecDetails I
	 Left Outer join SPCAutodata A on  A.BatchID=I.BatchID
    --left outer join MOSchedule MO on A.mc=MO.Machineid and A.comp=MO.PartID and A.opn=MO.Operationno and MO.MONumber=A.MONumber
    left outer join SPC_SampleInfo S on A.mc=S.mc and A.comp=S.comp and A.opn=S.opn and S.MONumber=A.MONumber and A.opr=S.opr and A.batchid=S.Batchid
    Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
    where 
	--A.mc=@machineid and --Commented machine filter
	A.comp=@ItemNo and A.opn=@operationNo and A.MONumber=@MONumber and A.batchid like ('M%')
	group by I.BatchID
	)T inner join #InspecDetails I on T.BatchID=I.BatchID where I.CharacteristicCode='LotSize'  

	SET @CharID = (Select top 1 CharteristicID from #InspecDetails order by cast(dbo.SplitAlphanumeric(CharteristicID,'^0-9')as int) desc )	
	SET @SortOrder = (Select top 1 SortOrder from #InspecDetails order by cast(dbo.SplitAlphanumeric(SortOrder,'^0-9')as int) desc )

	Insert into #InspecDetails(CharteristicID,CharacteristicCode,BatchID,SortOrder)
	Select cast(@CharID  as int) + 1,'Employee',I.headervalue,cast(@SortOrder as int)+1 from #InspecValueHeader I


	Update #InspecDetails set BatchValue = T.Oprerator  from 
	(Select I.BatchID,Max(A.opr) as Oprerator from  #InspecDetails I
	 Left Outer join SPCAutodata A on A.Dimension=I.CharteristicID and A.BatchID=I.BatchID
	 --left outer join MOSchedule MO on A.mc=MO.Machineid and A.comp=MO.PartID and A.opn=MO.Operationno and MO.MONumber=A.MONumber
	 Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
	 where-- A.BatchTS>=@Starttime and A.BatchTS<=@endtime and 
	 --A.mc=@machineid and --Commented machine filter
	 A.comp=@ItemNo and A.opn=@operationNo and (@DimensionID='' or SPC.CharacteristicCode=@DimensionID)
	 and A.MONumber=@MONumber group by I.BatchID)T
	inner join #InspecDetails I on T.BatchID=I.BatchID where I.CharacteristicCode='Employee' 

	--------------------------------------------- get last updated date and time  at comp-> opr -> batchID level -----------------------------------
	SET @CharID = (Select top 1 CharteristicID from #InspecDetails order by cast(dbo.SplitAlphanumeric(CharteristicID,'^0-9')as int) desc )	
	SET @SortOrder = (Select top 1 SortOrder from #InspecDetails order by cast(dbo.SplitAlphanumeric(SortOrder,'^0-9')as int) desc )

	Insert into #InspecDetails(CharteristicID,CharacteristicCode,BatchID,SortOrder)
	Select cast(@CharID  as int) + 1,'LastUpdatedDate',I.headervalue,cast(@SortOrder as int)+1 from #InspecValueHeader I

	Update #InspecDetails set BatchValue = T.TS  from 
	(Select I.BatchID,convert(nvarchar(10),Max(A.Timestamp),120) as TS from  #InspecDetails I
	 Left Outer join SPCAutodata A on A.Dimension=I.CharteristicID and A.BatchID=I.BatchID
	 Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
	 where
	 A.comp=@ItemNo and A.opn=@operationNo and (@DimensionID='' or SPC.CharacteristicCode=@DimensionID)
	 and A.MONumber=@MONumber group by I.BatchID)T
	inner join #InspecDetails I on T.BatchID=I.BatchID where I.CharacteristicCode='LastUpdatedDate' 

	SET @CharID = (Select top 1 CharteristicID from #InspecDetails order by cast(dbo.SplitAlphanumeric(CharteristicID,'^0-9')as int) desc )	
	SET @SortOrder = (Select top 1 SortOrder from #InspecDetails order by cast(dbo.SplitAlphanumeric(SortOrder,'^0-9')as int) desc )

	Insert into #InspecDetails(CharteristicID,CharacteristicCode,BatchID,SortOrder)
	Select cast(@CharID  as int) + 1,'LastUpdatedTime',I.headervalue,cast(@SortOrder as int)+1 from #InspecValueHeader I


	Update #InspecDetails set BatchValue = T.TS  from 
	(Select I.BatchID,cast(Max(A.Timestamp) as Time) as TS from  #InspecDetails I
	 Left Outer join SPCAutodata A on A.Dimension=I.CharteristicID and A.BatchID=I.BatchID
	 Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
	 where
	 A.comp=@ItemNo and A.opn=@operationNo and (@DimensionID='' or SPC.CharacteristicCode=@DimensionID)
	 and A.MONumber=@MONumber group by I.BatchID)T
	inner join #InspecDetails I on T.BatchID=I.BatchID where I.CharacteristicCode='LastUpdatedTime' 


	--------------------------------------------- get last updated date and time  at comp-> opr -> batchID level -----------------------------------


	 Update #InspecDetails set BatchValue = T.BatchVal  from 
	(Select I.CharteristicID,I.BatchID,isnull(A.value,'xxx') as BatchVal from #InspecDetails I
	 Left Outer join SPCAutodata A on A.Dimension=I.CharteristicID and A.BatchID=I.BatchID
	 --left outer join MOSchedule MO on A.mc=MO.Machineid and A.comp=MO.PartID and A.opn=MO.Operationno and MO.MONumber=A.MONumber
	 Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
	 where --A.BatchTS>=@Starttime and A.BatchTS<=@endtime and 
	 --A.mc=@machineid and --Commented machine filter
	 A.comp=@ItemNo and A.opn=@operationNo and (@DimensionID='' or SPC.CharacteristicCode=@DimensionID)
	 and A.MONumber=@MONumber )T
	inner join #InspecDetails I on T.CharteristicID=I.CharteristicID and T.BatchID=I.BatchID
	 where I.CharacteristicCode not in ('SampleSize','LotSize' ,'Employee','LastUpdatedDate','LastUpdatedTime' )

	Update #InspecDetails set InstrumentNo = T.InstrumentNo  from 
	(Select I.CharteristicID,I.BatchID,isnull(A.InstrumentNo,'NA') as InstrumentNo from #InspecDetails I
	 Left Outer join SPCAutodata A on A.Dimension=I.CharteristicID and A.BatchID=I.BatchID
	 --left outer join MOSchedule MO on A.mc=MO.Machineid and A.comp=MO.PartID and A.opn=MO.Operationno and MO.MONumber=A.MONumber
	 Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
	 where --A.BatchTS>=@Starttime and A.BatchTS<=@endtime and 
	-- A.mc=@machineid and --Commented machine filter
	 A.comp=@ItemNo and A.opn=@operationNo and (@DimensionID='' or SPC.CharacteristicCode=@DimensionID)
	 and A.MONumber=@MONumber )T
	inner join #InspecDetails I on T.CharteristicID=I.CharteristicID and T.BatchID=I.BatchID

	--select * from #InspecDetails
 --   Select I.CharteristicID,I.BatchID,isnull(A.InstrumentNo,'NA') as InstrumentNo 
	--from #InspecDetails I
	-- Left Outer join SPCAutodata A on A.Dimension=I.CharteristicID and A.BatchID=I.BatchID
	-- Left outer Join SPC_Characteristic SPC on SPC.componentid=A.comp and SPC.Operationno=A.opn and A.Dimension=SPC.CharacteristicID
	-- where  A.comp=@ItemNo and A.opn=@operationNo 
	-- and (@DimensionID='' or SPC.CharacteristicCode=@DimensionID)
	-- and A.MONumber=@MONumber 



    create table #InspecDetails1
    (
    Slno bigint identity (1,1) not null, 
    CharteristicID nvarchar(50),
    InstrumentNo nvarchar(50),
    BatchID nvarchar(50),
    InstrumentBatchID nvarchar(50),
	SortOrder int
    )


    create table #InspecDetails2
    (
    Slno bigint identity (1,1) not null, 
    CharteristicID nvarchar(50),
    InstrumentNo nvarchar(50),
    BatchID nvarchar(50),
    InstrumentBatchID nvarchar(50),
	SortOrder int
    )

	Insert into #InspecDetails1(CharteristicID,InstrumentNo,BatchID,InstrumentBatchID,SortOrder)
	select CharteristicID,InstrumentNo,BatchID,InstrumentBatchID,SortOrder from
	(Select distinct CharteristicID,InstrumentNo,BatchID,InstrumentBatchID,SortOrder from #InspecDetails
	where InstrumentNo<>'' and InstrumentNo is NOT NULL and InstrumentNo<>'NA') T 
     inner join #InspecValueHeader I on I.HeaderValue=T.BatchID
	order by cast(dbo.SplitAlphanumeric(I.HeaderID,'^0-9')as int),cast(dbo.SplitAlphanumeric(CharteristicID,'^0-9')as int)



	declare @TableReccount as int,@i as int
	Select @TableReccount = Count(*) from #InspecValueHeader
	select @i = 1


    Insert into #InspecDetails2(CharteristicID,InstrumentNo,BatchID,InstrumentBatchID,SortOrder)
    select  CharteristicID,InstrumentNo,BatchID,InstrumentBatchID,SortOrder 
	from #InspecDetails1 
    inner join #InspecValueHeader on #InspecDetails1.InstrumentBatchID=#InspecValueHeader.H
    where #InspecValueHeader.HeaderID=@i
    --where batchid in(select HeaderValue from #InspecValueHeader where HeaderID=@i)
    order by cast(dbo.SplitAlphanumeric(#InspecValueHeader.HeaderID,'^0-9')as int)

    


    select @i=2

	While @i <=@TableReccount
	Begin	   

	   if exists(select InstrumentNo from #InspecDetails1 
	    inner join #InspecValueHeader on #InspecDetails1.InstrumentBatchID=#InspecValueHeader.H
	    where #InspecValueHeader.HeaderID=@i
	   and InstrumentNo not in(select Instrumentno from #InspecDetails2 inner join #InspecValueHeader on #InspecDetails2.InstrumentBatchID=#InspecValueHeader.H where #InspecValueHeader.headerid= @i-1))
	   Begin
			 Insert into #InspecDetails2(CharteristicID,InstrumentNo,BatchID,InstrumentBatchID,SortOrder)
			 select  CharteristicID,InstrumentNo,BatchID,InstrumentBatchID,SortOrder from #InspecDetails1 
			  inner join #InspecValueHeader on #InspecDetails1.InstrumentBatchID=#InspecValueHeader.H
			  where #InspecValueHeader.HeaderID=@i
			 order by cast(dbo.SplitAlphanumeric(#InspecValueHeader.HeaderID,'^0-9')as int)
	   END

	   --Insert into #InspecDetails2(CharteristicID,InstrumentNo,BatchID,InstrumentBatchID)
	   --select  #InspecDetails1.CharteristicID,#InspecDetails1.InstrumentNo,(select HeaderValue from #InspecValueHeader where HeaderID=@i),(select H from #InspecValueHeader where HeaderID=@i) from #InspecDetails1
	   --inner join #InspecValueHeader on #InspecDetails1.InstrumentBatchID=#InspecValueHeader.H
	   --where #InspecValueHeader.HeaderID=@i-1
	   --and #InspecDetails1.InstrumentNo not in(select Instrumentno from #InspecDetails2 inner join #InspecValueHeader on #InspecDetails2.InstrumentBatchID=#InspecValueHeader.H where #InspecValueHeader.headerid= @i)
	   ----and #InspecDetails1.CharteristicID not in(select CharteristicID from #InspecDetails2 inner join #InspecValueHeader on #InspecDetails2.InstrumentBatchID=#InspecValueHeader.H where #InspecValueHeader.headerid= @i)			 
	   --order by cast(dbo.SplitAlphanumeric(#InspecValueHeader.HeaderID,'^0-9')as int)



	   Insert into #InspecDetails2(CharteristicID,InstrumentNo,BatchID,InstrumentBatchID,SortOrder)
	   select  CharteristicID,InstrumentNo,(select HeaderValue from #InspecValueHeader where HeaderID=@i),(select H from #InspecValueHeader where HeaderID=@i),SortOrder from #InspecDetails2
	   inner join #InspecValueHeader on #InspecDetails2.InstrumentBatchID=#InspecValueHeader.H
	   where #InspecValueHeader.HeaderID=@i-1
	   and InstrumentNo not in(select Instrumentno from #InspecDetails2 inner join #InspecValueHeader on #InspecDetails2.InstrumentBatchID=#InspecValueHeader.H where #InspecValueHeader.headerid= @i)
	   and CharteristicID not in(select CharteristicID from #InspecDetails2 inner join #InspecValueHeader on #InspecDetails2.InstrumentBatchID=#InspecValueHeader.H where #InspecValueHeader.headerid= @i)			 
	   order by cast(dbo.SplitAlphanumeric(#InspecValueHeader.HeaderID,'^0-9')as int)

	   select @i = @i+1

	end


	DECLARE @DynamicPivotQuery AS NVARCHAR(max),@DynamicPivotQuery1 AS NVARCHAR(max);
	DECLARE @ColumnName AS NVARCHAR(max);
     DECLARE @SelectColumnName AS NVARCHAR(max),@SelectColumnName1 AS NVARCHAR(max);
    	DECLARE @sqlText nvarchar(max); 

	  SELECT @SelectColumnName= ISNULL(@SelectColumnName + ',','') 
	 + QUOTENAME(HeaderValue)
	  FROM (select HeaderValue from #InspecValueHeader) AS BatchValues 


	SET @DynamicPivotQuery = 
	N'SELECT SortOrder,CharteristicID,CharacteristicCode,LSL,USL,SpecificationMean,InstrumentType,' + @SelectColumnName + ' into ##I
	FROM (select SortOrder,CharteristicID,CharacteristicCode,LSL,USL,SpecificationMean,InstrumentType,batchid,
	batchvalue
	from #InspecDetails 
	)as s 
	PIVOT (max(batchvalue) 
	FOR [batchid] IN (' + @SelectColumnName + ')) AS PVTTable order by cast(dbo.SplitAlphanumeric(CharteristicID,''^0-9'')as int)'	

	EXEC sp_executesql @DynamicPivotQuery



	create table #I
	( slno bigint identity(1,1) NOT NULL,
	  InstrumentBatchID nvarchar(50))

	  insert into #I(InstrumentBatchID)
	  select InstrumentBatchID from(
	  select distinct InstrumentBatchID,max(slno) as slno from #InspecDetails2 group by InstrumentBatchID
	  )AS BatchValues ORDER BY cast(dbo.SplitAlphanumeric(BatchValues.slno,'^0-9')as int) 
 
	  SELECT @SelectColumnName1= ISNULL(@SelectColumnName1 + ',','') 
	 + QUOTENAME(InstrumentBatchID)
	  FROM (select InstrumentBatchID from #I
	  )AS BatchValues  

	SET @DynamicPivotQuery1 = 
	N'SELECT SortOrder,CharteristicID,' + @SelectColumnName1 + ' into ##I1
	FROM (select SortOrder,CharteristicID,InstrumentBatchID,
	Instrumentno
	from #InspecDetails2 
	)as s 
	PIVOT (max(Instrumentno)
	FOR [InstrumentBatchID] IN (' + @SelectColumnName1 + ')) AS PVTTable  order by cast(dbo.SplitAlphanumeric(CharteristicID,''^0-9'')as int)'
	
	EXEC sp_executesql @DynamicPivotQuery1


select top 1 InspectionDrawing,Interval,SampleSize,IsNull(Product, 'NA') AS Product,IsNull(VersionNo, 'NA') AS VersionNo from SPC_Characteristic where  componentid= @ItemNo and OperationNo= @operationNo

	---select top 1 InspectionDrawing,Interval,SampleSize,Product,VersionNo from SPC_Characteristic where  componentid= @ItemNo and OperationNo= @operationNo


    If @Type = 'With InstrumentNo'
    Begin

		IF OBJECT_ID('tempdb.dbo.##I', 'U') IS NOT NULL
			BEGIN
			SET @sqlText = N'SELECT ##I.CharteristicID,##I.CharacteristicCode,##I.LSL,##I.USL,##I.SpecificationMean,##I.InstrumentType,##I.' + @SelectColumnName + ',##I1. ' + @SelectColumnName1 + ' FROM  ##I 
			left outer join ##I1 on ##I.CharteristicID=##I1.CharteristicID 		   
			order by cast(dbo.SplitAlphanumeric(##I.SortOrder,''^0-9'')as int)'
			print @sqltext
			Exec (@sqlText)
		END

    END


    If @Type = 'Without InstrumentNo'
    Begin

	IF OBJECT_ID('tempdb.dbo.##I', 'U') IS NOT NULL
    	BEGIN
	   SELECT @sqlText =''
	   SET @sqlText = N'SELECT ##I.CharteristicID,##I.CharacteristicCode,##I.LSL,##I.USL,##I.SpecificationMean,##I.InstrumentType,##I.' + @SelectColumnName + ' From ##I 
		   order by cast(dbo.SplitAlphanumeric(##I.SortOrder,''^0-9'')as int)'
	   print @sqltext
	   Exec (@sqlText)
	END

    END


    IF OBJECT_ID('tempdb.dbo.##I', 'U') IS NOT NULL
    BEGIN
    drop table ##I
    END


    IF OBJECT_ID('tempdb.dbo.##I1', 'U') IS NOT NULL
    BEGIN
    drop table ##I1
    END

END
End
