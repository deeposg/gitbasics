({
	doInit : function(component, event, helper) {
        //initial load of all related data 
        $A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");
        
        var action = component.get("c.init");
        action.setParams({
            'attendeeId': component.get('v.recordId')
        });
        action.setCallback(this, function(a){
            //component set for 5 objects so passing is more straightforward.
            //Gets returned in a wrapper class
            if(a.getReturnValue() == null){
            	component.set('v.ErrorCode',"This attendee cannot be rescheduled!");
            }
            else{
                component.set("v.Attendee",(a.getReturnValue()[0]["attendee"]));
                component.set("v.ServApp", (a.getReturnValue()[0]["servApp"]));
                component.set("v.Order", (a.getReturnValue()[0]["order"]));
                component.set("v.OrderProduct", (a.getReturnValue()[0]["orderProduct"]));
                
                //if the SA is on-site, we don't want to reschedule attendees
                if(component.get("v.ServApp").IH3POS__c == 'On-Site'){
                    component.set("v.onSite", true);         
                }
                if(component.get('v.ServApp').Business_Days_to_Scheduled_Start__c < -1){
                    component.set("v.pastSADate", true);
                }
                if(component.get('v.OrderProduct').SBQQ__Status__c != 'Draft'){
                    component.set('v.validOPState', false);
                }
                if(component.get('v.ServApp').Business_Days_to_Scheduled_Start__c < 5){
                    component.set('v.saWithin5Days', true);
                }
            }
            
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");          
        });
        $A.enqueueAction(action);
    },
    getServAppointmentsClick : function(component, event, helper) {
        $A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");   
        
        var reset = component.get("c.clearMessages");  
        $A.enqueueAction(reset);        
        
        var action = component.get("c.getServiceAppointments");
        action.setParams({
            'orderProduct' : component.get("v.OrderProduct"),
            'servApp' : component.get("v.ServApp")
        });
        console.log(component.get("v.OrderProduct"));
                console.log(component.get("v.ServApp"));
        action.setCallback(this, function(a){
            var records = a.getReturnValue();
            console.log('RECORDS');
            console.log(records);
            if(records.length > 0) {
                component.set("v.ServiceAppointments", records);
                component.set("v.listShow", true);
            }
            else {
            	component.set('v.ErrorCode',"There are no available service appointments to reschedule to.");
            }
                   
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");        
        });
        $A.enqueueAction(action);
	},
    rescheduleClick : function(component, event, helper){
        $A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");
        
        component.set("v.listShow", false);
        
        var reset = component.get("c.clearMessages");  
        $A.enqueueAction(reset);
        
        var action = component.get("c.rescheduleAttendee");
        action.setParams({
            'order' : component.get("v.Order"),
            'servApp' : component.get("v.ServApp"),
            'orderProduct' : component.get("v.OrderProduct"),
            'attendee' : component.get("v.Attendee"),
            'newServApp' : event.target.id
        });
        
        action.setCallback(this, function(a){
       		//check what the function returns, should be a bool
       		//can determine what message to show user, success or error
       		var msg = a.getReturnValue();
            
            if(msg == 'SUCCESS'){
                component.set('v.SuccessCode', "The attendee has been succesfully rescheduled to a new service appointment!");
            }
            else if(msg == 'CANCELED'){
            	component.set('v.ErrorCode', "The attendee can no longer be modified!");
            }
            else if(msg == 'INVALID_OP'){
            	component.set('v.ErrorCode', "The attendee cannot be rescheduled. Please contact your administrator!");                            
            }
            else if(msg == 'SA_FINISHED'){
                component.set('v.ErrorCode', "Service Appointment is already completed!");      
            }
            else {
            	component.set('v.ErrorCode', msg);         
            }
            
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");
            
            console.log('sldsShow' + $A.util.hasClass(component.find("busyIndicator"), 'slds-show'));
            console.log('sldsHide' + $A.util.hasClass(component.find("busyIndicator"), 'slds-hide'));            
        });
        
      	$A.enqueueAction(action);
    },
    cancelClick : function(component, event, helper) {
		$A.util.removeClass(component.find("busyIndicator"), "slds-hide");
        $A.util.addClass(component.find("busyIndicator"), "slds-show");
        
        var reset = component.get("c.clearMessages");  
        $A.enqueueAction(reset);
        
        component.set('v.disableButton', true);
        var action = component.get("c.cancelAttendee");
        action.setParams({
            'orderProduct' : component.get("v.OrderProduct"),
            'order' : component.get("v.Order"),
            'attendee' : component.get("v.Attendee"),
            'servApp' : component.get("v.ServApp")
        });
        
        action.setCallback(this, function(a) {
            var msg = a.getReturnValue();
            
            if(msg == 'CANCEL'){
                component.set('v.ErrorCode', "The attendee can no longer be modified!");
            }
            else if (msg == 'SUCCESS'){
                component.set('v.SuccessCode', "The attendee has been succesfully canceled!")
            }
            else if(msg == 'SA_FINISHED'){
                component.set('v.ErrorCode', "Service Appointment is already completed!");      
            }
			else if(msg == 'INVALID_OP'){
            	component.set('v.ErrorCode', "The attendee cannot be rescheduled. Please contact your administrator!");                            
            }            
            else{
                component.set('v.ErrorCode', msg);
            }
            
            $A.util.removeClass(component.find("busyIndicator"), "slds-show");
            $A.util.addClass(component.find("busyIndicator"), "slds-hide");            
        });
        $A.enqueueAction(action);
    },
    clearMessages : function(component, event, helper){
        component.set('v.SuccessCode', "");
        component.set('v.ErrorCode', "");
    }
})