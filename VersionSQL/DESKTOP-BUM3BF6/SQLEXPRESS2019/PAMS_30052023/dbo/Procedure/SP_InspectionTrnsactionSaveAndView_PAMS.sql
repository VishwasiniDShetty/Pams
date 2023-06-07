/****** Object:  Procedure [dbo].[SP_InspectionTrnsactionSaveAndView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*

SP_InspectionTrnsactionSaveAndView_PAMS 'p1','r1','m1','c1','O1','','View'
SP_InspectionTrnsactionSaveAndView_PAMS @Process=N'Raw material stage',@ReportType=N'Inward inspection report',@ProcessType=N'RM',@RawMaterial=N'M 1',@Param=N'View'
SP_InspectionTrnsactionSaveAndView_PAMS @Process=N'Raw material stage',@ReportType=N'Final Insp. Report',@ProcessType=N'FG-Operation',@ComponentID=N'Part 1',@OperationNo=N'10',@Param=N'View'


*/
CREATE procedure [dbo].[SP_InspectionTrnsactionSaveAndView_PAMS]
@Process nvarchar(2000)='',
@ReportType nvarchar(2000)='',
@ProcessType nvarchar(100)='',
@Machine nvarchar(50)='',
@ComponentID NVARCHAR(50)='',
@OperationNo nvarchar(50)='',
@RawMaterial nvarchar(50)='',
@RevID INT=0,
@RevNo nvarchar(50)='',
@RevDate datetime='',
@CharacteristicCode nvarchar(max)='',
@MeasuringInstrumentTranValue nvarchar(max)='',
@Date datetime='',
@DateTime datetime='',
@Shift nvarchar(100)='',
@BatchID INT=0,
@BatchValue nvarchar(2000)='',
@BatchTS DATETIME='',
@Status nvarchar(2000)='',
@Remarks nvarchar(max)='',
@Param nvarchar(100)='',
@Param1 nvarchar(100)='',
@GRNNo nvarchar(50)='',
@InvoiceNumber nvarchar(50)='',
@PJCNo nvarchar(50)='',
@PJCYear nvarchar(10)='',
@Pams_DCNo nvarchar(50)='',
@VendorDCNo nvarchar(50)='',
@MJCNo nvarchar(50)='',
@BatchBit nvarchar(max)='',
@UpdatedBy_Quality NVARCHAR(50)='',
@UpdatedTs_Quality DATETIME=NULL,
@UpdatedBy_MR NVARCHAR(50)='',
@UpdatedTs_MR DATETIME=NULL,
@MRBit bit=0
as
begin
create table #Inspection
(
RowID BIGINT IDENTITY(1,1),
Process NVARCHAR(2000),
ReportType nvarchar(2000),
ProcessType nvarchar(50),
ComponentID NVARCHAR(50),
OperationNo nvarchar(50),
Rawmaterial nvarchar(50),
specialCharacteristic nvarchar(max),
CharacteristicCode nvarchar(2000),
Specification nvarchar(2000),
MeasuringMethod nvarchar(max),
RevID INT,
RevNo nvarchar(50),
RevDate datetime,
NoOfSamples nvarchar(50),
MeasuringInstrument nvarchar(max),
MeasuredValue nvarchar(100),
ControlType nvarchar(100),
ControlValue nvarchar(max),
LSL nvarchar(50),
USL nvarchar(50),
SortOrder int,
IsMandatory bit default 0,
UpdatedBy_Quality NVARCHAR(50) DEFAULT NULL,
UpdatedTs_Quality DATETIME DEFAULT NULL,
UpdatedBy_MR NVARCHAR(50) DEFAULT NULL,
UpdatedTs_MR DATETIME DEFAULT NULL
)

