({
	doInit : function(component, event, helper) {
        
		//pass data to run data checks on all class based products
        $A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");
                
        var action = component.get("c.SetQuoteToApproved");
        action.setParams({
            'quoteId': component.get('v.recordId')
        });
        
        action.setCallback(this, function(a){
            var msg = a.getReturnValue();
            
            if(msg.includes("TAX")){
                component.set('v.ErrorCode', 'Taxes are missing from this quote! Please recalculate to proceed');
            }
            if(msg.includes("SUCCESS")){
                $A.get("e.force:closeQuickAction").fire();
                
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Success",
                    "message": "The Quote is now approved"
                });
                resultsToast.fire();
                
                $A.get('e.force:refreshView').fire();
            }

            
			$A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");
        });
        
        $A.enqueueAction(action);
	}
})