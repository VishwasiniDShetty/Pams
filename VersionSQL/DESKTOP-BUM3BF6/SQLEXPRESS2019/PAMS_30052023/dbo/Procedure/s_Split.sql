/****** Object:  Procedure [dbo].[s_Split]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- NR0095 :: Author:		Satyendraj
-- Create date: 6-Dec-2013
-- Description:	Split the data based on delimater
-- s_Split '1,2,3,4',','
-- =============================================
CREATE PROCEDURE [dbo].[s_Split] 
	@dataToSplit  VARCHAR(MAX),
	@splitChar char = ','
AS
BEGIN	
		SET NOCOUNT ON
		SET XACT_ABORT ON
		CREATE TABLE #temp_EMPID (EMPID VARCHAR(25))		
		DECLARE @t VARCHAR(MAX)
		DECLARE @I INT		
		SELECT @I = 0
		WHILE(@I <=LEN(@dataToSplit))
		BEGIN
		  SELECT @t = SUBSTRING(@dataToSplit,@I,1)
		  if(@t<>','and @t<>'')
		  BEGIN
			  Insert into #temp_EMPID SELECT SUBSTRING(@dataToSplit, @I, CHARINDEX(@splitChar, @dataToSplit + @splitChar, @I) - @I)
			  where substring(@splitChar+@dataToSplit,@I,1)=@splitChar AND @I < LEN(@dataToSplit) + 1
		  END
		  SET @I = @I + 1
		END
		
		SELECT EMPID FROM #temp_EMPID
		DROP TABLE #TEMP_EMPID	
END
