/****** Object:  Procedure [dbo].[s_Get_Auma_Prod_Downreport]    Committed by VersionSQL https://www.versionsql.com ******/

/***********************************************************************************
Procedure written by Karthick R on 20-Feb-2009.For NR00065.
New Excel Report showing Production and Down data DayWise for auma.
Note:----For Production data Mandoreport procedure is used
	 ----For Down data PdT is not applied
mod 1:ER0257 Karthick R on 29-sep-2010.To detect pdt from Shift Target only for %ideal
--ER0323 - SwathiKS - 19/Jan/2012  :: To Add Component Description Column in Output for Report SM_Daily_ProdDown_daywise.
ER0327 - SwathiKS/KarthikR - 16/Aug/12 :: SmartManager -> Standard -> Production and Downtime report-Daily By Hour -> Daily Production and Rejection - Excel
										  Report Name -> SM_Daily_ProdRej_daywise.xls
									      Added New Parameter "ProductionRejection" to show hourwise and shiftwise Rejections along with Production For Rajmane.
ER0382 - SwathiKS - 16-May-2014 :: While Showing Down Details to handle all "4" Record Types instead of only completed cylces.
DR0379 - SwathiKS - 30/Nov/2017 :: To Show Component Description n Description field instead of Showing Portion of Componentid so that it will be generic.
***********************************************************************************/
-- s_Get_Auma_Prod_downreport '2019-03-20','2019-03-21','','','ProductionRejection','Web'
--s_Get_Auma_Prod_downreport '2019-03-20','2019-03-26','','','Down','Web'
CREATE PROCEDURE [dbo].[s_Get_Auma_Prod_Downreport]
	@StartDate datetime,
	@Enddate datetime,
	@PlantID nvarchar(50) = '',
	@MachineID nvarchar(50) = '',
	--@RptProd_down nvarchar(15)='Production' --'ProductionRejection' --ER0327 Added
	@RptProd_down nvarchar(50)='Production', --'ProductionRejection' --ER0327 Added
	@param  nvarchar(50)=''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 --PROC
	
	Create Table #Base_Prod_ctn_Temp
	(	
		Machineid nvarchar(50),
		Machinedescription nvarchar(150),
		ComponentId nvarchar(50),
		Operationno int,
		Operatorid nvarchar(150),
		ShiftName nvarchar(20),
		ShiftID int,
		--mod 1
		ShiftStartTime datetime,
		ShiftEndTime datetime,
		--mod 1
		HourID nvarchar(50),
		--HourID int,
		Downtime nvarchar(50),
		FromTime datetime,
		ToTime Datetime,
		Actual nvarchar(50),
		Target float default(0),
		Hourlytarget float default(0),
		ShftActualCount float default(0),
		RejCount float default(0), --ER0327 Added
		ShftRejCount float default(0),
		TotalRejCount float default(0) --ER0327 Added
	)

 --ER0327 Added From here
 Create Table #Base_Prod_ctn_Temp1
	(	
		Machineid nvarchar(50),
		Machinedescription nvarchar(150),
		ComponentId nvarchar(50),
		Operationno int,
		Operatorid nvarchar(150),
		RejCount float default(0), 
		Starttime Datetime
	)


 --ER0327 Added Till here

 
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
 Remarks  [nvarchar] (255) NULL,
 id  bigint not null  
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime,ndtime,msttime ASC  
)ON [PRIMARY]  


