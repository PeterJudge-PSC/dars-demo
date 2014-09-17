@openapi.openedge.export FILE(type="BPM", operationName="%FILENAME%", useReturnValue="false", writeDataSetBeforeImage="false", executionMode="singleton").
/*------------------------------------------------------------------------
    File        : service_schedulepickup.p
    Purpose     : 
    Author(s)   : 
    Created     : Tue Sep 16 11:49:41 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using TripleDee.Shopping.DeliveryAndReturnService.

define input  parameter pcOrderCode  as character no-undo.                                      
define input  parameter pcReturnCode as character no-undo.
define output parameter pcDeliveryCode as character no-undo.

/* ***************************  Main Block  *************************** */
define variable oDARS as DeliveryAndReturnService no-undo.

oDARS = new DeliveryAndReturnService().

oDARS:SchedulePickup(input  pcOrderCode,
                     input  pcReturnCode,
                     output pcDeliveryCode).

/** eof **/