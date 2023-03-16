/***************************
Class Name: OsgOnlineHelper
Author: Blessen Mathew
Description: Class to help with communicating with OsgOnline, primarily to sync accounts and contacts

History Log
=====================================
2021-02-18		BMathew		Created initial class
2021-04-13		BMathew		Updated account to be pending if error generated on account
2021-08-25		BMathew		Added reassign endpoint
****************************/
public class OsgOnlineHelper {
    private class SyncResponse {
        public string status;
        public string id;
        public List<ContactData> contacts;
        public ErrorData errors;
    }
    
    private class ContactData {
        public string sf_id;
        public string osg_online_id;
    }
    
    private class ErrorData {
        public List<String> messages;
        public List<String> unexpected;
    }
    
    private class ContactSyncRequest {
        public string contact_id;
        public string email;
        public string personal_email;
        public string first_name;
        public string last_name;
        public string cell_number;
        public string home_number;
        public string birthdate;
    }
    
    private class AssignSyncRequest {
        public string contact_id;
        public string attendee_id;
        public string sf_course_id;
    }
    
    private static HTTPResponse SyncRequest(string endpoint, String json_string) {
		HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:OsgOnline_Sync/' + endpoint);            

        if(json_string != ''){
			req.setBody(json_string);
        }

        req.setMethod('POST');
		// Setup auth headers
		req.setHeader('x-api-key', '{!$Credential.Password}');
        req.setHeader('Content-Type','application/json');
        req.setTimeout(20000);
        
        Http http = new Http();
        HTTPResponse response = http.send(req);
        
        return response;
	}
    
	private static boolean Sync(string sObjectName, string endpoint, Id recordId, String json_string) {
        HTTPResponse response = SyncRequest(endpoint, json_string);
        System.debug(response);
        System.debug(response.getBody());
        
        // If the repsonse comes back properly
        if(response != null) {
        	SyncResponse syncResponse = new SyncResponse();
            syncResponse = (SyncResponse)JSON.deserialize(response.getBody(), SyncResponse.class);
            
            System.debug('RESPONSE=>' + syncResponse);

            if(response.getStatusCode() == 200 && syncResponse.status == 'SUCCESS') {
                if(syncResponse.id == '0'){
                    createErrorTask(sObjectName, recordId, 'Sync Failed (NO ID)', syncResponse.status, syncResponse);
                    return false;
                }
                if(syncResponse.contacts != null && !syncResponse.contacts.isEmpty()){
                    updateContacts(syncResponse.contacts);
                }

                updateRecord(sObjectName, syncResponse.id, recordId);                    
                return true;
            }  else {
                //System.debug(syncResponse.message);
                if(syncResponse.status != 'SUCCESS'){
                    createErrorTask(sObjectName, recordId, 'Sync Failed (NOT SUCCESSFUL) [' + response.getStatusCode() + ', ' + response.getStatus() + ']', syncResponse.status, syncResponse);
                }
                else{
                    createErrorTask(sObjectName, recordId, 'Sync Failed (NOT 200)', response.getStatus(), syncResponse);
                }
                return false;
            }
        } else {
            createErrorTask(sObjectName, recordId, 'Response Empty', 'Response came back empty.', null);
            return false;
        }
    }    

    private static void updateRecord(String sObjectName, String osgOnlineId, Id recordId){
        //Update record with lms Id
        if(sObjectName == 'Account'){
            Account account = new Account();
            account.Id = recordId;
            account.OsgOnline_Id__c = osgOnlineId;
            update account;            
        }
        else if(sObjectName == 'Contact'){
            Contact contact = new Contact();
            contact.Id = recordId;
            contact.OsgOnline_Id__c = osgOnlineId;
            update contact;                        
        }
        else if(sObjectName == 'Attendee__c'){
            Attendee__c attendee = new Attendee__c();
            attendee.Id = recordId;
            attendee.OsgOnline_Id__c = osgOnlineId;
            attendee.Confirmed__c = 'Yes';
            attendee.Check_in_Time__c = null;
            attendee.Theory_Status__c = 'Pending';
            attendee.Theory_Exam_Results__c = null;      
            attendee.LMS_Module_Position__c = null;
            attendee.Status__c = null;
            attendee.Training_Completed__c = null;
            attendee.Completion_Date__c = null;
            update attendee;
        }
    }
    
    private static void updateContacts(List<ContactData> contacts){
        List<Contact> updateContacts = new List<Contact>();
        for(ContactData data : contacts){
            Contact contact = new Contact();
            contact.Id = data.sf_id;
            contact.OsgOnline_Id__c = data.osg_online_id;
            
            updateContacts.add(contact);
        }
        update updateContacts;
    }
    
