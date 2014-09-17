@openapi.openedge.export FILE(type="BPM", operationName="%FILENAME%", useReturnValue="false", writeDataSetBeforeImage="false", executionMode="singleton").
/*------------------------------------------------------------------------
   File        : DeliveryAndReturnService
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : pjudge
   Created     : Fri Aug 01 09:11:42 EDT 2014
   Notes       : * Demo data generated with http://www.json-generator.com/ 
 ----------------------------------------------------------------------*/
block-level on error undo, throw.

using TripleDee.Shopping.DeliveryEntity.
using TripleDee.Shopping.LocationService.
using TripleDee.Shopping.OrderEntity.
using TripleDee.Shopping.OrderStatusEnum.
using OpenEdge.Mobile.PushNotificationFilterOperandEnum.
using OpenEdge.Mobile.PushNotificationMessageBuilder.
using OpenEdge.Mobile.PushNotificationService.
using OpenEdge.Net.URI.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.ObjectModelParser.
using Progress.Lang.AppError.
using Progress.Lang.Error.
using OpenEdge.Core.Assert.
using OpenEdge.BusinessRules.DecisionService.
using OpenEdge.BusinessRules.RulesServerConnectionParameters.
using OpenEdge.BusinessRules.RulesServerConnection.
using Progress.BPM.UserSession.
using Progress.Lang.OERequestInfo.
using Progress.BPM.Process.

