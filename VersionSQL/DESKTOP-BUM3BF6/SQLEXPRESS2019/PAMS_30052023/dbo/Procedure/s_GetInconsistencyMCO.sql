/****** Object:  Procedure [dbo].[s_GetInconsistencyMCO]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************************
NRO085 :: 7-jun-2013 :: Geetanjali - To populate inconsistent Machine,component and Operation which are not in 
                        master table but present in autodata.
ER0374 - SwathiKS - 31/Jan/2014 :: Performance Optimization.
ER0402 - SwathiKS - 10/Jul/2014 :: To populate inconsistent operator which are not in 
                        master table but present in autodata. 
DR0366 - SwathiKS - 01/Aug/2015 :: In Ace - 
a> Valid MCO combination are displayed as "Invalid MCO in COP"
To handle above case, Considered "Interfaceid" instead of "OperationNo" from COP Table while validating records for "Invalid MCO in COP".
b> Some Inconsistent M-C-O's are not listing as compared with Modifydata.

s_GetInconsistencyMCO '2015-07-01 06:00:00 AM','2015-08-13 06:00:00 AM','','STARRAG-1'  
****************************************************************************************************************************/

CREATE PROCEDURE [dbo].[s_GetInconsistencyMCO]
@Fromdate datetime,
@Todate datetime,
@plantid nvarchar(50)='',
@Machineid nvarchar(100)=''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


declare @sqlstr as nvarchar(4000)
Declare @Machines as nvarchar(500)
Declare @plantname as nvarchar(500)

Create table #MCO
(
Date datetime,
Machineid int,
Machine nvarchar(100),
Compid nvarchar(20),
component nvarchar(100) null,
Operationno int,
Remarks nvarchar(150),
oprid nvarchar(50) --ER0402
)

Declare @strMachine as nvarchar(250)
Declare @strPlantID as nvarchar(150)  
declare @CurDate as datetime
set @strMachine=''
set @strPlantID=''
if isnull(@Machineid,'')<> ''
begin	
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @Machineid + ''''	
	
end
if isnull(@plantid,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @plantid + ''''	
End

/******************************** ER0374 From here ********************************

select @sqlstr=''
select @sqlstr='insert into #MCO(Machineid,Machine,Compid ,Operationno ,Date,Remarks)   
Select distinct mc,''Machinename Invalid'',comp, opn,sttime,''Invalid Machine'' from autodata  where sttime>='''
set @sqlstr = @sqlstr + convert(nvarchar(20),@fromdate,120) +''' and ndtime<='''
set @sqlstr = @sqlstr + convert(nvarchar(20),@ToDate,120) + ''' and  mc not in (Select machineinformation.interfaceid from machineinformation )' 
print (@sqlstr)
exec (@sqlstr)

Select @sqlstr=''
select @sqlstr='Update #MCO set component=t.componentid from (Select componentid,interfaceid  from dbo.componentinformation)as t inner join  #MCO on t.interfaceid=#MCO.compid'
exec (@sqlstr)


select @sqlstr=''
select @sqlstr='insert into #MCO(Machineid,Machine,Compid ,Operationno ,Date,Remarks)  Select distinct mc,machineinformation.machineid,comp,opn,stdate,''Invalid Component'' from autodata inner join machineinformation   on machineinformation.interfaceid=autodata.mc 
inner join plantmachine on plantmachine.MachineID=machineinformation.machineid
where comp not in (Select interfaceid  from dbo.componentinformation)  and   sttime>='''
set @sqlstr = @sqlstr + convert(nvarchar(20),@fromdate,120) +''' and ndtime<='''
set @sqlstr = @sqlstr + convert(nvarchar(20),@ToDate,120) + ''' '
set @sqlstr = @sqlstr + @strPlantID +  @strMachine +' group by  mc,opn,comp,machineinformation.machineid,autodata.stdate'
print (@sqlstr)
exec (@sqlstr)


select @sqlstr=''
select @sqlstr='insert into #MCO(Machineid,Machine,component,Compid ,Operationno ,Date,Remarks) Select distinct mc,machineinformation.machineid,componentinformation.componentid,comp,opn,stdate,''Invalid MCO in COP''  from autodata inner join machineinformation   on machineinformation.interfaceid=autodata.mc 
inner join plantmachine on plantmachine.MachineID=machineinformation.machineid
inner join  componentinformation on componentinformation.interfaceid=comp '
select @sqlstr = @sqlstr + ' where machineinformation.machineid+componentinformation.componentid+opn not in (Select Machineid+Componentid+convert(nvarchar(50),Operationno)  from dbo.componentoperationpricing) and  sttime>='''
select @sqlstr = @sqlstr + convert(nvarchar(20),@fromdate,120) +''' and ndtime<=''' 
select @sqlstr = @sqlstr + convert(nvarchar(20),@ToDate,120) + ''' and  convert(nvarchar(20),stdate,120)+machineinformation.machineid+comp not in (select convert(nvarchar(20),date,120)+Machine+Compid from #MCO)' 
set @sqlstr = @sqlstr + @strPlantID +  @strMachine +' group by  mc,opn,comp,machineinformation.machineid,componentinformation.componentid,autodata.stdate'
print (@sqlstr)
exec (@sqlstr)
 *********************************** ER0374 Till Here *********************************/

/******************************** ER0374 From here ********************************/

select @sqlstr=''
select @sqlstr='insert into #MCO(Machineid,Machine,Compid ,Operationno ,Date,Remarks,oprid)    --ER0402 Added Oprid
Select distinct mc,''Machinename Invalid'',comp, opn,sttime,''Invalid Machine'',opr from autodata  where sttime>=''' + convert(nvarchar(20),@fromdate,120) +''' and  --ER0402 Added Opr
ndtime<=''' + convert(nvarchar(20),@ToDate,120) + ''' and '
set @sqlstr = @sqlstr + ' mc not in (Select distinct machineinformation.interfaceid from machineinformation )' 
print (@sqlstr)
exec (@sqlstr)

