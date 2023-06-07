/****** Object:  Procedure [dbo].[s_GetEnergyData_CycleLevel]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************************************************************************************************************************
--Procedure Created by Karthikg on 17/Nov/2009.
--NR0063-KarthikG-02/Nov/2009 :: New procedure 's_GetEnergyData_CycleLevel' to populate second screen of energy cockpit dynamically.
--ER00212-KarthickR-29-Dec-2009
Mod 1 :- Introduce minute level (1,2,3,4,5 min) energy consuption in second screen of energy cockpit.
DR0304 - SwathiKS - 12/Jan/2012 :: To Allow Decimals in kwh and kw values.
ER0383 - SwathiKS - 29/May/2014 :: Performance Optimization.

s_GetEnergyData '2011-08-27','','','','Day','History'
select * from machineinformation
s_GetEnergyData_CycleLevel_Modifiedkwh '07-Jan-2013 06:00:00','08-Jan-2013 06:00:00','JOBBER XL','bearing','1','Grid_GraphData_CycleLevel','Live','0'
***************************************************************************************************************************************************/
CREATE     procedure [dbo].[s_GetEnergyData_CycleLevel]
	@StartTime datetime ,
	@EndTime datetime,
	@MachineID nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperationNo SmallInt = '',
	@Parameter nvarchar(50)='',--Machinelevelstatistics,COLevelstatistics,Grid_GraphData_CycleLevel,Grid_GraphData_mintue
	@HistoryLive nvarchar(50)='History'--History,Live
--mod 1
	,@No_Of_Minute int --0,1,2,3,4,5
--mod 1
as
Begin


CREATE TABLE #FinalData
(
	MachineID NvarChar(50),
	MachineInterface nvarchar(50),
	StartTime DateTime,
	EndTime DateTime,
	UtilisedTime float,
	Energy_kwh float,
	Cycles int,
	Cost float,
	EnergyEfficiency float,
	MinEnergykwh float,
	Maxenergykwh float,
	Lthreshold float,
	uthreshold float
)
--mod 1


--Geeta added from here
create Table #Energydata
(
Machineid nvarchar(50),
Col1_ID int,
Col2_ID int,
st datetime,
nd datetime,
Col1_gtime Datetime,
Col2_gtime Datetime,
Col1_Amp float,
Col2_Amp float,
Col1_COl2 float
)
create table #temp
(
Machine nvarchar(50),
Componentid nvarchar(50),
OperationNo nvarchar(50),
Operator nvarchar(50),
starttime datetime,
Endtime datetime,
Mingtime datetime,
Maxgtime datetime,
Energy_Kwh float,
minEnergykwh float,
maxenergykwh float,
PF float,
LThreshold float,
UThreshold float,
Cuttingdetail float,
TotalCuttingTime float,
strCuttingdetail datetime,
strTotalCuttingTime datetime
)

create table #CODetails
(
Machine nvarchar(50),
Componentid nvarchar(50),
OperationNo nvarchar(50),
Operator nvarchar(50),
TotCompCount int,
CycAbvThreshold float,
CycBelowThreshold float,
MaxEnergy float,
MinEnergy float,
AvgEnergy float
)
--Geeta added til here


CREATE TABLE #minlevel
(
MachineID NvarChar(50),
StartTime DateTime,
EndTime DateTime,
mingtime datetime,
maxgtime datetime,
Energy_Kwh float,
Pf float,
Minenergykwh float,
Maxenergykwh float
)

Declare @st datetime

