({
	ClickLookup : function(component, event, helper) {
        var Record=component.get("v.SbqqQuoteLine");
        console.log(component.get("v.SbqqQuoteLine"));
        var qliData=Record.RecordId;
        var pId=Record.ProductId;
        var cpLine=Record.CourseProductLine;
        var distanceLearning = Record.apexDistanceLearning;
		var cmpEvent = component.getEvent("UpdateModal");
        console.log('var cpLine'+cpLine);
        console.log('var distanceL' + distanceLearning);
        cmpEvent.setParams({
            "ProductId"		 : pId,
            "SbqqQuoteLineId": qliData,
            "ModalCheck"     : true,
            "courseLine"     : cpLine,
            "meDistanceLearning" : distanceLearning
        });
        cmpEvent.fire();
	}
})