/****** Object:  Procedure [dbo].[s_Focas_getToolLifedetails]    Committed by VersionSQL https://www.versionsql.com ******/

/*
 --[dbo].[s_Focas_getToolLifedetails]  'ACE FT 2 L-3','2018-07-01 06:00:00','2018-07-03 06:00:00','BFL'     
 --[dbo].[s_Focas_getToolLifedetails]  'ACE FT 2 L-3','2018-07-01 06:00:00','2018-07-03 06:00:00','BFLAndon'     
 --[dbo].[s_Focas_getToolLifedetails]  '','2018-07-01 06:00:00','2018-07-03 06:00:00','BFL' 
 exec [dbo].[s_Focas_getToolLifedetails] @fromTime=N'2022-08-25 06:00:00',@ToTime=N'2022-09-07 06:00:00',@Machineid=N''

 */
CREATE PROCEDURE [dbo].[s_Focas_getToolLifedetails]      
@machineid as nvarchar(50)='',      
@fromTime datetime='',      
@ToTime datetime='',
@Param nvarchar(50)=''     
AS      
BEGIN      
 -- SET NOCOUNT ON added to prevent extra result sets from      
 -- interfering with SELECT statements.      
 SET NOCOUNT ON;      

Create table #AutoDataAlarms
(
	[ID] [bigint] ,
	[MachineID] [nvarchar](50),
	[ComponentID] [nvarchar](50) ,
	[OperationID] [nvarchar](50),
	AlarmNumber [nvarchar](50) ,
	ToolDescription nvarchar(500),
	Actual [int] ,
	[Target] [int] ,
	RecordType [int] ,
	Alarmtime [datetime] ,
	ToolLifeCount int
)

 create table #temp      
 (      
 id int,      
 Machineid nvarchar(50),      
 Componentid nvarchar(50),      
 operationid nvarchar(50),      
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
 ToolName nvarchar(50),      
 PartCount int,    
 ReasonforChange nvarchar(50),
 RemainingToolLife int,
 Threshold float,  
 ToolDescription nvarchar(500)
 )      
 
If  @Param = 'BFLAndon'
Begin

Select  F.Machineid,F.cnctimestamp,F.Programno  into #MaxProgram from Focas_ToolwiseMaxTimeDetails F inner join
(Select Machineid,Max(id) as idd from Focas_ToolwiseMaxTimeDetails
group by MachineID)T on F.MachineID=T.MachineID and F.id=T.idd

Insert into #temp(Machineid,ProgramNo,ToolNo,tooltarget,ToolActual,Threshold,ToolDescription)
Select F.Machineid,F.ProgramNo,F.ToolNo,F.ToolTarget,F.ToolActual,0,T.ToolDescription from Focas_ToolwiseMaxTimeDetails F
inner join #MaxProgram P on  F.MachineID=P.MachineID and F.ProgramNo=P.ProgramNo 
Left Outer join Focas_ToolLifeMaster T on T.Machineid=F.Machineid and F.ProgramNo=T.ProgramNo and F.ToolNo=T.ToolNo  
  
Update #temp set Threshold = case when ToolTarget>0 then ISNULL(Cast(Round((cast(ToolActual as float)/ cast(ToolTarget as float))*100,2) as float),0) end From #temp

Select Machineid,ProgramNo,ToolNo,ToolTarget,ToolActual,ISNULL(Threshold,0) as Threshold,(ToolTarget -ToolActual) as RL,ToolDescription from #temp
Order by (ToolTarget -ToolActual),MachineID,ToolNo
Return;

END

