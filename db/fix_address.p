
/*------------------------------------------------------------------------
    File        : fix_address.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed Sep 17 15:09:28 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

define temp-table ttAddressData no-undo
    field first_name  as character
    field last_name   as character
    field company_name    as character
    field address as character
    field city    as character
    field county  as character
    field state   as character
    field zip as character
    field phone1  as character
    field phone2  as character
    field email   as character
    field web       as character
    .


/* ***************************  Main Block  *************************** */
define query qryAddress for ttAddressData.

input from 'c:/devarea/common/address-data-us-500.csv'.
repeat:
    create ttAddressData.
    import delimiter ',' ttAddressData.
end.
input close.

/* Florida for Exchange */
open query qryAddress preselect each ttAddressData where ttAddressData.state eq 'FL'.

for each CustomerDetail:
    get next qryAddress.
    
    assign CustomerDetail.Location 
                = ttAddressData.address + ', '
                + ttAddressData.city + ', '
                + ttAddressData.state + ' '
                + ttAddressData.zip.     

    for each Order where
             Order.CustNum eq CustomerDetail.CustNum
             no-lock,
        each DeliveryItem where
             DeliveryItem.OrderCode eq Order.Code:
        DeliveryItem.Location = CustomerDetail.Location.
        DeliveryItem.ContactName = CustomerDetail.Name.
        DeliveryItem.ContactNumber = CustomerDetail.ContactNumber.
    end.
end.

