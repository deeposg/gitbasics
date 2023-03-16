trigger TimeOffRequestTrigger on Time_Off_Request__c (after insert, after update, after delete, before insert, before update, before delete) {
    Trigger_Setup__c triggSetting = Trigger_Setup__c.getInstance('Trigger Setup');
    if(!triggSetting.All_Triggers__c && !triggSetting.Deactivate_TimeOffRequestTrigger__c)
        new TimeOffRequestTriggerHandler().run();
}