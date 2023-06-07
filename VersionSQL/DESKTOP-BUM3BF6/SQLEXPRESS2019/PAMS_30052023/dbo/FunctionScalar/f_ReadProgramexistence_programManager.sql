/****** Object:  Function [dbo].[f_ReadProgramexistence_programManager]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************************************************************
ER0309 - KarthikR - 11/Nov/2011 :: Created New Function To Check Existence of Programfile for the selected M-C-O.
--Select * from programmanager
--select dbo.f_ReadProgramexistence_programManager ('MLC PUMA 220','23.txt','DC 5739',1)
********************************************************************************************/
Create    Function [dbo].[f_ReadProgramexistence_programManager] 
(@Machineid nvarchar(50),@programfile nvarchar(250),@componentid nvarchar(50),@operationNo int)
RETURNS nvarchar(2500)
AS
BEGIN

declare @Machineidlist as nvarchar(2500)
declare @comp nvarchar(50)
declare @opn int
Set @Machineidlist=''
Set @comp=''
Set @Opn=''
select @Machineidlist=coalesce(@Machineidlist + ',','')+T2.machineid
from 
(Select m1.machineid from machinecontrolinformation m1
where m1.machineid in (select distinct machineid from programmanager where programfile=@programfile)
and m1.Receiveatmachinefilepath in 
(Select Receiveatmachinefilepath from machinecontrolinformation where machineid=@Machineid))T2
if len(@Machineidlist)>0 and isnull(@Machineidlist,'')<>'' and @Machineidlist<>''
begin 
set @Machineidlist=substring(@Machineidlist,2,len(@Machineidlist))
if @Machineidlist like '%'+@Machineid+'%'
	begin
		Select @comp=componentid , @opn=operationNo from programmanager where machineid=@Machineid and programfile=@programfile 
		if (@comp<>'' and  isnull(@comp,'')<>'' and @opn<>'' and  isnull(@opn,0)<>0 )and 
			 (@comp<>@componentid or @operationNo<>@opn)
			Begin 
				if len(@Machineidlist)>len(@Machineid)
					begin
								Select @Machineidlist=@Machineidlist +' also for the selected machine
								with different Component-Operation,'
		+ CHAR(13) + 'Do you want to delete and create new M-C-0?'
					end
					else
						begin
							Select @Machineidlist=@Machineidlist+ ' with different Component-Operation,'
					+ CHAR(13) +' Do you want to delete and create new M-C-0?'
					end
			End

			Else
				begin
					Select @Machineidlist=@Machineidlist+ CHAR(13) +  ' Do you want to proceed?'
				End 
	End
	else
		begin
			Select @Machineidlist=@Machineidlist+ CHAR(13) +  ' Do you want to proceed?'
		end
end

RETURN @Machineidlist
END
