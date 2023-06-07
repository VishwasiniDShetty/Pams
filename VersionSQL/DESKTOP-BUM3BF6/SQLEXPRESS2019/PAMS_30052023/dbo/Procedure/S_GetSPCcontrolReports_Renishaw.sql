/****** Object:  Procedure [dbo].[S_GetSPCcontrolReports_Renishaw]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[S_GetSPCcontrolReports_Renishaw] '2019-12-01 00:00:00','2019-12-31 00:00:00','vmc','22','110','''Perpendicularity_0_05_WRT_C_M1'',''Diameter_Datum_H_Above_dia_30''',''
[dbo].[S_GetSPCcontrolReports_Renishaw] '2019-12-01 00:00:00','2019-12-31 00:00:00','vmc','35','110','''Concentricity_0_2_WRT_E_M2_'',''Cylindricity__DAT_F_M10_'',''Cylindricity_0_010_DAT_A_M13_'',''Diameter_Datum_E_DH_'',''Diameter_Dia_30_cir_'',''Flatness__DAT_G_M4_'',''Flatness__OP_C_PLN_DIA_9_M7''',''
[dbo].[S_GetSPCcontrolReports_Renishaw] '2021-01-01 16:25:46','2021-10-30 16:25:46','vmc','CTQ-04C-103-023-L','10','',''

*/
CREATE PROCEDURE [dbo].[S_GetSPCcontrolReports_Renishaw]
@StartDate datetime='',
@EndDate datetime='',
@Machine nvarchar(50)='',
@Component nvarchar(50)='',
@Operation nvarchar(50)='',
--@Dimension nvarchar(50)='',
@CharacteristicID nvarchar(max)='',
@Param nvarchar(50)	 = ''

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

CREATE TABLE #Target
(
Date datetime,
Shift NVARCHAR(50),
Employee nvarchar(50),
Machine nvarchar(50),
SerialNumber nvarchar(50),
Component nvarchar(50),
Operation nvarchar(50),
CharacteristicID nvarchar(50),
Value float
)

create table #shift
(
ShiftDate DateTime,		
Shiftname nvarchar(20),
ShftSTtime DateTime,
ShftEndTime DateTime
)

DECLARE @startime DATETIME
DECLARE @Endtime DATETIME

SELECT @startime=@StartDate
SELECT @Endtime=@EndDate

while cast(@startime as date)<=cast(@Endtime as date)
begin
INSERT INTO #shift(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
		Exec s_GetShiftTime @startime,''
		SELECT @startime = DATEADD(DAY,1,@startime)
end

Declare @StrCharId nvarchar(max)
declare @strsql nvarchar(4000)

SET @StrCharId =''
 If isnull(@CharacteristicID,'') <> ''  
Begin  
 Select @StrCharId = ' And ( S.CharacteristicID in (' + @CharacteristicID + '))'  
End 

set @strsql=''
select @strsql = @strsql + 'INSERT INTO #Target (Date,Employee,Machine,SerialNumber,Component,Operation,CharacteristicID,Value)
select A.Timestamp,A.Opr,A.mc,A.SerialNumber, A.Comp, A.Opn, S.CharacteristicID ,A.Value from SPCAutodata A
inner join machineinformation M on M.machineid=A.Mc
inner join SPC_Characteristic S on A.Comp=S.ComponentID and A.Opn=S.OperationNo and A.Dimension=S.CharacteristicCode'
select @strsql = @strsql + ' where Comp = '''+@Component+''' and Opn = ''' +@Operation+ ''' and M.machineid = '''+@Machine+''' 
and (A.Timestamp >= ''' + convert(nvarchar(25),@StartDate,120) + ''' and A.Timestamp <= ''' + convert(nvarchar(25),@EndDate,120) + ''')'
print @strsql
select @strsql = @strsql + @StrCharId
print @strsql
exec (@strsql)

--select * from #Target
--return

IF exists(select * from #Target)
BEGIN
	Declare 
	@columns NVARCHAR(MAX) = '',
	@sql     NVARCHAR(MAX) = '';

	SELECT @columns = @columns + QUOTENAME(T.CharacteristicID) + ',' FROM #Target T group by T.CharacteristicID
	SET @columns = LEFT(@columns, LEN(@columns) - 1);

	print @columns

	set @sql = ''
	SET @sql ='
	SELECT Date,shiftname as Shift,Employee,Machine,SerialNumber,Component,Operation,'+ @columns +' FROM   
	(
	SELECT Date,shiftname, Employee,Machine,SerialNumber,Component,Operation,CharacteristicID,Value as s1
	FROM #Target cross join #shift where date>=ShftSTtime and date<=ShftEndTime
	) AS t 
	PIVOT(max(s1) FOR CharacteristicID IN ('+ @columns + ')) AS pivot_table'

	EXECUTE sp_executesql @sql;

END
END
