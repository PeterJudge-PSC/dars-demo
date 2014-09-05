/*------------------------------------------------------------------------
    File        : delivery_dataset.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed Aug 06 10:07:15 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
define private temp-table eDelivery no-undo before-table bDelivery
    field Code          as character
    field DepotCode     as character
    field RouteCode     as character
    field DriverCode    as character
    field VehicleCode   as character
    field StartTime     as datetime-tz  
    field EndTime       as datetime-tz
    
    index idx1 as primary unique Code
    index idx2                   DriverCode StartTime
    index idx3 as unique DepotCode DriverCode RouteCode VehicleCode StartTime EndTime
    .

define private temp-table eDeliveryItem no-undo  before-table bDeliveryItem
    field Code as character
    field DeliveryCode as character
    field OrderCode as character
    field DeliveryStatus as character
    field DeliveredAt as datetime-tz
    field Comments as character
    field ProofOfDelivery as clob
    field ContactName   as character
    field ContactNumber as character
    field Location      as character    
    index idx1 as primary unique Code
    index idx2 as unique DeliveryCode OrderCode.
    
  define private dataset dsDriverDelivery for eDelivery, eDeliveryItem
    data-relation for eDelivery, eDeliveryItem relation-fields(Code, DeliveryCode)
    .
  