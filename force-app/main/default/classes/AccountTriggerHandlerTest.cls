@isTest
private class AccountTriggerHandlerTest {
    
    @isTest
    static void doTestCodeCoverage(){
        AccountTriggerHandler.TestCodeCoverage();
    }
    
    @isTest(SeeAllData=true)
    static void deployTrigger(){
        Account[] accts = new List<Account>();
        Account acc1 = new Account(Name = 'Test1');
        Account acc2 = new Account(Name = 'Test2');
        accts.add(acc1);
        accts.add(acc2);
        
        insert accts;
        
        Merge acc1 acc2;
    }
}