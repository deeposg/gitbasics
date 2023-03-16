@isTest
private class TimeOffRequestTriggerHandlerTest {
    @testSetup
    static void testData(){
        Trigger_Setup__c setting = (Trigger_Setup__c) SmartFactory.createSObject('Trigger_Setup__c',new Map<String, Object>{'Name' => 'Trigger Setup'});
        insert setting;
        
        PermissionSetAssignment psa = [select Id, Assignee.Name, PermissionSet.Name from PermissionSetAssignment Where PermissionSet.Name = 'FSL_Resource_License' Limit 1];
        System.assertEquals(true, psa.Id != null);
        
        User u = [Select id from User where Name =: psa.Assignee.Name Limit 1];
        System.assertEquals(true, u.Id != null);
        
        OperatingHours hour = (OperatingHours) SmartFactory.createSObject('OperatingHours');
        insert hour;
        
        ServiceTerritory st = (ServiceTerritory)SmartFactory.createSObject('ServiceTerritory',new Map<String, Object>{'OperatingHoursId' => hour.Id,'IsActive' => true});
        insert st;
        
        ServiceResource sr = (ServiceResource)SmartFactory.createSObject('ServiceResource',new Map<String,Object>{'Name' => 'Test', 'External_ID__c' => 'ex1', 'IsActive' => true, 'RelatedRecordId'=>u.id});
        insert sr;
        
        ServiceTerritoryMember stm = (ServiceTerritoryMember)SmartFactory.createSObject('ServiceTerritoryMember',new Map<String,Object>{'ServiceTerritoryId'=> st.Id, 'ServiceResourceId' => sr.Id, 'TerritoryType'=>'P'});
        insert stm;
        
        Time_Off_Request__c tr = (Time_Off_Request__c)SmartFactory.createSObject('Time_Off_Request__c',new Map<String,Object>{'Service_Resource__c'=>sr.Id,'Type_of_Absence_Requested__c'=>'Sick','Start_Date_Time__c'=>system.now(),'End_Date_Time__c'=>(system.now()).addMonths(1),'Reason_for_Absence__c'=>'test','Status__c'=>'Draft'});
        insert tr;
     }
    
     static testmethod void updateTest(){
         Test.startTest();
         Time_Off_Request__c tor = [Select Id from Time_Off_Request__c];
         tor.Status__c = 'Approved';
         update tor;
         Test.stopTest();
        
       
    }
}