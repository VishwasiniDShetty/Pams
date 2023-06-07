/****** Object:  Procedure [dbo].[s_GetAggDrilldownRejectionData_Chart]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[s_GetAggDrilldownRejectionData_Chart]   '2019-05-01','2019-12-30','','','APG-08','''575617/a'',''223125-11040-A'',''sample'',''223125-11040-A''','','','','',''
[dbo].[s_GetAggDrilldownRejectionData_Chart]   '2019-09-05','2019-09-07','','','APG-08','''575617/a'',''223125-11040-A'',''sample'',''223125-11040-A''','','','','',''
[dbo].[s_GetAggDrilldownRejectionData_Chart]   '2019-11-07','2019-12-29','','','','''570551/e'',''340312690''','','','','','OD UNDER SIZE,Step Difference Problem'

--[dbo].[s_GetAggDrilldownRejectionData_Chart]   '2019-01-01','2019-12-30','','','','','','','','',''
--[dbo].[s_GetAggDrilldownRejectionData_Chart]   '2019-01-01','2019-12-30','','','','','','','','',''
*/

CREATE  PROCEDURE [dbo].[s_GetAggDrilldownRejectionData_Chart]      
@StartDate As DateTime, 
@EndDate As DateTime,     
@PlantID As NVarChar(50)='',  
@Groupid as nvarchar(50)='',        
@MachineID As nvarchar(50)='',  
@Component As nvarchar(max)='',  -- multiple
@Operation As nvarchar(max)='',  -- multiple
@Rejcatagory nvarchar(50)='',
@RejSubcatagory nvarchar(50)='',  
@RejDescription nvarchar(50)='',
@Rejcode as nvarchar(4000)='',   --multiple
@Param nvarchar(100)=''   --ByRejCategory,ByRejcode or ''

AS      
BEGIN      
----------------------------------------------------------------------------------------------------------      
--* Declaration of Variables *--      
----------------------------------------------------------------------------------------------------------      
Declare @Strsql nvarchar(4000)      
Declare @timeformat AS nvarchar(12)      
      
Declare @Strmachine nvarchar(4000)      
Declare @StrPlantID AS NVarchar(255)      
Declare @CurDate As DateTime    
Declare @StrGroupid as nvarchar(255)  
Declare @StrRejCategory as nvarchar(4000)  
Declare @StrRejcode as nvarchar(4000)  
Declare @StrComponent nvarchar(max)      
Declare @StrOperation nvarchar(max)      
Declare @StrRejSubCategory as nvarchar(4000)  
Declare @StrRejDescription as nvarchar(4000)  

    
Select @Strsql = ''      
Select @Strmachine = ''      
Select @StrPlantID=''      
Select @StrGroupid=''      
Select @StrRejCategory=''      
Select @StrRejcode=''      
Select @StrComponent=''  
Select @StrOperation=''  
Select @StrRejSubCategory=''
Select @StrRejDescription=''

create table #Proddata
(
 
	Machineid nvarchar(50),
	ComponentID nvarchar(50),
	RejSubcategory nvarchar(50),
	RejCategory nvarchar(50),
	RejDesciption nvarchar(50),
	RejCode nvarchar(100),
	RejCount float default 0,
	TotalRejcount float default 0,

	CategoryTotal float default 0,
	CompTotal float default 0,
	SubCategoryTotal float default 0,
	DescriptionTotal float default 0,
	RejCodeTotal float default 0
)

 CREATE TABLE #MachineInfo     
(    
MachineID nvarchar(50)  
)  

DECLARE @joinedrej NVARCHAR(4000)  
select @joinedrej = coalesce(@joinedrej + ',''', '''')+item+'''' from [SplitStrings](@Rejcode, ',')     
if @joinedrej = ''''''  
set @joinedrej = ''  

 If isnull(@PlantID,'') <> ''  
Begin  
Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )'  
End  
  
