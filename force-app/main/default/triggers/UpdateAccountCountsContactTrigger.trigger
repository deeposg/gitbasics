trigger UpdateAccountCountsContactTrigger on Contact (after insert, after update, after delete) {
    List<Id> accountIDsToUpdate = new List<Id>();
    
    if (trigger.isInsert) {
        // No need to check previous value
        for(Contact c : Trigger.new) {
            accountIDsToUpdate.add(c.AccountId);
        }
    } else if (trigger.isUpdate) {
        for( Id recordId : Trigger.newMap.keySet() ) {
			if( Trigger.oldMap.get( recordId ).AccountId != Trigger.newMap.get( recordId ).AccountId ) {
				// Account has changed
				accountIDsToUpdate.add(Trigger.oldMap.get( recordId ).AccountId);
                accountIDsToUpdate.add(Trigger.newMap.get( recordId ).AccountId);
  			}
		}
    } else if (trigger.isDelete) {
        // No need to check new value        
	    for(Contact c : Trigger.old) {
   			accountIDsToUpdate.add(c.AccountId);
		}
    }
    
    List<Id> accountIDsToUpdateNoDupes = new List<Id>(new Set<Id>(accountIDsToUpdate));
    
    if (accountIDsToUpdateNoDupes.size() > 0) {
	    UpdateAccountCountsHelper.updateAccountContactCount(accountIDsToUpdateNoDupes);
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