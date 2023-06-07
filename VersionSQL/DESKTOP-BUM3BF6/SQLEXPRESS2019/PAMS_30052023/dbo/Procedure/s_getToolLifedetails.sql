/****** Object:  Procedure [dbo].[s_getToolLifedetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_getToolLifedetails]  '','2018-02-25','2018-02-27',''
CREATE PROCEDURE [dbo].[s_getToolLifedetails]      
@machineid as nvarchar(50)='',      
@fromTime datetime='',      
@ToTime datetime='',
@Param nvarchar(50)='' -- '' or 'ScheduledReport'

AS      
BEGIN      
 
 /*
 [dbo].[s_getToolLifedetails] '','2018-02-20 06:00:00','2018-02-27 18:00:00'   
 ER0467: Gopinath - 2018-09-04 :: Updated to fetch Tool Description
 */   
 SET NOCOUNT ON;      

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
 ReasonforChange nvarchar(50)    
 )      
 
CREATE TABLE #Focas_ToolLife1
  (
	[ID] [bigint] ,
	[MachineID] [nvarchar](50) NOT NULL,
	[ComponentID] [nvarchar](50) NOT NULL,
	[OperationID] [nvarchar](50) NOT NULL,
	[ToolNo] [nvarchar](50) NOT NULL,
	[ToolActual] [int] NOT NULL,
	[ToolTarget] [int] NOT NULL,
	[SpindleType] [int] NOT NULL,
	[ProgramNo] [int] NOT NULL,
	[CNCTimeStamp] [datetime] NOT NULL,
	[ToolUseOrderNumber] [int] NULL,
	[ToolInfo] [int] NULL,
	[PartsCount] [int] NULL,
	[ChangeReason] [int] NULL,    
    ToolLifeCount int
   )
insert into #Focas_ToolLife1 ([ID],[MachineID],[ComponentID],[OperationID],[ToolNo],[ToolActual],
[ToolTarget],[SpindleType],[ProgramNo],[CNCTimeStamp],[ToolUseOrderNumber],[ToolInfo],[PartsCount],[ChangeReason])
SELECT F.[ID], F.[MachineID], F.[ComponentID], F.[OperationID], F.[ToolNo], F.[ToolActual],
 F.[ToolTarget], F.[SpindleType], F.[ProgramNo], F.[CNCTimeStamp], F.[ToolUseOrderNumber], F.[ToolInfo], F.[PartsCount], F.[ChangeReason]          
FROM Focas_ToolLife  F
INNER JOIN FOCAS_MachineInformation FM on F.MachineID = FM.machineid
where F.CNCTimeStamp >= @FromTime and F.CNCTimeStamp <= @ToTime 
and (F.Machineid= @machineid or @machineid='')
 and  FM.MachineMTB = 'AMS'

      
 SELECT F.*      
INTO #Focas_ToolLife      
FROM Focas_ToolLife  F
INNER JOIN FOCAS_MachineInformation FM on F.MachineID = FM.machineid
where F.CNCTimeStamp >= @FromTime and F.CNCTimeStamp <= @ToTime 
and (F.Machineid= @machineid or @machineid='')
 and  FM.MachineMTB <> 'AMS'

