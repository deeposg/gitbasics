({
    contactsInit : function(component){
      	$A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");
        
        //Check the 'primary' contact and validate it can be used for merging
        var action = component.get("c.validateContact");
        action.setParams({
            'contactId' : component.get('v.recordId') 
        });
        action.setCallback(this, function(retVal){
            var msg = retVal.getReturnValue();
			component.set('v.CanMerge', msg);
            if(msg == true){
        		//get all potential contacts from the account that can be merged with the currently seleted contact
                var getContacts = component.get("c.getContacts");
                getContacts.setParams({
        		    'contactId' : component.get('v.recordId') 
                });
                getContacts.setCallback(this, function(retContacts){
                    var records = retContacts.getReturnValue();
					//set the contacts retreived into the list of contacts to display
                    if(records.length > 0) {
                        component.set("v.Contacts", records);
                    }
                    else {
                        component.set('v.ErrorCode',"There are no available contacts to merge to.");
                    }
                });
                $A.enqueueAction(getContacts);
            }
            else{
				component.set('v.ErrorCode', "Contact cannot be used for merge! Needs to belong to an account.");
            }
            
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");            
        });
		$A.enqueueAction(action);
    },
    mergeContactsClick : function(component, event, helper){
		$A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");

        //set the merge function with the primary and secondary contact
        var action = component.get("c.mergeContacts");
        action.setParams({
            'contactId1' : component.get('v.recordId'),
            'contactId2' : component.get('v.secondaryContact')
        });
        action.setCallback(this, function(a){
            var msg = a.getReturnValue();
            
            if(msg == 'SUCCESS'){
                component.set('v.SuccessCode', "The contacts was merged successfully!");

                //var navEvt = $A.get("e.force:navigateToSObject");
                //navEvt.setParams({
                //	"recordId": component.get('v.primaryContact')		
                //});
                //navEvt.fire();
                $A.get('e.force:refreshView').fire();
            }
            else if(msg == 'INVALID_OSGONLINE_MERGE'){
                component.set('v.ErrorCode', "Contacts cannot be merged! You cannot merge two OsgOnline synced contacts together.");
            }            
            else if(msg == 'INVALID_MERGE'){
                component.set('v.ErrorCode', "Contacts cannot be merged! Ensure the primary contact has a first name, last name and accountId. Ensure that both contacts belong to the same account. Ensure you are not trying to merge the same contact.");
            }
            else if(msg == 'INVALID_DOB_MERGE'){
			    component.set('v.ErrorCode', "Contacts cannot be merged! You cannot merge two contacts that have different date of births. Contact your administrator.");                    
            }
            else if(msg == 'INVALID_USERNAME_MERGE'){
			    component.set('v.ErrorCode', "Contacts cannot be merged! You cannot merge two contacts that have usernames. Contact your administrator.");                    
            }            
            else if(msg == 'INVALID_ID'){
                component.set('v.ErrorCode', "You cannot merge contacts without a valid ID for both.");                    
            }
            else {
            	component.set('v.ErrorCode', msg);
            }
            
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");
        });
        $A.enqueueAction(action);
	},
    setSecondaryContactClick : function(component, event, helper){
        component.set('v.secondaryContact', event.target.id);
    },
    cancelMergeClick : function(component, event, helper){
        component.set('v.secondaryContact', null);
		component.set('v.ErrorCode', '');        
    }
})