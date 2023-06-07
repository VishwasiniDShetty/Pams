/****** Object:  Procedure [dbo].[s_GetOEE_losses_BOSCH_BNG_CamShaft_AtLineLevel]    Committed by VersionSQL https://www.versionsql.com ******/

 
/***********************************************************************************************
Procedure Created By Karthik G on 12/Jul/2009 for showing OEE and other Loss Foctors.    
NR0056 - KarthikG - 05/Jun/2009 - Need new Excel Report showing OEE and other Loss Foctors.    
Used in the report (SM->Agg report->Breakdown Report->OEE Losses.)    
s_GetOEE_losses_BOSCH_BNG_CamShaft_AtLineLevel '2017-07-15','','','L2 ace gantry','Downcategory',''    
******************************************************************************************/    

CREATE  procedure [dbo].[s_GetOEE_losses_BOSCH_BNG_CamShaft_AtLineLevel]    
@dDate as DateTime,    
@machineID as nvarchar(50)='',    
@plantID nvarchar(50)='',    
@GroupID nvarchar(50)='',    
@DownID_Category as nvarchar(50),--DownID,DownCategory    
@param as nvarchar(50)--'','BOSCH_BNG_CamShaft'    
    
    
AS    
BEGIN    
    
Declare @tempDate as datetime    
Declare @InPutDate as datetime    
Declare @Counter as int    
declare @Monthdate as datetime    
    
Set @Counter = 1    
set @InPutDate=@dDate    
set @dDate = cast(cast(datepart(yyyy,@dDate)as nvarchar(4))+'-'+cast(datepart(mm,@dDate)as nvarchar(4))+'-01' as datetime)    
    
CREATE TABLE #DownID_Category     
(    
DownID_Category nvarchar(50),    
idd int identity(4,1)    
)    
    
CREATE TABLE #YearMonthDay    
(    
YearMonthDay nvarchar(50),    
ColumnHeader DateTime    
)    
    
CREATE TABLE #TempOEE_losses     
(    
YearMonthDay nvarchar(50),    
ColumnHeader DateTime,    
RowHeader nvarchar(50),    
RowValue Float,    
idd int    
)    
    
CREATE TABLE #OEE_losses     
(    
Machineid nvarchar(50),    
Machineinterface nvarchar(50),    
MachineDescription nvarchar(50),    
YearMonthDay nvarchar(50),    
ColumnHeader DateTime,    
RowHeader nvarchar(50),    
RowValue Float,    
idd int    
)    
    
CREATE TABLE #Summary    
(    
Machineid nvarchar(50),    
Machineinterface nvarchar(50),    
MachineDescription nvarchar(50),    
YearMonthDay nvarchar(50),    
ColumnHeader DateTime,    
RowHeader nvarchar(50),    
RowValue Float,    
idd int    
)    
    
DECLARE @strsql as varchar(4000)    
DECLARE @strmachine AS nvarchar(250)    
Declare @strPlantID as nvarchar(255)    
Declare @strGroupID as nvarchar(255)    
    
    
SELECT @strsql = ''    
SELECT @strmachine = ''    
SELECT @strPlantID = ''    
SELECT @strGroupID = ''    
    
    
if isnull(@machineid,'')<> ''    
begin    
 SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''    
end    
    
if isnull(@PlantID,'')<> ''    
Begin    
 SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''    
End    
    
