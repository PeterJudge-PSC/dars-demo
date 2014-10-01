/*------------------------------------------------------------------------
    File        : create_orders.p
    Description : Creates random orders for customers 
    Author(s)   : 
    Created     : Wed Oct 01 09:45:32 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.


/* ***************************  Main Block  *************************** */
define variable cOrderStatus as character extent 9 no-undo
    /* dup Ordered/Delivered to increase those statii */
    init ["Ordered","Delivered", "Ordered","Delivered","ReturnRequested","ReturnApproved","ReturnDenied","ReturnReceived","Refunded"].
    
define variable cReturnReason as character extent 5 no-undo
    init ['Too big','Broken','Too small','Unwanted gift','foo bar baz'].     

define variable cItemCode as character extent 6 no-undo
    init ["BOOK", "CD", "TABLET", "PHONE", "SHOE", "FOOD"].

define variable iOrderNum as integer no-undo.
define variable iLoop as integer no-undo.
define variable iMax as integer no-undo.
define variable iLoop2 as integer no-undo.
define variable iMax2 as integer no-undo.

for each CustomerDetail no-lock:
    
    for each Order where 
             Order.CustNum eq CustomerDetail.CustNum
             no-lock
             by Order.OrderNum desc:
        iOrderNum = Order.OrderNum.
        leave.
    end.
    
    iMax = random(2, 10).
    do iLoop = 1 to iMax:
        create Order.
        assign Order.Code = guid 
               Order.OrderNum = iOrderNum + iLoop
               Order.CustNum = CustomerDetail.CustNum
               Order.OrderDate = datetime-tz(
                                    date(add-interval(date(1,1,2014), random(1, 270), 'days')),
                                    random(1, 86400000),
                                    session:timezone)
               
               Order.OrderAmt = random(10, 1000)
               Order.OrderStatus = cOrderStatus[random(1, extent(cOrderStatus))]
               .
        case Order.OrderStatus:
            when "ReturnApproved" or
            when "ReturnReceived" or
            when "Refunded" then
                assign Order.ReturnCode   = substitute('RMA-&1-&2', Order.CustNum, Order.OrderNum)
                       Order.ReturnReason = cReturnReason[random(1, extent(cReturnReason))].
        end case.
        
        iMax2 = random(1, 3).
        do iLoop2 = 1 to iMax2:
            create OrderLine.
            assign OrderLine.OrderCode = Order.Code
                   OrderLine.LineNum = iLoop2
                   OrderLine.ItemCode = substitute('&1&200', cItemCode[random(1, extent(cItemCode))], random(1, 6))
                   OrderLine.Qty = random(1,3)
                   OrderLine.Volume = random(0, 15)                                            
                   .
        end.    /* orderline loop */
    end.    /* order loop */
end.     /* customer */


/* eof */