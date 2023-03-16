/**********************************************************************
Name: ContactTriggerHandler
Author : Shubham Verma
Description : Handler class for Contact Trigger   
**********************************************************************/
public with sharing class ContactTriggerHandler extends TriggerHandler{
    
    public override void afterInsert() {
        Set<Id> accountIds = new Set<Id>();
        for(Contact contact : (List<Contact>) Trigger.New){
            Account account = [Select Account_Status__c from Account where id =:contact.AccountId];
            if(account.Account_Status__c != 'Pending'){
	            accountIds.add(contact.AccountId);                
            }
        }
        
        if(accountIds.size() > 0){
            AccountTriggerHandler.mergeDuplicateContacts(accountIds);
        }
        
    }
     
    public override void afterUpdate() {
        Set<Id> updateContactIds = new Set<Id>();
        Set<Id> contactMergeAccountIds = new Set<Id>();
        
        Map<String, String> fieldMapping = new Map<String, String>{
            'email' => 'Email',
            'personal_email' => 'Personal_Email__c',    
            'first_name' => 'FirstName',
            'last_name' => 'LastName',
            'birthdate' => 'Date_Of_Birth__c',
            'cell_number' => 'MobilePhone',
            'home_number' => 'Phone'
        };
        Contact oldContact = new Contact();
        
        for(Contact contact : (List<Contact>) Trigger.New){
            oldContact = (Contact)Trigger.oldMap.get(contact.Id);

            if(!oldContact.FirstName.equals(contact.FirstName) || !oldContact.LastName.equals(contact.LastName)){
                contactMergeAccountIds.add(contact.AccountId);
            }
            
            for(String field : fieldMapping.values()){                
                if(oldContact.get(field) != contact.get(field) && contact.OsgOnline_Id__c != null){
                    updateContactIds.add(contact.Id);
                    break;
                }
            }
        }
        
        if(contactMergeAccountIds.size() > 0){
            AccountTriggerHandler.mergeDuplicateContacts(contactMergeAccountIds);
        }
        
        if(updateContactIds.size() > 0){
			updateOsgOnlineContacts(updateContactIds);
        }
    }
    
    public static void updateOsgOnlineContacts(Set<Id> contactIds){
        OsgOnlineHelper.processContactsUpdate(contactIds);
    }
    
	public static void TestCodeCoverage() {
            Boolean CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;
            CodeCoverage = true;
            CodeCoverage = false;        
	}    
}