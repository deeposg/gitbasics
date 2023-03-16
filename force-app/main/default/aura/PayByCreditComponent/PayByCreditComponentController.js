({
	doInit : function(component, event, helper) {
        console.log('doInit: ' + window.location.href);
        
        document.addEventListener('visibilitychange', function(e){
            //console.log('visibilitychange: ' ,document.hidden, e.timeStamp, e);
        });
        
        window .addEventListener('blur', function(e){
            //console.log('blur: ' , e);
        });
        
        window .addEventListener('focus', function(e){
            //console.log('focus: ' , e);
        });
        
        document.addEventListener('copy', function(e){
            //console.log('Copy: ' + window.getSelection().toString());
        });
        
        document.addEventListener('cut', function(e){
            //console.log('Cut: ' + window.getSelection().toString());
        });
        
        document.addEventListener('paste', function(e){
            //console.log('paste');
            
        });
        
        document.addEventListener('mouseup', function (event) {
            console.log('mouseup: ' , event.target);
            ///console.log('mouseup document.activeElement', document.activeElement);
            //
console.log(document.body.outerText);
            setTimeout(function() {
                console.log(document.body.outerText);
            }, 1000)
        }, true);
        
        document.addEventListener('mousedown', function (event) {
            console.log('mousedown 1: ' , event.target);
            console.log('mousedown 2: ' , event.toElement);
            ///console.log('mousedowndocument.activeElement', document.activeElement);
        }, true);
                                  
                                  
        
        document.addEventListener('keyup', function (event) {
        
        	var key = event.key || event.keyCode;
    
            console.log('key: ' + key);
            console.log('sel 2: ' , window.getSelection().toString());
            
            /*if (key == 'o') {
                var utilityAPI = component.find("utilitybar");
        		utilityAPI.openUtility();

            }*/
    	});
        
        /*
        var action = component.get("c.getOrderRecord");
        action.setParams({
            'RecordId': component.get('v.recordId')
        });
        action.setCallback(this, function(a){
            var returnUrl=a.getReturnValue();
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url" : returnUrl
            });
            urlEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
        });
        $A.enqueueAction(action);
        */
        //Find the text value of the component with aura:id set to "address"
        
       
	}
})