/**********************************************************************
Name: InvoiceTrigger
Author : Blessen Mathew
Description : Trigger for Invoice__c

History Log
==========================
2019-01-17		BMathew		Initial creation of trigger
**********************************************************************/
trigger InvoiceTrigger on Invoice__c (after insert, after update, after delete, before insert, before update, before delete) {
    new InvoiceTriggerHandler().run();
}