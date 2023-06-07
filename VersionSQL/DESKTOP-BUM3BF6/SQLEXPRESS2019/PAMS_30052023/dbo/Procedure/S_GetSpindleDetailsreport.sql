/****** Object:  Procedure [dbo].[S_GetSpindleDetailsreport]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************  
-- Author:		Anjana C V/SwathiKS
-- Create date: 02 Nov 2018
-- Modified date: 02 Nov 2018
-- Description:  
[S_GetSpindleDetailsreport] '2018-11-04 06:00:00','2018-11-04 18:00:00','PKH HBM-01','Bytime'
[S_GetSpindleDetailsreport] '2018-11-04 16:44:03.000','2018-11-04 18:00:00','PKH HBM-02','Bycycle'
***************************************************************************************************/  
CREATE PROCEDURE [dbo].[S_GetSpindleDetailsreport]  
 @StartTime datetime,    
 @EndTime datetime,    
 @MachineID nvarchar(50)='',    
 @Param nvarchar(20)= 'ByTime'    --Bytime/ByCycle
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

Declare @strSql as nvarchar(4000)   
Declare @strmachine nvarchar(1000) 

Select @strmachine=''
Select @strSql=''

if isnull(@machineid,'') <> ''  
Begin  

Select @strmachine = ' and ( m.MachineID = N''' + @MachineID + ''')'  
End  

CREATE TABLE #T_autodata
(
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
	id  bigint not null,
	WorkOrderNumber nvarchar(50)
)

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime,ndtime,msttime ASC
)ON [PRIMARY]

CREATE TABLE #Target    
(  
  
startdate datetime,  
enddate datetime,  
MachineID nvarchar(50),
Machineinterface nvarchar(50),
SpindleRuntime float
)

create table #spindle
(
SlNo bigint identity(1,1),
machineid nvarchar(50),
Starttime datetime,
RecordType int,
Datatype int,
cyclestart datetime,
CycleEnd datetime
)

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 


Select @T_ST=dbo.f_GetLogicalDaystart(@StartTime)
Select @T_ED=dbo.f_GetLogicalDayend(@EndTime)

Select @strsql=''
select @strsql ='insert into #T_autodata(mc, comp, opn, opr, dcode,sttime,ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id) '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where datatype=1 and (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)

Select @strsql=''
SELECT @strsql = 'INSERT INTO #Target(startdate,enddate,MachineID,machineinterface) '
SELECT @strsql = @strsql +' Select distinct a.sttime,a.ndtime, m.machineid,m.interfaceid
FROM #T_autodata A inner join Machineinformation M on M.interfaceid=A.mc   
WHERE (A.sttime >= '''+ convert(nvarchar(25),@StartTime,120)+''' AND A.ndtime <= '''+convert(nvarchar(25),@EndTime,120)+''')'
SELECT @strsql = @strsql +@strmachine
print @strsql
exec(@strsql)

Select @strsql=''
SELECT @strsql = 'INSERT INTO #Target(startdate,MachineID,machineinterface) '
SELECT @strsql = @strsql +' select 
case when R.sttime< '''+ convert(nvarchar(25),@StartTime,120)+''' then  '''+ convert(nvarchar(25),@StartTime,120)+''' else R.sttime end,
M.MachineID,M.interfaceid from Rawdata  R
inner join 
(
	select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
	inner join Autodata_maxtime A on rawdata.mc=A.machineid 
	where (Rawdata.sttime>=A.Endtime and (Rawdata.sttime>='''+convert(nvarchar(25),@StartTime,120)+''' and Rawdata.sttime<='''+convert(nvarchar(25),@EndTime,120)+''')) 
	and rawdata.datatype=11 group by mc  
) T1 on t1.mc=R.mc and t1.slno=R.slno  
inner join Autodata_maxtime A on R.mc=A.machineid  
inner join  Machineinformation M on M.interfaceid = R.mc  
where (R.sttime>=A.Endtime and (R.sttime>='''+convert(nvarchar(25),@StartTime,120)+''' and R.sttime<='''+convert(nvarchar(25),@EndTime,120)+''')) 
and R.datatype=11 '
SELECT @strsql = @strsql +@strmachine
SELECT @strsql = @strsql +' order by R.mc  '
print @strsql
exec(@strsql)



If @Param='Bycycle'
Begin

SET @EndTime=(Select top 1 enddate from #TARGET where convert(nvarchar(20),startdate,120)=convert(nvarchar(20),@StartTime,120))
END


Select @strSql=''
Select @strsql= 'Insert into #Spindle(MachineID,CycleStart,CycleEnd,Starttime,datatype,RecordType)
select distinct M.MachineID,#Target.StartDate,#Target.Enddate,A.Starttime,A.RecordType,
(case when RecordType=40 then 1 when RecordType=41 then 2 end ) Value from AutodataDetails A
inner join  Machineinformation M on M.interfaceid = A.Machine  
inner join #Target on A.machine=#Target.machineinterface
WHERE (A.Starttime>= '''+ convert(nvarchar(25),@StartTime,120)+''' AND A.Starttime<='''+convert(nvarchar(25),@EndTime,120)+''')
and (A.Starttime>=#Target.StartDate and A.starttime<=#Target.Enddate)'
SELECT @strsql = @strsql +@strmachine
SELECT @strsql = @strsql +' order by m.MachineID,A.Starttime'
print @strsql
exec(@strsql)

--Query to get Spindlestart ans SpindleEnd for each Machine  
Select S.cyclestart,S.CycleEnd,S.MachineID,S.Starttime as SpindleStart,Min(S1.Starttime) as SpindleEnd INTO #TempSpindle from #Spindle S  
inner join #Spindle S1 on S.MachineID=S1.MachineID  and S.cyclestart=S1.cyclestart and S.CycleEnd=S1.CycleEnd
Where S.Slno<S1.Slno and S.datatype='41' and S1.Datatype='40'  
Group by S.MachineID,S.Starttime,S.cyclestart,S.CycleEnd

Update #Target set SpindleRuntime = T.Runtime From
(select machineid,cyclestart,SUM(datediff(second,SpindleStart,SpindleEnd)) as Runtime from #TempSpindle
group by machineid,cyclestart)T 
inner join #Target on T.MachineID=#Target.MachineID and T.cyclestart=#Target.startdate

--select * from #TempSpindle order by SpindleStart

---RESULT1
SELECT MachineID,StartDate,Enddate,[dbo].[f_FormatTime](SpindleRuntime,'hh:mm:ss') as SpindleRuntime FROM #Target order by MachineID,StartDate
---RESULT1

---RESULT2
Select MachineID,CycleStart,CycleEnd,Starttime,datatype,RecordType from #spindle order by MachineID,Starttime
---RESULT2

---RESULT1
Select Machineid,[dbo].[f_FormatTime](SUM(SpindleRuntime),'hh:mm:ss') as TotalSpindleRuntime from #Target Group by MachineID
---RESULT2
END
 
