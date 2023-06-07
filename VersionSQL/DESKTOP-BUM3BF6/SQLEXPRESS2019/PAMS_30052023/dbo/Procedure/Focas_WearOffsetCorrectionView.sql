/****** Object:  Procedure [dbo].[Focas_WearOffsetCorrectionView]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Focas_WearOffsetCorrectionView] '2015-02-07','2015-02-12','VANTAGE MSY 01','1','T1','W1','0','0','0','View'            
CREATE PROCEDURE [dbo].[Focas_WearOffsetCorrectionView]            
 @Fromdate datetime='',            
 @Todate datetime='',            
 @machineid nvarchar(50)='',            
 @Programno nvarchar(50)='',            
 @toolNo nvarchar(50)='',            
 @WearOffsetNo nvarchar(50)='',            
 @Focus_wearOffsetCorrectionid int= 0,            
 @measureddimension float = 0,            
 @newwearoffsetvalue float = 0,  
@WearOffsetValue Float =0,            
 @param nvarchar(50)='',
 @Result nvarchar(1000) = ''
         
          
AS            
BEGIN           
 -- SET NOCOUNT ON added to prevent extra result sets from             
 -- interfering with SELECT statements.             
 SET NOCOUNT ON;            
            
if @param ='View'            
Begin            
      
select ROW_NUMBER() OVER(ORDER BY F.ID DESC) as SlNo,t.ID as Focas_WearOffsetCorrectionID,t.machineId,F.MeasuredTime,            
t.ProgramNumber,t.ToolNumber,t.WearOffsetNumber,t.DefaultWearOffsetValue,F.MeasuredDimension,            
F.NewWearOffsetValue,t.NominalDimension,t.LowerLimit,t.UpperLimit,t.DefaultWearOffsetValue,t.OffsetLocation,F.WearoffsetValue ,F.Result     
from [dbo].[Focas_WearOffsetCorrectionMaster] t       
OUTER APPLY (select * from Focas_WearOffsetCorrection c where c.Focas_WearOffsetCorrectionID = t.ID AND       
@Fromdate<=c.MeasuredTime AND @Todate>=c.MeasuredTime ) F             
--where t.machineId=@machineId and t.ProgramNumber=@Programno and t.ToolNumber=@toolNo and t.WearOffsetNumber=@WearOffsetNo      
where t.machineId=@machineId and t.ProgramNumber=@Programno and t.WearOffsetNumber=@WearOffsetNo      
      
End            
        
if @param ='machine'            
Begin            
select MachineId from [machineinformation]  Where EthernetEnabled =1            
End             
            
if @param ='ProgramNo'            
Begin            
select distinct ProgramNumber from [dbo].[Focas_WearOffsetCorrectionMaster]            
where machineId=@machineId             
End             
            
if @param ='ToolNo'            
Begin            
select distinct ToolNumber from [dbo].[Focas_WearOffsetCorrectionMaster]            
where machineId=@machineId and ProgramNumber=@Programno             
End             
if @param ='WearOffsetNo'            
Begin            
select distinct WearOffsetNumber from [dbo].[Focas_WearOffsetCorrectionMaster]            
where machineId=@machineId and ProgramNumber=@Programno and ToolNumber=@toolNo             
End             
if @param='insert'            
Begin            
        
insert into Focas_WearOffsetCorrection(Focas_WearOffsetCorrectionID,MeasuredDimension,NewWearOffsetValue,WearOffsetValue,Result)            
values(@Focus_wearOffsetCorrectionid,@measureddimension,@newwearoffsetvalue,@WearOffsetValue,@Result)            
End          
END 
