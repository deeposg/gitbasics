@isTest(SeeAllData=true)
private class SetContactUniqueEmailMD5Test {
    @isTest
    static void updateContact(){
        Trigger_Setup__c triggSetting = Trigger_Setup__c.getInstance('Trigger Setup');
        triggSetting.Deactivate_ContactTrigger__c = true;
        update triggSetting;
        
        Contact c = [select id from Contact where unique_email__c = 'greg@osg.ca' limit 1];
        c.email = 'x_greg@osg.ca';
        c.unique_email__c = 'x_greg@osg.ca';
        update c;
    }    
    
}