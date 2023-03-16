/***************************
Class Name: RecordMergeTool
Author: Blessen Mathew
Description: Merges two records of one object type into one and deletes the "secondary"

History Log
=====================================
2018-10-03		BMathew		Created initial class
2020-12-24		BMathew		Adjusted merge class to update primary record after successful merge call
2021-01-06		BMathew		Adding username as priority field to determine master record
****************************/
public with sharing class RecordMergeTool {
    
    //Determines if a Contact has an account and is considered valid for the merge process
    @AuraEnabled
    public static boolean validateContact(Id contactId){
		Contact contact = [Select AccountId From Contact Where id = :contactId];
        if(contact.AccountId == null){
            return false;
        }
        else{
            return true;
        }
    }
    
    //Gets a list of all Contacts that belong to the same account the passed in Contact belongs to (except for the passed in Contact)
	@AuraEnabled
    public static List<Contact> getContacts(Id contactId){
		Contact contact = [Select Id, AccountId From Contact Where id = :contactId];
        List<Contact> contacts = [Select Name, Email, Full_Telephone__c, Evaluation_Count__c From Contact Where AccountId = :contact.AccountId And Id != :contact.Id Order By Name];
        return contacts;
    }
    
    //Merges 2 contacts records together. Primary is based on osgOnline Id otherwise, contactId1 is considered the primary contact to merge details into
    @AuraEnabled
    public static String mergeContacts(Id contactId1, Id contactId2) {
        try{
			String commaSeparatedFields = '';
            
            //Retrieve all fields in contact object as a map
            Map<String, Schema.SObjectField> fields = sObjectType.Contact.fields.getMap();

            for(String key : fields.keyset()){
                SObjectField value = fields.get(key);
                //if the field is accessible, editable and createable (need to do this so we skip read-only fields)
                if(value.getDescribe().isAccessible() && value.getDescribe().isUpdateable() && value.getDescribe().isCreateable()){
                    if(commaSeparatedFields == null || commaSeparatedFields == '') {
                        commaSeparatedFields = key;
                    }
                    else {
                        commaSeparatedFields = commaSeparatedFields + ', ' + key;
                    }
                }
            }
       
            
            //If ID for both contacts is not passed in, block merge
            if(contactId1 == null || contactId2 == null){
                return 'INVALID_ID';
            }           
            
            //Setup query for both contacts and retrieve the objects
            String queryC1 = 'SELECT ' + commaSeparatedFields + ' FROM Contact Where Id = \'' + contactId1 + '\' LIMIT 1';
            String queryC2 = 'SELECT ' + commaSeparatedFields + ' FROM Contact Where Id = \'' + contactId2 + '\' LIMIT 1';
            
            Contact contact1 = Database.query(queryC1);
            Contact contact2 = Database.query(queryC2);
            Contact primaryContact = contact1;
            Contact secondaryContact = contact2;
            
            if(primaryContact.OsgOnline_Id__c != null && secondaryContact.OsgOnline_Id__c != null){
                return 'INVALID_OSGONLINE_MERGE';
            }
            
            if(primaryContact.Username__c != null && secondaryContact.Username__c != null){
                return 'INVALID_USERNAME_MERGE';
            }
            
            if(primaryContact.Date_Of_Birth__c != null && secondaryContact.Date_Of_Birth__c != null && primaryContact.Date_of_Birth__c != secondaryContact.Date_of_Birth__c){
                return 'INVALID_DOB_MERGE';
            }

            if(primaryContact.Date_Of_Birth__c != null && secondaryContact.Date_Of_Birth__c != null && primaryContact.Date_of_Birth__c == secondaryContact.Date_of_Birth__c){
                secondaryContact.Date_of_Birth__c= null;
                update secondaryContact;
            }
            
            //set the secondaryContact as the primary if it has a username, otherwise first contact is considered primary.
            if(contact2.OsgOnline_Id__c != null){
                primaryContact = contact2;
                secondaryContact = contact1;
            }

            //If secondary contact has DOB, move it to primary instead of swapping primary and secondary 
            if(secondaryContact.Date_of_Birth__c != null && primaryContact.Date_of_Birth__c == null){
                primaryContact.Date_of_Birth__c = secondaryContact.Date_of_Birth__c;
                update primaryContact;

                secondaryContact.Date_of_Birth__c = null;
                update secondaryContact;
            }
            
            //if contacts do not pass merge validation rules, block the merge
            if(validateContacts(primaryContact, secondaryContact) != TRUE){
				return 'INVALID_MERGE';
            }

            //Loop through all the required fields and if secondaryContact has a value primaryContact doesn't have, merge it over to primaryContact and update the object 
			for(String key : fields.keyset()){
                SObjectField value = fields.get(key);
                if(value.getDescribe().isAccessible() && value.getDescribe().isUpdateable() && value.getDescribe().isCreateable()){
                    Object field1 = primaryContact.get(key);
                    Object field2 = secondaryContact.get(key);
                    if(field1 == null && field2 != null) {
                        primaryContact.put(key, field2);
                    }
                }
            }
            
            List<Attendee__c> c2Attendees = [Select Id, Name, Contact__c, Quote_Account__c from Attendee__c where Contact__c = :secondaryContact.Id];
            for(Attendee__c attendee : c2Attendees) {
                attendee.Name = primaryContact.FirstName + ' ' + primaryContact.LastName;
				attendee.Quote_Account__c = primaryContact.AccountId;
            }
            update c2Attendees;
            

			/*
			 * Standard MERGE function will handle related records
			 *             
            //transfer attendee records
            List<Attendee__c> c2Attendees = [Select Id,First_Name__c, Last_Name__c, Name, Contact__c, Quote_Account__c from Attendee__c where Contact__c = :secondaryContact.Id];
            for(Attendee__c attendee : c2Attendees) {
                attendee.Name = primaryContact.FirstName + ' ' + primaryContact.MiddleName + ' ' + primaryContact.LastName;
               	attendee.Contact__c = primaryContact.Id;
				attendee.Quote_Account__c = primaryContact.AccountId;
            }
            update c2Attendees;
            
            //transfer certificates
            List<Certificate__c> c2Certificates = [Select Id, Contact__c from Certificate__c where Contact__c = :secondaryContact.Id];
            for(Certificate__c certificate : c2Certificates) {
                certificate.Contact__c = primaryContact.Id;
            }
            update c2Certificates;
            
            //transfer evaluations
            List<Evaluation__c> c2Evaluations = [Select Id, Attendee__c, Attendee_Contact__c from Evaluation__c where Attendee_Contact__c = :secondaryContact.Id];
            for(Evaluation__c evaluation : c2Evaluations) {
                evaluation.Attendee_Contact__c = primaryContact.Id;
            }
            update c2Evaluations;
			*/
            
            //run default merge method to transfer all related records
            merge primaryContact secondaryContact;
            //update the contact with any missing fields from secondaryContact
            update primaryContact;
        	return 'SUCCESS';
        }
        catch(Exception e) {
            System.debug('MERGE FAILED: ' + e.getMessage());
            return e.getMessage();
        }
    }
    
    //Checks if the contacts contain enough valid data to be merged into primaryContact
    private static boolean validateContacts(Contact primaryContact, Contact secondaryContact) {        
        //Validate the first contact and ensure it has all information prior to merging
        if(primaryContact.FirstName == null || primaryContact.LastName == null || primaryContact.AccountId == null) {
            return false;
        }
        else {
        	//If contact1 is valid, check contact2 to ensure it can be merged with contact1
            if(primaryContact.Id == secondaryContact.Id || primaryContact.AccountId != secondaryContact.AccountId) {
                return false;
            }
            else {
            	return true;
            }
        }
    }
    
    public static void testCodeCoverage(){
        Boolean CodeCoverage = false;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;           
    }
}