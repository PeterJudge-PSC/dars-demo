@openapi.openedge.export FILE(type="BPM", operationName="%FILENAME%", useReturnValue="false", writeDataSetBeforeImage="false", executionMode="singleton").
/*------------------------------------------------------------------------
    File        : service_notifydriver.p
    Description : 
    Created     : Tue Sep 16 10:44:50 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using TripleDee.Shopping.DeliveryAndReturnService.

define input  parameter pcDepotCode as character no-undo.
define input  parameter pcDriverCode as character no-undo.
define input  parameter pcReturnCode as character no-undo.

/* ***************************  Main Block  *************************** */
define variable oDARS as DeliveryAndReturnService no-undo.

oDARS = new DeliveryAndReturnService().

oDARS:NotifyDriver(input pcDepotCode,
                   input pcDriverCode,
                   input pcReturnCode).

/** eof **/