IF @Param='View'
begin
		if isnull(@Param1,'')='RM'
		BEGIN
			insert into #Inspection(Process,ReportType ,ProcessType ,Rawmaterial,specialCharacteristic  ,CharacteristicCode ,Specification ,MeasuringMethod,
			RevID ,RevNo ,RevDate ,NoOfSamples ,MeasuringInstrument ,MeasuredValue ,ControlType ,ControlValue ,LSL ,USL ,SortOrder,IsMandatory)
			select distinct I1.Process,I1.ReportType ,I1.ProcessType ,I1.Rawmaterial,specialCharacteristic  ,i1.CharacteristicCode ,Specification ,MeasuringMethod,
			I1.RevID ,RevNo,RevDate ,NoOfSamples ,MeasuringInstrument ,MeasuredValue ,ControlType ,ControlValue ,LSL ,USL ,SortOrder,IsMandatory from InspectionMasterRMLevel_PAMS I1 
			INNER JOIN 
			(SELECT DISTINCT Process,ReportType ,ProcessType ,isnull(Rawmaterial,'') Rawmaterial,
			MAX(REVID) AS REVID FROM InspectionMasterRMLevel_PAMS  WHERE Process like '%'+@Process+'%' AND ReportType=@ReportType AND ProcessType=@ProcessType AND  (RawMaterial=@RawMaterial OR ISNULL(@RawMaterial,'')='')
			group by Process,ReportType ,ProcessType ,RawMaterial 
			) I2 
			ON I1.Process=I2.Process AND I1.ReportType=I2.ReportType AND I1.ProcessType=I2.ProcessType AND ISNULL(I1.RawMaterial,'')=ISNULL(I2.RawMaterial,'') AND I1.RevID=I2.REVID 
			 WHERE i1.Process like '%'+@Process+'%' AND I1.ReportType=@ReportType AND I1.ProcessType=@ProcessType AND  (I1.RawMaterial=@RawMaterial OR ISNULL(@RawMaterial,'')='')

			SELECT * FROM #Inspection order by SortOrder,CharacteristicCode asc

			SELECT date,I1.process,I1.ReportType,I1.ProcessType,I1.RawMaterial,I1.SpecialCharacteristic,I1.CharacteristicCode,I1.Specification,I1.MeasuringMethod,I1.RevID,I1.RevNo,I1.RevDate,I1.NoOfSamples,I1.MeasuringInstrument,I1.MeasuredValue,
			I1.ControlType,I1.ControlValue,I1.LSL,I1.USL,I1.SortOrder,I1.BatchID,I1.BatchValue,I1.BatchTS,I1.Status,I1.Remarks,I1.MeasuringInstrumentTran,I1.GRNNo,I1.InvoiceNumber,isnull(f1.status,'') as FinalInspectionstatus  FROM InspectionTransactionRMLevel_PAMS I1  
			left join FinalInspectionTransaction_PAMS f1 on f1.process=I1.Process and f1.ReportType=i1.reporttype and f1.MaterialID=i1.RawMaterial and f1.GRNNo=i1.GRNNo and f1.InvoiceNumber=i1.InvoiceNumber
			WHERE i1.Process like '%'+@Process+'%' AND i1.ReportType=@ReportType AND i1.ProcessType=@ProcessType AND  i1.RawMaterial=@RawMaterial and i1.GrnNo=@grnno and i1.InvoiceNumber=@InvoiceNumber

		end
		if isnull(@Param1,'')='FG-Operation-Machine'
		BEGIN
			insert into #Inspection(Process,ReportType ,ProcessType ,ComponentID ,OperationNo ,specialCharacteristic  ,CharacteristicCode ,Specification ,MeasuringMethod,
			RevID ,RevNo ,RevDate ,NoOfSamples ,MeasuringInstrument ,MeasuredValue ,ControlType ,ControlValue ,LSL ,USL ,SortOrder,IsMandatory)
			select distinct I1.Process,I1.ReportType ,I1.ProcessType ,I1.ComponentID ,I1.OperationNo ,specialCharacteristic  ,i1.CharacteristicCode ,Specification ,MeasuringMethod,
			I1.RevID ,RevNo,RevDate ,NoOfSamples ,MeasuringInstrument ,MeasuredValue ,ControlType ,ControlValue ,LSL ,USL ,SortOrder,IsMandatory from InspectionMasterFG_PAMS I1 
			INNER JOIN 
			(SELECT DISTINCT Process,ReportType ,ProcessType ,isnull(ComponentID,'') ComponentID ,isnull(OperationNo,'') OperationNo ,
			MAX(REVID) AS REVID FROM InspectionMasterFG_PAMS  WHERE Process like '%'+@Process+'%' AND ReportType=@ReportType AND ProcessType=@ProcessType AND ComponentID=@ComponentID AND  
			OperationNo=@OperationNo
			group by Process,ReportType ,ProcessType ,isnull(ComponentID,'') ,isnull(OperationNo,'') 
			) I2 
			ON I1.Process=I2.Process AND I1.ReportType=I2.ReportType AND I1.ProcessType=I2.ProcessType AND ISNULL(I1.ComponentID,'')=ISNULL(I2.ComponentID,'') AND ISNULL(I1.OperationNo,'')=ISNULL(I2.OperationNo,'')
			AND I1.RevID=I2.REVID 
			 WHERE I1.Process like '%'+@Process+'%' AND I1.ProcessType=@ProcessType AND I1.ReportType=@ReportType AND I1.ComponentID=@ComponentID  AND  
			 I1.OperationNo=@OperationNo

			 SELECT * FROM #Inspection order by SortOrder asc,CharacteristicCode asc

			 SELECT I1.*,isnull(f1.status,'') as FinalInspectionstatus  FROM InspectionTransactionMCOLevel_PAMS I1
			 left join FinalInspectionTransactionMCOLevel_PAMS f1 on f1.process=I1.Process and f1.ReportType=i1.reporttype and f1.date=i1.date and f1.shift=i1.shift
			 and f1.Machine=i1.Machine and f1.componentid=i1.componentid and f1.operationno=i1.operationno and f1.PJCNo=I1.PJCNo and f1.PJCYear=I1.PJCYear
			 WHERE I1.Process like '%'+@Process+'%' AND I1.ProcessType=@ProcessType AND I1.ReportType=@ReportType AND I1.ComponentID=@ComponentID AND  
			 I1.OperationNo=@OperationNo  and I1.Machine=@Machine  and I1.Date=convert(nvarchar(20),@date,120) and I1.Shift=@Shift and i1.PJCNo=@PJCNo and i1.PJCYear=@PJCYear

		END

		if isnull(@Param1,'')='SF. Part'
		BEGIN
			insert into #Inspection(Process,ReportType ,ProcessType ,ComponentID  ,specialCharacteristic  ,CharacteristicCode ,Specification ,MeasuringMethod,
			RevID ,RevNo ,RevDate ,NoOfSamples ,MeasuringInstrument ,MeasuredValue ,ControlType ,ControlValue ,LSL ,USL ,SortOrder,IsMandatory)
			select distinct I1.Process,I1.ReportType ,I1.ProcessType ,I1.ComponentID ,specialCharacteristic  ,i1.CharacteristicCode ,Specification ,MeasuringMethod,
			I1.RevID ,RevNo,RevDate ,NoOfSamples ,MeasuringInstrument ,MeasuredValue ,ControlType ,ControlValue ,LSL ,USL ,SortOrder,IsMandatory from InspectionMasterFG_PAMS I1 
			INNER JOIN 
			(SELECT DISTINCT Process,ReportType ,ProcessType ,isnull(ComponentID,'') ComponentID ,MAX(REVID) AS REVID FROM InspectionMasterFG_PAMS  
			WHERE Process like '%'+@Process+'%' AND ReportType=@ReportType AND ProcessType=@ProcessType 
			AND ComponentID=@ComponentID	
			group by Process,ReportType ,ProcessType ,isnull(ComponentID,'')
			) I2 
			ON I1.Process=I2.Process AND I1.ReportType=I2.ReportType AND I1.ProcessType=I2.ProcessType AND ISNULL(I1.ComponentID,'')=ISNULL(I2.ComponentID,'') 
			AND I1.RevID=I2.REVID 
			 WHERE I1.Process like '%'+@Process+'%' AND I1.ProcessType=@ProcessType AND I1.ReportType=@ReportType AND I1.ComponentID=@ComponentID 

			 SELECT * FROM #Inspection order by SortOrder asc,CharacteristicCode asc

			 SELECT I1.*,isnull(f1.status,'') as FinalInspectionstatus FROM InspectionTransactionFGLevel_PAMS I1
			  left join FinalInspectionTransactionFG_PAMS f1 on f1.process=I1.Process and f1.ReportType=i1.reporttype and f1.componentid=I1.componentid and F1.Pams_dcno=I1.Pams_dcno 
			  and ISNULL(f1.VendorDCNo,'')=ISNULL(i1.VendorDCNo,'') and isnull(f1.mjcno,'')=isnull(i1.mjcno,'') and isnull(f1.PJCNo,'')=isnull(i1.PJCNo,'') and  isnull(f1.PJCYear,'')=isnull(i1.PJCYear,'')
			 WHERE I1.Process like '%'+@Process+'%' AND I1.ProcessType=@ProcessType AND I1.ReportType=@ReportType 
			 AND I1.ComponentID=@ComponentID and I1.Pams_dcno=@Pams_DCNo AND (I1.VendorDCNo=@VendorDCNo OR ISNULL(@VendorDCNo,'')='') 
			 and  (i1.MJCNo=@MJCNo or isnull(@MJCNo,'')='') and  (i1.PJCNo=@PJCNo or isnull(@PJCNo,'')='') and (i1.PJCYear=@PJCYear or isnull(@PJCYear,'')='')
			 --and I1.Date=convert(nvarchar(20),@date,120) and I1.Shift=@Shift

		END

		if isnull(@Param1,'')='FinalInspection'
		BEGIN
			insert into #Inspection(Process,ReportType ,ProcessType ,ComponentID  ,specialCharacteristic  ,CharacteristicCode ,Specification ,MeasuringMethod,
			RevID ,RevNo ,RevDate ,NoOfSamples ,MeasuringInstrument ,MeasuredValue ,ControlType ,ControlValue ,LSL ,USL ,SortOrder,IsMandatory)
			select distinct I1.Process,I1.ReportType ,I1.ProcessType ,I1.ComponentID ,specialCharacteristic  ,i1.CharacteristicCode ,Specification ,MeasuringMethod,
			I1.RevID ,RevNo,RevDate ,NoOfSamples ,MeasuringInstrument ,MeasuredValue ,ControlType ,ControlValue ,LSL ,USL ,SortOrder,IsMandatory from InspectionMasterFG_PAMS I1 
			INNER JOIN 
			(SELECT DISTINCT Process,ReportType ,ProcessType ,isnull(ComponentID,'') ComponentID ,MAX(REVID) AS REVID FROM InspectionMasterFG_PAMS  
			WHERE Process like '%'+@Process+'%' AND ReportType=@ReportType AND ProcessType=@ProcessType 
			AND ComponentID=@ComponentID	
			group by Process,ReportType ,ProcessType ,isnull(ComponentID,'')
			) I2 
			ON I1.Process=I2.Process AND I1.ReportType=I2.ReportType AND I1.ProcessType=I2.ProcessType AND ISNULL(I1.ComponentID,'')=ISNULL(I2.ComponentID,'') 
			AND I1.RevID=I2.REVID 
			 WHERE I1.Process like '%'+@Process+'%' AND I1.ProcessType=@ProcessType AND I1.ReportType=@ReportType AND I1.ComponentID=@ComponentID

			 SELECT * FROM #Inspection order by SortOrder asc,CharacteristicCode asc

			 --SELECT I1.*,isnull(f1.status,'') as FinalInspectionstatus  FROM InspectionTransactionFinalFGLevel_PAMS I1
			 --left join FinalInspectionTransactionFGLevel_PAMS f1 on f1.process=I1.Process and f1.ReportType=i1.reporttype 
			 --and  f1.componentid=i1.componentid and  f1.PJCNo=I1.PJCNo and f1.PJCYear=I1.PJCYear and  convert(nvarchar(20),f1.Date,120)=convert(nvarchar(20),i1.date,120) and f1.BatchBit=i1.BatchBit
			 --WHERE I1.Process like '%'+@Process+'%' AND I1.ProcessType=@ProcessType AND I1.ReportType=@ReportType AND I1.ComponentID=@ComponentID AND  
			 -- I1.OperationNo=@OperationNo and  i1.PJCNo=@PJCNo and i1.PJCYear=@PJCYear and  i1.BatchBit=@BatchBit

			  SELECT I1.*,isnull(f1.status,'') as FinalInspectionstatus  FROM InspectionTransactionFinalFGLevel_PAMS I1
			 left join FinalInspectionTransactionFGLevel_PAMS f1 on f1.process=I1.Process and f1.ReportType=i1.reporttype 
			 and  f1.componentid=i1.componentid and  f1.PJCNo=I1.PJCNo and f1.PJCYear=I1.PJCYear and  f1.BatchBit=i1.BatchBit
			 WHERE I1.Process like '%'+@Process+'%' AND I1.ProcessType=@ProcessType AND I1.ReportType=@ReportType AND I1.ComponentID=@ComponentID AND  
			  I1.OperationNo=@OperationNo and  i1.PJCNo=@PJCNo and i1.PJCYear=@PJCYear and  i1.BatchBit=@BatchBit

			 --I1.OperationNo=@OperationNo and  i1.PJCNo=@PJCNo and i1.PJCYear=@PJCYear and  convert(nvarchar(20),I1.Date,120)=convert(nvarchar(20),@DateTime,120) and i1.BatchBit=@BatchBit

		END

