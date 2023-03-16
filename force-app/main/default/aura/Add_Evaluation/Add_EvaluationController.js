({
	doInit : function(component, event, helper) {
        var isSAEval = component.get("c.isSAEvalProduct");
        isSAEval.setParams({
            "attendeeId" : component.get('v.recordId')
        });
        isSAEval.setCallback(this, function(saEval){
            var state = saEval.getReturnValue();
            //SA is a Evaluation
            if(state === true){
                component.set('v.isEval', true);
                var action = component.get("c.getEvaluationRecordTypeValues");
                action.setCallback(this, function(response) {
                    component.set("v.lstOfRecordType", response.getReturnValue());
                });
                $A.enqueueAction(action);
                
                var getContact = component.get("c.getContactId");
                getContact.setParams({
                    "attendeeId" : component.get('v.recordId')
                });
                getContact.setCallback(this, function(contactRtn){
                    component.set("v.contactId", contactRtn.getReturnValue());   
                    //set the default to prevent initial error
                    component.find("selectid").set("v.value", component.get("v.lstOfRecordType")[0]);
                });
                $A.enqueueAction(getContact);
            }
            else{
                component.set('v.isEval', false);
            }
        });
        $A.enqueueAction(isSAEval);

	},
    createRecord: function(component, event, helper){
        var action = component.get("c.getEvaluationRecordTypeId");
        
        var recordTypeLabel = component.find("selectid").get("v.value");
        
        action.setParams({
            "recordTypeLabel" : recordTypeLabel 
        });
        
        action.setCallback(this, function(response) {
        	var state = response.getState();
         	if (state === "SUCCESS") {
                 
            var createRecordEvent = $A.get("e.force:createRecord");
            var RecTypeID  = response.getReturnValue();
            createRecordEvent.setParams({
                "entityApiName": 'Evaluation__c',
                "recordTypeId": RecTypeID,
                'defaultFieldValues' : {
                    "Attendee__c" : component.get('v.recordId'),
                    "Attendee_Contact__c" : component.get('v.contactId')
                 }
            });
            createRecordEvent.fire();
             
         } else if (state == "INCOMPLETE") {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
               "title": "Oops!",
               "message": "Something went wrong! Contact your administrator"
            });
            toastEvent.fire();
             
         } else if (state == "ERROR") {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
               "title": "Error!",
               "message": "Something went wrong! Please contact your administrator"
            });
            toastEvent.fire();
         }
      });
      $A.enqueueAction(action);
    }
})