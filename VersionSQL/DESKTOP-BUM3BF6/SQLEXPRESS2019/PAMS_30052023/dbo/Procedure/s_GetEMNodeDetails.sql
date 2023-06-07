/****** Object:  Procedure [dbo].[s_GetEMNodeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************************************************************
ER0398 - SwathiKS - 01/Feb/2015 :: Created New Proc. to show Energy details for MM Forge.
--s_GetEMNodeDetails '2014-03-29 06:00:00','2014-03-30 06:00:00','','1','',''
*****************************************************************************************************************/
CREATE procedure [dbo].[s_GetEMNodeDetails]
@Starttime datetime='',
@Endtime Datetime='',
@Plantid nvarchar(50)='',
@CellID nvarchar(50)='',
@Component nvarchar(50)='',
@Param nvarchar(50)=''
as
begin

SET NOCOUNT ON; --ER0383

Create table #PlannedDownTimes
(
	MachineID nvarchar(50) NOT NULL,
	MachineInterface nvarchar(50) NOT NULL, 
	StartTime DateTime NOT NULL, 
	EndTime DateTime NOT NULL 
)

ALTER TABLE #PlannedDownTimes
ADD PRIMARY KEY CLUSTERED
(   [MachineInterface],
	[StartTime],
	[EndTime]
				
) ON [PRIMARY]


CREATE TABLE #DailyProductionFromAutodataT1 
(
	CellID nvarchar(50),
	Machineinterface nvarchar(50) NOT NULL,
	Compinterface nvarchar(50) NOT NULL,
	Opninterface nvarchar(50) NOT NULL,
	MachineID nvarchar(50) NOT NULL,
	Component nvarchar(50) NOT NULL,
	CompDescription nvarchar(100) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	msttime datetime NOT NULL,
    ndtime datetime NOT NULL,   
    batchid int,
    autodataid bigint,
    plantid nvarchar(50),
	Qty float
)

CREATE TABLE #DailyProductionFromAutodataT2
(
	CellID nvarchar(50),
	Machineinterface nvarchar(50) NOT NULL,
	Compinterface nvarchar(50) NOT NULL,
	Opninterface nvarchar(50) NOT NULL,
	MachineID nvarchar(50) NOT NULL,
	Component nvarchar(50) NOT NULL,
	CompDescription nvarchar(100) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	msttime datetime NOT NULL,
    ndtime datetime NOT NULL,   
    batchid int,
    plantid nvarchar(50),
	Qty float,
	InputWt float default 0,
	ForgingWt Float default 0,
	kwh float default 0,
	MinEnergy float default 0,
	MaxEnergy float default 0,
	pf float default 0,
	kwhperton float default 0,
	kwhofinputwt float default 0
)


Declare @strSql as nvarchar(4000)
DECLARE @StrComp AS NvarChar(255)
Declare @strCellID as nvarchar(255)
Declare @strPlantID as nvarchar(255)


select @strSql = ''
select @strPlantID=''
select @strCellID=''
SELECT @StrComp=''


