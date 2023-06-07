/****** Object:  Procedure [dbo].[s_GetMachineUptimeDowntimeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--s_GetMachineUptimeDowntimeDetails '2019-01-01 06:30:00 AM','2019-01-20 03:00:00 PM','A','CNC-01,CNC-10','GNA Axle II','',''
--s_GetMachineUptimeDowntimeDetails '2019-01-01 06:30:00 AM','2019-01-20 03:00:00 PM','A','''CNC-01''','GNA Axle II','',''
--s_GetMachineUptimeDowntimeDetails '2013-01-24 06:00:00 AM','2013-01-29 06:00:00 AM','','','CNC Lathe','daywisecockpit'
--s_GetMachineUptimeDowntimeDetails '2013-01-21 06:30:00 AM','2013-01-22 03:00:00 PM','','''ACE VTL-02'',''ACE VTL-01''','',''
--s_GetMachineUptimeDowntimeDetails '2019-03-01 06:30:00 AM','2019-03-05 06:00:00 PM','','','','',''
-- s_GetMachineUptimeDowntimeDetails '2020-02-24 06:00:00','2020-02-24 14:00:00','','MAKINO 1140,MAKINO 1141','','',''
CREATE        PROCEDURE [dbo].[s_GetMachineUptimeDowntimeDetails]
	@StartTime datetime ,
	@EndTime datetime,
	@shift nvarchar(20),
	@Machineid nvarchar(500),
	@plantid nvarchar(50),
	@param nvarchar(20)='', --ER0287
	@Groupid as nvarchar(50)=''
AS
BEGIN

CREATE TABLE #Machineupdowntime
(

	shiftdate datetime,
	shiftname nvarchar(20),
	shiftstart datetime,
	shiftend datetime,
	Plantid nvarchar(50),
	MachineID nvarchar(50),
	Starttime datetime,
	Endtime datetime,
	[Value] float,
	Color nvarchar(10),
	dcode nvarchar(50),
	DownReason nvarchar(50)
)

Create table #PlannedDownTimes
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	PStartTime DateTime,
	PEndTime DateTime,
	shiftdate datetime,
	shiftname nvarchar(20),
	shiftstart datetime,
	shiftend datetime,
	DownReason nvarchar(50)

)

Create table #PlannedDownTimesday
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	PStartTime DateTime,
	PEndTime DateTime,
	StartTime DateTime,
	EndTime DateTime
)

CREATE TABLE #PLD
(
	shiftdate datetime,
	shiftname nvarchar(20),
	shiftstart datetime,
	shiftend datetime,
	PStartTime DateTime,
	PEndTime DateTime,
	MachineID nvarchar(50),
	Starttime datetime,
	Endtime datetime,
	[Value] float,
	Color nvarchar(10),
	DownReason nvarchar(50)

)

CREATE TABLE #MLPLD
(
	shiftdate datetime,
	shiftname nvarchar(20),
	shiftstart datetime,
	shiftend datetime,
	PStartTime DateTime,
	PEndTime DateTime,
	MachineID nvarchar(50),
	Starttime datetime,
	Endtime datetime,
	threshold bigint,
	PPDT bigint,
	DownReason nvarchar(50)

)


create table #shiftdetails
(
	shiftdate datetime,
	shiftname nvarchar(20),
	shiftstart datetime,
	shiftend datetime

)

create table #MShift
(
	shiftdate datetime,
	shiftname nvarchar(20),
	shiftstart datetime,
	shiftend datetime,
	MachineID nvarchar(50),
	Minterfaceid nvarchar(10)
)

create table #ICD
(
	shiftdate datetime,
	shiftname nvarchar(20),
	shiftstart datetime,
	shiftend datetime,
	MachineID nvarchar(50),
	Minterfaceid nvarchar(10),
	Starttime datetime,
	Endtime datetime,
	[Value] float,
	Color nvarchar(10),
	DownReason nvarchar(50)
)

CREATE TABLE #cockpitdata
(

	shiftdate datetime,
	shiftname nvarchar(20),
	shiftstart datetime,
	shiftend datetime,
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	Totaltime float,
	Runtime float,
	Downtime Float,
	Managementloss Float,
	MLDown float,
	PDT Float,
	Cyclecount Float
)

CREATE TABLE #cockpitdataDaywise
(
	MachineID nvarchar(50),
	machineinterface nvarchar(50),
	Totaltime float,
	UtilisedTime float,
	Downtime Float,
	Managementloss Float,
	MLDown float,
	PDT Float,
	Cyclecount Float
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


declare @strsql as nvarchar(4000)
DECLARE @strmachine nvarchar(2000)
DECLARE @StrPlantID NVARCHAR(200)      
Declare @StrGroupid as nvarchar(255) 

SELECT  @strsql=''
SELECT @strmachine=''
SELECT @StrPlantID=''
Select @StrGroupid=''  

if isnull(@PlantID,'')<>''
begin
	select @StrPlantID=' AND (P.PlantID =N'''+@PlantID+''')'
end

--If @machineid<>''
--begin
----	--select @strmachine=' AND (M.machineid =N'''+@MachineID+''')'
--	select @strmachine=' AND ( M.machineid in (' + @MachineID + '))'
--end
DECLARE @joined NVARCHAR(500)--ER0210  
select @joined = coalesce(@joined + ',''', '''')+item+'''' from [SplitStrings](@machineid, ',')     
if @joined = ''''''  
set @joined = ''  

If @machineid<>''
begin
--select @strmachine = coalesce(@strmachine + ',''', '''')+item+'''' from [SplitStrings](@machineid, ',') 
--print @strmachine
--select @strmachine=' AND (M.machineid in (' + (Stuff(@strmachine, 1, 1, '')) + '))'
select @strmachine= ' and ( M.machineid in (' + @joined + '))'
End 

If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( PlantMachineGroups.GroupID = N''' + @GroupID + ''')'  
End 

IF  isnull(@shift,'')<> ''
BEGIN
		Insert into #shiftdetails
		exec [dbo].[s_GetShiftTime] @starttime,@shift
END
ELSE
BEGIN
		Insert into #shiftdetails
		exec [dbo].[s_GetShiftTime] @starttime,''
END



Declare @T_ST AS Datetime
Declare @T_ED AS Datetime 

Select @T_ST=min(shiftstart) from #shiftdetails
Select @T_ED=max(shiftend) from #shiftdetails 

  
Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
select @strsql = @strsql + ' From  AutoData  where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'  
print @strsql  
exec (@strsql)  


If @param = ''
Begin

		--To Get Utilised Time Details.
		SET @strSql = ''
		select @strsql = @strsql + 'Insert into #Machineupdowntime(Plantid,MachineID,Starttime,Endtime,[Value],Color,shiftdate,
			shiftname,shiftstart,shiftend)
			select P.Plantid,M.Machineid,case when A.msttime< SD.shiftstart then SD.shiftstart else A.msttime end as Starttime,
			case when A.ndtime>SD.shiftend then SD.shiftend else A.ndtime end as endtime,
			''1'',''Green'',
			SD.shiftdate,SD.shiftname,SD.shiftstart,SD.shiftend
			from #T_autodata A 
			inner join Machineinformation M on M.interfaceid=A.mc
			inner join plantmachine P on P.machineid=M.machineid 
			LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 
			cross join (select shiftdate,shiftname,shiftstart,shiftend from #shiftdetails
			where shiftstart<getdate()) SD
			where M.tpmtrakenabled=1 and (A.datatype=1)
			and 
			((A.msttime>= SD.shiftstart and A.ndtime<=SD.shiftend) or
			(A.msttime< SD.shiftstart and A.ndtime> SD.shiftstart and A.ndtime<=SD.shiftend) or
			(A.msttime>= SD.shiftstart and A.msttime< SD.shiftend  and A.ndtime> SD.shiftend) or
			(A.msttime< SD.shiftstart and A.ndtime>SD.shiftend))'
		select @strsql = @strsql + @StrPlantID + @strmachine + @StrGroupid
		select @strsql = @strsql + ' order by M.machineid,A.msttime'
		print @strsql
		exec(@strsql)

		--To get Downtime Details
		SET @strSql = ''
		select @strsql = @strsql + 'Insert into #Machineupdowntime(Plantid,MachineID,Starttime,Endtime,[Value],Color,shiftdate,
			shiftname,shiftstart,shiftend,DownReason)
			select P.Plantid,M.Machineid,case when A.msttime< SD.shiftstart then SD.shiftstart else A.msttime end as Starttime,
			case when A.ndtime>SD.shiftend then SD.shiftend else A.ndtime end as endtime,
			''0'',''Red'',
			SD.shiftdate,SD.shiftname,SD.shiftstart,SD.shiftend,ISNULL(D.Downid,'''')
			from #T_autodata A 
			inner join Machineinformation M on M.interfaceid=A.mc
			inner join plantmachine P on P.machineid=M.machineid 
			--inner join downcodeinformation D on D.interfaceid=A.dcode -- Anjana Commented inner join 
			LEFT join downcodeinformation D on D.interfaceid=A.dcode 
			LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 
			cross join (select shiftdate,shiftname,shiftstart,shiftend from #shiftdetails
			where shiftstart<getdate()) SD
			where M.tpmtrakenabled=1 and (A.datatype=2) 
			----and (D.availeffy = 0) 
			and 
			((A.msttime>= SD.shiftstart and A.ndtime<=SD.shiftend) or
			(A.msttime< SD.shiftstart and A.ndtime> SD.shiftstart and A.ndtime<=SD.shiftend) or
			(A.msttime>= SD.shiftstart and A.msttime< SD.shiftend  and A.ndtime> SD.shiftend) or
			(A.msttime< SD.shiftstart and A.ndtime>SD.shiftend))'
		select @strsql = @strsql + @StrPlantID + @strmachine + @StrGroupid
		select @strsql = @strsql + ' order by M.machineid,A.msttime'
		print @strsql
		exec(@strsql)

		update #Machineupdowntime set color = 'White' where shiftend < endtime


		select * from #Machineupdowntime order by machineid,starttime
		Return
END


If @param='ML'
Begin
		
		--To get Management Loss Details
		SET @strSql = ''
		select @strsql = @strsql + 'Insert into #Machineupdowntime(Plantid,MachineID,Starttime,Endtime,[Value],Color,shiftdate,
			shiftname,shiftstart,shiftend,dcode,DownReason)
			select P.Plantid,M.Machineid,case when A.msttime< SD.shiftstart then SD.shiftstart else A.msttime end as Starttime,
			case when A.ndtime>SD.shiftend then SD.shiftend else A.ndtime end as endtime,
			''2'',''Yellow'',
			SD.shiftdate,SD.shiftname,SD.shiftstart,SD.shiftend,A.dcode,ISNULL(D.Downid,'''')
			from #T_autodata A 
			inner join Machineinformation M on M.interfaceid=A.mc
			inner join plantmachine P on P.machineid=M.machineid 
			inner join downcodeinformation D on D.interfaceid=A.dcode
			LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 
			cross join (select shiftdate,shiftname,shiftstart,shiftend from #shiftdetails
			where shiftstart<getdate()) SD
			where M.tpmtrakenabled=1 and (A.datatype=2) and (D.availeffy = 1) 
			and
			((A.msttime>= SD.shiftstart and A.ndtime<=SD.shiftend) or
			(A.msttime< SD.shiftstart and A.ndtime> SD.shiftstart and A.ndtime<=SD.shiftend) or
			(A.msttime>= SD.shiftstart and A.msttime< SD.shiftend  and A.ndtime> SD.shiftend) or
			(A.msttime< SD.shiftstart and A.ndtime>SD.shiftend))'
		select @strsql = @strsql + @StrPlantID + @strmachine  + @StrGroupid
		select @strsql = @strsql + ' order by M.machineid,A.msttime'
		print @strsql
		exec(@strsql)

		--If Downtime is 6AM to 8AM then ML may be 6AM to 7AM remaining time account for Downtime.
		update #Machineupdowntime set Endtime = T.endtime from
		(select Plantid,machineid,starttime,case when datediff(s,starttime,endtime)>ISNULL(D.Threshold,0) AND ISNULL(D.Threshold,0)>0 
		THEN dateadd(s,(D.Threshold),starttime)
		ELSE endtime end as endtime,shiftstart,shiftend
		from #Machineupdowntime inner join downcodeinformation D on D.interfaceid=#Machineupdowntime.dcode
		where D.availeffy = 1)T inner join #Machineupdowntime on #Machineupdowntime.plantid=T.plantid and #Machineupdowntime.machineid=T.machineid
		and #Machineupdowntime.starttime=T.starttime and #Machineupdowntime.shiftend=T.shiftend and #Machineupdowntime.shiftstart=T.shiftstart
		
		
		select * from #Machineupdowntime order by machineid,starttime
		Return

END



If @param='ICD'
Begin


			SET @strSql = ''
			SET @strSql = 'Insert into #MShift
				SELECT SD.shiftdate,SD.shiftname,SD.shiftstart,SD.shiftend,
				M.machineid,M.interfaceid FROM MachineInformation M 
				inner join plantmachine P on M.machineid=P.machineid
				LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 
			    cross join (select shiftdate,shiftname,shiftstart,shiftend from #shiftdetails)SD
				WHERE M.tpmtrakenabled=1'
			select @strsql = @strsql + @StrPlantID + @strmachine + @StrGroupid
			select @strsql = @strsql + ' ORDER BY M.Machineid'
			EXEC(@strSql)

			--To get InCycleDown for Type 2 Record
			insert into #ICD
			Select T.shiftdate,T.shiftname,T.shiftstart,T.shiftend,T.machineid,AutoData.mc,
			case when autodata.sttime<T.shiftstart then T.shiftstart else autodata.sttime end,
			case when autodata.ndtime>T.shiftend then T.shiftend else autodata.ndtime end,'3','Maroon',D.downid From #T_autodata AutoData  INNER Join
				(Select mc,machineid,Sttime,NdTime,shiftstart,shiftend,shiftdate,shiftname From #T_autodata AutoData 
					inner join #MShift T1 ON T1.Minterfaceid=Autodata.mc
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(msttime < shiftstart)And (ndtime > shiftstart) AND (ndtime <= shiftend)
				 ) as T on t.mc=autodata.mc
			left join downcodeinformation D on D.interfaceid=autodata.dcode
			Where AutoData.DataType=2
			And ( autodata.Sttime > T.Sttime )
			And ( autodata.ndtime <  T.ndtime )
			AND ( autodata.ndtime >  T.shiftstart )

			--To get InCycleDown for Type 3 Record
			insert into #ICD
			Select T.shiftdate,T.shiftname,T.shiftstart,T.shiftend,T.machineid,AutoData.mc,
			case when autodata.sttime<T.shiftstart then T.shiftstart else autodata.sttime end,
			case when autodata.ndtime>T.shiftend then T.shiftend else autodata.ndtime end,'3','Maroon',D.downid From #T_autodata AutoData  INNER Join
				(Select mc,machineid,Sttime,NdTime,shiftstart,shiftend,shiftdate,shiftname From #T_autodata AutoData 
					inner join #MShift T1 ON T1.Minterfaceid =Autodata.mc
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(sttime >= shiftstart)And (ndtime >shiftend) and (sttime< shiftend)
			   ) as T
			ON AutoData.mc=T.mc
			left join downcodeinformation D on D.interfaceid=autodata.dcode
			Where AutoData.DataType=2
			And (T.Sttime < autodata.sttime  )
			And ( T.ndtime >  autodata.ndtime)
			AND (autodata.sttime  <  T.shiftend)

			--To get InCycleDown for Type 4 Record
			insert into #ICD
			Select T.shiftdate,T.shiftname,T.shiftstart,T.shiftend,T.machineid,AutoData.mc,
			case when autodata.sttime<T.shiftstart then T.shiftstart else autodata.sttime end,
			case when autodata.ndtime>T.shiftend then T.shiftend else autodata.ndtime end,'3','Maroon',D.downid From #T_autodata AutoData  INNER Join
				(Select mc,machineid,Sttime,NdTime,shiftstart,shiftend,shiftdate,shiftname From #T_autodata AutoData 
					inner join #MShift T1 ON T1.Minterfaceid =Autodata.mc
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(msttime < shiftstart)And (ndtime >shiftend)
				) as T
			ON AutoData.mc=T.mc
			left join downcodeinformation D on D.interfaceid=autodata.dcode
			Where AutoData.DataType=2
			And (T.Sttime < autodata.sttime  )
			And ( T.ndtime >  autodata.ndtime)
			AND (autodata.ndtime  >  T.shiftstart)
			AND (autodata.sttime  <  T.shiftend)

			select * from #ICD order by machineid,starttime 
			return
END


If @param='PlannedDT'
Begin
	
			--General temp table to get PlannedDowns for the selected shifts.
			SET @strSql = ''
			SET @strSql = 'Insert into #PlannedDownTimes
				SELECT Machine,InterfaceID,
					CASE When StartTime<SD.shiftstart Then SD.shiftstart Else StartTime End As StartTime,
					CASE When EndTime>SD.shiftend Then SD.shiftend Else EndTime End As EndTime,
				SD.shiftdate,SD.shiftname,SD.shiftstart,SD.shiftend,DownReason
				FROM PlannedDownTimes 
				inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
				inner join plantmachine P on M.machineid=P.machineid
				LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 
			    cross join (select shiftdate,shiftname,shiftstart,shiftend from #shiftdetails
				) SD
				WHERE PDTstatus =1 and M.tpmtrakenabled=1 and (
				(StartTime >= SD.shiftstart AND EndTime <=SD.shiftend)
				OR ( StartTime < SD.shiftstart  AND EndTime <= SD.shiftend AND EndTime > SD.shiftstart )
				OR ( StartTime >= SD.shiftstart   AND StartTime <SD.shiftend AND EndTime > SD.shiftend)
				OR ( StartTime < SD.shiftstart  AND EndTime > SD.shiftend)) '
			select @strsql = @strsql + @StrPlantID + @strmachine + @StrGroupid
			select @strsql = @strsql + ' ORDER BY Machine,StartTime'
			print @strsql
			EXEC(@strSql)


			--General table having shift details.
			SET @strSql = ''
			SET @strSql = 'Insert into #MShift
				SELECT SD.shiftdate,SD.shiftname,SD.shiftstart,SD.shiftend,
				M.machineid,M.interfaceid FROM MachineInformation M 
				inner join plantmachine P on M.machineid=P.machineid
				LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 
			    cross join (select shiftdate,shiftname,shiftstart,shiftend from #shiftdetails)SD
				WHERE M.tpmtrakenabled=1'
			select @strsql = @strsql + @StrPlantID + @strmachine + @StrGroupid
			select @strsql = @strsql + ' ORDER BY M.Machineid'
			EXEC(@strSql)


			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
			BEGIN

				
				--get the utilised time overlapping with PDT 
				Insert into #PLD(shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,MachineID,starttime,endtime,[value],color,DownReason)
				SELECT T.shiftdate,T.shiftname,T.shiftstart,T.shiftend,T.Pstarttime,T.Pendtime,
				T.MachineID,CASE When autodata.msttime<T.Pstarttime Then T.Pstarttime Else autodata.msttime End As StartTime,
				CASE When autodata.ndtime>T.Pendtime Then T.Pendtime Else autodata.ndtime End As endtime,'0.5','Blue',T.DownReason
				From #T_autodata AutoData  CROSS jOIN 
				(select shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,MachineInterface,MachineID,DownReason from #PlannedDownTimes) T
				WHERE autodata.DataType=1 And T.MachineInterface=AutoData.mc AND
				((autodata.msttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime)
				OR ( autodata.msttime < T.PStartTime  AND autodata.ndtime <= T.PEndTime AND autodata.ndtime > T.PStartTime )
				OR ( autodata.msttime >= T.PStartTime   AND autodata.msttime <T.PEndTime AND autodata.ndtime > T.PEndTime )
				OR ( autodata.msttime < T.PStartTime  AND autodata.ndtime > T.PEndTime))
				AND
				((autodata.msttime >= T.shiftstart  AND autodata.ndtime <=T.shiftend)
				OR ( autodata.msttime < T.shiftstart  AND autodata.ndtime <= T.shiftend AND autodata.ndtime > T.shiftstart)
				OR ( autodata.msttime >= T.shiftstart   AND autodata.msttime <T.shiftend AND autodata.ndtime > T.shiftend )
				OR ( autodata.msttime < T.shiftstart  AND autodata.ndtime > T.shiftend))


				/* Fetching Down Records from  Production Cycle  */
				---Handle intearction between ICD and PDT for type 1 production record for the selected time period.
				Insert into #PLD(shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,MachineID,starttime,endtime,[value],color,DownReason)
				Select T.shiftdate,T.shiftname,T.shiftstart,T.shiftend,T.starttime,T.endtime,
				T.MachineID,CASE When autodata.sttime<T.StartTime Then T.StartTime Else autodata.sttime End As PStartTime,
				CASE When autodata.ndtime>T.EndTime Then T.EndTime Else autodata.ndtime End As Pendtime,'0.5','Blue',T.DownReason
				From #T_autodata AutoData  CROSS jOIN (select shiftdate,shiftname,shiftstart,shiftend,PStartTime as starttime,
			    PEndTime as endtime,MachineInterface,machineid,DownReason from #PlannedDownTimes) T  INNER Join 
					(Select mc,Sttime,NdTime,shiftstart as starttime  From #T_autodata AutoData  
					inner join #MShift P on P.Minterfaceid=autodata.mc
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
						(msttime >= shiftstart) AND (ndtime <= shiftend)) as T1
				ON AutoData.mc=T1.mc and T1.starttime=T.shiftstart  
				Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
				And (( autodata.Sttime > T1.Sttime )
				And ( autodata.ndtime <  T1.ndtime ))
				AND
				((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
				or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
				or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
				or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )

				/* If production  Records of TYPE-2*/
				Insert into #PLD(shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,MachineID,starttime,endtime,[value],color,DownReason)
				select T.shiftdate,T.shiftname,T.shiftstart,T.shiftend,T.starttime,T.endtime,
				T.MachineID,CASE When autodata.sttime<T.StartTime Then T.StartTime Else autodata.sttime End As PStartTime,
				CASE When autodata.ndtime>T.endtime Then T.endtime Else autodata.ndtime End As Pendtime,'0.5','Blue',T.DownReason
				From #T_autodata AutoData  CROSS jOIN (select shiftdate,shiftname,shiftstart,shiftend,PStartTime as starttime,
			    PEndTime as endtime,MachineInterface,machineid,DownReason from #PlannedDownTimes) T INNER Join 
					(Select mc,Sttime,NdTime,shiftstart as starttime From #T_autodata AutoData  inner join #MShift P on P.Minterfaceid=autodata.mc
						Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
						(msttime < shiftstart)And (ndtime > shiftstart) AND (ndtime <=shiftend)) as T1
				ON AutoData.mc=T1.mc and T1.starttime=T.shiftstart  
				Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
				And (( autodata.Sttime > T1.Sttime )
				And ( autodata.ndtime <  T1.ndtime )
				AND ( autodata.ndtime >  T1.StartTime ))
				AND
				(( T.StartTime >= T1.StartTime )
				And ( T.StartTime <  T1.ndtime ))


				/* If production Records of TYPE-3*/
				Insert into #PLD(shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,MachineID,starttime,endtime,[value],color,DownReason)
				select T.shiftdate,T.shiftname,T.shiftstart,T.shiftend,T.starttime,T.endtime,
				T.MachineID,CASE When autodata.sttime<T.starttime Then T.starttime Else autodata.sttime End As PStartTime,
				CASE When autodata.ndtime>T.endtime Then T.endtime Else autodata.ndtime End As Pendtime,'0.5','Blue',T.DownReason
				From #T_autodata AutoData  CROSS jOIN (select shiftdate,shiftname,shiftstart,shiftend,PStartTime as starttime,
			    PEndTime as endtime,MachineInterface,machineid,DownReason from #PlannedDownTimes) T INNER Join 
					(Select mc,Sttime,NdTime,shiftstart as StartTime,shiftend as EndTime From #T_autodata AutoData  
					inner join #MShift P on P.Minterfaceid=autodata.mc
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(sttime >= shiftstart)And (ndtime > shiftend) and autodata.sttime < shiftend) as T1
				ON AutoData.mc=T1.mc and T1.StartTime=T.shiftstart
				Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
				And ((T1.Sttime < autodata.sttime  )
				And ( T1.ndtime >  autodata.ndtime)
				AND (autodata.sttime  <  T1.EndTime))
				AND
				(( T.EndTime > T1.Sttime )
				And ( T.EndTime <=T1.EndTime ) )


				/* If production Records of TYPE-4*/
				Insert into #PLD(shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,MachineID,starttime,endtime,[value],color,DownReason)
				select T.shiftdate,T.shiftname,T.shiftstart,T.shiftend,T.starttime,T.endtime,
				T.MachineID,CASE When autodata.sttime<T.starttime Then T.starttime Else autodata.sttime End As PStartTime,
				CASE When autodata.ndtime>T.endtime Then T.endtime Else autodata.ndtime End As Pendtime,'0.5','Blue',T.DownReason
				From #T_autodata AutoData  CROSS jOIN (select shiftdate,shiftname,shiftstart,shiftend,PStartTime as starttime,
			    PEndTime as endtime,MachineInterface,machineid,DownReason from #PlannedDownTimes) T INNER Join --ER0324 Added
					(Select mc,Sttime,NdTime,shiftstart as StartTime,shiftend as EndTime From #T_autodata AutoData  
					 inner join #MShift P on P.Minterfaceid=autodata.mc
						Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
						(msttime < shiftstart)And (ndtime > shiftend)) as T1
				ON AutoData.mc=T1.mc and T1.StartTime=T.shiftstart
				Where AutoData.DataType=2 and T.MachineInterface=autodata.mc
				And ( (T1.Sttime < autodata.sttime  )
					And ( T1.ndtime >  autodata.ndtime)
					AND (autodata.ndtime  >  T1.StartTime)
					AND (autodata.sttime  <  T1.EndTime))
				AND
				(( T.StartTime >=T1.StartTime)
				And ( T.EndTime <=T1.EndTime ))

			END


			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
			BEGIN


					--Get the downtime overlapping with PDT
					Insert into #PLD(shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,MachineID,starttime,endtime,[value],color,DownReason)
					SELECT T.shiftdate,T.shiftname,T.shiftstart,T.shiftend,T.Pstarttime,T.Pendtime,
					T.MachineID,CASE When autodata.msttime<T.Pstarttime Then T.Pstarttime Else autodata.msttime End As PStartTime,
					CASE When autodata.ndtime>T.PEndTime Then T.PEndTime Else autodata.ndtime End As Pendtime,'0.5','Blue',T.DownReason
					From #T_autodata AutoData  INNER JOIN DownCodeInformation D ON AutoData.DCode = D.InterfaceID
					CROSS jOIN 
					(select shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,MachineInterface,MachineID,DownReason from #PlannedDownTimes) T
					WHERE autodata.DataType=2 And T.MachineInterface=AutoData.mc AND (D.availeffy = 0) AND
					((autodata.msttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime)
					OR ( autodata.msttime < T.PStartTime  AND autodata.ndtime <= T.PEndTime AND autodata.ndtime > T.PStartTime )
					OR ( autodata.msttime >= T.PStartTime   AND autodata.msttime <T.PEndTime AND autodata.ndtime > T.PEndTime )
					OR ( autodata.msttime < T.PStartTime  AND autodata.ndtime > T.PEndTime))
					AND
					((autodata.msttime >= T.shiftstart  AND autodata.ndtime <=T.shiftend)
					OR ( autodata.msttime < T.shiftstart  AND autodata.ndtime <= T.shiftend AND autodata.ndtime > T.shiftstart)
					OR ( autodata.msttime >= T.shiftstart   AND autodata.msttime <T.shiftend AND autodata.ndtime > T.shiftend )
					OR ( autodata.msttime < T.shiftstart  AND autodata.ndtime > T.shiftend))



					--To handle interaction between PDT and Management Loss.
					Insert into #MLPLD(shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,MachineID,starttime,endtime,threshold,PPDT,DownReason)
					select T1.shiftdate,T1.shiftname,T1.StartShift,T1.Endshift,T2.Pstarttime,T2.Pendtime,
					T1.machineid,T1.sttime,T1.ndtime,T1.Threshold,T2.PPDT,T2.DownReason
					from
					(select id,mc,comp,opn,opr,D.threshold,S.shiftdate as shiftdate,S.shiftname as shiftname,S.shiftstart as StartShift,S.shiftend as Endshift,
					case when autodata.msttime<S.shiftstart then S.shiftstart else msttime END as sttime,
					case when ndtime>S.shiftend then S.shiftend else ndtime END as ndtime,machineid
					From #T_autodata AutoData  
					inner join downcodeinformation D
					on autodata.dcode=D.interfaceid inner join #MShift S on autodata.mc=S.Minterfaceid
					where autodata.datatype=2 AND
					(
					(autodata.msttime>=S.shiftstart  and  autodata.ndtime<=S.shiftend)
					OR (autodata.msttime<S.shiftstart and  autodata.ndtime>S.shiftstart and autodata.ndtime<=S.shiftend)
					OR (autodata.msttime>=S.shiftstart  and autodata.msttime<S.shiftend  and autodata.ndtime>S.shiftend)
					OR (autodata.msttime<S.shiftstart and autodata.ndtime>S.shiftend )
					) AND (D.availeffy = 1))
					 as T1 	
					left outer join
					(SELECT T.shiftstart  as intime, autodata.id,
					sum(CASE
					WHEN autodata.msttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime  THEN (autodata.loadunload)
					WHEN ( autodata.msttime < T.PStartTime  AND autodata.ndtime <= T.PEndTime  AND autodata.ndtime > T.PStartTime ) THEN DateDiff(second,T.PStartTime,autodata.ndtime)
					WHEN ( autodata.msttime >= T.PStartTime   AND autodata.msttime <T.PEndTime  AND autodata.ndtime > T.PEndTime  ) THEN DateDiff(second,autodata.msttime,T.PEndTime )
					WHEN ( autodata.msttime < T.PStartTime  AND autodata.ndtime > T.PEndTime ) THEN DateDiff(second,T.PStartTime,T.PEndTime )
					END ) as PPDT,Pstarttime,PEndtime,T.DownReason
					From #T_autodata AutoData 
					CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
					WHERE autodata.DataType=2 and T.MachineInterface=autodata.mc AND
					(
					(autodata.msttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime)
					OR ( autodata.msttime < T.PStartTime  AND autodata.ndtime <= T.PEndTime AND autodata.ndtime > T.PStartTime )
					OR ( autodata.msttime >= T.PStartTime   AND autodata.msttime <T.PEndTime AND autodata.ndtime > T.PEndTime )
					OR ( autodata.msttime < T.PStartTime  AND autodata.ndtime > T.PEndTime)
					)
					AND (downcodeinformation.availeffy = 1) group by autodata.id,T.Shiftstart,Pstarttime,PEndtime,T.DownReason ) as T2 on T1.id=T2.id  and T1.StartShift=T2.intime 


					Insert into #PLD(shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,MachineID,starttime,endtime,[value],color,DownReason)
					select shiftdate,shiftname,shiftstart,shiftend,Pstarttime,Pendtime,
					MachineID,starttime,case when DateDiff(second,starttime,endtime)-isnull(PPDT,0)> isnull(Threshold ,0) and isnull(Threshold ,0) > 0
					then dateadd(second,threshold,starttime)
					when DateDiff(second,starttime,endtime)-isnull(PPDT,0)= 0 then endtime
					when isnull(PPDT,0)= 0 then endtime
					else Dateadd(second,isnull(PPDT,0),starttime) End ,'0.5','Blue',DownReason
					FROM #MLPLD
			END


			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' OR (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
			begin
				select * from #PLD where Pstarttime is not null order by machineid,starttime
				return
		    end
END

If @param='shiftwiseCockpit'
Begin


		
			SET @strSql = ''
			SET @strSql = 'Insert into #MShift
				SELECT SD.shiftdate,SD.shiftname,SD.shiftstart,SD.shiftend,
				M.machineid,M.interfaceid FROM MachineInformation M 
				inner join plantmachine P on M.machineid=P.machineid
				LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 
			    cross join (select shiftdate,shiftname,shiftstart,shiftend from #shiftdetails)SD
				WHERE M.tpmtrakenabled=1'
			select @strsql = @strsql + @StrPlantID + @strmachine + @StrGroupid
			select @strsql = @strsql + ' ORDER BY M.Machineid'
			EXEC(@strSql)


				--General temp table to get PlannedDowns for the selected shifts.
				SET @strSql = ''
				SET @strSql = 'Insert into #PlannedDownTimes
					SELECT Machine,InterfaceID,
						CASE When StartTime<SD.shiftstart Then SD.shiftstart Else StartTime End As StartTime,
						CASE When EndTime>SD.shiftend Then SD.shiftend Else EndTime End As EndTime,
					SD.shiftdate,SD.shiftname,SD.shiftstart,SD.shiftend
					FROM PlannedDownTimes 
					inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
					inner join plantmachine P on M.machineid=P.machineid
					LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 
			        cross join (select shiftdate,shiftname,shiftstart,shiftend from #shiftdetails
					) SD
					WHERE PDTstatus =1 and M.tpmtrakenabled=1 and (
					(StartTime >= SD.shiftstart AND EndTime <=SD.shiftend)
					OR ( StartTime < SD.shiftstart  AND EndTime <= SD.shiftend AND EndTime > SD.shiftstart )
					OR ( StartTime >= SD.shiftstart   AND StartTime <SD.shiftend AND EndTime > SD.shiftend)
					OR ( StartTime < SD.shiftstart  AND EndTime > SD.shiftend)) '
				select @strsql = @strsql + @StrPlantID + @strmachine + @StrGroupid
				select @strsql = @strsql + ' ORDER BY Machine,StartTime'
				print @strsql
				EXEC(@strSql)

			Insert into #cockpitdata
			select shiftdate,shiftname,shiftstart,shiftend,machineid,Minterfaceid
			,0,0,0,0,0,0,0 from #MShift

			UPDATE #cockpitdata SET Runtime = isnull(Runtime,0) + isNull(t2.cycle,0)
			from
			(select      mc,
				sum(case when ( (autodata.msttime>=S.shiftstart) and (autodata.ndtime<=S.shiftend)) then  (cycletime+loadunload)
					 when ((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.shiftstart)and (autodata.ndtime<=S.shiftend)) then DateDiff(second, S.shiftstart, ndtime)
					 when ((autodata.msttime>=S.shiftstart)and (autodata.msttime<S.shiftend)and (autodata.ndtime>S.shiftend)) then DateDiff(second, mstTime, S.shiftend)
					 when ((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.shiftend)) then DateDiff(second, S.shiftstart, S.shiftend) END ) as cycle,S.shiftstart as ShiftStart
			From #T_autodata AutoData  inner join #cockpitdata S on autodata.mc=S.MachineInterface --ER0324 Added
			where (autodata.datatype=1) AND(( (autodata.msttime>=S.shiftstart) and (autodata.ndtime<=S.shiftend))
			OR ((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.shiftstart)and (autodata.ndtime<=S.shiftend))
			OR ((autodata.msttime>=S.shiftstart)and (autodata.msttime<S.shiftend)and (autodata.ndtime>S.shiftend))
			OR((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.shiftend)))
			group by autodata.mc,S.shiftstart
			) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface
			and t2.ShiftStart=#cockpitdata.shiftstart



			-------For Type2
			UPDATE  #cockpitdata SET Runtime = isnull(Runtime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(
			CASE
				When autodata.sttime <= T1.shiftstart Then datediff(s, T1.shiftstart,autodata.ndtime )
				When autodata.sttime > T1.shiftstart Then datediff(s , autodata.sttime,autodata.ndtime)
			END) as Down,t1.shiftstart as ShiftStart,T1.shiftdate as shiftdate
			From #T_autodata AutoData  INNER Join
				(Select mc,Sttime,NdTime,shiftstart,shiftend,shiftdate From #T_autodata AutoData 
					inner join #cockpitdata ST1 ON ST1.MachineInterface=Autodata.mc
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(msttime < shiftstart)And (ndtime > shiftstart) AND (ndtime <= shiftend)
			) as T1 on t1.mc=autodata.mc
			Where AutoData.DataType=2
			And ( autodata.Sttime > T1.Sttime )
			And ( autodata.ndtime <  T1.ndtime )
			AND ( autodata.ndtime >  T1.shiftstart )
			GROUP BY AUTODATA.mc,T1.shiftstart,T1.shiftdate)AS T2 Inner Join #cockpitdata on t2.mc = #cockpitdata.machineinterface
			and T2.shiftdate = #cockpitdata.shiftdate and t2.ShiftStart=#cockpitdata.shiftstart

			--Type 3
			UPDATE  #cockpitdata SET Runtime = isnull(Runtime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(CASE
				When autodata.ndtime > T1.shiftend Then datediff(s,autodata.sttime, T1.shiftend )
				When autodata.ndtime <=T1.shiftend Then datediff(s , autodata.sttime,autodata.ndtime)
			END) as Down,T1.shiftstart as ShiftStart,T1.shiftdate as shiftdate
			From #T_autodata AutoData  INNER Join
				(Select mc,Sttime,NdTime,shiftstart,shiftend,shiftdate From #T_autodata AutoData 
					inner join #cockpitdata ST1 ON ST1.MachineInterface =Autodata.mc
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(sttime >= ShiftStart)And (ndtime >shiftend) and (sttime< shiftend)
			 ) as T1
			ON AutoData.mc=T1.mc
			Where AutoData.DataType=2
			And (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.sttime  <  T1.shiftend)
			GROUP BY AUTODATA.mc,T1.shiftstart,T1.shiftdate )AS T2 Inner Join #cockpitdata on t2.mc = #cockpitdata.machineinterface
			and t2.shiftdate=#cockpitdata.shiftdate and t2.ShiftStart=#cockpitdata.shiftstart

			--For Type4
			UPDATE  #cockpitdata SET Runtime = isnull(Runtime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(CASE
				When autodata.sttime >= T1.shiftstart AND autodata.ndtime <= T1.shiftend Then datediff(s , autodata.sttime,autodata.ndtime)
				When autodata.sttime < T1.shiftstart And autodata.ndtime >T1.shiftstart AND autodata.ndtime<=T1.shiftend Then datediff(s, T1.shiftstart,autodata.ndtime )
				When autodata.sttime >= T1.shiftstart AND autodata.sttime<T1.shiftend AND autodata.ndtime>T1.shiftend Then datediff(s,autodata.sttime, T1.shiftend )
				When autodata.sttime<T1.shiftstart AND autodata.ndtime>T1.shiftend   Then datediff(s , T1.shiftstart,T1.shiftend)
			END) as Down,T1.shiftstart as ShiftStart,T1.shiftdate as shiftdate
			From #T_autodata AutoData  INNER Join
				(Select mc,Sttime,NdTime,ShiftStart,shiftend,shiftdate From #T_autodata AutoData 
					inner join #cockpitdata ST1 ON ST1.MachineInterface =Autodata.mc
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(msttime < ShiftStart)And (ndtime >shiftend)
				
			 ) as T1
			ON AutoData.mc=T1.mc
			Where AutoData.DataType=2
			And (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.ndtime  >  T1.ShiftStart)
			AND (autodata.sttime  <  T1.shiftend)
			GROUP BY AUTODATA.mc,T1.ShiftStart,T1.shiftdate
			 )AS T2 Inner Join #cockpitdata on t2.mc = #cockpitdata.machineinterface
			and T2.shiftdate = #cockpitdata.shiftdate and t2.ShiftStart=#cockpitdata.ShiftStart

			UPDATE #cockpitdata SET cyclecount = isnull(cyclecount,0) + isNull(t2.Comp,0)
			From
			(
					Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp,T1.shiftstart
					From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn,shiftstart From #T_autodata AutoData 
					inner join #cockpitdata on #cockpitdata.machineinterface=autodata.mc
					where (autodata.ndtime>ShiftStart) and (autodata.ndtime<=shiftend) and (autodata.datatype=1)
					Group By mc,comp,opn,shiftstart) as T1
					inner join #CockpitData on T1.mc = #CockpitData.machineinterface and t1.shiftstart=#CockpitData.shiftstart
					Inner join componentinformation C on T1.Comp = C.interfaceid
					Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
					inner join machineinformation on machineinformation.machineid =O.machineid
					and T1.mc=machineinformation.interfaceid
					GROUP BY mc,T1.shiftstart
			) as T2
			inner join #cockpitdata S  on t2.shiftstart=S.shiftstart  and t2.mc = S.machineinterface


			


			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
			BEGIN
				UPDATE #CockpitData SET cyclecount = ISNULL(cyclecount,0) - ISNULL(T2.comp,0) 
				from(
					select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp,T1.shiftstart as shiftstart
					From (
						select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn,#cockpitdata.shiftstart as shiftstart From #T_autodata AutoData 
						inner join #cockpitdata on #cockpitdata.machineinterface=autodata.mc
						inner JOIN #PlannedDownTimes T on T.MachineInterface = autodata.mc and T.shiftstart=#cockpitdata.shiftstart
						WHERE autodata.DataType=1 
						AND (autodata.ndtime > T.PStartTime  AND autodata.ndtime <=T.PEndTime)
						and (autodata.ndtime > T.shiftstart  AND autodata.ndtime <=T.shiftend)
						Group by mc,comp,opn,#cockpitdata.shiftstart
					) as T1
				inner join #CockpitData on T1.mc = #CockpitData.machineinterface and t1.shiftstart=#CockpitData.shiftstart
				Inner join Machineinformation M on M.interfaceID = T1.mc
				Inner join componentinformation C on T1.Comp=C.interfaceid
				Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
				GROUP BY MC,T1.shiftstart 
				) as T2 inner join #CockpitData on T2.mc = #CockpitData.machineinterface and t2.shiftstart=#CockpitData.shiftstart
			END

			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
			BEGIN
			
					---Get the down times which are not of type Management Loss
					UPDATE #cockpitdata SET downtime = isnull(downtime,0) + isNull(t2.down,0)
					from
					(select      mc,
						sum(case when ( (autodata.msttime>=S.shiftstart) and (autodata.ndtime<=S.shiftend)) then  loadunload
							 when ((autodata.sttime<S.shiftstart)and (autodata.ndtime>S.shiftstart)and (autodata.ndtime<=S.shiftend)) then DateDiff(second, S.shiftstart, ndtime)
							 when ((autodata.msttime>=S.shiftstart)and (autodata.msttime<S.shiftend)and (autodata.ndtime>S.shiftend)) then DateDiff(second, stTime, S.shiftend)
							 when ((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.shiftend)) then DateDiff(second, S.shiftstart, S.shiftend) END ) as down,S.shiftstart as ShiftStart
					   From #T_autodata AutoData  
					   inner join #cockpitdata S on autodata.mc=S.MachineInterface
					   inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
					where (autodata.datatype=2) and 
						  ((autodata.msttime>=S.shiftstart and autodata.ndtime<=S.shiftend)
						  OR(autodata.msttime<S.shiftstart and autodata.ndtime>S.shiftstart and autodata.ndtime<=S.shiftend)
						  OR(autodata.msttime>=S.shiftstart and autodata.msttime<S.shiftend and autodata.ndtime>S.shiftend)
						  OR(autodata.msttime<S.shiftstart and autodata.ndtime>S.shiftend)) 
						  group by autodata.mc,S.shiftstart
					) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface
					and t2.ShiftStart=#cockpitdata.shiftstart
					

					---Management Loss-----
					-- Type 1
					UPDATE #cockpitdata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select      mc,
						sum(CASE
					WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
					ELSE loadunload
					END) loss,S.shiftstart as ShiftStart
					From #T_autodata AutoData  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
					inner join #cockpitdata S on autodata.mc=S.MachineInterface --ER0324 Added
					where (autodata.msttime>=S.shiftstart)
					and (autodata.ndtime<=S.shiftend)
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc,S.shiftstart
					) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface
					and t2.ShiftStart=#cockpitdata.shiftstart

					-- Type 2
					UPDATE #cockpitdata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select      mc,
						sum(CASE
					WHEN DateDiff(second, S.ShiftStart, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
					ELSE DateDiff(second, S.ShiftStart, ndtime)
					end) loss,S.ShiftStart as ShiftStart
					From #T_autodata AutoData  --ER0324 Added
					 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
					inner join #cockpitdata S on autodata.mc=S.MachineInterface
					where (autodata.sttime<S.ShiftStart)
					and (autodata.ndtime>S.ShiftStart)
					and (autodata.ndtime<=S.Shiftend)
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc,S.shiftdate,S.shiftstart
					) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface
					and t2.ShiftStart=#cockpitdata.ShiftStart

					-- Type 3
					UPDATE #cockpitdata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select      mc,
						sum(CASE
					WHEN DateDiff(second, stTime, S.Shiftend)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)ELSE DateDiff(second, stTime, S.Shiftend)
					END) loss,S.ShiftStart as ShiftStart
					From #T_autodata AutoData   --ER0324 Added
					INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
					inner join #cockpitdata S on autodata.mc=S.MachineInterface
					where (autodata.msttime>=S.ShiftStart)
					and (autodata.sttime<S.Shiftend)
					and (autodata.ndtime>S.Shiftend)
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc,S.ShiftStart
					) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface
					and t2.ShiftStart=#cockpitdata.ShiftStart

					-- Type 4
					UPDATE #cockpitdata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select mc,
						sum(CASE
					WHEN DateDiff(second, S.ShiftStart, S.Shiftend)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
					ELSE DateDiff(second, S.ShiftStart, S.Shiftend)
					END) loss,S.ShiftStart as ShiftStart
					From #T_autodata AutoData  
					INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
					inner join #cockpitdata S on autodata.mc=S.MachineInterface
					where autodata.msttime<S.ShiftStart
					and autodata.ndtime>S.Shiftend
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc,S.ShiftStart
					) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface
					and t2.ShiftStart=#cockpitdata.ShiftStart
			end


			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
			BEGIN
				
						--get the utilised time overlapping with PDT and negate it from UtilisedTime
						UPDATE  #cockpitdata SET Runtime = isnull(Runtime,0) - isNull(t2.PlanDT,0),PDT=isnull(PDT,0) + isNull(t2.PlanDT,0)
						from( select T.shiftstart as intime,T.Machineid as machine,sum (CASE
						WHEN (autodata.msttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime)  THEN (cycletime+loadunload)
						WHEN ( autodata.msttime < T.PStartTime  AND autodata.ndtime <= T.PEndTime  AND autodata.ndtime > T.PStartTime ) THEN DateDiff(second,T.PStartTime,autodata.ndtime)
						WHEN ( autodata.msttime >= T.PStartTime   AND autodata.msttime <T.PEndTime  AND autodata.ndtime > T.PEndTime  ) THEN DateDiff(second,autodata.msttime,T.PEndTime )
						WHEN ( autodata.msttime < T.PStartTime  AND autodata.ndtime > T.PEndTime ) THEN DateDiff(second,T.PStartTime,T.PEndTime )
						END ) as PlanDT
						From #T_autodata AutoData  CROSS jOIN #PlannedDownTimes T --ER0324 Added
						WHERE autodata.DataType=1   and T.MachineInterface=autodata.mc AND(
						(autodata.msttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime)
						OR ( autodata.msttime < T.PStartTime  AND autodata.ndtime <= T.PEndTime AND autodata.ndtime > T.PStartTime )
						OR ( autodata.msttime >= T.PStartTime   AND autodata.msttime <T.PEndTime AND autodata.ndtime > T.PEndTime )
						OR ( autodata.msttime < T.PStartTime  AND autodata.ndtime > T.PEndTime))
						group by T.Machineid,T.shiftstart ) as t2 inner join #cockpitdata S on t2.intime=S.shiftstart and t2.machine=S.machineId
						
						----Add ICD's Overlapping  with PDT to UtilisedTime
						----Fetching Down Records from Production Cycle
						 ---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
							UPDATE  #cockpitdata SET Runtime = isnull(Runtime,0) + isNull(T2.IPDT ,0),PDT=isnull(PDT,0) + isNull(T2.IPDT ,0)
							FROM	(
							Select T.shiftstart as intime,AutoData.mc,
							SUM(
							CASE 	
								When autodata.sttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
								When autodata.sttime < T.PStartTime  and  autodata.ndtime <= T.PEndTime AND autodata.ndtime > T.PStartTime Then datediff(s, T.PStartTime,autodata.ndtime ) ---type 2
								When ( autodata.sttime >= T.PStartTime   AND autodata.sttime <T.PEndTime AND autodata.ndtime > T.PEndTime ) Then datediff(s, autodata.sttime,T.PEndTime ) ---type 3
								when ( autodata.sttime < T.PStartTime  AND autodata.ndtime > T.PEndTime)  Then datediff(s, T.PStartTime,T.PEndTime ) ---type 4
							END) as IPDT
							From #T_autodata AutoData  INNER Join 
								(Select mc,Sttime,NdTime,S.shiftstart as PStartTime from  autodata 
								 inner join #cockpitdata S on S.MachineInterface=autodata.mc
								Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
									(msttime >= S.shiftstart) AND (ndtime <= S.shiftend)) as T1
							ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
							Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
							And (( autodata.Sttime > T1.Sttime )
							And ( autodata.ndtime <  T1.ndtime )
							)
							AND
							((( T.PStartTime >=T1.Sttime) And ( T.PEndTime <=T1.ndtime ))
							or ( T.PStartTime < T1.Sttime  and  T.PEndTime <= T1.ndtime AND T.PEndTime > T1.Sttime)
							or (T.PStartTime >= T1.Sttime   AND T.PStartTime <T1.ndtime AND T.PEndTime > T1.ndtime )
							or (( T.PStartTime <T1.Sttime) And ( T.PEndTime >T1.ndtime )) )
							GROUP BY AUTODATA.mc,T.shiftstart
							)AS T2  INNER JOIN #cockpitdata ON
							T2.mc = #cockpitdata.MachineInterface and  t2.intime=#cockpitdata.shiftstart

						
						---mod 12(4)
						/* If production  Records of TYPE-2*/
						UPDATE  #cockpitdata SET Runtime = isnull(Runtime,0) + isNull(T2.IPDT ,0),PDT=isnull(PDT,0) + isNull(T2.IPDT ,0)
						FROM
						(Select T.shiftstart as intime,AutoData.mc ,
						SUM(
						CASE 	
							When autodata.sttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
							When autodata.sttime < T.PStartTime  and  autodata.ndtime <= T.PEndTime AND autodata.ndtime > T.PStartTime Then datediff(s, T.PStartTime,autodata.ndtime ) ---type 2
							When ( autodata.sttime >= T.PStartTime   AND autodata.sttime <T.PEndTime AND autodata.ndtime > T.PEndTime ) Then datediff(s, autodata.sttime,T.PEndTime ) ---type 3
							when ( autodata.sttime < T.PStartTime  AND autodata.ndtime > T.PEndTime)  Then datediff(s, T.PStartTime,T.PEndTime ) ---type 4
						END) as IPDT
						From #T_autodata AutoData  CROSS JOIN #PlannedDownTimes T INNER Join --ER0324 Added
							(Select mc,Sttime,NdTime,S.shiftstart as PStartTime from  autodata inner join #cockpitdata S on S.MachineInterface=autodata.mc
								Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
								(msttime < S.shiftstart)And (ndtime > S.shiftstart) AND (ndtime <= S.shiftend)) as T1
						ON AutoData.mc=T1.mc  and T1.PStartTime=T.shiftstart
						Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
						And (( autodata.Sttime > T1.Sttime )
						And ( autodata.ndtime <  T1.ndtime )
						AND ( autodata.ndtime >  T1.PStartTime ))
						AND
						(( T.PStartTime >= T1.PStartTime )
						And ( T.PStartTime <  T1.ndtime ) )
						GROUP BY AUTODATA.mc,T.shiftstart )AS T2  INNER JOIN #cockpitdata ON
						T2.mc = #cockpitdata.MachineInterface and  t2.intime=#cockpitdata.shiftstart
						
						/* If production Records of TYPE-3*/
						UPDATE  #cockpitdata SET Runtime = isnull(Runtime,0) + isNull(T2.IPDT ,0),PDT=isnull(PDT,0) + isNull(T2.IPDT ,0)
						FROM
						(Select T.shiftstart as intime,AutoData.mc ,
						SUM(
						CASE 	
							When autodata.sttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
							When autodata.sttime < T.PStartTime  and  autodata.ndtime <= T.PEndTime AND autodata.ndtime > T.PStartTime Then datediff(s, T.PStartTime,autodata.ndtime ) ---type 2
							When ( autodata.sttime >= T.PStartTime   AND autodata.sttime <T.PEndTime AND autodata.ndtime > T.PEndTime ) Then datediff(s, autodata.sttime,T.PEndTime ) ---type 3
							when ( autodata.sttime < T.PStartTime  AND autodata.ndtime > T.PEndTime)  Then datediff(s, T.PStartTime,T.PEndTime ) ---type 4
						END) as IPDT
						From #T_autodata AutoData  CROSS jOIN #PlannedDownTimes T INNER Join 
							(Select mc,Sttime,NdTime,S.shiftstart as PStartTime,S.shiftend as PEndTime From #T_autodata AutoData  
							 inner join #cockpitdata S on S.MachineInterface=autodata.mc
							Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
							(sttime >= S.shiftstart)And (ndtime > S.shiftend) and autodata.sttime <S.shiftend) as T1
						ON AutoData.mc=T1.mc and T1.PStartTime=T.shiftstart
						Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
						And ((T1.Sttime < autodata.sttime  )
						And ( T1.ndtime >  autodata.ndtime)
						AND (autodata.sttime  <  T1.PEndTime))
						AND
						(( T.PEndTime > T1.Sttime )
						And ( T.PEndTime <=T1.PEndTime ) )
						GROUP BY AUTODATA.mc,T.shiftstart)AS T2 INNER JOIN #cockpitdata ON
						T2.mc = #cockpitdata.MachineInterface and  t2.intime=#cockpitdata.shiftstart
						
						
						/* If production Records of TYPE-4*/
						UPDATE  #cockpitdata SET Runtime = isnull(Runtime,0) + isNull(T2.IPDT ,0),PDT=isnull(PDT,0) + isNull(T2.IPDT ,0)
						FROM
						(Select T.shiftstart as intime,AutoData.mc ,
						SUM(
						CASE 	
							When autodata.sttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
							When autodata.sttime < T.PStartTime  and  autodata.ndtime <= T.PEndTime AND autodata.ndtime > T.PStartTime Then datediff(s, T.PStartTime,autodata.ndtime ) ---type 2
							When ( autodata.sttime >= T.PStartTime   AND autodata.sttime <T.PEndTime AND autodata.ndtime > T.PEndTime ) Then datediff(s, autodata.sttime,T.PEndTime ) ---type 3
							when ( autodata.sttime < T.PStartTime  AND autodata.ndtime > T.PEndTime)  Then datediff(s, T.PStartTime,T.PEndTime ) ---type 4
						END) as IPDT
						From #T_autodata AutoData  CROSS jOIN #PlannedDownTimes T INNER Join 
							(Select mc,Sttime,NdTime,S.shiftstart as PStartTime,S.shiftend as PEndTime from 
							  autodata inner join #cockpitdata S on S.MachineInterface=autodata.mc
								Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
								(msttime < S.shiftstart)And (ndtime > S.shiftend)) as T1
						ON AutoData.mc=T1.mc and T1.PStartTime=T.shiftstart
						Where AutoData.DataType=2 and T.MachineInterface=autodata.mc
						And ( (T1.Sttime < autodata.sttime  )
							And ( T1.ndtime >  autodata.ndtime)
							AND (autodata.ndtime  >  T1.PStartTime)
							AND (autodata.sttime  <  T1.PEndTime))
						AND
						(( T.PStartTime >=T1.PStartTime)
						And ( T.PEndTime <=T1.PEndTime ) )
						GROUP BY AUTODATA.mc,T.shiftstart)AS T2  INNER JOIN #cockpitdata ON
						T2.mc = #cockpitdata.MachineInterface and  t2.intime=#cockpitdata.shiftstart
				
			END

			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
			BEGIN

			
						---Get the down times which are not of type Management Loss
						UPDATE #cockpitdata SET downtime = isnull(downtime,0) + isNull(t2.down,0)
						from
						(select      mc,
							sum(case when ( (autodata.msttime>=S.shiftstart) and (autodata.ndtime<=S.shiftend)) then  loadunload
								 when ((autodata.sttime<S.shiftstart)and (autodata.ndtime>S.shiftstart)and (autodata.ndtime<=S.shiftend)) then DateDiff(second, S.shiftstart, ndtime)
								 when ((autodata.msttime>=S.shiftstart)and (autodata.msttime<S.shiftend)and (autodata.ndtime>S.shiftend)) then DateDiff(second, stTime, S.shiftend)
								 when ((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.shiftend)) then DateDiff(second, S.shiftstart, S.shiftend) END ) as down,S.shiftstart as ShiftStart
						   From #T_autodata AutoData  
						   inner join #cockpitdata S on autodata.mc=S.MachineInterface
						   inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
						where (autodata.datatype=2) AND (downcodeinformation.availeffy = 0) and 
							  ((autodata.msttime>=S.shiftstart and autodata.ndtime<=S.shiftend)
							  OR(autodata.msttime<S.shiftstart and autodata.ndtime>S.shiftstart and autodata.ndtime<=S.shiftend)
							  OR(autodata.msttime>=S.shiftstart and autodata.msttime<S.shiftend and autodata.ndtime>S.shiftend)
							  OR(autodata.msttime<S.shiftstart and autodata.ndtime>S.shiftend)) 
							  group by autodata.mc,S.shiftstart
						) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface
						and t2.ShiftStart=#cockpitdata.shiftstart
						


						UPDATE #cockpitdata SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0),PDT=isnull(PDT,0) + isNull(t2.PldDown,0)
						from(
							select T.Shiftstart  as intime,T.Machineid as machineid,SUM
								   (CASE
								WHEN (autodata.sttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime)  THEN autodata.loadunload
								WHEN ( autodata.sttime < T.PStartTime  AND autodata.ndtime <= T.PEndTime  AND autodata.ndtime > T.PStartTime ) THEN DateDiff(second,T.PStartTime,autodata.ndtime)
								WHEN ( autodata.sttime >= T.PStartTime   AND autodata.sttime <T.PEndTime  AND autodata.ndtime > T.PEndTime  ) THEN DateDiff(second,autodata.sttime,T.PEndTime )
								WHEN ( autodata.sttime < T.PStartTime  AND autodata.ndtime > T.PEndTime ) THEN DateDiff(second,T.PStartTime,T.PEndTime )
								END ) as PldDown
							From #T_autodata AutoData   
							CROSS jOIN #PlannedDownTimes T
							INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
							WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
							(autodata.sttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime)
							OR ( autodata.sttime < T.PStartTime  AND autodata.ndtime <= T.PEndTime AND autodata.ndtime > T.PStartTime )
							OR ( autodata.sttime >= T.PStartTime   AND autodata.sttime <T.PEndTime AND autodata.ndtime > T.PEndTime )
							OR ( autodata.sttime < T.PStartTime  AND autodata.ndtime > T.PEndTime)
							)
							AND (downcodeinformation.availeffy = 0)
							group by T.Machineid ,T.Shiftstart ) as t2 
							inner join #cockpitdata S on t2.intime=S.shiftstart and t2.machineid=S.machineId
						

			
						UPDATE #cockpitdata SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),
						MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0),PDT=isnull(PDT,0) + isnull(T4.PPDT,0)
						from
						(select T3.mc,T3.StrtShft,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss,sum(T3.PPDT) as PPDT from
						 (
						select   t1.id,T1.mc,T1.Threshold,T1.StartShift as StrtShft,
						case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
						then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
						else 0 End  as Dloss,
						case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
						then isnull(T1.Threshold,0)
						else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss,isnull(T2.PPDT,0) as PPDT
						 from
						
						(   select id,mc,comp,opn,opr,D.threshold,S.shiftstart as StartShift,
							case when autodata.sttime<S.shiftstart then S.shiftstart else sttime END as sttime,
	       						case when ndtime>S.shiftend then S.shiftend else ndtime END as ndtime
							From #T_autodata AutoData  --ER0324 Added
							inner join downcodeinformation D
							on autodata.dcode=D.interfaceid inner join #cockpitdata S on autodata.mc=S.MachineInterface
							where autodata.datatype=2 AND
							(
							(autodata.msttime>=S.shiftstart  and  autodata.ndtime<=S.shiftend)
							OR (autodata.sttime<S.shiftstart and  autodata.ndtime>S.shiftstart and autodata.ndtime<=S.shiftend)
							OR (autodata.msttime>=S.shiftstart  and autodata.sttime<S.shiftend  and autodata.ndtime>S.shiftend)
							OR (autodata.msttime<S.shiftstart and autodata.ndtime>S.shiftend )
							) AND (D.availeffy = 1)) as T1 	
						left outer join
						(SELECT T.Shiftstart  as intime, autodata.id,
								   sum(CASE
								WHEN autodata.sttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime  THEN (autodata.loadunload)
								WHEN ( autodata.sttime < T.PStartTime  AND autodata.ndtime <= T.PEndTime  AND autodata.ndtime > T.PStartTime ) THEN DateDiff(second,T.PStartTime,autodata.ndtime)
								WHEN ( autodata.sttime >= T.PStartTime   AND autodata.sttime <T.PEndTime  AND autodata.ndtime > T.PEndTime  ) THEN DateDiff(second,autodata.sttime,T.PEndTime )
								WHEN ( autodata.sttime < T.PStartTime  AND autodata.ndtime > T.PEndTime ) THEN DateDiff(second,T.PStartTime,T.PEndTime )
								END ) as PPDT
							From #T_autodata AutoData   
							CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
							WHERE autodata.DataType=2 and T.MachineInterface=autodata.mc AND
								(
								(autodata.sttime >= T.PStartTime  AND autodata.ndtime <=T.PEndTime)
								OR ( autodata.sttime < T.PStartTime  AND autodata.ndtime <= T.PEndTime AND autodata.ndtime > T.PStartTime )
								OR ( autodata.sttime >= T.PStartTime   AND autodata.sttime <T.PEndTime AND autodata.ndtime > T.PEndTime )
								OR ( autodata.sttime < T.PStartTime  AND autodata.ndtime > T.PEndTime)
								)
								 AND (downcodeinformation.availeffy = 1) group by autodata.id,T.Shiftstart ) as T2 on T1.id=T2.id  and T1.StartShift=T2.intime ) as T3  group by T3.mc,T3.StrtShft
						) as t4 inner join #cockpitdata S on t4.StrtShft=S.shiftstart and t4.mc=S.MachineInterface

						UPDATE #cockpitdata  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
				
			END

			update #cockpitdata set Totaltime= datediff(s,shiftstart,shiftend)
			update #cockpitdata set downtime= isnull(downtime,0)-isnull(ManagementLoss,0)

			select shiftdate,shiftname,shiftstart,shiftend,machineid,Machineinterface,cyclecount,
			dbo.f_formattime( totaltime,'hh:mm:ss') as Totaltime,
			dbo.f_formattime(runtime,'hh:mm:ss') as runtime,
			dbo.f_formattime(Downtime,'hh:mm:ss') as Downtime,dbo.f_formattime(PDT,'hh:mm:ss') as PDT,
			dbo.f_formattime(Managementloss,'hh:mm:ss') as ManagementLoss from #cockpitdata
			return			

