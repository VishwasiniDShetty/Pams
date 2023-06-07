/****** Object:  Procedure [dbo].[s_GetLookups]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************
ER0346:: Created on : 8th Jan 2013 By Geetanjali Kore :: Lookup for master tables
ER0502:SwathiKS:12/Mar/2021::To Use EM_MachineInformation instead of Machineinformation.
Going forward we will store Machines in EM_MachineInformation Table which are enabled for Energy Data Collection instead of Machineinformation. 
To Assign Machines To Plant Use EM_PlantMachine instead of PlantMachine Table. 

s_GetLookups 'opn','CNC-15','','LA25BWD03-LKD'
S_GetLookUps 'Machine','CNC SHOP1','asc','','SIEMENS'
S_GetLookUps 'Group','AMIT'
*******************************************/
CREATE procedure [dbo].[s_GetLookups]
 @name nvarchar(50),--Plant,Machine,AlarmCategory,PredefinedTimePeriod,Comp,operation,Group,MachineByCell
 @filter nvarchar(100)='',
 @order varchar(5)='asc',
 @filter1 nvarchar(50)='',
 @ControllerType nvarchar(50)='',
 @GroupId nvarchar(50) =''
as
begin
declare @strsql nvarchar(4000)
Create table #shift (shiftname nvarchar(50))

declare @strgroupid as nvarchar(1000)
select @strgroupid=''

