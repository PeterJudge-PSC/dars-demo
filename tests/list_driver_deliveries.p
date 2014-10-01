
/*------------------------------------------------------------------------
    File        : list_customer_orders.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed Sep 17 14:47:52 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

block-level on error undo, throw.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
output to 'temp/driver_deliveries.txt'.

for each Driver no-lock:
    put unformatted
        Driver.Code
        '~t' Driver.Name skip
        fill('-', 80)  
        skip.
        
    for each Delivery where
             Delivery.DriverCode eq Driver.Code
             no-lock
             by Delivery.StartTime:
                                  
        put unformatted
            Delivery.StartTime
            '~t' Delivery.DeliveryStatus 
            '~t' Delivery.VehicleCode 
            '~t~t' Delivery.Code skip
            .
        
        for each DeliveryItem where
                 DeliveryItem.DeliveryCode eq Delivery.Code
                 no-lock,
           first Order where
                 Order.Code eq DeliveryItem.OrderCode
                 no-lock
                 by Order.CustNum
                 by Order.OrderNum:
           
            put unformatted
            '~t~t' Order.CustNum  
            '~t~t' Order.OrderNum 
            '~t~t' DeliveryItem.DeliveryStatus skip
            '~t~t' DeliveryItem.ContactName
            '~t' DeliveryItem.ContactNumber 
            '~t' DeliveryItem.Location
                skip.
        end.
    end.
    put unformatted skip(2).
end.

output close.