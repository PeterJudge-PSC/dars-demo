/*------------------------------------------------------------------------
    File        : test_list_deliveries.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Mon Aug 04 11:18:20 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Progress.Json.ObjectModel.JsonObject.
using TripleDee.Shopping.OrderEntity.
using TripleDee.Shopping.OrderStatusEnum.
using Progress.Json.ObjectModel.JsonArray.

/* ***************************  Main Block  *************************** */
define variable oFilter as JsonObject no-undo.
define variable oBE as OrderEntity no-undo.
define variable hDataset as handle no-undo.
define variable cFilter as character no-undo.
define variable cStatus as character extent no-undo.
define variable iOrderNum as integer no-undo.
define variable iCustNum as integer no-undo.

oBE = new OrderEntity().

iOrderNum = 1.
iCustNum = 1000.
extent(cStatus) = 2.
cStatus[1] = OrderStatusEnum:Ordered:Name.
cStatus[2] = OrderStatusEnum:ReturnApproved:Name.

oFilter = new JsonObject().
oFilter:Add('custNum', iCustNum).
oFilter:Write(output cFilter).

oBE:ListOrders(cFilter, output dataset-handle hDataset).
hDataset:write-json('file', 'temp/order-list-1.json', true).

oFilter:Add('orderNum', iOrderNum).
oFilter:Write(output cFilter).

oBE:ListOrders(cFilter, output dataset-handle hDataset).
hDataset:write-json('file', 'temp/order-list-2.json', true).

oFilter = new JsonObject().
oFilter:Add('orderStatus', new JsonArray(cStatus)).
oFilter:Write(output cFilter).

        message 
        string(oFilter:GetJsonText())
        view-as alert-box. 

oBE:ListOrders(cFilter, output dataset-handle hDataset).

hDataset:write-json('file', 'temp/order-list-3.json', true).


catch ae as Progress.Lang.AppError :
    
    message 
        ae:ReturnValue skip(2)
        ae:CallStack
    view-as alert-box.
        
end catch.

catch e as Progress.Lang.Error :
    
    message 
        e:GetMessage(1) skip(2)
        e:CallStack
    view-as alert-box.
		
end catch.