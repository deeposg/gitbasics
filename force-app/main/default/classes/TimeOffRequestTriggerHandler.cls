public with sharing class TimeOffRequestTriggerHandler extends TriggerHandler{
    public List<Time_Off_Request__c> timeOffReqs;  //List of TimeRequests
    
    public override void beforeInsert(){
        timeOffReqs = new List<Time_Off_Request__c>();
        for(Time_Off_Request__c tr : (List<Time_Off_Request__c>) Trigger.New){
            if(tr.Status__c != NULL && tr.Status__c == 'Approved') //filtring booked Quotes  
                timeOffReqs.add(tr);
        }
        if(timeOffReqs.size() > 0){
            TimeOffRequestTriggerHandler.createResorceAbsence(timeOffReqs);
        }
    }
    
    public override void beforeUpdate(){
        timeOffReqs = new List<Time_Off_Request__c>();
        for(Time_Off_Request__c tr : (List<Time_Off_Request__c>) Trigger.New){
            if(tr.Status__c != NULL && tr.Status__c == 'Approved') //filtring booked Quotes  
                timeOffReqs.add(tr);
        }
        if(timeOffReqs.size() > 0){
            TimeOffRequestTriggerHandler.createResorceAbsence(timeOffReqs);
        }
    }
    
    public Static void createResorceAbsence(List<Time_Off_Request__c> lstTimeOffReq){
    	List<ResourceAbsence> resourceAbsenceLst = new List<ResourceAbsence>();
    	Id recAbsRecTypeId = Schema.SObjectType.ResourceAbsence.RecordTypeInfosByName.get('Non Availability').RecordTypeId;
    	for(Time_Off_Request__c tr : lstTimeOffReq){
    		ResourceAbsence ra = new ResourceAbsence();
    		ra.RecordTypeId = recAbsRecTypeId;
    		ra.ResourceId = tr.Service_Resource__c;
    		ra.Start = tr.Start_Date_Time__c;
    		ra.End = tr.End_Date_Time__c;
    		ra.Type = tr.Type_of_Absence_Requested__c;
    		ra.Description = tr.Reason_for_Absence__c;
    		resourceAbsenceLst.add(ra);
    	}
    	if(resourceAbsenceLst.size() > 0){
    		insert resourceAbsenceLst;
    	}
    }
}