@openapi.openedge.export FILE(type="BPM", operationName="%FILENAME%", useReturnValue="false", writeDataSetBeforeImage="false", executionMode="singleton").
 
 /*------------------------------------------------------------------------
    File        : DeliveryEntity
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Wed Aug 06 09:56:39 EDT 2014
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using TripleDee.Shopping.BusinessEntity.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonDataType.

class TripleDee.Shopping.DeliveryEntity inherits BusinessEntity:
    {TripleDee/Shopping/delivery_dataset.i}
    
    define data-source srcDelivery for Delivery.
    define data-source srcDelItem for DeliveryItem.
    
	method override public void Initialize():
	    super:Initialize().
	    
        assign extent(this-object:ProDataSource) = 2
               
               this-object:ProDataSource[1] = data-source srcDelivery:handle
               this-object:ProDataSource[2] = data-source srcDelItem:handle
               . 
	end method.
		
	constructor public DeliveryEntity ():
		super(dataset dsDriverDelivery:handle).
	end constructor.
	
    /* READ */
    method public void ListDriverDeliveries(input filter as character, 
                                            output dataset dsDriverDelivery):
        ListDriverDeliveries(
                    input ParseFilter(filter),
                    output dataset dsDriverDelivery by-reference).
    end method.

    method public character extent DBG_BuildQuery(input poFilter as JsonObject):
        return BuildWhereClause(poFilter).
    end method.
    
    method public void ListDriverDeliveries(input poFilter as JsonObject,
                                            output dataset dsDriverDelivery):
        define variable cWhere as character extent  no-undo.
        
        assign cWhere = BuildWhereClause(poFilter).        
        
        if session:debug-alert then
            message 
            '[1]=' cWhere[1] skip
            '[2]=' cWhere[2] skip
            view-as alert-box title 'ListDriverDeliveries'.
        
        ReadData(cWhere).
    end method.
    
    method public void GetDeliveryByCode (input pcCode as character,
                                          output dataset dsDriverDelivery):
        ReadData(substitute('Delivery.Code eq &1', quoter(pcCode))).                                              
    end method.
    
    /* SUBMIT */
    method public void UpdateDriverDeliveries(input-output dataset dsDriverDelivery):
        Submit(input-output dataset dsDriverDelivery by-reference).
    end method.
    
end class.