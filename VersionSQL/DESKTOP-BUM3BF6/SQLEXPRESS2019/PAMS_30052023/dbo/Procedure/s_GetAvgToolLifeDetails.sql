/****** Object:  Procedure [dbo].[s_GetAvgToolLifeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/* 
--[dbo].[s_GetAvgToolLifeDetails]'2017-01-28 06:00:00','2017-04-29 18:00:00' ,'CNC','CNC-01',''             

exec [s_GetAvgToolLifeDetails] @fromTime=N'2022-08-25 06:00:00',@ToTime=N'2022-09-07 06:00:00',@Machineid=N'',@Groupid=N'',@ToolID=N''
  
*/  
CREATE PROCEDURE [dbo].[s_GetAvgToolLifeDetails]          
@FromTime datetime='',          
@ToTime datetime='',            
@Groupid nvarchar(50)='',        
@machineid nvarchar(max)='',        
@ToolID nvarchar(50) =''     
AS          
BEGIN          
 -- SET NOCOUNT ON added to prevent extra result sets from          
 -- interfering with SELECT statements.          
 SET NOCOUNT ON;          
          
 create table #AvgToolDetails          
 (          
 PlantID nvarchar(50),      
 Machineid nvarchar(50),      
 MachineDescription nvarchar(50),       
 ToolNo nvarchar(50),          
 ToolAverage int      
 )          
       
create table #ToolDetails          
 (          
 id int,          
 Machineid nvarchar(50),            
 ToolNo nvarchar(50),          
 PrevToolNo nvarchar(50),          
 ToolTarget int,          
 ToolActual int,          
 ToolLedValue int,          
 ProgramNo nvarchar(50),          
 CNCTimeStamp datetime,          
 ToolLifeCount int,          
 Flag int,          
 AlarmTime datetime ,        
 ToolName nvarchar(50)          
 )          
        
Create table #Focas_ToolLife      
(      
   [ID] [bigint],      
 [MachineID] [nvarchar](50),      
 [ComponentID] [nvarchar](50),      
 [OperationID] [nvarchar](50),      
 [ToolNo] [nvarchar](50),      
 [ToolActual] [int],      
 [ToolTarget] [int],      
 [SpindleType] [int],      
 [ProgramNo] [int],      
 [CNCTimeStamp] [datetime],      
 [ToolUseOrderNumber] [int],      
 [ToolInfo] [int]       
)      
      
Declare @strMachine as nvarchar(4000)   
Declare @strMachine1 as nvarchar(4000) 
Declare @strPlant as nvarchar(4000)      
Declare @strGroup as nvarchar(4000)      
     
declare @strsql as nvarchar(4000)      
 select @strMachine=''   
  select @strMachine1=''  
 Select @Strsql=''      
 select @strPlant=''      
 select @strGroup=''      
  
      