If ISNULL(@GroupId,'')<>''
BEGIN
	SELECT @strgroupid=' AND pmg.groupid=N'''+ @GroupId +''''
END

if @name='Plant' 
begin
	set @strsql=''
	set   @strsql='Select distinct pm.Plantid from plantmachine pm inner join machineinformation mi
	on   pm.machineid=mi.machineid and  tpmtrakenabled=1 order by pm.plantid '
	set @strsql= @strsql + @order
	exec(@strsql)
end

if @name='Machine' and @filter=''
begin
	set @strsql=''
	set @strsql='select Machineid from machineinformation where tpmtrakenabled=1 order by machineid '
	set @strsql= @strsql + @order
	exec(@strsql)
end

if @name='Machine' and @filter<>''
begin
	--set @strsql=''
	--set   @strsql='Select mi.Machineid from plantmachine pm inner join machineinformation mi
	--on   pm.machineid=mi.machineid and  tpmtrakenabled=1 and pm.plantid='
	--set @strsql= @strsql +''''+@filter+''''
	--set @strsql= @strsql+' order by mi.machineid '
	--set @strsql= @strsql + @order
	--exec(@strsql)
	if(@order = 'asc')
	BEGIN
	select mi.Machineid from plantmachine pm inner join machineinformation mi on pm.Machineid = mi.Machineid and 
	TpmTrakEnabled=1 and (pm.plantid=@filter or @filter='') and (mi.ControllerType = @ControllerType or @ControllerType = '')
	order by mi.Machineid asc
	END
	else
	BEGIN
	select mi.Machineid from plantmachine pm inner join machineinformation mi on pm.Machineid = mi.Machineid and 
	TpmTrakEnabled=1 and (pm.plantid=@filter or @filter='') and (mi.ControllerType = @ControllerType or @ControllerType = '')
	order by mi.Machineid desc
	END

end

if @name='EM_Plant' 
begin
	set @strsql=''
	set   @strsql='Select distinct pm.Plantid from EM_PlantMachine pm inner join EM_Machineinformation mi
	on   pm.machineid=mi.machineid and IsEnabled=1 order by pm.plantid '
	set @strsql= @strsql + @order
	exec(@strsql)
end

if @name='EM_Machine' and @filter=''
begin
	set @strsql=''
	set @strsql='select Machineid from EM_Machineinformation where IsEnabled=1 order by machineid '
	set @strsql= @strsql + @order
	exec(@strsql)
end

if @name='EM_Machine' and @filter<>''
begin
	--set @strsql=''
	--set   @strsql='Select mi.Machineid from plantmachine pm inner join machineinformation mi
	--on   pm.machineid=mi.machineid and  tpmtrakenabled=1 and pm.plantid='
	--set @strsql= @strsql +''''+@filter+''''
	--set @strsql= @strsql+' order by mi.machineid '
	--set @strsql= @strsql + @order
	--exec(@strsql)
	if(@order = 'asc')
	BEGIN
	select mi.Machineid from EM_PlantMachine pm inner join EM_Machineinformation mi on pm.Machineid = mi.Machineid and 
	IsEnabled=1 and (pm.plantid=@filter or @filter='') --and (mi.ControllerType = @ControllerType or @ControllerType = '')
	order by mi.Machineid asc
	END
	else
	BEGIN
	select mi.Machineid from EM_PlantMachine pm inner join EM_Machineinformation mi on pm.Machineid = mi.Machineid and 
	IsEnabled=1 and (pm.plantid=@filter or @filter='') --and (mi.ControllerType = @ControllerType or @ControllerType = '')
	order by mi.Machineid desc
	END

end

if @name='Group' and @filter<>''
begin
	set @strsql=''
	set   @strsql='Select distinct pmg.GroupID from plantmachine pm 
	inner join PlantMachineGroups pmg on   pm.Plantid=pmg.Plantid 
	and pm.plantid=('''+ @filter+ ''')'
	set @strsql= @strsql+' order by pmg.GroupID '
	set @strsql= @strsql + @order
	print @strsql
	exec(@strsql)
	
end

if @name='Group' and @filter=''
begin
	set @strsql=''
	set   @strsql='Select distinct pmg.GroupID from plantmachine pm 
	inner join PlantMachineGroups pmg on   pm.Plantid=pmg.Plantid '
	set @strsql= @strsql+' order by pmg.GroupID '
	set @strsql= @strsql + @order
	print @strsql
	exec(@strsql)	
end

if @name='MachineByCell'  and @filter<>''
begin
	set @strsql=''
	set   @strsql='Select distinct mi.Machineid from plantmachine pm 
	inner join machineinformation mi on pm.machineid=mi.machineid --and  tpmtrakenabled=1 
	and pm.plantid in ('''+ @filter+ ''')
	inner join PlantMachineGroups pmg on pm.Plantid=pmg.Plantid and pm.machineid=pmg.machineid
	where 1=1 '
	set @strsql=@strsql+@strgroupid
	set @strsql= @strsql+' order by mi.machineid '
	set @strsql= @strsql + @order
	print @strsql
	exec(@strsql)	
end


if @name='MachineByCell'  and @filter=''
begin
	set @strsql=''
	set @strsql='Select distinct mi.Machineid from plantmachine pm 
	inner join machineinformation mi on pm.machineid=mi.machineid
	inner join PlantMachineGroups pmg on pm.Plantid=pmg.Plantid and pm.machineid=pmg.machineid
	where 1=1 '
	set @strsql=@strsql+@strgroupid
	set @strsql= @strsql+' order by mi.machineid '
	set @strsql= @strsql + @order
	print @strsql
	exec(@strsql)	
end

if @name='AlarmCategory'
begin
	set @strsql=''
	set   @strsql='select Alarmno from  preventivemaster where charindex (''.'',alarmno)=''0'' order by alarmno '
	set @strsql= @strsql + @order
	exec(@strsql)
end

if @name='PredefinedTimePeriod'
begin
	INSERT INTO #shift (shiftname)
	Select 'Today - ' +shiftname  as shiftname from shiftdetails  where running=1 
	UNION ALL
	Select 'Today - All' 
	UNION ALL
	Select 'Yesterday - ' +shiftname  as shiftname from shiftdetails  where running=1 
	UNION ALL
	Select 'Yesterday - All' 
	Select * from #shift
end


if @name='Comp' and @filter=''
begin
	set @strsql=''
	set   @strsql='select distinct C.Componentid from componentoperationpricing C inner join Machineinformation M on M.machineid=C.machineid  inner join PlantMachine P on P.MachineID=M.Machineid where M.tpmtrakenabled=1 '
	set @strsql= @strsql+' order by C.Componentid '
	set @strsql= @strsql + @order
	exec(@strsql)
end

if @name='Comp' and @filter<>''
begin
	set @strsql=''
	set  @strsql='select distinct C.Componentid from componentoperationpricing C inner join Machineinformation M on M.machineid=C.machineid inner join PlantMachine P on P.MachineID=M.Machineid  where M.tpmtrakenabled=1 and M.Machineid='
	set @strsql= @strsql +''''+@filter+''''
	set @strsql= @strsql+' order by C.Componentid '
	set @strsql= @strsql + @order
	exec(@strsql)
end

if @name='Opn' 
begin

    select  distinct Operationno from componentoperationpricing COP 
	inner join  Componentinformation CI on COP.componentid=CI.componentid  
	inner join machineinformation m on COP.machineid=M.machineid
	where  (COP.machineid= @filter or @filter = '' )and  (COP.componentid= @filter1 or @filter1 = '')

	--set @strsql=''
	--set   @strsql='select  distinct Operationno from componentoperationpricing COP inner join  Componentinformation CI on COP.componentid=CI.componentid  inner join machineinformation m on COP.machineid=M.machineid'
	--set @strsql= @strsql+' order by COP.Operationno '
	--set @strsql= @strsql + @order
	--exec(@strsql)
end

if @name='Opn' and @filter<>'' and @filter1<>''
begin
	set @strsql=''
	set   @strsql='select  distinct Operationno from componentoperationpricing COP inner join  Componentinformation CI on COP.componentid=CI.componentid  inner join machineinformation m on COP.machineid=M.machineid '
	set @strsql= @strsql +' where COP.machineid='''+@filter+''''
	set @strsql= @strsql +'and COP.componentid= '''+@filter1+''''
	set @strsql= @strsql+' order by COP.Operationno '
	set @strsql= @strsql + @order
	exec(@strsql)
end

End
