/****** Object:  Function [dbo].[SplitStrings]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0453 - Gopinath - 23/Oct/2017 :: created New Function To Split CommaSeparated Strings e.g. @Input= 'a,b,c' Return Output=a,b,c
-- select item from [SplitStrings]('a,b,c', '')


    CREATE FUNCTION [dbo].[SplitStrings]
    (
       @List       NVARCHAR(MAX),
       @Delimiter  NVARCHAR(255)
    )
    RETURNS @Items TABLE (Item NVARCHAR(4000))
    WITH SCHEMABINDING
    AS
    BEGIN
	   
       DECLARE @ll INT 
	   declare  @ld INT
	   set @ll = LEN(@List) + 1
	   set @ld = LEN(@Delimiter);
     
       WITH a AS
       (
           SELECT
               [start] = 1,
               [end]   = COALESCE(NULLIF(CHARINDEX(@Delimiter, 
                           @List, 1), 0), @ll),
               [value] = SUBSTRING(@List, 1, 
                         COALESCE(NULLIF(CHARINDEX(@Delimiter, 
                           @List, 1), 0), @ll) - 1)
           UNION ALL
           SELECT
               [start] = CONVERT(INT, [end]) + @ld,
               [end]   = COALESCE(NULLIF(CHARINDEX(@Delimiter, 
                           @List, [end] + @ld), 0), @ll),
               [value] = SUBSTRING(@List, [end] + @ld, 
                         COALESCE(NULLIF(CHARINDEX(@Delimiter, 
                           @List, [end] + @ld), 0), @ll)-[end]-@ld)
           FROM a
           WHERE [end] < @ll
       )
       INSERT @Items SELECT [value]
       FROM a
       WHERE LEN([value]) > 0
       OPTION (MAXRECURSION 0);
     
		if (@List = '')
		begin
			insert into @Items values ('')
	    end
       RETURN;
    END
