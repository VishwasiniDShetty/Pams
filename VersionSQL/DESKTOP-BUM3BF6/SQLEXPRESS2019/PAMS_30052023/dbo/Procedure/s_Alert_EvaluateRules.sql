/****** Object:  Procedure [dbo].[s_Alert_EvaluateRules]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Alert_EvaluateRules] '06-May-2017 23:00:00','','r1','PartsCount','View' --For the Given RULE
--[dbo].[Alert_EvaluateRules] '06-May-2017 23:00:00','','','PartsCount','View' --For the Given Parameter

CREATE PROCEDURE [dbo].[s_Alert_EvaluateRules]
@Date Datetime,
@Shift nvarchar(50)='',
@RuleID nvarchar(50)='',
@ParameterID nvarchar(50)='',
@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

create table #temp
(
Parameter nvarchar(100),
RuleID nvarchar(100),
MachineID nvarchar(50),
Users nvarchar(50),
Shift nvarchar(50),
ShiftID int,
Email nvarchar(100),
MobileNo nvarchar(50),
Compare varchar(50),
Threshold int,
ThresholdUnit nvarchar(50),
[Description] [nvarchar](100),
EvaluateEvery [int],
EvaluateEveryUnit [nvarchar](50),
[Enabled] [bit],
AppliesTo [nvarchar](500),
EmailSubjectTemplate [nvarchar](500),
EmailBodyTemplate [nvarchar](500),
SMSTextTemplate [nvarchar](500),
SMSEnabled [bit],
EmailEnabled [bit] ,
flag_day Int
)

Create Table #ShiftTemp         
(
 PDate datetime,         
 ShiftName nvarchar(20),         
 ShiftID nvarchar(20),         
 ShiftStart datetime,         
 Shiftend Datetime 
)

if @param='View'
BEGIN	

INSERT INTO #Shifttemp(PDate,Shiftname,Shiftstart,Shiftend,ShiftID)         
Exec [s_GetCurrentShiftTime] @date,''    

If ISNULL(@RuleID,'')<>''
Begin
	insert into #temp (Parameter,RuleID,Compare,Threshold,ThresholdUnit,Machineid,Users,Shift,ShiftID,Email,MobileNo,[Description],EvaluateEvery,EvaluateEveryUnit,[Enabled],AppliesTo,EmailSubjectTemplate,EmailBodyTemplate,SMSTextTemplate,SMSEnabled,EmailEnabled) 
	select distinct AR.Parameter,AR.Ruleid,AR.Compare,AR.Threshold,AR.ThresholdUnit,ARM.Machineid,ARU.UserID,#ShiftTemp.ShiftName,AU.Shiftid,AC.Email1,AC.Phone1,
	AR.[Description],AR.[EvaluateEvery],AR.[EvaluateEveryUnit],AR.[Enabled],AR.[AppliesTo],AR.[EmailSubjectTemplate],AR.[EmailBodyTemplate],AR.[SMSTextTemplate],AR.[SMSEnabled],AR.[EmailEnabled] from Alert_Rules AR
    inner join 	Alert_AssignRulesToMachine ARM  on ARM.Ruleid=AR.Ruleid
	inner join Alert_AssignRulesToUser ARU on ARM.Machineid=ARU.Machineid and ARM.Ruleid=ARU.Ruleid
	inner join Alert_Consumers AC on ARU.userid=AC.Userid 
	inner join Alert_UserShiftAllocation AU  on ARU.userid=AU.Userid 
	inner join #ShiftTemp on AU.Shiftid=#ShiftTemp.Shiftid
	where (AR.Ruleid=@Ruleid) and convert(nvarchar(10),AU.Shiftdate,120)=convert(nvarchar(10),#ShiftTemp.Pdate,120) 
	Order by ARM.Machineid,ARU.UserID,AU.ShiftID,#ShiftTemp.ShiftName
End
Else
Begin
	insert into #temp (Parameter,RuleID,Compare,Threshold,ThresholdUnit,Machineid,Users,Shift,ShiftID,Email,MobileNo,[Description],EvaluateEvery,EvaluateEveryUnit,[Enabled],AppliesTo,EmailSubjectTemplate,EmailBodyTemplate,SMSTextTemplate,SMSEnabled,EmailEnabled) 
	select distinct AR.Parameter,AR.Ruleid,AR.Compare,AR.Threshold,AR.ThresholdUnit,ARM.Machineid,ARU.UserID,#ShiftTemp.ShiftName,AU.Shiftid,AC.Email1,AC.Phone1,
	AR.[Description],AR.[EvaluateEvery],AR.[EvaluateEveryUnit],AR.[Enabled],AR.[AppliesTo],AR.[EmailSubjectTemplate],AR.[EmailBodyTemplate],AR.[SMSTextTemplate],AR.[SMSEnabled],AR.[EmailEnabled] from Alert_Rules AR
    inner join 	Alert_AssignRulesToMachine ARM  on ARM.Ruleid=AR.Ruleid
	inner join Alert_AssignRulesToUser ARU on ARM.Machineid=ARU.Machineid and ARM.Ruleid=ARU.Ruleid
	inner join Alert_Consumers AC on ARU.userid=AC.Userid 
	inner join Alert_UserShiftAllocation AU  on ARU.userid=AU.Userid 
	inner join #ShiftTemp on AU.Shiftid=#ShiftTemp.Shiftid
	where (AR.Parameter=@ParameterID) and convert(nvarchar(10),AU.Shiftdate,120)=convert(nvarchar(10),#ShiftTemp.Pdate,120) 
	Order by ARM.Machineid,ARU.UserID,AU.ShiftID,#ShiftTemp.ShiftName
end


select * from #temp

END
end
