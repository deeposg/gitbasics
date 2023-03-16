/**********************************************************************
Name: ShippingItemTrigger
Author : Blessen Mathew
Description : Handles shipping logic (Amazon/Local)

History Log
==========================
2019-03-11		BMathew		Initial creation of trigger
2019-03-28		BMathew		Add handling of GBHolder and 2019 GB
**********************************************************************/
trigger ShippingItemTrigger on Shipping_Item__c (before insert, after insert, after update) {    
    //Store sku for all amazon products
    List<String> JHSCPosterIds = new List<String>();
    
    //Store ID of items to be processed further
 	Set<Id> posterOrderIds = new Set<Id>();
    Set<Id> shipOrderItemIds = new Set<Id>();   
    
    Shipping_Item__c oldShipping;
    
    //Fetch all amazon goods to be considered and construct a list of their Amazon Skus
    List<Product2> jhscPosterProducts = [Select Id from Product2 where ProductCode = 'PG-JHSCP' and IsActive = TRUE];
    
    for(Product2 product : jhscPosterProducts){
        JHSCPosterIds.add(product.Id);
    }
    
    if(Trigger.isBefore){
        for(Shipping_Item__c shippingItem : (List<Shipping_Item__c>)trigger.new){
            //Update any physical goods being shipped through amazon to generate Fulfillment ID
            if(shippingItem.Shipping_Method__c == 'Standard Courier'){
                //handle JHSC posters
                if(JHSCPosterIds.contains(shippingItem.Product__c)){
                    shippingItem.Fulfillment_Id__c = shippingItem.Order__c + '-PT-' + shippingItem.Order_Product__c;
                }
            }
        }             
    }
    
	if(Trigger.isAfter){
        for(Shipping_Item__c shippingItem : (List<Shipping_Item__c>)trigger.new){
            if(Trigger.isInsert){
                //Process any physical goods being shipped through amazon
                if(shippingItem.Shipping_Method__c == 'Standard Courier' && shippingItem.Fulfillment_Id__c != NULL){                    
                    //JHSC Poster
                    if(JHSCPosterIds.contains(shippingItem.Product__c)){
                        posterOrderIds.add(shippingItem.Order__c);
                    }
                }
            }
            
            if(Trigger.isUpdate){
                oldShipping = (Shipping_Item__c)Trigger.oldMap.get(shippingItem.Id); 
                
                if(shippingItem.Shipped__c == TRUE && oldShipping.Shipped__c == FALSE){
                    shipOrderItemIds.add(shippingItem.Order_Product__c);
                }           
            }
        }     
    }
    
    //Process orders that have JHSC Posters if processed by Amazon
    if(posterOrderIds.size() > 0){
	    ShippingItemTriggerHandler.processPosters(posterOrderIds, JHSCPosterIds);        
    }
    
    //Process shipping items and associated order products that are now shipped
    if(shipOrderItemIds.size() > 0){
		ShippingItemTriggerHandler.shipOrderItems(shipOrderItemIds);
    }
}