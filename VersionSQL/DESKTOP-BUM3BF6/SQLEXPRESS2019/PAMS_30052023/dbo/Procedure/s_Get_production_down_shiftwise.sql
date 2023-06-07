/****** Object:  Procedure [dbo].[s_Get_production_down_shiftwise]    Committed by VersionSQL https://www.versionsql.com ******/

/***********************************************************************************
NR0073 - KarthikR - 23/Feb/2011 :: To Add New Excel Report 
To Show Shiftwise Production and Downtime Graph For the Selected Machine.
***********************************************************************************/

CREATE    PROCEDURE [dbo].[s_Get_production_down_shiftwise]
	@StartDate nvarchar(20),
	@machineid nvarchar(50),
	@type nvarchar(20)='Normal'
	
AS
BEGIN
	
create table #stripechart_shiftwise
(
id int identity(1,1) NOT NULL,
shiftname nvarchar(25),
Shiftstartdate datetime,
Shiftenddate datetime,
Atmsttime datetime,
Atndtime datetime,
chopmsttime datetime,
chopndtime datetime,
value int )

if @Type='Normal'
Begin
		insert into #stripechart_shiftwise
		Select Shiftname,ShStDate,ShEdDate,t2.msttime,t2.ndtime,case
											when t1.ShStDate <= t2.msttime then t2.msttime
												else t1.ShStDate
												End as chopmsttime,case datatype
							when 2 then (case when ShEdDate >= t2.ndTime then t2.ndTime else ShEdDate End )
							else null end as chopndtime,case datatype
													when 2 then 0
													else 1 end as value
							 from 
		(Select Shiftname,shiftid,
								dateadd(day,SH.Fromday,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,SH.Fromtime) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.Fromtime) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.Fromtime) as nvarchar(2))))) as ShStDate,
								dateadd(day,SH.Today,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,SH.Totime) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.Totime) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.Totime) as nvarchar(2))))) as ShEdDate
								from shiftdetails SH where running=1) T1
		cross join
		(select * from autodata where  mc=(select interfaceid from machineinformation where machineid = @machineid ) ) T2
		where ((T2.mstTime >= T1.ShStDate and T2.ndTime <= T1.ShEdDate)or
								(T2.mstTime < T1.ShStDate and T2.ndTime > T1.ShStDate and T2.ndTime <=T1.ShEdDate)or
								(T2.mstTime >= T1.ShStDate and T2.mstTime < T1.ShEdDate and T2.ndTime > T1.ShEdDate) or
								(T2.mstTime < T1.ShStDate and T2.ndTime > T1.ShEdDate))
		order by ShStDate,ShEdDate,Shiftname,t2.msttime asc

		update #stripechart_shiftwise  set #stripechart_shiftwise.chopndtime=case #stripechart_shiftwise.value
										 when 1 then b.chopmsttime
									else #stripechart_shiftwise.chopndtime end 
		  from #stripechart_shiftwise,
		#stripechart_shiftwise B where B.id=(Select min(id) from #stripechart_shiftwise C where c.id>#stripechart_shiftwise.id)-- order by id asc)
End
	Else
		Begin
		if ((SELECT Top 1 ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT top 1 ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y' )
			Begin
				insert into #stripechart_shiftwise
				Select T1.Shiftname,ShStDate,ShEdDate,t2.Starttime,t2.endtime,case
												when t1.ShStDate <= t2.Starttime then t2.Starttime
													else t1.ShStDate
													End as chopmsttime,
							case when ShEdDate >= t2.EndTime then t2.EndTime else ShEdDate End
								 as chopndtime, 1 as value
								 from 
					(Select Shiftname,shiftid,
									dateadd(day,SH.Fromday,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,SH.Fromtime) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.Fromtime) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.Fromtime) as nvarchar(2))))) as ShStDate,
									dateadd(day,SH.Today,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,SH.Totime) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.Totime) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.Totime) as nvarchar(2))))) as ShEdDate
									from shiftdetails SH where running=1) T1
						cross join
						(select * from Planneddowntimes where machine=@machineid ) T2
							where ((T2.StartTime >= T1.ShStDate and T2.EndTime <= T1.ShEdDate)or
										(T2.StartTime < T1.ShStDate and T2.Endtime > T1.ShStDate and T2.Endtime <=T1.ShEdDate)or
										(T2.StartTime >= T1.ShStDate and T2.StartTime < T1.ShEdDate and T2.Endtime > T1.ShEdDate) or
										(T2.StartTime < T1.ShStDate and T2.Endtime > T1.ShEdDate))
				order by ShStDate,ShEdDate,Shiftname,t2.Starttime asc
			End
		End

Select * from #stripechart_shiftwise


End
