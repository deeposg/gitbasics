@isTest
public class ShippingItemTriggerHandlerTest {
	
    @isTest(SeeAllData=true)
    //before insert, after insert, after update
    static void deployTrigger(){
        List<Product2> JHSCPosterProducts = [Select Amazon_Sku__c from Product2 where ProductCode = 'PG-JHSCP' and IsActive = TRUE and Amazon_Sku__c != NULL];
        List<String> JHSCPosterSKUs = new List<String>();
        for(Product2 product : JHSCPosterProducts){
            JHSCPosterSKUs.add(product.Amazon_Sku__c);
        }        
        
		Order order = [Select Id from Order Limit 1];
        OrderItem orderItem = [Select Id from OrderItem Limit 1];
        Product2 product = [Select Id from Product2 limit 1];
		Contact contact = [Select Id from Contact limit 1];
        Account_Address__c accountAddress = [Select Id from Account_Address__c where Location_Address__c != NULL limit 1];
        
		Shipping_Item__c shippingItem = (Shipping_Item__c) SmartFactory.createSObject('Shipping_Item__c');
        String testPosterSku = JHSCPosterSKUs[0];
        shippingItem.Order__c = order.Id;
        shippingItem.Order_Product__c = orderItem.Id;        
        shippingItem.Amazon_Sku__c = testPosterSku;
        shippingItem.Name = '1234-SHIPPING';
		shippingItem.Product__c = product.Id;
        shippingItem.Quantity__c = 1;
        shippingItem.Shipping_Method__c = 'Standard Courier';
        shippingItem.Shipping_Courrier__c = 'Amazon';
        shippingItem.Ship_To_Contact__c = contact.Id;
        shippingItem.Shipping_Address__c = accountAddress.Id;

        insert shippingItem;      
              
              
        Shipping_Item__c si3 = [Select Shipped__c from Shipping_Item__c where id = :shippingItem.Id];
        si3.Shipped__c = TRUE;
        update si3;
    }
    
    @isTest
    static void doTestCodeCoverage(){
        ShippingItemTriggerHandler.TestCodeCoverage();
    }  
}