/****** Object:  Procedure [dbo].[s_GetmachineRunningStatus]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************************************
--ER0319 - SnehaK - 29/dec/2011 :: Created for cummins to get Machine running status.
--s_GetmachineRunningStatus '',''
s_GetmachineRunningStatus '','LT 25-1','2012-01-06 15:13:17.080'
Select * from machineinformation where machineid='mlc puma 220'
Select * from autodata where mc=1 order by sttime desc

****************************************************************************************/

CREATE  PROCEDURE [dbo].[s_GetmachineRunningStatus]
	@PlantID as nvarchar(50)='',
	@machineID as nvarchar(50)='',
	@Date as Datetime
	
AS
BEGIN
Declare @strMachine as nvarchar(255)
Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @curdate as datetime

SELECT @strMachine = ''
SELECT @strPlantID = ''
SELECT @strSql= ''
set @curdate=@Date

CREATE TABLE #MachineRunningStatus
	(
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		Componentid NvarChar(50),
		compinterface nvarchar(50),
		OperationNo NvarChar(50),
		opninterface nvarchar(50),
		sttime Datetime,
		ndtime Datetime,
		DataType smallint,
		ColorCode varchar(10)
	)



if isnull(@PlantID,'')<> ''
Begin	
	SET @strPlantID = 'and Pm.PlantID = N''' + @PlantID + ''''	
End

if isnull(@machineID,'')<> ''
Begin	
	SET @strMachine = 'and mi.MachineID = N''' + @machineid + ''''	
End

SET @strSql = @strSql +'Insert into #machineRunningStatus
						select mi.MachineID,mi.Interfaceid,C.ComponentID,C.interfaceID,O.OperationNo,O.interfaceid,sttime,ndtime,datatype,null from rawdata 
						inner join (select mc,max(slno) as slno from rawdata group by mc) t1 
						on t1.mc=rawdata.mc and t1.slno=rawdata.slno 
						right outer join Machineinformation MI on mi.Interfaceid = rawdata.mc 
						inner join PlantMachine pm on  pm.machineid=mi.machineid 
						left outer Join ComponentInformation C ON rawdata.Comp=C.InterfaceID
						left outer Join ComponentOperationPricing O ON rawdata.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND mi.MachineID=O.MachineID
						where 1=1' 
SET @strSql =  @strSql + @strMachine+ @strPlantID  +'order by rawdata.mc'
print @strsql
EXEC(@strSql)

--update #machineRunningStatus set ColorCode = 'Green' where datatype in (11,41)
update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2)


update #machineRunningStatus set ColorCode = t1.ColorCode from (
Select mrs.MachineID,
Case when (
case when datatype = 40 then datediff(second,sttime,@curdate)-isnull(cop.loadunload,120)
when datatype = 1 then datediff(second,ndtime,@curdate)-isnull(cop.loadunload,120)
end) > 0 
then 'Red'
when (
case when datatype = 40 then datediff(second,sttime,@curdate)-isnull(cop.loadunload,120)
when datatype = 1 then datediff(second,ndtime,@curdate)-isnull(cop.loadunload,120)
end) <= 0 
then 'Green'
--else 'Green'
end as ColorCode
from #machineRunningStatus mrs Left Outer join componentoperationpricing cop on mrs.MachineID = cop.MachineID 
and mrs.componentid=COP.componentid and mrs.operationno=cop.operationno
where  datatype in (40,1)
)as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID


update #machineRunningStatus set colorcode='RED' where isnull(colorcode,'')=''


select MachineId,colorcode from #machineRunningStatus

END
