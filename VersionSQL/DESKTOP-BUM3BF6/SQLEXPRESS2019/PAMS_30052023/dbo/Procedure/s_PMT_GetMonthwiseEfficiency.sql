/****** Object:  Procedure [dbo].[s_PMT_GetMonthwiseEfficiency]    Committed by VersionSQL https://www.versionsql.com ******/

--s_PMT_GetMonthwiseEfficiency '2019-06-05'
CREATE                                  PROCEDURE [dbo].[s_PMT_GetMonthwiseEfficiency]
	@StartDate As DateTime,
	@PlantID As NVarChar(50)='',
	@Groupid nvarchar(50)='',
	@Parameter As nvarchar(50)=''/* Shift,Day,Consolidated Etc*/
AS
BEGIN


declare @strsql as nvarchar(max)

Declare @Strmachine nvarchar(255)
Declare @StrPlantID AS NVarchar(255)
Declare @Strgroupid AS NVarchar(255)


Select @Strsql = ''
Select @Strmachine = ''
Select @StrPlantID=''
select @Strgroupid=''


Create Table #ProdData  
(  
StartDate datetime,
enddate datetime,
  Groupid  NVarChar(50),  
 OperatorID  NVarChar(50),  
 ProdCount Int DEFAULT 0,  
 AcceptedParts Int DEFAULT 0,  
 RejCount  Int DEFAULT 0,  
 ReworkPerformed Int DEFAULT 0,  
 MarkedForRework Int DEFAULT 0,  
 AEffy  Float DEFAULT 0,  
 PEffy  Float DEFAULT 0,  
 QEffy  Float DEFAULT 0,  
 OEffy  Float DEFAULT 0,  
 UtilisedTime  Float DEFAULT 0,  
 DownTime  Float DEFAULT 0,  
 CN  Float DEFAULT 0,  
 ManagementLoss float default 0,  
 DowntimeAE float default 0  
)

        
CREATE TABLE #TimePeriodDetails        
 (        
PDate datetime,        
Shift nvarchar(20),        
DStart datetime,        
DEnd datetime        
) 

Declare @StratOfMonth As DateTime        
Declare @EndOfMonth As DateTime        
Declare @AddMonth As DateTime        
Declare @EndDate As DateTime     

Select @StartDate = cast(datepart(yyyy,@StartDate) as nvarchar(4))+ '-01' + '-01'        
select @EndDate = dateadd(Month,11,@StartDate)        
      
SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')        
SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@EndDate,'End')        
While @StratOfMonth<=@EndOfMonth        
BEGIN        
INSERT INTO #TimePeriodDetails ( DStart, DEnd )        
SELECT @StratOfMonth,dbo.f_GetPhysicalMonth(@StratOfMonth,'End')        
        
SELECT @StratOfMonth=DateAdd(mm,1,@StratOfMonth)          
           
END        

Insert Into #ProdData(StartDate,EndDate)        
Select DStart,DEnd From #TimePeriodDetails 

 If isnull(@PlantID,'') <> ''        
 Begin        
  -- Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'   
   Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID in (' + @PlantID + '))'      
 End        
        
  
If isnull(@Groupid,'') <> ''  
Begin  
-- Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID = N''' + @GroupID + ''')' 
 Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID  in (' + @GroupID + '))'  
  
