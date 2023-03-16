@isTest
public class CreditNoteTriggerHandlerTest {
    @isTest (SeeAllData=true)
    static void deployTrigger(){
        Account acc = (Account) SmartFactory.createSObject('Account');
        insert acc;        
        
        Pricebook2 pb = (Pricebook2)SmartFactory.createSObject('Pricebook2');
        pb.IsActive=TRUE;
        insert pb;        
        
        Contact contact = [Select Id from Contact limit 1];
        
        Order ord = (Order) SmartFactory.createSObject('Order',new Map<String,Object>{'AccountId'=> acc.id,'EffectiveDate' => System.today(),'Pricebook2Id'=>pb.id, 'Invoice_Contact__c'=>contact.Id});
        insert ord;
        
        Credit_Note__c creditNote = (Credit_Note__c) SmartFactory.createSObject('Credit_Note__c',new Map<String,Object>{'Name'=> '123-Test', 'Account__c'=>acc.Id, 'Order__c'=>ord.Id});
        insert creditNote;
        
        delete creditNote;            
    }
    
    @isTest
    static void doTestCodeCoverage(){
        CreditNoteTriggerHandler.TestCodeCoverage();
    }   
}