END

IF @Param='Save'
begin
	if isnull(@Param1,'')='RM'
	begin
		if not exists(select * from InspectionTransactionRMLevel_PAMS where  ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND ReportType=@ReportType AND RawMaterial=@RawMaterial and CharacteristicCode=@CharacteristicCode and BatchID=@BatchID and GrnNo=@GRNNo and InvoiceNumber=@InvoiceNumber)
		begin
			insert into InspectionTransactionRMLevel_PAMS(Date,Process,ProcessType,ReportType,RawMaterial,CharacteristicCode,SpecialCharacteristic,Specification,MeasuringMethod,revid,revno,RevDate,NoOfSamples,
			MeasuringInstrument,MeasuringInstrumentTran,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,BatchID,BatchValue,BatchTS,Status,Remarks,GrnNo,InvoiceNumber,UpdatedBy_Quality,UpdatedTs_Quality,UpdatedBy_MR,UpdatedTs_MR)
			select @Date,@Process,@ProcessType,@ReportType,@RawMaterial,@CharacteristicCode,SpecialCharacteristic, Specification,MeasuringMethod,@RevID,@RevNo,@RevDate,NoOfSamples,
			MeasuringInstrument,@MeasuringInstrumentTranValue,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,@BatchID,@BatchValue,@BatchTS,@Status,@Remarks,@GRNNo,@InvoiceNumber,@UpdatedBy_Quality,@UpdatedTs_Quality,@UpdatedBy_MR,@UpdatedTs_MR from InspectionMasterRMLevel_PAMS
			where Process like '%'+@Process+'%' and ProcessType=@ProcessType  AND ReportType=@ReportType AND RawMaterial=@RawMaterial and CharacteristicCode=@CharacteristicCode and RevID=@RevID
		end
		else
		begin
		if isnull(@mrbit,0)=1
		begin
			update InspectionTransactionRMLevel_PAMS set BatchValue=@BatchValue,BatchTS=@BatchTS,UpdatedBy_MR=@UpdatedBy_MR,UpdatedTs_MR=@UpdatedTs_MR,Status=@Status,Remarks=@Remarks,MeasuringInstrumentTran=@MeasuringInstrumentTranValue
			where  ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND ReportType=@ReportType AND RawMaterial=@RawMaterial and Grnno=@GRNNo and invoicenumber=@InvoiceNumber and CharacteristicCode=@CharacteristicCode and BatchID=@BatchID 
		end
		else
		begin
			update InspectionTransactionRMLevel_PAMS set BatchValue=@BatchValue,BatchTS=@BatchTS,MeasuringInstrumentTran=@MeasuringInstrumentTranValue, UpdatedBy_Quality=@UpdatedBy_Quality,UpdatedTs_Quality=@UpdatedTs_Quality
			where  ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND ReportType=@ReportType AND RawMaterial=@RawMaterial and Grnno=@GRNNo and invoicenumber=@InvoiceNumber and CharacteristicCode=@CharacteristicCode and BatchID=@BatchID 

			update InspectionTransactionRMLevel_PAMS set Status=@Status,Remarks=@Remarks,UpdatedBy_Quality=@UpdatedBy_Quality,UpdatedTs_Quality=@UpdatedTs_Quality
			where  ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND ReportType=@ReportType AND RawMaterial=@RawMaterial and CharacteristicCode=@CharacteristicCode and Grnno=@GRNNo and invoicenumber=@InvoiceNumber
		end
		end
	end
	if isnull(@Param1,'')='FG-Operation-Machine'
	begin
		if not exists(select * from InspectionTransactionMCOLevel_PAMS where Date=@date and Shift=@Shift AND ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND ReportType=@ReportType AND isnull(machine,'')=isnull(@Machine,'') and ISNULL(ComponentID,'')=ISNULL(@ComponentID,'') AND ISNULL(OperationNo,'')=ISNULL(@OperationNo,'') and PJCNo=@PJCNo and PJCYear=@PJCYear and CharacteristicCode=@CharacteristicCode 
		and BatchID=@BatchID)
		begin
			insert into InspectionTransactionMCOLevel_PAMS(Date,shift,Process,ProcessType,ReportType,Machine,ComponentID,OperationNo,CharacteristicCode,SpecialCharacteristic,Specification,MeasuringMethod,revid,revno,RevDate,NoOfSamples,
			MeasuringInstrument,MeasuringInstrumentTran,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,BatchID,BatchValue,BatchTS,Status,Remarks,PJCNo,PJCYear,UpdatedBy_Quality,UpdatedTs_Quality,UpdatedBy_MR,UpdatedTs_MR)
			select @Date,@shift,@Process,@ProcessType,@ReportType,@Machine,@ComponentID,@OperationNo,@CharacteristicCode,SpecialCharacteristic, Specification,MeasuringMethod,@RevID,@RevNo,@RevDate,NoOfSamples,
			MeasuringInstrument,@MeasuringInstrumentTranValue,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,@BatchID,@BatchValue,@BatchTS,@Status,@Remarks,@PJCNo,@PJCYear,@UpdatedBy_Quality,@UpdatedTs_Quality,@UpdatedBy_MR,@UpdatedTs_MR from InspectionMasterFG_PAMS
			where Process like '%'+@Process+'%' and ProcessType=@ProcessType  AND ReportType=@ReportType AND  ISNULL(ComponentID,'')=ISNULL(@ComponentID,'') AND ISNULL(OperationNo,'')=ISNULL(@OperationNo,'') and CharacteristicCode=@CharacteristicCode and RevID=@RevID
		end
		else
		begin
		if isnull(@mrbit,0)=1
		begin
			update InspectionTransactionMCOLevel_PAMS set BatchValue=@BatchValue,BatchTS=@BatchTS,UpdatedBy_MR=@UpdatedBy_MR,UpdatedTs_MR=@UpdatedTs_MR,Status=@Status,Remarks=@Remarks,MeasuringInstrumentTran=@MeasuringInstrumentTranValue
			where ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND date=@date and shift=@Shift AND ReportType=@ReportType AND machine=@Machine and ISNULL(ComponentID,'')=ISNULL(@ComponentID,'') AND ISNULL(OperationNo,'')=ISNULL(@OperationNo,'') and PJCNo=@PJCNo and PJCYear=@PJCYear and  CharacteristicCode=@CharacteristicCode and BatchID=@BatchID
		end
		else
		begin
			update InspectionTransactionMCOLevel_PAMS set BatchValue=@BatchValue,BatchTS=@BatchTS,Status=@Status,Remarks=@Remarks,MeasuringInstrumentTran=@MeasuringInstrumentTranValue,UpdatedBy_Quality=@UpdatedBy_Quality,UpdatedTs_Quality=@UpdatedTs_Quality
			where ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND date=@date and shift=@Shift AND ReportType=@ReportType AND machine=@Machine and ISNULL(ComponentID,'')=ISNULL(@ComponentID,'') AND ISNULL(OperationNo,'')=ISNULL(@OperationNo,'') and PJCNo=@PJCNo and PJCYear=@PJCYear and  CharacteristicCode=@CharacteristicCode and BatchID=@BatchID

			update InspectionTransactionMCOLevel_PAMS set Status=@Status,Remarks=@Remarks,UpdatedBy_Quality=@UpdatedBy_Quality,UpdatedTs_Quality=@UpdatedTs_Quality
			where ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND  Date=@Date AND Shift=@Shift AND ReportType=@ReportType AND Machine=@Machine AND ISNULL(ComponentID,'')=ISNULL(@ComponentID,'') AND ISNULL(OperationNo,'')=ISNULL(@OperationNo,'') and PJCNo=@PJCNo and PJCYear=@PJCYear and CharacteristicCode=@CharacteristicCode
		end
		end
	END

	if isnull(@Param1,'')='SF. Part'
	begin
		if not exists(select * from InspectionTransactionFGLevel_PAMS where  ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND ReportType=@ReportType AND ComponentID=@ComponentID and Pams_DCNo=@Pams_DCNo and ISNULL(VendorDCNo,'')=ISNULL(@VendorDCNo,'') and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,'') and isnull(PJCYear,'')=isnull(@PJCYear,'')  and CharacteristicCode=@CharacteristicCode and BatchID=@BatchID)
		begin
			insert into InspectionTransactionFGLevel_PAMS(Date,shift,Process,ProcessType,ReportType,ComponentID,PJCNo,PJCYear,CharacteristicCode,SpecialCharacteristic,Specification,MeasuringMethod,revid,revno,RevDate,NoOfSamples,
			MeasuringInstrument,MeasuringInstrumentTran,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,BatchID,BatchValue,BatchTS,Status,Remarks,Pams_DCNo,VendorDCNo,MJCNo,UpdatedBy_Quality,UpdatedTs_Quality,UpdatedBy_MR,UpdatedTs_MR)
			select @Date,@shift,@Process,@ProcessType,@ReportType,@ComponentID,@PJCNo,@PJCYear,@CharacteristicCode,SpecialCharacteristic, Specification,MeasuringMethod,@RevID,@RevNo,@RevDate,NoOfSamples,
			MeasuringInstrument,@MeasuringInstrumentTranValue,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,@BatchID,@BatchValue,@BatchTS,@Status,@Remarks,@Pams_DCNo,@VendorDCNo,@MJCNo,@UpdatedBy_Quality,@UpdatedTs_Quality,@UpdatedBy_MR,@UpdatedTs_MR from InspectionMasterFG_PAMS
			where Process like '%'+@Process+'%' and ProcessType=@ProcessType  AND ReportType=@ReportType AND  ISNULL(ComponentID,'')=ISNULL(@ComponentID,'') AND ISNULL(OperationNo,'')=ISNULL(@OperationNo,'') and CharacteristicCode=@CharacteristicCode and RevID=@RevID 
		end
		else
		begin
		if isnull(@mrbit,0)=1
		begin
			update InspectionTransactionFGLevel_PAMS set BatchValue=@BatchValue,BatchTS=@BatchTS,UpdatedBy_MR=@UpdatedBy_MR,UpdatedTs_MR=@UpdatedTs_MR,Status=@Status,Remarks=@Remarks,MeasuringInstrumentTran=@MeasuringInstrumentTranValue
			where ProcessType=@ProcessType AND Process like '%'+@Process+'%'  AND ReportType=@ReportType and ISNULL(ComponentID,'')=ISNULL(@ComponentID,'')  and Pams_DCNo=@Pams_DCNo and ISNULL(VendorDCNo,'')=ISNULL(@VendorDCNo,'') and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,'') and isnull(PJCYear,'')=isnull(@PJCYear,'') and  CharacteristicCode=@CharacteristicCode and BatchID=@BatchID
		end
		else
		begin
			update InspectionTransactionFGLevel_PAMS set BatchValue=@BatchValue,BatchTS=@BatchTS,Status=@Status,Remarks=@Remarks,MeasuringInstrumentTran=@MeasuringInstrumentTranValue,UpdatedBy_Quality=@UpdatedBy_Quality,UpdatedTs_Quality=@UpdatedTs_Quality
			where ProcessType=@ProcessType AND Process like '%'+@Process+'%'  AND ReportType=@ReportType and ISNULL(ComponentID,'')=ISNULL(@ComponentID,'')  and Pams_DCNo=@Pams_DCNo and ISNULL(VendorDCNo,'')=ISNULL(@VendorDCNo,'') and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,'') and isnull(PJCYear,'')=isnull(@PJCYear,'') and  CharacteristicCode=@CharacteristicCode and BatchID=@BatchID

			update InspectionTransactionFGLevel_PAMS set Status=@Status,Remarks=@Remarks,UpdatedBy_Quality=@UpdatedBy_Quality,UpdatedTs_Quality=@UpdatedTs_Quality
			where ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND  ReportType=@ReportType AND  ISNULL(ComponentID,'')=ISNULL(@ComponentID,'') and Pams_DCNo=@Pams_DCNo and ISNULL(VendorDCNo,'')=ISNULL(@VendorDCNo,'') and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,'') and isnull(PJCYear,'')=isnull(@PJCYear,'') and CharacteristicCode=@CharacteristicCode
		end
		end
	end

		if isnull(@Param1,'')='FinalInspection'
	begin
		if not exists(select * from InspectionTransactionFinalFGLevel_PAMS where  ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND ReportType=@ReportType AND  ISNULL(ComponentID,'')=ISNULL(@ComponentID,'')  and PJCNo=@PJCNo and PJCYear=@PJCYear and CharacteristicCode=@CharacteristicCode 
		and BatchID=@BatchID and BatchBit=@BatchBit)
		begin
			insert into InspectionTransactionFinalFGLevel_PAMS(date,Process,ProcessType,ReportType,ComponentID,OperationNo,CharacteristicCode,SpecialCharacteristic,Specification,MeasuringMethod,revid,revno,RevDate,NoOfSamples,
			MeasuringInstrument,MeasuringInstrumentTran,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,BatchID,BatchValue,BatchTS,Status,Remarks,PJCNo,PJCYear,BatchBit,UpdatedBy_Quality,UpdatedTs_Quality,UpdatedBy_MR,UpdatedTs_MR)
			select @DateTime, @Process,@ProcessType,@ReportType,@ComponentID,@OperationNo,@CharacteristicCode,SpecialCharacteristic, Specification,MeasuringMethod,@RevID,@RevNo,@RevDate,NoOfSamples,
			MeasuringInstrument,@MeasuringInstrumentTranValue,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,@BatchID,@BatchValue,@BatchTS,@Status,@Remarks,@PJCNo,@PJCYear,@BatchBit,@UpdatedBy_Quality,@UpdatedTs_Quality,@UpdatedBy_MR,@UpdatedTs_MR from InspectionMasterFG_PAMS
			where Process like '%'+@Process+'%' and ProcessType=@ProcessType  AND ReportType=@ReportType AND  ISNULL(ComponentID,'')=ISNULL(@ComponentID,'')  and CharacteristicCode=@CharacteristicCode and RevID=@RevID
		end
		else
		begin
		if isnull(@mrbit,0)=1
		begin
			update InspectionTransactionFinalFGLevel_PAMS set BatchValue=@BatchValue,BatchTS=@BatchTS,UpdatedBy_MR=@UpdatedBy_MR,UpdatedTs_MR=@UpdatedTs_MR,Status=@Status,Remarks=@Remarks,MeasuringInstrumentTran=@MeasuringInstrumentTranValue
			where  ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND  ReportType=@ReportType AND ISNULL(ComponentID,'')=ISNULL(@ComponentID,'') and PJCNo=@PJCNo and PJCYear=@PJCYear and  CharacteristicCode=@CharacteristicCode and BatchID=@BatchID and batchBit=@BatchBit
		end
		else
		begin
			update InspectionTransactionFinalFGLevel_PAMS set BatchValue=@BatchValue,BatchTS=@BatchTS,MeasuringInstrumentTran=@MeasuringInstrumentTranValue,Status=@Status,Remarks=@Remarks,UpdatedBy_Quality=@UpdatedBy_Quality,UpdatedTs_Quality=@UpdatedTs_Quality
			where  ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND  ReportType=@ReportType AND ISNULL(ComponentID,'')=ISNULL(@ComponentID,'') and PJCNo=@PJCNo and PJCYear=@PJCYear and  CharacteristicCode=@CharacteristicCode and BatchID=@BatchID and batchBit=@BatchBit

			update InspectionTransactionFinalFGLevel_PAMS set Status=@Status,Remarks=@Remarks,UpdatedBy_Quality=@UpdatedBy_Quality,UpdatedTs_Quality=@UpdatedTs_Quality
			where ProcessType=@ProcessType AND Process like '%'+@Process+'%' AND   ReportType=@ReportType  AND ISNULL(ComponentID,'')=ISNULL(@ComponentID,'')  and PJCNo=@PJCNo and PJCYear=@PJCYear and CharacteristicCode=@CharacteristicCode and batchBit=@BatchBit
		end
		end
	END


