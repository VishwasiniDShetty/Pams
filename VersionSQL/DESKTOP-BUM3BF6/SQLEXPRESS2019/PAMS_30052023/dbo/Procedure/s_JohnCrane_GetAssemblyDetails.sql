/****** Object:  Procedure [dbo].[s_JohnCrane_GetAssemblyDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--Select * from Machineinformation
--[dbo].[s_JohnCrane_GetAssemblyDetails] '2017-11-01','2017-11-10','LT 2 LM 500 MSY','','DaywiseView'

--[dbo].[s_JohnCrane_GetAssemblyDetails] '2017-11-09','','LT 2 LM 500 MSY','','WorkOrderwiseStatus'
--[dbo].[s_JohnCrane_GetAssemblyDetails] '2017-11-10','','LT 2 LM 500 MSY','','WorkOrderwiseTranSactions'

--[dbo].[s_JohnCrane_GetAssemblyDetails] '2017-11-09 06:00:00','2017-11-10 06:00:00','LT 2 LM 500 MSY','IMTEXCOMP2','WorkOrderwiseDetails'

--[dbo].[s_JohnCrane_GetAssemblyDetails] '','','LT 2 LM 500 MSY','','WorkOrderwiseView'
CREATE PROCEDURE [dbo].[s_JohnCrane_GetAssemblyDetails]
@FromDate Datetime,
@ToDate Datetime,
@Machineid nvarchar(50)='',
@WorkOrderNo nvarchar(50)='',
@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

Create table #Day
(
	Starttime datetime,
	Endtime datetime
)


Create table #Assemblydata
(
	FromDate datetime,
	ToDate datetime,
	Machineinterface nvarchar(50),
	Machineid nvarchar(50),
	WorkorderNo nvarchar(50),
	WIP int,
	WIPToOffered int,
	WIPToHold int,
	OfferedToClear int,
	OfferedToHold int,
	HoldToOffered int,
	WIPTS datetime,
	OfferedTS datetime,
	HoldTS datetime,
	ClearedTS datetime  
)

Declare @Startdate as datetime
Declare @Enddate as datetime

Select @Startdate=@FromDate

While @Startdate<=@ToDate
Begin
	Insert into #Day(Starttime,Endtime)
	Select dbo.f_GetLogicalDay(@Startdate,'start'),dbo.f_GetLogicalDay(@Startdate,'End')
	Select @Startdate = Dateadd(day,1,@Startdate)
End

Select @Startdate=Min(Starttime) From #Day
Select @Enddate=Max(Endtime) From #Day

If @param = 'DaywiseView'
Begin

	Insert into #Assemblydata(FromDate,ToDate,Machineinterface,Machineid,WIP,WIPToOffered,WIPToHold,OfferedToClear,OfferedToHold,HoldToOffered)
	Select Starttime,Endtime,M.interfaceid,M.Machineid,0,0,0,0,0,0 From Machineinformation M 
	Cross join #Day where M.Machineid=@Machineid

	Update #Assemblydata Set WIP=T.WIP From
	(select T1.Fromdate,T1.ToDate,T1.Machineid,Count(T1.EventID) as WIP From
		(
		Select distinct A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID From JohnCrane_EventDetails J
		inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and J.Machineid=A.Machineinterface
		where J.EventId=1 and (J.EventDate>=@Startdate and J.EventDate<=@Enddate)
		Group by A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID
		)T1
	Group by T1.Fromdate,T1.ToDate,T1.Machineid)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid

	Update #Assemblydata Set WIPToOffered=T.WIPToOffered From
	(select T1.Fromdate,T1.ToDate,T1.Machineid,Count(T1.EventID) as WIPToOffered From
		(
		Select distinct A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID From JohnCrane_EventDetails J
		inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and J.Machineid=A.Machineinterface
		where J.EventId=2 and (J.EventDate>=@Startdate and J.EventDate<=@Enddate)
		Group by A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID
		)T1
	Group by T1.Fromdate,T1.ToDate,T1.Machineid)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid

	Update #Assemblydata Set WIPToHold=T.WIPToHold From
	(select T1.Fromdate,T1.ToDate,T1.Machineid,Count(T1.EventID) as WIPToHold From
		(
		Select distinct A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID From JohnCrane_EventDetails J
		inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and J.Machineid=A.Machineinterface
		where J.EventId=3 and (J.EventDate>=@Startdate and J.EventDate<=@Enddate)
		Group by A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID
		)T1
	Group by T1.Fromdate,T1.ToDate,T1.Machineid)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid

	Update #Assemblydata Set OfferedToClear=T.OfferedToClear From
	(select T1.Fromdate,T1.ToDate,T1.Machineid,Count(T1.EventID) as OfferedToClear From
		(
		Select distinct A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID From JohnCrane_EventDetails J
		inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and J.Machineid=A.Machineinterface
		where J.EventId=4 and (J.EventDate>=@Startdate and J.EventDate<=@Enddate)
		Group by A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID
		)T1
	Group by T1.Fromdate,T1.ToDate,T1.Machineid)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid

	Update #Assemblydata Set OfferedToHold=T.OfferedToHold From
	(select T1.Fromdate,T1.ToDate,T1.Machineid,Count(T1.EventID) as OfferedToHold From
		(
		Select distinct A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID From JohnCrane_EventDetails J
		inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and J.Machineid=A.Machineinterface
		where J.EventId=5 and (J.EventDate>=@Startdate and J.EventDate<=@Enddate)
		Group by A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID
		)T1
	Group by T1.Fromdate,T1.ToDate,T1.Machineid)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid

	Update #Assemblydata Set HoldToOffered=T.HoldToOffered From
	(select T1.Fromdate,T1.ToDate,T1.Machineid,Count(T1.EventID) as HoldToOffered From
		(
		Select distinct A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID From JohnCrane_EventDetails J
		inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and J.Machineid=A.Machineinterface
		where J.EventId=6 and (J.EventDate>=@Startdate and J.EventDate<=@Enddate)
		Group by A.FromDate,A.ToDate,A.Machineid,J.workorderno,J.EventID
		)T1
	Group by T1.Fromdate,T1.ToDate,T1.Machineid)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid

	Select distinct Convert(Nvarchar(10),J.EventDate,120) as FromDate,M.Machineid,M.interfaceid as Machineinterface,J.WorkOrderNo,0 as WIPToHold,0 as OfferedToHold,0 as HoldToOffered 
	Into #HoldQtyDetails From JohnCrane_EventDetails J
	inner join Machineinformation M on M.interfaceid=J.Machineid 
	where M.Machineid=@machineid 

	Update #HoldQtyDetails Set WIPToHold=T.WIPToHold From
	(
	Select A.FromDate,A.Machineid,A.WorkorderNo,SUM(J.Quantity) as WIPToHold From JohnCrane_EventDetails J
	inner join #HoldQtyDetails A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=3 and (J.EventDate>=@Startdate and J.EventDate<=@Enddate)
	Group by A.FromDate,A.Machineid,A.WorkorderNo
	)T inner join #HoldQtyDetails on #HoldQtyDetails.FromDate=T.FromDate and #HoldQtyDetails.Machineid=T.Machineid and #HoldQtyDetails.WorkorderNo=T.WorkorderNo

	Update #HoldQtyDetails Set OfferedToHold=T.OfferedToHold From
	(
	Select A.FromDate,A.Machineid,A.WorkorderNo,SUM(J.Quantity) as OfferedToHold From JohnCrane_EventDetails J
	inner join #HoldQtyDetails A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=5 and (J.EventDate>=@Startdate and J.EventDate<=@Enddate)
	Group by A.FromDate,A.Machineid,A.WorkorderNo
	)T inner join #HoldQtyDetails on #HoldQtyDetails.FromDate=T.FromDate and #HoldQtyDetails.Machineid=T.Machineid and #HoldQtyDetails.WorkorderNo=T.WorkorderNo

	Update #HoldQtyDetails Set HoldToOffered=T.HoldToOffered From
	(
	Select A.FromDate,A.Machineid,A.WorkorderNo,SUM(J.Quantity) as HoldToOffered From JohnCrane_EventDetails J
	inner join #HoldQtyDetails A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=6 and (J.EventDate>=@Startdate and J.EventDate<=@Enddate)
	Group by A.FromDate,A.Machineid,A.WorkorderNo
	)T inner join #HoldQtyDetails on #HoldQtyDetails.FromDate=T.FromDate and #HoldQtyDetails.Machineid=T.Machineid and #HoldQtyDetails.WorkorderNo=T.WorkorderNo

	Update #Assemblydata SET HoldToOffered = T.Hold From
	(Select H.Fromdate,H.Machineid,H.WorkorderNo,Case When (H.WIPToHold+H.OfferedToHold-H.HoldToOffered)=0 then 0 else (A.WIPToHold+A.OfferedToHold) End as Hold
	From #Assemblydata A inner join #HoldQtyDetails H on H.FromDate=A.FromDate and H.Machineid=A.Machineid and H.WorkorderNo=A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid

	Select Convert(Nvarchar(10),FromDate,120) as StartDate,WIP,WIPToOffered as Offered,HoldToOffered as Hold,OfferedToClear as Cleared from #Assemblydata Order by Fromdate

End

If @param = 'WorkOrderwiseStatus'
Begin

	Insert into #Assemblydata(Fromdate,Machineid,Machineinterface,WorkorderNo,WIP,WIPToOffered,WIPToHold,OfferedToClear,OfferedToHold,HoldToOffered)
	Select distinct Convert(Nvarchar(10),J.EventDate,120),M.Machineid,M.interfaceid,J.WorkOrderNo, 0,0,0,0,0,0 From JohnCrane_EventDetails J
	inner join Machineinformation M on M.interfaceid=J.Machineid 
	where M.Machineid=@machineid and Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),@FromDate,120)

	Update #Assemblydata Set WIP=T.WIPCount From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as WIPCount From JohnCrane_EventDetails J
	inner join #Assemblydata A on J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=1 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set WIPToOffered=T.WIPToOffered From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as WIPToOffered From JohnCrane_EventDetails J
	inner join #Assemblydata A on J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=2  
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set WIPToHold=T.WIPToHold From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as WIPToHold From JohnCrane_EventDetails J
	inner join #Assemblydata A on J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=3 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set OfferedToClear=T.OfferedToClear From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as OfferedToClear From JohnCrane_EventDetails J
	inner join #Assemblydata A on J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=4 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo

	Update #Assemblydata Set OfferedToHold=T.OfferedToHold From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as OfferedToHold From JohnCrane_EventDetails J
	inner join #Assemblydata A on J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=5 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set HoldToOffered=T.HoldToOffered From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as HoldToOffered From JohnCrane_EventDetails J
	inner join #Assemblydata A on J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=6 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo

	Select Convert(Nvarchar(10),FromDate,120) as StartDate,WorkOrderNo,WIP,(WIPToOffered-OfferedToHold+HoldToOffered-OfferedToClear) as Offered,(WIPToHold+OfferedToHold-HoldToOffered) as Hold,OfferedToClear as Cleared from #Assemblydata 
	Order by WorkOrderNo
End

If @param = 'WorkOrderwiseTransactions'
Begin

	Insert into #Assemblydata(Fromdate,Machineid,Machineinterface,WorkorderNo,WIP,WIPToOffered,WIPToHold,OfferedToClear,OfferedToHold,HoldToOffered)
	Select distinct Convert(Nvarchar(10),J.EventDate,120),M.Machineid,M.interfaceid,J.WorkOrderNo, 0,0,0,0,0,0 From JohnCrane_EventDetails J
	inner join Machineinformation M on M.interfaceid=J.Machineid 
	where M.Machineid=@machineid and Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),@FromDate,120)

	Update #Assemblydata Set WIP=T.WIPCount From
	(
	Select A.FromDate,A.Machineid,A.WorkorderNo,SUM(J.Quantity) as WIPCount From JohnCrane_EventDetails J
	inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and 
	J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=1 and Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),@FromDate,120)
	Group by A.FromDate,A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set WIPToOffered=T.WIPToOffered From
	(
	Select A.FromDate,A.Machineid,A.WorkorderNo,SUM(J.Quantity) as WIPToOffered From JohnCrane_EventDetails J
	inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and 
	J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=2 and Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),@FromDate,120)
	Group by A.FromDate,A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set WIPToHold=T.WIPToHold From
	(
	Select A.FromDate,A.Machineid,A.WorkorderNo,SUM(J.Quantity) as WIPToHold From JohnCrane_EventDetails J
	inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and 
	J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=3 and Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),@FromDate,120)
	Group by A.FromDate,A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set OfferedToClear=T.OfferedToClear From
	(
	Select A.FromDate,A.Machineid,A.WorkorderNo,SUM(J.Quantity) as OfferedToClear From JohnCrane_EventDetails J
	inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and 
	J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=4 and Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),@FromDate,120)
	Group by A.FromDate,A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo

	Update #Assemblydata Set OfferedToHold=T.OfferedToHold From
	(
	Select A.FromDate,A.Machineid,A.WorkorderNo,SUM(J.Quantity) as OfferedToHold From JohnCrane_EventDetails J
	inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and 
	J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=5 and Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),@FromDate,120)
	Group by A.FromDate,A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set HoldToOffered=T.HoldToOffered From
	(
	Select A.FromDate,A.Machineid,A.WorkorderNo,SUM(J.Quantity) as HoldToOffered From JohnCrane_EventDetails J
	inner join #Assemblydata A on Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),A.FromDate,120) and 
	J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=6 and Convert(Nvarchar(10),J.EventDate,120)=Convert(Nvarchar(10),@FromDate,120)
	Group by A.FromDate,A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.FromDate=T.FromDate and #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo

	Select Convert(Nvarchar(10),FromDate,120) as StartDate,WorkOrderNo,WIP,(WIPToOffered+HoldToOffered) as Offered,(WIPToHold+OfferedToHold) as Hold,OfferedToClear as Cleared from #Assemblydata 
	Order by WorkOrderNo
End



If @param='WorkOrderwiseView'
Begin

	Insert into #Assemblydata(Machineid,Machineinterface,WorkorderNo,WIP,WIPToOffered,WIPToHold,OfferedToClear,OfferedToHold,HoldToOffered)
	Select distinct M.Machineid,M.interfaceid,J.WorkOrderNo, 0,0,0,0,0,0 From JohnCrane_EventDetails J
	inner join Machineinformation M on M.interfaceid=J.Machineid 
	where M.Machineid=@machineid 

	Update #Assemblydata Set WIP=T.WIPCount From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as WIPCount From JohnCrane_EventDetails J
	inner join #Assemblydata A on J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=1 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo

	Update #Assemblydata Set WIPToOffered=T.WIPToOffered From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as WIPToOffered From JohnCrane_EventDetails J
	inner join #Assemblydata A on  J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=2 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on  #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set WIPToHold=T.WIPToHold From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as WIPToHold From JohnCrane_EventDetails J
	inner join #Assemblydata A on  J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=3 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set OfferedToClear=T.OfferedToClear From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as OfferedToClear From JohnCrane_EventDetails J
	inner join #Assemblydata A on J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=4 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on  #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo

	Update #Assemblydata Set OfferedToHold=T.OfferedToHold From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as OfferedToHold From JohnCrane_EventDetails J
	inner join #Assemblydata A on J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=5 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on  #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo


	Update #Assemblydata Set HoldToOffered=T.HoldToOffered From
	(
	Select A.Machineid,A.WorkorderNo,SUM(J.Quantity) as HoldToOffered From JohnCrane_EventDetails J
	inner join #Assemblydata A on J.Machineid=A.Machineinterface and J.WorkorderNo=A.WorkorderNo
	where J.EventId=6 
	Group by A.Machineid,A.WorkorderNo
	)T inner join #Assemblydata on #Assemblydata.Machineid=T.Machineid and #Assemblydata.WorkorderNo=T.WorkorderNo

	Select Convert(Nvarchar(10),FromDate,120) as StartDate,WorkOrderNo,WIP,(WIPToOffered-OfferedToHold+HoldToOffered) as Offered,(WIPToHold+OfferedToHold-HoldToOffered) as Hold,OfferedToClear as Cleared from #Assemblydata 
	Where WorkOrderNo=@WorkorderNo Order by WorkOrderNo
	

End

If @param = 'WorkOrderwiseDetails'
Begin
	--Select Row_Number() Over(Order by EventTS) as Slno, EventTS,Case when J.EventID='1' then 'WIP'
	--when J.EventID='2' then 'WIPToOffered'
	--when J.EventID='3' then 'WIPToHold'
	--when J.EventID='4' then 'OfferedToCleared'
	--when J.EventID='5' then 'OfferedToHold'
	--when J.EventID='6' then 'HoldToOffered' END as Status
	--,Quantity From JohnCrane_EventDetails J
	--inner join Machineinformation M on  J.Machineid=M.interfaceid
	--where J.EventId in(1,2,3,4,5,6) and J.WorkorderNo=@WorkOrderNo and M.Machineid=@machineid
	--Order by EventTS

	Select Row_Number() Over(Order by EventTS) as Slno, EventTS,Case when J.EventID='1' then 'WIP'
	when J.EventID='2' then 'WIP To Offered'
	when J.EventID='3' then 'WIP To Hold'
	when J.EventID='4' then 'Offered To Cleared'
	when J.EventID='5' then 'Offered To Hold'
	when J.EventID='6' then 'Hold To Offered' END as Status
	,Quantity,J.WorkorderNo 
	From JohnCrane_EventDetails J
	inner join Machineinformation M on  J.Machineid=M.interfaceid
	where J.EventId in(1,2,3,4,5,6) and (J.WorkorderNo=@WorkOrderNo OR @WorkOrderNo ='') and M.Machineid=@machineid 
	       and (J.EventDate>=@Startdate and J.EventDate<=@Enddate) 
	Order by EventTS


End


END
