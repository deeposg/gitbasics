/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Unit tests are class methods that verify whether a particular piece
* of code is working properly. Unit test methods take no arguments,
* commit no data to the database, and are flagged with the testMethod
* keyword in the method definition.
*
* All test methods in an organization are executed whenever Apex code is deployed
* to a production organization to confirm correctness, ensure code
* coverage, and prevent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production organization. In addition, all triggers must have some code coverage.
* 
* The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the organization size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
*/
@isTest
private class F8_WebServicesTest {
    
    //Preparing test data
    @testSetup
    private static void testData() {
        Trigger_Setup__c setting = (Trigger_Setup__c) SmartFactory.createSObject('Trigger_Setup__c',new Map<String, Object>{'Name' => 'Trigger Setup'});
        insert setting;
        
        Account acc = (Account) SmartFactory.createSObject('Account');
        insert acc;
        
        Contact c = (Contact)SmartFactory.createSObject('Contact', new Map<String, Object>{'LastName' =>'LastName','FirstName' =>'FastName', 'AccountId' =>acc.id ,'Session_ID__c' => '128dh777as'});
        insert c;
        
        Pricebook2 testPriceBook = (Pricebook2)SmartFactory.createSObject('Pricebook2', new Map<String, Object>{'name' => 'Standard Price Book 2000', 'Description' => 'Price Book 2000 Products', 'IsActive' => true});
        insert testPriceBook;
        
        Opportunity testOpportunity = (Opportunity)SmartFactory.createSObject('Opportunity', new Map<String, Object>{'Name' => 'testOpp', 'AccountId' => acc.id, 'CloseDate' => Date.Today() + 2, 'StageName' => 'Quoting', 'ForecastCategoryName' => 'Pipeline', 'Type' => 'New Customer'});
        insert testOpportunity;
        
        SBQQ__Quote__c testQuote = (SBQQ__Quote__c)SmartFactory.createSObject('SBQQ__Quote__c', new Map<String, Object>{'SBQQ__PrimaryContact__c' => c.id, 'SBQQ__Type__c' => 'Quote', 'TTT_Prerequisite_Exempt__c' => 'No', 'SBQQ__Primary__c' => true, 'SBQQ__Status__c' => 'Draft', 'SBQQ__DeliveryMethod__c' => 'Standard Courier', 'SBQQ__Opportunity2__c' => testOpportunity.id, 'SBQQ__PriceBook__c' => Test.getStandardPricebookId(), 'SBQQ__PricebookId__c' => Test.getStandardPricebookId(), 'Invoice_Contact__c' => c.id});
        insert testQuote;
        
    }
    
    
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        Test.startTest();
        
        
        System.assertNotEquals(null, F8_WebServices.generateKey());
        System.assertEquals(true, F8_WebServices.generateErrorResponse('Error has occured', 'ERROR').error);
        Test.stopTest();
    }
    
    static testMethod void myUnitTest1() {
        
        // TO DO: implement unit test
        Test.startTest();
        
        SBQQ__Quote__c quote = [SELECT id FROM SBQQ__Quote__c LIMIT 1];
        System.assertNotEquals(null, F8_WebServices.calculatorAPI(quote.Id));
        Test.stopTest();
        
    }
}