if isnull(@machineid, '') <> ''  
begin   
select @strmachine =   ' and ( machineinformation.machineid = N''' + @machineid + ''' )'  
end  
  
 If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( PlantMachineGroups.GroupID = N''' + @GroupID + ''')'  
End   

if isnull(@Rejcode,'')  <> '' 
Begin
select @StrRejcode = ' and ( rejectioncodeinformation.rejectionid in (' + @joinedrej +'))'  
END 

if isnull(@Component, '') <> ''  
begin   
select @StrComponent =   ' and ( ShiftProductionDetails.ComponentID in (' + @Component +'))'  
end  

 If isnull(@Rejcatagory,'') <> ''  
Begin  
 Select @StrRejCategory = ' And ( rejectioncodeinformation.Catagory = N''' + @Rejcatagory + ''')'  
End 

If isnull(@RejSubcatagory,'') <> ''  
Begin  
 Select @StrRejSubCategory = ' And ( rejectioncodeinformation.Subcategory = N''' + @RejSubcatagory + ''')'  
End 

 If isnull(@RejDescription,'') <> ''  
Begin  
 Select @StrRejDescription = ' And ( rejectioncodeinformation.RejectionDescription = N''' + @RejDescription + ''')'  
End 


Select @Strsql=''
Select @strsql=@strsql+'Insert into #Proddata(Machineid,ComponentID,RejCategory,RejCode,RejSubcategory,RejDesciption)
Select Distinct MachineInformation.Machineid,ShiftProductionDetails.ComponentID,rejectioncodeinformation.Catagory,rejectioncodeinformation.rejectionid,rejectioncodeinformation.Subcategory,rejectioncodeinformation.RejectionDescription 
from MachineInformation
Left Outer Join PlantMachine ON MachineInformation.MachineID=PlantMachine.MachineID
Left Outer Join PlantMachineGroups ON MachineInformation.MachineID=PlantMachineGroups.MachineID
cross join ShiftProductionDetails
cross join rejectioncodeinformation '
Select @Strsql =@Strsql+' Where MachineInformation.MachineID Is Not NULL'  
Select @Strsql =@Strsql+@StrPlantID+@Strmachine+@StrGroupid+@StrRejCategory+@StrRejcode+@StrRejSubCategory+@StrRejDescription+@StrComponent
Select @Strsql =@Strsql+' order by MachineInformation.Machineid,rejectioncodeinformation.Catagory,rejectioncodeinformation.Subcategory,rejectioncodeinformation.RejectionDescription,rejectioncodeinformation.rejectionid'
print @Strsql  
Exec (@Strsql)  


If isnull(@PlantID,'') <> ''      
Begin      
 Select @StrPlantID = ' And (ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'      
End      
      
If isnull(@Machineid,'') <> ''      
Begin      
 Select @Strmachine = ' And (ShiftProductionDetails.MachineID = N''' + @MachineID + ''')'      
End 

--if isnull(@Component, '') <> ''  
--begin   
--select @StrComponent =   ' and ( ShiftProductionDetails.ComponentID = N''' + @Component + ''' )'  
--end  

if isnull(@Component, '') <> ''  
begin   
select @StrComponent =   ' and ( ShiftProductionDetails.ComponentID in (' + @Component +'))'  
end  

--if isnull(@Operation, '') <> ''  
--begin   
--select @StrOperation =   ' and ( ShiftProductionDetails.operationno = N''' + @Operation + ''' )'  
--end  

if isnull(@Operation, '') <> ''  
begin   
select @StrOperation =   ' and ( ShiftProductionDetails.operationno in (' + @Operation +'))'  
end 

  Select @Strsql='' 
 Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'  
 Select @Strsql = @Strsql+' FROM('  
 Select @Strsql = @Strsql+' Select ShiftProductionDetails.MachineID,ShiftProductionDetails.ComponentID,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails 
							Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where convert(nvarchar(10),ShiftProductionDetails.Pdate,120)>=''' + convert(nvarchar(10),@StartDate,120)+ ''' and convert(nvarchar(10),ShiftProductionDetails.Pdate,120)<=''' + convert(nvarchar(10),@EndDate,120)+ '''  '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrComponent + @StrOperation
 Select @Strsql = @Strsql+' Group By ShiftProductionDetails.MachineID,ShiftProductionDetails.ComponentID'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID and T2.ComponentID=#proddata.ComponentID'  
 Print @Strsql  
 Exec(@Strsql) 

 update #Proddata set TotalRejcount = T.rejcount from
 (Select SUM(RejCount) as rejcount from #proddata)T

 Update #Proddata set CategoryTotal=T1.RejQty
 from(
	Select distinct RejCategory,SUM(RejCount) as RejQty from #proddata 
	group by RejCategory 
 )T1 inner join #Proddata T2 on T1.RejCategory=T2.RejCategory


  Update #Proddata set CompTotal=T1.RejQty
 from(
	Select RejCategory,ComponentID,SUM(RejCount) as RejQty from #proddata 
	group by RejCategory,ComponentID 
 )T1 inner join #Proddata T2 on T1.RejCategory=T2.RejCategory and T1.ComponentID=T2.ComponentID

 Update #Proddata set SubCategoryTotal=T1.RejQty
 from(
	Select RejCategory,ComponentID,RejSubcategory,SUM(RejCount) as RejQty from #proddata 
	group by RejCategory,ComponentID,RejSubcategory 
 )T1 inner join #Proddata T2 on T1.RejCategory=T2.RejCategory and T1.ComponentID=T2.ComponentID and T1.RejSubcategory=T2.RejSubcategory

 Update #Proddata set DescriptionTotal=T1.RejQty
 from(
	Select RejCategory,ComponentID,RejDesciption,RejSubcategory,SUM(RejCount) as RejQty from #proddata 
	group by RejCategory,ComponentID,RejDesciption,RejSubcategory 
 )T1 inner join #Proddata T2 on T1.RejCategory=T2.RejCategory and T1.ComponentID=T2.ComponentID and T1.RejSubcategory=T2.RejSubcategory and T1.RejDesciption=T2.RejDesciption

 Update #Proddata set RejCodeTotal=T1.RejQty
 from(
	Select RejCategory,ComponentID,RejSubcategory,RejDesciption,RejCode,SUM(RejCount) as RejQty from #proddata 
	group by RejCategory,ComponentID,RejSubcategory,RejDesciption,RejCode
 )T1 inner join #Proddata T2 on T1.RejCategory=T2.RejCategory and T1.ComponentID=T2.ComponentID and T1.RejSubcategory=T2.RejSubcategory and T1.RejDesciption=T2.RejDesciption and T1.RejCode=T2.RejCode


 select distinct RejCategory,ComponentID,RejSubcategory,RejDesciption,RejCode,CategoryTotal,CompTotal,SubCategoryTotal,DescriptionTotal,RejCodeTotal from #Proddata
 order by RejCategory,ComponentID,RejSubcategory,RejDesciption,RejCode


END 
