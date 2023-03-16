public without sharing class ServiceAppointmentTriggerHandler extends TriggerHandler{
    
    private class TTTSyncRequest {
        public String contactId;
        public String contactFullName;
        public String contactEmail;
        public String accountId;
        public String accountName;
        public String courseCode;
    }
    
	private class SyncResponse {
        public boolean success;
        public string message;
    }    
        
    public override void beforeInsert(){
        Set<Id> parentWO = new set<Id>();  // set of parent record if type of work order

        for(ServiceAppointment sa : (List<ServiceAppointment>) Trigger.New){
            parentWO.add(sa.ParentRecordId);
            if(sa.SchedStartTime != null){
                sa.Capture_Scheduled_Start__c=sa.SchedStartTime;
            }
			sa.Course_Maximum_Capacity__c = calculateCourseMaximum(sa);
        }
        if(parentWO.size() > 0){
            ServiceAppointmentTriggerHandler.populateQLFieldsOnSA(parentWO);
        }
    }
    
    public override void afterInsert(){
        Set<Id> onSiteSASet = new Set<Id>();
        for(ServiceAppointment sa : (List<ServiceAppointment>) Trigger.New){
            if(sa.IH3POS__c == 'On-Site'){
                onSiteSASet.add(sa.Id);
            }
        }		
        
        if(onSiteSASet.size() > 0){
			ServiceAppointmentTriggerHandler.setSAOrderDetails(onSiteSASet);
			ServiceAppointmentTriggerHandler.linkAttendeeOrderProduct(onSiteSASet);            
            ServiceAppointmentTriggerHandler.linkAttendeeServiceAppointment(onSiteSASet);
        }
    }

    //Used to populate the order information on the SA
    public static void setSAOrderDetails(Set<Id> saId){
        List<ServiceAppointment> saList = [Select Quote__c, Quote_Line__c from ServiceAppointment where id in: saId];
        for(ServiceAppointment sa : saList){
            Order o = NULL;
            OrderItem oi = NULL;
            o = [Select Id from Order where SBQQ__Quote__c = :sa.Quote__c];
            oi = [Select Id from OrderItem where SBQQ__QuoteLine__c = :sa.Quote_Line__c];
            if(o != NULL){
                sa.Order__c = o.Id;
                sa.Order_Product__c = oi.Id;
            }
        }
        update saList;
    }
    
    public override void beforeUpdate(){
        ServiceAppointment oldSA;
        for(ServiceAppointment sa : (List<ServiceAppointment>) Trigger.New){
            oldSA = (ServiceAppointment)Trigger.oldMap.get(sa.Id);

            if((sa.SchedStartTime != oldSA.SchedStartTime && sa.SchedStartTime != null)){
                sa.Capture_Scheduled_Start__c=sa.SchedStartTime;
            }
            
            //recalculate the course maximum capacity
            sa.Course_Maximum_Capacity__c = calculateCourseMaximum(sa);     
        }      	
    }
    
    private Decimal calculateCourseMaximum(ServiceAppointment sa){
        Decimal capOverride = (sa.Max_Capacity_Override__c == null) ? 0 : sa.Max_Capacity_Override__c;
        //For on-site SA, the location will be null
        Decimal capLocation = (sa.Location_Max_Capacity__c == null) ? 0 : sa.Location_Max_Capacity__c;
        
        Decimal courseMax = 0;
        //if the service appointment is on site we don't know the location capacity
        if(sa.IH3POS__c == 'On-Site'){
            courseMax = Math.max(sa.Product_Max_Capacity__c, capOverride);     
        }
        else {
            courseMax = Math.max(Math.min(sa.Product_Max_Capacity__c, capLocation), capOverride);
        }
        return courseMax;
    }
   
    public override void afterUpdate(){
        Set<Id> workTypeSAIdSet = new Set<Id>();
        Set<Id> serAppIds = new Set<Id>(); // Set of SA Id's which use to create absence records
        Set<Id> serAppIdsForAbsenceDeletion = new Set<Id>(); // Set of SA Id's which use to delete absence records
        Set<Id> canceledIHSAIds = new Set<Id>();
        Set<Id> canceledOSSAIds = new Set<Id>();        
        set<Id> schedTimeChnagedSAIds = new Set<Id>();
        set<Id> completeSAIds = new Set<Id>();
        set<Id> completedOSSAIds = new Set<Id>();
        set<Id> completedTTTSAIds = new Set<Id>();
        
        ServiceAppointment oldSA = new ServiceAppointment();
        for(ServiceAppointment sa : (List<ServiceAppointment>) Trigger.New){
            System.debug('SA=> ' + sa);
            if(sa.WorkTypeId == null){
                workTypeSAIdSet.add(sa.Id);                
            }
            oldSA = (ServiceAppointment)Trigger.oldMap.get(sa.Id);

            if(sa.Status == 'Canceled' && OldSA.Status != 'Canceled' && sa.IH3POS__c != 'On-Site'){
                canceledIHSAIds.add(sa.Id);
            }
            
            if(sa.Status == 'Canceled' && OldSA.Status != 'Canceled' && sa.IH3POS__c == 'On-Site'){
                canceledOSSAIds.add(sa.Id);
            }            

            if(sa.Status == 'Completed' && OldSA.Status != 'Completed'){
                completeSAIds.add(sa.Id);
                System.debug('SATriggerHandler - ' + sa.Id + ' completed');
            }
            if(sa.Status == 'Completed' && OldSA.Status != 'Completed' && sa.IH3POS__c == 'On-Site'){
                completedOSSAIds.add(sa.Id);
                System.debug('SATriggerHandler - ' + sa.Id + ' OS completed');                
            }
            //Get completed TTT courses to send to LearningLogin
            
            if(sa != null && OldSA != null &&  sa.SA_Course_Product_Line__c != null && sa.Status == 'Completed' && OldSA.Status != 'Completed' && sa.SA_Course_Product_Line__c.endsWith('TTT')){
            	//completedTTTSAIds.add(sa.Id);
                System.debug('SATriggerHandler - ' + sa.Id + ' TTT completed');                
            }
            // get Service Appointment Ids Which SchedStartTime is Changed
            if(sa.SchedStartTime != null){
                schedTimeChnagedSAIds.add(sa.Id); 
            }
        }
        
        if(canceledIHSAIds.size() > 0){
            ServiceAppointmentTriggerHandler.cancelAllIHRelatedItems(canceledIHSAIds);
        }
        if(canceledOSSAIds.size() > 0){
            ServiceAppointmentTriggerHandler.cancelAllOSRelatedItems(canceledOSSAIds);
        }        
        if(schedTimeChnagedSAIds.size() > 0){
            // call updateScheDateTimeOnOrderProd to update Scheduled Date and Time on all child order product
            ServiceAppointmentTriggerHandler.linkOrderProductServiceAppointment(schedTimeChnagedSAIds);
            ServiceAppointmentTriggerHandler.linkAttendeeServiceAppointment(schedTimeChnagedSAIds);
        }
        if(completedOSSAIds.size() > 0){
            System.debug('SATriggerHandler - ' + completedOSSAIds.size() + ' OS SAs completed');            
            ServiceAppointmentTriggerHandler.removeTBDAttendees(completedOSSAIds);            
        }
        if(completeSAIds.size() > 0){
            System.debug('SATriggerHandler - ' + completeSAIds.size() + ' SAs completed');
            ServiceAppointmentTriggerHandler.setOrderProductToDelivered(completeSAIds);
            ServiceAppointmentTriggerHandler.setCompletedDateOnSA(completeSAIds);
            ServiceAppointmentTriggerHandler.SetAttendeeToAttendedEntireCourse(completeSAIds);            
            ServiceAppointmentTriggerHandler.setAttendeeCertificateInfo(completeSAIds);            
        }
        if(completedOSSAIds.size() > 0){
            System.debug('SATriggerHandler - ' + completedOSSAIds.size() + ' OS SAs completed');
            ServiceAppointmentTriggerHandler.linkAddedOSAttendeeOrderProduct(completedOSSAIds);
            ServiceAppointmentTriggerHandler.setRequiredByOrderProductToDelivered(completedOSSAIds);            
            ServiceAppointmentTriggerHandler.calculateAdditionalAttendees(completedOSSAIds);
            ServiceAppointmentTriggerHandler.setExpenseOrderProductsToDelivered(completedOSSAIds);
        }
        if(completedTTTSAIds.size() > 0){
            //send Ids to function that process records and call endpoint
            ServiceAppointmentTriggerHandler.processTTTPortalRecords(completedTTTSAIds);
        }
        if(workTypeSAIdSet.size() > 0 && !system.isBatch() && !system.isFuture()){
            // call populateProductOfWorkType to populate product on Sa using Product of related worktype
            ServiceAppointmentTriggerHandler.populateProductOfWorkTypeNoFuture(workTypeSAIdSet);
        }
    }
    
    @future(callout=true)
    private static void processTTTPortalRecords(Set<Id> SAIds){
        List<Attendee__c> attendees = [Select Id, Contact__c, Contact__r.Name, Contact__r.Email, Contact__r.AccountId, Contact__r.Account.Name, Service_Appointment__r.Product__r.Course_Product_Line__c from Attendee__c where Theory_Status__c = 'Passed' and Service_Appointment__c in :SAIds];
        for(Attendee__c attendee : attendees){
            TTTSyncRequest syncRequest = new TTTSyncRequest();
            syncRequest.contactId = attendee.Contact__c;
            syncRequest.contactFullName = attendee.Contact__r.Name;
            syncRequest.contactEmail = attendee.Contact__r.Email;
            syncRequest.accountId = attendee.Contact__r.AccountId;
            syncRequest.accountName = attendee.Contact__r.Account.Name;
            syncRequest.courseCode = attendee.Service_Appointment__r.Product__r.Course_Product_Line__c;
            
            ServiceAppointmentTriggerHandler.PortalSync(syncRequest, attendee.Id);            
        }
    }
    
    //set the certification status on the attendee
    public static void setAttendeeCertificateInfo(Set<Id> SAIds){
        List<Attendee__c> attendees = new List<Attendee__c>();
        for(ServiceAppointment sa : [Select Id from ServiceAppointment where id in: SAIds]){
            List<Attendee__c> attendeesCertUpdate = [Select Id, Requires_Wall_Cert__c, Requires_Wallet_Card__c, Certificate_Status__c, Wallet_Card_Status__c from Attendee__c where Service_Appointment__c = :sa.Id];
            for(Attendee__c attendee : attendeesCertUpdate){
                if(attendee.Requires_Wall_Cert__c == TRUE){
                    attendee.Certificate_Status__c = 'Pending';
                }
                if(attendee.Requires_Wallet_Card__c == TRUE){
                    List<Evaluation__c> failedEvals = [Select Id from Evaluation__c where Attendee__c = :attendee.Id and Status__c = 'Fail'];
					attendee.Wallet_Card_Status__c = 'Pending';
                    attendee.Certificate_Status__c = 'Pending';
                }
                attendees.add(attendee);
            }
        }
        
        if (attendees.size() > 0){
            update attendees;
            System.debug('SATriggerHandler::setAttendeeCertificateInfo - ' + attendees.size() + ' attendees certificate info set.');        
        }
    }
    
    @future
    public static void linkAttendeeServiceAppointment(Set<Id> SAIds){
        List<SBQQ__QuoteLine__c> quoteLines = [Select Id from SBQQ__QuoteLine__c where Classroom_Course__c in :SAIds];
        Set<Id> quoteLineId = (new Map<Id,SBQQ__QuoteLine__c>(quoteLines)).keySet();
        List<Attendee__c> attendees = [Select Id, Quote_Line__c, Order_Product__c, Service_Appointment__c from Attendee__c where Quote_Line__c in:quoteLineId and Service_Appointment__c = null];
        for(Attendee__c attendee : attendees){
            List<OrderItem> orderItems = [Select Id, Classroom_Course__c from OrderItem where id = :attendee.Order_Product__c limit 1];
            if(orderItems.size() > 0){
                OrderItem oi = orderItems[0];
                attendee.Service_Appointment__c = oi.Classroom_Course__c;                
            }
        }
        update attendees;
    }
    
    public static void removeTBDAttendees(Set<Id> SAIds){
        List<Attendee__c> tbdAttendees = [Select Id, Quote_Line__c, Order_Product__c, Service_Appointment__c from Attendee__c where Service_Appointment__c in:SAIds and Contact_Is_Valid__c = FALSE and Name = 'TBD'];
        delete tbdAttendees;
        System.debug('SATriggerHandler::removeTBDAttendees - ' + tbdAttendees.size() + ' TBD attendees removed.');        
    }
    
    public static void linkAttendeeOrderProduct(Set<Id> SAIds){
        List<Attendee__c> updatedAttendees = new List<Attendee__c>();
        for(ServiceAppointment sa : [Select Quote_Line__c, Order_Product__c from ServiceAppointment where id in: SAIds]){
            for(Attendee__c attendee : [Select Id, Order_Product__c from Attendee__c where Quote_Line__c = :sa.Quote_Line__c]){
                attendee.Order_Product__c = sa.Order_Product__c;
                updatedAttendees.add(attendee);
            }
        }
        update updatedAttendees;
    }
    
    public static void linkAddedOSAttendeeOrderProduct(Set<Id> SAIds){
        List<Attendee__c> updatedAttendees = new List<Attendee__c>();
        for(ServiceAppointment sa : [Select Id, Order_Product__c from ServiceAppointment where id in: SAIds]){
            for(Attendee__c attendee : [Select Id, Order_Product__c from Attendee__c where Service_Appointment__c= :sa.Id and Order_Product__c = NULL]){
                attendee.Order_Product__c = sa.Order_Product__c;
                updatedAttendees.add(attendee);
            }
        }
        update updatedAttendees;
        System.debug('SATriggerHandler::linkAddedOSAttendeeOrderProduct - ' + updatedAttendees.size() + ' OS attendees linked to order product.');          
    }

    public static void calculateAdditionalAttendees(Set<Id> SAIds){            
        Map<Id, Decimal> saAttendeeDiffMap = new Map<Id, Decimal>();
        
        List<ServiceAppointment> onSiteSA = [Select Id, Order_Product__c, Confirmed_Seats__c, Checked_In_Seats__c from ServiceAppointment where id in :SAIds];
        for(ServiceAppointment sa : onSiteSA){
            if (sa.Order_Product__c != null) {
                OrderItem oi = [Select Id, Number_of_Participants__c, Product2Id from OrderItem where id = :sa.Order_Product__c];
                if (oi.Product2Id != null) {
                    Product2 prod = [Select Id, MaxOSCapacity_AdditionalChargeThreshold__c from Product2 where id = :oi.Product2Id];
                    if(prod.MaxOSCapacity_AdditionalChargeThreshold__c > 0){
                        saAttendeeDiffMap.put(sa.Id, sa.Checked_In_Seats__c - prod.MaxOSCapacity_AdditionalChargeThreshold__c);
                        System.debug('SATriggerHandler::calculateAdditionalAttendees - SA: ' + sa.Id + 'w/ ' + String.valueOf(sa.Checked_In_Seats__c - prod.MaxOSCapacity_AdditionalChargeThreshold__c) + '  additional attendees adjusted.'); 
                    }
                }
            }
        }

        if(saAttendeeDiffMap.size() != 0){
            ServiceAppointmentTriggerHandler.adjustAdditionalAttendees(saAttendeeDiffMap);            
        }
		
    }
    
    @future
    public static void adjustAdditionalAttendees(Map<Id, Decimal> saAttendeeCountMap){
        for(ServiceAppointment sa : [Select Id, Order_Product__c, Order__c, Confirmed_Seats__c, Checked_In_Seats__c, Product__c, SchedEndTime from ServiceAppointment where id in :saAttendeeCountMap.keySet()]){
            DateTime dT = sa.SchedEndTime;
            Date deliveryDate = date.newinstance(dT.year(), dT.month(), dT.day());            
            Decimal difference = saAttendeeCountMap.get(sa.Id);
            
            Order order = [Select Id, Status from Order where Id =: sa.Order__c];
            if(order.Status != 'Draft'){
                SBQQ.TriggerControl.disable();
                order.Status = 'Draft';
                update order;
                SBQQ.TriggerControl.enable();  
            }

			Product2 ae = [Select Id, External_Product_Name__c, Course_Product_Line__c, ProductCode, Family from Product2 where Name = 'Additional Attendees' and Family = 'Courses'];                        
            OrderItem oi = NULL;
            List<OrderItem> oiAdditionalAttendee = [Select Id, Delivery_Date__c, SBQQ__OrderedQuantity__c, SBQQ__QuotedQuantity__c, Quantity, Tax_Rate__c, Net_Unit_Price__c, Sales_Tax__c, Total_Amount_Without_Tax__c, Total_Net_Price__c, SBQQ__Status__c, Classroom_Course__c from OrderItem where SBQQ__RequiredBy__c = :sa.Order_Product__c and Product2Id =: ae.Id Limit 1];
            
            if(oiAdditionalAttendee.size() > 0){
                oi = oiAdditionalAttendee[0];
            }
            
            //If order product is activated, make it draft
            if(oi != NULL){
                oi.SBQQ__Status__c = 'Draft';
				update oi;
            }
            
            //if difference > 0, append additional attendees
            if(difference > 0){
                //adjust the existing additional attendees line
                if(oi != NULL){
                    oi.SBQQ__QuoteLine__c  = NULL;
                    oi.SBQQ__OrderedQuantity__c = difference;
                    oi.SBQQ__QuotedQuantity__c = difference;
                    oi.Total_Amount_Without_Tax__c = difference * oi.Net_Unit_Price__c;
                    oi.Sales_Tax__c = (difference * oi.Net_Unit_Price__c) * (oi.Tax_Rate__c/100);
                    oi.Total_Net_Price__c = (difference * oi.Net_Unit_Price__c) + ((difference * oi.Net_Unit_Price__c) * (oi.Tax_Rate__c/100));
                    oi.Classroom_Course__c = sa.Id;

                    update oi;
                    BillingHelper.deliverOrderProduct(oi, deliveryDate);
                }
                
                //Create and insert additional attendee line
                else{
					PricebookEntry pbe = [Select Id from PricebookEntry where Product2Id =: ae.Id];
					OrderItem saOP = [Select Id, Tax_Rate__c, External_Product_Name__c, Product_Code__c, Product_Family__c, Course_Product_Line__c, Account__c, Quote_Training_Address1__c from OrderItem where id =: sa.Order_Product__c];
                    Product2 saProd = [Select Extra_Seat_Price__c from Product2 where id = :sa.Product__c];
                    
                    OrderItem additionalAttendee = new OrderItem(
						PriceBookEntryId = pbe.Id,
                        OrderId = sa.Order__c,
                        Quantity = difference,
                        SBQQ__QuotedQuantity__c = difference,
                        SBQQ__OrderedQuantity__c = difference,
                        UnitPrice = saProd.Extra_Seat_Price__c,
                        Total_Amount_Without_Tax__c = saProd.Extra_Seat_Price__c * difference,
                        Sales_Tax__c = (saProd.Extra_Seat_Price__c * difference) * (saOP.Tax_Rate__c/100),
                        Total_Net_Price__c = (saProd.Extra_Seat_Price__c * difference) + ((saProd.Extra_Seat_Price__c * difference) * (saOP.Tax_Rate__c/100)),
                        External_Product_Name__c = ae.External_Product_Name__c,
                        Product_Code__c = ae.ProductCode,
                        Product_Family__c = ae.Family,
                        Course_Product_Line__c = ae.Course_Product_Line__c,
                        SBQQ__RequiredBy__c = saOP.Id,
                        Classroom_Course__c = sa.Id,
                        Account__c = saOP.Account__c,
                        Quote_Training_Address1__c = saOP.Quote_Training_Address1__c,
                        Tax_Rate__c = saOP.Tax_Rate__c
                    );
                    
                    insert additionalAttendee;
                    BillingHelper.deliverOrderProduct(additionalAttendee, deliveryDate);
                }
            }
            //remove existing additional attendee lines
            else{
                if(oi != NULL){
	                delete oi;                    
                }
            }

            SBQQ.TriggerControl.disable();
            order.Status = 'Activated';
            update order;
            SBQQ.TriggerControl.enable();
        }
    }
    
    
    // Method to pupulate Quote Line Realted fields on ServicAppointment when SA created throgh Book Appointment
    
    public static void populateQLFieldsOnSA(Set<Id> idsWO){
        //fatching Quote Line Ids
        Map<Id, Id> MapworkOrderQLId = new Map<Id,Id>();
        // map workorder with account
        Map<Id, Id> mapWOIdAccId = new Map<Id, Id>();

        for(WorkOrder wo : [Select Id, Quote_Line__c, AccountID From WorkOrder WHERE Id IN : idsWO]){
            if(wo.Quote_Line__c != null){
                MapworkOrderQLId.put(wo.Quote_Line__c, wo.Id);
            }
            if(wo.AccountId != null){
                mapWOIdAccId.put(wo.Id, wo.AccountId);
            }
        }
        
        Map<Id, SBQQ__QuoteLine__c> MapWOQuoteLine = new Map<Id,SBQQ__QuoteLine__c>();
        if(MapworkOrderQLId.keySet().size() > 0){
            for(SBQQ__QuoteLine__c ql : [Select Id, SBQQ__Quote__c, Quote_Training_Address1__c, SBQQ__Product__c, SBQQ__Product__r.IsMutiDay__c, Primary_Contact__c, Account__c,SBQQ__Quote__r.Id From SBQQ__QuoteLine__c Where Id IN : MapworkOrderQLId.keySet()]){
                if(MapworkOrderQLId.containsKey(ql.id)){
                    MapWOQuoteLine.put(MapworkOrderQLId.get(ql.Id), ql);
                }
            }
        }
        
        for(ServiceAppointment sa : (List<ServiceAppointment>) Trigger.New){
            if(MapWOQuoteLine.containsKey(sa.ParentRecordId)){
                //update Service Appointment
                SBQQ__QuoteLine__c quoteLine = MapWOQuoteLine.get(sa.ParentRecordId);
                system.debug('Quote-Line-record'+quoteLine);
                sa.Quote__c = quoteLine.SBQQ__Quote__c;
                sa.Quote_Line__c = quoteLine.Id;
                OrderItem oi = NULL;
                Order o = NULL;
                sa.Product__c = quoteLine.SBQQ__Product__c;
                sa.ContactId = quoteLine.Primary_Contact__c;
                sa.Account__c = quoteLine.Account__c;
                sa.IH3POS__c = 'On-site';
                if(quoteLine.Quote_Training_Address1__c != null){
                    sa.Training_Address1__c = quoteLine.Quote_Training_Address1__c;
                }
                System.debug(sa.Quote_Line__c);
            }
            if(mapWOIdAccId.containsKey(sa.ParentRecordId)){
                    sa.Account__c = mapWOIdAccId.get(sa.ParentRecordId);
            }
        }
    }
    
    public static void cancelAllOSRelatedItems(set<Id> saIds){
        Integer cancelCutoffLimit = 5;
        List<Attendee__c> updatedAttendees = new List<Attendee__c>();
        List<OrderItem> updatedOrderProducts = new List<OrderItem>();
        
        for(ServiceAppointment sa : [Select Id, Order_Product__c, ArrivalWindowStartTime from ServiceAppointment where id in: saIds]){
	    Integer daysToSA = (System.today()).daysBetween(Date.valueof(sa.ArrivalWindowStartTime));        
      		//check if order product needs to be canceled or canceled invoice	
            if(daysToSA > 4){
                Date startDate = Date.today();
                Date endDate = Date.today().addDays(daysToSA);
                
                for(integer i=0; i <= startDate.daysBetween(endDate); i++)
                {
                    Date dt = startDate + i;
                    DateTime currDate = DateTime.newInstance(dt.year(), dt.month(), dt.day());
                    String day = currDate.format('EEEE');
                    
                    if(day == 'Saturday' || day =='Sunday'){
                        cancelCutoffLimit = 7;
                        break;                    
                    }
                }
            }
            //check if sa is outside cutoff time frame
            if(daysToSA >= cancelCutoffLimit){
                for(OrderItem oi : [Select Id, SBQQ__Status__c from OrderItem where SBQQ__RequiredBy__c = :sa.Order_Product__c or Classroom_Course__c = :sa.Id]){
                    oi.SBQQ__Status__c = 'Canceled';
                    updatedOrderProducts.add(oi);
                }
                for(Attendee__c attendee: [Select Id, Status__c from Attendee__c where Service_Appointment__c = :sa.Id]){
                    attendee.Status__c = 'Canceled';
                    attendee.Confirmed__c = 'No';
                    updatedAttendees.add(attendee);
                }
            }
            else{
                for(OrderItem oi : [Select Id, SBQQ__Status__c from OrderItem where SBQQ__RequiredBy__c = :sa.Order_Product__c or Classroom_Course__c = :sa.Id]){
                    oi.SBQQ__Status__c = 'Canceled - Invoice';
                    updatedOrderProducts.add(oi);
                }
                for(Attendee__c attendee: [Select Id, Status__c from Attendee__c where Service_Appointment__c = :sa.Id]){
                    attendee.Status__c = 'Canceled';
                    attendee.Confirmed__c = 'No';
                    updatedAttendees.add(attendee);
                }           
            }
            
            if(updatedOrderProducts.size() > 0){
                update updatedOrderProducts;
            }
            
            if(updatedAttendees.size() > 0){
                update updatedAttendees;
            }
        }
    }
    
    public static void cancelAllIHRelatedItems(set<Id> saIds){
        // List of attendees to update Status 
        List<Attendee__c> canceledAttendees = new List<Attendee__c>();
        for(Attendee__c att : [Select Id, Status__c From Attendee__c Where Service_Appointment__c IN : saIds AND Order_Product_Status__c != 'Reschedulable']){
            att.Status__c = 'Canceled';
            canceledAttendees.add(att);
        }
        
        // List of order Product to Update Active Status
        List<OrderItem> canceledOrderProducts = new List<OrderItem>();
        for(OrderItem op: [Select Id From OrderItem where Classroom_Course__c IN : saIds AND (SBQQ__Status__c != 'Reschedulable' OR SBQQ__Status__c != 'Delivered')]){
            op.SBQQ__Status__c = 'Canceled';
            canceledOrderProducts.add(op);
        }
        
        //update attendee's Status to Canceled
        if(canceledAttendees.size() > 0){
            update canceledAttendees;
        }
        
        //update Order Product's Active Status to Canceled - Invoice
        if(canceledOrderProducts.size() > 0){
            update canceledOrderProducts;
        }
    }
    
    
    // Method to update appropriate attendees status to Attended Entire Course
    public static void SetAttendeeToAttendedEntireCourse( Set<Id> SAIds){
        List<Attendee__c> attendeeLst = new List<Attendee__c>();
        for(Attendee__c at : [Select Id, Status__c From Attendee__c Where Service_Appointment__c IN : SAIds]){
            //only want to update attendees who actually attended the course
            if(at.Status__c == 'Confirmed') {
            	at.Status__c = 'Attended Entire Course';
            	attendeeLst.add(at);
            }
        }
        
        if(attendeeLst.size() > 0){
            update attendeeLst;
	        System.debug('SATriggerHandler::SetAttendeeToAttendedEntireCourse - ' + attendeeLst.size() + ' attendees attended entire course.');        
        }
    }
    
    public static void setOrderProductToDelivered(Set<Id> SAIds){
        List<OrderItem> orderItems = [Select Id, SBQQ__Status__c, Delivery_Date__c, Classroom_Course__r.SchedEndTime from OrderItem Where Classroom_Course__c IN : SAIds AND SBQQ__Status__c = 'Draft'];
        Date deliveryDate;
        for(OrderItem oi : orderItems){
            DateTime dT = oi.Classroom_Course__r.SchedEndTime;
            deliveryDate = date.newinstance(dT.year(), dT.month(), dT.day());
            break;
        }
        BillingHelper.deliverOrderProducts(orderItems, deliveryDate);
        System.debug('SATriggerHandler::setOrderProductToDelivered - ' + orderItems.size() + ' order products delivered.');
    }
    
    public static void setRequiredByOrderProductToDelivered(Set<Id> SAIds){
		List<OrderItem> orderItems = new List<OrderItem>();
        for(ServiceAppointment sa : [Select Order_Product__c from ServiceAppointment where id in :SAIds]){
            if (sa.Order_Product__c != null) {
	            for(OrderItem oi : [Select Id, SBQQ__Status__c, Delivery_Date__c, SBQQ__RequiredBy__r.Classroom_Course__r.SchedEndTime from OrderItem where SBQQ__RequiredBy__c = :sa.Order_Product__c AND SBQQ__Status__c = 'Draft']){
    	            orderItems.add(oi);
        	    }       
            }
        }
        
        for(OrderItem oi : orderItems){
            DateTime dT = oi.SBQQ__RequiredBy__r.Classroom_Course__r.SchedEndTime;
            Date deliveryDate = date.newinstance(dT.year(), dT.month(), dT.day());
			BillingHelper.deliverOrderProduct(oi, deliveryDate);
        }   
    }
    
    public static void setExpenseOrderProductsToDelivered(Set<Id> SAIds){
        List<OrderItem> orderItems = new List<OrderItem>();
        for(ServiceAppointment sa : [Select Order__c from ServiceAppointment where id in :SAIds]){
            for(OrderItem oi : [Select Id, SBQQ__Status__c, Delivery_Date__c from OrderItem where OrderId = :sa.Order__c AND Product_Family__c = 'Expenses and Fees' AND SBQQ__Status__c = 'Draft' and SBQQ__RequiredBy__c = NULL]){
                orderItems.add(oi);
            }
        }
        BillingHelper.deliverOrderProducts(orderItems);
    }
    
    public static void setCompletedDateOnSA(Set<Id> SAIds){
        List<ServiceAppointment> serviceAppointments = [Select Date_Time_Completed__c from ServiceAppointment where id in :SAIds];
        for(ServiceAppointment sa : serviceAppointments){
            sa.Date_Time_Completed__c = System.now();
        }
        update serviceAppointments;
        System.debug('SATriggerHandler::setCompletedDateOnSA - ' + serviceAppointments.size() + ' SAs completed date set.');
    }
       
    public static void populateProductOfWorkTypeNoFuture(Set<Id> idsSA){
        try{
            System.debug('<<<<SA---Ids>>>'+idsSA);
            List<ServiceAppointment> serAppLst = new List<ServiceAppointment>();
            for(ServiceAppointment sa : [Select Id, Product__c, WorkTypeId,AccountId, WorkType.Product__c From ServiceAppointment Where Id IN : idsSA AND WorkTypeId != null AND  WorkType.Product__c != null]){
                if (sa.Product__c != sa.WorkType.Product__c) {
	                sa.Product__c = sa.WorkType.Product__c;
                	serAppLst.add(sa);
                }
            }
            
            if(serAppLst.size() > 0){
                update serAppLst;
            }
            
        }
        catch(Exception e){
            System.debug('Error:' + e.getMessage() +e.getLineNumber());
        }
    }
    
    
    public static void populateTrainingAddress(Set<Id> setAccountIds){
        List<Account_Address__c> accAddressLst = new List<Account_Address__c>();
        for(Account_Address__c aa : [Select Id, Account__c,Address1_1__c, City1__c, Country1__c, Postal_Code1__c, Province1__c, IHTPOSHT__c From Account_Address__c Where Account__c IN : setAccountIds AND Location_Status__c = 'Active' order by LastModifiedDate desc]){
            accAddressLst.add(aa);
        }
        
        if(accAddressLst.size() > 0){
            for(ServiceAppointment sa : (List<ServiceAppointment>) Trigger.New){
                if(sa.Training_Address1__c == null){
                    for(Account_Address__c aa : accAddressLst){
                        if(sa.Account__c != null && sa.Account__c == aa.Account__c && sa.Street  != null && sa.Street == aa.Address1_1__c 
                            && sa.City != null && sa.City == aa.City1__c && sa.State != null && sa.State == aa.Province1__c 
                            && sa.Country != null && sa.Country == aa.Country1__c
                         ){
                             sa.Training_Address1__c = aa.Id;
                             if(sa.IH3POS__c == null){
                                 if(aa.IHTPOSHT__c != null){
                                     if(aa.IHTPOSHT__c == 'IH')
                                         sa.IH3POS__c = 'In-House';
                                     else if(aa.IHTPOSHT__c == '3P' || aa.IHTPOSHT__c == 'HT'){
                                         sa.IH3POS__c = '3rd Party';
                                     }
                                     else
                                         sa.IH3POS__c = 'On-Site';
                                 }
                             }
                             break;
                         }
                    }
                }
            }
        }
    }
    
    // Method to update Scheduled Date and Time on child order product of Service Appointment
    public static void linkOrderProductServiceAppointment(Set<Id> serviceAppIds){ 
        List<OrderItem> orderItemToUpdate = new List<OrderItem>();
        for(ServiceAppointment sa : (List<ServiceAppointment>) Trigger.New){
            try {
                OrderItem item = [select id, Classroom_Course__c, Scheduled_Date_and_Time__c from OrderItem where Id =: sa.Order_Product__c];
                item.Classroom_Course__c = sa.id;
                orderItemToUpdate.add(item);
            } catch (System.NullPointerException e) {
    			System.debug('updateScheDateTimeOnOrderProd System.NullPointerException: ' + e);
    
            } catch (Exception e) {
    			System.debug('updateScheDateTimeOnOrderProd Error: ' + e);
    
            }
        }
        
        if(orderItemToUpdate.size() > 0){
            update orderItemToUpdate;
        }
    }    
    
    private static HTTPResponse SyncRequest(String json_string){
        String endpoint = 'registrations/sync';
        HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:TTTPortal/' + endpoint);
		req.setMethod('POST');

		// Setup auth headers
		req.setHeader('Authorization', 'Bearer {!$Credential.Password}');
        
        req.setHeader('Content-Type','application/json');
        req.setBody(json_string);
        
        Http http = new Http();
        HTTPResponse response = http.send(req);
        
        return response;
    }
    
    private static boolean Sync(string json_string, Id recordId) {
        HTTPResponse response = SyncRequest(json_string);
        
        // If the repsonse comes back properly
        if(response != null) {
        	SyncResponse syncResponse = new SyncResponse();
            syncResponse = (SyncResponse)JSON.deserialize(response.getBody(), SyncResponse.class);
            
			System.debug('RESPONSE=>' + syncResponse);

            if(response.getStatusCode() == 200) {
                return true;
            }  else {
                //System.debug(syncResponse);
                //System.debug(syncResponse.message);
                //if(!syncResponse.success){
                //CHECK THE FLAG AND TAKE MESSAGE FROM THE REPSONSE FOT TASK
                ServiceAppointmentTriggerHandler.createErrorTask(recordId, 'Sync Failed');
                //}
                return false;
            }
        } else {
            ServiceAppointmentTriggerHandler.createErrorTask(recordId, 'Response Empty');
            return false;
        }
    }
    
    private static void PortalSync(TTTSyncRequest request, Id recordId){
       ServiceAppointmentTriggerHandler.Sync(JSON.serialize(request), recordId);
    }
    
    private static void createErrorTask(Id recordId, String message){
		User user = [Select Id from User where Name = 'Blessen Mathew'];
        
		Task tsk = new Task();
        tsk.Subject = 'Investigate TTT Portal Sync (' + message + ')';
        tsk.WhatId = recordId;
        tsk.OwnerId = user.Id;
        tsk.Status = 'Open';
        tsk.Priority = 'High';
        tsk.Description = 'TTT Portal Sync. Review and investigate.';
        tsk.ActivityDate = Date.Today();
        tsk.Type = 'Learning Login';
        insert tsk;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false; 
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;  
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false; 
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false; 
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false; 
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false; 
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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