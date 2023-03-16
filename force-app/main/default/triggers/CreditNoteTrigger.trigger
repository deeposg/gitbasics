/**********************************************************************
Name: CreditNoteTrigger
Author : Blessen Mathew
Description : Trigger for Credit_Note__c

History Log
==========================
2019-01-17		BMathew		Initial creation of trigger
**********************************************************************/
trigger CreditNoteTrigger on Credit_Note__c (before delete) {
	new CreditNoteTriggerHandler().run();
}