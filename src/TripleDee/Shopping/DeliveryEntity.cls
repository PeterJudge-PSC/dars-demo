 /*------------------------------------------------------------------------
    File        : DeliveryEntity
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Wed Aug 06 09:56:39 EDT 2014
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using OpenEdge.Mobile.PushNotificationFilterOperandEnum.
using OpenEdge.Mobile.PushNotificationMessageBuilder.
using OpenEdge.Mobile.PushNotificationService.
using OpenEdge.Net.URI.
using Progress.BPM.Process.
using Progress.BPM.UserSession.
using Progress.Json.ObjectModel.JsonObject.
using TripleDee.Shopping.BusinessEntity.
using TripleDee.Shopping.OrderStatusEnum.
using Progress.Json.ObjectModel.ObjectModelParser.

class TripleDee.Shopping.DeliveryEntity inherits BusinessEntity:
    {TripleDee/Shopping/delivery_dataset.i &access-level=private}
    
    define data-source srcDelivery for Delivery.
    define data-source srcDelItem  for DeliveryItem.
    
    define private variable moNotificationService as PushNotificationService no-undo.
    define private variable moBpmService as UserSession no-undo.
    
    define private property BpmEnabled as logical no-undo
        get:
            return (valid-object(moBpmService) and moBpmService:Connected).
        end get.

    define private property NotificationsEnabled as logical no-undo
        get:
            return valid-object(moNotificationService).
        end get.
    
	/* Run by super class' constructor. */
	method override public void Initialize():
        define variable oConfig as JsonObject no-undo.
        
	    super:Initialize().
	    
        assign extent(this-object:ProDataSource) = 2
               
               this-object:ProDataSource[1] = data-source srcDelivery:handle
               this-object:ProDataSource[2] = data-source srcDelItem:handle
               
               oConfig = cast(new ObjectModelParser():ParseFile('conf/config.json'), JsonObject).
               
        InitializeNotificationService(
                oConfig:GetJsonObject('notificationService')).
                                        
        InitializeBpmService(
                oConfig:GetJsonObject('bpmService')).
	end method.
	
    method protected void InitializeNotificationService(input poConfig as JsonObject):
        if poConfig:GetLogical('enabled') then
            assign moNotificationService = PushNotificationService:Instance(
                                            URI:Parse(poConfig:GetCharacter('URL')),
                                            poConfig:GetCharacter('apiKey')).
    end method.
	
    method protected void InitializeBpmService(input poConfig as JsonObject):
        if poConfig:GetLogical('enabled') then
        do:
            assign moBpmService = new UserSession(poConfig:GetCharacter('serverURL')).
            moBpmService:Connect(poConfig:GetCharacter('user'), 
                                 poConfig:GetCharacter('password')).
        end.
    end method.
	
    method override public void Destroy():
        super:Destroy().
        
        assign moNotificationService = ?.
        
        /* log out */
        if valid-object (moBpmService) then
            moBpmService:Disconnect(true).
        
        assign moBpmService = ?.
    end method.
		
	constructor public DeliveryEntity():
		super(dataset dsDriverDelivery:handle).
	end constructor.
	
    /* READ */
    method public void ListDriverDeliveries(input filter as character, 
                                            output dataset dsDriverDelivery):
        ListDriverDeliveries(
                    input ParseFilter(filter),
                    output dataset dsDriverDelivery).
    end method.

    method public void ListDriverDeliveries(input poFilter as JsonObject,
                                            output dataset dsDriverDelivery):
        define variable cWhere as character extent no-undo.
        
        assign cWhere = BuildWhereClause(poFilter).        
        
        ReadData(cWhere).
    end method.
    
    method public void GetDeliveryByCode (input pcCode as character,
                                          output dataset dsDriverDelivery):
        ReadData(substitute('where Delivery.Code eq &1', quoter(pcCode))).                                              
    end method.
    
    /* SUBMIT */
    method public void UpdateDriverDeliveries(input-output dataset dsDriverDelivery):
        define variable oProcess as Process no-undo.
        
        /* Complete the BPM workstep */
        if BpmEnabled then
        for each eDeliveryItem where
                 eDeliveryItem.DeliveryStatus eq OrderStatusEnum:ReturnReceived:Name:
            oProcess = moBpmService:GetProcess('ReturnProcess', eDeliveryItem.OrderCode).
            oProcess:CompleteWorkstep('ReturnPickup').
        end.
        
        Submit(input-output dataset dsDriverDelivery by-reference).
    end method.
    
    /* INVOKE */
    method public void NotifyDriver (input pcOrderCode as character,
                                     input pcReturnCode as character,
                                     input pcDriverCode as character):
        define variable iNumReturns as integer no-undo.
        define variable cMessage as character no-undo.
        define variable oBuilder as PushNotificationMessageBuilder no-undo.
        define variable cDriverCode as character no-undo.
        define variable oFilter as JsonObject no-undo.
        define variable oProcess as Process no-undo.
        
        define query qryReturns for eDeliveryItem.
        
        if NotificationsEnabled then
        do:
            oFilter = new JsonObject().
            oFilter:Add('driverCode', pcDriverCode).
            oFilter:Add('itemStatus', OrderStatusEnum:PickupScheduled:Name).
            
            ListDriverDeliveries(input oFilter, output dataset dsDriverDelivery).
            
            open query qryReturns preselect each eDeliveryItem.
            assign iNumReturns = query qryReturns:num-results.
            
            /* send the notification */
            assign cMessage    = 'New pickup scheduled : ' + pcReturnCode
                   /* send the notification immediately */
                   oBuilder = PushNotificationMessageBuilder
                        :Send(cMessage, iNumReturns)
                        :AddStringFilter('driverCode', pcDriverCode,
                                         PushNotificationFilterOperandEnum:Equals)
                   .
            moNotificationService:SendNotification(oBuilder:Payload).
        end.
                
        /* activate task */
        if BpmEnabled then
        do:
            oProcess = moBpmService:GetProcess('ReturnProcess', pcOrderCode).
            oProcess:ActivateWorkstep('ReturnPickup').
        end.
    end method.
    
end class.