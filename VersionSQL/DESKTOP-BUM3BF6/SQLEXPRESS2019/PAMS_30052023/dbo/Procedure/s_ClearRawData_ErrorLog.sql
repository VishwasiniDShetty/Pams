/****** Object:  Procedure [dbo].[s_ClearRawData_ErrorLog]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************************************************************************
Procedure created By Karthik G On 20-Jul-2009. 
NR0058 - Karthik G - 20-Jul-2009 - To clear the old RawData records which are processed i.e.. where status in (1,15) 
and clear data from SmartDataErrorLog leaving last 1000 records.
**************************************************************************************************/

CREATE procedure [dbo].[s_ClearRawData_ErrorLog]
As
Begin
DECLARE  @Mc As Nvarchar(50)
DECLARE RD_CURSOR CURSOR FOR SELECT distinct mc FROM RawData order by mc

	OPEN RD_CURSOR
	FETCH NEXT FROM RD_CURSOR INTO @mc
	WHILE @@FETCH_STATUS = 0
	BEGIN

		Delete rawdata where 
		slno not in (select top 50000 slno from rawdata where mc = @mc order by slno desc) and 
		mc = @mc and status in (1,15)

		FETCH NEXT FROM RD_CURSOR INTO @mc
	END
	CLOSE RD_CURSOR
	DEALLOCATE RD_CURSOR

	Delete smartdataerrorlog where id not in (select top 50000 id from smartdataerrorlog order by id desc)

End
