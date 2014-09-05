/*------------------------------------------------------------------------
    File        : delivery_database.i
    Purpose     : Faux database schema 
    Author(s)   : 
    Created     : Tue Aug 05 11:30:04 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
define static protected temp-table CustomerDetail no-undo
    field CustNum       as integer
    field Name          as character
    field ContactNumber as character
    field Location      as character
    /* other real-world fields */
    index idx1 as primary unique CustNum. 

define static protected temp-table Order no-undo
    field Code            as character
    field CustNum         as integer
    field OrderNum        as integer
    field OrderDate       as datetime-tz
    field OrderAmt        as decimal     decimals 2
    field Instructions    as character      /* eg. "leave on porch" */
    field OrderStatus     as character      /* matches OrderStatusEnum */
    field ReturnCode      as character
    field ReturnReason    as character
    field DeliveryCode    as character
    /* other real-world fields */
    index idx1 as primary unique Code
    index idx2 as unique CustNum OrderNum
    index idx3 OrderStatus
    index idx4 ReturnCode
    .

define static protected temp-table OrderLine no-undo
    field OrderCode       as character
    field LineNum         as integer
    field ItemCode        as character
    field Qty             as integer
    field Volume          as decimal decimals 1
    /* other real-world fields */
    index idx1 as primary unique OrderCode LineNum.

define static protected temp-table Depot no-undo
    field Code     as character
    field Location as character     /* lat, long */
    index idx1 as primary unique Code. 

define static protected temp-table Driver no-undo
    field DepotCode  as character
    field Code as character
    field Name as character
    field ShiftStart as datetime-tz
    /* other real-world fields */
    index idx1 as primary unique DepotCode Code
    index idx2                   ShiftStart
    .        

define static protected temp-table VehicleType no-undo
    field Code     as character
    field Capacity as decimal      /* cubic meters */
    field Range    as integer      /* KM */
    .        

define static protected temp-table Route no-undo
    field DepotCode     as character
    field RouteCode       as character
    field Distance      as decimal
    index idx1 as primary unique DepotCode RouteCode
    .

define static protected temp-table Delivery no-undo
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
    
define static protected temp-table DeliveryItem no-undo
    field Code as character
    field DeliveryCode as character
    field OrderCode as character
    field DeliveryStatus as character
    field DeliveredAt as datetime-tz
    field Comments as character
    field ProofOfDelivery as clob
    index idx1 as primary unique Code
    index idx2 as unique DeliveryCode OrderCode.
    
define static protected dataset dsDatabase for VehicleType, 
                              Depot, Route, Driver, Delivery, 
                              DeliveryItem,
                              CustomerDetail, Order , OrderLine
    data-relation for Depot, Driver relation-fields(Code, DepotCode) nested
    data-relation for Depot, Route relation-fields(Code, DepotCode) nested
    data-relation for Driver, Delivery relation-fields(DepotCode, DepotCode, Code, DriverCode) nested
    data-relation for CustomerDetail, Order relation-fields(CustNum, CustNum) nested
    data-relation for Order,OrderLine relation-fields(Code, OrderCode) nested
    .
