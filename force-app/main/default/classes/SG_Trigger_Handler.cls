public class SG_Trigger_Handler {
    public static void onDelete(List <Object> deletedObjects) {
        if (deletedObjects == null) {
            return;
        }
        
        for (Object o : deletedObjects) {
            boolean hasSGField = false;
            
            try {
                if (o instanceof SObject) {
                	hasSGField = ((SObject)o).getSobjectType().getDescribe().fields.getMap().keySet().contains('safeguard__c');
                } else {
                    hasSGField = ((SG_TestRecord_Abstract)o).contains('safeguard__c');
                }
            } catch(Exception ex) {
                hasSGField = false;
            }
    
            if (hasSGField) {
                Boolean objectSGError = false;
                String objectSGErrorMsg = 'SafeGuard: You Don\'t Have Permission To Delete This Record';
                
                Object objectSGErrorValue;
                
                if (o instanceof SObject) {
                    objectSGErrorValue = ((SObject)o).get('safeguard__c');
                } else {
                    objectSGErrorValue = ((SG_TestRecord_Abstract)o).get('safeguard__c');
                }
                            
                if (objectSGErrorValue == null) {
                    objectSGError = false;
                } else if (objectSGErrorValue instanceof String) {
                    if (((String)objectSGErrorValue).trim() != '') {
                        objectSGError = true;
                        
                        if (!(objectSGErrorValue instanceof Id)) {
	                        objectSGErrorMsg = ((String)objectSGErrorValue).trim();
                        }
                    }
                } else if (objectSGErrorValue instanceof Boolean) {
                    if ((Boolean)objectSGErrorValue == true) {
                        objectSGError = true;
                        // Use the default error message
                    }
                } else if (objectSGErrorValue instanceof Double) {
                    Double errorValue = (Double)objectSGErrorValue;
                    
                    if (errorValue > 0) {
                        objectSGError = true;
                        // Use the default error message
                    }
                } else {
                    if (objectSGErrorValue.toString().trim() != '') {
                        objectSGError = true;
                        // Use the default error message
                    }
                }
    
                if (objectSGError) {
                    // Prevent Deletion
                    if (o instanceof SObject) {
	                    ((SObject)o).addError(objectSGErrorMsg);
                    } else {
                        ((SG_TestRecord_Abstract)o).addError(objectSGErrorMsg);
                    }
                }
            }
        }
    }
    
    public static boolean handleTestBeforeInsert(List <Object> insertObjects) {
        return true;
    }
    
    public static boolean handleTestBeforeDelete(List <Object> deletedObjects) {
        return true;
    }

}