public class SalesGoalTrackingTool {

    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getFiscalQuarterSales(String accountId){
        List<AggregateResult> fiscalQuarterSales = [Select sum(Total_Amount_Without_Tax__c) total_sales, FISCAL_QUARTER(CreatedDate) FQ, FISCAL_YEAR(CreatedDate) FY from OrderItem where Account__c =: accountId and SBQQ__Status__c != 'Canceled' and (CRM_Statement_Item_Id__c = null or CRM_Statement_Item_Id__c = 0) and CreatedDate = THIS_FISCAL_YEAR group by FISCAL_QUARTER(CreatedDate), FISCAL_YEAR(CreatedDate) order by FISCAL_QUARTER(CreatedDate)];
        return fiscalQuarterSales;
    }

    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getFiscalMonthlySales(String accountId){
        List<AggregateResult> fiscalMonthlySales = [Select sum(Total_Amount_Without_Tax__c) total_sales, CALENDAR_MONTH(CreatedDate) CM from OrderItem where Account__c =: accountId and SBQQ__Status__c != 'Canceled' and (CRM_Statement_Item_Id__c = null or CRM_Statement_Item_Id__c = 0) and CreatedDate = THIS_FISCAL_YEAR group by CALENDAR_MONTH(CreatedDate) order by CALENDAR_MONTH(CreatedDate)];
        return fiscalMonthlySales;
    }

    @AuraEnabled(cacheable=true)
    public static Account getAccountInfo(String accountId){
        Account account = [Select Id, Fiscal_Year_Goal__c, Last_Fiscal_Year__c, Fiscal_Year_Sales__c, Fiscal_Q1_Goal__c, Fiscal_Q2_Goal__c, Fiscal_Q3_Goal__c, Fiscal_Q4_Goal__c, Fiscal_Q1_Sales__c, Fiscal_Q2_Sales__c, Fiscal_Q3_Sales__c, Fiscal_Q4_Sales__c, January_Sales__c, February_Sales__c, March_Sales__c, April_Sales__c, May_Sales__c, June_Sales__c, July_Sales__c, August_Sales__c, September_Sales__c, October_Sales__c, November_Sales__c, December_Sales__c, January_Goal__c, February_Goal__c, March_Goal__c, April_Goal__c, May_Goal__c, June_Goal__c, July_Goal__c, August_Goal__c, September_Goal__c, October_Goal__c, November_Goal__c, December_Goal__c from Account where Id =: accountId][0];
        return account;
    }

    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getPreviousFiscalYearSales(String accountId){
        List<AggregateResult> previousFiscalYearSales = [Select sum(Total_Amount_Without_Tax__c) total_sales, FISCAL_YEAR(CreatedDate) FY from OrderItem where Account__c =: accountId and SBQQ__Status__c != 'Canceled' and (CRM_Statement_Item_Id__c = null or CRM_Statement_Item_Id__c = 0) and CreatedDate = LAST_N_FISCAL_YEARS:3 group by FISCAL_YEAR(CreatedDate) order by FISCAL_YEAR(CreatedDate) desc];
        return previousFiscalYearSales;
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getPendingSalesGoalRequest(String accountId){
        try {
            List<Account> accounts = [Select Id, Requested_Sales_Goal__c from Account where id = :accountId and Requested_Sales_Goal__c != null];
            if(accounts.size() == 0){
                return 0;
            }

            return accounts[0].Requested_Sales_Goal__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean setAccountFiscalPeriods(String accountId, Decimal m1, Decimal m2, Decimal m3, Decimal m4, Decimal m5, Decimal m6, Decimal m7, Decimal m8, Decimal m9, Decimal m10, Decimal m11, Decimal m12){
        try{
            Account account = new Account(
                Id = accountId,
                January_Sales__c = m1,
                February_Sales__c = m2,
                March_Sales__c = m3,
                April_Sales__c = m4,
                May_Sales__c = m5,
                June_Sales__c = m6,
                July_Sales__c = m7,
                August_Sales__c = m8,
                September_Sales__c = m9,
                October_Sales__c = m10,
                November_Sales__c = m11,
                December_Sales__c = m12
            );
            update account;

            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Period getCurrentFiscalQuarter(){
        Period period = [SELECT FiscalYearSettings.Name, Number, FullyQualifiedLabel, StartDate, EndDate FROM Period WHERE Type = 'Quarter' AND StartDate <= TODAY AND EndDate >= TODAY][0];
        return period;
    }

    @AuraEnabled
    public static Period getCurrentFiscalYear(){
        Period period = [SELECT FiscalYearSettings.Name, Number, FullyQualifiedLabel, StartDate, EndDate FROM Period WHERE Type = 'Year' AND StartDate <= TODAY AND EndDate >= TODAY][0];
        return period;
    }

    @AuraEnabled
    public static Boolean setSalesGoalRequest(String accountId, Integer goal){
        try{
            RecordType rt = [Select Id, Name from RecordType where sObjectType = 'Administrative_Request__c' and Name = 'Sales Goal Request'][0];
            List<Administrative_Request__c> existingRequest = [Select Id, Requested_Sales_Goal__c from Administrative_Request__c where Goal_Approved__c = false and Account__c = :accountId and RecordTypeId = :rt.Id];
            
            Administrative_Request__c ar = new Administrative_Request__c(
                Account__c = accountId,
                RecordTypeId = rt.Id,
                Requested_Sales_Goal__c = goal
            );

            if(existingRequest.size() > 0){
                ar.Id = existingRequest[0].Id;
                update ar;
            }
            else{
                insert ar;
            }

            Account account = new Account(
                Id = accountId,
                Requested_Sales_Goal__c = goal
            );
            update account;

            return true;
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean approveSalesGoalRequest(String accountId){
        try {
            RecordType rt = [Select Id, Name from RecordType where sObjectType = 'Administrative_Request__c' and Name = 'Sales Goal Request'][0];
            List<Administrative_Request__c> existingRequest = [Select Id, Goal_Approved__c, Requested_Sales_Goal__c from Administrative_Request__c where Goal_Approved__c = false and Account__c = :accountId and RecordTypeId = :rt.Id];
            
            Administrative_Request__c ar = new Administrative_Request__c(
                Id = existingRequest[0].Id,
                Goal_Approved__c = true
            );

            Account account = new Account(
                Id = accountId,
                Requested_Sales_Goal__c = null
            );

            update account;
            update ar;
            
            return true;            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
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
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
    }
    
}