/****** Object:  Procedure [dbo].[AssignScreenToMachine_SSWL]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[AssignScreenToMachine_SSWL] '''screen1'',''screen2'',''screen3'',''screen4'',''screen5''','''30 Ton-Welding Machine-146'',''60 Ton-Welding Machine-155'',''SLT-08 LM195'',''SLT-08 LM196'',''SLT-08 LM201'' ,''SLT-08 LM202'',''SLT-08 LM203'',''SLT-08 LM204'',''SLT-08 LM205'',''SLT-08 LM206'' '
*/
CREATE procedure [dbo].[AssignScreenToMachine_SSWL]
@Screen nvarchar(max)='',
@MachineID NVARCHAR(MAX)=''
AS
BEGIN
DECLARE @StrScreen nvarchar(max)
declare @StrMachine nvarchar(max)
declare @Strsql nvarchar(max)
DECLARE @cols AS NVARCHAR(MAX)
declare @query  AS NVARCHAR(MAX)

Declare @StrTPMMachines AS nvarchar(500) 
SELECT @StrTPMMachines=''

create table #AssignScreenMachine
(
ID BIGINT IDENTITY(1,1),
UserID nvarchar(50),
Screen NVARCHAR(500),
Machineid NVARCHAR(50),
Status int default 0
)

if isnull(@MachineID,'')<>''
begin
set @StrMachine= ' And machineinformation.machineid in (' +@MachineID+ ')'
END

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = ' AND MachineInformation.TPMTrakEnabled = 1 '  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END 

if isnull(@Screen,'')<>''
begin
set @StrScreen=' And ScreenDetails_SSWL.ScreenName in (' +@Screen+ ')'
end

select @Strsql=''
select @Strsql=@Strsql + 'Insert into #AssignScreenMachine(UserID,Screen,Machineid,Status) '
select @Strsql=@Strsql + 'Select distinct '''' as UserID,ScreenDetails_SSWL.ScreenName,machineinformation.Machineid,''0'' from machineinformation cross join ScreenDetails_SSWL where 1=1 '
select @Strsql=@Strsql+ @StrMachine + @StrTPMMachines +@StrScreen
print(@strsql)
exec(@strsql)

SELECT @cols= COALESCE(@cols+',','')+ QUOTENAME(Machineid) FROM  
(SELECT DISTINCT [Machineid] FROM #AssignScreenMachine)Tab 

  SELECT @Query='SELECT Screen, '+@cols+'FROM   
(select distinct p1.Screen,p1.Machineid,isnull(p2.Status,0) as status  from #AssignScreenMachine p1 left outer join AssignMachinesToScreens_SSWL p2 on p1.Screen=p2.ScreenName 
and p1.MachineID=p2.MachineID 
 )Tab1  
PIVOT  
(  
max(status)  FOR [Machineid] IN ('+@cols+')) AS Tab2
order by Screen'
EXEC  sp_executesql  @Query 
print(@query)

end
