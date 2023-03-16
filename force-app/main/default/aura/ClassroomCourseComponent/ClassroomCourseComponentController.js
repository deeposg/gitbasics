    ({
        doInit : function(component, event, helper) {   
            console.log('ClassroomCourseComp INIT');
            var action = component.get("c.getValues");
            action.setParams({
                "quoteId" : component.get("v.recordId"),
                "ProductFamily1" : "Courses",
                "ProductFamily2" : "Evaluations",
                "DeliveryMethod" :  "Classroom"
            });
            
            //Set up the callback
            action.setCallback(this, function(actionResult) {
                var RecordList = actionResult.getReturnValue();
                if(RecordList.length ==0){
                    component.set('v.HasRecord',true);
                }
                else{
                    component.set('v.HasRecord',false);
                }
                component.set("v.values",RecordList);
                $A.util.removeClass(component.find("busyIndicator"), "slds-show");
                $A.util.addClass(component.find("busyIndicator"), "slds-hide");
                
            }); 
            $A.enqueueAction(action);  
        },
        
        UpdateModals : function(component, event, helper){
        
            component.set("v.SelectedProductId",event.getParam("ProductId"));
            component.set("v.SelectedQuoteId",event.getParam("SbqqQuoteLineId"));
            component.set("v.SelectedCourseLine",event.getParam("courseLine"));
            component.set("v.cccDistanceLearning",event.getParam("meDistanceLearning"));
            component.set("v.ModalCheck",event.getParam("ModalCheck"));
            
            console.log('event Param :: ',event.getParam("courseLine"))
            console.log('Selected Course Line------------------------  ::', component.get("v.SelectedCourseLine"));
            console.log('Selected Distance Le------------------------  ::', component.get("v.cccDistanceLearning"));
        },
        CloseModals : function(component, event, helper){
            
            component.set("v.ModalCheck",event.getParam("ModalCheck"));
        },
        UpdateRecord : function(component, event, helper){
        
            component.set("v.ModalCheck",event.getParam("ModalCheck"));
            console.log('final',component.get("v.values"));
            console.log('final - course: ', event.getParam("CouseName"));
            var RcList=component.get("v.values");
            for(var i=0; i < RcList.length ; i++){
                if(RcList[i].RecordId == event.getParam("SbqqQuoteLineId")){
                    RcList[i].ClassroomName =event.getParam("CouseName");
                }
            }
            component.set("v.values",RcList);
        }
    })