@openapi.openedge.export FILE(type="BPM", operationName="%FILENAME%", useReturnValue="false", writeDataSetBeforeImage="false", executionMode="singleton").
/*------------------------------------------------------------------------
    File        : service_getordercode.p
    Purpose     : 
    Author(s)   : 
    Created     : Wed Sep 17 09:18:54 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using TripleDee.Shopping.DeliveryAndReturnService.

define input  parameter piCustNum as integer no-undo.
define input  parameter piOrderNum as integer no-undo.
define output parameter pcOrderCode as character no-undo.

/* ***************************  Main Block  *************************** */
define variable oDARS as DeliveryAndReturnService no-undo.

assign oDARS = new DeliveryAndReturnService()
       pcOrderCode = oDARS:GetOrderCode(
                            input        piCustNum,
                            input        piOrderNum).

/* eof */ 