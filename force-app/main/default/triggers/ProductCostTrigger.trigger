/**********************************************************************
Name: ProductCostTrigger
Author : Blessen Mathew
Description : Trigger for Product_Cost__c

History Log
==========================
2019-02-15		BMathew		Initial creation of trigger
**********************************************************************/
trigger ProductCostTrigger on Product_Cost__c (after insert, after update, after delete) {
    Set<Id> productIds = new Set<Id>();
    
    if(Trigger.isInsert){
        for(Product_Cost__c productCost : (List<Product_Cost__c>)trigger.new){
            if(productCost.Product__c != NULL){
                productIds.add(productCost.Product__c);
            }
        }          
    }
    
    if(Trigger.isUpdate || Trigger.isDelete){
        for(Product_Cost__c productCost : (List<Product_Cost__c>)trigger.old){
            if(productCost.Product__c != NULL){
                productIds.add(productCost.Product__c);
            }
        }   
    }
    
    if(productIds.size() > 0){
		ProductCostTriggerHandler.updateProductBaseCost(productIds);
    }
}