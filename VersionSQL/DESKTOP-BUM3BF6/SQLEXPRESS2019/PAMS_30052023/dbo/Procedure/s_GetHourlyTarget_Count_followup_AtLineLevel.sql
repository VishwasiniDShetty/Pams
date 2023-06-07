/****** Object:  Procedure [dbo].[s_GetHourlyTarget_Count_followup_AtLineLevel]    Committed by VersionSQL https://www.versionsql.com ******/

/***********************************************************************************
s_GetHourlyTarget_Count_followup_AtLineLevel '2021-07-06','LINE-1','','','','RunningPart'
s_GetHourlyTarget_Count_followup_AtLineLevel '2021-07-06','LINE-1','','','','BOSCH_BNG_CamShaft'
s_GetHourlyTarget_Count_followup_AtLineLevel '2021-07-06','LINE-1','','','','BOSCH_BNG_CamShaftsummary'
s_GetHourlyTarget_Count_followup_AtLineLevel '2021-07-06','LINE-7','','AMS B2 L-7','','BOSCH_Nashik_AELosses'
***********************************************************************************/
CREATE PROCEDURE [dbo].[s_GetHourlyTarget_Count_followup_AtLineLevel]
	@StartDate datetime,
	@PlantID nvarchar(50)='',
	@GroupID nvarchar(50) = '',
	@Machineid nvarchar(50)='',
	@Shift nvarchar(50)='',
	@Param nvarchar(50)=''--'','BOSCH_BNG_CamShaft','BOSCH_BNG_AELosses'

WITH RECOMPILE


AS
BEGIN


Create Table #Shift
(	
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	HourName nvarchar(50),
	HourID int,
	FromTime datetime,
	ToTime Datetime
)


Create Table #ShiftTemp
(	
	Machineid nvarchar(50),
	Machineinterface nvarchar(50),
	MachineDescription nvarchar(50),
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	HourName nvarchar(50),
	HourID int,
	FromTime datetime,
	ToTime Datetime,
	Target float,
	Actual float
)
	


Create Table #Summary
(	
	Machineid nvarchar(50),
	MachineDescription nvarchar(50),
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	HourName nvarchar(50),
	HourID int,
	FromTime datetime,
	ToTime Datetime,
	Target float,
	Actual float
)

Create Table #PDT
(	
	Machineid nvarchar(50),
	machineinterface nvarchar(50),
	FromTime datetime,
	ToTime Datetime,
	StartTime_PDT Datetime,
	EndTime_PDT Datetime,
	DownReason nvarchar(50),
	Actual float
)

CREATE TABLE #Target
(
	MachineID NvarChar(50),
	MachineInterface nvarchar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	sttime Datetime,
	ndtime Datetime,
	hursttime datetime,
	hurndtime datetime,
	hurId int,
	shftId int,
	Pdt int
)

CREATE TABLE #Target_actime
(
	MachineInterface nvarchar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	sttime Datetime,
	ndtime Datetime,
	hurId int,
	shftId int
	
)

Create table #Summary_AE_Losses
(
	machineid nvarchar(50),
	machinedescription nvarchar(50),
	HourID int,
	ShiftID int,
	DownCategory Nvarchar(50),
	downid Nvarchar(50),
	interfaceid Nvarchar(50),
	DownTime float
)

CREATE TABLE #T_autodata(
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] not NULL,
	[datatype] [tinyint] NULL ,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] not NULL,
	[PartsCount] decimal(18,5) NULL ,
	id  bigint not null
)

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime,ndtime,msttime ASC
)ON [PRIMARY]

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 

declare @sqlstr as nvarchar(4000)
declare @Targetsource nvarchar(50)
select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'


DECLARE @strsql as varchar(4000)
DECLARE @strmachine AS nvarchar(250)
declare @counter as datetime
declare @stdate as nvarchar(20)
declare @ShftPL as int
Declare @strPlantID as nvarchar(255)
Declare @strGroupID as nvarchar(255)


Declare @curmachineid as nvarchar(50)
Declare @curcomp  as nvarchar(50)
Declare @curop  as int
Declare @cursttime  as Datetime
Declare @curndtime  as datetime
Declare @curstarttime  as Datetime
Declare @curEndtime  as datetime
Declare @curhursttime as datetime
Declare @curhurndtime as datetime
Declare @curhurId as int
Declare @curshftId as int
Declare @cmachineid as nvarchar(50)
Declare @compid  as nvarchar(50)
Declare @operationid  as int
Declare @sttime  as Datetime
Declare @ndtime  as datetime
Declare @CEndtime  as Datetime
Declare @CStarttime  as datetime
Declare @churId as int
Declare @cshftId as int
Declare @churndtime as datetime
Declare @chursttime as datetime

select @stdate = CAST(datePart(yyyy,@StartDate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@StartDate) AS nvarchar(2)) + '-' + CAST(datePart(dd,@StartDate) AS nvarchar(2))
select @counter=convert(datetime, cast(DATEPART(yyyy,@StartDate)as nvarchar(4))+'-'+cast(datepart(mm,@StartDate)as nvarchar(2))+'-'+cast(datepart(dd,@StartDate)as nvarchar(2)) +' 00:00:00.000')
SELECT @strsql = ''
SELECT @strmachine = ''
SELECT @strPlantID = ''
SELECT @strGroupID = ''


