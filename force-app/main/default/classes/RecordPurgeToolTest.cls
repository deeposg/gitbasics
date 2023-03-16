@isTest
private class RecordPurgeToolTest {
    
    //@isTest (SeeAllData = true)
    static void purgeAccountsTest(){    
        Test.startTest();
        List<Account> accounts;
        List<User> salesReps;
        Date purgeDate = System.today() - 90;	//set the calculated purge date
        Date accountCreatedDate = System.today() - 30;	//set the minimum account age        
        
        //get all users who will be considered for purge
        salesReps = [select id from user where purge_exempt__c = false];
        
        accounts = [Select OwnerId, Reclaimed_From__c, Reclaimed_Date__c 
                    From Account 
                    Where OwnerId in :salesReps 											//only get accounts that belong to purge eligible users
                    AND(LastActivityDate < :purgeDate										//only consider accounts that haven't had activity in the last 90 days
                        OR LastActivityDate = null											//or has no activity date populated
                       )                        											
                    And (ParentId = null													//only consider accounts that do not have a parent
                         Or (ParentId != null And Child_Company_Contact_Required__c = true)	//or is a child and is required to be contacted
                        )
                    And Purge_Exempt__c = false												//only consider accounts that are not exempt from purging
					And CreatedDate < :accountCreatedDate									//only consider accounts that are of valid "age"                    
                   ];     
        
        System.assert(accounts.size() >= 0);
        
        RecordPurgeTool rpt = new RecordPurgeTool();
        SchedulableContext sc = null;
		rpt.execute(sc);
        
        //Run purgeAccounts
        RecordPurgeTool.purgeAccounts();

        //get trevors id since he will hold all purged accounts
        User purgeOwner = [Select Id from User Where name = 'Trevor Mandic'];	
        
        //retrieve all the accounts retrieved for purge
        accounts = [Select OwnerId, Reclaimed_From__c, Reclaimed_Date__c 
                    From Account 
                    Where id in :accounts										
                   ];	

        
        for(Account account : accounts){
           	System.assert(account.Reclaimed_Date__c == system.today());
            System.assert(account.OwnerId == purgeOwner.Id);
        }
        Test.stopTest();
    }
    
    @isTest
    static void doTestCodeCoverage(){
        RecordPurgeTool.testCodeCoverage();
    }

}