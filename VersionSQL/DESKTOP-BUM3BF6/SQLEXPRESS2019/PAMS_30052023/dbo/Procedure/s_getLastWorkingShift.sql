/****** Object:  Procedure [dbo].[s_getLastWorkingShift]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0448 - VasaviP - 10/Feb/2017 :: Created New Procedure to get last working shift for Bosch Jaipur.  
--[dbo].[s_getLastWorkingShift] '','','2017-01-08','Shift'    
CREATE PROCEDURE [dbo].[s_getLastWorkingShift]    
(    
@machineid nvarchar(50)='',    
@plantid nvarchar(50) ='',    
@startdatetime as datetime,    
@param nvarchar(50) ='',    
@day int='30'    
)    
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
Declare @CurStrtTime as datetime      
Declare @CurEndTime as datetime     
declare @startdate as datetime    
declare @enddate as datetime    
declare @startdatetime1 nvarchar(20)    
declare @lastWorkingShift nvarchar(50)    
declare @WorkingShiftCount int    
select @lastWorkingShift =  isnull(ValueInText ,'Y') from shopdefaults where Parameter='LastWorkingShift'    
select @WorkingShiftCount = count(*)  from SHiftdetails where running = 1    
declare @res int    
declare @Logicaldaystart as datetime    
Select @Logicaldaystart = dbo.f_GetLogicalDayStart(@startdatetime)    
    
CREATE TABLE #SDetails       
(      
 PDate datetime,      
 Shift nvarchar(20),      
 ShiftStart datetime,      
 ShiftEnd datetime,    
 Shiftid int      
)     
    
create table #temp    
(    
id int identity(1,1),    
Machineid nvarchar(50),    
Pdate datetime,     
Shift nvarchar(50),    
ShiftStart datetime,    
ShiftEnd datetime,    
Shiftid int      
)    
    
select @startdate = @startdatetime    
select @startdatetime1 = CAST(datePart(yyyy,@startdate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@startdate) AS nvarchar(2)) + '-' + CAST(datePart(dd,@startdate) AS nvarchar(2))    
    
    
    
INSERT INTO #SDetails(Pdate, Shift, ShiftStart, ShiftEnd,Shiftid)    
select @startdate,ShiftName,    
Dateadd(DAY,FromDay,(convert(datetime, @startdatetime1 + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,    
DateAdd(Day,ToDay,(convert(datetime, @startdatetime1 + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime    
,Shiftid from shiftdetails where running = 1 order by shiftid    
    
 select @res = count(*) from #SDetails tp left join PlannedDownTimes PDT on tp.ShiftStart=PDT.StartTime and tp.ShiftEnd = PDT.EndTime     
left join holidayList HL on  HL.Reason = PDT.DownReason     
and Convert(nvarchar(10),HL.Holiday,120)=Convert(nvarchar(10),@Logicaldaystart,120)     
    
    
Insert into #temp (Machineid,Pdate,ShiftStart,ShiftEnd,Shift,Shiftid)      
SELECT distinct Machineinformation.machineid,S.PDate,S.shiftstart,S.shiftend,S.Shift,S.Shiftid FROM Machineinformation      
Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid      
Cross join #SDetails S where (machineinformation.machineid= @machineid or @machineid='') and (plantmachine.plantid = @plantid or @plantid='')    
    
     
IF  NOT exists( select tp.* from #temp tp left join PlannedDownTimes PDT on tp.ShiftStart=PDT.StartTime    
 and tp.ShiftEnd = PDT.EndTime and tp.Machineid = PDT.Machine    
left join holidayList HL on  HL.Reason = PDT.DownReason and HL.Machineid = tp.Machineid and Convert(nvarchar(10),HL.Holiday,120)=Convert(nvarchar(10),@Logicaldaystart,120))    
BEGIN    
print 'Not exists'    
select Machineid,Pdate,Shift,ShiftStart,ShiftEnd,Shiftid from #temp;    
return;    
END    
--else if exists (select tp.* from #temp tp inner   join PlannedDownTimes PDT on tp.ShiftStart=PDT.StartTime and tp.ShiftEnd = PDT.EndTime and tp.Machineid = PDT.Machine    
--left join holidayList HL on  HL.Reason = PDT.DownReason  and HL.Machineid = tp.Machineid    
--and Convert(nvarchar(10),HL.Holiday,120)=Convert(nvarchar(10),@Logicaldaystart,120))     
--BEGIN    
--if (@Res= @WorkingShiftCount )    
--BEGIN    
--print 'exists'    
--select  Machineinformation.machineid,@startdate as Pdate,ShiftName,    
--Dateadd(DAY,FromDay,(convert(datetime, @startdatetime1 + ' ' + CAST(datePart(hh,StartTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,StartTime) as nvarchar(2))+ ':' + CAST(datePart(ss,StartTime) as nvarchar(2))))) as StartTime,    
--DateAdd(Day,ToDay,(convert(datetime, @startdatetime1 + ' ' + CAST(datePart(hh,EndTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,EndTime) as nvarchar(2))+ ':' + CAST(datePart(ss,EndTime) as nvarchar(2))))) as EndTime    
--,Shiftid     
--FROM Machineinformation      
--Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid      
--Cross join HolidayShift S where (machineinformation.machineid= @machineid or @machineid='') and (plantmachine.plantid = @plantid or @plantid='')     
--      
--return;    
--END    
--END    
else if exists(select * from PlannedDownTimes PDT --on tp.ShiftStart=PDT.StartTime and tp.ShiftEnd = PDT.EndTime and tp.Machineid = PDT.Machine    
inner join holidayList HL on  HL.Reason = PDT.DownReason  and HL.Machineid = pdt.Machine    
and Convert(nvarchar(10),HL.Holiday,120)=Convert(nvarchar(10),Pdt.starttime,120)  
where Convert(nvarchar(10),HL.Holiday,120)=Convert(nvarchar(10),@startdatetime,120))  
BEGIN    
print 'exists'    
select  Machineinformation.machineid,Convert(nvarchar(10),DateAdd(Day,ToDay,(convert(datetime, @startdatetime1 + ' ' + CAST(datePart(hh,EndTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,EndTime) as nvarchar(2))+ ':' + CAST(datePart(ss,EndTime) as nvarchar
(2))))),120) as Pdate,ShiftName,    
Dateadd(DAY,FromDay,(convert(datetime, @startdatetime1 + ' ' + CAST(datePart(hh,StartTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,StartTime) as nvarchar(2))+ ':' + CAST(datePart(ss,StartTime) as nvarchar(2))))) as StartTime,    
DateAdd(Day,ToDay,(convert(datetime, @startdatetime1 + ' ' + CAST(datePart(hh,EndTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,EndTime) as nvarchar(2))+ ':' + CAST(datePart(ss,EndTime) as nvarchar(2))))) as EndTime    
,Shiftid     
FROM Machineinformation      
Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid      
Cross join HolidayShift S where (machineinformation.machineid= @machineid or @machineid='') and (plantmachine.plantid = @plantid or @plantid='')     
      
return;    
END      
  
  
--print 'exists'    
    
--if(@lastWorkingShift = 'N')    
--BEGIN    
--select Machineid,Pdate,Shift,ShiftStart,ShiftEnd,Shiftid from #temp order by id     
--return;    
--END    
    
    
Select @CurStrtTime=(@startdatetime-isnull(@day,30))      
Select @CurEndTime=@startdatetime      
    
delete from #SDetails;    
delete from #temp;    
While @CurStrtTime<=@CurEndTime      
BEGIN      
select @startdate = @CurStrtTime    
select @startdatetime1 = CAST(datePart(yyyy,@startdate) AS nvarchar(4)) + '-' +     
CAST(datePart(mm,@startdate) AS nvarchar(2)) + '-' +     
CAST(datePart(dd,@startdate) AS nvarchar(2))    
    
INSERT INTO #SDetails(Pdate, Shift, ShiftStart, ShiftEnd,Shiftid)    
select @startdate,ShiftName,    
Dateadd(DAY,FromDay,(convert(datetime, @startdatetime1 + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,    
DateAdd(Day,ToDay,(convert(datetime, @startdatetime1 + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime    
,Shiftid from shiftdetails where running = 1 order by shiftid    
    
SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)      
END      
    
Insert into #temp (Machineid,Pdate,ShiftStart,ShiftEnd,Shift,Shiftid)      
SELECT distinct Machineinformation.machineid,S.PDate,S.shiftstart,S.shiftend,S.Shift,S.Shiftid FROM Machineinformation      
Left outer join Plantmachine on Machineinformation.machineid=Plantmachine.machineid      
Cross join #SDetails S where (machineinformation.machineid= @machineid or @machineid='') and (plantmachine.plantid = @plantid or @plantid='')    
    
    
delete tp from #temp tp inner join PlannedDownTimes PDT on tp.ShiftStart=PDT.StartTime    
 and tp.ShiftEnd = PDT.EndTime and tp.Machineid = PDT.Machine    
left join holidayList HL on  HL.Reason = PDT.DownReason and HL.Machineid =tp.Machineid    
    
    
if(@param='Shift')    
BEGIN    
    
 select T.Machineid,T.Pdate,T.[Shift],T.ShiftStart,T.ShiftEnd,T.Shiftid    
from (    
     select T.id,T.Machineid,T.Pdate,T.[Shift],T.ShiftStart,T.ShiftEnd,T.Shiftid,    
            row_number() over(partition by T.Machineid order by id desc) as rn    
     from #temp as T    
     ) as T     
where T.rn <= @WorkingShiftCount order by T.machineid,T.rn desc;    
    
END     
    
    
End   
