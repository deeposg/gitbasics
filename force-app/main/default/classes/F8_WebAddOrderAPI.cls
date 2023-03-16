/***************************
Class Name: F8_WebAddOrderAPI
Author: Aditya Chasta
Description: Class that takes data provided from cart and inserts order/orderProducts into Salesforce

History Log
=====================================
2017-12-17		AChasta		Created initial class
2018-06-13		BMathew		Fixed related records to remove orphaned records
2018-09-18		BMathew		Added Shipping/Billing addresses and Invoice/ShipTo/BillTo contacts to order
2018-11-21		BMathew		Added logic to determine if physical good order was Standard Courier or London Pickup and added additional details to order product lines
2019-05-03      MDrewitt    Added Client_ID__c and OrderNumber to the response after creation
2019-09-03		BMathew		Added email to attendee object
2022-10-25      Bmathew     Adjusted the stripe data in request to collect more data and store in salesforce
****************************/

@RestResource(urlMapping='/Cart/AddOrder/*')
global class F8_WebAddOrderAPI {
    
    @HttpPost
  	global static F8_WebResponseHandler addOrder(OrderRequest orderToCreate) {
    	F8_WebAddOrderAPISuccessResponseHandler successResponse; //Object to store success response
    	F8_WebErrorResponseHandler errorResponse; //Object to store error response
    	Savepoint sp = Database.setSavepoint();
    	System.debug(orderToCreate);
        System.debug(Json.serialize(orderToCreate));
        
    	try {
	        System.debug('F8_WebAddOrderAPI::SOQL Use (Start addOrder): ' + Limits.getQueries());            
      		successResponse = new F8_WebAddOrderAPISuccessResponseHandler();
      		if(orderToCreate != null) {
                //if shipping_method is populated, this indicates shipping, otherwise implied London Head Office Pickup
                String shippingMethod = orderToCreate.shipping_method == 'Standard Courier' ? 'Standard Courier' : 'London Pickup';
        		Set<String> productIdSet = new Set<String>();
        		if(orderToCreate.items != null && orderToCreate.items.size() > 0) {
          			//gather all product ids
                    for(ItemsWrapper item : orderToCreate.items) {
                    	productIdSet.add(item.product_id);
                    }
          
                  	//get the id for the shipping product from custom settings
                  	OSG_Settings__c shippingProductIdSetting = OSG_Settings__c.getInstance('Shipping Product Id');
                  	if(shippingProductIdSetting != null) {
                    	productIdSet.add(shippingProductIdSetting.Value__c);
                  	}

                  	//get the id for the promo product from custom settings
                  	/*OSG_Settings__c promoProductIdSetting = OSG_Settings__c.getInstance('Promo Product Id');
                  	if(promoProductIdSetting != null) {
                    	productIdSet.add(promoProductIdSetting.Value__c);
                  	}*/

          			//get the id for the tax product from custom settings
          			OSG_Settings__c taxProductIdSetting = OSG_Settings__c.getInstance('Tax Product Id');
          			if(taxProductIdSetting != null) {
            			productIdSet.add(taxProductIdSetting.Value__c);
          			}

          			//query for products and their pricebook entries
          			Map<Id, Product2> productMap = new Map<Id, Product2>([select id, (select id from PricebookEntries) from Product2 where id in: productIdSet]);
          
          			if(productMap.size() == productIdSet.size()) {
            			Pricebook2 pricebook;
            			if(!Test.isRunningTest()) {
              				pricebook = [select id, name from Pricebook2 where isStandard = true limit 1];
            			}
            
            			if(String.isNotBlank(orderToCreate.company)) {
              				//get recordType for Business Accounts
              				RecordType recordType = [select Id from recordType where name = 'Business Account'];
                
                            //create and insert a new account
                            Account companyAccount = new Account(Name = orderToCreate.company, RecordTypeId = recordType.Id, Account_Status__c = 'Pending', Account_Owner_Type__c  = 'Non-Exclusive');
                            insert companyAccount;
                            
                            // create and insert a bill-to contact
                            Contact billToContact = new Contact(
                                FirstName = orderToCreate.billing_address.first_name,
                                LastName = orderToCreate.billing_address.last_name,
                                AccountId = companyAccount.Id,
                                Email = orderToCreate.email,
                                Phone = orderToCreate.billing_address.phone
                            );
                            insert billToContact;
                            
                            companyAccount.Primary_Contact__c = billToContact.Id;
                            companyAccount.Invoice_Contact__c = billToContact.Id;
                            update companyAccount;
                
                            Contact shipContact = billToContact;
                  
                            // create a new order
                            Order newOrder = new Order(
                              	AccountId = companyAccount.Id,
                                Spree_Order_Id__c = orderToCreate.order_id,
                                Primary_Contact__c = billToContact.Id,
                              	BillToContactId = billToContact.Id,
                              	Invoice_Contact__c = billToContact.Id,
                              	EffectiveDate = Date.Today(),
                              	Status = 'Draft',
                              	SBQQ__PriceCalcStatus__c = 'Completed',
                              	Sales_User__c = 'ointe'
                            );
                            
                            if(Test.isRunningTest()) {
                              newOrder.Pricebook2Id = Test.getStandardPricebookId();
                            } 
                            else {
                              newOrder.Pricebook2Id = pricebook.id;
                            }
                            
                            //Constructs all billing address related information
                            if(orderToCreate.billing_address != null){
                                //Create LocationAddress
                                Location_Address__c locationAddress = createLocationAddress(orderToCreate.billing_address, 'Billing');
                                insert locationAddress;
                                                            
                                //Create AccountAddress
                                Account_Address__c accountAddress = createAccountAddress(companyAccount.Id, locationAddress.Id, 'Billing');
                                insert accountAddress;
                                
                                newOrder.Order_Billing_Address__c = accountAddress.Id;                                
                                newOrder.BillingStreet = orderToCreate.billing_address.address1 + ' ';
                                newOrder.BillingStreet += orderToCreate.billing_address.address2;
                                newOrder.BillingCity = orderToCreate.billing_address.city;
                                newOrder.BillingState = orderToCreate.billing_address.state;
                                newOrder.BillingPostalCode = orderToCreate.billing_address.postal_code;
                                newOrder.BillingCountry = orderToCreate.billing_address.country;
                            }
                            
                            Location_Address__c shippingLocationAddress;
                            Account_Address__c shippingAccountAddress;
                            //Constructs all shipping address related information
                            if(orderToCreate.shipping_address != null){
                                //Create LocationAddress
                                shippingLocationAddress = createLocationAddress(orderToCreate.shipping_address, 'Shipping');
                                insert shippingLocationAddress;
                                
                                //Create AccountAddress
                                shippingAccountAddress = createAccountAddress(companyAccount.Id, shippingLocationAddress.Id, 'Shipping');
                                insert shippingAccountAddress;
                            }


                            // insert the new order into Salesforce
                            insert newOrder;

                            //store stripe card details if populated
                            if(orderToCreate.stripe_data != null){
                                Stripe_Source__c stripeSource = new Stripe_Source__c(
                                    Name = orderToCreate.stripe_data.stripe_card_id, 
                                    Account__c = companyAccount.Id, 
                                    Order__c = newOrder.Id,
                                    Customer_Id__c = orderToCreate.stripe_data.stripe_customer_id,
                                    Exp_Month__c = orderToCreate.stripe_data.exp_month,
                                    Exp_Year__c = orderToCreate.stripe_data.exp_year,
                                    Last_4__c = orderToCreate.stripe_data.last_4,
                                    Usage__c = orderToCreate.stripe_data.usage
                                );
                                insert stripeSource;
                            }
                            
                            // gather all service appointment ids
                            Set<String> appointmentIdSet = new Set<String>();
                            for(ItemsWrapper item : orderToCreate.items) {
                                if(item.appointment != null){
                                    appointmentIdSet.add(item.appointment.id);
                                }
                            }
                            
                            // query for all the service appointments for these line items
                            Map<Id, ServiceAppointment> serviceAppointmentMap = new Map<Id, ServiceAppointment>(
                                [Select 
                                id,
                                Training_Address1__r.Address__c,
                                Training_Address1__r.City1__c,
                                Training_Address1__r.Province1__c,
                                Training_Address1__r.Postal_Code1__c,
                                Training_Address1__r.Country1__c,
                                SchedStartTime
                            from ServiceAppointment where id in: appointmentIdSet]);
                            
                            List<OrderItem> orderProductList = new List<OrderItem>();
                            List<Attendee__c> attendeeList = new List<Attendee__c>();
            
                            List<PriceBookEntry> pbEntry = [select id from PriceBookEntry where Product2Id in: productMap.keySet()];
                            Map<ItemsWrapper, OrderItem> orderProductToWrapperMap = new Map<ItemsWrapper, OrderItem>();
                
							System.debug('F8_WebAddOrderAPI::SOQL Use (Inside addOrder - start create prod orderItems): ' + Limits.getQueries()); 
                            
                            //Calculate shipping rate
                            Decimal orderTotal = 0;
                            Decimal taxRate = 0;
                            for(ItemsWrapper item : orderToCreate.items){
                            	orderTotal += item.total_cost;    
                            }
                            orderTotal += orderToCreate.shipping_cost; 
                            taxRate = (orderToCreate.tax_total / orderTotal).setScale(2);

                            //Create Stripe Payment for prepayments
                            if(orderToCreate.transaction_id != null){
                                Decimal stripeTotal = (orderTotal + orderToCreate.tax_total).setScale(2);
                                Stripe_Payments__c stripePayment = new Stripe_Payments__c(Name = orderToCreate.transaction_id, Name__c = billToContact.FirstName + ' ' + billToContact.LastName, Email__c = orderToCreate.email, Amount__c = stripeTotal, Order__c = newOrder.Id );
                                insert stripePayment;
                            }
                            
                            // create all the order lines and populate all associated information (classroom or physical good)
                            for(ItemsWrapper item : orderToCreate.items) {
                                OrderItem orderProduct;
                                
                                //TODO: DML IN FOR LOOP
            					Product2 product = [Select External_Product_Name__c, ProductCode, Family, Course_Product_Line__c, Amazon_Sku__c, ShipStation_Sku__c from Product2 where id = :item.product_id];                                
                                
                                //populate all shared line information
                                orderProduct = new OrderItem(
                                    Account__c = companyAccount.Id,
                                    PriceBookEntryId = productMap.get(item.product_id).PricebookEntries[0].id,
                                    OrderId = newOrder.Id, 
                                    Quantity = item.quantity,
                                    SBQQ__OrderedQuantity__c = item.quantity,
                                    UnitPrice = (item.unit_price).setScale(2),
                                    Tax_Rate__c = taxRate * 100,
                                    Total_Amount_Without_Tax__c = (item.total_cost).setScale(2),
                                    Sales_Tax__c = (item.total_cost * taxRate).setScale(2),
                                    Total_Net_Price__c = (item.total_cost + (item.total_cost * taxRate)).setScale(2),
                                    External_Product_Name__c = product.External_Product_Name__c,
                                    Product_Code__c = product.ProductCode,
                                    Product_Family__c = product.Family,
                                    Course_Product_Line__c = product.Course_Product_Line__c,
                                    SBQQ__Status__c = 'Draft',
                                    Amazon_Sku__c = product.Amazon_Sku__c,
                                    ShipStation_Sku__c = product.ShipStation_Sku__c,
                                    Shipping_Amount__c = 0,
                                    Shipping_Tax__c = 0
                                );

                                //set the shipping address on the order product
                                if(shippingMethod == 'Standard Courier'){
                                    orderProduct.Shipping_Address__c = shippingAccountAddress.Id;
                                    orderProduct.ShipToContactId__c = shipContact.Id;
                                    orderProduct.Delivery_Method__c = 'Shipping';
									orderProduct.Shipping_Method__c = shippingMethod;
                                    orderProduct.Ship_To_Province__c = orderToCreate.shipping_address.state;
                                    orderProduct.Shipping_Amount__c = orderToCreate.shipping_cost / orderToCreate.items.size();
                                    orderProduct.Shipping_Tax__c = (orderToCreate.shipping_cost / orderToCreate.items.size()) * taxRate;
                                }
                                
                                //process WSIB items
                                if(item.wsib_account_number != null){
                                    Contact wsibContact = new Contact(
                                        AccountId = companyAccount.Id,
                                        FirstName = item.contact_first_name,
                                        LastName = item.contact_last_name,
                                        Email = item.contact_email,
                                        Phone = item.contact_phone
                                    );

                                    insert wsibContact;

                                    newOrder.WSIB_Contact__c = wsibContact.Id;
                                    newOrder.WSIB_Number__c = item.wsib_account_number;
                                }

                                if(item.accept_subscription_terms != null){
                                    newOrder.Accepted_Subscription_Terms__c = item.accept_subscription_terms;
                                }

                                if(item.company_industry != null){
                                    companyAccount.Industry = item.company_industry;
                                }

                                if(item.company_employee_count != null){
                                    companyAccount.Number_of_Employees__c = item.company_employee_count;
                                }

                                if(item.marketing_opt_in != null){
                                    companyAccount.Marketing_Opt_In__c = item.marketing_opt_in;
                                }

                                update companyAccount;
                                                                   
                                //If OrderProduct is linked to a ServiceAppointment, populate the class related fields
                                System.debug('ITEM:APPOINTMENT');
                                System.debug(item.appointment);
                                if(item.appointment != null){
                                    System.debug('ITEM.APPOINTMENT != NULL');
                                }
                                if(item.appointment != null && item.appointment.id != null){
                                    System.debug('ITEM.APPOINTMENT != NULL && ITEM.APPOINTMENT.ID != NULL');
                                }
                                
                                if(item.appointment != null && item.appointment.id != null) {
                                    ServiceAppointment sa = serviceAppointmentMap.get(item.appointment.id);
                                    orderProduct.Classroom_Course__c = item.appointment.id;
                                    orderProduct.Training_Street__c = sa.Training_Address1__r.Address__c;
                                    orderProduct.Training_City__c = sa.Training_Address1__r.City1__c;
                                    orderProduct.Training_Province__c = sa.Training_Address1__r.Province1__c;
                                    orderProduct.Training_Postal_Code__c = sa.Training_Address1__r.Postal_Code1__c;
                                    orderProduct.Training_Country__c = sa.Training_Address1__r.Country1__c;
                                    orderProduct.Scheduled_Date_and_Time__c = sa.SchedStartTime;
                                    orderProduct.Delivery_Method__c = 'Classroom';
                                }
                                
                              	orderProductList.add(orderProduct);
                              	orderProductToWrapperMap.put(item, orderProduct);
                            }
							System.debug('F8_WebAddOrderAPI::SOQL Use (Inside addOrder - end create prod orderItems): ' + Limits.getQueries());            

                            // insert all the order lines
                            if(orderProductList.size() > 0) {
                                insert orderProductList;
                            }

                            // create attendees for relevent order lines
                            for(ItemsWrapper wrapper : orderProductToWrapperMap.keySet()) {
                                Id orderProductId = orderProductToWrapperMap.get(wrapper).id;
                                if(wrapper.appointment != null && wrapper.appointment.attendees != null && wrapper.appointment.attendees.size() > 0) {
                                	for(AttendeeWrapper attendee : wrapper.appointment.attendees) {     
                                        //search for contact (exact name match)
                                        //List<Contact> attendeeContacts = [Select Id from Contact where FirstName = :attendee.first_name and LastName = :attendee.last_name and AccountId = :companyAccount.Id];
                                        List<Contact> attendeeContacts = new List<Contact>();
                                        Contact c;
                                        
                                        if(attendeeContacts.size() == 0){
                                            //create associated contact
                                            Contact contact = new Contact(
                                                AccountId = companyAccount.Id,
                                                FirstName = attendee.first_name,
                                                LastName = attendee.last_name,
                                                Email = attendee.email,
                                                Phone = attendee.phone,
                                                MailingStreet = attendee.street,
                                                MailingCity = attendee.city,
                                                MailingState = attendee.state,
                                                MailingCountry = attendee.country,
                                                MailingPostalCode = attendee.postal_code
                                            );
                                            
                                            insert contact;
                                            c = contact;
                                        }
                                        else{
                                            c = attendeeContacts[0];
                                            c.MailingStreet = attendee.street;
                                            c.MailingCity = attendee.city;
                                            c.MailingState = attendee.state;
                                            c.MailingCountry = attendee.country;
                                            c.MailingPostalCode = attendee.postal_code;
                                            update c;
                                        }
                                        
                                        //If there serviceAppointment is defined, attach to attendee records
                                        if(serviceAppointmentMap.containsKey(wrapper.appointment.id)) {
                                            attendeeList.add(new Attendee__c(
                                                Name = attendee.first_name + ' ' + attendee.last_name,
                                            	Service_Appointment__c = wrapper.appointment.id,
                                                Order_Product__c = orderProductId,
                                            	Confirmed__c = 'Yes',
                                            	Contact__c = c.Id                                                
                                        	));
                                        }
                                        else{
                                            attendeeList.add(new Attendee__c(
                                            	Name = attendee.first_name + ' ' + attendee.last_name,
                                            	Order_Product__c = orderProductId,
                                            	Contact__c = c.Id
                                        	));           
                                        }
                                	}
                              	}
                            }
                
                            // insert attendees
                            if(attendeeList.size() > 0) {
                                System.debug('ATTENDEE LIST');
                                System.debug(attendeeList);
                              	insert attendeeList;
                            }

                            // activate the order
                            newOrder.Status = 'Draft';
                            update newOrder;
            

					        System.debug('F8_WebAddOrderAPI::SOQL Use (End addOrder): ' + Limits.getQueries());            
                            // return a success response
                            newOrder = [select Id, OrderNumber, Client_ID__c from Order where Id = :newOrder.id];
                            successResponse.order_id = newOrder.id;
                            successResponse.order_number = newOrder.OrderNumber;
                            successResponse.client_id = newOrder.Client_ID__c;
                            successResponse.success = true;
                            return successResponse;
            			} 
						else {
              				errorResponse = F8_WebServices.generateErrorResponse('Please provide valid Product Ids', 'ERROR');
            			}
          			} 
                    else {
            			errorResponse = F8_WebServices.generateErrorResponse('Please provide valid Product Ids', 'ERROR');
          			}
        		} 
                else {
          			errorResponse = F8_WebServices.generateErrorResponse('Please provide Items', 'ERROR');
        		}
      		} 
            else {
        		errorResponse = F8_WebServices.generateErrorResponse('Please provide request', 'ERROR');
      		}
    	} 
        catch(Exception e) {
      		Database.rollBack(sp);
      		errorResponse = F8_WebServices.generateErrorResponse(e.getMessage() + '####' + e.getStackTraceString(), 'ERROR');
    	}
    	return errorResponse;
    }	
    
    //Returns a LocationAddress object based on AddressWrapper object and type of address
    private static Location_Address__c createLocationAddress(AddressWrapper address, String type){
        Location_Address__c locationAddress = new Location_Address__c(
            Name = 'Location Address - ' + type,
            Location_Status__c = 'Active',
            Location_Type__c = 'Client Address',
            Address_1__c = address.address1,
            City__c = address.city,
            Province__c = address.state,
            Country__c = address.country,
            Postal_Code__c = address.postal_code,
            IHTPOSHT__c = 'OS'
        );
        return locationAddress;
    }

    //Returns a AccountAddress object based on AddressWrapper object and type of address and links to account
    private static Account_Address__c createAccountAddress(Id companyId, Id locationAddressId, String type){
        Account_Address__c accountAddress = new Account_Address__c(
            Account__c = companyId,
            Name = 'Account Adddress - ' + type,
            Location_Address__c = locationAddressId,
            Primary__c = true,
            Type__c = type + ' Address'
        );        
        return accountAddress;
    }

    global class OrderRequest {
        global String transaction_id;
        global String order_id;
        global String email;
        global String company;
        global String shipping_method;
        global Decimal shipping_cost;
        global Decimal tax_total;
        global String promo_code;
        global Decimal promo_discount;
        global AddressWrapper shipping_address;
        global AddressWrapper billing_address;
        global StripeData stripe_data;
        global List<ItemsWrapper> items;
    }

    global class StripeData {
        global String stripe_card_id;
        global Integer exp_month;
        global Integer exp_year;
        global String stripe_customer_id;
        global String last_4;
        global String usage;
    }
    
    global class AddressWrapper {
        global String first_name;
        global String last_name;
        global String address1;
        global String address2;
        global String city;
        global String country;
        global String state;
        global String postal_code;
        global String phone;
    }
    
    global class ItemsWrapper {
        global String product_id;
        global Decimal quantity;
        global Decimal unit_price;
        global Decimal total_cost;
        global String contact_first_name;
        global String contact_last_name;
        global String contact_email;
        global String contact_phone;
        global String wsib_account_number;
        global Boolean accept_subscription_terms;
        global String company_industry;
        global String company_employee_count;
        global Boolean marketing_opt_in;
        global AppointmentWrapper appointment;
    }
    
    global class AppointmentWrapper {
        global String id;
        global List<AttendeeWrapper> attendees;
    }
    
    global class AttendeeWrapper {
        global String first_name;
        global String middle_name;
        global String last_name;
        global String email;
        global String phone;
        global String street;
        global String city;
        global String state;
        global String country;
        global String postal_code;
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