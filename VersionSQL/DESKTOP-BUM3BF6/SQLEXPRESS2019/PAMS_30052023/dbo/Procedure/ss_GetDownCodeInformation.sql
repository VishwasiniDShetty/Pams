/****** Object:  Procedure [dbo].[ss_GetDownCodeInformation]    Committed by VersionSQL https://www.versionsql.com ******/

/*
ss_GetDownCodeInformation 'unknown','','','Searchdownid'
*/
CREATE PROCEDURE [dbo].[ss_GetDownCodeInformation]
	@downid nvarchar(50)='',
	@interfaceid nvarchar(50)='',
	@category nvarchar(50)='',
	@param nvarchar(50)=''
AS
BEGIN
	
	SET NOCOUNT ON;

if(@param = 'Searchdownid')
BEGIN
		If @downid <> ''
			BEGIN
				select downid,interfaceid,downdescription,Catagory,availeffy,retpermchour,threshold,prodeffy,thresholdfromCO,
				case downid when 'unknown' then CONVERT(bit, 1)
				when 'NO_DATA' then CONVERT(bit, 1)
				when 'Absent' then CONVERT(bit, 1)
				when 'Early Closure' then CONVERT(bit, 1)
				when 'Dummy Cycle' then CONVERT(bit, 1)
				when 'SCI' then CONVERT(bit, 1)
				when 'SCIU' then CONVERT(bit, 1)
				when 'DCL' then CONVERT(bit, 1)
				when 'DCLU' then CONVERT(bit, 1)
				else CONVERT(bit, 0)  end as result,[Owner] from downcodeinformation where downid like @downid + '%'
				order by downid
			END
		If @downid = ''
			BEGIN
				select downid,interfaceid,downdescription,Catagory,availeffy,retpermchour,threshold,prodeffy,thresholdfromCO,
				case downid when 'unknown' then CONVERT(bit, 1)
				when 'NO_DATA' then CONVERT(bit, 1)
				when 'Absent' then CONVERT(bit, 1)
				when 'Early Closure' then CONVERT(bit, 1)
				when 'Dummy Cycle' then CONVERT(bit, 1)
				when 'SCI' then CONVERT(bit, 1)
				when 'SCIU' then CONVERT(bit, 1)
				when 'DCL' then CONVERT(bit, 1)
				when 'DCLU' then CONVERT(bit, 1)
				else CONVERT(bit, 0)  end as result,[Owner] from downcodeinformation 
				order by downid
			END
END



if(@param = 'searchInterfaceid')
BEGIN
	if @interfaceid <>''
		BEGIN
				select downid,interfaceid,downdescription,Catagory,availeffy,retpermchour,threshold,prodeffy,thresholdfromCO,
				case downid when 'unknown' then 1
				when 'NO_DATA' then 1 
				when 'Absent' then 1
				when 'Early Closure' then 1
				when 'Dummy Cycle' then 1
				when 'SCI' then 1
				when 'SCIU' then 1
				when 'DCI' then 1
				when 'DCLU' then 1
				else 0  end as result,[Owner] from downcodeinformation  where interfaceid like @interfaceid + '%'
			order by interfaceid
		END

	if @interfaceid = ''
		BEGIN
				select downid,interfaceid,downdescription,Catagory,availeffy,retpermchour,threshold,prodeffy,thresholdfromCO,
				case downid when 'unknown' then 1
				when 'NO_DATA' then 1 
				when 'Absent' then 1
				when 'Early Closure' then 1
				when 'Dummy Cycle' then 1
				when 'SCI' then 1
				when 'SCIU' then 1
				when 'DCI' then 1
				when 'DCLU' then 1
				else 0  end as result,[Owner] from downcodeinformation 
			order by interfaceid
		END
END

if(@param = 'searchcategory')
BEGIN
	if @category <>''
		BEGIN
				select downid,interfaceid,downdescription,Catagory,availeffy,retpermchour,threshold,prodeffy,thresholdfromCO,
				case downid when 'unknown' then 1
				when 'NO_DATA' then 1 
				when 'Absent' then 1
				when 'Early Closure' then 1
				when 'Dummy Cycle' then 1
				when 'SCI' then 1
				when 'SCIU' then 1
				when 'DCI' then 1
				when 'DCLU' then 1
				else 0  end as result,[Owner] from downcodeinformation  where catagory like @category + '%'
			order by catagory
		END

	if @category = ''
		BEGIN
				select downid,interfaceid,downdescription,Catagory,availeffy,retpermchour,threshold,prodeffy,thresholdfromCO,
				case downid when 'unknown' then 1
				when 'NO_DATA' then 1 
				when 'Absent' then 1
				when 'Early Closure' then 1
				when 'Dummy Cycle' then 1
				when 'SCI' then 1
				when 'SCIU' then 1
				when 'DCI' then 1
				when 'DCLU' then 1
				else 0  end as result,[Owner] from downcodeinformation 
			order by catagory
		END


END

END
