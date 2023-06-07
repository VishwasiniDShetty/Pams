/****** Object:  Procedure [dbo].[s_GenerateInProcessInterval]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from MOSchedule
--[dbo].[s_GenerateInProcessInterval] 'CT13','514808','PSK802000-T29','1','100','1'
CREATE    PROCEDURE [dbo].[s_GenerateInProcessInterval]
@machineid nvarchar(50),
@MoNumber nvarchar(50),
@ItemNo nvarchar(50),
@operationNo nvarchar(50),
@MaxInterval int='',
@NoOfRecordsToPick int,
@Param nvarchar(50)=''
WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

Create Table #Interval
(
	IntervalID bigint identity(1,1) NOT NULL,
	IntervalValue int,
	MOQuantity int,
	NoOfRecordsToGenerate int
)

If @MaxInterval = ''
Begin
	Select @MaxInterval=0
END

Truncate Table #Interval

Insert INTO #Interval (IntervalValue,MOQuantity,NoOfRecordsToGenerate) 
select SPC.InprocessInterval,Max(MO.Quantity),0 from  SPC_Characteristic SPC 
--select SPC.InprocessInterval,'500',0 from  SPC_Characteristic SPC 
left outer join MOSchedule MO on SPC.componentid=MO.PartID and SPC.Operationno=MO.Operationno
where MO.Machineid=@machineid and SPC.componentid=@ItemNo and SPC.Operationno=@operationNo and MO.MONumber=@MONumber
and (SPC.InprocessInterval IS NOT NULL and SPC.Inprocessinterval<>0 and SPC.Inprocessinterval<>'')
Group by SPC.InprocessInterval
order by cast(dbo.SplitAlphanumeric(SPC.InprocessInterval,'^0-9')as int) 


Update #Interval set NoOfRecordsToGenerate = cast(MOQuantity/IntervalValue as int) 


Declare @NoOfRecords as int
Declare @NoOfRecordsToGenerate as int
Declare @count1 as int
Declare @count2 as int
Declare @RefCount2 as int
Declare @Multiple as int


Select @NoOfRecords = ISNULL(count(*),0) from #Interval
Select @NoOfRecordsToGenerate = NoOfRecordsToGenerate from #Interval where intervalid=1
Select @count1 = 1
Select @count2 = 1
select @RefCount2 = @count2
Select @Multiple = 2


While @count1 < = @NoOfRecords
BEGIN

	while @Count2<=@NoOfRecordsToGenerate
	Begin
		Insert into #Interval(IntervalValue)
		Select (IntervalValue * @Multiple) from #Interval where intervalid=@Count1
		select @RefCount2 = @count2
		Select @count2 = @count2 + 1
		Select @Multiple = @Multiple + 1
	ENd

	Select @Count1 = @Count1 + 1

	IF @RefCount2 = @NoOfRecordsToGenerate 
	BEGIN	
		Select @count2 = 1 
		Select @Multiple =2
		select @RefCount2 = 1
		Select @NoOfRecordsToGenerate = NoOfRecordsToGenerate from #Interval where intervalid=@count1
	END 

END

	Select top (@NoOfRecordsToPick) T.IntervalValue from 
	(Select Distinct IntervalValue from #Interval)T where T.IntervalValue>@MaxInterval order by T.IntervalValue

END
