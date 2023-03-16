({
	doInit: function(component, event, helper) {
        var action = component.get("c.getAttLst");
        action.setParams({
            'RecordId' :component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var Attlist=a.getReturnValue();
            console.log(Attlist.length);
            if(Attlist.length>0){
                var attlistes=[];
                var count=0;
                var qtlid='';
                var prevChild=0;
                for( var i=0;i<Attlist.length;i++){
                    if(qtlid == ''){
                        qtlid=Attlist[i].Quote_Line__c;
                    }
                    if(qtlid == Attlist[i].Quote_Line__c){
                        count++;
                    }
                    else{
                        qtlid=Attlist[i].Quote_Line__c;
                        prevChild=prevChild+count;
                        count=0;
                        count++;
                    }
                    
                    if(count!=1){
                        Attlist[i].Quote_Line__r.Name=''; 
                    }
                    var Oop={
                        'Count': count,
                        'Object':Attlist[i],
                        'LastCount':''
                        
                     };
                    attlistes.push(Oop);
                    console.log('list',attlistes);
                    console.log('Ivali',attlistes[i]);
                    console.log('vPvali',attlistes[prevChild]);
                    attlistes[prevChild].LastCount=count;
                    
                }
                
                
                component.set("v.AttList",attlistes);
                console.log(attlistes);
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