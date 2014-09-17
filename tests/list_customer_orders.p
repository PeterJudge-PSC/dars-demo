
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
output to 'temp/customer_orders.txt'.

for each CustomerDetail no-lock:
    put unformatted
        CustomerDetail.CustNum 
        '~t' CustomerDetail.Name  skip
        '~tLocation:~t' CustomerDetail.Location skip(2)
        'Order~tStatus~tRMA Code~tReason' skip
        fill('-', 80)  
        skip.
        
    for each Order where
         Order.CustNum eq CustomerDetail.CustNum
         no-lock:
        put unformatted
            Order.OrderNum
            '~t' Order.OrderStatus 
            '~t' Order.ReturnCode 
            '~t' substring(Order.ReturnReason,1, 45).
        
        if length(Order.ReturnReason) gt 45 then
            put unformatted '...' .
            
        put unformatted            
            skip.
    end.             
    put unformatted skip(2).
end.

output close.