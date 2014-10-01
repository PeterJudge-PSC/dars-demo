
/*------------------------------------------------------------------------
    File        : test_close_delivery.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed Oct 01 15:20:33 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

using TripleDee.Shopping.ShoppingService.
using TripleDee.Shopping.DeliveryEntity.


{TripleDee/Shopping/delivery_dataset.i}


/* ***************************  Main Block  *************************** */
define variable oShopSvc as ShoppingService no-undo.
define variable cDelivery as character no-undo.
define variable oDeliverySvc as DeliveryEntity no-undo.

oShopSvc = new ShoppingService().
oDeliverySvc = new DeliveryEntity().

cDelivery = '8b9385e0-d025-829f-eb13-e93c18c8832c'.

oDeliverySvc:GetDeliveryByCode(cDelivery, output dataset dsDriverDelivery).
dataset dsDriverDelivery:write-json('file', 'temp/close-001.json', true).

/* close delivery */
oShopSvc:CloseDelivery(cDelivery).

oDeliverySvc:GetDeliveryByCode(cDelivery, output dataset dsDriverDelivery).
dataset dsDriverDelivery:write-json('file', 'temp/close-002.json', true).


catch e as Progress.Lang.Error :
    message 
        e:GetMessage(1) skip(2)
        e:CallStack
    view-as alert-box.
        
end catch.

finally:
    message 
    'Closed ' cDelivery
    view-as alert-box.
end finally.