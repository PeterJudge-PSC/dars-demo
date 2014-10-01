/*------------------------------------------------------------------------
    File        : test_delivery_entity.p
    Description : 
    Created     : Mon Aug 04 11:18:20 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using TripleDee.Shopping.DeliveryEntity.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonArray.

/* ***************************  Main Block  *************************** */
define variable oFilter as JsonObject no-undo.
define variable oObject as JsonObject no-undo.
define variable oBE as DeliveryEntity no-undo.
define variable hDataset as handle no-undo.
define variable cFilter as character no-undo.
define variable cDepot as character no-undo.
define variable cDriver as character no-undo.
define variable cDelivery as character no-undo.

cDepot = 'DEP100'.
cDriver = 'DRV100'.
cDelivery = 'cdf6087e-7b4a-0295-eb13-ba3cd83afefd'.
cDelivery = 'ed26387e-424b-1a94-eb13-b83cd86e8ce3'.
cDelivery = 'e6e49dea-de3a-40b7-eb13-6d3cd0370b13'.
cDelivery = 'faf0dd5b-310e-0d81-eb13-d73c5892a706'.
cDelivery = '8b9385e0-d025-829f-eb13-e93c18c8832c'.

oBE = new DeliveryEntity().

oBE:GetDeliveryByCode(cDelivery, output dataset-handle hDataset).
hDataset:write-json('file', 'temp/del01.json', true).




oFilter = new JsonObject().
oFilter:Add('driverCode', cDriver).
oFilter:Add('depotCode', cDepot).
oFilter:Add('deliveryStatus', new JsonArray()).
oFilter:GetJsonArray('deliveryStatus'):Add('ReturnReceived').
oFilter:GetJsonArray('deliveryStatus'):Add('Ordered').

oObject = new JsonObject().
oObject:Add('ablFilter', oFilter).

/*oFilter:Write(output cFilter).*/

define variable cWhere as character extent no-undo.


message 
'cWhere[1]=' cWhere[1] skip
'cWhere[2]=' cWhere[2] skip
view-as alert-box.

oBE:ListDriverDeliveries(cFilter, output dataset-handle hDataset).

hDataset:write-json('file', 'temp/driver-list-1.json', true).

oFilter = new JsonObject().
oFilter:Add('deliveryCode', cDelivery).
oFilter:Write(output cFilter).

oBE:ListDriverDeliveries(cFilter, output dataset-handle hDataset).

hDataset:write-json('file', 'temp/driver-list-2.json', true).

catch e as Progress.Lang.Error :
    
    message 
        e:GetMessage(1) skip(2)
        e:CallStack
    view-as alert-box.
		
end catch.