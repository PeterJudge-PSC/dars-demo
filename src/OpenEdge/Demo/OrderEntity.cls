/*------------------------------------------------------------------------
    File        : OrderEntity
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Wed Aug 06 09:56:00 EDT 2014
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Demo.BusinessEntity.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonDataType.

class OpenEdge.Demo.OrderEntity inherits BusinessEntity: 
    {OpenEdge/Demo/order_dataset.i}
    
    define data-source srcOrder for Order.
    define data-source srcOLine for OrderLine.
    define data-source srcCustomer for CustomerDetail.
    
	method override public void Destroy(  ):
	end method.

	method override public void Initialize(  ):
	    assign extent(ProDataSource) = 3
	           ProDataSource[1] = data-source srcOrder:handle
	           ProDataSource[2] = data-source srcOLine:handle
	           ProDataSource[3] = data-source srcCustomer:handle
	           .
	end method.
	
	constructor public OrderEntity ():
		super (dataset dsOrder:handle).
	end constructor.
	
	/* READ */
	method public void ListOrders (input filter as character,
	                               output dataset dsOrder):
        ListOrders(input  ParseFilter(filter), 
                   output dataset dsOrder by-reference).
    end method.
    	                                   
    method public void ListOrders (input poFilter as JsonObject,
                                   output dataset dsOrder):
        define variable cWhere as character extent 3 no-undo.                                       
        define variable cDelim as character extent 3 no-undo.
        
        define variable iOrderNum as integer no-undo.
        define variable iCustNum as integer no-undo.
        define variable oArray as JsonArray no-undo.
        define variable iLoop as integer no-undo.
        define variable iMax as integer no-undo.
        
        /* [1] = Order
           [2] = OrderLine 
           [3] = CustomerDetail */
        assign cWhere = ''
               cDelim = ''.
                
        if poFilter:Has('custNum') then
            assign cWhere[1] = cWhere[1] + cDelim[1]
                             + substitute('Order.CustNum eq &1',
                                        poFilter:GetInteger('custNum'))
                   cDelim[1] = ' and '.
        
        if poFilter:Has('orderNum') then
            assign cWhere[1] = cWhere[1] + cDelim[1]
                             + substitute('Order.OrderNum eq &1',
                                        poFilter:GetInteger('orderNum'))
                   cDelim[1] = ' and '.
        
        if poFilter:Has('orderStatus') then
        do:
            case poFilter:GetType('orderStatus'):
                when JsonDataType:STRING then
                    assign cWhere[1] = cWhere[1] + cDelim[1]
                                     + substitute('Order.OrderStatus eq &1',
                                            quoter(poFilter:GetCharacter('orderStatus')))
                           cDelim[1] = ' and '.
                when JsonDataType:ARRAY then
                do:
                    assign oArray    = poFilter:GetJsonArray('orderStatus')
                           iMax      = oArray:Length
                           cWhere[1] = cWhere[1] + cDelim[1] + ' ( '
                           cDelim[1] = ''.
                           
                    do iLoop = 1 to iMax:
                        assign cWhere[1] = cWhere[1] + cDelim[1]
                                         + substitute('Order.OrderStatus eq &1',
                                                quoter(oArray:GetCharacter(iLoop)))
                               cDelim[1] = ' or '.
                    end.
                    
                    assign cWhere[1] = cWhere[1] + ' ) '
                           cDelim[1] = ' and '.
                end.    /* ARRAY */
            end case.
        end.
        
        message 
        '[1]=' cWhere[1] skip
        '[2]=' cWhere[2] skip
        '[3]=' cWhere[3] skip        
        view-as alert-box.
        
        ReadData(cWhere[1]).
    end method.
    
    /* SUBMIT */
    method public void UpdateOrders (input-output dataset dsOrder):
        Submit(input-output dataset dsOrder by-reference).
    end method.
    
end class.