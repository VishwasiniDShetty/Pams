/****** Object:  Procedure [dbo].[S_GetScheduledReports]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************************************************
--NR0067 - KarthikG - 22/May/2010 :: Enable emailing feature in schedule reports.
--ER0274 -KarthikR -05-dec-2010 :: To add one more column called reportid
--ER0283 - SwathiKS - 02/May/2011 :: To add one more Column RunReportForEvery.
--ER0364 - SwathiKS - 30/Sep/2013 :: To Select Entries other than RunReportForEvery<>Now
--ER0372 - Asif Iqbal - 21-Jan-2014 :: To replace the case 4 to Monthly.
---        satyendra - 21-March-2014 :: To replace the case 5 to Weekly
*********************************************************************************/
CREATE   PROCEDURE [dbo].[S_GetScheduledReports] 
AS
BEGIN

SELECT Slno,ReportName,
CASE ExportType
      WHEN '0' THEN 'Excel'
      WHEN '1' THEN 'HTML'
      WHEN '2' THEN 'MS Word'
      WHEN '3' THEN 'Print'
      WHEN '4' THEN 'PDF'
      ELSE 'Format Not Selected'
   END AS ExportType, 
ExportFileName, ExportPath,PlantID, Machine,Shift,Operator,
CASE DayBefores
      WHEN '0' THEN 'Today''s Data'
      WHEN '1' THEN 'One Day Before Data'
      WHEN '2' THEN 'Two Days Before Data'
      WHEN '3' THEN 'Three Days Before Data'
--ER0372 starts here
--    WHEN '4' THEN 'Four Days Before Data'
	  WHEN '4' THEN 'Monthly'
	  WHEN '5' THEN 'Weekly'
--ER0372 Ends here
      ELSE 'Day Not Selected'
   END AS DayBefores, Email_Flag,Email_List_TO,Email_List_CC,Email_List_BCC
--ER0274
,ReportID
--ER0274

--ER0283
,RunReportForEvery
--ER0283

FROM  ScheduledReports 
Where RunReportForEvery<>'Now' --ER0364 Added
END
