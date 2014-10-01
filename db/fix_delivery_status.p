/*------------------------------------------------------------------------
    File        : fix_delivery_status.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Mon Sep 29 12:00:34 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using TripleDee.Shopping.DeliveryStatusEnum.

for each Delivery:
    case Delivery.EndTime:
        when ? then assign Delivery.DeliveryStatus = DeliveryStatusEnum:Open:Name.
        otherwise   assign Delivery.DeliveryStatus = DeliveryStatusEnum:Closed:Name.
    end case.
    
    for each DeliveryItem where
             DeliveryItem.DeliveryCode eq Delivery.Code:
        
        find Order where Order.Code eq DeliveryItem.OrderCode.
        assign Order.OrderStatus = DeliveryItem.DeliveryStatus.
    end.
end.

for each Order where Order.OrderStatus eq 'OutForDelivery':
    assign Order.OrderStatus = 'Ordered'.
end.

for each Order where Order.OrderStatus eq 'PickupScheduled':
    assign Order.OrderStatus = 'ReturnApproved'.
end.
 