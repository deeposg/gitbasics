({
	doInit : function(component, event, helper) {
		console.log('init called----------------');
        console.log('mbc Dist', component.get("v.mbcDistanceLearning"));
        var action = component.get("c.getClassroomValues");
        console.log('Co Pro Id Val',component.get("v.ProductId"));
        console.log('Co Pro Line Val',component.get("v.CProductLine"));
        console.log('MBC DL: ', component.get("v.mbcDistanceLearning"));
        action.setParams({
            'courseprodLine' : component.get("v.CProductLine"),
            "ProdFamily1" : "Courses",
            "ProdFamily2" : "Evaluations",
            "DelMethod" :  "Classroom",
            "DistanceLearning" : component.get("v.mbcDistanceLearning")
        });
        action.setCallback(this, function(actionResult) {
            var Records=actionResult.getReturnValue();
            console.log('ModalBox',Records);
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");
            if(Records.length>0){
                component.set("v.ServiceAppointments", Records);
            }
            else{
                component.set("v.NoRecord",true);
            }
           }); 
        $A.enqueueAction(action);
	},
    closeModal : function(component, event, helper){
        
        var cmpEvent = component.getEvent("CloseModal");
        cmpEvent.setParams({
            "ModalCheck"     : false        
        });
        cmpEvent.fire();
    },
    saveAptNumber : function(component, event, helper){
        $A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");
        var action = component.get("c.SaveRecord");
        action.setParams({
            'QuoteId' : component.get("v.QuoteId"),
            'ServiceAppId' : event.target.id
        });
        action.setCallback(this, function(actionResult) {
            console.log('result:', actionResult);
            console.log('result retval:', actionResult.getReturnValue());
            console.log('result error:', actionResult.getError());
            var cmpEvent = component.getEvent("UpdateRecord");
            console.log('sdd');
            cmpEvent.setParams({
                "ModalCheck" : false,
                "CouseName"	: actionResult.getReturnValue(),
                "SbqqQuoteLineId" : component.get("v.QuoteId")
            });
            cmpEvent.fire();
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");
        }); 
        $A.enqueueAction(action);
        
    },
    
    SearchFilter : function(component, event){
        $A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");
        
        var action = component.get("c.getUpdatesValues");
        action.setParams({
            'courseprodLine' : component.get("v.CProductLine"),
            'KeyStroke' : component.find("KeyComp").get("v.value"),
            "ProFamily1" : "Courses",
            "ProFamily2" : "Evaluations",
            "DeMethod" :  "Classroom",
            "DistanceLearning" : component.get("v.mbcDistanceLearning")
        });
        action.setCallback(this, function(actionResult) {
            component.set("v.ServiceAppointments", actionResult.getReturnValue());
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");
           }); 
        $A.enqueueAction(action);
    }
})