/*------------------------------------------------------------------------
    File        : load_data.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Thu Sep 11 15:45:57 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

{delivery_database.i}

/* LOAD Data */
dataset dsDatabase:read-json('file', 'db/data.json').


for each ttCustomerDetail:
    create CustomerDetail .
    buffer-copy ttCustomerDetail to CustomerDetail.
end.

for each ttOrder:
    create Order.
    buffer-copy ttOrder to Order.
end.

for each ttOrderLine:
    create OrderLine.
    buffer-copy ttOrderLine to OrderLine.
end.

for each ttDepot:
    create Depot.
    buffer-copy ttDepot to Depot.
end.

for each ttDriver:
    create Driver.
    buffer-copy ttDriver to Driver.
end.

for each ttVehicleType:
    create VehicleType.
    buffer-copy ttVehicleType to VehicleType.
end.

for each ttRoute:
    create Route.
    buffer-copy ttRoute to Route.
end.

for each ttDelivery:
    create Delivery.
    buffer-copy ttDelivery to Delivery.
end.

for each ttDeliveryItem:
    create DeliveryItem.
    buffer-copy ttDeliveryItem to DeliveryItem.
end.