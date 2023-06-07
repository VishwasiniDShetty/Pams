/****** Object:  Procedure [dbo].[S_GetOffSetCorrection_Imtex]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************************************************************************
-- =============================================
-- Author:		Anjana  C V
-- Create date: 16 Jan 2019
-- Modified date: 16 Jan 2019
-- Description:	Get OffSet Correction SPC for Imtex
-- [S_GetOffSetCorrection_Imtex] '','',''
-- [S_GetOffSetCorrection_Imtex] '2020-01-05 17:17:19.000','2020-01-06 17:17:19.000','','','Maini'
[S_GetOffSetCorrection_Imtex] '2021-10-01 00:00:00.000','2021-10-30 00:00:00.000','','','1st-Setup','Maini'

-- =============================================
**************************************************************************************************/
CREATE  PROCEDURE [dbo].[S_GetOffSetCorrection_Imtex]
@StartTime datetime,
@EndTime datetime,
@ShiftName nvarchar(10) = '',
@MachineId as nvarchar(50),
@ComponentID AS NVARCHAR(50)='',
@Param nvarchar(50)=''
AS
BEGIN

--SELECT ROW_NUMBER() OVER (ORDER BY TimeStamp desc) AS CycleNo,TimeStamp as MeasuredTime,WearoffSetNumber,MeasureDimension,CorrectionValue from SPCAutodata A
--inner join Machineinformation on A.mc=Machineinformation.interfaceid
--where Machineinformation.machineid = @MachineId  and (timestamp >= @StartTime and timestamp <= @EndTime)
--order by TimeStamp desc

IF (@Param='' or ISNULL(@Param,'')='')
BEGIN
	if  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
	BEGIN
		--SELECT ROW_NUMBER() OVER (ORDER BY A.TimeStamp desc) AS CycleNo,A.TimeStamp as MeasuredTime, A.Dimension,A.WearOffsetNumber,
		--A.Value as MeasureDimension,A.CorrectionValue,A.MeasureDimension As MeanValue,E.Employeeid,A.ToolChangeTime,A.IgnoreForCPCPK from SPCAutodata A
		--inner join Machineinformation on A.mc=Machineinformation.interfaceid
		--Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
		--inner join SPC_Characteristic SP on Machineinformation.machineid=SP.machineid and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
		--and A.Comp=SP.ComponentID
		--where (Machineinformation.machineid = @MachineId or ISNULL(@MachineId,'')='') AND (SP.ComponentID=@ComponentID OR ISNULL(@ComponentID,'')='') and (timestamp >= @StartTime and timestamp <= @EndTime)
		--order by TimeStamp desc

		SELECT ROW_NUMBER() OVER (ORDER BY A.TimeStamp desc) AS CycleNo,A.TimeStamp as MeasuredTime, A.Dimension,A.WearOffsetNumber,
		A.Value as MeasureDimension,A.CorrectionValue,A.MeasureDimension As MeanValue,E.Employeeid,A.ToolChangeTime,A.IgnoreForCPCPK from SPCAutodata A
		inner join Machineinformation on A.mc=Machineinformation.interfaceid
		inner join componentinformation on a.Comp=componentinformation.InterfaceID
		Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
		inner join SPC_Characteristic SP on Machineinformation.machineid=SP.machineid and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
		and componentinformation.componentid=SP.ComponentID
		where (Machineinformation.machineid = @MachineId or ISNULL(@MachineId,'')='') AND (SP.ComponentID=@ComponentID OR ISNULL(@ComponentID,'')='') and (timestamp >= @StartTime and timestamp <= @EndTime)
		order by TimeStamp desc

	END
	ELSE
	BEGIN
		SELECT ROW_NUMBER() OVER (ORDER BY A.TimeStamp desc) AS CycleNo,A.TimeStamp as MeasuredTime, A.Dimension,A.WearoffSetNumber,
		A.Value as MeasureDimension,A.CorrectionValue,A.MeasureDimension As MeanValue,E.Employeeid,A.ToolChangeTime,A.IgnoreForCPCPK from SPCAutodata A
		inner join Machineinformation on A.mc=Machineinformation.interfaceid
		Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
		inner join Componentinformation CI on CI.interfaceid=A.comp
		inner join Componentoperationpricing CO on CO.interfaceid=A.opn and CO.machineid=Machineinformation.machineid and CO.componentid=CI.Componentid
		inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.operationno=SP.operationno and A.Dimension=SP.CharacteristicID
		and SP.ComponentID=CI.componentid
		where (Machineinformation.machineid = @MachineId or ISNULL(@MachineId,'')='') AND (ci.componentid=@ComponentID OR ISNULL(@ComponentID,'')='') and (timestamp >= @StartTime and timestamp <= @EndTime)
		order by TimeStamp desc
	END
END

IF @Param='Maini'
BEGIN

