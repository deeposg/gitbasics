trigger SetContactUniqueEmailMD5 on Contact (before insert, before update) {
	for (Contact c : trigger.new) {
		Boolean uniqueEmailChanged = false;
        
        if (Trigger.isInsert) {
            uniqueEmailChanged = true;
        } else if (c.unique_email__c != Trigger.oldMap.get(c.ID).unique_email__c) {
			uniqueEmailChanged = true;
        }
        
         if (uniqueEmailChanged && c.unique_email__c != null && c.unique_email__c != '') {
             Blob targetBlob = Blob.valueOf(c.unique_email__c);
             Blob hash = Crypto.generateDigest('MD5', targetBlob);
             c.unique_email_md5__c = EncodingUtil.convertToHex(hash);
         }
     }
}