if isnull(@GroupID,'')<> ''    
Begin    
 SET @strGroupID = ' AND PlantMachineGroups.GroupID = N''' + @GroupID + ''''    
End    
    
    
Insert Into #DownID_Category select 'OEE'
--Insert Into #DownID_Category select 'QualityLoss'
--Insert Into #DownID_Category select 'PE loss'   
Insert Into #DownID_Category select 'Quality Losses'
Insert Into #DownID_Category select 'Performance Loss'  

    
if @DownID_Category = 'DownCategory'    
Begin    
 Insert Into #DownID_Category Select distinct Catagory from downcodeinformation where Catagory is not null order by Catagory    
End    
else if @DownID_Category = 'DownID'    
Begin    
 Insert Into #DownID_Category Select distinct DownID from downcodeinformation where DownID is not null order by DownID    
End    
    
Insert Into #YearMonthDay select 'Year', @dDate    
    
Set @tempDate = @dDate    
set @Monthdate = @ddate    
    
    
while @Counter <= 31    
Begin    
 Insert Into #YearMonthDay select 'Day', @tempDate    
 set @tempDate = DateAdd(d,1,@tempDate)    
 Set @Counter = @Counter + 1    
End    
    
set @Monthdate = cast(cast(datepart(yyyy,@Monthdate)as nvarchar(4))+'-01-01' as datetime)    
Set @dDate = DateAdd(yyyy,1,@Monthdate)    
    
While @Monthdate < @dDate    
Begin    
 Insert Into #YearMonthDay select 'Month', @Monthdate    
 Set @Monthdate = DateAdd(mm,1,@Monthdate)    
End    
    
    
Insert into #TempOEE_losses(YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
Select YearMonthDay,ColumnHeader,DownID_Category,0,idd from #YearMonthDay cross join #DownID_Category order by YearMonthDay desc,ColumnHeader    
    
Select @strsql = ''    
Select @Strsql =     
'Insert into #OEE_losses(Machineid,Machineinterface,MachineDescription,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
Select Machineinformation.Machineid,Machineinformation.interfaceid,PlantMachineGroups.GroupID,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd from Machineinformation      
inner join Plantmachine on Machineinformation.Machineid=Plantmachine.Machineid    
inner Join PlantMachineGroups on plantmachine.machineID=PlantMachineGroups.machineID and plantmachine.PlantID=PlantMachineGroups.Plantid    
cross join #TempOEE_losses T where 1=1'--PM.Plantid=@Machineid    
Select @strsql = @strsql + @strPlantID + @strMachine + @strGroupID    
Select @strsql = @strsql + ' order by YearMonthDay desc,ColumnHeader,Machineinformation.machineid'    
Exec(@strsql)    
    
update #OEE_losses set RowValue = 0    
    
if @DownID_Category = 'DownCategory'    
Begin    
    
 Update #OEE_losses set RowValue = t1.DownTime from    
 (    
  Select SD.Machineid,SD.dDate,SD.DownCategory,sum(SD.downtime) as DownTime from shiftdowntimedetails SD    
  inner join #OEE_losses O on O.Machineid=SD.Machineid and O.ColumnHeader = SD.dDate and O.RowHeader = SD.DownCategory and O.YearMonthDay = 'Day'     
  and O.RowHeader not in ('LC7','LC16')    
  where SD.ML_Flag = 0 and datepart(mm,SD.dDate) = datepart(mm,@InPutDate) and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate)    
  group by SD.Machineid,SD.dDate,SD.DownCategory    
 ) as t1 inner join #OEE_losses on #OEE_losses.Machineid = t1.Machineid and #OEE_losses.ColumnHeader = t1.dDate and #OEE_losses.RowHeader = t1.DownCategory and #OEE_losses.YearMonthDay = 'Day'     
 and #OEE_losses.RowHeader not in ('LC7','LC16')    
    
    
 Update #OEE_losses set RowValue = t1.DownTime from    
 (    
  Select SD.Machineid,datepart(mm,SD.dDate) as mnth,SD.DownCategory,sum(SD.downtime) as DownTime from shiftdowntimedetails SD    
  inner join #OEE_losses O on  O.Machineid=SD.Machineid and Datepart(mm,O.ColumnHeader) = datepart(mm,SD.dDate) and O.RowHeader = SD.DownCategory and O.YearMonthDay = 'Month'    
  and O.RowHeader not in ('LC7','LC16')    
  where SD.ML_Flag = 0 and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate)    
  group by SD.Machineid,datepart(mm,SD.dDate),SD.DownCategory    
 )    
 as t1 inner join #OEE_losses on #OEE_losses.Machineid = t1.Machineid and Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and #OEE_losses.RowHeader = t1.DownCategory and #OEE_losses.YearMonthDay = 'Month'    
 and #OEE_losses.RowHeader not in ('LC7','LC16')    
    
    
 Update #OEE_losses set RowValue = t1.DownTime from    
 (Select SD.Machineid,SD.DownCategory,sum(SD.downtime) as DownTime from shiftdowntimedetails SD    
 inner join #OEE_losses O on O.Machineid = SD.Machineid and O.RowHeader = SD.DownCategory and O.YearMonthDay = 'Year'    
 and O.RowHeader not in ('LC7','LC16')    
 where SD.ML_Flag = 0 and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate) group by SD.Machineid,SD.DownCategory)    
 as t1 inner join #OEE_losses on #OEE_losses.Machineid = t1.Machineid and #OEE_losses.RowHeader = t1.DownCategory and #OEE_losses.YearMonthDay = 'Year'    
 and #OEE_losses.RowHeader not in ('LC7','LC16')    
    
End    
else if @DownID_Category = 'DownID'    
Begin    
    
    
 Update #OEE_losses set RowValue = t1.DownTime from    
 (    
 Select SD.Machineid,SD.dDate,SD.DownID,sum(SD.downtime) as DownTime from shiftdowntimedetails SD     
 inner join #OEE_losses O on O.Machineid=SD.Machineid and O.ColumnHeader = SD.dDate and    
 O.RowHeader = SD.DownID and O.YearMonthDay = 'Day'    
 where SD.ML_Flag = 0 and datepart(mm,SD.dDate) = datepart(mm,@InPutDate) and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate) and SD.DownCategory not in ('LC7','LC16')     
 group by SD.Machineid,SD.dDate,SD.DownID    
    
 )as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and #OEE_losses.ColumnHeader = t1.dDate and    
 #OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Day'    
 and #OEE_losses.RowHeader in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory not in ('LC7','LC16'))    
    
 Update #OEE_losses set RowValue = t1.DownTime from    
 (    
  Select SD.Machineid,datepart(mm,SD.dDate) as mnth,SD.DownID,sum(SD.downtime) as DownTime from shiftdowntimedetails SD     
  inner join #OEE_losses O on O.Machineid=SD.Machineid and Datepart(mm,O.ColumnHeader) = datepart(mm,SD.dDate) and    
  O.RowHeader = SD.DownID and O.YearMonthDay = 'Month'    
  where SD.ML_Flag = 0 and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate) and SD.DownCategory not in ('LC7','LC16')     
  group by SD.Machineid,datepart(mm,SD.dDate),SD.DownID    
    
 )as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and    
 #OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Month'    
 and #OEE_losses.RowHeader in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory not in ('LC7','LC16'))    
    
 Update #OEE_losses set RowValue = t1.DownTime from    
 (    
  Select SD.Machineid,SD.DownID,sum(SD.downtime) as DownTime from shiftdowntimedetails SD    
  inner join #OEE_losses O on O.Machineid=SD.Machineid and O.RowHeader = SD.DownID and O.YearMonthDay = 'Year'    
  where SD.ML_Flag = 0 and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate) and SD.DownCategory not in ('LC7','LC16')     
  group by SD.Machineid,SD.DownID    
    
 )    
 as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and #OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Year'    
 and #OEE_losses.RowHeader  in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory not in ('LC7','LC16'))    
    
End    
    
    
    
--OEE - From Here====================================================================================    
Update #OEE_losses set RowValue = t1.CN from    
(    
Select SP.Machineid,SP.pDate,sum(SP.AcceptedParts *(SP.CO_StdMachiningTime+SP.CO_StdLoadUnload)) AS CN from shiftproductiondetails SP    
inner join #OEE_losses O on O.Machineid=SP.Machineid and O.ColumnHeader = SP.pDate and O.RowHeader = 'OEE' and O.YearMonthDay = 'Day'     
where datepart(mm,SP.pDate) = datepart(mm,@InPutDate) and datepart(yyyy,SP.pDate) = datepart(yyyy,@InPutDate)     
group by SP.Machineid,SP.pDate    
)    
as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and #OEE_losses.ColumnHeader = t1.pDate and #OEE_losses.RowHeader = 'OEE'    
and #OEE_losses.YearMonthDay = 'Day'    
    
Update #OEE_losses set RowValue = t1.CN from    
(    
Select SP.Machineid,datepart(mm,SP.pDate) as mnth,sum(SP.AcceptedParts *(SP.CO_StdMachiningTime+SP.CO_StdLoadUnload)) AS CN from shiftproductiondetails SP    
inner join #OEE_losses O on O.Machineid=SP.Machineid and Datepart(mm,O.ColumnHeader) = datepart(mm,SP.pDate) and O.RowHeader = 'OEE' and O.YearMonthDay = 'Month'    
where datepart(yyyy,SP.pDate) = datepart(yyyy,@InPutDate)     
group by SP.Machineid,datepart(mm,SP.pDate)    
)    
as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and #OEE_losses.RowHeader = 'OEE' and #OEE_losses.YearMonthDay = 'Month'    
    
Update #OEE_losses set RowValue = t1.CN from    
(    
Select SP.Machineid,sum(SP.AcceptedParts *(SP.CO_StdMachiningTime+SP.CO_StdLoadUnload)) AS CN from shiftproductiondetails SP     
inner join #OEE_losses O on O.Machineid=SP.Machineid and O.RowHeader = 'OEE' and O.YearMonthDay = 'Year'    
where  datepart(yyyy,SP.pDate) = datepart(yyyy,@InPutDate)    
group by SP.Machineid    
)    
as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and #OEE_losses.RowHeader = 'OEE' and #OEE_losses.YearMonthDay = 'Year'    
--OEE - Till Here ===================================================================================    
    
    
    
--Performance Losses - From Here============================================================================    
--Update #OEE_losses set RowValue = t1.PEloss from    
--(    
--select SP.Machineid,SP.pdate,Sum((SP.Sum_of_ActCycleTime)-((SP.CO_stdMachiningTime+SP.CO_StdLoadUnload)*SP.Prod_Qty)) as PEloss from shiftproductiondetails SP    
--inner join #OEE_losses O on O.Machineid=SP.Machineid and O.ColumnHeader = SP.pDate and O.RowHeader = 'Performance Loss' and O.YearMonthDay = 'Day'    
--where datepart(yyyy,SP.pDate) = datepart(yyyy,@InPutDate) and datepart(mm,SP.pDate) = datepart(mm,@InPutDate)     
--group by SP.Machineid,SP.pdate    
--)    
--as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and #OEE_losses.ColumnHeader = t1.pDate and #OEE_losses.RowHeader = 'Performance Loss' and #OEE_losses.YearMonthDay = 'Day'    
 
-- Update #OEE_losses set RowValue = t1.PEloss from    
--(    
--Select SP.Machineid,datepart(mm,SP.pDate) as mnth,Sum((SP.Sum_of_ActCycleTime)-((SP.CO_stdMachiningTime+SP.CO_StdLoadUnload)*SP.Prod_Qty)) as PEloss from shiftproductiondetails SP    
--inner join #OEE_losses O on O.Machineid=SP.Machineid and  Datepart(mm,O.ColumnHeader) = datepart(mm,SP.pDate) and O.RowHeader = 'Performance Loss' and O.YearMonthDay = 'Month'    
--where datepart(yyyy,SP.pDate) = datepart(yyyy,@InPutDate)     
--group by SP.Machineid,datepart(mm,SP.pDate)    
--)    
--as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and #OEE_losses.RowHeader = 'Performance Loss' and #OEE_losses.YearMonthDay = 'Month' 


--Update #OEE_losses set RowValue = t1.PEloss from    
--(Select SP.Machineid,Sum((SP.Sum_of_ActCycleTime)-((SP.CO_stdMachiningTime+SP.CO_StdLoadUnload)*SP.Prod_Qty)) as PEloss from shiftproductiondetails SP    
--inner join #OEE_losses O on O.Machineid=SP.Machineid and O.RowHeader = 'Performance Loss' and O.YearMonthDay = 'Year'    
--where datepart(yyyy,SP.pDate) = datepart(yyyy,@InPutDate)    
--Group by SP.Machineid    
--)    
--as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and #OEE_losses.RowHeader = 'Performance Loss' and #OEE_losses.YearMonthDay = 'Year'   



Update #OEE_losses set RowValue = ISNULL(RowValue,0) + ISNULL(t1.PEloss,0) from
(
Select TT.Machineid,TT.pdate,SUM(TT.PELoss) as PELoss From
(
Select T.pdate,T.Machineid,T.Componentid,T.Operationno,SUM((T.Actcycletime)-(T.StdCycletime*T.ProdQty)) as PELoss From
(select SP.pdate,SP.Machineid,SP.Componentid,SP.Operationno,Sum(SP.Sum_of_ActCycleTime) as Actcycletime,(CO_stdMachiningTime+CO_StdLoadUnload) as StdCycletime,SUM(SP.Prod_Qty) as ProdQty from shiftproductiondetails SP
inner join #OEE_losses O on O.Machineid=SP.Machineid and O.ColumnHeader = SP.pDate and O.RowHeader = 'Performance Loss' and O.YearMonthDay = 'Day'
where datepart(yyyy,pDate) = datepart(yyyy,@InPutDate) and datepart(mm,pDate) = datepart(mm,@InPutDate)
group by SP.pdate,Sp.Machineid,SP.Componentid,SP.Operationno,CO_stdMachiningTime,CO_StdLoadUnload
)T Group by T.pdate,t.Machineid,T.Componentid,T.Operationno)TT group by TT.Machineid,TT.Pdate
)T1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and #OEE_losses.ColumnHeader = t1.pDate and #OEE_losses.RowHeader = 'Performance Loss' and #OEE_losses.YearMonthDay = 'Day'
 
Update #OEE_losses set RowValue = ISNULL(RowValue,0) + ISNULL(t1.PEloss,0) from
(
Select TT.Machineid,TT.mnth,SUM(TT.PELoss) as PELoss From
(
Select T.mnth,T.Machineid,T.Componentid,T.Operationno,SUM((T.Actcycletime)-(T.StdCycletime*T.ProdQty)) as PELoss From
(select datepart(mm,SP.pDate) as mnth,SP.Machineid,SP.Componentid,SP.Operationno,Sum(SP.Sum_of_ActCycleTime) as Actcycletime,(CO_stdMachiningTime+CO_StdLoadUnload) as StdCycletime,SUM(SP.Prod_Qty) as ProdQty from shiftproductiondetails SP
inner join #OEE_losses O on O.Machineid=SP.Machineid and Datepart(mm,O.ColumnHeader) = datepart(mm,SP.pDate)  and O.RowHeader = 'Performance Loss' and O.YearMonthDay = 'Month'
where datepart(yyyy,pDate) = datepart(yyyy,@InPutDate) 
group by datepart(mm,SP.pDate),Sp.Machineid,SP.Componentid,SP.Operationno,CO_stdMachiningTime,CO_StdLoadUnload
)T Group by T.mnth,t.Machineid,T.Componentid,T.Operationno)TT group by TT.Machineid,TT.mnth
)T1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and #OEE_losses.ColumnHeader = t1.mnth and #OEE_losses.RowHeader = 'Performance Loss' and #OEE_losses.YearMonthDay = 'Month'

  Update #OEE_losses set RowValue = ISNULL(RowValue,0) + ISNULL(t1.PEloss,0) from
(
Select TT.Machineid,SUM(TT.PELoss) as PELoss From
(
Select T.Machineid,T.Componentid,T.Operationno,SUM((T.Actcycletime)-(T.StdCycletime*T.ProdQty)) as PELoss From
(select SP.Machineid,SP.Componentid,SP.Operationno,Sum(SP.Sum_of_ActCycleTime) as Actcycletime,(CO_stdMachiningTime+CO_StdLoadUnload) as StdCycletime,SUM(SP.Prod_Qty) as ProdQty from shiftproductiondetails SP
inner join #OEE_losses O on O.Machineid=SP.Machineid and O.RowHeader = 'Performance Loss' and O.YearMonthDay = 'year'
where datepart(yyyy,pDate) = datepart(yyyy,@InPutDate) 
group by Sp.Machineid,SP.Componentid,SP.Operationno,CO_stdMachiningTime,CO_StdLoadUnload
)T Group by t.Machineid,T.Componentid,T.Operationno)TT group by TT.Machineid
)T1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and  #OEE_losses.RowHeader = 'Performance Loss' and #OEE_losses.YearMonthDay = 'year'
    

update  #OEE_losses set RowValue=0 where RowValue<0 and RowHeader = 'Performance Loss'

--Performance Losses - till Here============================================================================    
    
--Quality Losses - From Here============================================================================    
Update #OEE_losses set RowValue = t1.QualityLosses from    
(    
select SPD.Machineid,SPD.pdate,Sum((SPD.CO_stdMachiningTime+SPD.CO_StdLoadUnload)*SDD.Rejection_Qty) as QualityLosses from shiftproductiondetails spd     
inner join #OEE_losses O on O.Machineid=SPD.Machineid and O.ColumnHeader = SPD.pDate and O.RowHeader = 'Quality Losses' and O.YearMonthDay = 'Day'    
inner join shiftrejectiondetails sdd on spd.ID = Sdd.ID     
where datepart(yyyy,SPD.pDate) = datepart(yyyy,@InPutDate) and datepart(mm,SPD.pDate) = datepart(mm,@InPutDate)    
group by SPD.Machineid,SPD.pdate    
)    
as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and #OEE_losses.ColumnHeader = t1.pDate and #OEE_losses.RowHeader = 'Quality Losses' and #OEE_losses.YearMonthDay = 'Day'    
    
Update #OEE_losses set RowValue = t1.QualityLosses from    
(    
Select SPD.Machineid,datepart(mm,SPD.pDate) as mnth,Sum((SPD.CO_stdMachiningTime+SPD.CO_StdLoadUnload)*SDD.Rejection_Qty) as QualityLosses from shiftproductiondetails spd    
inner join #OEE_losses O on O.Machineid=SPD.Machineid and Datepart(mm,O.ColumnHeader) = datepart(mm,SPD.pDate) and O.RowHeader = 'Quality Losses' and O.YearMonthDay = 'Month'    
inner join shiftrejectiondetails sdd on spd.ID = Sdd.ID     
where datepart(yyyy,SPD.pDate) = datepart(yyyy,@InPutDate)    
group by SPD.Machineid,datepart(mm,SPD.pDate)    
)    
as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and #OEE_losses.RowHeader = 'Quality Losses' and #OEE_losses.YearMonthDay = 'Month'    
    
Update #OEE_losses set RowValue = t1.QualityLosses from    
(    
Select SPD.Machineid,Sum((SPD.CO_stdMachiningTime+SPD.CO_StdLoadUnload)*SDD.Rejection_Qty) as QualityLosses from shiftproductiondetails spd     
inner join #OEE_losses O on O.Machineid=SPD.Machineid and O.RowHeader = 'Quality Losses' and O.YearMonthDay = 'Year'    
inner join shiftrejectiondetails sdd on spd.ID = Sdd.ID    
 where datepart(yyyy,SPD.pDate) = datepart(yyyy,@InPutDate)    
group by SPD.Machineid    
)    
as t1 inner join #OEE_losses on #OEE_losses.Machineid=t1.Machineid and #OEE_losses.RowHeader = 'Quality Losses' and #OEE_losses.YearMonthDay = 'Year'    
    
    
    
if @DownID_Category = 'DownCategory'    
Begin    
    
 --DownTime by Category - From Here====================================================================================    
 Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from    
 (    
 Select SD.Machineid,SD.dDate,SD.DownCategory,sum(SD.downtime) as DownTime from shiftdowntimedetails SD     
 inner join #OEE_losses O on O.Machineid=SD.Machineid and O.ColumnHeader = SD.dDate and O.RowHeader = 'Quality Losses' and O.YearMonthDay = 'Day'     
 where ML_Flag = 0 and datepart(mm,SD.dDate) = datepart(mm,@InPutDate) and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate)    
 and SD.DownCategory in ('LC7','LC16')    
 group by SD.Machineid,SD.dDate,SD.DownCategory    
 )    
 as t1 inner join #OEE_losses on #OEE_losses.Machineid = t1.Machineid and #OEE_losses.ColumnHeader = t1.dDate and    
 #OEE_losses.RowHeader = 'Quality Losses' and #OEE_losses.YearMonthDay = 'Day'     
 and #OEE_losses.RowHeader in ('LC7','LC16')    
    
    
 Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from    
 (    
 Select SD.Machineid,datepart(mm,SD.dDate) as mnth,SD.DownCategory,sum(SD.downtime) as DownTime from shiftdowntimedetails SD    
 inner join #OEE_losses O on O.Machineid=SD.Machineid and Datepart(mm,O.ColumnHeader) = datepart(mm,SD.dDate) and O.RowHeader = SD.DownCategory and O.YearMonthDay = 'Month'    
 where SD.ML_Flag = 0 and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate) and SD.DownCategory in ('LC7','LC16')    
 group by SD.Machineid,datepart(mm,SD.dDate),SD.DownCategory    
 )    
 as t1 inner join #OEE_losses on #OEE_losses.Machineid = t1.Machineid and Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and    
 #OEE_losses.RowHeader = t1.DownCategory and #OEE_losses.YearMonthDay = 'Month'    
 and #OEE_losses.RowHeader in ('LC7','LC16')    
    
    
 Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from    
 (    
 Select SD.Machineid,SD.DownCategory,sum(SD.downtime) as DownTime from shiftdowntimedetails SD    
 inner join #OEE_losses O on O.Machineid=SD.Machineid and O.RowHeader = SD.DownCategory and O.YearMonthDay = 'Year'    
 where SD.ML_Flag = 0 and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate) and SD.DownCategory in ('LC7','LC16')     
 group by SD.Machineid,SD.DownCategory    
 )    
 as t1 inner join #OEE_losses on #OEE_losses.Machineid = t1.Machineid and #OEE_losses.RowHeader = t1.DownCategory and #OEE_losses.YearMonthDay = 'Year'    
 and #OEE_losses.RowHeader in ('LC7','LC16')    
 --DownTime by Category - Till Here====================================================================================    
End    
    
else if @DownID_Category = 'DownID'    
Begin    
    
 --DownTime by Category - From Here ====================================================================================    
 Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from    
 (    
 Select SD.Machineid,SD.dDate,SD.DownID,sum(SD.downtime) as DownTime from shiftdowntimedetails SD    
 inner join #OEE_losses O on O.Machineid=SD.Machineid and O.ColumnHeader = SD.dDate and O.RowHeader = SD.DownID and O.YearMonthDay = 'Day'    
 where SD.ML_Flag = 0 and datepart(mm,SD.dDate) = datepart(mm,@InPutDate) and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate)     
 and SD.DownCategory in ('LC7','LC16')     
 group by SD.Machineid,SD.dDate,SD.DownID    
 )    
 as t1 inner join #OEE_losses on #OEE_losses.Machineid = t1.Machineid and  #OEE_losses.ColumnHeader = t1.dDate and #OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Day'    
 and #OEE_losses.RowHeader in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory in ('LC7','LC16'))    
    
    
 Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from    
 (    
 Select SD.machineid,datepart(mm,SD.dDate) as mnth,SD.DownID,sum(SD.downtime) as DownTime from shiftdowntimedetails SD    
 inner join #OEE_losses O on O.Machineid=SD.Machineid and Datepart(mm,O.ColumnHeader) = datepart(mm,SD.dDate) and O.RowHeader = SD.DownID and O.YearMonthDay = 'Month'    
  where SD.ML_Flag = 0 and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate) and SD.DownCategory in ('LC7','LC16')     
 group by SD.machineid,datepart(mm,SD.dDate),SD.DownID    
 )    
 as t1 inner join #OEE_losses on #OEE_losses.Machineid = t1.Machineid and Datepart(mm,#OEE_losses.ColumnHeader) = t1.mnth and    
 #OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Month'    
 and #OEE_losses.RowHeader in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory in ('LC7','LC16'))    
    
    
 Update #OEE_losses set RowValue = Isnull(RowValue,0) + t1.DownTime from    
 (    
 Select SD.Machineid,SD.DownID,sum(SD.downtime) as DownTime from shiftdowntimedetails SD    
 inner join #OEE_losses O on O.Machineid=SD.Machineid and O.RowHeader = SD.DownID and O.YearMonthDay = 'Year'    
  where SD.ML_Flag = 0 and datepart(yyyy,SD.dDate) = datepart(yyyy,@InPutDate) and SD.DownCategory in ('LC7','LC16')     
 group by SD.Machineid,SD.DownID    
 )    
 as t1 inner join #OEE_losses on #OEE_losses.Machineid = t1.Machineid and #OEE_losses.RowHeader = t1.DownID and #OEE_losses.YearMonthDay = 'Year'    
 and #OEE_losses.RowHeader in (Select distinct DownID from downcodeinformation where DownID is not null and  Catagory in ('LC7','LC16'))    
 --DownTime by Category - Till Here ====================================================================================    
End    
    
    
--Quality Losses - till Here============================================================================    
if @DownID_Category = 'DownCategory'    
Begin    
 update #OEE_losses set RowHeader = t1.Description from     
 (select DownCategory,isnull(Description,DownCategory) as Description from downcategoryinformation) as t1     
 inner join #OEE_losses on t1.DownCategory = #OEE_losses.RowHeader    
End    
    
-- insert into #Summary(MachineDescription,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
-- select 'ACE FT',YearMonthDay,ColumnHeader,RowHeader,sum(RowValue),idd    
-- from #OEE_losses where Machinedescription like ('%FT%') group by YearMonthDay,ColumnHeader,RowHeader,idd    
--    
-- insert into #Summary(MachineDescription,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
-- select 'ACE ST',YearMonthDay,ColumnHeader,RowHeader,sum(RowValue),idd    
-- from #OEE_losses where Machinedescription like ('%ST%') group by YearMonthDay,ColumnHeader,RowHeader,idd    
--    
-- insert into #Summary(MachineDescription,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
-- select 'AMS A',YearMonthDay,ColumnHeader,RowHeader,sum(RowValue),idd    
-- from #OEE_losses where Machinedescription like ('%A%') group by YearMonthDay,ColumnHeader,RowHeader,idd    
--    
-- insert into #Summary(MachineDescription,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
-- select 'AMS B',YearMonthDay,ColumnHeader,RowHeader,sum(RowValue),idd    
-- from #OEE_losses where Machinedescription like ('%B%') group by YearMonthDay,ColumnHeader,RowHeader,idd    
--    
-- insert into #Summary(MachineDescription,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
-- select 'KM DIA 6',YearMonthDay,ColumnHeader,RowHeader,sum(RowValue),idd    
-- from #OEE_losses where Machinedescription like ('KM DIA 6') group by YearMonthDay,ColumnHeader,RowHeader,idd    
--    
-- insert into #Summary(MachineDescription,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
-- select 'KM DIA 1.43',YearMonthDay,ColumnHeader,RowHeader,sum(RowValue),idd    
-- from #OEE_losses where Machinedescription like ('KM DIA 1.43') group by YearMonthDay,ColumnHeader,RowHeader,idd    
--    
-- insert into #Summary(MachineDescription,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
-- select 'KM DIA 2.2',YearMonthDay,ColumnHeader,RowHeader,sum(RowValue),idd    
-- from #OEE_losses where Machinedescription like ('KM DIA 2.2') group by YearMonthDay,ColumnHeader,RowHeader,idd    
--    
-- insert into #Summary(MachineDescription,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
-- select 'KM A/F MILLING',YearMonthDay,ColumnHeader,RowHeader,sum(RowValue),idd    
-- from #OEE_losses where Machinedescription like ('KM A/F MILLING') group by YearMonthDay,ColumnHeader,RowHeader,idd    
    
    
 insert into #Summary(Machineid,MachineDescription,YearMonthDay,ColumnHeader,RowHeader,RowValue,idd)    
 select Machineid,MachineDescription,YearMonthDay,ColumnHeader,RowHeader,sum(RowValue),idd    
 from #OEE_losses group by Machineid,MachineDescription,YearMonthDay,ColumnHeader,RowHeader,idd    
    
 Select T.MachineDescription,T.YearMonthDay,T.ColumnHeader,T.RowHeader,IsNull(SUM(RowValue),0) as RowValue from     
 (    
 Select case when @Machineid<>'' or @Groupid='' then Machineid else MachineDescription end as MachineDescription,YearMonthDay,ColumnHeader,RowHeader,IsNull(RowValue,0) as RowValue from #Summary    
where Rowheader like 'OEE%' or  Rowheader like 'Quality%' or Rowheader like 'ChangeOver%' or Rowheader like 'Technical%' or Rowheader like 'Organizational%' or Rowheader like 'Performance%' )T Group By T.MachineDescription,T.YearMonthDay,T.ColumnHeader,T.RowHeader    
 order by T.MachineDescription,T.YearMonthDay,T.ColumnHeader,T.RowHeader --idd    
    
END    
    
