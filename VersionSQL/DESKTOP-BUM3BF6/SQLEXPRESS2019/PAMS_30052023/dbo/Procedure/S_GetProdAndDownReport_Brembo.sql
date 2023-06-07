/****** Object:  Procedure [dbo].[S_GetProdAndDownReport_Brembo]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
-- Author:		Anjana  C V
-- Create date: 03 October 2019
--Modified date: 03 October 2019
-- Description:	
-- [S_GetProdAndDownReport_Brembo] 'AMS MILLING','2019-07-01 06:00:00','2019-07-30 06:00:00'
**************************************************************************************************/
CREATE PROCEDURE [dbo].[S_GetProdAndDownReport_Brembo]
	@MachineId nvarchar(50) ,
	@StartDate DateTime ,
	@EndDate DateTime 	
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

Declare @strsql nvarchar(4000)  
Declare @strmachine nvarchar(50)  
Declare @timeformat as nvarchar(12)  
Declare @CurStrtTime as datetime  
Declare @CurEndTime as datetime  


CREATE TABLE #Target
(
pDate DateTime,
Shift nvarchar(50),
ShiftId int,
ShiftStart datetime,  
ShiftEnd datetime,  
MachineId  nvarchar(50),
MachineInt  nvarchar(50),
CompId  nvarchar(50),
CompInt  nvarchar(50),
OperationId nvarchar(50),
OperationInt nvarchar(50),
OperatorId nvarchar(50),
OperatorInt nvarchar(50),
OkComponents int default 0,
RejComponents int default 0,
Rework int default 0,
Components int default 0,
BT float,
CT float,
D1 float,
D2 float,
D3 float,
D4 float,
D5 float,
D6 float,
D7 float,
D8 float,
D9 float,
D10 float,
D11 float,
D12 float,
D13 float,
D14 float,
D15 float,
D16 float,
D17 float,
D18 float,
D19 float,
TEO FLoat,
ProdTime Float
)

CREATE TABLE #ShiftDetails   
(  
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime,
 ShiftId int   
)  
  
  
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

Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50)
)

Insert into #Downcode(Downid)
Select top 19 downid from downcodeinformation where --catagory not in('Management Loss')and
SortOrder<=19 and ISNULL(SortOrder,0) <>  0  
order by sortorder

Select @strsql = ''
Select @CurStrtTime=@StartDate  
Select @CurEndTime=@EndDate  
Select @timeformat = 'hh'  
  
while @CurStrtTime<=@CurEndTime  
BEGIN  
 INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
 EXEC s_GetShiftTime @CurStrtTime,''  
 SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)  
END   

