({
	doInit : function(component, event, helper) {
        
		//pass data to run data checks on all class based products
        $A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");
                
        var action = component.get("c.RunQuoteValidations");
        action.setParams({
            'quoteId': component.get('v.recordId')
        });
        
        var error = true;
        
        action.setCallback(this, function(a){
        	var msg = a.getReturnValue();
            console.log('MSG: ' + msg);
            
            if(msg.includes("OS") == true){
                component.set('v.OS', true);
                error = false;
            }
            if(msg.includes("IH") == true){
                component.set('v.IH', true);
                error = false;
            }
            if(msg == 'SUCCESS'){
            	$A.get("e.force:closeQuickAction").fire();
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Success",
                    "message": "The Quote is now booked"
                });
                resultsToast.fire();
                //if no errors and is now approved, refresh the page
        		$A.get('e.force:refreshView').fire();
                error = false;
            }
            //if msg doesn't contain IH or OS or success
            else if(error == true){
                component.set('v.ErrorCode', msg);
            }

			$A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");
        });
        
        $A.enqueueAction(action);
	}
})