If datediff(d, @StartTime,@EndTime) <= 2 
begin

		--mod 1
		if @HistoryLive = 'Live'
		Begin

		---ER0383 from Here
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
			[PartsCount] [int] NULL ,
			id  bigint not null
		)

		ALTER TABLE #T_autodata

		ADD PRIMARY KEY CLUSTERED
		(
			mc,sttime,ndtime,msttime ASC
		)ON [PRIMARY]

		Declare @strSql as nvarchar(4000)
		Declare @T_ST AS Datetime 
		Declare @T_ED AS Datetime 

		select @strsql = ''
		Select @T_ST=dbo.f_GetLogicalDay(@StartTime,'start')
		Select @T_ED=dbo.f_GetLogicalDay(@EndTime,'End')

		Select @strsql=''
		select @strsql ='insert into #T_autodata '
		select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
			select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
		select @strsql = @strsql + ' from autodata WITH(NOLOCK) where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR ' ---ER0383
		select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
		select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
							and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
		select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
		print @strsql
		exec (@strsql)
		--ER0383 till Here


			if @Parameter = 'Machinelevelstatistics'
			Begin

				Insert into #FinalData
				select top 1 MachineID,InterfaceID,@StartTime,@EndTime,0,0,0,0,0,0,0,0,0 from machineinformation where machineid = @MachineID	



						insert into #temp (Machine,Componentid,OperationNo,Operator,starttime,Endtime,
						mingtime,maxgtime,Energy_Kwh,minEnergykwh,maxEnergykwh,PF
						,LThreshold,UThreshold,Cuttingdetail,TotalCuttingTime)
						Select mi.Machineid,ci.ComponentID as ComponentID,cop.OperationNo as OperationNo,
						e.Employeeid as Operator,sttime as StartTime,ndtime as EndTime,min(gtime),max(gtime),
						0,0,0,Isnull(Round(Avg(abs(pf)),2),0) as PF,
						lowerenergythreshold as LThreshold,upperenergythreshold as UThreshold,0,0
						from #T_autodata A --ER0383
						inner join Machineinformation mi on A.mc = mi.interfaceid
						inner join componentinformation ci on A.comp = ci.interfaceid
						inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
						inner join employeeinformation e on A.opr = e.interfaceid
						left outer join tcs_energyconsumption tec WITH(NOLOCK) on tec.Machineid = mi.MachineID and tec.gtime >= A.sttime and tec.gtime <= A.ndtime --ER0383
						where datatype = 1 and --sttime >= @StartTime and ndtime <= @EndTime 	
						ndtime>@StartTime and ndtime<=@EndTime
						and mi.Machineid = @MachineID
						group by mi.Machineid,ci.ComponentID,cop.OperationNo,e.Employeeid,sttime,ndtime,lowerenergythreshold,upperenergythreshold
						order by sttime

						update #temp set minEnergykwh = isnull(minEnergykwh,0) + isnull(kwh,0) 
						from
						(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,mingtime,
						round(kwh,5) as kwh from #temp
						left outer join tcs_energyconsumption tec WITH(NOLOCK) on tec.Machineid = #temp.Machine  --ER0383
						and tec.gtime=mingtime)T2
						inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
						and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
						#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.mingtime=T2.mingtime

						update #temp set maxEnergykwh = isnull(maxEnergykwh,0) + isnull(kwh,0) 
						from
						(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,maxgtime,
						round(kwh,5) as kwh from #temp
						left outer join tcs_energyconsumption tec WITH(NOLOCK) on tec.Machineid = #temp.Machine  --ER0383
						and tec.gtime=maxgtime)T2
						inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
						and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
						#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.maxgtime=T2.maxgtime
						

						update #temp set Energy_Kwh = isnull(Energy_Kwh,0) + isnull(kwh,0) 
						from
						(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,
						round(isnull((maxEnergykwh - minEnergykwh),0),5) as kwh from #temp)T2
						inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
						and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
						#temp.starttime=T2.starttime and #temp.endtime=T2.endtime



						Update #FinalData set EnergyEfficiency = t2.EnergyEff from (
						select Machine,isnull(round(sum((case when t1.Energy>=t1.lowerenergythreshold then 1 END)* t1.upperenergythreshold)/isnull(sum(case when t1.Energy>=t1.lowerenergythreshold then t1.Energy END),1)* 100,2),0)  as EnergyEff
						 from (select Machine,Componentid,OperationNo,starttime,Endtime,
								Energy_kwh as energy,LThreshold as lowerenergythreshold,UThreshold as upperenergythreshold from #temp
							  ) as t1 group by Machine
							  ) as t2

						Update #FinalData set Minenergykwh = t2.minkwh from 
						(
							 Select T1.machineid,round(kwh,2) as minkwh from 
								(select mi.machineid,min(gtime) as mingtime 
								 from #T_autodata A --ER0383
								inner join Machineinformation mi on A.mc = mi.interfaceid
								inner join tcs_energyconsumption tec WITH(NOLOCK) on tec.gtime >= A.sttime and tec.gtime <= A.ndtime and tec.Machineid = mi.Machineid --ER0383
								where mi.Machineid = @MachineID and A.datatype = 1 and sttime >= @StartTime and ndtime <= @EndTime
								group by mi.machineid
								) as t1 inner join tcs_energyconsumption on tcs_energyconsumption.machineid=t1.machineid and tcs_energyconsumption.gtime=T1.mingtime 
						) as t2 inner join #FinalData on t2.machineiD = #FinalData.machineID 


						Update #FinalData set Maxenergykwh = t2.maxkwh from 
						(
						   select T1.machineid,round(kwh,2) as maxkwh from 
							(select mi.machineid,max(gtime) as maxgtime 
							 from #T_autodata A --ER0383
							inner join Machineinformation mi on A.mc = mi.interfaceid
							inner join tcs_energyconsumption tec WITH(NOLOCK) on tec.gtime >= A.sttime and tec.gtime <= A.ndtime and tec.Machineid = mi.Machineid --ER0383
							where mi.Machineid = @MachineID and A.datatype = 1 and sttime >= @StartTime and ndtime <= @EndTime
							group by mi.machineid
							) as t1 inner join tcs_energyconsumption on tcs_energyconsumption.machineid=t1.machineid and tcs_energyconsumption.gtime=T1.maxgtime 
						) as t2 inner join #FinalData on t2.machineiD = #FinalData.machineID 


						Update #FinalData
						set #FinalData.Energy_kwh = ISNULL(#FinalData.Energy_kwh,0)+ISNULL(t1.kwh,0), 
						#FinalData.Cost = ISNULL(#FinalData.Cost,0)+ISNULL(t1.kwh * (Select max(Valueintext) from shopdefaults where Parameter = 'CostPerKWH'),0)
						from 
						(
							select MachineiD,StartTime,EndTime,round((Maxenergykwh - Minenergykwh),2) as kwh from #FinalData 
						) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID and
						t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime


						--select * from #FinalData
						--return
						-- Type 1
						UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(
							select mc,#FinalData.StartTime,#FinalData.EndTime,sum(cycletime+loadunload) as cycle
							from #T_autodata autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383
							where (autodata.msttime>=#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime)and (autodata.datatype=1)
							group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime
						) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

						-- Type 2
						UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(
							select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, #FinalData.StartTime, ndtime)) as cycle
							from #T_autodata autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383
							where (autodata.msttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime) and (autodata.datatype=1)
							group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime
						) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

						-- Type 3
						UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(
							select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, mstTime, #FinalData.EndTime)) as cycle
							from #T_autodata autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383
							where (autodata.msttime>=#FinalData.StartTime) and (autodata.msttime<#FinalData.EndTime) and (autodata.ndtime>#FinalData.EndTime) and (autodata.datatype=1)
							group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime
						) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					-- Type 4
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(
						select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, #FinalData.StartTime, #FinalData.EndTime)) as cycle
						from #T_autodata autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383
						where (autodata.msttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.EndTime) and (autodata.datatype=1)
						group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					----/* Fetching Down Records from Production Cycle  */
					----/* If Down Records of TYPE-2 */
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(
						select A1.mc,#FinalData.StartTime,#FinalData.EndTime,
						case
							When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)
							When A2.sttime < #FinalData.StartTime And A2.ndtime > #FinalData.StartTime AND A2.ndtime<=#FinalData.EndTime Then datediff(s, #FinalData.StartTime,A2.ndtime )
						end as Down
						from #T_autodata A1 cross join #T_autodata A2 cross join #FinalData --ER0383
						where A1.datatype = 1 and A2.datatype = 2
						and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc
						and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime
						and A1.sttime < #FinalData.StartTime
						and A1.ndtime > #FinalData.StartTime
						and A1.ndtime <= #FinalData.EndTime
						and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					----/* If Down Records of TYPE-3 */
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(
						select A1.mc,#FinalData.StartTime,#FinalData.EndTime,
						case
							When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)
							When A2.sttime>=#FinalData.StartTime And A2.sttime < #FinalData.EndTime and A2.ndtime > #FinalData.EndTime Then datediff(s,A2.sttime, #FinalData.EndTime )
						end as Down
						from #T_autodata A1 cross join #T_autodata A2 cross join #FinalData --ER0383
						where A1.datatype = 1 and A2.datatype = 2
						and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc
						and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime
						and A1.sttime >= #FinalData.StartTime
						and A1.sttime < #FinalData.EndTime
						and A1.ndtime > #FinalData.EndTime
						and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					----/* If Down Records of TYPE-4 */
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(
						select A1.mc,#FinalData.StartTime,#FinalData.EndTime,
						case
							When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)
							When A2.sttime < #FinalData.StartTime And A2.ndtime > #FinalData.StartTime AND A2.ndtime<=#FinalData.EndTime Then datediff(s, #FinalData.StartTime,A2.ndtime )
							When A2.sttime>=#FinalData.StartTime And A2.sttime < #FinalData.EndTime and A2.ndtime > #FinalData.EndTime Then datediff(s,A2.sttime, #FinalData.EndTime )
							When A2.sttime<#FinalData.StartTime AND A2.ndtime>#FinalData.EndTime   Then datediff(s, #FinalData.StartTime,#FinalData.EndTime)
						end as Down
						from #T_autodata A1 cross join #T_autodata A2 cross join #FinalData --ER0383
						where A1.datatype = 1 and A2.datatype = 2
						and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc
						and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime
						and A1.sttime < #FinalData.StartTime
						and A1.ndtime > #FinalData.EndTime
						and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					UPDATE #FinalData SET Cycles = ISNULL(Cycles,0) + ISNULL(t2.comp,0)
					From(
					select Autodata.mc,#FinalData.StartTime,#FinalData.EndTime,
					SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp
					from #T_autodata autodata --ER0383
					inner join #FinalData on autodata.mc = #FinalData.machineinterface
					Inner join componentinformation C on autodata.Comp = C.interfaceid
					Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid
					inner join machineinformation on machineinformation.machineid =O.machineid and autodata.mc=machineinformation.interfaceid
					Where Autodata.datatype = 1
					and Autodata.ndtime > #FinalData.StartTime and Autodata.ndtime <= #FinalData.EndTime
					Group by Autodata.mc,#FinalData.StartTime,#FinalData.EndTime
					) As T2 Inner join #FinalData on T2.mc = #FinalData.machineinterface and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime

					select MachineID,StartTime,EndTime,
					dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as UtilisedTime,
					--round(Energy_Kwh,2) as Energy_Kwh, DR0304 commented here
					round(Energy_Kwh,2) as Energy_Kwh,-- DR0304 added here
					Cycles,round(Cost,2) as Cost,EnergyEfficiency,Minenergykwh,Maxenergykwh from #FinalData
			End
			
			if @Parameter = 'COLevelstatistics'
			Begin

						insert into #temp (Machine,Componentid,OperationNo,Operator,starttime,Endtime,
						Mingtime,Maxgtime,Energy_Kwh,Minenergykwh,Maxenergykwh,PF
						,LThreshold,UThreshold,Cuttingdetail)
						Select mi.Machineid,ci.ComponentID as ComponentID,cop.OperationNo as OperationNo,
						e.Employeeid as Operator,sttime as StartTime,ndtime as EndTime,
						--Round(isnull(max(kwh),0)-Isnull(min(kwh),0),2) as Energy_Kwh, DR0304 commented here
						--Round(isnull(max(kwh),0)-Isnull(min(kwh),0),5) as Energy_Kwh,--DR0304 added here
						min(gtime),max(gtime),
						0,0,0,Isnull(Round(Avg(case when pf>=0 then pf end),2),0) as PF,
						lowerenergythreshold as LThreshold,upperenergythreshold as UThreshold,0
						from #T_autodata A --ER0383
						inner join Machineinformation mi on A.mc = mi.interfaceid
						inner join componentinformation ci on A.comp = ci.interfaceid
						inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
						inner join employeeinformation e on A.opr = e.interfaceid
						left outer join tcs_energyconsumption tec WITH(NOLOCK) on tec.Machineid = mi.MachineID and tec.gtime >= A.sttime and tec.gtime <= A.ndtime --ER0383
						where datatype = 1 and --sttime >= @StartTime and ndtime <= @EndTime 	
						ndtime>@starttime and ndtime<=@endtime
						and mi.Machineid = @MachineID
						group by mi.Machineid,ci.ComponentID,cop.OperationNo,e.Employeeid,sttime,ndtime,lowerenergythreshold,upperenergythreshold
						order by sttime

						update #temp set minEnergykwh = isnull(minEnergykwh,0) + isnull(kwh,0) 
						from
						(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,mingtime,
						round(kwh,5) as kwh from #temp
						left outer join tcs_energyconsumption tec WITH(NOLOCK) on tec.Machineid = #temp.Machine  --ER0383
						and tec.gtime=mingtime)T2
						inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
						and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
						#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.mingtime=T2.mingtime

						update #temp set maxEnergykwh = isnull(maxEnergykwh,0) + isnull(kwh,0) 
						from
						(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,maxgtime,
						round(kwh,5) as kwh from #temp
						left outer join tcs_energyconsumption tec WITH(NOLOCK) on tec.Machineid = #temp.Machine  --ER0383
						and tec.gtime=maxgtime)T2
						inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
						and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
						#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.maxgtime=T2.maxgtime


						update #temp set Energy_Kwh = isnull(Energy_Kwh,0) + isnull(kwh,0) 
						from
						(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,
						round(isnull((maxEnergykwh - minEnergykwh),0),5) as kwh from #temp)T2
						inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
						and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
						#temp.starttime=T2.starttime and #temp.endtime=T2.endtime


						 insert into #CODetails(Machine,Componentid,OperationNo,Operator,TotCompCount)
						 Select distinct Machine,Componentid,OperationNo,Operator,count(Machine) from #temp 
						  group by Machine,Componentid,OperationNo,Operator

						update #CODetails set CycAbvThreshold = T1.CycAbvThreshold from 
						(select Machine,Componentid,OperationNo,Operator,isnull(Count(case when Energy_Kwh>=LThreshold then Machine END),0) as CycAbvThreshold
						 from #temp where Energy_Kwh>=LThreshold
						 group by Machine,Componentid,OperationNo,Operator) T1
						inner join #CODetails C on T1.machine=C.machine and T1.Componentid=C.Componentid and T1.OperationNo=C.OperationNo
						and T1.Operator=C.Operator

						update #CODetails set CycBelowThreshold = T1.CycBelowThreshold from 
						(select Machine,Componentid,OperationNo,Operator,isnull(Count(case when Energy_Kwh<LThreshold then Machine END),0) as CycBelowThreshold
						 from #temp group by Machine,Componentid,OperationNo,Operator) T1
						inner join #CODetails C on T1.machine=C.machine and T1.Componentid=C.Componentid and T1.OperationNo=C.OperationNo
						and T1.Operator=C.Operator
		                 
					   Update #CODetails set MaxEnergy = T1.MaxEnergy,MinEnergy=T1.MinEnergy,AvgEnergy=T1.AvgEnergy from 
					   (select Machine,Componentid,OperationNo,Operator,isnull(round(Min(Energy_Kwh),5),0) as MinEnergy,
						isnull(round(Max(Energy_Kwh),5),0) as MaxEnergy,isnull(round(Avg(Energy_Kwh),5),0) as AvgEnergy from #temp
						where Energy_Kwh>=LThreshold group by Machine,Componentid,OperationNo,Operator)T1
						inner join #CODetails C on T1.machine=C.machine and T1.Componentid=C.Componentid and T1.OperationNo=C.OperationNo
						and T1.Operator=C.Operator

						select * from #CODetails
					

			End

			--if @Parameter = 'Grid_GraphData'--ER00212-KarthickR-29-Dec-2009
			if @Parameter = 'Grid_GraphData_CycleLevel'
			Begin
				
		
				--Geeta added from here
						insert into #temp (Machine,Componentid,OperationNo,Operator,starttime,Endtime,
						mingtime,maxgtime,Energy_Kwh,minEnergykwh,maxEnergykwh,PF
						,LThreshold,UThreshold,Cuttingdetail,TotalCuttingTime)
						Select mi.Machineid,ci.ComponentID as ComponentID,cop.OperationNo as OperationNo,
						e.Employeeid as Operator,sttime as StartTime,ndtime as EndTime,min(gtime),max(gtime),
						--Round(isnull(max(kwh),0)-Isnull(min(kwh),0),2) as Energy_Kwh, DR0304 commented here
						--Round(isnull(max(kwh),0)-Isnull(min(kwh),0),5) as Energy_Kwh,--DR0304 added here
						0,0,0,Isnull(Round(Avg(abs(pf)),2),0) as PF,
						lowerenergythreshold as LThreshold,upperenergythreshold as UThreshold,0,0
						from #T_autodata A --ER0383
						inner join Machineinformation mi on A.mc = mi.interfaceid
						inner join componentinformation ci on A.comp = ci.interfaceid
						inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
						inner join employeeinformation e on A.opr = e.interfaceid
						left outer join tcs_energyconsumption tec WITH(NOLOCK) on tec.Machineid = mi.MachineID and tec.gtime >= A.sttime and tec.gtime <= A.ndtime--ER0383
						where datatype = 1 and --sttime >= @StartTime and ndtime <= @EndTime 	
						ndtime>@StartTime and ndtime<=@EndTime
						and mi.Machineid = @MachineID
						group by mi.Machineid,ci.ComponentID,cop.OperationNo,e.Employeeid,sttime,ndtime,lowerenergythreshold,upperenergythreshold
						order by sttime

	

						update #temp set minEnergykwh = isnull(minEnergykwh,0) + isnull(kwh,0) 
						from
						(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,mingtime,
						round(kwh,5) as kwh from #temp
						left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
						and tec.gtime=mingtime)T2
						inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
						and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
						#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.mingtime=T2.mingtime

						update #temp set maxEnergykwh = isnull(maxEnergykwh,0) + isnull(kwh,0) 
						from
						(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,maxgtime,
						round(kwh,5) as kwh from #temp
						left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
						and tec.gtime=maxgtime)T2
						inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
						and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
						#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.maxgtime=T2.maxgtime
						

						update #temp set Energy_Kwh = isnull(Energy_Kwh,0) + isnull(kwh,0) 
						from
						(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,
						round(isnull((maxEnergykwh - minEnergykwh),0),5) as kwh from #temp)T2
						inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
						and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
						#temp.starttime=T2.starttime and #temp.endtime=T2.endtime

	
						insert into #Energydata(Machineid,Col1_gtime,Col2_gtime,Col1_Amp,Col2_Amp,st,nd)
						select @machineid,s1.gtime,
						case when s1.gtime1>#temp.Endtime then #temp.Endtime else s1.gtime1 end,
						s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime 
						from (select machineid,gtime,ampere,gtime1,ampere1 from tcs_energyconsumption WITH(NOLOCK) --ER0383
						where gtime>=@starttime and gtime<=@endtime and machineid=@machineid
						and isnull(gtime1,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000') s1, #temp
						where  S1.gtime>=#temp.starttime and S1.gtime<=#temp.Endtime and S1.machineid=@machineid
						and #temp.Machine=@machineid
						group by S1.machineid,s1.gtime,s1.gtime1,s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime

						update #Energydata set COl1_COl2=datediff(s,Col1_gtime,Col2_gtime)
		                 

						Update #temp set Cuttingdetail=T.CT from(Select sum(COl1_COl2) as Ct,#temp.starttime as st,#temp.Endtime as nd  from #Energydata,#temp 
						inner join Machineinformation M on M.machineid=#temp.machine where Col1_Amp>= M.LowerPowerthreshold and
						#temp.starttime=#Energydata.st and #Energydata.nd=#temp.Endtime group by #temp.starttime,#temp.Endtime)T  where T.st=#temp.starttime  and T.nd=#temp.Endtime

						update #temp  set TotalCuttingTime = isnull(TotalCuttingTime,0) + isnull(T1.TotalCutting,0)
						from
						(select Machine,Sum(Cuttingdetail) as TotalCutting from #temp group by Machine)T1
						inner join  #temp on #temp.Machine=T1.Machine


						Select Machine,Componentid,OperationNo,Operator,starttime,Endtime,Energy_Kwh,PF
						,LThreshold,UThreshold,Cuttingdetail,TotalCuttingTime,dbo.f_FormatTime(Cuttingdetail,'hh:mm:ss') as strCuttingdetail,
						dbo.f_FormatTime(TotalCuttingTime,'hh:mm:ss') as strTotalCuttingTime from #temp 
						--Geeta added till here
			End


			--ER00212-KarthickR-29-Dec-2009--From Here
			if @Parameter = 'Grid_GraphData_Mintue'
			Begin

					Set @st=@StartTime


					 while @st<@EndTime
						Begin
							insert into #minlevel(MachineID,StartTime,EndTime,Energy_Kwh,Pf,Minenergykwh,Maxenergykwh)
							values(@MachineID,@st,dateadd(mi,@No_Of_Minute,@st),0,0,0,0)
							set @st=dateadd(mi,@No_Of_Minute,@st)	
						End
				

						update #minlevel set pf=isnull(t1.pf,0),mingtime=T1.mingtime,maxgtime=T1.maxgtime from 
						(
						Select mi.Machineid,#minlevel.StartTime,#minlevel.EndTime,
						Isnull(Round(Avg(Abs(tec.pf)),2),0) as PF,min(gtime) as mingtime,max(gtime) as maxgtime
						from  Machineinformation mi
						inner join tcs_energyconsumption tec WITH(NOLOCK) on tec.Machineid = mi.MachineID --ER0383
						inner join #minlevel on #minlevel.machineid=mi.machineid
						where gtime >= #minlevel.StartTime and gtime <=#minlevel.EndTime	
						and mi.Machineid = @MachineID
						group by mi.Machineid,#minlevel.StartTime,#minlevel.EndTime
						) t1 inner join #minlevel on  #minlevel.StartTime=T1.StartTime  and T1.EndTime=#minlevel.EndTime

						update #minlevel set Minenergykwh=isnull(Minenergykwh,0) + isnull(T2.kwh,0) from 
						(
						select #minlevel.machineid,starttime,endtime,ROUND(kwh,5) as kwh,mingtime
						from #minlevel
						inner join tcs_energyconsumption tec WITH(NOLOCK) on tec.Machineid = #minlevel.machineid --ER0383
						and tec.gtime=#minlevel.mingtime
						)T2 inner join #minlevel on  #minlevel.StartTime=T2.StartTime  and T2.EndTime=#minlevel.EndTime
						and  #minlevel.mingtime=T2.mingtime

						update #minlevel set Maxenergykwh=isnull(Maxenergykwh,0) + isnull(T2.kwh,0) from 
						(
						select #minlevel.machineid,starttime,endtime,ROUND(kwh,5) as kwh,maxgtime
						from #minlevel
						inner join tcs_energyconsumption tec WITH(NOLOCK) on tec.Machineid = #minlevel.machineid --ER0383
						and tec.gtime=#minlevel.maxgtime
						)T2 inner join #minlevel on  #minlevel.StartTime=T2.StartTime  and T2.EndTime=#minlevel.EndTime
						and  #minlevel.maxgtime=T2.maxgtime

						update #minlevel set Energy_Kwh = isnull(Energy_Kwh,0) + isnull(T2.kwh,0)
						from
						(select machineid,starttime,endtime,
						 round((Maxenergykwh-Minenergykwh),5) as kwh from #minlevel
						)T2 inner join #minlevel on  #minlevel.StartTime=T2.StartTime  and T2.EndTime=#minlevel.EndTime
						
						select * from #minlevel order by MachineID,StartTime,EndTime
			End
			--ER00212-KarthickR-29-Dec-2009--Till Here
		End	
end
Else
Begin

			
			--mod 1
			if @HistoryLive = 'Live'
			Begin
				if @Parameter = 'Machinelevelstatistics'
				Begin

					Insert into #FinalData
					select top 1 MachineID,InterfaceID,@StartTime,@EndTime,0,0,0,0,0,0,0,0,0 from machineinformation where machineid = @MachineID	



							insert into #temp (Machine,Componentid,OperationNo,Operator,starttime,Endtime,
							mingtime,maxgtime,Energy_Kwh,minEnergykwh,maxEnergykwh,PF
							,LThreshold,UThreshold,Cuttingdetail,TotalCuttingTime)
							Select mi.Machineid,ci.ComponentID as ComponentID,cop.OperationNo as OperationNo,
							e.Employeeid as Operator,sttime as StartTime,ndtime as EndTime,min(gtime),max(gtime),
							0,0,0,Isnull(Round(Avg(abs(pf)),2),0) as PF,
							lowerenergythreshold as LThreshold,upperenergythreshold as UThreshold,0,0
							from autodata A
							inner join Machineinformation mi on A.mc = mi.interfaceid
							inner join componentinformation ci on A.comp = ci.interfaceid
							inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
							inner join employeeinformation e on A.opr = e.interfaceid
							left outer join tcs_energyconsumption tec on tec.Machineid = mi.MachineID and tec.gtime >= A.sttime and tec.gtime <= A.ndtime
							where datatype = 1 and --sttime >= @StartTime and ndtime <= @EndTime 	
							ndtime>@StartTime and ndtime<=@EndTime
							and mi.Machineid = @MachineID
							group by mi.Machineid,ci.ComponentID,cop.OperationNo,e.Employeeid,sttime,ndtime,lowerenergythreshold,upperenergythreshold
							order by sttime

							update #temp set minEnergykwh = isnull(minEnergykwh,0) + isnull(kwh,0) 
							from
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,mingtime,
							round(kwh,5) as kwh from #temp
							left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
							and tec.gtime=mingtime)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.mingtime=T2.mingtime

							update #temp set maxEnergykwh = isnull(maxEnergykwh,0) + isnull(kwh,0) 
							from
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,maxgtime,
							round(kwh,5) as kwh from #temp
							left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
							and tec.gtime=maxgtime)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.maxgtime=T2.maxgtime
							

							update #temp set Energy_Kwh = isnull(Energy_Kwh,0) + isnull(kwh,0) 
							from
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,
							round(isnull((maxEnergykwh - minEnergykwh),0),5) as kwh from #temp)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime



							Update #FinalData set EnergyEfficiency = t2.EnergyEff from (
							select Machine,isnull(round(sum((case when t1.Energy>=t1.lowerenergythreshold then 1 END)* t1.upperenergythreshold)/isnull(sum(case when t1.Energy>=t1.lowerenergythreshold then t1.Energy END),1)* 100,2),0)  as EnergyEff
							 from (select Machine,Componentid,OperationNo,starttime,Endtime,
									Energy_kwh as energy,LThreshold as lowerenergythreshold,UThreshold as upperenergythreshold from #temp
								  ) as t1 group by Machine
								  ) as t2

			/*******

					Update #FinalData set EnergyEfficiency = t2.EnergyEff from (
						select mc,isnull(round(sum((case when t1.Energy>=t1.lowerenergythreshold then 1 END)* t1.upperenergythreshold)/isnull(sum(case when t1.Energy>=t1.lowerenergythreshold then t1.Energy END),1)* 100,2),0)  as EnergyEff
						 from (select mc,comp,opn,sttime,ndtime,
						---Round(isnull(max(kwh),0)-Isnull(min(kwh),0),2) as Energy, --DR0304 Commented
						Round(isnull(max(kwh),0)-Isnull(min(kwh),0),5) as Energy, --DR0304 Added
						lowerenergythreshold,upperenergythreshold from autodata A
						inner join Machineinformation mi on A.mc = mi.interfaceid
						inner join componentinformation ci on A.comp = ci.interfaceid
						inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
						inner join employeeinformation e on A.opr = e.interfaceid
						inner join tcs_energyconsumption tec on tec.gtime >= A.sttime and tec.gtime <= A.ndtime and tec.Machineid = mi.Machineid
						where mi.Machineid = @MachineID and A.datatype = 1 and sttime >= @StartTime and ndtime <= @EndTime
						group by mc,comp,opn,sttime,ndtime,lowerenergythreshold,upperenergythreshold
						) as t1 group by mc
					) as t2
			**********/
							/* Swathi Commented From Here


								Update #FinalData set EnergyEfficiency = t2.EnergyEff from (
									select mc,isnull(round(sum((case when t1.Energy>=t1.lowerenergythreshold then 1 END)* t1.upperenergythreshold)/isnull(sum(case when t1.Energy>=t1.lowerenergythreshold then t1.Energy END),1)* 100,2),0)  as EnergyEff
									 from (select mc,comp,opn,sttime,ndtime,
									---Round(isnull(max(kwh),0)-Isnull(min(kwh),0),2) as Energy, --DR0304 Commented
									Round(isnull(max(kwh),0)-Isnull(min(kwh),0),5) as Energy, --DR0304 Added
									lowerenergythreshold,upperenergythreshold from autodata A
									inner join Machineinformation mi on A.mc = mi.interfaceid
									inner join componentinformation ci on A.comp = ci.interfaceid
									inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
									inner join employeeinformation e on A.opr = e.interfaceid
									inner join tcs_energyconsumption tec on tec.gtime >= A.sttime and tec.gtime <= A.ndtime and tec.Machineid = mi.Machineid
									where mi.Machineid = @MachineID and A.datatype = 1 and sttime >= @StartTime and ndtime <= @EndTime
									group by mc,comp,opn,sttime,ndtime,lowerenergythreshold,upperenergythreshold
									) as t1 group by mc
								) as t2
						


									Update #FinalData set Energy_Kwh = t2.Energy_Kwh, Cycles = t2.Cycles, Cost = Isnull(t2.Cost,0) from (
										select sum(t1.kwh) as Energy_Kwh,count(t1.kwh) as Cycles,
										Round(sum(t1.kwh)*(Select top 1 valueintext from shopdefaults where parameter = 'CostPerKWH'),2) as Cost
										 from (
											select sttime,ndtime,
											--Round(isnull(max(kwh),0)-Isnull(min(kwh),0),2) as kwh from autodata A --DR0304 Commented
											Round(isnull(max(kwh),0)-Isnull(min(kwh),0),5) as kwh from autodata A --DR0304 Added
											inner join Machineinformation mi on A.mc = mi.interfaceid
											inner join componentinformation ci on A.comp = ci.interfaceid
											inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
											inner join employeeinformation e on A.opr = e.interfaceid
											inner join tcs_energyconsumption on tcs_energyconsumption.gtime >= A.sttime and tcs_energyconsumption.gtime <= A.ndtime and tcs_energyconsumption.Machineid = mi.MachineID
											where mi.Machineid = @MachineID
											And sttime >= @StartTime AND ndtime<= @EndTime And datatype = 1 Group by sttime,ndtime
										) as t1
									) as t2

							Update #FinalData set
							#FinalData.Energy_Kwh = ISNULL(#FinalData.Energy_Kwh,0)+ISNULL(t1.kwh,0),
							#FinalData.Cost = ISNULL(#FinalData.Cost,0)+ISNULL(t1.kwh * (Select max(Valueintext) from shopdefaults where Parameter = 'CostPerKWH'),0)
							from (
								select tcs_energyconsumption.MachineiD,StartTime,EndTime,
								avg(Abs(tcs_energyconsumption.pf)) as PF,
								max(kwh)-min(kwh) as kwh from tcs_energyconsumption inner join #FinalData on
								tcs_energyconsumption.machineID = #FinalData.MachineID and tcs_energyconsumption.gtime >= #FinalData.StartTime
								and tcs_energyconsumption.gtime <= #FinalData.EndTime --And tcs_energyconsumption.pf >= 0
								group by tcs_energyconsumption.MachineiD,StartTime,EndTime
							) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID and
							t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime
							*/

					
					Update #FinalData set Minenergykwh = t2.minkwh from 
					(
						 Select T1.machineid,round(kwh,2) as minkwh from 
							(select mi.machineid,min(gtime) as mingtime 
							 from autodata A
							inner join Machineinformation mi on A.mc = mi.interfaceid
							inner join tcs_energyconsumption tec on tec.gtime >= A.sttime and tec.gtime <= A.ndtime and tec.Machineid = mi.Machineid
							where mi.Machineid = @MachineID and A.datatype = 1 and sttime >= @StartTime and ndtime <= @EndTime
							group by mi.machineid
							) as t1 inner join tcs_energyconsumption on tcs_energyconsumption.machineid=t1.machineid and tcs_energyconsumption.gtime=T1.mingtime 
					) as t2 inner join #FinalData on t2.machineiD = #FinalData.machineID 


					Update #FinalData set Maxenergykwh = t2.maxkwh from 
					(
					   select T1.machineid,round(kwh,2) as maxkwh from 
						(select mi.machineid,max(gtime) as maxgtime 
						 from autodata A
						inner join Machineinformation mi on A.mc = mi.interfaceid
						inner join tcs_energyconsumption tec on tec.gtime >= A.sttime and tec.gtime <= A.ndtime and tec.Machineid = mi.Machineid
						where mi.Machineid = @MachineID and A.datatype = 1 and sttime >= @StartTime and ndtime <= @EndTime
						group by mi.machineid
						) as t1 inner join tcs_energyconsumption on tcs_energyconsumption.machineid=t1.machineid and tcs_energyconsumption.gtime=T1.maxgtime 
					) as t2 inner join #FinalData on t2.machineiD = #FinalData.machineID 


					Update #FinalData
					set #FinalData.Energy_kwh = ISNULL(#FinalData.Energy_kwh,0)+ISNULL(t1.kwh,0), 
					#FinalData.Cost = ISNULL(#FinalData.Cost,0)+ISNULL(t1.kwh * (Select max(Valueintext) from shopdefaults where Parameter = 'CostPerKWH'),0)
					from 
					(
						select MachineiD,StartTime,EndTime,round((Maxenergykwh - Minenergykwh),2) as kwh from #FinalData 
					) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID and
					t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime


					--select * from #FinalData
					--return
					-- Type 1
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(
						select mc,#FinalData.StartTime,#FinalData.EndTime,sum(cycletime+loadunload) as cycle
						from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface
						where (autodata.msttime>=#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime)and (autodata.datatype=1)
						group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					-- Type 2
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(
						select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, #FinalData.StartTime, ndtime)) as cycle
						from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface
						where (autodata.msttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime) and (autodata.datatype=1)
						group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					-- Type 3
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(
						select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, mstTime, #FinalData.EndTime)) as cycle
						from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface
						where (autodata.msttime>=#FinalData.StartTime) and (autodata.msttime<#FinalData.EndTime) and (autodata.ndtime>#FinalData.EndTime) and (autodata.datatype=1)
						group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					-- Type 4
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(
						select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, #FinalData.StartTime, #FinalData.EndTime)) as cycle
						from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface
						where (autodata.msttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.EndTime) and (autodata.datatype=1)
						group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					----/* Fetching Down Records from Production Cycle  */
					----/* If Down Records of TYPE-2 */
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(
						select A1.mc,#FinalData.StartTime,#FinalData.EndTime,
						case
							When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)
							When A2.sttime < #FinalData.StartTime And A2.ndtime > #FinalData.StartTime AND A2.ndtime<=#FinalData.EndTime Then datediff(s, #FinalData.StartTime,A2.ndtime )
						end as Down
						from autodata A1 cross join autodata A2 cross join #FinalData
						where A1.datatype = 1 and A2.datatype = 2
						and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc
						and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime
						and A1.sttime < #FinalData.StartTime
						and A1.ndtime > #FinalData.StartTime
						and A1.ndtime <= #FinalData.EndTime
						and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					----/* If Down Records of TYPE-3 */
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(
						select A1.mc,#FinalData.StartTime,#FinalData.EndTime,
						case
							When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)
							When A2.sttime>=#FinalData.StartTime And A2.sttime < #FinalData.EndTime and A2.ndtime > #FinalData.EndTime Then datediff(s,A2.sttime, #FinalData.EndTime )
						end as Down
						from autodata A1 cross join autodata A2 cross join #FinalData
						where A1.datatype = 1 and A2.datatype = 2
						and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc
						and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime
						and A1.sttime >= #FinalData.StartTime
						and A1.sttime < #FinalData.EndTime
						and A1.ndtime > #FinalData.EndTime
						and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					----/* If Down Records of TYPE-4 */
					UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(
						select A1.mc,#FinalData.StartTime,#FinalData.EndTime,
						case
							When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)
							When A2.sttime < #FinalData.StartTime And A2.ndtime > #FinalData.StartTime AND A2.ndtime<=#FinalData.EndTime Then datediff(s, #FinalData.StartTime,A2.ndtime )
							When A2.sttime>=#FinalData.StartTime And A2.sttime < #FinalData.EndTime and A2.ndtime > #FinalData.EndTime Then datediff(s,A2.sttime, #FinalData.EndTime )
							When A2.sttime<#FinalData.StartTime AND A2.ndtime>#FinalData.EndTime   Then datediff(s, #FinalData.StartTime,#FinalData.EndTime)
						end as Down
						from autodata A1 cross join autodata A2 cross join #FinalData
						where A1.datatype = 1 and A2.datatype = 2
						and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc
						and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime
						and A1.sttime < #FinalData.StartTime
						and A1.ndtime > #FinalData.EndTime
						and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime
					) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

					UPDATE #FinalData SET Cycles = ISNULL(Cycles,0) + ISNULL(t2.comp,0)
					From(
					select Autodata.mc,#FinalData.StartTime,#FinalData.EndTime,
					SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp
					from autodata
					inner join #FinalData on autodata.mc = #FinalData.machineinterface
					Inner join componentinformation C on autodata.Comp = C.interfaceid
					Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid
					inner join machineinformation on machineinformation.machineid =O.machineid and autodata.mc=machineinformation.interfaceid
					Where Autodata.datatype = 1
					and Autodata.ndtime > #FinalData.StartTime and Autodata.ndtime <= #FinalData.EndTime
					Group by Autodata.mc,#FinalData.StartTime,#FinalData.EndTime
					) As T2 Inner join #FinalData on T2.mc = #FinalData.machineinterface and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime

					select MachineID,StartTime,EndTime,
					dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as UtilisedTime,
					--round(Energy_Kwh,2) as Energy_Kwh, DR0304 commented here
					round(Energy_Kwh,2) as Energy_Kwh,-- DR0304 added here
					Cycles,round(Cost,2) as Cost,EnergyEfficiency,Minenergykwh,Maxenergykwh from #FinalData
				End
				
				if @Parameter = 'COLevelstatistics'
				Begin

					/*
							select
							isnull(Count(case when t1.Energy>=t1.LThreshold then t1.mc END),0) as CycAbvThreshold,
							isnull(Count(case when t1.Energy<t1.LThreshold then t1.mc END),0) as CycBelowThreshold,
							isnull(count(t1.mc),0) as TotCompCount,
							isnull(max(case when t1.energy>=t1.LThreshold then t1.energy END ),0) as MaxEnergy,
							isnull(min(case when t1.energy>=t1.LThreshold then t1.energy END),0) as MinEnergy,
							isnull(round(AVG(case when t1.energy>=t1.LThreshold then t1.energy END),2),0) as AvgEnergy from
							(
								select mc,comp,opn,sttime,ndtime,
								--Round(isnull(max(kwh),0)-Isnull(min(kwh),0),2) as Energy, --DR0304 commented here
								Round(isnull(max(kwh),0)-Isnull(min(kwh),0),5) as Energy, --DR0304 Added here
								lowerenergythreshold as LThreshold from autodata A
								inner join Machineinformation mi on A.mc = mi.interfaceid
								inner join componentinformation ci on A.comp = ci.interfaceid
								inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
								left outer join employeeinformation e on A.opr = e.interfaceid
								inner join tcs_energyconsumption tec on  tec.Machineid = mi.Machineid
								where mi.Machineid = @MachineID and ci.componentid = @ComponentID
								and cop.OperationNo = @OperationNo and A.datatype = 1 and tec.gtime >= A.sttime and tec.gtime <= A.ndtime and sttime >= @StartTime and ndtime <= @EndTime
								group by mc,comp,opn,sttime,ndtime,lowerenergythreshold
							)as t1 group by mc,comp,opn--,sttime,ndtime

					*/

							insert into #temp (Machine,Componentid,OperationNo,Operator,starttime,Endtime,
							Mingtime,Maxgtime,Energy_Kwh,Minenergykwh,Maxenergykwh,PF
							,LThreshold,UThreshold,Cuttingdetail)
							Select mi.Machineid,ci.ComponentID as ComponentID,cop.OperationNo as OperationNo,
							e.Employeeid as Operator,sttime as StartTime,ndtime as EndTime,
							--Round(isnull(max(kwh),0)-Isnull(min(kwh),0),2) as Energy_Kwh, DR0304 commented here
							--Round(isnull(max(kwh),0)-Isnull(min(kwh),0),5) as Energy_Kwh,--DR0304 added here
							min(gtime),max(gtime),
							0,0,0,Isnull(Round(Avg(case when pf>=0 then pf end),2),0) as PF,
							lowerenergythreshold as LThreshold,upperenergythreshold as UThreshold,0
							from autodata A
							inner join Machineinformation mi on A.mc = mi.interfaceid
							inner join componentinformation ci on A.comp = ci.interfaceid
							inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
							inner join employeeinformation e on A.opr = e.interfaceid
							left outer join tcs_energyconsumption tec on tec.Machineid = mi.MachineID and tec.gtime >= A.sttime and tec.gtime <= A.ndtime
							where datatype = 1 and --sttime >= @StartTime and ndtime <= @EndTime 	
							ndtime>@starttime and ndtime<=@endtime
							and mi.Machineid = @MachineID
							group by mi.Machineid,ci.ComponentID,cop.OperationNo,e.Employeeid,sttime,ndtime,lowerenergythreshold,upperenergythreshold
							order by sttime

							/*
							update #temp set minEnergykwh = isnull(minEnergykwh,0) + isnull(kwh,0) 
							from
							(select t1.Machine,t1.ComponentID,t1.OperationNo,t1.Operator,t1.StartTime,t1.EndTime,
							 round(kwh,5) as kwh from 
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,
							min(gtime) as mingtime from #temp
							left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
							and tec.gtime >= StartTime and tec.gtime <= EndTime
							group by Machine,ComponentID,OperationNo,Operator,StartTime,EndTime)T1
							inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T1.mingtime)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime

				
							update #temp set maxEnergykwh = isnull(maxEnergykwh,0) + isnull(kwh,0) 
							from
							(select t1.Machine,t1.ComponentID,t1.OperationNo,t1.Operator,t1.StartTime,t1.EndTime,
							 round(kwh,5) as kwh from 
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,
							max(gtime) as maxgtime from #temp
							left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
							and tec.gtime >= StartTime and tec.gtime <= EndTime
							group by Machine,ComponentID,OperationNo,Operator,StartTime,EndTime)T1
							inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T1.maxgtime)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime
							*/


							update #temp set minEnergykwh = isnull(minEnergykwh,0) + isnull(kwh,0) 
							from
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,mingtime,
							round(kwh,5) as kwh from #temp
							left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
							and tec.gtime=mingtime)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.mingtime=T2.mingtime

							update #temp set maxEnergykwh = isnull(maxEnergykwh,0) + isnull(kwh,0) 
							from
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,maxgtime,
							round(kwh,5) as kwh from #temp
							left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
							and tec.gtime=maxgtime)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.maxgtime=T2.maxgtime


							update #temp set Energy_Kwh = isnull(Energy_Kwh,0) + isnull(kwh,0) 
							from
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,
							round(isnull((maxEnergykwh - minEnergykwh),0),5) as kwh from #temp)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime


							 insert into #CODetails(Machine,Componentid,OperationNo,Operator,TotCompCount)
							 Select distinct Machine,Componentid,OperationNo,Operator,count(Machine) from #temp 
							  group by Machine,Componentid,OperationNo,Operator

							update #CODetails set CycAbvThreshold = T1.CycAbvThreshold from 
							(select Machine,Componentid,OperationNo,Operator,isnull(Count(case when Energy_Kwh>=LThreshold then Machine END),0) as CycAbvThreshold
							 from #temp where Energy_Kwh>=LThreshold
							 group by Machine,Componentid,OperationNo,Operator) T1
							inner join #CODetails C on T1.machine=C.machine and T1.Componentid=C.Componentid and T1.OperationNo=C.OperationNo
							and T1.Operator=C.Operator

							update #CODetails set CycBelowThreshold = T1.CycBelowThreshold from 
							(select Machine,Componentid,OperationNo,Operator,isnull(Count(case when Energy_Kwh<LThreshold then Machine END),0) as CycBelowThreshold
							 from #temp group by Machine,Componentid,OperationNo,Operator) T1
							inner join #CODetails C on T1.machine=C.machine and T1.Componentid=C.Componentid and T1.OperationNo=C.OperationNo
							and T1.Operator=C.Operator
			                 
						   Update #CODetails set MaxEnergy = T1.MaxEnergy,MinEnergy=T1.MinEnergy,AvgEnergy=T1.AvgEnergy from 
						   (select Machine,Componentid,OperationNo,Operator,isnull(round(Min(Energy_Kwh),5),0) as MinEnergy,
							isnull(round(Max(Energy_Kwh),5),0) as MaxEnergy,isnull(round(Avg(Energy_Kwh),5),0) as AvgEnergy from #temp
							where Energy_Kwh>=LThreshold group by Machine,Componentid,OperationNo,Operator)T1
							inner join #CODetails C on T1.machine=C.machine and T1.Componentid=C.Componentid and T1.OperationNo=C.OperationNo
							and T1.Operator=C.Operator

							select * from #CODetails
						

				End





				--if @Parameter = 'Grid_GraphData'--ER00212-KarthickR-29-Dec-2009
				if @Parameter = 'Grid_GraphData_CycleLevel'
				Begin
					
						--Geeta Commented from here
						--		Select mi.Machineid,ci.ComponentID as ComponentID,cop.OperationNo as OperationNo,
						--		e.Employeeid as Operator,sttime as StartTime,ndtime as EndTime,
						--		Round(isnull(max(kwh),0)-Isnull(min(kwh),0),2) as Energy_Kwh, DR0304 commented here
						--		Round(isnull(max(kwh),0)-Isnull(min(kwh),0),5) as Energy_Kwh,--DR0304 added here
						--		Isnull(Round(Avg(case when pf>=0 then pf end),2),0) as PF,
						--		lowerenergythreshold as LThreshold,upperenergythreshold as UThreshold
						--		from autodata A
						--		inner join Machineinformation mi on A.mc = mi.interfaceid
						--		inner join componentinformation ci on A.comp = ci.interfaceid
						--		inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
						--		inner join employeeinformation e on A.opr = e.interfaceid
						--		inner join tcs_energyconsumption tec on tec.Machineid = mi.MachineID and tec.gtime >= A.sttime and tec.gtime <= A.ndtime
						--		where datatype = 1 and sttime >= @StartTime and ndtime <= @EndTime 	
						--		and mi.Machineid = @MachineID
						--		group by mi.Machineid,ci.ComponentID,cop.OperationNo,e.Employeeid,sttime,ndtime,lowerenergythreshold,upperenergythreshold
						--		order by sttime
						--Geeta Commented till here


					--Geeta added from here
							insert into #temp (Machine,Componentid,OperationNo,Operator,starttime,Endtime,
							mingtime,maxgtime,Energy_Kwh,minEnergykwh,maxEnergykwh,PF
							,LThreshold,UThreshold,Cuttingdetail,TotalCuttingTime)
							Select mi.Machineid,ci.ComponentID as ComponentID,cop.OperationNo as OperationNo,
							e.Employeeid as Operator,sttime as StartTime,ndtime as EndTime,min(gtime),max(gtime),
							--Round(isnull(max(kwh),0)-Isnull(min(kwh),0),2) as Energy_Kwh, DR0304 commented here
							--Round(isnull(max(kwh),0)-Isnull(min(kwh),0),5) as Energy_Kwh,--DR0304 added here
							0,0,0,Isnull(Round(Avg(abs(pf)),2),0) as PF,
							lowerenergythreshold as LThreshold,upperenergythreshold as UThreshold,0,0
							from autodata A
							inner join Machineinformation mi on A.mc = mi.interfaceid
							inner join componentinformation ci on A.comp = ci.interfaceid
							inner join componentoperationpricing cop on A.opn = cop.interfaceid and cop.machineid = mi.MachineID and cop.componentid = ci.componentid
							inner join employeeinformation e on A.opr = e.interfaceid
							left outer join tcs_energyconsumption tec on tec.Machineid = mi.MachineID and tec.gtime >= A.sttime and tec.gtime <= A.ndtime
							where datatype = 1 and --sttime >= @StartTime and ndtime <= @EndTime 	
							ndtime>@StartTime and ndtime<=@EndTime
							and mi.Machineid = @MachineID
							group by mi.Machineid,ci.ComponentID,cop.OperationNo,e.Employeeid,sttime,ndtime,lowerenergythreshold,upperenergythreshold
							order by sttime

							/*
							update #temp set minEnergykwh = isnull(minEnergykwh,0) + isnull(kwh,0) 
							from
							(select t1.Machine,t1.ComponentID,t1.OperationNo,t1.Operator,t1.StartTime,t1.EndTime,
							round(kwh,5) as kwh from 
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,
							min(gtime) as mingtime from #temp
							left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
							and tec.gtime >= StartTime and tec.gtime <= EndTime
							group by Machine,ComponentID,OperationNo,Operator,StartTime,EndTime)T1
							inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T1.mingtime)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime


							update #temp set maxEnergykwh = isnull(maxEnergykwh,0) + isnull(kwh,0) 
							from
							(select t1.Machine,t1.ComponentID,t1.OperationNo,t1.Operator,t1.StartTime,t1.EndTime,
							 round(kwh,5) as kwh from 
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,
							max(gtime) as maxgtime from #temp
							left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
							and tec.gtime >= StartTime and tec.gtime <= EndTime
							group by Machine,ComponentID,OperationNo,Operator,StartTime,EndTime)T1
							inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T1.maxgtime)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime
							*/

							update #temp set minEnergykwh = isnull(minEnergykwh,0) + isnull(kwh,0) 
							from
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,mingtime,
							round(kwh,5) as kwh from #temp
							left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
							and tec.gtime=mingtime)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.mingtime=T2.mingtime

							update #temp set maxEnergykwh = isnull(maxEnergykwh,0) + isnull(kwh,0) 
							from
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,maxgtime,
							round(kwh,5) as kwh from #temp
							left outer join tcs_energyconsumption tec on tec.Machineid = #temp.Machine 
							and tec.gtime=maxgtime)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime and #temp.maxgtime=T2.maxgtime
							

							update #temp set Energy_Kwh = isnull(Energy_Kwh,0) + isnull(kwh,0) 
							from
							(Select Machine,ComponentID,OperationNo,Operator,StartTime,EndTime,
							round(isnull((maxEnergykwh - minEnergykwh),0),5) as kwh from #temp)T2
							inner join #temp on T2.machine=#temp.machine and T2.componentid=#temp.componentid
							and #temp.operationno=T2.operationno and #temp.operator=T2.operator and
							#temp.starttime=T2.starttime and #temp.endtime=T2.endtime

							/*
							insert into #Energydata(Machineid,Col1_ID,Col2_ID,st,nd)
							select @machineid ,s1.idd,min(s2.idd),#temp.starttime,#temp.Endtime from tcs_energyconsumption s1,tcs_energyconsumption s2
							, #temp
							where s1.idd<s2.idd and S1.gtime>#temp.starttime and S1.gtime<#temp.Endtime and S1.machineid=@machineid
							and S2.gtime>#temp.starttime and S2.gtime<#temp.Endtime and S2.machineid=@machineid and #temp.Machine=@machineid
							group by S2.machineid,s1.idd,#temp.starttime,#temp.Endtime
							
							
							update #Energydata set Col1_gtime=t1.gtime,Col1_Amp=t1.ampere from #Energydata E inner join tcs_energyconsumption t1 on t1.idd=E.Col1_ID
							update #Energydata set Col2_gtime=t1.gtime,Col2_Amp=t1.Ampere from #Energydata E inner join tcs_energyconsumption t1 on t1.idd=E.Col2_ID
							update #Energydata set COl1_COl2=datediff(s,Col1_gtime,Col2_gtime)
						


							insert into #Energydata(Machineid,Col1_gtime,Col2_gtime,Col1_Amp,Col2_Amp,st,nd)
							select @machineid,s1.gtime,s1.gtime1,s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime 
							from tcs_energyconsumption s1, #temp
							where  S1.gtime>=#temp.starttime and S1.gtime<=#temp.Endtime and S1.machineid=@machineid
							and #temp.Machine=@machineid
							group by S1.machineid,s1.gtime,s1.gtime1,s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime
							*/

							insert into #Energydata(Machineid,Col1_gtime,Col2_gtime,Col1_Amp,Col2_Amp,st,nd)
							select @machineid,s1.gtime,
							case when s1.gtime1>#temp.Endtime then #temp.Endtime else s1.gtime1 end,
							s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime 
							from (select machineid,gtime,ampere,gtime1,ampere1 from tcs_energyconsumption
							where gtime>=@starttime and gtime<=@endtime and machineid=@machineid
							and isnull(gtime1,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000') s1, #temp
							where  S1.gtime>=#temp.starttime and S1.gtime<=#temp.Endtime and S1.machineid=@machineid
							and #temp.Machine=@machineid
							group by S1.machineid,s1.gtime,s1.gtime1,s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime

							update #Energydata set COl1_COl2=datediff(s,Col1_gtime,Col2_gtime)
			                 

							Update #temp set Cuttingdetail=T.CT from(Select sum(COl1_COl2) as Ct,#temp.starttime as st,#temp.Endtime as nd  from #Energydata,#temp 
							inner join Machineinformation M on M.machineid=#temp.machine where Col1_Amp>= M.LowerPowerthreshold and
							#temp.starttime=#Energydata.st and #Energydata.nd=#temp.Endtime group by #temp.starttime,#temp.Endtime)T  where T.st=#temp.starttime  and T.nd=#temp.Endtime

							update #temp  set TotalCuttingTime = isnull(TotalCuttingTime,0) + isnull(T1.TotalCutting,0)
							from
							(select Machine,Sum(Cuttingdetail) as TotalCutting from #temp group by Machine)T1
							inner join  #temp on #temp.Machine=T1.Machine


							Select Machine,Componentid,OperationNo,Operator,starttime,Endtime,Energy_Kwh,PF
							,LThreshold,UThreshold,Cuttingdetail,TotalCuttingTime,dbo.f_FormatTime(Cuttingdetail,'hh:mm:ss') as strCuttingdetail,
							dbo.f_FormatTime(TotalCuttingTime,'hh:mm:ss') as strTotalCuttingTime from #temp 
							--Geeta added till here
				End


				--ER00212-KarthickR-29-Dec-2009--From Here
				if @Parameter = 'Grid_GraphData_Mintue'
				Begin


						Set @st=@StartTime


						 while @st<@EndTime
							Begin
								insert into #minlevel(MachineID,StartTime,EndTime,Energy_Kwh,Pf,Minenergykwh,Maxenergykwh)
								values(@MachineID,@st,dateadd(mi,@No_Of_Minute,@st),0,0,0,0)
								set @st=dateadd(mi,@No_Of_Minute,@st)	
							End
					

							/*
							update #minlevel set Energy_Kwh=isnull(t1.Energy_Kwh,0),pf=isnull(t1.pf,0) from (
							Select mi.Machineid,#minlevel.StartTime,#minlevel.EndTime,
							--Round(isnull(max(tec.kwh),0)-Isnull(min(tec.kwh),0),2) as Energy_Kwh DR0304 commented here
							Round(isnull(max(tec.kwh),0)-Isnull(min(tec.kwh),0),5) as Energy_Kwh --DR0304 added here
							--,Isnull(Round(Avg(case when tec.pf>=0 then tec.pf end),2),0) as PF
							,Isnull(Round(Avg(Abs(tec.pf)),2),0) as PF
							from  Machineinformation mi
							inner join tcs_energyconsumption tec on tec.Machineid = mi.MachineID
							inner join #minlevel on #minlevel.machineid=mi.machineid
							where gtime >= #minlevel.StartTime and gtime <=#minlevel.EndTime	
							and mi.Machineid = @MachineID
							group by mi.Machineid,#minlevel.StartTime,#minlevel.EndTime
							) t1 inner join #minlevel on  #minlevel.StartTime=T1.StartTime  and T1.EndTime=#minlevel.EndTime
							*/

							update #minlevel set pf=isnull(t1.pf,0),mingtime=T1.mingtime,maxgtime=T1.maxgtime from 
							(
							Select mi.Machineid,#minlevel.StartTime,#minlevel.EndTime,
							Isnull(Round(Avg(Abs(tec.pf)),2),0) as PF,min(gtime) as mingtime,max(gtime) as maxgtime
							from  Machineinformation mi
							inner join tcs_energyconsumption tec on tec.Machineid = mi.MachineID
							inner join #minlevel on #minlevel.machineid=mi.machineid
							where gtime >= #minlevel.StartTime and gtime <=#minlevel.EndTime	
							and mi.Machineid = @MachineID
							group by mi.Machineid,#minlevel.StartTime,#minlevel.EndTime
							) t1 inner join #minlevel on  #minlevel.StartTime=T1.StartTime  and T1.EndTime=#minlevel.EndTime

							update #minlevel set Minenergykwh=isnull(Minenergykwh,0) + isnull(T2.kwh,0) from 
							(
							select #minlevel.machineid,starttime,endtime,ROUND(kwh,5) as kwh,mingtime
							from #minlevel
							inner join tcs_energyconsumption tec on tec.Machineid = #minlevel.machineid
							and tec.gtime=#minlevel.mingtime
							)T2 inner join #minlevel on  #minlevel.StartTime=T2.StartTime  and T2.EndTime=#minlevel.EndTime
							and  #minlevel.mingtime=T2.mingtime

							update #minlevel set Maxenergykwh=isnull(Maxenergykwh,0) + isnull(T2.kwh,0) from 
							(
							select #minlevel.machineid,starttime,endtime,ROUND(kwh,5) as kwh,maxgtime
							from #minlevel
							inner join tcs_energyconsumption tec on tec.Machineid = #minlevel.machineid
							and tec.gtime=#minlevel.maxgtime
							)T2 inner join #minlevel on  #minlevel.StartTime=T2.StartTime  and T2.EndTime=#minlevel.EndTime
							and  #minlevel.maxgtime=T2.maxgtime

							update #minlevel set Energy_Kwh = isnull(Energy_Kwh,0) + isnull(T2.kwh,0)
							from
							(select machineid,starttime,endtime,
							 round((Maxenergykwh-Minenergykwh),5) as kwh from #minlevel
							)T2 inner join #minlevel on  #minlevel.StartTime=T2.StartTime  and T2.EndTime=#minlevel.EndTime
							
							select * from #minlevel order by MachineID,StartTime,EndTime
				End
				--ER00212-KarthickR-29-Dec-2009--Till Here
			End
End


end