CREATE TABLE #spcautodata
(
mc NVARCHAR(50),
comp NVARCHAR(50),
opn NVARCHAR(50),
opr NVARCHAR(50),
TimeStamp DATETIME, 
Dimension nvarchar(50),
WearOffsetNumber NVARCHAR(50),
value FLOAT,
correctionvalue NVARCHAR(50),
Measuredimension NVARCHAR(50),
OvalityMax nvarchar(50),
OvalityMin nvarchar(50),
ToolChangeTime datetime,
IgnoreForCPCPK Bit
)

 CREATE TABLE #ShiftTemp     
 (    
	 ShiftDate datetime,    
	 ShiftName nvarchar(20),    
	 ShiftStart datetime,    
	 ShiftEnd datetime    
 ) 
Declare @ST datetime
SET @ST= @StartTime

 While(@ST <= @EndTime)  
 BEGIN  
	 Insert into #ShiftTemp(ShiftDate,ShiftName, ShiftStart, ShiftEnd)  
	 Exec s_GetShiftTime @ST,'' 
	 SELECT @ST = Dateadd(Day,1,@ST)  
 END 

 INSERT INTO #spcautodata(mc,comp,opn,opr,TimeStamp,Dimension,WearOffsetNumber,value,correctionvalue,Measuredimension,OvalityMax,OvalityMin,ToolChangeTime,IgnoreForCPCPK)
 SELECT mc,comp,opn,opr,Timestamp,Dimension,WearOffSetNumber,Value,CorrectionValue,MeasureDimension,OvalityMax,OvalityMin,S.ToolChangeTime,S.IgnoreForCPCPK  FROM dbo.SPCAutodata s
 INNER JOIN dbo.machineinformation m ON m.InterfaceID=s.Mc
 WHERE (m.machineid=@MachineId OR ISNULL(@MachineId,'')='') 
 AND (TimeStamp>=@StartTime AND TimeStamp<=@EndTime)

 if (select isnull(valueintext,'N') from ShopDefaults where Parameter='EnableOvality')='Y'
BEGIN
if  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
	BEGIN
		--SELECT ROW_NUMBER() OVER (ORDER BY A.TimeStamp desc) AS CycleNo, machineinformation.machineid,sp.ComponentID,S.ShiftDate,S.ShiftName,A.TimeStamp as MeasuredTime, A.Dimension,A.WearOffsetNumber,
		--A.Value as MeasureDimension,A.CorrectionValue,A.MeasureDimension As MeanValue,E.Employeeid,
		--SP.LSL,SP.USL,(Case When A.Value >= SP.LSL and A.value <= SP.USL then 0
		--				    when A.Value < SP.LSL and A.value > SP.USL Then 1
		--					else 1
		--				END) as ValueOutOfRange,A.ToolChangeTime,A.IgnoreForCPCPK,A.OvalityMax AS MaxVal,a.OvalityMin as MinVal,round((cast(A.OvalityMax as float)-cast(a.OvalityMin as float)),2) as Ovality
		--from #spcautodata A
		--inner join Machineinformation on A.mc=Machineinformation.interfaceid
		--Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
		--inner join SPC_Characteristic SP on Machineinformation.machineid=SP.machineid and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
		--and A.Comp=SP.ComponentID
		--CRoss join #ShiftTemp S
		--where (Machineinformation.machineid = @MachineId or ISNULL(@MachineId,'')='') AND(sp.ComponentID=@ComponentID OR ISNULL(@ComponentID,'')='') and (timestamp >= S.ShiftStart and timestamp <= S.ShiftEnd) and (S.ShiftName = @ShiftName or ISNULL(@ShiftName, '')='') 
		--order by TimeStamp desc

		SELECT ROW_NUMBER() OVER (ORDER BY A.TimeStamp desc) AS CycleNo, machineinformation.machineid,sp.ComponentID,S.ShiftDate,S.ShiftName,A.TimeStamp as MeasuredTime, A.Dimension,A.WearOffsetNumber,
		A.Value as MeasureDimension,A.CorrectionValue,A.MeasureDimension As MeanValue,E.Employeeid,
		SP.LSL,SP.USL,(Case When A.Value >= SP.LSL and A.value <= SP.USL then 0
						    when A.Value < SP.LSL and A.value > SP.USL Then 1
							else 1
						END) as ValueOutOfRange,A.ToolChangeTime,A.IgnoreForCPCPK,A.OvalityMax AS MaxVal,a.OvalityMin as MinVal,round((cast(A.OvalityMax as float)-cast(a.OvalityMin as float)),2) as Ovality
		from #spcautodata A
		inner join Machineinformation on A.mc=Machineinformation.interfaceid
		inner join componentinformation on a.Comp=componentinformation.InterfaceID
		Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
		inner join SPC_Characteristic SP on Machineinformation.machineid=SP.machineid and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
		and componentinformation.componentid=SP.ComponentID
		CRoss join #ShiftTemp S
		where (Machineinformation.machineid = @MachineId or ISNULL(@MachineId,'')='') AND(sp.ComponentID=@ComponentID OR ISNULL(@ComponentID,'')='') and (timestamp >= S.ShiftStart and timestamp <= S.ShiftEnd) and (S.ShiftName = @ShiftName or ISNULL(@ShiftName, '')='') 
		order by TimeStamp desc

	END
	ELSE
	BEGIN
		SELECT ROW_NUMBER() OVER (ORDER BY A.TimeStamp desc) AS CycleNo, machineinformation.machineid,sp.ComponentID, S.ShiftDate,S.ShiftName,A.TimeStamp as MeasuredTime, A.Dimension,A.WearoffSetNumber,
		A.Value as MeasureDimension,A.CorrectionValue,A.MeasureDimension As MeanValue,E.Employeeid,
		SP.LSL,SP.USL,(Case When A.Value >= SP.LSL and A.value <= SP.USL then 0
							when A.Value < SP.LSL and A.value > SP.USL Then 1
							else 1
						END) as ValueOutOfRange,A.ToolChangeTime,A.IgnoreForCPCPK,A.OvalityMax AS MaxVal,a.OvalityMin as MinVal,round((cast(A.OvalityMax as float)-cast(a.OvalityMin as float)),2) as Ovality
		from #spcautodata A
		inner join Machineinformation on A.mc=Machineinformation.interfaceid
		Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
		inner join Componentinformation CI on CI.interfaceid=A.comp
		inner join Componentoperationpricing CO on CO.interfaceid=A.opn and CO.machineid=Machineinformation.machineid and CO.componentid=CI.Componentid
		inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.operationno=SP.operationno and A.Dimension=SP.CharacteristicID
		and SP.ComponentID=CI.componentid
		CRoss join #ShiftTemp S
		where (Machineinformation.machineid = @MachineId or ISNULL(@MachineId,'')='') AND (ci.componentid=@ComponentID OR ISNULL(@ComponentID,'')='') and (timestamp >= S.ShiftStart and timestamp <= S.ShiftEnd) and (S.ShiftName = @ShiftName or ISNULL(@ShiftName, '')='') 
		order by TimeStamp desc
	end
