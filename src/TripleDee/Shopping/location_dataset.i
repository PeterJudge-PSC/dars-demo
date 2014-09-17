/*------------------------------------------------------------------------
    File        : order_dataset.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Wed Aug 06 10:07:15 EDT 2014
    Notes       :
  ----------------------------------------------------------------------*/
  define private temp-table eVehicle no-undo
        field Code     as character
        field Capacity as decimal      /* cubic meters */
        field Range    as decimal      /* KM */
        .        
  
  define private temp-table eRoute no-undo
    field Code        as character
    field DepotCode   as character
    field Range       as decimal
    index idx1 as primary unique DepotCode Code
    .
  