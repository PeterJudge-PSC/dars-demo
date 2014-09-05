/*------------------------------------------------------------------------
    File        : LocationService
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Tue Aug 05 15:59:53 EDT 2014
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Demo.BusinessEntity.

class OpenEdge.Demo.LocationService inherits BusinessEntity:
/*    {OpenEdge/Demo/delivery_database.i}*/
    {OpenEdge/Demo/location_dataset.i}

    method public void FindRouteForDelivery(input pcDeliveryCode as character,
                                            output table eRoute):
        /* clearly not real. use fiund a random route */
        FindRouteForLocation(pcDeliveryCode, output table eRoute by-reference).
    end method.
    
    method public void FindRouteForLocation(input pcLocation as character,
                                            output table eRoute):
        define query qryRoute for Route scrolling.
        
        open query qryRoute preselect each Route.
        query qryRoute:reposition-to-row(random(1, query qryRoute:num-results)).
        query qryRoute:get-next().
        
        empty temp-table eRoute.
        create eRoute.
        buffer-copy Route to eRoute.
        
        finally:
            close query qryRoute.
        end finally.
    end method.
    
    method public void AllocateAvailableVehicle(input pcDepot as character,
                                                output table eVehicle):
        define query qryVehicle for VehicleType scrolling.
        
        open query qryVehicle preselect each VehicleType.
        query qryVehicle:reposition-to-row(random(1, query qryVehicle:num-results)).
        query qryVehicle:get-next().
        
        empty temp-table eVehicle.
        create eVehicle.
        buffer-copy VehicleType to eVehicle.

        finally:
            close query qryVehicle.
        end finally.
    end method.
    
		
	constructor public LocationService ():
		super (input ?).
	end constructor.


end class.