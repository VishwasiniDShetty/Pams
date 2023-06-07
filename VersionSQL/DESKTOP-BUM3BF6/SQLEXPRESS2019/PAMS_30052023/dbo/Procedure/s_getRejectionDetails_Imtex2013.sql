/****** Object:  Procedure [dbo].[s_getRejectionDetails_Imtex2013]    Committed by VersionSQL https://www.versionsql.com ******/

--s_getRejectionDetails_Imtex2013 'ACE-04','2012-02-10 15:00:00','2012-02-10 23:30:00','SECOND'
--s_getRejectionDetails_Imtex2013 'MLC Puma 220','2013-01-03 06:00:00','2013-01-03 14:00:00','A'
--s_getRejectionDetails_Imtex2013 'MLC Puma 220','2013-01-03 14:30:00','2013-01-03 23:00:00','B'
--s_getRejectionDetails_Imtex2013 'MLC Puma 220','2012-12-29 23:00:00','2012-12-30 06:00:00','C'

--s_getRejectionDetails_Imtex2013 'MLC Puma 220','2013-01-03 06:00:00','2013-01-04 14:00:00','All'


CREATE procedure [dbo].[s_getRejectionDetails_Imtex2013]
@Machine nvarchar(50),
@sttime datetime,
@ndtime datetime,
@shift nvarchar(25)
As
 Begin
create table #temp
(
Mc  nvarchar(50),
Machine nvarchar(50),
comp nvarchar(50),
Component  nvarchar(50),
opn nvarchar(50),
Operation  nvarchar(50),
opr nvarchar(50),
Operator nvarchar(50),
Partcount int,
Rejection int
)


insert into  #temp 
select A.mc,MI.Machineid,A.comp,CI.componentid,A.opn,COP.operationno,A.opr,EI.Employeeid,isnull(sum(A.partscount),0),0 from autodata A 
inner join machineinformation MI on A.mc=MI.Interfaceid
inner join componentInformation CI on A.comp=CI.Interfaceid
inner join employeeinformation EI on A.opr=EI.Interfaceid
inner join componentoperationpricing COP on A.Opn= COP.Interfaceid and CI.Componentid=COP.ComponentID
and cop.machineid=MI.Machineid
where MI.Machineid=@Machine and A.sttime>=@sttime and A.ndtime<=@ndtime group by  
A.mc,MI.Machineid,A.comp,CI.componentid,A.opn,COP.operationno,A.opr,EI.Employeeid

Declare @logicaldaystart datetime
Declare @shiftid tinyint


set @logicaldaystart=(Select dbo.f_GetLogicalDayStart (dateadd(s,1,@sttime)))
set @shiftid=(Select shiftid from shiftdetails where running=1 and Shiftname=@shift)

PRINT (@logicaldaystart)

update #temp set Rejection=AR.Rej from ( (Select mc,comp,Opn,opr,isnull(sum(Rejection_QTY),0)  as Rej from AutodataRejections where AutodataRejections.RejShift=@shiftid and AutodataRejections.Rejdate=@logicaldaystart
group by mc,comp,Opn,opr) AR  inner join #temp as A on AR.mc=A.mc and AR.comp=A.comp and AR.Opn=A.Opn and AR.opr=A.opr
)

Select mc,machine,comp,component,opn,operation,opr,operator,partcount,rejection,(Partcount-Rejection) as AcceptedQty from #temp


End
