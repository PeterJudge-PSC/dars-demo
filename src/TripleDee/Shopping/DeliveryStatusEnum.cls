/*------------------------------------------------------------------------
    File        : DeliveryStatusEnum
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Tue Aug 05 11:54:37 EDT 2014
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.EnumMember.
using TripleDee.Shopping.DeliveryStatusEnum.

class TripleDee.Shopping.DeliveryStatusEnum inherits EnumMember:
    {Consultingwerk/EnumMember.i Open   1 DeliveryStatusEnum}
    {Consultingwerk/EnumMember.i Closed 2 DeliveryStatusEnum}
    
    constructor protected DeliveryStatusEnum ( input piValue as integer, input pcName as character ):
        super (input piValue, input pcName).
    end constructor.
    
    {Consultingwerk/EnumFromString.i TripleDee.Shopping.DeliveryStatusEnum}
    
end class.