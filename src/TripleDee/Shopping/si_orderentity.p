@openapi.openedge.export FILE(type="BPM", operationName="%FILENAME%", useReturnValue="false", writeDataSetBeforeImage="false", executionMode="single-run").
/*------------------------------------------------------------------------
    File        : si_orderentity.p
    Purpose     : Service Interface for the OrderEntity
    Author(s)   : 
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using TripleDee.Shopping.OrderEntity.

/* ***************************  Main Block  *************************** */
define variable oOrderEntity as OrderEntity no-undo.

assign oOrderEntity = new OrderEntity().

/** internal procedures that map to public methods.  **/
@openapi.openedge.export(type="BPM", operationName="%FILENAME%_%PROCNAME%", useReturnValue="false", writeDataSetBeforeImage="false").
procedure GetOrderCode:
    define input  parameter piCustNum as integer no-undo.
    define input  parameter piOrderNum as integer no-undo.
    define output parameter pcOrderCode as character no-undo.
    
    assign pcOrderCode = oOrderEntity:GetOrderCode(piCustNum, piOrderNum).
end procedure.

@openapi.openedge.export(type="BPM", operationName="%FILENAME%_%PROCNAME%", useReturnValue="false", writeDataSetBeforeImage="false").
procedure RequestReturn:
    define input        parameter pcOrderCode as character no-undo.
    define input-output parameter pcReturnReason as character no-undo.
    define       output parameter pcReturnStatus as character no-undo.
    define       output parameter pcReturnCode as character no-undo.
    
    assign pcReturnStatus = oOrderEntity:RequestReturn(input        pcOrderCode,
                                                       input-output pcReturnReason,
                                                             output pcReturnCode).
end procedure.
       
/* eof */ 