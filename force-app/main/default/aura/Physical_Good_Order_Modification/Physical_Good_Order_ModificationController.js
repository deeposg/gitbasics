({
	doInit: function(component) {
        $A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");
        
		var getShippingItemStatus = component.get("c.getShippingItemStatus");
        getShippingItemStatus.setParams({
            'shippingItemId': component.get('v.recordId')
        });
        
        getShippingItemStatus.setCallback(this, function(rtnVal){
			var msg = rtnVal.getReturnValue();
            
            if(msg == 'VALID'){
				component.set("v.showOptions", true);
                component.set("v.originalQuantity", component.get("v.simpleRecord.Quantity__c"));
            }
            else if(msg == 'INVALID'){
                component.set("v.ErrorCode", "This shipping item cannot be modified!");
            }
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");            
        });
        $A.enqueueAction(getShippingItemStatus);
	},
    updateQuantityClick: function(component){        
        component.set('v.SuccessCode', '');
        component.set('v.ErrorCode', '');
        
        var origQty = component.get('v.originalQuantity');
        var newQty = component.get('v.newQuantity');
        
        if(newQty <= 0 || newQty > origQty){
			component.set('v.ErrorCode', 'Quantity needs to be greater than 0 and less than original quantity');	            
        }
        if(newQty == origQty){
            component.set('v.ErrorCode', 'The quantity has not changed!');
        }
        if(newQty > 0 && newQty < origQty){
            $A.util.removeClass(component.find("busyIndicator"), "slds-hide");
            $A.util.addClass(component.find("busyIndicator"), "slds-show");
            
            var reduceQuantity = component.get('c.reduceShippingQuantity');
            reduceQuantity.setParams({
                'shippingItemId': component.get('v.recordId'),
                'newQuantity': newQty
            });
            reduceQuantity.setCallback(this, function(retVal){
            	var state = retVal.getReturnValue();
                if(state == true){
                    component.set('v.SuccessCode', 'The shipping item quantity was successfully reduced!');
                }
                else if(state == false){
                    component.set('v.ErrorCode', 'There was an error reducing the quantity! Contact your administrator.');
                }
                component.set('v.modifyQuantity', false);
				component.set('v.showOptions', true);
				$A.util.removeClass(component.find("busyIndicator"), "slds-show");
            	$A.util.addClass(component.find("busyIndicator"), "slds-hide"); 
            });
            $A.enqueueAction(reduceQuantity);
        }
    },
    cancelShippingItemClick: function(component){
        component.set('v.SuccessCode', '');
        component.set('v.ErrorCode', '');
        
    	$A.util.removeClass(component.find("busyIndicator"), "slds-hide");
		$A.util.addClass(component.find("busyIndicator"), "slds-show");

		var cancel = component.get('c.cancelShippingItem');
        cancel.setParams({
            'shippingItemId': component.get('v.recordId')
        });
        cancel.setCallback(this, function(retVal){
            var state = retVal.getReturnValue();
            if(state == true){
                component.set('v.SuccessCode', 'The shipping item was successfully canceled!');
            }
            else if(state == false){
                component.set('v.ErrorCode', 'There was an error canceling the shipping item! Contact your administrator.');
            }
            
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");             
        });
        $A.enqueueAction(cancel);
    },
    modifyQuantityClick: function(component){
        component.set('v.modifyQuantity', true);
        component.set('v.showOptions', false);
    },
    cancelModifyClick: function(component){
        component.set('v.SuccessCode', '');
        component.set('v.ErrorCode', '');        
        
        component.set('v.modifyQuantity', false);
		component.set('v.showOptions', true);
    }
})