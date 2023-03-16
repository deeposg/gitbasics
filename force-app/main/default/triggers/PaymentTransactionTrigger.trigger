/**********************************************************************
Name: PaymentTransactionTrigger
Author : Blessen Mathew
Description : Trigger for Payment_Transaction__c

History Log
==========================
2021-06-25		BMathew		Initial creation of trigger
**********************************************************************/
trigger PaymentTransactionTrigger on Payment_Transaction__c (after insert, after update, after delete, before insert, before update, before delete) {
	new PaymentTransactionTriggerHandler().run();
}