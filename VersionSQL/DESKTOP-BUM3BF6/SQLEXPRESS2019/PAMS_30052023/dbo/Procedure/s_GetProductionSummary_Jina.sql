/****** Object:  Procedure [dbo].[s_GetProductionSummary_Jina]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from Production_Summary_Jina
--select * from Rejection_Rework_Details_Jina
--[dbo].[s_GetProductionSummary_Jina] '2014-02-01','first','CT-26','','','delete_insert'
CREATE   PROCEDURE [dbo].[s_GetProductionSummary_Jina]  
 @Date as DateTime='',  
 @Shift as Nvarchar(20)='',  
 @MachineID as NvarChar(100)='',
 @ComponentID as nvarchar(50)='',
 @WorkorderNo  as nvarchar(50)='',
 @param as nvarchar(50)=''
 
AS   
BEGIN  
Declare @StartTime as datetime  
Declare @EndTime as datetime  
Declare @strMachine as nvarchar(2000) 
Declare @strComponentID as nvarchar(250)  
Declare @StrSql as varchar(8000) 
Declare @companyDefault as nvarchar(50)
 
select distinct @companyDefault= Employeeid from employeeinformation where Company_default=1

create table #TempMCOODown2  
(  
Mdate datetime,  
MShift nvarchar(50),  
MShiftStart datetime,  
MShiftEnd datetime ,
Shiftid int  
)  
create table #Temp1
(  
pDate datetime,  
Shift nvarchar(50),  
PShiftStart datetime,  
PShiftEnd datetime,    
MachineID nvarchar(50),  
ComponentID nvarchar(50),    
OperationNo nvarchar(50),   
OperatorID nvarchar(50), 
Prod_Qty int default 0,    
WorkOrderNumber nvarchar(50),
BMachineID nvarchar(50), 
BComponentID nvarchar(50),    
BOperationNo nvarchar(50),   
BOperatorID nvarchar(50), 
ReworkPerformed int default 0,
ReworkRejected int default 0,
Shiftid int 
)  


create table #Temp2
(  
[Date] datetime,  
[Shift] nvarchar(50),  
MachineID nvarchar(50),  
ComponentID nvarchar(50),    
OperationNo nvarchar(50),   
OperatorID nvarchar(50),  
WorkOrderNumber nvarchar(50),
ReworkPerformed int default 0,
Rejection_Code int,
Rejection_Qty int default 0,
Flag nvarchar(50),
BMachineID nvarchar(50), 
BComponentID nvarchar(50),    
BOperationNo nvarchar(50),   
BOperatorID nvarchar(50), 
) 


insert into #TempMCOODown2 ( Mdate,MShift,MShiftStart,MShiftEnd)
 EXEC s_GetShiftTime @Date,@Shift  

update #TempMCOODown2 set shiftid = T1.shiftid
from (select distinct shiftname,shiftid from shiftdetails where running=1)T1
inner join #TempMCOODown2 on #TempMCOODown2.MShift=T1.shiftname


--Summarizing Autodata and inserting into temp table with respect to interfaceId
Insert into #Temp1(pDate,Shift,PShiftStart,PShiftEnd,MachineID, ComponentID,OperationNo,OperatorID,WorkOrderNumber,Prod_Qty,Shiftid)  
SELECT T.Mdate,T.Mshift,T.MShiftStart,T.MShiftEnd,a.mc, a.comp,a.opn, a.opr,A.WorkOrderNumber,sum(a.PartsCount),T.Shiftid FROM autodata A   
Cross join #TempMCOODown2 T  WHERE ((A.ndtime>T.MShiftStart AND A.ndtime <=T.MShiftEnd) or  
(A.msttime>=T.MShiftStart and A.msttime<T.MShiftEnd and A.ndtime>T.MShiftEnd) or  
(A.msttime<T.MShiftStart and A.ndtime>T.MShiftEnd))  
AND (A.datatype = 1)  
GROUP BY T.Mdate,T.Mshift,T.MShiftStart,T.MShiftEnd,a.mc , a.comp,a.opn, a.opr,A.WorkOrderNumber,T.Shiftid


--updating Reworkperformed,ReworkRejected for MachineID-CompID-OperationID-OperatorID-Workorderno-Date-Shift
update #Temp1 set ReworkPerformed=t1.ReworkPerformed,ReworkRejected=t1.ReworkRejected from 
(select P.RejDate,P.RejShift,P.mc,P.comp,P.opn,P.opr,P.WorkOrderNumber,Sum(isnull(P.ReworkPerformed,0)) as ReworkPerformed,Sum(isnull(P.ReworkRejected,0)) as ReworkRejected,t.Shiftid from #temp1 t inner join ReworkPerformedSummary_Jina P  
on  t.MachineID=P.mc and t.ComponentID=P.comp and t.OperationNo=p.opn and t.OperatorID=P.opr and t.WorkOrderNumber=P.WorkOrderNumber
where t.pdate=P.RejDate and t.[ShiftID]=P.RejShift
group by P.RejDate,P.RejShift,P.mc,P.comp,P.opn,P.opr,P.WorkOrderNumber,t.Shiftid)t1 inner join #temp1 t2 on 
 t1.RejDate=t2.pDate and t1.RejShift=t2.[ShiftID] and t1.mc=t2.MachineID and t1.comp=t2.ComponentID and t1.opn=t2.OperationNo and t1.opr=t2.OperatorID


 --insert into temp2 table 
insert into #temp2( [Date],[Shift],MachineID,ComponentID,OperationNo,OperatorID,WorkOrderNumber,Rejection_Qty,Rejection_Code,Flag)
select  t.pDate,t.[Shift],t.MachineID,T.ComponentID,t.OperationNo,t.OperatorID,t.WorkOrderNumber,sum(isnull(Q.Rejection_Qty,0)),Q.Rejection_Code,Q.Flag from  
#temp1 t  inner join  AutodataRejections Q on Q.RejDate=t.pDate and Q.RejShift=t.[ShiftID] and Q.mc=t.MachineID and Q.comp=t.ComponentID and Q.opn=t.OperationNo and Q.opr=t.OperatorID and Q.WorkOrderNumber=t.WorkOrderNumber
inner join rejectioncodeinformation R on Q.Rejection_Code=R.interfaceid
group by t.[pDate],t.[Shift],t.MachineID,T.ComponentID,t.OperationNo,t.OperatorID,t.WorkOrderNumber,Q.Rejection_Code,Q.Flag



--update BuisnessID for #temp1 table
update #temp1 set BmachineID =isnull(M.MachineId,'None') from #temp1 T left outer join machineinformation M on T.Machineid=M.InterfaceID
update #temp1 set BComponentID = isnull(c.Componentid,'None') from #temp1 T left outer join componentinformation c on T.ComponentID=C.InterfaceID

update #temp1 set BComponentID = isnull(c.Componentid,'None') from #temp1 T left outer  join  componentoperationpricing c on T.BMachineID=C.machineid and T.BComponentID=C.componentid

update #temp1 set BOperationNo=isnull(cop.operationno,9999) from #temp1 T left outer join  componentoperationpricing cop on T.BMachineID=cop.machineid 
and T.BComponentID=cop.ComponentId and T.OperationNo=cop.InterfaceID

update #temp1 set BOperatorID=isnull(e.employeeid,@companyDefault) from #temp1 T left outer join employeeinformation e on T.OperatorID=e.interfaceid


--update BuisnessID for #temp2 table
update #Temp2 set BmachineID =isnull(M.MachineId,'None') from #Temp2 T left outer join machineinformation M on T.Machineid=M.InterfaceID
update #Temp2 set BComponentID = isnull(c.Componentid,'None') from #Temp2 T left outer join componentinformation c on T.ComponentID=C.InterfaceID
update #Temp2 set BComponentID = isnull(c.Componentid,'None') from #Temp2 T left outer  join  componentoperationpricing c on T.BMachineID=C.machineid and T.BComponentID=C.componentid
update #temp2 set BOperationNo=isnull(cop.operationno,9999) from #temp2 T left outer join  componentoperationpricing cop on T.BMachineID=cop.machineid 
and T.BComponentID=cop.ComponentId and T.OperationNo=cop.InterfaceID 
update #temp2 set BOperatorID=isnull(e.employeeid,@companyDefault) from #temp2 T left outer join employeeinformation e on T.OperatorID=e.interfaceid


if @param='Delete_Insert'
Begin

delete from Production_Summary_Jina where [date]=@Date and [Shift]=@Shift and machine=@MachineID and (Component=@ComponentID or @ComponentID='')
 and (WorkOrderNumber=@WorkorderNo or @WorkorderNo='')

 
 
insert into  Production_Summary_Jina([Date],[Shift],[Machine],[WorkOrderNumber],[Component],[Operation],[Operator],[Qty],[Cycles],[ReworkPerformed],CreatedDate,ModifiedDate)
select t.pdate,t.Shift,t.BMachineID,t.WorkOrderNumber,t.BComponentID,t.BOperationNo,t.BOperatorID, isnull(isnull(t.Prod_Qty,0)-isnull(p.Rejection_Qty,0)+isnull(t.ReworkRejected,0),0),isnull(t.prod_Qty,0),isnull(t.ReworkPerformed,0),getdate(),getdate()
 from #temp1 t		left outer join  (select t4.[Date],t4.[Shift],t4.bMachineID,t4.bComponentID,t4.bOperationNo,t4.bOperatorID,t4.WorkOrderNumber,t4.Flag,isnull(sum(t4.Rejection_Qty),0) as Rejection_Qty 
 from #temp2 t4 where t4.Flag= 'Rejection' 
 group by  t4.[Date],t4.[Shift],t4.bMachineID,t4.bComponentID,t4.bOperationNo,t4.bOperatorID,t4.WorkOrderNumber,t4.Flag
   ) p on t.pDate=p.[Date] and 
t.[shift]=p.[shift]	 and t.BMachineID=p.BMachineID and t.BComponentID=p.BComponentID and t.BOperationNo=P.BOperationNo and t.BOperatorID=p.BOperatorID and t.WorkOrderNumber=p.WorkOrderNumber									
where t.BMachineID=@MachineID and (t.BComponentID=@ComponentID or @ComponentID='') and (t.WorkOrderNumber=@WorkorderNo or @WorkorderNo='')


insert into Rejection_Rework_Details_Jina([Date],[Shift],[Machine],[WorkOrderNumber],[Component],[Operation],[Operator],Rejection_Rework_flag,Person_flag,rejection_rework_qty,code,CreatedDate,ModifiedDate)
select t.date,t.Shift,t.BMachineID,t.WorkOrderNumber,t.BComponentID,t.BOperationNo,t.BOperatorID,t.flag,'Operator',Rejection_Qty,Rejection_Code,getdate(),getdate() from #Temp2 T
where t.BMachineID=@MachineID and (t.BComponentID=@ComponentID or @ComponentID='') and (t.WorkOrderNumber=@WorkorderNo or @WorkorderNo='')

End

if @param='Update_Insert'
Begin

	
	select t.pdate as [Date],t.[Shift] as [Shift],t.BMachineID as Machine,t.WorkOrderNumber as WorkOrderNumber,t.BComponentID as Component,t.BOperationNo as Operation,
	       t.BOperatorID as operator, isnull(t.Prod_Qty- isnull(p.Rejection_Qty,0)+ isnull(t.ReworkRejected,0),0) as Qty,isnull(t.prod_Qty,0) as Cycles,isnull(t.ReworkPerformed,0) as  ReworkPerformed
	 into #temptable
	 from #temp1 t		left outer join  (select t4.[Date],t4.[Shift],t4.bMachineID,t4.bComponentID,t4.bOperationNo,t4.bOperatorID,t4.WorkOrderNumber,t4.Flag,isnull(sum(t4.Rejection_Qty),0) as Rejection_Qty 
	 from #temp2 t4 where t4.Flag= 'Rejection' 
	 group by  t4.[Date],t4.[Shift],t4.bMachineID,t4.bComponentID,t4.bOperationNo,t4.bOperatorID,t4.WorkOrderNumber,t4.Flag
	   ) p on t.pDate=p.[Date] and 
	t.[shift]=p.[shift]	 and t.BMachineID=p.BMachineID and t.BComponentID=p.BComponentID and t.BOperationNo=P.BOperationNo and t.BOperatorID=p.BOperatorID and t.WorkOrderNumber=p.WorkOrderNumber									
	where t.BMachineID=@MachineID and (t.BComponentID=@ComponentID or @ComponentID='') and (t.WorkOrderNumber=@WorkorderNo or @WorkorderNo='')
	

	Update TP SET TP.Qty=T.Qty,TP.Cycles=T.Cycles,Tp.ReworkPerformed=T.ReworkPerformed,tp.ModifiedDate=getdate() 
	FROM Production_Summary_Jina TP INNER JOIN  
	( select  [Date], [Shift], Machine,WorkOrderNumber as WorkOrderNumber, Component, Operation,  operator,  Qty,Cycles,ReworkPerformed  from  #temptable )T ON 
	TP.[Date]=T.[Date] and TP.[Shift]=T.[Shift] and TP.Machine=T.Machine and TP.Component=T.Component and TP.Operation=T.Operation 
	and TP.operator=T. operator and TP.WorkOrderNumber=T.WorkOrderNumber	
	

	insert into  Production_Summary_Jina([Date],[Shift],[Machine],[WorkOrderNumber],[Component],[Operation],[Operator],[Qty],[Cycles],[ReworkPerformed],CreatedDate,ModifiedDate)
	select  T.[Date], T.[Shift], T.Machine,T.WorkOrderNumber as WorkOrderNumber, T.Component, T.Operation,  T.operator,  T.Qty,T.Cycles,T.ReworkPerformed,getdate(),getdate()  
	from  #temptable T left outer join Production_Summary_Jina TP on TP.[Date]=T.[Date] and TP.[Shift]=T.[Shift] and TP.Machine=T.Machine and TP.Component=T.Component and TP.Operation=T.Operation 
	and TP.operator=T. operator and TP.WorkOrderNumber=T.WorkOrderNumber
	where TP.Qty is null

	
	select t.date as [date],t.Shift as [Shift],t.BMachineID as MachineID,t.WorkOrderNumber as WorkorderNo,t.BComponentID as ComponentID,t.BOperationNo as OperationNo,t.BOperatorID as OperatorID,t.flag as Rej_Rwk_flag,'Operator' as personflag,Rejection_Qty as Rej_rwk_qty,Rejection_Code as Rej_Code into #Rej_Rwk_Summary_temp from #Temp2 T
	where t.BMachineID=@MachineID and (t.BComponentID=@ComponentID or @ComponentID='') and (t.WorkOrderNumber=@WorkorderNo or @WorkorderNo='')

	Update AP set Ap.Rejection_Rework_Qty=t.Rej_rwk_qty,
	Ap.[ModifiedDate]=getdate()  
	From Rejection_Rework_Details_Jina AP INNER JOIN  
	(select [date], [Shift], MachineID,  WorkorderNo, ComponentID, OperationNo, OperatorID, Rej_Rwk_flag, Rej_rwk_qty, Rej_Code from #Rej_Rwk_Summary_temp)T   
    ON AP.[date] = T.[date] and  Ap.[Shift]=T.Shift and Ap.[Machine]= T.MachineID and Ap.WorkOrderNumber=T.WorkorderNo and Ap.Component=t.ComponentID and Ap.Operation=t.OperationNo
	and Ap.Operator=t.OperatorID and Ap.Rejection_Rework_flag=t.Rej_Rwk_flag and Ap.Code=t.Rej_Code and Ap.Person_flag='Operator'
	
	insert into Rejection_Rework_Details_Jina([Date],[Shift],[Machine],[WorkOrderNumber],[Component],[Operation],[Operator],Rejection_Rework_flag,Person_flag,rejection_rework_qty,code,CreatedDate,ModifiedDate)
	select t.date as [date],t.Shift as [Shift], MachineID, WorkorderNo, ComponentID, OperationNo, OperatorID, Rej_Rwk_flag,'Operator' as personflag, Rej_rwk_qty, Rej_Code,getdate(),getdate() from #Rej_Rwk_Summary_temp T
	left outer join Rejection_Rework_Details_Jina TP on  TP.[Date]=T.[Date] and TP.[Shift]=T.[Shift] and TP.Machine=T.MachineID and TP.Component=T.ComponentID and TP.Operation=T.OperationNo 
	and TP.operator=T. OperatorID and TP.WorkOrderNumber=T.WorkorderNo and T.Rej_Code=Tp.code and t.personflag='operator'
	where TP.Rejection_Rework_Qty is null

End


END  
