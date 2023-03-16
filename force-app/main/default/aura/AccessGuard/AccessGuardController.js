({
    handleClick : function (cmp, event, helper) {
        console.log("You clicked: " + event.getSource().get("v.label"));
        
$A.get('e.force:refreshView').fire();
    }
})