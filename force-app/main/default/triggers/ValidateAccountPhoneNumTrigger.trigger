trigger ValidateAccountPhoneNumTrigger on Account (before insert, before update) {
    string test = '';
    

	for (Account c: trigger.new){
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
	}
    
}