({
	doInit: function(cmp) {
		var userId = $A.get("$SObjectType.CurrentUser.Id");
        cmp.set("v.userId", userId);
        console.log(cmp.get("v.userId"));
        
        window.addEventListener("message", function(event) {
            console.log('Update Height', event.data);
            ////document.getElementById('frame').height = event.data;
            //document.getElementById('frame').height = "500px";
        }, false);
    }

})