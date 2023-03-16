trigger QuoteLineTrigger on SBQQ__QuoteLine__c (after insert, after update, after delete, before insert, before update, before delete) {
    Trigger_Setup__c triggSetting = Trigger_Setup__c.getInstance('Trigger Setup');
    if(!triggSetting.All_Triggers__c && !triggSetting.Deactivate_QuoteLineTrigger__c)
        new QuoteLineTriggerHandler().run();
}