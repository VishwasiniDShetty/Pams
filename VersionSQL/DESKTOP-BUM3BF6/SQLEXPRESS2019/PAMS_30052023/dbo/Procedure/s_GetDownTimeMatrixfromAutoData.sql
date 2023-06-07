/****** Object:  Procedure [dbo].[s_GetDownTimeMatrixfromAutoData]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************/
  
  
/****** Object:  StoredProcedure [dbo].[s_GetDownTimeMatrixfromAutoData]    Script Date: 10/14/2010 12:39:49 ******/  
  
/***************************************************************************  
Procedure Created By SangeetaKallur 16/06/05  
Procedure Altered by SSK ON 09-Oct-2006 to include Plant Level Concept  
Altered by Mrudula to inclue or exclude downs.  
Procedure Altered By SSK on 06-Dec-2006 :  
 To Remove Constraint Name and adding it by Primary Key  
NR0048 - KarthikG - 16-Jun-2008 - In SmartManager/Breakdown report give one more report type "MachineDownTime Matrix - 2" in excel sheet to show the downtimes at machine and category level.  
Note:Component and operation not qualified.So,ER0181 not done.  
mod 1 :- ER0182 By Kusuma M.H on 16-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.  
Note:ER0181 not done because CO qualification not found.  
ER0190 - KarthikG - 17-Aug-2009 - Introduce one more report type ""Down and Production PIE Chart "" in Smartmanager/Analysis Report Standard/Down time Report.  
In the report display the total distribution of production and down time.  
Down time distribution should be by category."  
ER0202 - KarthikG - 24-Oct-2009 - "Smartmanager->StandartReport->Downtime->ProdAndDownPieChart Only the setting time exceed the standard (from co table) should be accounted for setting loss.  
The standard setting time should be added to production time."  
ER0210 By Karthikg on 19/Feb/2010 :: Introduce PDT on 5150. Handle PDT at Machine Level.  
mod 2:- For DR0231 By Mrudula M. Rao on 11-Mar-2009.Smartmanager->StandartReport->Downtime->ProdAndDownPieChart  
 Setting Loss is coming in -ve if you exclude setting from the report.  
 Exclude logic has not been introduced while calculating setting loss and production time  by comparing with the threshold.  
ER0225 - SwatiK S - 31/Mar/2010 :: Apply standard setup loss threshold after batching by MCO, instead of applying threshold at cycle level.  
DR0236 - KarthikG - 19/Jun/2010 :: Use proper conditions in case statements to remove icd's from type 4 production records.  
DR0240 - SwathiKS - 13/Jun/2010 :: To Match Sum of Production and downtime to Total time  
DR0261 -Karthick R 13-Oct-2010.Data duplication has happened due to single Co present in two  machines.  
ER0350 - SwathiKS - 10/Apr/2013 :: Introduced New @Matrixtype "DLoss_By_Catagory" To show DownLosses Categorywise for Shriram Pistons.  
To avoid that Component information table has been removed from the join condition  
ER0415 - SwathiKS - 12/Aug/2015 :: Iphone - Added New Parameter to list Machinewise Top 5 DownID's order by Downtime desc.  
ER0453 - Gopinath - 20/Oct/2017 :: To Handle Multiple Machines as Input using Function [SplitStrings].  
DR0379 - SwathiKS - 29/Nov/2017 :: To Sort DownCatagory's when @MatrixType=DTime_By_Catagory_And_PTime for SPF.
Anjana C V - 31/07/2017 :: To handle 16 downCodes for SONA
DR0389 - SwathiKS - 03/mar/2021 :: DowntimeMatrixReport - When we select Multiple Downcodes when Down_PDT is Enabled Proc was giving error.
******************************************************************************/ 
--[s_GetDownTimeMatrixfromAutoData] '2019-02-15 06:00:00','2019-02-25 06:00:00','','','','','','','','','DFreq','','0','' 
--[s_GetDownTimeMatrixfromAutoData] '2019-01-01 06:00:00','2019-01-25 06:00:00','','','','','','','','','DTime','','0',''   
--[s_GetDownTimeMatrixfromAutoData] '2019-01-01 06:00:00','2019-01-25 06:00:00','','','','','','','','','DLoss_By_Catagory','GNA Axle II','0',''  
--[s_GetDownTimeMatrixfromAutoData] '2017-01-24 06:00:00','2017-01-28 06:00:00','','','','','','','','','DLoss_By_Catagory','','0'  
--[s_GetDownTimeMatrixfromAutoData] '2017-01-01 06:00:00','2017-01-29 06:00:00','MCH-FIRE-03-26,LT 2 LM 500 MSY','','','','','','','','DTime_By_Catagory','','0'  
--[s_GetDownTimeMatrixfromAutoData] '2019-07-01 06:00:00','2019-07-3 06:00:00','','','','','','','','','DTime_By_Catagory_And_PTime','','0'   
CREATE PROCEDURE [dbo].[s_GetDownTimeMatrixfromAutoData]  -- filtering machineids in the beginning  
 @StartTime DateTime,  
 @EndTime DateTime,  
 ---mod 1  
 --Replaced nvarchar in place of varchar to support unicode characters.  
-- @MachineID  varchar(50) = '',  
-- @DownID  varchar(8000) = '',  
-- @OperatorID  varchar(50) = '',  
-- @ComponentID  varchar(50) = '',  
-- @MachineIDLabel varchar(50) ='ALL',  
-- @OperatorIDLabel varchar(50) = 'ALL',  
-- @DownIDLabel varchar(50) = 'ALL',  
-- @ComponentIDLabel varchar(50) = 'ALL',  
-- @MatrixType varchar(20) = '',  
-- @PlantID varchar(50) = '',  
 @MachineID  nvarchar(MAX) = '',  
 @DownID  nvarchar(4000) = '',  
 @OperatorID  nvarchar(50) = '',  
 @ComponentID  nvarchar(50) = '',  
 @MachineIDLabel nvarchar(50) ='ALL',  
 @OperatorIDLabel nvarchar(50) = 'ALL',  
 @DownIDLabel nvarchar(50) = 'ALL',  
 @ComponentIDLabel nvarchar(50) = 'ALL',  
 @MatrixType nvarchar(50) = '',  
 @PlantID nvarchar(50) = '',  
 ---mod 1  
 @Excludedown int,
 @Groupid as nvarchar(MAX)=''   
AS  
BEGIN  
---mod 1  
--Replaced nvarchar in place of varchar to support unicode characters.  
--declare @strsql nvarchar(4000)  
--declare @strdown varchar(8000)  
--declare @strMachine nvarchar(255)  
--declare @strcomponent varchar(255)  
--declare @strOperator varchar(255)  
--Declare @StrPlant varchar(255)  
declare @strsql nvarchar(MAX)  
declare @strdown nvarchar(4000)  
declare @strMachine nvarchar(MAX)  
declare @strcomponent nvarchar(255)  
declare @strOperator nvarchar(255)  
Declare @StrPlant nvarchar(255)  
DECLARE @StrPLD_DownId NVARCHAR(2000)--ER0210  
--DECLARE @joined NVARCHAR(4000)--ER0210  
Declare @StrGroupid as nvarchar(MAX) 
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)


DECLARE @joined1 NVARCHAR(4000)


