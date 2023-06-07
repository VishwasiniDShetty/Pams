/****** Object:  Procedure [dbo].[s_GetProductionandRejectionTrend]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetProductionandRejectionTrend] '2016-03-01','2016-03-15','ABDS LINE','week'
CREATE PROCEDURE [dbo].[s_GetProductionandRejectionTrend]
@StartTime datetime,
@Endtime datetime,
@Machineid nvarchar(50),
@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

Create table #ProdandRejDetails
(
	Startdate datetime,
	Enddate datetime,
	Weekno nvarchar(50),
	ProdQty int,
	Rejqty int,
	ProdTarget int,
	RejTarget int
)

Create table #ProdTarget
(
	Startdate datetime,
	Enddate datetime,
	Weekno nvarchar(50),
	ProdQty int,
	Rejqty int,
	ProdTarget int,
	RejTarget int
)


Create table #TempProdTarget
(
	Startdate datetime,
	Enddate datetime,
	Comp nvarchar(50),
	ProdTarget int
)

Declare @Startdate as datetime
Declare @Enddate as datetime

declare @Curstart as datetime
declare @curend as datetime

Select @Curstart = dbo.f_GetLogicalDay(@StartTime,'start')
Select @curend = dbo.f_GetLogicalDay(@Endtime,'start')

While @Curstart<=@curend
BEGIN
	Insert into  #ProdTarget(Startdate,Enddate,ProdQty,ProdTarget,Rejqty,RejTarget)
	Select Convert(nvarchar(20),dbo.f_GetLogicalDay(@Curstart,'start'),120),Convert(nvarchar(20),dbo.f_GetLogicalDay(@Curstart,'End'),120),0,0,0,0
	Select @Curstart = Dateadd(Day,1,@Curstart)
END

Insert into #TempProdTarget(Startdate,Enddate,comp,ProdTarget)
Select T.Startdate,T.Enddate,C.Componentid,0
from autodata A
Inner join machineinformation M on M.interfaceid=A.mc
Inner join componentinformation C ON A.Comp=C.interfaceid
Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
Cross join #ProdTarget T
WHERE A.DataType=1 and M.machineid=@Machineid
AND (A.ndtime > T.Startdate  AND A.ndtime <=T.Enddate)
Group by T.Startdate,T.Enddate,C.Componentid


Update #TempProdTarget set ProdTarget = Isnull(H.ProdTarget,0) + Isnull(T1.ProdTarget,0) from
(
select H.startdate,H.comp,T.idealcount as ProdTarget
from (
 select S.date,
		S.Component,
		S.idealcount,
		row_number() over(partition by S.Component order by S.date desc) as rn
 from (select  machine,date,component,sum(idealcount)  as idealcount from loadschedule where Machine=@machineid 
 and component in(select distinct comp from #TempProdTarget)  group by date,component,machine )S
 ) as T inner join #TempProdTarget H on T.Component=H.comp 
where T.rn <= 1 )T1 inner join #TempProdTarget H on T1.Comp=H.comp 

If @param='Day'
BEGIN

		Select @Startdate = dbo.f_GetLogicalDay(@StartTime,'start')
		Select @Enddate = dbo.f_GetLogicalDay(@Endtime,'start')

		While @Startdate<=@Enddate
		BEGIN
			Insert into  #ProdandRejDetails(Startdate,Enddate,ProdQty,ProdTarget,Rejqty,RejTarget)
			Select Convert(nvarchar(20),dbo.f_GetLogicalDay(@Startdate,'start'),120),Convert(nvarchar(20),dbo.f_GetLogicalDay(@Startdate,'End'),120),0,0,0,0
			Select @Startdate = Dateadd(Day,1,@Startdate)
		END

		Select @Startdate = Min(Startdate) from #ProdandRejDetails 
		Select @Enddate = Max(Enddate) from #ProdandRejDetails 

		Update #ProdandRejDetails set ProdQty = Isnull(ProdQty,0) + Isnull(T1.Comp,0) from  
		(Select T.Startdate,T.Enddate,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
		from autodata A
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross join #ProdandRejDetails T
		WHERE A.DataType=1 and M.machineid=@Machineid
		AND (A.ndtime > T.Startdate  AND A.ndtime <=T.Enddate)
		Group by T.Startdate,T.Enddate)T1 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate

		Update #ProdandRejDetails set ProdTarget = Isnull(T1.ProdTarget,0) from
		(select Startdate,Enddate,sum(ProdTarget) as ProdTarget from #TempProdTarget
		group by Startdate,Enddate)T1 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN

			Update #ProdandRejDetails set Prodqty = Isnull(Prodqty,0) - Isnull(T2.Comp,0) from  (
			select T1.Startdate,T1.Enddate,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From 
			( 
				select S.Startdate,S.Enddate,mc,comp,opn,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
				Inner join machineinformation M on M.interfaceid=autodata.mc
				Cross join #ProdandRejDetails S
				CROSS JOIN PlannedDownTimes T
				WHERE autodata.DataType=1 And T.Machine = M.Machineid and M.Machineid=@Machineid
				AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
				AND (autodata.ndtime > S.Startdate  AND autodata.ndtime <=S.Enddate)
				Group by S.Startdate,S.Enddate,mc,comp,opn
			) as T1
			Inner join Machineinformation M on M.interfaceID = T1.mc
			Inner join componentinformation C on T1.Comp=C.interfaceid
			Inner join #ProdandRejDetails T on T.Startdate=T1.Startdate and T.Enddate=T1.Enddate
			Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
			GROUP BY T1.Startdate,T1.Enddate
			) as T2 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T2.Startdate
				and #ProdandRejDetails.Enddate=T2.Enddate 

			Update #ProdandRejDetails set ProdTarget = Isnull(#ProdandRejDetails.ProdTarget,0) - Isnull(T1.PDTTarget,0) from
			(select sum(ProdTarget) as PDTTarget from #ProdandRejDetails where convert(nvarchar(10),startdate,120) in 
			(select convert(nvarchar(10),holiday,120) from holidaylist where machineid=@Machineid and convert(nvarchar(10),holiday,120)>=convert(nvarchar(10),@startdate,120) and convert(nvarchar(10),holiday,120)<=convert(nvarchar(10),@Enddate,120)))T1 

		END

		Update #ProdandRejDetails set Rejqty =  Isnull(#ProdandRejDetails.Rejqty,0) + Isnull(T1.Rejqty,0) from
		(Select T.Startdate,T.Enddate,SUM(A.Rejection_Qty) as Rejqty
		from AutodataRejections A 
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross join #ProdandRejDetails T
		where A.Flag='Rejection' and M.machineid=@Machineid 
		and (A.CreatedTS>=T.Startdate  and A.CreatedTS<=T.Enddate)
		group by T.Startdate,T.Enddate
		)T1 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate

		Update #ProdandRejDetails set RejTarget = T1.RejTarget from
		(Select T.startdate,T.enddate,(100-Isnull(QE,95)) as RejTarget from EfficiencyTarget,#ProdandRejDetails T where machineid=@Machineid and
		 datepart(month,convert(nvarchar(10),T.startdate,120)) between datepart(month,convert(nvarchar(10),EfficiencyTarget.startdate,120)) and 
		 datepart(month,convert(nvarchar(10),EfficiencyTarget.enddate,120)) and Targetlevel='MONTH')T1  inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate

		Select Startdate,Enddate,Convert(nvarchar(2),datepart(day,Startdate)) + '-' + Convert(nvarchar(3),datename(month,Startdate)) as DisplayDate,ProdQty,ProdTarget,Rejqty,RejTarget from #ProdandRejDetails
END


If @param='Month'
BEGIN


		Select @Startdate = dbo.f_GetLogicalMonth(@StartTime,'Start')
		Select @Enddate=dbo.f_GetLogicalMonth(@Endtime,'start')

		While @Startdate<=@Enddate
		BEGIN
			Insert into  #ProdandRejDetails(Startdate,Enddate,ProdQty,ProdTarget,Rejqty,RejTarget)
			Select Convert(nvarchar(20),dbo.f_GetLogicalMonth(@Startdate,'Start'),120),Convert(nvarchar(20),dbo.f_GetLogicalMonth(@Startdate,'End'),120),0,0,0,0
			Select @Startdate = Dateadd(month,1,@Startdate)
		END

		Select @Startdate = Min(Startdate) from #ProdandRejDetails 
		Select @Enddate = Max(Enddate) from #ProdandRejDetails 

		Update #ProdandRejDetails set ProdQty = Isnull(ProdQty,0) + Isnull(T1.Comp,0) from  
		(Select T.Startdate,T.Enddate,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
		from autodata A
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross join #ProdandRejDetails T
		WHERE A.DataType=1 and M.machineid=@Machineid
		AND (A.ndtime > T.Startdate  AND A.ndtime <=T.Enddate)
		Group by T.Startdate,T.Enddate)T1 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate 



		Update #ProdandRejDetails set ProdTarget = Isnull(T1.ProdTarget,0) from
		(select P.Startdate,P.Enddate,sum(T.ProdTarget) as ProdTarget from #TempProdTarget T,#ProdandRejDetails P
		where T.Startdate>=P.Startdate and T.Enddate<=P.Enddate
		group by P.Startdate,P.Enddate)T1 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN

			Update #ProdandRejDetails set Prodqty = Isnull(Prodqty,0) - Isnull(T2.Comp,0) from  (
			select T1.Startdate,T1.Enddate,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From 
			( 
				select S.Startdate,S.Enddate,mc,comp,opn,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
				Inner join machineinformation M on M.interfaceid=autodata.mc
				Cross join #ProdandRejDetails S
				CROSS JOIN PlannedDownTimes T
				WHERE autodata.DataType=1 And T.Machine = M.Machineid and M.Machineid=@Machineid
				AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
				AND (autodata.ndtime > S.Startdate  AND autodata.ndtime <=S.Enddate)
				Group by S.Startdate,S.Enddate,mc,comp,opn
			) as T1
			Inner join Machineinformation M on M.interfaceID = T1.mc
			Inner join componentinformation C on T1.Comp=C.interfaceid
			Inner join #ProdandRejDetails T on T.Startdate=T1.Startdate and T.Enddate=T1.Enddate
			Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
			GROUP BY T1.Startdate,T1.Enddate
			) as T2 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T2.Startdate
				and #ProdandRejDetails.Enddate=T2.Enddate 

			Update #ProdandRejDetails set ProdTarget = Isnull(#ProdandRejDetails.ProdTarget,0) - Isnull(T1.PDTTarget,0) from
			(select sum(ProdTarget) as PDTTarget from #ProdandRejDetails where convert(nvarchar(10),startdate,120) in 
			(select convert(nvarchar(10),holiday,120) from holidaylist where machineid=@Machineid and convert(nvarchar(10),holiday,120)>=convert(nvarchar(10),@startdate,120) and convert(nvarchar(10),holiday,120)<=convert(nvarchar(10),@Enddate,120)))T1 

		END

		Update #ProdandRejDetails set Rejqty = Isnull(#ProdandRejDetails.Rejqty,0) + Isnull(T1.Rejqty,0) from
		(Select T.Startdate,T.Enddate,SUM(A.Rejection_Qty) as Rejqty
		from AutodataRejections A 
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross join #ProdandRejDetails T
		where A.Flag='Rejection' and M.machineid=@Machineid 
		and (A.CreatedTS>=T.Startdate  and A.CreatedTS<=T.Enddate)
		group by T.Startdate,T.Enddate
		)T1 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate

--		Update #ProdandRejDetails set RejTarget = T1.RejTarget from
--		(Select (100-Isnull(QE,95)) as RejTarget from EfficiencyTarget where machineid=@Machineid and
--		 convert(nvarchar(10),startdate,120)>=convert(nvarchar(10),@startdate,120) and convert(nvarchar(10),enddate,120)<=convert(nvarchar(10),@enddate,120) and Targetlevel='MONTH')T1

		Update #ProdandRejDetails set RejTarget = T1.RejTarget from
		(Select T.startdate,T.enddate,(100-Isnull(QE,95)) as RejTarget from EfficiencyTarget,#ProdandRejDetails T where machineid=@Machineid and
		 datepart(month,convert(nvarchar(10),T.startdate,120)) between datepart(month,convert(nvarchar(10),EfficiencyTarget.startdate,120)) and 
		 datepart(month,convert(nvarchar(10),EfficiencyTarget.enddate,120)) and Targetlevel='MONTH')T1  inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate

		Select Startdate,Enddate,Convert(nvarchar(3),datename(month,Startdate)) as DisplayDate,ProdQty,ProdTarget,Rejqty,RejTarget from #ProdandRejDetails
END


If @param='Week'
BEGIN

		Insert into  #ProdandRejDetails(Startdate,Enddate,Weekno,ProdQty,ProdTarget,Rejqty,RejTarget)
		select min(weekdate),Max(weekdate),weeknumber,0,0,0,0 from calender where weekdate>=@StartTime and weekdate<=@Endtime
		group by weeknumber 

		update #ProdandRejDetails set Startdate = convert(nvarchar(20),dbo.f_GetLogicalday(Startdate,'Start'),120)
		update #ProdandRejDetails set Enddate = convert(nvarchar(20),dbo.f_GetLogicalday(Enddate,'end'),120)

		Select @Startdate = Min(Startdate) from #ProdandRejDetails 
		Select @Enddate = Max(Enddate) from #ProdandRejDetails 

		Update #ProdandRejDetails set ProdQty = Isnull(ProdQty,0) + Isnull(T1.Comp,0) from  
		(Select T.Startdate,T.Enddate,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
		from autodata A
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross join #ProdandRejDetails T
		WHERE A.DataType=1 and M.machineid=@Machineid
		AND (A.ndtime > T.Startdate  AND A.ndtime <=T.Enddate)
		Group by T.Startdate,T.Enddate)T1 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate 


		Update #ProdandRejDetails set ProdTarget = Isnull(T1.ProdTarget,0) from
		(select P.Startdate,P.Enddate,sum(T.ProdTarget) as ProdTarget from #TempProdTarget T,#ProdandRejDetails P
		where T.Startdate>=P.Startdate and T.Enddate<=P.Enddate
		group by P.Startdate,P.Enddate)T1 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN

			Update #ProdandRejDetails set Prodqty = Isnull(Prodqty,0) - Isnull(T2.Comp,0) from  (
			select T1.Startdate,T1.Enddate,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From 
			( 
				select S.Startdate,S.Enddate,mc,comp,opn,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
				Inner join machineinformation M on M.interfaceid=autodata.mc
				Cross join #ProdandRejDetails S
				CROSS JOIN PlannedDownTimes T
				WHERE autodata.DataType=1 And T.Machine = M.Machineid and M.Machineid=@Machineid
				AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
				AND (autodata.ndtime > S.Startdate  AND autodata.ndtime <=S.Enddate)
				Group by S.Startdate,S.Enddate,mc,comp,opn
			) as T1
			Inner join Machineinformation M on M.interfaceID = T1.mc
			Inner join componentinformation C on T1.Comp=C.interfaceid
			Inner join #ProdandRejDetails T on T.Startdate=T1.Startdate and T.Enddate=T1.Enddate
			Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
			GROUP BY T1.Startdate,T1.Enddate
			) as T2 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T2.Startdate
				and #ProdandRejDetails.Enddate=T2.Enddate 

			Update #ProdandRejDetails set ProdTarget = Isnull(#ProdandRejDetails.ProdTarget,0) - Isnull(T1.PDTTarget,0) from
			(select sum(ProdTarget) as PDTTarget from #ProdandRejDetails where convert(nvarchar(10),startdate,120) in 
			(select convert(nvarchar(10),holiday,120) from holidaylist where machineid=@Machineid and convert(nvarchar(10),holiday,120)>=convert(nvarchar(10),@startdate,120) and convert(nvarchar(10),holiday,120)<=convert(nvarchar(10),@Enddate,120)))T1 

		END

		Update #ProdandRejDetails set Rejqty = Isnull(#ProdandRejDetails.Rejqty,0) + Isnull(T1.Rejqty,0) from
		(Select T.Startdate,T.Enddate,SUM(A.Rejection_Qty) as Rejqty
		from AutodataRejections A 
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross join #ProdandRejDetails T
		where A.Flag='Rejection' and M.machineid=@Machineid 
		and (A.CreatedTS>=T.Startdate  and A.CreatedTS<=T.Enddate)
		group by T.Startdate,T.Enddate
		)T1 inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate

--		Update #ProdandRejDetails set RejTarget = T1.RejTarget from
--		(Select (100-Isnull(QE,95)) as RejTarget from EfficiencyTarget where machineid=@Machineid and
--		 convert(nvarchar(10),startdate,120)>=convert(nvarchar(10),@startdate,120) and convert(nvarchar(10),enddate,120)<=convert(nvarchar(10),@enddate,120) and Targetlevel='MONTH')T1


		Update #ProdandRejDetails set RejTarget = T1.RejTarget from
		(Select T.startdate,T.enddate,(100-Isnull(QE,95)) as RejTarget from EfficiencyTarget,#ProdandRejDetails T where machineid=@Machineid and
		 datepart(month,convert(nvarchar(10),T.startdate,120)) between datepart(month,convert(nvarchar(10),EfficiencyTarget.startdate,120)) and 
		 datepart(month,convert(nvarchar(10),EfficiencyTarget.enddate,120)) and Targetlevel='MONTH')T1  inner join #ProdandRejDetails on #ProdandRejDetails.Startdate=T1.Startdate
		and #ProdandRejDetails.Enddate=T1.Enddate

		Select Startdate,Enddate,'Week' + Weekno as DisplayDate,ProdQty,ProdTarget,Rejqty,RejTarget from #ProdandRejDetails order by Startdate
END

END
