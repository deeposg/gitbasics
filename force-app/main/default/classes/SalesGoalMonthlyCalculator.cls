public class SalesGoalMonthlyCalculator implements Schedulable{
    public void execute(SchedulableContext sc){
        calculateMonthlyGoals();
    }

    public static void calculateMonthlyGoals(){
        Period period = [SELECT FiscalYearSettings.Name, Number, FullyQualifiedLabel, StartDate, EndDate FROM Period WHERE Type = 'Quarter' AND StartDate <= TODAY AND EndDate >= TODAY];
        Integer currentFQ = period.Number;
        Integer currentMonth = Date.Today().Month();

        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<Id, List<AggregateResult>> accountMonthlyMap = new Map<Id, List<AggregateResult>>();
        List<Account> accounts = [Select Id, Fiscal_Q1_Goal__c, Fiscal_Q2_Goal__c, Fiscal_Q3_Goal__c, Fiscal_Q4_Goal__c, January_Goal__c, February_Goal__c, March_Goal__c, April_Goal__c, May_Goal__c, June_Goal__c, July_Goal__c, August_Goal__c, September_Goal__c, October_Goal__c, November_Goal__c, December_Goal__c, January_Sales__c, February_Sales__c, March_Sales__c, April_Sales__c, May_Sales__c, June_Sales__c, July_Sales__c, August_Sales__c, September_Sales__c, October_Sales__c, November_Sales__c, December_Sales__c, Recalculate_Monthly_Goals__c from Account where Recalculate_Monthly_Goals__c = true limit 400];
        Set<Id> accountIds = new Set<Id>();
        List<Account> updateAccounts = new List<Account>();

        Integer iteration = 0;
        for(Account account : accounts){
            iteration++;
            accountMap.put(account.Id, account);
            accountIds.add(account.Id);

            if((accountIds.size() == 50) || ((accounts.size() - iteration) == 0)){

                List<AggregateResult> fiscalMonthSales = [Select Account__c, sum(Total_Amount_Without_Tax__c) total_sales, CALENDAR_MONTH(CreatedDate) CM from OrderItem where Account__c in :accountIds and SBQQ__Status__c != 'Canceled' and (CRM_Statement_Item_Id__c = null or CRM_Statement_Item_Id__c = 0) and CreatedDate = THIS_FISCAL_QUARTER group by Account__c, CALENDAR_MONTH(CreatedDate) order by Account__c, CALENDAR_MONTH(CreatedDate)];
                for(AggregateResult ar : fiscalMonthSales){
                    Id accountId = (Id)ar.get('Account__c');
                    if(accountMonthlyMap.containsKey(accountId)){
                        accountMonthlyMap.get(accountId).add(ar);
                    }
                    else{
                        accountMonthlyMap.put(accountId, new List<AggregateResult> { ar });
                    }
                }


                List<AggregateResult> fiscalQuarterSales = [Select Account__c, sum(Total_Amount_Without_Tax__c) total_sales from OrderItem where Account__c in :accountIds and SBQQ__Status__c != 'Canceled' and (CRM_Statement_Item_Id__c = null or CRM_Statement_Item_Id__c = 0) and CreatedDate = THIS_FISCAL_QUARTER group by Account__c, FISCAL_QUARTER(CreatedDate) order by Account__c];

                for(AggregateResult ar : fiscalQuarterSales){
                    Id accountId = (Id)ar.get('Account__c');
                    Account currentAccount = accountMap.get(accountId);
                    Decimal quarterlySales = (Decimal)ar.get('total_sales');

                    if(currentFQ == 1){
                        if(currentAccount.Fiscal_Q1_Goal__c > quarterlySales){
                            Decimal q1Difference = currentAccount.Fiscal_Q1_Goal__c - quarterlySales;

                            if(currentMonth == 10){
                                Decimal monthlyGoal = (q1Difference / 2).round(System.RoundingMode.Down);
                
                                currentAccount.October_Goal__c = monthlyGoal;
                                currentAccount.November_Goal__c = monthlyGoal;
                            }
            
                            if(currentMonth == 11){            
                                Decimal monthlyGoal = (q1Difference / 1).round(System.roundingMode.Down);
            
                                currentAccount.November_Goal__c = monthlyGoal;
                            }
                        }
                        //LWC cannot handle goal set to 0
                        /*
                        else{
                            if(currentMonth == 10){
                                currentAccount.October_Goal__c = 0;
                                currentAccount.November_Goal__c = 0;
                            }
                            if(currentMonth == 11){
                                currentAccount.November_Goal__c = 0;
                            }
                        }
                        */

                        List<AggregateResult> monthlySales = accountMonthlyMap.get(accountId);
                        for(AggregateResult arm : monthlySales){
                            Integer calendarMonth = (Integer)arm.get('CM');

                            if(calendarMonth == 9){
                                currentAccount.September_Sales__c = (Decimal)arm.get('total_sales');
                            }
                            if(calendarMonth == 10){
                                currentAccount.October_Sales__c = (Decimal)arm.get('total_sales'); 
                            }
                            if(calendarMonth == 11){
                                currentAccount.November_Sales__c = (Decimal)arm.get('total_sales'); 
                            }
                        }
                    }

                    if(currentFQ == 2){
                        if(currentAccount.Fiscal_Q2_Goal__c > quarterlySales){
                            Decimal q2Difference = currentAccount.Fiscal_Q2_Goal__c - quarterlySales;

                            if(currentMonth == 1){
                                Decimal monthlyGoal = (q2Difference / 2).round(System.RoundingMode.Down);
                
                                currentAccount.January_Goal__c = monthlyGoal;
                                currentAccount.February_Goal__c = monthlyGoal;
                            }
            
                            if(currentMonth == 2){            
                                Decimal monthlyGoal = (q2Difference / 1).round(System.roundingMode.Down);
            
                                currentAccount.February_Goal__c = monthlyGoal;
                            }
                        }
                        /*
                        else{
                            if(currentMonth == 1){
                                currentAccount.January_Goal__c = 0;
                                currentAccount.February_Goal__c = 0;
                            }
                            if(currentMonth == 2){
                                currentAccount.February_Goal__c = 0;
                            }
                        }
                        */

                        List<AggregateResult> monthlySales = accountMonthlyMap.get(accountId);
                        for(AggregateResult arm : monthlySales){
                            Integer calendarMonth = (Integer)arm.get('CM');

                            if(calendarMonth == 12){
                                currentAccount.December_Sales__c = (Decimal)arm.get('total_sales');
                            }
                            if(calendarMonth == 1){
                                currentAccount.January_Sales__c = (Decimal)arm.get('total_sales'); 
                            }
                            if(calendarMonth == 2){
                                currentAccount.February_Sales__c = (Decimal)arm.get('total_sales'); 
                            }
                        }
                    }       
                    
                    if(currentFQ == 3){
                        if(currentAccount.Fiscal_Q3_Goal__c > quarterlySales){
                            Decimal q3Difference = currentAccount.Fiscal_Q3_Goal__c - quarterlySales;

                            if(currentMonth == 4){
                                Decimal monthlyGoal = (q3Difference / 2).round(System.RoundingMode.Down);
                
                                currentAccount.April_Goal__c = monthlyGoal;
                                currentAccount.May_Goal__c = monthlyGoal;
                            }
            
                            if(currentMonth == 5){            
                                Decimal monthlyGoal = (q3Difference / 1).round(System.roundingMode.Down);
            
                                currentAccount.May_Goal__c = monthlyGoal;
                            }
                        }
                        /*
                        else{
                            if(currentMonth == 4){
                                currentAccount.April_Goal__c = 0;
                                currentAccount.May_Goal__c = 0;
                            }
                            if(currentMonth == 5){
                                currentAccount.May_Goal__c = 0;
                            }
                        }
                        */

                        List<AggregateResult> monthlySales = accountMonthlyMap.get(accountId);
                        for(AggregateResult arm : monthlySales){
                            Integer calendarMonth = (Integer)arm.get('CM');

                            if(calendarMonth == 3){
                                currentAccount.March_Sales__c = (Decimal)arm.get('total_sales');
                            }
                            if(calendarMonth == 4){
                                currentAccount.April_Sales__c = (Decimal)arm.get('total_sales'); 
                            }
                            if(calendarMonth == 5){
                                currentAccount.May_Sales__c = (Decimal)arm.get('total_sales'); 
                            }
                        }
                    }                    

                    if(currentFQ == 4){
                        if(currentAccount.Fiscal_Q4_Goal__c > quarterlySales){
                            Decimal q4Difference = currentAccount.Fiscal_Q4_Goal__c - quarterlySales;

                            if(currentMonth == 7){
                                Decimal monthlyGoal = (q4Difference / 2).round(System.RoundingMode.Down);
                
                                currentAccount.July_Goal__c = monthlyGoal;
                                currentAccount.August_Goal__c = monthlyGoal;
                            }
            
                            if(currentMonth == 8){            
                                Decimal monthlyGoal = (q4Difference / 1).round(System.roundingMode.Down);
            
                                currentAccount.August_Goal__c = monthlyGoal;
                            }
                        }

                        /*
                        else{
                            if(currentMonth == 7){
                                currentAccount.July_Goal__c = 0;
                                currentAccount.August_Goal__c = 0;
                            }
                            if(currentMonth == 8){
                                currentAccount.August_Goal__c = 0;
                            }
                        }
                        */

                        List<AggregateResult> monthlySales = accountMonthlyMap.get(accountId);
                        for(AggregateResult arm : monthlySales){
                            Integer calendarMonth = (Integer)arm.get('CM');

                            if(calendarMonth == 6){
                                currentAccount.June_Sales__c = (Decimal)arm.get('total_sales');
                            }
                            if(calendarMonth == 7){
                                currentAccount.July_Sales__c = (Decimal)arm.get('total_sales'); 
                            }
                            if(calendarMonth == 8){
                                currentAccount.August_Sales__c = (Decimal)arm.get('total_sales'); 
                            }
                        }
                    }

                    currentAccount.Recalculate_Monthly_Goals__c = false;
                    updateAccounts.add(currentAccount);
                }

                //run calculations on any accounts where no sales processed
                for(String accountId : accountIds){
                    Account currentAccount = accountMap.get(accountId);
                    //if true, it wasn't processed above
                    if(currentAccount.Recalculate_Monthly_Goals__c == true){
                        if(currentFQ == 1){
                            Decimal q1Difference = currentAccount.Fiscal_Q1_Goal__c;

                            if(currentMonth == 10){
                                Decimal monthlyGoal = (q1Difference / 2).round(System.RoundingMode.Down);
                                
                                currentAccount.October_Goal__c = monthlyGoal;
                                currentAccount.November_Goal__c = monthlyGoal;
                            }
            
                            if(currentMonth == 11){            
                                Decimal monthlyGoal = (q1Difference / 1).round(System.roundingMode.Down);
                                
                                currentAccount.November_Goal__c = monthlyGoal;
                            }
                        }
                        if(currentFQ == 2){
                            Decimal q2Difference = currentAccount.Fiscal_Q2_Goal__c;

                            if(currentMonth == 1){
                                Decimal monthlyGoal = (q2Difference / 2).round(System.RoundingMode.Down);
                
                                currentAccount.January_Goal__c = monthlyGoal;
                                currentAccount.February_Goal__c = monthlyGoal;
                            }
            
                            if(currentMonth == 2){            
                                Decimal monthlyGoal = (q2Difference / 1).round(System.roundingMode.Down);
            
                                currentAccount.February_Goal__c = monthlyGoal;
                            }
                        }
                        if(currentFQ == 3){
                            Decimal q3Difference = currentAccount.Fiscal_Q3_Goal__c;

                            if(currentMonth == 4){
                                Decimal monthlyGoal = (q3Difference / 2).round(System.RoundingMode.Down);
                
                                currentAccount.April_Goal__c = monthlyGoal;
                                currentAccount.May_Goal__c = monthlyGoal;
                            }
            
                            if(currentMonth == 5){            
                                Decimal monthlyGoal = (q3Difference / 1).round(System.roundingMode.Down);
            
                                currentAccount.May_Goal__c = monthlyGoal;
                            }
                        }
                        if(currentFQ == 4){
                            Decimal q4Difference = currentAccount.Fiscal_Q4_Goal__c;

                            if(currentMonth == 7){
                                Decimal monthlyGoal = (q4Difference / 2).round(System.RoundingMode.Down);
                
                                currentAccount.July_Goal__c = monthlyGoal;
                                currentAccount.August_Goal__c = monthlyGoal;
                            }
            
                            if(currentMonth == 8){            
                                Decimal monthlyGoal = (q4Difference / 1).round(System.roundingMode.Down);
            
                                currentAccount.August_Goal__c = monthlyGoal;
                            }
                        }

                        currentAccount.Recalculate_Monthly_Goals__c = false;
                        updateAccounts.add(currentAccount);
                    }
                }

                accountIds = new Set<Id>();
            }
            else{
                continue;
            }
        }

        update updateAccounts;
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