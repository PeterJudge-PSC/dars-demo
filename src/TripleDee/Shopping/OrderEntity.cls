@openapi.openedge.export FILE(type="BPM", operationName="%FILENAME%", useReturnValue="false", writeDataSetBeforeImage="false", executionMode="singleton").
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

using TripleDee.Shopping.BusinessEntity.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonDataType.

class TripleDee.Shopping.OrderEntity inherits BusinessEntity: 
    {TripleDee/Shopping/order_dataset.i}
    
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
    
    method public void GetOrderByCode (input pcCode as character,
                                       output dataset dsOrder):
        ReadData(substitute('Order.Code eq &1', quoter(pcCode))).
    end method.

    method public void GetOrderByNum (input        piCustNum as integer,
                                      input        piOrderNum as integer,
                                      output dataset dsOrder):
        ReadData(substitute('Order.CustNum eq &1 and Order.OrderNum eq &2',
                        piCustNum, piOrderNum)).
    end method.
    
    method public void ListOrders (input poFilter as JsonObject,
                                   output dataset dsOrder):
        define variable cWhere as character extent no-undo.

        assign cWhere = BuildWhereClause(poFilter).
         
        if session:debug-alert then
            message 
            '[1]=' cWhere[1] skip
            '[2]=' cWhere[2] skip
            '[3]=' cWhere[3] skip
            view-as alert-box title 'ListOrders'.
        
        ReadData(cWhere[1]).
    end method.
    
    /* SUBMIT */
    method public void UpdateOrders (input-output dataset dsOrder):
        Submit(input-output dataset dsOrder by-reference).
    end method.
    
end class.