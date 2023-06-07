/****** Object:  Procedure [dbo].[s_GetRejectionRework_Precision]    Committed by VersionSQL https://www.versionsql.com ******/

/*************************************************
-- Author:		Anjana C V
-- Create date: 25th Dec 2018
-- Modified date: 25th Dec 2018
-- Description: Get Rejection Rework
-- [s_GetRejectionRework_Precision] '600KVA AI BUTTWELDER' ,'2018-06-26 15:22:07.603' , '2018-06-28 16:29:07.200','Rejection'
-- [s_GetRejectionRework_Precision] '600KVA AI BUTTWELDER' ,'2018-06-26 15:22:07.603' , '2018-06-28 16:29:07.200',''
*************************************************/

CREATE PROCEDURE [dbo].[s_GetRejectionRework_Precision]  
 @MachineID nvarchar(50) = '',  
 @StartDate datetime,  
 @EndDate datetime,
 @Param nvarchar(100)

WITH RECOMPILE  
AS  
BEGIN  

CREATE TABLE #FinalTarget    
(  
 MachineID nvarchar(50) NOT NULL,  
 machineinterface nvarchar(50), 
 Comp nvarchar(50) NOT NULL,  
 Compinterface nvarchar(50), 
 Opn nvarchar(50) NOT NULL,  
 Opninterface nvarchar(50), 
 Opr nvarchar(50) NOT NULL,  
 Oprinterface nvarchar(50), 
 RName nvarchar(50),
 RDescription nvarchar(100),   
 RDateTime Datetime,
 RQuantity int,
 Flag nvarchar(50)
 )

 If @param = 'Rejection' OR @Param = ''
 BEGIN
 INSERT INTO #FinalTarget (MachineID,machineinterface,Compinterface,Comp,Opninterface,Opn,Oprinterface,Opr,RName,RDescription,
 RDateTime,RQuantity,Flag)
 SELECT DISTINCT M.machineid , M.InterfaceID ,C.InterfaceID , C.componentid , CO.InterfaceID ,CO.operationno , E.interfaceid , E.employeeno ,
 R.rejectionid ,R.rejectiondescription,AR.CreatedTS,AR.Rejection_Qty , AR.Flag
 FROM AutodataRejections AR 
 INNER JOIN machineinformation M ON AR.MC = M.InterfaceID
 INNER JOIN componentinformation C ON AR.comp = C.InterfaceID
 INNER JOIN componentoperationpricing CO ON AR.OPN = CO.InterfaceID and C.componentid=CO.componentid and CO.machineid=M.machineid
 INNER JOIN employeeinformation E ON AR.opr = E.interfaceid
 INNER JOIN rejectioncodeinformation R ON AR.Rejection_Code = R.interfaceid
 WHERE AR.Flag = 'Rejection'
 AND M.machineid = @MachineID
 AND (AR.CreatedTS >= @StartDate AND AR.CreatedTS <= @EndDate)
 END

 If @param = 'MarkedForRework' OR @Param = ''
 BEGIN
  INSERT INTO #FinalTarget(MachineID,machineinterface,Compinterface,Comp,Opninterface,Opn,Oprinterface,Opr,RName,RDescription,
 RDateTime,RQuantity,Flag)
 SELECT DISTINCT  M.machineid , M.InterfaceID ,C.InterfaceID , C.componentid , CO.InterfaceID ,CO.operationno , E.interfaceid , E.employeeno , 
 R.REWORKID ,R.REWORKDESCRIPTION,AR.CreatedTS,AR.Rejection_Qty , AR.Flag
 FROM AutodataRejections AR INNER JOIN machineinformation M ON AR.MC = M.InterfaceID
 INNER JOIN componentinformation C ON AR.comp = C.InterfaceID
 INNER JOIN componentoperationpricing CO ON AR.OPN = CO.InterfaceID and C.componentid=CO.componentid and CO.machineid=M.machineid
 INNER JOIN employeeinformation E ON AR.opr = E.interfaceid
 INNER JOIN Reworkinformation R ON AR.Rejection_Code = R.REWORKINTERFACEID
 WHERE AR.Flag = 'MarkedForRework'
 AND M.machineid = @MachineID
 AND (AR.CreatedTS >= @StartDate AND AR.CreatedTS <= @EndDate)
 END

 If @param = 'ReworkPerformed' OR @Param = ''
 BEGIN
   INSERT INTO #FinalTarget(MachineID,machineinterface,Compinterface,Comp,Opninterface,Opn,Oprinterface,Opr,RName,RDescription,
 RDateTime,RQuantity,Flag)
 SELECT DISTINCT M.machineid , M.InterfaceID ,C.InterfaceID , C.componentid , CO.InterfaceID ,CO.operationno , E.interfaceid , E.employeeno ,
  R.REWORKID ,R.REWORKDESCRIPTION,AR.CreatedTS,AR.Rejection_Qty, AR.Flag
 FROM AutodataRejections AR INNER JOIN machineinformation M ON AR.MC = M.InterfaceID
 INNER JOIN componentinformation C ON AR.comp = C.InterfaceID
 INNER JOIN componentoperationpricing CO ON AR.OPN = CO.InterfaceID and C.componentid=CO.componentid and CO.machineid=M.machineid
 INNER JOIN employeeinformation E ON AR.opr = E.interfaceid
 INNER JOIN Reworkinformation R ON AR.Rejection_Code = R.REWORKINTERFACEID
 WHERE AR.Flag = 'ReworkPerformed'
 AND M.machineid = @MachineID
 AND (AR.CreatedTS >= @StartDate AND AR.CreatedTS <= @EndDate)
 END

 
 SELECT * FROM #FinalTarget order by Flag,RDateTime

END
