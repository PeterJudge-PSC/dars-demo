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
using Progress.Json.ObjectModel.JsonDataType.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Lang.AppError.
using OpenEdge.Core.Collections.Iterator.

class TripleDee.Shopping.BusinessEntity abstract inherits OpenEdge.BusinessLogic.BusinessEntity:

    method protected JsonObject ParseFilter (input pcFilter as character):
        define variable oParsedConstruct as JsonConstruct no-undo.
        define variable oParser as ObjectModelParser no-undo.
        
        if pcFilter eq '' or pcFilter eq ? then
            return new JsonObject().
        
        oParser = new ObjectModelParser().
        oParsedConstruct = oParser:Parse(pcFilter).
       
        return cast(oParsedConstruct, JsonObject).
    end method.
    
    method protected character extent BuildWhereClause(input poFilter as JsonObject):
        define variable iLoop as integer no-undo.
        define variable iTableNum as integer no-undo.
        define variable iMax as integer no-undo.
        define variable cProperties as character extent no-undo.
        define variable cName as character no-undo.
        define variable cFieldWhere as character extent 3 no-undo.
        define variable cWhere as character extent no-undo.
        define variable cDelim as character extent no-undo.
        
        assign cProperties = poFilter:GetNames()
               iMax = extent(cProperties)
               extent(cWhere) = extent(this-object:ProDataSource)
               extent(cDelim) = extent(cWhere)
               .
        
        do iLoop = 1 to iMax:
            assign cName = cProperties[iLoop]
                   cFieldWhere = GetDataSourceFieldWhere(cName)
                   iTableNum  = integer(cFieldWhere[1])
                   no-error.
            if iTableNum eq 0 then
                next.
            
            assign cWhere[iTableNum] = cWhere[iTableNum] + cDelim[iTableNum]
                                      + BuildClause(poFilter,
                                                    cName,
                                                    cFieldWhere[2],
                                                    'eq',
                                                    cFieldWhere[3])
                   cDelim[iTableNum] = ' and '.
        end.
        
        return cWhere.
    end method.
    
    /* separated method for recursion */
    method private character BuildClause(input poFilter as JsonArray,
                                         input piIndex as integer,
                                         input pcTableDotField as character,
                                         input pcOperator as character,
                                         input pcAblDataType as character):
        define variable cClause as character no-undo.
        define variable oArray as JsonArray no-undo.
        define variable iMax as integer no-undo.
        define variable iLoop as integer no-undo.
        define variable cDelim as character no-undo.
        define variable cProperties as character extent no-undo.
        define variable cPropertyName as character no-undo.
        
        case poFilter:GetType(piIndex):
            when JsonDataType:STRING or
            when JsonDataType:NUMBER or
            when JsonDataType:BOOLEAN then
            case pcAblDataType:
                when 'date' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetDate(piIndex)).
                when 'datetime' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetDatetime(piIndex)).
                when 'datetime-tz' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetDatetimeTZ(piIndex)).
                when 'character' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                quoter(poFilter:GetCharacter(piIndex))).
                when 'clob' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                quoter(poFilter:GetLongchar(piIndex))).
                when 'decimal' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetDecimal(piIndex)).
                when 'integer' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetInteger(piIndex)).
                when 'int64' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetInt64(piIndex)).
                when 'logical' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetLogical(piIndex)).
            end case. /* STRING/NUMBER/BOOLEAN */
            when JsonDataType:NULL then
                assign cClause = substitute('&1 &2 ?',
                                            pcTableDotField,
                                            pcOperator).
            when JsonDataType:ARRAY then
            do:
                assign oArray = poFilter:GetJsonArray(piIndex)
                       iMax = oArray:Length
                       cClause = ' ( '
                       cDelim = ''.
                       
                do iLoop = 1 to iMax:
                    assign cClause = cClause + cDelim
                                   + BuildClause(oArray,
                                                 iLoop,
                                                 pcTableDotField,
                                                 pcOperator,
                                                 pcAblDataType).
                       cDelim = ' or '.
                end.
                assign cClause = cClause + ' )'.                
            end.    /* ARRAY*/
            otherwise
                undo, throw new AppError(substitute('Unsupported JsonDataType &1 for where clause filtering',
                                            poFilter:GetType(piIndex)), 0).
        end case.
        
        return cClause.                                             
    end method.
    
    method private character BuildClause(input poFilter as JsonObject,
                                         input pcPropertyName as character,
                                         input pcTableDotField as character,
                                         input pcOperator as character,
                                         input pcAblDataType as character):
        define variable cClause as character no-undo.
        define variable oArray as JsonArray no-undo.
        define variable iMax as integer no-undo.
        define variable iLoop as integer no-undo.
        define variable cDelim as character no-undo.
        
        case poFilter:GetType(pcPropertyName):
            when JsonDataType:STRING or
            when JsonDataType:NUMBER or
            when JsonDataType:BOOLEAN then
            case pcAblDataType:
                when 'date' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetDate(pcPropertyName)).
                when 'datetime' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetDatetime(pcPropertyName)).
                when 'datetime-tz' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetDatetimeTZ(pcPropertyName)).
                when 'character' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                quoter(poFilter:GetCharacter(pcPropertyName))).
                when 'clob' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                quoter(poFilter:GetLongchar(pcPropertyName))).
                when 'decimal' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetDecimal(pcPropertyName)).
                when 'integer' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetInteger(pcPropertyName)).
                when 'int64' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetInt64(pcPropertyName)).
                when 'logical' then
                    assign cClause = substitute('&1 &2 &3',
                                                pcTableDotField,
                                                pcOperator,
                                                poFilter:GetLogical(pcPropertyName)).
            end case. /* NUMBER/ABL-DATA-TYPE */
            when JsonDataType:NULL then
                assign cClause = substitute('&1 &2 ?',
                                            pcTableDotField,
                                            pcOperator).
            when JsonDataType:ARRAY then
            do:
                assign oArray = poFilter:GetJsonArray(pcPropertyName)
                       iMax = oArray:Length
                       cClause = ' ( '
                       cDelim = ''
                       .
                do iLoop = 1 to iMax:
                    assign cClause = cClause + cDelim
                                   + BuildClause(oArray,
                                                    iLoop,
                                                    pcTableDotField,
                                                    pcOperator,
                                                    pcAblDataType).
                       cDelim = ' or '.
                end.
                assign cClause = cClause + ' )'.                
            end. /* ARRAY */
            otherwise
                undo, throw new AppError(substitute('Unsupported JsonDataType &1 for where clause filtering',
                                            poFilter:GetType(pcPropertyName)), 0).
        end case.
        
        return cClause.
    end method.
    
    method private character extent 3 GetDataSourceFieldWhere(input pcFieldName as character):
        define variable hField as handle no-undo.
        define variable iLoop as integer no-undo.
        define variable iMax as integer no-undo.
        define variable iBufferLoop as integer no-undo.
        define variable iNumBuffers as integer no-undo.
        define variable cWhere as character extent 3 no-undo.
        
        assign iMax = extent(this-object:ProDataSource)
               cWhere[1] = string(0).
               
        do iLoop = 1 to iMax while not valid-handle(hField):
            assign iNumBuffers = ProDataSource[iLoop]:num-source-buffers.
            do iBufferLoop = 1 to iNumBuffers while not valid-handle(hField):
                assign hField = ProDataSource[iLoop]
                                    :get-source-buffer(iBufferLoop)
                                        :buffer-field(pcFieldName) no-error.
                if valid-handle(hField) then
                    assign cWhere[1] = string(iLoop) 
                           cWhere[2] = substitute('&1.&2',
                                                hField:table,
                                                hField:name)
                           cWhere[3] = hField:data-type.                                               
            end.
        end.
        
        return cWhere.
    end method.
    
	constructor protected BusinessEntity ( input hDS as handle ):
		super (input hDS).
		
		this-object:Initialize().
	end constructor.

    destructor public BusinessEntity():
        this-object:Destroy().
    end destructor.
    
    method public void Initialize():
    end method.
    
    method public void Destroy():
    end method.

end class.