if isnull(@cellid,'')<> ''
begin
	SET @strCellID = ' AND CellHistory.CellID = N''' + @cellid + ''''
end

if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

If ISNULL(@Component,'')<>''
BEGIN
	SELECT @StrComp=' AND componentinformation.ComponentID=N'''+ @Component +''''
END

/* Planned Down times for the given time period */
SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT Machine,InterfaceID,
		CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
		CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
	FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
	WHERE PDTstatus =1 and(
	(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
	OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
SET @strSql =  @strSql  + ' ORDER BY Machine,StartTime'
EXEC(@strSql)


select @strsql = 'insert into #DailyProductionFromAutodataT1 (CellID,Machineinterface,MachineID,Compinterface,Component,CompDescription,Opninterface,Operation,msttime,ndtime,'
select @strsql = @strsql + 'batchid,autodataid,Plantid,Qty)'
select @strsql = @strsql + '( SELECT Cellhistory.cellid,machineinformation.interfaceid,machineinformation.machineid,componentinformation.interfaceid,componentinformation.componentid,componentinformation.description, '
select @strsql = @strsql + ' componentoperationpricing.interfaceid,componentoperationpricing.operationno, '
select @strsql = @strsql + ' Case when autodata.msttime< ''' + convert(nvarchar(20),@StartTime) + ''' then ''' + convert(nvarchar(20),@StartTime) + ''' else autodata.msttime end, 
Case when autodata.ndtime> ''' + convert(nvarchar(20),@EndTime) + ''' then ''' + convert(nvarchar(20),@EndTime) + ''' else autodata.ndtime end,'
select @strsql = @strsql + '0,autodata.id,Plantmachine.plantid,0'
select @strsql = @strsql + ' FROM autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID'
select @strsql = @strsql + ' inner join Cellhistory on Cellhistory.machineid=machineinformation.machineid  INNER JOIN  '
select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid '
select @strsql = @strsql + ' Left Outer Join Employeeinformation EI on EI.interfaceid=autodata.opr '
select @strsql = @strsql + ' Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode '
select @strsql = @strsql + ' WHERE	((autodata.msttime >= ''' + convert(nvarchar(20),@StartTime) + '''  AND autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + '	OR ( autodata.msttime < ''' + convert(nvarchar(20),@StartTime) + '''  AND autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime) + ''' AND autodata.ndtime >''' + convert(nvarchar(20),@StartTime) + ''' )'
select @strsql = @strsql + '	OR ( autodata.msttime >= ''' + convert(nvarchar(20),@StartTime) + '''   AND autodata.msttime <''' + convert(nvarchar(20),@EndTime) + ''' AND autodata.ndtime > ''' + convert(nvarchar(20),@EndTime) + ''' )'
select @strsql = @strsql + '	OR ( autodata.msttime < ''' + convert(nvarchar(20),@StartTime) + '''  AND autodata.ndtime > ''' + convert(nvarchar(20),@EndTime) + ''') )'
select @strsql = @strsql + @strPlantID + @strCellID + @StrComp
select @strsql = @strsql +  ' ) order by autodata.msttime'
print @strsql
exec(@strsql)


declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50)
declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@id nvarchar(50)
declare @batchid int
Declare @autodataid bigint,@autodataid_prev bigint
declare @setupcursor  cursor
set @setupcursor=cursor for
select autodataid,MachineID ,Component ,Operation  from #DailyProductionFromAutodataT1  order by machineid,msttime
open @setupcursor
fetch next from @setupcursor into @autodataid,@mc,@comp,@opn
set @autodataid_prev=@autodataid
set @mc_prev = @mc
set @comp_prev = @comp
set @opn_prev = @opn
set @batchid =1

while @@fetch_status = 0
begin
If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn	
	begin		
	    update #DailyProductionFromAutodataT1 set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn 
		print @batchid
	end
	else
	begin	
	      set @batchid = @batchid+1        
	      update #DailyProductionFromAutodataT1 set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn 
          set @autodataid_prev=@autodataid 
	      set @mc_prev=@mc 	
	      set @comp_prev=@comp
	      set @opn_prev=@opn	
	end	
	fetch next from @setupcursor into @autodataid,@mc,@comp,@opn
	
end
close @setupcursor
deallocate @setupcursor

insert into #DailyProductionFromAutodataT2 (CellID,PlantID,Machineinterface,MachineID,Compinterface,Component,CompDescription,Opninterface,operation,batchid,msttime,ndtime,Qty) 
Select CellID,PlantID,Machineinterface,MachineID,Compinterface,Component,CompDescription,Opninterface,operation,batchid,min(msttime),max(ndtime),Qty from #DailyProductionFromAutodataT1 group by CellID,PlantID,MachineID,Machineinterface,Compinterface,Component,CompDescription,operation,Opninterface,batchid,Qty order by batchid 

--Calculation of PartsCount Begins..
UPDATE #DailyProductionFromAutodataT2 SET Qty = ISNULL(Qty,0) + ISNULL(t2.Parts,0)
From
(	  
	Select mc,comp,opn,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Parts 
		   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn from autodata
			inner join #DailyProductionFromAutodataT2 on #DailyProductionFromAutodataT2.Machineinterface=autodata.mc
		   where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)
		   Group By mc,comp,opn) as T1
	Inner join componentinformation C on T1.Comp = C.interfaceid
	Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
	inner join machineinformation on machineinformation.machineid =O.machineid
	and T1.mc=machineinformation.interfaceid
	inner join #DailyProductionFromAutodataT2 on #DailyProductionFromAutodataT2.machineinterface=T1.mc
	GROUP BY mc,comp,opn
) As T2 Inner join #DailyProductionFromAutodataT2 on T2.mc = #DailyProductionFromAutodataT2.machineinterface
and T2.comp = #DailyProductionFromAutodataT2.Compinterface and T2.opn = #DailyProductionFromAutodataT2.Opninterface

--Mod 4 Apply PDT for calculation of Count
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN

	UPDATE  #DailyProductionFromAutodataT2 SET Qty = ISNULL(Qty,0) - ISNULL(T2.Parts,0) from
	(
			select mc,comp,opn,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as Parts From 
			( 
			select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn from autodata
			inner join #DailyProductionFromAutodataT2 on #DailyProductionFromAutodataT2.machineinterface=autodata.mc
			CROSS JOIN #PlannedDownTimes T
			WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
			AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
			AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)
		    Group by mc,comp,opn
			) as T1
	Inner join Machineinformation M on M.interfaceID = T1.mc
	inner join #DailyProductionFromAutodataT2 on #DailyProductionFromAutodataT2.machineinterface=T1.mc
	Inner join componentinformation C on T1.Comp=C.interfaceid
	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
	GROUP BY MC,comp,opn
	) as T2 Inner join #DailyProductionFromAutodataT2 on T2.mc = #DailyProductionFromAutodataT2.machineinterface
	and T2.comp = #DailyProductionFromAutodataT2.Compinterface and T2.opn = #DailyProductionFromAutodataT2.Opninterface

END


insert into #DailyProductionFromAutodataT2(CellID,PlantID,Machineinterface,MachineID,Compinterface,Component,CompDescription,Opninterface,operation,batchid,msttime,ndtime,Qty)
select CellID,PlantID,NI.NodeInterface,NI.NodeId,Compinterface,Component,CompDescription,Opninterface,operation,batchid,msttime,ndtime,0 from #DailyProductionFromAutodataT2
cross join MachineNodeInformation NI

update #DailyProductionFromAutodataT2 set Qty = isnull(Qty,0)+ isnull(T2.Parts,0) from
(select Machineinterface,msttime,ndtime,count(*) as Parts from Machinenodeautodata M
inner join #DailyProductionFromAutodataT2 D on D.Machineinterface=M.nodeinterface
where M.starttime>=D.msttime and M.starttime<=D.ndtime
group by Machineinterface,msttime,ndtime)as T2 Inner join #DailyProductionFromAutodataT2 on T2.Machineinterface = #DailyProductionFromAutodataT2.machineinterface
and T2.msttime = #DailyProductionFromAutodataT2.msttime and T2.ndtime = #DailyProductionFromAutodataT2.ndtime

update #DailyProductionFromAutodataT2 set Inputwt = isnull(inputwt,0)+ isnull(T1.Iwt,0),ForgingWt=isnull(Forgingwt,0)+isnull(T1.Fwt,0) from
(Select C.Componentid,C.inputweight as Iwt ,C.ForegingWeight as Fwt from Componentinformation C
inner join #DailyProductionFromAutodataT2 D on C.Componentid=D.Component)T1
inner join #DailyProductionFromAutodataT2 on T1.Componentid=#DailyProductionFromAutodataT2.Component


Update #DailyProductionFromAutodataT2 set PF = ISNULL(PF,0)+ISNULL(T2.AvgPF,0) from 
(
	select T.MachineiD,D.msttime,D.ndtime,avg(Abs(T.pf)) as AvgPF 
    from tcs_energyconsumption T WITH(NOLOCK) inner join #DailyProductionFromAutodataT2 D on 
	T.machineID = D.MachineID and T.gtime >= D.msttime
	and T.gtime <= D.ndTime group by T.MachineiD,D.msttime,D.ndtime
) as T2 Inner join #DailyProductionFromAutodataT2 on T2.Machineid = #DailyProductionFromAutodataT2.machineid
and T2.msttime = #DailyProductionFromAutodataT2.msttime and T2.ndtime = #DailyProductionFromAutodataT2.ndtime


Update #DailyProductionFromAutodataT2 set MinEnergy = ISNULL(MinEnergy,0)+ISNULL(t2.kwh,0) from 
(
	select T1.MachineiD,T1.msttime,T1.ndtime,round(kwh,2) as kwh from 
	(
	select  T.MachineiD,D.msttime,D.ndtime,min(gtime) as mingtime
	from tcs_energyconsumption T WITH(NOLOCK) inner join #DailyProductionFromAutodataT2 D on 
	T.machineID = D.MachineID and T.gtime >= D.msttime and T.gtime <= D.ndtime
	where T.kwh>0 group by  T.MachineiD,D.msttime,D.ndtime
	)T1 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T1.mingtime

) as T2 Inner join #DailyProductionFromAutodataT2 on T2.Machineid = #DailyProductionFromAutodataT2.machineid
and T2.msttime = #DailyProductionFromAutodataT2.msttime and T2.ndtime = #DailyProductionFromAutodataT2.ndtime

Update #DailyProductionFromAutodataT2 set MaxEnergy = ISNULL(MaxEnergy,0)+ISNULL(t2.kwh,0) from 
(
	select T1.MachineiD,T1.msttime,T1.ndtime,round(kwh,2) as kwh from 
	(
	select  T.MachineiD,D.msttime,D.ndtime,max(gtime) as maxgtime
	from tcs_energyconsumption T WITH(NOLOCK) inner join #DailyProductionFromAutodataT2 D on 
	T.machineID = D.MachineID and T.gtime >= D.msttime and T.gtime <= D.ndtime
	where T.kwh>0 group by  T.MachineiD,D.msttime,D.ndtime
	)T1 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T1.maxgtime

) as T2 Inner join #DailyProductionFromAutodataT2 on T2.Machineid = #DailyProductionFromAutodataT2.machineid
and T2.msttime = #DailyProductionFromAutodataT2.msttime and T2.ndtime = #DailyProductionFromAutodataT2.ndtime

Update #DailyProductionFromAutodataT2 set kwh = Isnull(round((MaxEnergy - MinEnergy),2) ,0)

Update #DailyProductionFromAutodataT2 set kwhperton = Isnull(round((kwh/ForgingWt),2) ,0) where ForgingWt>0

Update #DailyProductionFromAutodataT2 set kwhofinputwt=Isnull(round(((inputwt*1000)/kwh),2) ,0) where kwh>0

select CellID,MachineID,Component,CompDescription,Operation,Qty,ForgingWt,InputWt,round(kwh,2) as kwh,round(kwhperton,2) as kwhperton,round(pf,2) as pf,
round(kwhofinputwt,2) as kwhofinputwt from #DailyProductionFromAutodataT2 order by msttime,Machineinterface

end
