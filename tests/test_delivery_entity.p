/*------------------------------------------------------------------------
    File        : test_delivery_entity.p
    Description : 
    Created     : Mon Aug 04 11:18:20 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Demo.DeliveryEntity.
using Progress.Json.ObjectModel.JsonObject.

/* ***************************  Main Block  *************************** */
define variable oFilter as JsonObject no-undo.
define variable oBE as DeliveryEntity no-undo.
define variable hDataset as handle no-undo.
define variable cFilter as character no-undo.
define variable cDepot as character no-undo.
define variable cDriver as character no-undo.
define variable cDelivery as character no-undo.

cDepot = 'DEP100'.
cDriver = 'DRV100'.
cDelivery = '53e25e100c533392e01c880a'.

oBE = new DeliveryEntity().

oFilter = new JsonObject().
oFilter:Add('driverCode', cDriver).
oFilter:Add('depotCode', cDepot).
oFilter:Write(output cFilter).

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