DECLARE @strsql as varchar(4000)
DECLARE @strPlant_Machine AS nvarchar(250)
DECLARE @Targetsource as nvarchar(100)
DECLARE @stdate as nvarchar(25)
declare @ExactStdate as datetime
declare @TmpStartdate as datetime
declare @TmpEnddate as datetime
declare @ShftPL as int
select @stdate = CAST(datePart(yyyy,@StartDate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@StartDate) AS nvarchar(2)) + '-' + CAST(datePart(dd,@StartDate) AS nvarchar(2))
select @ExactStdate=convert(datetime, cast(DATEPART(yyyy,@StartDate)as nvarchar(4))+'-'+cast(datepart(mm,@StartDate)as nvarchar(2))+'-'+cast(datepart(dd,@StartDate)as nvarchar(2)) +' 00:00:00.000')
print @stdate
print @ExactStdate
SELECT @strsql = ''
SELECT @strPlant_Machine = ''
set @TmpStartdate=  Cast([dbo].[f_GetLogicalDay](@startdate,'Start') as datetime)
set @TmpEnddate= Cast([dbo].[f_GetLogicalDay](@startdate,'End') as datetime )
--if @param <> '' 
--begin
--set @TmpEnddate= Cast([dbo].[f_GetLogicalDay](@Enddate,'End') as datetime )
--end
--else 
--begin
--set @TmpEnddate= Cast([dbo].[f_GetLogicalDay](@startdate,'End') as datetime )
--end 
print @TmpStartdate
print @TmpEnddate

  
Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,Remarks,id'  
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@TmpStartdate,120)+''' and ndtime <= '''+ convert(nvarchar(25),@TmpEnddate,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@TmpStartdate,120)+''' and ndtime >'''+ convert(nvarchar(25),@TmpEnddate,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@TmpStartdate,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartDate,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@TmpEnddate,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@StartDate,120)+''' and ndtime >'''+ convert(nvarchar(25),@TmpEnddate,120)+''' and sttime<'''+convert(nvarchar(25),@TmpEnddate,120)+''' ) )'  
print @strsql  
exec (@strsql)  


if (@RptProd_down='Production') or (@RptProd_down='ProductionRejection') --ER0327 Added
Begin
	
			insert into #Base_Prod_ctn_Temp(Fromtime,ToTime,MachineId,ComponentiD,Operationno,OperatorID,HourID,Downtime,Actual)
			Exec s_GetMando_Reports @TmpStartdate,@TmpEnddate,@plantID,@machineID,'','1','2'

			
			--print '----------------------'
			--print @tmpstartdate
			--print @TmpEnddate
			--print @plantID
			--print @machineID
			--print '----------------------'

			Delete from #Base_Prod_ctn_Temp where Downtime='Total Output' or Downtime='DownTime'
			--select * from #Base_Prod_ctn_Temp

			Update #Base_Prod_ctn_Temp set Downtime=0
			--Select * from #Base_Prod_ctn_Temp
			Update #Base_Prod_ctn_Temp set	ShiftiD=t1.shiftid,ShiftName=T1.ShiftName
					--mod 1
						,ShiftStartTime=T1.Shstdate,ShiftEndTime=T1.Sheddate
					--mod 1
				From #Base_Prod_ctn_Temp Bs inner join
						(Select Shiftname,shiftid,
						dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.Fromtime) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.Fromtime) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.Fromtime) as nvarchar(2))))) as ShStDate,
						dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.Totime) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.Totime) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.Totime) as nvarchar(2))))) as ShEdDate
						from shiftdetails SH where running=1) T1 on
											Bs.fromtime>=T1.Shstdate and Bs.totime<=T1.Sheddate
			
			UPDATE #Base_Prod_ctn_Temp SET downtime = isnull(downtime,0) + isNull(t2.down,0)
				from
				(select M.MachineID,C.componentId,O.operationno,E.employeeid,T1.shiftid,sum(
						CASE
						WHEN  A.msttime>=T1.StartTime  and  A.ndtime<=T1.EndTime  THEN  A.loadunload
						WHEN (A.sttime<T1.StartTime and  A.ndtime>T1.StartTime and A.ndtime<=T1.EndTime)  THEN DateDiff(second, T1.StartTime, ndtime)
						WHEN (A.msttime>=T1.StartTime  and A.sttime<T1.EndTime  and A.ndtime>T1.EndTime)  THEN DateDiff(second, stTime, T1.Endtime)
						WHEN A.msttime<T1.StartTime and A.ndtime>T1.EndTime   THEN DateDiff(second, T1.StartTime, T1.EndTime)
						END
					)AS down
				from #T_autodata A inner join downcodeinformation on A.dcode=downcodeinformation.interfaceid
					inner join machineinformation M on M.interfaceid=A.mc
					inner join componentinformation C on C.interfaceid=A.comp
					inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
					inner join Employeeinformation E on E.Interfaceid=A.opr
					inner join (Select shiftid,
						dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.Fromtime) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.Fromtime) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.Fromtime) as nvarchar(2))))) as StartTime,
						dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.Totime) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.Totime) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.Totime) as nvarchar(2))))) as EndTime
						from shiftdetails SH where Running=1 ) T1
				  on (
				(A.msttime>=T1.StartTime  and  A.ndtime<=T1.EndTime)
				OR (A.sttime<T1.StartTime and  A.ndtime>T1.StartTime and A.ndtime<=T1.EndTime)
				OR (A.msttime>=T1.StartTime  and A.sttime<T1.EndTime  and A.ndtime>T1.EndTime)
				OR (A.msttime<T1.StartTime and A.ndtime>T1.EndTime )
				)
				where A.datatype=2 AND (downcodeinformation.availeffy = 0)
				group by M.MachineID,C.componentId,O.operationno,E.employeeid,T1.shiftid
				) as t2 inner join #Base_Prod_ctn_Temp BS on t2.MachineID = BS.MachineID
				And T2.componentId=Bs.componentId and T2.operationno=BS.operationno and
				T2.employeeid=BS.OPeratorid
				and T2.shiftid=Bs.shiftid

			Select top 1 @Targetsource = ValueInText from Shopdefaults where Parameter='TargetFrom'
				If isnull(@Targetsource,'')='Exact Schedule'
				Begin
					--Update #HeaderOperation set Operation = t1.OperationNO from (select OperationNo,interfaceid from componentoperationpricing)as t1 inner join #HeaderOperation on #HeaderOperation.OperationID = t1.interfaceid
					print 'Exact Schedule'
					Update #Base_Prod_ctn_Temp set Target = T1.idealcount from (select * from loadschedule ) as T1
					inner join #Base_Prod_ctn_Temp on T1.[date] = #Base_Prod_ctn_Temp.FromTime
					and T1.Shift = #Base_Prod_ctn_Temp.ShiftName
					and T1.Machine =  #Base_Prod_ctn_Temp.machineID and T1.Component = #Base_Prod_ctn_Temp.ComponentId
					and T1.operation = #Base_Prod_ctn_Temp.Operationno --where RowHeader3 = 'Shift Target' or RowHeader3 = 'Hourly Target'
					--mod 1
						update #Base_Prod_ctn_Temp set ShftActualCount=T1.Actual,Hourlytarget=Bs.Target/Isnull(T1.cnt,1) from #Base_Prod_ctn_Temp Bs
							inner join
							(Select MachineID,ComponentID,Operationno,operatorid,ShiftID,
							sum(Cast(Actual as float))as Actual,count(ShiftID) as cnt From #Base_Prod_ctn_Temp Bs
							Group by MachineID,ComponentID,Operationno,operatorid,ShiftID ) T1
							On T1.MachineID=Bs.MachineID and T1.ComponentID=Bs.ComponentID
							and T1.Operationno=Bs.Operationno and T1.operatorid=Bs.operatorid
							and T1.ShiftID=Bs.ShiftID
					--mod 1
				End
				If isnull(@Targetsource,'')='Default Target per CO'
				Begin
					print 'Default Target per CO'
					Create Table #loadschedule([date] datetime,shift NvarChar(50),Machine NvarChar(50),Component NvarChar(50),Operation NvarChar(50),IdealCount NvarChar(50))
					Insert #loadschedule Select [date],shift,Machine,Component,Operation,IdealCount from loadschedule order by [date]
					Update #Base_Prod_ctn_Temp set Target  = T1.idealcount from (select * from #loadschedule ) as T1
					inner join #Base_Prod_ctn_Temp on T1.Shift = #Base_Prod_ctn_Temp.ShiftName and T1.Machine = #Base_Prod_ctn_Temp.MachineID
					and T1.Component = #Base_Prod_ctn_Temp.Componentid and T1.operation = #Base_Prod_ctn_Temp.Operationno
					--where RowHeader3 = 'Shift Target' or RowHeader3 = 'Hourly Target'
				--mod 1
					update #Base_Prod_ctn_Temp set ShftActualCount=T1.Actual,Hourlytarget=Bs.Target/Isnull(T1.cnt,1) from #Base_Prod_ctn_Temp Bs
							inner join
							(Select MachineID,ComponentID,Operationno,operatorid,ShiftID,
							sum(Cast(Actual as float))as Actual,count(ShiftID) as cnt From #Base_Prod_ctn_Temp Bs
							Group by MachineID,ComponentID,Operationno,operatorid,ShiftID ) T1
							On T1.MachineID=Bs.MachineID and T1.ComponentID=Bs.ComponentID
							and T1.Operationno=Bs.Operationno and T1.operatorid=Bs.operatorid
							and T1.ShiftID=Bs.ShiftID
				--mod 1
				End
				If isnull(@Targetsource,'')='% Ideal'
				Begin
					print '% Ideal'
					update #Base_Prod_ctn_Temp set Target= t1.tcount from
					(
					select CO.componentid as component,CO.Operationno as operation,#Base_Prod_ctn_Temp.ShiftStartTime as strt
						,#Base_Prod_ctn_Temp.ShiftEndTime as ndtm,#Base_Prod_ctn_Temp.MachineID as mcid,
						tcount=((datediff(second,#Base_Prod_ctn_Temp.ShiftStartTime,#Base_Prod_ctn_Temp.ShiftEndTime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
					from componentoperationpricing CO inner join #Base_Prod_ctn_Temp
					on #Base_Prod_ctn_Temp.machineid=Co.machineid and CO.Componentid=#Base_Prod_ctn_Temp.ComponentID and Co.operationno=#Base_Prod_ctn_Temp.Operationno
					) as t1 inner join #Base_Prod_ctn_Temp on t1.strt=#Base_Prod_ctn_Temp.ShiftStartTime
						 and t1.ndtm=#Base_Prod_ctn_Temp.ShiftEndTime
					 and t1.mcid=#Base_Prod_ctn_Temp.MachineID and t1.component=#Base_Prod_ctn_Temp.ComponentID and
					t1.operation=#Base_Prod_ctn_Temp.Operationno --where RowHeader3 = 'Shift Target' or RowHeader3 = 'Hourly Target'
		--mod 1
						update #Base_Prod_ctn_Temp set ShftActualCount=T1.Actual,Hourlytarget=Bs.Target/Isnull(T1.cnt,1) from #Base_Prod_ctn_Temp Bs
							inner join
							(Select MachineID,ComponentID,Operationno,operatorid,ShiftID,
							sum(Cast(Actual as float))as Actual,count(ShiftID) as cnt From #Base_Prod_ctn_Temp Bs
							Group by MachineID,ComponentID,Operationno,operatorid,ShiftID ) T1
							On T1.MachineID=Bs.MachineID and T1.ComponentID=Bs.ComponentID
							and T1.Operationno=Bs.Operationno and T1.operatorid=Bs.operatorid
							and T1.ShiftID=Bs.ShiftID

			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
			BEGIN
					update #Base_Prod_ctn_Temp set Target=target-((cast(t3.Totalpdt as float)/cast(datediff(ss,t3.Starttime,t3.Endtime) as float))*target)
						from
						(
						Select Machineid,Starttime,Endtime,Sum(Datediff(ss,Starttimepdt,Endtimepdt))as TotalPDT
						From
						(
						select fd.StartTime,fd.EndTime,Case
										when fd.StartTime <= pdt.StartTime then pdt.StartTime
										else fd.StartTime
										End as Starttimepdt
						,Case when fd.EndTime >= pdt.EndTime then pdt.EndTime else fd.EndTime End as Endtimepdt
						,fd.MachineID
						from
						(Select distinct Machineid,ShiftStartTime as StartTime ,ShiftEndTime as EndTime from #Base_Prod_ctn_Temp) as fd
						 cross join planneddowntimes pdt
						where PDTstatus = 1  and fd.machineID = pdt.Machine and --and DownReason <> 'SDT'
						((pdt.StartTime >= fd.StartTime and pdt.EndTime <= fd.EndTime)or
						(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.StartTime and pdt.EndTime <=fd.EndTime)or
						(pdt.StartTime >= fd.StartTime and pdt.StartTime <fd.EndTime and pdt.EndTime > fd.EndTime) or
						(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.EndTime))
						)T2 group by Machineid,Starttime,Endtime
						)T3 inner join #Base_Prod_ctn_Temp
						on T3.Machineid=#Base_Prod_ctn_Temp.machineid and T3.Starttime=#Base_Prod_ctn_Temp.Shiftstarttime and T3.Endtime= #Base_Prod_ctn_Temp.Shiftendtime
		
				
				End
			END  --mod 1
				
				If @RptProd_down = 'Production' --ER0327 added Line
				BEGIN                --ER0327 added Line
						--Select B.Machineid,B.ComponentId, --ER0323 Commented 
						Select	B.Machineid,
						M.description as Machinedescription,
						--substring(B.ComponentId,1, charindex(' ',B.ComponentId)) as ComponentId,(substring(B.ComponentId,charindex(' ',B.ComponentId),len(B.ComponentId)-1)) as CompDescription,  --ER0323 Added --DR0379
						B.ComponentId as ComponentId,C.Description as CompDescription, --DR0379
						B.Operationno, B.Operatorid, B.ShiftName, B.ShiftID, B.HourID,
						dbo.f_FormatTime (isnull(B.Downtime,0),'hh:mm:ss') AS Downtime,
						B.FromTime,B.ToTime,B.Actual, CEILING(B.Target) as Target,CEILING(B.Hourlytarget) as Hourlytarget
						,B.ShftActualCount,P.PlantID from #Base_Prod_ctn_Temp B
						INNER JOIN machineinformation M ON B.Machineid = m.machineid
						left outer join Plantmachine P on P.machineid=B.machineID
						left outer join componentinformation C on B.componentid=C.Componentid
						where isnull(B.ShftActualCount,0)>0 or isnull(B.Downtime,0)>0
						order by P.PlantID,B.MachineID,B.shiftID,B.componentID,B.operationno,B.operatorID asc
				END               --ER0327  added Line

				--ER0327 added From Here
				If @RptProd_down = 'ProductionRejection' 
				BEGIN              
					
					Update #Base_Prod_ctn_Temp set RejCount = isnull(RejCount,0) + isnull(T1.Rejection_Qty,0)
					From
					( Select CreatedTS,mc,comp,opn,opr,Rejection_Qty,M.Machineid,O.Componentid,
					  O.Operationno,E.employeeid from AutodataRejections A
					  inner join Machineinformation M on A.mc=M.interfaceid
					  inner join componentinformation C on C.interfaceid=A.comp
					  inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
					  inner join Employeeinformation E on E.Interfaceid=A.opr				  
					)T1 inner join #Base_Prod_ctn_Temp B on B.Machineid=T1.Machineid and B.Componentid=T1.Componentid and B.Operationno=T1.Operationno
					  and B.Operatorid = T1.employeeid where T1.CreatedTS>=B.fromtime and T1.CreatedTS<B.totime--T1.createdTS between B.Fromtime and B.totime
			
			
					 If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
					  BEGIN
						  Insert into #Base_Prod_ctn_Temp1
						  select M.Machineid,M.description,C.componentid,O.operationno,E.employeeid,A.Rejection_Qty,A.CreatedTS 
						  from AutodataRejections A
						  inner join Machineinformation M on A.mc=M.interfaceid
						  inner join componentinformation C on C.interfaceid=A.comp
						  inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
						  inner join Employeeinformation E on E.Interfaceid=A.opr
						  inner join Planneddowntimes P on P.machine=M.Machineid
						  where PDTStatus =1 and A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
						 
				
						  Update #Base_Prod_ctn_Temp set RejCount = isnull(B.RejCount,0) - isnull(T1.rejcount,0) from
						 (select Machineid,Componentid,operationno,operatorid,rejcount,starttime from #Base_Prod_ctn_Temp1)
						  T1 inner join #Base_Prod_ctn_Temp B on B.Machineid=T1.Machineid and B.Componentid=T1.Componentid and B.Operationno=T1.Operationno
						  and B.Operatorid = T1.operatorid where (T1.starttime>=B.Fromtime and T1.starttime<B.totime)

					END

					update #Base_Prod_ctn_Temp set ShftRejCount=T1.RejCount
					from #Base_Prod_ctn_Temp Bs
					inner join
					(
					Select MachineID,ComponentID,Operationno,operatorid,ShiftID,
					sum(Cast(RejCount as float))as RejCount
					From #Base_Prod_ctn_Temp Bs
					Group by MachineID,ComponentID,Operationno,operatorid,ShiftID 
					) T1
					On T1.MachineID=Bs.MachineID and T1.ComponentID=Bs.ComponentID
					and T1.Operationno=Bs.Operationno and T1.operatorid=Bs.operatorid
					and T1.ShiftID=Bs.ShiftID


					if @param <> ''
					begin 
					    Select B.Machineid,M.description as Machinedescription,B.ComponentId,
						B.Operationno, B.Operatorid,e.name as OperatorName, B.ShiftName, B.ShiftID, B.HourID,					
						B.FromTime,B.ToTime,round(cast(B.Actual as float),2) as Actual,  CEILING(B.Target) as Target,CEILING(B.Hourlytarget) as Hourlytarget
						,round(B.ShftActualCount,2) as ShftActualCount,P.PlantID,B.RejCount,B.ShftRejCount ShiftRejCount 
						from #Base_Prod_ctn_Temp B
						INNER JOIN machineinformation M ON B.Machineid = m.machineid
						left outer join Plantmachine P on P.machineid=B.machineID
						left outer join employeeinformation e on e.employeeid=b.Operatorid
					--	where isnull(B.ShftActualCount,0)>0 
						order by B.shiftID,B.MachineID,P.PlantID,B.componentID,B.operationno,B.operatorID asc
					end 
					else 
					 begin
					    Select B.Machineid,M.description as Machinedescription,B.ComponentId,
						B.Operationno, B.Operatorid,e.name as OperatorName, B.ShiftName, B.ShiftID, B.HourID,					
						B.FromTime,B.ToTime,round(cast(B.Actual as float),2) as Actual, CEILING(B.Target) as Target,CEILING(B.Hourlytarget) as Hourlytarget
						,round(B.ShftActualCount,2) as ShftActualCount,P.PlantID,B.RejCount,B.ShftRejCount ShiftRejCount 
						 from #Base_Prod_ctn_Temp B
						 INNER JOIN machineinformation M ON B.Machineid = m.machineid
						left outer join Plantmachine P on P.machineid=B.machineID
						left outer join employeeinformation e on e.employeeid=b.Operatorid
						where isnull(B.ShftActualCount,0)>0 
						order by B.shiftID,B.MachineID,P.PlantID,B.componentID,B.operationno,B.operatorID asc
					end
					
				END
			    --ER0327 added Till Here

END


if @RptProd_down='Down'
	Begin

       --ER0382
		declare @TS as datetime
		declare @TE as datetime
		Select @TS = @TmpStartdate
		Select @TE = @TmpEnddate
		--ER0382

		Set @strPlant_Machine=''
		If isnull(@MachineID,'') <> ''
		BEGIN
			--SELECT @strPlant_Machine = @strPlant_Machine+' AND ( Machineinformation.machineid = N''' + @MachineID+ ''')' --ER0382
			  SELECT @strPlant_Machine = @strPlant_Machine+' AND ( M.machineid = N''' + @MachineID+ ''')' --ER0382
		END

		IF isnull(@PlantID,'') <> ''
		BEGIN
			--SELECT @strPlant_Machine =@strPlant_Machine+ ' AND ( PlantMachine.PlantID = N''' + @PlantID+ ''')' --ER0382
			  SELECT @strPlant_Machine =@strPlant_Machine+ ' AND ( PM.PlantID = N''' + @PlantID+ ''')' --ER0382
		END

		/*** ER0382 From Here
		Set @strsql=''
		--Select @strsql=' Select  Machineinformation.MachineID,C.componentID, '     --ER0323 Commented
		Select @strsql=' Select  Machineinformation.MachineID,substring(C.componentID,1,charindex('''+' '+''',C.componentID)) as componentID,
				 LTRIM(substring(C.componentID,charindex('''+' '+''',C.componentID),len(C.componentID)-1)) as CompDescription, '  --ER0323 Added
		Select @strsql= @strsql + 'O.operationno,autodata.sttime AS StartTime,
					autodata.ndtime AS EndTime,
					employeeinformation.Employeeid AS OperatorID,
					downcodeinformation.downid AS DownID,
					isnull(autodata.loadunload,0) as Dwntm_Sec,
					dbo.f_FormatTime (isnull(autodata.loadunload,0),''hh:mm:ss'')
					AS DownTime,
					   autodata.Remarks,T1.cnt as MCwiseCnt,PlantMachine.PlantID
							FROM	autodata
									INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID
									INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
									INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid
									inner join componentinformation C on C.interfaceid=autodata.comp
									inner join componentoperationpricing O on O.interfaceid=autodata.opn
									and C.componentid=O.componentid and O.MachineID = machineinformation.MachineID
									inner join (Select machineinformation.MachineID,dbo.f_FormatTime (Sum(isnull(Autodata.loadunload,0)),''hh:mm:ss'')  as Cnt
												from Machineinformation
												inner join Autodata on Autodata.mc=machineinformation.InterfaceID
												INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
												INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid
												inner join componentinformation C on C.interfaceid=autodata.comp
												inner join componentoperationpricing O on O.interfaceid=autodata.opn
									and C.componentid=O.componentid and O.MachineID = machineinformation.MachineID
												where autodata.datatype = 2 AND
												(autodata.sttime >='''+Convert(nvarchar(25),@TmpStartdate,120)+'''
												AND autodata.ndtime <='''+Convert(nvarchar(25),@TmpEnddate,120)+''')
												Group by machineinformation.MachineID  ) T1 on T1.machineID=Machineinformation.MachineiD
									left outer join PlantMachine  on machineinformation.machineid = PlantMachine.MachineID
							WHERE	autodata.datatype = 2 AND
									(autodata.sttime >='''+Convert(nvarchar(25),@TmpStartdate,120)+'''
								 AND autodata.ndtime <='''+Convert(nvarchar(25),@TmpEnddate,120)+''')  '
								+ @strPlant_Machine+' Order by PlantMachine.PlantID,Machineinformation.MachineID,
								autodata.sttime,autodata.ndtime,C.componentID,O.operationno,employeeinformation.Employeeid Asc'
				print(@strsql)
				Exec(@strsql)
			ER0382 Till Here	***/



		---------------------------------------- ER0382 From Here -------------------------------------------
		Select M.MachineID,M.description,dbo.f_FormatTime (Sum
		(Case  
		when (A.sttime>=Convert(nvarchar(25),@TS,120) AND A.ndtime<=Convert(nvarchar(25),@TE,120)) then (A.loadunload)
		when (A.sttime<Convert(nvarchar(25),@TS,120) AND A.ndtime<=Convert(nvarchar(25),@TE,120) AND A.ndtime>Convert(nvarchar(25),@TS,120)) then datediff(s,Convert(nvarchar(25),@TS,120),A.ndtime)
		when (A.sttime>=Convert(nvarchar(25),@TS,120) AND A.sttime<Convert(nvarchar(25),@TE,120) AND A.ndtime> Convert(nvarchar(25),@TE,120) ) then datediff(s,A.sttime,Convert(nvarchar(25),@TE,120))		
		when (A.sttime<Convert(nvarchar(25),@TS,120) AND A.ndtime>Convert(nvarchar(25),@TE,120)) then datediff(s,Convert(nvarchar(25),@TS,120),Convert(nvarchar(25),@TE,120))
		end),'hh:mm:ss') as Cnt
		into #Downdata 
		from Machineinformation M 
		inner join #T_autodata A on A.mc=M.InterfaceID
		INNER JOIN downcodeinformation DI ON A.dcode = DI.interfaceid
		INNER JOIN employeeinformation E ON A.opr = E.interfaceid
		inner join componentinformation C on C.interfaceid=A.comp
		inner join componentoperationpricing O on O.interfaceid=A.opn
		and C.componentid=O.componentid and O.MachineID = M.MachineID 
		where A.datatype=2 AND
		((A.sttime>=Convert(nvarchar(25),@TS,120) AND A.ndtime<=Convert(nvarchar(25),@TE,120))
		OR(A.sttime<Convert(nvarchar(25),@TS,120) AND A.ndtime<=Convert(nvarchar(25),@TE,120) AND A.ndtime>Convert(nvarchar(25),@TS,120))
		OR(A.sttime>=Convert(nvarchar(25),@TS,120) AND A.sttime<Convert(nvarchar(25),@TE,120) AND A.ndtime>Convert(nvarchar(25),@TE,120))
		OR(A.sttime<Convert(nvarchar(25),@TS,120) AND A.ndtime>Convert(nvarchar(25),@TE,120)))
		Group by M.MachineID,M.description

		Set @strsql=''
		--Select @strsql=' Select  Machineinformation.MachineID,C.componentID, '     --ER0323 Commented     
		Select @strsql=' Select M.MachineID,M.description as Machinedescription,'
				 --substring(C.componentID,1,charindex('''+' '+''',C.componentID)) as componentID,LTRIM(substring(C.componentID,charindex('''+' '+''',C.componentID),len(C.componentID)-1)) as CompDescription,'  --ER0323 Added   --DR0379
		Select @strsql=@strsql + 'C.componentID as componentID,C.Description as CompDescription, ' --DR0379                                         
		Select @strsql= @strsql + 'O.operationno,
					case when A.sttime<'''+Convert(nvarchar(25),@TS,120)+''' then '''+Convert(nvarchar(25),@TS,120)+''' else A.sttime end AS StartTime, 
					case when A.ndtime>'''+Convert(nvarchar(25),@TE,120)+''' then '''+Convert(nvarchar(25),@TE,120)+''' else A.ndtime end AS EndTime, 
					E.Employeeid AS OperatorID,
					DI.downid AS DownID,
					--isnull(A.loadunload,0) as Dwntm_Sec, 
					isnull(Case  
							when (A.sttime>='''+Convert(nvarchar(25),@TS,120)+''' AND A.ndtime<='''+Convert(nvarchar(25),@TE,120)+''') then (A.loadunload)
							when (A.sttime<'''+ convert(nvarchar(25),@TS,120)+''' AND A.ndtime<='''+ convert(nvarchar(25),@TE,120)+''' AND A.ndtime>'''+ convert(nvarchar(25),@TS,120)+''') then datediff(s,'''+Convert(nvarchar(25),@TS,120)+''',A.ndtime)
						    when (A.sttime>='''+ convert(nvarchar(25),@TS,120)+''' AND A.sttime<'''+ convert(nvarchar(25),@TE,120)+''' AND A.ndtime>'''+ convert(nvarchar(25),@TE,120)+''') then datediff(s,A.sttime,''' + convert(nvarchar(25),@TE,120)+''')		
							when (A.sttime<'''+ convert(nvarchar(25),@TS,120)+''' AND A.ndtime>'''+ convert(nvarchar(25),@TE,120)+''') then datediff(s,'''+ convert(nvarchar(25),@TS,120)+''','''+ convert(nvarchar(25),@TE,120)+''')
							end,0) as Dwntm_Sec,
					dbo.f_FormatTime(isnull(
							Case  
							when (A.sttime>='''+Convert(nvarchar(25),@TS,120)+''' AND A.ndtime<='''+Convert(nvarchar(25),@TE,120)+''') then (A.loadunload)
							when (A.sttime<'''+ convert(nvarchar(25),@TS,120)+''' AND A.ndtime<='''+ convert(nvarchar(25),@TE,120)+''' AND A.ndtime>'''+ convert(nvarchar(25),@TS,120)+''') then datediff(s,'''+Convert(nvarchar(25),@TS,120)+''',A.ndtime)
						    when (A.sttime>= '''+ convert(nvarchar(25),@TS,120)+''' AND A.sttime<'''+ convert(nvarchar(25),@TE,120)+''' AND A.ndtime>'''+ convert(nvarchar(25),@TE,120)+''') then datediff(s,A.sttime,'''+ convert(nvarchar(25),@TE,120)+''')		
							when (A.sttime< '''+ convert(nvarchar(25),@TS,120)+''' AND A.ndtime>'''+ convert(nvarchar(25),@TE,120)+''') then datediff(s,''' + convert(nvarchar(25),@TS,120)+''',''' + convert(nvarchar(25),@TE,120)+''')
							end,0),''hh:mm:ss'')AS DownTime,
					   A.Remarks,T1.cnt as MCwiseCnt,PM.PlantID
							FROM #T_autodata A
									INNER JOIN machineinformation M ON A.mc = M.InterfaceID
									INNER JOIN downcodeinformation DI ON A.dcode = DI.interfaceid
									INNER JOIN employeeinformation E ON A.opr = E.interfaceid
									inner join componentinformation C on C.interfaceid=A.comp
									inner join componentoperationpricing O on O.interfaceid=A.opn
									and C.componentid=O.componentid and O.MachineID = M.MachineID
									inner join #Downdata T1 on T1.machineID=M.MachineiD
									left outer join PlantMachine  PM on M.machineid = PM.MachineID
							WHERE	A.datatype = 2 AND
									((A.sttime>='''+Convert(nvarchar(25),@TS,120)+''' AND A.ndtime<='''+Convert(nvarchar(25),@TE,120)+''')  
									OR (A.sttime<'''+ convert(nvarchar(25),@TS,120)+''' AND A.ndtime<='''+ convert(nvarchar(25),@TE,120)+''' AND A.ndtime>'''+ convert(nvarchar(25),@TS,120)+''')
									OR (A.sttime>='''+ convert(nvarchar(25),@TS,120)+''' AND A.sttime<'''+ convert(nvarchar(25),@TE,120)+''' AND A.ndtime>'''+ convert(nvarchar(25),@TE,120)+''')
									OR (A.sttime<'''+ convert(nvarchar(25),@TS,120)+''' AND A.ndtime>'''+ convert(nvarchar(25),@TE,120)+'''))'
								+ @strPlant_Machine+' Order by PM.PlantID,M.MachineID,
								A.sttime,A.ndtime,C.componentID,O.operationno,E.Employeeid Asc'
				print(@strsql)
				Exec(@strsql)
		---------------------------------------------------- ER0382 Till Here -------------------------------------------------------


	End
End
