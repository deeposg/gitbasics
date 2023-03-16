trigger ValidateContactPhoneTrigger on Contact (before insert, before update) {
	for (Contact c: trigger.new){
        if (!String.isBlank(c.phone)) {
            string phoneError = PhoneNumberValidator.getPhoneError(c.phone);

            if (phoneError != '') {
                c.addError('Phone: ' + phoneError);
            } else {
                string formatted = PhoneNumberValidator.getFormattedPhoneNumber(c.phone);
                if (c.phone != formatted) {
	                c.phone = formatted;
                }
            }
        }
        
        if (!String.isBlank(c.MobilePhone)) {
            string mobilePhoneError = PhoneNumberValidator.getPhoneError(c.MobilePhone);
            
            if (mobilePhoneError != '') {
                c.addError('Mobile Phone: ' + mobilePhoneError);
            } else {
                string formattedMobile = PhoneNumberValidator.getFormattedPhoneNumber(c.MobilePhone);
                if (c.MobilePhone != formattedMobile) {
	                c.MobilePhone = formattedMobile;
                }
            }
        }
	}
}