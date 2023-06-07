/****** Object:  Procedure [dbo].[s_Alert_ShiftAllocation]    Committed by VersionSQL https://www.versionsql.com ******/

--** s_Alert_ShiftAllocation updated for temp table column width of email and phone nos **--
CREATE PROCEDURE [dbo].[s_Alert_ShiftAllocation]
@PlantID nvarchar(50)='',
@Fromdate nvarchar(50),
@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

create table #temp
(
Startdate datetime,
Displaydate nvarchar(50),
Shiftid nvarchar(10),
Consumer nvarchar(500),
Email nvarchar(2000),
Phone nvarchar(2000),
IsChecked Int default 0

)

Create table #day
(
	Startdate datetime,
	Displaydate nvarchar(50),
	Shiftid nvarchar(10),
	Shiftname nvarchar(20)
)

if @param='View'
BEGIN	

Declare @startdate as datetime
Declare @Enddate as datetime

select @startdate = @Fromdate
select @Enddate = dateadd(day,6,@Fromdate)

while @startdate<=@Enddate
Begin
	Insert into #day(Startdate,Displaydate,shiftid,shiftname)
	select @startdate,Cast(datepart(day,@startdate) as nvarchar(2)) + '-' + Cast(datename(Month,@startdate) as nvarchar(3)) + ' ' +shiftname + ' [' + cast(shiftid as nvarchar) + ']',shiftid,Shiftname from Shiftdetails where Running=1 order by shiftid
	select @startdate = dateadd(day,1,@startdate)
end


insert into #temp (Consumer,Email,Phone,Startdate,Displaydate,shiftid) 
select distinct UserID,Email1,Phone1,Startdate,Displaydate,shiftid from 
Alert_Consumers AC  
inner join plantmachine PM on PM.PlantID=AC.PlantID 
cross join #Day
where (PM.Plantid=@plantid or @plantid='')
order by Startdate,shiftid


update #temp set ISchecked = T.IsChecked from 
(select tp.Startdate,tp.shiftid ,tp.Consumer, 1 as IsChecked from #temp tp 
inner join [Alert_UserShiftAllocation] AR on tp.Consumer= AR.Userid and convert(nvarchar(10),tp.Startdate,120)  = convert(nvarchar(10),AR.Shiftdate,120) and tp.Shiftid=AR.Shiftid 
)T inner join #temp on T.Startdate=#temp.Startdate and T.shiftid= #temp.shiftid and T.Consumer= #temp.Consumer


DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

   select @ColumnName = STUFF((SELECT ',' + QUOTENAME(Cast(datepart(day,startdate) as nvarchar(2))+ '-' + Cast(datename(Month,startdate) as nvarchar(3)) + ' ' + shiftname + ' [' + shiftid + ']')                 
  FROM #day group by startdate,shiftname,shiftid order by startdate,shiftid  
   FOR XML PATH(''), TYPE                      
   ).value('.', 'NVARCHAR(MAX)')                       
  ,1,1,'')   --g : changed @startdate to startdate in the second Cast, which was causing to use next month instead of current month during last week of the month


SET @DynamicPivotQuery = 
  N'
  SELECT Consumer,Email,Phone,' + @ColumnName + '
    FROM (select Consumer,Email,Phone,Displaydate,IsChecked from #temp
		  group by Consumer,Email,Phone,Displaydate,IsChecked)#temp
    PIVOT(MAX(IsChecked)
          FOR Displaydate IN (' + @ColumnName + ')) AS PVTTable'

--Execute the Dynamic Pivot Query
execute (@DynamicPivotQuery)


END



END