END

end




--	if @ProcessType='RM'
--	BEGIN
--		 update #Inspection set BatchID=(t1.Batchid),vALUE=(t1.val)
--		from
--		(
--				select distinct Process,ReportType ,ProcessType ,ComponentID ,OperationNo ,Rawmaterial,characteristiccode, STUFF((SELECT distinct ',' + cast(L2.BatchID as nvarchar(50))
--				from InspectionTransactionFGLevel_PAMS L2 
--				where l2.Process=l3.Process and l2.ReportType=l3.ReportType and isnull(l2.ComponentID,'')= isnull(l3.ComponentID,'') and 
--				isnull(l2.OperationNo,'')= isnull(l3.OperationNo,'') and  isnull(l2.RawMaterial,'')= isnull(l3.Rawmaterial,'') and isnull(l2.characteristiccode,'')=isnull(l3.characteristiccode,'')
--				and (machine=@Machine or isnull(@Machine,'')='')
--				FOR XML PATH(''), TYPE
--				).value('.', 'NVARCHAR(MAX)') 
--				,1,1,'') Batchid,
--				STUFF((SELECT distinct ',' + L2.Value
--				from InspectionTransactionFGLevel_PAMS L2 
--				where l2.Process=l3.Process and l2.ReportType=l3.ReportType and isnull(l2.ComponentID,'')= isnull(l3.ComponentID,'') and 
--				isnull(l2.OperationNo,'')= isnull(l3.OperationNo,'') and  isnull(l2.RawMaterial,'')= isnull(l3.Rawmaterial,'') and isnull(l2.characteristiccode,'')=isnull(l3.characteristiccode,'')
--				and (machine=@Machine or isnull(@Machine,'')='')
--				FOR XML PATH(''), TYPE
--				).value('.', 'NVARCHAR(MAX)') 
--				,1,1,'') Val from #Inspection l3 
--		) t1 inner join #Inspection on #Inspection.Process=t1.Process and #Inspection.ReportType=t1.ReportType and isnull(#Inspection.ComponentID,'')= isnull(t1.ComponentID,'') and 
--		isnull(#Inspection.OperationNo,'')= isnull(t1.OperationNo,'') and  isnull(#Inspection.RawMaterial,'')= isnull(t1.Rawmaterial,'') and #Inspection.CharacteristicCode=t1.CharacteristicCode
--	END




--select * from #Inspection order by SortOrder
--return

--	select distinct I1.Process, I1.ReportType , I1.ProcessType ,I1.ComponentID , I1.OperationNo , I1.Rawmaterial, I1.specialCharacteristic , I1.CharacteristicID , I1.CharacteristicCode ,
--	 I1.Specification , I1.MeasuringMethod,I1.RevID , I1.RevNo , I1.RevDate , I1.NoOfSamples , I1.MeasuringInstrument , I1.MeasuredValue , I1.ControlType , I1.ControlValue , I1.LSL , I1.USL ,
--	  I1.SortOrder,I2.BatchID,I2.BatchTS,I2.Value from #Inspection I1 LEFT JOIN InspectionTransaction_PAMS I2 ON I1.Process=I2.Process AND I1.ReportType=I2.ReportType AND 
--	ISNULL(I1.ComponentID,'')=ISNULL(I2.ComponentID,'') AND ISNULL(I1.OperationNo,'')=ISNULL(I2.OperationNo,'') AND ISNULL(I1.RawMaterial,'')=ISNULL(I2.RawMaterial,'') and
--	i1.CharacteristicCode=i2.CharacteristicCode


--STUFF((SELECT distinct ',' + L2.Machine
--         from InspectionTransaction_PAMS L2 
--		 where l2.Process=l3.Process and l2.ReportType=l3.ReportType and isnull(l2.ComponentID,'')= isnull(l3.ComponentID,'') and 
--		 isnull(l2.OperationNo,'')= isnull(l3.OperationNo,'') and  isnull(l2.RawMaterial,'')= isnull(l3.Rawmaterial,'') and isnull(l2.characteristiccode,'')=isnull(l3.characteristiccode,'')
--		 and (machine=@Machine or isnull(@Machine,'')='')
--            FOR XML PATH(''), TYPE
--            ).value('.', 'NVARCHAR(MAX)') 
--        ,1,1,'') Mc



--end
