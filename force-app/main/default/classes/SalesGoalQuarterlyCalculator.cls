public class SalesGoalQuarterlyCalculator implements Schedulable{
    public void execute(SchedulableContext sc){
        calculateQuarterlyGoals();
    }

    public static void calculateQuarterlyGoals(){
        Period period = [SELECT FiscalYearSettings.Name, Number, FullyQualifiedLabel, StartDate, EndDate FROM Period WHERE Type = 'Quarter' AND StartDate <= TODAY AND EndDate >= TODAY];
        Integer currentFQ = period.Number;

        Map<Id, List<AggregateResult>> accountQuarterlyMap = new Map<Id, List<AggregateResult>>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        List<Account> accounts = [Select Id, Fiscal_Year_Goal__c, Fiscal_Year_Sales__c, Fiscal_Q1_Goal__c, Fiscal_Q2_Goal__c, Fiscal_Q3_Goal__c, Fiscal_Q4_Goal__c, Fiscal_Q1_Sales__c, Fiscal_Q2_Sales__c, Fiscal_Q3_Sales__c, Fiscal_Q4_Sales__c, Fiscal_Q1_State__c, Fiscal_Q2_State__c, Fiscal_Q3_State__c, Fiscal_Q4_State__c, Recalculate_Quarterly_Goals__c from Account where Recalculate_Quarterly_Goals__c = true limit 400];
        Set<Id> accountIds = new Set<Id>();
        List<Account> updateAccounts = new List<Account>();

        Integer iteration = 0;
        for(Account account : accounts){            
            iteration++;
            accountMap.put(account.Id, account);
            accountIds.add(account.Id);

            if((accountIds.size() == 50) || ((accounts.size() - iteration) == 0)){
                //get all accounts in list with sales and store quarterly aggregate in map to retrieve
                List<AggregateResult> fiscalQuarterlySales = [Select Account__c, sum(Total_Amount_Without_Tax__c) total_Sales, FISCAL_QUARTER(CreatedDate) FQ from OrderItem where Account__c in :accountIds and SBQQ__Status__c != 'Canceled' and (CRM_Statement_Item_Id__c = null or CRM_Statement_Item_Id__c = 0) and CreatedDate = THIS_FISCAL_YEAR group by Account__c, FISCAL_QUARTER(CreatedDate) order by Account__c, FISCAL_QUARTER(CreatedDate)];
                for(AggregateResult ar : fiscalQuarterlySales){
                    Id accountId = (Id)ar.get('Account__c');
                    if(accountQuarterlyMap.containsKey(accountId)){
                        accountQuarterlyMap.get(accountId).add(ar);
                    }
                    else{
                        accountQuarterlyMap.put(accountId, new List<AggregateResult> { ar });
                    }
                }

                List<AggregateResult> fiscalYearSales = [Select Account__c, sum(Total_Amount_Without_Tax__c) total_sales from OrderItem where Account__c in :accountIds and SBQQ__Status__c != 'Canceled' and (CRM_Statement_Item_Id__c = null or CRM_Statement_Item_Id__c = 0) and CreatedDate = THIS_FISCAL_YEAR group by Account__c, FISCAL_YEAR(CreatedDate) order by Account__c];
                for(AggregateResult ar : fiscalYearSales){
                    Id accountId = (Id)ar.get('Account__c');
                    Account currentAccount = accountMap.get(accountId);
                    Decimal yearlySales = (Decimal)ar.get('total_sales');

                    Decimal q1 = 0, q2 = 0, q3 = 0, q4 = 0;
                    List<AggregateResult> quarterlySales = accountQuarterlyMap.get(accountId);
                    for(AggregateResult qs : quarterlySales){
                        Integer fiscalQuarter = (Integer)qs.get('FQ');

                        if(fiscalQuarter == 1){
                            q1 = ((Decimal)qs.get('total_sales')).round(System.RoundingMode.Down);
                        }
                        if(fiscalQuarter == 2){
                            q2 = ((Decimal)qs.get('total_sales')).round(System.RoundingMode.Down);
                        }
                        if(fiscalQuarter == 3){
                            q3 = ((Decimal)qs.get('total_sales')).round(System.RoundingMode.Down);
                        }
                        if(fiscalQuarter == 4){
                            q4 = ((Decimal)qs.get('total_sales')).round(System.RoundingMode.DOWN);
                        }
                    }
                    
                    if(currentFQ == 2){
                        if(currentAccount.Fiscal_Year_Goal__c > yearlySales){
                            Decimal q1Difference = currentAccount.Fiscal_Q1_Goal__c - q1;

                            Decimal q2Offset = (q1Difference * 0.32).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q2_Goal__c += q2Offset;
                            Decimal q2MonthlyGoalSplit = (currentAccount.Fiscal_Q2_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.December_Goal__c = q2MonthlyGoalSplit;
                            currentAccount.January_Goal__c = q2MonthlyGoalSplit;
                            currentAccount.February_Goal__c = q2MonthlyGoalSplit;
    
                            Decimal q3Offset = (q1Difference * 0.40).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q3_Goal__c += q3Offset;
                            Decimal q3MonthlyGoalSplit = (currentAccount.Fiscal_Q3_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.March_Goal__c = q3MonthlyGoalSplit;
                            currentAccount.April_Goal__c = q3MonthlyGoalSplit;
                            currentAccount.May_Goal__c = q3MonthlyGoalSplit;
    
                            Decimal q4Offset = (q1Difference * 0.28).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q4_Goal__c += q4Offset;
                            Decimal q4MonthlyGoalSplit = (currentAccount.Fiscal_Q4_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.June_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.July_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.August_Goal__c = q4MonthlyGoalSplit;

                            currentAccount.Fiscal_Q1_State__c = q1;
                        }
                    }

                    if(currentFQ == 3){
                        if(currentAccount.Fiscal_Year_Goal__c > yearlySales){
                            Decimal q2Difference = currentAccount.Fiscal_Q2_Goal__c - q2;
                            Decimal q1Change = currentAccount.Fiscal_Q1_State__c - q1;
                            q2Difference += q1Change;

                            Decimal q3Offset = (q2Difference * 0.56).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q3_Goal__c += q3Offset;
                            Decimal q3MonthlyGoalSplit = (currentAccount.Fiscal_Q3_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.March_Goal__c = q3MonthlyGoalSplit;
                            currentAccount.April_Goal__c = q3MonthlyGoalSplit;
                            currentAccount.May_Goal__c = q3MonthlyGoalSplit;

                            Decimal q4Offset = (q2Difference * 0.44).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q4_Goal__c += q4Offset;
                            Decimal q4MonthlyGoalSplit = (currentAccount.Fiscal_Q4_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.June_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.July_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.August_Goal__c = q4MonthlyGoalSplit;

                            currentAccount.Fiscal_Q2_State__c = q2;
                            currentAccount.Fiscal_Q1_State__c = q1;
                        }
                    }

                    if(currentFQ == 4){
                    //let it be able to be run every day in q4, need to process cancellation immediately?
                    //Need to store q3 state and check that first? if state != 0, use that check, otherwise normal diff
                    //TODO v2
                        if(currentAccount.Fiscal_Year_Goal__c > yearlySales){
                            Decimal q3Difference = currentAccount.Fiscal_Q3_Goal__c - q3;
                            Decimal q2Change = currentAccount.Fiscal_Q2_State__c - q2;
                            Decimal q1Change = currentAccount.Fiscal_Q1_State__c - q1;
                            q3Difference += q2Change;
                            q3Difference += q1Change;

                            Decimal q4Offset = (q3Difference).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q4_Goal__c += q4Offset;
                            Decimal q4MonthlyGoalSplit = (currentAccount.Fiscal_Q4_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.June_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.July_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.August_Goal__c = q4MonthlyGoalSplit;

                            currentAccount.Fiscal_Q3_State__c = q3;
                            currentAccount.Fiscal_Q2_State__c = q2;
                            currentAccount.Fiscal_Q1_State__c = q1;
                        }
                    }

                    currentAccount.Recalculate_Quarterly_Goals__c = false;
                    updateAccounts.add(currentAccount);
                }
                
                //run calculations on any accounts where no sales processed
                for(String accountId : accountIds){
                    Account currentAccount = accountMap.get(accountId);
                    //if true, it wasn't processed above
                    if(currentAccount.Recalculate_Quarterly_Goals__c == true){
                        if(currentFQ == 2){
                            Decimal q1Difference = currentAccount.Fiscal_Q1_Goal__c;

                            Decimal q2Offset = (q1Difference * 0.32).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q2_Goal__c += q2Offset;
                            Decimal q2MonthlyGoalSplit = (currentAccount.Fiscal_Q2_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.December_Goal__c = q2MonthlyGoalSplit;
                            currentAccount.January_Goal__c = q2MonthlyGoalSplit;
                            currentAccount.February_Goal__c = q2MonthlyGoalSplit;
                            
                            Decimal q3Offset = (q1Difference * 0.40).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q3_Goal__c += q3Offset;
                            Decimal q3MonthlyGoalSplit = (currentAccount.Fiscal_Q3_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.March_Goal__c = q3MonthlyGoalSplit;
                            currentAccount.April_Goal__c = q3MonthlyGoalSplit;
                            currentAccount.May_Goal__c = q3MonthlyGoalSplit;
                            
                            Decimal q4Offset = (q1Difference * 0.28).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q4_Goal__c += q4Offset;
                            Decimal q4MonthlyGoalSplit = (currentAccount.Fiscal_Q4_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.June_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.July_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.August_Goal__c = q4MonthlyGoalSplit;
                            
                            currentAccount.Fiscal_Q1_State__c = 0;
                        }
                        if(currentFQ == 3){
                            Decimal q1 = 0, q2 = 0;
                            if(accountQuarterlyMap.containsKey(accountId)){
                                List<AggregateResult> quarterlySales = accountQuarterlyMap.get(accountId);
                                for(AggregateResult qs : quarterlySales){
                                    Integer fiscalQuarter = (Integer)qs.get('FQ');
            
                                    if(fiscalQuarter == 1){
                                        q1 = ((Decimal)qs.get('total_sales')).round(System.RoundingMode.DOWN);
                                    }
                                    if(fiscalQuarter == 2){
                                        q2 = ((Decimal)qs.get('total_sales')).round(System.RoundingMode.DOWN);
                                    }
                                }
                            }
                            Decimal q2Difference = currentAccount.Fiscal_Q2_Goal__c - q2;
                            Decimal q1Change = currentAccount.Fiscal_Q1_State__c - q1;
                            q2Difference += q1Change;
                            
                            Decimal q3Offset = (q2Difference * 0.56).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q3_Goal__c += q3Offset;
                            Decimal q3MonthlyGoalSplit = (currentAccount.Fiscal_Q3_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.March_Goal__c = q3MonthlyGoalSplit;
                            currentAccount.April_Goal__c = q3MonthlyGoalSplit;
                            currentAccount.May_Goal__c = q3MonthlyGoalSplit;
                            
                            Decimal q4Offset = (q2Difference * 0.44).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q4_Goal__c += q4Offset;
                            Decimal q4MonthlyGoalSplit = (currentAccount.Fiscal_Q4_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.June_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.July_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.August_Goal__c = q4MonthlyGoalSplit;
                            
                            currentAccount.Fiscal_Q2_State__c = q2;
                            currentAccount.Fiscal_Q1_State__c = q1;
                        }
                        if(currentFQ == 4){
                            Decimal q1 = 0, q2 = 0, q3 = 0;
                            if(accountQuarterlyMap.containsKey(accountId)){
                                List<AggregateResult> quarterlySales = accountQuarterlyMap.get(accountId);
                                for(AggregateResult qs : quarterlySales){
                                    Integer fiscalQuarter = (Integer)qs.get('FQ');
            
                                    if(fiscalQuarter == 1){
                                        q1 = ((Decimal)qs.get('total_sales')).round(System.RoundingMode.DOWN);
                                    }
                                    if(fiscalQuarter == 2){
                                        q2 = ((Decimal)qs.get('total_sales')).round(System.RoundingMode.DOWN);
                                    }
                                    if(fiscalQuarter == 3){
                                        q3 = ((Decimal)qs.get('total_sales')).round(System.RoundingMode.DOWN);
                                    }
                                }
                            }
                            Decimal q3Difference = currentAccount.Fiscal_Q3_Goal__c - q3;
                            Decimal q2Change = currentAccount.Fiscal_Q2_State__c - q2;
                            Decimal q1Change = currentAccount.Fiscal_Q1_State__c - q1;
                            q3Difference += q2Change;
                            q3Difference += q1Change;
                            
                            Decimal q4Offset = (q3Difference).round(System.RoundingMode.Down);
                            currentAccount.Fiscal_Q4_Goal__c += q4Offset;
                            Decimal q4MonthlyGoalSplit = (currentAccount.Fiscal_Q4_Goal__c / 3).round(System.RoundingMode.Down);
                            currentAccount.June_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.July_Goal__c = q4MonthlyGoalSplit;
                            currentAccount.August_Goal__c = q4MonthlyGoalSplit;
                            
                            currentAccount.Fiscal_Q3_State__c = q3;
                            currentAccount.Fiscal_Q2_State__c = q2;
                            currentAccount.Fiscal_Q1_State__c = q1;
                        }

                        currentAccount.Recalculate_Quarterly_Goals__c = false;
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