Update #ShiftDetails
SET ShiftId = T.ShiftId
FROM (SELECT ShiftID,ShiftName from shiftdetails where Running = 1) t Inner join #ShiftDetails S on T.ShiftName= S.Shift

Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@StartDate,120)+''' and ndtime <= '''+ convert(nvarchar(25),@EndDate,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartDate,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndDate,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartDate,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartDate,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@EndDate,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@StartDate,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndDate,120)+''' and sttime<'''+convert(nvarchar(25),@EndDate,120)+''' ) )'  
print @strsql  
exec (@strsql)  

  INSERT INTO #Target (pDate,Shift,ShiftId,ShiftStart,ShiftEnd,MachineId,MachineInt,CompId,CompInt,OperationId,OperationInt,OperatorId,OperatorInt,BT,CT,TEO) 
		SELECT DISTINCT T.PDate,T.Shift,T.ShiftId,T.ShiftStart,T.ShiftEnd,m.machineid,m.InterfaceID,C.componentid,C.InterfaceID,COP.operationno,COP.InterfaceID,E.Employeeid,E.interfaceid,0.5,0.33,datediff(s,T.ShiftStart,T.ShiftEnd)
		FROM #ShiftDetails T
		LEFT JOIN #T_autodata autodata
		ON ((autodata.msttime >= T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)  
		OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )  
		OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
		OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd))
		LEFT JOIN machineinformation m On M.InterfaceID = autodata.mc AND  M.machineid = @MachineId
		LEFT JOIN componentinformation C On C.InterfaceID = autodata.comp
		LEFT JOIN employeeinformation E On E.InterfaceID = autodata.opr
		LEFT JOIN componentoperationpricing COP ON autodata.opn = COP.InterfaceID  
		AND C.componentid = COP.componentid  and COP.machineid=M.machineid 

--For Prodtime  
UPDATE #Target SET ProdTime = isnull(ProdTime,0) + isNull(t2.cycle,0)  
from  
(select S.MachineID,S.CompId,S.OperationId,S.OperatorId,S.ShiftStart,S.ShiftEnd,  
 sum(case when ((autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd)) then  (autodata.cycletime+autodata.loadunload)  
   when ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd)) then DateDiff(second, S.ShiftStart, autodata.ndtime)  
   when ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, autodata.mstTime, S.ShiftEnd)  
   when ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, S.ShiftStart, S.ShiftEnd) END ) as cycle  
from #T_autodata autodata   
inner join #Target S on autodata.mc = S.MachineInt and autodata.comp=S.CompInt and autodata.opn=S.OperationInt and autodata.opr = S.OperatorInt  
where (autodata.datatype=1) AND(( (autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd))  
OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd))  
OR ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))  
OR((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)))  
group by S.MachineID,S.CompId,S.OperationId,S.OperatorId,S.ShiftStart,S.ShiftEnd  
) as t2 inner join #Target on t2.MachineID = #Target.MachineID and  t2.CompId = #Target.CompId and   
t2.OperationId = #Target.OperationId and t2.OperatorId = #Target.OperatorId  
and t2.ShiftStart=#Target.ShiftStart and t2.ShiftEnd=#Target.ShiftEnd  
  
  
--Type 2  
UPDATE  #Target SET ProdTime = isnull(ProdTime,0) - isNull(t2.Down,0)  
FROM  
(Select T1.mc,T1.comp,T1.opn,T1.opr,T1.ShiftStart,T1.ShiftEnd,  
SUM(  
CASE  
 When autodata.sttime <= T1.ShiftStart Then datediff(s, T1.ShiftStart,autodata.ndtime )  
 When autodata.sttime > T1.ShiftStart Then datediff(s,autodata.sttime,autodata.ndtime)  
END) as Down  
From #T_autodata AutoData INNER Join  
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.opr,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,  
  ST1.ShiftStart as ShiftStart,ST1.ShiftEnd as ShiftEnd From #T_autodata AutoData  
  inner join #Target ST1 ON ST1.MachineInt=Autodata.mc and ST1.CompInt=Autodata.Comp and  
  ST1.OperationInt=Autodata.opn and Autodata.opr = ST1.OperatorInt  
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And  
  (AutoData.msttime < ST1.ShiftStart)And (AutoData.ndtime > ST1.ShiftStart) AND (AutoData.ndtime <= ST1.ShiftEnd)  
 ) as T1 on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.opr=Autodata.opr  
Where AutoData.DataType=2  
And ( autodata.Sttime > T1.Sttime )  
And ( autodata.ndtime <  T1.ndtime )  
AND ( autodata.ndtime >  T1.ShiftStart )  
GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.ShiftStart,T1.ShiftEnd)AS T2 Inner Join #Target on t2.mc = #Target.MachineInt and  
t2.comp = #Target.CompInt and t2.opn = #Target.OperationInt and  t2.opr = #Target.OperatorInt   
and t2.ShiftStart=#Target.ShiftStart and t2.ShiftEnd=#Target.ShiftEnd  
  
  
  
--Type 3  
UPDATE  #Target SET ProdTime = isnull(ProdTime,0) - isNull(t2.Down,0)  
FROM  
(Select T1.mc,T1.comp,T1.opn,T1.opr,T1.ShiftStart,T1.ShiftEnd,  
SUM(CASE  
 When autodata.ndtime > T1.ShiftEnd Then datediff(s,autodata.sttime, T1.ShiftEnd )  
 When autodata.ndtime <= T1.ShiftEnd Then datediff(s , autodata.sttime,autodata.ndtime)  
END) as Down  
From #T_autodata AutoData INNER Join  
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.opr,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,  
  ST1.ShiftStart as ShiftStart,ST1.ShiftEnd as ShiftEnd From #T_autodata AutoData  
  inner join #Target ST1 ON ST1.MachineInt=Autodata.mc and ST1.CompInt=Autodata.Comp and  
  ST1.OperationInt=Autodata.opn and Autodata.opr = ST1.OperatorInt  
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And  
  (AutoData.sttime >= ST1.ShiftStart)And (AutoData.ndtime > ST1.ShiftEnd) and (AutoData.sttime< ST1.ShiftEnd)  
   ) as T1  
ON t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.opr=Autodata.opr  
Where AutoData.DataType=2  
And (T1.Sttime < autodata.sttime)  
And ( T1.ndtime > autodata.ndtime)  
AND (autodata.sttime  <  T1.ShiftEnd)  
GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.ShiftStart,T1.ShiftEnd )AS T2 Inner Join #Target on t2.mc = #Target.MachineInt and  
t2.comp = #Target.CompInt and t2.opn = #Target.OperationInt and  t2.opr = #Target.OperatorInt   
and t2.ShiftStart=#Target.ShiftStart and t2.ShiftEnd=#Target.ShiftEnd  
  
  
--For Type4  
UPDATE  #Target SET ProdTime = isnull(ProdTime,0) - isNull(t2.Down,0)  
FROM  
(Select T1.mc,T1.comp,T1.opn,T1.opr,T1.ShiftStart,T1.ShiftEnd,  
SUM(CASE  
 When autodata.sttime >= T1.ShiftStart AND autodata.ndtime <= T1.ShiftEnd Then datediff(s , autodata.sttime,autodata.ndtime)  
 When autodata.sttime < T1.ShiftStart And autodata.ndtime >T1.ShiftStart AND autodata.ndtime<=T1.ShiftEnd Then datediff(s, T1.ShiftStart,autodata.ndtime )  
 When autodata.sttime >= T1.ShiftStart AND autodata.sttime<T1.ShiftEnd AND autodata.ndtime>T1.ShiftEnd Then datediff(s,autodata.sttime, T1.ShiftEnd )  
 When autodata.sttime<T1.ShiftStart AND autodata.ndtime>T1.ShiftEnd   Then datediff(s , T1.ShiftStart,T1.ShiftEnd)  
END) as Down  
From #T_autodata AutoData INNER Join  
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.opr,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,  
  ST1.ShiftStart as ShiftStart,ST1.ShiftEnd as ShiftEnd  From #T_autodata AutoData  
  inner join #Target ST1 ON ST1.MachineInt=Autodata.mc and ST1.CompInt=Autodata.Comp and  
  ST1.OperationInt=Autodata.opn and Autodata.opr = ST1.OperatorInt  
  where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And   
  (AutoData.msttime <  ST1.ShiftStart) And (AutoData.ndtime > ST1.ShiftEnd)  
 ) as T1  
on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.opr=Autodata.opr   
Where AutoData.DataType=2  
And (T1.Sttime < autodata.sttime  )  
And ( T1.ndtime >  autodata.ndtime)  
AND (autodata.ndtime  >  T1.ShiftStart)  
AND (autodata.sttime  <  T1.ShiftEnd)  
GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.ShiftStart,T1.ShiftEnd  
 )AS T2 Inner Join #Target on t2.mc = #Target.MachineInt and  
t2.comp = #Target.CompInt and t2.opn = #Target.OperationInt and  t2.opr = #Target.OperatorInt   
and t2.ShiftStart=#Target.ShiftStart and t2.ShiftEnd=#Target.ShiftEnd  
  

--Calculation of PartsCount Begins-- 
UPDATE #Target SET components = ISNULL(components,0) + ISNULL(t2.comp1,0)
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.opr,T1.ShiftStart,T1.ShiftEnd,
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1
--,SUM((O.cycletime/ISNULL(O.SubOperations,1))* T1.OrginalCount) C1N1
     From (select mc,comp,opn,opr,ShiftStart,ShiftEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata  
     INNER JOIN #Target F on F.MachineInt=Autodata.mc and F.CompInt=Autodata.comp and F.OperationInt = Autodata.opn and F.OperatorInt=Autodata.opr  
     where (autodata.ndtime>F.ShiftStart) and (autodata.ndtime<=F.ShiftEnd) and (autodata.datatype=1)  
     Group By mc,comp,opn,opr,ShiftStart,ShiftEnd) as T1  
 INNER JOIN #Target F on F.MachineInt=T1.mc and F.CompInt=T1.comp and F.OperationInt = T1.opn and F.OperatorInt=T1.opr  
 and F.ShiftStart=T1.ShiftStart and F.ShiftEnd=T1.ShiftEnd
 Inner join componentinformation C on F.CompInt = C.interfaceid  
 Inner join ComponentOperationPricing O ON  F.OperationId = O.interfaceid and C.Componentid=O.componentid  
 inner join machineinformation on machineinformation.machineid =O.machineid  
 and F.MachineInt=machineinformation.interfaceid  
 GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.ShiftStart,T1.ShiftEnd  
) As T2 Inner Join #Target on T2.mc = #Target.MachineInt and  
T2.comp = #Target.CompInt and T2.opn = #Target.OperationInt and  T2.opr = #Target.OperatorInt   
and T2.ShiftStart=#Target.ShiftStart and T2.ShiftEnd=#Target.ShiftEnd  
  
--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
--BEGIN  
    
-- UPDATE #Target SET components=ISNULL(components,0)- isnull(t2.PlanCt,0) ,CN = isnull(CN,0) - isNull(t2.C1N1,0) 
--  FROM ( select autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.ShiftStart,F.ShiftEnd,
--  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt,
--	SUM((CO.cycletime * ISNULL(PartsCount,1))/ISNULL(CO.SubOperations,1))  C1N1
--   from #T_autodata autodata   
--     INNER JOIN #Target F on F.MachineInt=autodata.mc and F.CompInt=autodata.comp and F.OperationId = autodata.opn and F.OperatorInt=autodata.opr  
--  Inner jOIN #PlannedDownTimesShift T on T.MachineInt=autodata.mc    
--  inner join machineinformation M on autodata.mc=M.Interfaceid  
--  Inner join componentinformation CI on autodata.comp=CI.interfaceid   
--  inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and  
--  CI.componentid=CO.componentid  and CO.machineid=M.machineid  
--  WHERE autodata.DataType=1 and  
--  (autodata.ndtime>F.ShiftStart) and (autodata.ndtime<=F.ShiftEnd)   
--  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
--   Group by autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.ShiftStart,F.ShiftEnd,CO.SubOperations   
-- ) as T2 Inner Join #Target on T2.mc = #Target.MachineInt and  
-- T2.comp = #Target.CompInt and T2.opn = #Target.OperationInt and  T2.opr = #Target.OperatorInt   
-- and T2.ShiftStart=#Target.ShiftStart and T2.ShiftEnd=#Target.ShiftEnd  
   
--END  
-- select * from AutodataRejections

Update #Target set RejComponents = isnull(RejComponents,0) + isnull(T1.RejQty,0)    
From    
( Select mc,comp,opn,opr,SUM(A.Rejection_Qty) as RejQty,T.ShiftStart,T.ShiftEnd from AutodataRejections A    
inner join (SELECT MachineInt,CompInt,OperationInt,OperatorInt,ShiftStart,ShiftEnd from #Target) T 
 on T.MachineInt=A.mc and T.CompInt = A.comp and T.OperationInt = A.opn and T.OperatorInt = A.opr
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
where A.CreatedTS>=T.ShiftStart and A.CreatedTS<T.ShiftEnd and A.flag = 'Rejection'    
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'    
group by A.mc,A.comp,A.opn,A.opr,T.ShiftStart,T.ShiftEnd
)T1 inner join #Target on T1.mc = #Target.MachineInt and  
 T1.comp = #Target.CompInt and T1.opn = #Target.OperationInt and  T1.opr = #Target.OperatorInt   
 and T1.ShiftStart=#Target.ShiftStart and T1.ShiftEnd=#Target.ShiftEnd       
   
   
Update #Target set RejComponents = isnull(RejComponents,0) + isnull(T1.RejQty,0)    
From    
( Select A.mc,comp,opn,opr,SUM(A.Rejection_Qty) as RejQty,T.ShiftStart,T.ShiftEnd from AutodataRejections A      
Inner join (SELECT MachineInt,CompInt,OperationInt,OperatorInt,Pdate,ShiftStart,ShiftEnd,ShiftId from #Target) T 
 on T.MachineInt=A.mc and T.CompInt = A.comp and T.OperationInt = A.opn and T.OperatorInt = A.opr
 AND convert(nvarchar(10),(A.RejDate),126)=T.Pdate and A.RejShift=T.shiftid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid      
where A.flag = 'Rejection' and  --A.Rejshift in (T.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (T.Pdate) and  
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
group by A.mc,A.comp,A.opn,A.opr,T.ShiftStart,T.ShiftEnd
)T1 inner join #Target on T1.mc = #Target.MachineInt and  
 T1.comp = #Target.CompInt and T1.opn = #Target.OperationInt and  T1.opr = #Target.OperatorInt   
 and T1.ShiftStart=#Target.ShiftStart and T1.ShiftEnd=#Target.ShiftEnd       
    

Update #Target set Rework = isnull(Rework,0) + isnull(T1.ReworkQty,0)    
From    
( Select mc,comp,opn,opr,SUM(A.Rejection_Qty) as ReworkQty,T.ShiftStart,T.ShiftEnd from AutodataRejections A    
inner join (SELECT MachineInt,CompInt,OperationInt,OperatorInt,ShiftStart,ShiftEnd from #Target) T 
 on T.MachineInt=A.mc and T.CompInt = A.comp and T.OperationInt = A.opn and T.OperatorInt = A.opr
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
where A.CreatedTS>=T.ShiftStart and A.CreatedTS<T.ShiftEnd and A.flag = 'MarkedforRework'    
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'    
group by A.mc,A.comp,A.opn,A.opr,T.ShiftStart,T.ShiftEnd
)T1 inner join #Target on T1.mc = #Target.MachineInt and  
 T1.comp = #Target.CompInt and T1.opn = #Target.OperationInt and  T1.opr = #Target.OperatorInt   
 and T1.ShiftStart=#Target.ShiftStart and T1.ShiftEnd=#Target.ShiftEnd       
   
   
Update #Target set Rework = isnull(Rework,0) + isnull(T1.ReworkQty,0)    
From    
( Select A.mc,comp,opn,opr,SUM(A.Rejection_Qty) as ReworkQty,T.ShiftStart,T.ShiftEnd from AutodataRejections A      
Inner join (SELECT MachineInt,CompInt,OperationInt,OperatorInt,Pdate,ShiftStart,ShiftEnd,ShiftId from #Target) T 
 on T.MachineInt=A.mc and T.CompInt = A.comp and T.OperationInt = A.opn and T.OperatorInt = A.opr
 AND convert(nvarchar(10),(A.RejDate),126)=T.Pdate and A.RejShift=T.shiftid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid      
where A.flag = 'MarkedforRework' and  --A.Rejshift in (T.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (T.Pdate) and  
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
group by A.mc,A.comp,A.opn,A.opr,T.ShiftStart,T.ShiftEnd
)T1 inner join #Target on T1.mc = #Target.MachineInt and  
 T1.comp = #Target.CompInt and T1.opn = #Target.OperationInt and  T1.opr = #Target.OperatorInt   
 and T1.ShiftStart=#Target.ShiftStart and T1.ShiftEnd=#Target.ShiftEnd       
    
Update #Target SET OkComponents = Components - RejComponents

----- Top 19 downTime Calculation-----
declare @i as nvarchar(10)
declare @colName as nvarchar(50)
Select @i=1

while @i <=19
Begin
	Select @ColName = Case  when @i=1 then 'D1'
							when @i=2 then 'D2'
							when @i=3 then 'D3'
							when @i=4 then 'D4'
							when @i=5 then 'D5'
							when @i=6 then 'D6'
							when @i=7 then 'D7'
							when @i=8 then 'D8'
							when @i=9 then 'D9'
							when @i=10 then 'D10'
							when @i=11 then 'D11'
							when @i=12 then 'D12'
							when @i=13 then 'D13'
							when @i=14 then 'D14'
							when @i=15 then 'D15'
							when @i=16 then 'D16'
							when @i=17 then 'D17'
							when @i=18 then 'D18'
							when @i=19 then 'D19'

						 END



	 ---Get the down times which are not of type Management Loss  
	 Select @strsql = ''
	 Select @strsql = @strsql + ' UPDATE #Target SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t2.down,0)  
	 from  
	 (select  F.Shiftstart,F.ShiftEnd,F.MachineInt,F.CompInt,F.OperationInt,F.OperatorInt,  
	  sum (CASE  
		WHEN (autodata.msttime >= F.Shiftstart  AND autodata.ndtime <=F.ShiftEnd)  THEN autodata.loadunload  
		WHEN ( autodata.msttime < F.Shiftstart  AND autodata.ndtime <= F.ShiftEnd  AND autodata.ndtime > F.Shiftstart ) THEN DateDiff(second,F.Shiftstart,autodata.ndtime)  
		WHEN ( autodata.msttime >= F.Shiftstart   AND autodata.msttime <F.ShiftEnd  AND autodata.ndtime > F.ShiftEnd  ) THEN DateDiff(second,autodata.msttime,F.ShiftEnd )  
		WHEN ( autodata.msttime < F.Shiftstart  AND autodata.ndtime > F.ShiftEnd ) THEN DateDiff(second,F.Shiftstart,F.ShiftEnd )  
		END ) as down  
		from #T_autodata autodata   
		inner join #Target F on autodata.mc = F.MachineInt and autodata.comp=F.CompInt and autodata.opn=F.OperationInt and autodata.opr = F.OperatorInt  
		inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
		inner join #Downcode on #Downcode.downid= downcodeinformation.downid
		where (autodata.datatype=''2'') AND  #Downcode.Slno= ' + @i + ' and 
		(( (autodata.msttime>=F.Shiftstart) and (autodata.ndtime<=F.ShiftEnd))  
		   OR ((autodata.msttime<F.Shiftstart) and (autodata.ndtime>F.Shiftstart) and (autodata.ndtime<=F.ShiftEnd))  
		   OR ((autodata.msttime>=F.Shiftstart) and (autodata.msttime<F.ShiftEnd) and (autodata.ndtime>F.ShiftEnd))  
		   OR((autodata.msttime<F.Shiftstart) and (autodata.ndtime>F.ShiftEnd)))   
		AND (downcodeinformation.availeffy = ''0'')  
		group by F.Shiftstart,F.ShiftEnd,F.MachineInt,F.CompInt,F.OperationInt,F.OperatorInt  
	  ) as t2 Inner Join #Target on t2.MachineInt = #Target.MachineInt and  
	 t2.CompInt = #Target.CompInt and t2.OperationInt = #Target.OperationInt and  t2.OperatorInt = #Target.OperatorInt   
	 and t2.Shiftstart=#Target.Shiftstart and t2.ShiftEnd=#Target.ShiftEnd '
     print @strsql
	 exec(@strsql) 
	 
		--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
		--BEGIN   
		--	 Select @strsql = '' 
		--	 Select @strsql = @strsql + 'UPDATE  #Target SET ' + @ColName + ' = isnull(' + @ColName + ',0) - isNull(T2.PPDT ,0)  
		--	 FROM(  
		--	 SELECT F.Shiftstart,F.ShiftEnd,F.MachineInt,F.CompInt,F.OperationInt,F.OperatorInt,  
		--		SUM  
		--		(CASE  
		--		WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
		--		WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
		--		WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
		--		WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
		--		END ) as PPDT  
		--		FROM #T_autodata AutoData  
		--		CROSS jOIN #PlannedDownTimesShift T  
		--		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
		--		INNER JOIN #Target F on F.MachineInt=Autodata.mc and F.CompInt=Autodata.comp and F.OperationInt = Autodata.opn and F.OperatorInt=Autodata.opr  
		--		inner join #Downcode on #Downcode.downid= downcodeinformation.downid
			
		--		WHERE autodata.DataType=''2'' AND T.MachineInt=autodata.mc AND (downcodeinformation.availeffy = ''0'') and #Downcode.Slno= ' + @i + '  
		--		 AND  
		--		 ((autodata.sttime >= F.Shiftstart  AND autodata.ndtime <=F.ShiftEnd)  
		--		 OR ( autodata.sttime < F.Shiftstart  AND autodata.ndtime <= F.ShiftEnd AND autodata.ndtime > F.Shiftstart )  
		--		 OR ( autodata.sttime >= F.Shiftstart   AND autodata.sttime <F.ShiftEnd AND autodata.ndtime > F.ShiftEnd )  
		--		 OR ( autodata.sttime < F.Shiftstart  AND autodata.ndtime > F.ShiftEnd))  
		--		 AND  
		--		 ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
		--		 OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
		--		 OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
		--		 OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
		--		 AND  
		--		 ((F.Shiftstart >= T.StartTime  AND F.ShiftEnd <=T.EndTime)  
		--		 OR ( F.Shiftstart < T.StartTime  AND F.ShiftEnd <= T.EndTime AND F.ShiftEnd > T.StartTime )  
		--		 OR ( F.Shiftstart >= T.StartTime   AND F.Shiftstart <T.EndTime AND F.ShiftEnd > T.EndTime )  
		--		 OR ( F.Shiftstart < T.StartTime  AND F.ShiftEnd > T.EndTime) )   
		--		 group  by F.Shiftstart,F.ShiftEnd,F.MachineInt,F.CompInt,F.OperationInt,F.OperatorInt  
		--	 )AS T2  Inner Join #Target on t2.MachineInt = #Target.MachineInt and  
		--	 t2.CompInt = #Target.CompInt and t2.OperationInt = #Target.OperationInt and  t2.OperatorInt = #Target.OperatorInt   
		--	 and t2.Shiftstart=#Target.Shiftstart and t2.ShiftEnd=#Target.ShiftEnd  '
		--	print @strsql
		--	exec(@Strsql)
		--END

	select @i  =  @i + 1
End

select * from #Downcode
select PDate,Shift,MachineId,CompId,OperatorId,OkComponents,Bt,CT,
dbo.f_FormatTime(D1,@TimeFormat) D1,dbo.f_FormatTime(D2,@TimeFormat) D2,dbo.f_FormatTime(D3,@TimeFormat) D3,dbo.f_FormatTime(D4,@TimeFormat) D4,
dbo.f_FormatTime(D5,@TimeFormat) D5,dbo.f_FormatTime(D6,@TimeFormat) D6,dbo.f_FormatTime(D7,@TimeFormat) D7,dbo.f_FormatTime(D8,@TimeFormat) D8,
dbo.f_FormatTime(D9,@TimeFormat) D9,dbo.f_FormatTime(D10,@TimeFormat) D10,dbo.f_FormatTime(D11,@TimeFormat) D11,dbo.f_FormatTime(D12,@TimeFormat) D12,
dbo.f_FormatTime(D13,@TimeFormat) D13,dbo.f_FormatTime(D14,@TimeFormat) D14,dbo.f_FormatTime(D15,@TimeFormat) D15,dbo.f_FormatTime(D16,@TimeFormat) D16,
dbo.f_FormatTime(D17,@TimeFormat) D17,dbo.f_FormatTime(D18,@TimeFormat) D18,dbo.f_FormatTime(D19,@TimeFormat) D19,dbo.f_FormatTime(TEO,@TimeFormat) TEO,
dbo.f_FormatTime(ProdTime,@TimeFormat) ProdTime 
from #Target order by Pdate,ShiftStart,machineID,CompId,OperationId

END
