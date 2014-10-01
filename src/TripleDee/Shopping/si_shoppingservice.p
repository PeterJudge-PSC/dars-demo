@openapi.openedge.export FILE(type="BPM", operationName="%FILENAME%", useReturnValue="false", writeDataSetBeforeImage="false", executionMode="single-run").
/*------------------------------------------------------------------------
    File        : si_shoppingservice.p
    Description : Service interface for the ShoppingService 
    Author(s)   : 
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using TripleDee.Shopping.ShoppingService.

/* ***************************  Main Block  *************************** */
define variable oShoppingSvc as ShoppingService no-undo.

assign oShoppingSvc = new ShoppingService().

@openapi.openedge.export(type="BPM", operationName="%FILENAME%_%PROCNAME%", useReturnValue="false", writeDataSetBeforeImage="false").
procedure SchedulePickup:
    define input  parameter pcOrderCode  as character no-undo.                                      
    define output parameter pcDriverCode as character no-undo.
    
    oShoppingSvc:SchedulePickup(input pcOrderCode, output pcDriverCode).
end procedure.    

procedure OpenDelivery:
    define input  parameter pcDriver as character no-undo.
    define output parameter pcDeliveryCode as character no-undo.
    
    pcDeliveryCode = oShoppingSvc:OpenDelivery(pcDriver).
end procedure.

procedure CloseDelivery:
    define input parameter pcDeliveryCode as character no-undo.
    
    oShoppingSvc:CloseDelivery(pcDeliveryCode).
end procedure.

/** eof **/