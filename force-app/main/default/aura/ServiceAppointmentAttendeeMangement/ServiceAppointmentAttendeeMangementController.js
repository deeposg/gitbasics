({
	doInit: function(component, event, helper) {
        var action = component.get("c.getAttLst");
        action.setParams({
            'RecordId' :component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var Attlist=a.getReturnValue();
            console.log('ATTTT######',Attlist);
            if(Attlist.length>0){
                var attlistes=[];
                var count=0;
                 var SAid='';
                var prevChild=0;
                for( var i=0;i<Attlist.length;i++){
                    if(SAid == ''){
                        SAid=Attlist[i].Service_Appointment__c;
                    }
                    if(SAid == Attlist[i].Service_Appointment__c){
                        count++;
                    }
                    else{
                        SAid=Attlist[i].Service_Appointment__c;
                        //attlistes[prevChild].LastCount=count;
                        prevChild=prevChild+count;
                        count=0;
                        count++;
                    }
                    
                    
                    
                    if(count!=1){
                        Attlist[i].Service_Appointment__r.AppointmentNumber=''; 
                    }
                    var Oop={
                        'Count': count,
                        'Object':Attlist[i],
                        'LastCount':''
                        
                     };
                    
                    attlistes.push(Oop);
                    attlistes[prevChild].LastCount=count;
                }
                
                console.log("attlistes",attlistes);
                component.set("v.AttList",attlistes);
                setTimeout(function(){
                    $A.util.removeClass(component.find("busyIndicator"), "slds-show");
                    $A.util.addClass(component.find("busyIndicator"), "slds-hide");
                }, 5000);
            }
            else{
                component.set('v.HasRecord',true);
                setTimeout(function(){
                    $A.util.removeClass(component.find("busyIndicator"), "slds-show");
                    $A.util.addClass(component.find("busyIndicator"), "slds-hide");
                }, 1000);
            }
        });
        $A.enqueueAction(action);	
	},
    
    closePress : function(component,event,helper){
        //alert('called');
        $A.get("e.force:closeQuickAction").fire();
    },
    UpdateAttendees : function(component,event,helper){
        var AttList = component.get("v.AttList"); 
        var UpdatedList=[];
        for(var i=0;i<AttList.length;i++){
            var Attendee=AttList[i].Object;
            UpdatedList.push(Attendee);
        }
        var action = component.get("c.UpdateAttendee");
        action.setParams({
            'AttendeeList' : UpdatedList
        });
        action.setCallback(this, function(a) {
            $A.get("e.force:closeQuickAction").fire();
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "message": "The record has been updated successfully."
            });
            toastEvent.fire();
        });
        $A.enqueueAction(action);
        
    }
})