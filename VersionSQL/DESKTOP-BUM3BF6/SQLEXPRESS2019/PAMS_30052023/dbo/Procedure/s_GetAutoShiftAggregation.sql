/****** Object:  Procedure [dbo].[s_GetAutoShiftAggregation]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************************************************************************************
NR0083 - Geetanjali Kore - 6/feb/2013 :: Created Wrap up Procedure for AutoAggregation Service,Which calls the procedure "s_Push_Prodn_Down_ShiftAggregation". 
ER0435 - SwathiKS - 01/Jun/2016 :: to introduce Plantid as input.
*************************************************************************************************************************************/
--s_GetAutoShiftAggregation '3','','PAMS'
CREATE Procedure [dbo].[s_GetAutoShiftAggregation]
@Day int='',
@Shift nvarchar(20)='',
@PlantID As NvarChar(50) --ER0435

As
Begin

Declare @totime as datetime
Declare @fromtime as datetime
Declare @shiftname as nvarchar(20)
Declare @Datepart as nvarchar(50)

----ER0435 Added From Here
--set @fromtime=(Select isnull(max(Endtime),(Select min(sttime)from autodata)) from shiftaggtrail) 
--set @fromtime=(Select isnull(max(Endtime),(Select min(sttime)from autodata
--                            inner join machineinformation M on autodata.mc=M.interfaceid
--                            inner join plantmachine PM on M.machineid=PM.MachineID
--                            where PM.PlantID=@PlantID)) from shiftaggtrail 
--                            inner join machineinformation M on ShiftAggTrail.machineid=M.machineid
--                            inner join plantmachine PM on M.machineid=PM.MachineID
--                            where PM.PlantID=@PlantID)
----ER0435 Added Till Here

Declare @MaxSttime as datetime
Declare @MinSttime as datetime

IF NOT EXISTS(Select * from shiftaggtrail inner join machineinformation M on shiftaggtrail.Machineid=M.machineid inner join plantmachine PM on M.machineid=PM.MachineID where PM.PlantID=@PlantID)
BEGIN
 select @MinSttime= min(A.sttime)  From Autodata A
 inner join machineinformation M on A.mc=M.interfaceid
 inner join plantmachine PM on M.machineid=PM.MachineID
 where PM.PlantID=@PlantID
END

-- Select @fromtime=min(TS) from
-- (Select M.Machineid,isnull(max(Endtime),@MinSttime)as TS from shiftaggtrail
--inner join machineinformation M on shiftaggtrail.Machineid=M.machineid
--inner join plantmachine PM on M.machineid=PM.MachineID
--where PM.PlantID=@PlantID group by M.machineid)T

 Select @fromtime=isnull(max(Endtime),@MinSttime) from shiftaggtrail
inner join machineinformation M on shiftaggtrail.Machineid=M.machineid
inner join plantmachine PM on M.machineid=PM.MachineID
where PM.PlantID=@PlantID

If @day>0
Begin

	print  @fromtime
	set @totime=dateadd(day,@day-1,@fromtime)
	set @totime=(SELECT CONVERT(VARCHAR(10),@totime,111))
	set @totime=@totime+' 23:59:59'
	print @totime

	exec [s_Push_Prodn_Down_ShiftAggregation] @fromtime,'','',@PlantID,'PUSH','',@totime ----ER0435 
End

End
