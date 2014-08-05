/*------------------------------------------------------------------------
    File        : BusinessEntity
    Description : 
    Author(s)   : pjudge
    Notes       : 
  ----------------------------------------------------------------------*/
routine-level on error undo, throw.

using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonConstruct.
using Progress.Json.ObjectModel.ObjectModelParser.
using OpenEdge.BusinessLogic.BusinessEntity.

class OpenEdge.Demo.BusinessEntity abstract inherits BusinessEntity:
    
    method protected JsonObject ParseFilter (input pcFilter as character):
        define variable oParsedConstruct as JsonConstruct no-undo.
        define variable oParser as ObjectModelParser no-undo.
        
        oParser = new ObjectModelParser().
        oParsedConstruct = oParser:Parse(pcFilter).
       
        return cast(oParsedConstruct, JsonObject).
    end method.


	constructor protected BusinessEntity ( input hDS as handle ):
		super (input hDS).
        this-object:Initialize().
	end constructor.

    destructor public BusinessEntity():
        this-object:Destroy().
    end destructor.
    
    method abstract public void Initialize().
    method abstract public void Destroy().
    
end class.
