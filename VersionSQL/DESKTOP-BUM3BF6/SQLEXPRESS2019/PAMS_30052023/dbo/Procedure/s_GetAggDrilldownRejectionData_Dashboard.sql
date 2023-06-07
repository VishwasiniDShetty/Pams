/****** Object:  Procedure [dbo].[s_GetAggDrilldownRejectionData_Dashboard]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetAggDrilldownRejectionData_Dashboard]   '2019-01-01','2019-12-30','','','','','','','','','','ByRejCategory'
--[dbo].[s_GetAggDrilldownRejectionData_Dashboard]   '2019-01-01','2019-12-30','','','','','','Dimensional Defects','','','','ByRejSubCategory'
--[dbo].[s_GetAggDrilldownRejectionData_Dashboard]   '2019-01-01','2019-12-30','','','','','','','','','','ByRejDesciption'
--[dbo].[s_GetAggDrilldownRejectionData_Dashboard]   '2019-01-01','2019-12-30','','','','','','','','','','ByRejcode'


CREATE  PROCEDURE [dbo].[s_GetAggDrilldownRejectionData_Dashboard]      
@StartDate As DateTime, 
@EndDate As DateTime,     
@PlantID As NVarChar(50)='',  
@Groupid as nvarchar(50)='',        
@MachineID As nvarchar(50)='',  
@Component As nvarchar(max)='',  
@Operation As nvarchar(max)='',  
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
	RejSubcategory nvarchar(50),
	RejCategory nvarchar(50),
	RejDesciption nvarchar(50),
	RejCode nvarchar(100),
	RejCount float default 0,
	TotalRejcount float default 0
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
Select @strsql=@strsql+'Insert into #Proddata(Machineid,RejCategory,RejCode,RejSubcategory,RejDesciption)
Select Distinct MachineInformation.Machineid,rejectioncodeinformation.Catagory,rejectioncodeinformation.rejectionid,rejectioncodeinformation.Subcategory,rejectioncodeinformation.RejectionDescription from MachineInformation
Left Outer Join PlantMachine ON MachineInformation.MachineID=PlantMachine.MachineID
Left Outer Join PlantMachineGroups ON MachineInformation.MachineID=PlantMachineGroups.MachineID
cross join rejectioncodeinformation '
Select @Strsql =@Strsql+' Where MachineInformation.MachineID Is Not NULL'  
Select @Strsql =@Strsql+@StrPlantID+@Strmachine+@StrGroupid+@StrRejCategory+@StrRejcode+@StrRejSubCategory+@StrRejDescription
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
 Select @Strsql = @Strsql+' Select ShiftProductionDetails.MachineID,ShiftRejectiondetails.Rejection_Reason as Rejcode,Sum(isnull(ShiftRejectionDetails.Rejection_Qty,0))as Rej'  
 Select @Strsql = @Strsql+' From ShiftProductionDetails 
							Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'  
 Select @Strsql = @Strsql+' Where convert(nvarchar(10),ShiftProductionDetails.Pdate,120)>=''' + convert(nvarchar(10),@StartDate,120)+ ''' and convert(nvarchar(10),ShiftProductionDetails.Pdate,120)<=''' + convert(nvarchar(10),@EndDate,120)+ '''  '  
 Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrComponent + @StrOperation
 Select @Strsql = @Strsql+' Group By ShiftProductionDetails.MachineID,ShiftRejectiondetails.Rejection_Reason'  
 Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.MachineID=T2.MachineID  and #ProdData.Rejcode=T2.Rejcode '  
 Print @Strsql  
 Exec(@Strsql)  

 update #Proddata set TotalRejcount = T.rejcount from
 (Select SUM(RejCount) as rejcount from #proddata)T

If @Param='ByRejCategory' --Level1
Begin
	Select RejCategory,SUM(RejCount) as RejQty,case when SUM(RejCount)>0 then ISNULL(ROUND(((SUM(RejCount)/TotalRejcount) *100),2),0) else 0  end as Rejpercent from #proddata 
	group by RejCategory,TotalRejcount order by RejCategory
END
If @Param='ByRejSubCategory' --Level2
Begin
	Select RejCategory,RejSubcategory,SUM(RejCount) as RejQty,case when SUM(RejCount)>0 then ISNULL(ROUND(((SUM(RejCount)/TotalRejcount) *100),2),0) else 0  end as Rejpercent from #proddata 
	group by RejCategory,RejSubcategory,TotalRejcount order by RejCategory,RejSubcategory
END
If @Param='ByRejDesciption' --Level3
Begin
	Select RejCategory,RejSubcategory,RejDesciption,SUM(RejCount) as RejQty,case when SUM(RejCount)>0 then ISNULL(ROUND(((SUM(RejCount)/TotalRejcount) *100),2),0) else 0  end as Rejpercent from #proddata 
	where RejDesciption<>'' group by RejCategory,RejSubcategory,RejDesciption,TotalRejcount order by RejCategory,RejSubcategory,RejDesciption
END
If @Param='' or @Param='ByRejCode' --Level4
Begin
	Select RejCategory,Rejcode as RejReason,SUM(RejCount) as RejQty,case when SUM(RejCount)>0 then ISNULL(ROUND(((SUM(RejCount)/TotalRejcount) *100),2),0) else 0  end as Rejpercent from #proddata 
	where RejCount>0 group by RejCategory,Rejcode,TotalRejcount order by RejCategory,Rejcode
END

END 
