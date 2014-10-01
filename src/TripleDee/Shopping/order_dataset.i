/*------------------------------------------------------------------------
    File        : order_dataset.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed Aug 06 10:07:15 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
define {&access-level}  temp-table eCustomerDetail no-undo
    field CustNum       as integer
    field Name          as character
    field ContactNumber as character
    field Location      as character
    /* other real-world fields */
    index idx1 as primary unique CustNum. 

define {&access-level}  temp-table eOrder no-undo before-table bOrder
    field Code            as character
    field CustNum         as integer
    field OrderNum        as integer
    field OrderDate       as datetime-tz
    field OrderAmt        as decimal     decimals 2
    field Instructions    as character      /* eg. "leave on porch" */
    field OrderStatus     as character      /* matches OrderStatusEnum */
    field ReturnCode      as character
    field ReturnReason    as character
    /* other real-world fields */
    index idx1 as primary unique Code
    index idx2 as unique CustNum OrderNum
    index idx3 OrderStatus
    index idx4 ReturnCode
    .

define {&access-level}  temp-table eOrderLine no-undo before-table bOrderLine
    field OrderCode       as character
    field LineNum         as integer
    field ItemCode        as character
    field Qty             as integer
    field Volume          as decimal decimals 1
    /* other real-world fields */
    index idx1 as primary unique OrderCode LineNum.
 
define {&access-level}  dataset dsOrder for eOrder, eOrderLine, eCustomerDetail
    data-relation for eOrder,eOrderLine relation-fields(Code, OrderCode) nested
    data-relation for eOrder,eCustomerDetail relation-fields(CustNum, CustNum) nested
    .
/* eof */