;With cte As      
(SELECT id,Machineid,Componentid,OperationID,ToolNo,ToolTarget,ToolActual,ProgramNo,CNCTimeStamp,PartsCount,ChangeReason,      
         ROW_NUMBER() OVER (PARTITION BY ToolNO ORDER BY ToolNO,cnctimestamp) AS rn      
  FROM #Focas_ToolLife)  
  
 

insert into #temp(id,Machineid,Componentid,operationid,ToolNo,PrevToolNo,ToolTarget,ToolActual,ToolLedValue,ProgramNo,CNCTimeStamp,PartCount,ReasonforChange)      
SELECT c1.ID, c1.Machineid, c1.Componentid,c1.OperationID,c1.ToolNO,IsNull(c2.ToolNO, 0) As PrevToolNo,c1.ToolTarget,c1.ToolActual,c2.ToolActual as ToolLedValue,c1.ProgramNo,        
c1.CNCTimeStamp,c1.PartsCount,c1.ChangeReason      
  FROM cte c1      
  LEFT OUTER JOIN cte c2 ON c1.ToolNO = c2.ToolNO And c2.rn = c1.rn + 1;       



update #temp set Flag = 1 where ToolLedValue < ToolActual and ToolNo=PrevToolNo      

update #temp set ToolLifeCount = T.ToolCount from      
(select count (Toolno) as ToolCount,ToolNo from #temp where Flag = 1       
group by ToolNo)T inner join #temp on #temp.ToolNo = T.ToolNo      
where #temp.Flag = 1  
    
update #Focas_ToolLife1 set ToolLifeCount = T.ToolCount from      
(
select count (Toolno) as ToolCount,ToolNo from #temp   
group by ToolNo
)T inner join #Focas_ToolLife1 on #Focas_ToolLife1.ToolNo = T.ToolNo   
      
IF @Param='ScheduledReport' 
BEGIN


	select #Temp.CNCTimeStamp as [Date], pm.PlantID Line, #Temp.Machineid Machine,#Temp.ToolNo Tool, ISNULL(T.ToolDescription, '') ToolDescription, 
	#Temp.ToolTarget,#Temp.ToolActual,D.DownID ChangeReason, Round(100*#Temp.ToolActual/cast(#Temp.ToolTarget as float),2) ToolPercent 
	from #temp  
	Left Outer Join componentinformation C on C.InterfaceID=#Temp.Componentid 
	Left Outer Join componentoperationpricing O on C.componentid=O.componentid and O.operationno=#Temp.OperationID and O.Machineid=#Temp.Machineid
	Left Outer join ToolSequence T on T.componentid=O.componentid and O.operationno=T.operationno
	and O.Machineid=T.Machineid and #Temp.ToolNo=T.ToolNo 
	Left Outer join Downcodeinformation D on D.interfaceid=#Temp.ReasonforChange
	inner join PlantMachine pm on pm.MachineID=#temp.Machineid
	where Flag = 1
	--order by pm.PlantID, pm.MachineID,cnctimestamp,  #Temp.ToolNO;
	--order by #Temp.ToolActual/cast(#Temp.ToolTarget as float)

	UNION

	select  F.CNCTimeStamp as [Date], PM.PlantID,F.Machineid Machine,F.ToolNo Tool,ISNULL(T.ToolDescription, '') ToolDescription,
	F.ToolTarget,F.ToolActual,D.DownID ChangeReason, Round(100 * F.ToolActual/cast(F.ToolTarget as float),2) ToolPercent 
	FROM #Focas_ToolLife1  F
	Left Outer Join componentinformation C on C.InterfaceID=F.Componentid 
	Left Outer Join componentoperationpricing O on C.componentid=O.componentid and O.operationno=F.OperationID and O.Machineid=F.Machineid
	Left Outer join Focas_downcodeInformation D on D.interfaceid=F.ChangeReason
	Left Outer join ToolSequence T on T.componentid=O.componentid and O.operationno=T.operationno
	and O.Machineid=T.Machineid and F.ToolNo=T.ToolNo 
	inner join PlantMachine PM on PM.MachineID=F.Machineid
	order by #Temp.ToolActual/cast(#Temp.ToolTarget as float)
END
ELSE
BEGIN

select #Temp.Machineid,#Temp.ToolNo,T.ToolDescription,#Temp.ToolLifeCount as NoOfTimesChanged,#Temp.CNCTimeStamp as ChangeTime,
C.Componentid + ' <' + cast(O.operationno as nvarchar(50)) + '>' as [Type],#Temp.ToolTarget,#Temp.ToolActual,#Temp.PartCount,D.DownID from #temp  
Left Outer Join componentinformation C on C.InterfaceID=#Temp.Componentid 
Left Outer Join componentoperationpricing O on C.componentid=O.componentid and O.operationno=#Temp.OperationID and O.Machineid=#Temp.Machineid
Left Outer join ToolSequence T on T.componentid=O.componentid and O.operationno=T.operationno
and O.Machineid=T.Machineid and #Temp.ToolNo=T.ToolNo 
Left Outer join Downcodeinformation D on D.interfaceid=#Temp.ReasonforChange
where Flag = 1       
--order by ToolNO,cnctimestamp
UNION
select F.Machineid,F.ToolNo,T.ToolDescription,ToolLifeCount,F.CNCTimeStamp as ChangeTime,
C.Componentid + ' <' + cast(O.operationno as nvarchar(50)) + '>' as [Type],F.ToolTarget,F.ToolActual,F.PartsCount,D.DownID
FROM #Focas_ToolLife1  F
Left Outer Join componentinformation C on C.InterfaceID=F.Componentid 
Left Outer Join componentoperationpricing O on C.componentid=O.componentid and O.operationno=F.OperationID and O.Machineid=F.Machineid
Left Outer join ToolSequence T on T.componentid=O.componentid and O.operationno=T.operationno
and O.Machineid=T.Machineid and F.ToolNo=T.ToolNo 
Left Outer join Focas_downcodeInformation D on D.interfaceid=F.ChangeReason
order by ToolNO,cnctimestamp

END
END      
