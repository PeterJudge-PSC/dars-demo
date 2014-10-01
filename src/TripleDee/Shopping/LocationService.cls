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

class TripleDee.Shopping.LocationService:
    {TripleDee/Shopping/location_dataset.i &access-level=private}

    method public void AllocateAvailableVehicle(output table eVehicle):
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
	end constructor.
	
end class.