If @Param='' or @Param='BFL'
BEGIN 
	 SELECT *
	INTO #Focas_ToolLife      
	FROM Focas_ToolLife  where CNCTimeStamp >= @FromTime and CNCTimeStamp <= @ToTime and      
	( Machineid= @machineid or ISNULL(@machineid,'')='')

	;With cte As      
	(SELECT id,Machineid,Componentid,OperationID,ToolNo,ToolTarget,ToolActual,ProgramNo,CNCTimeStamp,PartsCount,ChangeReason,      
			ROW_NUMBER() OVER (PARTITION BY Machineid,ToolNO ORDER BY Machineid,ToolNO,cnctimestamp) AS rn      
	FROM #Focas_ToolLife)      


	insert into #temp(id,Machineid,Componentid,operationid,ToolNo,PrevToolNo,ToolTarget,ToolActual,ToolLedValue,ProgramNo,CNCTimeStamp,PartCount,ReasonforChange)      
	SELECT c1.ID, c1.Machineid, c1.Componentid,c1.OperationID,c1.ToolNO,IsNull(c2.ToolNO, 0) As PrevToolNo,c1.ToolTarget,c1.ToolActual,c2.ToolActual as ToolLedValue,c1.ProgramNo,        
	c1.CNCTimeStamp,c1.PartsCount,c1.ChangeReason      
	FROM cte c1      
	LEFT OUTER JOIN cte c2 ON c1.Machineid = c2.Machineid And c1.ToolNO = c2.ToolNO And c2.rn = c1.rn + 1;       
        
	update #temp set Flag = 1 where ToolLedValue < ToolActual and ToolNo=PrevToolNo  
 
	update #temp set ToolLifeCount = T.ToolCount from      
	(select Machineid,count (Toolno) as ToolCount,ToolNo from #temp where Flag = 1       
	group by Machineid,ToolNo)T inner join #temp on #temp.ToolNo = T.ToolNo and #temp.Machineid = T.Machineid     
	where #temp.Flag = 1  
	
END     
  
If @Param=''
Begin

Insert into #AutoDataAlarms(ID,MachineID,ComponentID,OperationID,AlarmNumber,ToolDescription,Actual,[Target],RecordType,Alarmtime)
	select A.ID,M.machineid,C.componentid,COP.operationno,A.AlarmNumber,T.ToolDescription,A.Actual,A.[Target],A.RecordType,A.Alarmtime FROM AutoDataAlarms A
	 inner join machineinformation M on A.MachineID = M.InterfaceID
	  inner join PlantMachine P on P.MachineID = M.machineid 
	  inner join componentinformation C on A.ComponentID = C.InterfaceID
	  inner Join componentoperationpricing COP on A.OperationID = COP.InterfaceID 
	  and M.machineid = COP.machineid and C.componentid = COP.componentid
	  inner Join  ToolSequence T on T.MachineID = M.Machineid and T.ComponentID = C.componentid
	  and T.OperationNo = COP.operationno and T.ToolNo = A.AlarmNumber 
	where Alarmtime >= @FromTime and Alarmtime <= @ToTime and      
	( M.Machineid= @machineid or ISNULL(@machineid,'')='')  

update #AutoDataAlarms set ToolLifeCount = T.ToolCount from      
	(select Machineid,count (AlarmNumber) as ToolCount,AlarmNumber from #AutoDataAlarms     
	group by Machineid,AlarmNumber)T inner join #AutoDataAlarms on #AutoDataAlarms.AlarmNumber = T.AlarmNumber and #AutoDataAlarms.Machineid = T.Machineid     


select * from (
select #Temp.Machineid,#Temp.ToolNo,T.ToolDescription,#Temp.ToolLifeCount as NoOfTimesChanged,#Temp.CNCTimeStamp as ChangeTime,
T.Componentid as [Type],#Temp.ToolTarget,#Temp.ToolActual,#Temp.PartCount,#Temp.ProgramNo from #temp  
Left Outer join Focas_ToolLifeMaster T on T.Machineid=#Temp.Machineid and #Temp.ProgramNo=T.ProgramNo and #Temp.ToolNo=T.ToolNo 
where Flag = 1 
UNION
select A.Machineid,A.AlarmNumber,A.ToolDescription,ToolLifeCount as NoOfTimesChanged,A.Alarmtime as ChangeTime,
A.Componentid as [Type],A.Target,A.Actual,0 as PartCount,0 as ProgramNo FROM #AutoDataAlarms A
)T1
order by ToolNO,ChangeTime;  
Return;
  
End

If @Param='BFL'
Begin

update #temp set RemainingToolLife = ISNULL(ToolTarget,0)-ISNULL(ToolActual,0)

select #Temp.Machineid,#Temp.ToolNo,T.ToolDescription,#Temp.ToolLifeCount as NoOfTimesChanged,#Temp.CNCTimeStamp as ChangeTime,
T.Componentid as [Type],#Temp.ToolTarget,#Temp.ToolActual,#Temp.PartCount,#Temp.ProgramNo,#temp.RemainingToolLife from #temp  
Left Outer join Focas_ToolLifeMaster T on T.Machineid=#Temp.Machineid and #Temp.ProgramNo=T.ProgramNo and #Temp.ToolNo=T.ToolNo 
where Flag = 1       
order by Machineid,ToolNO,cnctimestamp; 
Return;

End
  

     
END      
