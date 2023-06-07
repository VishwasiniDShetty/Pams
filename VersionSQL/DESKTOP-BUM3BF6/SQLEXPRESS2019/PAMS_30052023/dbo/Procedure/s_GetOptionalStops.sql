/****** Object:  Procedure [dbo].[s_GetOptionalStops]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************      History     *******************************************
Used in VDG for BOSCH

NR0051: Procedure created by Mrudula on 22-dec-2008. Get list of optional stops for the given starttime
        and endtime of a production cycle and machineid.
	
mod 1:- By Mrudula M. Rao on 16-jan-2009 for ER0162. Use datatype 70 for optional stop start and 71 for optional stop end. Instead of 40 and 41

****************************************************************************************************/


CREATE               PROCEDURE [dbo].[s_GetOptionalStops]

	@MachineID nvarchar(50) = '',
	@StartTime datetime ,
	@EndTime datetime ,
	@PlantID nvarchar(50)=''
	
AS
BEGIN

Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(255)
declare @timeformat as nvarchar(2000)
declare @curstarttime as datetime
declare @curendtime as datetime
declare @nxtstarttime as datetime
declare @nxtendtime as datetime
declare @CycStarttime as datetime
declare @CycEndtime as datetime
				
SELECT @strMachine = ''
SELECT @strPlantID = ''
SELECT @timeformat ='ss'

Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	select @timeformat = 'ss'
end



if isnull(@machineid,'')<> '' 
begin
	SET @strMachine = ' AND MachineInformation.MachineID = ''' + @machineid + ''''
	
end
if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = ''' + @PlantID + ''''
End


create table #OptionalStops
      (
	Machineid nvarchar(50),
	CycStart datetime,
	CycEnd datetime,
	StartTime datetime,
	Endtime datetime,
	StopTime nvarchar(50)
      )

Create table #NStops
    (MachID nvarchar(50),
     Strt datetime,
     ndtime datetime,
    RecordType int
    )



---select * from #AllCycles


---declare CycCursor for 


	--Get 40 and 41 type records for the cycle
	insert into #NStops(MachID,Strt,RecordType )
	Select M.Machineid,A.starttime,A.recordtype
	from autodatadetails A inner join machineinformation M on M.interfaceid=A.Machine
	Where M.Machineid=@MachineID and A.starttime> @StartTime and A.Starttime<@EndTime
	---MOD 1
	---and A.Recordtype in (40,41)
	and A.Recordtype in (70,71)
	---MOD 1
	order by A.Starttime ASC
	
	---update the endtime of the current record with starttime of the next record
	
	DECLARE Optcursor  cursor for
	select Strt,ndtime from #NStops
		open Optcursor
		fetch next from Optcursor into @curstarttime,@curendtime	
		IF (@@fetch_status = 0)
		BEGIN
			fetch next  from Optcursor into @nxtstarttime,@nxtendtime	
		while (@@fetch_status = 0)
		BEGIN
			set @curendtime = @nxtstarttime
			update #NStops set ndtime = @curendtime  where Strt=@curstarttime
			SET @curstarttime=@nxtstarttime
		      FETCH NEXT  from Optcursor into @nxtstarttime,@nxtendtime	
		END
		UPDATE #NStops set ndtime=@EndTime   where Strt=@curstarttime
	END

	
	close Optcursor
	deallocate Optcursor
	
	insert into #OptionalStops(Machineid,CycStart,CycEnd,StartTime,Endtime,StopTime)
	select MachID,@StartTime,@EndTime,Strt,ndtime,Datediff(s,Strt,ndtime) from #NStops
	where RecordType=70


--select * from #NStops



Select * from   #OptionalStops

END
