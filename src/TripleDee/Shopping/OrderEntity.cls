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
using OpenEdge.BusinessRules.DecisionService.
using Progress.Json.ObjectModel.ObjectModelParser.
using OpenEdge.BusinessRules.RulesServerConnectionParameters.
using OpenEdge.BusinessRules.RulesServerConnection.
using TripleDee.Shopping.OrderStatusEnum.

class TripleDee.Shopping.OrderEntity inherits BusinessEntity: 
    {TripleDee/Shopping/order_dataset.i &access-level=private}
    {OpenEdge/BusinessRules/ttRulesMessage.i}
    
    define data-source srcOrder for Order.
    define data-source srcOLine for OrderLine.
    define data-source srcCustomer for CustomerDetail.
    
    define private variable moDecisionService as DecisionService no-undo.
    
	method override public void Destroy():
	    super:Destroy().
	    moDecisionService = ?.
	end method.

	method override public void Initialize():
        define variable oConfig as JsonObject no-undo.
        
        super:Initialize().
        
	    assign extent(ProDataSource) = 3
	           ProDataSource[1] = data-source srcOrder:handle
	           ProDataSource[2] = data-source srcOLine:handle
	           ProDataSource[3] = data-source srcCustomer:handle
	           .

        assign oConfig = cast(new ObjectModelParser():ParseFile('conf/config.json'), JsonObject).
        
        InitializeDecisionService(
                oConfig:GetJsonObject('decisionService')).
	end method.
	
    method protected void InitializeDecisionService(input poConfig as JsonObject):
        define variable oParams as RulesServerConnectionParameters no-undo.
        define variable oServerConnection as RulesServerConnection no-undo.
        
        if poConfig:GetLogical('enabled') then
            assign oParams = new RulesServerConnectionParameters(poConfig:GetJsonObject('RulesServer'))
                   oServerConnection = new RulesServerConnection(oParams)
                   
                   /* Use the latest version of the ReturnApproval DecisionService */
                   moDecisionService = new DecisionService(oServerConnection,
                                            poConfig:GetCharacter('name'),
                                            poConfig:GetDecimal('version')).
    end method.
    	
	constructor public OrderEntity ():
		super (dataset dsOrder:handle).
	end constructor.
	
	/* READ */
	method public void ListOrders (input filter as character,
	                               output dataset dsOrder):
        ListOrders(input ParseFilter(filter), output dataset dsOrder).
    end method.
    
    method public void GetOrderByCode (input pcCode as character,
                                       output dataset dsOrder):
        ReadData(substitute('where Order.Code eq &1', quoter(pcCode))).
    end method.

    method public void GetOrderByNum (input        piCustNum as integer,
                                      input        piOrderNum as integer,
                                      output dataset dsOrder):
        ReadData(substitute('where Order.CustNum eq &1 and Order.OrderNum eq &2',
                        piCustNum, piOrderNum)).
    end method.
    
    method public void ListOrders (input poFilter as JsonObject,
                                   output dataset dsOrder):
        define variable cWhere as character extent no-undo.

        assign cWhere = BuildWhereClause(poFilter).
                
        ReadData(cWhere).
    end method.
    
    /* SUBMIT */
    method public void UpdateOrders (input-output dataset dsOrder):
        Submit(input-output dataset dsOrder by-reference).
    end method.
    
    /* INVOKE */
    method public character RequestReturn(input        pcOrderCode as character,
                                          input-output pcReason as character,
                                                output pcReturnCode as character ):
        /* find customer order */
        GetOrderByCode(pcOrderCode, output dataset dsOrder).
        find first eOrder. /* should be only 1 */
        
        /* mark it as a return request */
        EnableDatasetForUpdate().
        assign eOrder.OrderStatus  = OrderStatusEnum:ReturnRequested:Name
               eOrder.ReturnReason = pcReason.
        DisableDatasetForUpdate().
        
        /* updates order status & return code from decision service output */
        Submit(input-output dataset dsOrder by-reference).
        
        /* Assume all went well (yes, but this is a demo) and
           treat the local version as Pravda */
        dataset dsOrder:accept-changes().
        
        /* calls corticon */
        if valid-object(moDecisionService) then
        do:
            moDecisionService:InvokeService(input-output table eOrder by-reference).
            moDecisionService:GetMessages(output table RulesMessage).
        end.
        
        /* flag the row as changed */
        EnableDatasetForUpdate().
        
        find first eOrder.
        row-state(eOrder) = row-modified.
        
        find first RulesMessage where
                   RulesMessage.TableName eq 'eOrder' and
                   RulesMessage.DataKeyValue eq string(rowid(eOrder))
                   no-error.
        if available RulesMessage then
            assign pcReason = RulesMessage.MessageText.                    

        /** DECISION SERVICE HAS DONE THIS **/
        assign eOrder.ReturnCode  = substitute('RMA-&1-&2', eOrder.CustNum, eOrder.OrderNum)
               eOrder.OrderStatus = OrderStatusEnum:ReturnApproved:Name.
        /* decision service */
        
        DisableDatasetForUpdate().
        
        /* updates order status & return code from decision service output */
        Submit(input-output dataset dsOrder by-reference).
        
        find first eOrder. 
        assign pcReturnCode = eOrder.ReturnCode.             
        return eOrder.OrderStatus.
    end method.
    
    method public character GetOrderCode(input piCustNum as integer,
                                         input piOrderNum as integer):
        GetOrderByNum(input  piCustNum,
                      input  piOrderNum,
                      output dataset dsOrder).
        
        /* should be only 1 */
        find first eOrder no-error.
        
        if available eOrder then
            return eOrder.Code.
        return ?.
    end method.
        
end class.