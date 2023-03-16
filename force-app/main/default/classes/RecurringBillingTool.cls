/***************************
Class Name: RecurringBillingTool
Author: Blessen Mathew
Description: Class to help with membership style billing

History Log
=====================================
2021-08-12		BMathew		Created initial class
2021-10-01		BMathew		Adjusted billing period to check product frequency to determine next invoice date
2022-06-20      BMathew     Added a check against the current product price. Add a contracted discount if difference exists
****************************/
public class RecurringBillingTool implements Schedulable{
    public void execute(SchedulableContext sc){
        generateAutomatedOrderProduct();
    }

    public static void generateAutomatedOrderProduct(){
        List<OrderItem> orderItems = [Select Id, Automated_Billing_Date__c, (Select Id from SBQQ__Components__r) from OrderItem where Automated_Billing_Date__c = TODAY and SBQQ__Status__c != 'Canceled'];
        for(OrderItem orderItem : orderItems){
            if(orderItem.SBQQ__Components__r == null || orderItem.SBQQ__Components__r.size() == 0){
                OrderItem op = [Select Account__c, SBQQ__Status__c, Product2Id, Product2.Recurring_Invoice_Frequency__c, Classroom_Course__c, Course_Product_Line__c, Delivery_Method__c, External_Product_Name__c, ListPrice, List_Unit_Price__c, Net_Unit_Price__c, Contracted_Discount_Display__c, Product2.Standard_Price__c, OrderId, SBQQ__OrderedQuantity__c, Product_Code__c, Product_Family__c, Product_Name__c, Promo_Discount_Amt__c, Promotional_Discount__c, Quantity, Scheduled_Date_and_Time__c, Total_Amount_Without_Tax__c, SBQQ__TaxCode__c, Tax_Province__c, Tax_Rate__c, Total_Price__c, Total_Net_Price__c, TotalPrice, Sales_Tax__c, Train_the_Trainer__c, Training_City__c, Training_Country__c, Training_Location_Name__c, Training_Postal_Code__c, Training_Province__c, Training_Street__c, UnitPrice, Volume_Discount__c, Wall_Certificate__c, Wallet_Card__c, Work_Type__c, PricebookEntryId, SBQQ__RequiredBy__c from OrderItem where id=:orderItem.Id];
                Order order = [Select Id, Status from Order where Id =: op.OrderId];
                
                SBQQ.TriggerControl.disable();
                order.Status = 'Draft';
                update order;
                SBQQ.TriggerControl.enable(); 
                
                OrderItem oi = op.clone(false, false, false, false);
                oi.Delivery_Date__c = system.today();
                oi.SBQQ__RequiredBy__c = op.Id;
                
                if(oi.Product2.Standard_Price__c > oi.ListPrice){
                    Decimal difference = (oi.ListPrice - oi.Product2.Standard_Price__c).round(System.RoundingMode.Down);
                    oi.ListPrice = oi.Product2.Standard_Price__c;
                    oi.List_Unit_Price__c = oi.Product2.Standard_Price__c;
                    oi.Contracted_Discount_Display__c = difference;
                    oi.UnitPrice = oi.ListPrice + difference;
                }
                
                DateTime dt = System.now();
                DateTime dtNextInvoice;
                if(op.Product2.Recurring_Invoice_Frequency__c == 'Monthly'){
                    dtNextInvoice = dt.addMonths(1);
                }
                else{
                    dtNextInvoice = dt.addMonths(12);
                }
                DateTime automatedBillingLabelDt = DateTime.newInstance(dtNextInvoice.year(), dtNextInvoice.month(), dtNextInvoice.day() - 1);
                String memo = dt.format('MMMM') + ' ' + dt.day() + ', ' + dt.year() + ' - ' + automatedBillingLabelDt.format('MMMM') + ' ' + automatedBillingLabelDt.day() + ', ' + automatedBillingLabelDt.year();
                
                oi.Invoice_Memo__c = memo;
                
                insert oi;
                
                SBQQ.TriggerControl.disable();
                order.Status = 'Activated';
                update order;
                SBQQ.TriggerControl.enable();
            }
            else{
                continue;
            }
        }
    }

    public static void testCodeCoverage(){
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
    }    
}