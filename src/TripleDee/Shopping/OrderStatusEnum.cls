/*------------------------------------------------------------------------
    File        : OrderStatusEnum
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Tue Aug 05 11:54:37 EDT 2014
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Core.EnumMember.
using TripleDee.Shopping.OrderStatusEnum.

class TripleDee.Shopping.OrderStatusEnum inherits EnumMember:
    {Consultingwerk/EnumMember.i Ordered           1 OrderStatusEnum}
    {Consultingwerk/EnumMember.i Delivered         2 OrderStatusEnum}
    {Consultingwerk/EnumMember.i ReturnRequested   3 OrderStatusEnum}
    {Consultingwerk/EnumMember.i ReturnApproved    4 OrderStatusEnum}
    {Consultingwerk/EnumMember.i ReturnDenied      5 OrderStatusEnum}
    {Consultingwerk/EnumMember.i ReturnReceived    6 OrderStatusEnum}
    {Consultingwerk/EnumMember.i Refunded          7 OrderStatusEnum}
    {Consultingwerk/EnumMember.i OutForDelivery    8 OrderStatusEnum}
    {Consultingwerk/EnumMember.i PickupScheduled   9 OrderStatusEnum}
    
    constructor protected OrderStatusEnum ( input piValue as integer, input pcName as character ):
        super (input piValue, input pcName).
    end constructor.
    
    {Consultingwerk/EnumFromString.i TripleDee.Shopping.OrderStatusEnum}
    
end class.