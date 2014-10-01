/*------------------------------------------------------------------------
   File        : ShoppingService
   Purpose     : Task-based service for scheduling and creating driver
                 deliveries from orders
   Syntax      : 
   Description : 
   Author(s)   : pjudge
   Created     : Fri Aug 01 09:11:42 EDT 2014
   Notes       :  
 ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.Assert.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.AppError.
using TripleDee.Shopping.DeliveryEntity.
using TripleDee.Shopping.LocationService.
using TripleDee.Shopping.OrderEntity.
using TripleDee.Shopping.OrderStatusEnum.
using TripleDee.Shopping.DeliveryStatusEnum.
using TripleDee.Shopping.BusinessEntity.

class TripleDee.Shopping.ShoppingService:
    {TripleDee/Shopping/delivery_dataset.i &access-level=private}
    {TripleDee/Shopping/order_dataset.i    &access-level=private}    
    
    define private variable moDeliveryEntity as DeliveryEntity no-undo.
    define private variable moOrderEntity as OrderEntity no-undo.
    define private variable moLocationService as LocationService no-undo.
    
    define private variable mhDeliveryChanges as handle no-undo.
    define private variable mhOrderChanges as handle no-undo.
    
	constructor public ShoppingService():
		super().
		
        assign moDeliveryEntity  = new DeliveryEntity()
               moOrderEntity     = new OrderEntity()
               moLocationService = new LocationService().
        
        create dataset mhDeliveryChanges.
        mhDeliveryChanges:create-like(dataset dsDriverDelivery:handle).               

        create dataset mhOrderChanges.
        mhOrderChanges:create-like(dataset dsOrder:handle).               
	end constructor.
	
    /* INVOKE */
    method public void SchedulePickup(input  pcOrderCode  as character,
                                      output pcDriverCode as character):
        define variable oFilter as JsonObject no-undo.
        define variable hChanges as handle no-undo.
        
        /* find customer order */
        moOrderEntity:GetOrderByCode(pcOrderCode, output dataset dsOrder).
        
        /* should be only 1 */
        find first eOrder. 
        find first eCustomerDetail where
                   eCustomerDetail.CustNum eq eOrder.CustNum.
        
        /* find open deliveries */
        assign oFilter = new JsonObject().
        oFilter:Add('deliveryStatus', DeliveryStatusEnum:Open:Name).
        
        moDeliveryEntity:ListDriverDeliveries(input oFilter,
                                              output dataset dsDriverDelivery).
        find first eDelivery no-error.
        if not available eDelivery then
            return error new AppError('No open deliveries', 0).
        
        assign pcDriverCode = eDelivery.DriverCode.
        
        BusinessEntity:EnableDatasetForUpdate(dataset dsDriverDelivery:handle).
        BusinessEntity:EnableDatasetForUpdate(dataset dsOrder:handle).
        
        do transaction:
            create eDeliveryItem.
            assign eDeliveryItem.Code           = guid 
                   eDeliveryItem.DeliveryCode   = eDelivery.Code
                   eDeliveryItem.OrderCode      = eOrder.Code 
                   eDeliveryItem.DeliveryStatus = OrderStatusEnum:ReturnApproved:Name
                   
                   eDeliveryItem.Location       = eCustomerDetail.Location
                   eDeliveryItem.ContactName    = eCustomerDetail.Name
                   eDeliveryItem.ContactNumber  = eCustomerDetail.ContactNumber
                   
                   /* mark the delivery as out for pickup */
                   eOrder.OrderStatus           = OrderStatusEnum:PickupScheduled:Name.
        end.
        
        BusinessEntity:DisableDatasetForUpdate(dataset dsDriverDelivery:handle).
        BusinessEntity:DisableDatasetForUpdate(dataset dsOrder:handle).
        
        /* only send changes */
        mhDeliveryChanges:get-changes(dataset dsDriverDelivery:handle).
        
        moDeliveryEntity:UpdateDriverDeliveries(input-output dataset-handle mhDeliveryChanges by-reference).
        moOrderEntity:UpdateOrders(input-output dataset dsOrder by-reference).
    end method.
    
    /* INVOKE */
    method public void CloseDelivery(input pcDeliveryCode as character):
        moDeliveryEntity:GetDeliveryByCode(pcDeliveryCode,
                                           output dataset dsDriverDelivery).

        BusinessEntity:EnableDatasetForUpdate(dataset dsDriverDelivery:handle).

        find eDelivery.
        assign eDelivery.EndTime        = now
               eDelivery.DeliveryStatus = DeliveryStatusEnum:Closed:Name.
        
        /* update the order's status */
        for each eDeliveryItem where
                 eDeliveryItem.DeliveryCode eq eDelivery.Code:
            moOrderEntity:GetOrderByCode(eDeliveryItem.OrderCode, output dataset dsOrder).
            
            find eOrder where eOrder.Code eq eDeliveryItem.OrderCode.
            
            BusinessEntity:EnableDatasetForUpdate(dataset dsOrder:handle).
            case eDeliveryItem.DeliveryStatus:
                /* revert un-delivered and un-picked-up orders */
                when OrderStatusEnum:OutForDelivery:Name then
                    assign eOrder.OrderStatus = OrderStatusEnum:Ordered:Name.
                when OrderStatusEnum:PickupScheduled:Name then
                    assign eOrder.OrderStatus = OrderStatusEnum:ReturnApproved:Name.
                otherwise
                    assign eOrder.OrderStatus = eDeliveryItem.DeliveryStatus.
            end case.
            BusinessEntity:DisableDatasetForUpdate(dataset dsOrder:handle).
            
            moOrderEntity:UpdateOrders(input-output dataset dsOrder by-reference).
        end.
        BusinessEntity:DisableDatasetForUpdate(dataset dsDriverDelivery:handle).
        
        moDeliveryEntity:UpdateDriverDeliveries(input-output dataset dsDriverDelivery by-reference).
    end method.
    
    /* INVOKE */
    method public character OpenDelivery(input pcDriver as character):
        define variable cDeliveryCode as character no-undo.
        define variable oFilter as JsonObject no-undo.
        define variable oArray as JsonArray no-undo.
        define variable hVehicle as handle no-undo.
        define variable hBuffer as handle no-undo.
        define variable dAvailableCapacity as decimal no-undo.
        define variable dOrderVolume as decimal no-undo.
        
        oFilter = new JsonObject().
        oArray = new JsonArray().
        oFilter:Add('orderStatus', oArray).
        oArray:Add(OrderStatusEnum:Ordered:Name).
        oArray:Add(OrderStatusEnum:ReturnApproved:Name).
        
        moOrderEntity:ListOrders(input  oFilter,
                                 output dataset dsOrder).
        
        moLocationService:AllocateAvailableVehicle(output table-handle hVehicle).
        assign hBuffer = hVehicle:default-buffer-handle.
                                        
        BusinessEntity:EnableDatasetForUpdate(dataset dsDriverDelivery:handle).
        BusinessEntity:EnableDatasetForUpdate(dataset dsOrder:handle).
        
        create eDelivery.
        assign cDeliveryCode            = guid
               eDelivery.Code           = cDeliveryCode
               eDelivery.DeliveryStatus = DeliveryStatusEnum:Open:Name
               eDelivery.DriverCode     = pcDriver
               eDelivery.VehicleCode    = hBuffer::code
               eDelivery.StartTime      = now
               eDelivery.EndTime        = ?
               
               dAvailableCapacity       = hBuffer::Capacity.
        
        for each eOrder,
            first eCustomerDetail where
                  eCustomerDetail.CustNum eq eOrder.CustNum
                  no-lock:
            
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
                   eDeliveryItem.DeliveryStatus = eOrder.OrderStatus    /* ordered or returnapproved */
                   
                   eDeliveryItem.Location       = eCustomerDetail.Location
                   eDeliveryItem.ContactName    = eCustomerDetail.Name
                   eDeliveryItem.ContactNumber  = eCustomerDetail.ContactNumber
                   
                   dAvailableCapacity           = dAvailableCapacity - dOrderVolume.
                   
            /* flag order so that we don't try to deliver orders more than once. */
            case eOrder.OrderStatus:
                when OrderStatusEnum:Ordered:Name then
                    assign eOrder.OrderStatus = OrderStatusEnum:OutForDelivery:Name.
                when OrderStatusEnum:ReturnApproved:Name then
                    assign eOrder.OrderStatus = OrderStatusEnum:PickupScheduled:Name.
            end case.
        end.
        
        BusinessEntity:DisableDatasetForUpdate(dataset dsDriverDelivery:handle).
        BusinessEntity:DisableDatasetForUpdate(dataset dsOrder:handle).
        
        moDeliveryEntity:UpdateDriverDeliveries(input-output dataset dsDriverDelivery by-reference).
        moOrderEntity:UpdateOrders(input-output dataset dsOrder by-reference ).
        
        return cDeliveryCode.
    end method.
    
end class.