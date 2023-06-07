/****** Object:  Procedure [dbo].[S_ViewInspectionReport_GEA]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[S_ViewInspectionReport_GEA] '','P003','1'
CREATE  PROCEDURE [dbo].[S_ViewInspectionReport_GEA]
@Param nvarchar(50)='',
@ProdOrderNo nvarchar(50)='',
@OpnNo nvarchar(50)=''
WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

create table #InspecDetails
(
idd int default 0,
ShiftDate datetime,    
Shiftname nvarchar(20),  
ShftSTtime datetime,  
ShftEndTime datetime,  
Machineid nvarchar(50),
MaterialID nvarchar(50),
OpnNo nvarchar(50),
ProdOrderNo nvarchar(50),
SlNo nvarchar(50),
CharacteristicSlNo nvarchar(50),
CharacteristicCode nvarchar(50),
InsByOpr nvarchar(50), 
InsByQAEngg nvarchar(50),
OprTS nvarchar(50), 
QAEnggTS nvarchar(50), 
OprValue1 nvarchar(50),
OprValue2 nvarchar(50),
QAValue1 nvarchar(50),
QAValue2 nvarchar(50),
InspectorName nvarchar(50),
Oprname nvarchar(50),
OprRemarks nvarchar(500),
QARemarks nvarchar(500),
PlanAndRevNo nvarchar(50),
InspectedTS datetime
)

CREATE TABLE #ShiftDefn  
(  
 ShiftDate datetime,    
 Shiftname nvarchar(20),  
 ShftSTtime datetime,  
 ShftEndTime datetime   
)  

declare @starttime as datetime
declare @endtime as datetime



Select distinct I.MaterialID,substring(C.description,charindex('[',C.description,1)+1,charindex('][',C.description)-2) as Model,
substring(C.description,charindex('[',C.description,2)+1,len(C.description)-charindex(']',C.description)-2) as description,I.ProductionOrderNo,
I.MachineID,I.PlanAndRevNo,COP.drawingno as InspectionDrawing,I.SerialNo,I.OperationNo into #TempInspec
from InspectionTransaction_GEA I
inner join componentinformation C on I.MaterialID=C.componentid
inner join componentoperationpricing COP on COP.componentid=C.componentid and COP.machineid=I.MachineID and COP.operationno=I.OperationNo
inner join SPC_Characteristic S on S.ComponentID=I.MaterialID and S.OperationNo=I.OperationNo
where I.ProductionOrderNo=@ProdOrderNo and I.OperationNo=@OpnNo 

insert into #InspecDetails(Machineid,MaterialID,ProdOrderNo,OpnNo,SlNo,CharacteristicSlNo,CharacteristicCode,PlanAndRevNo)
Select distinct I.Machineid,I.MaterialID,I.ProductionOrderNo,I.OperationNo,I.SerialNo,SP.CharacteristicID,SP.CharacteristicCode,I.PlanAndRevNo from #TempInspec I
inner join SPC_Characteristic SP on I.MaterialID=SP.ComponentID and I.OperationNo=SP.OperationNo and I.PlanAndRevNo=SP.PlanNoAndRevNo

Update #InspecDetails SET OprName=T.opr,OprValue1=T.InspectionValue1,OprValue2=T.InspectionValue2,OprTS=T.TS,OprRemarks=t.Remarks From
(Select I.MachineID,I.MaterialID,I.OpnNo,I.ProdOrderNo,I.CharacteristicSlNo,I.PlanAndRevNo,I.Slno,IW.InspectionValue1,IW.InspectionValue2
,IW.InspectedTS as TS,IW.OprInspectorName as opr,IW.Remarks From #InspecDetails I
inner join InspectionTransaction_GEA IW on IW.MaterialID=I.MaterialID and IW.OperationNo=I.OpnNo
and IW.ProductionOrderNo=I.ProdOrderNo and IW.CharacteristicSlNo=I.CharacteristicSlNo and IW.PlanAndRevNo=I.PlanAndRevNo AND IW.SerialNo=I.Slno and I.machineid=IW.MachineID 
where IW.InspectedBy='Operator' and IW.OperationNo=@OpnNo and IW.ProductionOrderNo=@ProdOrderNo
)T inner join #InspecDetails I on T.MaterialID=I.MaterialID and T.OpnNo=I.OpnNo and T.ProdOrderNo=I.ProdOrderNo
and T.Slno=I.slno and T.CharacteristicSlNo=I.CharacteristicSlNo and T.PlanAndRevNo=I.PlanAndRevNo and T.machineid=I.machineid

Update #InspecDetails SET InspectorName=T.opr,QAValue1=T.InspectionValue1,QAValue2=T.InspectionValue2,QAEnggTS=T.TS,QARemarks=t.Remarks From
(Select I.MachineID,I.MaterialID,I.OpnNo,I.ProdOrderNo,I.CharacteristicSlNo,I.PlanAndRevNo,I.Slno,IW.InspectionValue1,IW.InspectionValue2
,IW.InspectedTS as TS,IW.OprInspectorName as opr,IW.Remarks From #InspecDetails I
inner join InspectionTransaction_GEA IW on IW.MaterialID=I.MaterialID and IW.OperationNo=I.OpnNo
and IW.ProductionOrderNo=I.ProdOrderNo and IW.CharacteristicSlNo=I.CharacteristicSlNo and IW.PlanAndRevNo=I.PlanAndRevNo AND IW.SerialNo=I.Slno and I.machineid=IW.MachineID 
where IW.InspectedBy='QA Engineer' and IW.OperationNo=@OpnNo and IW.ProductionOrderNo=@ProdOrderNo
)T inner join #InspecDetails I on T.MaterialID=I.MaterialID and T.OpnNo=I.OpnNo and T.ProdOrderNo=I.ProdOrderNo and T.MaterialID=I.MaterialID 
and T.Slno=I.slno and T.CharacteristicSlNo=I.CharacteristicSlNo and T.PlanAndRevNo=I.PlanAndRevNo and T.machineid=I.machineid  

select @starttime=[dbo].[f_GetLogicalDayStart](min(I.OprTS)),@endtime=[dbo].[f_GetLogicalDayStart](max(I.OprTS)) from #InspecDetails I


while @starttime<=@endtime
Begin
	Insert into #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
	Exec s_GetShiftTime @starttime,''
	select @starttime=dateadd(day,1,@starttime)
End

update #InspecDetails set ShiftDate=T.ShiftDate,ShiftName=T.Shiftname from(
Select I.MachineID,I.MaterialID,I.OpnNo,I.ProdOrderNo,I.CharacteristicSlNo,I.PlanAndRevNo,I.Slno,I.OprTS,convert(nvarchar(10),S.ShiftDate,120) as shiftdate,S.Shiftname
From #InspecDetails I cross join #ShiftDefn S
where (I.OprTS>=S.ShftSTtime and I.OprTS<=S.ShftEndTime))T  inner join #InspecDetails I on T.MachineID=I.MachineID and T.MaterialID=I.MaterialID and T.OpnNo=I.OpnNo and T.ProdOrderNo=I.ProdOrderNo
and T.Slno=I.slno and T.CharacteristicSlNo=I.CharacteristicSlNo and T.PlanAndRevNo=I.PlanAndRevNo and T.OprTS=I.OprTS


select * from #TempInspec

select ROW_NUMBER() Over(order by CharacteristicCode) as Rownumber,CharacteristicCode as Parameter,
case when isnull(OprValue2,'')<>'' then OprValue1 + '\' + isnull(OprValue2,'') else OprValue1 end as OperatorMeasurement,
case when isnull(QAValue2,'')<>'' then QAValue1 + '\' + isnull(QAValue2,'') else QAValue1 end as QualityMeasurement,
OprName as OperatorID,e.Name as OperatorName,convert(nvarchar(10),ShiftDate,120) as SDate,Shiftname,
case when ISNULL(OprRemarks,'')<>'' and ISNULL(QARemarks,'')<>'' then OprRemarks + ',' + QARemarks 
when ISNULL(QARemarks,'')='' then OprRemarks
when ISNULL(OprRemarks,'')='' then QARemarks END as Remarks,
Machineid,MaterialID,ProdOrderNo,OpnNo,SlNo,CharacteristicSlNo,PlanAndRevNo,
OprTS,QAEnggTS  from #InspecDetails
LEFT OUTER JOIN employeeinformation e on e.Employeeid=#InspecDetails.Oprname
order by ShftSTtime
 
END
