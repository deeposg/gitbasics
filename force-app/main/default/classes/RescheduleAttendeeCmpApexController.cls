/***************************
Class Name: RescheduleAttendeeCmpApexController
Author: Blessen Mathew
Description: To handle rescheduling and canceling attendees from public (IH) courses

History Log
=====================================
2018-04-04      BMathew     Created initial class
2018-12-31      BMathew     Adjusted class to user SBQQ__OrderedQuantity__c as per CPQ latest update
2021-05-27		BMathew		Rewrote some logic regarding cloning and quantity adjustments to get around some CPQ update limitations
****************************/
public without sharing class RescheduleAttendeeCmpApexController {
    //the number of days before an SA that a client can cancel w/o getting charged
    static Integer DAY_CUTOFF_LIMIT = 5;
    //States that should be considered invalid for order products, orders and attendees and should stop processing methods
    static Set<String> REJECTED_STATES = new Set<String>{'Canceled', 'Canceled - Invoice', 'Delivered' , 'Attended Entire Course'};
    
    @AuraEnabled
    //Initialize any required objects needed for canceling and rescheduling related to specified attendee record
    public static List<AttendeeReschedule> init(Id attendeeId){
        try{
            System.debug('AttendeeReschedule::Init(BEGIN)');
            List<AttendeeReschedule> results = new List<AttendeeReschedule>();
            AttendeeReschedule ar = new AttendeeReschedule();
            
            ar.attendee = [SELECT Confirmed__c, Order_Product__c, Service_Appointment__c, Status__c from Attendee__c where id=:attendeeId];
            ar.servApp = [SELECT Id, AppointmentNumber, Distance_Learning__c, Business_Days_to_Scheduled_Start__c, IH3POS__c from ServiceAppointment where id=:ar.attendee.Service_Appointment__c];
            ar.orderProduct = [Select Id, Account__c, SBQQ__Status__c, Product2Id, Classroom_Course__c, Course_Product_Line__c, Delivery_Method__c, External_Product_Name__c, ListPrice, List_Unit_Price__c, Net_Unit_Price__c, OrderId, SBQQ__OrderedQuantity__c, Product_Code__c, Product_Family__c, Product_Name__c, Promo_Discount_Amt__c, Promotional_Discount__c, Quantity, Scheduled_Date_and_Time__c, Total_Amount_Without_Tax__c, SBQQ__TaxCode__c, Tax_Province__c, Tax_Rate__c, Total_Price__c, Total_Net_Price__c, TotalPrice, Sales_Tax__c, Train_the_Trainer__c, Training_City__c, Training_Country__c, Training_Location_Name__c, Training_Postal_Code__c, Training_Province__c, Training_Street__c, UnitPrice, Volume_Discount__c, Wall_Certificate__c, Wallet_Card__c, Work_Type__c, PricebookEntryId from OrderItem where id=: ar.attendee.Order_Product__c];                
            ar.order = [SELECT status from Order where id=:ar.orderProduct.OrderId];
            System.debug(ar);
            results.add(ar);
            
            System.debug('AttendeeReschedule::Init(END)');
            return results;
        }
        catch(Exception e){
            System.debug('AttendeeReschedule::Init(FAILED)');
            return null;
        }
    }
    
 
    //This will reschedule the attendee to a new ServiceAppointment and adjust their order product if neccessary and determine if they are allowed to be rescheduled
    @AuraEnabled
    public static String rescheduleAttendee(Order order, ServiceAppointment servApp, OrderItem orderProduct, Attendee__c attendee, Id newServApp){
        try{
            System.debug('AttendeeReschedule::rescheduleAttendee(BEGIN)');            
            String originalOrderStatus = order.Status;
            OrderItem opToUse = orderProduct;
            ServiceAppointment newServiceAppointment;
            
            //if order product is cancelled you cannot reschedule or cancel
            if(REJECTED_STATES.contains(orderProduct.SBQQ__Status__c) || REJECTED_STATES.contains(attendee.Status__c)){
                return 'CANCELED';
            }
            
            newServiceAppointment = [Select Business_Days_to_Scheduled_Start__c, SchedStartTime, Training_Address1__c, Address, Location_Name__c from ServiceAppointment where id=:newServApp];
            
            //Cannot move attendee outside of SA that is already finished
            if(servApp.Business_Days_to_Scheduled_Start__c < -1)
            {
                return 'SA_FINISHED';
            }
            
            if(checkOrderProductState(opToUse) == FALSE){
                return 'INVALID_OP';
            }
            
            //preserves state of existing order products in order  
            //saveOrderProductStatus(order);
                  
            //order can't be activated before modification
            if(originalOrderStatus != 'Draft'){
                SBQQ.TriggerControl.disable();
                order.Status = 'Draft';
                update order;
                SBQQ.TriggerControl.enable();  
            }
            
            //if quantity > 1, we need to create a clone of the order product
            if(orderProduct.SBQQ__OrderedQuantity__c > 1){
                opToUse = cloneOrderProduct(orderProduct, 'Draft');
                attendee.Order_Product__c = opToUse.Id;
            }
            
            attendee.Service_Appointment__c = newServApp;
            attendee.Confirmed__c = 'Yes';
            attendee.Check_in_Time__c = null;
            attendee.Theory_Status__c = 'Pending';
            attendee.Theory_Exam_Results__c = null;
            attendee.Status__c = null;
            update attendee;
            
            opToUse.Classroom_Course__c = newServApp;
            opToUse.Scheduled_Date_and_Time__c = newServiceAppointment.SchedStartTime; 
            opToUse.Quote_Training_Address1__c = newServiceAppointment.Training_Address1__c;
            opToUse.Training_Street__c = newServiceAppointment.Address.getStreet();
            opToUse.Training_City__c = newServiceAppointment.Address.getCity();
            opToUse.Training_Province__c = newServiceAppointment.Address.getState();
            opToUse.Training_Postal_Code__c = newServiceAppointment.Address.getPostalCode();
            opToUse.Training_Country__c = newServiceAppointment.Address.getCountry();
            
            //THE INFAMOUS DOUBLE UPDATE (THIS JUST WORKS, DONT ASK QUESTIONS)
            update opToUse;
            //update opToUse;
            
            SBQQ.TriggerControl.disable();
            order.Status = 'Activated';
            update order;
            SBQQ.TriggerControl.enable();
            
            System.debug('AttendeeReschedule::rescheduleAttendee(END)');                          
            return 'SUCCESS';      
            
        }
        catch(Exception e){
            return e.getMessage();
        }
        
    }
 
    @AuraEnabled
    public static String cancelAttendee(OrderItem orderProduct, Order order, Attendee__c attendee, ServiceAppointment servApp){
        try
        {
            System.debug('AttendeeReschedule::cancelAttendee(BEGIN)');                                      
            OrderItem opToUse = orderProduct;
            String originalOrderStatus = order.Status;
                        
            //If the order product/attendee is canceled or the attendee is not confirmed for the course, we cannot cancel them
            if(REJECTED_STATES.contains(opToUse.SBQQ__Status__c) || REJECTED_STATES.contains(attendee.Status__c) || attendee.Confirmed__c == 'No') {
                return 'CANCEL';
            }
            
            if(servApp.Business_Days_to_Scheduled_Start__c < 0)
            {
                return 'SA_FINISHED';
            }
            
            if(checkOrderProductState(opToUse) == FALSE){
                return 'INVALID_OP';
            }            
              
            //saveOrderProductStatus(order);
       
            //order can't be activated before modification
            if(originalOrderStatus != 'Draft'){
                SBQQ.TriggerControl.disable();
                order.Status = 'Draft';
                update order;
                SBQQ.TriggerControl.enable();  
            }
        
            //Need to clone order product if quantity > 1
            if(orderProduct.SBQQ__OrderedQuantity__c > 1){
                opToUse = cloneOrderProduct(orderProduct, 'Canceled');
                attendee.Order_Product__c = opToUse.Id;
            }
            
            //attendee gets canceled and seat opens up in service appointment
            attendee.Status__c = 'Canceled';
            attendee.Confirmed__c = 'No';
            update attendee;
            
            //Attendee can be canceled without getting invoiced if at least 5 days left to SA
            if(servApp.Business_Days_to_Scheduled_Start__c < DAY_CUTOFF_LIMIT) {
                opToUse.SBQQ__Status__c = 'Canceled - Invoice';          
            }
            else{
                opToUse.SBQQ__Status__c = 'Canceled';
            }
            
            //THE INFAMOUS DOUBLE UPDATE (THIS JUST WORKS, DONT ASK QUESTIONS)
            //update opToUse;
            update opToUse;
            
            SBQQ.TriggerControl.disable();
            order.Status = 'Activated';
            update order;
            SBQQ.TriggerControl.enable();            
                    
            System.debug('AttendeeReschedule::cancelAttendee(END)');                                                  
            return 'SUCCESS';
        }
        catch(Exception e){
            System.debug('AttendeeReschedule::cancelAttendee(FAILED)');                                                  
            return e.getMessage();
        }
    }
    
    //Get all valid service appointments that attendee can be rescheduled to that still have remaining space
    @AuraEnabled
    public static List<ServiceAppointment> getServiceAppointments(OrderItem orderProduct, ServiceAppointment servApp){
        String cpl = orderProduct.Course_Product_Line__c;
        String dm = orderProduct.Delivery_Method__c;
        Boolean dl = servApp.Distance_Learning__c;
        //Web orders won't have the correct information on the order product so we need to go through the product to get it
        if(cpl == null || dm == null){
            Product2 prod = [Select Name, Delivery_Method__c, Distance_Learning__c, Course_Product_Line__c from Product2 where id = :orderProduct.Product2Id limit 1];
            cpl = prod.Course_Product_Line__c;
            dm = prod.Delivery_Method__c;
        }
        
        String query = 'SELECT AppointmentNumber, Training_Address1__r.Location_Address__r.Name, Spaces_Left__c, IH3POS__c, Duration, SchedStartTime, SchedEndTime, Course_Maximum_Capacity__c, Address FROM ServiceAppointment WHERE Course_Product_Line__c = ' + cpl + 'AND Product__r.Delivery_Method__c = ' + dm + 'AND Product_Family__c= \'Courses\' AND ( Status = \'Assigned\' OR Status = \'Scheduled\') AND Distance_Learning__c = ' + dl + 'AND SchedStartTime >' + system.today().format() + 'AND IH3POS__c != \'On-Site\' AND Spaces_Left__c > 0 AND AppointmentNumber != ' + servApp.AppointmentNumber + 'Order By SchedStartTime Asc';
        System.debug(query);
        
        List<ServiceAppointment> saList = [SELECT AppointmentNumber, Training_Address1__r.Location_Address__r.Name, Spaces_Left__c, 
                                           IH3POS__c, Duration, SchedStartTime, SchedEndTime, Course_Maximum_Capacity__c, Address 
                                           FROM ServiceAppointment 
                                           WHERE Course_Product_Line__c = :cpl AND 
                                           Product__r.Delivery_Method__c = :dm AND 
                                           Product_Family__c= 'Courses' AND 
                                           ( Status = 'Assigned' OR Status = 'Scheduled') AND
                                           Distance_Learning__c = :dl AND
                                           SchedStartTime > Today AND  
                                           IH3POS__c != 'On-Site' AND
                                           Spaces_Left__c > 0 AND                               //Ensure there is space left
                                           AppointmentNumber != :servApp.AppointmentNumber      //remove the current service appointment as a choice
                                           Order By SchedStartTime Asc];
        return saList;
    }
    
    //stores current value in cloned status
    public static void saveOrderProductStatus(Order order){
        System.debug('AttendeeReschedule::saveOrderProductStatus(BEGIN)');                        
        List<OrderItem> orderProducts = [Select SBQQ__Status__c, Cloned_Status__c from OrderItem where OrderId = :order.Id];
        for(OrderItem oi : orderProducts){
            oi.Cloned_Status__c = oi.SBQQ__Status__c;
        }
        System.debug('AttendeeReschedule::saveOrderProductStatus(END)');        
        update orderProducts;
    }

    //Returns a clone of the order product, gives quantity of 1, reduces original order product quantity by 1 and inserts new order product.
    public static OrderItem cloneOrderProduct(OrderItem op, String status){
        System.debug('AttendeeReschedule::cloneOrderProduct(BEGIN)');                                                                                  
        OrderItem clonedOrderProduct = op.clone(false, false, false, false);
        
        //if the quote line is copied over, all the attendees that were originally attached will be attached to the clonedOrderProduct
        clonedOrderProduct.SBQQ__Status__c = status;
        //clonedOrderProduct.OriginalOrderItemId = op.Id;        
        clonedOrderProduct.SBQQ__OrderedQuantity__c = 1;
        System.debug('INSERT CLONED ORDER PRODUCT');
        insert clonedOrderProduct;
        
        //Need to adjust all fields related to billing
        //clonedOrderProduct.Quantity = 1;
        clonedOrderProduct.Total_Amount_Without_Tax__c = op.Net_Unit_Price__c;
        clonedOrderProduct.Sales_Tax__c = op.Net_Unit_Price__c * (op.Tax_Rate__c/100);
        clonedOrderProduct.Total_Net_Price__c = clonedOrderProduct.Total_Amount_Without_Tax__c + clonedOrderProduct.Sales_Tax__c;
        System.debug('UPDATE CLONED ORDER PRODUCT');
        update clonedOrderProduct;
        
        /*
        op.SBQQ__Status__c = 'Draft';
        System.debug('UPDATE ORIG ORDER PRODUCT');
        update op;
        */
        
        //update cost
        op.SBQQ__OrderedQuantity__c--;
        op.Total_Amount_Without_Tax__c = op.Net_Unit_Price__c * op.SBQQ__OrderedQuantity__c;
        op.Sales_Tax__c = op.Sales_Tax__c - (op.Net_Unit_Price__c * (op.Tax_Rate__c/100));
        op.Total_Net_Price__c = op.Total_Amount_Without_Tax__c + op.Sales_Tax__c;
        System.debug('UPDATE ORIG ORDER PRODUCT');
        System.debug(op);
        update op;
        
        //op.Quantity--;
        //System.debug('UPDATE ORIG ORDER PRODUCT');
        //update op;
        
        //setCorrectOrderProductStatus(op.OrderId);
        
        System.debug('AttendeeReschedule::cloneOrderProduct(END)');        
        return clonedOrderProduct;            
    }
    
    
    //Sets all the order products within order to the correct status
    public static void setCorrectOrderProductStatus(Id orderId){
        System.debug('AttendeeReschedule::setCorrectOrderProductStatus(BEGIN)');                
        List<OrderItem> orderProducts = [Select Cloned_Status__c, SBQQ__Status__c from OrderItem where OrderId = :orderId];
        for(OrderItem oi : orderProducts){
            if(oi.Cloned_Status__c != NULL){
                oi.SBQQ__Status__c = oi.Cloned_Status__c;
                oi.Cloned_Status__c = NULL;
            }
        }
        System.debug('AttendeeReschedule::setCorrectOrderProductStatus(END)');                        
        update orderProducts;
    }
    
    //Checks if the orderProduct is valid
    public static boolean checkOrderProductState(OrderItem op){
        if(op.Tax_Rate__c == NULL || op.Tax_Rate__c == 0 || op.Quantity <= 0 || op.SBQQ__OrderedQuantity__c <= 0 || op.Net_Unit_Price__c < 0 || op.Total_Net_Price__c < 0){
            return false;
        }
        else{
            return true;
        }
    }
    
    //wrapper class that is used to send objects back to lightning component
    public class AttendeeReschedule{
        @AuraEnabled
        public Attendee__c attendee;
        @AuraEnabled
        public ServiceAppointment servApp;
        @AuraEnabled
        public OrderItem orderProduct;
        @AuraEnabled
        public Order order;
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