Select @StrGroupid=''  

--ER0453  
--select @joined = coalesce(@joined + ',''', '''')+item+'''' from [SplitStrings](@machineid, ',')     
--if @joined = ''''''  
-- set @joined = ''  
--ER0453  

if isnull(@MachineID,'')<>''
begin
	---mod 1
	--select @strmachine=' AND (machineinformation.machineid ='''+@MachineID+''')'
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined
	---mod 1
end

 
   
select @joined1 =  (case when (coalesce( +@joined1 + ',''', '''')) = ''''  then 'N''' else @joined1+',N''' end) +item+'''' from [SplitStrings](@DownID, ',')     

if @joined1 = 'N'''''  
set @joined1 = '' 

select @DownID = @joined1
 
---mod 1  
-- Temporary Table  
Create TABLE #DownTimeData  
(  
 MachineID nvarchar(50) NOT NULL,  
 --McInterfaceid nvarchar(4),  
 McInterfaceid nvarchar(50),  
 machineDescription NVarChar(150), 
 DownID nvarchar(50) NOT NULL,  
 DownTime float,  
 DownFreq int  
 --CONSTRAINT downtimedata_key PRIMARY KEY (MachineId, DownID)  
)  
ALTER TABLE #DownTimeData  
 ADD PRIMARY KEY CLUSTERED  
 (  
  MachineId, DownID  
 )ON [PRIMARY]  
CREATE TABLE #ProdDownTimeData--ER0190  
(  
 MachineID nvarchar(50),  
 --McInterfaceid nvarchar(4),  
 McInterfaceid nvarchar(50),
 machineDescription NVarChar(150),   
 DownCatagory nvarchar(50),  
 DownTime float,  
)--ER0190  
CREATE TABLE #FinalData  
(  
 MachineID nvarchar(50) NOT NULL,  
 machineDescription NVarChar(150), 
 DownID nvarchar(50) NOT NULL,  
 DownTime float,  
 downfreq int,  
 TotalMachine float,  
 TotalDown float,  
 TotalMachineFreq float DEFAULT(0),  
 TotalDownFreq float DEFAULT(0)  
 --CONSTRAINT finaldata_key PRIMARY KEY (MachineID, DownID)  
)  
ALTER TABLE #FinalData  
 ADD PRIMARY KEY CLUSTERED  
 (  
  MachineId, DownID  
 )ON [PRIMARY]  

  
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
 id  bigint not null  
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime,ndtime,msttime ASC  
)ON [PRIMARY]  