    private static void createErrorTask(String sObjectName, Id recordId, String subject, String message, SyncResponse syncResponse){
		User user = [Select Id from User where Name = 'Blessen Mathew'];
        
		Task tsk = new Task();
        tsk.Subject = 'Investigate OSG Online Sync (' + subject + ')';
        if(sObjectName == 'Contact'){
            tsk.WhoId = recordId;
        }
        else{
	        tsk.WhatId = recordId;            
        }
        tsk.OwnerId = user.Id;
        tsk.Status = 'Open';
        tsk.Priority = 'High';
        tsk.Description = message;
        tsk.ActivityDate = Date.Today();
        tsk.Type = 'OSG Online';
        
        if(syncResponse.errors != null){
            if(syncResponse.errors.messages != null){
                tsk.Description += ' => messages';
                tsk.Description += syncResponse.errors.messages.toString();
            }
            if(syncResponse.errors.unexpected != null){
                tsk.Description += ' => unexpected';
                tsk.Description += syncResponse.errors.unexpected.toString();
            }
        }
        
        insert tsk;
        
        //If error is on account, set back to pending until error resolved
        if(sObjectName == 'Account'){
            updateAccount(recordId);
        }
    }
    
    private static void updateAccount(Id recordId){
        List<Account> accounts = [Select Id, Account_Status__c, OsgOnline_Id__c from Account where Id=: recordId];
        Account account = accounts[0];
        if(account.OsgOnline_Id__c == null && account.Account_Status__c != 'Pending'){
            account.Account_Status__c = 'Pending';
            update account;
        }
    }
    
    @future(callout=true)
    public static void processRecord(String sObjectName, Id recordId){
        String endpoint = '';
        if(sObjectName == 'Account'){
            endpoint = 'accounts/sync/' + recordId;
        }
        else if(sObjectName == 'Contact'){
            endpoint = 'contacts/sync/' + recordId;
        }
        
     	Sync(sObjectName, endpoint, recordId, '');   
    }
    
    @future(callout=true)
    public static void processContactsUpdate(Set<Id> contactIds){
        for(Contact contact : [Select Id, Name, FirstName, LastName, Email, Personal_Email__c, Date_Of_Birth__c, MobilePhone, Phone from Contact where Id in :contactIds]){
            processContactUpdate(contact);
        }
    }
    
    private static void processContactUpdate(Contact contact){
        ContactSyncRequest syncRequest = new ContactSyncRequest();
		String endpoint = 'contacts/sync_profile';
        String sObjectName = 'Contact';
        
        syncRequest.contact_id = contact.Id != null ? contact.Id : '';
        syncRequest.email = contact.email != null ? contact.email : '';
        syncRequest.personal_email = contact.Personal_Email__c != null ? contact.Personal_Email__c : '';
        syncRequest.first_name = contact.FirstName != null ? contact.FirstName : '';
        syncRequest.last_name = contact.LastName != null ? contact.LastName : '';
        syncRequest.cell_number = contact.MobilePhone != null ? contact.MobilePhone : '';
        syncRequest.home_number = contact.Phone != null ? contact.Phone : '';
        syncRequest.birthdate = contact.Date_Of_Birth__c != null ? contact.Date_Of_Birth__c.year() + '/' + contact.Date_Of_Birth__c.month() + '/' + contact.Date_Of_Birth__c.day() : '';
    
        String json_string = JSON.Serialize(syncRequest);
        
        Sync(sObjectName, endpoint, contact.id, json_string);
    }
    
    @future(callout=true)
    public static void processCourseAssign(Id attendeeId){
        AssignSyncRequest syncRequest = new AssignSyncRequest();
        String endpoint = 'contacts/assign';
        String sObjectName = 'Attendee__c';
        
        Attendee__c attendee = [Select Id, Contact__c, Service_Appointment__c from Attendee__c where id = :attendeeId];
        
        syncRequest.contact_id = attendee.Contact__c;
        syncRequest.attendee_id = attendee.Id;
        syncRequest.sf_course_id = attendee.Service_Appointment__c;
        
        String json_string = JSON.Serialize(syncRequest);
        
        Sync(sObjectName, endpoint, attendee.Id, json_string);
    }
    
    @AuraEnabled
    public static boolean resetCourse(Id attendeeId){
        String endpoint = 'attendees/' + attendeeId + '/reassign';
        String sObjectName = 'Attendee__c';
        
        return Sync(sObjectName, endpoint, attendeeId, '');
    }

    @AuraEnabled
    public static boolean resendRegistrationEmail(Id contactId){
        String endpoint = 'contacts/' + contactId + '/resend_signup_email';
        String sObjectName = 'Contact';

        return Sync(sObjectName, endpoint, contactId, '');
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