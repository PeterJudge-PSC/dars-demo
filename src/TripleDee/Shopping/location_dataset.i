/*------------------------------------------------------------------------
    File        : location_dataset.i
    Description : 
    Notes       :
  ----------------------------------------------------------------------*/
define {&access-level}  temp-table eVehicle no-undo
    field Code     as character
    field Capacity as decimal      /* cubic meters */
    field Range    as decimal      /* KM */
    .

/* eof */