End 
         
  Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'        
  Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'        
  Select @Strsql = @Strsql+ ' From('        
  Select @Strsql = @Strsql+ ' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,Sum(ISNULL(Prod_Qty,0))ProdCount,Sum(ISNULL(AcceptedParts,0))AcceptedParts,        
         Sum(ISNULL(Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(Marked_For_Rework,0)) AS MarkedForRework,Sum(Sum_of_ActCycleTime)As UtilisedTime        
                              From ShiftProductionDetails CROSS Join (Select StartDate ,EndDate From #ProdData ) as T1 '        
  Select @Strsql = @Strsql+ ' Where  pDate>=T1.StartDate And pDate<= T1.EndDate'        
 Select @Strsql = @Strsql+  @StrPlantID + @StrGroupid        
  Select @Strsql = @Strsql+ ' GROUP By T1.StartDate,T1.EndDate  '   
  Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate'
  Print @Strsql        
  Exec(@Strsql)        
        
/*================================================================================================================*/     
        
  Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'        
  Select @Strsql = @Strsql+' FROM('        
  Select @Strsql = @Strsql+' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,Sum(isnull(Rejection_Qty,0))Rej'        
  Select @Strsql = @Strsql+' From ShiftProductionDetails CROSS Join (Select StartDate ,EndDate  From #ProdData )T1        
        Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'        
  Select @Strsql = @Strsql+' Where pDate>=T1.StartDate And pDate<= T1.EndDate'        
 Select @Strsql = @Strsql+  @StrPlantID + @StrGroupid        
  Select @Strsql = @Strsql+' Group By T1.StartDate,T1.EndDate'
  Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate '    
  Print @Strsql        
  Exec(@Strsql)        
          
        
      
  Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'        
  Select @Strsql = @Strsql + ' From ('        
  Select @Strsql = @Strsql + ' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '        
  Select @Strsql = @Strsql + ' From ShiftProductionDetails CROSS Join (Select StartDate ,EndDate From #ProdData )T1 '        
  Select @Strsql = @Strsql + ' Where pDate>=T1.StartDate And pDate<= T1.EndDate '        
 Select @Strsql = @Strsql+  @StrPlantID +  @StrGroupid        
  Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate  '     
  Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate ' 
  Print @Strsql        
  Exec(@Strsql)        
        
 If isnull(@PlantID,'') <> ''        
 Begin        
 -- Select @StrPlantID = ' And ( ShiftDowntimeDetails.PlantID = N''' + @PlantID + ''' )'   
   Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID in (' + @PlantID + '))'       
 End        
 
     
If isnull(@Groupid,'') <> ''  
Begin  
 --Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID = N''' + @GroupID + ''')'
 Select @StrGroupid = ' And ( ShiftDownTimeDetails.GroupID  in (' + @GroupID + '))'   
End 
     
      
  Select @Strsql =''        
  SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '        
  Select @Strsql = @Strsql+ 'From (SELECT datepart(mm,ddate)as dmonth,datepart(yyyy,ddate)as dyear,sum(datediff(s,starttime,endtime)) as MinorDownTime 
  FROM ShiftDownTimeDetails '        
  Select @Strsql = @Strsql+ 'WHERE downid in (select downid from downcodeinformation where prodeffy = 1) 
  Group By datepart(mm,ddate),datepart(yyyy,ddate)'        
  Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON  T2.dmonth=datepart(mm,#ProdData.Startdate) 
  and T2.dyear=datepart(yyyy,#ProdData.EndDate)'        
  print @StrSql        
  EXEC(@StrSql)       
    
          
  Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'        
  Select @Strsql = @Strsql + ' From (select T1.StartDate As StartDate ,T1.EndDate As EndDate,(Sum(DownTime))As DownTime'        
  Select @Strsql = @Strsql + ' From ShiftDownTimeDetails CROSS Join (Select StartDate ,EndDate From #ProdData )T1        
          where  dDate>=T1.StartDate And dDate<= T1.EndDate'        
 Select @Strsql = @Strsql+  @StrPlantID + @StrGroupid       
  Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate '     
  Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate'
  Print @Strsql        
  Exec(@Strsql)         
        
  Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'        
  Select @Strsql = @Strsql + 'from (select T1.startdate as startdate, T1.Enddate as Enddate, sum(        
    CASE         
   WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0          
   THEN isnull(ShiftDownTimeDetails.Threshold,0)        
   ELSE ShiftDownTimeDetails.DownTime        
    END) AS LOSS '        
   Select @Strsql = @Strsql + ' From ShiftDownTimeDetails CROSS JOIN (Select StartDate ,EndDate From #ProdData )T1        
                                         where  dDate>=T1.StartDate And dDate<= T1.EndDate And ML_flag = 1'        
          
 Select @Strsql = @Strsql+  @StrPlantID +@StrGroupid        
  Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate '    
  Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate'       
  Print @Strsql        
  Exec(@Strsql)         
         
        
 ---mod 1 introduced with mod2 to neglect threshold ML from dtime        
  UPDATE #ProdData SET DownTime=DownTime-ManagementLoss    ---ER0335 Added        
        
        
  UPDATE #ProdData SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)        
  Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0        
  UPDATE #ProdData        
  SET        
   PEffy = (CN/UtilisedTime) ,        
   AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))        
  WHERE UtilisedTime <> 0        
  UPDATE #ProdData        
  SET        
   OEffy = PEffy * AEffy * QEffy * 100,        
   PEffy = PEffy * 100 ,        
   AEffy = AEffy * 100,        
   QEffy = QEffy * 100        

 select @Strsql=''    
	 select @strsql=@strsql + ' select Startdate,Enddate,convert(nvarchar(3),datename(month,Startdate)) as StartMonth,
	 round(OEffy,2) as OEffy ,  
	 round(AEffy,2) as AEffy ,        
	 round(PEffy,2) as PEffy,          
	 round(QEffy,2) as QEffy,
	 dbo.f_formattime(DownTime,''hh'')  as DownTime 
	  From #ProdData     
	 order by startdate'  
	 print(@strsql)    
	 exec(@strsql)     

END