if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
end

if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

if isnull(@GroupID,'')<> ''
Begin
	SET @strGroupID = ' AND PlantMachineGroups.GroupID = N''' + @GroupID + ''''
End

If @Shift<>'' 
Begin         
	insert into #Shift(PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime)
	select 
	@counter,S.ShiftName,S.ShiftID,SH.Hourname,SH.HourID,
	dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),
	dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))
	from shiftdetails S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid
	where S.running=1
	and S.ShiftName = @Shift 
end        
If @Shift = '' 
Begin          
	insert into #Shift(PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime)
	select 
	@counter,S.ShiftName,S.ShiftID,SH.Hourname,SH.HourID,
	dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),
	dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))
	from shiftdetails S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid
	where S.running=1
end 

Select @T_ST=min(FromTime) from #Shift
Select @T_ED=max(ToTime) from #Shift


Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)

Select @strsql=''
Select @strsql = 'insert into #Shifttemp(Machineid,Machineinterface,MachineDescription,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)
select Machineinformation.Machineid,Machineinformation.interfaceid,PlantMachineGroups.GroupID,S.PDate,S.ShiftName,S.ShiftID,S.HourName,S.HourID,S.FromTime,S.ToTime,0,0 
from Machineinformation cross join #shift S
inner join plantmachine on Machineinformation.Machineid=plantmachine.Machineid 
Left Outer Join PlantMachineGroups on plantmachine.machineID=PlantMachineGroups.machineID and plantmachine.PlantID=PlantMachineGroups.Plantid
where 1=1'
Select @strsql = @strsql + @strPlantID + @strMachine + @strGroupID
EXEC(@strsql)


if isnull(@Param,'') = 'RunningPart'
Begin

	create table #temp_Part
	(  
	 Machineid nvarchar(50), 
	 Machinedescription nvarchar(50),  
	 Componentid nvarchar(50),
	 StTime Datetime 
	) 

	create table #Runningpart_Part
	(  
	 Machineid nvarchar(50),  
	 Machinedescription nvarchar(50), 
	 Componentid nvarchar(50),
	 StTime Datetime 
	) 


	select @strsql=''
	SELECT @strsql= @strsql + 'insert into #temp_Part(machineid,Machinedescription,Componentid,StTime)
	  Select T.Machineid,T.GroupID,C.ComponentID,T.Sttime from 
	  (
		  select Machineinformation.machineid,Machineinformation.interfaceid,PlantMachineGroups.GroupID,Max(A.StTime) as Sttime from autodata A  
		  inner join Machineinformation on A.mc=Machineinformation.interfaceid  
		  inner join plantmachine on Machineinformation.Machineid=plantmachine.Machineid
		  Left Outer Join PlantMachineGroups on plantmachine.machineID=PlantMachineGroups.machineID and plantmachine.PlantID=PlantMachineGroups.Plantid
		  where A.ndtime>='''+convert(nvarchar(20),@T_ST)+''' and A.ndtime<='''+convert(nvarchar(20),@T_ED)+''' and PlantMachineGroups.machineID IS NOT NULL'  
		Select @strsql = @strsql + @strPlantID + @strMachine + @strGroupID
		SELECT @strsql = @strsql +'group by Machineinformation.machineid,Machineinformation.interfaceid,PlantMachineGroups.GroupID
	   )T inner join autodata A on T.interfaceid=A.mc and T.Sttime=A.Sttime
	  inner join Componentinformation C on A.comp=C.interfaceid  
	  inner join Componentoperationpricing CO on A.opn=CO.interfaceid and T.Machineid=CO.Machineid and C.Componentid=CO.Componentid '
	print @strsql
	exec (@strsql)  


--	insert into #Runningpart_Part(Machinedescription,Componentid)
--	select 'ACE FT',Componentid
--	from #temp_Part where Machinedescription like ('%FT%') 
--
--	insert into #Runningpart_Part(Machinedescription,Componentid)
--	select 'ACE ST',Componentid
--	from #temp_Part where Machinedescription like ('%ST%') 
--
--	insert into #Runningpart_Part(Machinedescription,Componentid)
--	select 'AMS A',Componentid
--	from #temp_Part where Machinedescription like ('A%') 
--
--	insert into #Runningpart_Part(Machinedescription,Componentid)
--	select 'AMS B',Componentid
--	from #temp_Part where Machinedescription like ('%B%') 
--
--	insert into #Runningpart_Part(Machinedescription,Componentid)
--	select 'KM DIA 6',Componentid
--	from #temp_Part where Machinedescription like ('KM DIA 6') 
--	
--	insert into #Runningpart_Part(Machinedescription,Componentid)
--	select 'KM DIA 1.43',Componentid
--	from #temp_Part where Machinedescription like ('KM DIA 1.43') 
--
--	insert into #Runningpart_Part(Machinedescription,Componentid)
--	select 'KM DIA 2.2',Componentid
--	from #temp_Part where Machinedescription like ('KM DIA 2.2') 
--
--	insert into #Runningpart_Part(Machinedescription,Componentid)
--	select 'KM A/F MILLING',Componentid
--	from #temp_Part where Machinedescription like ('KM A/F MILLING') 

--	insert into #Runningpart_Part(Machinedescription,Componentid)
--	select Machinedescription,Componentid
--	from #temp_Part where Machinedescription like ('KM A/F MILLING') 

	insert into #Runningpart_Part(Machinedescription,Componentid,STTIME)
	select case when @Machineid<>'' or @Groupid='' then Machineid else Machinedescription end,Componentid,sttime from #temp_Part 

	Select T.Machinedescription,T.Componentid from
	(
		Select Machinedescription,Componentid,ROW_NUMBER() over(PARTITION BY Machinedescription order by sttime desc) as rn
		from #Runningpart_Part 
	 )T where T.rn=1
END

IF ISNULL(@Targetsource,'')='% Ideal'
BEGIN

insert into #target
Select S.machineid,mc,comp,opn,msttime,ndtime,S.fromtime,S.totime,s.HourID,s.ShiftID,0 from  #ShiftTemp S
inner join #T_autodata A on S.MachineInterface=A.mc where
((A.ndtime>=S.fromtime  and  A.ndtime<=S.totime) )
order by mc,sttime



declare @RptCursor  cursor
Set @RptCursor= CURSOR FOR
		SELECT MachineInterface,ComponentID ,OperationNo,Sttime,ndtime,hurId,shftId from #target order by MachineInterface,Sttime,ndtime

OPEN @RptCursor
FETCH NEXT FROM @RptCursor INTO @cmachineid, @compid, @operationid,@sttime,@ndtime,@churId,@cshftId

if (@@fetch_status = 0)
begin
 -- initialize current variables		
  select @curmachineid = @cmachineid	
  select @curcomp = @compid
  select @curop = @operationid
  Select @cursttime=@sttime
  Select @curndtime=@ndtime
  select @curhurId=@churId	
  select @curshftId=@cshftId	
  Select @curstarttime=@cstarttime
  Select @curendtime=@cendtime
end	

	WHILE (@@fetch_status <> -1)
		BEGIN
			  IF (@@fetch_status <> -2)
			    BEGIN
					FETCH NEXT FROM @RptCursor INTO @cmachineid, @compid, @operationid,@sttime,@ndtime,@churId,@cshftId
					if (@@fetch_status = 0) and (@curmachineid = @cmachineid) and (@curcomp = @compid) and (@curop = @operationid)
					 begin
							 Select @curndtime=@ndtime					
					 end
					else if (@@fetch_status = 0)
					 begin
						insert into #Target_actime
						Select @curmachineid as mc,@curcomp as comp,@curop as opn,
							Case  when @cursttime<@curstarttime  then @cstarttime else @cursttime end as start,
							case when @curndtime>@curendtime then @curendtime Else @curndtime End as  endt,@curhurId,@curshftId
							
						select @curmachineid = @cmachineid	
						select @curcomp = @compid
						select @curop = @operationid
						Select @cursttime=@sttime
						Select @curndtime=@ndtime
						select @curhurId=@churId	
						select @curshftId=@cshftId	
					end
			    END
		END

insert into #Target_actime
Select @curmachineid as mc,@curcomp as comp,@curop as opn,
Case  when @cursttime<@curstarttime then @curstarttime else @cursttime end as start,
case when @curndtime>@curendtime then @curendtime Else @curndtime End as  endt,@curhurId,@curshftId

close @rptcursor
deallocate @rptcursor

update #Target_actime set ndtime=t1.Totime from #Target_actime inner join
(Select #Target_actime.machineinterface,max(#Target_actime.ndtime)as ndtime,max(#ShiftTemp.Totime) as Totime from #Target_actime
	inner join #ShiftTemp on #ShiftTemp.machineinterface=#Target_actime.machineinterface
group by #Target_actime.machineinterface
)T1 on T1.machineinterface=#Target_actime.machineinterface and t1.ndtime=#Target_actime.ndtime

delete From #Target


insert into #Target
select sh.machineid,sh.machineinterface,t1.componentId,t1.Operationno,
case when t1.sttime<=sh.Fromtime then sh.fromtime else t1.sttime end as Start,
case when t1.ndtime>=sh.Totime then sh.totime else t1.ndtime end as Endt,sh.fromtime,sh.totime,sh.hourid,sh.shiftid,0
from #target_actime t1
inner join #ShiftTemp Sh on sh.machineinterface=T1.machineinterface
where
((sh.fromTime >= t1.Sttime and sh.toTime <= t1.ndTime)or
(sh.fromTime < t1.Sttime and sh.toTime > t1.Sttime and sh.toTime <=t1.ndTime)or
(sh.fromTime >= t1.Sttime and sh.fromTime <t1.ndTime and sh.toTime >t1.ndTime) or
(sh.fromTime <  t1.Sttime and sh.toTime >t1.ndTime))


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N'
BEGIN

update #Target set pdt=t3.pdt from 
(
Select t2.machineinterface,T2.Machine,T2.sttime,T2.ndtime,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt
from
(
	Select T1.*,Pdt.machine,
	Case when  T1.Sttime <= pdt.StartTime then pdt.StartTime else T1.Sttime End as StartTimepdt,
	Case when  T1.ndtime >= pdt.EndTime then pdt.EndTime else T1.ndtime End as EndTimepdt
	from #Target T1
	inner join Planneddowntimes pdt on t1.machineid=Pdt.machine
	where PDTstatus = 1  and
	((pdt.StartTime >= t1.Sttime and pdt.EndTime <= t1.ndTime)or
	(pdt.StartTime < t1.Sttime and pdt.EndTime > t1.Sttime and pdt.EndTime <=t1.ndTime)or
	(pdt.StartTime >= t1.Sttime and pdt.StartTime <t1.ndTime and pdt.EndTime >t1.ndTime) or
	(pdt.StartTime <  t1.Sttime and pdt.EndTime >t1.ndTime))
)T2 group by  t2.machineinterface,T2.Machine,T2.sttime,T2.ndtime
) T3
inner join #Target T on T.machineinterface=T3.machineinterface and T.Sttime=T3.Sttime and  T.ndtime=T3.ndtime

End

update #ShiftTemp set target=Round(T1.target,0) from 
(
	Select  M.machineid,hurId,shftId,
	sum(
	(((datediff(second,T.sttime,T.ndtime)-isnull(pdt,0))*Co.suboperations)/Co.cycletime)*isnull(Co.targetpercent,100) /100) as target
	from #target T
	inner join machineinformation M on M.Interfaceid=T.machineinterface
	inner join componentinformation C on C.interfaceid=T.componentid
	inner join componentoperationpricing CO on M.machineid=co.machineid and c.componentid=Co.componentid
	and Co.interfaceid=T.OperationNo
	group by M.Machineid,hurId,shftId
)T1 inner join #ShiftTemp on T1.machineid=#ShiftTemp.machineid and T1.hurId=#ShiftTemp.HourId and T1.shftId=#ShiftTemp.ShiftId
end
else
begin
	update #ShiftTemp set target=T1.target from
	(
		select sum(SH.target)AS TARGET ,SH.Sdate,SH.hourid,SH.Machineid,
		SH.Hourstart  as Hourstart ,SH.Hourend as Hourend from
		shifthourtargets SH 
		inner join #ShiftTemp S on S.machineid=SH.Machineid and S.hourid=SH.hourid and S.Fromtime=SH.Hourstart and S.totime=SH.Hourend
		where SH.sdate=convert(datetime,@stdate) 
		group by SH.Sdate,SH.hourid,SH.Machineid,SH.Hourstart,SH.Hourend
	) as T1 inner join #ShiftTemp on #ShiftTemp.machineid=T1.Machineid and #ShiftTemp.hourid=T1.hourid and #ShiftTemp.Fromtime=T1.Hourstart and #ShiftTemp.totime=T1.Hourend
end


if isnull(@Param,'') = 'BOSCH_BNG_AELosses'
Begin

	Select machineID,MachineInterface,pDate,HourID,ShiftID,FromTime,ToTime,DownCategoryInformation.DownCategory,0 as DownTime,0 as DownTimeByCategory,0 as DownTimeMaxOrder into #AE_Losses
	from #ShiftTemp cross join DownCategoryInformation order by shiftid,hourid

	UPDATE #AE_Losses SET DownTime = isnull(DownTime,0) + isNull(t1.down,0) from(
		select mc,
		sum(case
		when autodata.msttime>=#AE_Losses.FromTime and autodata.ndtime<=#AE_Losses.ToTime then loadunload
		when autodata.sttime<#AE_Losses.FromTime and autodata.ndtime>#AE_Losses.FromTime and autodata.ndtime<=#AE_Losses.ToTime then DateDiff(second, #AE_Losses.FromTime, ndtime)
		when autodata.msttime>=#AE_Losses.FromTime and autodata.sttime<#AE_Losses.ToTime and autodata.ndtime>#AE_Losses.ToTime then DateDiff(second, mstTime, #AE_Losses.ToTime)
		when autodata.msttime<#AE_Losses.FromTime and autodata.ndtime>#AE_Losses.ToTime then DateDiff(second, #AE_Losses.FromTime, #AE_Losses.ToTime)
		end) as down,#AE_Losses.FromTime,#AE_Losses.ToTime,DownCategoryInformation.DownCategory
		from #T_autodata autodata
		inner join #AE_Losses on autodata.mc = #AE_Losses.machineinterface
		inner join downcodeinformation on autodata.dcode = downcodeinformation.downid
		inner join DownCategoryInformation on downcodeinformation.Catagory = DownCategoryInformation.DownCategory and #AE_Losses.DownCategory = DownCategoryInformation.DownCategory
		where (autodata.datatype=2) and
		((autodata.msttime>=#AE_Losses.FromTime and autodata.ndtime<=#AE_Losses.ToTime)or
		 (autodata.sttime<#AE_Losses.FromTime and autodata.ndtime>#AE_Losses.FromTime and autodata.ndtime<=#AE_Losses.ToTime)or
		 (autodata.msttime>=#AE_Losses.FromTime and autodata.sttime<#AE_Losses.ToTime and autodata.ndtime>#AE_Losses.ToTime)or
		 (autodata.msttime<#AE_Losses.FromTime and autodata.ndtime>#AE_Losses.ToTime))
		group by autodata.mc,#AE_Losses.FromTime,#AE_Losses.ToTime,DownCategoryInformation.DownCategory
	) as t1 inner join #AE_Losses 	on t1.mc = #AE_Losses.machineinterface 	and t1.FromTime = #AE_Losses.FromTime
	and t1.ToTime = #AE_Losses.ToTime and t1.DownCategory = #AE_Losses.DownCategory

	select top 9 IDENTITY(int, 1,1) AS ID_Num, DownCategory,sum(DownTime) as DownTime into #AE_Losses_Inorder from #AE_Losses group by DownCategory order by sum(DownTime) desc

	UPDATE #AE_Losses SET DownTimeByCategory = isnull(#AE_Losses.DownTimeByCategory,0) +  isnull(t1.DownTime,0),
						  DownTimeMaxOrder = isnull(#AE_Losses.DownTimeMaxOrder,0) +  isnull(t1.ID_Num,0)
	from(select * from #AE_Losses_Inorder) as t1 inner join #AE_Losses on t1.DownCategory = #AE_Losses.DownCategory
	update #AE_Losses set DownTime = cast(dbo.f_FormatTime(DownTime,'mm')as float),DownTimeByCategory = cast(dbo.f_FormatTime(DownTimeByCategory,'mm')as float)


	select HourID,ShiftID,DownCategory,DownTime from #AE_Losses
	where DownTimeMaxOrder <=9 and DownTimeMaxOrder <> 0
	order by FromTime,DownTimeMaxOrder

	return
End

--ER0353 Added From Here
if isnull(@Param,'') = 'BOSCH_Nashik_AELosses'
Begin

	Select machineID,MachineInterface,machinedescription,pDate,HourID,ShiftID,FromTime,ToTime,T.Catagory as Downcategory,T.Downid as Downid,T.interfaceid as interfaceid,0 as DownTime into #AE_Losses1
	from #ShiftTemp cross join (Select Downid,Catagory,interfaceid from Downcodeinformation DI inner join DownCategoryInformation DC
	on DI.catagory=DC.Downcategory)T order by shiftid,hourid,T.Catagory


	UPDATE #AE_Losses1 SET DownTime = isnull(DownTime,0) + isNull(t1.down,0) from(
		select mc,
		sum(case
		when autodata.msttime>=#AE_Losses1.FromTime and autodata.ndtime<=#AE_Losses1.ToTime then loadunload
		when autodata.sttime<#AE_Losses1.FromTime and autodata.ndtime>#AE_Losses1.FromTime and autodata.ndtime<=#AE_Losses1.ToTime then DateDiff(second, #AE_Losses1.FromTime, ndtime)
		when autodata.msttime>=#AE_Losses1.FromTime and autodata.sttime<#AE_Losses1.ToTime and autodata.ndtime>#AE_Losses1.ToTime then DateDiff(second, mstTime, #AE_Losses1.ToTime)
		when autodata.msttime<#AE_Losses1.FromTime and autodata.ndtime>#AE_Losses1.ToTime then DateDiff(second, #AE_Losses1.FromTime, #AE_Losses1.ToTime)
		end) as down,#AE_Losses1.FromTime,#AE_Losses1.ToTime,#AE_Losses1.DownCategory,#AE_Losses1.downid
		from #T_autodata autodata
		inner join #AE_Losses1 on autodata.mc = #AE_Losses1.machineinterface
		inner join downcategoryinformation DC on DC.downcategory=#AE_Losses1.DownCategory
		inner join downcodeinformation D on autodata.dcode = D.interfaceid and D.catagory=DC.DownCategory
		and #AE_Losses1.downid=D.downid
		where (autodata.datatype=2) and
		((autodata.msttime>=#AE_Losses1.FromTime and autodata.ndtime<=#AE_Losses1.ToTime)or
		 (autodata.sttime<#AE_Losses1.FromTime and autodata.ndtime>#AE_Losses1.FromTime and autodata.ndtime<=#AE_Losses1.ToTime)or
		 (autodata.msttime>=#AE_Losses1.FromTime and autodata.sttime<#AE_Losses1.ToTime and autodata.ndtime>#AE_Losses1.ToTime)or
		 (autodata.msttime<#AE_Losses1.FromTime and autodata.ndtime>#AE_Losses1.ToTime))
		group by autodata.mc,#AE_Losses1.FromTime,#AE_Losses1.ToTime,#AE_Losses1.DownCategory,#AE_Losses1.downid
	) as t1 inner join #AE_Losses1 	on t1.mc = #AE_Losses1.machineinterface and t1.FromTime = #AE_Losses1.FromTime
	and t1.ToTime = #AE_Losses1.ToTime and t1.DownCategory = #AE_Losses1.DownCategory and t1.downid = #AE_Losses1.downid

	--select * from #AE_Losses1 where HourID='8' and ShiftID='3' and Machineid='KM DIA 2.2 L-1'
	--return

	update #AE_Losses1 set DownTime = cast(dbo.f_FormatTime(DownTime,'mm')as float)

--	insert into #Summary_AE_Losses(machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime)
--	select 'ACE FT',HourID,ShiftID,DownCategory,downid,interfaceid,replace(sum(DownTime),'0','') as DownTime  from #AE_Losses1
--	where Machinedescription like ('%FT%') group by HourID,ShiftID,DownCategory,downid,interfaceid
--
--	insert into #Summary_AE_Losses(machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime)
--	select 'ACE ST',HourID,ShiftID,DownCategory,downid,interfaceid,replace(sum(DownTime),'0','') as DownTime  from #AE_Losses1
--	where Machinedescription like ('%ST%') group by HourID,ShiftID,DownCategory,downid,interfaceid
--
--	insert into #Summary_AE_Losses(machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime)
--	select 'AMS A',HourID,ShiftID,DownCategory,downid,interfaceid,replace(sum(DownTime),'0','') as DownTime  from #AE_Losses1
--	where Machinedescription like ('%A%') group by HourID,ShiftID,DownCategory,downid,interfaceid
--
--	insert into #Summary_AE_Losses(machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime)
--	select 'AMS B',HourID,ShiftID,DownCategory,downid,interfaceid,replace(sum(DownTime),'0','') as DownTime  from #AE_Losses1
--	where Machinedescription like ('%B%') group by HourID,ShiftID,DownCategory,downid,interfaceid
--
--	insert into #Summary_AE_Losses(machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime)
--	select 'KM DIA 6',HourID,ShiftID,DownCategory,downid,interfaceid,replace(sum(DownTime),'0','') as DownTime  from #AE_Losses1
--	where Machinedescription like ('KM DIA 6') group by HourID,ShiftID,DownCategory,downid,interfaceid
--
--	insert into #Summary_AE_Losses(machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime)
--	select 'KM DIA 1.43',HourID,ShiftID,DownCategory,downid,interfaceid,replace(sum(DownTime),'0','') as DownTime  from #AE_Losses1
--	where Machinedescription like ('KM DIA 1.43') group by HourID,ShiftID,DownCategory,downid,interfaceid
--
--	insert into #Summary_AE_Losses(machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime)
--	select 'KM DIA 2.2',HourID,ShiftID,DownCategory,downid,interfaceid,replace(sum(DownTime),'0','') as DownTime  from #AE_Losses1
--	where Machinedescription like ('KM DIA 2.2') group by HourID,ShiftID,DownCategory,downid,interfaceid
--
--	insert into #Summary_AE_Losses(machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime)
--	select 'KM A/F MILLING',HourID,ShiftID,DownCategory,downid,interfaceid,replace(sum(DownTime),'0','') as DownTime  from #AE_Losses1
--	where Machinedescription like ('KM A/F MILLING') group by HourID,ShiftID,DownCategory,downid,interfaceid


	--Select @strsql =''
	--select @strsql = @strsql + '
	--insert into #Summary_AE_Losses(machineid,machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime)
	--select A.Machineid,PlantMachineGroups.GroupID,A.HourID,A.ShiftID,A.DownCategory,A.downid,A.interfaceid,replace(sum(A.DownTime),''0'','''') as DownTime  from #AE_Losses1 A
	--inner join Machineinformation on Machineinformation.Machineid=A.Machineid
	--inner join PlantMachine on PlantMachine.Machineid=Machineinformation.Machineid
	--Left Outer Join PlantMachineGroups on A.machineID=PlantMachineGroups.machineID where 1=1 '
	--Select @strsql = @strsql + @strPlantID + @strMachine + @strGroupID
	--select @strsql = @strsql + ' group by A.Machineid,PlantMachineGroups.GroupID,A.HourID,A.ShiftID,A.DownCategory,A.downid,A.interfaceid'	
	--print @strsql
	--exec(@strsql)


	Select @strsql =''
	select @strsql = @strsql + '
	insert into #Summary_AE_Losses(machineid,machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime)
	select A.Machineid,PlantMachineGroups.GroupID,A.HourID,A.ShiftID,A.DownCategory,A.downid,A.interfaceid,sum(A.DownTime) as DownTime  from #AE_Losses1 A
	inner join Machineinformation on Machineinformation.Machineid=A.Machineid
	inner join PlantMachine on PlantMachine.Machineid=Machineinformation.Machineid
	Left Outer Join PlantMachineGroups on A.machineID=PlantMachineGroups.machineID where 1=1 '
	Select @strsql = @strsql + @strPlantID + @strMachine + @strGroupID
	select @strsql = @strsql + ' group by A.Machineid,PlantMachineGroups.GroupID,A.HourID,A.ShiftID,A.DownCategory,A.downid,A.interfaceid'	
	print @strsql
	exec(@strsql)


	Select @strsql =''
	select @strsql = @strsql + 'UPDATE #Summary_AE_Losses SET downtime=ISNULL(downtime,0)+ISNULL(T.Down,0) FROM ( '
	select @strsql = @strsql + 'select A.machineid,machinedescription,A.HourID,A.ShiftID,A.DownCategory,A.downid,A.interfaceid,sum(A.DownTime) as Down  from #Summary_AE_Losses A
	inner join Machineinformation on Machineinformation.Machineid=A.Machineid
	inner join PlantMachine on PlantMachine.Machineid=Machineinformation.Machineid
	Left Outer Join PlantMachineGroups on A.machineID=PlantMachineGroups.machineID where 1=1 and A.downid='''+'NO_DATA'+''' '
	Select @strsql = @strsql + @strPlantID + @strMachine + @strGroupID
	select @strsql = @strsql + ' group by A.Machineid,A.machinedescription,A.HourID,A.ShiftID,A.DownCategory,A.downid,A.interfaceid ) T'
	select @strsql = @strsql + ' INNER JOIN #Summary_AE_Losses ON T.Machineid=#Summary_AE_Losses.machineid AND isnull(t.machinedescription,'''+''+''')=isnull(#Summary_AE_Losses.machinedescription,'''+''+''')
	and t.HourID=#Summary_AE_Losses.HourID and t.ShiftID=#Summary_AE_Losses.ShiftID and #Summary_AE_Losses.DownCategory='''+'Organizational Losses'+''' 
	and  #Summary_AE_Losses.interfaceid='''+'22'+''' '
	print @strsql
	exec(@strsql)

	Select T.machinedescription,T.HourID,T.ShiftID,T.DownCategory,T.downid,T.interfaceid,SUM(T.downtime) as downtime from(
	select case when @Machineid<>'' or @Groupid='' then machineid else machinedescription end as machinedescription,HourID,ShiftID,DownCategory,downid,interfaceid,downtime
	from #Summary_AE_Losses)T group by T.machinedescription,T.HourID,T.ShiftID,T.DownCategory,T.downid,T.interfaceid  order by T.MachineDescription,T.ShiftID,T.HourID
	return
End



	
update #ShiftTemp set Actual=T1.Actual1 from(
	select M.machineid as machine,S.FromTime as hrstart,S.ToTime as hrend,sum(A.partscount/O.suboperations) as Actual1
	from #T_autodata A
	inner join machineinformation M on M.interfaceid=A.mc
	inner join componentinformation C on C.interfaceid=A.comp
	inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
	inner join #ShiftTemp S on M.Machineid= S.machineid
	where A.datatype=1 and A.ndtime>S.FromTime and A.ndtime<=S.ToTime
	group by M.machineid,S.FromTime ,S.ToTime
) as T1 inner join #ShiftTemp on #ShiftTemp.machineid=T1.machine and #ShiftTemp.Fromtime=T1.hrstart and #ShiftTemp.totime=T1.hrend



insert into #PDT
select st.machineID,st.machineinterface,st.FromTime,st.ToTime,--pdt.StartTime,pdt.EndTime,
case when  st.FromTime > pdt.StartTime then st.FromTime else pdt.StartTime end,
case when  st.ToTime < pdt.EndTime then st.ToTime else pdt.EndTime end,pdt.DownReason,0
from #ShiftTemp st inner join PlannedDownTimes pdt
on st.machineID = pdt.Machine and PDTstatus = 1 and
((pdt.StartTime >= st.FromTime  AND pdt.EndTime <=st.ToTime)
OR ( pdt.StartTime < st.FromTime  AND pdt.EndTime <= st.ToTime AND pdt.EndTime > st.FromTime )
OR ( pdt.StartTime >= st.FromTime   AND pdt.StartTime <st.ToTime AND pdt.EndTime > st.ToTime )
OR ( pdt.StartTime < st.FromTime  AND pdt.EndTime > st.ToTime))

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	update #PDT set Actual=isnull(#PDT.Actual,0) + isNull(t1.Actual ,0) from(
		select M.machineid as machine,StartTime_PDT,EndTime_PDT,sum(A.partscount/O.suboperations) as Actual
		from #T_autodata A
		inner join machineinformation M on M.interfaceid=A.mc
		inner join componentinformation C on C.interfaceid=A.comp
		inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
		inner join #PDT  on M.Machineid= #PDT.machineid
		where A.datatype=1 and A.ndtime>#PDT.StartTime_PDT and A.ndtime<=#PDT.EndTime_PDT
		group by M.machineid,StartTime_PDT,EndTime_PDT
	) as t1 inner join #PDT on #PDT.machineid=t1.machine and #PDT.StartTime_PDT=t1.StartTime_PDT and #PDT.EndTime_PDT=t1.EndTime_PDT


	Update #ShiftTemp set Actual = isnull(#ShiftTemp.Actual,0) - isNull(t1.Actual ,0) from(
		Select MachineID,FromTime,ToTime,sum(Actual) as Actual from #PDT Group by MachineID,FromTime,ToTime
	) as t1 inner join #ShiftTemp on t1.machineID = #ShiftTemp.machineID and
	t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime
End



if isnull(@Param,'') = ''
Begin
	select machineID,MachineInterface,pDate,ShiftName,
	ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual
	from #ShiftTemp order by shiftid,hourid
	return
End

if isnull(@Param,'') = 'BOSCH_BNG_CamShaft'
Begin


	--The Maximum allowed Target or Actual is 120
	--Update #ShiftTemp set Target = 120 where Target > 120
	--Update #ShiftTemp set Actual = 120 where Actual > 120

--	insert into #Summary(MachineDescription,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)
--	select 'ACE FT',pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('%FT%') group by pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime
--
--		insert into #Summary(MachineDescription,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)
--	select 'ACE ST',pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('%ST%') group by pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime
--
--	insert into #Summary(MachineDescription,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)
--	select 'AMS A',pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('A%') group by pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime
--
--	insert into #Summary(MachineDescription,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)
--	select 'AMS B',pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('%B%') group by pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime
--
--	insert into #Summary(MachineDescription,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)
--	select 'KM DIA 6',pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('KM DIA 6') group by pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime
--
--	insert into #Summary(MachineDescription,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)
--	select 'KM DIA 1.43',pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('KM DIA 1.43') group by pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime
--
--	insert into #Summary(MachineDescription,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)
--	select 'KM DIA 2.2',pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('KM DIA 2.2') group by pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime
--
--	insert into #Summary(MachineDescription,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)
--	select 'KM A/F MILLING',pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('KM A/F MILLING') group by pDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime

	Select @strsql = '
	insert into #Summary(MachineID,MachineDescription,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Target,Actual)
	select S.MachineID,PlantMachineGroups.GroupID,S.pDate,S.ShiftName,S.ShiftID,S.HourName,S.HourID,S.FromTime,S.ToTime,sum(S.Target),sum(S.Actual)
	from #ShiftTemp S 
	inner join Machineinformation on Machineinformation.Machineid=S.Machineid
	inner join PlantMachine on PlantMachine.Machineid=Machineinformation.Machineid
	Left Outer Join PlantMachineGroups on S.machineID=PlantMachineGroups.machineID where 1=1'
	Select @strsql = @strsql + @strPlantID + @strMachine + @strGroupID
	Select @strsql = @strsql + ' group by S.MachineID,PlantMachineGroups.GroupID,S.pDate,S.ShiftName,S.ShiftID,S.HourName,S.HourID,S.FromTime,S.ToTime'
	Exec(@strsql)



	Select T.MachineDescription,T.PDate,T.ShiftName,T.ShiftID,T.HourName,T.HourID,T.FromTime,T.ToTime,SUM(T.Target) as Target,SUM(T.Actual) as Actual from 
	(select case when @Machineid<>'' or @Groupid='' then machineid else machinedescription end as MachineDescription,PDate,ShiftName,ShiftID,HourName,
	HourID,FromTime,ToTime,Target,Actual from #Summary
	)T Group by T.MachineDescription,T.PDate,T.ShiftName,T.ShiftID,T.HourName,T.HourID,T.FromTime,T.ToTime
	order by T.MachineDescription,T.ShiftID,T.HourID



End


if isnull(@Param,'') = 'BOSCH_BNG_CamShaftSummary'
Begin

	Delete from #summary

--	insert into #Summary(MachineDescription,Machineid,PDate,ShiftName,ShiftID,Target,Actual)
--	select 'ACE FT',Machineid,PDate,ShiftName,ShiftID,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('%FT%') group by Machineid,PDate,ShiftName,ShiftID
--
--	insert into #Summary(MachineDescription,Machineid,PDate,ShiftName,ShiftID,Target,Actual)
--	select 'ACE ST',Machineid,PDate,ShiftName,ShiftID,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('%ST%') group by Machineid,PDate,ShiftName,ShiftID
--
--	insert into #Summary(MachineDescription,Machineid,PDate,ShiftName,ShiftID,Target,Actual)
--	select 'AMS A',Machineid,PDate,ShiftName,ShiftID,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('A%') group by Machineid,PDate,ShiftName,ShiftID
--
--	insert into #Summary(MachineDescription,Machineid,PDate,ShiftName,ShiftID,Target,Actual)
--	select 'AMS B',Machineid,PDate,ShiftName,ShiftID,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('%B%') group by Machineid,PDate,ShiftName,ShiftID
--
--	insert into #Summary(MachineDescription,Machineid,PDate,ShiftName,ShiftID,Target,Actual)
--	select 'KM DIA 6',Machineid,PDate,ShiftName,ShiftID,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('KM DIA 6') group by Machineid,PDate,ShiftName,ShiftID
--
--	
--	insert into #Summary(MachineDescription,Machineid,PDate,ShiftName,ShiftID,Target,Actual)
--	select 'KM DIA 1.43',Machineid,PDate,ShiftName,ShiftID,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('KM DIA 1.43') group by Machineid,PDate,ShiftName,ShiftID
--
--	insert into #Summary(MachineDescription,Machineid,PDate,ShiftName,ShiftID,Target,Actual)
--	select 'KM DIA 2.2',Machineid,PDate,ShiftName,ShiftID,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('KM DIA 2.2') group by Machineid,PDate,ShiftName,ShiftID
--	
--	insert into #Summary(MachineDescription,Machineid,PDate,ShiftName,ShiftID,Target,Actual)
--	select 'KM A/F MILLING',Machineid,PDate,ShiftName,ShiftID,sum(Target),sum(Actual)
--	from #ShiftTemp where Machinedescription like ('KM A/F MILLING') group by Machineid,PDate,ShiftName,ShiftID

	Select @strsql = ''
	Select @strsql = 'insert into #Summary(MachineDescription,Machineid,PDate,ShiftName,ShiftID,Target,Actual)
	select ISNULL(PlantMachineGroups.GroupID,'' ''),S.Machineid,S.PDate,S.ShiftName,S.ShiftID,sum(S.Target),sum(S.Actual)
	from #ShiftTemp S 
	inner join Machineinformation on Machineinformation.Machineid=S.Machineid
	inner join PlantMachine on PlantMachine.Machineid=Machineinformation.Machineid
	Left Outer Join PlantMachineGroups on S.machineID=PlantMachineGroups.machineID WHERE 1=1 '
	Select @strsql = @strsql + @strPlantID + @strMachine + @strGroupID
	Select @strsql = @strsql + ' group by PlantMachineGroups.GroupID,S.Machineid,S.PDate,S.ShiftName,S.ShiftID'
	EXEC(@strsql)


	select MachineDescription,Machineid,PDate,ShiftName,ShiftID,Target,Actual from #Summary
	order by MachineDescription,ShiftID,Machineid

End

End
