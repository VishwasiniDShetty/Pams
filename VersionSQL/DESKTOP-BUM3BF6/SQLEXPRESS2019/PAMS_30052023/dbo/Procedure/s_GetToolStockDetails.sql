/****** Object:  Procedure [dbo].[s_GetToolStockDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--mod 1 :- ER0182 By Kusuma M.H on 09-Jun-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
--Note:ER0181 not done because CO qualification not found.


CREATE  procedure [dbo].[s_GetToolStockDetails]
@FromDate Datetime,
@Todate datetime,
@Toolid nvarchar(50)='',
@Toolcategory nvarchar(50)=''

as 
Begin

Declare @StrToolcat as nvarchar(150)
Declare @Strtoolid as nvarchar(150)
declare @Strdate as datetime
Declare @Str as nvarchar(1200)

If isnull(@Toolcategory,'')<>''
Begin
	---mod 1
--	Select @StrToolcat= ' and t1.toolcategory='''+ @Toolcategory +''''
	Select @StrToolcat= ' and t1.toolcategory = N'''+ @Toolcategory +''''
	---mod 1
	print @StrToolcat
End

If isnull(@Toolid,'')<>''
Begin
	---mod 1
--	Select @Strtoolid= ' and t1.toolid='''+ @Toolid +''''
	Select @Strtoolid= ' and t1.toolid = N'''+ @Toolid +''''
	---mod 1
End

select @Str='Select t1.Toolcategory,t1.ToolID,t1.PONumber,PurchaseDate,PurchaseQuantity,[InStores-Good],[Instores-used] ,Inshop as [Stock Out],t2.Remarks from toolstockmanagement t1 inner join
			(Select Toolcategory,ToolID,PONumber,Remarks from tooltransaction where id in (select max(id) from tooltransaction group by Toolcategory,ToolID,PONumber)) as t2 on '
select @Str=@Str + ' t1.Toolcategory = t2.Toolcategory and t1.ToolID = t2.ToolID and t1.PONumber = t2.PONumber'
select @str=@str+ ' where t1.purchasedate >= '''+ convert(nvarchar(30),@FromDate) +''' and t1.purchasedate <= '''+ convert(nvarchar(30),@Todate) +''''
select @str=@str + isnull(@StrToolcat,'')  + isnull(@Strtoolid,'')

exec(@str)
END
