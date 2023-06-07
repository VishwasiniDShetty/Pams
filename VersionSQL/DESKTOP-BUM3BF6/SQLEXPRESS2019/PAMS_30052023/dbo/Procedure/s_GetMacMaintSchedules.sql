/****** Object:  Procedure [dbo].[s_GetMacMaintSchedules]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetMacMaintSchedules] '','','','','','','','','','','','',''
CREATE PROCEDURE [dbo].[s_GetMacMaintSchedules]
@ActivityID int='',
@Machine nvarchar(50)='',
@SubSystem nvarchar(2000)='',
@ImagePath nvarchar(1000)='',
@PartNo nvarchar(2000)='',
@Activity nvarchar(50)='',
@Standard nvarchar(1000)='',
@frequency nvarchar(50)='',
@Date datetime='',
@Shift1 bit='',
@Shift2 bit='',
@Shift3 bit ='',
@Day bit='',
@Week bit='',
@Month bit='',
@param nvarchar(50)=''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	create table #ShiftTemp
	(
	StartDate datetime,
	ShiftName nvarchar(50),
	Starttime datetime,
	EndTime datetime,
	ShiftID int
	)


insert into #ShiftTemp(StartDate,Shiftname,Starttime,Endtime,Shiftid)
exec [s_GetCurrentShiftTime] @Date,''



declare @Dt as datetime
declare @Shift nvarchar(50)
select @Dt=convert(char(10),StartDate,126)  from #ShiftTemp
select @Shift =ShiftName from #ShiftTemp 


if @param='Insert'
BEGIN
insert into MacMaintSchedules(PartNo,Activity,[Standard],[Frequency],[Shift1],
[Shift2],[Shift3],[Day],[Week],[Month],[Machine],[SubSystem],[ImagePath],[Date],[Shift])
select @PartNo,@Activity,@Standard,@frequency,@Shift1,@Shift2,@Shift3,@Day,@Week,@Month,@Machine,@SubSystem
,@ImagePath,@Dt,@Shift
END

if @param='Delete'
BEGIN
delete from MacMaintSchedules where ActivityID=@ActivityID
END

if @param='Update'
BEGIN
Update MacMaintSchedules set [Shift1]=@Shift1,
[Shift2]=@Shift2,[Shift3]=@Shift3,[Day]=@Day,[Week]=@Week,[Month]=@month,[ImagePath]=@ImagePath
where ActivityID=@ActivityID and [Machine]=@machine and [SubSystem]=@SubSystem
END

END
