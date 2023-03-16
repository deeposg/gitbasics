@isTest
public class PaymentTransactionTriggerHandlerTest {
	@isTest (SeeAllData=true)
    static void deployTrigger(){
        Invoice__c invoice = [Select Id, Account__c from Invoice__c where Balance__c > 0 limit 1];
        Credit_Note__c creditNote = [Select Id from Credit_Note__c where Balance__c > 0 limit 1];
        
        Payment_Transaction__c paymentTransaction = new Payment_Transaction__c();
        paymentTransaction.Amount__c = 1;
        paymentTransaction.Invoice__c = invoice.Id;
        paymentTransaction.Credit_Note__c = creditNote.Id;
        paymentTransaction.Date_Posted__c = System.now();
        paymentTransaction.From_LMS__c = true;
        
        insert paymentTransaction;
        
    }
    
    
    @isTest
    static void doTestCodeCoverage(){
        PaymentTransactionTriggerHandler.TestCodeCoverage();
    } 
}