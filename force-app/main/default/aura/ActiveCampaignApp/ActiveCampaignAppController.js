({
	doInit: function(cmp) {
		var userId = $A.get("$SObjectType.CurrentUser.Id");
        cmp.set("v.userId", userId);
    }

})