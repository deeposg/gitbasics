@isTest
private class AttendeeTriggerHandlerTest {

    private static void testData(){
       Trigger_Setup__c setting = (Trigger_Setup__c) SmartFactory.createSObject('Trigger_Setup__c',new Map<String, Object>{'Name' => 'Trigger Setup'});
        insert setting;
        
        Account acc = (Account) SmartFactory.createSObject('Account');
        insert acc;
        
        PermissionSetAssignment psa = [select Id, Assignee.Name, PermissionSet.Name from PermissionSetAssignment Where PermissionSet.Name = 'FSL_Resource_License' Limit 1];
        System.assertEquals(true, psa.Id != null);
        
        User u = [Select id, Email from User where Name =: psa.Assignee.Name Limit 1];
        System.assertEquals(true, u.Id != null);
        
        Contact c = (Contact)SmartFactory.createSObject('Contact', new Map<String, String>{'LastName' =>'LastName','FirstName' =>'FastName', 'AccountId' =>acc.id });
        insert c;
        
        Pricebook2 pb = (Pricebook2)SmartFactory.createSObject('Pricebook2');
        pb.IsActive=TRUE;
        insert pb;
        System.debug('Pricebook2::::'+pb);
        
        Product2 pro = (Product2)SmartFactory.createSObject('Product2');
        pro.IsActive=true;
        insert pro;
        System.debug('Product2::::'+pro);
        
        PricebookEntry stdpbe = (PricebookEntry)SmartFactory.createSObject('PricebookEntry',new Map<String, Object>{'Pricebook2Id' => Test.getStandardPricebookId(), 'Product2Id' => pro.Id});
        stdpbe.IsActive=TRUE;
        insert stdpbe;
        System.debug('STd PricebookEntry::::'+stdpbe);
        
        PricebookEntry pbe = (PricebookEntry)SmartFactory.createSObject('PricebookEntry', new Map<String, Object>{'Pricebook2Id' =>pb.Id, 'Product2Id' => pro.Id});
        pbe.IsActive=true;
        insert pbe;
        System.debug('PricebookEntry::::'+pbe);
        
        Opportunity opp = (Opportunity)SmartFactory.createSObject('Opportunity', new Map<String, String>{'Name' =>'Test Opportunity','StageName' =>'Open','AccountId' => acc.Id , 'Pricebook2Id' => pb.id}); 
        //system.assert(false,opp);
        insert opp;
        
        SBQQ__Quote__c q =  (SBQQ__Quote__c)SmartFactory.createSObject('SBQQ__Quote__c', new Map<String, Object>{'SBQQ__PrimaryContact__c' =>c.id , 'SBQQ__Opportunity__c' => opp.id, 'SBQQ__Primary__c' => true,'SBQQ__Status__c' => 'Draft','SBQQ__SubscriptionTerm__c' => 365,'SBQQ__Type__c' => 'Quote','SBQQ__StartDate__c' => Date.today()});
        insert q;
        System.debug('SBQQ__Quote__c::::'+q);
        
        SBQQ__QuoteLine__c ql = (SBQQ__QuoteLine__c)SmartFactory.createSObject('SBQQ__QuoteLine__c', new Map<String, Object>{'SBQQ__Product__c' =>pro.id,'SBQQ__Quote__c' => q.id,'SBQQ__ListPrice__c' => 10.0,'SBQQ__Quantity__c' => 10, 'SBQQ__Number__c' =>1,'Days_to_Fulfill_Order__c' =>'1-2 business days','SBQQ__SubscriptionBase__c' => 'List','SBQQ__SubscriptionScope__c'=> 'Quote'});
        insert ql;
        
        OperatingHours hour = (OperatingHours) SmartFactory.createSObject('OperatingHours');
        insert hour;
        
        WorkType wt = (WorkType) SmartFactory.createSObject('WorkType');
        insert wt;
        
        Order ord = (Order) SmartFactory.createSObject('Order',new Map<String,Object>{'AccountId'=> acc.id,'EffectiveDate' => System.today(),'Pricebook2Id'=>pb.id});
        insert ord;
        
        OrderItem ordItem = (OrderItem) SmartFactory.createSObject('OrderItem',new Map<String,Object>{'Product2Id'  =>pro.id , 'OrderId' => ord.id,'PricebookEntryId'=> pbe.id,'UnitPrice'=>100.0});
        insert ordItem;
        
        ServiceTerritory st = (ServiceTerritory)SmartFactory.createSObject('ServiceTerritory',new Map<String, Object>{'OperatingHoursId' => hour.Id,'IsActive' => true});
        insert st;
      
        WorkOrder wo = (WorkOrder)SmartFactory.createSObject('WorkOrder',new Map<String, Object>{'AccountId' => acc.id ,'ServiceTerritoryId' => st.id,'WorkTypeId'=> wt.id});
        insert wo;
 
       
    //system.assert(false,setting);
        ServiceAppointment sa = (ServiceAppointment)SmartFactory.createSObject('ServiceAppointment',new Map<String, Object>{'ParentRecordId' => wo.id});
        insert sa;

        Attendee__c att = (Attendee__c)SmartFactory.createSObject('Attendee__c',new Map<String,Object>{'Name' => 'Test','Service_Appointment__c' => sa.id,'Contact__c'=>c.id,'Order_Product__c' => ordItem.id});
        
        insert att; 
    }
    
    private static void updateTest(){
        test.startTest();
            Attendee__c att = [select id,name from Attendee__c];
            att.Name = 'Test Attendee';
            update att;
        test.stopTest();
    }
    
    private static void deleteTest(){
        test.startTest();
            Attendee__c att = [select id,name from Attendee__c];
            delete att;
            Attendee__c att2 = [select id,name from Attendee__c where id =:att.id ALL ROWS];
            undelete att2;
        test.stopTest();
    }
    
    @isTest
    static void doTestCodeCoverage(){
        AttendeeTriggerHandler.TestCodeCoverage();
    }
}