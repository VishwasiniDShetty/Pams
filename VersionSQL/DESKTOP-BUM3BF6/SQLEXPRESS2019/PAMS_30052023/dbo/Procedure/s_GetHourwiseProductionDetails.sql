/****** Object:  Procedure [dbo].[s_GetHourwiseProductionDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetHourwiseProductionDetails] '2013-01-09 06:00:00 AM','2013-01-09 02:00:00 PM','A','ACE VTL-02',''

CREATE     PROCEDURE [dbo].[s_GetHourwiseProductionDetails]
	@StartTime datetime ,
	@Endtime Datetime,
	@SHIFTNAME nvarchar(50),
	@machineid nvarchar(50),
	@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

Create table #HourlyData
(
	 Machineid nvarchar(50),  
	 FromTime datetime,  
	 ToTime Datetime,  
	 Actual float,  
	 Target float Default 0,
	 Eff float default 0,
	 Color nvarchar(20)
)

Create Table #ShiftTemp  
 (  
  PDate datetime,  
  ShiftName nvarchar(20),  
  FromTime datetime,  
  ToTime Datetime,  
 ) 

CREATE TABLE #Target  
(

	MachineID nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	OpnInterface nvarchar(50),
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	msttime datetime,
    ndtime datetime,
	FromTm datetime,
	ToTm datetime,   
    runtime int,   
	Targetpercent float,
    batchid int,
    autodataid bigint,
	Suboperation int,
	StdCycletime float
)

CREATE TABLE #FinalTarget  
(

	MachineID nvarchar(50) NOT NULL,
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	OpnInterface nvarchar(50),
	msttime datetime,
    ndtime datetime,
	FromTm datetime,
	ToTm datetime,   
    runtime int,   
	Targetpercent float,
    batchid int,
	Suboperation int,
	StdCycletime float,
	Target float Default 0
)

CREATE TABLE #T_autodataforDown
(
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] NULL,
	[datatype] [tinyint] NULL ,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] NULL,
	[PartsCount] [int] NULL ,
	id  bigint not null
)

ALTER TABLE #T_autodataforDown

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime ASC
)ON [PRIMARY]

declare @curstarttime as datetime  
Declare @curendtime as datetime  
declare @curstart as datetime  
declare @hourid nvarchar(50)  
Declare @StrDiv int  
Declare @counter as datetime  	

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime

Declare @strsql nvarchar(4000)
Declare @strmachine nvarchar(255)


if isnull(@machineid,'') <> ''
Begin
	Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'
End

If @param = ''
BEGIN

	  select @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')  
        
      select @counter=  CASE  
      WHEN FROMDAY=1 AND TODAY=1 THEN dbo.f_GetLogicalDayStart(@counter)  
      WHEN FROMDAY=0 AND TODAY=1 THEN @COUNTER  
      WHEN FROMDAY=0 AND TODAY=0 THEN @COUNTER  
      END FROM SHIFTDETAILS WHERE RUNNING=1 AND SHIFTNAME=@SHIFTNAME  

      Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)  
      Exec s_GetShiftTime @counter,@ShiftName  
    
      SELECT TOP 1 @counter=FromTime FROM #ShiftTemp ORDER BY FromTime ASC  
      SELECT TOP 1 @EndTime=ToTime FROM #ShiftTemp ORDER BY FromTime DESC  
      select @StrDiv=cast (ceiling (cast(datediff(second,@counter,@EndTime)as float ) /3600) as int)   

      While(@counter < @EndTime)  
      BEGIN  
        SELECT @curstarttime=@counter  
        SELECT @curendtime=DATEADD(Second,3600,@counter)  
        if @curendtime >= @EndTime  
        Begin  
         set @curendtime = @EndTime  
        End  

		 Insert into #HourlyData(Machineid,FromTime,ToTime,Actual,Target)
		 Select @machineid,convert(nvarchar(20),@curstarttime),convert(nvarchar(20),@curendtime),0,0
	     SELECT @counter = DATEADD(Second,3600,@counter)  
     END  

		
	Select @T_ST=min(FromTime) from #HourlyData 
	Select @T_ED=max(Totime) from #HourlyData 

	Select @strsql=''
	select @strsql ='insert into #T_autodataforDown '
	select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
	select @strsql = @strsql + ' from autodata inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc 
	where (datatype=1) and (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
	select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
	select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					 and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
	select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
	select @strsql = @strsql + @strmachine
	print @strsql
	exec (@strsql)

	Select @strsql=''
	select @strsql ='insert into #T_autodataforDown '
	select @strsql = @strsql + 'SELECT A1.mc, A1.comp, A1.opn, A1.opr, A1.dcode,A1.sttime,'
	 select @strsql = @strsql + 'A1.ndtime, A1.datatype, A1.cycletime, A1.loadunload, A1.msttime, A1.PartsCount,A1.id'
	select @strsql = @strsql + ' from autodata A1 inner join Machineinformation on Machineinformation.interfaceid=A1.mc where A1.datatype=2 and
	(( A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
	 ( A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
	 (A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) or
	 (A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and A1.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
	and NOT EXISTS ( select * from Autodata A2 inner join Machineinformation on Machineinformation.interfaceid=A2.mc where  A2.datatype=1 and  ((  A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
	 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
	 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) 
	OR (A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and  A2.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
	and A2.sttime<=A1.sttime and A2.ndtime>A1.ndtime and A1.mc=A2.mc'
	select @strsql = @strsql + @strmachine
	select @strsql = @strsql + ' )'
	select @strsql = @strsql + @strmachine
	print @strsql
	exec (@strsql)

	Update #HourlyData set Actual = Isnull(Actual,0) + Isnull(T1.Comp,0) from  
	(Select M.machineid,T.FromTime,T.ToTime,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
	from autodata A
	Inner join machineinformation M on M.interfaceid=A.mc
	Inner join #HourlyData T on T.machineid=M.machineid
	Inner join componentinformation C ON A.Comp=C.interfaceid
	Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
	WHERE A.DataType=1 and M.machineid=@Machineid
	AND(A.ndtime > T.FromTime  AND A.ndtime <=T.ToTime)
	Group by M.machineid,T.FromTime,T.ToTime)T1 inner join #HourlyData on #HourlyData.FromTime=T1.FromTime
	and #HourlyData.ToTime=T1.ToTime and #HourlyData.machineid=T1.machineid

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN

		Update #HourlyData set Actual = Isnull(Actual,0) - Isnull(T1.Comp,0) from  
		(Select M.machineid,T1.FromTime,T1.ToTime,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
		from autodata A
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join #HourlyData T1 on T1.machineid=M.machineid
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		CROSS jOIN PlannedDownTimes T
		WHERE A.DataType=1 and T.machine=T1.Machineid and M.machineid=@Machineid
		AND(A.ndtime > T1.FromTime  AND A.ndtime <=T1.ToTime)
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		Group by M.machineid,T1.FromTime,T1.ToTime)T1 inner join #HourlyData on #HourlyData.FromTime=T1.FromTime
		and #HourlyData.ToTime=T1.ToTime and #HourlyData.machineid=T1.machineid	
	END


	insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,
	msttime,ndtime,FromTm,ToTm,batchid,runtime,autodataid,Targetpercent,Suboperation,StdCycletime)
	SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,
	componentoperationpricing.operationno, componentoperationpricing.interfaceid,
	Case when autodata.msttime< T.fromtime then T.fromtime else autodata.msttime end, 
	Case when autodata.ndtime> T.totime then T.totime else autodata.ndtime end,
	T.fromtime,T.totime,0,0,autodata.id,isnull(componentoperationpricing.Targetpercent,100)
	,isnull(componentoperationpricing.Suboperations,1),isnull(componentoperationpricing.Cycletime,0) FROM #T_autodataforDown  autodata
	INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID 
    INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID  
	INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
	AND componentinformation.componentid = componentoperationpricing.componentid
	and componentoperationpricing.machineid=machineinformation.machineid 
	Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid 
	Left Outer Join Employeeinformation EI on EI.interfaceid=autodata.opr 
	Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode 
	Cross join #HourlyData T
	WHERE machineinformation.machineid = @machineid and	((autodata.msttime >= T.fromtime  AND autodata.ndtime <= T.totime)
	OR ( autodata.msttime < T.fromtime  AND autodata.ndtime <= T.totime AND autodata.ndtime >T.fromtime )
	OR ( autodata.msttime >= T.fromtime   AND autodata.msttime <T.totime AND autodata.ndtime > T.totime )
	OR ( autodata.msttime < T.fromtime  AND autodata.ndtime > T.totime ))
	order by autodata.msttime

	declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50),@From_Prev datetime
	declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@Fromtime datetime,@id nvarchar(50)
	declare @batchid int
	Declare @autodataid bigint,@autodataid_prev bigint
	declare @setupcursor  cursor
	set @setupcursor=cursor for
	select autodataid,FromTm,MachineID ,Component ,Operation  from #Target order by machineid,msttime
	open @setupcursor
	fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn
	set @autodataid_prev=@autodataid
	set @mc_prev = @mc
	set @comp_prev = @comp
	set @opn_prev = @opn
	SET @From_Prev = @Fromtime
	set @batchid =1

	while @@fetch_status = 0
	begin
	If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn	and @From_Prev = @Fromtime
		begin		
			update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and FromTm=@Fromtime
			print @batchid
		end
		else
		begin	
			  set @batchid = @batchid+1        
			  update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and FromTm=@Fromtime
			  set @autodataid_prev=@autodataid 
			  set @mc_prev=@mc 	
			  set @comp_prev=@comp
			  set @opn_prev=@opn	
			  SET @From_Prev = @Fromtime
		end	
		fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn
		
	end
	close @setupcursor
	deallocate @setupcursor

	insert into #FinalTarget (MachineID,Component,operation,machineinterface,Compinterface,Opninterface,Runtime,batchid,msttime,ndtime,FromTm,ToTm,Targetpercent,Suboperation,StdCycletime) 
	Select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,datediff(s,min(msttime),max(ndtime)),batchid,min(msttime),max(ndtime),FromTm,ToTm,Targetpercent,Suboperation,StdCycletime from #Target 
	group by MachineID,Component,operation,batchid,FromTm,ToTm,Targetpercent,machineinterface,Compinterface,Opninterface,Suboperation,StdCycletime order by batchid 

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
	BEGIN

	Update #FinalTarget set Runtime = Isnull(Runtime,0) - Isnull(T1.MLDown,0) from
	(
		select T.machineinterface,T.Compinterface,T.Opninterface,T.FromTm,T.ToTm,SUM
		    (CASE
			WHEN (autodata.sttime >= T.msttime  AND autodata.ndtime <=T.ndtime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.msttime  AND autodata.ndtime <= T.ndtime  AND autodata.ndtime > T.msttime ) THEN DateDiff(second,T.msttime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.msttime   AND autodata.sttime <T.ndtime  AND autodata.ndtime > T.ndtime  ) THEN DateDiff(second,autodata.sttime,T.ndtime )
			WHEN ( autodata.sttime < T.msttime  AND autodata.ndtime > T.ndtime ) THEN DateDiff(second,T.msttime,T.ndtime )
			END ) as MLDown
		from autodata  
		INNER JOIN #FinalTarget T on T.machineinterface=Autodata.mc and T.Compinterface=Autodata.comp
		and T.Opninterface = Autodata.opn
		INNER JOIN DownCodeInformation ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2 AND
		((autodata.sttime >= T.msttime  AND autodata.ndtime <=T.ndtime)
		OR ( autodata.sttime < T.msttime  AND autodata.ndtime <= T.ndtime AND autodata.ndtime > T.msttime )
		OR ( autodata.sttime >= T.msttime   AND autodata.sttime <T.ndtime AND autodata.ndtime > T.ndtime )
		OR ( autodata.sttime < T.msttime  AND autodata.ndtime > T.ndtime))
		AND (downcodeinformation.availeffy = 1)
		group by T.machineinterface,T.Compinterface,T.Opninterface,T.FromTm,T.ToTm
	)T1 inner join  #FinalTarget on  T1.machineinterface=#FinalTarget.machineinterface and T1.Compinterface=#FinalTarget.Compinterface
	and T1.Opninterface=#FinalTarget.Opninterface and T1.FromTm=#FinalTarget.FromTm and #FinalTarget.ToTm=T1.ToTm

	END

	Update #FinalTarget set Target = Isnull(Target,0) + isnull(T1.targetcount,0) from
	(Select machineinterface,Compinterface,Opninterface,FromTm,ToTm,sum(((Runtime*suboperation)/stdcycletime)*isnull(targetpercent,100) /100) as targetcount
	 from #FinalTarget group by machineinterface,Compinterface,Opninterface,FromTm,ToTm)T1 inner join #FinalTarget on  T1.machineinterface=#FinalTarget.machineinterface and T1.Compinterface=#FinalTarget.Compinterface
	and T1.Opninterface=#FinalTarget.Opninterface and T1.FromTm=#FinalTarget.FromTm and #FinalTarget.ToTm=T1.ToTm

	Update #HourlyData set Target = Isnull(Target,0) + isnull(T1.TCount,0) from 
	(Select machineid,FromTm,ToTm,Sum(Target) as Tcount from #FinalTarget
	 Group by machineid,FromTm,ToTm)T1 inner join #HourlyData on #HourlyData.machineid=T1.machineid and
	 #HourlyData.Fromtime=T1.FromTm and  #HourlyData.Totime=T1.ToTm

	Declare @GreenEff int,@RedEff int
	Select @GreenEff = Valueintext from Shopdefaults where parameter='TempleAndonGreen'
	Select @RedEff = Valueintext from Shopdefaults where parameter='TempleAndonRed'

	Update #HourlyData set Eff = Round(((Round(Actual,0)/Round(Target,0))*100),2) where Target>0

	Update #HourlyData set Color = Case when Eff >= @GreenEff then 'Green' When Eff >= @RedEff and Eff < @GreenEff then 'Yellow' 
	When Eff >=  0 AND Eff <  @RedEff then 'Red' ELSE 'WHITE' End

	update #HourlyData set color = 'white' where Target=0 

	update #HourlyData set color = 'white',Target=0,Actual=0 where FromTime >= getdate() 
	
	select Machineid,Fromtime,Totime,Round(Actual,0) as Actual,Round(Target,0) as Target,Eff,Color from #HourlyData
END



If @Param = 'RunningPart'
BEGIN
	  select top 1 M.Machineid,C.Componentid as Componentid,E.Employeeid as OperatorID from Autodata A  
      inner join Machineinformation M on A.mc=M.interfaceid  
      inner join Componentinformation C on A.comp=C.interfaceid  
      inner join Componentoperationpricing CO on A.opn=CO.interfaceid  
      and M.Machineid=CO.Machineid and C.Componentid=CO.Componentid  
	  inner join Employeeinformation E on A.opr=E.interfaceid
      where M.Machineid=@machineid and sttime>=@starttime and ndtime<=@endtime   
      order by sttime desc  
END

END
