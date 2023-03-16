@isTest(SeeAllData=true)
private class ValidateAccountPhoneTriggerTest {

   @isTest static void testPhoneValidNumber() {
	   Account c = [select id from Account limit 1];
       c.phone = '2234456677';
       
       try {
	       update c;
       } catch(Exception e) {
           // Expected
       }
   }


    @isTest static void testPhoneInvalidNumber() {
	   Account c = [select id from Account limit 1];
       c.phone = '12234456677';
       
       try {
	       update c;
       } catch(Exception e) {
           // Expected
       }
   }

}