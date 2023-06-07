/****** Object:  Procedure [dbo].[S_Get_Component_Setup_Report_KTA]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************
Created By : Raksha R
Created On: 05-Aug-2022
Description : Component Setup Report


exec [dbo].[S_Get_Component_Setup_Report_KTA] @param = 'DownCodeList'
exec [dbo].[S_Get_Component_Setup_Report_KTA] '2022-07-01 06:00:00','2022-07-30 14:00:00','60 Ton-Welding Machine-155'
exec [dbo].[S_Get_Component_Setup_Report_KTA] '2022-07-01 06:00:00','2022-07-30 14:00:00','','','',
'''GOST50 FMH27 100 MAIN BODY AD/SL-BL'',''SK40 FRICTION WELDING BLANK ABOVE 50MM -BL''','''PIYUSH KUMAR'',''Dipak Divedi''',''

exec [dbo].[S_Get_Component_Setup_Report_KTA] '2022-07-01 06:00:00','2022-07-30 14:00:00'

exec [dbo].[S_Get_Component_Setup_Report_KTA] '2022-08-01 06:00:00','2022-08-30 14:00:00'

**********************************************************/
CREATE procedure [dbo].[S_Get_Component_Setup_Report_KTA]
@StartDate datetime='',  
 @EndDate datetime='',  
 @MachineID nvarchar(50) = '',  
 @Plantid nvarchar(50) = '',
 @CellID nvarchar(50)='',
 @ComponentID nvarchar(max)='',
 @Operator nvarchar(max)='',
 @param nvarchar(50) = ''  
WITH RECOMPILE  
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

  
CREATE TABLE #T_autodata  
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
 [PartsCount] decimal(18,5) NULL ,
 id  bigint not null  
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime ASC  
)ON [PRIMARY]  
  
  
CREATE TABLE #FinalTarget    
(  
MachineID nvarchar(50) NOT NULL,  
machineinterface nvarchar(50),  
Component nvarchar(50) NOT NULL,  
Compinterface nvarchar(50),  
Operation nvarchar(50) NOT NULL,  
OpnInterface nvarchar(50),  
Operator nvarchar(50),  
OprInterface nvarchar(50),  
BatchStart datetime,  
BatchEnd datetime,  
StdSetupTime nvarchar(50),
ActSetupTime nvarchar(50),
A  float,
B  float,
C  float,
D  float,
E  float,
F  float,
G  float,
H  float,
I  float,
J  float,
K  float,
L  float,
M  float,
N  float,
O  float
)  
 
CREATE TABLE #PlannedDownTimesShift  
(  
 SlNo int not null identity(1,1),  
 Starttime datetime,  
 EndTime datetime,  
 Machine nvarchar(50),  
 MachineInterface nvarchar(50),  
 DownReason nvarchar(50),  
 ShiftSt datetime  
)  
   

Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50)
)

Insert into #Downcode(Downid)
Select top 15 downid from downcodeinformation where Catagory like '%Setup%' 
--and (SortOrder>0 and SortOrder<=15) 
and SortOrder IS NOT NULL 
order by sortorder

If @param = 'DownCodeList'
Begin
	select downid from #Downcode order by slno
	return
end 


  
Declare @strsql nvarchar(max)  
Declare @strmachine nvarchar(1000)  
Declare @StrTPMMachines AS nvarchar(1000)  
Declare @StrPlantid as nvarchar(1000)  
 declare @StrCell as nvarchar(50)
 declare @StrComponentID as nvarchar(max)
 declare @StrOperator as nvarchar(max)

Declare @timeformat as nvarchar(12)  
Declare @CurStrtTime as datetime  
Declare @CurEndTime as datetime  
Declare @T_Start AS Datetime   
Declare @T_End AS Datetime  
  
Select @strsql = ''  
Select @StrTPMMachines = ''  
Select @strmachine = ''  
select @strPlantID = ''  
 select @StrCell=''
  select @StrComponentID=''
    select @StrOperator=''

