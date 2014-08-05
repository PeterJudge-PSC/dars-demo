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

using OpenEdge.Demo.BusinessEntity.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.AppError.
using Progress.Lang.Error.
using OpenEdge.Demo.OrderStatusEnum.

class OpenEdge.Demo.DeliveryAndReturnService inherits BusinessEntity:
    /* 'database' schema and holder */
    {OpenEdge/Demo/delivery_database.i}
    
    define temp-table eVehicleType no-undo like dbVehicleType.
    define temp-table eDepot no-undo like dbDepot.
    define temp-table eDriver no-undo like dbDriver.
    define temp-table eRoute no-undo like dbRoute.
    define temp-table eDelivery no-undo like dbDelivery.
    define temp-table eDeliveryItem no-undo like dbDeliveryItem.
    define temp-table eCustomerDetail no-undo like dbCustomerDetail.
    define temp-table eOrder no-undo like dbOrder.
    define temp-table eOrderLine no-undo like dbOrderLine.
    
    define dataset dsDriverDelivery for eDelivery, eDeliveryItem, eOrder, eOrderLine, eCustomerDetail
        data-relation for eDelivery, eDeliveryItem relation-fields(Code, DeliveryCode)
        data-relation for eDeliveryItem, eOrder relation-fields(OrderCode, Code) 
        data-relation for eOrder, eOrderLine relation-fields(Code, OrderCode)
        data-relation for eOrder, eCustomerDetail relation-fields(CustNum, CustNum)
        .
    
    define data-source srcVehicle for dbVehicleType.
    define data-source srcDepot for dbDepot.
    define data-source srcDriver for dbDriver.
    define data-source srcRoute for dbRoute.
    define data-source srcDelivery for dbDelivery.
    define data-source srcDelItem for dbDeliveryItem.
    define data-source srcCustomer for dbCustomerDetail.
    define data-source srcOrder for dbOrder.
    define data-source srcOLine for dbOrderLine.

	constructor public DeliveryAndReturnService ():
		super(dataset dsDriverDelivery:handle).
	end constructor.

	method override public void Destroy():
	    /* persist the data */
	    dataset dsDatabase:write-json('file', 'db/data-after.json', true).
	end method.
	
    method override public void Initialize():
        assign extent(this-object:ProDataSource) = 5
               
               this-object:ProDataSource[1] = data-source srcDelivery:handle
               this-object:ProDataSource[2] = data-source srcDelItem:handle
               this-object:ProDataSource[3] = data-source srcOrder:handle
               this-object:ProDataSource[4] = data-source srcOLine:handle
               this-object:ProDataSource[5] = data-source srcCustomer:handle
               . 
        
        /* LOAD Data */
        dataset dsDatabase:read-json('file', 'db/data.json').
        
        /* set time-sensitive stuff (start/end times */

        /* debug */        
        dataset dsDatabase:write-json('file', 'temp/dump.json', yes).
    end method.

    /* READ */
    method public void ListDriverDeliveries(input filter as character, 
                                            output dataset dsDriverDelivery):
        define variable cDriverCode as character no-undo.
        define variable cDepotCode  as character no-undo.
        define variable cDeliveryCode as character no-undo.
        define variable cRouteCode as character no-undo.
        define variable cDeliveryWhere as character no-undo.
        
        define variable oFilter as JsonObject no-undo.
                
        /* filter: 
                { "driverCode":"", "depotCode":"", "deliveryCode":"" } */
                
        assign oFilter     = ParseFilter(filter)
               cDriverCode = oFilter:GetCharacter('driverCode')
               cDepotCode  = oFilter:GetCharacter('depotCode')
               .
        if oFilter:Has('deliveryCode') then
            assign cDeliveryCode = oFilter:GetCharacter('deliveryCode')
                   cDeliveryWhere = 'where dbDelivery.Code eq ' + quoter(cDeliveryCode)
                   .
        else
            assign cDeliveryWhere = 'where dbDelivery.DriverCode eq ' + quoter(cDriverCode) + ' and '
                                  + '      dbDelivery.DepotCode eq ' + quoter(cDepotCode) + ' and '
                                  + '      dbDelivery.EndTime eq ? '.
        ReadData(cDeliveryWhere).
    end method.    
    
    /* SUBMIT */
    method public void UpdateDriverDeliveries(input-output dataset dsDriverDelivery):
        Submit(input-output dataset dsDriverDelivery by-reference).
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
        ReadData(substitute('where dbOrder.OrderNum eq &1 and dbOrder.CustNum eq &2', 
                                piOrderNum, piCustNum),
                 buffer eOrder:handle).
        find first eOrder. /* should be only 1 */
        
        assign eOrder.OrderStatus = OrderStatusEnum:ReturnRequested:Name
               eOrder.ReturnReason = pcReason.
        
        /* call Decision Service to determine return approval/denial and reasons for 
        oMessages:Read(hRulesMessage).
        */
        
        if true then
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
        CommitData(row-modified).
        
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
    method public character CreateDelivery(input pcDepot as character,
                                           input pcDriver as character):
        define variable dAvailableCapacity as decimal no-undo.
        define variable cRouteCode as character no-undo.
        
        create dbDelivery.
        assign dbDelivery.Code = guid
               dbDelivery.DepotCode = pcDepot
               dbDelivery.DriverCode = pcDriver
               dbDelivery.VehicleCode = AllocateAvailableVehicle(pcDepot)
               dbDelivery.StartTime = now
               dbDelivery.EndTime = ?.
        
        find dbVehicleType where
             dbVehicleType.Code eq dbDelivery.VehicleCode.
        assign dAvailableCapacity = dbVehicleType.Capacity.
        
        for each dbOrder where
                 dbOrder.OrderStatus eq OrderStatusEnum:Ordered:Name or
                 dbOrder.OrderStatus eq OrderStatusEnum:ReturnApproved:Name
                 no-lock,
            first dbCustomerDetail where
                  dbCustomerDetail.CustNum eq dbOrder.CustNum
                  no-lock:
            
            /* cannot ship from this depot */
            assign cRouteCode = FindRouteForLocation(pcDepot, dbCustomerDetail.Location).
            
            if cRouteCode eq '-1' then
                next.
            
            create dbDeliveryItem.
            assign dbDeliveryItem.DeliveryCode = dbDelivery.Code
                   dbDeliveryItem.OrderCode = dbOrder.Code
                   dbDeliveryItem.DeliveryStatus = OrderStatusEnum:OutForDelivery:Name 
                   .
        end.
        
        /* this is likely to be some really complex logic. we just use 
           the last one (really just any route). 
           https://en.wikipedia.org/wiki/Vehicle_routing_problem */
        assign dbDelivery.RouteCode = cRouteCode.
        
        return dbDelivery.Code.
    end method.
    
    method private character FindRouteForLocation(input pcDepot as character,
                                                  input pcLocation as character):

        define query qryRoute for dbRoute scrolling.
        
        open query qryRoute preselect each dbRoute.
        query qryRoute:reposition-to-row(random(1, query qryRoute:num-results)).
        query qryRoute:get-next().
        
        return dbRoute.RouteCode.
        
        /**
        define variable iMaxRange as integer no-undo.
        define variable iCustomerDistance as integer no-undo.
        
        find dbDepot where dbDepot.Code eq pcDepot.
        
        for each dbVehicleType no-lock 
                 by dbVehicleType.Range descending:
            iMaxRange = dbVehicleType.Range.
            leave.                      
        end.
        
        /* geolocate  */
        if true /*(dbDepot.Location + iMaxRange) ge MaxDistance(dbDepot.Location, pcLocation) */ then
        do:
            find first dbRoute where
                       dbRoute.DepotCode eq pcDepot and
                       dbRoute.Distance lt iCustomerDistance.
             return dbRoute.RouteCode.
        end.
        else
            /* ELSE unable to ship to customer from this depot */ . 
            return '-1'.
        **/            
    end method.

    method private character AllocateAvailableVehicle(input pcDepot as character):
        define query qryVehicle for dbVehicleType scrolling.
        
        open query qryVehicle preselect each dbVehicleType.
        query qryVehicle:reposition-to-row(random(1, query qryVehicle:num-results)).
        query qryVehicle:get-next().
        
        return dbVehicleType.Code.
    end method.
    
end class.