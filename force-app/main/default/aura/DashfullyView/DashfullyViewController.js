({
	doInit : function(component, event, helper) {
        console.log('DashfullyView::doInit()');
        
        var recordID = component.get("v.recordId");
        if (recordID == undefined) {
            recordID = '';
        }
//        console.log('sObjectName: ', component.get("v.sObjectName"));
        
        var url = window.location.href.split("?")[0];
        var urlParts = url.split('/');
        var mode = urlParts[urlParts.length-1];
        
  
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var sessionId = '';
        var organizationId = '';
        var partnerURL = '';
        
//        component.set("v.dashFrameSrc", "https://dashfully.herokuapp.local/" + mode + "/" + recordID)
//        

        var action = component.get("c.getSessionDetails");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var sessionDetails = response.getReturnValue();
                // set current user information on userInfo attribute
                //component.set("v.userInfo", storeResponse);
                //console.log('sessionDetails', sessionDetails);
                
                sessionId = sessionDetails[0];
                organizationId = sessionDetails[1];
                partnerURL = sessionDetails[2];
                
				console.log('mode: ', mode);
                console.log('userId', userId);
                console.log('sessionId', sessionId);
                console.log('organizationId', organizationId);
                console.log('partnerURL', partnerURL);
                
                var dashFrameSrc = "https://dashfully.herokuapp.local/" + mode + "/" + recordID + "?embedded&userId=" + encodeURI(userId) + "&sessionId=" + encodeURI(sessionId) + "&organizationId=" + encodeURI(organizationId) + "&partnerURL=" + encodeURI(partnerURL);
                component.set("v.dashFrameSrc", dashFrameSrc)
                 
            }
        });
        $A.enqueueAction(action);
        
        var listener = function(event) {
            if (event.data.frameHeight != undefined) {
				component.set("v.dashFrameHeight", event.data.frameHeight + 'px')
        	    component.set("v.loaded",true);
                component.set("v.containerHeightStyle",'');
                
            }
    	}
    
        if(window.addEventListener !== undefined) {
        	window.addEventListener("message", listener, false);
		}
    }
})