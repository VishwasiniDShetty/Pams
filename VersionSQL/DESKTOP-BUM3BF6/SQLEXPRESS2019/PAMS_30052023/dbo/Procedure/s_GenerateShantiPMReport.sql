/****** Object:  Procedure [dbo].[s_GenerateShantiPMReport]    Committed by VersionSQL https://www.versionsql.com ******/

/*
ER0462 - Gopinath - 05/Apr/2018 :: New Procedure To Export PM Details For Shanti.
exec [s_GenerateShantiPMReport] '2017-11-01 00:00:00', '2017-11-28 00:00:00', ''
exec [s_GenerateShantiPMReport] '2017-11-1 00:00:00', '2017-11-28 00:00:00', 'CT11'
exec [s_GenerateShantiPMReport] '2017-11-1 00:00:00', '2017-11-28 00:00:00', 'CT10'
*/
CREATE PROCEDURE [dbo].[s_GenerateShantiPMReport]
 @StartTime datetime output,    
 @EndTime datetime output,    
 @MachineID nvarchar(50) = '',
 @GroupID As nvarchar(50) = ''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT pma.RecordType, pma.Machine, pma.Starttime, pma.Reason, pma.MainCategory, pma.SubCategory INTO #tmp
FROM
(
  SELECT *, datepart(month, starttime) mnth, 
  ROW_NUMBER() OVER (PARTITION BY maincategory, subcategory,datepart(month, starttime), machine ORDER BY Starttime DESC) AS ROWNO
  FROM PM_AutodataDetails
  WHERE Starttime >= @StartTime AND Starttime <= @EndTime AND recordtype IN (57,58) --AND (Machine=@MachineID OR @MachineID='') 
) AS pma
WHERE pma.recordtype IN (57,58) AND pma.ROWNO=1

SELECT * 
INTO #pmi
FROM
(
SELECT pmi.Category, pmi.SubCategory, pmi.SubCategoryID, pmi.Frequency, mi.description AS MachineType
FROM PM_Information pmi, machineinformation mi
WHERE mi.description not in (SELECT DISTINCT ISNULL(MachineType, 'GENERAL') FROM PM_Information) AND pmi.MachineType = 'GENERAL'
UNION
SELECT pmi.Category, pmi.SubCategory, pmi.SubCategoryID, pmi.Frequency, pmi.MachineType
FROM PM_Information pmi
WHERE pmi.MachineType <> 'GENERAL'
) tmp


SELECT mi.machineid,pmg.GroupID, -- mi.description, pmi.MachineType, 
CASE  pma.RecordType WHEN 56 THEN 'TEST' WHEN 57 THEN 'OK' WHEN 58 THEN 'NOT OK' END Record, pma.Machine, pma.Starttime, 
CASE ISNULL(dci.downid, '') WHEN '' THEN pma.Reason ELSE dci.downid END AS Reason, 
pmc.Category,
pmi.SubCategory, datepart(month, pma.starttime) AS mon
FROM #tmp pma 
INNER JOIN PM_Category pmc ON pma.MainCategory = pmc.InterfaceID 
INNER JOIN  #pmi pmi ON pmi.SubCategoryID = pma.SubCategory AND pmi.Category=pmc.Category 
INNER JOIN  machineinformation mi ON mi.InterfaceID=pma.Machine AND (mi.machineid=@MachineID OR @MachineID='') 
LEFT JOIN PlantMachineGroups pmg on mi.machineid = pmg.machineid AND (pmg.GroupID=@GroupID or isnull(@GroupId,'')='')
LEFT OUTER JOIN  downcodeinformation dci ON dci.interfaceid=pma.Reason
WHERE mi.description = pmi.MachineType
ORDER BY mi.machineid, pma.Starttime DESC

END    
