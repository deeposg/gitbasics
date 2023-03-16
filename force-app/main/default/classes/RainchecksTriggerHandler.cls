/**********************************************************************
Name: QuoteTriggerHandler
Author : Shubham Verma
Description : Handler class for Rainchecks Trigger    
**********************************************************************/
public with sharing class RainchecksTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert(){
        
        /*
         for(Rainchecks__c r : (List<Rainchecks__c>) Trigger.New){
            // getting order ids from Rainchecks
            if(r.Status__c == 'Completed' || r.Status__c == 'Expired'){
                
                r.Is_Completed_Expired__c = True;
            }
            else {
                r.Is_Completed_Expired__c = False;
            }
        }
*/
    }
    
    public override void beforeUpdate(){
        /*
        for(Rainchecks__c r : (List<Rainchecks__c>) Trigger.New){
            // getting order ids from Rainchecks
            if(r.Status__c == 'Completed' || r.Status__c == 'Expired'){
                
                r.Is_Completed_Expired__c = True;
            }
            else {
                r.Is_Completed_Expired__c = False;
            }
        }
*/
    }
    
    public override void afterInsert(){
        // getting order ids from Rainchecks
        /*
        Set<Id> orderIdsSet = new Set<Id>();
        for(Rainchecks__c rain : (List<Rainchecks__c>) Trigger.New){
            if(rain.Order__c != null){
                orderIdsSet.add(rain.Order__c);
            }
        }
        
        if(orderIdsSet.size() > 0)
            RainchecksTriggerHandler.populateRainOnOrder(orderIdsSet);
*/
    }

    // method to populate raincheck number on related order
    // method to populate total intial value of rainchecks on order
    // order should be reduction order 
    public static void populateRainOnOrder( Set<Id> ordIds){
        /*
        // Map of reduction order's 
        Map<Id, Order> reductionOrderMap = new Map<Id, Order>();
        // fatching reduction orders
        for(Order ord : [Select Id, Applied_Rainchecks__c, Total_Raincheck_Current_Value__c From Order 
                            Where Id IN : ordIds AND IsReductionOrder = true]){
            reductionOrderMap.put(ord.Id, ord);
        }
        //System.assert(false,reductionOrderMap);
        // map of reduction order's to update
        Map<Id,Order> reductionOrderUpadateMap = new Map<Id,Order>();
        for(Rainchecks__c rain : (List<Rainchecks__c>) Trigger.New){
            System.debug('Rain-Name'+rain.name);
            //Append if already reductionOrderUpadateMap have order 
            if(reductionOrderMap.containsKey(rain.Order__c)){
                Order ord = reductionOrderMap.get(rain.Order__c);
                if(reductionOrderUpadateMap.containsKey(ord.Id)){
                    Order o = reductionOrderUpadateMap.get(ord.Id);
                    o.Applied_Rainchecks__c += +', ' +rain.Name;
                    o.Total_Raincheck_Current_Value__c += rain.Initial_Value__c;
                    reductionOrderUpadateMap.put(o.Id,o);
                }
                else{
                    ord.Applied_Rainchecks__c = rain.Name;
                    ord.Total_Raincheck_Current_Value__c = rain.Initial_Value__c;
                    reductionOrderUpadateMap.put(ord.Id, ord);
                }
                
            }
        }
        
        if(reductionOrderUpadateMap.size() > 0){
            TriggerHandler.bypass('OrderTriggerHandler');
            //System.assert(false,reductionOrderUpadateMap);
            update reductionOrderUpadateMap.values();
            TriggerHandler.clearBypass('OrderTriggerHandler');
        }
        */
    }
}