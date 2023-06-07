/****** Object:  Procedure [dbo].[SP_MasterJobCardHistory_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MasterJobCardHistory_Pams @MJCNo=N'RM/GRN/1/2023-24',@RawMaterial=N'Ø12.30_16MnCr5'
go
SP_MasterJobCardHistory_Pams @MJCNo=N'RM/GRN/3/2023-24',@RawMaterial=N'Ø30.40_16MnCr5'

*/
CREATE procedure [dbo].[SP_MasterJobCardHistory_Pams]
@MJCNo nvarchar(50)='',
@RawMaterial nvarchar(50)=''
as

CREATE TABLE #Temp
(
MJCNo nvarchar(50), 
GRNNo nvarchar(50), 
MaterialID nvarchar(50),
PartID nvarchar(50), 
PamsDCNo nvarchar(50),
Vendor nvarchar(50),
VendorDCno nvarchar(50),
VendorDCDate nvarchar(50),
VehicleNo nvarchar(50),
PJCNo nvarchar(50),
Process nvarchar(2000),
Sequence nvarchar(50),
IssuedQty_KG float ,
IssuedQty_Numbers float,
ReceivedQty_KG float,
ReceivedQty_Numbers float,
RejQty float,
DC_Stores_Status nvarchar(50)
)
begin
	--declare @PJCProcessType nvarchar(50)
	--select  @PJCProcessType=''
	--select  @PJCProcessType=(select PJCProcessType from RawMaterialDetails_PAMS where materialid=@RawMaterial)
	--print @PJCProcessType

	--if @PJCProcessType='PJC after first process'
	--begin
	--	select D1.MJCNo, d1.GRNNo,d1.MaterialID,d1.PartID,d1.PamsDCNo,d1.Vendor,d1.VendorDCno,d1.VendorDCDate,d1.VehicleNo,D1.Process,d2.Qty_KG as IssuedQtyInKG,D2.Qty_Numbers AS IssuedQtyInNumbers,d1.Qty_KG as RceivedQtyInKG,
	--	d1.Qty_Numbers as RceivedQtyInNumbers,d1.RejQty,d1.DC_Stores_Status from DCNoGeneration_PAMS  d1 left join DCStoresDetails_PAMS d2 on d1.GRNNo=d2.GRNNo and d1.Vendor=d2.Vendor
	--	and d1.MaterialID=d2.MaterialID and d1.PartID=d2.PartID and d1.PamsDCNo=d2.Pams_DCNo
	--	--WHERE ISNULL(D1.PJCNo,'')='' AND D1.MJCNo=@MJCNo
	--end

	--IF @PJCProcessType='PJC before first process'
	--BEGIN
	--	insert into #Temp(MJCNo,GRNNo,MaterialID,PartID,PamsDCNo,Vendor,VendorDCno,VendorDCDate,VehicleNo,Process,IssuedQty_KG,IssuedQty_Numbers, ReceivedQty_KG,
	--	ReceivedQty_Numbers,RejQty,DC_Stores_Status,PJCNo)
	--	select D1.MJCNo, d1.GRNNo,d1.MaterialID,d1.PartID,d1.PamsDCNo,d1.Vendor,d1.VendorDCno,d1.VendorDCDate,d1.VehicleNo,D1.Process,d2.Qty_KG as IssuedQtyInKG,D2.Qty_Numbers AS IssuedQtyInNumbers,d1.Qty_KG as RceivedQtyInKG,
	--	d1.Qty_Numbers as RceivedQtyInNumbers,d1.RejQty,d1.DC_Stores_Status,d1.PJCNo from DCStoresDetails_PAMS d1 left join DCNoGeneration_PAMS d2 on d1.GRNNo=d2.GRNNo and d1.Vendor=d2.Vendor
	--	and d1.MaterialID=d2.MaterialID and d1.PartID=d2.PartID and d1.PamsDCNo=d2.Pams_DCNo
	--	WHERE  D1.MJCNo=@MJCNo

	--	--update #Temp set Sequence=isnull(t1.sequence,0)
	--	--from
	--	--(
	--	--select distinct process,PartID,Sequence from ProcessAndFGAssociation_PAMS
	--	--) 
	--	--t1 inner join #Temp on t1.PartID=#Temp.PartID and t1.Process=#Temp.Process
		
	--	select MJCNo, GRNNo,MaterialID,PartID,PamsDCNo,Vendor,VendorDCno,VendorDCDate,VehicleNo,Process,IssuedQty_KG as IssuedQtyInKG,IssuedQty_Numbers AS IssuedQtyInNumbers,ReceivedQty_KG as RceivedQtyInKG,
	--	ReceivedQty_Numbers as RceivedQtyInNumbers,RejQty,DC_Stores_Status from #Temp --where isnull(sequence,0)=1
			
	--END
		select D1.MJCNo, d1.GRNNo,d1.MaterialID,d1.PartID,d1.Pams_DCNo as PamsDCNo,d1.Vendor,d2.VendorDCno,case when d2.VendorDCDate='1900-01-01 00:00:00.000' then null else d2.VendorDCDate end VendorDCDate ,d2.VehicleNo,D1.Process,d1.Qty_KG as IssuedQtyInKG,D1.Qty_Numbers AS IssuedQtyInNumbers,d2.Qty_KG as RceivedQtyInKG,
		d2.Qty_Numbers as RceivedQtyInNumbers,d2.RejQty,d2.DC_Stores_Status,d1.PJCNo from DCNoGeneration_PAMS  d1 left join DCStoresDetails_PAMS d2 on d1.GRNNo=d2.GRNNo and d1.Vendor=d2.Vendor
		and d1.MaterialID=d2.MaterialID and d1.PartID=d2.PartID and d1.Pams_DCNo=d2.PamsDCNo and d1.MJCNo=d2.MJCNo and d1.Process=d2.Process and isnull(d1.pjcno,'')=isnull(d2.pjcno,'')
		WHERE D1.MJCNo=@MJCNo
		order by d1.MJCNo,d1.GRNNo,d1.MaterialID,d1.PartID,d1.DCDate 

end
