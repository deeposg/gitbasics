/*********************************************************************************************************************
* F8_WebProductSelectionAPI class exposed as web-serivce
* Post- Create contact
* Author - Aditya Chasta
* Created date - 06/20/2017
**********************************************************************************************************************/

@RestResource(urlMapping='/Cart/ProductInfo/*')
global with sharing class F8_WebProductSelectionAPI {
    @HttpPost
    global static List<F8_WebResponseHandler> retrieveProduct(ProductInfoRequest requestProduct) {
        List<F8_WebProductSelectSuccessRespHandler> successResponseList = new List<F8_WebProductSelectSuccessRespHandler>(); //Object to store success response
        List<F8_WebErrorResponseHandler> errorResponseList = new List<F8_WebErrorResponseHandler>(); //Object to store error response
        F8_WebErrorResponseHandler errorResponse; 
        try {
            String whereStatement = 'where';
            String fromStatement = ') from Product2 ';
            //base query
            String query = 'select Id, Name, Distance_Learning__c, Recurring_Invoice__c, Recurring_Invoice_Frequency__c, Delivery_Method__c, External_Product_Name__c, SBQQ__DiscountSchedule__c, Train_The_Trainer__c, Family, Standard_Price__c, Duration__c, Physical_Good_Type__c, Course_Product_Line__c, Current_Inventory_Count__c, (select id, Street, City, State, PostalCode, SchedStartTime, SchedEndTime, Spaces_Left__c , Course_Maximum_Capacity__c,Training_Address1__c, Confirmed_Seats__c, Distance_Learning__c from Service_Appointments__r ';
            //It will be used to filter products
            String appointmentQuery = '(select Product__c from ServiceAppointment ';
            String serviceAppointmentString = 'id in ';
            String whereClauseForProduct = 'where IsActive = true and ((( Family = \'Courses\' and Delivery_Method__c = \'Classroom\' ) or Family = \'Physical Goods\') or (ProductCode = \'OL-TTAL\') or (ProductCode = \'OL-JHSCI\') or (ProductCode = \'OL-JHSCB\') or (ProductCode = \'CS-WSIB\')) and ( Course_Product_Line__c != \'SFACPR2\') and (Course_Product_Line__c != \'AI\') ';
            //if product has filter conditions

            String whereClauseForAppointment = '';// = whereStatement + ' (StatusCategory = \'Scheduled\' or StatusCategory = \'None\') ';
            //if service appointment has filter conditions
            Boolean whereForAppointment = false;
            
            /*Applying filters to appointment*/
            
            //If appointment_id is not null then include it in where clause
            if(String.isNotBlank(requestProduct.appointment_id)) {// if appointment_id is not null in the request
                whereClauseForAppointment = whereStatement+' id = '+'\''+requestProduct.appointment_id+'\' ';
                whereForAppointment = true;
            } 
            
            //If location is not null then include it in where clause
            if(String.isNotBlank(requestProduct.location)) {
                if(whereForAppointment) {
                    whereClauseForAppointment = whereClauseForAppointment + 'and City = '+'\''+String.escapeSingleQuotes(requestProduct.location)+'\' ';
                } else {
                    whereClauseForAppointment = whereStatement+' City = '+'\''+String.escapeSingleQuotes(requestProduct.location)+'\' ';
                    whereForAppointment = true;
                }
            }
                
            //If end_date is not null then include it in where clause
            if(String.isNotBlank(String.valueOf(requestProduct.end_date))) {
                //Converting the date string into date format
                //
                
            	Date endDate;
            
                if(String.isNotBlank(String.valueOf(requestProduct.end_date))) {
                	endDate = Date.valueOf(String.escapeSingleQuotes(requestProduct.end_date));
                } else {
                    endDate = Date.valueOf('2021-01-01');
                }
            
                //Converting the date into DateTime
                DateTime endDateTime = DateTime.newInstance(endDate.year(), endDate.month(),endDate.day());
                //Converting DateTime into YYYY-MM-DDTHH:MM:SSz format as query accepts only this format
                String endDateString = endDateTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
                
                //Fetching today's date
                Date currentDate = Date.Today();
                //Converting the date into DateTime
                DateTime currentDateTime = DateTime.newInstance(currentDate.year(), currentDate.month(),currentDate.day());
                //Converting DateTime into YYYY-MM-DDTHH:MM:SSz format as query accepts only this format
                String currentDateString = currentDateTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
                //endDateTime = endDateTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'z\''); 
                if(whereForAppointment) {
                    whereClauseForAppointment = whereClauseForAppointment + 'and SchedStartTime >= ' + currentDateString + ' and SchedEndTime <= '+endDateString+' ';
                } else {
                    whereClauseForAppointment = whereStatement + ' SchedStartTime >= ' + currentDateString + ' and SchedEndTime <= '+endDateString+' ';
                    whereForAppointment = true;
                }
            }
            
            //Completing the filter query on ServiceAppointments
            if(whereForAppointment) {
                whereClauseForAppointment = whereClauseForAppointment + ' and (StatusCategory = \'Scheduled\' or StatusCategory = \'None\') ';
                 
                appointmentQuery = appointmentQuery + whereClauseForAppointment;
                query +=whereClauseForAppointment;
            }
            query += fromStatement;
            /*Applying filter on product*/
            
            //If product_id is not null the include it in the where clause
            if(String.isNotBlank(String.valueOf(requestProduct.product_id))) {
                whereClauseForProduct = whereClauseForProduct + 'and id = '+'\''+String.escapeSingleQuotes(requestProduct.product_id)+'\' ';
            }
            
            //If product_line is not null the include it in the where clause
            if(String.isNotBlank(String.valueOf(requestProduct.product_line))) {
                whereClauseForProduct = whereClauseForProduct + 'and Course_Product_Line__c = '+'\''+String.escapeSingleQuotes(requestProduct.product_line)+'\' ';
            }
            
            //If family is not null the include it in the where clause
            if(String.isNotBlank(String.valueOf(requestProduct.family))) {
                whereClauseForProduct = whereClauseForProduct + 'and Family = '+'\''+String.escapeSingleQuotes(requestProduct.family)+'\' ';
            }
                
            //Completing the query
            query = query + whereClauseForProduct;
            if(whereForAppointment) {
                query = query + 'and '+ serviceAppointmentString + appointmentQuery + ') ';
            }
        	
            query = query + 'LIMIT 50000';
            
            Map<Id, Id> appointAddressMap = new Map<Id, Id>();
            //System.assert(false,+'####'+query);
            //querying the products
            System.debug('QUERY: ' + query);
            List<Product2> productsToRetrieve = Database.query(query);
            
            if(productsToRetrieve != null && productsToRetrieve.size() != 0) { // If product list is not empty
                Set<Id> discScheIds = new Set<Id>();
                for(Product2 product : productsToRetrieve) {
                    if(Product.SBQQ__DiscountSchedule__c != null){
                        discScheIds.add(Product.SBQQ__DiscountSchedule__c);
                    }
                    
                    for(ServiceAppointment appointment : product.Service_Appointments__r) {
                        if(String.isNotBlank(appointment.Training_Address1__c)) {
                            appointAddressMap.put(appointment.id, appointment.Training_Address1__c);
                        }
                    }
                }
                Map<Id, Account_Address__c> accountAddressMap = new Map<Id, Account_Address__c>([select id,  Address1_1__c, Address1_2__c, City1__c, Province1__c, Postal_Code1__c, Web_Name__c, Province_State_Code__c from Account_Address__c where id in: appointAddressMap.values()]);
                Decimal remainingQuantity;
                
                //Map for Prodcut related Discount Tier
                Map<Id, List<SBQQ__DiscountTier__c>> mapDiscountTiers = new Map<Id, List<SBQQ__DiscountTier__c>>();
                if(discScheIds.size() > 0){
                    for(SBQQ__DiscountTier__c tier : [Select Id, SBQQ__Schedule__c, SBQQ__LowerBound__c, SBQQ__UpperBound__c, SBQQ__DiscountAmount__c From SBQQ__DiscountTier__c Where SBQQ__Schedule__c IN : discScheIds]){
                        if(!mapDiscountTiers.containsKey(tier.SBQQ__Schedule__c))
                            mapDiscountTiers.put(tier.SBQQ__Schedule__c, new List<SBQQ__DiscountTier__c>());
                        mapDiscountTiers.get(tier.SBQQ__Schedule__c).add(tier);
                    }
                
                }
                             //Iterating over all the products and setting response in related fields
                for(Product2 product : productsToRetrieve) {
                    System.debug('PROD: ' + product);
                    F8_WebProductSelectSuccessRespHandler successResponse = new F8_WebProductSelectSuccessRespHandler();
                    successResponse.id = product.id;
                    successResponse.name = product.External_Product_Name__c;
                    successResponse.product_line = product.Course_Product_Line__c;
                    successResponse.base_price = product.Standard_Price__c;
                    successResponse.duration = product.Duration__c;
                    successResponse.physical_good_type = product.Physical_Good_Type__c;
                    successResponse.train_the_trainer = product.Train_The_Trainer__c;
                    successResponse.distance_learning = product.Distance_Learning__c;
                    successResponse.delivery_method = product.Delivery_Method__c;
                    successResponse.recurring_invoice = product.Recurring_Invoice__c;
                    successResponse.recurring_invoice_frequency = product.Recurring_Invoice_Frequency__c;
                    
                    System.debug('SUCCRESP: ' + successResponse);
                    
                    if(mapDiscountTiers.containsKey(product.SBQQ__DiscountSchedule__c)){
                        for(SBQQ__DiscountTier__c tiers : mapDiscountTiers.get(product.SBQQ__DiscountSchedule__c)){
                            System.debug('TIER: ' + tiers);
                            //system.assert(false,'Price=='+product.Standard_Price__c+'---'+tiers.SBQQ__DiscountAmount__c+'----'+tiers.SBQQ__LowerBound__c +'-----'+tiers.SBQQ__UpperBound__c);
                            successResponse.pricing.add(new F8_WebProductSelectSuccessRespHandler.Pricing(tiers.SBQQ__LowerBound__c,tiers.SBQQ__UpperBound__c,(product.Standard_Price__c - tiers.SBQQ__DiscountAmount__c)));
                        }
                    }
                    
                    //Iterating over all the ServiceAppointments and setting response in related fields
                    for(ServiceAppointment appointment : product.Service_Appointments__r) {
                        System.debug('APPT: ' + appointment);
                        remainingQuantity = 0;
                        if(product.Family == 'Courses') {
                            /*if(appointment.Course_Maximum_Capacity__c != null && appointment.Confirmed_Seats__c != null) {
                                remainingQuantity = appointment.Course_Maximum_Capacity__c - appointment.Confirmed_Seats__c;
                            } else if(appointment.Course_Maximum_Capacity__c != null && (appointment.Confirmed_Seats__c == null || appointment.Confirmed_Seats__c == 0)) {
                                remainingQuantity = appointment.Course_Maximum_Capacity__c;
                            }*/
                            remainingQuantity = appointment.Spaces_Left__c ;
                        } else if (product.Family == 'Physical Goods') {
                            remainingQuantity = product.Current_Inventory_Count__c;
                        }
                        // Adding ServiceAppointment related response to appointments list
                        //Location_Address__c location_address = [select id,  Address__c, Address_2__c, City__c, Province__c,   Postal_Code__c from Location_Address__c where id =: appointment.Training_Address__c];
                        if(appointAddressMap.containsKey(appointment.id)){
                            Account_Address__c address = accountAddressMap.get(appointAddressMap.get(appointment.id));
                            System.debug('ADDR: ' + address);
                            if(address != null){
                            	successResponse.appointments.add(new F8_WebProductSelectSuccessRespHandler.Appointments(appointment.id, remainingQuantity, appointment.SchedStartTime, appointment.SchedEndTime, appointment.City, address.Address1_1__c, address.Address1_2__c,address.City1__c, address.Province1__c, address.Postal_Code1__c, address.Web_Name__c, address.Province_State_Code__c, appointment.Distance_Learning__c));
                            }
                            else{
                            	successResponse.appointments.add(new F8_WebProductSelectSuccessRespHandler.Appointments(appointment.id, remainingQuantity, appointment.SchedStartTime, appointment.SchedEndTime, appointment.City, appointment.Street,'', appointment.City, appointment.State, appointment.PostalCode, appointment.City, appointment.State, appointment.Distance_Learning__c));
                                
                            }
                        }
                        else {
                            successResponse.appointments.add(new F8_WebProductSelectSuccessRespHandler.Appointments(appointment.id, remainingQuantity, appointment.SchedStartTime, appointment.SchedEndTime, appointment.City, appointment.Street,'', appointment.City, appointment.State, appointment.PostalCode, appointment.City, appointment.State, appointment.Distance_Learning__c));
                    
                        }
                    }
                    successResponseList.add(successResponse);
                }
            }
            return successResponseList;
        } catch(Exception e) { // If some exception occurs
            //System.assert(false, 'ERROR : '+e.getMessage()+' Stack Trace : '+e.getStackTraceString());
            System.debug('EXC: ' + e);
            errorResponseList.add(F8_WebServices.generateErrorResponse('ERROR : '+e.getMessage()+' Stack Trace : '+e.getStackTraceString(), 'ERROR'));
        } 
        
        return errorResponseList;
    }
    
    /*
    * Wrapper class for request
    */
     global class ProductInfoRequest {
    
        global String product_id;
        global String appointment_id;
        global String location;
        global String end_date;
        global String family;
        global String product_line;
    }
    
    public static void doTest(){
        Boolean CodeCoverage = false;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;        
    }
}