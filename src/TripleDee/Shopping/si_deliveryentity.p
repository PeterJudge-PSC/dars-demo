@openapi.openedge.export FILE(type="BPM", operationName="%FILENAME%", useReturnValue="false", writeDataSetBeforeImage="false", executionMode="single-run").
/*------------------------------------------------------------------------
    File        : si_DeliveryEntity.p
    Purpose     : Service Interface for the DeliveryEntity
    Author(s)   : 
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using TripleDee.Shopping.DeliveryEntity.

/* ***************************  Main Block  *************************** */
define variable oDeliveryEntity as DeliveryEntity no-undo.

assign oDeliveryEntity = new DeliveryEntity().

/** internal procedures that map to public methods.  **/
@openapi.openedge.export(type="BPM", operationName="%FILENAME%_%PROCNAME%", useReturnValue="false", writeDataSetBeforeImage="false").
procedure NotifyDriver:
    define input parameter pcOrderCode  as character no-undo.
    define input parameter pcReturnCode as character no-undo.
    define input parameter pcDriverCode as character no-undo.
    
    oDeliveryEntity:NotifyDriver(pcOrderCode, pcReturnCode, pcDriverCode).
end procedure.
/* eof */ 