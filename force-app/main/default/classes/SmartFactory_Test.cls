/*
   Copyright 2011 Mavens Consulting, Inc.
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at
       http://www.apache.org/licenses/LICENSE-2.0
   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/   

@isTest
private class SmartFactory_Test {
	static {
		SmartFactory.FillAllFields = true; // increase test coverage without creating custom objects
	}  
	
	static testMethod void createsSingleObjectWithSingleRequiredStringField() {
        Account account = (Account)SmartFactory.createSObject('Account');
        account.BillingState = 'Alberta';
        account.BillingCountry = 'Canada';
        account.BillingStateCode = 'AB';
        account.BillingCountryCode = 'CA';
        account.ShippingState = 'Alberta';
        account.ShippingCountry = 'Canada';
        account.ShippingStateCode = 'AB';
        account.ShippingCountryCode = 'CA';
		//insert account;
		//System.assert(account.Id != null);
		//System.assert(account.Name != null);
	}
	
	static testMethod void createsObjectWithCascadeSetsLookupField() {
		//Contact contact = (Contact)SmartFactory.createSObject('Contact', true);
        //contact.FirstName = 'Test';
        //insert contact;
		//System.assert(contact.Id != null);
		//System.assert(contact.AccountId != null);
	}
	
	static testMethod void createsObjectWithoutCascadeDoesNotSetLookupField() {
		Contact contact = (Contact)SmartFactory.createSObject('Contact', false);
		contact.FirstName = 'Test';
        //insert contact;
		//System.assert(contact.AccountId == null);
	}
	
    static testMethod void methodTest(){
        Contact contact = (Contact)SmartFactory.createSObject('Contact', false, 1);
        contact.FirstName = 'Test';
        //insert contact;
		//System.assert(contact.id != null);
    }
    
    static testMethod void methodTest2(){
        Contact contact = (Contact)SmartFactory.createSObject('Contact', false, new  Map<String, Object>{'LastName'=>'LastTestName'});
        contact.FirstName = 'Test';
        //insert contact;
		//System.assert(contact.id != null);
    }
    
    static testMethod void methodTest3(){
        List<Contact> contact = SmartFactory.createSObjectList('Contact', 1);
        //insert contact;
		//System.assert(contact.size()>0);
    }
    
    static testMethod void methodTest4(){
       List<Contact> contact = SmartFactory.createSObjectList('Contact', 1, new  Map<String, Object>{'LastName'=>'LastTestName'});
        //insert contact;
		//System.assert(contact.size()>0);
    }
    
    static testMethod void methodTest5(){
        List<Contact> contact = SmartFactory.createSObjectList('Contact',false, 1);
        //insert contact;
		//System.assert(contact.size()>0);
    }
    
	static testMethod void createObjectWithUnsupportedTypeThrowsException() {
		try {
			SmartFactory.createSObject('Unsupported');
			System.assert(false);
		} catch (UnsupportedObjectTypeException ex) {
			System.assert(true);
		}
	}
}