({ 
  doInit : function(component, event, helper) { 
      var userId = $A.get("$SObjectType.CurrentUser.Id");
	
      component.set("v.userId", userId);
  } 
})