select @strsql = ''  
select @StrPlant=''  
IF ISNULL(@PlantID,'')<>''  
BEGIN  
---mod 1  
--SELECT @StrPlant=' And PlantMachine.PlantID='''+ @PlantID +''''  
SELECT @StrPlant=' And PlantMachine.PlantID=N'''+ @PlantID +''''  
---mod 1  
END 

If isnull(@Groupid,'') <> ''  
Begin 
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined
	Select @StrGroupid = ' And ( PlantMachineGroups.GroupID IN(' + @GroupID + '))'  
End 
 

Select @strsql=''  
select @strsql ='insert into #T_autodata  
				SELECT mc, comp, opn, opr, dcode,sttime, ndtime, datatype, cycletime, loadunload, msttime, 
				PartsCount,id from autodata where (( sttime >='''+ convert(nvarchar(25),@StartTime,120)+''' 
				and ndtime <= '''+ convert(nvarchar(25),@EndTime,120)+''' )
				OR  ( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' )  
				OR ( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartTime,120)+'''  
				and ndtime<='''+convert(nvarchar(25),@EndTime,120)+''' ) 
				OR ( sttime >='''+convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' 
				and sttime<'''+convert(nvarchar(25),@EndTime,120)+''' ) )'  
print @strsql  
exec (@strsql) 

--ER0210  
SELECT @StrPLD_DownId=''  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'  
BEGIN  
 SELECT @StrPLD_DownId=' AND Downcodeinformation.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'  
END  
   
SELECT Machine,Interfaceid as MachineInterface,  
 Description ,
 CASE When StartTime<@StartTime Then @StartTime Else StartTime End As StartTime,  
 CASE When EndTime>@EndTime Then @EndTime Else EndTime End As EndTime  
 INTO #PlannedDownTimes  
FROM PlannedDownTimes inner join machineinformation on PlannedDownTimes.Machine=machineinformation.MachineID  
WHERE PDTstatus = 1 And ((StartTime >= @StartTime  AND EndTime <=@EndTime)  
OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )  
OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )  
OR ( StartTime < @StartTime  AND EndTime > @EndTime))  
--ER0210  
  
--Select * from #PlannedDownTimes  
Select @strsql = 'INSERT INTO #DownTimeData (MachineID,McInterfaceid,machineDescription, DownID, DownTime,DownFreq)  
    SELECT Machineinformation.MachineID AS MachineID,Machineinformation.interfaceid,Machineinformation.Description,downcodeinformation.downid AS DownID, 0,0 
	FROM Machineinformation CROSS JOIN downcodeinformation 
	INNER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID 
	LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID '  
if isnull(@downid, '') <> '' and isnull(@machineid,'') <> '' and @Excludedown=0  
 begin  
 select @strsql =  @strsql + ' where  downcodeinformation.downid in (' + @downid + ')'  
 ---mod 1  
-- select @strsql =  @strsql + ' and ( machineinformation.machineid = ''' + @machineid + ''')'  
 select @strsql =  @strsql + ' and ( machineinformation.machineid in (' + @MachineID + '))'  --ER0453  
 ---mod 1  
 end  
--change  
if isnull(@downid, '') <> '' and isnull(@machineid,'') <> '' and @Excludedown=1  
 begin  
 select @strsql =  @strsql + ' where  downcodeinformation.downid not in (' + @downid + ')'  
 ---mod 1  
-- select @strsql =  @strsql + ' and ( machineinformation.machineid = ''' + @machineid + ''')'  
 select @strsql =  @strsql + ' and ( machineinformation.machineid in (' + @MachineID + '))' --ER0453  
-- print @strsql  
 ---mod 1  
 end  
--change  
if isnull(@downid, '') <> '' and isnull(@machineid,'') = '' and @Excludedown=0  
 begin  
 select @strsql =  @strsql + ' where  downcodeinformation.downid in( ' + @downid + ' )'  
 end  
--change  
if isnull(@downid, '') <> '' and isnull(@machineid,'') = '' and @Excludedown=1  
 begin  
 select @strsql =  @strsql + ' where  downcodeinformation.downid not in( ' + @downid + ')'   
 end  
if isnull(@downid, '') = '' and isnull(@machineid,'') <> ''  
 begin  
 ---mod 1  
-- select @strsql =  @strsql + ' where ( machineinformation.machineid = ''' + @machineid + ''')'  
 select @strsql =  @strsql + ' where ( machineinformation.machineid in (' + @MachineID + '))' --ER0453  
 ---mod 1  
 end  
--============To handle 16 downs ==========--
IF (Select ValueInInt from CockpitDefaults WHERE Parameter = 'ExcludeTPMTrakDown') = 1
BEGIN
   IF isnull(@downid, '') = '' and isnull(@machineid,'') = ''
    BEGIN
      select @strsql = @strsql + ' WHERE downcodeinformation.DownID not in (select DownId from PredefinedDownCodeInfo ) '
	END
    IF isnull(@downid, '') <> '' and isnull(@machineid,'') <> '' 
	BEGIN
	 select @strsql = @strsql + ' AND downcodeinformation.DownID not in (select DownId from PredefinedDownCodeInfo ) '
	END
END 

select @strsql = @strsql + @StrPlant +  @StrGroupid + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID '  
print @strsql  
exec (@strsql)  
--print @strsql  
select @strdown = ''  
select @strmachine = ''  
select @stroperator = ''  
select @strcomponent = ''  
if isnull(@machineid, '') <> ''  
 begin  
 ---mod 1  
-- select @strmachine =  ' and ( Machineinformation.machineid = ''' + @machineid + ''')'  
 select @strsql =  @strsql + ' and ( machineinformation.machineid in (' + @MachineID + '))' --ER0453  
 ---mod 1  
 end  
if isnull(@componentid, '') <> ''  
 begin  
 ---mod 1  
-- select @strcomponent =  ' and ( componentinformation.componentid = ''' + @componentid + ''')'  
 select @strcomponent =  ' and ( componentinformation.componentid = N''' + @componentid + ''')'  
 ---mod 1  
 end  
if isnull(@operatorid,'')  <> ''  
 BEGIN  
 ---mod 1  
-- select @stroperator = ' and ( employeeinformation.employeeid = ''' + @OperatorID +''')'  
 select @stroperator = ' and ( employeeinformation.employeeid = N''' + @OperatorID +''')'  
 ---mod 1  
 END  
if isnull(@downid,'')  <> '' and @Excludedown=0  
 BEGIN  
 select @strdown = ' and ( downcodeinformation.downid in (' + @Downid +'))'  
 END  
if isnull(@downid,'')  <> '' and @Excludedown=1  
 BEGIN  
 select @strdown = ' and ( downcodeinformation.downid not in (' + @Downid +'))'  
 END  
--Get Down Time Details  
--TYPE1 i  
select @strsql = ''  
select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) , '  
select @strsql = @strsql + ' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '  
select @strsql = @strsql + ' FROM'  
select @strsql = @strsql + ' (SELECT mc,count(mc)as dwnfrq,sum(loadunload)as down,downcodeinformation.downid as downid'  
select @strsql = @strsql + ' from '  
select @strsql = @strsql + '  #T_autodata autodata INNER JOIN'  
--select @strsql = @strsql + ' machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID INNER JOIN' --DR0240 - SwathiKS - 13/Jun/2010  
select @strsql = @strsql + ' machineinformation ON autodata.mc = machineinformation.InterfaceID 
							Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
	                        LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID 
							inner JOIN' --DR0240 - SwathiKS - 13/Jun/2010  
--select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'  
select @strsql = @strsql + ' employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN'  
select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'  
select @strsql = @strsql + ' where  autodata.sttime>='''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime,120)+''' and datatype=2 '  
select @strsql = @strsql + @StrPlant + @strmachine + @StrGroupid   + @strcomponent + @strdown --+ @stroperator  
select @strsql = @strsql + ' group by autodata.mc,downcodeinformation.downid )'  
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'  
exec (@strsql)  
--TYPE2  
select @strsql = ''  
select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0),'  
select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'  
select @strsql = @strsql+' FROM'  
select @strsql = @strsql+' (SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, '''+convert(varchar(20),@StartTime)+''', ndtime))as down,downcodeinformation.downid as downid'  
select @strsql = @strsql+' from'  
select @strsql=@strsql+'  #T_autodata autodata INNER JOIN'  
select @strsql = @strsql + ' machineinformation ON autodata.mc = machineinformation.InterfaceID 
							Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
							LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID '  
--select @strsql = @strsql + 'INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN' --DR0240 - SwathiKS - 13/Jun/2010  
--select @strsql = @strsql + ' LEFT OUTER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'DR0261 -Karthick R 13-Oct-2010  
select @strsql = @strsql + ' left outer join employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN '  
select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'  
select @strsql=@strsql+' where  autodata.sttime<'''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime,120)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime,120)+''' and datatype=2'  
select @strsql = @strsql  + @StrPlant + @strmachine + @StrGroupid   + @strcomponent + @strdown + @stroperator  
select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'  
select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'  
print @strsql  
exec (@strsql)  
--TYPE3  
select @strsql = ''  
select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0),'  
select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'  
select @strsql = @strsql+' FROM'  
select @strsql = @strsql+' (SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, stTime, '''+convert(varchar(20),@Endtime)+'''))as down,downcodeinformation.downid as downid '  
select @strsql = @strsql+' from'  
select @strsql = @strsql+'  #T_autodata autodata INNER JOIN'  
select @strsql = @strsql+ ' machineinformation ON autodata.mc = machineinformation.InterfaceID 
							Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID
							LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID '  
--select @strsql = @strsql+ 'INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN' --DR0240 - SwathiKS - 13/Jun/2010  
--select @strsql = @strsql+ ' LEFT OUTER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'DR0261 -Karthick R 13-Oct-2010  
select @strsql = @strsql+' inner join employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN'  
select @strsql = @strsql+' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'  
select @strsql = @strsql+' where  autodata.sttime>='''+convert(varchar(20),@starttime,120)+'''and autodata.sttime<'''+convert(varchar(20),@endtime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime,120)+''' and datatype=2'  
select @strsql = @strsql  + @StrPlant + @strmachine + @StrGroupid   + @strcomponent + @strdown + @stroperator  
select @strsql= @strsql+' group by autodata.mc,downcodeinformation.downid )'  
select @strsql= @strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'  
print @strsql  
exec (@strsql)  
--TYPE4  
select @strsql = ''  
select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0),'  
select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'  
select @strsql = @strsql+' FROM'  
select @strsql = @strsql+' (SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, '''+convert(varchar(20),@StartTime)+''', '''+convert(varchar(20),@EndTime)+'''))as down,downcodeinformation.downid as downid'  
select @strsql = @strsql+' from'  
select @strsql = @strsql+' #T_autodata autodata INNER JOIN'  
select @strsql = @strsql+' machineinformation ON autodata.mc = machineinformation.InterfaceID 
						   Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
							LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID '  
--select @strsql = @strsql+ 'INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN' --DR0240 - SwathiKS - 13/Jun/2010  
--select @strsql = @strsql+ ' LEFT OUTER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'DR0261 -Karthick R 13-Oct-2010  
select @strsql = @strsql+'inner join  employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN'  
select @strsql = @strsql+' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'  
select @strsql = @strsql+' where  autodata.sttime<'''+convert(varchar(20),@starttime,120)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime,120)+''' and datatype=2'  
select @strsql = @strsql  + @StrPlant+@strmachine + @StrGroupid  + @strcomponent + @strdown + @stroperator  
select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'  
select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'  
print @strsql  
exec (@strsql)  
 
--ER0210  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'  
BEGIN  
---DR0389 
--  Select @strsql=''  
--  Select @strsql= 'UPDATE #DownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)  
--FROM( '  
--    Select @strsql=@strsql+ 'SELECT autodata.MC,DownId, SUM  
--        (CASE  
--     WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload  
--     WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
--     WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
--     WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
--     END ) as PPDT  
--    FROM #T_autodata autodata CROSS jOIN #PlannedDownTimes T  
--    INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
--    INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID  
--    Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
--	LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID 
--    --left outer JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID  
--    INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid  
--    WHERE autodata.DataType=2 And T.Machine = machineinformation.MachineID AND (  
--     (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
--     OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
--     OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
--     OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
--     )AND(  
--     (autodata.sttime >= '''+convert(varchar(20),@starttime,120)+'''  AND autodata.ndtime <='''+convert(varchar(20),@endtime,120)+''')  
--     OR ( autodata.sttime < '''+convert(varchar(20),@starttime,120)+'''  AND autodata.ndtime <= '''+convert(varchar(20),@endtime,120)+''' AND autodata.ndtime > '''+convert(varchar(20),@starttime,120)+''' )  
--     OR ( autodata.sttime >= '''+convert(varchar(20),@starttime,120)+'''   AND autodata.sttime <'''+convert(varchar(20),@endtime,120)+''' AND autodata.ndtime > '''+convert(varchar(20),@endtime,120)+''' )  
--     OR ( autodata.sttime < '''+convert(varchar(20),@starttime,120)+'''  AND autodata.ndtime > '''+convert(varchar(20),@endtime,120)+''') )'  
--  Select @strsql = @strsql  + @StrPlant + @strmachine + @StrGroupid   + @strcomponent + @strdown + @stroperator + @StrPLD_DownId  
--  Select @strsql= @strsql + 'group by autodata.mc,DownId  
--  ) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId  
--  Where #DownTimeData.DownTime>0'  
--  print(@StrPLD_DownId)  
--  print(@strsql)  
--  Exec (@strsql)  

 Select @strsql=''  
  Select @strsql= 'UPDATE #DownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)  
FROM( '  
    Select @strsql=@strsql+ 'SELECT A.MC,DownId, SUM  
        (CASE  
     WHEN (A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime)  THEN A.loadunload  
     WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)  
     WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )  
     WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
     END ) as PPDT  
    FROM #T_autodata A CROSS jOIN #PlannedDownTimes T  
    INNER JOIN DownCodeInformation  ON A.DCode = DownCodeInformation.InterfaceID  
    INNER JOIN machineinformation ON A.mc = machineinformation.InterfaceID  
    Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
	LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID 
    --left outer JOIN componentinformation ON A.comp = componentinformation.InterfaceID  
    INNER JOIN employeeinformation ON A.opr = employeeinformation.interfaceid  
    WHERE A.DataType=2 And T.Machine = machineinformation.MachineID AND (  
     (A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime)  
     OR ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )  
     OR ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime AND A.ndtime > T.EndTime )  
     OR ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime)  
     )AND(  
     (A.sttime >= '''+convert(varchar(20),@starttime,120)+'''  AND A.ndtime <='''+convert(varchar(20),@endtime,120)+''')  
     OR ( A.sttime < '''+convert(varchar(20),@starttime,120)+'''  AND A.ndtime <= '''+convert(varchar(20),@endtime,120)+''' AND A.ndtime > '''+convert(varchar(20),@starttime,120)+''' )  
     OR ( A.sttime >= '''+convert(varchar(20),@starttime,120)+'''   AND A.sttime <'''+convert(varchar(20),@endtime,120)+''' AND A.ndtime > '''+convert(varchar(20),@endtime,120)+''' )  
     OR ( A.sttime < '''+convert(varchar(20),@starttime,120)+'''  AND A.ndtime > '''+convert(varchar(20),@endtime,120)+''') )'  
  Select @strsql = @strsql  + @StrPlant + @strmachine + @StrGroupid   + @strcomponent + @strdown + @stroperator + @StrPLD_DownId  
  Select @strsql= @strsql + 'group by A.mc,DownId  
  ) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId  
  Where #DownTimeData.DownTime>0'  
  print(@StrPLD_DownId)  
  print(@strsql)  
  Exec (@strsql) 
  -----DR0389 
END  
--select MachineID, DownID, DownTime, downfreq,0,0 from #DownTimeData  
--return  
--ER0210  
INSERT INTO #FinalData (MachineID,machineDescription, DownID, DownTime,downfreq, TotalMachine, TotalDown)  
 select MachineID,machineDescription, DownID, DownTime, downfreq,0,0  
 from #DownTimeData  
UPDATE #FinalData  
SET  
TotalMachineFreq = (SELECT SUM(Downfreq) FROM #FinalData as FD WHERE Fd.machineID = #FinalData.machineid),  
TotalDownFreq = (SELECT SUM(Downfreq) FROM #FinalData as FD WHERE Fd.DownID = #FinalData.DownID),  
TotalMachine = (SELECT SUM(DownTime) FROM #FinalData as FD WHERE Fd.machineID = #FinalData.machineid),  
TotalDown = (SELECT SUM(DownTime) FROM #FinalData as FD WHERE Fd.DownID = #FinalData.DownID)  
/*else if @MatrixType = 'DFreq'  
 select A.MachineID,MAx(A.DownID)+ '('+ Convert(Nvarchar(4),A.DownFreq) + ')' as MaxDownReasonFreq  
 FROM #FinalData A INNER JOIN (SELECT B.machineid,MAX(B.DownFreq)as DownFreq FROM #FinalData B group by machineid) as T2  
 ON A.MachineId = T2.MachineId and A.DownFreq = t2.DownFreq  
 group by A.MachineId,A.DownFreq  
*/  
--select output  
if @MatrixType = 'MaxReasonTime'  
Begin 

			 select A.MachineID,machineDescription,SUBSTRING(MAx(A.DownID),1,6)+ '-'+ SUBSTRING(dbo.f_FormatTime(A.DownTime,'hh:mm:ss'),1,5) as MaxDownReasonTime  
			 FROM #FinalData A INNER JOIN (SELECT B.machineid,MAX(B.DownTime)as DownTime FROM #FinalData B group by machineid) as T2  
			 ON A.MachineId = T2.MachineId and A.DownTime = t2.DownTime  
			 Where A.DownTime > 0  
			 group by A.MachineId,machineDescription,A.DownTime 

End  
if @MatrixType = 'DTime'  
Begin 

			 select  MachineID,  
			 machineDescription,
			  #FinalData.DownID as DownCode,  
			  DownDescription as DownID,  
			  DownTime as DownTime,  
			  DownFreq as DownFreq,  
			  TotalMachine as TotalMachine,  
			  TotalDown as TotalDown,  
			  DownTime/3600 as Hours,  
			  @MachineIDLabel as MachineIDLabel,  
			  @OperatorIDLabel  as OperatorIDLabel,  
			  @DownIDLabel  as DownIDLabel ,  
			  @ComponentIDLabel as ComponentIDLabel,  
			  @StartTime as StartTime,  
			  @EndTime as EndTime,  
			  TotalMachineFreq as TotalMachineFreq,  
			  TotalDownFreq as TotalDownFreq,
			  downcodeinformation.[Owner]
			  FROM #FinalData  
			 INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid  
			 inner join (
				 select MachineID  Machine, sum(downtime) as Sumdowntime from #FinalData  
				 group by MachineID having sum(downtime) > 0
			 )as F  on F.Machine = #FinalData.MachineID  
			 inner join (
				 select DownID Down, sum(downtime) as Sumdowntime from #FinalData  
				 group by DownID  having sum(downtime) > 0
			 )as F1  on  F1.Down = #FinalData.DownID
			 --WHERE (TotalDown > 0) and (TotalMachine > 0) and DownTime>0   
			 Order By  TotalDown desc,downcodeinformation.DownID, TotalMachine desc, machineid  

End  
  
---ER0415 Added From here  
if @MatrixType = 'Iphone_DTime'  
Begin  

			 			select T.MachineID,  
						machineDescription,
				   T.DownID  
			from (  
				 select T.Machineid, 
				 machineDescription, 
						T.Downid,  
						T.downtime,  
						row_number() over(partition by T.machineid order by T.downtime desc) as rn  
				 from #FinalData as T where downtime>0  
				 ) as T  
			where T.rn <= 5 
End  
---ER0415 Added Till here  
  
if @MatrixType = 'DFreq'  
Begin  

			 select  MachineID,  
			 machineDescription,
			  #FinalData.DownID as DownCode,  
			  DownDescription as DownID,  
			  --DownTime as DownTime,  
			  DownFreq as DownFreq,  
			  --TotalMachine as TotalMachine,  
			  --TotalDown as TotalDown,  
			  --DownTime/3600 as Hours,  
			  @MachineIDLabel as MachineIDLabel ,  
			  --@OperatorIDLabel  as OperatorIDLabel,  
			  @DownIDLabel  as DownIDLabel,  
			  --@ComponentIDLabel as ComponentIDLabel,  
			  --@StartTime as StartTime,  
			  --@EndTime as EndTime,  
			  TotalMachineFreq as TotalMachineFreq,  
			  TotalDownFreq as TotalDownFreq,
			  downcodeinformation.[Owner]
			 FROM #FinalData  
			 INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid  
			 inner join (
			select MachineID  Machine, sum(downtime) as Sumdowntime from #FinalData  
			group by MachineID having sum(downtime) > 0
			)as F  on F.Machine = #FinalData.MachineID  
			inner join (
			select DownID Down, sum(downtime) as Sumdowntime from #FinalData  
			group by DownID  having sum(downtime) > 0
			)as F1  on  F1.Down = #FinalData.DownID
			 --WHERE (TotalDownFreq > 0) and (TotalMachineFreq > 0) and DownFreq > 0    
			 Order By  TotalDownFreq desc,downcodeinformation.DownID, TotalMachineFreq desc, machineid 
End  
if @MatrixType = 'DTime_By_Catagory'  --NR0048  
Begin  

			select  Isnull(downcodeinformation.Catagory,'Uncategorized') as Catagory,MachineID,machineDescription,sum(DownTime) as DownTime  
			 FROM #FinalData INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid  
			 WHERE (TotalDown > 0) and (TotalMachine > 0) and DownTime > 0   
			 group by downcodeinformation.Catagory,MachineID,machineDescription Order By  downcodeinformation.Catagory,MachineID 
END  
  
--ER0350 Added From Here.  
if @MatrixType = 'DLoss_By_Catagory'    
Begin  

		 select  Isnull(downcodeinformation.Catagory,'Uncategorized') as Catagory,#FinalData.DownID,Round(sum(DownTime)/60,2) as DownTime,
		 sum(DownTime) as DowntimeInSeconds,
		 downcodeinformation.[Owner]
		 FROM #FinalData INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid  
		 WHERE (Downtime > 0)  
		 group by downcodeinformation.Catagory,#FinalData.DownID,downcodeinformation.[Owner] Order By  downcodeinformation.Catagory,#FinalData.DownID 

End  
---ER0350 Added Till Here.  
  
  
--s_GetDownTimeMatrixfromAutoData_prod  
if @MatrixType = 'DTime_By_Catagory_And_PTime'  
--ER0190  
Begin  


 insert into #ProdDownTimeData --(MachineID,McInterfaceID,DownCatagory)  
 select distinct mi.MachineID,InterfaceID,mi.description,'ProdTime',0 from #FinalData inner join Machineinformation mi on #FinalData.Machineid = mi.Machineid  
 WHERE (TotalDown > 0) and (TotalMachine > 0)  


 -- Type 1 -- Here the Column DownTime holds Utilised Time  
 UPDATE #ProdDownTimeData SET DownTime = isnull(DownTime,0) + isNull(t2.cycle,0) from (  
 select mc,sum(cycletime+loadunload) as cycle from #T_autodata autodata  
 where (autodata.msttime>=@StartTime) and (autodata.ndtime<=@EndTime)  
 and (autodata.datatype=1) group by autodata.mc  
 ) as t2 inner join #ProdDownTimeData on t2.mc = #ProdDownTimeData.McInterfaceID  
 -- Type 2 -- Here the Column DownTime holds Utilised Time  
 UPDATE #ProdDownTimeData SET DownTime = isnull(DownTime,0) + isNull(t2.cycle,0) from (  
 select  mc,SUM(DateDiff(second, @StartTime, ndtime)) cycle from #T_autodata autodata  
 where (autodata.msttime<@StartTime) and (autodata.ndtime>@StartTime)  
 and (autodata.ndtime<=@EndTime) and (autodata.datatype=1) group by autodata.mc  
 ) as t2 inner join #ProdDownTimeData on t2.mc = #ProdDownTimeData.McInterfaceID  
 -- Type 3 -- Here the Column DownTime holds Utilised Time  
 UPDATE  #ProdDownTimeData SET DownTime = isnull(DownTime,0) + isNull(t2.cycle,0) from (  
 select  mc,sum(DateDiff(second, mstTime, @Endtime)) cycle from #T_autodata autodata  
 where (autodata.msttime>=@StartTime) and (autodata.msttime<@EndTime)  
 and (autodata.ndtime>@EndTime) and (autodata.datatype=1) group by autodata.mc  
 ) as t2 inner join #ProdDownTimeData on t2.mc = #ProdDownTimeData.McInterfaceID  
 -- Type 4 -- Here the Column DownTime holds Utilised Time  
 UPDATE #ProdDownTimeData SET DownTime = isnull(DownTime,0) + isnull(t2.cycle,0) from (  
 select mc,sum(DateDiff(second, @StartTime, @EndTime)) cycle from #T_autodata autodata  
 where (autodata.msttime<@StartTime) and (autodata.ndtime>@EndTime)  
 and (autodata.datatype=1) group by autodata.mc  
 ) as t2 inner join #ProdDownTimeData on t2.mc = #ProdDownTimeData.McInterfaceID  
 /* Fetching Down Records from Production Cycle  */  
 /* If Down Records of TYPE-2*/  
 UPDATE  #ProdDownTimeData SET DownTime = isnull(DownTime,0) - isNull(t2.Down,0) FROM (  
  Select AutoData.mc ,  
  SUM(CASE  
    When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )  
    When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)  
   END) as Down  
  From #T_autodata autodata INNER Join (  
     Select mc,Sttime,NdTime From #T_autodata autodata Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
     --(sttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime) --DR0240 - SwathiKS - 13/Jun/2010  
     (msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)  
     ) as T1  on AutoData.mc=T1.mc  
  Where AutoData.DataType=2 And ( autodata.Sttime > T1.Sttime )And ( autodata.ndtime <  T1.ndtime )  
  AND ( autodata.ndtime >  @StartTime ) GROUP BY AUTODATA.mc  
 )AS T2 Inner Join #ProdDownTimeData on t2.mc = #ProdDownTimeData.McInterfaceID  
 /* If Down Records of TYPE-3*/  
 UPDATE  #ProdDownTimeData SET DownTime = isnull(DownTime,0) - isNull(t2.Down,0) FROM (  
  Select AutoData.mc,  
  SUM(CASE  
    When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )  
    When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime) END) as Down  
  From #T_autodata autodata INNER Join (  
     Select mc,Sttime,NdTime From #T_autodata autodata Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
     --(sttime >= @StartTime)And (ndtime > @EndTime) --DR0240 - SwathiKS - 13/Jun/2010  
     (sttime >= @StartTime)And (sttime<@endtime)AND(ndtime > @EndTime)  
      ) as T1  
  ON AutoData.mc=T1.mc  
  Where AutoData.DataType=2 And (T1.Sttime < autodata.sttime  )  
  And ( T1.ndtime >  autodata.ndtime) AND (autodata.sttime  <  @EndTime) GROUP BY AUTODATA.mc  
 )AS T2 Inner Join #ProdDownTimeData on t2.mc = #ProdDownTimeData.McInterfaceID  
 /* If Down Records of TYPE-4*/  
--  
/*  
select @StartTime,@EndTime  
Select mc,Sttime,NdTime From AutoData  
     Where AutoData.mc = 3 and DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
     --(sttime < @StartTime)And (ndtime > @EndTime)  
      (msttime < @StartTime)And (ndtime > @EndTime)  
Select * From AutoData INNER Join (  
 Select mc,Sttime,NdTime From AutoData  
 Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
 (msttime < @StartTime)And (ndtime > @EndTime)  
) as T1  
ON AutoData.mc=T1.mc Where AutoData.mc = 3 and AutoData.DataType=2 And (T1.Sttime < autodata.sttime) And ( T1.ndtime >  autodata.ndtime)AND (autodata.ndtime  >  @StartTime)AND (autodata.sttime  <  @EndTime)  
*/  
--  
 UPDATE  #ProdDownTimeData SET DownTime = isnull(DownTime,0) - isNull(t2.Down,0) FROM (  
  Select AutoData.mc,  
--DR0236 - KarthikG - 19/Jun/2010 :: From Here  
--  SUM(CASE  
--   When autodata.sttime < @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )  
--   When autodata.ndtime >= @EndTime AND autodata.sttime>@StartTime Then datediff(s,autodata.sttime, @EndTime )  
--   When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)  
--   When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)  
--   END) as Down  
  SUM(CASE  
   When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)--type 1  
   When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime And autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )--type 2  
   When autodata.sttime>=@StartTime and Autodata.sttime<@EndTime and autodata.ndtime > @EndTime then datediff(s,autodata.sttime, @EndTime )--type3  
   When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime) --type 4  
   END) as Down  
--DR0236 - KarthikG - 19/Jun/2010 :: Till Here  
  From #T_autodata autodata INNER Join (  
     Select mc,Sttime,NdTime From #T_autodata autodata  
     Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
     --(sttime < @StartTime)And (ndtime > @EndTime)  
      (msttime < @StartTime)And (ndtime > @EndTime)  
      ) as T1  
  ON AutoData.mc=T1.mc  
  Where AutoData.DataType=2 And (T1.Sttime < autodata.sttime  )  
  And ( T1.ndtime >  autodata.ndtime)AND (autodata.ndtime  >  @StartTime)AND (autodata.sttime  <  @EndTime) GROUP BY AUTODATA.mc  
 )AS T2 Inner Join #ProdDownTimeData on t2.mc = #ProdDownTimeData.McInterfaceID  
   
 --ER0210  
 If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
 BEGIN  
  UPDATE #ProdDownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0) FROM(  
   SELECT autodata.MC,SUM  
    (CASE  
    WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload)  
    WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
    WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )  
    WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
    END)  as PPDT  
   FROM #T_autodata autodata CROSS jOIN #PlannedDownTimes T  
   WHERE autodata.DataType=1 And T.MachineInterface=AutoData.mc AND  
    (  
    (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
    OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
    OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
    OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )  
   group by autodata.mc  
  ) as TT INNER JOIN #ProdDownTimeData ON TT.mc = #ProdDownTimeData.McInterfaceID  
  --Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
  UPDATE  #ProdDownTimeData set DownTime =isnull(DownTime,0) + isNull(T2.IPDT ,0)  FROM (  
  Select AutoData.mc,  
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  From #T_autodata autodata INNER Join  
   (Select mc,Sttime,NdTime From #T_autodata autodata  
    Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
    (msttime >= @StartTime) AND (ndtime <= @EndTime)) as T1  
  ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T  
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
  And (( autodata.Sttime > T1.Sttime )  
  And ( autodata.ndtime <  T1.ndtime )  
  )  
  AND  
  ((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))  
  or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)  
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )  
  or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )  
  GROUP BY AUTODATA.mc  
  )AS T2  INNER JOIN #ProdDownTimeData ON T2.mc = #ProdDownTimeData.McInterfaceID  
  /* Fetching Down Records from Production Cycle  */  
  /* If production  Records of TYPE-2*/  
  UPDATE  #ProdDownTimeData set DownTime =isnull(DownTime,0) + isNull(T2.IPDT ,0)  FROM (  
   Select AutoData.mc,  
   SUM(  
   CASE    
    When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
    When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
    When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
    when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
   END) as IPDT  
   From #T_autodata autodata INNER Join  
    (Select mc,Sttime,NdTime From #T_autodata autodata  
     Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
     (msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1  
   ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T  
   Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
   And (( autodata.Sttime > T1.Sttime )  
   And ( autodata.ndtime <  T1.ndtime )  
   AND ( autodata.ndtime >  @StartTime ))  
   AND  
   (( T.StartTime >= @StartTime )  
   And ( T.StartTime <  T1.ndtime ) )  
   GROUP BY AUTODATA.mc  
  )AS T2  INNER JOIN #ProdDownTimeData ON T2.mc = #ProdDownTimeData.McInterfaceID  
   
  /* If production Records of TYPE-3*/  
  UPDATE  #ProdDownTimeData set DownTime =isnull(DownTime,0) + isNull(T2.IPDT ,0)  
  FROM  
  (Select AutoData.mc ,  
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  From #T_autodata autodata INNER Join  
   (Select mc,Sttime,NdTime From #T_autodata autodata  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
   (sttime >= @StartTime)And (ndtime > @EndTime) and autodata.sttime <@EndTime) as T1  
  ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T  
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
  And ((T1.Sttime < autodata.sttime  )  
  And ( T1.ndtime >  autodata.ndtime)  
  AND (autodata.msttime  <  @EndTime))  
  AND  
  (( T.EndTime > T1.Sttime )  
  And ( T.EndTime <=@EndTime ) )  
  GROUP BY AUTODATA.mc)AS T2  INNER JOIN #ProdDownTimeData ON T2.mc = #ProdDownTimeData.McInterfaceID  
   
   
  /* If production Records of TYPE-4*/  
  UPDATE  #ProdDownTimeData set DownTime =isnull(DownTime,0) + isNull(T2.IPDT ,0)  
  FROM  
  (Select AutoData.mc ,  
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  From #T_autodata autodata INNER Join  
   (Select mc,Sttime,NdTime From #T_autodata autodata  
    Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
    (msttime < @StartTime)And (ndtime > @EndTime)) as T1  
  ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T  
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
  And ((T1.Sttime < autodata.sttime  )And ( T1.ndtime >  autodata.ndtime) AND (autodata.ndtime  >  @StartTime) AND (autodata.sttime  <  @EndTime))  
  AND (( T.StartTime >=@StartTime) And ( T.EndTime <=@EndTime ) )  
  GROUP BY AUTODATA.mc)AS T2  INNER JOIN #ProdDownTimeData ON T2.mc = #ProdDownTimeData.McInterfaceID  
 END  
 --ER0210  
 insert into #ProdDownTimeData (DownCatagory,MachineID,Mcinterfaceid,machineDescription,DownTime)  
 select  Isnull(downcodeinformation.Catagory,'Uncategorized') as Catagory,#FinalData.MachineID,Machineinformation.interfaceid,Machineinformation.description,sum(DownTime)as DownTime  
 FROM #FinalData INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid  
 inner join machineinformation on machineinformation.machineid=#finaldata.machineid  --ER0225 - SwatiKS - 31/Mar/2010  
 WHERE (TotalDown > 0) and (TotalMachine > 0)  
 group by downcodeinformation.Catagory,#FinalData.MachineID,Machineinformation.interfaceid,Machineinformation.description Order By  downcodeinformation.Catagory,#FinalData.MachineID  
 --Select DownCatagory as Catagory,MachineID,DownTime from #ProdDownTimeData where DownCatagory in ('ProdTime','SETTING')  
 --ER0202 - KarthikG - 24-Oct-2009  
 IF EXISTS (select * from shopdefaults where parameter = 'StdSetupAsProduction' and valueintext = 'yes')  
 begin    
   select autodata.ID,  
   autodata.mc,autodata.comp,autodata.opn,--ER0225 - SwatiKS - 31/Mar/2010  
   machineinformation.MachineID,isnull(componentoperationpricing.Stdsetuptime,0)AS Stdsetuptime , --DR0240 - SwathiKS - 13/Jun/2010  
   sum(case  
   when autodata.sttime>=@starttime and autodata.ndtime<=@endtime then autodata.loadunload  
   when autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime then Datediff(s,@starttime,ndtime)  
   when autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime then  datediff(s,sttime,@endtime)  
   when autodata.sttime<@starttime and autodata.ndtime>@endtime then  datediff(s,@starttime,@endtime)  
   end) as setuptime,0 as Batchid  
   into #setuptime  
   from #T_autodata autodata  
   inner join machineinformation on autodata.mc = machineinformation.interfaceid  
   --inner join componentinformation on autodata.comp = componentinformation.interfaceid --DR0240 - SwathiKS - 13/Jun/2010  
   left outer join componentinformation on autodata.comp = componentinformation.interfaceid  
   --inner join componentoperationpricing on autodata.opn =  componentoperationpricing.interfaceid and componentinformation.componentid = componentoperationpricing.componentid and componentoperationpricing.machineid = machineinformation.machineid --DR0240 - SwathiKS - 13/Jun/2010  
   left outer join componentoperationpricing on autodata.opn =  componentoperationpricing.interfaceid and componentinformation.componentid = componentoperationpricing.componentid and componentoperationpricing.machineid = machineinformation.machineid  
   where datatype=2 and machineinformation.MachineID in (Select distinct MachineID from #ProdDownTimeData)  
   and dcode in (select interfaceid from downcodeinformation inner join #DownTimeData on downcodeinformation.DownID=#DownTimeData.DownID where downcodeinformation.catagory = 'setting')  
   And  
   ((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or  
    (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or  
    (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or  
    (autodata.sttime<@starttime and autodata.ndtime>@endtime))  
   group by autodata.ID,  
   autodata.mc,autodata.comp,autodata.opn,--ER0225 - SwatiKS - 31/Mar/2010  
   machineinformation.MachineID,componentoperationpricing.Stdsetuptime  
   --ER0210  
   If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
   BEGIN  
    update #setuptime set setuptime = isnull(setuptime,0) - isnull(t1.setuptime_pdt,0) from (  
     select autodata.ID,machineinformation.MachineID,  
     sum(datediff(s,CASE WHEN autodata.sttime >= T.StartTime THEN autodata.sttime else T.StartTime End,CASE WHEN autodata.ndtime <= T.EndTime THEN autodata.ndtime else T.EndTime End))  
     as setuptime_pdt  
     from #T_autodata autodata  
     inner join machineinformation on autodata.mc = machineinformation.interfaceid  
     inner join componentinformation on autodata.comp = componentinformation.interfaceid  
     inner join componentoperationpricing on autodata.opn =  componentoperationpricing.interfaceid and componentinformation.componentid = componentoperationpricing.componentid and componentoperationpricing.machineid = machineinformation.machineid  
     CROSS jOIN #PlannedDownTimes T  
     where datatype=2 and T.MachineInterface=AutoData.mc and machineinformation.MachineID in (Select distinct MachineID from #ProdDownTimeData)  
     and dcode in (select interfaceid from downcodeinformation inner join #DownTimeData on downcodeinformation.DownID=#DownTimeData.DownID where downcodeinformation.catagory = 'setting') And  
     ((autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
       OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
       OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
       OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
     )AND  
     ((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or  
      (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or  
      (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or  
      (autodata.sttime<@starttime and autodata.ndtime>@endtime))  
     group by autodata.ID,machineinformation.MachineID  
    ) as t1 inner join #setuptime on t1.Machineid = #setuptime.MachineID  and #setuptime.ID = t1.ID  
   End  
--ER0225 - SwatiKS - 31/Mar/2010 :: Changes From here  
declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50)  
declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@id nvarchar(50)  
declare @batchid int  
declare @setupcursor  cursor  
set @setupcursor=cursor for  
select id,mc,comp,opn from #setuptime order by mc,id  
open @setupcursor  
fetch next from @setupcursor into @id,@mc,@comp,@opn  
set @mc_prev = @mc  
set @comp_prev = @comp  
set @opn_prev = @opn  
set @batchid =1  
while @@fetch_status = 0  
begin  
If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn   
begin     
       update #setuptime set batchid = @batchid where mc=@mc and comp=@comp and opn=@opn and id=@id  
    end  
 else  
     begin   
       set @batchid = @batchid +1  
       update #setuptime set batchid = @batchid where mc=@mc and comp=@comp and opn=@opn and id=@id  
       set @mc_prev=@mc    
       set @comp_prev=@comp  
       set @opn_prev=@opn    
    end   
 fetch next from @setupcursor into @id,@mc,@comp,@opn  
   
end  
close @setupcursor  
deallocate @setupcursor  
----  
----select mc,MachineId,sum(utilizetime) as utilizetime,sum(Downtime) as Downtime from (  
--  select BatchID,mc,MachineId,max(stdsetuptime) as stdsetuptime,sum(setuptime) as setuptime,  
--  case when sum(setuptime)<max(stdsetuptime) then sum(setuptime)else max(stdsetuptime) end as utilizetime,  
--  case when sum(setuptime)>max(stdsetuptime) then sum(setuptime)-max(stdsetuptime) else 0 end as Downtime  
--  from #setuptime where MachineId = 'LT 20-2' group by BatchID,mc,MachineId  
---- ) as t1  group by mc,MachineId  
--return--  
--select * from #ProdDownTimeData  
--Select * from #setuptime  
--select BatchID,mc,MachineId,max(stdsetuptime) as stdsetuptime,sum(setuptime) as setuptime,  
--case when sum(setuptime)<max(stdsetuptime) then sum(setuptime)else max(stdsetuptime) end as utilizetime,  
--case when sum(setuptime)>max(stdsetuptime) then sum(setuptime)-max(stdsetuptime) else 0 end as Downtime  
--from #setuptime group by BatchID,mc,MachineId  
update #prodDownTimeData set downtime=case  
when #ProdDownTimeData.DownCatagory = 'Setting' then isnull(t2.downtime,0)  
when #ProdDownTimeData.DownCatagory = 'ProdTime' then isnull(#ProdDownTimeData.downtime,0) + Isnull(t2.utilizetime,0) end   
from (  
 select mc,MachineId,sum(utilizetime) as utilizetime,sum(Downtime) as Downtime from (  
  select BatchID,mc,MachineId,max(stdsetuptime) as stdsetuptime,sum(setuptime) as setuptime,  
  case when sum(setuptime)<max(stdsetuptime) then sum(setuptime)else max(stdsetuptime) end as utilizetime,  
  case when sum(setuptime)>max(stdsetuptime) then sum(setuptime)-max(stdsetuptime) else 0 end as Downtime  
  from #setuptime group by BatchID,mc,MachineId  
 ) as t1 group by mc,MachineId  
)as t2 inner join #ProdDowntimedata on t2.mc=#ProdDowntimedata.McInterfaceid where #ProdDownTimeData.DownCatagory in ('Setting','ProdTime')  
--ER0225 - SwatiKS - 31/Mar/2010 :: Changes till here  
--select * from #setuptime  
--select * from #ProdDownTimeData  
--Select DownCatagory as Catagory,MachineID,DownTime from #ProdDownTimeData  
--select * from machineinformation where machineid = 'LT 20-2'  
--ER0225 - SwatiKS - 31/Mar/2010 :: Commented From here  
/*  
   update #ProdDownTimeData set downtime = case  
   when #ProdDownTimeData.DownCatagory = 'Setting' then isnull(#ProdDownTimeData.downtime - t1.stdsetuptime,0)  
   when #ProdDownTimeData.DownCatagory = 'ProdTime' then isnull(#ProdDownTimeData.downtime + t1.stdsetuptime,0)  
   else isnull(#ProdDownTimeData.downtime,0) end   
   from (  
     Select MachineID,  
     sum(Case When Stdsetuptime >= setuptime then setuptime else Stdsetuptime end) as stdsetuptime  
     from #setuptime group by MachineID  
   )as t1 inner join #ProdDownTimeData on t1.MachineID = #ProdDownTimeData.machineID  
*/  
--ER0225 - SwatiKS - 31/Mar/2010 :: Commented till here  
/*  
  update #ProdDownTimeData set downtime = case  
   when #ProdDownTimeData.DownCatagory = 'Setting' then isnull(#ProdDownTimeData.downtime - t1.stdsetuptime,0)  
   when #ProdDownTimeData.DownCatagory = 'ProdTime' then isnull(#ProdDownTimeData.downtime + t1.stdsetuptime,0)  
   else isnull(#ProdDownTimeData.downtime,0)  
   end from (  
   select machineinformation.MachineID,sum(case  
   when autodata.sttime>=@starttime and autodata.ndtime<=@endtime then --Type 1  
    case when datediff(s,sttime,ndtime) >= stdsetuptime  then stdsetuptime else datediff(s,sttime,ndtime) end  
   when autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime then --Type 2  
    case when datediff(s,@starttime,ndtime) >= stdsetuptime  then stdsetuptime else datediff(s,@starttime,ndtime) end  
   when autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime then --Type 3  
    case when datediff(s,sttime,@endtime) >= stdsetuptime  then stdsetuptime else datediff(s,sttime,@endtime) end  
   when autodata.sttime<@starttime and autodata.ndtime>@endtime then --Type 4  
    case when datediff(s,@starttime,@endtime) >= stdsetuptime  then stdsetuptime else datediff(s,@starttime,@endtime) end  
   end) as stdsetuptime from autodata  
   inner join machineinformation on autodata.mc = machineinformation.interfaceid  
   inner join componentinformation on autodata.comp = componentinformation.interfaceid  
   inner join componentoperationpricing on autodata.opn =  componentoperationpricing.interfaceid and componentinformation.componentid = componentoperationpricing.componentid and componentoperationpricing.machineid = machineinformation.machineid  
   where datatype=2 and machineinformation.MachineID in (Select distinct MachineID from #ProdDownTimeData)  
   and dcode in (select interfaceid from downcodeinformation where catagory = 'setting') And  
   ((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or  
    (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or  
    (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or  
    (autodata.sttime<@starttime and autodata.ndtime>@endtime))  
   group by machineinformation.MachineID  
  ) as t1 inner join #ProdDownTimeData on t1.MachineID = #ProdDownTimeData.machineID  
  --and exists (select * from shopdefaults where parameter = 'StdSetupAsProduction' and valueintext = 'yes')  
*/  
  --ER0210  
 end  
 --ER0202 - KarthikG - 24-Oct-2009  

----DR0379 Added From Here
	create table #CatagorySort
	(
	Slno int,
	catagory nvarchar(50)
	)
	Insert into #CatagorySort(Slno,Catagory)
	Select '1','ProdTime'

	insert into #CatagorySort(Slno,Catagory)
	Select 1+ Row_number() Over(Order by DownCatagory),DownCatagory From (Select distinct DownCatagory From #ProdDownTimeData where DownCatagory<>'ProdTime')T --DR0379
----DR0379 Added Till Here


 -- Select DownCatagory as Catagory,MachineID,DownTime  from #ProdDownTimeData where DownTime > 0--where DownCatagory in ('ProdTime','SETTING')  --DR0379
 --Select P.DownCatagory as Catagory,P.MachineID,P.DownTime  from #ProdDownTimeData P
 --inner join #CatagorySort C on C.catagory=P.DownCatagory where DownTime > 0 Order by C.Slno--where DownCatagory in ('ProdTime','SETTING')   --DR0379
  Select P.DownCatagory as Catagory,P.MachineID,P.machineDescription,ROUND((P.DownTime/60),2) as Downtime,
  P.DownTime as DowntimeInSeconds  from #ProdDownTimeData P
 inner join #CatagorySort C on C.catagory=P.DownCatagory where DownTime > 0 Order by C.Slno--where DownCatagory in ('ProdTime','SETTING')   --DR0379

End  
END  