End

If @param='DaywiseCockpit'
Begin

			select @starttime = dbo.f_GetLogicalDay(@starttime,'Start')
			select @endtime = dbo.f_GetLogicalDay(@starttime,'end')

			SET @strSql = ''
			SET @strSql = 'Insert into #cockpitdataDaywise
				SELECT M.machineid,M.interfaceid,0,0,0,0,0,0,0 FROM MachineInformation M 
				inner join plantmachine P on M.machineid=P.machineid
				LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 
			    WHERE M.tpmtrakenabled=1'
			select @strsql = @strsql + @StrPlantID + @strmachine + @StrGroupid
			select @strsql = @strsql + ' ORDER BY M.Machineid'
			print @strsql 
			EXEC(@strSql)

			SET @strSql = ''
			SET @strSql = 'Insert into #PlannedDownTimesday
				SELECT Machine,InterfaceID,Starttime as Pstarttime,endtime as Pendtime,
					CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
					CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
				FROM PlannedDownTimes inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
				LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 
			    WHERE PDTstatus =1 and(
				(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
				OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
				OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
				OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
			SET @strSql =  @strSql + @strMachine + @StrGroupid + ' ORDER BY Machine,StartTime'
			EXEC(@strSql)

			-- Type 1
			UPDATE #cockpitdataDaywise SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
			from
			(select      mc,sum(cycletime+loadunload) as cycle
			From #T_autodata AutoData 
			where (autodata.msttime>=@StartTime)
			and (autodata.ndtime<=@EndTime)
			and (autodata.datatype=1)
			group by autodata.mc
			) as t2 inner join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface

			-- Type 2
			UPDATE #cockpitdataDaywise SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
			from
			(select  mc,SUM(DateDiff(second, @StartTime, ndtime)) cycle
			From #T_autodata AutoData 
			where (autodata.msttime<@StartTime)
			and (autodata.ndtime>@StartTime)
			and (autodata.ndtime<=@EndTime)
			and (autodata.datatype=1)
			group by autodata.mc
			) as t2 inner join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface
			-- Type 3
			UPDATE  #cockpitdataDaywise SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
			from
			(select  mc,sum(DateDiff(second, mstTime, @Endtime)) cycle
			From #T_autodata AutoData 
			where (autodata.msttime>=@StartTime)
			and (autodata.msttime<@EndTime)
			and (autodata.ndtime>@EndTime)
			and (autodata.datatype=1)
			group by autodata.mc
			) as t2 inner join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface
			-- Type 4
			UPDATE #cockpitdataDaywise SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0)
			from
			(select mc,
			sum(DateDiff(second, @StartTime, @EndTime)) cycle From #T_autodata AutoData 
			where (autodata.msttime<@StartTime)
			and (autodata.ndtime>@EndTime)
			and (autodata.datatype=1)
			group by autodata.mc
			)as t2 inner join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface	

			/* Fetching Down Records from Production Cycle  */
			/* If Down Records of TYPE-2*/
			UPDATE  #cockpitdataDaywise SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(
			CASE
			When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )
			When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
			END) as Down
			From #T_autodata AutoData  INNER Join
			(Select mc,Sttime,NdTime From #T_autodata AutoData 
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
			ON AutoData.mc=T1.mc
			Where AutoData.DataType=2
			And ( autodata.Sttime > T1.Sttime )
			And ( autodata.ndtime <  T1.ndtime )
			AND ( autodata.ndtime >  @StartTime )
			GROUP BY AUTODATA.mc)AS T2 Inner Join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface

			/* If Down Records of TYPE-3*/
			UPDATE  #cockpitdataDaywise SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(CASE
			When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
			When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
			END) as Down
			From #T_autodata AutoData  INNER Join
			(Select mc,Sttime,NdTime From #T_autodata AutoData 
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(sttime >= @StartTime)And (ndtime > @EndTime) and (sttime<@EndTime) ) as T1
			ON AutoData.mc=T1.mc
			Where AutoData.DataType=2
			And (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.sttime  <  @EndTime)
			GROUP BY AUTODATA.mc)AS T2 Inner Join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface

			/* If Down Records of TYPE-4*/
			UPDATE  #cockpitdataDaywise SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(CASE
			When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
			When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
			When autodata.sttime>=@StartTime And autodata.sttime < @EndTime AND autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
			When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
			END) as Down
			From #T_autodata AutoData  INNER Join
			(Select mc,Sttime,NdTime From #T_autodata AutoData 
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < @StartTime)And (ndtime > @EndTime) ) as T1
			ON AutoData.mc=T1.mc
			Where AutoData.DataType=2
			And (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.ndtime  >  @StartTime)
			AND (autodata.sttime  <  @EndTime)
			GROUP BY AUTODATA.mc
			)AS T2 Inner Join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface

			--mod 4:Get utilised time over lapping with PDT.
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
			BEGIN
					UPDATE #cockpitdataDaywise set UtilisedTime =isnull(UtilisedTime,0) - isNull(TT.PPDT ,0),
					PDT = isnull(PDT,0)+isNull(TT.PPDT ,0)
					FROM(
					SELECT autodata.MC,SUM
					(CASE
					WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload)
					WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
					WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END)  as PPDT
					From #T_autodata AutoData  CROSS jOIN #PlannedDownTimesday T
					WHERE autodata.DataType=1 And T.MachineInterface=AutoData.mc AND
					(
					(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )
					group by autodata.mc
					)
					as TT INNER JOIN #cockpitdataDaywise ON TT.mc = #cockpitdataDaywise.MachineInterface

					--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
					UPDATE  #cockpitdataDaywise set UtilisedTime =isnull(UtilisedTime,0) + isNull(T2.IPDT ,0),PDT = isnull(PDT,0) + isNull(T2.IPDT ,0) 	
					FROM	(
					Select AutoData.mc,
					SUM(
					CASE 	
					When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
					When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
					When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
					when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
					END) as IPDT
					From #T_autodata AutoData  INNER Join
					(Select mc,Sttime,NdTime From #T_autodata AutoData 
						Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
						(msttime >= @StartTime) AND (ndtime <= @EndTime)) as T1
					ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimesday T
					Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
					And (( autodata.Sttime > T1.Sttime )
					And ( autodata.ndtime <  T1.ndtime )
					)
					AND
					((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
					or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
					or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
					or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
					GROUP BY AUTODATA.mc
					)AS T2  INNER JOIN #cockpitdataDaywise ON T2.mc = #cockpitdataDaywise.MachineInterface
					---mod 4(4)

					/* Fetching Down Records from Production Cycle  */
					/* If production  Records of TYPE-2*/
					UPDATE  #cockpitdataDaywise set UtilisedTime =isnull(UtilisedTime,0) + isNull(T2.IPDT ,0),PDT =isnull(PDT,0) + isNull(T2.IPDT ,0) 	
					FROM	(
					Select AutoData.mc,
					SUM(
					CASE 	
					When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
					When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
					When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
					when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
					END) as IPDT
					From #T_autodata AutoData  INNER Join
					(Select mc,Sttime,NdTime From #T_autodata AutoData 
						Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
						(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
					ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimesday T
					Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
					And (( autodata.Sttime > T1.Sttime )
					And ( autodata.ndtime <  T1.ndtime )
					AND ( autodata.ndtime >  @StartTime ))
					AND
					(( T.StartTime >= @StartTime )
					And ( T.StartTime <  T1.ndtime ) )
					GROUP BY AUTODATA.mc
					)AS T2  INNER JOIN #cockpitdataDaywise ON T2.mc = #cockpitdataDaywise.MachineInterface

					/* If production Records of TYPE-3*/
					UPDATE  #cockpitdataDaywise set UtilisedTime =isnull(UtilisedTime,0) + isNull(T2.IPDT ,0),PDT =isnull(PDT,0) + isNull(T2.IPDT ,0) 	
					FROM
					(Select AutoData.mc ,
					SUM(
					CASE 	
					When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
					When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
					When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
					when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
					END) as IPDT
					From #T_autodata AutoData  INNER Join
					(Select mc,Sttime,NdTime From #T_autodata AutoData 
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(sttime >= @StartTime)And (ndtime > @EndTime) and autodata.sttime <@EndTime) as T1
					ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimesday T
					Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
					And ((T1.Sttime < autodata.sttime  )
					And ( T1.ndtime >  autodata.ndtime)
					AND (autodata.msttime  <  @EndTime))
					AND
					(( T.EndTime > T1.Sttime )
					And ( T.EndTime <=@EndTime ) )
					GROUP BY AUTODATA.mc)AS T2  INNER JOIN #cockpitdataDaywise ON T2.mc = #cockpitdataDaywise.MachineInterface


					/* If production Records of TYPE-4*/
					UPDATE  #cockpitdataDaywise set UtilisedTime =isnull(UtilisedTime,0) + isNull(T2.IPDT ,0),PDT =isnull(PDT,0) + isNull(T2.IPDT ,0) 	
					FROM
					(Select AutoData.mc ,
					SUM(
					CASE 	
					When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
					When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
					When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
					when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
					END) as IPDT
					From #T_autodata AutoData  INNER Join
					(Select mc,Sttime,NdTime From #T_autodata AutoData 
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(msttime < @StartTime)And (ndtime > @EndTime)) as T1
					ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimesday T
					Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
					And ( (T1.Sttime < autodata.sttime  )
					And ( T1.ndtime >  autodata.ndtime)
					AND (autodata.ndtime  >  @StartTime)
					AND (autodata.sttime  <  @EndTime))
					AND
					(( T.StartTime >=@StartTime)
					And ( T.EndTime <=@EndTime ) )
					GROUP BY AUTODATA.mc)AS T2  INNER JOIN #cockpitdataDaywise ON T2.mc = #cockpitdataDaywise.MachineInterface

			END
			
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')

			BEGIN
					-- Type 1
					UPDATE #cockpitdataDaywise SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select mc,sum(
					CASE
					WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
					THEN isnull(downcodeinformation.Threshold,0)
					ELSE loadunload
					END) AS LOSS
					From #T_autodata AutoData  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
					where (autodata.msttime>=@StartTime)
					and (autodata.ndtime<=@EndTime)
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc) as t2 inner join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface

					-- Type 2
					UPDATE #cockpitdataDaywise SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select      mc,sum(
					CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
					then isnull(downcodeinformation.Threshold,0)
					ELSE DateDiff(second, @StartTime, ndtime)
					END)loss
					From #T_autodata AutoData  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
					where (autodata.sttime<@StartTime)
					and (autodata.ndtime>@StartTime)
					and (autodata.ndtime<=@EndTime)
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc
					) as t2 inner join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface

					-- Type 3
					UPDATE #cockpitdataDaywise SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select      mc,SUM(
					CASE WHEN DateDiff(second,stTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
					then isnull(downcodeinformation.Threshold,0)
					ELSE DateDiff(second, stTime, @Endtime)
					END)loss
					From #T_autodata AutoData  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
					where (autodata.msttime>=@StartTime)
					and (autodata.sttime<@EndTime)
					and (autodata.ndtime>@EndTime)
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc
					) as t2 inner join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface

					-- Type 4
					UPDATE #cockpitdataDaywise SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select mc,sum(
					CASE WHEN DateDiff(second, @StartTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
					then isnull(downcodeinformation.Threshold,0)
					ELSE DateDiff(second, @StartTime, @Endtime)
					END)loss
					From #T_autodata AutoData  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
					where autodata.msttime<@StartTime
					and autodata.ndtime>@EndTime
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc
					) as t2 inner join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface

					---get the downtime for the time period
					UPDATE #cockpitdataDaywise SET downtime = isnull(downtime,0) + isNull(t2.down,0)
					from
					(select mc,sum(
							CASE
							WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
							WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
							WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
							WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
							END
						)AS down
					From #T_autodata AutoData  inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
					where autodata.datatype=2 AND
					(
					(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
					OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
					OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
					OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
					)
					group by autodata.mc
					) as t2 inner join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface
			End


			---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
			BEGIN

				---step 1
				UPDATE #cockpitdataDaywise SET downtime = isnull(downtime,0) + isNull(t2.down,0)
				from
				(select mc,sum(
				CASE
				WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
				WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
				WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
				WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
				END
				)AS down
				From #T_autodata AutoData  inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				where autodata.datatype=2 AND
				(
				(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
				OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
				OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
				OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
				) AND (downcodeinformation.availeffy = 0)
				group by autodata.mc
				) as t2 inner join #cockpitdataDaywise on t2.mc = #cockpitdataDaywise.machineinterface
			
				---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
				UPDATE #cockpitdataDaywise set downtime=isnull(downtime,0)- isNull(TT.PPDT ,0), PDT =isnull(PDT,0) + isNull(TT.PPDT ,0)
				FROM(
				SELECT autodata.MC, SUM
				(CASE
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PPDT
				From #T_autodata AutoData  CROSS jOIN #PlannedDownTimesday T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				) AND (downcodeinformation.availeffy = 0)
				group by autodata.mc
				) as TT INNER JOIN #cockpitdataDaywise ON TT.mc = #cockpitdataDaywise.MachineInterface


				UPDATE #cockpitdataDaywise SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
				from
				(select T3.mc,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
				select   t1.id,T1.mc,T1.Threshold,
				case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
				then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
				else 0 End  as Dloss,
				case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
				then isnull(T1.Threshold,0)
				else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
				from

				(   select id,mc,comp,opn,opr,D.threshold,
				case when autodata.sttime<@StartTime then @StartTime else sttime END as sttime,
				case when ndtime>@EndTime then @EndTime else ndtime END as ndtime
				From #T_autodata AutoData 
				inner join downcodeinformation D
				on autodata.dcode=D.interfaceid where autodata.datatype=2 AND
				(
				(autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)
				OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
				OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
				OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )
				) AND (D.availeffy = 1)) as T1 	
				left outer join
				(SELECT autodata.id,
				sum(CASE
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PPDT
				From #T_autodata AutoData  CROSS jOIN #PlannedDownTimesday T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				)
				AND (downcodeinformation.availeffy = 1) group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc
				) as t4 inner join #cockpitdataDaywise on t4.mc = #cockpitdataDaywise.machineinterface

				UPDATE #cockpitdataDaywise SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
			END

			--Calculation of PartsCount Begins..
			UPDATE #cockpitdataDaywise SET cyclecount = ISNULL(cyclecount,0) + ISNULL(t2.comp,0)
			From
			(
			Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp
			From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn From #T_autodata AutoData 
			where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)
			Group By mc,comp,opn) as T1
			Inner join componentinformation C on T1.Comp = C.interfaceid
			Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
			inner join machineinformation on machineinformation.machineid =O.machineid
			and T1.mc=machineinformation.interfaceid
			GROUP BY mc
			) As T2 Inner join #cockpitdataDaywise on T2.mc = #cockpitdataDaywise.machineinterface


			--Mod 4 Apply PDT for calculation of Count
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
			BEGIN
					UPDATE #cockpitdataDaywise SET cyclecount = ISNULL(cyclecount,0) - ISNULL(T2.comp,0) 
					from(
					select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From 
					(
					select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn From #T_autodata AutoData 
					CROSS JOIN #PlannedDownTimesday T
					WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
					AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
					AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)
					Group by mc,comp,opn
					) as T1
					Inner join Machineinformation M on M.interfaceID = T1.mc
					Inner join componentinformation C on T1.Comp=C.interfaceid
					Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
					GROUP BY MC
					) as T2 inner join #cockpitdataDaywise on T2.mc = #cockpitdataDaywise.machineinterface
			END

			update #cockpitdataDaywise set Totaltime= datediff(s,@starttime,@endtime)
			update #cockpitdataDaywise set downtime= isnull(downtime,0)-isnull(ManagementLoss,0)


			select Machineid,Machineinterface,Cyclecount,
			dbo.f_formattime( totaltime,'hh:mm:ss') as Totaltime,'100' as TotalEffy,
			dbo.f_formattime(UtilisedTime,'hh:mm:ss') as Runtime, Isnull(Round((UtilisedTime/Totaltime) * 100,2),0) as RuntimeEffy,
			dbo.f_formattime(Downtime,'hh:mm:ss') as Downtime,ISNULL(Round((Downtime/Totaltime) * 100,2),0) as DowntimeEffy,
			dbo.f_formattime(PDT,'hh:mm:ss') as PDT,ISNULL(Round((PDT/Totaltime) * 100,2),0) as PDTEffy,
			dbo.f_formattime(Managementloss,'hh:mm:ss') as ManagementLoss ,ISNULL(Round((Managementloss/Totaltime) * 100,2),0) as MGMTEffy
			from #cockpitdataDaywise
			return			

End


end
