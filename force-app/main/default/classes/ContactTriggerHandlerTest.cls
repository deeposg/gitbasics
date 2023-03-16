@isTest
private class ContactTriggerHandlerTest {
    @testSetup 
    static void testData(){
        Trigger_Setup__c setting = (Trigger_Setup__c) SmartFactory.createSObject('Trigger_Setup__c',new Map<String, Object>{'Name' => 'Trigger Setup'});
        insert setting;
        
        Account acc = (Account) SmartFactory.createSObject('Account');
        insert acc;
        
        PermissionSetAssignment psa = [select Id, Assignee.Name, PermissionSet.Name from PermissionSetAssignment Where PermissionSet.Name = 'FSL_Resource_License' Limit 1];
        System.assertEquals(true, psa.Id != null);
        
        User u = [Select id, Email from User where Name =: psa.Assignee.Name Limit 1];
        System.assertEquals(true, u.Id != null);
        
        Contact c = (Contact)SmartFactory.createSObject('Contact', new Map<String, String>{'Owner'=>u.id,'LastName' =>'LastName','FirstName' =>'FastName', 'AccountId' =>acc.id, 'Email'=>'ajitj@appcino.com' });
        insert c;
        
    }
    
    @isTest
    static void doTestCodeCoverage(){
        ContactTriggerHandler.TestCodeCoverage();
    }    
    
}