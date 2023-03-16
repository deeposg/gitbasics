@isTest
private class ValidateContactPhoneTriggerTest {

   @isTest static void testPhoneValidNumber() {
	   Contact c = new Contact();
       c.phone = '2234456677';
       c.MobilePhone = '2234456677';
       
       try {
	       insert c;
       } catch(Exception e) {
           // Expected
       }
   }


    @isTest static void testPhoneInvalidNumber() {
	   Contact c = new Contact();
       c.phone = '12234456677';
       c.MobilePhone = '12234456677';
       
       try {
	       insert c;
       } catch(Exception e) {
           // Expected
       }
   }

}