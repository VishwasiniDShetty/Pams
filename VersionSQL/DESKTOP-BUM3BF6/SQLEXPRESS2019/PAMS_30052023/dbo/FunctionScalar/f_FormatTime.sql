/****** Object:  Function [dbo].[f_FormatTime]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0401 - SwathiKS - 31/Dec/2014 :: To consider "5" decimal places instead of "2" decimal places when timeformat="hh".
CREATE    Function [dbo].[f_FormatTime] 
--(@Number decimal(38,5),@Format as nvarchar(8))
(@Number decimal(38,5),@Format as nvarchar(20))
RETURNS nvarchar(25)
AS
BEGIN
declare @hh as nvarchar(25)
declare @mm as nvarchar(25)
declare @ss as nvarchar(25)
Declare @AA as Decimal(38,2)
Declare @AA1 as Decimal(38,5)--ER0401

IF @Format is null or @Format = '' SET @Format = 'ss'
IF (@Number is Null or isnumeric(@Number) = 0) SET @Number = 0
	
IF @Format = 'hh'
BEGIN
	--SET @AA = ROUND(convert(Decimal(38,2), @Number)/3600,2)--ER0401
	--SET @hh = Convert(nvarchar(25),@AA)--ER0401
	SET @AA1 = ROUND(convert(Decimal(38,5), @Number)/3600,5)--ER0401
	SET @hh = Convert(nvarchar(25),@AA1)--ER0401
	RETURN @hh
END

IF @Format = 'mm'
BEGIN
SET @AA = ROUND(convert(Decimal(38,2), @Number)/60,2)
	SET @mm = Convert(nvarchar(25),@AA)
	RETURN @mm
END
IF @Format = 'ss'
BEGIN
	SET @ss = CONVERT(Varchar(25),Convert(Decimal(38,0),@Number))
	RETURN @ss
END


IF @Format = 'hh:mm:ss'
BEGIN
IF @Number = 0
RETURN '00:00:00'
DECLARE @hours as decimal(38,5)
DECLARE @hhh as bigint
DECLARE @minutes as decimal(38,5)
DECLARE @mmm as int
DECLARE @sss as int
DECLARE @StrHH as nvarchar(14)
DECLARE @StrMM as nvarchar(3)
DECLARE @StrSS as nvarchar(3)
SET @hours = Round(ABS(@Number)/ 3600, 5)
SET @hhh = Convert(bigint,@hours)
SET @minutes = Round(((@hours - @hhh) * 60), 5)
SET @mmm = Convert(Int,@minutes)
SET @sss = CONVERT(int,Round((@minutes - @mmm) * 60,0))
If @sss = 60
Begin
SET @mmm = @mmm + 1
SET @sss = 0
End
If @mmm = 60
BEGIN
SET @hhh = @hhh + 1
SET @mmm = 0
End
--  If @Number < 0
	-- SET @hhh = @hhh * -1
--format the return value as a string
If @Number < 0
SET @StrHH = '-' + CONVERT(nvarchar(14),@hhh)
Else
	If @hhh <= 9
SET @StrHH = '0' + CONVERT(nvarchar(14), @hhh)
Else
SET @StrHH = CONVERT(nvarchar(14),@hhh)
If @mmm <= 9
	SET @StrMM = '0' + CONVERT(nvarchar(3),@mmm)
Else
	SET @StrMM = CONVERT(nvarchar(3),@mmm)
If @sss <= 9
SET @StrSS = '0' + CONVERT(nvarchar(3),@sss)
Else
	SET @StrSS = CONVERT(nvarchar(3),@sss)
RETURN @StrHH + ':' + @StrMM + ':' + @StrSS
	
END

IF @Format = 'hh:mm'
BEGIN
IF @Number = 0
RETURN '0:0'
DECLARE @hours1 as decimal(38,5)
DECLARE @hhh1 as bigint
DECLARE @minutes1 as decimal(38,5)
DECLARE @mmm1 as int
DECLARE @sss1 as int
DECLARE @StrHH1 as nvarchar(14)
DECLARE @StrMM1 as nvarchar(3)
DECLARE @StrSS1 as nvarchar(3)
SET @hours1 = Round(ABS(@Number)/ 3600, 5)
SET @hhh1 = Convert(bigint,@hours1)
SET @minutes1 = Round(((@hours1 - @hhh1) * 60), 5)
SET @mmm1 = Convert(Int,@minutes1)
SET @sss1 = CONVERT(int,Round((@minutes1 - @mmm1) * 60,0))
If @sss1 = 60
Begin
SET @mmm1 = @mmm1 + 1
SET @sss1 = 0
End
If @mmm1 = 60
BEGIN
SET @hhh1 = @hhh1 + 1
SET @mmm1 = 0
End

If @Number < 0
SET @StrHH1 = '-' + CONVERT(nvarchar(14),@hhh1)
Else
	If @hhh1 <= 9
SET @StrHH1 = CONVERT(nvarchar(14), @hhh1)
Else
SET @StrHH1 = CONVERT(nvarchar(14),@hhh1)
If @mmm1 <= 9
	SET @StrMM1 = CONVERT(nvarchar(3),@mmm1)
Else
	SET @StrMM1 = CONVERT(nvarchar(3),@mmm1)
If @sss1 <= 9
	SET @StrSS1 =  CONVERT(nvarchar(3),@sss1)
Else
	SET @StrSS1 = CONVERT(nvarchar(3),@sss1)

--if @StrHH1=0 and @StrMM1<>0
--RETURN  @StrMM1 
--else
RETURN  @StrHH1 + ':' + @StrMM1
	
END


IF @Format = 'hh:mm hrs/mins'
BEGIN
IF @Number = 0
RETURN '0:0'

SET @hours1 = Round(ABS(@Number)/ 3600, 5)
SET @hhh1 = Convert(bigint,@hours1)
SET @minutes1 = Round(((@hours1 - @hhh1) * 60), 5)
SET @mmm1 = Convert(Int,@minutes1)
SET @sss1 = CONVERT(int,Round((@minutes1 - @mmm1) * 60,0))
If @sss1 = 60
Begin
SET @mmm1 = @mmm1 + 1
SET @sss1 = 0
End
If @mmm1 = 60
BEGIN
SET @hhh1 = @hhh1 + 1
SET @mmm1 = 0
End

If @Number < 0
SET @StrHH1 = '-' + CONVERT(nvarchar(14),@hhh1)
Else
	If @hhh1 <= 9
SET @StrHH1 = CONVERT(nvarchar(14), @hhh1)
Else
SET @StrHH1 = CONVERT(nvarchar(14),@hhh1)
If @mmm1 <= 9
	SET @StrMM1 = CONVERT(nvarchar(3),@mmm1)
Else
	SET @StrMM1 = CONVERT(nvarchar(3),@mmm1)
If @sss1 <= 9
	SET @StrSS1 =  CONVERT(nvarchar(3),@sss1)
Else
	SET @StrSS1 = CONVERT(nvarchar(3),@sss1)

--if @StrHH1=0 and @StrMM1<>0
--RETURN  @StrMM1 
--else
RETURN  @StrHH1 + 'h' + ':' + @StrMM1 + 'm'
	
END

RETURN '00:00:00'

END
