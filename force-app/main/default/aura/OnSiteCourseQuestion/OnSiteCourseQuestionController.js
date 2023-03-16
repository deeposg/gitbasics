({
    doInit: function(component, evt, helper) {
        var action = component.get("c.getCourses");
        action.setParams({
            quoteId : component.get("v.recordId") 
        });
        action.setCallback(this, function(a) {
            component.set("v.HasRecord",component.get("v.HasRecord")+a.getReturnValue().length);
            component.set("v.SBQQ__QuoteLine__c", a.getReturnValue());
            console.log(a.getReturnValue());
            //if(component.get("v.HasRecord").length >0){
                 
           // }
        });
        $A.enqueueAction(action);
        var action1 = component.get("c.getEvaluations");
        action1.setParams({
            quoteId : component.get("v.recordId") 
        });
        action1.setCallback(this, function(a) {
            component.set("v.HasRecord",component.get("v.HasRecord")+a.getReturnValue().length);
            component.set("v.evaluations", a.getReturnValue());
            setTimeout(function(){
                $A.util.removeClass(component.find("busyIndicator"), "slds-show");
                $A.util.addClass(component.find("busyIndicator"), "slds-hide");
            }, 5000);
            
        });
        $A.enqueueAction(action1);
        
    },
    TabSwitch : function(component, event, helper) {
        
	},
    
    closePress : function(component,event,helper){
        //alert('called');
        $A.get("e.force:closeQuickAction").fire();
    },
    
    saveQuoteLines : function(component,event,helper){
        
        var lstQuoteLine = component.get("v.SBQQ__QuoteLine__c");
        var evaluationsList = component.get("v.evaluations");
        
        console.log(lstQuoteLine);
        console.log(evaluationsList);
        if(evaluationsList.length > 0){
            for(var i = 0; i < evaluationsList.length; i++){
                lstQuoteLine.push(evaluationsList[i]);
            }
        }
        
        var action = component.get("c.saveQuoteLine");
        action.setParams({
            "quoteLineToSave" :  lstQuoteLine
        });
        action.setCallback(this, function(a) {
                //component.set("v.SBQQ__QuoteLine__c", a.getReturnValue());
                //console.log(a);
               $A.get("e.force:closeQuickAction").fire();
               var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The record has been updated successfully."
                });
                toastEvent.fire();
        });
        $A.enqueueAction(action);
    },
})