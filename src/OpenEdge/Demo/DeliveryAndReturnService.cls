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

using OpenEdge.Demo.DeliveryEntity.
using OpenEdge.Demo.LocationService.
using OpenEdge.Demo.OrderEntity.
using OpenEdge.Demo.OrderStatusEnum.
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

class OpenEdge.Demo.DeliveryAndReturnService:
    {OpenEdge/Demo/delivery_dataset.i}
    {OpenEdge/Demo/order_dataset.i}
    
    define private variable moNotificationService as PushNotificationService no-undo.
    define private variable moDeliveryEntity as DeliveryEntity no-undo.
    define private variable moOrderEntity as OrderEntity no-undo.
    define private variable moLocationService as LocationService no-undo.
    
	constructor public DeliveryAndReturnService():
		super().
		
		assign moDeliveryEntity = new DeliveryEntity()
		       moOrderEntity    = new OrderEntity()
		       moLocationService = new LocationService().
        
        this-object:Initialize().
	end constructor.
	
	method public void Destroy():
        moDeliveryEntity:Destroy().
        moOrderEntity:Destroy().
	end method.
	
    method public void Initialize():
        define variable oConfig as JsonObject no-undo.
        define variable oParser as ObjectModelParser no-undo.
        
        assign oParser = new ObjectModelParser()
               oConfig = cast(oParser:ParseFile('cfg/config.json'), JsonObject)
               oConfig = oConfig:GetJsonObject('notificationService').
        
        assign moNotificationService = PushNotificationService:Instance(
                                        URI:Parse(oConfig:GetCharacter('URL')),
                                        oConfig:GetCharacter('apiKey')).
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
        moDeliveryEntity:UpdateDriverDeliveries(input-output dataset dsDriverDelivery by-reference).
    end method.
    
    /* INVOKE */
    method public void RequestReturn(input  piCustNum as integer,
                                     input  piOrderNum as integer,
                                     input  pcReason as character,
                                     output pcReturnStatus as longchar /* JSON */):
        define variable oReturnStatus as JsonObject no-undo.
        define variable oMessages     as JsonArray  no-undo.
        define variable iMsgLoop      as integer    no-undo.
        define variable hRulesMessage as handle     no-undo.
        define variable oFilter       as JsonObject no-undo.
                                                 
        /*
        pcReturnStatus = '~{ "status": "approved/pending/rejected/error", 
                             "reason":"optional", 
                             "returnCode":"", 
                             "error":true/false}'.
        */
        assign oReturnStatus = new JsonObject()
               oMessages     = new JsonArray().
        /* setup return object */
        oReturnStatus:AddNull('status').
        oReturnStatus:AddNull('reason').
        oReturnStatus:AddNull('returnCode').
        oReturnStatus:Add('error', false).
        
        /* find customer order */
        oFilter = new JsonObject().
        oFilter:Add('custNum', piCustNum).
        oFilter:Add('orderNum', piOrderNum).
        
        moOrderEntity:ListOrders(oFilter, output dataset dsOrder by-reference).
        find first eOrder. /* should be only 1 */
        
        assign eOrder.OrderStatus = OrderStatusEnum:ReturnRequested:Name
               eOrder.ReturnReason = pcReason.
        
        /* call Decision Service to determine return approval/denial and reasons for 
        oMessages:Read(hRulesMessage).
        */
        
        if etime mod 2 eq 0 then
        do:
            assign eOrder.ReturnCode = substitute('RMA-&1-&2', eOrder.CustNum, eOrder.OrderNum) 
                   eOrder.OrderStatus = OrderStatusEnum:ReturnApproved:Name.
            oMessages:Add('great customer').
        end.
        else
        do:
            assign eOrder.OrderStatus = OrderStatusEnum:ReturnDenied:Name.
            oMessages:Add(substitute('dodgy reason given: &1', pcReason)).
        end.
        
        /* update DB */        
        moDeliveryEntity:UpdateDriverDeliveries(input-output dataset dsDriverDelivery by-reference).
        
        /* return info and messages */
        oReturnStatus:Set('status',     eOrder.OrderStatus).
        oReturnStatus:Set('returnCode', eOrder.ReturnCode).
        oReturnStatus:Set('reason',     oMessages).
        
        catch oAppError as AppError:
            oReturnStatus:Set('status', 'error').
            oReturnStatus:Set('error',  true).
            oReturnStatus:Set('reason', oMessages).
            
            oMessages:Add(oAppError:ReturnValue).
            
            do iMsgLoop = 1 to oAppError:NumMessages:
                oMessages:Add(oAppError:GetMessage(iMsgLoop)).
            end.
        end catch.
        catch oError as Error:
            oReturnStatus:Set('status', 'error').
            oReturnStatus:Set('error',  true).
            oReturnStatus:Set('reason', oMessages).
            
            do iMsgLoop = 1 to oError:NumMessages:
                oMessages:Add(oError:GetMessage(iMsgLoop)).
            end.
        end catch.
        finally:
            oReturnStatus:Write(input-output pcReturnStatus).
        end finally.
    end method.
    
    /* INVOKE */
    method public character CloseDelivery(input pcDeliveryCode as character):
        define variable cFilterString as character no-undo.
        define variable oFilter       as JsonObject no-undo.
        
        oFilter = new JsonObject().
        oFilter:Add('deliveryCode', pcDeliveryCode).
        oFilter:Write(output cFilterString).
        
        moDeliveryEntity:ListDriverDeliveries(
                            cFilterString, 
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
               eDelivery.VehicleCode = hVehicle::Code
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
        
        assign eDelivery.RouteCode = hRoute::RouteCode.
        
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
        
        
        /* find a route for the customer. */

        /* find a driver that's on that route */

        /**/
        oFilter = new JsonObject().
        oFilter:Add('driverCode', pcDriverCode).
        oFilter:Add('depotCode', pcDepotCode).
        
        moDeliveryEntity:ListDriverDeliveries(
                    input  oFilter,
                    output dataset dsDriverDelivery by-reference).
        
        /* send the notification */        
        assign cMessage    = 'New pickup: ' + pcReturnCode 
               iNumReturns = 1.
               
        oBuilder = PushNotificationMessageBuilder
                    :Send(cMessage, iNumReturns)
                    :AddStringFilter('depotCode', pcDepotCode,
                                     PushNotificationFilterOperandEnum:Equals)
                    :AddStringFilter('driverCode', cDriverCode,
                                     PushNotificationFilterOperandEnum:Equals)
                    .
        
        moNotificationService:SendNotification(oBuilder:Payload).                                         
    end method.
end class.