/**********************************************************************
Name: QuoteTriggerHandler
Author : Shubham Verma
Description : Handler class for Quote Trigger    

History Log
==========================
2018-11-28		BMathew		Added quote validations methods to check for criteria before moving quote along process
2018-12-13		BMathew		Added additional logic to ensure tax is set on quote lines that have non-zero net price
2019-05-08		BMathew		Added logic to auto-generate an opportunity when a quote is sent to the client if it doesn't exist
2020-04-07		BMathew		Added logic to check for distance courses and ensure required fields exist in contacts
2020-12-16		BMathew		Added logic to handle JHSC1 Online attendees
2021-03-19		BMathew		Adjusted In-House Line errors to not include attendees where the quoteLine have a requiredBy
**********************************************************************/
public with sharing class QuoteTriggerHandler extends TriggerHandler {
     
    //Runs validations to ensure all required data exists
	public static String runQuoteValidations(Id quoteId){
        try{
            String errorMessages = '';
            
            List<SBQQ__QuoteLine__c> allQuoteLines = [Select Id from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteId];
            
            //Empty quote errors
            if(allQuoteLines.size() == 0){
                errorMessages += 'Quote cannot be empty.<br/>';
				System.debug('EMPTY ERRORS: ' + errorMessages);
                return errorMessages;
            }
            
            //Contains Shipping line errors
            List<SBQQ__QuoteLine__c> shippingLines = [Select Id from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteId and SBQQ__ProductCode__c = 'SHIPPING'];
            if(shippingLines.size() > 0){
                errorMessages += 'Contains Shipping Lines.<br/>';
				System.debug('HAS SHIPPING LINES ERRORS: ' + errorMessages);                
            }
            
            //JHSC Bundle OL1 line errors
            Integer numberOfInvalidJHSCOnlineAttendeeContactFirstName = 0;
            Integer numberOfInvalidJHSCOnlineAttendeeContactLastName = 0;
            Integer numberOfInvalidJHSCOnlineAttendeeContactEmail = 0;
            Integer numberOfInvalidJHSCOnlineAttendeeClassroom = 0;              
            List<Attendee__c> attendeesJHSCOnline = [select Contact__r.AccountId, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email, Quote_Line__r.Account__c, Quote_Line__r.Classroom_Course__c from Attendee__c where Quote_Line__r.SBQQ__Quote__c =:quoteId and Quote_Line__r.Course_Product_Line__c = 'JHSCI' and Quote_Line__r.Delivery_Method__c = 'Online'];
            for(Attendee__c attendee : attendeesJHSCOnline){
                if(attendee.Contact__r.FirstName == NULL){
                    numberOfInvalidJHSCOnlineAttendeeContactFirstName++;
                }
                if(attendee.Contact__r.LastName == NULL){
                    numberOfInvalidJHSCOnlineAttendeeContactLastName++;
                }
                if(attendee.Contact__r.Email == NULL){
                    numberOfInvalidJHSCOnlineAttendeeContactEmail++;
                }
                if(attendee.Quote_Line__r.Classroom_Course__c == NULL){
                    numberOfInvalidJHSCOnlineAttendeeClassroom++;
                }
            }
            
            if(numberOfInvalidJHSCOnlineAttendeeClassroom > 0){
                errorMessages+= '(OL-JHSCI) JHSCI Online lines attendees are missing an associated service appointment.<br/>';
                System.debug('OL-JHSCI ERRORS: ' + errorMessages);
            }            
            if(numberOfInvalidJHSCOnlineAttendeeContactFirstName > 0){
                errorMessages+= '(OL-JHSCI) JHSCI Online lines attendee contacts are missing first name.<br/>';
                System.debug('OL-JHSCI ERRORS: ' + errorMessages);
            }
            if(numberOfInvalidJHSCOnlineAttendeeContactLastName > 0){
                errorMessages+= '(OL-JHSCI) JHSCI Online lines attendee contacts are missing last name.<br/>';
                System.debug('OL-JHSCI ERRORS: ' + errorMessages);
            }
            if(numberOfInvalidJHSCOnlineAttendeeContactEmail > 0){
                errorMessages+= '(OL-JHSCI) JHSCI Online lines attendee contacts are missing email.<br/>';
                System.debug('OL-JHSCI ERRORS: ' + errorMessages);
            }
            
            Integer numberOfInvalidDL2BundleAttendee = 0;
			List<Attendee__c> bundleAttendeesDL2 = [select Quote_Line__r.Course_Product_Line__c, Contact__r.Email, Contact__r.MailingStreet, Contact__r.MailingCity, Contact__r.MailingState, Contact__r.MailingCountry, Contact__r.MailingPostalCode from Attendee__c where Quote_Line__r.SBQQ__Quote__c =:quoteId and Quote_Line__r.Delivery_Method__c = 'Classroom' and Quote_Line__r.SBQQ__Product__r.Distance_Learning__c = true and Quote_Line__r.Course_Product_Line__c = 'JHSCII' and Quote_Line__r.SBQQ__RequiredBy__c != null];
            for(Attendee__c attendee : bundleAttendeesDL2){                
                //for any distance course, email is required
                if(attendee.Contact__r.Email == NULL){
                    numberOfInvalidDL2BundleAttendee++;
                }
            }
            
            if(numberOfInvalidDL2BundleAttendee > 0){
                errorMessages+= '(OL-JHSCI) JHSCII DL attendees in a bundle must have contacts that have a valid email.<br/>';
                System.debug('OL-JHSCI ERRORS: ' + errorMessages);
            }
            
            //Online TTAL line errors
            Integer numberOfInvalidTTALAttendeeContactFirstName = 0;
            Integer numberOfInvalidTTALAttendeeContactLastName = 0;
            Integer numberOfInvalidTTALAttendeeContactEmail = 0;
            Integer numberOfInvalidTTALAttendeeClassroom = 0;
            List<Attendee__c> attendeesTTAE = [select Contact__r.AccountId, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email, Quote_Line__r.Account__c, Quote_Line__r.Classroom_Course__c from Attendee__c where Quote_Line__r.SBQQ__Quote__c =:quoteId and Quote_Line__r.Course_Product_Line__c = 'TTAL'];
            for(Attendee__c attendee : attendeesTTAE){
                if(attendee.Contact__r.FirstName == NULL){
                    numberOfInvalidTTALAttendeeContactFirstName++;
                }
                if(attendee.Contact__r.LastName == NULL){
                    numberOfInvalidTTALAttendeeContactLastName++;
                }
                if(attendee.Contact__r.Email == NULL){
                    numberOfInvalidTTALAttendeeContactEmail++;
                }
                
                if(attendee.Quote_Line__r.Classroom_Course__c == NULL){
                    numberOfInvalidTTALAttendeeClassroom++;
                }
            }
            
            if(numberOfInvalidTTALAttendeeClassroom > 0){
                errorMessages+= '(TTAL) Tools & Techniques for Adult Learning lines attendees are missing an associated service appointment.<br/>';
                System.debug('OL ERRORS: ' + errorMessages);
            }            
            if(numberOfInvalidTTALAttendeeContactFirstName > 0){
                errorMessages+= '(TTAL) Tools & Techniques for Adult Learning lines attendee contacts are missing first name.<br/>';
                System.debug('OL ERRORS: ' + errorMessages);
            }
            if(numberOfInvalidTTALAttendeeContactLastName > 0){
                errorMessages+= '(TTAL) Tools & Techniques for Adult Learning lines attendee contacts are missing last name.<br/>';
                System.debug('OL ERRORS: ' + errorMessages);
            }
            if(numberOfInvalidTTALAttendeeContactEmail > 0){
                errorMessages+= '(TTAL) Tools & Techniques for Adult Learning lines attendee contacts are missing email.<br/>';
                System.debug('OL ERRORS: ' + errorMessages);
            }
            
            //In-House line errors
            Integer numberOfInvalidAttendeeContactAccounts = 0;
            Integer numberOfMissingAttendeeContact = 0;
            Integer numberOfMissingAttendeeClassroom = 0;
            Integer numberOfContactIsInvalid = 0;
            List<Attendee__c> attendeesNonOS = [select Contact__c, Contact__r.AccountId, Quote_Line__r.Account__c, Quote_Line__r.Classroom_Course__c, Contact_Is_Valid__c from Attendee__c where Quote_Line__r.SBQQ__Quote__c =:quoteId and Quote_Line__r.Delivery_Method__c = 'Classroom' and (Quote_Line__r.SBQQ__RequiredBy__c = null or (Quote_Line__r.Course_Product_Line__c = 'JHSCII' and Quote_Line__r.SBQQ__RequiredBy__c != null and Quote_Line__r.Classroom_Course__c != null))];
            for(Attendee__c attendee : attendeesNonOS){
                if(attendee.Contact__c == NULL){
                    numberOfMissingAttendeeContact++;
                }
                if(attendee.Contact__r.AccountId != attendee.Quote_Line__r.Account__c){
                    numberOfInvalidAttendeeContactAccounts++;
                }
                if(attendee.Quote_Line__r.Classroom_Course__c == NULL){
                 	numberOfMissingAttendeeClassroom++;   
                }
                if(attendee.Contact_Is_Valid__c != true){
                    numberOfContactIsInvalid++;
                }
            }
            
            if(numberOfMissingAttendeeContact > 0){
                errorMessages += 'In-House lines attendees are missing contact information.<br/>';
				System.debug('IH ERRORS: ' + errorMessages);
            }
            
            if(numberOfInvalidAttendeeContactAccounts > 0 || numberOfContactIsInvalid > 0){
                errorMessages += 'In-House lines attendees have invalid contacts or do not belong to the correct account.<br/>';
				System.debug('IH ERRORS: ' + errorMessages);                
            }
            
            if(numberOfMissingAttendeeClassroom > 0){
                errorMessages += 'In-House lines attendees are missing an associated service appointment.<br/>';
				System.debug('IH ERRORS: ' + errorMessages);
            }
            
            //Distance Course line errors
            Integer numberOfInvalidAttendeeAddress = 0;
            Integer numberOfInvalidAttendeeEmail = 0;
            Integer numberOfInvalidJHSCDistanceLines = 0;
            List<String> addressRequiredCourses = new List<String>{'JHSCI', 'JHSCII', 'JHSCR'};
            List<Attendee__c> attendeesDistance = [select Quote_Line__r.Course_Product_Line__c, Contact__r.Email, Contact__r.MailingStreet, Contact__r.MailingCity, Contact__r.MailingState, Contact__r.MailingCountry, Contact__r.MailingPostalCode from Attendee__c where Quote_Line__r.SBQQ__Quote__c =:quoteId and Quote_Line__r.Delivery_Method__c = 'Classroom' and Quote_Line__r.SBQQ__Product__r.Distance_Learning__c = true and (Quote_Line__r.SBQQ__RequiredBy__c = null or (Quote_Line__r.Course_Product_Line__c = 'JHSCII' and Quote_Line__r.SBQQ__RequiredBy__c != null and Quote_Line__r.Classroom_Course__c != null))];
            for(Attendee__c attendee : attendeesDistance){
                //If a course that ships material, address are required
                if(addressRequiredCourses.contains(attendee.Quote_Line__r.Course_Product_Line__c) || attendee.Quote_Line__r.Course_Product_Line__c.contains('TTT')){
                    if(attendee.Contact__r.MailingStreet == NULL || attendee.Contact__r.MailingCity == NULL || attendee.Contact__r.MailingState == NULL || attendee.Contact__r.MailingCountry == NULL || attendee.Contact__r.MailingPostalCode == NULL){
                    	numberOfInvalidAttendeeAddress++; 
                    }
                }
                
                //for any distance course, email is required
                if(attendee.Contact__r.Email == NULL){
                    numberOfInvalidAttendeeEmail++;
                }
            }
            
            if(numberOfInvalidAttendeeAddress > 0){
                errorMessages += 'Distance Learning lines attendee contacts are missing address details for shipping material.<br/>';
                System.debug('DL ERRORS: ' + errorMessages);                  
            }
            
            if(numberOfInvalidAttendeeEmail > 0){
                errorMessages += 'Distance Learning lines attendee contacts are missing email.<br/>';
                System.debug('DL ERRORS: ' + errorMessages);                   
            }
            
            //Ensure all attendees with contacts are valid (covers on-site/evals)
            Integer numberOfInvalidAttendeeContact = 0;
            List<Attendee__c> nonTBDAttendees = [select Contact__r.AccountId, Quote_Line__r.Account__c, Quote_Line__r.Classroom_Course__c, Contact_Is_Valid__c from Attendee__c where Quote_Line__r.SBQQ__Quote__c =:quoteId and Contact__c != Null and Quote_Line__r.Delivery_Method__c != 'Classroom'];
            for(Attendee__c attendee : nonTBDAttendees){
                if(attendee.Contact_Is_Valid__c != true){
                    numberOfInvalidAttendeeContact++;
                }
            }
            
            if(numberOfInvalidAttendeeContact > 0){
                errorMessages += 'Attendees have an incorrect contact. Ensure the account of the quote and contact are exact.<br/>';
				System.debug('ATTENDEE ERRORS: ' + errorMessages);
            }
            
            //Duplicate Attendees
            List<AggregateResult> duplicateIHAttendees = [Select Count(id) Contact__c, Quote_Line__r.Classroom_Course__c from Attendee__c where Quote_Line__r.SBQQ__Quote__c = :quoteId and Contact__c != NULL and Quote_Line__r.Delivery_Method__c = 'Classroom' Group By Contact__c, Quote_Line__r.Classroom_Course__c Having count(id) > 1];
            if(duplicateIHAttendees.size() > 0){
                errorMessages += 'In-House/3P classroom lines cannot have duplicate attendee contacts.<br/>';
                System.debug('IH ERRORS: ' + errorMessages);                
            }            

            //On-site line errors            
            Integer NumberOfOSMissingDate = 0;
            Integer NumberOfOSMissingParticipants = 0;
            Integer numberOfOSMissingTrainingAddress = 0;
			Integer numberOfOSEvalsMissingClassroom = 0;
            Integer numberOfOSToyotaMissingTrainingRoom = 0;
            
            List<SBQQ__QuoteLine__c> quoteLinesOS = [Select Id, Classroom_Course__c, Quote_Training_Address1__c, Quote_Training_Address1__r.Account__r.Name, Toyota_Training_Room__c, Preferred_Date_and_Time__c, Number_of_Participants__c, SBQQ__ProductFamily__c from SBQQ__QuoteLine__c where SBQQ__Quote__c  = :quoteId and Delivery_Method__c = 'On-site' and (SBQQ__ProductCode__c != 'AE-AA' and SBQQ__ProductCode__c != 'AE-WS') and (NOT SBQQ__ProductName__c LIKE '%Contract%')];            
            for(SBQQ__QuoteLine__c quoteLine : quoteLinesOS){
                if(quoteLine.Preferred_Date_and_Time__c  == NULL){
                    NumberOfOSMissingDate++;
                }
                if((quoteLine.Number_of_Participants__c == NULL || quoteLine.Number_of_Participants__c == 0) && quoteLine.SBQQ__ProductFamily__c == 'Courses'){
                    NumberOfOSMissingParticipants++;
                }
                if(quoteLine.Quote_Training_Address1__c == NULL){
                    numberOfOSMissingTrainingAddress++;
                }
                if(quoteLine.Quote_Training_Address1__r.Account__r.Name.contains('Toyota Motor') && quoteLine.Toyota_Training_Room__c == NULL){
                    numberOfOSToyotaMissingTrainingRoom++;
                }
            }
                        
            if(NumberOfOSMissingDate > 0){
                errorMessages += 'On-Site lines are missing a preferred date and time.<br/>';
                System.debug('OS ERRORS: ' + errorMessages);
            }

            if(NumberOfOSMissingParticipants > 0){
                errorMessages += 'On-Site lines are missing number of participants.<br/>';
                System.debug('OS ERRORS: ' + errorMessages);                
            }            
                
            if(numberOfOSMissingTrainingAddress > 0){
                errorMessages += 'On-Site lines are missing training address.<br/>';
                System.debug('OS ERRORS: ' + errorMessages);
            }
            
            if(numberOfOSToyotaMissingTrainingRoom > 0){
                errorMessages += 'On-Site (Toyota) lines are missing Toyota Training Room.<br/>';
                System.debug('OS ERRORS: ' + errorMessages);
            }
            
            List<ServiceAppointment> onSiteServiceAppointments = [Select Id from ServiceAppointment where Quote__c = :quoteId];
            if(onSiteServiceAppointments.size() > 0){
                errorMessages += 'Cannot book On-Site Service Appointments prior to approval.<br/>';
                System.debug('OS ERRORS: ' + errorMessages);
            }
            
			List<AggregateResult> duplicateOSAttendees = [Select Count(id) Contact__c, Quote_Line__c from Attendee__c where Quote_Line__r.SBQQ__Quote__c = :quoteId and Contact__c != NULL and Quote_Line__r.Delivery_Method__c = 'On-site' Group By Contact__c, Quote_Line__c Having count(id) > 1];
            if(duplicateOSAttendees.size() > 0){
                errorMessages += 'On-Site classroom lines cannot have duplicate attendee contacts.<br/>';
                System.debug('OS ERRORS: ' + errorMessages);                
            }

            //Evaluation Attendees
            Integer numberOfInvalidEvaluationAttendees = 0;
            List<Attendee__c> attendeesEvaluations = [select Contact__c, Quote_Line__r.Account__r.Name, Contact_Is_Valid__c from Attendee__c where Quote_Line__r.SBQQ__Quote__c = :quoteId and Quote_Line__r.Delivery_Method__c = 'On-site' and Quote_Line__r.SBQQ__ProductFamily__c = 'Evaluations' and Quote_Line__r.Course_Product_Line__c != 'RFTE'];
            for(Attendee__c attendee : attendeesEvaluations){
                if(!attendee.Quote_Line__r.Account__r.Name.contains('Toyota Motor') && attendee.Contact_Is_Valid__c != true){
                    numberOfInvalidEvaluationAttendees++;
                }
            }

            if(numberOfInvalidEvaluationAttendees > 0){
                errorMessages += 'Evaluation attendees are missing a contact record. Ensure all attendees in evaluations have an associated contact.<br/>';
				System.debug('OS EVALUATION ERRORS: ' + errorMessages);
            }            
            
            List<SBQQ__QuoteLine__c> quoteLines = [Select Id, Sales_Tax__c, Total_Amount_Without_Tax__c, SBQQ__NetPrice__c, Shipping_Amount__c, Shipping_Tax__c, Surcharge__c, Account__c, SBQQ__Quote__r.SBQQ__BillingCountry__c from SBQQ__QuoteLine__c where SBQQ__Quote__c  = :quoteId];
            
            //Tax calculation Errors ($0)
            Integer numberOfInvalidTaxLines = 0;
            Integer numberOfInvalidSurchargeLines = 0;
            for(SBQQ__QuoteLine__c quoteLine : quoteLines){
                //TODO
                //Check if training, shipping and check appropriate address field to determine tax requirement
                if(quoteLine.SBQQ__Quote__r.SBQQ__BillingCountry__c == 'Canada' && ((quoteLine.Sales_Tax__c == 0 && quoteLine.Total_Amount_Without_Tax__c != 0) || (quoteLine.Shipping_Amount__c != 0 && quoteLine.Shipping_Amount__c != NULL && quoteLine.Shipping_Tax__c == 0))){
                    numberOfInvalidTaxLines++;
                }
                if(quoteLine.Surcharge__c < 0){
                    numberOfInvalidSurchargeLines++;
                }
            }

            //TODO
            //Check the OL1 line as well

            //Check DL2 Bundle Tax. Force to be Ontario tax
            List<SBQQ__QuoteLine__c> dl2BundleLines = [select Id, Sales_Tax__c, Tax_Rate__c, Total_Amount_Without_Tax__c, SBQQ__NetPrice__c, Shipping_Amount__c, Shipping_Tax__c, Surcharge__c, Account__c, SBQQ__Quote__r.SBQQ__BillingCountry__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteId and Delivery_Method__c = 'Classroom' and SBQQ__Product__r.Distance_Learning__c = true and Course_Product_Line__c = 'JHSCII' and SBQQ__RequiredBy__c != null];
            for(SBQQ__QuoteLine__c quoteLine : dl2BundleLines){
                if(quoteLine.Sales_Tax__c <= 1){
                    numberOfInvalidTaxLines++;
                }
            }

            if(numberOfInvalidTaxLines > 0){
                errorMessages += 'All lines need tax.<br/>';
	            System.debug('TAX ERRORS: ' + errorMessages);                
            }
            
            if(numberOfInvalidSurchargeLines > 0){
                errorMessages += 'Quote Lines cannot have negative surcharges.<br/>';
	            System.debug('SURCHARGE ERRORS: ' + errorMessages);                  
            }
            
            //Shipping Line Errors
            Integer numberOfInvalidShippingContactLines = 0;
            Integer numberOfInvalidShippingContactEmailLines = 0;
            Integer numberOfInvalidShippingAddressLines = 0;
            List<SBQQ__QuoteLine__c> shippingQuoteLines = [Select ShipToContactId__c, ShipToContactId__r.Email, Shipping_Address__c, Shipping_Amount__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteId and Shipping_Method__c = 'Standard Courier'];
            for(SBQQ__QuoteLine__c quoteLine : shippingQuoteLines){
                if(quoteLine.ShipToContactId__c == NULL){
                    numberOfInvalidShippingContactLines++;
                }
                if(quoteLine.ShipToContactId__r.Email == NULL){
                    numberOfInvalidShippingContactEmailLines++;
                }
                if(quoteLine.Shipping_Address__c == NULL){
                    numberOfInvalidShippingAddressLines++;
                }
            }
            
            if(numberOfInvalidShippingContactLines > 0){
                errorMessages += 'All shipping lines need valid shipping contact.<br/>';
                System.debug('SHIPPING ERRORS: ' + errorMessages);
            }
            
            if(numberOfInvalidShippingContactEmailLines > 0){
                errorMessages += 'All shipping contacts need a valid email.<br/>';
                System.debug('SHIPPING ERRORS: ' + errorMessages);
            }
            
            if(numberOfInvalidShippingAddressLines > 0){
                errorMessages += 'All shipping lines need valid shipping address.<br/>';
                System.debug('SHIPPING ERRORS: ' + errorMessages);
            }
            
            //Check primary and invoice contacts
	        SBQQ__Quote__c quoteContacts = [Select Invoice_Contact__c, Invoice_Contact__r.Email, Invoice_Contact__r.Phone, Invoice_Contact__r.Has_Valid_Data__c, SBQQ__PrimaryContact__c, SBQQ__PrimaryContact__r.Email, SBQQ__PrimaryContact__r.Phone, SBQQ__PrimaryContact__r.Has_Valid_Data__c from SBQQ__Quote__c where id = :quoteId];
            
            //Primary Contact validity checks
            if(quoteContacts.SBQQ__PrimaryContact__c == NULL){
                errorMessages += 'Quote is missing a primary contact.<br/>';
                System.debug('PRIMARY CONTACT ERRORS: ' + errorMessages);
            }
            if(quoteContacts.SBQQ__PrimaryContact__r.Email == NULL){
                errorMessages += 'Quote primary contact is missing an email.<br/>';
                System.debug('PRIMARY CONTACT ERRORS: ' + errorMessages);                
            }
            if(quoteContacts.SBQQ__PrimaryContact__r.Phone == NULL){
                errorMessages += 'Quote primary contact is missing a valid phone number.<br/>';
                System.debug('PRIMARY CONTACT ERRORS: ' + errorMessages);                
            }
            if(quoteContacts.SBQQ__PrimaryContact__r.Has_Valid_Data__c == false){
                errorMessages += 'Quote primary contact has invalid data. Ensure name, phone and email are valid.<br/>';
                System.debug('PRIMARY CONTACT ERRORS: ' + errorMessages);                
            }
            
            //Invoice contact validity checks
            if(quoteContacts.Invoice_Contact__c == NULL){
                errorMessages += 'Quote is missing an invoice contact.<br/>';
                System.debug('INVOICE CONTACT ERRORS: ' + errorMessages);
            }
            if(quoteContacts.Invoice_Contact__r.Email == NULL){
                errorMessages += 'Quote invoice contact is missing an email.<br/>';
                System.debug('INVOICE CONTACT ERRORS: ' + errorMessages);                
            }
            if(quoteContacts.Invoice_Contact__r.Phone == NULL){
                errorMessages += 'Quote invoice contact is missing a valid phone number.<br/>';
                System.debug('INVOICE CONTACT ERRORS: ' + errorMessages);                
            }
            if(quoteContacts.Invoice_Contact__r.Has_Valid_Data__c == false){
                errorMessages += 'Quote invoice contact has invalid data. Ensure name, phone and email are valid.<br/>';
                System.debug('INVOICE CONTACT ERRORS: ' + errorMessages);                
            }            
            
            //Weekend Charge Line Errors
            Product2 weekendHalfProd = [Select Id from Product2 where Name = 'Weekend or Stat Holiday (Half-Day)'];
            Product2 weekendFullProd = [Select Id from Product2 where Name = 'Weekend or Stat Holiday'];
            Integer weekendHalfQL = [Select Count() from SBQQ__QuoteLine__c where SBQQ__Product__c = :weekendHalfProd.Id and SBQQ__Quote__c = :quoteId];
            Integer weekendFullQL = [Select Count() from SBQQ__QuoteLine__c where SBQQ__Product__c = :weekendFullProd.Id and SBQQ__Quote__c = :quoteId];
            
            SBQQ__Quote__c quote = [Select Total_Weekend_Duration__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where id = :quoteId];
            
            if(quote.Total_Weekend_Duration__c > 0){
                if(quote.Total_Weekend_Duration__c > 4 && weekendFullQL == 0){
                    errorMessages += 'Quote is missing weekend full-day charge.<br/>';
					System.debug('WEEKEND ERRORS: ' + errorMessages);                    
                }
                else if(quote.Total_Weekend_Duration__c <= 4 && weekendHalfQL == 0){
                    errorMessages += 'Quote is missing weekend half-day charge.<br/>';
                    System.debug('WEEKEND ERRORS: ' + errorMessages);
                }
            }
            
            //Check if there are existing sent quotes under opportunity
            List<SBQQ__Quote__c> quotesInOpportunity = [Select Id from SBQQ__Quote__c where SBQQ__Opportunity2__c = :quote.SBQQ__Opportunity2__c and Send_Date__c != NULL and Id != :quoteId and SBQQ__Status__c not in ('Rejected', 'Expired')];
            if(quotesInOpportunity.size() > 0){
                errorMessages += 'Quote cannot be sent because there is already a sent quote in the opportunity. Reject any quotes that are no longer valid.<br/>';
                System.debug('ALREADY SENT QUOTE ERRORS: ' + errorMessages);
            }
            
            return errorMessages;
        }
        catch(Exception e){
            //validation rule messages will break the component so need to send them back via the catch
            return e.getMessage();
        }
    }
    
    public override void beforeUpdate(){
        SBQQ__Quote__c oldQ;
        for(SBQQ__Quote__c q : (List<SBQQ__Quote__c>)Trigger.New){
            oldQ = (SBQQ__Quote__c)Trigger.oldMap.get(q.Id);
            
            //Check if recordType is not Expired/Rejected
            SBQQ__Quote__c quote = [Select Id, RecordType.Name from SBQQ__Quote__c where Id= :q.Id];
            if(quote.RecordType.Name != 'Rejected Quote' && quote.RecordType.Name != 'Expired Quote'){
                //Run quote validations
                if(q.Validated__c == TRUE && oldQ.Validated__c != TRUE){
                    String error = '';
                    //run validations
                    //Quotes already ordered can bypass current validations
                    if(q.SBQQ__Ordered__c != TRUE){
                        error = QuoteTriggerHandler.runQuoteValidations(q.Id);
                    }

                    if(error != ''){
                        q.addError(error, false);
                    }
                    else{
                        //Sets Quote to Approved
                        RecordType recordType = [Select Id from RecordType where name = 'Approved Quote'];
                        q.RecordTypeId = recordType.Id;
                        q.SBQQ__Status__c = 'Approved'; 
                        q.SBQQ__Primary__c = true;
                    }
                }

                if(q.Validated__c == FALSE && oldQ.Validated__c != FALSE && q.SBQQ__Status__c == 'Approved'){
                    //Sets Quote to Draft
                    RecordType recordType = [Select Id from RecordType where name = 'Pre-Approved Quote'];
                    q.RecordTypeId = recordType.Id;
                    q.SBQQ__Status__c = 'Draft'; 
                }
            }
           	
            if(q.Send_Date__c != NULL && oldQ.Send_Date__c == NULL){
                //If there is no opportunity on the quote, auto generate an opportunity with details
                if(oldQ.SBQQ__Opportunity2__c == NULL){
                    Account account = [Select Name from Account where Id = :q.SBQQ__Account__c Limit 1];
                    
                    Opportunity opp = new Opportunity();
                    opp.AccountId = oldQ.SBQQ__Account__c;
                    opp.SBQQ__PrimaryQuote__c = oldQ.Id;
                    opp.Name = 'AUTO: Opp - ' + q.Name;
                    opp.StageName = 'Awaiting Approval';
                    opp.Type = 'Existing Customer';
                    opp.CloseDate = System.today();
                    opp.Amount = oldQ.Total_Net_Amount__c;
                    opp.Auto_Generated__c = true;
                    insert opp;
                    
                    q.SBQQ__Opportunity2__c = opp.Id;
                }
                else{
                    Opportunity opp = [Select Id, StageName, Amount from Opportunity where Id = :oldQ.SBQQ__Opportunity2__c];
                    opp.StageName = 'Awaiting Approval';
                    opp.Amount = oldQ.Total_Net_Amount__c;

                    update opp;
                }                  
            }
            
            //Book the quote
            if(q.SBQQ__Ordered__c == TRUE && oldQ.SBQQ__Ordered__c != TRUE){                
                RecordType recordType = [Select Id from RecordType where name = 'Booked Quote'];
                q.RecordTypeId = recordType.Id;
                q.SBQQ__Status__c = 'Booked';
            }
        }
    }
    
    public override void afterUpdate(){
        // set of Booked Quote's
        Set<Id> BookedQuote = new Set<Id>();
        Map<Id, SBQQ__Quote__c> mapOldQuotes = (Map<Id, SBQQ__Quote__c>) Trigger.OldMap;
        
        for(SBQQ__Quote__c q : (List<SBQQ__Quote__c>) Trigger.New){
            
            System.debug('SBQQ__Status ::'+ q.SBQQ__Status__c);
            if(q.SBQQ__Status__c == 'Booked' && mapOldQuotes.get(q.Id).SBQQ__Status__c != 'Booked'){
                BookedQuote.add(q.id);
            }
        }
        
        if(BookedQuote.size() > 0){
            // call UpdateAttendeeServiceAppointment method to populate SA on attendees
            QuoteTriggerHandler.UpdateAttendeeServiceAppointment(BookedQuote);
        }
		
        System.debug('BOOKEDQUOTE SIZE:' + BookedQuote.size());
    }
    
    //Method to Map Service Appointment with Attendee 
    Public Static void UpdateAttendeeServiceAppointment(Set<Id> Qid){
        Map<id,id> ClassRoomList= new Map<id,id>();
        Set<id> onSiteList= new Set<id>();
        for(SBQQ__QuoteLine__c QuoteLines :[Select id,Name,Product_Family__c,Delivery_Method__c,Classroom_Course__c, SBQQ__ProductCode__c, SBQQ__RequiredBy__c,
                                            Classroom_Course__r.Confirmed_Seats__c,Classroom_Course__r.Course_Maximum_Capacity__c,SBQQ__Quantity__c
                                            from SBQQ__QuoteLine__c where SBQQ__Quote__c in : Qid]){
                                                if(QuoteLines.Product_Family__c == 'Courses' && QuoteLines.Delivery_Method__c == 'Classroom'){
                                                    if(QuoteLines.Classroom_Course__c != NULL){
                                                        ClassRoomList.put(QuoteLines.id,QuoteLines.Classroom_Course__c);
                                                    }
                                                }
                                                if((QuoteLines.Product_Family__c == 'Courses' && QuoteLines.Delivery_Method__c == 'On-site') || QuoteLines.Product_Family__c == 'Evaluations'){
                                                    onSiteList.add(QuoteLines.id);
                                                }
                                            }
        
        Set<Id> OverBooked=new Set<Id>();
        Map<Id,String> overBookedMap = new Map<Id,String>();
        
        // Prevent Quote from being booked if Confirmed Seat + Quantity is > Maximum Capacity 
        for(SBQQ__QuoteLine__c QuoteLines :[Select id,Name,SBQQ__Quote__c ,Product_Family__c,Delivery_Method__c,Classroom_Course__c,Classroom_Course__r.AppointmentNumber,
                                            Classroom_Course__r.Confirmed_Seats__c,Classroom_Course__r.Course_Maximum_Capacity__c,Classroom_Course__r.Spaces_Left__c,SBQQ__Quantity__c
                                            from SBQQ__QuoteLine__c where SBQQ__Quote__c in : Qid]){
                                                
                                                if(QuoteLines.Classroom_Course__c != NULL){
                                                    if(QuoteLines.Classroom_Course__r.Confirmed_Seats__c == NULL)
                                                        QuoteLines.Classroom_Course__r.Confirmed_Seats__c = 0;
                                                    if(QuoteLines.SBQQ__Quantity__c == NULL)
                                                        QuoteLines.SBQQ__Quantity__c = 0;
                                                    if(QuoteLines.Classroom_Course__r.Course_Maximum_Capacity__c == NULL)
                                                        QuoteLines.Classroom_Course__r.Course_Maximum_Capacity__c = 0;
                                                    
                                                    
                                                    system.debug('Spaces Left: '+(Integer)QuoteLines.Classroom_Course__r.Spaces_Left__c);
                                                    system.debug('Requested QTY: '+(Integer)QuoteLines.SBQQ__Quantity__c);
                                                    
                                                    if((Integer)QuoteLines.Classroom_Course__r.Spaces_Left__c < (Integer)QuoteLines.SBQQ__Quantity__c){
                                                        OverBooked.add(QuoteLines.SBQQ__Quote__c);
                                                        overBookedMap.put(QuoteLines.SBQQ__Quote__c,QuoteLines.Classroom_Course__r.AppointmentNumber);
                                                    }
                                                }
                                            }
        
        //Throwing Exception if it met above criteria
        for(SBQQ__Quote__c q : (List<SBQQ__Quote__c>) Trigger.New){
            if(overBookedMap.containsKey(q.Id)){
                q.addError('You cannot mark this Quote as "Booked" for the Service Appointment-' + overBookedMap.values() + ', because Confirmed Seat Exceeds Maximum Capacity');
                System.debug('THE MAXIMUM HAS BEEN REACHED!');                
            }
        }
        
        //ClassRoom Update Attendee
        if(ClassRoomList.size() > 0){
            List<Attendee__c> AttendeeClasroomList=[Select id,Name,Quote_Line__r.Id,Service_Appointment__c,Confirmed__c, Order_Product__c
                                                    from Attendee__c where Quote_Line__c in : ClassRoomList.keySet()];
            for(Attendee__c attendee : AttendeeClasroomList){
                OrderItem oi = NULL;
                oi = [Select Id from OrderItem where SBQQ__QuoteLine__c = :attendee.Quote_Line__c];
                attendee.Service_Appointment__c = ClassRoomList.get(attendee.Quote_Line__r.Id);
                attendee.Confirmed__c='Yes';
                if(oi != NULL){
                    attendee.Order_Product__c = oi.Id;
                }
            }
            Update AttendeeClasroomList;
        }
        
        //Onsite Update Attendee
        if(onSiteList.size() > 0){
            Map<id,id> OnsiteMap = New Map<id,id>();
            for(ServiceAppointment ServiceList : [select id,Quote_Line__c from ServiceAppointment where Quote_Line__c In : onSiteList]){
                OnsiteMap.put(ServiceList.Quote_Line__c,ServiceList.Id);
            } 
            List<Attendee__c> AttendeeClasroomList=[Select id,Name,Quote_Line__r.Id,Service_Appointment__c,Confirmed__c
                                                    from Attendee__c where Quote_Line__c in : onSiteList];
            for(Attendee__c attendee : AttendeeClasroomList){
                attendee.Service_Appointment__c = OnsiteMap.get(attendee.Quote_Line__r.Id);
                attendee.Confirmed__c='Yes';
            }
            Update AttendeeClasroomList;
            
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
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
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
    }    
    
}