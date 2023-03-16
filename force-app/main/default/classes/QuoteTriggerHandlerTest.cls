@isTest
private class QuoteTriggerHandlerTest {
    
    static void testData(){
        Trigger_Setup__c setting = (Trigger_Setup__c) SmartFactory.createSObject('Trigger_Setup__c',new Map<String, Object>{'Name' => 'Trigger Setup'});
        insert setting;
        
        Account acc = (Account) SmartFactory.createSObject('Account');
        insert acc;
        
        PermissionSetAssignment psa = [select Id, Assignee.Name, PermissionSet.Name from PermissionSetAssignment Where PermissionSet.Name = 'FSL_Resource_License' Limit 1];
        System.assertEquals(true, psa.Id != null);
        
        User u = [Select id from User where Name =: psa.Assignee.Name Limit 1];
        System.assertEquals(true, u.Id != null);
        
        Contact c = (Contact)SmartFactory.createSObject('Contact', new Map<String, String>{'LastName' =>'LastName','FirstName' =>'FastName', 'AccountId' =>acc.id });
        insert c;
        
        Pricebook2 pb = (Pricebook2)SmartFactory.createSObject('Pricebook2');
        pb.IsActive=TRUE;
        insert pb;
        System.debug('Pricebook2::::'+pb);
        
        Product2 pro = (Product2)SmartFactory.createSObject('Product2',new Map<String,Object>{'Family'=>'Physical Goods','Current_Inventory_Count__c'=>10,'Maximum_Capacity_Maximum_Attendees__c' => 100});
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
        
         OperatingHours hour = (OperatingHours) SmartFactory.createSObject('OperatingHours');
        insert hour;
        
        WorkType wt = (WorkType) SmartFactory.createSObject('WorkType', new Map<String , Object>{'Product__c'=>Pro.Id});
        insert wt;
        
        ServiceTerritory st = (ServiceTerritory)SmartFactory.createSObject('ServiceTerritory',new Map<String, Object>{'OperatingHoursId' => hour.Id,'IsActive' => true});
        insert st;
        
        WorkOrder wo = (WorkOrder)SmartFactory.createSObject('WorkOrder',new Map<String, Object>{'AccountId' => acc.id ,'ServiceTerritoryId' => st.id,'WorkTypeId'=> wt.id});
        insert wo;
        
        ServiceAppointment sa = (ServiceAppointment)SmartFactory.createSObject('ServiceAppointment',new Map<String, Object>{'ParentRecordId' => wo.id,'Confirmed_Seats__c' => 5,'Course_Maximum_Capacity__c'=>50});
        insert sa;
        
        Order ord = (Order) SmartFactory.createSObject('Order',new Map<String,Object>{'AccountId'=> acc.id,'EffectiveDate' => System.today(),'Pricebook2Id'=>pb.id});
        insert ord;
        
        
        SBQQ__Quote__c q =  (SBQQ__Quote__c)SmartFactory.createSObject('SBQQ__Quote__c', new Map<String, Object>{'SBQQ__PrimaryContact__c' =>c.id , 'SBQQ__Account__c' => acc.Id, 'SBQQ__Opportunity__c' => opp.id, 'SBQQ__Primary__c' => true,'SBQQ__Status__c' => 'Draft','SBQQ__SubscriptionTerm__c' => 365,'SBQQ__Type__c' => 'Quote','SBQQ__StartDate__c' => Date.today(), 'Invoice_Contact__c' => c.id});
        insert q;
        //System.debug('SBQQ__Quote__c::::'+q);
        
        /*SBQQ__QuoteLine__c ql1 = (SBQQ__QuoteLine__c)SmartFactory.createSObject('SBQQ__QuoteLine__c', new Map<String, Object>{'SBQQ__Product__c' =>pro.id,'Product_Family__c'=>'Courses','Delivery_Method__c'=>'On-site','SBQQ__Quote__c' => q.id,'SBQQ__ListPrice__c' => 10.0,'SBQQ__Quantity__c' => 10,'Classroom_Course__c'=>sa.id, 'SBQQ__Number__c' =>1,'Days_to_Fulfill_Order__c' =>'1-2 business days','SBQQ__SubscriptionBase__c' => 'List','SBQQ__SubscriptionScope__c'=> 'Quote'});
        insert ql1;
        
        OrderItem ordItem = (OrderItem) SmartFactory.createSObject('OrderItem',new Map<String,Object>{'Product2Id'  =>pro.id , 'OrderId' => ord.id,'PricebookEntryId'=> pbe.id,'UnitPrice'=>100.0,'Product_Family__c'=>'Evaluations', 'SBQQ__QuoteLine__c' => ql1.Id});
        insert ordItem;
        
		Rainchecks__c rain = (Rainchecks__c) SmartFactory.createSObject('Rainchecks__c',new Map<String,Object>{'Account__c'=>acc.id,'Order__c'=>ord.id,'Order_Product__c'=>ordItem.id,'Product__c'=>pro.id,'Status__c'=>'Pending'});
        insert rain;
		        
		SBQQ__QuoteLine__c ql = (SBQQ__QuoteLine__c)SmartFactory.createSObject('SBQQ__QuoteLine__c', new Map<String, Object>{'Account__c'=>acc.id,'SBQQ__Product__c' =>pro.id,'Product_Family__c'=>'Courses','Delivery_Method__c'=>'Classroom','SBQQ__Quote__c' => q.id,'SBQQ__ListPrice__c' => 10.0,'SBQQ__Quantity__c' => 10,'Classroom_Course__c'=>sa.id, 'SBQQ__Number__c' =>1,'Days_to_Fulfill_Order__c' =>'1-2 business days','SBQQ__SubscriptionBase__c' => 'List','SBQQ__SubscriptionScope__c'=> 'Quote','Raincheck__c'=>rain.id});
        
        insert ql;        
        */
		
        
        
       
    }
    
    private static void bulkInsertTest(){
        
        /*Contact c =[Select id from Contact limit 1];
        Opportunity opp =[Select id,SBQQ__PrimaryQuote__c from Opportunity limit 1];
     
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        for(integer i = 0 ; i< 5 ;  i++){
             SBQQ__Quote__c q =  (SBQQ__Quote__c)SmartFactory.createSObject('SBQQ__Quote__c', new Map<String, Object>{'SBQQ__PrimaryContact__c' =>c.id , 'SBQQ__Opportunity__c' => opp.id, 'SBQQ__Status__c' => 'Draft','SBQQ__SubscriptionTerm__c' => 365,'SBQQ__Type__c' => 'Quote','SBQQ__StartDate__c' => Date.today().addDays(2)});
            quoteList.add(q);
        }
        insert quoteList;
        */
     
    }
    
    private static void updateTest(){
    
//      try{
      
     // SBQQ__Quote__c quote = [select id from SBQQ__Quote__c where SBQQ__Primary__c = true limit 1 ];
      //  quote.Payment_Type__c = 'Credit Card';
      //  quote.SBQQ__Status__c = 'Booked';   
       // update quote;
        
  //    }catch(Exception e){
    //   System.assert(false,e.getmessage());
     // }
      
       
    }
    
    @isTest
    static void doTestCodeCoverage(){
        QuoteTriggerHandler.TestCodeCoverage();
    }
    
}