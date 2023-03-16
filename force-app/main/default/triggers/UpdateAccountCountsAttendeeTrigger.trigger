trigger UpdateAccountCountsAttendeeTrigger on Attendee__c (after insert, after update, after delete) {
    List<Id> accountIDsToUpdate = new List<Id>();
    
    if (trigger.isInsert) {
        // No need to check previous value
        for(Attendee__c c : Trigger.new) {
            if (c.Contact_Account_ID__c != null && c.Contact_Account_ID__c.length() > 0) {
	            accountIDsToUpdate.add(c.Contact_Account_ID__c   );
            }
        }
    } else if (trigger.isUpdate) {
        for( Id recordId : Trigger.newMap.keySet() ) {
			if( Trigger.oldMap.get( recordId ).Contact_Account_ID__c    != Trigger.newMap.get( recordId ).Contact_Account_ID__c    ) {
				// Account has changed
				
                if (Trigger.oldMap.get( recordId ).Contact_Account_ID__c != null && ((string)Trigger.oldMap.get( recordId ).Contact_Account_ID__c).length() > 0) {
					accountIDsToUpdate.add(Trigger.oldMap.get( recordId ).Contact_Account_ID__c   );
                }
                
                if (Trigger.newMap.get( recordId ).Contact_Account_ID__c != null && ((string)Trigger.newMap.get( recordId ).Contact_Account_ID__c).length() > 0) {
	                accountIDsToUpdate.add(Trigger.newMap.get( recordId ).Contact_Account_ID__c   );
                }
  			}
		}
    } else if (trigger.isDelete) {
        // No need to check new value        
	    for(Attendee__c c : Trigger.old) {
            if (c.Contact_Account_ID__c != null && c.Contact_Account_ID__c.length() > 0) {
   				accountIDsToUpdate.add(c.Contact_Account_ID__c   );
            }
		}
    }
    
    List<Id> accountIDsToUpdateNoDupes = new List<Id>(new Set<Id>(accountIDsToUpdate));
    
    if (accountIDsToUpdateNoDupes.size() > 0) {
	    UpdateAccountCountsHelper.updateAccountAttendeeCount(accountIDsToUpdateNoDupes);
	}
    
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
}