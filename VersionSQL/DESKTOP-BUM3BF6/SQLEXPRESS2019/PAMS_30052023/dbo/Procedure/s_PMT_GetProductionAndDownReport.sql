/****** Object:  Procedure [dbo].[s_PMT_GetProductionAndDownReport]    Committed by VersionSQL https://www.versionsql.com ******/

--s_PMT_GetProductionAndDownReport '2022-11-05','','','',''
CREATE                                  PROCEDURE [dbo].[s_PMT_GetProductionAndDownReport]
	@StartDate As DateTime,
	@PlantID As NVarChar(50)='',
	@MachineID As nvarchar(50) = '',
	@Groupid nvarchar(50)='',
	@Parameter As nvarchar(50)=''/* Shift,Day,Consolidated Etc*/
AS
BEGIN

Declare @CurDate As DateTime
declare @EndDate as datetime
SELECT @CurDate=dbo.f_GetPhysicalMonth(@StartDate,'Start')
Select @EndDate =dbo.f_GetPhysicalMonth(@StartDate,'End')

declare @strsql as nvarchar(max)

Declare @Strmachine nvarchar(255)
Declare @StrPlantID AS NVarchar(255)
Declare @Strgroupid AS NVarchar(255)
declare @i as nvarchar(10)
declare @colName as nvarchar(50)

Select @Strsql = ''
Select @Strmachine = ''
Select @StrPlantID=''
select @Strgroupid=''
Select @i=1

CREATE TABLE #TimePeriodDetails
(
PDate datetime,
Shift nvarchar(20),
DStart datetime,
DEnd datetime
)

Create Table #ProdData
(
Pdate DateTime,
Shift  NVarChar(20),
PlantID  NVarChar(50),
groupid  NVarChar(50),
MachineID  NVarChar(50),
ComponentID  NVarChar(50),
OperationNo  NVarChar(50),
OperatorID  NVarChar(50),
Cycletime float DEFAULT 0,
NoOfPcs int DEFAULT 1,
D1 float DEFAULT 0,
D2 float DEFAULT 0,
D3 float DEFAULT 0,
D4 float DEFAULT 0,
D5 float DEFAULT 0,
D6 float DEFAULT 0,
D7 float DEFAULT 0,
D8 float DEFAULT 0,
D9 float DEFAULT 0,
D10 float DEFAULT 0,
D11 float DEFAULT 0,
D12 float DEFAULT 0,
D13 float DEFAULT 0,
D14 float DEFAULT 0,
D15 float DEFAULT 0,
LUtime float DEFAULT 0,
ActualParts Int DEFAULT 0,
OKParts Int DEFAULT 0,
WorkingHours int DEFAULT 0,
Shiftstart datetime,
Shiftend datetime
)

Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50),
	InterfaceId nvarchar(50),
)

Insert into #Downcode(Downid,InterfaceId)
--Select top 7 downid,InterfaceId 
-- from downcodeinformation 
-- where SortOrder<=7 and ( isnull(SortOrder,0) <> 0) order by sortorder
 Select top 15 downid,InterfaceId 
 from downcodeinformation 
 where SortOrder<=15 and ( isnull(SortOrder,0) <> 0) order by sortorder

While @CurDate<=@EndDate
BEGIN

INSERT #TimePeriodDetails(Pdate, Shift, DStart, DEnd)
EXEC s_GetShiftTime @CurDate,''
			
SELECT @CurDate=DateAdd(dd,1,@CurDate)
END

