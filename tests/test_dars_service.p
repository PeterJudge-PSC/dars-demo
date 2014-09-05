/*------------------------------------------------------------------------
    File        : test_list_deliveries.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Mon Aug 04 11:18:20 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using OpenEdge.Demo.DeliveryAndReturnService.
using Progress.Json.ObjectModel.JsonObject.

/* ***************************  Main Block  *************************** */
log-manager:log-entry-types = 'temp-tables,4GLTrace'.
log-manager:logfile-name = 'temp/logmanager.log'.
log-manager:logging-level = 5.

define variable oFilter as JsonObject no-undo.
define variable oDARS as DeliveryAndReturnService no-undo.
define variable hDataset as handle no-undo.
define variable cFilter as character no-undo.
define variable cDepot as character no-undo.
define variable cDriver as character no-undo.
define variable cDelivery as character no-undo.

cDepot = 'DEP100'.
cDriver = 'DRV100'.
/*cFilter = '~{}'.*/

oDARS = new DeliveryAndReturnService().

oDARS:ListDriverDeliveries(cFilter, output dataset-handle hDataset by-reference).

hDataset:write-json('file', 'temp/dars-list-1.json', true).

cDelivery = oDARS:OpenDelivery(cDepot, cDriver).

oFilter = new JsonObject().
oFilter:Add('driverCode', cDriver).
oFilter:Add('depotCode', cDepot).
/*oFilter:Add('deliveryCode', cDelivery).*/
oFilter:Write(output cFilter).

oDARS:ListDriverDeliveries(cFilter, output dataset-handle hDataset by-reference).

hDataset:write-json('file', 'temp/dars-list-2.json', true).

oDARS:CloseDelivery(cDelivery).

catch e as Progress.Lang.Error :
    
    message 
        e:GetMessage(1) skip(2)
        e:CallStack
    view-as alert-box.
		
end catch.