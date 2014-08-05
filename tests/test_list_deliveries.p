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
define variable oFilter as JsonObject no-undo.
define variable oBE as DeliveryAndReturnService no-undo.
define variable hDataset as handle no-undo.
define variable cFilter as character no-undo.
define variable cDepot as character no-undo.
define variable cDriver as character no-undo.
define variable cDelivery as character no-undo.

cDepot = 'DEP100'.
cDriver = 'DRV100'.

oBE = new DeliveryAndReturnService().

cDelivery = oBE:CreateDelivery(cDepot, cDriver).
cDelivery = oBE:CreateDelivery(cDepot, cDriver).

oFilter = new JsonObject().
oFilter:Add('driverCode', cDriver).
oFilter:Add('depotCode', cDepot).
/*oFilter:Add('deliveryCode', cDelivery).*/
oFilter:Write(output cFilter).

oBE:ListDriverDeliveries(cFilter, output dataset-handle hDataset).

hDataset:write-json('file', 'temp/driver-list.json', true).

