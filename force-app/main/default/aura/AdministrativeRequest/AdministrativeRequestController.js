({
	doInit : function(component, event, helper) {
		var sObjectName = component.get("v.sObjectName");
        var recordId = component.get("v.recordId");
        var action;
        var getAccount = false;
        if(sObjectName == "Account"){
            action = component.get("c.getRecordTypesForAccount");
        }
        else if(sObjectName == "Order"){
            action = component.get("c.getRecordTypesForOrder");
            getAccount = true;
        }
        else if(sObjectName == "Invoice__c"){
            action = component.get("c.getRecordTypesForInvoice");
            getAccount = true;            
        }
        else if (sObjectName == "SBQQ__Quote__c"){
            action = component.get("c.getRecordTypesForQuote");
            getAccount = true;            
        }
        else if (sObjectName == 'OrderItem'){
			action = component.get("c.getRecordTypesForOrderItem");
            getAccount = true;                
        }
        action.setCallback(this, function(response) {
            component.set("v.lstOfRecordType", response.getReturnValue());
            
            //Set default value for inputSelection. (There is a known bug when only 1 option)
            component.find("selectid").set("v.value", response.getReturnValue()[0].Id);
        });
        $A.enqueueAction(action);
        
        if(getAccount == true){
            var accountAction = component.get("c.getAccountInfo");
            accountAction.setParams({
                "sObjectName" : sObjectName,
                "recordId" : recordId
            });
            
            accountAction.setCallback(this, function(response) {
                component.set("v.account", response.getReturnValue());
            });
            $A.enqueueAction(accountAction);
        }
	},
   	createRecord: function(component, event, helper){
		var sObjectName = component.get("v.sObjectName");
        var recordId = component.get("v.recordId");        
        var recordTypeId = component.find("selectid").get("v.value");
        //console.log(recordTypeId);
        var createRecordEvent = $A.get("e.force:createRecord");
        
        //get Account, Order, Invoice, Quote, anything we can set
        var accountId = '';
        var orderId = '';
        var quoteId = '';
        var invoiceId = '';
        var orderItemId = '';
        
        if(sObjectName == 'Account'){
            accountId = recordId;
        }
        else if(sObjectName == 'Order'){
            orderId = recordId;
            accountId = component.get("v.account").Id;
        }
        else if(sObjectName == 'SBQQ__Quote__c'){
            quoteId = recordId;
            accountId = component.get("v.account").Id;
        }
        else if(sObjectName == 'Invoice__c'){
            invoiceId = recordId;
            accountId = component.get("v.account").Id;
        }
        else if(sObjectName == 'OrderItem'){
            orderItemId = recordId;
            accountId = component.get("v.account").Id;
        }
        
        createRecordEvent.setParams({
            "entityApiName": 'Administrative_Request__c',
            "recordTypeId": recordTypeId,
            'defaultFieldValues' : {
                "Account__c" : accountId,
                "Order__c" : orderId,
                "Invoice__c" : invoiceId,
                "Quote__c" : quoteId,
                "Order_Product__c" : orderItemId
            }
        });
        createRecordEvent.fire();
   	}    
})