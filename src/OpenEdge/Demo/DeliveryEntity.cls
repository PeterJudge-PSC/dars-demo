 
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

using OpenEdge.Demo.BusinessEntity.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonDataType.

class OpenEdge.Demo.DeliveryEntity inherits BusinessEntity:
    {OpenEdge/Demo/delivery_dataset.i}
    
    define data-source srcDelivery for Delivery.
    define data-source srcDelItem for DeliveryItem.
    
	method override public void Initialize(  ):
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
    
    method public void ListDriverDeliveries(input poFilter as JsonObject, 
                                            output dataset dsDriverDelivery):
        define variable cWhere as character extent 2 no-undo.
        define variable cDelim as character extent 2 no-undo.
        define variable oArray as JsonArray no-undo.
        define variable iLoop as integer no-undo.
        define variable iMax as integer no-undo.
        
        /* filter: 
                { "driverCode":"", "depotCode":"", "deliveryCode":"" } */
        
        /* [1] = Delivery 
           [2] = DeliveryItem */
        assign cWhere = ''
               cDelim = ''.
        
        if poFilter:Has('deliveryCode') then
            assign cWhere[1] = cWhere[1] + cDelim[1]
                             + substitute('Delivery.Code eq &1',
                                    quoter(poFilter:GetCharacter('deliveryCode')))
                   cDelim[1] = ' and '.
        
        if poFilter:Has('driverCode') then
            assign cWhere[1] = cWhere[1] + cDelim[1]
                             + substitute('Delivery.DriverCode eq &1',
                                    quoter(poFilter:GetCharacter('driverCode')))
                   cDelim[1] = ' and '.

        if poFilter:Has('depotCode') then
            assign cWhere[1] = cWhere[1] + cDelim[1]
                             + substitute('Delivery.DepotCode eq &1', 
                                    quoter(poFilter:GetCharacter('depotCode')))
                   cDelim[1] = ' and '.

        if poFilter:Has('startTime') then
            assign cWhere[1] = cWhere[1] + cDelim[1]
                             + substitute('Delivery.StartTime eq &1', poFilter:GetDatetimeTZ('startTime'))
                   cDelim[1] = ' and '.

        if poFilter:Has('endTime') then
            assign cWhere[1] = cWhere[1] + cDelim[1]
                             + substitute('Delivery.StartTime eq &1', poFilter:GetDatetimeTZ('endTime'))
                   cDelim[1] = ' and '.
        
        if poFilter:Has('itemStatus') then
        do:
            if poFilter:GetType('itemStatus') eq JsonDataType:STRING then
                assign cWhere[2] = cWhere[2] + cDelim[2]
                                 + substitute('DeliveryItem.DeliveryStatus eq &1',
                                        quoter(poFilter:GetCharacter('itemStatus')))
                       cDelim[2] = ' and '.
            else
            if poFilter:GetType('itemStatus') eq JsonDataType:ARRAY then
            do:
                assign oArray = poFilter:GetJsonArray('itemStatus')
                       iMax = oArray:Length
                       cWhere[2] = cWhere[2] + cDelim[2] + ' ( '
                       cDelim[2] = ''.
                       
                do iLoop = 1 to iMax:
                assign cWhere[2] = cWhere[2] + cDelim[2]
                                 + substitute('DeliveryItem.DeliveryStatus eq &1',
                                        quoter(oArray:GetCharacter(iLoop)))
                       cDelim[2] = ' or '.
                end.
                
                /* reset for whole where-clause */
                assign cWhere[2] = cWhere[2] + ' ) '
                       cDelim[2] = ' and '.
            end.
        end.
        
        message 
        '[1]=' cWhere[1] skip
        '[2]=' cWhere[2] skip
        view-as alert-box.
        
        ReadData(cWhere).
    end method.
    
    /* SUBMIT */
    method public void UpdateDriverDeliveries(input-output dataset dsDriverDelivery):
        Submit(input-output dataset dsDriverDelivery by-reference).
    end method.
    
end class.