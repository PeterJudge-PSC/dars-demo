@openapi.openedge.export FILE(type="BPM", operationName="%FILENAME%", useReturnValue="false", writeDataSetBeforeImage="false", executionMode="singleton").
/*------------------------------------------------------------------------
    File        : service_requestreturn.p
    Purpose     : 
    Author(s)   : 
    Created     : Tue Sep 16 10:44:26 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using TripleDee.Shopping.DeliveryAndReturnService.

define input        parameter pcOrderCode as character no-undo.
define input-output parameter pcReturnReason as character no-undo.
define       output parameter pcReturnStatus as character no-undo.
define       output parameter pcReturnCode as character no-undo.

/* ***************************  Main Block  *************************** */
define variable oDARS as DeliveryAndReturnService no-undo.

assign oDARS = new DeliveryAndReturnService()
       pcReturnCode = oDARS:RequestReturn(
                            input        pcOrderCode,
                            input-output pcReturnReason,
                                  output pcReturnStatus).
                                  
                                          
/* eof */