if isnull(@machineid,'')<> ''      
begin      
 --SET @strMachine = ' AND FT.MachineID in (' + @Machineid + ')'   
 SET @strMachine = ' AND FT.MachineID =N''' + @Machineid + ''''    
end      

if isnull(@Groupid,'')<> ''      
begin      
 SET @strGroup = ' AND PMG.GroupID = N''' + @Groupid + ''''   
end   
   
if isnull(@machineid,'')<> ''      
begin      
 SET @strMachine1 = ' AND M.MachineID =N''' + @Machineid + ''''    
end  

Select @Strsql=@Strsql+'INSERT INTO #Focas_ToolLife([ID],[MachineID],[ComponentID],[OperationID],[ToolNo],[ToolActual],[ToolTarget],[SpindleType],[ProgramNo] ,[CNCTimeStamp],[ToolUseOrderNumber],[ToolInfo])      
 SELECT [ID],[MachineID],[ComponentID],[OperationID],[ToolNo],[ToolActual],[ToolTarget],[SpindleType],[ProgramNo] ,[CNCTimeStamp],[ToolUseOrderNumber],[ToolInfo] FROM Focas_ToolLife FT WITH(NOLOCK) where CNCTimeStamp >= '''+ Convert(nvarchar(20),@FromTime,120) +''' and CNCTimeStamp <= '''+ Convert(nvarchar(20),@ToTime,120) +''''        
Select @Strsql=@Strsql+@strMachine      
exec(@strsql)      
    
Select @Strsql=@Strsql+'INSERT INTO #Focas_ToolLife([ID],[MachineID],[ComponentID],[OperationID],[ToolNo],[ToolActual],[ToolTarget],[SpindleType],[ProgramNo] ,[CNCTimeStamp],[ToolUseOrderNumber],[ToolInfo])      
 SELECT A.[ID],M.[MachineID],C.[ComponentID],COP.[OperationNO],A.[AlarmNumber],A.[Actual],A.[Target],A.[RecordType],0 as [ProgramNo] ,[Alarmtime],0 as [ToolUseOrderNumber],0 as [ToolInfo] 
 FROM AutoDataAlarms A
 inner join machineinformation M on A.MachineID = M.InterfaceID
	  inner join PlantMachine P on P.MachineID = M.machineid 
	  inner join componentinformation C on A.ComponentID = C.InterfaceID
	  inner Join componentoperationpricing COP on A.OperationID = COP.InterfaceID 
	  and M.machineid = COP.machineid and C.componentid = COP.componentid
	  inner Join  ToolSequence T on T.MachineID = M.Machineid and T.ComponentID = C.componentid
	  and T.OperationNo = COP.operationno and T.ToolNo = A.AlarmNumber 
where Alarmtime >= '''+ Convert(nvarchar(20),@FromTime,120) +''' and Alarmtime <= '''+ Convert(nvarchar(20),@ToTime,120) +''''        
Select @Strsql=@Strsql+@strMachine1
print @strsql
exec(@strsql)
       
	
--;With cte As          
--(SELECT id,Machineid,ToolNo,ToolTarget,ToolActual,ProgramNo,CNCTimeStamp,          
--         ROW_NUMBER() OVER (PARTITION BY Machineid,ToolNO ORDER BY Machineid,ToolNO,cnctimestamp) AS rn          
--  FROM #Focas_ToolLife)        
          
--insert into #ToolDetails(id,Machineid,ToolNo,PrevToolNo,ToolTarget,ToolActual,ToolLedValue,ProgramNo,CNCTimeStamp)          
--SELECT c1.ID, c1.Machineid,c1.ToolNO,IsNull(c2.ToolNO, 0) As PrevToolNo,c1.ToolTarget,c1.ToolActual,c2.ToolActual as ToolLedValue,c1.ProgramNo,            
--c1.CNCTimeStamp FROM cte c1          
----LEFT OUTER JOIN cte c2 ON c1.machineid=c2.machineid and c1.ToolNO = c2.ToolNO And c2.rn = c1.rn + 1;           
          
--Update #ToolDetails set Flag = 1 where ToolLedValue < ToolActual and ToolNo=PrevToolNo          
          
--update #ToolDetails set ToolLifeCount = T.ToolCount from          
--(select Machineid,count (Toolno) as ToolCount,ToolNo from #ToolDetails where Flag = 1           
--group by ToolNo,Machineid)T inner join #ToolDetails on #ToolDetails.ToolNo = T.ToolNo and #ToolDetails.Machineid = T.Machineid           
--where #ToolDetails.Flag = 1          
 
 insert into #ToolDetails(id,Machineid,ToolNo,ToolTarget,ToolActual,ProgramNo,CNCTimeStamp)          
SELECT DISTINCT c1.ID, c1.Machineid,c1.ToolNO,c1.ToolTarget,c1.ToolActual,c1.ProgramNo,c1.CNCTimeStamp FROM #Focas_ToolLife c1          

 update #ToolDetails set ToolLifeCount = T.ToolCount from          
(select Machineid,count (Toolno) as ToolCount,ToolNo from #ToolDetails         
group by ToolNo,Machineid)T inner join #ToolDetails on #ToolDetails.ToolNo = T.ToolNo and #ToolDetails.Machineid = T.Machineid           
        

 Select @Strsql=''      
 Select @strsql = @Strsql + '          
insert into #AvgToolDetails(PlantID,Machinedescription,Machineid,ToolNo,ToolAverage)      
select Plantmachine.PlantID,PM.description,PM.Machineid,FT.ToolNo,0 from Machineinformation   PM    
inner join #Focas_ToolLife FT on PM.Machineid=FT.Machineid 
left outer join Plantmachine on Plantmachine.machineid=FT.Machineid
LEFT OUTER JOIN PlantMachineGroups PMG ON PMG.PlantID = PlantMachine.PlantID and PMG.machineid = PlantMachine.MachineID '
Select @strsql = @Strsql + ' where (FT.ToolNo='''+ @ToolID + ''' or isnull('''+ @ToolID + ''','''')='''') and (FT.ToolActual>0 and FT.ToolNo<>''0'') '      
Select @strsql = @Strsql + @strMachine + @strGroup     
Select @strsql = @Strsql + ' Group by Plantmachine.PlantID,PM.Description,PM.Machineid,FT.ToolNo'      
Exec(@Strsql)      
 
--Update #AvgToolDetails set ToolAverage=T1.ToolAvg From       
--(Select Machineid,Toolno,SUM(ToolActual)/SUM(ToolLifeCount) as ToolAvg From       
--#ToolDetails  where ToolLifeCount>0 Group by Machineid,Toolno)T1 inner join  #AvgToolDetails on #AvgToolDetails.ToolNo = T1.ToolNo and #AvgToolDetails.Machineid = T1.Machineid           

Update #AvgToolDetails set ToolAverage=T1.ToolAvg From       
(Select Machineid,Toolno,SUM(ToolActual)/(ToolLifeCount) as ToolAvg From       
#ToolDetails  where ToolLifeCount>0 Group by Machineid,Toolno,ToolLifeCount)T1 inner join  #AvgToolDetails on #AvgToolDetails.ToolNo = T1.ToolNo and #AvgToolDetails.Machineid = T1.Machineid           

      
Select PlantID,Machinedescription,Machineid,ToolNo,ToolAverage from #AvgToolDetails Order by PlantID,Machinedescription,Machineid      
      
          
END   