if isnull(@machineid,'') <> ''  
Begin  
 Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'  
End  
  
if isnull(@PlantID,'') <> ''  
Begin  
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'  

End  
if isnull(@CellID,'') <> ''  
Begin  
 Select @StrCell = ' and ( PG.GroupID = N''' + @CellID + ''')'  

End 

if isnull(@ComponentID,'') <> ''  
Begin  
 --Select @StrComponentID = ' and ( componentinformation.ComponentID = N''' + @ComponentID + ''')'  
 Select @StrComponentID = ' and ( componentinformation.ComponentID in (' + @ComponentID +') )' 
End 

if isnull(@Operator,'') <> ''  
Begin  
 --Select @StrOperator = ' and ( EI.Employeeid = N''' + @Operator + ''')'  
 Select @StrOperator = ' and ( EI.Employeeid in (' + @Operator +') )' 
End 

Select @T_Start=dbo.f_GetLogicalDay(@StartDate,'start')  
Select @T_End=dbo.f_GetLogicalDay(@EndDate,'End') 

/* Planned Down times for the given time period */  
Select @strsql=''  
select @strsql = 'insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason)'  
select @strsql = @strsql + 'select  
CASE When StartTime<'''+ convert(nvarchar(25),@T_Start,120)+''' Then '''+ convert(nvarchar(25),@T_Start,120)+''' Else StartTime End,  
case When EndTime>'''+ convert(nvarchar(25),@T_End,120)+''' Then '''+ convert(nvarchar(25),@T_End,120)+''' Else EndTime End,  
Machine,MachineInformation.InterfaceID,  
DownReason  
FROM PlannedDownTimes 
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
WHERE PDTstatus =1 and (  
(StartTime >= '''+ convert(nvarchar(25),@T_Start,120)+'''  AND EndTime <='''+ convert(nvarchar(25),@T_End,120)+''')  
OR ( StartTime < '''+ convert(nvarchar(25),@T_Start,120)+'''  AND EndTime <= '''+ convert(nvarchar(25),@T_End,120)+''' AND EndTime > '''+ convert(nvarchar(25),@T_Start,120)+''' )  
OR ( StartTime >= '''+ convert(nvarchar(25),@T_Start,120)+'''  AND StartTime <'''+ convert(nvarchar(25),@T_End,120)+''' AND EndTime > '''+ convert(nvarchar(25),@T_End,120)+''' )  
OR ( StartTime < '''+ convert(nvarchar(25),@T_Start,120)+'''  AND EndTime > '''+ convert(nvarchar(25),@T_End,120)+''') )'  
select @strsql = @strsql + @strmachine   
select @strsql = @strsql + 'ORDER BY StartTime'  
print @strsql  
exec (@strsql)  

  
Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
select @strsql = @strsql + ' from autodata where datatype=2 and (( sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_End,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_Start,120)+'''  
							 and ndtime<='''+convert(nvarchar(25),@T_End,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' and sttime<'''+convert(nvarchar(25),@T_End,120)+''' ) )'  
print @strsql  
exec (@strsql)  


  

Select @strsql=''  
select @strsql ='insert into #FinalTarget (MachineID,machineinterface,Component,Compinterface,operation,Opninterface,Operator,Oprinterface,BatchStart,BatchEnd,StdSetupTime,ActSetupTime) 
SELECT machineinformation.machineid, ST.mc,componentinformation.componentid, ST.comp,  
componentoperationpricing.operationno, ST.opn,EI.Employeeid,ST.opr ,ST.SetupStartTime,ST.SetupEndTime,componentoperationpricing.StdSetupTime,dateDiff(Second,SetupStartTime,SetupEndTime)
FROM SetupTransaction_KTA  ST  
INNER JOIN  machineinformation ON ST.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON ST.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON ST.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
INNER Join Employeeinformation EI on EI.interfaceid=ST.opr   
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid  
left join PlantMachineGroups PG on PlantMachine.PlantID=PG.PlantID and PG.MachineID=Machineinformation.machineid  
WHERE ((ST.SetupStartTime >= '''+convert(nvarchar(25),@T_Start,120) +''' AND ST.SetupEndTime <= '''+convert(nvarchar(25),@T_End,120) +''' ) 
OR ( ST.SetupStartTime < '''+convert(nvarchar(25),@T_Start,120)+'''  AND ST.SetupEndTime <= '''+convert(nvarchar(25),@T_End,120)+''' AND ST.SetupEndTime > '''+convert(nvarchar(25),@T_Start,120)+''' )  
OR ( ST.SetupStartTime >= '''+convert(nvarchar(25),@T_Start,120)+''' AND ST.SetupStartTime < '''+convert(nvarchar(25),@T_End,120)+''' AND ST.SetupEndTime > '''+convert(nvarchar(25),@T_End,120)+''' )  
OR ( ST.SetupStartTime < '''+convert(nvarchar(25),@T_Start,120)+''' AND ST.SetupEndTime > '''+convert(nvarchar(25),@T_End,120)+''' )) '
select @strsql = @strsql + @strPlantID + @strmachine  + @StrCell + @StrComponentID  + @StrOperator
print @strsql  
exec (@strsql)


declare @i as nvarchar(10)
declare @colName as nvarchar(50)
Select @i=1
	  

--while @i <=15 --SV
while @i <=15 --SV
Begin
	Select @ColName = Case when @i=1 then 'A'
						when @i=2 then 'B'
						when @i=3 then 'C'
						when @i=4 then 'D'
						when @i=5 then 'E'
						when @i=6 then 'F'
						when @i=7 then 'G'
						when @i=8 then 'H'
						when @i=9 then 'I'
						when @i=10 then 'J'
						when @i=11 then 'K'
						when @i=12 then 'L'
						when @i=13 then 'M'
						when @i=14 then 'N'
						when @i=15 then 'O'
						 END



	 ---Get the down times which are not of type Management Loss  
	 Select @strsql = ''
	 Select @strsql = @strsql + ' UPDATE #FinalTarget SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t2.down,0)  
	 from  
	 (select  F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,  
	  sum (CASE  
		WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload  
		WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)  
		WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )  
		WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )  
		END ) as down  
		from #T_autodata autodata   
		inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.opr = F.Oprinterface  
		inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
		inner join #Downcode on #Downcode.downid= downcodeinformation.downid
		where (autodata.datatype=''2'') AND  #Downcode.Slno= ' + @i + ' and 
		(( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))  
		   OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))  
		   OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))  
		   OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))   
		AND (downcodeinformation.availeffy = ''0'')  
		   group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface  
	 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
	 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface   
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd '
     print @strsql
	 exec(@strsql) 
	 
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
	BEGIN   
			Select @strsql = '' 
			Select @strsql = @strsql + 'UPDATE  #FinalTarget SET ' + @ColName + ' = isnull(' + @ColName + ',0) - isNull(T2.PPDT ,0)  
			FROM(  
			SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,  
			SUM  
			(CASE  
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
			END ) as PPDT  
			FROM #T_autodata AutoData  
			CROSS jOIN #PlannedDownTimesShift T  
			INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
			INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr  
			inner join #Downcode on #Downcode.downid= downcodeinformation.downid
			
			WHERE autodata.DataType=''2'' AND T.MachineInterface=autodata.mc AND (downcodeinformation.availeffy = ''0'') and #Downcode.Slno= ' + @i + '  
				AND  
				((autodata.sttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  
				OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd AND autodata.ndtime > F.BatchStart )  
				OR ( autodata.sttime >= F.BatchStart   AND autodata.sttime <F.BatchEnd AND autodata.ndtime > F.BatchEnd )  
				OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd))  
				AND  
				((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
				OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
				AND  
				((F.BatchStart >= T.StartTime  AND F.BatchEnd <=T.EndTime)  
				OR ( F.BatchStart < T.StartTime  AND F.BatchEnd <= T.EndTime AND F.BatchEnd > T.StartTime )  
				OR ( F.BatchStart >= T.StartTime   AND F.BatchStart <T.EndTime AND F.BatchEnd > T.EndTime )  
				OR ( F.BatchStart < T.StartTime  AND F.BatchEnd > T.EndTime) )   
				group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface  
			)AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
			t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface   
			and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  '
		print @strsql
		exec(@Strsql)
	END

	select @i  =  @i + 1
End


 --select Machineid,machineinterface,Component,Compinterface,Operation,OpnInterface,Operator,OprInterface,BatchStart,BatchEnd,dbo.f_formattime(StdSetupTime,'hh:mm:ss') as StdSetupTime,
	--dbo.f_formattime(ActSetupTime,'hh:mm:ss') as ActSetupTime,dbo.f_formattime((A),'hh:mm:ss') as A,dbo.f_formattime((B),'hh:mm:ss') as B,dbo.f_formattime((C),'hh:mm:ss') as C,
	--dbo.f_formattime((D),'hh:mm:ss') as D,dbo.f_formattime((E),'hh:mm:ss') as E,dbo.f_formattime((F),'hh:mm:ss') as F,dbo.f_formattime((G),'hh:mm:ss') as G,dbo.f_formattime((H),'hh:mm:ss') as H,
	--dbo.f_formattime((I),'hh:mm:ss') as I,dbo.f_formattime((J),'hh:mm:ss') as J,dbo.f_formattime((K),'hh:mm:ss') as K,dbo.f_formattime((L),'hh:mm:ss') as L,dbo.f_formattime((M),'hh:mm:ss') as M,
	--dbo.f_formattime((N),'hh:mm:ss') as N,dbo.f_formattime((O),'hh:mm:ss') as O
	--from #FinalTarget  
	--order By MachineID,Component,Operation

	 select Machineid,machineinterface,Component,Compinterface,Operation,OpnInterface,Operator,OprInterface,BatchStart,BatchEnd,dbo.f_formattime(StdSetupTime,'hh:mm:ss') as StdSetupTime,
	dbo.f_formattime(ActSetupTime,'hh:mm:ss') as ActSetupTime
	from #FinalTarget 
	order By BatchStart

	 select Component,Compinterface,dbo.f_formattime((sum(isnull(A,0))),'hh:mm:ss') as A,dbo.f_formattime((sum(isnull(B,0))),'hh:mm:ss') as B,dbo.f_formattime((sum(isnull(C,0))),'hh:mm:ss') as C,
	dbo.f_formattime((sum(isnull(D,0))),'hh:mm:ss') as D,dbo.f_formattime((sum(isnull(E,0))),'hh:mm:ss') as E,dbo.f_formattime((sum(isnull(F,0))),'hh:mm:ss') as F,dbo.f_formattime((sum(isnull(G,0))),'hh:mm:ss') as G,
	dbo.f_formattime((sum(isnull(H,0))),'hh:mm:ss') as H,dbo.f_formattime((sum(isnull(I,0))),'hh:mm:ss') as I,dbo.f_formattime((sum(isnull(J,0))),'hh:mm:ss') as J,dbo.f_formattime((sum(isnull(K,0))),'hh:mm:ss') as K,
	dbo.f_formattime((sum(isnull(L,0))),'hh:mm:ss') as L,dbo.f_formattime((sum(isnull(M,0))),'hh:mm:ss') as M,dbo.f_formattime((sum(isnull(N,0))),'hh:mm:ss') as N,dbo.f_formattime((sum(isnull(O,0))),'hh:mm:ss') as O
	from #FinalTarget 
	Group by Component,Compinterface
	order By Component


END
