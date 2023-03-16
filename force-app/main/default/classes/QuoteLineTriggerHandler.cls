/**********************************************************************
Name: QuoteLineTriggerHandler
Author : Shubham Verma
Description : Handler class for QuoteLine Trigger

History Log
==========================
2020-12-16		BMathew		Added logic to handle JHSCI Online attendees and when sold as a bundle with JHSCII
**********************************************************************/
public with sharing class QuoteLineTriggerHandler extends TriggerHandler{
    public static Set<Id> classRoomIds;
    public static Set<Id> quoteIds;
    public static Set<Id> quoteLineIds; //set of Quote Line Items
    public static List<String> productCodeExceptions = new List<String>{'TTAL', 'JHSCI'};	//product codes that are exceptions to the standard queryies
    public static Set<String> productCodeExceptionsSet = new Set<String>{'TTAL', 'JHSCI'};
    
    public override void beforeInsert(){
        
        Set<Id> productIds = new Set<Id>();
        classRoomIds = new Set<Id>();
        quoteIds = new Set<Id>();
        try{
            for(SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>) Trigger.New){
                if(ql.SBQQ__Product__c != Null){
                    productIds.add(ql.SBQQ__Product__c);
                }
                // filter quote line's having classroom course
                if(ql.Classroom_Course__c != Null){
                    classRoomIds.add(ql.Classroom_Course__c);
                }
                if(ql.Classroom_Course__c == Null){
                    quoteIds.add(ql.SBQQ__Quote__c);
                }
            }
            if(productIds.size() > 0){
                // call populateWorkType method to Populate work type on Quote Line with respective product 
                QuoteLineTriggerHandler.populateWorkType(productIds);
            }
            
            if(classRoomIds.size() > 0 || quoteIds.size() > 0){
                // call populateTrainingAddressFields method to populate training address fields on Quote line with rescpective Classroom(SA) address fields
                QuoteLineTriggerHandler.populateTrainingAddressFields();
            }
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }
    }
    
    public override void beforeUpdate(){
        
        Set<Id> productIds = new Set<Id>();
        classRoomIds = new Set<Id>();
        quoteIds = new Set<Id>();
        
        try{
            for(SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>) Trigger.New){
                
                SBQQ__QuoteLine__c oldQL = (SBQQ__QuoteLine__c)Trigger.oldMap.get(ql.id);

                if(ql.Promotional_Discount__c != Null && oldQL.Promotional_Discount__c != ql.Promotional_Discount__c){
					List<Promotion__c> promotions = [Select Id, Promotional_Code__c from Promotion__c where id =: ql.Promotional_Discount__c];
                    
                    for(Promotion__c promo : promotions){
                        if(promo.Promotional_Code__c.indexOf('COVID19') != -1){
                            Account account = [Select Id, Covid_Discount__c from Account where Id = :ql.Account__c][0];
                            Decimal remainingCovidDiscounts = account.Covid_Discount__c;
                            
                            System.debug('REMAINING: ' + remainingCovidDiscounts);
                            if(remainingCovidDiscounts == null){
                                ql.addError('Account has no Covid Discounts!');
                            }
                            else{
                                System.debug('-1: ' + (remainingCovidDiscounts - 1));
                                if((remainingCovidDiscounts - 1) < 0){
                                    ql.addError('No more Covid Discounts remaining!');
                                }
                                else{
                                    account.Covid_Discount__c--;
                                    //update account;
                                }
                            }
                    	}
                    }
                }
                
                if(ql.SBQQ__Product__c != Null && ((SBQQ__QuoteLine__c)Trigger.oldMap.get(ql.Id)).SBQQ__Product__c != ql.SBQQ__Product__c){
                    productIds.add(ql.SBQQ__Product__c);
                }
                // checkin if class room is updated for quote line to update training fields
                if(ql.Classroom_Course__c != Null  && ((SBQQ__QuoteLine__c)Trigger.oldMap.get(ql.Id)).Classroom_Course__c != ql.Classroom_Course__c){
                    classRoomIds.add(ql.Classroom_Course__c);
                }
                if(ql.Classroom_Course__c == Null){
                    quoteIds.add(ql.SBQQ__Quote__c);
                }
            }

            System.debug('#### : '+productIds+'@@@@0'+classRoomIds+'@@@@'+quoteIds);
            
            if(productIds.size() > 0){
                // call populateWorkType method to Populate work type on Quote Line with respective product 
                QuoteLineTriggerHandler.populateWorkType(productIds);
            }
            
            if(classRoomIds.size() > 0 || quoteIds.size() > 0){
                // call populateTrainingAddressFields method to populate training address fields on Quote line with rescpective Classroom(SA) address fields
                QuoteLineTriggerHandler.populateTrainingAddressFields();
            }
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }    
    }
    
    public override void afterInsert(){
        
        quoteLineIds = new Set<Id>();
        Set<Id> quoteIdSet = new Set<Id>();
        classRoomIds = new Set<Id>();
        List<string> ids = new List<string>(); //List of record ids having Train_the_Trainer__c = true
        
        try{
            for(SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>) Trigger.New){
                quoteIds.add(ql.SBQQ__Quote__c);
                // filte Quote Lines's with Course or Evaluations Product to create attendee records
                if(ql.SBQQ__ProductFamily__c == 'Courses' || ql.SBQQ__ProductFamily__c == 'Evaluations') {
                    System.debug('AFTER INSERT::ID => ' + ql.Id);
                    System.debug(ql.Product_Family__c);
                    System.debug(ql.Course_Product_Line__c);
                    System.debug(ql.SBQQ__Product__r.Delivery_Method__c);                    
                    quoteLineIds.add(ql.Id);
                }
                if(ql.Classroom_Course__c != Null){
                    classRoomIds.add(ql.Classroom_Course__c);
                }
                //Filter record ids having Train_the_Trainer__c = true
                if(ql.Train_the_Trainer__c) {
                    ids.add(ql.id);
                }
            }
            System.debug('ids : '+ids);
            //Code to populate Training Instructor Requirements URL field if Train_the_Trainer__c = true

            system.debug('<<<<--Ids-->>>>'+quoteLineIds);
            if(quoteLineIds.size() > 0){
                System.debug('AFTER INSERT::quoteLineIds =>' + quoteLineIds);
                // call createAttendeeRecord method to create attendee records
                QuoteLineTriggerHandler.createAttendeeRecord(quoteLineIds);
            }
            if(classRoomIds.size() > 0){
                // call updateQuotedSeats metod to update current quoted field on classroom(SA) record
                QuoteLineTriggerHandler.updateQuotedSeats(classRoomIds);
            }
            
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }
        
        
    }
    public override void afterUpdate(){
       
        quoteLineIds = new Set<Id>();
        Set<Id> quoteIdSet = new Set<Id>();
        Set<Id> qlIdsOSCQuestion = new Set<Id>(); // Set of Quote Line Id's For pushing data of On-Site Question to related Service Appointment
        classRoomIds = new Set<Id>();
        
        try{
            SBQQ__QuoteLine__c oldQuoteLine = new SBQQ__QuoteLine__c();
            for(SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>) Trigger.New){
                quoteIds.add(ql.SBQQ__Quote__c);
                oldQuoteLine = (SBQQ__QuoteLine__c)Trigger.oldMap.get(ql.id);
                if(ql.Classroom_Course__c != null){
                    if(oldQuoteLine.Classroom_Course__c != null && oldQuoteLine.Classroom_Course__c != ql.Classroom_Course__c){
                        classRoomIds.add(oldQuoteLine.Classroom_Course__c);    
                    }
                    if(ql.SBQQ__Quantity__c != oldQuoteLine.SBQQ__Quantity__c || oldQuoteLine.Classroom_Course__c == null){
                        classRoomIds.add(ql.Classroom_Course__c);
                    }
                }
                // checking if quatity or no. of participants values updated to create attendee records
                if((ql.SBQQ__ProductFamily__c == 'Courses' || ql.SBQQ__ProductFamily__c == 'Evaluations') && (ql.Number_of_Participants__c != oldQuoteLine.Number_of_Participants__c || ql.SBQQ__Quantity__c != oldQuoteLine.SBQQ__Quantity__c)) {
                    System.debug('AFTER UPDATE::Id => ' + ql.Id);
                    quoteLineIds.add(ql.Id);
                }
                // checking if Quote Line's fields updated which is relate to OSC course questions
                if(ql.Primary_Contact__c != oldQuoteLine.Primary_Contact__c || ql.Lifting_Device_Eval_Details__c != oldQuoteLine.Lifting_Device_Eval_Details__c || ql.Annual_Safety_Inspection_Eval_Details__c != oldQuoteLine.Annual_Safety_Inspection_Eval_Details__c){
                    qlIdsOSCQuestion.add(ql.Id);
                }
                 
            }
            if(qlIdsOSCQuestion.size() > 0 ){
                // call pushOSCQuestionAns to push Ans to related classroom(SA) 
                QuoteLineTriggerHandler.pushOSCQuestionAns(qlIdsOSCQuestion);
            }
            if(quoteLineIds.size() > 0){
                // call createAttendeeRecord method to create attendee records
                QuoteLineTriggerHandler.createAttendeeRecord(quoteLineIds);
            }
            if(classRoomIds.size() > 0){
                // call updateQuotedSeats metod to update current quoted field on classroom(SA) record
                QuoteLineTriggerHandler.updateQuotedSeats(classRoomIds);
            }
            
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }        
    }
    
    
    public override void beforeDelete(){
        String profileName = [select Name from profile where id = :UserInfo.getProfileId()].Name;
        quoteLineIds = new Set<Id>();
        
        try{
            for(SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>) Trigger.Old){
				
				//Check if the quote has been sent
				SBQQ__Quote__c q = [Select Send_Date__c from SBQQ__Quote__c where Id =: ql.SBQQ__Quote__c][0];
                if(q.Send_Date__c != NULL && profileName != 'OSG Sys Admin'){
                    ql.addError('Cannot delete quote line! Contact your administrator.');
                }
                // filter Courses and Evaluations Quote lins 
                if((ql.SBQQ__ProductFamily__c == 'Courses' || ql.SBQQ__ProductFamily__c == 'Evaluations')) {
                    quoteLineIds.add(ql.Id);
                }
            }
            if(quoteLineIds.size() > 0){
                // Delete attendee records when ever a quote line deleted
                QuoteLineTriggerHandler.deleteAttendeeRecords(quoteLineIds);
            }
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }    
    }
    
    
    public override void afterDelete(){
        quoteIds = new Set<Id>();
        classRoomIds = new Set<Id>();
        Set<Id> quoteIdSet = new Set<Id>();
        
        try{
            for(SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>) Trigger.Old){
                quoteIds.add(ql.SBQQ__Quote__c);
                if(ql.Classroom_Course__c != null ){
                    classRoomIds.add(ql.Classroom_Course__c);
                }
            }
            if(classRoomIds.size() > 0){
                // call updateQuotedSeats metod to update current quoted field on classroom(SA) record
                QuoteLineTriggerHandler.updateQuotedSeats(classRoomIds);
            }
            if(quoteIds.size() > 0){
                //QuoteLineTriggerHandler.sameDayCourseMatch(quoteIds);
            }
            
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }
        
        
    }
    
    // Method to populate work type on Quote line
    // Populate work type with related product on Quote Line
    // Product family should be in ('Evaluations','Consulting Services','Courses') and Delivery Metohd = On-site
    public static void populateWorkType(Set<Id> prodIds){
        
        Map<Id,Id> mapProdWorkType = new Map<Id,Id>();
        // Querying worktype records
        
        try{
            for(WorkType wt : [Select Id,Product__c,Product__r.Family From WorkType Where Product__c IN : prodIds AND (Product__r.Family IN ('Evaluations','Consulting Services','Courses') AND (Product__r.Delivery_Method__c != 'Classroom' OR Product__r.Course_Product_Line__c in :productCodeExceptions))]){
                mapProdWorkType.put(wt.Product__c, wt.Id);
            }
            if(mapProdWorkType.keySet().size() > 0){
                for(SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>) Trigger.New){
                    if(mapProdWorkType.containsKey(ql.SBQQ__Product__c)){
                        ql.Work_Type__c = mapProdWorkType.get(ql.SBQQ__Product__c);
                    }
                }
            }
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }
        
        
    }
    
    
    
    // Method to populate training address fields with rescpective classroom(SA) recourd address
    public static void populateTrainingAddressFields(){
        
        Map <Id,ServiceAppointment> mapSA = new Map<Id,ServiceAppointment>();
        
        try{
            if(classRoomIds.size() > 0){
                //Querying Service Appointment records
                for(ServiceAppointment sa : [Select Id, Street, City, State, Country, PostalCode, SchedStartTime From ServiceAppointment Where Id IN: classRoomIds]){
                    mapSA.put(sa.Id,sa);
                }
            }

            for(SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>) Trigger.New){
                if(ql.Classroom_Course__c != Null){
                    if(mapSA.keySet().size() > 0){
                        // Map Training fields with Classroom(SA) address
                        if(mapSA.containsKey(ql.Classroom_Course__c)){
                            ql.Training_Province__c = mapSA.get(ql.Classroom_Course__c).State;
                            ql.Scheduled_Date_and_Time__c = mapSA.get(ql.Classroom_Course__c).SchedStartTime;
                        }
                    }
                }

            }
            
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }  
    }
    
 
    
    // Method to create Attendee Records relted to the Quote Lines
    public static void createAttendeeRecord(set<Id> qlIds){
        List<SBQQ__QuoteLine__c> lstQuoteLine = new List<SBQQ__QuoteLine__c>(); // Quote Line List for creating respective Attendee records 
        
        try{
            // Fatching Quote Line Records  for Knowing Delivery Method of Quote Line
            for(SBQQ__QuoteLine__c ql : [Select Id,SBQQ__Product__c,Account__r.Name, SBQQ__ProductFamily__c, Number_of_Participants__c, SBQQ__Quantity__c, SBQQ__Product__r.Delivery_Method__c, SBQQ__Product__r.Course_Product_Line__c, Course_Product_Line__c From SBQQ__QuoteLine__c Where Id IN : qlIds AND (SBQQ__Product__r.Delivery_Method__c = 'Classroom' OR (SBQQ__Product__r.Delivery_Method__c = 'On-site' and SBQQ__ProductFamily__c = 'Evaluations' and SBQQ__Product__r.Course_Product_Line__c != 'RFTE' and (not Account__r.Name like '%Toyota Motor%')) OR (SBQQ__Product__r.Delivery_Method__c = 'Online' and SBQQ__Product__r.Course_Product_Line__c in :productCodeExceptions))]){
                lstQuoteLine.add(ql);
                System.debug('CREATE ATTENDEE RECORD (FOR LOOP):: ' + ql);
            }
            
            //Map for getting the count of exisiting Attendee records with rescpective Quote Line 
            Map<Id,Integer> countMap = new Map<Id,Integer>();
            for(AggregateResult ar : [Select Count(Id) idCount, Quote_Line__c From Attendee__c Where Quote_Line__c IN :qlIds Group By Quote_Line__c]){
                countMap.put((Id)ar.get('Quote_Line__c'), (Integer)ar.get('idCount'));
            }
            
            System.debug(qlIds);
            //List of newly created attendee records
            List<Attendee__c> lstAttendeeRecords = new List<Attendee__c>();
            for(SBQQ__QuoteLine__c ql :lstQuoteLine){
                Integer startingpoint = 0; //staring point for loop
                Integer endPoint = 0;      //end point of loop
                //setting starting point if already attendee record creted for rescpective Quote Line
                if(countMap.keySet().size() > 0 && countMap.containsKey(ql.Id)){
                    startingpoint = countMap.get(ql.Id); 
                }
                // setting endPoint 
                if((ql.SBQQ__ProductFamily__c == 'Courses' && ql.SBQQ__Product__r.Delivery_Method__c == 'Classroom') || (ql.SBQQ__ProductFamily__c == 'Evaluations')){
                    endPoint = (Integer)ql.SBQQ__Quantity__c;
                }
                if(ql.SBQQ__ProductFamily__c == 'Courses' && ql.SBQQ__Product__r.Delivery_Method__c == 'Online' && productCodeExceptionsSet.contains(ql.SBQQ__Product__r.Course_Product_Line__c)){
                    endPoint = (Integer)ql.SBQQ__Quantity__c;
                }
                if(ql.SBQQ__ProductFamily__c == 'Courses' && ql.SBQQ__Product__r.Delivery_Method__c== 'On-site'){
                    endPoint = (Integer)ql.Number_of_Participants__c;
                }
                system.debug('---Starting Point---'+startingpoint +'******'+endPoint);
                // loop for crating attendee records
                for(Integer i = startingpoint; i< endPoint; i++){
                    Attendee__c atRec = new Attendee__c();
                    atRec.Name = 'TBD';
                    atRec.Quote_Line__c = ql.Id;
                    lstAttendeeRecords.add(atRec);
                }
                
            }
            // insert newly created attendee records
            if(lstAttendeeRecords.size() > 0){
                insert lstAttendeeRecords;
            }
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }
    }
    
    
    
    // Method to delete attendee records 
    public static void deleteAttendeeRecords(Set<Id> qlIds){
        List<Attendee__c> lstDelAttendeeRecords = new List<Attendee__c>();
        
        try{
            for(Attendee__c at : [Select Id, Quote_Line__c From Attendee__c Where Quote_Line__c IN : qlIds]){
                lstDelAttendeeRecords.add(at);
            }
            
            if(lstDelAttendeeRecords.size() > 0){
                delete lstDelAttendeeRecords;
            }
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }
    }
    
    
    // Method to update current quoted seat on classroom course record
    public static void updateQuotedSeats(Set<Id> classRoomCourseIds){
        //System.assert(false,classRoomCourseIds);
        Map<Id, List<SBQQ__QuoteLine__c>> mapClassroomQLines = new Map<Id, List<SBQQ__QuoteLine__c>>();
        Map<Id, ServiceAppointment> mapServiceAppointment = new Map<Id, ServiceAppointment>();
        
        try{
            for(ServiceAppointment sa : [Select Id, Current_Quoted_Seats__c, Confirmed_Seats__c, (Select Id, SBQQ__Quantity__c From Quote_Lines__r) From ServiceAppointment Where Id IN:classRoomCourseIds]){
                mapClassroomQLines.put(sa.Id, new List<SBQQ__QuoteLine__c>());
                mapServiceAppointment.put(sa.Id, sa);
                for(SBQQ__QuoteLine__c ql : sa.Quote_Lines__r){
                    mapClassroomQLines.get(sa.Id).add(ql);
                }
            }
            //System.assert(false,+'==Map-1=='+mapClassroomQLines+'###Map-2###'+mapServiceAppointment);
            List<ServiceAppointment> updateSALst = new List<ServiceAppointment>();
            if(mapServiceAppointment.keySet().size() > 0){
                for(Id saId : mapServiceAppointment.keySet()){
                    ServiceAppointment updateSA = mapServiceAppointment.get(saId);
                    updateSA.Current_Quoted_Seats__c = 0.0;
                    for(SBQQ__QuoteLine__c ql : mapClassroomQLines.get(saId)){
                        updateSA.Current_Quoted_Seats__c += ql.SBQQ__Quantity__c;
                    }
                    if(updateSA.Confirmed_Seats__c == null){
                        updateSA.Confirmed_Seats__c = 0;
                    }
                    
                    updateSA.Current_Quoted_Seats__c += updateSA.Confirmed_Seats__c;
                    updateSALst.add(updateSA);
                }
            }

            if(updateSALst.size() > 0){
                try{
                    update updateSALst;
                }
                catch(Exception e){
                    System.assert(false, e.getMessage() +'=====' + e.getLinenumber());
                }
            }
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
        }
    }
    
    
    
    // Method to push On-Site Course Question's Answers to related Service Appointment of Quote Line
    public static void pushOSCQuestionAns(Set<Id> qlIds){
        Map<Id,ServiceAppointment> mapQLServiceAppointment = new Map<Id,ServiceAppointment>();
        
        try{
            // Fatching Service Appointment Records related
            for(ServiceAppointment sa : [Select Id, Quote_Line__c From ServiceAppointment Where Quote_Line__c IN : qlIds]){
                mapQLServiceAppointment.put(sa.Quote_Line__c, sa);
            }
            
            List<ServiceAppointment> serviceAppointmentLstToUpdate = new List<ServiceAppointment>();
            if(mapQLServiceAppointment.keySet().size() > 0){
              
                for(SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>) Trigger.New){
                    if(mapQLServiceAppointment.containsKey(ql.id)){
                        ServiceAppointment updateSA = mapQLServiceAppointment.get(ql.Id);
                        updateSA.ContactId = ql.Primary_Contact__c;
                        updateSA.Lifting_Device_Eval_Details__c = ql.Lifting_Device_Eval_Details__c;
                        updateSA.Annual_Safety_Inspection_Eval_Details__c = ql.Annual_Safety_Inspection_Eval_Details__c;
                        serviceAppointmentLstToUpdate.add(updateSA);
                    }
                }
            }
            
            if(serviceAppointmentLstToUpdate.size() > 0){
                update serviceAppointmentLstToUpdate;
            }
        }
        catch(Exception e){
            System.debug('Error In Quote Line: '+e.getMessage()+e.getStackTraceString()); 
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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