If isnull(@PlantID,'') <> ''
Begin
	Select @StrPlantID = ' And ( S.PlantID = N''' + @PlantID + ''' )'
End
If isnull(@Machineid,'') <> ''
Begin
	Select @Strmachine = ' And ( S.MachineID = N''' + @MachineID + ''')'
End
If isnull(@Groupid,'') <> ''
Begin
	Select @Strgroupid = ' And ( S.groupid = N''' + @Groupid + ''')'
End


--Select @strsql=''
--Select @strsql=@strsql+'
--Insert into #ProdData(PlantID,groupid,MachineID,ComponentID,OperationNo,OperatorID,Pdate,Shift,Cycletime,LUtime,Shiftstart,Shiftend)
--Select DISTINCT S.PlantID,S.groupid,S.MachineID,S.ComponentID,S.OperationNo,S.OperatorID,T.Pdate,S.Shift,S.CO_StdMachiningTime,S.CO_StdLoadUnload,T.DStart,T.DEnd from ShiftProductionDetails S
--inner join #TimePeriodDetails T on convert(nvarchar(10),S.pDate,120)=convert(nvarchar(10),T.pDate,120) and S.Shift=T.Shift
--where S.machineid is not null ' 
--Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @Strgroupid
--Select @Strsql = @Strsql+ ' order by S.PlantID,S.groupid,T.Pdate,S.MachineID'
--print @strsql
--exec(@strsql)

Select @strsql=''
Select @strsql=@strsql+'
Insert into #ProdData(PlantID,groupid,MachineID,ComponentID,OperationNo,OperatorID,Pdate,Shift,--Cycletime,LUtime,
Shiftstart,Shiftend)
( Select DISTINCT S.PlantID,S.groupid,S.MachineID,S.ComponentID,S.OperationNo,S.OperatorID,T.Pdate,S.Shift,--S.CO_StdMachiningTime,S.CO_StdLoadUnload,
T.DStart,T.DEnd from ShiftProductionDetails S
inner join #TimePeriodDetails T on convert(nvarchar(10),S.pDate,120)=convert(nvarchar(10),T.pDate,120) and S.Shift=T.Shift
where S.machineid is not null ' 
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @Strgroupid
Select @strsql=@strsql+' ) UNION ( Select DISTINCT S.PlantID,S.groupid,S.MachineID,S.ComponentID,S.OperationNo,S.OperatorID,T.Pdate,S.Shift,--0,0,
T.DStart,T.DEnd from ShiftDownTimeDetails S
inner join #TimePeriodDetails T on convert(nvarchar(10),S.dDate,120)=convert(nvarchar(10),T.pDate,120) and S.Shift=T.Shift
where S.machineid is not null 
AND S.DownId IN ( SELECT Downid from #Downcode) ' 
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @Strgroupid
Select @Strsql = @Strsql+ ' )'
--Select @Strsql = @Strsql+ ' order by S.PlantID,S.groupid,T.Pdate,S.MachineID'
print @strsql
exec(@strsql)

Select @Strsql=''
Select @Strsql = 'Update #ProdData Set Cycletime=ISNULL(S.Cycletime,0),LUtime=ISNULL(S.LUtime,0)'
Select @Strsql = @Strsql+ ' From( 
							Select DISTINCT S.MachineID,S.ComponentID,S.OperationNo,S.OperatorID,T.Pdate,S.Shift,
							S.CO_StdMachiningTime as Cycletime,S.CO_StdLoadUnload as LUtime from ShiftProductionDetails S
							inner join #TimePeriodDetails T on convert(nvarchar(10),S.pDate,120)=convert(nvarchar(10),T.pDate,120) and S.Shift=T.Shift '
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @Strgroupid
Select @Strsql = @Strsql+ ' )As S inner Join #ProdData ON #ProdData.pDate=S.pDate And #ProdData.Shift=S.Shift And #ProdData.MachineID=S.MachineID And #ProdData.ComponentID=S.ComponentID 
And #ProdData.OperationNo=S.OperationNo And #ProdData.OperatorID=S.OperatorID'
Print @Strsql
Exec(@Strsql)

Select @Strsql=''
Select @Strsql = 'Update #ProdData Set ActualParts=ISNULL(S.ActualParts,0),OKParts=ISNULL(S.OKParts,0)'
Select @Strsql = @Strsql+ ' From('
Select @Strsql = @Strsql+ ' Select S.pDate,S.Shift,S.MachineID,S.ComponentID,S.OperationNo,S.OperatorID,Sum(ISNULL(S.Prod_Qty,0)) as ActualParts,Sum(ISNULL(S.AcceptedParts,0)) as OKParts From ShiftProductionDetails S
inner join #ProdData ON convert(nvarchar(10),#ProdData.pDate,120)=convert(nvarchar(10),S.pDate,120) And #ProdData.Shift=S.Shift And #ProdData.MachineID=S.MachineID And #ProdData.ComponentID=S.ComponentID 
And #ProdData.OperationNo=S.OperationNo And #ProdData.OperatorID=S.OperatorID '
Select @Strsql = @Strsql+ ' Where S.MachineID IS NOT NULL '
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @Strgroupid
Select @Strsql = @Strsql+ ' GROUP By S.pDate,S.Shift,S.MachineID,S.ComponentID,S.OperationNo,S.OperatorID '
Select @Strsql = @Strsql+ ' )As S inner Join #ProdData ON #ProdData.pDate=S.pDate And #ProdData.Shift=S.Shift And #ProdData.MachineID=S.MachineID And #ProdData.ComponentID=S.ComponentID 
And #ProdData.OperationNo=S.OperationNo And #ProdData.OperatorID=S.OperatorID'
Print @Strsql
Exec(@Strsql)

--while @i <=7
while @i <=15
Begin

 Select @ColName = Case when @i=1 then 'D1'
						when @i=2 then 'D2'
						when @i=3 then 'D3'
						when @i=4 then 'D4'
						when @i=5 then 'D5'
						when @i=6 then 'D6'
						when @i=7 then 'D7'
						when @i=8 then 'D8'
						when @i=9 then 'D9'
						when @i=10 then 'D10'
						when @i=11 then 'D11'
						when @i=12 then 'D12'
						when @i=13 then 'D13'
						when @i=14 then 'D14'
						when @i=15 then 'D15'
					END

Select @strsql = ''
Select @strsql = @strsql + ' UPDATE  #ProdData SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(S.down,0)  
from  
( select S.dDate,S.Shift,S.MachineID,S.ComponentID,S.OperationNo,S.OperatorID,
Sum(S.DownTime) As Down
from ShiftDownTimeDetails S    
inner join downcodeinformation on S.downid=downcodeinformation.downid 
inner join #Downcode on #Downcode.downid= downcodeinformation.downid	
inner join #ProdData ON convert(nvarchar(10),#ProdData.pDate,120)=convert(nvarchar(10),S.dDate,120) And #ProdData.Shift=S.Shift And #ProdData.MachineID=S.MachineID And #ProdData.ComponentID=S.ComponentID 
And #ProdData.OperationNo=S.OperationNo And #ProdData.OperatorID=S.OperatorID 
Where #Downcode.Slno= ' + @i + '  '
Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @Strgroupid
Select @Strsql = @Strsql+  ' group by S.dDate,S.Shift,S.MachineID,S.ComponentID,S.OperationNo,S.OperatorID)
As S inner Join #ProdData ON #ProdData.pDate=S.dDate And #ProdData.Shift=S.Shift And #ProdData.MachineID=S.MachineID And #ProdData.ComponentID=S.ComponentID 
And #ProdData.OperationNo=S.OperationNo And #ProdData.OperatorID=S.OperatorID'
print @strsql
exec(@Strsql)

select @i  =  @i + 1
END  

update #ProdData set WorkingHours=DATEDIFF(SECOND,Shiftstart,shiftend)

UPDATE #ProdData SET WorkingHours = WorkingHours - isnull(T1.PDT,0) 
from
(Select Machine,#ProdData.shiftstart,SUM(datediff(SECOND,Starttime,endtime))as PDT from Planneddowntimes
inner join (select distinct machineid,shiftstart,shiftend from #ProdData) as #ProdData on #ProdData.machineid=Planneddowntimes.machine
where starttime>=#ProdData.shiftstart and endtime<=#ProdData.shiftend group by Machine,#ProdData.shiftstart)T1
Inner Join #ProdData on T1.Machine=#ProdData.Machineid  and T1.shiftstart=#ProdData.shiftstart

SELECT * FROM #downcode ORDER BY Slno 

Select PlantID,groupid,MachineID,ComponentID,OperationNo,OperatorID,Pdate,Shift,Cycletime,LUtime,ActualParts,OKParts,
--dbo.f_formattime(D1,'mm') as D1,dbo.f_formattime(D2,'mm') as D2,dbo.f_formattime(D3,'mm') as D3,dbo.f_formattime(D4,'mm') as D4,
--dbo.f_formattime(D5,'mm') as D5,dbo.f_formattime(D6,'mm') as D6,dbo.f_formattime(D7,'mm') as D7,
D1,D2,D3,D4,D5,D6,D7,D8,D9,D10,D11,D12,D13,D14,D15,
WorkingHours,
NoOfPcs from #ProdData order by PlantID,groupid,Pdate,MachineID

END
