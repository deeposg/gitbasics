@isTest
private class RainchecksTriggerHandlerTest {
    
    @testSetup
    static void testData(){
        /*Trigger_Setup__c setting = (Trigger_Setup__c) SmartFactory.createSObject('Trigger_Setup__c',new Map<String, Object>{'Name' => 'Trigger Setup'});
        insert setting;
        
        Account acc = (Account) SmartFactory.createSObject('Account');
        insert acc;
        
        Pricebook2 pb = (Pricebook2)SmartFactory.createSObject('Pricebook2');
        pb.IsActive=TRUE;
        insert pb;
        System.debug('Pricebook2::::'+pb);
        
        Product2 pro = (Product2)SmartFactory.createSObject('Product2');
        pro.IsActive=true;
        pro.Delivery_Method__c = 'Classroom';
        pro.Family = 'Courses';
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
        
        Order ord = (Order) SmartFactory.createSObject('Order',new Map<String,Object>{'AccountId'=> acc.id,'EffectiveDate' => System.today(),'Pricebook2Id'=>pb.id});
        insert ord;
        
        OrderItem ordItem = (OrderItem) SmartFactory.createSObject('OrderItem',new Map<String,Object>{'Product2Id'  =>pro.id , 'OrderId' => ord.id,'PricebookEntryId'=> pbe.id,'UnitPrice'=>100.0,'Generate_Raincheck__c'=>'Yes'});
        insert ordItem;
        
        Rainchecks__c rain = (Rainchecks__c) SmartFactory.createSObject('Rainchecks__c',new Map<String,Object>{'Account__c'=>acc.id, 'Product__c'=>pro.id,'Status__c'=>'Pending', 'Initial_Value__c'=>1500});
        insert rain;
*/
    }
    
    
    private static testMethod void testInsertTrigger() {
        /*
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Rainchecks__c rain = (Rainchecks__c) SmartFactory.createSObject('Rainchecks__c', new Map<String,Object>{'Account__c'=>acc.id, 'Product__c'=>prod.id,'Status__c'=>'Pending', 'Initial_Value__c'=>1500});
        insert rain;
        rain = [SELECT Id, Is_Completed_Expired__c, Status__c FROM Rainchecks__c WHERE Id = :rain.Id]; 
        System.assertEquals(False, rain.Is_Completed_Expired__c);
        
        Rainchecks__c rain1 = (Rainchecks__c) SmartFactory.createSObject('Rainchecks__c', new Map<String,Object>{'Account__c'=>acc.id, 'Product__c'=>prod.id,'Status__c'=>'Completed', 'Initial_Value__c'=>0});
        insert rain1;
        rain1 = [SELECT Id, Is_Completed_Expired__c, Status__c FROM Rainchecks__c WHERE Id = :rain1.Id]; 
        System.assertEquals(True, rain1.Is_Completed_Expired__c);
*/
        
    }
    
    private static testMethod void testUpdateTrigger() {
        /*
        Rainchecks__c raincheckRecord = [SELECT Id, Is_Completed_Expired__c, Status__c FROM Rainchecks__c LIMIT 1]; 
        Update raincheckRecord;   
        System.assertEquals(False, raincheckRecord.Is_Completed_Expired__c);
        
        raincheckRecord.Status__c = 'Completed';
        Update raincheckRecord;       
        raincheckRecord = [SELECT Id, Is_Completed_Expired__c, Status__c FROM Rainchecks__c WHERE Id = :raincheckRecord.Id]; 
        System.assertEquals(True, raincheckRecord.Is_Completed_Expired__c);
        
        Order o = [select id, AccountId,Count_of_Products__c,Status,SBQQ__PriceCalcStatus__c,CreatedDate from Order];
        o.SBQQ__PriceCalcStatus__c = 'Completed';
        o.StatusCode = 'A';
        o.Status = 'Activated';
        update o;
        //Order result = [select id, Status, SBQQ__PriceCalcStatus__c, Count_of_Products__c from Order where id =: o.id ];
        //system.assert(false, result);
        //System.assertEquals(result.Status, 'Activated');

        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        //Rainchecks__c rain4 = (Rainchecks__c) SmartFactory.createSObject('Rainchecks__c', new Map<String,Object>{'Account__c'=>acc.id, 'Product__c'=>prod.id,'Status__c'=>'Completed', 'Initial_Value__c'=>0, 'Order__c'=>reductionOrder.Id});
        //insert rain4;
        //
        */
    }
}