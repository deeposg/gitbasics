public class PhoneNumberValidator {
    public static string getPhoneError(string phone) {
        string phoneDigits = PhoneNumberValidator.getValidPhoneDigits(phone);
        
        boolean hasError = false;
        if (phoneDigits.startsWith('0') || phoneDigits.startsWith('1')) {
            hasError = true;
        }
        
        if (phoneDigits.length() != 10) {
            hasError = true;
        }
        
        if (hasError) {
	        return 'Enter a valid 10 digit number.';
        } else {
            return '';
        }
    }
    
    public static string getValidPhoneDigits(string phone) {
        string digits = phone.replaceAll( '[^0-9]', '' );
        return digits;  
    }
    
    public static string getFormattedPhoneNumber(string phone) {
        string phoneDigits = PhoneNumberValidator.getValidPhoneDigits(phone);
        string formattedPhone = phoneDigits;
        return formattedPhone;  
    }
}