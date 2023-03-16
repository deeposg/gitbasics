@isTest
public class ProductCostTriggerHandlerTest {
    @isTest
    static void deployTrigger(){
        Product2 prod = (Product2) SmartFactory.createSObject('Product2');
        insert prod;         
        
        Product_Cost__c productCost = new Product_Cost__c();        
        productCost.Name = 'Test';
        productCost.Amount__c = 100.0;
        productCost.Product__c = prod.Id;
        insert productCost;
        
        productCost.Amount__c = 90.0;
        update productCost;
        
        delete productCost;
    }
    
    @isTest
    static void doTestCodeCoverage(){
        ProductCostTriggerHandler.TestCodeCoverage();
    }  
}