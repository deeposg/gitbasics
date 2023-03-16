({
	myAction : function(component, event, helper) {
		
	},
    
    doInit : function(component, event, helper) {
		console.log('browser',  $A.get("$Browser.formFactor"));
                
        var data = {
            labels: ["January", "February", "March"],
            datasets: [{
                data: [65, 59, 80, 81, 56, 55, 40]
            }]
        };
        var el = component.find("d3Container").getElement();
		console.log('el', el);
        
    },
    
    handleClick : function (cmp, event, helper) {
        console.log("You clicked: " + event.getSource().get("v.label"));

  
                   cmp.find('overlayLib').showCustomModal({
                       header: "Application Confirmation",

                       showCloseButton: true,
                       cssClass: "mymodal",
                       closeCallback: function() {
                           alert('You closed the alert!');
                       }
                   });
                   
    }      
})