/*------------------------------------------------------------------------
    File        : BusinessEntity
    Description : 
    Author(s)   : pjudge
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Progress.Json.ObjectModel.JsonObject.
using Progress.Json.ObjectModel.JsonConstruct.
using Progress.Json.ObjectModel.ObjectModelParser.
using OpenEdge.BusinessLogic.BusinessEntity.

class OpenEdge.Demo.BusinessEntity abstract inherits BusinessEntity:
    /* 'database' schema and holder */
    {OpenEdge/Demo/delivery_database.i}
    
    method protected JsonObject ParseFilter (input pcFilter as character):
        define variable oParsedConstruct as JsonConstruct no-undo.
        define variable oParser as ObjectModelParser no-undo.
        
        if pcFilter eq '' or pcFilter eq ? then
            return new JsonObject().
        
        oParser = new ObjectModelParser().
        oParsedConstruct = oParser:Parse(pcFilter).
       
        return cast(oParsedConstruct, JsonObject).
    end method.
    
    constructor static BusinessEntity():
        /* LOAD Data */
        dataset dsDatabase:read-json('file', 'db/data.json').
    end constructor. 

	constructor protected BusinessEntity ( input hDS as handle ):
		super (input hDS).
		
		this-object:Initialize().
	end constructor.

    destructor public BusinessEntity():
        this-object:Destroy().
        
        os-copy 'db/data.json' 'db/data.prev.json'.
        dataset dsDatabase:write-json('file', 'db/data.json', true).
    end destructor.
    
    method public void Initialize():
    end method.
    
    method public void Destroy():
    end method.

end class.
