/****** Object:  Procedure [dbo].[SP_ProcessCreationAndAssociation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_ProcessCreationAndAssociation_PAMS @Param=N'ProcessReportTypeAssociation'
SP_ProcessCreationAndAssociation_PAMS @Param=N'ProcessFGAssociation'
SP_ProcessCreationAndAssociation_PAMS @Param=N'FGAndOperationAssociation'
SP_ProcessCreationAndAssociation_PAMS @Param=N'ProcessVendorAssociation'

*/
CREATE procedure [dbo].[SP_ProcessCreationAndAssociation_PAMS]
@FGId nvarchar(50)='',
@Param nvarchar(50)=''
AS
BEGIN

DECLARE @cols AS NVARCHAR(MAX)
declare @query  AS NVARCHAR(MAX)

create table #Temp1
(
ProcessID INT,
process nvarchar(2000),
ReportID INT,
reporttype nvarchar(2000),
Checked int  default 0,
InspectionMethod nvarchar(2000)
)

create table #Temp4
(
VendorID NVARCHAR(50),
VendorName nvarchar(500),
ProcessID INT,
process nvarchar(2000),
Checked int default 0
)


create table #Temp3
(
ProcessID INT,
process nvarchar(2000),
FGid NVARCHAR(50),
FGDescription nvarchar(500),
DCType nvarchar(50),
OperationNo nvarchar(100),
Checked int default 0,
Sequence int default 0,
DisplayPamsDCNo INT DEFAULT 0
)



	if @Param='ProcessReportTypeAssociation'
	begin
		insert into #Temp1(process,reporttype,ProcessID,ReportID)
		select distinct process,reporttype,P1.ProcessID,R1.ReportID from ProcessMaster_PAMS p1
		cross join ReportTypeMaster_PAMS r1

		update #Temp1 set Checked=(t1.chk),InspectionMethod=(t1.inspmethod)
		from
		(select distinct process,reporttype,Checked as chk,InspectionMethod as inspmethod from ProcessAndReportTypeAssociation_PAMS
		) t1 inner join #Temp1 on #Temp1.process=t1.process and #Temp1.reporttype=t1.reporttype

		select * from #Temp1 ORDER BY processID,ReportID
	 END

	 IF @Param='ProcessFGAssociation'
	 begin

		insert into #Temp3(ProcessID,process,FGid,FGDescription,Checked,Sequence,DisplayPamsDCNo)
		select distinct p1.Processid,p1.Process,f1.PartID,f1.PartDescription, 0,0,0 from  ProcessMaster_PAMS p1 cross join  FGDetails_PAMS f1 

		update #Temp3 set Checked=(t1.chk),DCType=(t1.DCType),Sequence=(t1.Sequence),DisplayPamsDCNo=(t1.DisplayPamsDCNo)
		from
		(select distinct process,PartID,DCType, Checked as chk,Sequence,DisplayPamsDCNo from ProcessAndFGAssociation_PAMS
		)t1 inner join #Temp3 on t1.Process=#Temp3.process and t1.PartID=#Temp3.FGid

		select ProcessID,process ,FGid,FGDescription,checked, DCType,isnull(Sequence,0) as Sequence,isnull(DisplayPamsDCNo,0) as DisplayPamsDCNo  from #Temp3 where FGid like '%'+@FGId+'%' order by FGid,ProcessID 


		--SELECT @cols= COALESCE(@cols+',','')+ QUOTENAME(process) FROM  
		--(SELECT DISTINCT TOP 100 PERCENT 
		--processid,process
		--FROM ProcessMaster_PAMS 
		--) t
		--ORDER BY Processid asc


		--insert into #Temp3(ProcessID,process,FGid,FGDescription,Checked)
		--select distinct p1.Processid,p1.Process,f1.PartID,f1.PartDescription,0 from  ProcessMaster_PAMS p1 cross join  FGDetails_PAMS f1 

		--update #Temp3 set Checked=(t1.chk)
		--from
		--(select distinct process,PartID,Checked as chk from ProcessAndFGAssociation_PAMS
		--)t1 inner join #Temp3 on t1.Process=#Temp3.process and t1.PartID=#Temp3.FGid


		--  SELECT @Query='SELECT distinct FGid ,FGDescription, '+@cols+'FROM   
		--(select distinct process, FGid ,FGDescription, isnull(Checked,0) as Checked from #Temp3
		-- )Tab1  
		--PIVOT  
		--(  
		--max(Checked)  FOR [process] IN ('+@cols+')) AS Tab2
		--order by FGid'
		--print(@query)
		--EXEC  sp_executesql  @Query 

	 end

	  IF @Param='ProcessVendorAssociation'
	 begin

		SELECT @cols= COALESCE(@cols+',','')+ QUOTENAME(process) FROM  
		(SELECT DISTINCT TOP 100 PERCENT 
		processid,process
		FROM ProcessMaster_PAMS 
		order by ProcessID
		) t
		ORDER BY Processid asc


		insert into #Temp4(ProcessID,process,VendorID,VendorName,Checked)
		select distinct p1.Processid,p1.Process,f1.VendorID,f1.VendorName,0 from  ProcessMaster_PAMS p1 cross join  VendorDetails_PAMS f1 
		where f1.Approval='Ok' and f1.IsActive=1

		update #Temp4 set Checked=(t1.chk)
		from
		(select distinct process,VendorID,Checked as chk from ProcessAndVendorAssociation_PAMS
		)t1 inner join #Temp4 on t1.Process=#Temp4.process and t1.VendorID=#Temp4.VendorID


		  SELECT @Query='SELECT distinct VendorID ,VendorName, '+@cols+'FROM   
		(select distinct process, VendorID ,VendorName, isnull(Checked,0) as Checked from #Temp4
		 )Tab1  
		PIVOT  
		(  
		max(Checked)  FOR [process] IN ('+@cols+')) AS Tab2
		order by VendorID'
		print(@query)
		EXEC  sp_executesql  @Query 

	 end

	 if @Param='FGAndOperationAssociation'
	 begin
		
		SELECT @cols= COALESCE(@cols+',','')+ QUOTENAME(OperationNo) FROM  
		(SELECT DISTINCT TOP 100 PERCENT  OperationNo
		FROM operationmaster_pams 
		order by  OperationNo
		) t

		insert into #Temp3(OperationNo,FGid,FGDescription,Checked)
		select distinct p1.OperationNo,f1.PartID,f1.PartDescription,0 from  operationmaster_pams p1 cross join  FGDetails_PAMS f1 

		update #Temp3 set Checked=(t1.chk)
		from
		(select distinct PartID,Operation,Checked as chk from FGAndOperationAssociation_pams
		)t1 inner join #Temp3 on t1.PartID=#Temp3.FGid and t1.Operation=#Temp3.OperationNo



		  SELECT @Query='SELECT distinct FGid ,FGDescription, '+@cols+'FROM   
		(select distinct OperationNo, FGid ,FGDescription, isnull(Checked,0) as Checked from #Temp3
		 )Tab1  
		PIVOT  
		(  
		max(Checked)  FOR [OperationNo] IN ('+@cols+')) AS Tab2 '
		print(@query)
		EXEC  sp_executesql  @Query 

	end
	
END