--ER0402 From Here
select @sqlstr=''
select @sqlstr='insert into #MCO(Machineid,Machine,Compid ,Operationno ,Date,Remarks,oprid)  
Select distinct mc,Machineid,comp, opn,sttime,''Invalid OperatorID'',opr from autodata 
inner join machineinformation on machineinformation.interfaceid=autodata.mc  
where sttime>=''' + convert(nvarchar(20),@fromdate,120) +''' and  
ndtime<=''' + convert(nvarchar(20),@ToDate,120) + ''' and '
set @sqlstr = @sqlstr + ' opr not in (Select distinct interfaceid from employeeinformation )' 
print (@sqlstr)
exec (@sqlstr)
--ER0402 Till Here


Select @sqlstr=''
select @sqlstr='Update #MCO set component=t.componentid from (Select distinct componentid,interfaceid  from dbo.componentinformation)as t inner join  #MCO on t.interfaceid=#MCO.compid'
exec (@sqlstr)


select @sqlstr=''
select @sqlstr='insert into #MCO(Machineid,Machine,Compid ,Operationno ,Date,Remarks,oprid)  --ER0402
Select distinct mc,machineinformation.machineid,comp,opn,stdate,''Invalid Component'',opr from autodata  --ER0402
inner join machineinformation on machineinformation.interfaceid=autodata.mc 
inner join plantmachine on plantmachine.MachineID=machineinformation.machineid
where comp not in (Select distinct interfaceid  from dbo.componentinformation)  and   
sttime>=''' + convert(nvarchar(20),@fromdate,120) +''' and ndtime<=''' + convert(nvarchar(20),@ToDate,120) + ''' '
set @sqlstr = @sqlstr + @strPlantID +  @strMachine 
print (@sqlstr)
exec (@sqlstr)


/* DR0366 Commented From here
select @sqlstr=''
select @sqlstr='insert into #MCO(Machineid,Machine,component,Compid ,Operationno ,Date,Remarks,oprid)' --ER0402
select @sqlstr= @sqlstr + ' Select distinct T.mc,machineinformation.machineid,C.componentid,T.comp,T.opn,T.stdate,''Invalid MCO in COP'',T.opr  from --ER0402
(select distinct B.mc,B.comp,B.opn,B.stdate,B.opr from autodata B --ER0402
where (B.sttime>= ''' + convert(nvarchar(20),@fromdate,120) +''' and B.ndtime<= ''' + convert(nvarchar(20),@ToDate,120) + ''')) T
inner join machineinformation on machineinformation.interfaceid=T.mc 
inner join componentinformation C on C.interfaceid=T.comp 
inner join plantmachine on plantmachine.MachineID=machineinformation.machineid' 
--where machineinformation.machineid+C.componentid+T.opn not in (Select distinct Machineid+Componentid+convert(nvarchar(50),Operationno) from dbo.componentoperationpricing)--DR0366
select @sqlstr= @sqlstr + ' where machineinformation.machineid+C.componentid+T.opn not in (Select distinct Machineid+Componentid+convert(nvarchar(50),interfaceid) from dbo.componentoperationpricing)--DR0366
and convert(nvarchar(20),T.stdate,120)+machineinformation.machineid+T.comp not in (select convert(nvarchar(20),date,120)+Machine+Compid from #MCO) ' 
set @sqlstr = @sqlstr + @strPlantID +  @strMachine
print (@sqlstr)
exec (@sqlstr)
DR0366 Commented From here */

--DR0366 Added From here
select @sqlstr=''
select @sqlstr='insert into #MCO(Machineid,Machine,component,Compid ,Operationno ,Date,Remarks,oprid)' --ER0402
select @sqlstr= @sqlstr + ' Select distinct T.mc,machineinformation.machineid,C.componentid,T.comp,T.opn,T.stdate,''Invalid MCO in COP'',T.opr  from --ER0402
(select distinct B.mc,B.comp,B.opn,B.stdate,B.opr from autodata B --ER0402
where (B.sttime>= ''' + convert(nvarchar(20),@fromdate,120) +''' and B.ndtime<= ''' + convert(nvarchar(20),@ToDate,120) + ''')
and (mc+'' ''+comp+'' ''+ opn not in 
			(select m.interfaceid+'' ''+c.interfaceid+'' ''+o.interfaceid from componentinformation C
			inner join  componentoperationpricing O on O.componentid=C.componentid
			inner join machineinformation m on m.machineid=o.machineid 
			where m.interfaceid+'' ''+c.interfaceid+'' ''+o.interfaceid is not null)  
	)
) T left outer join machineinformation on machineinformation.interfaceid=T.mc 
left outer join plantmachine on plantmachine.MachineID=machineinformation.machineid
left outer join componentinformation C on C.interfaceid=T.comp ' 
select @sqlstr= @sqlstr + ' where convert(nvarchar(20),T.stdate,120)+machineinformation.machineid+T.comp not in (select convert(nvarchar(20),date,120)+Machine+Compid from #MCO) ' 
set @sqlstr = @sqlstr + @strPlantID +  @strMachine
print (@sqlstr)
exec (@sqlstr)
----DR0366 Added Till here

 /*********************************** ER0374 Till Here *********************************/



--select Machineid, Machine, Compid, component, Operationno, Remarks from #MCO  order by Date --ER0374
select distinct Machineid, Machine, Compid, component, Operationno, oprid,Remarks from #MCO   --ER0374 --ER0402

End
