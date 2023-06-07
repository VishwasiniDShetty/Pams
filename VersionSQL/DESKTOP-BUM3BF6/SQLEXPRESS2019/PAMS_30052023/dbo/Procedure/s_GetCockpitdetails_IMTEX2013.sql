/****** Object:  Procedure [dbo].[s_GetCockpitdetails_IMTEX2013]    Committed by VersionSQL https://www.versionsql.com ******/

--ACE VTL-02
--s_GetCockpitdetails_IMTEX2013 '2013-01-30','CNC VTL','ACE VTL-02','shiftwise'
CREATE                 PROCEDURE [dbo].[s_GetCockpitdetails_IMTEX2013]
	@Startdate datetime,
	@Plantid nvarchar(50) ='',
	@MachineID nvarchar(50)='',
	@param nvarchar(50) --'Plantwise','Machinewise','shiftwise'
AS
BEGIN

Declare @starttime as datetime
Declare @endtime as datetime
Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(255)

SELECT @strSql=''					--karthik 21 feb 07
SELECT @strMachine = ''
SELECT @strPlantID = ''

if isnull(@MachineID,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @MachineID + ''''
end

if isnull(@Plantid,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @Plantid + ''''
End


Create table #cockpitdata
(
Plantid nvarchar(50),
Machineid nvarchar(50),
Mcinterface int,
Prodtime float,
prodtime1 nvarchar(120),
ProdEff float,
NonProdtime float,
nonprodtime1 nvarchar(120),
NonProdEff float,
Loadunload float,
loadunload1 nvarchar(120),
LoadunloadEff float,
MachineStoppage float,
MachineStoppage1 nvarchar(120),
MachineStoppageEff float,
TOTALTIME FLOAT,
PlannedParts float,
ActualParts float,
TargetRevenue int,
delivery float
)

create table #shiftdetails
(
Startdate datetime,
shiftname nvarchar(20),
Starttime datetime,
Endtime datetime
)

Create table #Finaldata
(
Startdate datetime,
shiftname nvarchar(20),
Starttime datetime,
Endtime datetime,
Plantid nvarchar(50),
Machineid nvarchar(50),
Mcinterface int,
Prodtime float,
Prodtime1 nvarchar(50),
ProdEff float,
NonProdtime float,
NonProdtime1 nvarchar(50),
NonProdEff float,
Loadunload float,
Loadunload1 nvarchar(50),
MachineStoppage float,
MachineStoppage1 nvarchar(50),
ActualParts int,
TOTALTIME FLOAT
)

create table #Downtime
(

	starttime datetime,
	endtime datetime,
	downtime nvarchar(50),
	[DownDescription] nvarchar(50)
)


If @param <>'Shiftwise'
Begin
	select @starttime = dbo.f_GetLogicalDay(@Startdate,'Start')
	select @endtime = dbo.f_GetLogicalDay(@Startdate,'end')
End

If @param = 'Shiftwise'
Begin
	select @starttime = dbo.f_GetLogicalDay(@Startdate,'Start')
	insert into #shiftdetails
	exec s_GetShiftTime @starttime,''	
End



SET @strSql = ' Insert into #cockpitdata ( Plantid,Machineid,Mcinterface,Prodtime,ProdEff,NonProdtime,NonProdEff,Loadunload,LoadunloadEff,MachineStoppage,MachineStoppageEff,PlannedParts,ActualParts,TargetRevenue,delivery,TOTALTIME)'
SET @strSql = @strSql + ' SELECT PlantMachine.plantID,MachineInformation.MachineID, MachineInformation.interfaceid,0,0,0,0,0,0,0,0,0,0,0,0,0 FROM MachineInformation
			  LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID WHERE MachineInformation.interfaceid > ''0'' 
			  AND MachineInformation.TPMTrakEnabled = 1 '
SET @strSql =  @strSql + @strMachine + @strPlantID 
print @strSql
EXEC(@strSql)

If @param <>'Shiftwise'
Begin

			----To Get Prodtime
			UPDATE #CockpitData SET Prodtime = isnull(Prodtime,0) + isNull(t2.prod,0)
				from
				(select mc,sum(
						CASE
						WHEN  autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  cycletime
						WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
						WHEN (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
						WHEN autodata.sttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
						END
					)AS prod
				from autodata inner join Machineinformation on autodata.mc=Machineinformation.interfaceid
				where autodata.datatype=1 AND
				(
				(autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)
				OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
				OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
				OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )
				) 
				group by autodata.mc
			) as t2 inner join #CockpitData on t2.mc = #CockpitData.Mcinterface


				/* Fetching Down Records from Production Cycle  */
				/* If Down Records of TYPE-2*/
				UPDATE  #CockpitData SET Prodtime = isnull(Prodtime,0) - isNull(t2.Down,0)
				FROM
				(Select AutoData.mc ,
				SUM(
				CASE
				When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )
				When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
				END) as Down
				From AutoData INNER Join
				(Select mc,Sttime,NdTime From AutoData
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
				ON AutoData.mc=T1.mc
				Where AutoData.DataType=2
				And ( autodata.Sttime > T1.Sttime )
				And ( autodata.ndtime <  T1.ndtime )
				AND ( autodata.ndtime >  @StartTime )
				GROUP BY AUTODATA.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.Mcinterface

				
				/* If Down Records of TYPE-3*/
				UPDATE  #CockpitData SET Prodtime = isnull(Prodtime,0) - isNull(t2.Down,0)
				FROM
				(Select AutoData.mc ,
				SUM(CASE
				When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
				When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
				END) as Down
				From AutoData INNER Join
				(Select mc,Sttime,NdTime From AutoData
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime >= @StartTime)And (ndtime > @EndTime) and (sttime<@EndTime) ) as T1
				ON AutoData.mc=T1.mc
				Where AutoData.DataType=2
				And (T1.Sttime < autodata.sttime  )
				And ( T1.ndtime >  autodata.ndtime)
				AND (autodata.sttime  <  @EndTime)
				GROUP BY AUTODATA.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.Mcinterface

				/* If Down Records of TYPE-4*/
				UPDATE  #CockpitData SET Prodtime = isnull(Prodtime,0) - isNull(t2.Down,0)
				FROM
				(Select AutoData.mc ,
				SUM(CASE
				When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
				When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
				When autodata.sttime>=@StartTime And autodata.sttime < @EndTime AND autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
				When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
				--DR0236 - KarthikG - 19/Jun/2010 :: Till Here
				END) as Down
				From AutoData INNER Join
				(Select mc,Sttime,NdTime From AutoData
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < @StartTime)And (ndtime > @EndTime) ) as T1
				ON AutoData.mc=T1.mc
				Where AutoData.DataType=2
				And (T1.Sttime < autodata.sttime  )
				And ( T1.ndtime >  autodata.ndtime)
				AND (autodata.ndtime  >  @StartTime)
				AND (autodata.sttime  <  @EndTime)
				GROUP BY AUTODATA.mc
				)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.Mcinterface

			----To Get Loadunloadtime
			UPDATE #CockpitData SET Loadunload = isnull(Loadunload,0) + isNull(t2.LD,0)
				from
				(select mc,	sum(case
						WHEN (autodata.msttime >= @StartTime  AND autodata.sttime <=@EndTime) THEN DateDiff(second,autodata.msttime,autodata.sttime)
						WHEN ( autodata.msttime < @StartTime  AND autodata.sttime <= @EndTime AND autodata.sttime > @StartTime ) THEN DateDiff(second,@StartTime,autodata.sttime)
						WHEN ( autodata.msttime >= @StartTime   AND autodata.msttime <@EndTime AND autodata.sttime > @EndTime ) THEN DateDiff(second,autodata.msttime,@EndTime)
						WHEN ( autodata.msttime < @StartTime  AND autodata.ndtime > @EndTime) THEN DateDiff(second,@StartTime,@EndTime)
						END)  as LD 
				from autodata inner join Machineinformation on autodata.mc=Machineinformation.interfaceid
				where autodata.datatype=1 AND
				(
				(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
				OR (autodata.msttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
				OR (autodata.msttime>=@StartTime  and autodata.msttime<@EndTime  and autodata.ndtime>@EndTime)
				OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
				) 
				group by autodata.mc
			) as t2 inner join #CockpitData on t2.mc = #CockpitData.Mcinterface

			--To get downtime
			UPDATE #CockpitData SET MachineStoppage = isnull(MachineStoppage,0) + isNull(t2.down,0)
			from
			(select mc,sum(
					CASE
					WHEN  (autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)  THEN  loadunload
					WHEN (autodata.msttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
					WHEN (autodata.msttime>=@StartTime  and autodata.msttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, mstTime, @Endtime)
					WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
					END
				)AS down
				from autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				where autodata.datatype=2 AND
				(
				(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
				OR (autodata.msttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
				OR (autodata.msttime>=@StartTime  and autodata.msttime<@EndTime  and autodata.ndtime>@EndTime)
				OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
				) 
				group by autodata.mc
			) as t2 inner join #CockpitData on t2.mc = #CockpitData.Mcinterface


			--To Get Parts
			UPDATE #CockpitData SET ActualParts = ISNULL(ActualParts,0) + ISNULL(t2.comp,0)
			From
			(
				Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp
					   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn from autodata
					   where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)
					   Group By mc,comp,opn) as T1
				Inner join componentinformation C on T1.Comp = C.interfaceid
				Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
				inner join machineinformation on machineinformation.machineid =O.machineid
				and T1.mc=machineinformation.interfaceid
				GROUP BY mc
			) As T2 Inner join #CockpitData on T2.mc = #CockpitData.Mcinterface


			--To Get NonProductionTime
			UPDATE #CockpitData set Nonprodtime = MachineStoppage+Loadunload

			--To get TurnOver
			UPDATE #CockpitData SET TargetRevenue = isnull(TargetRevenue,0) + isNull(t2.revenue,0)
			from
			(
			select Machineid,(24*mchrrate) as revenue from machineinformation 
			) as t2 inner join #CockpitData on t2.Machineid = #CockpitData.Machineid


			--To get PlannedParts
			select @strSql =''
			select @strSql='update #CockpitData set PlannedParts= isnull(PlannedParts,0)+ ISNULL(t1.tcount,0) from
			(select machine,sum(idealcount) as tcount from
			loadschedule where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC)'
			select @strSql= @strSql + ' group by machine) as t1 inner join #CockpitData on
			t1.machine=#CockpitData.machineid '
			PRINT @strSql
			EXEC (@strSql)

			--To get Delivery (%)
			update #CockpitData  set delivery = T1.del from
			(select Plantid,Machineid,(sum(ActualParts)/sum(PlannedParts))* 100 as del 
			 from #CockpitData where ActualParts<>0 and PlannedParts<>0
			 group by Plantid,Machineid)T1 inner join #CockpitData on T1.Machineid=#CockpitData.machineid

			
			
			If @param='Plantwise'
			Begin

			
				update #cockpitdata set prodtime = isnull(T.ProductionTime,0),Nonprodtime = isnull(T.NonProductionTime,0),Loadunload=isnull(T.Loadunload,0),
				MachineStoppage = isnull(T.MachineStoppages,0),ActualParts=isnull(T.NumberOfCycles,0),PlannedParts=isnull(T.PlannedParts,0),
				TargetRevenue = ISNULL(T.TargetRevenue,0),TOTALTIME=ISNULL(T.TOTALTIME,0) from 
				(select Plantid,Sum(Prodtime) as ProductionTime,Sum(NonProdtime) as NonProductionTime,
				Sum(Loadunload) as Loadunload,Sum(MachineStoppage) as MachineStoppages,sum(ActualParts) as NumberOfCycles,sum(PlannedParts) as PlannedParts,sum(TargetRevenue) as TargetRevenue,
				sum(prodtime)+ sum(Nonprodtime) AS TOTALTIME
				from #cockpitdata group by Plantid)T inner join  #cockpitdata on #cockpitdata.plantid=T.plantid 

				update #cockpitdata set ProdEff=isnull(T.ProdEff,0),NonProdEff=isnull(T.NonProdEff,0),LoadunloadEff=isnull(T.LoadunloadEff,0),
				MachineStoppageEff = isnull(T.MachineStoppageEff,0)from
				(select Plantid,round((sum(prodtime)/sum(Totaltime))*100,2) as ProdEff ,
				round((sum(Nonprodtime)/sum(Totaltime))*100,2) as NonProdEff,
				round((sum(Loadunload)/sum(Totaltime))*100,2) as LoadunloadEff,
				round((sum(MachineStoppage)/sum(Totaltime))*100,2) as MachineStoppageEff from #cockpitdata 
				WHERE TOTALTIME<>0 group by Plantid)T
			    inner join  #cockpitdata on #cockpitdata.plantid=T.plantid 



				update #cockpitdata set Prodtime1 = convert(nvarchar,dbo.f_FormatTime(Prodtime,'HH:MM:SS'),120),
				Nonprodtime1 = convert(nvarchar,dbo.f_FormatTime(Nonprodtime,'HH:MM:SS'),120),Loadunload1 = convert(nvarchar,dbo.f_FormatTime(Loadunload,'HH:MM:SS'),120),
				MachineStoppage1 = convert(nvarchar,dbo.f_FormatTime(MachineStoppage,'HH:MM:SS'),120)

				/*
				select top 1 Plantid,
				case when right('000'+ convert(nvarchar(3),datepart(hour,Prodtime1)),3)= '000' and right('000' + convert(nvarchar(3),datepart(minute,Prodtime1)),3) = '000' then ''
				when right('000'+ convert(nvarchar(3),datepart(hour,Prodtime1)),3)= '000' then  right('000' + convert(nvarchar(3),datepart(minute,Prodtime1)),3) + ' min ' 
				when right('000' + convert(nvarchar(3),datepart(minute,Prodtime1)),3) = '000' then right('000'+ convert(nvarchar(3),datepart(hour,Prodtime1)),3) + ' hr '
				else right('000'+ convert(nvarchar(3),datepart(hour,Prodtime1)),3) + ' hr ' +  right('000' + convert(nvarchar(3),datepart(minute,Prodtime1)),3) + ' min '
				end as ProductionTime,
				round(ProdEff,0) as  ProdEff,
					case when right('000'+ convert(nvarchar(3),datepart(hour,Nonprodtime1)),3)= '000' and right('000' + convert(nvarchar(3),datepart(minute,Nonprodtime1)),3) = '000' then ''
				when right('000'+ convert(nvarchar(3),datepart(hour,Nonprodtime1)),3)= '000' then  right('000' + convert(nvarchar(3),datepart(minute,Nonprodtime1)),3) + ' min ' 
				when right('000' + convert(nvarchar(3),datepart(minute,Nonprodtime1)),3) = '000' then right('000'+ convert(nvarchar(3),datepart(hour,Nonprodtime1)),3) + ' hr '
				else right('000'+ convert(nvarchar(3),datepart(hour,Nonprodtime1)),3) + ' hr ' +  right('000' + convert(nvarchar(3),datepart(minute,Nonprodtime1)),3) + ' min '
				end as NonProductionTime,
				round(NonProdEff,0) as NonProdEff,
				case when right('000'+ convert(nvarchar(3),datepart(hour,Loadunload1)),3)= '000' and right('000' + convert(nvarchar(3),datepart(minute,Loadunload1)),3) = '000' then ''
				when right('000'+ convert(nvarchar(3),datepart(hour,Loadunload1)),3)= '000' then  right('000' + convert(nvarchar(3),datepart(minute,Loadunload1)),3) + ' min ' 
				when right('000' + convert(nvarchar(3),datepart(minute,Loadunload1)),3) = '000' then right('000'+ convert(nvarchar(3),datepart(hour,Loadunload1)),3) + ' hr '
				else right('000'+ convert(nvarchar(3),datepart(hour,Loadunload1)),3) + ' hr ' +  right('000' + convert(nvarchar(3),datepart(minute,Loadunload1)),3) + ' min '
				end as Loadunload,
				round(LoadunloadEff,0) as LoadunloadEff,
					case when right('000'+ convert(nvarchar(3),datepart(hour,MachineStoppage1)),3)= '000' and right('000' + convert(nvarchar(3),datepart(minute,MachineStoppage1)),3) = '000' then ''
				when right('000'+ convert(nvarchar(3),datepart(hour,MachineStoppage1)),3)= '000' then  right('000' + convert(nvarchar(3),datepart(minute,MachineStoppage1)),3) + ' min ' 
				when right('000' + convert(nvarchar(3),datepart(minute,MachineStoppage1)),3) = '000' then right('000'+ convert(nvarchar(3),datepart(hour,MachineStoppage1)),3) + ' hr '
				else right('000'+ convert(nvarchar(3),datepart(hour,MachineStoppage1)),3) + ' hr ' +  right('000' + convert(nvarchar(3),datepart(minute,MachineStoppage1)),3) + ' min '
				end as  MachineStoppages,
				round(MachineStoppageEff,0) as MachineStoppageEff,
				ActualParts as NumberOfCycles,
				TargetRevenue as TargetRevenue from #cockpitdata 
				*/
				select top 1 Plantid,
				substring(dbo.f_FormatTime(Prodtime,'hh:mm:ss'),1,charindex(':',dbo.f_FormatTime(Prodtime,'hh:mm:ss'))-1) + ' hrs ' +
				substring(dbo.f_FormatTime(Prodtime,'hh:mm:ss'),charindex(':',dbo.f_FormatTime(Prodtime,'hh:mm:ss'))+1,charindex(':',dbo.f_FormatTime(Prodtime,'hh:mm:ss'))-1) + ' mins ' as ProductionTime,
				round(ProdEff,0) as ProdEff ,
				substring(dbo.f_FormatTime(NonProdtime,'hh:mm:ss'),1,charindex(':',dbo.f_FormatTime(NonProdtime,'hh:mm:ss'))-1) + ' hrs ' +
				substring(dbo.f_FormatTime(NonProdtime,'hh:mm:ss'),charindex(':',dbo.f_FormatTime(NonProdtime,'hh:mm:ss'))+1,charindex(':',dbo.f_FormatTime(NonProdtime,'hh:mm:ss'))-2) + ' mins ' as NonProductionTime,
				round(NonProdEff,0) as NonProdEff ,
				substring(dbo.f_FormatTime(Loadunload,'hh:mm:ss'),1,charindex(':',dbo.f_FormatTime(Loadunload,'hh:mm:ss'))-1) + ' hrs ' +
				substring(dbo.f_FormatTime(Loadunload,'hh:mm:ss'),charindex(':',dbo.f_FormatTime(Loadunload,'hh:mm:ss'))+1,charindex(':',dbo.f_FormatTime(Loadunload,'hh:mm:ss'))-1) + ' mins ' as Loadunload,
				round(LoadunloadEff,0) as LoadunloadEff,
				substring(dbo.f_FormatTime(MachineStoppage,'hh:mm:ss'),1,charindex(':',dbo.f_FormatTime(MachineStoppage,'hh:mm:ss'))-1) + ' hrs ' +
				substring(dbo.f_FormatTime(MachineStoppage,'hh:mm:ss'),charindex(':',dbo.f_FormatTime(MachineStoppage,'hh:mm:ss'))+1,charindex(':',dbo.f_FormatTime(MachineStoppage,'hh:mm:ss'))-2) + ' mins ' as MachineStoppages,
				round(MachineStoppageEff,0) as MachineStoppageEff,
				ActualParts as NumberOfCycles,
				TargetRevenue as TargetRevenue from #cockpitdata 

			end

			If @param='Machinewise'
			Begin


				update #cockpitdata set prodtime = isnull(T.ProductionTime,0),Nonprodtime = isnull(T.NonProductionTime,0),Loadunload=isnull(T.Loadunload,0),
				MachineStoppage = isnull(T.MachineStoppages,0),ActualParts=isnull(T.NumberOfCycles,0),PlannedParts=isnull(T.PlannedParts,0),
				TargetRevenue = ISNULL(T.TargetRevenue,0),TOTALTIME=ISNULL(T.TOTALTIME,0) from 
				(select Plantid,Machineid,Sum(Prodtime) as ProductionTime,Sum(NonProdtime) as NonProductionTime,
				Sum(Loadunload) as Loadunload,Sum(MachineStoppage) as MachineStoppages,sum(ActualParts) as NumberOfCycles,sum(PlannedParts) as PlannedParts,sum(TargetRevenue) as TargetRevenue,
				sum(prodtime)+ sum(Nonprodtime) AS TOTALTIME
				from #cockpitdata group by Plantid,Machineid)T inner join  #cockpitdata on #cockpitdata.plantid=T.plantid and #cockpitdata.machineid=T.machineid


				update #cockpitdata set ProdEff=isnull(T.ProdEff,0),NonProdEff=isnull(T.NonProdEff,0),LoadunloadEff=isnull(T.LoadunloadEff,0),
				MachineStoppageEff = isnull(T.MachineStoppageEff,0)from
				(select Plantid,Machineid,round((sum(prodtime)/sum(Totaltime))*100,2) as ProdEff ,
				round((sum(Nonprodtime)/sum(Totaltime))*100,2) as NonProdEff,
				round((sum(Loadunload)/sum(Totaltime))*100,2) as LoadunloadEff,
				round((sum(MachineStoppage)/sum(Totaltime))*100,2) as MachineStoppageEff from #cockpitdata 
				WHERE TOTALTIME<>0 group by Plantid,Machineid)T
			    inner join  #cockpitdata on #cockpitdata.plantid=T.plantid and #cockpitdata.machineid=T.machineid


				update #cockpitdata set delivery = isnull(T.delivery,0) from
				(select Plantid,Machineid,round((ActualParts/PlannedParts)*100,2) as delivery from #cockpitdata
				 where PlannedParts<>0 )T
				 inner join  #cockpitdata on #cockpitdata.plantid=T.plantid and #cockpitdata.machineid=T.machineid


				update #cockpitdata set Prodtime1 = dbo.f_FormatTime(Prodtime,'hh:mm:ss'),
				Nonprodtime1 = dbo.f_FormatTime(Nonprodtime,'hh:mm:ss'),Loadunload1 = dbo.f_FormatTime(Loadunload,'hh:mm:ss'),
				MachineStoppage1 = dbo.f_FormatTime(MachineStoppage,'hh:mm:ss')


				select Plantid,Machineid,
				substring(dbo.f_FormatTime(Sum(Prodtime),'hh:mm:ss'),1,charindex(':',dbo.f_FormatTime(Sum(Prodtime),'hh:mm:ss'))-1) + ' hrs '
				 + substring(dbo.f_FormatTime(Sum(Prodtime),'hh:mm:ss'),charindex(':',dbo.f_FormatTime(Sum(Prodtime),'hh:mm:ss'))+1,charindex(':',dbo.f_FormatTime(Sum(Prodtime),'hh:mm:ss'))-1) + ' mins ' 
				as ProductionTime,round(sum(ProdEff),0) as ProdEff,
				substring(dbo.f_FormatTime(Sum(NonProdtime),'hh:mm:ss'),1,charindex(':',dbo.f_FormatTime(Sum(NonProdtime),'hh:mm:ss'))-1) + ' hrs ' 
				+ substring(dbo.f_FormatTime(Sum(NonProdtime),'hh:mm:ss'),charindex(':',dbo.f_FormatTime(Sum(NonProdtime),'hh:mm:ss'))+1,charindex(':',dbo.f_FormatTime(Sum(NonProdtime),'hh:mm:ss'))-1) + ' mins '
				 as NonProductionTime, round(sum(NonProdEff),0) as NonProdEff,
				substring(dbo.f_FormatTime(Sum(Loadunload),'hh:mm:ss'),1,charindex(':',dbo.f_FormatTime(Sum(Loadunload),'hh:mm:ss'))-1) + ' hrs ' 
				+ substring(dbo.f_FormatTime(Sum(Loadunload),'hh:mm:ss'),charindex(':',dbo.f_FormatTime(Sum(Loadunload),'hh:mm:ss'))+1,charindex(':',dbo.f_FormatTime(Sum(Loadunload),'hh:mm:ss'))-1) + ' mins ' 
				as Loadunload, round(sum(LoadunloadEff),0) as LoadunloadEff,
				substring(dbo.f_FormatTime(Sum(MachineStoppage),'hh:mm:ss'),1,charindex(':',dbo.f_FormatTime(Sum(MachineStoppage),'hh:mm:ss'))-1) + ' hrs ' 
				+ substring(dbo.f_FormatTime(Sum(MachineStoppage),'hh:mm:ss'),charindex(':',dbo.f_FormatTime(Sum(MachineStoppage),'hh:mm:ss'))+1,charindex(':',dbo.f_FormatTime(Sum(MachineStoppage),'hh:mm:ss'))-1) + ' mins ' 
				as MachineStoppages,round(sum(MachineStoppageEff),0) as MachineStoppageEff,
				sum(ActualParts) as NumberOfCycles,
				sum(PlannedParts) as PlannedParts,
				sum(delivery) as delivery,
				sum(TargetRevenue) as TargetRevenue from #cockpitdata 
				group by Plantid,Machineid
			end

			If @param='MachinewiseDown'
			Begin

				Insert into #downtime(StartTime,EndTime,[DownDescription],DownTime)
				SELECT
				case when autodata.sttime<@starttime then @starttime else autodata.sttime end AS StartTime,
				case when autodata.ndtime>@endtime then @endtime else autodata.ndtime end AS EndTime,
				downcodeinformation.downdescription as [DownDescription],
				case
				When (autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime ) THEN loadunload
				WHEN ( autodata.sttime < @StartTime AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime ) THEN DateDiff(second, @StartTime, ndtime)
				WHEN ( autodata.sttime >= @StartTime AND autodata.sttime < @EndTime AND autodata.ndtime > @EndTime ) THEN  DateDiff(second, stTime, @EndTime)
				ELSE
				DateDiff(second, @StartTime, @EndTime)END AS DownTime
				FROM autodata 
				INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
				INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
				WHERE machineinformation.machineid = @MachineID AND autodata.datatype = 2 AND
				(
				(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
				OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
				OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
				OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
				)
				ORDER BY autodata.ndtime



				select StartTime,EndTime,[DownDescription],
						substring(dbo.f_FormatTime(DownTime,'hh:mm:ss'),1,charindex(':',dbo.f_FormatTime(DownTime,'hh:mm:ss'))-1) + ' hrs '
				 + substring(dbo.f_FormatTime(DownTime,'hh:mm:ss'),charindex(':',dbo.f_FormatTime(DownTime,'hh:mm:ss'))+1,charindex(':',dbo.f_FormatTime(DownTime,'hh:mm:ss'))-1) + ' mins ' 
				as DownTime
				from #downtime
		  end

END



If @param='Shiftwise'
Begin


		insert into #Finaldata
		select Startdate,shiftname,Starttime,endtime,Plantid,Machineid,Mcinterface,Prodtime,0,0,NonProdtime,0,0,Loadunload,0,MachineStoppage,0,ActualParts,0 from 
		#cockpitdata cross join #shiftdetails



		----To Get Prodtime
		UPDATE #Finaldata SET Prodtime = isnull(Prodtime,0) + isNull(t2.prod,0)
			from
			(select mc,starttime,endtime,sum(
					CASE
					WHEN  autodata.sttime>=StartTime  and  autodata.ndtime<=EndTime  THEN  cycletime
					WHEN (autodata.sttime<StartTime and  autodata.ndtime>StartTime and autodata.ndtime<=EndTime)  THEN DateDiff(second, StartTime, ndtime)
					WHEN (autodata.sttime>=StartTime  and autodata.sttime<EndTime  and autodata.ndtime>EndTime)  THEN DateDiff(second, stTime, EndTime)
					WHEN autodata.sttime<StartTime and autodata.ndtime>EndTime   THEN DateDiff(second, StartTime, EndTime)
					END
				)AS prod
			from autodata inner join Machineinformation on autodata.mc=Machineinformation.interfaceid
			inner join #Finaldata on #Finaldata.Machineid=Machineinformation.machineid
			where autodata.datatype=1 AND
			(
			(autodata.sttime>=StartTime  and  autodata.ndtime<=EndTime)
			OR (autodata.sttime<StartTime and  autodata.ndtime>StartTime and autodata.ndtime<=EndTime)
			OR (autodata.sttime>=StartTime  and autodata.sttime<EndTime  and autodata.ndtime>EndTime)
			OR (autodata.sttime<StartTime and autodata.ndtime>EndTime )
			) 
			group by autodata.mc,starttime,endtime
		) as t2 inner join #Finaldata on t2.mc = #Finaldata.Mcinterface and t2.starttime=#Finaldata.starttime and t2.endtime=#Finaldata.endtime



		--ICD Type 2
		UPDATE  #Finaldata SET Prodtime = isnull(Prodtime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(
		CASE
			When autodata.sttime <= T1.starttime Then datediff(s, T1.starttime,autodata.ndtime )
			When autodata.sttime > T1.starttime Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,t1.starttime as ShiftStart
		From AutoData INNER Join
			(Select mc,Sttime,NdTime,starttime,endtime From AutoData
				inner join #Finaldata ST1 ON ST1.McInterface=Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < starttime)And (ndtime > starttime) AND (ndtime <= endtime)
		) as T1 on t1.mc=autodata.mc
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T1.starttime )
		GROUP BY AUTODATA.mc,T1.starttime)AS T2 Inner Join #Finaldata on t2.mc = #Finaldata.mcinterface
		and t2.ShiftStart=#Finaldata.starttime

		--For Type4
		UPDATE  #Finaldata SET Prodtime = isnull(Prodtime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
			When autodata.sttime >= T1.starttime AND autodata.ndtime <= T1.endtime Then datediff(s , autodata.sttime,autodata.ndtime)
			When autodata.sttime < T1.starttime And autodata.ndtime >T1.starttime AND autodata.ndtime<=T1.endtime Then datediff(s, T1.starttime,autodata.ndtime )
			When autodata.sttime >= T1.starttime AND autodata.sttime<T1.endtime AND autodata.ndtime>T1.endtime Then datediff(s,autodata.sttime, T1.endtime )
			When autodata.sttime<T1.starttime AND autodata.ndtime>T1.endtime   Then datediff(s , T1.starttime,T1.endtime)
		END) as Down,T1.starttime as ShiftStart
		From AutoData INNER Join
			(Select mc,Sttime,NdTime,starttime,endtime From AutoData
				inner join #Finaldata ST1 ON ST1.mcInterface =Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < starttime)And (ndtime >endtime)
			
		 ) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.starttime)
		AND (autodata.sttime  <  T1.endtime)
		GROUP BY AUTODATA.mc,T1.starttime
		 )AS T2 Inner Join #Finaldata on t2.mc = #Finaldata.mcinterface
		and t2.ShiftStart=#Finaldata.starttime

		--Type 3
		UPDATE  #Finaldata SET Prodtime = isnull(Prodtime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
			When autodata.ndtime > T1.endtime Then datediff(s,autodata.sttime, T1.endtime )
			When autodata.ndtime <=T1.endtime Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,T1.starttime as ShiftStart
		From AutoData INNER Join
			(Select mc,Sttime,NdTime,starttime,endtime From AutoData
				inner join #Finaldata ST1 ON ST1.mcInterface =Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime >= starttime)And (ndtime >endtime) and (sttime< endtime)
		 ) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T1.endtime)
		GROUP BY AUTODATA.mc,T1.starttime)AS T2 Inner Join #Finaldata on t2.mc = #Finaldata.mcinterface
		 and t2.ShiftStart=#Finaldata.starttime


		----To Get Loadunloadtime
		UPDATE #Finaldata SET Loadunload = isnull(Loadunload,0) + isNull(t2.LD,0)
			from
			(select mc,starttime,endtime,sum(case
					WHEN (autodata.msttime >= StartTime  AND autodata.sttime <=EndTime) THEN DateDiff(second,autodata.msttime,autodata.sttime)
					WHEN ( autodata.msttime < StartTime  AND autodata.sttime <= EndTime AND autodata.sttime > StartTime ) THEN DateDiff(second,StartTime,autodata.sttime)
					WHEN ( autodata.msttime >= StartTime   AND autodata.msttime <EndTime AND autodata.sttime > EndTime ) THEN DateDiff(second,autodata.msttime,EndTime)
					WHEN ( autodata.msttime < StartTime  AND autodata.ndtime > EndTime) THEN DateDiff(second,StartTime,EndTime)
					END)  as LD 
			from autodata inner join Machineinformation on autodata.mc=Machineinformation.interfaceid
			inner join #Finaldata on #Finaldata.Machineid=Machineinformation.machineid
			where autodata.datatype=1 AND
			(
			(autodata.msttime>=StartTime  and  autodata.ndtime<=EndTime)
			OR (autodata.msttime<StartTime and  autodata.ndtime>StartTime and autodata.ndtime<=EndTime)
			OR (autodata.msttime>=StartTime  and autodata.msttime<EndTime  and autodata.ndtime>EndTime)
			OR (autodata.msttime<StartTime and autodata.ndtime>EndTime )
			) 
			group by autodata.mc,starttime,endtime
		) as t2 inner join #Finaldata on t2.mc = #Finaldata.Mcinterface  and t2.starttime=#Finaldata.starttime and t2.endtime=#Finaldata.endtime

		--To get downtime
			
		UPDATE #Finaldata SET MachineStoppage = isnull(MachineStoppage,0) + isNull(t2.down,0)
		from
		(select mc,starttime,endtime,#Finaldata.machineid,sum(
				CASE
				WHEN  (autodata.msttime>=StartTime  and  autodata.ndtime<=EndTime)  THEN  autodata.loadunload
				WHEN (autodata.msttime<StartTime and  autodata.ndtime>StartTime and autodata.ndtime<=EndTime)  THEN DateDiff(second, StartTime, ndtime)
				WHEN (autodata.msttime>=StartTime  and autodata.msttime<EndTime  and autodata.ndtime>EndTime)  THEN DateDiff(second, mstTime, Endtime)
				WHEN autodata.msttime<StartTime and autodata.ndtime>EndTime   THEN DateDiff(second, StartTime, EndTime)
				END
			)AS down
			from autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
			inner join Machineinformation on autodata.mc=Machineinformation.interfaceid
			inner join #Finaldata on #Finaldata.Machineid=Machineinformation.machineid
			where autodata.datatype=2 AND
			(
			(autodata.msttime>=StartTime  and  autodata.ndtime<=EndTime)
			OR (autodata.msttime<StartTime and  autodata.ndtime>StartTime and autodata.ndtime<=EndTime)
			OR (autodata.msttime>=StartTime  and autodata.msttime<EndTime  and autodata.ndtime>EndTime)
			OR (autodata.msttime<StartTime and autodata.ndtime>EndTime )
			) AND (downcodeinformation.availeffy = 0)
			group by autodata.mc,starttime,endtime,#Finaldata.machineid
		) as t2 inner join #Finaldata on t2.mc = #Finaldata.Mcinterface  and t2.starttime=#Finaldata.starttime and t2.endtime=#Finaldata.endtime



		--To Get Parts
		UPDATE #Finaldata SET ActualParts = ISNULL(ActualParts,0) + ISNULL(t2.comp,0)
		From
		(
			Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp,
			#Finaldata.starttime,#Finaldata.endtime
				   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn,starttime,endtime from autodata
					inner join #Finaldata on #Finaldata.mcinterface=autodata.mc
				   where (autodata.ndtime>StartTime) and (autodata.ndtime<=EndTime) and (autodata.datatype=1)
				   Group By mc,comp,opn,starttime,endtime) as T1
			Inner join componentinformation C on T1.Comp = C.interfaceid
			Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
			inner join machineinformation on machineinformation.machineid =O.machineid
			and T1.mc=machineinformation.interfaceid
			inner join #Finaldata on #Finaldata.machineid=machineinformation.machineid
			and #finaldata.starttime=T1.starttime and #finaldata.endtime=T1.endtime
			GROUP BY mc,#Finaldata.starttime,#Finaldata.endtime
		) As T2 Inner join #Finaldata on T2.mc = #Finaldata.Mcinterface and T2.starttime=#Finaldata.starttime and T2.endtime=#Finaldata.endtime


		--To Get NonProductionTime
		UPDATE #Finaldata set Nonprodtime = MachineStoppage+Loadunload
			
		
		update #Finaldata set prodtime = isnull(T.ProductionTime,0),Nonprodtime = isnull(T.NonProductionTime,0),Loadunload=isnull(T.Loadunload,0),
		MachineStoppage = isnull(T.MachineStoppages,0),ActualParts=isnull(T.NumberOfCycles,0),
		TOTALTIME=ISNULL(T.TOTALTIME,0) from 
		(select Plantid,Machineid,starttime,endtime,Sum(Prodtime) as ProductionTime,Sum(NonProdtime) as NonProductionTime,
		Sum(Loadunload) as Loadunload,Sum(MachineStoppage) as MachineStoppages,sum(ActualParts) as NumberOfCycles,
		sum(prodtime)+ sum(Nonprodtime) AS TOTALTIME
		from #Finaldata group by Plantid,Machineid,starttime,endtime)T
		 inner join  #Finaldata on #Finaldata.plantid=T.plantid and #Finaldata.machineid=T.machineid
		and T.starttime=#Finaldata.starttime and T.endtime=#Finaldata.endtime

		update #Finaldata set ProdEff=isnull(T.ProdEff,0),NonProdEff=isnull(T.NonProdEff,0) from
		(select Plantid,Machineid,starttime,endtime,round((sum(prodtime)/sum(Totaltime))*100,2) as ProdEff ,
		round((sum(Nonprodtime)/sum(Totaltime))*100,2) as NonProdEff from #Finaldata 
		WHERE TOTALTIME<>0 group by Plantid,Machineid,starttime,endtime)T
	    inner join  #Finaldata on #Finaldata.plantid=T.plantid and #Finaldata.machineid=T.machineid
		and T.starttime=#Finaldata.starttime and T.endtime=#Finaldata.endtime

		update #Finaldata set Prodtime1 = dbo.f_FormatTime(Prodtime,'hh:mm:ss'),
		Nonprodtime1 = dbo.f_FormatTime(Nonprodtime,'hh:mm:ss'),Loadunload1 = dbo.f_FormatTime(Loadunload,'hh:mm:ss'),
		MachineStoppage1 = dbo.f_FormatTime(MachineStoppage,'hh:mm:ss')

		select Plantid,Machineid,Starttime,Endtime,shiftname,
		case when right('00'+ convert(nvarchar,datepart(hour,Prodtime1)),2)= '00' and right('00' + convert(nvarchar(2),datepart(minute,Prodtime1)),2) = '00' then ''
		when right('00'+ convert(nvarchar,datepart(hour,Prodtime1)),2)= '00' then  right('00' + convert(nvarchar(2),datepart(minute,Prodtime1)),2) + ' min ' 
		when right('00' + convert(nvarchar(2),datepart(minute,Prodtime1)),2) = '00' then right('00'+ convert(nvarchar,datepart(hour,Prodtime1)),2) + ' hr '
		else right('00'+ convert(nvarchar,datepart(hour,Prodtime1)),2) + ' hr ' +  right('00' + convert(nvarchar(2),datepart(minute,Prodtime1)),2) + ' min '
		end as ProductionTime,round(ProdEff,0) as ProdEff,
		case when right('00'+ convert(nvarchar,datepart(hour,Nonprodtime1)),2)= '00' and right('00' + convert(nvarchar(2),datepart(minute,Nonprodtime1)),2) = '00' then ''
		when right('00'+ convert(nvarchar,datepart(hour,Nonprodtime1)),2)= '00' then  right('00' + convert(nvarchar(2),datepart(minute,Nonprodtime1)),2) + ' min ' 
		when right('00' + convert(nvarchar(2),datepart(minute,Nonprodtime1)),2) = '00' then right('00'+ convert(nvarchar,datepart(hour,Nonprodtime1)),2) + ' hr '
		else right('00'+ convert(nvarchar,datepart(hour,Nonprodtime1)),2) + ' hr ' +  right('00' + convert(nvarchar(2),datepart(minute,Nonprodtime1)),2) + ' min '
		end as NonProductionTime,round(NonProdEff,0) as NonProdEff,
		case when right('00'+ convert(nvarchar,datepart(hour,Loadunload1)),2)= '00' and right('00' + convert(nvarchar(2),datepart(minute,Loadunload1)),2) = '00' then ''
		when right('00'+ convert(nvarchar,datepart(hour,Loadunload1)),2)= '00' then  right('00' + convert(nvarchar(2),datepart(minute,Loadunload1)),2) + ' min ' 
		when right('00' + convert(nvarchar(2),datepart(minute,Loadunload1)),2) = '00' then right('00'+ convert(nvarchar,datepart(hour,Loadunload1)),2) + ' hr '
		else right('00'+ convert(nvarchar,datepart(hour,Loadunload1)),2) + ' hr ' +  right('00' + convert(nvarchar(2),datepart(minute,Loadunload1)),2) + ' min '
		end as Loadunload,
		case when right('00'+ convert(nvarchar,datepart(hour,MachineStoppage1)),2)= '00' and right('00' + convert(nvarchar(2),datepart(minute,MachineStoppage1)),2) = '00' then ''
		when right('00'+ convert(nvarchar,datepart(hour,MachineStoppage1)),2)= '00' then  right('00' + convert(nvarchar(2),datepart(minute,MachineStoppage1)),2) + ' min ' 
		when right('00' + convert(nvarchar(2),datepart(minute,MachineStoppage1)),2) = '00' then right('00'+ convert(nvarchar,datepart(hour,MachineStoppage1)),2) + ' hr '
		else right('00'+ convert(nvarchar,datepart(hour,MachineStoppage1)),2) + ' hr ' +  right('00' + convert(nvarchar(2),datepart(minute,MachineStoppage1)),2) + ' min '
	    end as MachineStoppages,
		ActualParts as NumberOfCycles
		from #Finaldata 
End

END
