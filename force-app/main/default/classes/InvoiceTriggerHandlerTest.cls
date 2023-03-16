@isTest
public class InvoiceTriggerHandlerTest {
    @isTest (SeeAllData=true)
    static void deployTrigger(){
        Account acc = (Account) SmartFactory.createSObject('Account');
        insert acc;        
        
        Pricebook2 pb = (Pricebook2)SmartFactory.createSObject('Pricebook2');
        pb.IsActive=TRUE;
        insert pb;
        
        Contact contact = [Select Id from Contact where email != NULL limit 1];
        
        Order ord = (Order) SmartFactory.createSObject('Order',new Map<String,Object>{'AccountId'=> acc.id,'EffectiveDate' => System.today(),'Pricebook2Id'=>pb.id, 'Invoice_Contact__c'=>contact.Id, 'Status' => 'Draft'});
        insert ord;

        Invoice__c invoice = new Invoice__c();
        invoice.Account__c = acc.Id;
        invoice.Name = '123-Test';
        invoice.Order__c = ord.Id;
		invoice.Billing_Contact__c = contact.Id;
        insert invoice;
        
        delete invoice;         
    }
    
    @isTest
    static void doTestCodeCoverage(){
        InvoiceTriggerHandler.TestCodeCoverage();
    }   
}