END



if (select isnull(valueintext,'N') from ShopDefaults where Parameter='EnableOvality')='N'
BEGIN
if  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
	BEGIN
		SELECT ROW_NUMBER() OVER (ORDER BY A.TimeStamp desc) AS CycleNo, machineinformation.machineid,sp.ComponentID,S.ShiftDate,S.ShiftName,A.TimeStamp as MeasuredTime, A.Dimension,A.WearOffsetNumber,
		A.Value as MeasureDimension,A.CorrectionValue,A.MeasureDimension As MeanValue,E.Employeeid,
		SP.LSL,SP.USL,(Case When A.Value >= SP.LSL and A.value <= SP.USL then 0
						    when A.Value < SP.LSL and A.value > SP.USL Then 1
							else 1
						END) as ValueOutOfRange,A.ToolChangeTime,A.IgnoreForCPCPK
		from #spcautodata A
		inner join Machineinformation on A.mc=Machineinformation.interfaceid
		inner join componentinformation on a.Comp=componentinformation.InterfaceID
		Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
		inner join SPC_Characteristic SP on Machineinformation.machineid=SP.machineid and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
		and componentinformation.componentid=SP.ComponentID
		CRoss join #ShiftTemp S
		where (Machineinformation.machineid = @MachineId or ISNULL(@MachineId,'')='') AND(sp.ComponentID=@ComponentID OR ISNULL(@ComponentID,'')='') and (timestamp >= S.ShiftStart and timestamp <= S.ShiftEnd) and (S.ShiftName = @ShiftName or ISNULL(@ShiftName, '')='') 
		order by TimeStamp desc
	END
	ELSE
	BEGIN
		SELECT ROW_NUMBER() OVER (ORDER BY A.TimeStamp desc) AS CycleNo, machineinformation.machineid,sp.ComponentID, S.ShiftDate,S.ShiftName,A.TimeStamp as MeasuredTime, A.Dimension,A.WearoffSetNumber,
		A.Value as MeasureDimension,A.CorrectionValue,A.MeasureDimension As MeanValue,E.Employeeid,
		SP.LSL,SP.USL,(Case When A.Value >= SP.LSL and A.value <= SP.USL then 0
							when A.Value < SP.LSL and A.value > SP.USL Then 1
							else 1
						END) as ValueOutOfRange,A.ToolChangeTime,A.IgnoreForCPCPK
		from #spcautodata A
		inner join Machineinformation on A.mc=Machineinformation.interfaceid
		Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
		inner join Componentinformation CI on CI.interfaceid=A.comp
		inner join Componentoperationpricing CO on CO.interfaceid=A.opn and CO.machineid=Machineinformation.machineid and CO.componentid=CI.Componentid
		inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.operationno=SP.operationno and A.Dimension=SP.CharacteristicID
		and SP.ComponentID=CI.componentid
		CRoss join #ShiftTemp S
		where (Machineinformation.machineid = @MachineId or ISNULL(@MachineId,'')='') AND (ci.componentid=@ComponentID OR ISNULL(@ComponentID,'')='') and (timestamp >= S.ShiftStart and timestamp <= S.ShiftEnd) and (S.ShiftName = @ShiftName or ISNULL(@ShiftName, '')='') 
		order by TimeStamp desc
	end
end
end

END
