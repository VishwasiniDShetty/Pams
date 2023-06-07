/****** Object:  Function [dbo].[SplitAlphanumeric]    Committed by VersionSQL https://www.versionsql.com ******/

create FUNCTION [dbo].[SplitAlphanumeric]
(@str VARCHAR(8000), @validchars VARCHAR(8000))
RETURNS VARCHAR(8000)
BEGIN
declare @t as int
Set @t=0
WHILE PATINDEX('%[' + @validchars + ']%',@str) > 0
begin
SET @str=REPLACE(@str, SUBSTRING(@str ,PATINDEX('%['
+ @validchars +']%',@str), 1) ,'')
set @t=@t+1
end
RETURN @str
END
