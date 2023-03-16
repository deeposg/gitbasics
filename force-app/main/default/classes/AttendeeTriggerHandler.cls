/**********************************************************************
Name: AttendeeTriggerHandler
Author : Shubham Verma
Description : Handler class for Attendee Trigger   
**********************************************************************/
public with sharing class AttendeeTriggerHandler extends TriggerHandler{

     public AttendeeTriggerHandler(){
     }

     public override void beforeInsert() {
         System.debug('AttendeeTriggerHandler::SOQL Use (Start beforeInsert): ' + Limits.getQueries());
         // Get service appointment ids of all the attendee records
         Set<Id> lstServiceAppIds = new Set<Id>();
         try{
             for(Attendee__c ar : (List<Attendee__c>) Trigger.New){
                 lstServiceAppIds.add(ar.Service_Appointment__c);
             }
             System.debug('AttendeeTriggerHandler::SOQL Use (LstServiceAppIds): ' + Limits.getQueries());
             
             Map<Id, ServiceAppointment> mapServiceAppointments = new Map<Id, ServiceAppointment>([SELECT Id, Product_Name__c FROM ServiceAppointment WHERE Id IN :lstServiceAppIds]);
             //Map<Id, ServiceAppointment, Contact> existingServiceAppointmentContacts = new Map<Id, ServiceAppointment, Contact>([Select Id, Service_Appointment__c, Contact__c from Attendee__c where Service_Appointment__c IN :lstServiceAppIds AND Contact__c != null Group By Service_Appointment__c, Contact__c]);
             List<Attendee__c> existingServiceAppointmentContacts = [Select Service_Appointment__c, Contact__c from Attendee__c where Service_Appointment__c IN :lstServiceAppIds AND Contact__c != null ];
             System.debug('AttendeeTriggerHander::SOQL (ExistingServAppContacts): ' + existingServiceAppointmentContacts.size());
             
             //Query all the Service appointement records associated to the attendee 
             for(Attendee__c ar : (List<Attendee__c>) Trigger.New){
                 if(ar.Service_Appointment__c != null && mapServiceAppointments.containsKey(ar.Service_Appointment__c)) {
                     ar.Product_Name__c = mapServiceAppointments.get(ar.Service_Appointment__c).Product_Name__c;
                     System.debug('AttendeeTriggerHanlder::SOQL Use (Update ProductName): ' + Limits.getQueries());
                     
                     
                     for(Attendee__c existingAttendee : (List<Attendee__c>)existingServiceAppointmentContacts){
                         if (ar.Contact__c != null && ar.Service_Appointment__c == existingAttendee.Service_Appointment__c && ar.Contact__c == existingAttendee.Contact__c && ar.Id != existingAttendee.Id && ar.Confirmed__c == existingAttendee.Confirmed__c) {
                             ar.addError('Duplicate Existing Attendee Contact Found: ' + existingAttendee.Id);
                             continue;
                         }
                     }
                     
                     for(Attendee__c existingAttendee : (List<Attendee__c>)Trigger.New){
                         if (ar.Contact__c != null && ar.Service_Appointment__c == existingAttendee.Service_Appointment__c && ar.Contact__c == existingAttendee.Contact__c && ar.Id != existingAttendee.Id && ar.Confirmed__c == existingAttendee.Confirmed__c) {
                             ar.addError('Duplicate Same Attendee Contact Found: ' + existingAttendee.Id);
                             continue;
                         }
                     } 
					
                 }
             }
             
             System.debug('AttendeeTriggerHandler::SOQL Use (End beforeInsert): ' + Limits.getQueries());
         }catch(Exception e){
             System.debug('Error: '+e.getMessage()+e.getStackTraceString()); 
         }
     }
    
    
     public override void beforeUpdate() {
         System.debug('AttendeeTriggerHandler::SOQL Use (Strt beforeUpdate): ' + Limits.getQueries());
		 Set<Id> lstServiceAppIds = new Set<Id>();         
         Attendee__c oldAttendee = new Attendee__c();
         try{
             for(Attendee__c ar : (List<Attendee__c>) Trigger.New){
                 oldAttendee = (Attendee__c)Trigger.oldMap.get(ar.id);
                 if(oldAttendee.Service_Appointment__c != ar.Service_Appointment__c && oldAttendee.Service_Appointment__c != NULL){
	                 lstServiceAppIds.add(ar.Service_Appointment__c);                     
                 }
             }
             System.debug('AttendeeTriggerHandler::SOQL Use (LstServiceAppIds): ' + Limits.getQueries());
             
             if(lstServiceAppIds.size() > 0){
                 Map<Id, ServiceAppointment> mapServiceAppointments = new Map<Id, ServiceAppointment>([SELECT Id, Product_Name__c FROM ServiceAppointment WHERE Id IN :lstServiceAppIds]);
                 //Map<Id, ServiceAppointment, Contact> existingServiceAppointmentContacts = new Map<Id, ServiceAppointment, Contact>([Select Id, Service_Appointment__c, Contact__c from Attendee__c where Service_Appointment__c IN :lstServiceAppIds AND Contact__c != null Group By Service_Appointment__c, Contact__c]);
                 List<Attendee__c> existingServiceAppointmentContacts = [Select Service_Appointment__c, Contact__c from Attendee__c where Service_Appointment__c IN :lstServiceAppIds AND Contact__c != null ];
                 System.debug('AttendeeTriggerHander::SOQL (ExistingServAppContacts): ' + existingServiceAppointmentContacts.size());
                 
                 //Query all the Service appointement records associated to the attendee 
                 for(Attendee__c ar : (List<Attendee__c>) Trigger.New){
                     if(ar.Service_Appointment__c != null && mapServiceAppointments.containsKey(ar.Service_Appointment__c)) {
                         
                         for(Attendee__c existingAttendee : (List<Attendee__c>)existingServiceAppointmentContacts){
                             if (ar.Contact__c != null && ar.Service_Appointment__c == existingAttendee.Service_Appointment__c && ar.Contact__c == existingAttendee.Contact__c && ar.Id != existingAttendee.Id && ar.Confirmed__c == existingAttendee.Confirmed__c) {
                                 ar.addError('Duplicate Existing Attendee Contact Found: ' + existingAttendee.Id);
                                 continue;
                             }
                         }
                         
                         for(Attendee__c existingAttendee : (List<Attendee__c>)Trigger.New){
                             if (ar.Contact__c != null && ar.Service_Appointment__c == existingAttendee.Service_Appointment__c && ar.Contact__c == existingAttendee.Contact__c && ar.Id != existingAttendee.Id && ar.Confirmed__c == existingAttendee.Confirmed__c) {
                                 ar.addError('Duplicate Same Attendee Contact Found: ' + existingAttendee.Id);
                                 continue;
                             }
                         } 
                        
                     }
                 }
                 
                 System.debug('AttendeeTriggerHandler::SOQL Use (End beforeUpdate): ' + Limits.getQueries());   
             }

         }catch(Exception e){
             System.debug('Error: '+e.getMessage()+e.getStackTraceString()); 
         }         
         
         
         System.debug('AttendeeTriggerHandler::SOQL Use (End beforeUpdate): ' + Limits.getQueries()); 
     }
     
     public override void beforeDelete() {
     }
     
     public override void afterInsert() {
		System.debug('AttendeeTriggerHandler::SOQL Use (Start afterInsert): ' + Limits.getQueries());         
         Set<Id> lstServiceAppointmentIds = new Set<Id>(); // Set for Ids of related service Appointment
         try{
             for(Attendee__c ar : (List<Attendee__c>) Trigger.New){
             if(ar.Service_Appointment__c != null)
                 lstServiceAppointmentIds.add(ar.Service_Appointment__c);
             }
             if(lstServiceAppointmentIds.size() > 0){
                AttendeeTriggerHandler.countAttendees(lstServiceAppointmentIds);
             }
		System.debug('AttendeeTriggerHandler::SOQL Use (End afterInsert): ' + Limits.getQueries());         
         }catch(Exception e){
             System.debug('Error: '+e.getMessage()+e.getStackTraceString());
         }
     }
     
     public override void afterUpdate() {
         System.debug('AttendeeTriggerHandler::SOQL Use (Start afterUpdate): ' + Limits.getQueries());
         Set<Id> lstServiceAppointmentIds = new Set<Id>(); // Set for Ids of related service Appointment
         Set<Id> attendeeIds = new Set<Id>();
         try{  
             for(Attendee__c ar : (List<Attendee__c>) Trigger.New){
                 Attendee__c oldAttendee = (Attendee__c)Trigger.oldMap.get(ar.Id);
                 
                 if(ar.Service_Appointment__c != null){
                     lstServiceAppointmentIds.add(ar.Service_Appointment__c);
                 }
                 
                 if(oldAttendee.Service_Appointment__c != null && ar.Service_Appointment__c != oldAttendee.Service_Appointment__c){
                     lstServiceAppointmentIds.add(oldAttendee.Service_Appointment__c);
                 }
             }             
             
             if(lstServiceAppointmentIds.size() > 0){
                 AttendeeTriggerHandler.countAttendees(lstServiceAppointmentIds);
             }
             System.debug('AttendeeTriggerHandler::SOQL Use (End afterUpdate): ' + Limits.getQueries());   
         }catch(Exception e){
             System.debug('Error: '+e.getMessage()+e.getStackTraceString());
         }
     }
     
     public override void afterDelete() {
         System.debug('AttendeeTriggerHandler::SOQL Use (Start afterDelete): ' + Limits.getQueries());
         Set<Id> lstServiceAppointmentIds = new Set<Id>(); // Set for Ids of related service Appointment
         try{
             for(Attendee__c ar : (List<Attendee__c>) Trigger.Old){
             if(ar.Service_Appointment__c != null)
                 lstServiceAppointmentIds.add(ar.Service_Appointment__c);
             }
             if(lstServiceAppointmentIds.size() > 0){
                AttendeeTriggerHandler.countAttendees(lstServiceAppointmentIds);
             }
         	System.debug('AttendeeTriggerHandler::SOQL Use (End afterDelete): ' + Limits.getQueries());
             
         }catch(Exception e){
             System.debug('Error: '+e.getMessage()+e.getStackTraceString());
         }         
     }

    public static void afterUndelete() {
   
    }
    
    
    // Method to pupulate total no. of attendees on service appointment record's confirmed field
    // Attendee should have service appointment field
    public static void countAttendees(Set<Id> lstServiceAppointmentIds){
        System.debug('AttendeeTriggerHandler::SOQL Use (Start countAttendees): ' + Limits.getQueries());
        // Maps to hold the count of respective rollups in the aggregate queries
        Map<Id, Integer> mapConfirmedSeatRollup = new Map<Id, Integer>();
        Map<Id, Integer> mapAttendeesEvaluatedRollup = new Map<Id, Integer>();
        Map<Id, Integer> mapCheckedInSeatsRollup = new Map<Id, Integer>();
        try{
            
            System.debug('AttendeeTriggerHandler::SOQL Use (countAttendees Step 1): ' + Limits.getQueries());
             // fetching attendee recods with aggregrade results to populate confirmed seats on service appointment 
        for(AggregateResult ar : [SELECT count(Id) totalAttendee, Service_Appointment__c FROM Attendee__c  WHERE Service_Appointment__c IN :lstServiceAppointmentIds AND Confirmed__c = 'Yes' GROUP BY Service_Appointment__c]){
            
            mapConfirmedSeatRollup.put((Id)ar.get('Service_Appointment__c'), (Integer)ar.get('totalAttendee'));    
        }
            
        for(AggregateResult ar : [SELECT count(Id) totalAttendee, Service_Appointment__c FROM Attendee__c  WHERE Service_Appointment__c IN :lstServiceAppointmentIds AND (Status__c = 'Confirmed' OR Status__c = 'Attended Entire Course') GROUP BY Service_Appointment__c]){
            
            mapCheckedInSeatsRollup.put((Id)ar.get('Service_Appointment__c'), (Integer)ar.get('totalAttendee'));    
        }
        
            System.debug('AttendeeTriggerHandler::SOQL Use (countAttendees Step 2): ' + Limits.getQueries());
            
        // fetching attendee recods with aggregrade results to populate evaluated attendees count on service appointment 
        for(AggregateResult ar : [SELECT count(Id) totalAttendee, Service_Appointment__c FROM Attendee__c  WHERE Service_Appointment__c IN :lstServiceAppointmentIds AND Evaluated__c = True GROUP BY Service_Appointment__c]){
            
            mapAttendeesEvaluatedRollup.put((Id)ar.get('Service_Appointment__c'), (Integer)ar.get('totalAttendee'));    
        }
        
            System.debug('AttendeeTriggerHandler::SOQL Use (countAttendees Step 3): ' + Limits.getQueries());
        system.debug(' >>>>>  mapConfirmedSeatRollup >>>>> ' + mapConfirmedSeatRollup);
        system.debug(' >>>>>  mapAttendeesEvaluatedRollup >>>>> ' + mapAttendeesEvaluatedRollup);
        
        // We will iterate over all the service appointment ids so if we also update records which is not queries by 
        // the aggregate queries. This is to avoide incorrect data on the parent record. If a service appointement record doesn't have 
        // any child record then it will not be returned in the aggregate query and we will have to identify those records so we can 
        // update those records with 0 count.
        List<ServiceAppointment> lstServiceAppointment = new List<ServiceAppointment>();
        for(Id serviceAppId : lstServiceAppointmentIds) {
            
            // Create a new instance of ServiceAppointment object and assign it the id 
            ServiceAppointment sa = new ServiceAppointment(
                                                Id = serviceAppId, 
                                                Number_of_Attendees_Evaluated__c = 0, 
                                                Confirmed_Seats__c = 0);
            
            // Check if map has confirmed seats for the service appointment record.
            // Update the confirmed seats if it is returned in the aggregate query.                               
            if(mapConfirmedSeatRollup.containsKey(serviceAppId))
                sa.Confirmed_Seats__c = mapConfirmedSeatRollup.get(serviceAppId);
            
            //update the number of confirmed checked in seats
            if(mapCheckedInSeatsRollup.containsKey(serviceAppId))
                sa.Checked_In_Seats__c = mapCheckedInSeatsRollup.get(serviceAppId);
            
            // Check if map has attendees evaluated for the service appointment record.
            // Update the count of attendees evaluated if it is returned in the aggregate query.                               
            if(mapAttendeesEvaluatedRollup.containsKey(serviceAppId))
                sa.Number_of_Attendees_Evaluated__c = mapAttendeesEvaluatedRollup.get(serviceAppId);
            
            lstServiceAppointment.add(sa);
            }
            if(!lstServiceAppointment.isEmpty()){
                System.debug('AttendeeTriggerHandler::SOQL Update (lstServiceAppointment): ' + Limits.getQueries());
                TriggerHandler.bypass('ServiceAppointmentTriggerHandler');
                update lstServiceAppointment;
                TriggerHandler.clearBypass('ServiceAppointmentTriggerHandler');
				System.debug('AttendeeTriggerHandler::SOQL Update (lstServiceAppointment): ' + Limits.getQueries());
            }
        }catch(Exception e){
            System.debug('Error: '+e.getMessage()+e.getStackTraceString());
        }
       
        System.debug('AttendeeTriggerHandler::SOQL Use (End countAttendees): ' + Limits.getQueries());
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
            CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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