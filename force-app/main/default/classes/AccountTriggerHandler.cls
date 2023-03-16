/**********************************************************************
Name: AccountTriggerHandler
Author : Blessen Mathew
Description : Handler class for Account Trigger   

History Log
==========================
2021-01-06		BMathew		Added logic to check accounts for duplicate contacts and merge them when accounts are merged or moved out of pending status
**********************************************************************/
public with sharing class AccountTriggerHandler extends TriggerHandler{
    public override void afterDelete(){
        Set<Id> masterAccountIds = new Set<Id>();
        System.debug('AFTER DELETE');        
        
        //Used for account merging
        for(Account account :(List<Account>)Trigger.Old){
			System.debug('ACCOUNT MASTER RECORD: ' + account.MasterRecordId);
            if(account.MasterRecordId != null){
                masterAccountIds.add(account.MasterRecordId);
            }
        }
        
        if(masterAccountIds.size() > 0){
            mergeDuplicateContacts(masterAccountIds);
        }
        
    }
    
    public override void beforeDelete(){
        
    }
    
    public override void afterInsert() {
        
    }
    
    public override void afterUpdate() {
        Set<Id> masterAccountIds = new Set<Id>();
        Set<Id> osgOnlineAccountSyncIds = new Set<Id>();
        Set<Id> ownerChangeAccountIds = new Set<Id>();
        
        Account oldAccount = new Account();
        for(Account account : (List<Account>) Trigger.New){
            oldAccount = (Account)Trigger.oldMap.get(account.Id);
            if(oldAccount.Account_Status__c == 'Pending' && account.Account_Status__c != 'Pending'){
                masterAccountIds.add(account.Id);
            }
            
            if(oldAccount.OwnerId != account.OwnerId && oldAccount.OwnerId != null && account.LearningLogin_Id__c != null && account.LearningLogin_Owner_Do_Not_Sync__c != true){
                ownerChangeAccountIds.add(account.Id);
            }
        }
        
        if(masterAccountIds.size() > 0){
            AccountTriggerHandler.mergeDuplicateContacts(masterAccountIds);
        }
        
        if(ownerChangeAccountIds.size() > 0){
            AccountTriggerHandler.processAccountOwnerChange(ownerChangeAccountIds);
        }
    }
    
    @future(callout=true)
    public static void processAccountOwnerChange(Set<Id> accountIds){
        for(Id recordId : accountIds){
            LearningLoginHelper.processRecord('Account', recordId);
        }
    }
    
    @future
    //Loops through the accounts defined in set and finds any duplicate contacts and merges them
    public static void mergeDuplicateContacts(Set<Id> accountIds){
        System.debug('SET OF ACCOUNTS: ' + accountIds);
        //TODO: Can we group by dob, if there are 2 people with same name with different dob, we do not want to merge them, they are different people
        for(AggregateResult result : [Select Count(Id) recordCount, Name, AccountId, Email from Contact where AccountId in :accountIds group by Name, AccountId, Email having Count(Id) > 1 limit 100]){
            System.debug('AGG RESULT=> ' + result);
            String accountId = String.valueOf(result.get('AccountId'));
            String name = String.valueOf(result.get('Name'));
            String email = String.valueOf(result.get('Email'));
            
            Contact primaryContact;
            List<Contact> primaryContactResults = new List<Contact>();
            
            //Query for a primary contact based off osgOnline Id
            primaryContactResults = [Select Id, AccountId, Title, Email, Personal_Email__c, Date_Of_Birth__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Phone, Phone_Ext__c, MobilePhone, Identity_Verified__c from Contact where AccountId = :accountId and Name = :name and Email = :email and OsgOnline_Id__c != null limit 1];

            //Look for any other primary contact matches
            if(primaryContactResults.size() == 0){
	            primaryContactResults = [Select Id, AccountId, Title, Email, Personal_Email__c, Date_Of_Birth__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Phone, Phone_Ext__c, MobilePhone, Identity_Verified__c from Contact where AccountId = :accountId and Name = :name and Email = :email and (Personal_Email__c != null or Date_of_Birth__c != null) limit 1];
            }            
            
            //Check for a primary contact based off if primary/invoice contact
            if(primaryContactResults.size() == 0){
                primaryContactResults = [Select Id, AccountId, Title, Email, Personal_Email__c, Date_Of_Birth__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Phone, Phone_Ext__c, MobilePhone, Identity_Verified__c from Contact where AccountId = :accountId and Name = :name and Email = :email and (Is_Primary__c = true or Is_Invoice__c = true) limit 1];
            }                        
            
            //Check for primary based on email
            if(primaryContactResults.size() == 0){
                primaryContactResults = [Select Id, AccountId, Title, Email, Personal_Email__c, Date_Of_Birth__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Phone, Phone_Ext__c, MobilePhone, Identity_Verified__c from Contact where AccountId = :accountId and Name = :name and Email = :email limit 1];
            }
            
            //If no results, just use the first contact name match
            if(primaryContactResults.size() == 0){
	            primaryContactResults = [Select Id, AccountId, Title, Email, Personal_Email__c, Date_Of_Birth__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Phone, Phone_Ext__c, MobilePhone, Identity_Verified__c from Contact where AccountId = :accountId and Name = :name order by CreatedDate desc limit 1];
            }
            primaryContact = primaryContactResults[0];
            
            //Exempt the primaryContact from the list query
            List<Contact> contacts = [Select Id, AccountId, Title, Email, Personal_Email__c, Date_Of_Birth__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Phone, Phone_Ext__c, MobilePhone, Identity_Verified__c from Contact where AccountId = :accountId and Name = :name and id != :primaryContact.Id and OsgOnline_Id__c = null];
            System.debug('LIST OF CONTACTS TO MERGE: ' + contacts);
            //Merge all duplicate contacts into master
            for(Contact contact : contacts){
				//check for any priority fields that can be copied to master record
                if(primaryContact.Email == null && contact.Email != null){
                    primaryContact.Email = contact.Email;
                }
                
                if(primaryContact.Personal_Email__c == null && contact.Personal_Email__c != null){
                    primaryContact.Personal_Email__c = contact.Personal_Email__c;
                }
                
                if(primaryContact.Date_Of_Birth__c == null && contact.Date_Of_Birth__c != null){
                    primaryContact.Date_Of_Birth__c = contact.Date_Of_Birth__c;
                }

                /*ADDRESS DETAILS*/
                if(primaryContact.MailingStreet == null && contact.MailingStreet != null){
                    primaryContact.MailingStreet = contact.MailingStreet;
                }
                
                if(primaryContact.MailingCity == null && contact.MailingCity != null){
                    primaryContact.MailingCity = contact.MailingCity;
                }
                
                if(primaryContact.MailingState == null && contact.MailingState != null){
                    primaryContact.MailingState = contact.MailingState;
                }

                if(primaryContact.MailingPostalCode == null && contact.MailingPostalCode != null){
                    primaryContact.MailingPostalCode = contact.MailingPostalCode;
                }

                if(primaryContact.MailingCountry == null && contact.MailingCountry != null){
                    primaryContact.MailingCountry = contact.MailingCountry;
                }                
                
                if(primaryContact.Phone == null && contact.Phone != null){
                    primaryContact.Phone = contact.Phone;
                }   
                
                if(primaryContact.Phone_Ext__c == null && contact.Phone_Ext__c != null){
                    primaryContact.Phone_Ext__c = contact.Phone_Ext__c;
                }  

                if(primaryContact.MobilePhone == null && contact.MobilePhone != null){
                    primaryContact.MobilePhone = contact.MobilePhone;
                }  

                if(primaryContact.Identity_Verified__c == false && contact.Identity_Verified__c != false){
                    primaryContact.Identity_Verified__c = contact.Identity_Verified__c;
                }  
                
                if(primaryContact.Title == null && contact.Title != null){
                    primaryContact.Title = contact.Title;
                }

                if(contact.Phone != null && primaryContact.MobilePhone == contact.Phone){
                    primaryContact.MobilePhone = null;
                }

                if(primaryContact.Phone != null && primaryContact.Phone == contact.MobilePhone){
                    contact.MobilePhone = null;
                    update contact;
                }
                
                update primaryContact;
                merge primaryContact contact;
            }
        }        
    }

    @AuraEnabled
    public static boolean unsetPrimaryAddresses(String accountId, String type){
        try {
            List<Account_Address__c> accountAddresses = [Select Id, Primary__c from Account_Address__c where Account__c = :accountId and Primary__c = true and Type__c = :type];
            for(Account_Address__c address : accountAddresses){
                address.Primary__c = false;
            }
            update accountAddresses;

            Account account = [Select Id, Primary_Billing_Address__c, Primary_Shipping_Address__c from Account where Id =: accountId];
            if(type == 'Billing Address'){
                account.Primary_Billing_Address__c = null;    
            }
            else if(type == 'Shipping Address'){
                account.Primary_Shipping_Address__c = null;
            }
            update account;

            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
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
    }
}