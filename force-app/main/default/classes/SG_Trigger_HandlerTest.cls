@isTest
public class SG_Trigger_HandlerTest {
    static testMethod void testBeforeOnDeleteTriggers() {
        SObject o;
        
        System.debug('testBeforeOnDeleteTriggers::Account');
        try {
            o = new Account();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Asset');
        try {
            o = new Asset();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Attachment');
        try {
            o = new Attachment();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Campaign');
        try {
            o = new Campaign();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Case');
        try {
            o = new Case();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Contact');
        try {
            o = new Contact();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Contract');
        try {
            o = new Contract();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Event');
        try {
            o = new Event();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Lead');
        try {
            o = new Lead();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Note');
        try {
            o = new Note();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Opportunity');
        try {
            o = new Opportunity();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Order');
        try {
            o = new Order();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::OrderItem');
        try {
            o = new OrderItem();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::Task');
        try {
            o = new Task();
            insert o;
        } catch(Exception ex) {}
        
        System.debug('testBeforeOnDeleteTriggers::User');
        try {
            o = new User();
            insert o;
        } catch(Exception ex) {}

    }
    
    static testMethod void testBeforeOnDeleteBadObject() {
        List <Object> deletedObjects = new List<Object>();
        
        deletedObjects.add((String)'Bad Object');
        SG_Trigger_Handler.onDelete(deletedObjects);

    }
    
    static testMethod void testBeforeOnDeleteNoSGField() {
        List <Object> deletedObjects = new List<Object>();
        
        SG_TestRecord_Abstract o = new SG_TestRecord_NoSGField();

        deletedObjects.add(o);
        SG_Trigger_Handler.onDelete(deletedObjects);
        
        System.assertEquals(o.errMsg, '');
        System.assertEquals(o.get(''), null);
                

    }
    
    static testMethod void testBeforeOnDeleteNullFieldValue() {
        List <Object> deletedObjects = new List<Object>();
        
        SG_TestRecord_Abstract o = new SG_TestRecord_NullFieldValue();
        
        deletedObjects.add(o);
        SG_Trigger_Handler.onDelete(deletedObjects);
        
        System.assertEquals(o.errMsg, '');

    }
    
    static testMethod void testBeforeOnDeleteStringField() {
        List <Object> deletedObjects = new List<Object>();
        
        SG_TestRecord_Abstract o = new SG_TestRecord_FieldType_String();
        
        deletedObjects.add(o);
        SG_Trigger_Handler.onDelete(deletedObjects);
        
        System.assertEquals(o.errMsg, 'Test Error Message');

    }
    
    static testMethod void testBeforeOnDeleteBooleanField() {
        List <Object> deletedObjects = new List<Object>();
        
        SG_TestRecord_Abstract o = new SG_TestRecord_FieldType_Boolean();
        
        deletedObjects.add(o);
        SG_Trigger_Handler.onDelete(deletedObjects);
        
        System.assertEquals(o.errMsg, 'SafeGuard: You Don\'t Have Permission To Delete This Record');

    }
    
    static testMethod void testBeforeOnDeleteDoubleField() {
        List <Object> deletedObjects = new List<Object>();
        
        SG_TestRecord_Abstract o = new SG_TestRecord_FieldType_Double();
        
        deletedObjects.add(o);
        SG_Trigger_Handler.onDelete(deletedObjects);
        
        System.assertEquals(o.errMsg, 'SafeGuard: You Don\'t Have Permission To Delete This Record');

    }
    
    static testMethod void testBeforeOnDeleteOtherField() {
        List <Object> deletedObjects = new List<Object>();
        
        SG_TestRecord_Abstract o = new SG_TestRecord_FieldType_Other();
        
        deletedObjects.add(o);
        SG_Trigger_Handler.onDelete(deletedObjects);
        
        System.assertEquals(o.errMsg, 'SafeGuard: You Don\'t Have Permission To Delete This Record');

    }
}