class TripleDee.Shopping.DeliveryAndReturnService:
    {TripleDee/Shopping/delivery_dataset.i}
    {TripleDee/Shopping/order_dataset.i}
    {OpenEdge/BusinessRules/ttRulesMessage.i}
    
    define private variable moNotificationService as PushNotificationService no-undo.
    define private variable moDeliveryEntity as DeliveryEntity no-undo.
    define private variable moOrderEntity as OrderEntity no-undo.
    define private variable moLocationService as LocationService no-undo.
    define private variable moDecisionService as DecisionService no-undo.
    define private variable moBpmService as UserSession no-undo.
    
	constructor public DeliveryAndReturnService():
		super().
		
		assign moDeliveryEntity  = new DeliveryEntity()
		       moOrderEntity     = new OrderEntity()
		       moLocationService = new LocationService().
        
        this-object:Initialize().
	end constructor.
	
	method public void Destroy():
        moDeliveryEntity:Destroy().
        moOrderEntity:Destroy().
        moLocationService:Destroy().

        DestroyNotificationService().
        DestroyDecisionService().
        DestroyBpmService().
	end method.
	
    method public void Initialize():
        define variable oConfig as JsonObject no-undo.
        
        assign oConfig = cast(new ObjectModelParser():ParseFile('conf/config.json'), JsonObject).
        
        InitializeNotificationService(
                oConfig:GetJsonObject('notificationService')).

        InitializeDecisionService(
                oConfig:GetJsonObject('decisionService')).
                                        
        InitializeBpmService(
                oConfig:GetJsonObject('bpmService')).
    end method.
    
    method protected void InitializeNotificationService(input poConfig as JsonObject):
        if poConfig:GetLogical('enabled') then
            assign moNotificationService = PushNotificationService:Instance(
                                            URI:Parse(poConfig:GetCharacter('URL')),
                                            poConfig:GetCharacter('apiKey')).
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
    
    method protected void InitializeBpmService(input poConfig as JsonObject):
        if poConfig:GetLogical('enabled') then
        do:
            assign moBpmService = new UserSession(poConfig:GetCharacter('serverURL')).
            moBpmService:Connect(poConfig:GetCharacter('user'), 
                                 poConfig:GetCharacter('password')).
        end.
    end method.

    method protected void DestroyNotificationService():
        assign moNotificationService = ?.
    end method.
    
    method protected void DestroyDecisionService():
        assign moDecisionService = ?.
    end method.
    
    method protected void DestroyBpmService():
        /* log out */
        if valid-object (moBpmService) then
            moBpmService:Disconnect(true).
        
        assign moBpmService = ?.
    end method.
    
    /* READ */
    method public void ListDriverDeliveries(input filter as character, 
                                            output dataset dsDriverDelivery):
        moDeliveryEntity:ListDriverDeliveries(
                                input filter,
                                output dataset dsDriverDelivery by-reference).
    end method.
    
    /* SUBMIT */
    method public void UpdateDriverDeliveries(input-output dataset dsDriverDelivery):
        define variable oProcess as Process no-undo.
        
        /* Complete the BPM workstep */
        for each eOrder where
                 eOrder.OrderStatus eq OrderStatusEnum:ReturnReceived:Name:
                     
            oProcess = moBpmService:GetProcess('ReturnProcess', eOrder.Code).
            oProcess:CompleteWorkstep('ReturnPickup').
        end.
        
        moDeliveryEntity:UpdateDriverDeliveries(input-output dataset dsDriverDelivery by-reference).
    end method.
    
    /* INVOKE */
    method public character RequestReturn(input        pcOrderCode as character,
                                          input-output pcReason as character,
                                                output pcReturnStatus as character ):
        /* find customer order */
        moOrderEntity:GetOrderByCode(pcOrderCode, output dataset dsOrder by-reference).
        find first eOrder. /* should be only 1 */
        
        assign eOrder.OrderStatus = OrderStatusEnum:ReturnRequested:Name
               eOrder.ReturnReason = pcReason.
        
        temp-table eOrder:tracking-changes = true.
        
        /* calls corticon */
        moDecisionService:InvokeService(input-output table eOrder by-reference).
        moDecisionService:GetMessages(output table RulesMessage by-reference).
        
        /* flag the row as changed */
        find first eOrder.
        buffer eOrder:row-state = row-modified.
        
        temp-table eOrder:tracking-changes = false.

        find first RulesMessage where
                   RulesMessage.TableName eq 'eOrder' and
                   RulesMessage.DataKeyValue eq string(rowid(eOrder))
                   no-error.
        if available RulesMessage then
            assign pcReason = RulesMessage.MessageText.                    

        /** DECISION SERVICE DOES THIS 
        assign eOrder.ReturnCode = substitute('RMA-&1-&2', eOrder.CustNum, eOrder.OrderNum) 
               /*eOrder.OrderStatus = OrderStatusEnum:ReturnApproved:Name.*/
        **/
        
        /* updates order status & return code from decision service output */
        moOrderEntity:UpdateOrders(input-output dataset dsOrder by-reference).
        
        assign pcReturnStatus = eOrder.OrderStatus.
        return eOrder.ReturnCode.
    end method.
    
    /* INVOKE */
    method public void SchedulePickup(input  pcOrderCode    as character,
                                      input  pcReturnCode   as character,
                                      output pcDeliveryCode as character ):
        define variable oFilter as JsonObject no-undo.
        define variable hRoute  as handle no-undo.
        
        /* find customer order */
        moOrderEntity:GetOrderByCode(pcOrderCode, output dataset dsOrder by-reference).
        
        /* should be only 1 */
        find first eOrder. 
        find first eCustomerDetail where
                   eCustomerDetail.CustNum eq eOrder.CustNum.
        
        moLocationService:FindRouteForLocation(
                            input eCustomerDetail.Location,
                            output table-handle hRoute by-reference).
        
        /* add the item to the delivery */
        assign oFilter = new JsonObject().
        oFilter:Add('routeCode', hRoute::Code).
        
        moDeliveryEntity:ListDriverDeliveries(input oFilter,
                                              output dataset dsDriverDelivery by-reference).

        find first eDelivery.
        
        temp-table eDeliveryItem:tracking-changes = true.
        do transaction:
            create eDeliveryItem.
            assign eDeliveryItem.Code           = guid 
                   eDeliveryItem.DeliveryCode   = eDelivery.Code
                   eDeliveryItem.OrderCode      = eOrder.Code 
                   eDeliveryItem.DeliveryStatus = OrderStatusEnum:ReturnApproved:Name.
        end.
        temp-table eDeliveryItem:tracking-changes = false.
        
        moDeliveryEntity:UpdateDriverDeliveries(input-output dataset dsDriverDelivery by-reference).
        
        assign pcDeliveryCode = eDelivery.Code.
    end method.
    
    /* INVOKE */
    method public character CloseDelivery(input pcDeliveryCode as character):
        moDeliveryEntity:GetDeliveryByCode(pcDeliveryCode,
                            output dataset dsDriverDelivery by-reference).
        
        find eDelivery.
        assign eDelivery.EndTime = now.
        
        moDeliveryEntity:UpdateDriverDeliveries(input-output dataset dsDriverDelivery by-reference).
    end method.
    
    /* INVOKE */
    method public character OpenDelivery(input pcDepot as character,
                                         input pcDriver as character):
        define variable cRouteCode as character no-undo.
        define variable oFilter as JsonObject no-undo.
        define variable oArray as JsonArray no-undo.
        define variable hVehicle as handle no-undo.
        define variable hRoute as handle no-undo.
        define variable dAvailableCapacity as decimal no-undo.
        define variable dOrderVolume as decimal no-undo.
        
        oFilter = new JsonObject().
        oArray = new JsonArray().
        oFilter:Add('orderStatus', oArray).
        oArray:Add(OrderStatusEnum:Ordered:Name).
        oArray:Add(OrderStatusEnum:ReturnApproved:Name).
        
        moOrderEntity:ListOrders(input  oFilter,
                                 output dataset dsOrder by-reference).
        
        moLocationService:AllocateAvailableVehicle(
                                input  pcDepot, 
                                output table-handle hVehicle by-reference).
        
        create eDelivery.
        assign eDelivery.Code        = guid
               eDelivery.DepotCode   = pcDepot
               eDelivery.DriverCode  = pcDriver
               eDelivery.VehicleCode = hVehicle::code
               eDelivery.StartTime   = now
               eDelivery.EndTime     = ?
               dAvailableCapacity    = hVehicle::Capacity.
        
        for each eOrder,
            first eCustomerDetail where
                  eCustomerDetail.CustNum eq eOrder.CustNum
                  no-lock:
            
            /* can only ship from this depot */
            moLocationService:FindRouteForLocation(
                                input eCustomerDetail.Location,
                                output table-handle hRoute by-reference).            
            /* only deliveries for this depot considered */
            if hRoute::DepotCode ne pcDepot then
                next.
            
            assign dOrderVolume = 0.
            for each eOrderLine where
                     eOrderLine.OrderCode eq eOrder.Code:
                assign dOrderVolume = dOrderVolume
                                    + eOrderLine.Volume.                         
            end.
            
            /* truck can only take _so_ much ... */
            if dAvailableCapacity - dOrderVolume lt 0 then
                leave.
                 
            create eDeliveryItem.
            assign eDeliveryItem.Code           = guid 
                   eDeliveryItem.DeliveryCode   = eDelivery.Code
                   eDeliveryItem.OrderCode      = eOrder.Code
                   eDeliveryItem.DeliveryStatus = OrderStatusEnum:OutForDelivery:Name
                   dAvailableCapacity           = dAvailableCapacity - dOrderVolume 
                   .
        end.
        
        /* this is likely to be some really complex logic. we just use 
           the last one (really just any route). 
           https://en.wikipedia.org/wiki/Vehicle_routing_problem */
        moLocationService:FindRouteForDelivery(
                                        input  eDelivery.Code,
                                        output table-handle hRoute by-reference).
        /* only deliveries for this depot considered */
        Assert:Equals(pcDepot, hRoute::DepotCode).
        
        assign eDelivery.RouteCode = hRoute::Code.
        
        moDeliveryEntity:UpdateDriverDeliveries(input-output dataset dsDriverDelivery by-reference).
        
        return eDelivery.Code.
    end method.
    
    method public void NotifyDriver (input pcDepotCode as character,
                                     input pcDriverCode as character,
                                     input pcReturnCode as character):
        define variable iNumReturns as integer no-undo.
        define variable cMessage as character no-undo.
        define variable oBuilder as PushNotificationMessageBuilder no-undo.
        define variable cDriverCode as character no-undo.
        define variable oFilter as JsonObject no-undo.
        define variable oProcess as Process no-undo.
        
        define query qryReturns for eDeliveryItem.
        
        oFilter = new JsonObject().
        oFilter:Add('driverCode', pcDriverCode).
        oFilter:Add('depotCode', pcDepotCode).
        oFilter:Add('itemStatus', OrderStatusEnum:ReturnApproved:Name).
        
        moDeliveryEntity:ListDriverDeliveries(
                    input  oFilter,
                    output dataset dsDriverDelivery by-reference).
        
        open query qryReturns preselect each eDeliveryItem.
        
        /* send the notification */        
        assign cMessage    = 'New pickup: ' + pcReturnCode 
               iNumReturns = query qryReturns:num-results 
               
               /* send the notification immediately */
               oBuilder = PushNotificationMessageBuilder
                    :Send(cMessage, iNumReturns)
                    :AddStringFilter('depotCode', pcDepotCode,
                                     PushNotificationFilterOperandEnum:Equals)
                    :AddStringFilter('driverCode', cDriverCode,
                                     PushNotificationFilterOperandEnum:Equals)
               .
        moNotificationService:SendNotification(oBuilder:Payload).
        
        /* activate task along */
        oFilter = new JsonObject().
        oFilter:Add('returnCode', pcReturnCode).
        
        moOrderEntity:ListOrders(oFilter, output dataset dsOrder by-reference).
        find first eOrder.
        
        oProcess = moBpmService:GetProcess('ReturnProcess', eOrder.Code).
        oProcess:ActivateWorkstep('ReturnPickup').
    end method.
    
    method public character GetOrderCode(input        piCustNum as integer,
                                         input        piOrderNum as integer):
        moOrderEntity:GetOrderByNum(piCustNum, piOrderNum, output dataset dsOrder by-reference).

        /* should be only 1 */
        find first eOrder no-error.
        
        if available eOrder then
            return eOrder.Code.                                             
    end method.

end class.