/*------------------------------------------------------------------------
    File        : delivery_dataset.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed Aug 06 10:07:15 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
define {&access-level} temp-table eDelivery no-undo before-table bDelivery
    field Code              as character
    field DeliveryStatus    as character    /* from DeliveryStatusEnum */
    
    field DriverCode    as character
    field VehicleCode   as character
    
    field StartTime     as datetime-tz
    field EndTime       as datetime-tz
    
    index idx1 as primary unique Code
    index idx2                   DeliveryStatus
    .
    
define {&access-level}  temp-table eDeliveryItem no-undo  before-table bDeliveryItem
    field Code as character
    field DeliveryCode as character
    field OrderCode as character
    field DeliveryStatus as character   /* One of OrderStatusEnum */
    field DeliveredAt as datetime-tz
    field Comments as character
    field ContactName   as character
    field ContactNumber as character
    field Location      as character
        
    index idx1 as primary unique Code
    index idx2 as         unique Code OrderCode
    .
    
define {&access-level} temp-table eProofOfDelivery no-undo before-table bProofOfDelivery
    field DeliveryItemCode as character
    field ProofOfDelivery  as clob       /* signature/barcode scan */
    
    index idx1 as primary unique DeliveryItemCode
    .
    
define {&access-level}  dataset dsDriverDelivery for eDelivery, eDeliveryItem, eProofOfDelivery
    data-relation for eDelivery, eDeliveryItem relation-fields(Code, DeliveryCode)
    data-relation for eDeliveryItem, eProofOfDelivery relation-fields(Code, DeliveryItemCode)
    .

/* eof */ 
