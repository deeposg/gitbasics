({
	doInit : function(component, event, helper) {
		
	},
    
    recordUpdated : function(component, event, helper){
		$A.get('e.force:refreshView').fire();
    },
    
    getDetails : function(component, event, helper){
        $A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");
        
		var action = component.get("c.getAmazonShippingDetails");
        action.setParams({
			'recordId': component.get('v.recordId'),
            'fulfillmentId' : component.get('v.simpleRecord.Fulfillment_Id__c')
        });
        
        action.setCallback(this, function(retVal){
            $A.get('e.force:refreshView').fire();
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");            
        });
        
        $A.enqueueAction(action);        
    }
})