/****** Object:  Procedure [dbo].[s_GetOprGroupId]    Committed by VersionSQL https://www.versionsql.com ******/

/*******************************************************************************************************
NR0043:Procedure created by Shilpa H.M on 12-May-08 to support Operator Grouping for JohnDeere
:This procedure creates the group if it does not exist
ER0421- SwathiKS- 30/dec/2015 :: To handle if @opr is '0' or single entry i.e '1'
********************************************************************************************************/
--[dbo].[s_GetOprGroupId]  '0:00000'
CREATE         procedure [dbo].[s_GetOprGroupId] 
@Opr nvarchar(50)
As

Declare @i as integer
Declare @Temp as nvarchar(50)
Declare @Comp_Def as nvarchar(50)
Declare @TempId as nvarchar(50)
Declare @Sep as nvarchar(2)
Declare @TempChk as nvarchar(50)

Begin
	Select @Sep=groupseperator1 from smartdataportrefreshdefaults
	Set @Opr = @Opr + @Sep
	
	Create Table #temp(Opr bigint)
	Create Table #temp1([ID] int IDENTITY(1,1),Opr1 bigint)
	

 While charindex(@Sep,@Opr)>0
  Begin
	insert into #Temp  values(substring(@Opr,1,charindex(@Sep,@Opr)-1))
	set @Opr = substring(@Opr,charindex(@Sep,@Opr)+1,len(@opr)-charindex(@Sep,@Opr)+1)		
  End--While


 Insert into #Temp1(Opr1) select Opr from #temp where opr<>0 order by Opr 

 Set @Comp_Def=''
 Set @Temp = ''

 select  @i = min(id) from #Temp1	
 while @i<= (select max(id) from #Temp1) 
   begin
	set @Temp=@Temp + @Sep + (select cast(Opr1 as nvarchar(50)) from #temp1 where id=@i)
	Set @i=@i+1
   end

--ER0421 Added From here
IF (Select Count(*) from #temp1)= '0'
BEGIN
	Return
END
--ER0421 Added Till here


Set @Temp=Substring(@Temp,2,len(@Temp)-1)
If exists (Select * from employeeinformation where interfaceid=@Temp and operate=1) 
Begin
	Select @Temp
	Return
End--IF

--ER0421 Added From here
 If exists (Select * from employeeinformation where interfaceid=@Temp) 
 Begin
	Select @Temp
	Return
 End--IF
--ER0421 Added Till here

Set @TempChk=@Temp + @Sep
While charindex(@Sep,@TempChk)>0
Begin
 if NOT Exists (select interfaceid from employeeinformation where InterfaceID= substring(@TempChk,1,charindex(@Sep,@TempChk)-1))
 Begin	
	   
    	    select @Comp_Def='XYZ'
	    select  @Comp_Def = interfaceid from employeeinformation where Company_default = 1
	    set @Temp = @Comp_Def
	    Select @Temp
	    return
 End
 Set @TempChk = substring(@TempChk,charindex(@Sep,@TempChk)+1,len(@TempChk)-charindex(@Sep,@TempChk)+1)
End --while 

Select @Sep=groupseperator2 from smartdataportrefreshdefaults

  If not exists (select * from employeeinformation where interfaceid=@Temp and operate =1)
     Begin
 	select  @i = min(id) from #Temp1
     	While @i<=(select max(id) from #Temp1) 
 	 Begin  
		Select @TempId=employeeid from employeeinformation where interfaceid=(select cast(opr1 as nvarchar(50)) from #temp1 where id=@i)  
		Set @Comp_Def=@Comp_Def + @Sep + @TempId
		Insert into employeegroups(Groupid,OperatorID) values(@Temp,@TempId)
	  	Set @i=@i+1
 	 End
		
	If len(@Comp_Def)>=50
          Begin
	     Raiserror('Error-Employeeid is exceeding 50 characters', 16,@Comp_Def)
	     Delete from employeegroups where groupid=@Temp
	     Return -1
	  End

	Set @TempId=substring(@Comp_Def,2,len(@Comp_Def)-1)
	Insert into employeeinformation(Employeeid,Name,Operate,interfaceid) values(@TempId,@TempId,1,@Temp)
   End--If
 Select @Temp 
Return 

End
