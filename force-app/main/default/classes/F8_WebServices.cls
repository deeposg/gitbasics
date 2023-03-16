/*********************************************************************************************************************
* F8_WebServices class for F8_WebAPI utility methods
* Post- Create contact
* Author - Aditya Chasta
* Created date - 06/14/2017
**********************************************************************************************************************/

global class F8_WebServices {
    
    //generateKey this method will be used to generate encrypted key that will be used as session_id and reset_token
    global static String generateKey() {
        String guid; //encrypted unique id
        try {
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        } catch(Exception e) {
            guid = 'ERROR : '+e.getMessage()+' Stack Trace : '+e.getStackTraceString();
        }
        return guid;
    }
    
    global static F8_WebErrorResponseHandler generateErrorResponse(String message, String errorId) {
        
        F8_WebErrorResponseHandler errorResponse = new F8_WebErrorResponseHandler();
        errorResponse.error = true;
        errorResponse.error_id = errorId;
        errorResponse.message = message;
        
        return errorResponse;
    }
    
    global static String calculatorAPI(String quoteId) {
        String startingQuoteJson = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quoteId); 
        F8_CPQAPIServices.QuoteModel startingModel = (F8_CPQAPIServices.QuoteModel)JSON.deserialize(startingQuoteJson, F8_CPQAPIServices.QuoteModel.class); 
        
        F8_CPQAPIServices.CalculatorContext context = new F8_CPQAPIServices.CalculatorContext(); 
        context.quote = startingModel; 
        
        //Loading the QuoteCalculator API to calculate the price
        String resultJson = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteCalculator', null, JSON.serialize(context)); 
        F8_CPQAPIServices.QuoteModel resultModel = (F8_CPQAPIServices.QuoteModel)JSON.deserialize(resultJson, F8_CPQAPIServices.QuoteModel.class);
        
        //Calling the QuoteSaver API to save the quote
        String result = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(resultModel));
        return result;
    }
}